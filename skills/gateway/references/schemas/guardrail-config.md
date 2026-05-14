---
name: guardrail-config-schema
description: Schema reference for guardrail provider accounts (guardrail-config-group) and gateway guardrails config (gateway-guardrails-config). Covers integration types, rule fields, and the generate-validate-apply workflow.
---

# Guardrail Config Schema

Two manifest types work together for guardrails:

1. **Guardrail Config Group** (`provider-account/guardrail-config-group`) -- registers guardrail provider integrations with credentials and configuration
2. **Gateway Guardrails Config** (`gateway-guardrails-config`) -- creates rules that attach guardrail providers to specific models, users, and tools

## Fetch Existing Config

### Guardrail Config Groups

```bash
# Via tfy CLI
tfy get provider-accounts --type guardrail-config-group

# Via Direct API
$TFY_API_SH GET '/api/svc/v1/provider-accounts?type=guardrail-config-group'
```

Example response (abridged):

```json
{
  "id": "pa-abc123",
  "name": "my-guardrails",
  "type": "provider-account/guardrail-config-group",
  "integrations": [
    {
      "name": "pii-filter",
      "type": "integration/guardrail/tfy-pii",
      "config": {}
    },
    {
      "name": "content-mod",
      "type": "integration/guardrail/tfy-content-moderation",
      "config": {}
    }
  ]
}
```

### Gateway Guardrails Config

```bash
# Via tfy CLI
tfy get gateway-guardrails-config

# Via Direct API
$TFY_API_SH GET '/api/svc/v1/gateway-guardrails-configs'
```

Example response (abridged):

```json
{
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
      "llm_input_guardrails": [ ... ],
      "llm_output_guardrails": [ ... ],
      "mcp_tool_pre_invoke_guardrails": [],
      "mcp_tool_post_invoke_guardrails": []
    }
  ]
}
```

## Schema Reference: Guardrail Config Group

Manifest type: `provider-account/guardrail-config-group`

### Top-Level Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Unique name for this config group (lowercase, hyphens) |
| `type` | string | Yes | Must be `provider-account/guardrail-config-group` |
| `integrations` | array of Integration | Yes | List of guardrail provider integrations |

### Integration Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | No | Optional display name for this integration |
| `type` | string | Yes | Guardrail provider type (e.g. `integration/guardrail/tfy-pii`). See [guardrail-providers.md](../guardrail-providers.md) for all 23 supported types |
| `config` | object | Yes | Provider-specific configuration. Empty `{}` for built-in providers that need no credentials |

Built-in providers requiring no config: `tfy-pii`, `tfy-content-moderation`, `tfy-prompt-injection`, `secret-detection`, `code-safety-linter`, `sql-sanitizer`.

External providers require credentials in `config` (e.g. `api_key`, `endpoint_url`). See [guardrail-providers.md](../guardrail-providers.md) for required fields per provider.

## Schema Reference: Gateway Guardrails Config

Manifest type: `gateway-guardrails-config`

### Top-Level Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Unique name for this guardrails config (lowercase, hyphens) |
| `type` | string | Yes | Must be `gateway-guardrails-config` |
| `gateway_ref` | string | Yes | Fully qualified name (FQN) of the AI Gateway deployment |
| `rules` | array of Rule | Yes | Ordered list of guardrail rules |

### Rule Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | Yes | Unique identifier for the rule within this config |
| `when` | object | Yes | Conditions controlling which requests this rule applies to |
| `llm_input_guardrails` | array of GuardrailEntry | No | Guardrails applied to LLM request inputs |
| `llm_output_guardrails` | array of GuardrailEntry | No | Guardrails applied to LLM response outputs |
| `mcp_tool_pre_invoke_guardrails` | array of GuardrailEntry | No | Guardrails applied before MCP tool execution |
| `mcp_tool_post_invoke_guardrails` | array of GuardrailEntry | No | Guardrails applied after MCP tool execution |

### `when` Object

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `target_conditions` | object | Yes | What the rule targets |
| `subject_conditions` | object | Yes | Who the rule applies to |

#### `target_conditions`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `models` | array of string | Yes | Model name patterns. Use `["*"]` for all models. Supports glob patterns like `"openai/gpt-4*"` |
| `mcp_servers` | array of string | Yes | MCP server names to target. Use `[]` if not targeting MCP servers |
| `tools` | array of string | Yes | Specific tool names to target. Use `[]` if not targeting specific tools |

#### `subject_conditions`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `users` | array of string | Yes | User patterns. Use `["*"]` for all users, or specific emails like `"alice@example.com"` |
| `teams` | array of string | Yes | Team names. Use `[]` if not filtering by team |

### GuardrailEntry Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `provider_ref` | string | Yes | Reference to the guardrail integration. Format: `{groupName}/{integrationName}` where `groupName` is the config group name and `integrationName` is the integration name within that group |
| `operation` | string (enum) | Yes | `validate` (check and block/flag) or `mutate` (modify content, e.g. redact PII) |
| `enforcing_strategy` | string (enum) | Yes | How violations are handled (see below) |
| `priority` | integer | No | Ordering when multiple guardrails apply. Lower values run first |

#### `provider_ref` Format

The `provider_ref` links a rule to a specific integration within a config group:

```
<provider-account-id>:integration/guardrail/<provider-type>
```

Where `<provider-account-id>` is the ID returned when creating the config group, and `<provider-type>` is the guardrail type (e.g. `tfy-pii`).

#### `enforcing_strategy` Values

| Value | Description |
|-------|-------------|
| `enforce` | Block the request on violation |
| `audit` | Log the violation but allow the request through |
| `enforce_but_ignore_on_error` | Enforce if the guardrail succeeds; allow the request if the guardrail itself errors |

## Generate & Validate Workflow

### 1. Create the Guardrail Config Group

Write a manifest for the provider integrations:

```yaml
# guardrail-providers.yaml
name: my-guardrails
type: provider-account/guardrail-config-group
integrations:
  - name: pii-filter
    type: integration/guardrail/tfy-pii
    config: {}
  - name: content-mod
    type: integration/guardrail/tfy-content-moderation
    config: {}
  - name: prompt-injection
    type: integration/guardrail/tfy-prompt-injection
    config: {}
```

Validate and apply:

```bash
tfy apply -f guardrail-providers.yaml --dry-run --show-diff
tfy apply -f guardrail-providers.yaml
```

Note the provider account ID from the response -- you need it for `provider_ref` values in the rules.

### 2. Write the Gateway Guardrails Config

```yaml
# guardrails-config.yaml
name: production-guardrails
type: gateway-guardrails-config
gateway_ref: GATEWAY_FQN
rules:
  # PII filtering on all models for all users
  - id: "pii-filter-all"
    when:
      target_conditions:
        models: ["*"]
        mcp_servers: []
        tools: []
      subject_conditions:
        users: ["*"]
        teams: []
    llm_input_guardrails:
      - provider_ref: "pa-abc123:integration/guardrail/tfy-pii"
        operation: mutate
        enforcing_strategy: enforce
        priority: 1
    llm_output_guardrails:
      - provider_ref: "pa-abc123:integration/guardrail/tfy-pii"
        operation: mutate
        enforcing_strategy: enforce
        priority: 1
    mcp_tool_pre_invoke_guardrails: []
    mcp_tool_post_invoke_guardrails: []

  # Content moderation in audit mode for specific models
  - id: "content-mod-audit"
    when:
      target_conditions:
        models: ["openai/gpt-4*", "anthropic/claude-*"]
        mcp_servers: []
        tools: []
      subject_conditions:
        users: ["*"]
        teams: []
    llm_input_guardrails:
      - provider_ref: "pa-abc123:integration/guardrail/tfy-content-moderation"
        operation: validate
        enforcing_strategy: audit
        priority: 1
    llm_output_guardrails: []
    mcp_tool_pre_invoke_guardrails: []
    mcp_tool_post_invoke_guardrails: []
```

### 3. Validate with dry run

```bash
tfy apply -f guardrails-config.yaml --dry-run --show-diff
```

### 4. Fix issues

Common problems:
- Invalid `provider_ref` -- ensure the provider account ID and integration type are correct
- Missing `gateway_ref` -- list gateways to get the FQN
- Duplicate rule `id` values -- each id must be unique
- Unknown guardrail type -- check [guardrail-providers.md](../guardrail-providers.md) for valid types
- Using `mutate` on a validate-only provider -- check the provider's supported operations

### 5. Apply

```bash
tfy apply -f guardrails-config.yaml
```

## Common Patterns

### PII Filtering on All Traffic

Apply `tfy-pii` with `mutate` operation on both input and output to redact PII before it reaches the model and in responses:

```yaml
llm_input_guardrails:
  - provider_ref: "pa-abc123:integration/guardrail/tfy-pii"
    operation: mutate
    enforcing_strategy: enforce
llm_output_guardrails:
  - provider_ref: "pa-abc123:integration/guardrail/tfy-pii"
    operation: mutate
    enforcing_strategy: enforce
```

### Audit Mode for Initial Rollout

Use `enforcing_strategy: audit` to monitor violations without blocking requests. Review logs, then switch to `enforce`:

```yaml
enforcing_strategy: audit
```

### Model-Specific Rules

Target guardrails to specific models using glob patterns in `target_conditions.models`:

```yaml
target_conditions:
  models: ["openai/gpt-4*", "anthropic/claude-*"]
  mcp_servers: []
  tools: []
```

### User Exemptions

Restrict a rule to specific teams or users so others are exempt:

```yaml
subject_conditions:
  users: []
  teams: ["engineering", "data-science"]
```

### MCP Tool Guardrails

Scan tool inputs before execution and outputs after:

```yaml
mcp_tool_pre_invoke_guardrails:
  - provider_ref: "pa-abc123:integration/guardrail/tfy-prompt-injection"
    operation: validate
    enforcing_strategy: enforce
mcp_tool_post_invoke_guardrails:
  - provider_ref: "pa-abc123:integration/guardrail/secret-detection"
    operation: validate
    enforcing_strategy: enforce
```

## Checklist

- [ ] Fetched existing guardrail config groups and gateway guardrails config
- [ ] Created a guardrail config group with the needed provider integrations
- [ ] Noted the provider account ID from the config group creation response
- [ ] `provider_ref` values use the correct format: `<provider-account-id>:integration/guardrail/<type>`
- [ ] `gateway_ref` is set to the correct gateway FQN
- [ ] Rule IDs are unique within the config
- [ ] `operation` matches what the provider supports (`validate` vs `mutate`)
- [ ] Considered `audit` enforcing strategy for initial rollout
- [ ] External guardrail provider endpoints are trusted and organization-controlled
- [ ] Validated both manifests with `tfy apply --dry-run --show-diff` before applying
- [ ] Tested a request after apply to confirm guardrails are active
