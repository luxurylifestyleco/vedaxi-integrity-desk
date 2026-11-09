# Elastic Web Master Intent

Owner: `Master Agent // Elastic Web`  
Canonical source: [`ELASTIC_WEB_CANONICAL_SCOPE.md`](ELASTIC_WEB_CANONICAL_SCOPE.md)  
Execution chain: [`ELASTIC_WEB_MASTER_BATCH_CHAIN.md`](ELASTIC_WEB_MASTER_BATCH_CHAIN.md)  
Live queue: [`../.codex/elastic-web-agent-queue.json`](../.codex/elastic-web-agent-queue.json)

## One-sentence intent

Elastic Web coordinates a human or agent's desired outcome across independent
agents, providers, and protocols while preserving delegated authority and
producing defensible evidence that the outcome was actually achieved.

Elastic Web is the interoperability and control plane. It is not a merchant,
payment processor, hosting provider, external business source of truth, or
replacement for VAOS, AgentOS, Decision Engine, Skill Port, A2A, MCP, WebMCP,
UCP, REST, or AP2.

## Non-negotiable truth rules

- `COMPLETED` requires completion criteria plus sufficient evidence.
- Unknown, expired, revoked, or out-of-scope authority fails closed.
- Worker self-reports, telemetry, screenshots, and HTTP success are not proof.
- Evidence is attributable, correlated, append-only, privacy-scoped, and
  independently verified where claimed.
- No production deployment, publication, payment, destructive migration, or
  external disclosure without explicit human approval.
- Every claim is `sourced`, `inferred`, `proposed`, or `unknown`.

## Current build state

| Area | Status | Meaning |
|---|---|---|
| B1 architecture | COMPLETED | Repository scope and gaps mapped |
| B2 contracts | COMPLETED | Local outcome/delegation/evidence/verification slice |
| B3 coordination | COMPLETED | Local outcome correlation |
| B4 evidence | PARTIAL | Local contracts pass; live PostgreSQL/RLS/retention remain open |
| B5 recovery | PARTIAL | Local evaluator/recovery/idempotency contracts; durable recovery open |
| B6 protocols/payment | BLOCKED | Browser WebMCP, UCP commerce, AP2, and live providers unproven |
| B7 Mission Control | PARTIAL | Read-only assurance view; trusted auth/source of truth open |
| B8 end-to-end proof | BLOCKED | Requires live deployment/provider/database evidence |

## Operator system

The queue runner is the only status surface to use:

```powershell
pwsh -NoProfile -File scripts/agent-queue-runner.ps1 -Reconcile
pwsh -NoProfile -File scripts/agent-queue-runner.ps1 -Watch -IntervalSeconds 15
pwsh -NoProfile -File scripts/agent-queue-runner.ps1 -Reconcile -Json
```

It shows `DONE`, observable workers, capacity, ready work, and blocked gates.
It never upgrades unknown or stale work to completed.

## Orchestration tools now present

- Codex CLI: execution bridge (`codex exec`, `codex queue`, `codex agents`).
- Local queue supervisor/runner: durable status and operator visibility.
- Elastic `recipe-runtime`: existing execution/evidence authority.
- LangGraph `1.2.19`: optional orchestration extra, wired through
  `packages/recipe-runtime/langgraph_adapter.py`.
- Existing skills: parallel dispatch, delivery orchestration, verification,
  handoff, and worker best practices.
- Hermes: reachable for tool/skill discovery; no agent skills or KGS dispatch
  capability were observable in this session.

## Remaining work is not “more orchestration”

The next work must close evidence gates, in this order:

1. Disposable PostgreSQL target with admin/restricted DSNs, RLS, retention, and
   rollback evidence.
2. One provider sandbox with receipt schema, credentials, issuer, and trust
   root.
3. Non-production deployed browser target for WebMCP registration, execution,
   removal, and cross-origin proof.
4. Independent verification of B8 scenarios A-H.

Until those inputs exist, the build is locally implemented but not production-
ready. Do not hide these gates with another framework.
