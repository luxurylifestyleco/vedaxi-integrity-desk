# Hermes MCP Client Matrix

This is a compatibility target list, not a popularity ranking. It records the
connection instructions that matter for the Elastic Hermes bridge. Tool
semantics remain the same for every client: use `hermes.ask` for a prompt to
Hermes and `messages_send` only for an explicit outbound channel message.

## Shared connection contract

Every client must use the `/mcp` path, send the bearer header on every request,
accept JSON or one-shot SSE responses, preserve `Mcp-Session-Id`, and refresh
its MCP session after the bridge restarts or its tool list changes.

After connecting: `initialize` → `notifications/initialized` when supported →
`tools/list` → use the returned instructions.

## Client matrix

Status values:

- `DOCS`: behavior supported by primary client documentation.
- `LIVE`: verified against this bridge in this project.
- `PROTOCOL`: likely compatible from documented MCP support; live client test
  still required.
- `OAUTH`: client documentation points to OAuth for remote HTTP; static bearer
  may require a relay or OAuth front door.
- `UNKNOWN`: no authoritative client-specific behavior was available; test it
  before claiming compatibility.

| Client | Status | Special connection instruction |
| --- | --- | --- |
| Instinct | LIVE | Reconnect after updates; send bearer header; accept SSE; call `tools/list`; use `hermes.ask` for direct Hermes prompts. |
| Claude Desktop | PROTOCOL | Configure remote MCP through the client-supported connector/bridge; preserve auth and reconnect after changes. |
| Claude Code | DOCS | Use `claude mcp` or `--mcp-config`; pass the bearer header; explicitly allow the MCP tools when using non-interactive mode. |
| ChatGPT / Codex app | PROTOCOL | Add the remote MCP server with its auth mechanism; refresh the connection after tool changes. |
| OpenAI Codex CLI | DOCS | Use `/mcp`; pass headers; enable explicit trust for the remote server in the client configuration; call `list_tools()` after initialize. |
| Cursor | OAUTH | Cursor documents remote Streamable HTTP/SSE with OAuth; use an OAuth-capable front door or a compatible relay rather than assuming static bearer support. |
| Windsurf | PROTOCOL | Configure the remote HTTP/SSE server and auth in its MCP settings; verify it preserves bearer headers on every request. |
| Cline | PROTOCOL | Configure the remote MCP URL and custom headers; refresh cached tools after bridge changes. |
| Roo Code | PROTOCOL | Configure the remote MCP URL and custom headers; use `hermes.ask`, not `messages_send`, for Hermes answers. |
| VS Code / GitHub Copilot | DOCS | Configure Streamable HTTP; VS Code tries it before legacy SSE and supports custom headers. |
| GitHub Copilot CLI | DOCS | Add the remote server with HTTP transport and an explicit `Authorization` header. |
| Gemini CLI | DOCS | Use its remote HTTP configuration (`httpUrl` where required) and headers; run MCP discovery after reconnect. |
| Goose | PROTOCOL | Configure remote Streamable HTTP/SSE and preserve authorization/session state; live verification required. |
| Continue | PROTOCOL | Configure the remote MCP server and bearer header; refresh the tool catalog after updates. |
| Zed | OAUTH | Use Zed's context-server authentication flow; static bearer compatibility is not assumed. |
| JetBrains AI Assistant | PROTOCOL | Configure the remote MCP server in the IDE and verify custom-header/session support. |
| Amazon Q Developer CLI | PROTOCOL | Configure the remote MCP server and authentication; verify Streamable HTTP support for the installed version. |
| Replit Agent | UNKNOWN | Do not claim compatibility until a live initialize/tools-list/tools-call test passes. |
| Manus | UNKNOWN | Do not claim compatibility until its MCP connector exposes custom auth headers and a live handshake passes. |
| Grok / Grokbot | UNKNOWN | Do not claim compatibility until its MCP connector exposes custom auth headers and a live handshake passes. |
| Wajo | UNKNOWN | Do not claim compatibility until its MCP connector exposes custom auth headers and a live handshake passes. |

## Tool-level rules for all clients

- `conversations_list` is the first step when the target conversation is
  unknown.
- `conversation_get` uses the exact `session_key` returned by discovery.
- `messages_read` comes before consequential replies or external sends.
- `attachments_fetch` requires a `message_id` from `messages_read`.
- `events_poll` must advance `after_cursor`; `events_wait` must use a bounded
  timeout and cursor.
- `channels_list` discovers valid targets before `messages_send` when needed.
- `permissions_list_open` comes before `permissions_respond`; only respond to
  a known approval ID.
- Do not parallelize writes to the same conversation.
- Treat “sent”, “received”, and “answered” as separate states and verify the
  returned result.
- `hermes.ask` is stateless across calls unless the prompt includes the needed
  context; it does not continue a selected Telegram/Discord/etc. conversation.
- Do not put VEDA, KGS, or Hermes credentials in prompts or tool arguments.

## Current bridge boundary

The bridge is verified for the Instinct path and the direct `hermes.ask` flow.
It is not yet a full modern MCP transport: persistent GET streams, DELETE
cleanup, strict session validation, cancellation, and OAuth are not implemented.
Clients requiring those features need a compatibility layer or a future bridge
transport upgrade.

## Primary references

- [MCP client directory](https://github.com/modelcontextprotocol/docs/blob/main/clients.mdx)
- [VS Code MCP configuration](https://github.com/microsoft/vscode-docs/blob/main/docs/agents/reference/mcp-configuration.md)
- [GitHub Copilot CLI MCP servers](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-mcp-servers)
- [Cursor MCP documentation](https://docs.cursor.com/context/model-context-protocol)
- [Anthropic MCP documentation](https://docs.anthropic.com/en/docs/mcp)
