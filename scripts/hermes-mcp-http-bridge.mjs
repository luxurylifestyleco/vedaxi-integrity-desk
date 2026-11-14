import { randomBytes, randomUUID } from "node:crypto";
import { readFileSync } from "node:fs";
import { createServer } from "node:http";
import { spawn } from "node:child_process";
import { createInterface } from "node:readline";

const host = "127.0.0.1";
const port = Number(process.env.HERMES_MCP_HTTP_PORT || 8787);
const token = process.env.ELASTIC_HERMES_MCP_TOKEN || randomBytes(24).toString("hex");
const hermesBin = process.env.HERMES_BIN || "C:\\Users\\m_jor\\AppData\\Local\\hermes\\bin\\hermes.exe";
const maxBodyBytes = 1024 * 1024;
const allowedOrigin = process.env.ELASTIC_HERMES_MCP_ORIGIN || "";
const hermesApiUrl = process.env.HERMES_API_URL || "http://127.0.0.1:8642/v1/chat/completions";
const hermesApiModel = process.env.HERMES_API_MODEL || "hermes-agent";
const hermesEnvPath = process.env.HERMES_ENV_PATH || "C:\\Users\\m_jor\\AppData\\Local\\hermes\\.env";

function localEnvValue(name) {
  try {
    const line = readFileSync(hermesEnvPath, "utf8")
      .split(/\r?\n/)
      .find((entry) => new RegExp(`^\\s*${name}\\s*=`).test(entry));
    return line?.split("=", 2)[1]?.trim().replace(/^['\"]|['\"]$/g, "") || "";
  } catch {
    return "";
  }
}

async function askHermes(arguments_) {
  const prompt = typeof arguments_?.prompt === "string" ? arguments_.prompt.trim() : "";
  if (!prompt || prompt.length > 12000) throw new Error("prompt must be 1-12000 characters");
  const apiKey = process.env.HERMES_API_SERVER_KEY || localEnvValue("API_SERVER_KEY");
  if (!apiKey) throw new Error("Hermes API key is not configured");
  const response = await fetch(hermesApiUrl, {
    method: "POST",
    headers: { Authorization: `Bearer ${apiKey}`, "Content-Type": "application/json" },
    body: JSON.stringify({ model: hermesApiModel, messages: [{ role: "user", content: prompt }], stream: false }),
    signal: AbortSignal.timeout(60000),
  });
  if (!response.ok) throw new Error(`Hermes API returned ${response.status}`);
  const payload = await response.json();
  const answer = payload?.choices?.[0]?.message?.content;
  if (typeof answer !== "string") throw new Error("Hermes API returned no answer");
  return { content: [{ type: "text", text: answer }] };
}

const hermesAskTool = {
  name: "hermes.ask",
  description: "Submit a prompt to the local Hermes runtime and return its generated answer.",
  inputSchema: {
    type: "object",
    properties: { prompt: { type: "string", description: "The message to send to Hermes." } },
    required: ["prompt"],
    additionalProperties: false,
  },
};

const child = spawn(hermesBin, ["mcp-serve"], { stdio: ["pipe", "pipe", "pipe"] });
const pending = new Map();
let stderr = "";
let requestChain = Promise.resolve();

function failPending(error) {
  for (const { reject } of pending.values()) reject(error);
  pending.clear();
}

child.on("error", (error) => {
  failPending(new Error("Hermes process unavailable"));
});
child.on("exit", () => failPending(new Error("Hermes process exited")));
child.stderr.on("data", (chunk) => {
  stderr = `${stderr}${chunk}`.slice(-4000);
});

const lines = createInterface({ input: child.stdout });
lines.on("line", (line) => {
  if (!line.trim()) return;
  let message;
  try { message = JSON.parse(line); } catch { return; }
  if (message.id === undefined) return;
  const waiter = pending.get(message.id);
  if (!waiter) return;
  pending.delete(message.id);
  waiter.resolve(message);
});

function sendToHermes(message) {
  return new Promise((resolve, reject) => {
    if (child.exitCode !== null || child.killed) return reject(new Error("Hermes process unavailable"));
    pending.set(message.id, { resolve, reject });
    child.stdin.write(`${JSON.stringify(message)}\n`);
    setTimeout(() => {
      if (!pending.has(message.id)) return;
      pending.delete(message.id);
      reject(new Error("Hermes MCP response timed out"));
    }, 30000).unref();
  });
}

function authorized(request) {
  return request.headers.authorization === `Bearer ${token}`;
}

function reply(response, status, body, request = null, extraHeaders = {}) {
  if (status === 204) {
    response.writeHead(status);
    response.end();
    return;
  }
  const data = JSON.stringify(body);
  const wantsEventStream = request?.headers.accept?.includes("text/event-stream");
  const headers = {
    "Content-Type": wantsEventStream ? "text/event-stream" : "application/json",
    "Cache-Control": "no-store",
    "Access-Control-Allow-Headers": "Authorization, Content-Type, MCP-Protocol-Version",
    ...extraHeaders,
  };
  if (allowedOrigin) headers["Access-Control-Allow-Origin"] = allowedOrigin;
  const payload = wantsEventStream ? `event: message\ndata: ${data}\n\n` : data;
  headers["Content-Length"] = Buffer.byteLength(payload);
  response.writeHead(status, headers);
  response.end(payload);
}

const server = createServer(async (request, response) => {
  if (request.method === "OPTIONS") return reply(response, 204, {});
  if (request.url === "/health" && request.method === "GET") {
    return reply(response, 200, { status: child.exitCode === null ? "ok" : "down", service: "elastic-hermes-mcp-bridge" });
  }
  if (request.url !== "/mcp" || request.method !== "POST") return reply(response, 404, { error: "not found" });
  if (!authorized(request)) return reply(response, 401, { error: "bearer token required" });

  let raw = "";
  for await (const chunk of request) {
    raw += chunk;
    if (Buffer.byteLength(raw) > maxBodyBytes) {
      request.destroy();
      return reply(response, 413, { error: "request too large" });
    }
  }
  try {
    const message = JSON.parse(raw);
    if (!message || typeof message !== "object" || message.jsonrpc !== "2.0" || typeof message.method !== "string") {
      return reply(response, 400, { error: "invalid JSON-RPC request" });
    }
    if (message.method.startsWith("notifications/")) return reply(response, 204);
    requestChain = requestChain.catch(() => {}).then(async () => {
      if (message.method === "tools/call" && message.params?.name === "hermes.ask") {
        return { jsonrpc: "2.0", id: message.id, result: await askHermes(message.params.arguments) };
      }
      return sendToHermes(message);
    });
    const result = await requestChain;
    if (message.method === "tools/list" && result?.result?.tools && !result.result.tools.some((tool) => tool.name === hermesAskTool.name)) {
      result.result.tools.push(hermesAskTool);
    }
    const sessionHeaders = message.method === "initialize"
      ? { "Mcp-Session-Id": randomUUID() }
      : {};
    if (message.method === "initialize" && result?.result) {
      result.result.instructions = `${result.result.instructions || ""} Use this server as a live Hermes messaging bridge: list or retrieve the relevant conversation, read recent messages for context, then call messages_send when a reply is required. Wait for and use the tool result before responding.`.trim();
    }
    reply(response, 200, result, request, sessionHeaders);
  } catch (error) {
    reply(response, 502, { error: "Hermes MCP request failed" });
  }
});

server.listen(port, host, () => {
  console.log(JSON.stringify({ service: "elastic-hermes-mcp-bridge", endpoint: `http://${host}:${port}/mcp` }));
});

function shutdown() {
  server.close();
  child.kill();
}
process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);
