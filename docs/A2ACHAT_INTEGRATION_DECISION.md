# A2AChat Integration Decision — 2026-11-04

## Decision

Use A2AChat as a reference and optional client-facing transport, not as the
authority for Elastic identity, authorization, task state, execution, or
evidence.

The client path is:

```text
client chat -> authenticated session/consent -> A2A message/send
-> Elastic runtime -> outcome/evidence -> chat response
```

This makes chat useful without allowing a chat provider to claim that an
operation was authorized or fulfilled.

## What A2AChat gives us

The public project describes agent profiles, public channels, direct messages,
invite-based handshakes, REST polling, WebSocket streaming, and short-lived
session-token rotation. The handshake is the valuable idea: a message session
does not exist merely because an agent knows an address.

Sources: [A2AChat repository](https://github.com/AndrewAndrewsen/a2achat),
[A2AChat skill contract](https://github.com/AndrewAndrewsen/a2achat/blob/main/SKILL.md).

## Reuse boundary

| Decision | A2AChat concept | Elastic treatment |
|---|---|---|
| ADAPT | handshake/approval | Local consent receipt before task submission |
| ADAPT | short-lived session token | Bind session to principal, tenant, expiry, and revocation |
| ADAPT | polling fallback | Keep task polling as the baseline transport |
| ADAPT | streaming | Add only after authenticated polling is durable |
| REJECT | hosted agent directory | Elastic capability registry remains authoritative |
| REJECT | hosted message store | Elastic task/event/evidence ledger remains authoritative |
| REJECT | provider-generated identity | Elastic principal and tenant policy decide access |
| DEFER | outbound A2AChat connector | Requires explicit disclosure/credential approval and an opt-in boundary |

## Current local gap

`apps/demo-bank/bank.py::chat_with_agent` returns a synthetic `session_id` and
`status=connected`. Its manifest exposes the capability with `support:write`,
but there is no durable conversation/session store or authenticated chat route
that turns a client message into an A2A task. The local A2A adapter now has
JSON-RPC task submission, polling, cancellation, and correlation, but its task
store is process-local and gateway authentication is still not production
ready.

## Next cycle: A2ACHAT-ELASTIC-BRIDGE-2026-11-04

1. **CHAT-AUTH** — define the local principal, tenant, consent, session expiry,
   revocation, and scope contract. Write only the existing assurance/runtime
   boundary. Acceptance: unauthenticated, expired, revoked, cross-tenant, and
   over-scoped requests fail closed; no external provider call.
2. **CHAT-SESSION** — replace the synthetic chat connection with a local
   session/conversation lifecycle behind the existing capability and route.
   Acceptance: `chat_with_agent` returns a session tied to
   principal/tenant/expiry; messages and task/artifact metadata are retained by
   `contextId`; and a client message produces a correlated A2A task without
   executing outside the existing runtime.
3. **CHAT-TASK** — connect inbound chat messages to the current A2A
   `message/send`, task polling, cancel, text response artifact, and
   outcome/evidence correlation.
   Acceptance: session ID, task ID, context ID, intent ID, outcome ID, and
   evidence/verification IDs survive the round trip.
4. **CHAT-DURABILITY** — persist session/task state at the existing runtime
   persistence boundary. Acceptance: restart-safe get/poll/cancel and atomic
   state transitions; no second task store or executor.
5. **CHAT-CONFORMANCE** — add local contract tests and a threat-model check;
   defer live A2AChat integration until credentials, disclosure, and a named
   external test target are explicitly approved.

Dependencies: CHAT-AUTH -> CHAT-SESSION -> CHAT-TASK -> CHAT-DURABILITY;
CHAT-CONFORMANCE runs after each slice. Streaming and outbound A2AChat remain
deferred until polling, auth, and durability pass.

## Explicit non-goals

Do not add a second chat database, replace A2A with a proprietary chat wire
format, publish credentials, or send private project data to A2AChat. Do not
claim live interoperability from local contract tests.

## Status

- **Implemented:** local A2A JSON-RPC task lifecycle and correlation slice.
- **Partial:** local chat capability exists but is a synthetic connection only.
- **Missing:** authenticated chat session, chat-to-task route, durable session/task state.
- **Blocked/Unverified:** live hosted A2AChat integration, external credentials,
  production auth, streaming/push, and live conformance.
