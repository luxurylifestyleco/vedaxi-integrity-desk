# IntentIR + Elastic Web Audit

Date: 2026-11-09  
Owner: `Master Agent // Intentir Architecture`  
Status: local P0/P1 implementation slices reconciled; live identity, database, provider, browser, and deployment gates remain blocked or unverified.

## Executive assessment

The repository already contains a working local intent-to-capability path:

`natural language -> IntentIR -> capability registry/retrieval -> recipe DAG -> execution -> telemetry/assurance`

The system is useful as an offline/public-repository prototype. It is not production-ready because durable runtime, live provider proof, browser proof, and deployment evidence are separate gates. Adding another orchestrator, marketplace, database, or ML router would increase complexity without closing the current gaps.

The highest-value foundation gap was the IntentIR boundary itself. Before this change, the model represented a parsed goal but did not make the original expression, lifecycle state, preferences, unresolved information, or fulfillment state first-class. That made refinement and assurance dependent on free-form metadata. The smallest justified correction is additive: IntentIR schema version `1.1` with those fields defaulted for existing callers.

## Evidence map

| Area | Status | Evidence | Meaning |
|---|---|---|---|
| IntentIR model and validation | IMPLEMENTED / extended | `packages/intent-ir/intent_ir.py:19-130`; `test_intent_ir.py` | Pydantic contract with strict extra-field rejection and bounded confidence. New additive lifecycle/provenance fields are implemented and tested. |
| Intent compilation | PROTOTYPE | `packages/intent-ir/compiler.py:103-187`; compiler tests | Deterministic rule-based compiler supports a small document/commerce vocabulary. It is not general intent understanding. |
| Capability contract | PARTIAL | `packages/capability-registry/capability.py:25-115`; registry tests | Inputs, outputs, permissions, provider, protocol, endpoint, cost, latency, and historical success are represented. Preconditions/postconditions and trust are not normalized. |
| Capability registry | PROTOTYPE | `packages/capability-registry/registry.py:22-106` | In-memory, substring search, and duplicate registration replacement are local behavior; no durable tenant-aware source of truth. |
| Capability discovery | IMPLEMENTED locally / PARTIAL external | `packages/capability-registry/mcp_adapter.py`; `capability-registry/api_discovery.py`; `capability-projection/discovery.py` and focused tests | Local registry/MCP/A2A/WebMCP plus fixture-backed OpenAPI 3.x and AsyncAPI 2.x/3.x ingestion are implemented. A trusted synthetic remote-MCP path reaches the existing runtime. Live external discovery remains unverified. |
| Retrieval/ranking | IMPLEMENTED locally / DEFER learned ranking | `packages/capability-retrieval/retriever.py`; retrieval tests | Deterministic suitability filtering now rejects missing inputs, permission mismatches, and protocol mismatches before ranking. No measured learned-ranking path is required yet. |
| Recipes | IMPLEMENTED locally | `packages/recipe-schema/recipe.py`; `packages/recipe-runtime/runner.py`; authority tests | Versioned lifecycle and DAG validation/execution exist; `RecipeDAGRunner` is the execution authority. Automatic composition/optimization is explicitly not implemented. |
| Execution | IMPLEMENTED locally / PARTIAL external | `packages/recipe-runtime/runner.py`; `apps/gateway/app.py` | Local execution, dependency order, checkpoints, telemetry, and trusted synthetic MCP bridging exist. Provider-authoritative completion and live provider execution remain unverified. |
| Assurance/evidence | IMPLEMENTED locally / PARTIAL durable | `packages/assurance-protocol/outcome.py:74-190`; assurance tests; `db/migrations/004-006` | Outcome lifecycle, append-only in-memory ledger, verification, authorization, and idempotency contracts exist. Live Postgres/RLS/retention remains a gate. |
| Authorization | IMPLEMENTED locally / BLOCKED production | `packages/assurance-protocol/authorization.py`; `apps/gateway/auth.py`; authorization and gateway tests | Local authorization, bearer validation boundary, tenant/session ownership, and non-loopback fail-closed behavior pass. Production identity-provider validation and real tenant/principal mapping remain unavailable. Gateway remains loopback/demo-only by default. |
| Durable chat/task state | IMPLEMENTED locally / UNVERIFIED live | `db/migrations/007_chat_conversation_tasks.sql`; `apps/gateway/app.py`; `packages/capability-projection/a2a.py`; focused tests | Opt-in SQLite stores are restart-safe locally; Postgres stores are DSN-gated and locally fake-backed. Live restart-safe cancellation, direct restricted-role RLS checks, and rollback acceptance were not executed. |
| Protocol interoperability | IMPLEMENTED locally / PARTIAL external | `capability-projection/a2a.py`; `apps/gateway/app.py`; `capability-registry/mcp_adapter.py`; `api_discovery.py`; `webmcp_boundary.py` | Local A2A JSON-RPC/HTTP+JSON, MCP, WebMCP, OpenAPI, and AsyncAPI paths are tested. Normal-runtime official TCK and live browser/provider interoperability remain unproven. |

## IntentIR recommendation

### Minimal contract

Required semantic core remains `goal`, `domain`, `action`, `object`, `desired_output`, constraints, authority, disclosure, success conditions, confidence, and metadata. The new fields are deliberately optional at the JSON Schema boundary for compatibility:

- `schema_version`: contract version, default `1.1`.
- `original_expression`: source expression, without silently treating interpretation as fact.
- `state`: `UNCLEAR`, `DISCOVERY`, `FORMED`, `EXECUTING`, `FULFILLED`, `FAILED`, or `CANCELLED`.
- `preferences`: non-mandatory ranking signals, separate from hard constraints.
- `uncertainty`: unresolved fields and clarification requirements.
- `fulfillment`: result/assurance state; invocation success is not fulfillment proof.

This is intentionally not a psychology model, policy engine, or second lifecycle authority. The existing assurance protocol remains authoritative for durable outcome state and evidence.

### Lifecycle

Use the small IntentIR formation lifecycle for representation (`UNCLEAR -> DISCOVERY -> FORMED -> EXECUTING`) and the existing assurance lifecycle for execution/result states. Do not duplicate the full `OutcomeStatus` graph inside IntentIR.

### Direct implementation evidence

Changed files:

- `public-repos/vedaxi-elastic/packages/intent-ir/intent_ir.py`
- `public-repos/vedaxi-elastic/packages/intent-ir/compiler.py`
- `public-repos/vedaxi-elastic/packages/intent-ir/schema.json`
- `public-repos/vedaxi-elastic/packages/intent-ir/test_intent_ir.py`

Verification: `uv run pytest packages/intent-ir -q` -> `37 passed`.

## Elastic Web recommendation

Keep the existing responsibilities:

1. Validate the IntentIR boundary.
2. Retrieve candidates from existing registries/adapters.
3. Reject candidates that fail hard requirements.
4. Select or resolve an existing recipe.
5. Execute through the existing DAG/runtime boundary.
6. Verify the outcome using evidence and assurance contracts.

The next implementation priority is not learned ranking. It is a deterministic suitability gate that checks capability permissions, protocol, required inputs, and explicit constraints before ranking by relevance/cost/latency. This can reuse the current `Capability`, `CapabilityRetriever`, and `RecipeStore` types.

## Independent security and execution gaps

- The gateway's local execution routes do not authenticate callers or resolve tenant/principal from credentials. The code binds the default server to loopback and the README disclaims production OAuth/signature/tenant authorization; it must not be exposed as a production gateway.
- A2A inbound handling reaches the local executor without transport authentication. Keep it loopback/demo-only until an authenticated inbound principal is wired through the existing authorization contract.
- `REQUIRE_APPROVAL` is represented in outcome data but is not an end-to-end gateway enforcement path. Do not transition to `AUTHORIZED` from request data alone.
- Idempotency primitives exist, but gateway side-effecting routes do not require or enforce an idempotency key.
- Remote MCP discovery/invocation is not connected to the canonical gateway runtime; discovered external capabilities cannot yet flow through provider execution and authoritative evidence.

These are separate issues. Fixing IntentIR provenance does not fix transport authorization, and adding a ranker does not fix external execution or evidence.

## Standards adoption matrix

| Standard | Relevant requirement | Current state | Decision |
|---|---|---|---|
| RFC 9315 | Intent is declarative; refinement, fulfillment, assurance, lifecycle, and drift are distinct concerns. | Applied conceptually; not a protocol implementation. | ADAPT selectively; use source preservation, uncertainty, refinement, and assurance boundaries. |
| RFC 9316 | Intent is operational goals/outcomes, not lower-level implementation instructions. | Compatible with current model. | REUSE as semantic guardrail. |
| RFC 9417 | Assurance architecture and compliance assessment. | Existing assurance contracts are local adaptation. | ADAPT; do not claim RFC compliance. |
| A2A | Agent cards describe capabilities/auth; tasks have states, messages, and artifacts. | Custom adapter/projection exists. | ADAPT; keep A2A for agent/task coordination, not tool discovery. |
| MCP | Tools expose schemas; lifecycle and authorization are protocol concerns. | Custom adapter exists; SDK is not installed. | ADAPT current adapter; run conformance before changing version. |
| WebMCP | Browser-native structured tool registration/invocation with schema validation and lifecycle. | Native projection/lifecycle code exists. | INTEGRATE only at browser boundary; current maturity is draft/experimental. |
| OpenAPI | Machine-readable HTTP operations and schemas. | Fixture-backed `APIDiscoveryAdapter` supports OpenAPI 3.x locally. | REUSE locally; defer live provider conformance until authorized. |
| JSON Schema | Portable validation/evolution contract. | IntentIR and assurance schemas use it. | REUSE. |
| AsyncAPI | Event/channel/message descriptions for event-driven APIs. | Fixture-backed `APIDiscoveryAdapter` supports AsyncAPI 2.x/3.x locally. | REUSE locally; defer live provider conformance until authorized. |
| RFC 9700 | OAuth token, audience, scope, and resource protection hardening. | Local bearer/authorization controls exist. | ADAPT and verify with tenant/audience matrix before adding auth infrastructure. |
| OpenTelemetry | Correlated traces, events, metrics, and context propagation. | Local telemetry/event bus exists; no exporter proof. | REUSE concepts; defer exporter until runtime target is chosen. |

## Gap matrix and backlog

| ID | Engine | Gap | Priority | Classification | Smallest next step | Verification |
|---|---|---|---|---|---|---|
| P0-I1 | IntentIR | Source, uncertainty, lifecycle, and fulfillment were implicit. | P0 | BUILD | Completed additive IntentIR `1.1` slice. | IntentIR suite: 37 passed. |
| P0-E1 | Shared | IntentIR-to-Elastic request/result correlation was split between IntentIR and OutcomeEnvelope. | P0 | CLOSED locally | Correlation regression is implemented and verified; durable/restart correlation remains external. | Focused gateway/projection suite and full local Python suite. |
| P0-S1 | Elastic Web | Production caller identity and approval enforcement are not configured. | P0 | BLOCKED external | Keep loopback-only/default fail-closed behavior; wait for a named trusted identity contract. | Local negative tests pass; production IdP/tenant mapping is absent. |
| P0-E2 | Elastic Web | Discovered MCP capabilities do not reach the canonical provider/runtime/evidence path. | P0 | ADAPT | Route one remote MCP capability through `RecipeDAGRunner`; fail closed on unknown provider/protocol. | Discovery → retrieval → runtime invocation → pending/verified evidence test. |
| P1-E1 | Elastic Web | Candidate retrieval did not visibly enforce hard constraints before ranking. | P1 | CLOSED locally | Deterministic suitability filtering is implemented. | Negative tests for missing input, permission, and protocol. |
| P1-E2 | Elastic Web | Live OpenAPI/AsyncAPI discovery is not externally proven. | P1 | UNVERIFIED external | Keep fixture-backed ingestion; validate a named real service only when authorized. | Fixture suite is local evidence, not live conformance. |
| P2-E1 | Elastic Web | Provider receipts, browser deployment, and production deployment remain unproven. | P2 | UNVERIFIED external | Run named provider/browser/deployment gates with approval. | Provider attestation, browser, and deployment evidence. |
| P3-E1 | Elastic Web | Learned ranking is not measured. | P3 | DEFER | Establish deterministic baseline metrics first. | E01/E05 matched workload evidence. |

### Reconciliation note — local P0/P1 closure

The original P0-E2 wording above is stale: the trusted synthetic remote-MCP
bridge is now locally verified through discovery, retrieval, `RecipeDAGRunner`,
and non-authoritative evidence. The remaining gap is live provider authority,
not a second executor. Likewise, local P0/P1 implementation slices are closed;
the open work is external or runtime-gated.

For the database gate, application-level gateway cross-tenant denial is a
separate result from direct PostgreSQL RLS proof. The following live criteria
were not executed and remain individually open: restart-safe cancellation,
direct restricted-role `INSERT` rejection, and rollback acceptance.

## Decision register

| Decision | Alternatives rejected | Reason |
|---|---|---|
| Keep IntentIR and Elastic Web as boundary-separated contracts. | New microservices or repositories. | The current local code already has the needed module boundaries; infrastructure would not close evidence gaps. |
| Make IntentIR additions optional at the JSON Schema boundary. | Require all new fields immediately. | Preserves existing clients while allowing new producers to carry provenance and uncertainty. |
| Keep assurance authority in `assurance-protocol`. | Duplicate full outcome lifecycle inside IntentIR. | Prevents two conflicting status authorities. |
| Keep deterministic retrieval before ML ranking. | Add LinUCB/router/vector service now. | No measured workload demonstrates benefit; current repository already has a reproducible baseline. |
| Treat protocol support as adapters, not protocol equivalence. | Normalize A2A, MCP, WebMCP, OpenAPI, and AsyncAPI into one wire protocol. | They solve different interoperability problems and have different maturity/security boundaries. |

## Research synthesis

Siegel and Searls contribute user-directed demand and vendor independence: relevant to intent expression and provider selection, not a marketplace build. Bush, Nelson, and Solid contribute associative provenance and linked reusable information: relevant to evidence/reference relationships, not a new storage platform. Engelbart, Licklider, and Weiser contribute human-computer augmentation and integrated work context: relevant to orchestration and explanation, not device engineering. Bell/Gemmell and Dey/Abowd clarify searchable personal data and interpreted context, both outside this scope. The unresolved technical problems are trustworthy delegation, provider truth, cross-protocol conformance, durable recovery, and measuring whether optimization improves verified outcomes.

## External gates and unknowns

- Public code and local tests do not prove deployed browser WebMCP behavior.
- Local assurance tests do not prove shared PostgreSQL/RLS/retention behavior.
- A provider receipt or HTTP success does not prove external business truth.
- A2A/MCP/WebMCP version compatibility must be tested against the target runtime.
- No production publication, deployment, external message, payment, or destructive migration was performed.

## A2A and A2AChat follow-up

The local A2A adapter now supports the JSON-RPC unary/polling boundary through `/a2a`, `message/send`, `tasks/get`, `tasks/cancel`, and task listing, while retaining the legacy `/message:send` route. Task snapshots preserve task/context/trace/intent/outcome/evidence/verification correlation. Post-dispatch cancellation is represented as a request and does not falsely claim that synchronous execution stopped.

This is `IMPLEMENTED` for the local prototype, not full production A2A conformance. Local streaming/SSE, task errors, cancellation, and an explicitly opt-in loopback TCK fixture profile are implemented. Opt-in SQLite persistence and a DSN-gated Postgres adapter exist locally. Push callbacks, production authenticated transport, live restart-safe cancellation, direct database RLS rejection tests, rollback acceptance, external Agent Card validation, and normal-runtime live SDK/TCK interoperability remain `UNVERIFIED` or `BLOCKED`. The latest normal-runtime official TCK result is 46 passed, 27 failed, 41 skipped; the five artifact/message fixture scenarios pass under the isolated fixture profile only.

`a2achat` is absent from the workspace. The public project at [AndrewAndrewsen/a2achat](https://github.com/AndrewAndrewsen/a2achat) is a hosted agent profile/channel/DM service with its own API-key and session model, not the official A2A wire protocol. Reusable ideas are explicit peer consent, short-lived sessions, token rotation, and polling fallback. It is not a justified dependency or identity/evidence authority for Elastic Web, and no external registration or disclosure was performed.

## Smallest next action

Keep local P0/P1 implementation closed. The next actionable gate is an
explicitly authorized DSN smoke run, whose acceptance criteria must separately
record restart-safe cancellation, direct restricted-role `INSERT` rejection,
rollback acceptance, and application-level cross-tenant denial. Do not treat
the last item as RLS proof.
