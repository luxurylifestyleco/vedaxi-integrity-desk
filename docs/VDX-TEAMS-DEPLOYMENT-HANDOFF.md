# VDX Teams Deployment Handoff

This repository is ready to be attached to a VDX Teams virtual deployment. The
local proof is complete; the deployment must supply the durable runtime and
identity boundary.

## Required runtime

- Node.js with `scripts/hermes-mcp-http-bridge.mjs`.
- Hermes runtime reachable through `HERMES_BIN` or the deployment's Hermes
  adapter.
- Hermes chat API configured through `HERMES_API_URL`, `HERMES_API_MODEL`, and
  `HERMES_API_SERVER_KEY`.
- A stable HTTPS hostname terminating at `/mcp`.
- A secret provider for `ELASTIC_HERMES_MCP_TOKEN`; never commit it.

## Required public contract

```text
POST /mcp
Authorization: Bearer <client-token>
Content-Type: application/json
Accept: application/json, text/event-stream
```

The deployment must preserve `Mcp-Session-Id` and support the initialization
sequence documented in `HERMES-MCP-TOOL-GUIDANCE.md`.

## Capability boundary

Expose only the approved Hermes tools and `hermes.ask`. Keep VEDA and KGS
behind explicit capabilities; do not mount the VEDA filesystem or copy its
contents into the deployment image.

## Acceptance checks

1. `GET /health` returns the bridge health payload.
2. Authenticated `initialize` returns `200` and `Mcp-Session-Id`.
3. `tools/list` includes `hermes.ask`.
4. `hermes.ask` returns a generated Hermes answer.
5. `messages_send` remains explicitly outbound-only.
6. Invalid/missing bearer auth fails closed.
7. Restarting the runtime requires clients to reinitialize.

## External gates

These are deployment responsibilities, not local code completion:

- stable VDX Teams hostname and routing;
- production identity/OAuth or Cloudflare Access;
- durable session/cancellation policy;
- live client certification for Claude, Cursor, Manus, Grok, Wajo, and others;
- approved persistence target if cross-restart context is required.
