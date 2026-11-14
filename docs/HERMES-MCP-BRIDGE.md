# Hermes MCP Bridge

This bridge makes the local Hermes `mcp-serve` process reachable through an
HTTP MCP endpoint. It keeps Hermes, KGS, and VEDA on the laptop; it does not
copy or upload their data.

## Flow

```text
Instinct or another MCP client
        |
        | HTTPS + Authorization: Bearer <token>
        v
Cloudflare quick tunnel
        v
127.0.0.1:8787  (scripts/hermes-mcp-http-bridge.mjs)
        v
Hermes mcp-serve (stdio)
```

## Start locally

Run from the repository root. Keep the token outside the repository:

```powershell
$stateDir = "$env:LOCALAPPDATA\elastic-web"
New-Item -ItemType Directory -Force $stateDir | Out-Null
if (-not (Test-Path "$stateDir\bridge-token.txt")) {
  [Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Maximum 256 })) |
    Set-Content -NoNewline "$stateDir\bridge-token.txt"
}
$env:ELASTIC_HERMES_MCP_TOKEN = Get-Content -Raw "$stateDir\bridge-token.txt"
node scripts/hermes-mcp-http-bridge.mjs
```

Check it locally:

```powershell
Invoke-WebRequest http://127.0.0.1:8787/health
```

## Temporary public test

Install `cloudflared` separately, then run:

```powershell
cloudflared tunnel --url http://127.0.0.1:8787
```

Use the generated HTTPS URL with `/mcp`. Configure the MCP client with:

```json
{
  "url": "https://<temporary-host>/mcp",
  "headers": {
    "Authorization": "Bearer <contents-of-%LOCALAPPDATA%\\elastic-web\\bridge-token.txt>"
  }
}
```

The quick-tunnel URL is ephemeral. Stop `cloudflared` and the Node process
when the test is complete. Use a named tunnel plus an access policy for any
non-test deployment.

## Hermes conversation flow

After MCP initialization, clients should list or retrieve the relevant
conversation, read recent messages, and call `messages_send` when they need
Hermes to respond. The bridge adds this guidance to the MCP initialization
instructions.

## Security boundary

- The bridge binds to loopback only.
- Every `/mcp` request requires a bearer token.
- The token is never logged by the bridge and must not be committed.
- VEDA remains local; do not expose the vault as a filesystem endpoint.
- Do not publish an unauthenticated Vercel proxy for this bridge.
