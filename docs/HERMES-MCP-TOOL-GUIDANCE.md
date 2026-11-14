# Hermes MCP Tool Guidance

This is the shared operating contract for Codex, Claude, Instinct, and any
other MCP client connected to the Elastic Hermes bridge.

## Connection sequence

1. Authenticate with the bearer token.
2. Send `initialize` and capture `Mcp-Session-Id`.
3. Call `tools/list` after initialization.
4. Follow the returned server instructions.
5. Reconnect after bridge instruction changes; existing MCP sessions may cache
   initialization metadata.

Clients must use the `/mcp` path, not the tunnel root. Preserve the returned
`Mcp-Session-Id`, send `notifications/initialized` when supported, and discard
cached session state whenever the bridge restarts or a quick-tunnel URL changes.
The current bridge emits one SSE response event per POST; it does not provide a
persistent GET stream or DELETE session cleanup endpoint.

## Tool rules

| Tool | Rule |
| --- | --- |
| `conversations_list` | First step when the target conversation is unknown. Treat results as candidate matches and verify the target. |
| `conversation_get` | Use the exact `session_key` returned by `conversations_list`; use for metadata, not as a substitute for recent messages. |
| `messages_read` | Read before replying or sending consequential content. Preserve ordering and timestamps; truncated history is incomplete. |
| `attachments_fetch` | Use only with a `message_id` returned by `messages_read`. |
| `events_poll` | Use bounded polling; carry the returned `next_cursor` into the next call. |
| `events_wait` | Use for near-real-time delivery; bound `timeout_ms` and resume from `after_cursor`. |
| `messages_send` | External write to a platform conversation. It does not ask Hermes to generate an answer. Verify its returned status/message ID. |
| `hermes.ask` | Prompt the local Hermes runtime and return its generated answer. Wait for completion; do not confuse the answer with a transport acknowledgement. |
| `channels_list` | Discover valid outbound targets before `messages_send` when the target string is unknown. |
| `permissions_list_open` | Inspect pending approvals in the current bridge session before responding. |
| `permissions_respond` | Use only with an approval ID from `permissions_list_open`; decisions are `allow-once`, `allow-always`, or `deny`. |

## Global rules

- Never use `messages_send` as a substitute for `hermes.ask`.
- Do not parallelize writes to the same Hermes conversation.
- Treat “sent”, “received”, and “answered” as different states.
- For every write, verify the tool result and re-read the conversation when
  possible.
- Keep tests and real outbound communication explicit in the prompt/message.
- Do not expose VEDA, KGS, or Hermes credentials through tool arguments or
  responses.
- Unknown tools require the same read/write, sequencing, confirmation, and
  response-handling classification before use.

## Client notes

- Instinct: configure bearer headers, accept `text/event-stream`, reconnect
  after bridge changes, and use `hermes.ask` for direct Hermes prompts.
- Codex: use the `/mcp` URL with explicit trust enabled and pass the bearer
  header through the client request headers; call `list_tools()` after a fresh
  initialize.
- Claude: use the same protocol and header requirements. Claude compatibility
  is not independently verified in this repository.
- URL-only MCP clients cannot authenticate against this bridge. They require a
  relay, OAuth, or native custom-header support.

Retries can duplicate external `messages_send` messages. Retry
`hermes.ask` only with bounded attempts and make prompts self-contained; it
does not preserve conversation memory between calls unless the prompt includes
the needed context.

## Current interoperability boundary

The tested path is `POST` JSON-RPC over HTTPS with bearer authentication,
one-shot SSE/JSON responses, Hermes `mcp-serve`, and `hermes.ask`. Persistent
server-sent events, GET-based stream establishment, DELETE cleanup, strict
session validation, and independent Claude testing remain unverified.
