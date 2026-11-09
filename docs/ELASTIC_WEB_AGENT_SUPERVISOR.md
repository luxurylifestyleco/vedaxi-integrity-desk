# Elastic Web Agent Supervisor

The queue supervisor is the durable local control-plane check for
`Master Agent // Elastic Web`. It reads `.codex/elastic-web-agent-queue.json`,
validates the state machine, identifies stale or unobservable workers without
calling them complete, and selects the next ready actions up to the configured
worker limit.

## Commands

From the repository root:

```powershell
pwsh -File scripts/agent-queue-supervisor.ps1 -Mode Validate
pwsh -File scripts/agent-queue-supervisor.ps1 -Mode Plan
pwsh -File scripts/agent-queue-supervisor.ps1 -Mode Reconcile
pwsh -File scripts/agent-queue-supervisor.ps1 -SelfTest
pwsh -File scripts/agent-queue-runner.ps1
pwsh -File scripts/agent-queue-runner.ps1 -Watch -IntervalSeconds 15
pwsh -File scripts/agent-queue-runner.ps1 -Reconcile -Json
pwsh -File scripts/agent-queue-dispatcher.ps1 -Mode Plan
```

`Reconcile` records observations and the next batch in the existing ledger. It
does not promote an unobservable or stale worker to `COMPLETED`, and it does not
delete worker history.

The runner is the operator view. One-shot mode prints the current queue,
observable workers, capacity, and next batch. `-Watch` repeats it; `-Json`
returns the same snapshot for another local process. It stops cleanly with
Ctrl+C and does not create a second queue.

The dispatcher is separate and safe by default: `-Mode Plan` has no side
effects. `-Mode Dispatch` starts only actions that explicitly provide
`prompt`, `write_scope`, and `verification_command`; each runs in an isolated
Codex worktree and returns to the master for independent verification.

## Boundary

The script is intentionally not a second orchestrator. The installed Codex CLI
does expose `codex exec`, `codex queue`, and `codex agents`, but a standalone
`codex exec` session is not the same as a verified native sub-agent of the
current master session. The master remains the only component allowed to
assign write scopes, verify evidence, and close work. This prevents a
scheduled process from creating duplicate writers or claiming that a worker is
active when the dispatcher is unavailable.

The supervisor therefore plans and reconciles work automatically, while actual
dispatch stays at the master boundary until an action has an explicit prompt,
write scope, worktree policy, and verification command. No external framework
is required for this local control plane.

## Recovery rule

`RUNNING` without a parseable `last_activity_at`, or older than the stale
threshold, is reported as `UNKNOWN` or `STALE_UNKNOWN`. A human or master agent
must inspect the actual session before requeueing it.
