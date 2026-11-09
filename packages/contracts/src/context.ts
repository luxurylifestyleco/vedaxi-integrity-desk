/**
 * Typed context passed between Elastic workflow steps.
 *
 * This is intentionally storage- and vendor-neutral. Railway/Postgres,
 * KGS, Graphiti, or a future workflow engine may implement the backing
 * adapters without changing the recipe or WebMCP contracts.
 */

export type ContextFactSource =
  | "explicit_user"
  | "authorized_provider"
  | "observed_behavior"
  | "inferred"
  | "workflow"
  | "external_reference";

export interface ContextEvidenceRef {
  id: string;
  source: string;
  observedAt: string;
  locator?: string;
}

export interface ContextFact<T = unknown> {
  key: string;
  value: T;
  source: ContextFactSource;
  confidence: number;
  validFrom?: string;
  validUntil?: string;
  observedAt: string;
  evidence: ContextEvidenceRef[];
  sensitivity: "public" | "personal" | "financial";
}

export interface ContextPacket {
  requestId: string;
  userId: string;
  tenantId?: string;
  assembledAt: string;
  facts: ContextFact[];
  missing: string[];
  nextAction?: string;
}

export interface WorkflowStepResult<T = unknown> {
  workflowRunId: string;
  stepId: string;
  status: "completed" | "waiting_for_user" | "blocked" | "failed";
  result?: T;
  evidence: ContextEvidenceRef[];
  retryable: boolean;
}
