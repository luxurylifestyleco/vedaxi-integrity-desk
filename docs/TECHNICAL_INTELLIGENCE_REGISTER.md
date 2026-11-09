# Technical Intelligence Register

Status: baseline assembled 2026-10-28; documentation and research reconciled 2026-11-09. No experiment, application code, migration, or live service was executed in this review. Later queue claims are distinguished from independently inspected source below.

E01 status: PARTIAL. Only deterministic offline self-tests and the targeted four-test contracts evaluator ran; the four-axis public/private runner baseline was not measured. E02-E06 are unexecuted.

This is the umbrella technical register for the VEDAXI/WebMCP product and its Elastic runtime. The existing execution backlog remains [.delivery/progress.md](../.delivery/progress.md) and its linked task briefs; the Master Agent owns [.codex/elastic-web-agent-queue.json](../.codex/elastic-web-agent-queue.json). Protocol authority remains [Elastic protocol adapters](../public-repos/vedaxi-elastic/docs/PROTOCOL_ADAPTERS.md); this file replaces neither authority nor backlog.

## Source map and provenance

| Surface | Source | Provenance | Status convention |
|---|---|---|---|
| VEDAXI/WebMCP product | `apps/`, `packages/`, `tests/`, `evals/` | Root `codex/webmcp-capability-projection` @ `aaadcbecc14bbd7617af6d2ae2de3998c894cc25`, rechecked 2026-11-09; dirty working tree, including this untracked register | Baseline source inspection plus scoped review below; HEAD alone does not identify the dirty source |
| Public Elastic | `public-repos/vedaxi-elastic/` | `codex/protocol-interoperability` @ `8f940d0c21c6d5fb5d19340973c5f5d24f1db58e`, rechecked 2026-11-09; dirty source and untracked additions; `uv.lock` is tracked | Scoped source inspection; later live-provider claim is queue-recorded, not independently rerun here |
| Private runtime | `.agent-workspaces/product-hardening/` | `codex/product-hardening` @ `915287d` | Source-inspected; deployment not verified here |
| Reuse proof | `.agent-workspaces/reuse-proof/` | detached @ `f987179` | Context only; not a current public release |
| Integration worktree | `.worktrees/integration-system/` | `codex/integration-system` @ `f10d64b` | Context only; not a current public release |
| Prior VDX context | Historical/private references | Exact current source lineage unresolved | Keep separate; do not promote claims |

`IMPLEMENTED` means source exists. `INTEGRATED` means source paths are connected in the inspected architecture. `VERIFIED` requires actual runtime/deployment evidence, not only test code. `PARTIAL` means a bounded slice exists. `UNVERIFIED` means the source or configuration exists but the required runtime evidence was not inspected. `PLANNED` means documented or proposed only.

Private, reuse-proof, and integration HEADs above were rechecked on 2026-11-09 and are unchanged; their capability descriptions retain the baseline inspection scope. No branch, worktree, queue, or other document was changed. The public nested `189e07c` revision remains historical UCP evidence, not current provenance.

### November 6 queue reconciliation

Read on 2026-11-09: the queue records `updated_at: 2026-11-06T14:10:00+05:30`, overall `NOT_PRODUCTION_READY`, and next gate `P0-PRODUCTION-AUTH-ADAPTER`. A queue label or test-count summary is a recorded claim, not a fresh independent verification. This review read source and metadata only; no tests, scripts, browser probes, database calls, or provider calls were run.

| Area | Recorded queue evidence | Independently observed source and remaining limit |
|---|---|---|
| Regression baseline | November 6 master rerun reports 540 Elastic Python tests, 221 root tests, and 79 focused gateway/projection tests passing | Counts were not reproduced or raw run transcripts inspected here. They do not measure the E01 four-axis baseline or complete E02-E06 |
| Chat/task durability | `P1-DURABLE-ADAPTER`, `P1-POSTGRES-DURABLE`, and `DURABLE-TENANT-BOUNDARY` report SQLite/Postgres stores and local restart/isolation tests | `packages/capability-projection/a2a.py` and `apps/gateway/app.py` contain SQLite and Postgres stores. Postgres access requires tenant context and sets transaction-local `app.tenant_id`; live restart/RLS smoke remains unverified |
| Supabase schema versus behavior | Later `P1-SUPABASE-MIGRATION-APPLY` and `P1-SUPABASE-RLS-VERIFY` report migrations 003-007 and catalog/policy verification, superseding earlier queue statements that tables were absent | Local `db/migrations/007_chat_conversation_tasks.sql` defines the three tables and forced tenant RLS. Remote schema and policies were not re-read here. `P1-SUPABASE-RUNTIME-SMOKE` remains blocked in the queue; a smoke script exists, but runtime cross-tenant denial and restart behavior are not established by catalog inspection |
| Production identity | `P0-AUTH-BOUNDARY` reports a provider-neutral adapter; `P0-PRODUCTION-AUTH-ADAPTER` remains blocked | `apps/gateway/auth.py` requires an explicit validator and fails closed; `create_app` rejects production/non-loopback configuration without a trusted adapter. Token signature/issuer/audience/expiry/revocation checks and trusted tenant/principal mapping still require a named provider contract |
| A2A lifecycle and TCK | Local task/stream/cancel work is reported. Production-profile TCK summary records 46 passed, 27 failed, 41 skipped; a separate opt-in artifact/message fixture records 5/5 | `a2a.py` has ordered local stream events and cancel methods; push configuration is explicitly unsupported. Gateway restricts the TCK fixture to non-production loopback. Neither fixture success nor local tests establishes normal-runtime or production conformance |
| Remote MCP and receipts | `P1-EXTERNAL-PROVIDER-CONFORMANCE` records a live read-only Microsoft Release Communications MCP path with 4 tools and one search, `verificationStatus=INSUFFICIENT`, `completionAuthoritative=false` | `remote_mcp.py` and `mcp_adapter.py` contain explicit-trust discovery/invocation paths. The external exchange was not rerun here, and provider receipt/signature authority remains unverified. The protocol document's older no-live-server statement predates this queue claim |
| WebMCP and deployment | Queue records local headed-Chrome AbortSignal removal and a separate blocked public deployment gate | No browser or hosting check was performed here. Local removal evidence does not establish public multi-origin deployment or end-to-end browser conformance |

Queue inconsistencies remain visible rather than being silently promoted: `LOCAL-A2A-CONFORMANCE-AUDIT` is labeled `VERIFIED` while its evidence says no final report; the TCK entry also carries an unreconciled `54/75 executed` summary; older batch/provider summaries lag the more specific later entries. These are evidence-reconciliation gaps, not permission to alter the queue or claim a new pass.

## Capability register

| Capability | Maturity | Evidence / gap |
|---|---|---|
| IntentIR and compiler | IMPLEMENTED / INTEGRATED | Public `packages/intent-ir/`; Pydantic contract, schema, deterministic compiler |
| Capability registry | IMPLEMENTED / INTEGRATED | Public `packages/capability-registry/`; registry, seed data, MCP normalization |
| Capability retrieval | IMPLEMENTED / INTEGRATED | Public `packages/capability-retrieval/`; keyword, vector, semantic-router, progressive disclosure |
| Recipe schema/store | IMPLEMENTED / INTEGRATED | Public `packages/recipe-schema/`; versioned DAG and lifecycle |
| DAG runner | IMPLEMENTED / INTEGRATED | Public `packages/recipe-runtime/runner.py`; private adaptive engine extends it |
| LangGraph coordination | IMPLEMENTED optional / UNVERIFIED durable | Public `packages/recipe-runtime/langgraph_adapter.py` wraps `RecipeDAGRunner`; caller-supplied durable checkpointer is required. No second executor or queue authority |
| Chat/task persistence | IMPLEMENTED locally / UNVERIFIED live | Public SQLite/Postgres task and session stores in `a2a.py` and gateway `app.py`; local source and November 6 queue claims are separated above |
| Decision state | IMPLEMENTED / UNVERIFIED | Private `packages/intent-ir/decision_state.py`; bounded candidates and content hash, not authorization |
| Adaptive Decision Engine | PARTIAL / UNVERIFIED | Private `packages/adaptive-recipe/engine.py`; optional durable executor and integrity hooks |
| Event Store / causal ledger | IMPLEMENTED / UNVERIFIED | Private `packages/adaptive-recipe/event_manager.py`; hash chain, metadata policy, verification, safe replay |
| Provenance graph / KGS | PARTIAL | Private `provenance_graph.py` projects verified ledger traces; no separate graph service found |
| Three-tier memory | IMPLEMENTED in-memory / PARTIAL durable | Private `memory_tiers.py`; episodic, procedural, semantic bounded KV with provenance |
| Permissions and approval | IMPLEMENTED / PARTIAL | Private `permissions.py`, `integrity_runtime.py`; durable approval pause/resume is incomplete |
| Idempotency and receipts | IMPLEMENTED privately / UNVERIFIED live | Private `apps/runtime/app.py`, `assurance_runtime.py`; internal unsigned receipt is not external proof |
| Cancellation and recovery | PARTIAL | WebMCP lifecycle abort and local A2A task/store cancellation exist; end-to-end durable cancellation, external side effects, and reconciliation remain E02/E04 work |
| Mission Control | PARTIAL | No separate service named Mission Control; closest surfaces are private runtime API and Elastic World UI |
| Scheduled product jobs | PLANNED / UNVERIFIED | Baseline found no customer-job scheduler. Repository queue/dispatcher scripts are engineering coordination, not evidence of a durable product scheduler |
| Observability | IMPLEMENTED locally / PARTIAL production | Event bus, ledger, health endpoint; no second telemetry database or OTel exporter found |

## Protocol and technology catalogue

| Technology/protocol | Current source state | Version/source note | Decision |
|---|---|---|---|
| MCP | Hand-rolled adapter/client; no SDK dependency | Remote client pins `2025-06-18`; official MCP docs checked for `2026-07-28` versioning | Reconcile by conformance experiment E04; no automatic upgrade |
| A2A | Custom adapters, discovery, local task stores, and ordered local stream events; push callbacks unsupported | Source wire version `1.0`; official release checked 2026-10-28: A2A `v1.0.1`; November 6 TCK claim remains incomplete | Keep adapter and E04; do not equate fixture success with production conformance |
| WebMCP | Browser-native registration lifecycle | Oct 27 CG draft, not a W3C Standard | Compare actual `globalThis.ModelContext` browser behavior to draft in E04 |
| UCP | IMPLEMENTED locally for an opt-in synthetic read-only catalog: projection/profile, exact-version negotiation, intent discovery, gateway handler wiring, search, and partial lookup; HTTP/live interoperability remains UNVERIFIED | Current checked UCP date version `2026-08-25`; explicit `ucp_enabled`, supported catalog operation, service endpoint, bounded inputs, and `UCP-Agent` header required; no profile fetch/auth/tenant verification | Keep synthetic flag off by default; checkout/payment/cart/order/returns remain unsupported; production requires profile/signature/auth/tenant and real HTTP evidence |
| A2UI | Research-only; no adoption established in the inspected manifests | Official index and v1.0 specification checked 2026-11-09 both say Current; specification last updated 2026-06-08 | Evaluate only as a typed UI projection within E06; pin schema/renderer compatibility before any adoption; no execution or approval authority |
| AG-UI | Research-only; no adoption established in the inspected manifests | Official client/state docs and Pydantic AI integration checked 2026-11-09; cancellation behavior is adapter/version-specific | Add cancel versus disconnect/reconnect cases to E02/E04 planning; do not add a transport or service merely to obtain those tests |
| LangGraph | Optional local adapter and declared orchestration extra | `pyproject.toml` declares `langgraph>=1.2.19`; tracked `uv.lock` resolves `1.2.19`; installed environment was not inspected | Retain existing runner authority; checkpointer/source presence is not durable-recovery proof |
| Temporal | Not installed | Latest checked `1.32.1`; durable replay/worker model; MCP activities may repeat side effects | DEFER; evaluate only if E02 shows current runtime cannot meet recovery/approval requirements |
| Dapr | Not installed | `1.19` checked; sidecar/runtime infrastructure; fast-path is preview, and MCP/vector features are alpha/preview areas | DEFER absent measured portability or duplicate-integration gap |
| Istio/Linkerd/SPIRE | Not installed | Exact current patch not established for mesh options; SPIRE `1.15.5` checked | DEFER; mesh cannot enforce business arguments or approval |
| OAuth | Private controls plus public provider-neutral bearer scaffold; no production provider mapping established | RFC 9700 is the security baseline; parsing a bearer string is not token or tenant validation | Keep production auth gate blocked; test scopes, audience, tenant, and task ownership in E03 |
| Routing | Fixed/in-process routing and benchmark controls exist | TwinRouterBench v5 and related papers are watch-only; RouteLLM is a heavy optional candidate | Measure matched workload in E05 before adopting a router |
| Cache | No business result cache identified | Prompt caching is not authorization/result reuse | Design exact-result reuse with tenant/principal/scope/capability/input/data/policy binding in E05 |
| Deployment | Render configuration exists privately | Source shows Render, not Railway | Do not add Railway; audit Supabase dependence before self-hosting claims |
| Payments | No authority granted | AP2 is an agent authorization-mandate protocol; x402 V2 is a payment verification/settlement protocol; budget/session management is outside x402 core | DEFER real payments; fake settlement only if separately authorized |
| Telemetry | Local event/ledger model | OpenTelemetry GenAI semantic conventions are the candidate standard | Pin schema before exporting; do not add a second telemetry database |

## Advisory register

No MCP SDK package is declared or resolved in inspected Node/Python manifests or lockfiles. Current MCP/WebMCP paths are custom or browser-native.

| Advisory | Current applicability | Required trigger for re-review |
|---|---|---|
| GHSA-jm63-cq47-j5jp | No TypeScript MCP SDK/shared HTTP transport found | Adding official TypeScript SDK HTTP server/transport helpers |
| GHSA-rvq5-wwqv-78pq | No MCP SDK bearer/resource helper found; custom Supabase/Flask auth is not thereby proven safe | Adding MCP OAuth/resource-server validation |
| GHSA-hvrp-rf83-w775 | No Python MCP SDK or experimental task API found | Adding Python MCP task APIs |

These are conditional advisories, not vulnerability findings.

## Research source catalogue

Baseline research rows retain their 2026-10-28 check date; the UCP implementation evidence is dated 2026-10-31. New rows explicitly marked 2026-11-09 were checked in this review; older version claims were not refreshed wholesale. Next weekly research target: 2026-11-16; architecture: 2026-11-28; security: when dependency/protocol state changes. Unless overridden below: owner is unassigned, maintenance status is unknown, production suitability is unverified, cost is unknown, and compatibility must be measured before adoption.

| Source | Checked fact | License/maintenance/dependency/run-model note | Decision and reconsider trigger |
|---|---|---|---|
| [MCP versioning](https://modelcontextprotocol.io/docs/2026-07-28/learn/versioning) | Official versioning page is dated/current for `2026-07-28`; negotiation and backward compatibility are documented | Protocol source; SDK/license applicability unknown because no SDK is installed | Keep hand-rolled `2025-06-18` client until E04 measures negotiation; reconsider on failed compatibility evidence |
| [A2A releases](https://github.com/a2aproject/A2A/releases) | Release checked: `v1.0.1`; source wire version is `1.0` | Apache-2.0 project; current maintenance beyond checked release unknown; custom adapter has no SDK dependency | Keep adapter; reconsider if E04 finds reconnect/cancel incompatibility |
| [WebMCP draft](https://webmachinelearning.github.io/webmcp/) | Oct 27 CG draft; not a W3C Standard | Browser-native API; browser implementation/version is unknown until observed | Keep native lifecycle; reconsider on browser conformance failure in E04 |
| [UCP official specification](https://ucp.dev/specification/overview/) | Current checked profile/version model uses date version `2026-08-25`; profiles require `services`, `capabilities` when used, and `payment_handlers`; exact protocol/capability negotiation is separate | Public specification; no UCP SDK or live commerce service is installed; current implementation is catalog projection/profile logic only | Keep catalog-only fail-closed slice; reconsider checkout/payment/cart/order only after separate transport, auth, idempotency, and synthetic end-to-end evidence |
| [Temporal releases](https://github.com/temporalio/temporal/releases), [workflow execution](https://docs.temporal.io/workflow-execution), [self-hosting](https://docs.temporal.io/self-hosted-guide), [MCP integration](https://docs.temporal.io/develop/python/integrations/mcp) | Latest checked `1.32.1`; durable replay requires service/workers/persistence; MCP activities may repeat side effects and timeout does not cancel external work | MIT; adds service/worker/persistence operational dependencies; cost unknown | DEFER; reconsider only if E02 fails current recovery/approval requirements |
| [Dapr 1.19](https://blog.dapr.io/posts/2026/10/22/dapr-v1.19-is-now-available/), [no-Docker hosting](https://docs.dapr.io/operations/hosting/self-hosted/self-hosted-no-docker/) | `1.19` checked; sidecar runtime can run without Docker but is not dependency-free; fast-path is preview and MCP/vector features are alpha/preview areas | Apache-2.0; adds sidecars and operational dependencies; those preview features are not required | DEFER; reconsider only for measured portability or duplicate-integration gap |
| [Istio](https://istio.io/latest/docs/overview/what-is-istio/), [Linkerd](https://linkerd.io/2-edge/overview/), [SPIRE 1.15.5](https://github.com/spiffe/spire/releases/tag/v1.15.5) | Mesh/SPIFFE options reviewed; exact Istio/Linkerd patch not verified | Licenses/maintenance vary by project; adds mesh/identity operations; cannot enforce business arguments or approvals | DEFER; reconsider only for a measured network identity requirement |
| [RFC 9700](https://www.rfc-editor.org/rfc/rfc9700.html) | OAuth security baseline for scopes/audience and resource protection | Standards source; implementation dependency is current Supabase/Flask auth | Use E03 before auth infrastructure expansion; reconsider on boundary failure |
| [TwinRouterBench v5](https://arxiv.org/abs/2605.18859), [router critique](https://arxiv.org/abs/2610.02762), [RouteLLM](https://github.com/lm-sys/RouteLLM/blob/main/pyproject.toml), [AgentRouter](https://arxiv.org/abs/2609.22951) | Research checked; no Elastic benefit measured | RouteLLM introduces heavyweight torch/transformers; license/runtime cost must be verified before use | E05 only; reconsider on measured token/latency win |
| [Prompt caching](https://developers.openai.com/api/docs/guides/prompt-caching) | Provider prompt cache is not business authorization/result reuse | Provider behavior; no local cache dependency | Design exact reuse in E05; reconsider only with bound identity and reauthorization |
| [AP2 v0.2.0](https://github.com/google-agentic-commerce/AP2/releases/tag/v0.2.0), [authorization](https://ap2-protocol.org/ap2/agent_authorization/), [security](https://ap2-protocol.org/ap2/security_and_privacy_considerations/) | AP2 is an agent authorization mandate protocol, not settlement authority; release year is not asserted | Apache-2.0; payment/provider dependencies unknown; no authority granted | DEFER real payments; reconsider only after explicit payment authorization |
| [x402 V2 specification](https://github.com/x402-foundation/x402/blob/main/specs/x402-specification-v2.md) | x402 is a payment verification/settlement protocol; budget/session management is outside x402 core | Apache-2.0; provider/network/token support unknown; do not assume USDT support | DEFER real payments; fake settlement only if authorized |
| [PostgreSQL pg_dump](https://www.postgresql.org/docs/current/app-pgdump.html), [Supabase self-hosting](https://supabase.com/docs/guides/self-hosting) | `pg_dump` is portable export, not complete DR; self-hosting adds services/ops | Existing Postgres/Supabase dependency; backup/restore cost and RPO/RTO unknown | Audit actual Supabase dependence before deployment change |
| [OpenTelemetry GenAI conventions](https://opentelemetry.io/docs/specs/semconv/gen-ai/) | Candidate telemetry schema | No exporter or second database installed; schema/version pin unknown | Reconsider after E01/E02 identify fields; do not add a second telemetry database |
| [A2UI official index](https://a2ui.org/), [v1.0 specification](https://github.com/a2ui-project/a2ui/blob/main/specification/v1_0/docs/a2ui_protocol.md) | Checked 2026-11-09: both identify v1.0 as Current; specification last updated 2026-06-08. Older cached Candidate descriptions are not the current checked source | Specification status does not establish renderer/package compatibility or Elastic integration; license and dependency review required before adoption | E06 candidate only: compare typed projection against the same prompt-first path; no new orchestration authority |
| [AG-UI client](https://docs.ag-ui.com/sdk/js/client/abstract-agent), [state](https://docs.ag-ui.com/concepts/state), [Pydantic AI AG-UI integration](https://pydantic.dev/docs/ai/integrations/ui/ag-ui/) | Checked 2026-11-09; pages are undated. Client exposes abort; state docs describe snapshots/deltas. Pydantic AI distinguishes first-party cancellation from disconnect: disconnect does not fire its `RUN_FINISHED` or `on_cancel` | The latter is an adapter-specific behavior, not a universal guarantee. No AG-UI dependency or runtime was introduced | Use as E02/E04 test design: user cancel, disconnect, reconnect/resync, duplicate/late events, and persisted outcome reconciliation; no adoption claim |
| [Agent Memory as Rate-Limited Filtering](https://arxiv.org/abs/2611.02361) | v1 submitted 2026-11-02; checked 2026-11-09. Controlled access-log experiments compare explicit ordered state and long-history readers; results depend on reader and task | Research preprint, not Elastic evidence; no package, infrastructure, cost, or latency benefit established here | Refine E02/E03 with explicit grant/revoke/expiry/reinstatement and revision state; compare against history-only decisions before adopting a memory system |
| [One Assistant, Many Memories / GroupAssistBench](https://arxiv.org/abs/2611.04867) | v1 submitted 2026-11-03; checked 2026-11-09. Separates memory recall from appropriate assistance across single, distributed, and conflicting histories | Research benchmark; its results do not transfer automatically to Elastic; no new memory store justified | Refine E01/E06 scoring for correct use of source-bound facts, revisions, and conflicts, not recall alone |
| [The Devil is in the Context](https://arxiv.org/abs/2611.04672), [taxonomy and persistent-state discussion](https://arxiv.org/html/2611.04672v1) | v1 submitted 2026-11-03; checked 2026-11-09. Nine-dimension taxonomy distinguishes persistent state modification and delayed activation from same-session influence | Threat-model/test-design source, not a vulnerability finding or proof of protection; memory writes and later reuse need separate coverage | Extend E03 planning with untrusted-content-to-memory poisoning, conditional later-session activation, provenance retention, and revocation tests; no new security infrastructure |

## Baseline correction notes

- The VDX dashboard receipt validator recomputes and compares SHA-256 of its canonical safe projection (`testId`, `transport`, `outcome`, `checkedAt`, `assertions`).
- That VDX receipt is unsigned and does not prove that a probe ran or that an external outcome occurred. The separate private Elastic assurance runtime has its own run/ledger evidence path; do not conflate the two.
- The historical settled-key adapter defect is unknown/unverified against current source; it must not be reported as a current defect.

## Scorecard and guardrails

Every experiment must record:

1. Tokens per successful task, including failed/retried attempts.
2. End-to-end latency, using p50/p95 rather than an invented promise.
3. Execution steps, setup steps, and user actions.
4. Accepted task coverage and usability.

Reliability/security hard gates: no duplicate synthetic side effects, no lost run, uncertain outcomes reconcile, zero cross-tenant reuse/leakage, exact audience/tenant/task ownership, no speculative writes, bounded prefetch cost/concurrency/TTL, explicit approval/revocation, and rollback by feature flag or isolated-state discard.

## Experiment backlog

These retain their original scope and status: E01 is PARTIAL; E02-E06 are unexecuted. Queue regression and conformance claims above are not automatically experiment completions:

- **E01 — Immutable baseline corpus:** matched workloads; tokens, p50/p95, steps/actions, accepted coverage, failure/retry accounting.
- **E02 — Runner fault matrix:** crash before dispatch, after provider success/before write, concurrent duplicate, DB failure, approval expiry/revocation/restart, cancellation/version change.
- **E03 — Tenant and audience matrix:** two tenants across auth, task ownership, read/cancel/artifact, omitted filters, wrong audience; zero leakage.
- **E04 — Protocol conformance:** MCP version negotiation, A2A v1 flow/reconnect/cancel, WebMCP registration/invocation/abort/navigation/fallback.
- **E05 — Exact reuse and routing:** bound cache identity and cost-matched routing against the same workload; no new services.
- **E06 — Prompt onboarding:** one prompt-first customer path; measure actions and verified outcome before considering drag/drop.

Research refinements proposed 2026-11-09, within the existing experiments only: E02/E03 should compare explicit current revision/authorization state against ordered history and cover stale or revoked memory; E03 should include persistent poisoning that activates in a later session; E02/E04 should distinguish user cancellation from connection loss and reconcile state after reconnect; E01/E06 should score appropriate use of conflicting/revised facts as well as recall. An A2UI projection is only a candidate E06 comparison. None of these cases was executed, and no measured token, latency, usability, security, or infrastructure benefit is claimed.

See [owner brief](TECHNICAL_INTELLIGENCE_OWNER_BRIEF.md) and [engineering brief](TECHNICAL_INTELLIGENCE_ENGINEERING_BRIEF.md).

Bounded E01 evidence is recorded in [.delivery/E01_BASELINE_EVIDENCE.md](../.delivery/E01_BASELINE_EVIDENCE.md). E01 remains PARTIAL: it covers only deterministic offline checks; the full public/private runner baseline remains open. E02-E06 are unexecuted.

Final UCP implementation evidence is recorded in [.delivery/E01_BASELINE_EVIDENCE.md](../.delivery/E01_BASELINE_EVIDENCE.md) and the reproducible non-socket script [.delivery/ucp_regression_assertions.py](../.delivery/ucp_regression_assertions.py). The nested protocol authority remains [PROTOCOL_ADAPTERS.md](../public-repos/vedaxi-elastic/docs/PROTOCOL_ADAPTERS.md). This is not full UCP conformance or production readiness.

## Review cadence and watch status

- Historical run history check: 2026-10-28, when three enabled review schedules were reported. This 2026-11-09 run maintains this register only; it does not authorize application execution or engineering dispatch. Current schedule enablement was not rechecked in this documentation review.
- Daily security review: starts 2026-10-29, around 09:00 Asia/Kolkata, flexible within one hour.
- Weekly research review: Mondays, starts 2026-11-02, around 09:00 Asia/Kolkata, flexible within one hour.
- Monthly architecture review: 28th of each month, starts 2026-11-28, around 09:00 Asia/Kolkata, flexible within one hour.
- Incident/release connectivity was not rechecked here; the historical check did not establish a connected incident/release source. Do not claim event-driven monitoring from repository configuration.
- Research review completed: 2026-11-09. Next weekly target: 2026-11-16.
- Architecture review target: 2026-11-28.
- Security review target: daily when dependency/protocol changes occur.
- Existing watch workflow: `.github/workflows/protocol-standards-watch.yml`.
- Watch output is currently console-only; local config does not prove the workflow is enabled or pushed.
- Deduplicate future verified watch output against this register and the existing protocol authority; do not add another repository cron or monitor.

## Coverage questions

The initial baseline answers these twelve questions at source level and marks runtime gaps explicitly:

1. What is the canonical intent representation and where is it compiled?
2. How are capabilities registered, retrieved, disclosed, and ranked?
3. Which path executes a known recipe, and where is the DAG runner?
4. Where does Decision Engine logic live, and what is actually durable?
5. What is the source of truth for Mission Control/user-visible execution state?
6. Is the Event Store/causal ledger append-only, hash-linked, verifiable, and replayable?
7. What memory tiers exist, what provenance is required, and what persists?
8. How are Supabase/Postgres, authentication, tenants, API keys, and organization scope connected?
9. Are scheduled jobs, workers, cancellation, retries, recovery, and approval pauses implemented?
10. Which protocols and SDKs are installed, resolved, projected, or only hand-rolled?
11. What deployment/export profiles exist, and which claims are source-only versus runtime-verified?
12. What are the current capability gaps, scorecard metrics, security gates, and first isolated experiments?

## Campaign questions and direct answers

1. **Temporal durability:** Temporal would provide durable workflow replay through a service, workers, and persistence, but activities can repeat side effects and timeout does not cancel external MCP work. The current system should first run E02; Temporal is deferred unless current recovery/approval semantics fail.
2. **Dapr increment:** Dapr could add sidecar portability and standard building blocks. Its fast-path is preview, while MCP/vector features are alpha/preview areas; it also adds runtime operations. No measured gap justifies it; defer pending E02/E05 evidence.
3. **Mesh necessity:** No measured requirement currently justifies adding Istio, Linkerd, or SPIRE. Mesh identity cannot enforce tool arguments, tenant scope, or approval policy; use existing TLS/app policy first.
4. **Actual protocols E2E:** MCP remains hand-rolled and pinned to `2025-06-18`; A2A custom adapter speaks wire `1.0`; WebMCP uses browser-native `ModelContext`; UCP remains a synthetic catalog/profile slice. The November 6 queue records bounded live MCP and local/TCK evidence with the limits above. E04 is still unexecuted and full conformance is not claimed.
5. **Auth boundaries:** Private source has Supabase/bearer controls. Public source now includes a provider-neutral bearer scaffold and tenant-bound Postgres queries, but production identity mapping and live restart/RLS smoke remain open gates. E03 must still test scope, audience, tenant, task ownership, and wrong-principal reads/cancels.
6. **Data responsibilities:** Publishers own source evidence; Elastic owns capability/recipe/runtime metadata; Postgres/Supabase owns private durable runs and ledgers; providers own external results. Receipts bind internal evidence but do not prove external truth.
7. **Routing/cache/prefetch:** Use fixed/in-process routing first. Exact reuse must bind tenant, principal, scope, capability, input, data version, and policy version, then reauthorize. Prefetch must be bounded and read-only; E05 measures whether complexity pays back.
8. **Deployment choices:** Current source shows Render plus Postgres/Supabase. Shared SaaS needs HTTPS; dedicated deployments can reuse app/database; customer-managed plain process plus PostgreSQL/existing IdP is a candidate. Railway and full self-host Supabase are not justified now.
9. **Emerging research:** Routing remains watch-only. The November 9 additions prioritize explicit revision state, appropriate memory use, cross-session poisoning coverage, and cancellation/disconnect distinctions within E01-E06. A2UI/AG-UI are evaluation candidates, not adopted infrastructure; no paper result is Elastic production proof.
10. **Payments relevance:** AP2 concerns agent authorization mandates; x402 concerns payment verification/settlement. Neither grants payment authority here; budget/session handling is outside x402 core. Real payments remain deferred.
11. **Demonstrate today vs concepts:** Source-backed demonstration candidates are local/public Elastic capability discovery, recipe/DAG execution, custom A2A/MCP/WebMCP projection, and private-source durable-runtime code. No runtime demonstration was executed or verified in this audit. Temporal/Dapr/mesh/routing/cache/payments are concepts or deferred options, not delivered capabilities.
12. **Highest-value improvements:** First measure successful-task tokens, p50/p95 latency, execution/user steps, and accepted coverage; then harden duplicate prevention, uncertain-outcome reconciliation, tenant isolation, protocol conformance, and prompt-first onboarding through E01-E06.
