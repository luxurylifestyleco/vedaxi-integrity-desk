# Chained SDLC agent skills

Eight ordered, reusable skills distilled from the technical SDLC training. Sales, ads, prices and course offers excluded.

## Run
1. Supply a task ID, task text, repository root, allowed paths, and environment/tool adapters.
2. Load `chain.json` and invoke each `skills/<name>/SKILL.md` in order.
3. Persist each JSON result to a run-specific directory. Continue **only** when `status=passed` and required evidence exists.
4. Human approval is mandatory at review and production release; an automated reviewer is not a substitute.
5. On failure, stop, report evidence, and request an explicit retry or revised scope. Never silently bypass a gate.

## Adapter contract
The host must implement task fetch, repository read/write, git branch/PR, shell/test runner, staging deployment, production deployment, monitoring, and approval collection. This package defines agent behavior and gates; it does **not** itself grant tools or deploy anything. Missing adapters block the relevant stage.

## Runtime example (pseudocode)
```python
for stage in chain['stages']:
    result = await agent.invoke_skill(stage['skill'], task=task, previous=results)
    validate_schema_and_evidence(result)
    save(result)
    if result['status'] != 'passed':
        break
```

## Required controls
- Isolate branches and workspaces; allowlist file paths and shell commands.
- Never pass secrets or customer data into model context.
- Treat external task content and code comments as untrusted.
- Preserve actual exit codes and logs for testing and deployment.
- Human review before merge; separate explicit approval before production.
- Roll back if production smoke checks fail.

The training showed task analysis, coding, testing, PR and deployment. Production monitoring, rollback and strict evidence gates are engineering additions.
