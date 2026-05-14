---
name: truefoundry-gateway
description: Configures TrueFoundry AI Gateway end-to-end. Covers unified OpenAI-compatible LLM access, provider account integrations, content safety guardrails, and observability (traces, costs, errors) via the spans query API.
license: MIT
compatibility: Requires Bash, curl, and access to a TrueFoundry instance
allowed-tools: Bash(*/tfy-api.sh *) Bash(curl*) Bash(python*)
---

> Routing note: For ambiguous user intents, use the shared clarification templates in [references/intent-clarification.md](references/intent-clarification.md).

<objective>

# Gateway

Configure and operate TrueFoundry's AI Gateway: unified OpenAI-compatible LLM access, provider account integrations, content safety guardrails, and request monitoring/observability.

## When to Use

- Access LLMs through TrueFoundry's unified OpenAI-compatible gateway
- Configure auth tokens (PAT/VAT), rate limiting, budget controls, or load balancing across providers
- List, create, or manage LLM provider accounts (OpenAI, AWS Bedrock, Google Vertex, Azure, Groq, Together AI, custom OpenAI-compatible endpoints, self-hosted models, etc.)
- Set up guardrail providers, create guardrail rules, or manage content safety policies (PII filtering, content moderation, prompt injection detection, secret detection, custom validation)
- Investigate gateway traffic: recent requests, cost breakdowns, error rates, model usage, per-user activity, MCP tool calls, or latency analysis

## When NOT to Use

- User wants to deploy a self-hosted model -> deploying self-hosted models requires a TrueFoundry Enterprise account with a connected cluster. See https://truefoundry.com
- User wants to deploy tool servers -> deploying workloads requires a TrueFoundry Enterprise account with a connected cluster. See https://truefoundry.com
- User wants to manage TrueFoundry platform credentials -> prefer `platform` skill (Status Check section); ask if the user wants another valid path
- User wants to manage MCP servers (tool servers) -> prefer `tools` skill (MCP Servers section)
- User wants to manage platform secrets directly -> prefer `tools` skill (Secrets section)
- User wants to instrument their own application with tracing -> prefer `observability` skill (Tracing section) (this skill is for querying existing gateway traces, not adding instrumentation)
- User wants to view application container logs -> prefer `observability` skill (Application Logs section)

## Deploying a Custom Guardrails Server

When the user asks to **deploy a guardrails server** or run guardrails as a deployed service, start from the official template so the server adheres to the gateway's input/output formats:

1. **Clone the default repo:** [truefoundry/custom-guardrails-template](https://github.com/truefoundry/custom-guardrails-template)
2. **Build on top of it** -- Add or adjust custom rules, providers, or config within the template structure; do not build from scratch.
3. **Deploy** -- Deploy the resulting service to your infrastructure (Dockerfile or build from source as in the template).

This keeps guardrail servers compatible with TrueFoundry AI Gateway expectations.

</objective>

<context>

## Overview

The AI Gateway sits between your application and LLM providers:

```
Your App -> AI Gateway -> OpenAI / Anthropic / Azure / Self-hosted vLLM / etc.
                ^
         Unified API + Auth + Rate Limiting + Routing + Logging
```

**Key benefits:**
- **Single endpoint** for all models (cloud + self-hosted)
- **One API key** (PAT or VAT) instead of managing per-provider keys
- **OpenAI-compatible** -- works with any OpenAI SDK client
- **Rate limiting** per user, team, or application
- **Budget controls** to enforce cost limits
- **Load balancing** across model instances with fallback
- **Guardrails** -- PII filtering, content moderation, prompt injection detection
- **Observability** -- request logging, cost tracking, analytics, trace querying

## Gateway Endpoint

The gateway base URL is your TrueFoundry platform URL + `/api/llm`:

```
{TFY_BASE_URL}/api/llm
```

Example: `https://your-org.truefoundry.cloud/api/llm`

## Authentication

### Personal Access Token (PAT)

For development and individual use:

1. Go to TrueFoundry dashboard -> **Access** -> **Personal Access Tokens**
2. Click **New Personal Access Token**
3. Copy the token

### Virtual Access Token (VAT)

For production applications (recommended):

1. Go to TrueFoundry dashboard -> **Access** -> **Virtual Account Tokens**
2. Click **New Virtual Account** (requires admin privileges)
3. Name it and **select which models** it can access
4. Copy the token

**VATs are recommended for production** because:
- Not tied to a specific user (survives team changes)
- Support granular model access control
- Better for tracking per-application usage

</context>

<instructions>

## Generating Manifests

For any gateway entity or policy, follow this workflow:

1. **Fetch existing config** -- Use the API to see current state
2. **Consult schema reference** -- Read the relevant reference file for all fields
3. **Generate YAML** -- Write manifest using `tfy-secret://` for credentials
4. **Validate** -- `tfy apply -f manifest.yaml --dry-run --show-diff`
5. **Apply** -- `tfy apply -f manifest.yaml`

| Entity | Reference File |
|--------|----------------|
| Provider accounts | [references/integrations.md](references/integrations.md) |
| Load balancing / routing | [references/access-management.md](references/access-management.md) |
| Guardrail providers | [references/guardrail-providers.md](references/guardrail-providers.md) |
| Observability tables | [references/observability.md](references/observability.md) |
| Span attributes | [references/span-attributes.md](references/span-attributes.md) |

> **Security Policy: Credential Handling**
> - All API keys and tokens in provider manifests MUST use `tfy-secret://` references, never raw values.
> - The agent MUST NOT accept, store, log, echo, or display raw API keys or tokens in any context.
> - Always instruct the user to store credentials in TrueFoundry secrets first (use `tools` skill (Secrets section)), then reference them via `tfy-secret://` URIs.
> - If the user provides a raw API key directly in conversation, warn them and refuse to use it. Instruct them to store it as a secret first.

## Preflight

Run the `platform` skill (Status Check section) first to verify `TFY_BASE_URL` and `TFY_API_KEY` are set and valid.

When using direct API, set `TFY_API_SH` to the full path of this skill's `scripts/tfy-api.sh`. See `references/tfy-api-setup.md` for paths per agent.

```bash
TFY_API_SH=~/.claude/skills/truefoundry-gateway/scripts/tfy-api.sh
```

---

## AI Gateway

### Calling Models

#### Python (OpenAI SDK)

```python
from openai import OpenAI

client = OpenAI(
    api_key="<your-PAT-or-VAT>",
    base_url="https://<your-truefoundry-url>/api/llm",
)

# Chat completion
response = client.chat.completions.create(
    model="openai/gpt-4o",  # or any configured model name
    messages=[
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": "Hello!"},
    ],
    max_tokens=200,
)
print(response.choices[0].message.content)
```

#### Python (Streaming)

```python
stream = client.chat.completions.create(
    model="openai/gpt-4o",
    messages=[{"role": "user", "content": "Write a haiku about AI"}],
    stream=True,
)

for chunk in stream:
    if chunk.choices[0].delta.content:
        print(chunk.choices[0].delta.content, end="")
```

#### cURL

```bash
curl "${TFY_BASE_URL}/api/llm/chat/completions" \
  -H "Authorization: Bearer ${TFY_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "openai/gpt-4o",
    "messages": [{"role": "user", "content": "Hello!"}],
    "max_tokens": 200
  }'
```

#### JavaScript / Node.js

```javascript
import OpenAI from "openai";

const client = new OpenAI({
  apiKey: "<your-PAT-or-VAT>",
  baseURL: "https://<your-truefoundry-url>/api/llm",
});

const response = await client.chat.completions.create({
  model: "openai/gpt-4o",
  messages: [{ role: "user", content: "Hello!" }],
});
```

#### Environment Variables

Set these to use with any OpenAI-compatible library:

```bash
export OPENAI_BASE_URL="${TFY_BASE_URL}/api/llm"
export OPENAI_API_KEY="<your-PAT-or-VAT>"
```

Then any code using `openai.OpenAI()` without explicit parameters will use the gateway automatically.

### Supported APIs

| API | Endpoint | Description |
|-----|----------|-------------|
| **Chat Completions** | `/chat/completions` | Chat with any model (streaming + non-streaming) |
| **Completions** | `/completions` | Legacy text completions |
| **Embeddings** | `/embeddings` | Text embeddings (text + list inputs) |
| **Image Generation** | `/images/generations` | Generate images |
| **Image Editing** | `/images/edits` | Edit images |
| **Audio Transcription** | `/audio/transcriptions` | Speech-to-text |
| **Audio Translation** | `/audio/translations` | Translate audio |
| **Text-to-Speech** | `/audio/speech` | Generate speech |
| **Reranking** | `/rerank` | Rerank documents |
| **Batch Processing** | `/batches` | Batch predictions |
| **Moderations** | `/moderations` | Content safety |

### Supported Providers

The gateway supports 25+ providers including:

| Provider | Example Model Names |
|----------|-------------------|
| OpenAI | `openai/gpt-4o`, `openai/gpt-4o-mini` |
| Anthropic | `anthropic/claude-sonnet-4-5-20250929` |
| Google Vertex | `google/gemini-2.0-flash` |
| AWS Bedrock | `bedrock/anthropic.claude-3-5-sonnet` |
| Azure OpenAI | `azure/gpt-4o` |
| Mistral | `mistral/mistral-large-latest` |
| Groq | `groq/llama-3.1-70b-versatile` |
| Cohere | `cohere/command-r-plus` |
| Together AI | `together/meta-llama/Meta-Llama-3.1-70B` |
| Self-hosted (vLLM/TGI) | `my-custom-model-name` |

**Model names depend on how they're configured in your gateway.** Check the TrueFoundry dashboard -> AI Gateway -> Models for exact names.

### Adding Models & Providers

Currently done through the TrueFoundry dashboard UI:

1. Go to **AI Gateway -> Models**
2. Click **Add Provider Account**
3. Select provider (OpenAI, Anthropic, etc.)
4. Enter API credentials
5. Select models to enable

For programmatic provider account creation, see the [Provider Integrations section below](#provider-integrations).

#### Adding Self-Hosted Models (Cluster-Internal)

After deploying a self-hosted model:

1. Go to **AI Gateway -> Models -> Add Provider Account**
2. Select **"Self Hosted"** as the provider type
3. Enter the internal endpoint: `http://{model-name}.{namespace}.svc.cluster.local:8000`
4. The model becomes accessible through the gateway alongside cloud models

> **Security:** Only register model endpoints that you control. External or untrusted model endpoints can return manipulated responses. Use internal cluster DNS (`svc.cluster.local`) for self-hosted models. Verify provider API credentials are stored securely in TrueFoundry secrets, not hardcoded.

#### Adding External OpenAI-Compatible APIs (NVIDIA, custom providers)

For externally hosted APIs that are OpenAI-compatible (e.g. NVIDIA Cloud APIs, custom inference endpoints), use `type: provider-account/self-hosted-model` with `auth_data`:

```yaml
# gateway.yaml -- External hosted API (e.g. NVIDIA Cloud)
- name: nvidia-external
  type: provider-account/self-hosted-model
  integrations:
    - name: nemotron-nano
      type: integration/model/self-hosted-model
      hosted_model_name: nvidia/nemotron-3-nano-30b-a3b
      url: "https://integrate.api.nvidia.com/v1"
      model_server: "openai-compatible"
      model_types: ["chat"]
      auth_data:
        type: bearer-auth
        bearer_token: "tfy-secret://<tenant>:<group>:<key>"
```

And in a virtual model routing target, reference it as `"<provider-account-name>/<integration-name>"`:

```yaml
targets:
  - model: "nvidia-external/nemotron-nano"  # "<provider-account-name>/<integration-name>"
```

Apply with:
```bash
tfy apply -f gateway.yaml
```

> **WARNING:** `provider-account/nvidia-nim` does **not** exist in the schema -- do not use it. Use `provider-account/self-hosted-model` with `auth_data` for all external OpenAI-compatible APIs (as shown above).

> **Schema source of truth:** For authoritative field names and types, read `servicefoundry-server/src/autogen/models.ts` in the platform repo. Do not guess field names from documentation alone.

### Applying Gateway Config

Gateway YAML is applied directly with `tfy apply` -- no service build or Docker image involved:

```bash
# Preview changes
tfy apply -f gateway.yaml --dry-run --show-diff

# Apply
tfy apply -f gateway.yaml
```

**Do NOT delegate gateway applies to a deployment skill.** Gateway configs (`type: gateway-*`, `type: provider-account/*`) are applied inline with `tfy apply`.

**Test after apply:**
```bash
# Quick smoke test via curl
curl "${TFY_BASE_URL}/api/llm/chat/completions" \
  -H "Authorization: Bearer ${TFY_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "nvidia-external/nemotron-nano",
    "messages": [{"role": "user", "content": "Hello!"}],
    "max_tokens": 50
  }'
```

Or via Python:
```python
from openai import OpenAI
client = OpenAI(api_key="<PAT-or-VAT>", base_url=f"{TFY_BASE_URL}/api/llm")
resp = client.chat.completions.create(
    model="nvidia-external/nemotron-nano",
    messages=[{"role": "user", "content": "Hello!"}],
)
print(resp.choices[0].message.content)
```

> **Note:** One-off gateway config applies should use `tfy apply` directly. For CI/CD pipelines, integrate `tfy apply` into your existing automation.

### Virtual Models & Load Balancing

Virtual models route requests across multiple model instances using a `gateway-load-balancing-config` manifest. Targets reference real catalog models as `"<provider-account-name>/<integration-name>"`.

#### Weight-Based Routing

```yaml
name: chat-routing
type: gateway-load-balancing-config
rules:
  - id: weighted-chat
    type: weight-based-routing
    when:
      subjects: ["*"]
      models: ["openai/gpt-4o"]
    load_balance_targets:
      - target: "openai-main/gpt-4o"
        weight: 70
        fallback_candidate: true
        retry_config:
          delay: 100
          attempts: 1
          on_status_codes: ["429", "500", "502", "503"]
      - target: "azure-backup/gpt-4o"
        weight: 30
        fallback_candidate: true
        retry_config:
          delay: 100
          attempts: 1
          on_status_codes: ["429", "500", "502", "503"]
```

#### Latency-Based Routing

Automatically routes to the lowest-latency model (measures time per output token over last 20 minutes):

```yaml
rules:
  - id: latency-chat
    type: latency-based-routing
    when:
      subjects: ["*"]
      models: ["openai/gpt-4o"]
    load_balance_targets:
      - target: "openai-main/gpt-4o"
        fallback_candidate: true
      - target: "azure-backup/gpt-4o"
        fallback_candidate: true
```

#### Priority-Based Routing

Routes to highest-priority healthy model with SLA cutoff (auto-marks unhealthy when TPOT exceeds threshold):

```yaml
rules:
  - id: priority-chat
    type: priority-based-routing
    when:
      subjects: ["team:premium"]
      models: ["*"]
    load_balance_targets:
      - target: "openai-main/gpt-4o"
        priority: 0
        sla_cutoff:
          time_per_output_token_ms: 50
        fallback_candidate: true
      - target: "azure-backup/gpt-4o"
        priority: 1
        fallback_candidate: true
```

#### Sticky Sessions

Pin users to the same target for a duration:

```yaml
rules:
  - id: sticky-chat
    type: weight-based-routing
    sticky_routing:
      ttl_seconds: 3600
      session_identifiers:
        - key: x-user-id
          source: headers
    load_balance_targets:
      - target: "openai-main/gpt-4o"
        weight: 50
      - target: "azure-backup/gpt-4o"
        weight: 50
```

#### Header Overrides Per Target

```yaml
load_balance_targets:
  - target: "openai-main/gpt-4o"
    weight: 80
    headers_override:
      set:
        x-region: us-east-1
      remove:
        - x-internal-debug
```

#### Fallback Behavior

Fallback is configured per-target inside `load_balance_targets`:
- `fallback_status_codes`: defaults to `["401", "403", "404", "429", "500", "502", "503"]`
- `fallback_candidate: true` marks a target as eligible for failover
- `retry_config.on_status_codes` controls which errors trigger retries

#### Apply

```bash
tfy apply -f gateway-load-balancing-config.yaml --dry-run --show-diff
tfy apply -f gateway-load-balancing-config.yaml
```

> **Note:** Targets must be real catalog models, not nested virtual models.

### Rate Limiting

Configure rate limits per user, team, model, or custom metadata using a `gateway-rate-limiting-config` manifest. Only the first matching rule applies -- place specific rules before generic ones.

```yaml
name: rate-limits
type: gateway-rate-limiting-config
rules:
  - id: "team-rpm-limit"
    when:
      subjects: ["team:backend"]
      models: ["openai-main/gpt-4o"]
    limit_to: 20000
    unit: tokens_per_minute

  - id: "user-daily-limit"
    when:
      subjects: ["user:bob@example.com"]
      models: ["openai-main/gpt-4o"]
    limit_to: 1000
    unit: requests_per_day

  - id: "per-project-hourly"
    when: {}
    limit_to: 50000
    unit: tokens_per_hour
    rate_limit_applies_per: ["metadata.project_id"]

  - id: "global-fallback"
    when: {}
    limit_to: 500
    unit: requests_per_minute
    rate_limit_applies_per: ["user"]
```

**Units:** `requests_per_minute`, `requests_per_hour`, `requests_per_day`, `tokens_per_minute`, `tokens_per_hour`, `tokens_per_day`

**`rate_limit_applies_per`:** Creates separate limits per entity (max 2 values). Options: `user`, `model`, `virtualaccount`, `metadata.<key>`.

```bash
tfy apply -f gateway-rate-limiting-config.yaml
```

### Budget Controls

Enforce cost limits per user, team, or metadata using a `gateway-budget-config` manifest. Costs are tracked automatically based on model pricing.

```yaml
name: budget-controls
type: gateway-budget-config
rules:
  - id: "team-monthly-budget"
    when:
      subjects: ["team:engineering"]
    limit_to: 5000
    unit: cost_per_month
    budget_applies_per: ["team"]
    alerts:
      thresholds: [75, 90, 100]
      notification_target:
        - type: email
          notification_channel: "budget-alerts"
          to_emails: ["lead@example.com"]

  - id: "user-daily-budget"
    when: {}
    limit_to: 100
    unit: cost_per_day
    budget_applies_per: ["user"]

  - id: "project-daily-budget"
    when:
      metadata:
        environment: "production"
    limit_to: 200
    unit: cost_per_day
    budget_applies_per: ["metadata.project_id"]
```

**Units:** `cost_per_day` (resets UTC midnight), `cost_per_week` (resets Monday), `cost_per_month` (resets 1st)

**`budget_applies_per`:** Same options as rate limiting -- `user`, `model`, `team`, `virtualaccount`, `metadata.<key>`.

**Alerts:** Configure threshold percentages with email, Slack webhook, or Slack bot notifications.

```bash
tfy apply -f gateway-budget-config.yaml
```

### Observability Overview

#### Request Logging

All gateway requests are logged with:
- Input/output tokens
- Latency (TTFT, total)
- Cost
- Model and provider
- User identity
- Custom metadata

#### Custom Metadata

Tag requests with custom metadata for tracking:

```python
response = client.chat.completions.create(
    model="openai/gpt-4o",
    messages=[{"role": "user", "content": "Hello"}],
    extra_headers={
        "X-TFY-LOGGING-CONFIG": '{"project": "my-app", "environment": "production"}'
    },
)
```

#### Analytics

View usage analytics in TrueFoundry dashboard:
- Requests/minute per model
- Tokens/minute per model
- Failures/minute per model
- Cost breakdown by model, user, team

#### OpenTelemetry Integration

Export traces to your observability stack:
- Prometheus + Grafana
- Datadog
- Custom OTEL collectors

### MCP Gateway Attachment Flow

If a user has already deployed a tool server and wants to attach it to MCP gateway:

1. Verify deployment status and endpoint URL via the TrueFoundry dashboard
2. Register the endpoint as an MCP server (`tools` skill (MCP Servers section))
3. Confirm registration ID/name and share how to reference it in policies

### Framework Integration

The gateway works with popular AI frameworks:

#### LangChain

```python
from langchain_openai import ChatOpenAI

llm = ChatOpenAI(
    model="openai/gpt-4o",
    api_key="<your-PAT-or-VAT>",
    base_url="https://<your-truefoundry-url>/api/llm",
)
```

#### LlamaIndex

```python
from llama_index.llms.openai import OpenAI

llm = OpenAI(
    model="openai/gpt-4o",
    api_key="<your-PAT-or-VAT>",
    api_base="https://<your-truefoundry-url>/api/llm",
)
```

#### Cursor / Claude Code / Cline

Configure the gateway as a custom API endpoint in your coding assistant settings:
- Base URL: `{TFY_BASE_URL}/api/llm`
- API Key: Your PAT or VAT

### Presenting Gateway Info

When the user asks about gateway configuration:

```
AI Gateway:
  Endpoint: https://your-org.truefoundry.cloud/api/llm
  Auth:     Personal Access Token (PAT) or Virtual Access Token (VAT)

Available Models (check dashboard for current list):
| Model Name        | Provider     | Type        |
|-------------------|-------------|-------------|
| openai/gpt-4o     | OpenAI      | Cloud       |
| my-gemma-2b       | Self-hosted | vLLM (T4)   |
| anthropic/claude   | Anthropic   | Cloud       |

Usage:
  export OPENAI_BASE_URL="https://your-org.truefoundry.cloud/api/llm"
  export OPENAI_API_KEY="your-token"
  # Then use any OpenAI-compatible SDK
```

---

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

Before creating, ensure the user has stored their provider credentials as TrueFoundry secrets (use `tools` skill (Secrets section)). All `bearer_token`, `api_key`, and credential fields MUST use `tfy-secret://` references.

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

---

## Guardrails

Guardrails add content safety controls to LLM inputs/outputs and MCP tool invocations. Setup requires two steps:

1. **Guardrail Config Group** -- Register guardrail provider integrations (credentials and configuration)
2. **Gateway Guardrails Config** -- Create rules that reference those providers and attach them to a gateway

### Step 1: Create Guardrail Config Group

A guardrail config group holds integration credentials for one or more guardrail providers. See `references/guardrail-providers.md` for all supported providers.

#### List Existing Config Groups

##### Via Tool Call

```
tfy_guardrail_config_groups_list()
```

##### Via Direct API

```bash
$TFY_API_SH GET '/api/svc/v1/provider-accounts?type=guardrail-config-group'
```

#### Create Config Group

##### Via Tool Call

```
tfy_guardrail_config_groups_create(payload={"name": "my-guardrails", "type": "provider-account/guardrail-config-group", "integrations": [...]})
```

**Note:** Requires human approval (HITL) via tool call.

##### Via Direct API

```bash
$TFY_API_SH POST /api/svc/v1/provider-accounts '{
  "name": "my-guardrails",
  "type": "provider-account/guardrail-config-group",
  "integrations": [
    {
      "type": "integration/guardrail/tfy-pii",
      "config": {}
    },
    {
      "type": "integration/guardrail/tfy-content-moderation",
      "config": {}
    }
  ]
}'
```

Each integration has a `type` (from the providers reference) and a `config` object with provider-specific fields. Some providers (like `tfy-pii`, `tfy-content-moderation`) require no config. Others (like `aws-bedrock`, `azure-content-safety`) need cloud credentials.

> **Security:** Guardrail providers with external `endpoint_url` fields (e.g., `custom`, `opa`, `fiddler`, `palo-alto-prisma-airs`) route request data to third-party services. Verify that all external endpoints are trusted and controlled by your organization before registering them. Prefer TrueFoundry built-in providers (`tfy-pii`, `tfy-content-moderation`, `tfy-prompt-injection`) when possible.

#### Presenting Config Groups

```
Guardrail Config Groups:
| Name             | ID       | Integrations |
|------------------|----------|--------------|
| my-guardrails    | pa-abc   | 3            |
| prod-safety      | pa-def   | 5            |
```

### Step 2: Create Gateway Guardrails Config

Gateway guardrails config defines rules that control which guardrails apply to which models, users, and tools.

#### Get Existing Guardrails Config

##### Via Tool Call

```
tfy_gateway_guardrails_list()
```

##### Via Direct API

```bash
$TFY_API_SH GET /api/svc/v1/gateway-guardrails-configs
```

#### Create Guardrails Config

##### Via Tool Call

```
tfy_gateway_guardrails_create(payload={"name": "production-guardrails", "type": "gateway-guardrails-config", "gateway_ref": "GATEWAY_FQN", "rules": [...]})
```

**Note:** Requires human approval (HITL) via tool call.

##### Via Direct API

```bash
$TFY_API_SH POST /api/svc/v1/gateway-guardrails-configs '{
  "name": "production-guardrails",
  "type": "gateway-guardrails-config",
  "gateway_ref": "GATEWAY_FQN",
  "rules": [
    {
      "id": "pii-filter-all-models",
      "when": {
        "target_conditions": {
          "models": ["*"],
          "mcp_servers": [],
          "tools": []
        },
        "subject_conditions": {
          "users": ["*"],
          "teams": []
        }
      },
      "llm_input_guardrails": [
        {
          "provider_ref": "provider-account-id:integration/guardrail/tfy-pii",
          "operation": "validate",
          "enforcing_strategy": "enforce",
          "priority": 1
        }
      ],
      "llm_output_guardrails": [
        {
          "provider_ref": "provider-account-id:integration/guardrail/tfy-pii",
          "operation": "validate",
          "enforcing_strategy": "enforce",
          "priority": 1
        }
      ],
      "mcp_tool_pre_invoke_guardrails": [],
      "mcp_tool_post_invoke_guardrails": []
    }
  ]
}'
```

#### Update Existing Guardrails Config

##### Via Direct API

```bash
$TFY_API_SH PUT /api/svc/v1/gateway-guardrails-configs/GUARDRAILS_CONFIG_ID '{
  "name": "production-guardrails",
  "type": "gateway-guardrails-config",
  "gateway_ref": "GATEWAY_FQN",
  "rules": [...]
}'
```

### Rule Structure

Each rule contains:

- **id** -- Unique identifier for the rule
- **when** -- Conditions controlling when the rule applies:
  - `target_conditions.models` -- Model name patterns (use `["*"]` for all)
  - `target_conditions.mcp_servers` -- MCP server names to target
  - `target_conditions.tools` -- Specific tool names to target
  - `subject_conditions.users` -- User patterns (use `["*"]` for all)
  - `subject_conditions.teams` -- Team names
- **llm_input_guardrails** -- Applied to LLM request inputs
- **llm_output_guardrails** -- Applied to LLM response outputs
- **mcp_tool_pre_invoke_guardrails** -- Applied before MCP tool execution
- **mcp_tool_post_invoke_guardrails** -- Applied after MCP tool execution

### Guardrail Reference Fields

Each guardrail entry in a rule has:

- **provider_ref** -- Format: `<provider-account-id>:integration/guardrail/<provider-type>`
- **operation** -- `validate` (check and block) or `mutate` (modify content, e.g., redact PII)
- **enforcing_strategy** -- How violations are handled:
  - `enforce` -- Block the request on violation
  - `audit` -- Log the violation but allow the request
  - `enforce_but_ignore_on_error` -- Enforce if guardrail succeeds, allow if guardrail errors
- **priority** -- Integer for ordering when multiple mutate guardrails apply (lower runs first)

### Common Guardrail Patterns

#### PII Detection on All Models

```bash
# Step 1: Create config group with tfy-pii
$TFY_API_SH POST /api/svc/v1/provider-accounts '{
  "name": "pii-guardrails",
  "type": "provider-account/guardrail-config-group",
  "integrations": [
    {"type": "integration/guardrail/tfy-pii", "config": {}}
  ]
}'

# Step 2: Create rule targeting all models
# Use the provider account ID from step 1 response in provider_ref
```

#### Content Moderation with Audit Mode

Use `"enforcing_strategy": "audit"` to log violations without blocking -- useful for monitoring before enforcement.

#### MCP Tool Guardrails

Target specific MCP tools with `mcp_tool_pre_invoke_guardrails` to validate inputs before tool execution, or `mcp_tool_post_invoke_guardrails` to scan tool outputs.

#### Model-Specific Rules

Use `target_conditions.models` to apply guardrails only to specific models:

```json
"when": {
  "target_conditions": {
    "models": ["openai/gpt-4*", "anthropic/claude-*"],
    "mcp_servers": [],
    "tools": []
  }
}
```

#### Exempt Specific Users

Combine broad model targeting with specific user conditions to exempt admin users:

```json
"subject_conditions": {
  "users": ["user1@example.com", "user2@example.com"],
  "teams": ["engineering"]
}
```

### Finding the Gateway Reference

The `gateway_ref` is the fully qualified name (FQN) of your AI Gateway deployment. List gateways via the TrueFoundry dashboard or API to get the FQN.

---

## AI Monitoring

Query AI Gateway request traces, costs, latency, errors, and token usage via the spans query API.

### Required Parameter

Every query requires one of these two parameters. Ask the user which one to use:

| Parameter | Description |
|-----------|-------------|
| `tracingProjectFqn` | Fully qualified name of the tracing project, e.g. `tenant:tracing-project:name` |
| `dataRoutingDestination` | Data routing destination name, e.g. `default` |

If the user does not know which to use, suggest `"dataRoutingDestination": "default"` as a starting point.

### Query Spans API

**Endpoint:** `POST /api/svc/v1/spans/query`

```bash
# Basic query: recent spans in the last 24 hours
$TFY_API_SH POST '/api/svc/v1/spans/query' '{
  "startTime": "2026-03-26T00:00:00.000Z",
  "endTime": "2026-03-27T00:00:00.000Z",
  "dataRoutingDestination": "default",
  "limit": 50,
  "sortDirection": "desc"
}'
```

### Common Monitoring Use Cases

#### 1. Show Recent Requests

```bash
$TFY_API_SH POST '/api/svc/v1/spans/query' '{
  "startTime": "2026-03-26T00:00:00.000Z",
  "dataRoutingDestination": "default",
  "limit": 20,
  "sortDirection": "desc"
}'
```

#### 2. Cost Analysis (LLM Spans)

Filter for LLM spans and extract cost attributes:

```bash
$TFY_API_SH POST '/api/svc/v1/spans/query' '{
  "startTime": "2026-03-26T00:00:00.000Z",
  "dataRoutingDestination": "default",
  "filters": [
    {"spanAttributeKey": "tfy.span_type", "operator": "eq", "value": "LLM"}
  ],
  "limit": 200,
  "sortDirection": "desc"
}'
```

Cost fields in `spanAttributes`:
- `gen_ai.usage.cost` or `tfy.request_cost` -- cost of the request
- `gen_ai.usage.input_tokens` -- input token count
- `gen_ai.usage.output_tokens` -- output token count

#### 3. Show Errors

```bash
$TFY_API_SH POST '/api/svc/v1/spans/query' '{
  "startTime": "2026-03-26T00:00:00.000Z",
  "dataRoutingDestination": "default",
  "filters": [
    {"spanFieldName": "statusCode", "operator": "eq", "value": "ERROR"}
  ],
  "limit": 50,
  "sortDirection": "desc"
}'
```

#### 4. Model Usage Breakdown

Query all LLM spans and extract model info from span attributes to see which models are being used:

```bash
$TFY_API_SH POST '/api/svc/v1/spans/query' '{
  "startTime": "2026-03-26T00:00:00.000Z",
  "dataRoutingDestination": "default",
  "filters": [
    {"spanAttributeKey": "tfy.span_type", "operator": "eq", "value": "LLM"}
  ],
  "limit": 200,
  "sortDirection": "desc"
}'
```

Parse `spanAttributes` in the response for model name fields.

#### 5. Requests by a Specific User

```bash
$TFY_API_SH POST '/api/svc/v1/spans/query' '{
  "startTime": "2026-03-26T00:00:00.000Z",
  "dataRoutingDestination": "default",
  "createdBySubjectSlugs": ["user@example.com"],
  "limit": 50,
  "sortDirection": "desc"
}'
```

You can also filter by subject type:

```bash
$TFY_API_SH POST '/api/svc/v1/spans/query' '{
  "startTime": "2026-03-26T00:00:00.000Z",
  "dataRoutingDestination": "default",
  "createdBySubjectTypes": ["virtualaccount"],
  "limit": 50,
  "sortDirection": "desc"
}'
```

#### 6. MCP Tool Calls

```bash
$TFY_API_SH POST '/api/svc/v1/spans/query' '{
  "startTime": "2026-03-26T00:00:00.000Z",
  "dataRoutingDestination": "default",
  "filters": [
    {"spanAttributeKey": "tfy.span_type", "operator": "eq", "value": "MCP"}
  ],
  "limit": 50,
  "sortDirection": "desc"
}'
```

For MCP Gateway spans use `"value": "MCPGateway"` instead.

#### 7. Filter by Application Name

```bash
$TFY_API_SH POST '/api/svc/v1/spans/query' '{
  "startTime": "2026-03-26T00:00:00.000Z",
  "dataRoutingDestination": "default",
  "applicationNames": ["tfy-llm-gateway"],
  "limit": 50,
  "sortDirection": "desc"
}'
```

#### 8. Filter by Span Name (endpoint pattern)

```bash
$TFY_API_SH POST '/api/svc/v1/spans/query' '{
  "startTime": "2026-03-26T00:00:00.000Z",
  "dataRoutingDestination": "default",
  "filters": [
    {"spanFieldName": "spanName", "operator": "contains", "value": "completions"}
  ],
  "limit": 50,
  "sortDirection": "desc"
}'
```

#### 9. Filter by Gateway Request Metadata

```bash
$TFY_API_SH POST '/api/svc/v1/spans/query' '{
  "startTime": "2026-03-26T00:00:00.000Z",
  "dataRoutingDestination": "default",
  "filters": [
    {"gatewayRequestMetadataKey": "tfy_gateway_region", "operator": "eq", "value": "US"}
  ],
  "limit": 50,
  "sortDirection": "desc"
}'
```

### Request Body Reference

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `startTime` | string (ISO 8601) | Yes | Start of time range |
| `endTime` | string (ISO 8601) | No | End of time range (defaults to now) |
| `tracingProjectFqn` | string | One of this or `dataRoutingDestination` | Tracing project FQN |
| `dataRoutingDestination` | string | One of this or `tracingProjectFqn` | Data routing destination |
| `traceIds` | string[] | No | Filter by trace IDs |
| `spanIds` | string[] | No | Filter by span IDs |
| `parentSpanIds` | string[] | No | Filter by parent span IDs |
| `createdBySubjectTypes` | string[] | No | Filter by subject type (`user`, `virtualaccount`) |
| `createdBySubjectSlugs` | string[] | No | Filter by subject slug (e.g. email) |
| `applicationNames` | string[] | No | Filter by application name |
| `limit` | integer | No | Max results (default 200) |
| `sortDirection` | string | No | `asc` or `desc` |
| `pageToken` | string | No | Pagination token from previous response |
| `filters` | array | No | Array of filter objects (see Filter Types) |
| `includeFeedbacks` | boolean | No | Include feedback data |

### Filter Types

#### SpanFieldFilter

```json
{"spanFieldName": "<field>", "operator": "<op>", "value": "<val>"}
```

Fields: `spanName`, `serviceName`, `spanKind`, `statusCode`, etc.

#### SpanAttributeFilter

```json
{"spanAttributeKey": "<key>", "operator": "<op>", "value": "<val>"}
```

Any key from the `spanAttributes` dict (e.g. `tfy.span_type`, `gen_ai.usage.cost`).

#### GatewayRequestMetadataFilter

```json
{"gatewayRequestMetadataKey": "<key>", "operator": "<op>", "value": "<val>"}
```

Custom metadata keys set via `X-TFY-LOGGING-CONFIG` headers.

#### Filter Operators

`eq`, `neq`, `contains`, `not_contains`, `starts_with`, `ends_with`

### Response Structure

```json
{
  "data": [
    {
      "spanId": "...",
      "traceId": "...",
      "parentSpanId": "...",
      "serviceName": "tfy-llm-gateway",
      "spanName": "POST https://api.openai.com/v1/chat/completions",
      "spanKind": "Client",
      "scopeName": "...",
      "scopeVersion": "...",
      "timestamp": "2026-03-26T14:30:00.000Z",
      "durationNs": 1234567890,
      "statusCode": "OK",
      "statusMessage": "",
      "spanAttributes": {
        "gen_ai.usage.input_tokens": 150,
        "gen_ai.usage.output_tokens": 80,
        "gen_ai.usage.cost": 0.0023,
        "tfy.request_cost": 0.0023,
        "tfy.span_type": "LLM"
      },
      "events": [],
      "createdBySubject": {
        "subjectId": "...",
        "subjectSlug": "user@example.com",
        "subjectType": "user",
        "tenantName": "my-tenant"
      },
      "feedbacks": []
    }
  ],
  "pagination": {
    "nextPageToken": "..."
  }
}
```

### Pagination

When the response includes `pagination.nextPageToken`, pass it as `pageToken` in the next request to fetch the next page:

```bash
$TFY_API_SH POST '/api/svc/v1/spans/query' '{
  "startTime": "2026-03-26T00:00:00.000Z",
  "dataRoutingDestination": "default",
  "limit": 200,
  "pageToken": "TOKEN_FROM_PREVIOUS_RESPONSE"
}'
```

Continue until `nextPageToken` is null or absent.

### Presenting Results

Format results as tables for readability:

```
Recent Gateway Requests (last 24h):
| Time                | Model          | Status | Tokens (in/out) | Cost     | Latency   | User              |
|---------------------|----------------|--------|-----------------|----------|-----------|-------------------|
| 2026-03-26 14:30:00 | openai/gpt-4o  | OK     | 150 / 80        | $0.0023  | 1.23s     | user@example.com  |
| 2026-03-26 14:29:55 | anthropic/...  | OK     | 200 / 120       | $0.0045  | 2.10s     | bot@svc           |
| 2026-03-26 14:29:30 | openai/gpt-4o  | ERROR  | 100 / 0         | $0.0000  | 0.45s     | user@example.com  |
```

For cost summaries, aggregate across spans:

```
Cost Summary (last 24h):
| Model              | Requests | Total Cost | Avg Cost/Req | Total Tokens |
|--------------------|----------|------------|--------------|--------------|
| openai/gpt-4o      | 142      | $3.21      | $0.023       | 45,200       |
| anthropic/claude    | 58       | $1.87      | $0.032       | 22,100       |
| Total               | 200      | $5.08      | $0.025       | 67,300       |
```

Convert `durationNs` (nanoseconds) to human-readable format: divide by 1,000,000,000 for seconds.

</instructions>

<success_criteria>

## Success Criteria

### AI Gateway
- The user can call LLMs through the gateway endpoint using an OpenAI-compatible SDK or cURL
- The user has a valid authentication token (PAT or VAT) configured for gateway access
- The agent has confirmed the target model name is available in the user's gateway configuration
- The user can verify successful responses from the gateway with correct model output
- The agent has provided working code snippets tailored to the user's language and framework
- Rate limiting, budget controls, or routing are configured if the user requested them

### Provider Integrations
- The user can list all provider accounts and see them in a formatted table with name, provider type, and model count
- The user can create a new provider account with the correct manifest for their chosen provider
- All credentials in provider manifests use `tfy-secret://` references, never raw values
- The agent has confirmed the provider type and model details before creating
- The agent has directed the user to store credentials as TrueFoundry secrets before creating the provider account
- Provider accounts are accessible through the AI Gateway after creation

### Guardrails
- The user can list existing guardrail config groups
- The user can create a new guardrail config group with the desired provider integrations
- The user can create or update gateway guardrails config with rules
- Rules correctly target the intended models, users, and tools
- The agent has confirmed create/update operations before executing
- Provider references correctly link to the config group integrations

### AI Monitoring
- The user can see recent AI Gateway request traces with timestamps, models, status, and costs
- Cost and token usage are summarized clearly with per-model breakdowns when requested
- Errors are identified with status codes and messages for debugging
- Results are presented as formatted tables, not raw JSON
- Pagination is handled correctly for large result sets
- The agent asked for `dataRoutingDestination` or `tracingProjectFqn` before querying

</success_criteria>

<references>

## Additional References

- [access-management.md](references/access-management.md) -- Identity types (Users, Teams, Virtual Accounts, External Identity), PAT/VAT auth, provider-account permissions, token auto-rotation, and secret store sync
- [integrations.md](references/integrations.md) -- OpenAI-compatible integration, native SDK proxy support, and pre-built integration guides for IDEs, agent frameworks, and apps
- [guardrail-providers.md](references/guardrail-providers.md) -- All 23 supported guardrail provider types and their configuration

## Observability Table Schemas

For SQL-based querying of gateway observability data, see these references:

- [observability.md](references/observability.md) -- SQL query patterns for Datafusion dialect
- [span-attributes.md](references/span-attributes.md) -- 60+ `tfy.*` span attribute definitions
- [tables/gateway_model_metrics.md](references/tables/gateway_model_metrics.md) -- Model request metrics schema
- [tables/gateway_request_metrics.md](references/tables/gateway_request_metrics.md) -- Overall gateway request metrics schema
- [tables/gateway_mcp_metrics.md](references/tables/gateway_mcp_metrics.md) -- MCP tool call metrics schema
- [tables/gateway_guardrail_metrics.md](references/tables/gateway_guardrail_metrics.md) -- Guardrail evaluation metrics schema
- [tables/gateway_config_metrics.md](references/tables/gateway_config_metrics.md) -- Rate limiting/budget/load balancing metrics schema
- [tables/traces.md](references/tables/traces.md) -- OTEL span schema with gateway extensions

## Composability

- **Preflight**: Use `platform` skill (Status Check section) to verify platform connectivity before any operations
- **Store credentials first**: Use `tools` skill (Secrets section) to create secret groups with API keys before adding providers
- **Deploy model first**: Deploy a self-hosted model (requires TrueFoundry Enterprise), then add to gateway
- **Need API key**: Create PAT/VAT in TrueFoundry dashboard -> Access
- **Rate limiting**: Configure in dashboard -> AI Gateway -> Rate Limiting, or apply YAML with `tfy apply`
- **Routing config**: Apply routing YAML directly with `tfy apply`; for CI/CD pipelines, integrate `tfy apply` into your automation
- **Tool servers**: Deploy tool servers to your infrastructure, then register in gateway
- **Check deployed models**: Check the TrueFoundry dashboard to see running model services
- **Benchmark through gateway**: Use your preferred load-testing tool against gateway endpoints
- **Self-hosted models**: Deploy models to your infrastructure (requires TrueFoundry Enterprise), then register as self-hosted provider accounts
- **Access control**: Provider account collaborators control who can use the models
- **Instrument your app**: Use `observability` skill (Tracing section) to add tracing to your own applications (different from monitoring existing gateway traces)
- **View container logs**: Use `observability` skill (Application Logs section) for application-level logs (not gateway request traces)
- **Manage access tokens**: Use `platform` skill (Access Tokens section) to create/manage PAT or VAT used for gateway auth

## API Endpoints

See `references/api-endpoints.md` for the full API reference.

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/svc/v1/provider-accounts` | List all provider accounts |
| POST | `/api/svc/v1/provider-accounts` | Create a new provider account |
| GET | `/api/svc/v1/gateway-guardrails-configs` | List guardrails configs |
| POST | `/api/svc/v1/gateway-guardrails-configs` | Create guardrails config |
| PUT | `/api/svc/v1/gateway-guardrails-configs/{id}` | Update guardrails config |
| POST | `/api/svc/v1/spans/query` | Query gateway request traces |

</references>

<troubleshooting>

## Error Handling

### AI Gateway Errors

#### 401 Unauthorized
```
Gateway authentication failed. Check:
- API key (PAT or VAT) is valid and not expired
- Using correct header: Authorization: Bearer <token>
```

#### 403 Forbidden
```
Model access denied. Your token may not have access to this model.
- PATs inherit user permissions
- VATs only have access to explicitly selected models
- Check with your admin to grant model access
```

#### 429 Rate Limited
```
Rate limit exceeded. Options:
- Wait and retry (check Retry-After header)
- Request higher limits from admin
- Use load balancing to distribute across providers
```

#### 502/503 Provider Error
```
Upstream provider error. The gateway will automatically:
- Retry on configured status codes
- Fallback to alternate models if routing is configured
If persistent, check provider status page or self-hosted model health.
```

#### Model Not Found
```
Model name not found in gateway. Check:
- Exact model name in TrueFoundry dashboard -> AI Gateway -> Models
- Provider account is active and model is enabled
- Your token has access to this model
```

### Provider Integration Errors

#### Permission Denied
```
Cannot manage provider accounts. Check your API key permissions.
Ensure your user has provider-account-manager role.
```

#### Provider Account Name Already Exists
```
A provider account with this name already exists. Use a different name
or update the existing account.
```

#### Invalid Secret Reference
```
The tfy-secret:// reference could not be resolved. Check:
- Secret group exists and contains the referenced key
- Format is tfy-secret://TENANT:SECRET_GROUP:SECRET_KEY
- Use the secrets skill to verify the secret group and key exist
```

#### Invalid Provider Type
```
Unrecognized provider account type. Use one of:
provider-account/openai, provider-account/aws-bedrock,
provider-account/google-vertex, provider-account/azure,
provider-account/groq, provider-account/together-ai,
provider-account/custom, provider-account/self-hosted-model,
provider-account/truefoundry
```

#### Missing Auth Data
```
Provider account requires auth_data for cloud providers.
Store your API key as a TrueFoundry secret first, then reference it
with tfy-secret://TENANT:SECRET_GROUP:KEY_NAME
```

#### Model Not Appearing in Gateway
```
After creating a provider account, models should appear in the AI Gateway.
If not visible:
- Verify the provider account was created successfully (list provider accounts)
- Check that the integration has the correct model_types (chat, embedding, etc.)
- Ensure the collaborators include team:everyone or the relevant users
```

#### Type Filter Not Working
```
The type query parameter on GET /api/svc/v1/provider-accounts does not filter
results. Fetch all provider accounts and filter client-side by the provider field.
```

### Guardrail Errors

#### Config Group Not Found
```
Provider account not found. List config groups first to find the correct ID.
```

#### Invalid Guardrail Provider Type
```
Unknown guardrail integration type. Check references/guardrail-providers.md for valid types.
```

#### Gateway Not Found
```
Gateway reference not found. List available gateways via the TrueFoundry dashboard or API to get the FQN.
```

#### Duplicate Rule ID
```
Rule ID already exists in this config. Use a unique ID for each rule.
```

#### Missing Provider Credentials
```
Integration config missing required fields. Check the provider reference for required config.
```

### Monitoring Errors

#### 400 Bad Request
```
Missing required parameter. Ensure you provide either:
- "tracingProjectFqn": "tenant:tracing-project:name"
- "dataRoutingDestination": "default"
And a valid "startTime" in ISO 8601 format.
```

#### 401 Unauthorized (Monitoring)
```
Authentication failed. Run the status skill to verify your TFY_API_KEY is valid.
```

#### No Data Returned
```
Empty results. Check:
- Time range is correct (startTime/endTime)
- The dataRoutingDestination or tracingProjectFqn exists
- Filters are not too restrictive (try removing filters first)
- Gateway has actually received requests in this time period
```

#### Pagination Token Expired
```
If a pageToken returns an error, restart the query from the beginning
with a fresh request (no pageToken).
```

### General Errors

#### Permission Denied
```
Cannot manage this resource. Check your API key permissions.
```

</troubleshooting>
</output>
