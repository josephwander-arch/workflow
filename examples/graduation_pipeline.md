# Example: Graduation Pipeline — Browser to API

The graduation pipeline is workflow's core use case. You automate a task via browser once, capture the underlying API, then replay it as direct HTTP forever.

## Scenario

You need to look up patient data against an example healthcare payer's FHIR endpoint. Currently you do this through the browser every time.

## Step 1: Browser Discovery (hands MCP server)

Launch a browser session and perform the task manually while hands captures network traffic:

```
hands:browser_launch()
hands:browser_navigate(url: "https://portal.example-health.com/login")
hands:browser_type(a11y_ref: "username_field", text: "user@example.com")
hands:browser_type(a11y_ref: "password_field", text: "***")
hands:browser_click(a11y_ref: "login_button")
hands:browser_navigate(url: "https://portal.example-health.com/fhir/Patient?name=Smith")
```

Now extract the API pattern from the recorded network traffic:

```
hands:browser_learn_api()
```

This returns the underlying HTTP calls — URL patterns, methods, headers, auth tokens.

## Step 2: Store Credential (workflow)

Take the bearer token captured from the browser session and store it in the encrypted vault:

```
workflow:credential_store(
  name: "payer_bearer_token",
  value: "eyJhbGciOiJSUzI1NiIs...",
  credential_type: "bearer",
  service: "acme_health",
  notes: "Captured from portal.example-health.com login, expires ~1hr"
)
```

The token value is DPAPI-encrypted on disk. Never appears in plaintext in any file.

## Step 3: Store API Pattern (workflow)

Store the discovered endpoint pattern with a credential reference (not the token itself):

```
workflow:api_store(
  name: "payer_fhir_patient_search",
  url_pattern: "https://api.example-health.com/fhir/Patient?name={name}",
  method: "GET",
  credential_ref: "payer_bearer_token",
  response_shape: ["entry", "total", "link"],
  notes: "Discovered via browser_learn_api on 2026-03-15. FHIR Bundle response."
)
```

## Step 4: Validate

```
workflow:api_test(
  name: "payer_fhir_patient_search",
  params: {"name": "Smith"}
)
→ {works: true, status: 200, response_time_ms: 142}
```

## Step 5: Use It — No Browser Needed

From now on, every lookup is a direct HTTP call:

```
workflow:api_call(
  name: "payer_fhir_patient_search",
  params: {"name": "Jones"}
)
→ {success: true, status: 200, response_time_ms: 87, body: {entry: [...], total: 3}}
```

## Step 6: Transform the Response

Pipe the FHIR bundle through a transform to extract just what you need:

```
workflow:transform_pipe(
  input: <result.body from above>,
  operations: [
    {"op": "flatten", "key": "entry"},
    {"op": "pick", "keys": ["id", "name", "birthDate"]},
    {"op": "template", "format": "Patient {id}: {name} (DOB: {birthDate})"}
  ]
)
→ ["Patient 12345: Smith, John (DOB: 1952-03-14)", ...]
```

## When the API Breaks

If the token expires or the endpoint changes, `api_call` returns a `fallback_hint`:

```
{success: false, status: 401, fallback_hint: "Token may be expired. Re-authenticate via browser and update credential 'payer_bearer_token'."}
```

Go back to hands, re-authenticate, capture new token, `credential_store` it again. All patterns referencing `payer_bearer_token` automatically use the new value. No pattern updates needed.

## Token Rotation (No Pattern Updates)

```
workflow:credential_store(
  name: "payer_bearer_token",
  value: "<new_token>",
  credential_type: "bearer",
  service: "acme_health"
)

workflow:api_test(name: "payer_fhir_patient_search", params: {"name": "test"})
→ {works: true, status: 200}
```

One credential update. Zero pattern updates. That's the credential-by-reference pattern.
