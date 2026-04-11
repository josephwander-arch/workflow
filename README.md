# Workflow MCP Server

API pattern storage and replay, DPAPI-encrypted credential vault, data transform pipelines, watch polling, and workflow chains — all through one MCP server. Single Rust binary, 30 tools, zero runtime dependencies.

**Workflow is the graduation pipeline partner for [hands](https://github.com/josephwander-arch/hands).** Use hands to automate a browser task once, capture the underlying API calls with `hands:browser_learn_api`, store them with `workflow:api_store`, then replay via direct HTTP forever. No browser needed on future runs. 100x faster.

## The Graduation Pipeline

```
Day 1: Browser automation (hands MCP server)
        ↓ hands:browser_learn_api extracts endpoint patterns from network traffic
Day 2: Store patterns (workflow:api_store)
        ↓ Named pattern with URL template, headers, credential reference
Day N: Direct HTTP replay (workflow:api_call)
        ↓ No browser. No Chrome. No selectors. Just HTTP.
```

**The economics:**
- Browser session: ~3-5 seconds startup + page load + interaction + fragile selectors
- API call: ~50-200ms, no browser process, no DOM, no breakage from UI redesigns

**Production proof:** 24+ stored API patterns in daily use across Humana, Aetna, and UnitedHealthcare/Optum FHIR endpoints for Medicare insurance brokerage. Real `last_used` timestamps. No browser window ever opens.

## Capabilities

### PRODUCTION (stable, battle-tested)

| Category | Tools | Description |
|----------|-------|-------------|
| API Patterns | `api_store`, `api_call`, `api_list`, `api_test`, `api_delete` | Store discovered API patterns with URL templates and credential references, replay via direct HTTP |
| Credentials | `credential_store`, `credential_get`, `credential_list`, `credential_delete`, `credential_refresh` | Windows DPAPI-encrypted credential vault. Store by name, reference from API patterns. OAuth refresh support. |
| Transforms | `transform_pipe`, `pipe_test` | JSON transform pipelines: pick, rename, flatten, filter, template, group_by, math. Chain operations sequentially. |
| Watches | `watch_define`, `watch_list`, `watch_check`, `watch_schedule`, `watch_delete` | Define polling conditions, trigger actions when conditions are met |
| Workflows | `workflow_define`, `workflow_run`, `workflow_list`, `workflow_status`, `workflow_delete` | Trigger-action chains composing watches, API calls, and transforms |

### EXPERIMENTAL (functionally complete, not production-validated)

| Category | Tools | Description |
|----------|-------|-------------|
| Flows | `flow_record_start`, `flow_record_step`, `flow_record_stop`, `flow_replay`, `flow_adapt`, `flow_dispatch`, `flow_list`, `flow_delete` | Record and replay multi-step MCP tool sequences. 1 test flow stored, never run in production. Use for prototyping. A follow-up release will harden based on real-world usage. |

**30 tools total** across 6 modules.

## Install

### Download

Grab the binary for your platform:

- **x64 Windows**: [workflow_x64_windows.exe](https://github.com/josephwander-arch/workflow/releases/latest/download/workflow_x64_windows.exe)
- **ARM64 Windows**: [workflow_arm64_windows.exe](https://github.com/josephwander-arch/workflow/releases/latest/download/workflow_arm64_windows.exe)

Rename to `workflow.exe` and place wherever you keep your MCP server binaries.

### Claude Desktop Config

Add this to your `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "workflow": {
      "command": "C:/path/to/workflow.exe",
      "args": []
    }
  }
}
```

See `claude_desktop_config.example.json` for the full snippet with both architecture options.

### Prerequisites

- **Windows 10/11** — DPAPI credential encryption requires Windows. On other platforms, credentials are stored unencrypted (development/testing only).
- No Node.js, no Python, no runtime dependencies.

### Verify Installation

Run `doctor.ps1` to check your setup:

```powershell
.\doctor.ps1
```

## Quickstart — The Graduation Flow

This is the core use case. You've been using hands to automate a browser task. Now graduate it to a direct API call.

### Step 1: Discover the API (hands)

```
hands:browser_launch()
hands:browser_navigate(url: "https://portal.humana.com")
# ... interact with the page ...
hands:browser_learn_api()  → extracts endpoint patterns
```

### Step 2: Store credentials and pattern (workflow)

```
workflow:credential_store(
  name: "humana_token",
  value: "<captured_bearer_token>",
  credential_type: "bearer",
  service: "humana"
)

workflow:api_store(
  name: "humana_member_search",
  url_pattern: "https://api.humana.com/fhir/Patient?name={name}",
  method: "GET",
  credential_ref: "humana_token",
  notes: "Discovered via browser_learn_api 2026-03-15"
)
```

### Step 3: Test it

```
workflow:api_test(name: "humana_member_search", params: {"name": "Smith"})
```

### Step 4: Use it forever — no browser

```
workflow:api_call(name: "humana_member_search", params: {"name": "Jones"})
```

When the API breaks (token expired, endpoint changed), the response includes a `fallback_hint` telling you to go back to the browser. Re-discover, re-graduate.

## Key Concepts

### Credential by Reference

Never hardcode tokens in API patterns. Store credentials by name in the DPAPI-encrypted vault, reference them via `credential_ref` in `api_store`. When tokens rotate, update one credential — all patterns that reference it automatically get the new value.

### Execution Model

`flow_replay`, `watch_check`, and `workflow_run` return **execution plans**, not results. They tell your session what tools to call with what parameters. Your session executes the plan. This is by design — workflow doesn't have access to other MCP servers.

### Data Storage

All data lives in `C:\CPC\workflows\` as JSON files with atomic writes (write to `.tmp`, then rename). Safe against crashes mid-write.

## Recommended CLAUDE.md Instructions

See `skills/workflow-recommended-instructions.md` for a copy-paste block to add to your CLAUDE.md. Covers the credential-by-reference mandate, graduation discipline, and experimental flow warnings.

## Examples

See the `examples/` directory:
- `graduation_pipeline.md` — Full hands-to-workflow graduation walkthrough
- `credential_storage.md` — DPAPI vault patterns and token rotation
- `api_pattern_replay.md` — Advanced API patterns with transforms

## Pairs With: hands MCP Server

Workflow and hands are designed as two halves of the same pipeline.

| Scenario | Use |
|----------|-----|
| First time doing a task | hands (browser) |
| Task has a known API pattern | workflow (api_call) |
| API call fails / token expired | hands (browser re-auth) then workflow (credential_store) |
| Need to transform API response | workflow (transform_pipe) |
| Need to poll for changes | workflow (watch_define) |

---

## Compatible With

Works with any MCP client. Common install channels:

- **Claude Desktop** (the main chat app) — add to `claude_desktop_config.json`. See `claude_desktop_config.example.json` in this repo.
- **Claude Code** — add to `~/.claude/mcp.json`, or point your `CLAUDE.md` at `skills/workflow.md` to load it as a skill instead.
- **OpenAI Codex CLI** — register via Codex's MCP config, or load the skill directly.
- **Gemini CLI** — register via Gemini's MCP config, or load the skill directly.

**Two install layouts:**

1. **Local folder** — clone or download this repo, then point your client at the local directory or the extracted `.exe` binary.
2. **Installed binary** — grab the `.exe` from the [Releases](https://github.com/josephwander-arch/workflow/releases) page, place it wherever you keep your MCP binaries, then register its path in your client's config.

**Also ships as a skill** — if your client supports Anthropic skill files, load `skills/workflow.md` directly. Skill-only mode gives you the behavioral guidance without running the server; useful for planning, review, or read-only workflows.

### First-run tip: enable "always-loaded tools"

For the smoothest experience, enable **tools always loaded** in your Claude client settings (Claude Desktop: Settings → Tools, or equivalent in Claude Code / Codex / Gemini). This ensures Claude recognizes the tool surface on first use without needing to re-discover it every session. Most users hit friction on day one because this is off by default.

## License

Apache 2.0 — see [LICENSE](LICENSE).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## Contact

Joseph Wander — protipsinc@gmail.com
GitHub: [github.com/josephwander-arch](https://github.com/josephwander-arch/)

## Donations

If this project saves you time, consider supporting development:

**$NeverRemember** (Cash App)
