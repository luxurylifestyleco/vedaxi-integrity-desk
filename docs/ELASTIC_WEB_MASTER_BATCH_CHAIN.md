# Elastic Web Master Batch Chain

Status: `not production-ready; reconciled 2026-11-09`  
Owner: `Master Agent // Elastic Web`  
Source: `C:\Users\m_jor\.codex\attachments\c1742733-f89e-46bf-bb07-c84dd918dd7d\Pasted text.txt`

## Main intent — never drop this

Elastic Web must coordinate a human or agent's desired outcome across
independent agents, providers, and protocols while preserving delegated
authority and producing defensible evidence that the desired state was actually
achieved. Elastic Web is the interoperability/control plane; it is not the
merchant, payment processor, hosting provider, or external source of truth.

## Non-negotiable invariants

- Extend existing VAOS/AgentOS/Decision Engine/Skill Port/protocol/security
  boundaries; do not create a second orchestrator, registry, marketplace, or
  mandatory proxy path.
- Unknown, expired, revoked, or out-of-scope authority fails closed.
- Telemetry, logs, screenshots, and successful HTTP responses are not business
  proof by themselves.
- Evidence is append-only, attributable, correlated, privacy-scoped, and
  independently verifiable where claimed.
- `COMPLETED` requires completion criteria plus sufficient evidence; tool-call
  success is not completion.
- No live publish, payment, deployment, destructive migration, or external
  disclosure without an explicit human approval gate.
- Every claim is labeled `sourced`, `inferred`, `proposed`, or `unknown`.

## Batch chain

| Batch | Purpose | Required output | Gate to advance |
|---|---|---|---|
| B1 | Architecture audit | Existing-vs-required map; source/runtime boundaries; gap list | Every required capability is mapped to evidence or marked unknown |
| B2 | Core contracts | Outcome Envelope, lifecycle, delegation, evidence, verification contracts | Schemas reject unsafe ambiguity; contract tests pass |
| B3 | Coordination wiring | Outcome IDs correlated through intent, capability, protocol, execution, and event paths | One read-only execution proves correlation without a new orchestrator |
| B4 | Evidence infrastructure | Append-only ledger, artifact references, integrity/provenance interfaces, verification adapters | Duplicate/correction/conflict/revocation tests pass |
| B5 | Evaluator/recovery | Completion criteria, partial completion, retries, timeout, cancellation, recovery, reconciliation | Irreversible operations are not retried blindly; failure scenarios are explicit |
| B6 | Protocol/payment boundaries | A2A/MCP/WebMCP/UCP/REST/AP2 adapter mapping and payment evidence correlation | Protocols remain distinct; AP2 is retained; live claims are separately evidenced |
| B7 | Mission Control/security | Existing dashboard extension, audit view, tenant isolation, threat model | No secret leakage or authorization bypass in tests and review |
| B8 | End-to-end proof | Scenarios A–H with receipts and handoff | All scenarios have reproducible evidence; unresolved live work is listed |

## Current batch state

### B1 — Architecture audit

`PASS - repository scope`. The public Elastic repo, technical register, and live-system handoff
were inspected. The public repo has intent, capabilities, recipes, telemetry,
custom protocol adapters, assurance contracts, local suitability filtering,
trusted synthetic MCP bridging, and opt-in durable chat/task adapters. Live
runtime/deployment, Supabase/RLS, SkillPort/AgentOS/Hermes, and provider
integrations are not proven by this workspace alone.

### B2 — Core contracts

`PASS - local slice`. The existing assurance package was extended with
`OutcomeEnvelope`, `Delegation`, `EvidenceRecord`, `VerificationResult`, guarded
lifecycle transitions, and an append-only in-memory ledger reference. This is a
contract/reference slice, not a claim of durable production persistence.

### B3 - Coordination wiring

`PASS - local correlation`. The existing capability execution endpoint accepts
or creates an `outcome_id`, carries it through protocol metadata and the
delivered event, and returns it to the caller. Durable outcome persistence and
authorization enforcement remain open.

### B4 - Evidence infrastructure

`PASS - local contract + direct RLS; live acceptance partial`. Local
migration/RLS contracts, application-path tenant checks, and direct restricted-role
`INSERT` rejection passed against the linked Supabase target using a temporary
non-bypass role; the role was removed after verification. Live restart-safe
cancellation and rollback acceptance remain separate unexecuted criteria.

### B8 - End-to-end proof

`PASS - local suite; live proof open`. The UCP catalog path uses the existing
registry and executor. Current nested full suite: `624 passed in 10.51s`, exit 0.
The earlier `377 passed` count is historical worker evidence. Scenario D,
payment, and live deployment proof were not run. The linked Supabase runtime
smoke separately passed restart persistence, task recovery, cleanup, and
application-path cross-tenant denial.

### B5 - Evaluator and recovery

`PASS - local runtime slice; durable recovery integration pending`. The gateway
now routes local capability execution through outcome/evidence/verification/
evaluation and refuses to report authoritative completion without a verifying
adapter. The evaluator requires
verified completion criteria and the recovery contract fails closed for uncertain
irreversible operations, duplicate/conflicting events, delayed terminal events,
and unconfirmed cancellation. Gateway and durable-worker integration remain open.
The current Supabase smoke runner contains a submitted-task cancellation and
post-restart recovery assertion; live execution remains blocked by the absent
DSN in the Codex process.

Current-batch evidence: Sub Agent 23 reported `5 passed in 0.38s` for the
idempotency contract. Sub Agent 25 reported `9 passed in 0.44s` for provider
receipt-correlation checks. Sub Agent 21 reported syntax compilation and
`git diff --check` for the recipe path, but its focused HTTP tests were blocked
by sandbox `WinError 10013`. These outputs are worker reports, not reruns in the
2026-11-02 checkpoint.

### B6 - Protocol and payment boundaries

The current repository supports local A2A, MCP, REST, and a limited read-only
UCP catalog contract. The local WebMCP boundary now supports registration,
invocation, and removal with exact-origin checks and fail-closed unknown-tool
handling; its focused projection/boundary suite is `22 passed in 0.66s`.
Current loopback gateway/protocol HTTP evidence is `52 passed in 3.79s`, exit 0,
using real HTTP server threads and `urllib.request.urlopen`. Actual
`document.modelContext` browser registration, public deployment, and remote
provider interoperability remain `UNVERIFIED`. UCP commerce/payment and AP2
remain fail-closed.

### B7 - Mission Control and security

The dashboard now has a read-only `/api/assurance` projection and an Assurance /
Mission Control panel. The worker report records `7 passed` for the panel and a
direct handler check for the API, while HTTP verification was blocked by
`WinError 10013`. The endpoint returns explicit `UNKNOWN` without a trusted
assurance store. Authentication, tenant isolation, CORS policy, trusted source
of truth, and execution authorization remain open.

### Current ledger checkpoint

Source revision observed: branch `codex/protocol-interoperability`, nested HEAD
`8f940d0c21c6d5fb5d19340973c5f5d24f1db58e`; working tree dirty with preserved
implementation changes. The prior `189e07c82e5f02c7e094813135e66c15c492a9db`
value is a historical source checkpoint.

Worker-reported current-batch changes:

- Recipe Assurance: `apps/gateway/app.py`, `apps/gateway/test_gateway.py`.
- Mission Control: `apps/dashboard/app.py`, `apps/dashboard/test_dashboard.py`.
- Idempotency Store: `packages/assurance-protocol/idempotency.py`, `test_idempotency.py`.
- Assurance Panel: `apps/dashboard/index.html`.
- Receipt Adapter: `packages/assurance-protocol/provider.py`, `test_provider.py`.
- Retention Contract: `db/migrations/test_migration_contract.py`.

The historical aggregate claims `403 passed` and `88 passed` are not treated as
fresh checkpoint evidence because no persisted command transcript was available.
The earlier `377 passed in 15.90s` count and any earlier `52 passed` aggregate
are historical worker evidence; the current loopback HTTP result is the separate
`52 passed in 3.79s` gateway/protocol run recorded above. Current independent
nested verification is `624 passed in 10.51s`, exit 0; it does not close
restart-safe cancellation, rollback, real provider-signed receipt authority,
real Supabase login/revocation exercise, browser interoperability, or deployment criteria.
The repository is not production-ready.

## Required handoff format for every batch

1. `COMPLETED`: changed files and observed verification output.
2. `FAILED`: exact failure and attempted correction.
3. `BLOCKED`: missing authority, environment, or external evidence.
4. `UNVERIFIED`: source exists but runtime/property was not proved.
5. Next batch and the invariant it depends on.

## Stop rule

Do not call the master prompt complete while any B1–B8 gate is missing. A
repository test pass can close only the tested repository claim; it cannot close
live database, AgentOS/Hermes, provider, deployment, or external protocol claims.
