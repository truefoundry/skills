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
- User wants to manage TrueFoundry platform credentials -> prefer `platform` skill (Status Check section)
- User wants to manage MCP servers (tool servers) -> prefer `mcp-servers` skill
- User wants to manage platform secrets directly -> prefer `platform` skill (Secrets section)
- User wants to instrument their own application with tracing -> prefer `observability` skill
- User wants to view application container logs -> prefer `observability` skill

## Deploying a Custom Guardrails Server

Start from the official template: [truefoundry/custom-guardrails-template](https://github.com/truefoundry/custom-guardrails-template). Build on top of it, then deploy.

</objective>

<context>

## Overview

```
Your App -> AI Gateway -> OpenAI / Anthropic / Azure / Self-hosted vLLM / etc.
                ^
         Unified API + Auth + Rate Limiting + Routing + Logging
```

**Key benefits:** Single endpoint for all models, one API key (PAT/VAT), OpenAI-compatible, rate limiting, budget controls, load balancing with fallback, guardrails, and full observability.

## Gateway Endpoint

```
{TFY_BASE_URL}/api/llm
```

## Authentication

**PAT (Personal Access Token):** Dashboard -> Access -> Personal Access Tokens. For development.

**VAT (Virtual Access Token):** Dashboard -> Access -> Virtual Account Tokens. For production (not tied to a user, supports granular model access).

</context>

<instructions>

## Security Policy

- All credentials in manifests MUST use `tfy-secret://` references, never raw values.
- **Never ask the user to paste an API key into chat.** Direct them to store it in TrueFoundry dashboard -> Secrets, then provide only the `tfy-secret://` URI. Or have them set it via `! export TFY_API_KEY=...` so it stays in the shell.
- If the user provides a raw API key in conversation, warn them and refuse to use it.

## Preflight

Verify `tfy login` is complete. If missing, stop and use `truefoundry-onboard`.

Set `TFY_API_SH` for direct API calls:
```bash
TFY_API_SH=~/.claude/skills/truefoundry-gateway/scripts/tfy-api.sh
```

## Quick Lookups — One Call, One Answer

For read-only questions, go straight to the API. Do not explore CLI subcommands — they don't exist. See [references/cli-reference.md](references/cli-reference.md).

| User asks | Single call |
|-----------|------------|
| What models/providers are attached? | `$TFY_API_SH GET /api/svc/v1/provider-accounts` |
| What models can I call? | `curl -s "${TFY_BASE_URL}/api/llm/models" -H "Authorization: Bearer ${TFY_API_KEY}"` |
| What guardrails are configured? | `$TFY_API_SH GET /api/svc/v1/gateway-guardrails-configs` |
| Show recent gateway requests | `$TFY_API_SH POST /api/svc/v1/spans/query '{"startTime":"...","dataRoutingDestination":"default","limit":20,"sortDirection":"desc"}'` |
| Is the gateway reachable? | `curl -s "${TFY_BASE_URL}/api/llm/health"` |

**After login is confirmed, the next step for any read question is the API call above — nothing else.**

---

## Calling Models

The gateway is OpenAI-compatible. Minimal example:

```bash
curl "${TFY_BASE_URL}/api/llm/chat/completions" \
  -H "Authorization: Bearer ${TFY_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"model": "openai/gpt-4o", "messages": [{"role": "user", "content": "Hello!"}], "max_tokens": 200}'
```

Or set environment variables for any OpenAI SDK:
```bash
export OPENAI_BASE_URL="${TFY_BASE_URL}/api/llm"
export OPENAI_API_KEY="<your-PAT-or-VAT>"
```

For complete SDK examples (Python, Node.js, streaming), supported APIs table, framework integrations (LangChain, LlamaIndex, Cursor), and routing/rate-limiting/budget configuration, see [references/calling-models.md](references/calling-models.md).

---

## Provider Integrations

### List Provider Accounts

```bash
$TFY_API_SH GET /api/svc/v1/provider-accounts
```

Present as a formatted table with name, provider, type, and model count (from `integrations` array length).

### Create Provider Account

1. Ensure credentials are stored as TrueFoundry secrets first (`platform` skill, Secrets section)
2. Use the appropriate provider template from [references/provider-templates.md](references/provider-templates.md)
3. Apply: `$TFY_API_SH POST /api/svc/v1/provider-accounts "$payload"`

Supported providers: OpenAI, AWS Bedrock, Google Vertex, Azure OpenAI, Groq, Together AI, Custom (any OpenAI-compatible), Self-Hosted, TrueFoundry.

### Applying Config (Any Gateway Resource)

```bash
tfy apply -f manifest.yaml --dry-run --show-diff
tfy apply -f manifest.yaml
```

Do NOT delegate gateway applies to a deployment skill. Gateway configs are applied inline with `tfy apply`.

---

## Guardrails

Guardrails add content safety controls. Setup requires two steps:

1. **Create guardrail config group** — register provider integrations
2. **Create gateway guardrails config** — create rules referencing those providers

Quick list: `$TFY_API_SH GET /api/svc/v1/gateway-guardrails-configs`

For full setup instructions, rule structure, API calls, and common patterns, see [references/guardrails-setup.md](references/guardrails-setup.md).

Supported providers reference: [references/guardrail-providers.md](references/guardrail-providers.md).

---

## AI Monitoring

Query gateway request traces via the spans API. Requires either `tracingProjectFqn` or `dataRoutingDestination` (suggest `"default"` as starting point).

### Recent Requests

```bash
$TFY_API_SH POST /api/svc/v1/spans/query '{
  "dataRoutingDestination": "default",
  "startTime": "2026-05-15T00:00:00.000Z",
  "limit": 20,
  "sortDirection": "desc"
}'
```

Present results as formatted tables (time, model, status, tokens, cost, latency, user).

For all monitoring use cases (cost analysis, errors, model usage, user filtering, MCP tool calls, metadata filtering), filter types, response structure, and pagination, see [references/monitoring.md](references/monitoring.md).

### Aggregated Metrics

```bash
$TFY_API_SH POST /api/svc/v1/llm-gateway/metrics/query '{
  "startTs": "...", "endTs": "...",
  "datasource": "modelMetrics",
  "type": "distribution",
  "aggregations": [{"type": "sum", "column": "costInUSD"}],
  "groupBy": ["modelName"]
}'
```

---

## Generating Manifests

For any gateway entity or policy:

1. **Fetch existing config** — API call from Quick Lookups
2. **Consult schema reference** — see table below
3. **Generate YAML** — use `tfy-secret://` for credentials
4. **Validate** — `tfy apply -f manifest.yaml --dry-run --show-diff`
5. **Apply** — `tfy apply -f manifest.yaml`

| Entity | Reference |
|--------|-----------|
| Provider accounts | [references/provider-templates.md](references/provider-templates.md) |
| Virtual models / routing | [references/calling-models.md](references/calling-models.md) (Virtual Models section) |
| Rate limiting | [references/schemas/rate-limiting.md](references/schemas/rate-limiting.md) |
| Budget controls | [references/schemas/budget-limiting.md](references/schemas/budget-limiting.md) |
| Guardrails | [references/guardrails-setup.md](references/guardrails-setup.md) |
| Observability tables | [references/observability.md](references/observability.md) |

</instructions>

<success_criteria>

## Success Criteria

### AI Gateway
- User can call LLMs through the gateway using OpenAI-compatible SDK or cURL
- Valid PAT or VAT configured
- Target model name confirmed available
- Working code snippets provided in user's language/framework

### Provider Integrations
- Provider accounts listed in a formatted table
- New provider accounts use `tfy-secret://` for all credentials
- Provider type and model details confirmed before creating

### Guardrails
- Guardrail config groups listed
- Rules correctly target intended models, users, and tools
- Create/update operations confirmed before executing

### AI Monitoring
- Recent traces shown with timestamps, models, status, costs
- Results presented as formatted tables, not raw JSON
- `dataRoutingDestination` or `tracingProjectFqn` asked before querying

</success_criteria>

<references>

## References

### Core
- [cli-reference.md](references/cli-reference.md) — CLI commands, flags, what doesn't exist
- [api-endpoints.md](references/api-endpoints.md) — Full REST API with curl examples

### Gateway Operations
- [calling-models.md](references/calling-models.md) — SDK examples, routing, rate limiting, budgets, frameworks
- [provider-templates.md](references/provider-templates.md) — All provider manifest templates (OpenAI, Bedrock, Vertex, Azure, etc.)
- [guardrails-setup.md](references/guardrails-setup.md) — Guardrail config groups and rules setup
- [monitoring.md](references/monitoring.md) — Spans query API, metrics, use cases
- [guardrail-providers.md](references/guardrail-providers.md) — All 23 guardrail provider types

### Schemas
- [schemas/provider-account.md](references/schemas/provider-account.md) — Provider account schema
- [schemas/virtual-model.md](references/schemas/virtual-model.md) — Virtual model / load balancing schema
- [schemas/rate-limiting.md](references/schemas/rate-limiting.md) — Rate limiting schema
- [schemas/budget-limiting.md](references/schemas/budget-limiting.md) — Budget control schema
- [schemas/guardrail-config.md](references/schemas/guardrail-config.md) — Guardrail config schema

### Other
- [access-management.md](references/access-management.md) — Identity, PAT/VAT, permissions
- [integrations.md](references/integrations.md) — Native SDK proxy, IDE integrations
- [observability.md](references/observability.md) — SQL query patterns
- [span-attributes.md](references/span-attributes.md) — 60+ span attribute definitions

## Composability

- **Store credentials first**: `platform` skill (Secrets section) -> then `tfy-secret://` URI
- **Need API key**: Dashboard -> Access -> Personal Access Tokens or Virtual Accounts
- **MCP servers**: `mcp-servers` skill
- **Deploy models**: Requires TrueFoundry Enterprise with connected cluster
- **Instrument your app**: `observability` skill (Tracing section)

</references>

<troubleshooting>

## Error Handling

### 401 Unauthorized
API key (PAT/VAT) is invalid or expired. Check `Authorization: Bearer <token>` header.

### 403 Forbidden
Token lacks access to this model. PATs inherit user permissions; VATs only access explicitly selected models.

### 404 Model Not Found
Model name not in gateway. Check exact name via dashboard -> AI Gateway -> Models or `GET /api/llm/models`.

### 429 Rate Limited
Wait and retry (check Retry-After header). Request higher limits or use load balancing.

### 502/503 Provider Error
Upstream provider issue. Gateway auto-retries/fallbacks if routing is configured. Check provider status page.

### Permission Denied (Provider Accounts)
User needs `provider-account-manager` role. Check collaborators on the provider account.

### Invalid Secret Reference
`tfy-secret://` path cannot resolve. Verify format: `tfy-secret://TENANT:SECRET_GROUP:SECRET_KEY`. Use `platform` skill to check secret group exists.

### Type Filter Not Working
The `type` query parameter on `GET /api/svc/v1/provider-accounts` does NOT filter. Fetch all and filter client-side.

### Provider Account Name Already Exists
Use a different name or update the existing account.

### Model Not Appearing in Gateway After Creation
Verify: provider account created successfully, integration has correct `model_types`, collaborators include `team:everyone` or relevant users.

### No Monitoring Data
Check: time range is correct, `dataRoutingDestination` exists, filters aren't too restrictive, gateway has received requests.

### 400 Bad Request (Monitoring)
Missing required parameter. Ensure you provide `tracingProjectFqn` or `dataRoutingDestination`, and a valid `startTime` in ISO 8601.

</troubleshooting>
