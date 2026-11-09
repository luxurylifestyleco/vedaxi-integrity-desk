# IntentIR <-> Elastic Web Interoperability Contract v1

Status: `LOCAL CONTRACT / PRODUCTION CONFORMANCE UNVERIFIED`  
Owner: `Master Agent // Elastic Web`  
Version: `1.0`  
Date: `2026-11-04`

This document defines the smallest supported contract for an agent or chat
client to submit a request to Elastic Web and receive a correlated execution
result. It describes the existing local implementation; it does not add a new
transport, executor, database, identity provider, or fulfillment authority.

## 1. Authority model

```text
Client / A2AChat-style session
  -> A2A JSON-RPC message/send
  -> IntentIR compiler
  -> capability retrieval
  -> existing RecipeDAGRunner
  -> execution telemetry and assurance
  -> A2A task result / tasks/get
```

- The client owns the original request and transport correlation IDs.
- IntentIR owns the structured interpretation of that request.
- Elastic capability retrieval selects a registered capability.
- `RecipeDAGRunner` remains the execution authority.
- The assurance/evidence path decides whether completion is authoritative.
- A2A task state is a transport view. The default store is process-local; the
  local implementation also provides opt-in SQLite restart-safe stores and a
  DSN-gated Postgres adapter. Live database behavior is not claimed here.
- A2AChat patterns may supply session, consent, context, and message
  conventions; A2AChat is not the execution, evidence, or verification
  authority.

## 2. Version and compatibility

This contract has two version markers:

| Layer | Version | Compatibility rule |
|---|---:|---|
| Interoperability document | `1.0` | A client must support the fields and states in this document. |
| IntentIR schema | `1.1` | The compiler emits `schema_version: "1.1"`; consumers must reject unknown fields according to the IntentIR model. |
| A2A transport | `1.0` | `/a2a` accepts no `A2A-Version` header or `A2A-Version: 1.0`; other values are rejected. |

The transport uses camelCase correlation names (`contextId`, `messageId`,
`intentId`, `outcomeId`, `evidenceId`, `verificationId`). IntentIR and internal
telemetry use the existing snake_case names (`intent_id`, `outcome_id`, and so
on). These are equivalent projections, not separate identifiers.

No forward-compatible unknown runtime fields are defined here. A future
contract version must document any new required field and its migration rule.

## 3. Request contract

### 3.1 A2A JSON-RPC entry point

`POST /a2a` with `Content-Type: application/json`.

```json
{
  "jsonrpc": "2.0",
  "id": "rpc-001",
  "method": "message/send",
  "params": {
    "message": {
      "messageId": "msg-001",
      "contextId": "ctx-001",
      "role": "user",
      "metadata": {
        "sessionId": "chat-001",
        "arguments": {
          "account_id": "ACC-1"
        }
      },
      "parts": [
        {
          "kind": "text",
          "text": "Get my August bank statement"
        }
      ]
    }
  }
}
```

Required:

- `jsonrpc` must be `"2.0"`.
- `method` must be `"message/send"` for submission.
- `params.message.role` must be `"user"` or `"ROLE_USER"`.
- `params.message.parts` must contain at least one non-empty text part.

For chat-bound requests, `contextId` must belong to the `sessionId`; the
gateway resolves the principal and tenant and rejects client-supplied
`tenantId` or `principalId`. `messageId` is the idempotency key within a
session. Repeating the same `messageId` returns the original task and must not
execute the request again.

The legacy `POST /message:send` endpoint accepts the same message object as
the request body and returns the task directly. It is retained for existing
callers; new clients should use `/a2a`.

### 3.2 IntentIR projection

The text is compiled into the existing IntentIR model. A representative
compiled value is:

```json
{
  "schema_version": "1.1",
  "intent_id": "intent-001",
  "original_expression": "Get my August bank statement",
  "state": "FORMED",
  "goal": "retrieve_document",
  "domain": "finance",
  "action": "get",
  "object": "bank_statement",
  "constraints": {},
  "preferences": {},
  "context": {},
  "desired_output": "document",
  "authority": {},
  "disclosure": {},
  "success_conditions": [],
  "confidence": 1.0,
  "uncertainty": {},
  "fulfillment": {},
  "metadata": {}
}
```

The example shows the model shape, not a guarantee that the deterministic
local compiler supports every natural-language request. Unsupported or
unmatched requests fail before successful task completion.

## 4. Result contract

### 4.1 Successful JSON-RPC response

The `/a2a` result is a canonical task. The example below shows the completed
shape; identifiers are illustrative values with the same field names emitted
by the adapter.

```json
{
  "jsonrpc": "2.0",
  "id": "rpc-001",
  "result": {
    "id": "task-001",
    "contextId": "ctx-001",
    "status": {
      "state": "completed",
      "message": {
        "role": "agent",
        "parts": [
          {
            "text": "The request completed successfully."
          }
        ]
      }
    },
    "artifacts": [
      {
        "parts": [
          {
            "text": "{\"statement\":\"August\",\"account_id\":\"ACC-1\"}"
          }
        ]
      }
    ],
    "metadata": {
      "taskId": "task-001",
      "contextId": "ctx-001",
      "messageId": "msg-001",
      "sessionId": "chat-001",
      "traceId": "trace-001",
      "intentId": "intent-001",
      "outcomeId": "outcome-001",
      "evidenceId": "execution-event-trace-001",
      "verificationId": "verification-trace-001",
      "outcomeStatus": "COMPLETED",
      "verificationStatus": "VERIFIED",
      "completionAuthoritative": true
    }
  }
}
```

The minimum correlation chain is:

```text
messageId -> taskId -> traceId -> intentId -> outcomeId
                                      -> evidenceId -> verificationId
```

`completionAuthoritative: true` is only emitted when the existing assurance
evaluation reaches its completed state with sufficient evidence. Execution
success alone is not a fulfillment claim.

### 4.2 Non-authoritative execution

If execution returns but verification is incomplete, the task remains
non-terminal or reports a truthful working state. The client must not treat a
successful provider invocation as verified fulfillment:

```json
{
  "id": "task-002",
  "status": {
    "state": "working",
    "message": {
      "role": "agent",
      "parts": [
        {
          "text": "The request executed, but verification is incomplete."
        }
      ]
    }
  },
  "metadata": {
    "taskId": "task-002",
    "traceId": "trace-002",
    "intentId": "intent-002",
    "outcomeId": "outcome-002",
    "evidenceId": "execution-event-trace-002",
    "verificationId": "verification-trace-002",
    "outcomeStatus": "PARTIALLY_COMPLETED",
    "verificationStatus": "INSUFFICIENT",
    "completionAuthoritative": false
  }
}
```

### 4.3 Polling and cancellation

```json
{
  "jsonrpc": "2.0",
  "id": "rpc-002",
  "method": "tasks/get",
  "params": {"id": "task-001", "sessionId": "chat-001"}
}
```

```json
{
  "jsonrpc": "2.0",
  "id": "rpc-003",
  "method": "tasks/cancel",
  "params": {"id": "task-001", "sessionId": "chat-001"}
}
```

Cancellation is conditional: a submitted task becomes `canceled`; an active
task records `cancellationRequested`; a terminal task is unchanged. Ownership
is checked before either operation for chat-bound tasks.

Local streaming returns an ordered event list beginning with a non-terminal
submitted event and ending with a terminal event. Push notification
configuration is explicitly unsupported and fails closed.

## 5. Error semantics

JSON-RPC protocol errors use the existing codes:

| Code | Meaning | Examples |
|---:|---|---|
| `-32600` | Invalid JSON-RPC request | Missing `jsonrpc` or non-string `method` |
| `-32601` | Method not found | Unsupported A2A method |
| `-32602` | Invalid parameters or authorization failure at the local boundary | Missing message, invalid parts, expired session, wrong context, task ownership failure |
| `-32001` | Task not found | Unknown task ID in `tasks/get` or `tasks/cancel` |
| `-32005` | Unsupported A2A version | `A2A-Version` other than `1.0` |

The HTTP status for JSON-RPC errors at `/a2a` is currently `200`, with the
error represented in the JSON-RPC envelope. Unsupported HTTP transport
configuration fails closed before request handling: unauthenticated
non-loopback or production binding is rejected, and a request without a
trusted authentication adapter receives HTTP `401` or `503` as applicable.

Errors are not fulfillment evidence. A client must preserve the returned
error code/message and may retry only with a new request or the same
idempotent `messageId` according to the transport state.

## 6. Compatibility and security constraints

- The local default is loopback-only.
- Non-loopback or production use requires an explicitly configured trusted
  authentication adapter.
- Chat sessions require consent, scopes, expiry, revocation checks, and
  session/context ownership.
- The local A2A adapter currently uses a synthetic local principal and an
  unresolved tenant in its assurance path; this is not production identity or
  tenant proof.
- The default task and chat stores are process-local. SQLite restart-safe
  stores and a DSN-gated Postgres adapter exist locally. The linked Supabase
  runtime smoke passed restart persistence, task recovery, cleanup, and
  application-path cross-tenant denial. A temporary non-bypass
  `elastic_runtime_smoke` role also received the expected RLS rejection on a
  direct cross-tenant `INSERT`, and the role was removed. Gateway
  cross-tenant denial remains application-path evidence, not a substitute for
  direct database RLS proof. Restart-safe cancellation and rollback acceptance
  remain unverified; the current smoke runner contains no cancellation
  assertion.
- No A2AChat connector, credential, outbound callback, or hosted chat service
  is required by this contract.

## 7. Implementation and test references

Implementation:

- `public-repos/vedaxi-elastic/packages/intent-ir/intent_ir.py` — IntentIR
  schema version `1.1` and validation.
- `public-repos/vedaxi-elastic/packages/capability-projection/a2a.py` — inbound
  adapter, task store, canonical task mapping, client, and local stream.
- `public-repos/vedaxi-elastic/apps/gateway/app.py` — `/a2a`, `/message:send`,
  task polling/cancel, chat authorization, and transport fail-closed guard.
- `public-repos/vedaxi-elastic/packages/telemetry/telemetry.py` — trace
  correlation for intent, task, context, outcome, evidence, and verification.

Tests:

- `public-repos/vedaxi-elastic/apps/gateway/test_protocols.py` — Agent Card,
  JSON-RPC lifecycle, chat ownership/idempotency, and transport behavior.
- `public-repos/vedaxi-elastic/packages/capability-projection/test_projection.py`
  — adapter execution, correlation, task lifecycle, and stream behavior.
- `docs/A2ACHAT_INTEGRATION_DECISION.md` — A2AChat reuse boundary and deferred
  outbound integration.
- `docs/A2ACHAT_THREAT_MODEL.md` — session, idempotency, ownership, and
  non-fulfillment-claim constraints.

## 8. Consistency checklist

- [x] Uses existing IntentIR field names and schema version `1.1`.
- [x] Uses existing A2A methods: `message/send`, `tasks/get`, `tasks/cancel`.
- [x] Uses existing transport correlation names and internal identifier names.
- [x] Keeps RecipeDAGRunner and assurance/evidence as authorities.
- [x] Documents legacy `/message:send` without making it a second protocol.
- [x] Documents canonical lowercase task states and legacy uppercase input
      compatibility.
- [x] Documents exact local JSON-RPC error codes and version guard.
- [x] Documents idempotency and chat ownership behavior.
- [x] States local-only, process-local, and unverified limitations.
- [x] References executable implementation and tests.
- [ ] Live restart-safe cancellation and rollback acceptance verified
      separately; direct restricted-role `INSERT` rejection and the linked
      Supabase RLS denial are complete evidence gates.
- [ ] External A2A SDK/TCK, provider, browser, or hosted A2AChat conformance
      verified.

The unchecked items are evidence gates, not requirements silently claimed as
complete by this document.
