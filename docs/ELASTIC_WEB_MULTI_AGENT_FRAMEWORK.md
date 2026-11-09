# Elastic Web Multi-Agent Framework

Status: `ACTIVE`  
Master: `Master Agent // Elastic Web`

## Operating architecture

```text
Master Agent // Elastic Web
  ├─ scopes work from ELASTIC_WEB_CANONICAL_SCOPE.md
  ├─ sequences batches from ELASTIC_WEB_MASTER_BATCH_CHAIN.md
  ├─ assigns disjoint sub-agent scopes
  ├─ challenges returned claims against files and test output
  ├─ integrates only verified changes
  └─ updates the execution checklist and decides the next batch

Sub-agents
  ├─ one bounded responsibility each
  ├─ no peer orchestration
  ├─ no external publication or deployment
  ├─ no shared-state writes unless explicitly assigned
  └─ return evidence, changed paths, failures, and unknowns
```

## Dispatch rules

1. Work is split only when tasks are independent and can run concurrently.
2. Shared database, gateway, migration, or dashboard writes are serialized.
3. A sub-agent report is not proof; the master re-checks it independently.
4. Every task states scope, exclusions, expected output, and verification.
5. Agents must preserve unrelated dirty-tree changes.
6. Failed or drifting agents are excluded from the final claim and recorded.
7. Completed agents are closed after their result is captured.

## Active roster

| Agent | Responsibility | Mode | Write scope | State |
|---|---|---|---|---|
| Master Agent // Elastic Web | Integration and verification | active | scoped repository changes | active |
| Sub Agent 1 // Migration Review | B4 migration/RLS/rollback audit | read-only | none | completed — FAIL gate |
| Sub Agent 2 // Verification Design | B4 verification engine implementation | bounded write | `packages/assurance-protocol/verification.py`, `test_verification.py` | completed — PASS contract slice |
| Sub Agent 5 // Context Contract | Neutral execution context | bounded write | `packages/assurance-protocol/execution_context.py`, `test_execution_context.py` | completed — PASS |
| Sub Agent 6 // Migration Hardening | Forward-only local DB hardening | bounded write | `db/migrations/005_outcome_assurance_hardening.sql`, `test_migration_contract.py` | completed — PASS static slice |
| Sub Agent 7 // Tenant Evidence | Tenant/evidence correlation | bounded write | `outcome.py`, `verification.py`, assurance tests | completed — PASS |
| Sub Agent 17 // Provider Contracts | Provider-neutral receipt/execution contracts | bounded write | `packages/assurance-protocol/provider.py`, `test_provider.py` | completed - PASS local slice |

## Required return format

- `PASS`, `FAIL`, `BLOCKED`, or `UNVERIFIED` verdict.
- Exact files and line/section evidence.
- Claims labeled sourced, inferred, proposed, or unknown.
- Changed files, if any.
- Commands/tests run and actual output.
- Risks and the smallest next action.

## Integration gate

The master integrates a sub-agent result only after checking:

- scope was respected;
- no unauthorized external or destructive action occurred;
- the result matches the canonical scope and batch gate;
- tests or read-only evidence support the claim;
- conflicts with existing source are surfaced.

## B4 dispatch record

- Migration review: `FAIL` for production persistence/security. Main findings:
  no RLS, no same-tenant foreign-key enforcement, retention metadata only, no
  rollback procedure, and SQL/Python constraint drift.
- Verification design: `FAIL` because the executable engine was absent;
  implementation is now dispatched as a pure in-memory slice.
- Master decision: proceed with verification contracts only; do not apply or
  represent migration 004 as production-ready.
- Verification implementation: `PASS` after master review corrected the
  signature-reference path to return `INSUFFICIENT` without explicit signature
  verification. Assurance tests: `15 passed`; full suite: `385 passed`.
- Tenant/evidence correlation: `PASS` after independent master verification;
  assurance suite `27 passed`, full suite `397 passed`. Live RLS remains
  unverified.

## Autonomous control protocol

The master agent owns the queue. The user does not rotate workers, reconcile
statuses, or decide whether a completed worker still occupies a slot.

### State machine

```text
QUEUED → RUNNING → REPORTED → VERIFIED → CLOSED
                  ↘ FAILED
                  ↘ BLOCKED
```

- `QUEUED`: assigned a unique task ID, owner, disjoint write scope, exclusions,
  acceptance criteria, and verification command.
- `RUNNING`: a worker has been dispatched and is observable by the master.
- `REPORTED`: the worker returned; its self-report is not yet evidence.
- `VERIFIED`: the master independently checked files, scope, and output.
- `CLOSED`: the worker no longer counts against the concurrency limit.
- `FAILED`: execution or verification failed; preserve the failure and do not
  silently replace it with a success claim.
- `BLOCKED`: the next action requires authority, environment, or an external
  state change; record the exact missing input.

### Queue invariants

1. Maximum five `RUNNING` workers.
2. Shared gateway, dashboard, migration, and database write scopes are
   serialized; independent read-only or package-local scopes may fan out.
3. A completed worker is closed immediately after its result and evidence are
   captured.
4. A failed dispatch is recorded as `FAILED` or `BLOCKED`; it is never treated
   as an implicit local success.
5. A replacement is dispatched only after closure and only for a concrete
   unresolved task, not to keep a count active.
6. Every cycle ends with an updated queue ledger, checklist, and next-action
   pointer so a later session can resume without reconstructing state from chat.

The machine-readable queue state is stored at
`.codex/elastic-web-agent-queue.json`.
