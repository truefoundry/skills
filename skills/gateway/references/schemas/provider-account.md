---
name: provider-account-schema
description: Complete schema reference for all AI Gateway provider account types, auth configurations, integrations, and collaborator roles.
---

# Provider Account Schema Reference

## Fetch Existing Config

```bash
# List all provider accounts
$TFY_API_SH GET /api/svc/v1/provider-accounts
```

> **Note:** The `type` query parameter on this endpoint does NOT filter results. Fetch all and filter client-side by the `provider` or `manifest.type` field.

### Example Response

```json
{
  "data": [
    {
      "id": "pa-abc123",
      "name": "openai-main",
      "fqn": "tenant:openai:openai-main",
      "provider": "openai",
      "manifest": {
        "name": "openai-main",
        "type": "provider-account/openai",
        "collaborators": [
          { "role_id": "provider-account-manager", "subject": "user:admin@example.com" },
          { "role_id": "provider-account-access", "subject": "team:everyone" }
        ],
        "integrations": [
          {
            "name": "gpt-4o",
            "type": "integration/model/openai",
            "model_types": ["chat"],
            "auth_data": {
              "type": "bearer-auth",
              "bearer_token": "tfy-secret://tenant:secrets:OPENAI_API_KEY"
            }
          }
        ]
      },
      "integrations": [ ... ],
      "createdBySubject": { ... },
      "accountId": "...",
      "createdAt": "2026-01-15T10:00:00.000Z",
      "updatedAt": "2026-01-15T10:00:00.000Z"
    }
  ]
}
```

---

## Schema Reference

### Common Fields (All Provider Types)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Unique name for the provider account (lowercase, hyphens) |
| `type` | string | Yes | Provider account type (see Provider Types table) |
| `collaborators` | array | No | Access control entries (see Collaborators below) |
| `integrations` | array | Yes | Model integration definitions (see per-type schemas) |

### Collaborators

Each entry in the `collaborators` array:

| Field | Type | Required | Valid Values |
|-------|------|----------|--------------|
| `role_id` | string | Yes | `provider-account-manager`, `provider-account-access` |
| `subject` | string | Yes | `user:<email>` or `team:<team-name>` |

**Roles:**

| Role | Description |
|------|-------------|
| `provider-account-manager` | Can edit and delete the provider account |
| `provider-account-access` | Can use models from this provider account |

---

### Provider Types

| Provider | `type` Value | Integration `type` | Auth `type` |
|----------|-------------|-------------------|-------------|
| OpenAI | `provider-account/openai` | `integration/model/openai` | `bearer-auth` |
| AWS Bedrock | `provider-account/aws-bedrock` | `integration/model/aws-bedrock` | `aws-irsa-auth` |
| Google Vertex | `provider-account/google-vertex` | `integration/model/google-vertex` | `gcp-service-account-auth` |
| Azure OpenAI | `provider-account/azure` | `integration/model/azure` | `azure-auth` |
| Groq | `provider-account/groq` | `integration/model/groq` | `bearer-auth` |
| Together AI | `provider-account/together-ai` | `integration/model/together-ai` | `bearer-auth` |
| Custom | `provider-account/custom` | `integration/model/custom` | `bearer-auth` |
| Self-Hosted | `provider-account/self-hosted-model` | `integration/model/self-hosted-model` | None or `bearer-auth` |
| TrueFoundry | `provider-account/truefoundry` | (none -- platform-managed) | Platform-managed |

> **WARNING:** `provider-account/nvidia-nim` does NOT exist. Use `provider-account/self-hosted-model` with `bearer-auth` for external OpenAI-compatible APIs (NVIDIA, etc.).

---

### Integration Fields (Common)

Every integration object inside the `integrations` array shares these fields:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Integration name (used in routing targets as `<account-name>/<integration-name>`) |
| `type` | string | Yes | Integration type (see Provider Types table) |
| `model_types` | string[] | Yes | Model capabilities: `"chat"`, `"embedding"`, `"completion"`, `"image"`, `"audio"`, `"rerank"` |
| `auth_data` | object | Varies | Authentication config (see per-type auth schemas below) |

---

### Auth Data Schemas

#### `bearer-auth` (OpenAI, Groq, Together AI, Custom, Self-Hosted external)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | string | Yes | `"bearer-auth"` |
| `bearer_token` | string | Yes | `tfy-secret://<tenant>:<group>:<key>` |

```yaml
auth_data:
  type: bearer-auth
  bearer_token: "tfy-secret://TENANT:SECRET_GROUP:API_KEY"
```

#### `aws-irsa-auth` (AWS Bedrock)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | string | Yes | `"aws-irsa-auth"` |
| `aws_region` | string | Yes | AWS region (e.g., `us-east-1`) |
| `aws_access_key_id` | string | Yes | `tfy-secret://` reference |
| `aws_secret_access_key` | string | Yes | `tfy-secret://` reference |

```yaml
auth_data:
  type: aws-irsa-auth
  aws_region: us-east-1
  aws_access_key_id: "tfy-secret://TENANT:SECRET_GROUP:AWS_ACCESS_KEY_ID"
  aws_secret_access_key: "tfy-secret://TENANT:SECRET_GROUP:AWS_SECRET_ACCESS_KEY"
```

#### `gcp-service-account-auth` (Google Vertex)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | string | Yes | `"gcp-service-account-auth"` |
| `gcp_service_account_key` | string | Yes | `tfy-secret://` reference to JSON key file |
| `gcp_project_id` | string | Yes | GCP project ID |
| `gcp_region` | string | Yes | GCP region (e.g., `us-central1`) |

```yaml
auth_data:
  type: gcp-service-account-auth
  gcp_service_account_key: "tfy-secret://TENANT:SECRET_GROUP:GCP_SA_KEY"
  gcp_project_id: my-gcp-project
  gcp_region: us-central1
```

#### `azure-auth` (Azure OpenAI)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | string | Yes | `"azure-auth"` |
| `api_key` | string | Yes | `tfy-secret://` reference |
| `api_base` | string | Yes | Azure resource URL (e.g., `https://my-resource.openai.azure.com`) |
| `api_version` | string | Yes | API version (e.g., `2024-02-01`) |

```yaml
auth_data:
  type: azure-auth
  api_key: "tfy-secret://TENANT:SECRET_GROUP:AZURE_OPENAI_KEY"
  api_base: "https://my-resource.openai.azure.com"
  api_version: "2024-02-01"
```

---

### Self-Hosted Model Additional Fields

Self-hosted integrations (`integration/model/self-hosted-model`) have extra fields beyond the common ones:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `hosted_model_name` | string | Yes | The actual model name on the server (e.g., `meta-llama/Meta-Llama-3.1-8B-Instruct`) |
| `url` | string | Yes | Model server endpoint URL |
| `model_server` | string | Yes | Server type: `"openai-compatible"` |
| `auth_data` | object | No | Omit for cluster-internal; use `bearer-auth` for external APIs |

Cluster-internal URL pattern: `http://{service-name}.{namespace}.svc.cluster.local:{port}`

### Custom Integration Additional Fields

Custom integrations (`integration/model/custom`) have an extra field:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `url` | string | Yes | Base URL of the OpenAI-compatible API endpoint |

### TrueFoundry Provider

TrueFoundry provider accounts (`provider-account/truefoundry`) are platform-managed and require no `auth_data`. The `integrations` array is typically empty.

---

### Credential Rule

All `bearer_token`, `api_key`, `aws_access_key_id`, `aws_secret_access_key`, `gcp_service_account_key`, and other credential fields MUST use `tfy-secret://` references. Never use raw values.

Format: `tfy-secret://<TENANT>:<SECRET_GROUP>:<SECRET_KEY>`

Store credentials as TrueFoundry secrets first (use the `tools` skill (Secrets section)), then reference them in provider manifests.

---

## Generate and Validate Workflow

### 1. Write YAML manifest

```yaml
name: openai-main
type: provider-account/openai
collaborators:
  - role_id: provider-account-manager
    subject: user:admin@example.com
  - role_id: provider-account-access
    subject: team:everyone
integrations:
  - name: gpt-4o
    type: integration/model/openai
    model_types:
      - chat
    auth_data:
      type: bearer-auth
      bearer_token: "tfy-secret://my-org:api-keys:OPENAI_API_KEY"
```

### 2. Validate (dry run)

```bash
tfy apply -f provider-account.yaml --dry-run --show-diff
```

### 3. Fix any errors

Common issues:
- Missing `tfy-secret://` reference (raw API key used)
- Invalid `type` value (check Provider Types table)
- Mismatched integration `type` for the provider account `type`
- Missing required `auth_data` fields

### 4. Apply

```bash
tfy apply -f provider-account.yaml
```

Or via direct API:

```bash
$TFY_API_SH POST /api/svc/v1/provider-accounts "$(cat provider-account.yaml | yq -o json '{manifest: .}')"
```

---

## Checklist

- [ ] Provider account `name` is unique and lowercase with hyphens
- [ ] `type` matches a valid provider type from the table above
- [ ] Each integration has a `name`, `type`, and `model_types`
- [ ] Integration `type` matches the provider account `type` (e.g., `provider-account/openai` uses `integration/model/openai`)
- [ ] All credential fields use `tfy-secret://` references (no raw keys)
- [ ] Secrets referenced via `tfy-secret://` have been created in TrueFoundry first
- [ ] `collaborators` include at least one `provider-account-manager`
- [ ] `model_types` array contains valid values (`chat`, `embedding`, `completion`, `image`, `audio`, `rerank`)
- [ ] Self-hosted models use cluster-internal URLs (`svc.cluster.local`) when possible
- [ ] External APIs (NVIDIA, etc.) use `provider-account/self-hosted-model` with `bearer-auth`, not a nonexistent provider type
- [ ] Dry-run passes: `tfy apply -f manifest.yaml --dry-run --show-diff`
