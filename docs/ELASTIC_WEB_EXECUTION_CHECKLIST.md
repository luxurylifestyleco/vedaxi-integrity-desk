# Elastic Web Execution Checklist

This is the control list for the master build. It is updated after each batch;
an unchecked gate is not complete, even if a nearby test passes.

Historical source checkpoint: 2026-11-02. Public repository source observed at branch
`codex/protocol-interoperability`, revision
`189e07c82e5f02c7e094813135e66c15c492a9db`. The working tree is dirty. This
checkpoint did not advance the revision. Current nested verification is recorded below.

## Current reconciliation - 2026-11-09

- `COMPLETED`: the original IntentIR + Elastic Web handover has an evidence-backed audit, interoperability contract, standards matrix, roadmaps, backlog, decision register, A2AChat decision, and execution checklist.
- `COMPLETED`: reconciled local P0/P1 implementation surface; current nested full-suite verification is `624 passed in 10.51s`, exit 0, on 2026-11-09. The earlier `377 passed in 15.90s` count is historical worker evidence.
- `COMPLETED`: fixture-backed OpenAPI/AsyncAPI discovery and the loopback-only `ELASTIC_A2A_TCK_FIXTURE=1` profile; targeted official artifact/message TCK checks: `5 passed` over HTTP+JSON.
- `COMPLETED`: current loopback HTTP gateway/protocol evidence: `52 passed in 3.79s`, exit 0, using real `serve_forever` threads and `urllib.request.urlopen`. This proves local HTTP behavior only; it does not prove remote/provider/Supabase/production behavior.
- `COMPLETED`: linked Supabase runtime smoke passed in the DSN-bearing PowerShell session: restart persistence, task recovery, cleanup, and application-path cross-tenant denial passed.
- `BLOCKED`: normal-runtime official A2A TCK is not production conformance (`46 passed, 27 failed, 41 skipped`; `54/75` HTTP+JSON checks executed). Remaining failures are fixture-dependent outputs and TCK expectation mismatches.
- `COMPLETED locally / UNVERIFIED live`: Supabase JWT authentication is implemented in `apps/gateway/auth.py` with issuer, audience, JWKS, expiry, subject, server-controlled tenant, scopes, and revocation-hook checks; identity propagates into chat session/task ownership. A real user login/revocation exercise remains unrun.
- `UNVERIFIED`: production deployment, browser native interoperability, live external A2AChat/provider conformance, and provider-signed receipts.
- `COMPLETED`: direct restricted-role PostgreSQL `INSERT` rejection was verified against the linked Supabase target: temporary non-superuser `elastic_runtime_smoke` (member of `elastic_runtime`, `rolbypassrls=false`) received `ERROR: new row violates row-level security policy for table "chat_sessions"`; the temporary role was then removed and confirmed absent.
- `UNVERIFIED`: live restart-safe cancellation and rollback acceptance. The Supabase smoke proves the application-path restart/persistence/cross-tenant scenario; cancellation and rollback remain separate criteria.
- The actionable user/external prerequisites are tracked in `docs/INTENTIR_ELASTIC_WEB_UNBLOCK_LIST.md`.

## Control loop

- [x] Preserve the master intent at the top of `ELASTIC_WEB_MASTER_BATCH_CHAIN.md`.
- [x] Inspect the live workspace before adding new modules.
- [x] Record existing-vs-missing capability status.
- [x] Separate sourced, inferred, proposed, and unknown claims.
- [x] Use bounded delegated audits and challenge their output independently.
- [x] Re-run verification after every material implementation change.
- [ ] Do not claim live/runtime completion from repository tests.
- [ ] Do not publish, deploy, send, pay, or mutate external systems without explicit approval.

## Batch gates

| Batch | State | Evidence | Next action |
|---|---|---|---|
| B1 Architecture audit | `PASS - repository scope` | `ELASTIC_WEB_MASTER_BATCH_CHAIN.md`; repo audit; technical register; live handoff; current nested full suite `620 passed` | Preserve live database/provider/browser gates |
| B2 Core contracts | `PASS — local slice` | `packages/assurance-protocol/test_assurance.py`, `test_outcome.py`; targeted suite `6 passed` | Add persistence/runtime integration only after B1 map is frozen |
| B3 Coordination wiring | `PASS - local correlation` | `apps/gateway/test_gateway.py`; targeted correlation suite; current nested full suite `620 passed` | Preserve durable/restart correlation as a live gate |
| B4 Evidence infrastructure | `PASS - local contract + runtime smoke + direct RLS; live acceptance partial` | Local migration/RLS contract, linked Supabase restart/persistence/cross-tenant smoke, and direct restricted-role `INSERT` rejection passed. | Separately execute live restart-safe cancellation and rollback acceptance against a named target |
| B5 Evaluator/recovery | `PASS - local runtime slice` | Scenarios E, F, H passed in the scratch harness against existing contracts. Durable recovery still has no live database. | Do not retry irreversible operations without the RLS gate |
| B6 Protocol/payment boundaries | `PASS - local browser unregister` | Chrome 156 on `http://127.0.0.1:8767/`: toolsAdded 1, AbortSignal abort, toolsRemoved, later invoke `Tool not found`. `http://localhost:8767/` did not see the 127.0.0.1 tool. No public deploy. Payment not executed. | Keep payment fail-closed |
| B7 Mission Control/security | `PARTIAL` | Hermes PID 36908 alive, telegram connected, writer matches, revision `bf0203a794a0`, version 0.21.5. Webhook `:8644` listening. API `:8642` was `FIN_WAIT_1`. KGS `/health` 200 and `/stats` counts only. Worker identifiers UNKNOWN. Gateway was not restarted. | Do not copy private graph payloads into the repo |
| B8 End-to-end proof | `PASS - local suite; live proof open` | Local end-to-end paths are covered by the current `620 passed` suite. This does not prove live HTTP, payment, provider, database, or deployment behavior. | Not a production deploy |

## Current blockers and unknowns

- [x] Gateway cross-tenant denial is covered by the application-path tests.
- [x] Direct restricted-role PostgreSQL `INSERT` rejection is verified against the named live target; the temporary role was removed after the test.
- [ ] Restart-safe cancellation is verified across gateway restart against the named live target.
- [ ] Rollback acceptance is verified against the named live target.

## Current-batch evidence ledger

These are worker-reported existing outputs, not rerun during this checkpoint:

- `COMPLETED` — Sub Agent 21 // Recipe Assurance: changed `apps/gateway/app.py` and `apps/gateway/test_gateway.py`; syntax compilation and `git diff --check` passed; focused HTTP tests were `BLOCKED` by sandbox `WinError 10013`.
- `COMPLETED` — Sub Agent 22 // Mission Control: changed `apps/dashboard/app.py` and `apps/dashboard/test_dashboard.py`; direct handler check passed; focused dashboard HTTP tests were `BLOCKED` by sandbox `WinError 10013`.
- `COMPLETED` — Sub Agent 23 // Idempotency Store: added `packages/assurance-protocol/idempotency.py` and `test_idempotency.py`; exact output `5 passed in 0.38s`; `git diff --check` passed.
- `COMPLETED` — Sub Agent 24 // Assurance Panel: changed `apps/dashboard/index.html`; exact output `7 passed`; `git diff --check` passed.
- `COMPLETED` — Sub Agent 25 // Receipt Adapter: changed `packages/assurance-protocol/provider.py` and `test_provider.py`; exact output `9 passed in 0.44s`; `git diff --check` passed. Cryptographic verification and live-provider support remain unclaimed.
- `COMPLETED` — Sub Agent 26 // Retention Contract: changed `db/migrations/test_migration_contract.py`; exact output `8 passed in 0.06s`; `git diff --check` passed. This is static contract coverage only; SQL retention deletion enforcement remains absent.
- `UNVERIFIED` — prior aggregate `52 passed`, `403 passed`, and `88 passed` claims: no persisted command transcript or newly rerun output was supplied in this checkpoint, so they remain historical claims rather than fresh evidence for current edits.

- [x] Current nested full-repository test result is green: `624 passed in 10.51s`, exit 0, on 2026-11-09. The prior `403 passed, 32 socket failures` report from `WinError 10013` is historical and does not describe this current run.
- [x] Non-HTTP current-batch suites are independently green: `88 passed`; dashboard suite independently green: `7 passed`.
- [ ] Durable database target and migration authority are identified.
- [ ] Migration 004/005 passes live tenant/RLS, retention, rollback, and SQL/Python contract gates.
- [x] Pure verification engine covers duplicate, conflict, correlation, expiry, revocation, adapter aggregation, and signature fail-closed behavior.
- [x] Neutral execution context and tenant/evidence correlation contracts fail closed on mismatched tenant identity.
- [x] Recovery contract covers bounded retries, uncertain outcomes, duplicate/conflict events, delayed terminal events, cancellation truthfulness, and escalation decisions.
- [x] DB health check reports 12 required tables, append-only triggers, and missing RLS honestly.
- [x] Tenant/RLS runtime behavior is independently verified for the direct restricted-role `INSERT` denial; cancellation and rollback remain open.
- [ ] AgentOS/SkillPort/Hermes revisions and startup are independently verified.
- [ ] AP2 integration location and contract are identified.
- [ ] Provider attestations and artifact-store boundary are identified.
- [ ] Mission Control's trusted source of truth is confirmed; current endpoint explicitly reports `UNKNOWN` without one.
- [ ] Provider execution is routed through a common provider executor with durable operation identity, reconciliation, and multi-provider conflict policy.
- [x] A2A/recipe local assurance wiring has current focused loopback HTTP evidence: `apps/gateway/test_gateway.py apps/gateway/test_protocols.py`: `52 passed in 3.79s`, exit 0. Remote/provider interoperability remains unverified; the `620` full-suite result alone is not HTTP evidence.
- [x] WebMCP has a local registration, invocation, and removal contract with exact-origin checks; focused projection/boundary suite: `22 passed in 0.66s`.
- [ ] WebMCP has real browser registration, invocation, and removal evidence; deployment and browser interoperability remain unverified.
- [ ] UCP commerce/payment and AP2 remain unimplemented; no payment completion claim is allowed.

## Change discipline

- [x] Preserve unrelated dirty-tree changes.
- [x] Do not add a second orchestrator, registry, marketplace, dashboard, or database.
- [x] Keep the new contract/reference implementation separate from telemetry claims.
- [ ] Add a migration only after inspecting the existing database ownership and rollback path.
- [ ] Attach an executable test to every new behavior.

## Checkpoint conclusion

- `COMPLETED`: local migration/RLS contract and application-path tests. Current nested full suite `624 passed in 10.51s`, exit 0.
- `COMPLETED`: linked Supabase runtime smoke passed for restart persistence, task recovery, cleanup, and application-path cross-tenant denial.
- `COMPLETED`: direct restricted-role `INSERT` rejection passed against the linked Supabase target and the temporary role was removed.
- `UNVERIFIED`: restart-safe cancellation and rollback acceptance remain unexecuted.
- `UNVERIFIED`: live restart-safe cancellation, rollback acceptance, real provider-signed receipt authority, real Supabase login/revocation exercise, deployment, and native/public browser WebMCP proof remain open. Local/synthetic provider checks and one read-only external-provider path do not establish provider authority.
- Smallest remaining local/live gate: cancellation and rollback require a cancellable task and a disposable database or branch. External authentication, provider authority, deployment, and public/native browser proof remain separately gated. Do not apply destructive rollback checks to the shared `elastic_web` database. Do not call this production-ready.

## Final handoff test

The master prompt remains open until the checklist can answer, with reproducible
evidence: who authorized the outcome, which agents/providers/protocols acted,
what evidence was produced, what was independently verified, why the final state
was chosen, and how an auditor can reconstruct the path.
