---
name: rate-limiting-schema
description: Schema reference for gateway-rate-limiting-config manifests. Covers rule fields, valid units, matcher syntax, and the generate-validate-apply workflow.
---

# Rate Limiting Config Schema

Manifest type: `gateway-rate-limiting-config`

Rate limiting controls how many requests or tokens a user, team, or application can consume within a time window. Only the **first matching rule** applies to a given request -- place specific rules before generic ones.

## Fetch Existing Config

### Via tfy CLI

```bash
tfy get gateway-rate-limiting-config
```

### Via Direct API

```bash
$TFY_API_SH GET '/api/svc/v1/gateway/configs?type=gateway-rate-limiting-config'
```

Example response (abridged):

```json
{
  "name": "rate-limits",
  "type": "gateway-rate-limiting-config",
  "rules": [
    {
      "id": "team-rpm-limit",
      "when": {
        "subjects": ["team:backend"],
        "models": ["openai-main/gpt-4o"]
      },
      "limit_to": 20000,
      "unit": "tokens_per_minute"
    },
    {
      "id": "global-fallback",
      "when": {},
      "limit_to": 500,
      "unit": "requests_per_minute",
      "rate_limit_applies_per": ["user"]
    }
  ]
}
```

## Schema Reference

### Top-Level Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Unique name for this config (lowercase, hyphens) |
| `type` | string | Yes | Must be `gateway-rate-limiting-config` |
| `rules` | array of Rule | Yes | Ordered list of rate limiting rules |

### Rule Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | Yes | Unique identifier for the rule within this config |
| `when` | object | Yes | Matcher that determines which requests this rule applies to. Use `{}` to match all requests |
| `limit_to` | number | Yes | Maximum allowed value for the chosen unit |
| `unit` | string (enum) | Yes | The rate limiting unit (see Valid Units below) |
| `rate_limit_applies_per` | array of string | No | Entities to create separate counters for (max 2 values). Defaults to a single global counter if omitted |

### `when` Matcher

The `when` object controls which requests match this rule. An empty object `{}` matches everything.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `subjects` | array of string | No | Subject patterns to match. Examples: `"user:alice@example.com"`, `"team:backend"`, `"*"` (all) |
| `models` | array of string | No | Model name patterns to match. Examples: `"openai-main/gpt-4o"`, `"*"` (all) |
| `metadata` | object | No | Key-value pairs to match against request metadata |

Subject pattern formats:
- `"user:<email>"` -- matches a specific user
- `"team:<name>"` -- matches all members of a team
- `"*"` -- matches any subject

### Valid Units

| Unit | Description |
|------|-------------|
| `requests_per_minute` | Number of requests per minute |
| `requests_per_hour` | Number of requests per hour |
| `requests_per_day` | Number of requests per day |
| `tokens_per_minute` | Total tokens (input + output) per minute |
| `tokens_per_hour` | Total tokens (input + output) per hour |
| `tokens_per_day` | Total tokens (input + output) per day |

### `rate_limit_applies_per` Options

Creates independent counters per entity. Maximum of 2 values in the array.

| Value | Description |
|-------|-------------|
| `user` | Separate limit per individual user |
| `model` | Separate limit per model |
| `virtualaccount` | Separate limit per virtual account token |
| `metadata.<key>` | Separate limit per value of the given metadata key (e.g. `metadata.project_id`) |

## Generate & Validate Workflow

### 1. Write the YAML manifest

```yaml
# rate-limits.yaml
name: rate-limits
type: gateway-rate-limiting-config
rules:
  # Specific rule first: team-level token limit on a single model
  - id: "team-rpm-limit"
    when:
      subjects: ["team:backend"]
      models: ["openai-main/gpt-4o"]
    limit_to: 20000
    unit: tokens_per_minute

  # Per-user daily request limit for a specific user
  - id: "user-daily-limit"
    when:
      subjects: ["user:bob@example.com"]
      models: ["openai-main/gpt-4o"]
    limit_to: 1000
    unit: requests_per_day

  # Per-project hourly token limit using metadata
  - id: "per-project-hourly"
    when: {}
    limit_to: 50000
    unit: tokens_per_hour
    rate_limit_applies_per: ["metadata.project_id"]

  # Generic fallback: per-user RPM across all models
  - id: "global-fallback"
    when: {}
    limit_to: 500
    unit: requests_per_minute
    rate_limit_applies_per: ["user"]
```

### 2. Validate with dry run

```bash
tfy apply -f rate-limits.yaml --dry-run --show-diff
```

Review the diff output. Fix any validation errors before proceeding.

### 3. Fix issues

Common problems:
- Duplicate rule `id` values -- each id must be unique within the config
- `rate_limit_applies_per` with more than 2 entries -- reduce to at most 2
- Invalid `unit` value -- use one of the six valid units listed above
- Rules in wrong order -- specific rules must come before generic ones

### 4. Apply

```bash
tfy apply -f rate-limits.yaml
```

## Checklist

- [ ] Fetched existing rate limiting config to understand current state
- [ ] Rule IDs are unique within the config
- [ ] Specific rules are ordered before generic/fallback rules
- [ ] `unit` values are from the valid set (requests_per_minute/hour/day, tokens_per_minute/hour/day)
- [ ] `rate_limit_applies_per` has at most 2 entries
- [ ] `when` matchers use correct subject patterns (`user:`, `team:`, or `*`)
- [ ] Validated with `tfy apply --dry-run --show-diff` before applying
- [ ] Tested a request after apply to confirm limits are active
