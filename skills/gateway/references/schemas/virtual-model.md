---
name: virtual-model-schema
description: Complete schema reference for virtual model routing configurations including weight-based, latency-based, and priority-based routing, sticky sessions, and fallback behavior.
---

# Virtual Model Schema Reference

Virtual models route requests across multiple model instances using a `gateway-load-balancing-config` manifest. Targets reference real catalog models as `"<provider-account-name>/<integration-name>"`.

## Fetch Existing Config

```bash
# List all provider accounts (includes virtual models)
$TFY_API_SH GET /api/svc/v1/provider-accounts
```

Filter results client-side for entries with `manifest.type` equal to `provider-account/virtual-model`.

> **Note:** The `type` query parameter does NOT filter results on this endpoint. Fetch all and filter client-side.

### Example Response (Virtual Model Provider Account)

```json
{
  "id": "pa-vm-abc123",
  "name": "chat-router",
  "provider": "virtual-model",
  "manifest": {
    "name": "chat-router",
    "type": "provider-account/virtual-model",
    "integrations": [
      {
        "name": "gpt-4o-virtual",
        "type": "integration/model/virtual",
        "routing_config": { ... }
      }
    ]
  }
}
```

---

## Schema Reference

### Top-Level Manifest (Load Balancing Config)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Unique config name (lowercase, hyphens) |
| `type` | string | Yes | `"gateway-load-balancing-config"` |
| `rules` | array | Yes | Array of routing rule objects |

### Virtual Model Provider Account

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Provider account name |
| `type` | string | Yes | `"provider-account/virtual-model"` |
| `integrations` | array | Yes | Array with virtual model integrations |

### Virtual Model Integration

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Integration name (used as the model slug) |
| `type` | string | Yes | `"integration/model/virtual"` |
| `routing_config` | object | Yes | Routing configuration (defined in rules) |

---

### Routing Rule

Each entry in the `rules` array:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | Yes | Unique rule identifier |
| `type` | string | Yes | Routing strategy (see Routing Types below) |
| `when` | object | Yes | Conditions controlling when this rule applies |
| `load_balance_targets` | array | Yes | Array of target configurations |
| `sticky_routing` | object | No | Sticky session config (see Sticky Routing) |

### Routing Types

| `type` Value | Description |
|-------------|-------------|
| `weight-based-routing` | Distributes traffic by percentage weights |
| `latency-based-routing` | Routes to lowest-latency target (measures TPOT over last 20 minutes) |
| `priority-based-routing` | Routes to highest-priority healthy target with SLA cutoff |

### `when` Conditions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `subjects` | string[] | Yes | Subject patterns -- `["*"]` for all, or `"team:<name>"`, `"user:<email>"` |
| `models` | string[] | Yes | Model name patterns -- `["*"]` for all, or specific model names |

---

### Load Balance Target

Each entry in `load_balance_targets`:

| Field | Type | Required | Applies To | Description |
|-------|------|----------|------------|-------------|
| `target` | string | Yes | All | Target model: `"<provider-account-name>/<integration-name>"` |
| `weight` | integer | Yes (weight-based) | weight-based | Traffic percentage (all weights should sum logically) |
| `priority` | integer | Yes (priority-based) | priority-based | Priority rank (0 = highest priority) |
| `sla_cutoff` | object | No | priority-based | SLA threshold; auto-marks target unhealthy when exceeded |
| `fallback_candidate` | boolean | No | All | `true` to mark as eligible for failover (default: varies) |
| `fallback_status_codes` | string[] | No | All | HTTP codes triggering fallback. Default: `["401","403","404","429","500","502","503"]` |
| `retry_config` | object | No | All | Retry settings for transient errors |
| `headers_override` | object | No | All | Per-target header modifications |

### `sla_cutoff` (Priority-Based Only)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `time_per_output_token_ms` | integer | Yes | Max TPOT in ms; target marked unhealthy if exceeded |

```yaml
sla_cutoff:
  time_per_output_token_ms: 50
```

### `retry_config`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `delay` | integer | Yes | Delay in ms between retries |
| `attempts` | integer | Yes | Number of retry attempts |
| `on_status_codes` | string[] | Yes | HTTP status codes that trigger a retry |

```yaml
retry_config:
  delay: 100
  attempts: 1
  on_status_codes: ["429", "500", "502", "503"]
```

### `headers_override`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `set` | object | No | Headers to set (key-value pairs) |
| `remove` | string[] | No | Header names to remove |

```yaml
headers_override:
  set:
    x-region: us-east-1
  remove:
    - x-internal-debug
```

---

### Sticky Routing

Pin users to the same target for a duration. Works with any routing type.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `ttl_seconds` | integer | Yes | Duration to pin a user to a target (in seconds) |
| `session_identifiers` | array | Yes | Array of identifiers to determine session affinity |

#### Session Identifier

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `key` | string | Yes | Header or parameter name (e.g., `x-user-id`) |
| `source` | string | Yes | Where to read the key from: `"headers"` |

```yaml
sticky_routing:
  ttl_seconds: 3600
  session_identifiers:
    - key: x-user-id
      source: headers
```

---

### Fallback Behavior

Fallback is configured per-target inside `load_balance_targets`:

- `fallback_status_codes` defaults to `["401", "403", "404", "429", "500", "502", "503"]`
- `fallback_candidate: true` marks a target as eligible to receive failover traffic
- `retry_config.on_status_codes` controls which errors trigger retries before fallback

Targets must be real catalog models, not nested virtual models.

---

## Generate and Validate Workflow

### 1. Write YAML manifest

#### Weight-Based Example

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

#### Latency-Based Example

```yaml
name: latency-routing
type: gateway-load-balancing-config
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

#### Priority-Based Example

```yaml
name: priority-routing
type: gateway-load-balancing-config
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

#### Sticky Sessions Example

```yaml
name: sticky-routing
type: gateway-load-balancing-config
rules:
  - id: sticky-chat
    type: weight-based-routing
    sticky_routing:
      ttl_seconds: 3600
      session_identifiers:
        - key: x-user-id
          source: headers
    when:
      subjects: ["*"]
      models: ["openai/gpt-4o"]
    load_balance_targets:
      - target: "openai-main/gpt-4o"
        weight: 50
      - target: "azure-backup/gpt-4o"
        weight: 50
```

### 2. Validate (dry run)

```bash
tfy apply -f gateway-load-balancing-config.yaml --dry-run --show-diff
```

### 3. Fix any errors

Common issues:
- Target format must be `"<provider-account-name>/<integration-name>"` (not just a model name)
- Targets must reference real catalog models, not nested virtual models
- Weight-based routing requires `weight` on every target
- Priority-based routing requires `priority` on every target
- `sla_cutoff` only applies to `priority-based-routing`
- `sticky_routing` requires both `ttl_seconds` and `session_identifiers`

### 4. Apply

```bash
tfy apply -f gateway-load-balancing-config.yaml
```

---

## Checklist

- [ ] Config `name` is unique and lowercase with hyphens
- [ ] `type` is `gateway-load-balancing-config`
- [ ] Each rule has a unique `id`
- [ ] Rule `type` is one of: `weight-based-routing`, `latency-based-routing`, `priority-based-routing`
- [ ] `when.subjects` and `when.models` are set (use `["*"]` for all)
- [ ] All targets use the format `"<provider-account-name>/<integration-name>"`
- [ ] All targets reference real catalog models (not virtual models)
- [ ] Weight-based rules have `weight` on every target
- [ ] Priority-based rules have `priority` on every target (0 = highest)
- [ ] At least one target has `fallback_candidate: true` if fallback is desired
- [ ] `retry_config.on_status_codes` uses string values (e.g., `"429"`, not `429`)
- [ ] Sticky routing includes `ttl_seconds` and at least one session identifier
- [ ] Dry-run passes: `tfy apply -f manifest.yaml --dry-run --show-diff`
