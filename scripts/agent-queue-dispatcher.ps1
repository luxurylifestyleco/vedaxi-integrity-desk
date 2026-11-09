[CmdletBinding()]
param(
    [ValidateSet('Plan', 'Dispatch')]
    [string]$Mode = 'Plan',
    [string]$QueuePath = '.codex/elastic-web-agent-queue.json',
    [int]$MaxWorkers = 5,
    [string]$RepositoryPath = (Get-Location).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Read-Queue([string]$Path) {
    $raw = Get-Content -LiteralPath $Path -Raw
    if ([string]::IsNullOrWhiteSpace($raw)) { throw "Queue is empty: $Path" }
    return $raw | ConvertFrom-Json
}

function Save-Queue([object]$Queue, [string]$Path) {
    $Queue.updated_at = [DateTimeOffset]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
    $temporaryPath = "$Path.$PID.tmp"
    try {
        $Queue | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $temporaryPath -Encoding utf8
        Move-Item -LiteralPath $temporaryPath -Destination $Path -Force
    } finally {
        if (Test-Path -LiteralPath $temporaryPath) {
            Remove-Item -LiteralPath $temporaryPath -Force -ErrorAction SilentlyContinue
        }
    }
}

function Enter-QueueLock([string]$Path) {
    $lockPath = "$Path.lock"
    try {
        return [System.IO.File]::Open($lockPath, [System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
    } catch {
        throw "Queue is already being dispatched: $Path"
    }
}

function ConvertTo-ProcessArgument([string]$Value) {
    if ($null -eq $Value) { return '""' }
    $escaped = $Value -replace '(\\*)"', '$1$1\"'
    $escaped = $escaped -replace '(\\+)$', '$1$1'
    return '"' + $escaped + '"'
}

function Get-Dispatchable([object]$Queue, [int]$Limit) {
    $running = @($Queue.running_workers)
    $capacity = [math]::Max(0, [int]$Queue.max_running_workers - $running.Count)
    $actions = @($Queue.next_actions | Where-Object { $_.status -in @('READY', 'QUEUED') })
    $selected = @($actions | Select-Object -First ([math]::Min($capacity, $Limit)))
    $planned = @()
    foreach ($action in $selected) {
        $missing = @(@('prompt', 'write_scope', 'verification_command') | Where-Object {
            $null -eq $action.PSObject.Properties[$_] -or [string]::IsNullOrWhiteSpace([string]$action.$_)
        })
        $planned += [pscustomobject]@{
            id = [string]$action.id
            status = if ($missing.Count -eq 0) { 'DISPATCHABLE' } else { 'UNDISPATCHABLE' }
            missing_fields = @($missing)
            write_scope = if ($action.write_scope) { [string]$action.write_scope } else { $null }
        }
    }
    [pscustomobject]@{
        capacity = $capacity
        ready_actions = @($actions | ForEach-Object { [string]$_.id })
        planned = $planned
    }
}

if (-not (Test-Path -LiteralPath $QueuePath)) { throw "Queue not found: $QueuePath" }

if ($Mode -eq 'Plan') {
    $queue = Read-Queue $QueuePath
    $plan = Get-Dispatchable $queue $MaxWorkers
    [pscustomobject]@{
        mode = $Mode
        queue = (Resolve-Path -LiteralPath $QueuePath).Path
        plan = $plan
        dispatch_side_effects = 'NONE'
    } | ConvertTo-Json -Depth 10
    exit 0
}

$codexCandidates = @(
    @(Get-Command codex.exe -ErrorAction SilentlyContinue)
    @(Get-Command codex -All -ErrorAction SilentlyContinue)
)
$codex = @($codexCandidates | Where-Object { $_.CommandType -eq 'Application' -or $_.CommandType -eq 'ExternalScript' } | Select-Object -First 1)
if ($codex.Count -eq 0) {
    throw 'codex CLI is not available on PATH'
}
$codex = $codex[0]

$queueLock = Enter-QueueLock $QueuePath
try {
    $queue = Read-Queue $QueuePath
    $plan = Get-Dispatchable $queue $MaxWorkers

$dispatchable = @($plan.planned | Where-Object { $_.status -eq 'DISPATCHABLE' })
if ($dispatchable.Count -eq 0) {
    [pscustomobject]@{
        mode = $Mode
        dispatched = @()
        skipped = @($plan.planned)
        reason = 'No task has explicit prompt, write_scope, and verification_command metadata.'
    } | ConvertTo-Json -Depth 10
    exit 0
}

$runRoot = Join-Path $RepositoryPath '.codex\agent-runs'
New-Item -ItemType Directory -Path $runRoot -Force | Out-Null
$started = @()
foreach ($item in $dispatchable) {
    $action = @($queue.next_actions | Where-Object { $_.id -eq $item.id })[0]
    $runId = "$($action.id)-$([DateTimeOffset]::UtcNow.ToString('yyyyMMddHHmmss'))"
    $runDir = Join-Path $runRoot $runId
    New-Item -ItemType Directory -Path $runDir -Force | Out-Null
    $outputPath = Join-Path $runDir 'output.jsonl'
    $lastMessagePath = Join-Path $runDir 'last-message.md'
    $lease = [pscustomobject]@{
        task_id = [string]$action.id
        run_id = $runId
        status = 'STARTING'
        last_activity_at = [DateTimeOffset]::UtcNow.ToString('o')
        process_id = $null
        process_start_time = $null
        output = $outputPath
    }
    $queue.running_workers = @($queue.running_workers) + $lease
    $action.status = 'RUNNING'
    Save-Queue $queue $QueuePath
    try {
        $args = @('exec', '--json', '--cd', $RepositoryPath, '--sandbox', 'workspace-write', '--output-last-message', $lastMessagePath)
        if ($action.worktree_policy -ne 'shared') { $args += '--worktree' }
        $args += [string]$action.prompt
        $filePath = $codex.Source
        if ($codex.CommandType -eq 'ExternalScript') {
            $filePath = (Get-Command pwsh -CommandType Application -ErrorAction Stop).Source
            $args = @('-NoProfile', '-File', $codex.Source) + $args
        }
        $quotedArgs = $args | ForEach-Object { ConvertTo-ProcessArgument ([string]$_) }
        $process = Start-Process -FilePath $filePath -ArgumentList $quotedArgs -WorkingDirectory $RepositoryPath -RedirectStandardOutput $outputPath -RedirectStandardError (Join-Path $runDir 'error.log') -PassThru
        $lease.process_id = $process.Id
        $lease.process_start_time = $process.StartTime.ToUniversalTime().ToString('o')
        $lease.status = 'RUNNING'
        $lease.last_activity_at = [DateTimeOffset]::UtcNow.ToString('o')
        Save-Queue $queue $QueuePath
        $started += [pscustomobject]@{ id = [string]$action.id; run_id = $runId; process_id = $process.Id; output = $outputPath }
    } catch {
        $queue.running_workers = @($queue.running_workers | Where-Object { $_.run_id -ne $runId })
        $action.status = 'READY'
        Save-Queue $queue $QueuePath
        throw
    }
}

[pscustomobject]@{
    mode = $Mode
    dispatched = $started
    note = 'Dispatch creates isolated Codex worktrees. Master verification and queue closure remain mandatory.'
} | ConvertTo-Json -Depth 10
} finally {
    if ($null -ne $queueLock) { $queueLock.Dispose() }
}
