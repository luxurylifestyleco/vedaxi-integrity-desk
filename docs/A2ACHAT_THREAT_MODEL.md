# A2AChat Conformance Threat Model

Status: local contract only. No A2AChat service, credentials, or network
connector are used by the current implementation.

## Boundary

```text
client chat
  -> local authenticated session and consent
  -> A2A message/send
  -> IntentIR and existing Elastic runtime
  -> A2A task and assurance metadata
  -> client polling through tasks/get
```

A2AChat is treated as a source of client-session patterns, not as an authority
for Elastic identity, tenant policy, authorization, task state, fulfillment,
evidence, or verification. `contextId` identifies a conversation; each
`messageId` may create at most one local `taskId`.

## Conformance controls

| Requirement | Local control | Evidence |
|---|---|---|
| No network by default | Chat uses the local gateway and existing A2A adapter; no A2AChat connector or credential configuration exists | `apps/gateway/test_protocols.py` chat flow; no connector package/config |
| No unverified fulfillment claim | Text says verification is incomplete unless the assurance result is authoritative | `packages/capability-projection/test_projection.py::test_a2a_chat_task_bridge_is_multiturn_idempotent_and_human_readable`; gateway assurance path |
| Duplicate messages are safe | Stable `messageId` returns the original task and does not execute again | `test_a2a_chat_task_bridge_is_multiturn_idempotent_and_human_readable`; `test_chat_task_bridge_is_idempotent_and_session_owned` |
| Task ownership is enforced | Chat task get/cancel requires the owning session and context | `test_chat_task_bridge_is_idempotent_and_session_owned`; `test_chat_session_context_ownership_and_a2a_reference` |
| Connector remains absent/disabled | No outbound A2AChat implementation is part of the local runtime; integration remains an explicit future gate | `docs/A2ACHAT_INTEGRATION_DECISION.md` and repository inspection |

## Threats and required behavior

1. **Session confusion or hijacking**

   A client must not be able to submit a client-supplied tenant or principal,
   reuse another session's context, or continue after expiry/revocation.
   Reject before A2A execution.

2. **Duplicate execution**

   Retries are expected in chat transports. A repeated `messageId` must return
   the original task; reusing that ID under another context must fail.

3. **False completion**

   A successful recipe return is not proof of fulfillment. Chat text and task
   metadata must preserve the assurance state and must not claim authoritative
   completion without verification evidence.

4. **Cross-tenant task access**

   A task ID is not an authorization credential. `tasks/get` and
   `tasks/cancel` must apply the same session/context ownership checks as
   `message/send`.

5. **Unapproved external disclosure**

   No private project data, secrets, or live credentials may leave the process.
   Any future outbound connector must be opt-in, disabled by default, use
   synthetic compatibility tests first, and be unable to mark local work
   fulfilled.

6. **Checkpoint authority confusion**

   LangGraph may provide recipe checkpointing when explicitly configured. It is
   not the A2A task store, chat history authority, identity provider, or
   assurance ledger. A raw `contextId` must not become an unscoped checkpoint
   key; any future durable mapping must be tenant-scoped.

## Local acceptance contract

The conformance slice passes when all of the following remain true:

- local chat tests pass without contacting an external host;
- duplicate message submission executes once;
- wrong-session task lookup/cancellation is rejected;
- incomplete verification produces non-authoritative text;
- no A2AChat connector, secret, dependency, streaming path, or database change
  is required;
- live interoperability is not claimed from these tests.

## Explicit non-goals

This slice does not implement hosted A2AChat integration, WebSocket streaming,
production identity resolution, durable session/task persistence, provider
cancellation, or database migrations. Those require separate authorization and
verification gates.

Source references: [A2AChat repository](https://github.com/AndrewAndrewsen/a2achat),
[A2AChat skill contract](https://github.com/AndrewAndrewsen/a2achat/blob/main/SKILL.md),
and the local [integration decision](A2ACHAT_INTEGRATION_DECISION.md).
