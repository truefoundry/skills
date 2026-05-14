# Provider Account Manifest Reference

Templates for creating provider account manifests based on codebase scan findings.

## Manifest Structure

Every provider account manifest has:
- `name` — unique identifier (e.g., `openai-main`)
- `type` — provider type (e.g., `provider-account/openai`)
- `collaborators` — access control
- `auth_data` — credentials (always reference TFY secrets)
- `integrations` — list of models to expose

## Applying Manifests

```bash
# Dry run first
tfy apply -f provider-account.yaml --dry-run --show-diff

# Apply
tfy apply -f provider-account.yaml
```

---

## OpenAI

```yaml
name: openai-main
type: provider-account/openai
collaborators:
  - role_id: provider-account-access
    subject: team:everyone
auth_data:
  api_key: tfy-secret://TENANT:llm-keys:OPENAI_API_KEY
  type: api-key
integrations:
  - cost:
      metric: public_cost
    name: gpt-4o
    type: integration/model/openai
    model_id: gpt-4o
    model_types:
      - chat
  - cost:
      metric: public_cost
    name: gpt-4o-mini
    type: integration/model/openai
    model_id: gpt-4o-mini
    model_types:
      - chat
  - cost:
      metric: public_cost
    name: gpt-4.1
    type: integration/model/openai
    model_id: gpt-4.1
    model_types:
      - chat
  - cost:
      metric: public_cost
    name: gpt-4.1-mini
    type: integration/model/openai
    model_id: gpt-4.1-mini
    model_types:
      - chat
  - cost:
      metric: public_cost
    name: text-embedding-3-large
    type: integration/model/openai
    model_id: text-embedding-3-large
    model_types:
      - embedding
  - cost:
      metric: public_cost
    name: text-embedding-3-small
    type: integration/model/openai
    model_id: text-embedding-3-small
    model_types:
      - embedding
```

### OpenAI Model Types

| Model | `model_types` |
|-------|--------------|
| gpt-4o, gpt-4o-mini, gpt-4.1, gpt-4-turbo | `[chat]` |
| text-embedding-3-large, text-embedding-3-small, text-embedding-ada-002 | `[embedding]` |
| dall-e-3, gpt-image-1 | `[image]` |
| whisper-1, gpt-4o-mini-transcribe | `[audio_transcription]` |
| tts-1, tts-1-hd | `[audio_speech]` |
| gpt-realtime, gpt-realtime-mini | `[realtime]` |

---

## Anthropic

```yaml
name: anthropic-main
type: provider-account/anthropic
collaborators:
  - role_id: provider-account-access
    subject: team:everyone
auth_data:
  api_key: tfy-secret://TENANT:llm-keys:ANTHROPIC_API_KEY
  type: api-key
integrations:
  - cost:
      metric: public_cost
    name: claude-sonnet-4-20250514
    type: integration/model/anthropic
    model_id: claude-sonnet-4-20250514
    model_types:
      - chat
  - cost:
      metric: public_cost
    name: claude-opus-4-20250514
    type: integration/model/anthropic
    model_id: claude-opus-4-20250514
    model_types:
      - chat
  - cost:
      metric: public_cost
    name: claude-haiku-4-5-20251001
    type: integration/model/anthropic
    model_id: claude-haiku-4-5-20251001
    model_types:
      - chat
```

---

## Google (Gemini)

```yaml
name: gemini-main
type: provider-account/google
collaborators:
  - role_id: provider-account-access
    subject: team:everyone
auth_data:
  api_key: tfy-secret://TENANT:llm-keys:GOOGLE_API_KEY
  type: api-key
integrations:
  - cost:
      metric: public_cost
    name: gemini-2.5-pro
    type: integration/model/google
    model_id: gemini-2.5-pro
    model_types:
      - chat
  - cost:
      metric: public_cost
    name: gemini-2.5-flash
    type: integration/model/google
    model_id: gemini-2.5-flash
    model_types:
      - chat
  - cost:
      metric: public_cost
    name: gemini-2.0-flash
    type: integration/model/google
    model_id: gemini-2.0-flash
    model_types:
      - chat
```

---

## Azure OpenAI

```yaml
name: azure-main
type: provider-account/azure
collaborators:
  - role_id: provider-account-access
    subject: team:everyone
auth_data:
  api_key: tfy-secret://TENANT:llm-keys:AZURE_OPENAI_API_KEY
  type: api-key
  api_base: https://YOUR-RESOURCE.openai.azure.com
  api_version: "2024-12-01-preview"
integrations:
  - cost:
      metric: public_cost
    name: gpt-4o
    type: integration/model/azure
    model_id: gpt-4o  # This is the deployment name in Azure
    model_types:
      - chat
```

Note: Azure requires `api_base` (resource URL) and `api_version` in auth_data.

---

## AWS Bedrock

```yaml
name: bedrock-main
type: provider-account/aws-bedrock
collaborators:
  - role_id: provider-account-access
    subject: team:everyone
auth_data:
  type: aws-access-key-auth
  aws_access_key_id: tfy-secret://TENANT:llm-keys:AWS_ACCESS_KEY_ID
  aws_secret_access_key: tfy-secret://TENANT:llm-keys:AWS_SECRET_ACCESS_KEY
  aws_region: us-east-1
integrations:
  - cost:
      metric: public_cost
    name: anthropic.claude-3-5-sonnet
    type: integration/model/aws-bedrock
    model_id: anthropic.claude-3-5-sonnet-20241022-v2:0
    model_types:
      - chat
```

---

## Groq

```yaml
name: groq-main
type: provider-account/groq
collaborators:
  - role_id: provider-account-access
    subject: team:everyone
auth_data:
  api_key: tfy-secret://TENANT:llm-keys:GROQ_API_KEY
  type: api-key
integrations:
  - cost:
      metric: public_cost
    name: llama-3.1-70b-versatile
    type: integration/model/groq
    model_id: llama-3.1-70b-versatile
    model_types:
      - chat
```

---

## Together AI

```yaml
name: together-main
type: provider-account/together-ai
collaborators:
  - role_id: provider-account-access
    subject: team:everyone
auth_data:
  api_key: tfy-secret://TENANT:llm-keys:TOGETHER_API_KEY
  type: api-key
integrations:
  - cost:
      metric: public_cost
    name: meta-llama/Meta-Llama-3.1-70B-Instruct-Turbo
    type: integration/model/together-ai
    model_id: meta-llama/Meta-Llama-3.1-70B-Instruct-Turbo
    model_types:
      - chat
```

---

## Mistral

```yaml
name: mistral-main
type: provider-account/mistral
collaborators:
  - role_id: provider-account-access
    subject: team:everyone
auth_data:
  api_key: tfy-secret://TENANT:llm-keys:MISTRAL_API_KEY
  type: api-key
integrations:
  - cost:
      metric: public_cost
    name: mistral-large-latest
    type: integration/model/mistral
    model_id: mistral-large-latest
    model_types:
      - chat
```

---

## Virtual Model (Load Balancing / Fallback)

Create after provider accounts are set up. Allows using a single model name that routes to multiple backends:

```yaml
name: default-routing
type: gateway-load-balancing-config
rules:
  - id: main-chat
    type: priority-based-routing
    when:
      subjects: ["*"]
      models: ["default/chat"]
    load_balance_targets:
      - target: "openai-main/gpt-4o-mini"
        priority: 0
        fallback_candidate: true
        retry_config:
          delay: 100
          attempts: 2
          on_status_codes: ["429", "500", "502", "503"]
      - target: "anthropic-main/claude-haiku-4-5-20251001"
        priority: 1
        fallback_candidate: true
        retry_config:
          delay: 200
          attempts: 1
          on_status_codes: ["429", "500", "502", "503"]
```

Usage: `model="default/chat"` routes to gpt-4o-mini with fallback to Claude Haiku.

---

## Tenant Name Resolution

The `TENANT` in `tfy-secret://TENANT:...` is derived from the TFY base URL:
- `https://myorg.truefoundry.cloud` -> tenant is `myorg`
- `https://app.truefoundry.com` -> tenant is `app` (SaaS default)

Get it programmatically:
```bash
echo "$TFY_BASE_URL" | sed 's|https://||' | cut -d. -f1
```

---

## Generating Manifests from Scan Results

Algorithm for the agent:

1. Collect all unique `(provider, model_name)` pairs from scan
2. Group by provider
3. For each provider group:
   - Choose a `name` (e.g., `openai-main`, `anthropic-main`)
   - Set the correct `type`
   - Reference the appropriate secret key
   - List all models as integrations with correct `model_id` and `model_types`
4. Write to `tfy-provider-{name}.yaml`
5. Dry-run, show diff, apply on confirmation
