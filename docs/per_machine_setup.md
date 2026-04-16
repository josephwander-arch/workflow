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

## Two-Tier Storage

Workflow uses a two-tier storage model: metadata in JSON files, secrets in the OS keyring.

| Tier | What's stored | Location | Synced? |
|------|--------------|----------|---------|
| Metadata | Credential names, types, API patterns, TOTP entry names | `C:\CPC\workflows\*.json` | No (per-machine) |
| Secrets | Credential values, TOTP secrets | OS keyring (Windows Credential Manager / macOS Keychain / Linux Secret Service) | No (per-machine, by OS design) |

**Why two tiers?** The OS keyring encrypts secrets at the OS level, tied to the current user account. This means secret values never appear in plaintext files, and rotation is atomic (update keyring, all subsequent reads get the new value immediately).

**Startup probe:** On every start, the server runs a two-Entry sentinel probe: writes a timestamped value via one `Entry` instance, drops it, then reads via a fresh `Entry` with the same service+user. If the values don't match, the keyring backend is not persisting across instances (mock backend), and the server refuses to start. This catches misconfigured builds where `features = ["windows-native"]` is missing from the keyring dependency.

**Per-machine consequence:** Secrets do not transfer between machines. After installing on a new machine, re-run `workflow:credential_store` for each credential and `workflow:totp_register` / `workflow:totp_register_from_uri` for each TOTP entry.

## Workflow-Specific Notes

- **OS keyring encryption:** Credentials are encrypted by the OS keyring (Windows Credential Manager on Windows), tied to the current user account. Credentials **do not transfer between machines** — re-enter on each machine after install. This is by design (no credential sync risk).
- **Credential re-entry on new machines:** When setting up a second machine, re-run `workflow:credential_store` for each credential. The credential names and API patterns can be the same — only the encrypted values are machine-local.
- **Flow recording storage:** Recorded flows are stored in `%LOCALAPPDATA%\CPC\workflow\flows\` — per-machine, not synced. If you want the same flows on multiple machines, copy the `flows\` directory manually.
- **TOTP/HOTP secrets:** TOTP and HOTP secrets are stored in the OS keyring alongside credentials. Re-register on each machine using `workflow:totp_register` or `workflow:totp_register_from_uri`.
- **Data directory:** All workflow metadata (API patterns, watch definitions, workflow chains) lives in `C:\CPC\workflows\` as JSON files. Atomic writes (write to `.tmp`, then rename) protect against crash corruption.
- **Legacy DPAPI migration (v1.3.0+):** If you upgraded from a pre-v1.3.0 install, run `workflow:migrate_dpapi_to_keyring` once to move DPAPI-encrypted credentials to the OS keyring. Idempotent — safe to run multiple times.

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
