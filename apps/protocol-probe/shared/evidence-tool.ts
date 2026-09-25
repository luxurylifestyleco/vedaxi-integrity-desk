import {
  projectElasticCapabilityToWebMcp,
  searchEvidence,
  type ElasticCapabilityContract,
  type EvidenceObject,
  type WebMcpTool
} from "@vedaxi/contracts";

const MAX_QUERY_LENGTH = 160;

function validateQuery(input: unknown): string {
  if (!input || typeof input !== "object" || Array.isArray(input)) {
    throw new Error("input must contain only query");
  }

  const fields = input as Record<string, unknown>;
  if (Object.keys(fields).length !== 1 || !("query" in fields)) {
    throw new Error("input must contain only query");
  }

  const query = fields.query;
  if (typeof query !== "string" || query.trim().length === 0) {
    throw new Error("query must be a non-blank string");
  }

  if (query.length > MAX_QUERY_LENGTH) {
    throw new Error("query is too long");
  }

  return query;
}

export function createReadOnlyEvidenceTool(
  name: string,
  title: string,
  description: string,
  evidence: EvidenceObject
): WebMcpTool {
  const capability: ElasticCapabilityContract = {
    id: name,
    name: title,
    description,
    domain: "evidence",
    inputs: {
      type: "object",
      properties: { query: { type: "string", maxLength: MAX_QUERY_LENGTH, pattern: "\\S" } },
      required: ["query"],
      additionalProperties: false
    },
    outputs: { type: "object", properties: { results: { type: "array" } } },
    permissions: ["evidence:read"],
    provider: evidence.sourceOrigin,
    protocol: "webmcp",
    endpoint: evidence.locator,
    metadata: { provenance: evidence.provenance }
  };
  return projectElasticCapabilityToWebMcp(
    capability,
    async (_capability, input) => searchEvidence(validateQuery(input), [evidence]),
    { readOnlyHint: true, untrustedContentHint: true }
  );
}
