# Workflow MCP Server — Recommended CLAUDE.md Instructions

Copy the block below into your CLAUDE.md (global or project-level).

---

```markdown
## Workflow MCP Server Rules

### Credentials
- ALWAYS store credentials via `workflow:credential_store` with a reference name.
- NEVER hardcode tokens, API keys, or passwords in `api_store` headers or body templates.
- Use `credential_ref` in `api_store` to reference the vault. When tokens rotate, update one credential — all patterns follow.
- After `credential_store` or `credential_refresh`, ALWAYS run `api_test` to confirm the new credential works.

### API Patterns — The Graduation Discipline
- Whenever you find yourself doing the same browser task twice, graduate it:
  1. `hands:browser_learn_api` to extract the endpoint pattern
  2. `workflow:api_store` to save it with `credential_ref`
  3. `workflow:api_test` to validate
  4. From then on: `workflow:api_call` — no browser needed.
- Always use `api_test` before `api_call` in production pipelines or after any token rotation.
- When `api_call` returns `fallback_hint`, fall back to hands browser automation — the API broke, go re-discover.

### Flows — Experimental
- `flow_record_*`, `flow_replay`, `flow_adapt`, `flow_dispatch` are EXPERIMENTAL (v1.1.1).
- Use for prototyping. Do not rely on flows for production-critical automation yet.
- `flow_replay` returns an execution plan — it does NOT execute tools. Your session runs the plan.

### Data Transforms
- Use `pipe_test` with `show_intermediate: true` to debug pipelines before production use.
- `transform_pipe` operations chain sequentially — output of each step feeds the next.

### Watches and Workflows
- `watch_check` and `workflow_run` return instructions/plans — they don't execute tools directly.
- Scheduled watches and dispatched flows require an external scheduled-tasks server for unattended execution.
```

---

**What this covers:**
- Credential-by-reference mandate (the #1 security rule)
- The graduation discipline (browser→API pattern)
- api_test-before-api_call in production
- Honest experimental marking for flows
- Execution model clarity (plans, not direct execution)

**What this doesn't cover** (intentionally — keep CLAUDE.md lean):
- Individual tool parameters (that's what the skill file is for)
- Troubleshooting (skill file)
- Storage internals (skill file)
