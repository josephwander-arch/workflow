# Example: Credential Storage and Management

DPAPI-encrypted credential vault patterns.

## Store a Bearer Token

```
workflow:credential_store(
  name: "github_pat",
  value: "ghp_REPLACE_WITH_YOUR_GITHUB_TOKEN",
  credential_type: "bearer",
  service: "github",
  notes: "Personal access token, fine-grained, expires 2026-12-31"
)
```

## Store an API Key

```
workflow:credential_store(
  name: "openai_key",
  value: "sk-REPLACE_WITH_YOUR_OPENAI_KEY",
  credential_type: "api_key",
  service: "openai",
  notes: "Injected as X-API-Key header"
)
```

## Store Basic Auth

```
workflow:credential_store(
  name: "jenkins_basic",
  value: "dXNlcjpwYXNz",
  credential_type: "basic",
  service: "jenkins",
  notes: "Base64-encoded user:pass"
)
```

## List Credentials (Safe — Never Shows Values)

```
workflow:credential_list()
→ [
    {name: "github_pat", credential_type: "bearer", service: "github", created_at: "2026-03-15T10:00:00Z"},
    {name: "openai_key", credential_type: "api_key", service: "openai", created_at: "2026-03-16T14:30:00Z"},
    {name: "jenkins_basic", credential_type: "basic", service: "jenkins", created_at: "2026-03-17T09:00:00Z"}
  ]
```

Filter by service:

```
workflow:credential_list(service: "github")
```

## Retrieve a Credential (Decrypted)

```
workflow:credential_get(name: "github_pat")
→ {name: "github_pat", value: "ghp_REPLACE_WITH_YOUR_GITHUB_TOKEN", credential_type: "bearer"}
```

Only succeeds for the same Windows user who stored it.

## Token Rotation Pattern

When a token expires or is rotated:

```
# Store the new value (upserts — replaces existing)
workflow:credential_store(
  name: "github_pat",
  value: "ghp_yyyyyyyyyyyyyyyyyyyy",
  credential_type: "bearer",
  service: "github"
)

# Verify all API patterns still work
workflow:api_test(name: "github_repos")
→ {works: true, status: 200}
```

All API patterns referencing `github_pat` via `credential_ref` automatically use the new value. No pattern updates needed.

## OAuth Refresh Flow

For OAuth endpoints that support refresh tokens:

```
# First time — provide token URL and client ID (stored for future refreshes)
workflow:credential_refresh(
  name: "payer_refresh",
  token_url: "https://auth.example-health.com/oauth2/token",
  client_id: "your_client_id"
)

# Subsequent refreshes — just the name
workflow:credential_refresh(name: "payer_refresh")
→ {refreshed: true, new_expiry_seconds: 3600}

# Always test after refresh
workflow:api_test(name: "payer_fhir_patient_search", params: {"name": "test"})
```

## Security Notes

- Values are encrypted with Windows DPAPI (current user's key, current machine)
- Plaintext never touches the filesystem
- Credentials stored in `C:\CPC\workflows\credentials.json` as DPAPI-encrypted base64
- On non-Windows: unencrypted storage (development/testing only — not for production secrets)
- Deleting a credential is immediate and irreversible — check `api_list` for references first
