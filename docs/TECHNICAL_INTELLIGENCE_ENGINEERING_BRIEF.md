# Technical Intelligence Engineering Brief

Baseline date: 2026-10-28. Documentation-only planning with a PARTIAL E01 offline baseline; E02-E06 have not run.

E01 execution status: claim-integrity and hard-quality self-tests passed, and the targeted contracts evaluator passed 4/4 tests. The four-axis public/private runner baseline (tokens per successful task, p50/p95 E2E latency, execution/setup/user steps, accepted coverage) was not measured.

## Existing implementation surfaces

| Surface | Paths | Current reading |
|---|---|---|
| Intent/capability | `public-repos/vedaxi-elastic/packages/intent-ir/`, `capability-registry/`, `capability-retrieval/` | Implemented and integrated source |
| Recipes/DAG | `public-repos/vedaxi-elastic/packages/recipe-schema/`, `recipe-runtime/` | Local/in-memory public execution |
| Protocol projection | `public-repos/vedaxi-elastic/packages/capability-projection/` | A2A/MCP/WebMCP/UCP adapters; no SDK dependency |
| Native WebMCP | `packages/contracts/src/webmcp.ts`, `apps/paper/src/paper/use-paper-registration.ts`, `apps/video/src/video/use-video-registration.ts` | Browser-native lifecycle and abort path |
| Durable runtime | `.agent-workspaces/product-hardening/apps/runtime/`, `packages/adaptive-recipe/` | Postgres/Supabase, tenant controls, receipts, ledger, replay source exists; deployment unverified |
| Existing backlog | `.delivery/` | Use as the only execution queue |

## Experiment contracts

### E01 — Immutable baseline corpus

Run the same synthetic workload through public and private runners separately. Record tokens per successful task, p50/p95 E2E latency, execution/setup/user steps, accepted task coverage, failures, retries, and provider calls. Freeze acceptance thresholds before observing results.

### E02 — Fault matrix

Inject failures at dispatch, provider success before persistence, duplicate concurrency, database failure, approval expiry/revocation, restart, cancellation, and version change. Required outcomes: no duplicate synthetic side effect, no lost run, explicit uncertain state, and safe reconciliation. Compare public and private paths; do not blend evidence.

### E03 — Tenant/audience/task ownership

Use two synthetic tenants and wrong/missing audience, task, artifact, cancel, and filter inputs. Required outcome: zero leakage and zero unauthorized mutation. This is the first security gate before any auth infrastructure expansion.

### E04 — Protocol conformance

Record MCP version negotiation against the official current versioning model, A2A wire v1 flow/reconnect/cancel, and actual browser WebMCP registration/invocation/abort/navigation behavior. The current remote client’s `2025-06-18` pin is a compatibility gap to track, not an automatic upgrade instruction.

### E05 — Exact reuse/routing

Prototype only with existing storage. Cache identity must bind tenant, principal, scope, capability, input, data version, and policy version; reauthorize on consumption. Prefetch must have bounded cost/concurrency/TTL and must never speculate writes. Compare fixed routing, in-process rules, and a cost-matched two-model baseline.

### E06 — Prompt onboarding

Measure one prompt-first request from entry to verified result. Count user actions, setup actions, approvals, and failure recovery. Consider drag/drop only if the measured workflow exposes a real capability-discovery/usability gap.

## Experiment matrix

All experiments are **PROPOSED / NOT RUN**. No results, thresholds, or production guarantees should be inferred.

| ID | Affected components | Dependencies | Alternatives compared | Metrics and acceptance | Rollback |
|---|---|---|---|---|---|
| E01 | Public `recipe-runtime`; private `adaptive-recipe/engine.py`; telemetry | Frozen synthetic corpus and identical task definitions | Public runner vs private runner; fixed route vs recipe | Tokens/success, p50/p95 E2E, execution/setup/user steps, accepted coverage, failures/retries; accept only after thresholds are frozen before runs | Isolated benchmark state; discard reports; no production writes |
| E02 | DAG runner, durable executor, `event_manager.py`, provider adapter, Postgres trace store | Fault injection seams and synthetic side-effect counter | Current public path vs private durable path; retry vs reconcile | Zero duplicate synthetic side effects, zero lost runs, explicit uncertain state, successful restart/approval recovery | Feature flag and isolated database/schema; discard synthetic traces |
| E03 | Supabase/Flask auth, tenant pool, run/detail/cancel/artifact routes, receipt access | Two synthetic tenants and controlled wrong-audience/task inputs | Existing auth boundary vs proposed policy checks | Zero cross-tenant reads, writes, artifact leaks, wrong-principal cancels, or omitted-filter expansion | Synthetic tenants only; revoke test keys and delete isolated data |
| E04 | Remote MCP client, A2A adapter/discovery, WebMCP browser registration | Current official protocol references, supported browser, capture harness | Current hand-rolled versions vs negotiated/current protocol behavior | Successful list/call, reconnect/cancel, registration/invocation/abort/navigation, truthful fallback; no unsupported claim without evidence | No dependency upgrade; revert isolated compatibility branch or discard captures |
| E05 | Retrieval/routing, existing storage, future exact-result cache boundary | E01 corpus and explicit identity/policy version fields | Fixed route, small in-process rules, cost-matched two-model baseline, no-cache vs exact reuse | Tokens/success, p50/p95, cache-hit correctness, reauthorization, prefetch cost/concurrency/TTL, no cross-tenant reuse; adopt only on measured win | Feature flag; discard cache namespace and benchmark state |
| E06 | Prompt onboarding UI, capability discovery, approval/receipt presentation | One safe read-only capability and verified receipt path | Prompt-first vs any proposed drag/drop flow | User actions, setup actions, approval count, completion rate, recovery clarity; no drag/drop unless it reduces measured friction | Hide behind UI flag; retain existing prompt path |

## Guardrails

- No production side effects or real payment authority.
- No new paid service or infrastructure dependency.
- No Redis/cache service by default.
- No framework migration from the current Render/Postgres/Supabase source without measured need.
- No automatic MCP SDK adoption; current source has no SDK package and uses custom/browser-native paths.
- No vulnerability claim from advisory/version alone.
- Every result must retain source path, commit/worktree provenance, exact command, fixture scope, acceptance result, and rollback/discard method.

## Protocol/security notes

The existing protocol register is [PROTOCOL_ADAPTERS.md](../public-repos/vedaxi-elastic/docs/PROTOCOL_ADAPTERS.md). The standards watcher is configured in `.github/workflows/protocol-standards-watch.yml` and `scripts/watch-protocol-standards.mjs`, but its local untracked state and console-only output do not prove it is enabled or producing durable evidence.

Current MCP advisory state is conditional: no affected TypeScript/Python SDK is resolved, no SDK helper is called, and custom auth remains separately unverified. Re-review if official SDK HTTP, bearer/resource, or experimental task APIs are introduced.

The VDX dashboard receipt validator recomputes and compares SHA-256 of its canonical safe projection (`testId`, `transport`, `outcome`, `checkedAt`, `assertions`). That receipt is unsigned and does not prove that a probe ran or that an external outcome occurred. The separate private Elastic assurance runtime has its own run/ledger evidence path; do not conflate the two. The historical settled-key adapter defect remains unknown/unverified against current source.

## Run-history and monitor boundary

Run history was checked on 2026-10-28. Future verified findings from the enabled read-only schedules must update this register and link to the existing protocol authority or experiment evidence. The local standards-watch workflow remains untracked and its GitHub Actions execution is unproven; it is not a second active monitor. No additional repository scheduler or incident integration was configured; reuse existing mechanisms and verify supported event access before future setup.
