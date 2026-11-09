import "jsr:@supabase/functions-js/edge-runtime.d.ts";

type ChatRequest = {
  message?: unknown;
  context_id?: unknown;
  idempotency_key?: unknown;
};

const json = (body: Record<string, unknown>, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });

function stableId(prefix: string, value: string): string {
  const encoded = btoa(value).replaceAll("+", "-").replaceAll("/", "_").replaceAll("=", "");
  return `${prefix}_${encoded.slice(0, 32)}`;
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  const authorization = req.headers.get("authorization") ?? "";
  const subject = authorization.startsWith("Bearer ") ? "jwt-present" : "";
  if (!subject) return json({ error: "missing_bearer_token" }, 401);

  let input: ChatRequest;
  try {
    input = await req.json();
  } catch {
    return json({ error: "invalid_json" }, 400);
  }

  const message = typeof input.message === "string" ? input.message.trim() : "";
  if (!message) return json({ error: "message_required" }, 400);

  const contextId = typeof input.context_id === "string" && input.context_id.trim()
    ? input.context_id.trim()
    : "demo-context";
  const idempotencyKey = typeof input.idempotency_key === "string" && input.idempotency_key.trim()
    ? input.idempotency_key.trim()
    : message;
  const taskId = stableId("task", `${contextId}:${idempotencyKey}`);
  const sessionId = stableId("session", contextId);

  return json({
    simulated: true,
    session: { session_id: sessionId, context_id: contextId, principal_kind: "agent" },
    task: {
      task_id: taskId,
      context_id: contextId,
      state: "completed",
      cancel_state: "not_requested",
      correlation: { session_id: sessionId, intent_id: null, outcome_id: null },
    },
    message: {
      role: "agent",
      parts: [{ kind: "text", text: `Simulated response: ${message}` }],
    },
    authority: "simulation-only",
    persistence: "not-written",
  });
});
