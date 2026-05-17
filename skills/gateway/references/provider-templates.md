# Provider Account Templates

Complete manifest templates for creating provider accounts via the REST API.

## Provider Integrations

### List Provider Accounts

#### Via Direct API

```bash
# List all provider accounts
$TFY_API_SH GET /api/svc/v1/provider-accounts
```

> **Note:** The `type` query parameter on this endpoint does NOT work (returns all provider accounts regardless of filter). To filter by provider type, fetch all and filter client-side.

Present results as a formatted table:

```
Provider Accounts:
| Name            | Provider       | Type                          | Models |
|-----------------|----------------|-------------------------------|--------|
| openai-main     | openai         | provider-account/openai       | 3      |
| bedrock-prod    | aws-bedrock    | provider-account/aws-bedrock  | 5      |
| vertex-default  | google-vertex  | provider-account/google-vertex| 2      |
```

The model count is derived from the `integrations` array length in each provider account response.

### Create Provider Account

Before creating, ensure the user has stored their provider credentials as TrueFoundry secrets (use `platform` skill (Secrets section)). All `bearer_token`, `api_key`, and credential fields MUST use `tfy-secret://` references.

#### Via Direct API

```bash
# Create a provider account
$TFY_API_SH POST /api/svc/v1/provider-accounts "$payload"
```

### Provider Manifest Templates

#### OpenAI

```bash
payload=$(cat <<'PAYLOAD'
{
  "manifest": {
    "name": "openai-main",
    "type": "provider-account/openai",
    "collaborators": [
      {"role_id": "provider-account-manager", "subject": "user:ADMIN_EMAIL"},
      {"role_id": "provider-account-access", "subject": "team:everyone"}
    ],
    "integrations": [
      {
        "name": "gpt-4o",
        "type": "integration/model/openai",
        "model_types": ["chat"],
        "auth_data": {
          "type": "bearer-auth",
          "bearer_token": "tfy-secret://TENANT:SECRET_GROUP:OPENAI_API_KEY"
        }
      }
    ]
  }
}
PAYLOAD
)
$TFY_API_SH POST /api/svc/v1/provider-accounts "$payload"
```

#### AWS Bedrock

```bash
payload=$(cat <<'PAYLOAD'
{
  "manifest": {
    "name": "bedrock-prod",
    "type": "provider-account/aws-bedrock",
    "collaborators": [
      {"role_id": "provider-account-manager", "subject": "user:ADMIN_EMAIL"},
      {"role_id": "provider-account-access", "subject": "team:everyone"}
    ],
    "integrations": [
      {
        "name": "claude-3-5-sonnet",
        "type": "integration/model/aws-bedrock",
        "model_types": ["chat"],
        "auth_data": {
          "type": "aws-irsa-auth",
          "aws_region": "us-east-1",
          "aws_access_key_id": "tfy-secret://TENANT:SECRET_GROUP:AWS_ACCESS_KEY_ID",
          "aws_secret_access_key": "tfy-secret://TENANT:SECRET_GROUP:AWS_SECRET_ACCESS_KEY"
        }
      }
    ]
  }
}
PAYLOAD
)
$TFY_API_SH POST /api/svc/v1/provider-accounts "$payload"
```

#### Google Vertex

```bash
payload=$(cat <<'PAYLOAD'
{
  "manifest": {
    "name": "vertex-default",
    "type": "provider-account/google-vertex",
    "collaborators": [
      {"role_id": "provider-account-manager", "subject": "user:ADMIN_EMAIL"},
      {"role_id": "provider-account-access", "subject": "team:everyone"}
    ],
    "integrations": [
      {
        "name": "gemini-2-flash",
        "type": "integration/model/google-vertex",
        "model_types": ["chat"],
        "auth_data": {
          "type": "gcp-service-account-auth",
          "gcp_service_account_key": "tfy-secret://TENANT:SECRET_GROUP:GCP_SA_KEY",
          "gcp_project_id": "my-gcp-project",
          "gcp_region": "us-central1"
        }
      }
    ]
  }
}
PAYLOAD
)
$TFY_API_SH POST /api/svc/v1/provider-accounts "$payload"
```

#### Azure OpenAI

```bash
payload=$(cat <<'PAYLOAD'
{
  "manifest": {
    "name": "azure-openai",
    "type": "provider-account/azure",
    "collaborators": [
      {"role_id": "provider-account-manager", "subject": "user:ADMIN_EMAIL"},
      {"role_id": "provider-account-access", "subject": "team:everyone"}
    ],
    "integrations": [
      {
        "name": "gpt-4o-azure",
        "type": "integration/model/azure",
        "model_types": ["chat"],
        "auth_data": {
          "type": "azure-auth",
          "api_key": "tfy-secret://TENANT:SECRET_GROUP:AZURE_OPENAI_KEY",
          "api_base": "https://my-resource.openai.azure.com",
          "api_version": "2024-02-01"
        }
      }
    ]
  }
}
PAYLOAD
)
$TFY_API_SH POST /api/svc/v1/provider-accounts "$payload"
```

#### Groq

```bash
payload=$(cat <<'PAYLOAD'
{
  "manifest": {
    "name": "groq-main",
    "type": "provider-account/groq",
    "collaborators": [
      {"role_id": "provider-account-manager", "subject": "user:ADMIN_EMAIL"},
      {"role_id": "provider-account-access", "subject": "team:everyone"}
    ],
    "integrations": [
      {
        "name": "llama-3-70b",
        "type": "integration/model/groq",
        "model_types": ["chat"],
        "auth_data": {
          "type": "bearer-auth",
          "bearer_token": "tfy-secret://TENANT:SECRET_GROUP:GROQ_API_KEY"
        }
      }
    ]
  }
}
PAYLOAD
)
$TFY_API_SH POST /api/svc/v1/provider-accounts "$payload"
```

#### Together AI

```bash
payload=$(cat <<'PAYLOAD'
{
  "manifest": {
    "name": "together-ai",
    "type": "provider-account/together-ai",
    "collaborators": [
      {"role_id": "provider-account-manager", "subject": "user:ADMIN_EMAIL"},
      {"role_id": "provider-account-access", "subject": "team:everyone"}
    ],
    "integrations": [
      {
        "name": "llama-3-1-70b",
        "type": "integration/model/together-ai",
        "model_types": ["chat"],
        "auth_data": {
          "type": "bearer-auth",
          "bearer_token": "tfy-secret://TENANT:SECRET_GROUP:TOGETHER_API_KEY"
        }
      }
    ]
  }
}
PAYLOAD
)
$TFY_API_SH POST /api/svc/v1/provider-accounts "$payload"
```

#### Custom (Any OpenAI-Compatible Endpoint)

```bash
payload=$(cat <<'PAYLOAD'
{
  "manifest": {
    "name": "my-custom-provider",
    "type": "provider-account/custom",
    "collaborators": [
      {"role_id": "provider-account-manager", "subject": "user:ADMIN_EMAIL"},
      {"role_id": "provider-account-access", "subject": "team:everyone"}
    ],
    "integrations": [
      {
        "name": "my-model",
        "type": "integration/model/custom",
        "model_types": ["chat"],
        "auth_data": {
          "type": "bearer-auth",
          "bearer_token": "tfy-secret://TENANT:SECRET_GROUP:CUSTOM_API_KEY"
        },
        "url": "https://my-openai-compatible-api.example.com/v1"
      }
    ]
  }
}
PAYLOAD
)
$TFY_API_SH POST /api/svc/v1/provider-accounts "$payload"
```

#### Self-Hosted Model

```bash
payload=$(cat <<'PAYLOAD'
{
  "manifest": {
    "name": "my-self-hosted",
    "type": "provider-account/self-hosted-model",
    "collaborators": [
      {"role_id": "provider-account-manager", "subject": "user:ADMIN_EMAIL"},
      {"role_id": "provider-account-access", "subject": "team:everyone"}
    ],
    "integrations": [
      {
        "name": "my-vllm-model",
        "type": "integration/model/self-hosted-model",
        "hosted_model_name": "meta-llama/Meta-Llama-3.1-8B-Instruct",
        "url": "http://my-model.my-namespace.svc.cluster.local:8000",
        "model_server": "openai-compatible",
        "model_types": ["chat"]
      }
    ]
  }
}
PAYLOAD
)
$TFY_API_SH POST /api/svc/v1/provider-accounts "$payload"
```

> **Note:** Self-hosted models deployed within the cluster typically do not need `auth_data`. Use internal cluster DNS (`svc.cluster.local`) for the URL.

#### TrueFoundry (Platform-Managed)

```bash
payload=$(cat <<'PAYLOAD'
{
  "manifest": {
    "name": "truefoundry-models",
    "type": "provider-account/truefoundry",
    "collaborators": [
      {"role_id": "provider-account-manager", "subject": "user:ADMIN_EMAIL"},
      {"role_id": "provider-account-access", "subject": "team:everyone"}
    ],
    "integrations": []
  }
}
PAYLOAD
)
$TFY_API_SH POST /api/svc/v1/provider-accounts "$payload"
```

### Known Provider Types

| Provider | Manifest Type | Auth Type |
|----------|--------------|-----------|
| OpenAI | `provider-account/openai` | `bearer-auth` |
| AWS Bedrock | `provider-account/aws-bedrock` | `aws-irsa-auth` |
| Google Vertex | `provider-account/google-vertex` | `gcp-service-account-auth` |
| Azure OpenAI | `provider-account/azure` | `azure-auth` |
| GCP | `provider-account/gcp` | `gcp-service-account-auth` |
| Groq | `provider-account/groq` | `bearer-auth` |
| Together AI | `provider-account/together-ai` | `bearer-auth` |
| Custom | `provider-account/custom` | `bearer-auth` |
| Self-Hosted | `provider-account/self-hosted-model` | None (cluster-internal) or `bearer-auth` |
| TrueFoundry | `provider-account/truefoundry` | Platform-managed |

### Collaborator Roles

| Role ID | Description |
|---------|-------------|
| `provider-account-manager` | Can edit and delete the provider account |
| `provider-account-access` | Can use models from this provider account |

Use `subject` values like `user:admin@example.com` for individual users or `team:everyone` for organization-wide access.

### Response Structure

The provider account response object contains:

```json
{
  "id": "...",
  "name": "openai-main",
  "fqn": "tenant:openai:openai-main",
  "provider": "openai",
  "manifest": { ... },
  "integrations": [ ... ],
  "createdBySubject": { ... },
  "accountId": "...",
  "createdAt": "...",
  "updatedAt": "..."
}
```

- `manifest.integrations` contains the integration definitions (model configs)
- Top-level `integrations` contains expanded integration objects with their own IDs
