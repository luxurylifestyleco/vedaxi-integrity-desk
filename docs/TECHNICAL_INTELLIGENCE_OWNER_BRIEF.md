# Technical Intelligence Owner Brief

Baseline date: 2026-10-28. This brief is decision support, not a release approval.

Execution status: E01 is PARTIAL. Offline self-tests and the targeted four-test contracts evaluator ran; the four-axis public/private runner baseline was not measured. E02-E06 remain unexecuted.

## What matters now

The lowest-risk path is to measure the existing public and private runners before adding infrastructure. The public Elastic repository already has IntentIR, capability registry/retrieval, recipes, DAG execution, A2A, MCP, WebMCP projection, and local telemetry. The private runtime adds Postgres-backed traces, tenant controls, idempotency, receipts, kill switch, and replay, but those capabilities are not deployment-verified in this scan.

The customer promise should remain prompt-first: one request, the smallest useful capability path, a truthful result/receipt, and explicit approval only when needed. Drag/drop is not justified until E06 shows a real usability gap.

## Decisions and non-decisions

- Keep `public-repos/vedaxi-elastic/docs/PROTOCOL_ADAPTERS.md` as protocol authority.
- Keep `.delivery/progress.md` and existing task briefs as execution backlog.
- Use [TECHNICAL_INTELLIGENCE_REGISTER.md](TECHNICAL_INTELLIGENCE_REGISTER.md) as the umbrella intelligence register.
- Do not add Railway, Temporal, Dapr, a mesh, Redis, a second telemetry database, or real payment authority without an experiment showing a current requirement.
- Do not treat SDK advisory absence as proof that custom auth is safe.
- Do not treat unsigned internal receipts as external execution proof.
- Do not promote historical VDX claims into current architecture without source and runtime evidence.

## Proposed decision gates

1. Complete E01's four-axis public/private baseline and establish acceptance thresholds before optimization; the current offline evidence is insufficient.
2. E02/E03 establish recovery, idempotency, tenant isolation, and security boundaries.
3. E04 establishes actual protocol/browser compatibility against pinned versions and current implementations.
4. E05 decides whether exact reuse or routing is worth complexity.
5. E06 decides whether the prompt-first experience needs a visual builder.

No experiment is authorized to create production side effects, new paid services, or real payment authority.

## Source catalogue

Primary sources consulted are linked from the register: MCP versioning, A2A releases, WebMCP draft, Temporal workflow/replay/MCP integration docs, Dapr hosting/release notes, OAuth RFC 9700, routing papers/repository, prompt-caching guidance, AP2/x402 specifications, PostgreSQL dump guidance, Supabase self-hosting, and OpenTelemetry GenAI conventions. External sources provide context and constraints; repository source and runtime evidence determine VEDAXI status.

## Review questions

- Does the existing private runtime pass E02 without a duplicate synthetic side effect?
- Does E03 prove tenant, audience, and task ownership across every read/write/cancel path?
- Does E04 show the installed browser API and protocol versions actually interoperate?
- Does E05 improve successful-task cost/latency enough to justify added state or routing complexity?
- Does E06 reduce customer actions without hiding approval, provenance, or failure?

## Operating state checked 2026-10-28

The automation service confirmed three enabled read-only schedules: daily security review beginning October 29 around 09:00 Asia/Kolkata, weekly research review beginning November 2, and monthly architecture review beginning November 28. Each is flexible within one hour. No code-change or auto-execution authority is attached. Incident/release event monitoring is not connected; do not infer GitHub Actions or event-driven monitoring from local configuration.
