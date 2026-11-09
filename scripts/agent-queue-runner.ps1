[CmdletBinding()]
param(
    [string]$QueuePath = '.codex/elastic-web-agent-queue.json',
    [int]$IntervalSeconds = 15,
    [int]$MaxCycles = 1,
    [switch]$Watch,
    [switch]$Reconcile,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($IntervalSeconds -lt 1) { throw 'IntervalSeconds must be at least 1' }
if ($Watch -and $MaxCycles -eq 1) { $MaxCycles = 0 }

$root = (Resolve-Path -LiteralPath (Join-Path (Get-Location) $QueuePath)).Path | Split-Path -Parent | Split-Path -Parent
$supervisor = Join-Path $root 'scripts\agent-queue-supervisor.ps1'
if (-not (Test-Path -LiteralPath $supervisor)) { throw "Supervisor not found: $supervisor" }

function Get-Snapshot {
    $mode = if ($Reconcile) { 'Reconcile' } else { 'Plan' }
    $text = & pwsh -NoProfile -File $supervisor -Mode $mode -QueuePath $QueuePath
    if ($LASTEXITCODE -ne 0) { throw "Supervisor failed with exit code $LASTEXITCODE" }
    return ($text -join [Environment]::NewLine) | ConvertFrom-Json
}

function Show-Snapshot([object]$Snapshot) {
    if ($Json) {
        $Snapshot | ConvertTo-Json -Depth 12
        return
    }

    Write-Output "Master Agent // Elastic Web | $($Snapshot.queue_status) | $(Get-Date -Format o)"
    Write-Output "Queue: $($Snapshot.queue)"
    Write-Output ""
    Write-Output 'Workers'
    $workers = @($Snapshot.running_workers)
    if ($workers.Count -eq 0) {
        Write-Output '  none observable'
    } else {
        foreach ($worker in $workers) {
            Write-Output "  $($worker.task_id)  $($worker.observed_state)  last=$($worker.last_activity_at)  age=$($worker.age_minutes)m"
        }
    }

    Write-Output ''
    Write-Output 'Recent task history'
    $history = @($Snapshot.task_history | Select-Object -Last 8)
    if ($history.Count -eq 0) {
        Write-Output '  none recorded'
    } else {
        foreach ($task in $history) {
            Write-Output "  $($task.id)  $($task.status)  $($task.title)  evidence=$($task.evidence)"
        }
    }

    Write-Output ''
    Write-Output "Next batch (capacity $($Snapshot.plan.capacity))"
    $batch = @($Snapshot.plan.next_batch)
    if ($batch.Count -eq 0) {
        Write-Output "  none; pointer=$($Snapshot.plan.next_action_id)"
    } else {
        $batch | ForEach-Object { Write-Output "  $_" }
    }

    Write-Output "Running actions: $([string]::Join(', ', @($Snapshot.plan.running_actions)))"
    Write-Output "Blocked actions: $([string]::Join(', ', @($Snapshot.plan.blocked_actions)))"
}

$cycle = 0
do {
    $cycle++
    $snapshot = Get-Snapshot
    if ($cycle -gt 1 -and -not $Json) { Write-Output '' }
    Show-Snapshot $snapshot
    if (-not $Watch -and $MaxCycles -eq 1) { break }
    if ($MaxCycles -gt 0 -and $cycle -ge $MaxCycles) { break }
    Start-Sleep -Seconds $IntervalSeconds
} while ($true)
