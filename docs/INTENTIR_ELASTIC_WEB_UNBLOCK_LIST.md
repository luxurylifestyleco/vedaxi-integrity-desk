# IntentIR + Elastic Web Unblock List

Updated: 2026-11-09

This list separates work that is complete from work that requires an external
contract, credential, approval, or deployment target. No secret values belong in
this document or in chat.

## Completed and independently verified

| Area | Evidence | State |
|---|---|---|
| IntentIR schema, provenance, lifecycle, uncertainty, fulfillment | `packages/intent-ir`; current nested full suite is `620 passed` | COMPLETED |
| Elastic Web retrieval, suitability filtering, recipes, DAG execution | capability registry/retrieval/runtime tests; `RecipeDAGRunner` remains sole execution authority | COMPLETED locally |
| A2A JSON-RPC, HTTP+JSON, polling, cancel, SSE, errors | Current loopback gateway/protocol HTTP evidence: `52 passed in 3.79s`; nested full suite: `620 passed in 23.78s` | COMPLETED locally; live/remote conformance unverified |
| A2AChat boundary | `docs/A2ACHAT_INTEGRATION_DECISION.md`; local session/task bridge | COMPLETED locally; external connector deferred |
| MCP, WebMCP, OpenAPI, AsyncAPI adapters | focused adapter and discovery tests | COMPLETED locally; live interoperability unverified |
| Supabase migrations and local PostgreSQL/RLS contract | migration 007 contract plus local migration/RLS checks | COMPLETED for schema/local gate; live smoke and direct restricted-role RLS proof passed; cancellation/rollback remain open |
| Opt-in A2A TCK fixture profile | `ELASTIC_A2A_TCK_FIXTURE=1`; official artifact/message checks `5 passed` | COMPLETED, loopback-only |

## Items requiring user or external input

| Gate | What is missing | What you need to provide or approve | What the master will do next |
|---|---|---|---|
| Production authentication | A trusted identity contract | Name the IdP and provide the contract: issuer, audience/resource, signing-key discovery, required claims for tenant/principal, expiry/revocation source, scopes, and approval policy. Configure secrets through the runtime environment, never chat. | Implement the provider-specific validator, tenant/principal mapping, negative/positive matrix, and production binding gate. |
| Durable runtime smoke test | Restart-safe cancellation and rollback acceptance | The linked target is connected and the restart/persistence/cleanup/cross-tenant smoke passed. Direct restricted-role `INSERT` denial also passed with a temporary non-bypass role that was removed. The current runner has no `smoke-cancel` assertion. | Run cancellation persistence against a task that reaches a cancellable state, and run rollback only against a disposable database/branch; do not use the shared public schema. |
| Normal-runtime A2A conformance | The official TCK expects fixture-provider outputs that the generic Elastic runtime does not generate | Choose one: accept the isolated fixture profile as test-only evidence, or authorize a named capability-backed conformance provider with artifact/message behavior. | If provider-backed, add generic capability mappings and rerun the normal TCK. Never add production message-ID hacks. |
| External A2AChat interoperability | External endpoint, credentials, disclosure scope, and callback policy | Name the authorized A2AChat target and explicitly approve outbound disclosure/credentials/callback behavior. | Run a bounded read-only interoperability test; do not make A2AChat the execution or evidence authority. |
| Browser WebMCP proof | A deployed/accessible browser target and test session | Name the target URL and approve the browser validation/deployment action. | Verify registration, invocation, exact-origin isolation, abort/removal, and navigation behavior. |
| Provider-authoritative verification | Signed receipt or attestation contract | Name the provider and supply its public verification key/receipt schema and trust policy. | Validate signature, issuer, scope, replay, and correlation before marking completion authoritative. |
| Production deployment | Target environment, release owner, rollback/monitoring plan | Explicitly approve the deployment target and release window. | Run final gates, deploy, monitor, and report rollback readiness. |
| Live database acceptance | A named DSN and authorized smoke target | The linked target is connected and the application-path smoke plus direct restricted-role `INSERT` rejection are complete. | Separately test restart-safe cancellation and rollback acceptance against safe targets. The gateway result is not direct RLS proof. |

## Current verdict

- Local engineering scope: `COMPLETED` for the implemented contract surface.
- Current full-suite evidence: `620 passed in 23.78s`, exit 0, from `.venv/Scripts/python.exe -m pytest -q` in the nested Elastic repository (2026-11-09). The earlier `377 passed` worker count is historical evidence, not the current total.
- Current local HTTP evidence: `52 passed in 3.79s`, exit 0, from the gateway/protocol HTTP tests using real loopback server threads and `urllib.request.urlopen`.
- Live database evidence: `PARTIAL`; restart/persistence/cleanup/application-path cross-tenant smoke and direct restricted-role `INSERT` rejection passed. Restart-safe cancellation and rollback acceptance remain unverified.
- Normal runtime A2A TCK: `46 passed, 27 failed, 41 skipped`; not production conformance.
- Provider evidence: local/synthetic receipt verification and one read-only external-provider path are verified; real provider-signed receipt authority remains blocked pending the provider trust contract.
- Queue: `NOT_PRODUCTION_READY`; no ready local work is observable. Production authentication, external provider authority, deployment/browser proof, restart-safe cancellation, and rollback acceptance remain blocked or unverified.
- No deployment, publication, external message, payment, or destructive migration was performed.
