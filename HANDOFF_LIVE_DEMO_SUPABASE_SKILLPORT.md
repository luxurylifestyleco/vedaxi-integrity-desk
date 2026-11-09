# Live-System Handoff: Elastic Web / AgentOS / SkillPort

## Mission

Finish and verify the live parts of the Elastic Web security and interoperability work without changing the repository architecture, introducing a second orchestrator, or treating Docker/Temporal/Dapr/Istio availability as proof of correctness.

The repository work is substantially complete and locally tested. This handoff covers the work that requires control of live demo infrastructure, Supabase/PostgreSQL, SkillPort/AgentOS, Hermes, or external runtime configuration.

## Source boundaries

- Private implementation repo: `C:\Users\m_jor\Documents\Vedaxi-Elastic-Web-Mastermind`
- Public repo: `C:\Users\m_jor\Documents\elastic-web`
- REA source: `https://github.com/morluto/rea`
- REA CLI: `rea@6.7.0`
- Codex/Hermes REA registrations: already installed and aligned; restart clients before use.

Do not infer live state from README claims or previous agent reports. Re-run each check and attach the command output, test receipt, migration identifier, or screenshot.

## Current verified baseline

### Repository tests

- Private repo: `1198 passed, 38 skipped, 9 warnings, 14 subtests`
- Public repo: `414 passed`
- Private Dapr/Temporal-inspired path includes:
  - bounded idempotent retries;
  - activity timeout and cooperative cancellation;
  - durable checkpoints, read-back verification, and compensation;
  - persistent optimistic state and leases;
  - event IDs and sequences;
  - consumer offsets, retry accounting, and dead-letter records;
  - transactional payment idempotency and uncertain-outcome evidence;
  - live authorization at private-prefetch consumption.

### Runtime boundary

- Local Elastic code remains authoritative.
- Temporal and Dapr are optional probes/adapters, not workflow or policy authorities.
- Istio is not active and must not be described as active.
- REA is an evidence/inspection layer only. It must not authorize actions, mutate production data, or replace the runtime ledger.

## Workstream A — Supabase / PostgreSQL / RLS

Owner: database/security operator with access to the restricted runtime and disposable admin DSNs.

### Required actions

1. Identify the exact migration set actually applied to the target database. Do not use stale names such as `migrations/004_policy.sql` unless that file is present in the selected repository revision.
2. Run the governed PostgreSQL acceptance suite with two separate credentials:
   - restricted runtime DSN;
   - disposable database-admin DSN used only for corruption and policy tests.
3. Verify, with real SQL read-back:
   - tenant isolation under RLS;
   - default-deny policy behavior;
   - policy inheritance cannot broaden permissions;
   - policy epoch/revocation invalidates private prefetch claims;
   - payment journal uniqueness on `(payer, idempotency_key)`;
   - terminal payment states cannot be inserted without appropriate evidence;
   - event sequence/hash integrity survives concurrent writes;
   - durable state/lease tables survive process restart.
4. Confirm the database role used by the runtime cannot alter policy, bypass RLS, or publish public cache entries outside its allowed role.
5. Capture migration version, schema diff, role grants, RLS policies, and test output.

### Acceptance criteria

- No cross-tenant read or write succeeds.
- A forged principal, bearer token, grant ID, or policy epoch cannot authorize an action.
- Duplicate payment idempotency submissions produce one durable record and a deterministic rejection.
- Live RLS tests pass without skips.
- Any skipped test has a named owner and a blocking reason.

### Rollback

Use the database provider’s migration rollback or restore procedure. Never run destructive SQL against an existing application database. Use a disposable database for corruption injection.

## Workstream B — Live demo / runtime services

Owner: demo/runtime operator.

### Required actions

1. Start the live demo using the existing repo scripts and record the exact revision and environment profile.
2. Verify health independently:
   - Elastic gateway/runtime;
   - Qdrant/KGS if configured;
   - Temporal endpoint and UI, if configured;
   - Dapr health endpoint, if configured;
   - Istio status, explicitly reporting inactive when absent.
3. Execute a read-only request through the real gateway and capture:
   - authenticated principal;
   - tenant binding;
   - policy decision;
   - workflow/checkpoint events;
   - provider response and independent read-back evidence;
   - final outcome.
4. Execute negative probes:
   - forged `X-Principal`;
   - unknown bearer token;
   - cross-tenant identifier;
   - expired/replayed prefetch claim;
   - arbitrary payment grant ID;
   - retry after uncertain provider outcome;
   - malformed Temporal/Dapr configuration;
   - subscriber failure after event persistence.
5. Confirm startup probing performs no state write, publish, payment, or authorization mutation.

### Acceptance criteria

- Positive read-only flow succeeds with a traceable ledger record.
- Every negative probe is rejected before the external side effect.
- Temporal/Dapr absence degrades to the local durable path without changing authorization.
- A provider timeout is reported as uncertain/reconcile-required, never as success.
- Demo UI does not imply that a presentation-only scenario caused a real bank, payment, or property transaction.

## Workstream C — SkillPort / AgentOS / Hermes

Owner: AgentOS/SkillPort maintainer.

### Required actions

1. Confirm the exact SkillPort and AgentOS repository revisions in scope. Do not assume the private Elastic repo contains their source.
2. Verify the launcher/service startup path without ChatGPT Remote.
3. Verify the local task ledger and ownership/execution fence.
4. Confirm retired tools are gated and cannot be selected by default.
5. Confirm the REA skill is installed only in the intended shared AgentOS location and that Codex/Hermes MCP registrations point to the pinned local `rea-agents` command.
6. Restart the clients and verify that REA tools appear in the active session. `rea doctor` alone cannot prove the currently running client has reconnected.
7. Run one harmless local REA operation against a selected local artifact or source tree. Record the Evidence ID, target digest, limitations, and unknowns.
8. Confirm REA findings are advisory evidence and cannot grant permissions, bypass approval, alter RLS, or become workflow authority.

### Acceptance criteria

- AgentOS starts locally without ChatGPT Remote.
- SkillPort routes only declared, non-retired skills.
- Task ownership and execution fencing are observable in the ledger.
- REA registration is aligned in Codex and Hermes after restart.
- REA evidence is stored with provenance and does not contain secrets or private payloads.

## Workstream D — Protocol and security regression

Owner: security reviewer.

Run the public protocol suite and the private security/red-team suite from clean, reproducible environments. Review the result against the actual code paths, not generated reports.

Required coverage:

- MCP, A2A, WebMCP discovery and classifier behavior;
- identity and trust boundary;
- policy inheritance and default deny;
- payment grant/envelope binding;
- prefetch method/cookie/auth/tenant/replay protections;
- event duplicate delivery and dead-letter behavior;
- RLS and restart contention;
- no second orchestrator or hidden Docker dependency.

## Workstream E — CRUD policy rollout

Owner: policy/database operator.

The public gateway now supports explicit capability metadata:

```json
{"crud_resource":"support","crud_action":"create"}
```

Allowed actions are `create`, `read`, `update`, and `delete`. Exact grants are
`resource:action`. Legacy `resource:write` remains mutation-only compatibility
for create/update/delete and never grants read.

### Required actions

1. Inventory every live capability across local, MCP, A2A, WebMCP, SkillPort,
   and recipe registries.
2. Assign an explicit CRUD resource and action to every capability that reads
   or mutates a resource. Do not infer authorization from display names or
   caller-supplied metadata.
3. Create a tenant-scoped permission migration from `resource:write` to exact
   action grants. Keep the legacy grant only during the measured migration
   window.
4. Verify that read-only principals cannot create, update, or delete; mutation
   principals cannot read unless separately granted; and delete requires the
   existing sensitive-action approval path.
5. Apply the same decision to direct capability execution and recipe execution.
6. Add the CRUD policy version and decision evidence to the audit record.

### Acceptance criteria

- Every live capability has one trusted CRUD classification or is explicitly
  marked non-resource/public with a written reason.
- Invalid or missing CRUD declarations fail closed for protected capabilities.
- Cross-tenant CRUD access is denied even when the action permission is present.
- Policy changes are reversible and have a migration/rollback receipt.
- No client, agent, recipe, or REA finding can mint a CRUD grant.

## Evidence package to return

Return one bundle containing:

1. repository commit SHA and dirty-tree report;
2. exact test commands and outputs;
3. migration IDs and database schema/RLS read-back;
4. runtime health outputs with timestamps;
5. positive and negative probe results;
6. AgentOS/SkillPort/Hermes configuration paths and backups;
7. REA version, MCP registration state, Evidence IDs, target digests, and limitations;
8. a PASS / FAIL / BLOCKED / UNVERIFIED matrix;
9. rollback steps for every live mutation;
10. explicit list of unrelated pre-existing changes not touched.

## Stop conditions

Stop and escalate instead of guessing when:

- the target database or tenant is ambiguous;
- a migration would be destructive or irreversible;
- a credential, private payload, or customer data would leave the local boundary;
- a live write/payment/publish action is not explicitly authorized;
- a test is skipped because a required DSN or provider is missing;
- REA reports partial coverage or inference rather than observed behavior;
- Temporal, Dapr, or Istio would become authoritative by configuration drift.

## Final handoff rule

Do not report “complete” until every workstream has a directly reproducible receipt. Repository tests prove repository behavior; they do not prove live Supabase/RLS, SkillPort startup, client reconnection, or production deployment.
