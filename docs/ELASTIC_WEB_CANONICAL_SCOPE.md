# Elastic Web Canonical Scope

Status: `SCOPED — execution follows the batch chain`  
Owner: `Master Agent // Elastic Web`  
Source: the two pasted master prompts, verified identical by SHA-256:
`51F5B4B86287B94001485CBCFAB4BA33C1C2B6225F83063841B3F1430AFD7B2F`

## Canonical mission

Extend the existing Elastic Web infrastructure into a protocol-neutral outcome
coordination system. It accepts a human or agent desired outcome, coordinates
independent agents and providers, preserves delegated authority, and verifies
the final result through trustworthy evidence.

Elastic Web is the interoperability and control plane. It does not become the
merchant, payment processor, hosting provider, or external business source of
truth.

## Scope boundary

### In scope

1. Protocol-neutral Outcome Envelope and lifecycle.
2. Principal, agent, provider, delegation, authorization, revocation, expiry,
   scope, approval, and delegation-chain enforcement.
3. Resolution across existing A2A, MCP, WebMCP, UCP, REST/OpenAPI, and AP2
   boundaries without treating them as interchangeable.
4. Stable correlation of outcome, execution, capability, provider, protocol,
   event, evidence, and verification identifiers.
5. Append-only evidence ledger and secure artifact-reference boundary.
6. Provenance, digest, signature, issuer, credential, authorization, expiry,
   duplicate, conflict, and correlation verification.
7. Outcome evaluator with completion criteria, partial completion, recovery,
   idempotency, cancellation, reconciliation, and human escalation.
8. Reuse of the existing PostgreSQL/event infrastructure and tenant boundary.
9. Extension of existing Mission Control/dashboard surfaces.
10. Automated unit, integration, security, and end-to-end scenario tests.
11. Technical documentation, migration plan, API/event contracts, threat model,
    and handoff evidence.

### Explicitly out of scope

- Rebuilding Elastic Web, VAOS, AgentOS, Decision Engine, Skill Port, or the
  existing agent registry.
- Creating a second orchestrator, marketplace, dashboard, database, or mandatory
  proxy for every provider interaction.
- Replacing A2A, MCP, WebMCP, UCP, REST, or AP2.
- Becoming a payment rail, merchant, bank, checkout owner, or provider source of
  truth.
- Storing sensitive payment credentials unnecessarily.
- Blockchain or artificial confidence scores without a concrete requirement.
- Autonomous deployment, publication, external messaging, payment, or production
  mutation without explicit human approval.
- Claiming live Supabase/RLS, provider, AP2, AgentOS, SkillPort, Hermes, or
  deployment behavior from repository tests alone.

## System shape

```text
Principal
  -> Delegation / Authorization
  -> Outcome Envelope
  -> Protocol Resolution
  -> Direct or mediated Provider Execution
  -> Execution Graph
  -> Append-only Evidence Ledger
  -> Verification Engine
  -> Outcome Evaluator
  -> Completed / Partial / Recovery / Failed / Disputed
```

Telemetry and observability correlate with this graph but never substitute for
authoritative business evidence.

## Workstreams and deliverables

| Workstream | Deliverables | Exit evidence |
|---|---|---|
| W1 Audit | Architecture audit, gap analysis, source/runtime map, existing-vs-new map | Every requirement mapped to verified, partial, unverified, or unknown evidence |
| W2 Contracts | Outcome, delegation, evidence, verification schemas; lifecycle transitions | Schema and negative tests pass; completion fails closed without evidence |
| W3 Coordination | Outcome-aware execution, protocol registry/resolver, normalized results | One existing execution preserves outcome correlation end to end |
| W4 Evidence | Append-only ledger, artifact references, provenance, integrity, conflict/duplicate handling | Correction creates a new record; mutation is rejected; correlation tests pass |
| W5 Evaluator | Completion criteria, verification policy, recovery and reconciliation | Conflicting/partial/revoked/delayed scenarios produce defensible states |
| W6 Protocol/payment | A2A/MCP/WebMCP/UCP/REST/AP2 mapping and receipts | Protocol-specific tests pass; AP2 is retained or explicitly marked external/unknown |
| W7 Persistence/security | Existing DB migration, tenant isolation, approvals, threat model | Migration is additive and rollback-readable; security tests pass |
| W8 Mission Control | Existing dashboard outcome/evidence/audit views | Operator can explain why an outcome completed, failed, or was disputed |
| W9 E2E proof | Scenarios A–H and technical handoff | Reproducible receipts for each scenario; live gaps explicitly listed |

## Dependency order

```text
W1 Audit
  -> W2 Contracts
  -> W3 Coordination
  -> W4 Evidence
  -> W5 Evaluator
  -> W6 Protocol/payment integration
  -> W7 Persistence/security hardening
  -> W8 Mission Control
  -> W9 End-to-end proof
```

No downstream work may silently promote an upstream `PARTIAL`, `UNKNOWN`, or
`UNVERIFIED` claim to `COMPLETED`.

## Acceptance criteria

The scoped system is complete only when an external agent can:

1. Establish verifiable identity.
2. Receive scoped, expiring, revocable delegated authority.
3. Submit or join a protocol-neutral Outcome.
4. Discover independent providers through existing protocol adapters.
5. Execute multiple operations under one Outcome ID.
6. Produce attributable, correlated evidence.
7. Have evidence independently verified.
8. Preserve partial failures, conflicts, duplicates, delayed events, and recovery
   decisions.
9. Produce a defensible final status.
10. Allow an auditor to reconstruct authorization, actors, providers, protocols,
    evidence, verification, and the completion decision.

## Current implementation truth

### Completed at repository scope

- Existing public Elastic audit and gap map.
- Canonical batch chain and execution checklist.
- Outcome, delegation, evidence, verification contracts.
- Guarded outcome lifecycle transitions.
- Append-only in-memory evidence reference implementation.
- Outcome ID correlation through the existing capability execution path.
- UCP/demo-bank dirty-tree stabilization.
- Reconciled nested Elastic local suite: `377 passed` on 2026-11-09.
- Local suitability filtering, trusted synthetic remote-MCP bridging, fail-closed
  transport, A2A streaming, and opt-in SQLite/Postgres chat-task stores.

### Partial or unverified

- Live PostgreSQL outcome/evidence and chat/task persistence behavior.
- Restart-safe cancellation, direct restricted-role `INSERT` rejection, and
  rollback acceptance have not been executed against a live target.
- Runtime authorization and delegation enforcement.
- Tenant isolation and production RLS. Gateway cross-tenant denial is an
  application-path check and is not direct database RLS proof.
- Secure artifact store and retention/deletion enforcement.
- Cryptographic signature and credential verification.
- AP2 integration location and live behavior.
- Multi-provider recovery and reconciliation.
- Mission Control evidence views.
- AgentOS, SkillPort, Hermes, provider, and deployment runtime state.

## Control documents

- [Master batch chain](ELASTIC_WEB_MASTER_BATCH_CHAIN.md)
- [Execution checklist](ELASTIC_WEB_EXECUTION_CHECKLIST.md)
- [Outcome/evidence build slice](OUTCOME_EVIDENCE_BUILD.md)

The batch chain and checklist control execution. This document controls scope.
