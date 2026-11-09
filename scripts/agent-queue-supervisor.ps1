[CmdletBinding()]
param(
    [ValidateSet('Validate', 'Plan', 'Reconcile')]
    [string]$Mode = 'Validate',
    [string]$QueuePath = '.codex/elastic-web-agent-queue.json',
    [int]$StaleAfterMinutes = 30,
    [int]$MaxWorkers = 5,
    [string]$Now,
    [switch]$SelfTest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Read-Queue([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Queue file not found: $Path"
    }
    $raw = Get-Content -LiteralPath $Path -Raw
    if ([string]::IsNullOrWhiteSpace($raw)) {
        throw "Queue file is empty: $Path"
    }
    return $raw | ConvertFrom-Json
}

function Get-Now([string]$Value) {
    if ($Value) { return [DateTimeOffset]::Parse($Value, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::RoundtripKind) }
    return [DateTimeOffset]::UtcNow
}

function Assert-Queue([object]$Queue, [int]$Limit) {
    $required = @('schema_version', 'master', 'status', 'max_running_workers', 'running_workers', 'next_actions')
    foreach ($name in $required) {
        if ($null -eq $Queue.PSObject.Properties[$name]) {
            throw "Queue is missing required field: $name"
        }
    }

    if ($Queue.schema_version -ne 'elastic-web-agent-queue.v1') {
        throw "Unsupported queue schema: $($Queue.schema_version)"
    }

    $workerLimit = [int]$Queue.max_running_workers
    if ($workerLimit -lt 1 -or $workerLimit -gt $Limit) {
        throw "Queue max_running_workers must be between 1 and $Limit"
    }

    $running = @($Queue.running_workers)
    if ($running.Count -gt $workerLimit) {
        throw "Queue has $($running.Count) running workers but limit is $workerLimit"
    }

    $ids = @($Queue.next_actions | ForEach-Object { $_.id })
    $uniqueIds = @($ids | Sort-Object -Unique)
    if ($uniqueIds.Count -ne $ids.Count) {
        throw 'Queue next_actions contains duplicate ids'
    }
    foreach ($action in @($Queue.next_actions)) {
        foreach ($name in @('id', 'status', 'scope', 'missing_evidence', 'next_authorization')) {
            if ($null -eq $action.PSObject.Properties[$name]) {
                throw "Action $($action.id) is missing required field: $name"
            }
        }
    }
}

function Get-WorkerObservation([object]$Worker, [DateTimeOffset]$At, [int]$StaleMinutes) {
    $state = if ($null -ne $Worker.PSObject.Properties['status'] -and $Worker.status) { [string]$Worker.status } else { 'UNKNOWN' }
    $lastActivity = $null
    if ($null -ne $Worker.PSObject.Properties['last_activity_at'] -and $Worker.last_activity_at) {
        try { $lastActivity = [DateTimeOffset]::Parse([string]$Worker.last_activity_at, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::RoundtripKind) }
        catch { $state = 'UNKNOWN' }
    }
    $ageMinutes = $null
    if ($lastActivity) { $ageMinutes = [math]::Round(($At - $lastActivity).TotalMinutes, 1) }
    $observed = $state
    $processAlive = $null
    $processStartTime = $null
    if ($null -ne $Worker.PSObject.Properties['process_id'] -and $Worker.process_id) {
        $process = Get-Process -Id ([int]$Worker.process_id) -ErrorAction SilentlyContinue
        $processAlive = $null -ne $process
        if ($process) {
            $processStartTime = $process.StartTime.ToUniversalTime().ToString('o')
            if ($null -ne $Worker.PSObject.Properties['process_start_time'] -and $Worker.process_start_time) {
                try {
                    $expectedStart = [DateTimeOffset]::Parse([string]$Worker.process_start_time, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::RoundtripKind)
                    $actualStart = [DateTimeOffset]::Parse($processStartTime, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::RoundtripKind)
                    if ([math]::Abs(($actualStart - $expectedStart).TotalSeconds) -gt 2) { $processAlive = $false }
                } catch { $processAlive = $false }
            } else {
                $processAlive = $null
            }
        }
    }
    if ($state -eq 'RUNNING' -and $processAlive -eq $false) { $observed = 'EXITED_UNVERIFIED' }
    elseif ($state -eq 'RUNNING' -and $null -eq $lastActivity) { $observed = 'UNKNOWN' }
    elseif ($state -eq 'RUNNING' -and $ageMinutes -gt $StaleMinutes) { $observed = 'STALE_UNKNOWN' }

    [pscustomobject]@{
        task_id = if ($null -ne $Worker.PSObject.Properties['task_id'] -and $Worker.task_id) { [string]$Worker.task_id } else { 'UNKNOWN' }
        status = $state
        observed_state = $observed
        last_activity_at = if ($lastActivity) { $lastActivity.ToString('o') } else { $null }
        age_minutes = $ageMinutes
        process_id = if ($null -ne $Worker.PSObject.Properties['process_id'] -and $Worker.process_id) { [int]$Worker.process_id } else { $null }
        process_alive = $processAlive
        process_start_time = $processStartTime
    }
}

function Get-Plan([object]$Queue, [int]$Limit) {
    $occupied = @($Queue.running_workers | ForEach-Object { [string]$_.task_id })
    $capacity = [math]::Max(0, ([int]$Queue.max_running_workers) - $occupied.Count)
    $ready = @($Queue.next_actions | Where-Object { $_.status -in @('READY', 'QUEUED') })
    $blocked = @($Queue.next_actions | Where-Object { $_.status -eq 'BLOCKED' })
    $running = @($Queue.next_actions | Where-Object { $_.status -eq 'RUNNING' })
    $lanes = @('IntentIR', 'Elastic Web', 'A2A', 'Durability', 'Research', 'Verification')
    $cursor = 0
    if ($null -ne $Queue.PSObject.Properties['round_robin'] -and $null -ne $Queue.round_robin.cursor) {
        $cursor = [math]::Max(0, [int]$Queue.round_robin.cursor) % $lanes.Count
    }
    $ordered = @()
    for ($offset = 0; $offset -lt $lanes.Count; $offset++) {
        $lane = $lanes[($cursor + $offset) % $lanes.Count]
        $ordered += @($ready | Where-Object {
            $workstream = if ($null -ne $_.PSObject.Properties['workstream'] -and $_.workstream) { [string]$_.workstream } else { 'Verification' }
            $workstream -eq $lane
        } | Select-Object -First 1)
    }
    $selected = @($ordered | Select-Object -First ([math]::Min($capacity, $Limit)))
    [pscustomobject]@{
        capacity = $capacity
        ready_actions = @($ready | ForEach-Object { [string]$_.id })
        next_batch = @($selected | ForEach-Object { [string]$_.id })
        running_actions = @($running | ForEach-Object { [string]$_.id })
        blocked_actions = @($blocked | ForEach-Object { [string]$_.id })
        next_action_id = if ($selected.Count -gt 0) { [string]$selected[0].id } elseif ($blocked.Count -gt 0) { [string]$blocked[0].id } else { $null }
        round_robin = [pscustomobject]@{
            lanes = $lanes
            cursor = $cursor
            selected_lanes = @($selected | ForEach-Object { if ($null -ne $_.PSObject.Properties['workstream'] -and $_.workstream) { [string]$_.workstream } else { 'Verification' } })
        }
        dispatch_boundary = 'Master Agent must dispatch native Codex workers; this script does not claim to do so'
    }
}

function Write-Json([Parameter(ValueFromPipeline = $true)][object]$Value) {
    $Value | ConvertTo-Json -Depth 10
}

if ($SelfTest) {
    $sample = [pscustomobject]@{
        schema_version = 'elastic-web-agent-queue.v1'
        master = 'Master Agent // Test'
        status = 'READY_FOR_NEXT_CYCLE'
        max_running_workers = 2
        running_workers = @([pscustomobject]@{ task_id = 'T1'; status = 'RUNNING'; last_activity_at = '2026-11-02T00:00:00Z' })
        round_robin = [pscustomobject]@{ lanes = @('IntentIR', 'Elastic Web', 'A2A', 'Durability', 'Research', 'Verification'); cursor = 0 }
        next_actions = @(
            [pscustomobject]@{ id = 'A1'; status = 'READY'; workstream = 'Elastic Web'; scope = 'one'; missing_evidence = ''; next_authorization = '' },
            [pscustomobject]@{ id = 'A2'; status = 'BLOCKED'; scope = 'two'; missing_evidence = 'input'; next_authorization = 'authorize input' }
        )
    }
    Assert-Queue $sample 5
    $observation = Get-WorkerObservation $sample.running_workers[0] ([DateTimeOffset]::Parse('2026-11-02T01:00:00Z')) 30
    if ($observation.observed_state -ne 'STALE_UNKNOWN') { throw 'Self-test failed: stale worker was not classified safely' }
    $plan = Get-Plan $sample 5
    if (@($plan.next_batch).Count -ne 1 -or $plan.next_batch[0] -ne 'A1') { throw 'Self-test failed: ready action was not selected' }
    Write-Output 'SELFTEST PASS'
    exit 0
}

$queue = Read-Queue $QueuePath
Assert-Queue $queue $MaxWorkers
$at = Get-Now $Now
$observations = @($queue.running_workers | ForEach-Object { Get-WorkerObservation $_ $at $StaleAfterMinutes })
$plan = Get-Plan $queue $MaxWorkers
$reconcileWriteError = $null

if ($Mode -eq 'Reconcile') {
    $exited = @($observations | Where-Object { $_.observed_state -eq 'EXITED_UNVERIFIED' })
    foreach ($worker in $exited) {
        $action = @($queue.next_actions | Where-Object { $_.id -eq $worker.task_id })[0]
        if ($null -ne $action) { $action.status = 'FAILED' }
        if ($null -eq $queue.PSObject.Properties['task_history']) {
            $queue | Add-Member -MemberType NoteProperty -Name task_history -Value @()
        }
        $queue.task_history = @($queue.task_history) + [pscustomobject]@{
            id = $worker.task_id
            title = 'Worker Exit Reconciliation'
            owner = 'Master Agent // Elastic Web'
            status = 'FAILED'
            changed_files = @()
            evidence = "Process $($worker.process_id) exited without a final Codex result; output must be inspected before retry."
            completed_at = $at.ToString('o')
        }
    }
    if ($exited.Count -gt 0) {
        $queue.running_workers = @($queue.running_workers | Where-Object { $_.task_id -notin @($exited | ForEach-Object { $_.task_id }) })
    }
    $updatedAt = $at.ToString('yyyy-MM-ddTHH:mm:ssK')
    if ($null -eq $queue.PSObject.Properties['updated_at']) {
        $queue | Add-Member -MemberType NoteProperty -Name updated_at -Value $updatedAt
    } else {
        $queue.updated_at = $updatedAt
    }
    $supervisorState = [pscustomobject]@{
        last_reconciled_at = $at.ToString('o')
        stale_after_minutes = $StaleAfterMinutes
        observations = $observations
        next_batch = $plan.next_batch
        note = 'Observations never promote UNKNOWN or STALE_UNKNOWN to completed or failed.'
    }
    if ($null -eq $queue.PSObject.Properties['supervisor']) {
        $queue | Add-Member -MemberType NoteProperty -Name supervisor -Value $supervisorState
    } else {
        $queue.supervisor = $supervisorState
    }
    try {
        $queue | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $QueuePath -Encoding utf8
    } catch {
        $reconcileWriteError = $_.Exception.Message
    }
}

[pscustomobject]@{
    mode = $Mode
    queue = (Resolve-Path -LiteralPath $QueuePath).Path
    queue_status = [string]$queue.status
    running_workers = $observations
        task_history = if ($null -ne $queue.PSObject.Properties['task_history']) { @($queue.task_history) } else { @() }
    plan = $plan
    reconciled = ($Mode -eq 'Reconcile' -and $null -eq $reconcileWriteError)
    write_error = $reconcileWriteError
} | Write-Json
