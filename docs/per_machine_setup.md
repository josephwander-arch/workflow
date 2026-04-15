# Workflow — Per-Machine Setup

This guide covers everything you need to do on each machine where you want to run the `workflow` MCP server.

## Per-Machine Checklist

| Item | Per-machine? | How to set up |
|---|---|---|
| MCP binary | Yes | Download from GitHub release → `C:\CPC\servers\workflow.exe`. Pick right arch (`_arm64.exe` or `_x64.exe`). |
| Claude Desktop config | Yes | Edit `%APPDATA%\Claude\claude_desktop_config.json` — copy entry from `claude_desktop_config.example.json` in this repo into your `mcpServers` object. |
| Per-machine paths | Yes | Will be auto-detected by `cpc-paths` (forthcoming). For now, set env vars or hardcode in your config. See "Path Configuration" below. |
| User preferences | Yes | Open Claude Desktop → Settings → Profile → paste your preferences. (UI-only, can't script.) |
| Skills (optional) | Yes | If using CPC skills system, mirror from your Drive's `Volumes/skills/{skill}/` to `%LOCALAPPDATA%\claude-skills\{skill}\`. |
| OS keyring credentials | Yes | Run `workflow:credential_store` per credential after first install on each machine. Credentials are encrypted per-machine with Windows DPAPI and do not sync automatically. (Forthcoming: keyring migration planned for v1.3.0.) |
| Volumes / knowledge base | No (Drive-synced) | If Volumes is on Google Drive, just verify Drive is syncing on each machine. No copy needed. |

## Workflow-Specific Notes

- **Windows DPAPI encryption:** Credentials are encrypted using Windows DPAPI, which ties them to the current user account on the current machine. This means credentials **do not transfer between machines** — you must run `workflow:credential_store` on each machine after install. This is by design (no credential sync risk).
- **Credential re-entry on new machines:** When setting up a second machine, re-run `workflow:credential_store` for each credential you need. The credential names and API patterns can be the same — only the encrypted values are machine-local.
- **Flow recording storage:** Recorded flows are stored in `%LOCALAPPDATA%\CPC\workflow\flows\` — per-machine, not synced. If you want the same flows on multiple machines, copy the `flows\` directory manually.
- **TOTP/HOTP secrets:** TOTP and HOTP secrets are stored in the same DPAPI-encrypted store as credentials. Re-register them on each machine using `workflow:totp_register` or `workflow:totp_register_from_uri`.
- **Data directory:** All workflow data (API patterns, watch definitions, workflow chains) lives in `C:\CPC\workflows\` as JSON files. Atomic writes (write to `.tmp`, then rename) protect against crash corruption.
- **v1.3.0 keyring migration (planned):** A future release will migrate from DPAPI to a cross-platform OS keyring. Until then, credential setup is a required manual step on each machine.

**Test post-install:** `workflow:credential_list` should return an empty list cleanly (no errors, no panics).

## Path Configuration

**Coming in `cpc-paths` (next release):** automatic detection of Volumes path, install path, backups path. Auto-writes `.cpc-config.toml` on first run. Until then, paths are detected via env vars with fallbacks:

| Path | Env var | Default fallback |
|---|---|---|
| Volumes (knowledge base) | `CPC_VOLUMES_PATH` | `C:\My Drive\Volumes` (Windows) |
| Install (server binaries) | `CPC_INSTALL_PATH` | `C:\CPC\servers` (Windows) |
| Backups | `CPC_BACKUPS_PATH` | `%LOCALAPPDATA%\CPC\backups` (Windows) |

If you're on a different platform or your Drive is mounted elsewhere, set the env vars in your shell profile or system environment before launching Claude Desktop.

## Future: cpc-setup.exe (planned)

A single-binary helper that automates this entire per-machine setup is planned. It will:
- Detect platform + architecture
- Download the right MCP server binary from GitHub releases
- Auto-detect Volumes / install / backup paths and write `.cpc-config.toml`
- Mirror skills from your Drive (if using CPC skills system)
- Generate a `claude_desktop_config.json` snippet ready to paste

Until cpc-setup.exe ships, follow the manual steps above.
