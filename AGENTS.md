# Elastic Web Agent Operating Rules

## Master ownership

`Master Agent // Elastic Web` owns the execution queue. The user is not the
worker orchestrator and must not be asked to rotate agents, reconcile routine
statuses, close completed workers, or select the next ready task.

## Queue behavior

- Read `.codex/elastic-web-agent-queue.json` before dispatch.
- Keep at most five observable workers running.
- Dispatch only independent scopes with explicit write boundaries.
- Close a worker immediately after its result is captured and independently
  verified; completed workers do not occupy capacity.
- Automatically select the next ready task after closure without waiting for a
  user reminder.
- Never mark an unobservable, stale, blocked, or self-reported worker complete.
- If no ready task exists, show the blocked gates once and stop creating noise.
- Use `scripts/agent-queue-runner.ps1` as the operator status surface.

## Evidence

Worker output is a claim, not proof. The master must verify changed paths,
scope, exact commands, outputs, revision, and dirty-tree impact before marking
work `VERIFIED` or `CLOSED`.

## Authority boundaries

Do not deploy, publish, send external messages, pay, apply destructive
migrations, or disclose private project information without explicit approval.
Do not add a second orchestrator, queue, database, dashboard, or provider
authority. LangGraph may coordinate graph state behind existing Elastic
execution; it does not replace the queue or evidence authority.

## Handoff

Every cycle leaves the queue ledger, checklist, and next-action pointer
readable. Reports must separate `COMPLETED`, `FAILED`, `BLOCKED`, and
`UNVERIFIED`, and must state the smallest next action.
