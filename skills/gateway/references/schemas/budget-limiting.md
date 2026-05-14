---
name: budget-limiting-schema
description: Schema reference for gateway-budget-config manifests. Covers rule fields, cost units, alert configuration, and the generate-validate-apply workflow.
---

# Budget Config Schema

Manifest type: `gateway-budget-config`

Budget controls enforce cost limits per user, team, or custom metadata dimension. Costs are tracked automatically based on model pricing. When a budget is exhausted, subsequent requests are blocked until the period resets.

## Fetch Existing Config

### Via tfy CLI

```bash
tfy get gateway-budget-config
```

### Via Direct API

```bash
$TFY_API_SH GET '/api/svc/v1/gateway/configs?type=gateway-budget-config'
```

Example response (abridged):

```json
{
  "name": "budget-controls",
  "type": "gateway-budget-config",
  "rules": [
    {
      "id": "team-monthly-budget",
      "when": {
        "subjects": ["team:engineering"]
      },
      "limit_to": 5000,
      "unit": "cost_per_month",
      "budget_applies_per": ["team"],
      "alerts": {
        "thresholds": [75, 90, 100],
        "notification_target": [
          {
            "type": "email",
            "notification_channel": "budget-alerts",
            "to_emails": ["lead@example.com"]
          }
        ]
      }
    },
    {
      "id": "user-daily-budget",
      "when": {},
      "limit_to": 100,
      "unit": "cost_per_day",
      "budget_applies_per": ["user"]
    }
  ]
}
```

## Schema Reference

### Top-Level Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Unique name for this config (lowercase, hyphens) |
| `type` | string | Yes | Must be `gateway-budget-config` |
| `rules` | array of Rule | Yes | Ordered list of budget rules |

### Rule Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | Yes | Unique identifier for the rule within this config |
| `when` | object | Yes | Matcher that determines which requests this rule applies to. Use `{}` to match all requests |
| `limit_to` | number | Yes | Maximum cost allowed in the budget period (USD) |
| `unit` | string (enum) | Yes | The budget period unit (see Valid Units below) |
| `budget_applies_per` | array of string | No | Entities to create separate budget counters for. Defaults to a single global counter if omitted |
| `alerts` | object | No | Alert configuration for threshold notifications |
| `audit_mode` | boolean | No | When `true`, log budget violations but do not block requests. Defaults to `false` |

### `when` Matcher

The `when` object controls which requests match this rule. An empty object `{}` matches everything. Same structure as rate limiting.

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

| Unit | Reset Schedule |
|------|---------------|
| `cost_per_day` | Resets at UTC midnight |
| `cost_per_week` | Resets Monday at UTC midnight |
| `cost_per_month` | Resets on the 1st of each month at UTC midnight |

### `budget_applies_per` Options

Creates independent budget counters per entity.

| Value | Description |
|-------|-------------|
| `user` | Separate budget per individual user |
| `model` | Separate budget per model |
| `team` | Separate budget per team |
| `virtualaccount` | Separate budget per virtual account token |
| `metadata.<key>` | Separate budget per value of the given metadata key (e.g. `metadata.project_id`) |

### `alerts` Object

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `thresholds` | array of number | Yes | Percentage thresholds that trigger notifications (e.g. `[75, 90, 100]`) |
| `notification_target` | array of NotificationTarget | Yes | Where to send alert notifications |

### NotificationTarget Object

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | string (enum) | Yes | `email` or `slack` |
| `notification_channel` | string | Yes | Channel name for routing the notification |
| `to_emails` | array of string | Conditional | Required when `type` is `email`. List of email addresses |

For Slack notifications, use `type: "slack"` and configure the `notification_channel` to match your Slack webhook integration name.

## Generate & Validate Workflow

### 1. Write the YAML manifest

```yaml
# budget-controls.yaml
name: budget-controls
type: gateway-budget-config
rules:
  # Team-level monthly budget with alerts
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

  # Per-user daily budget (no alerts)
  - id: "user-daily-budget"
    when: {}
    limit_to: 100
    unit: cost_per_day
    budget_applies_per: ["user"]

  # Per-project daily budget for production, audit mode
  - id: "project-daily-budget"
    when:
      metadata:
        environment: "production"
    limit_to: 200
    unit: cost_per_day
    budget_applies_per: ["metadata.project_id"]
    audit_mode: true
```

### 2. Validate with dry run

```bash
tfy apply -f budget-controls.yaml --dry-run --show-diff
```

Review the diff output. Fix any validation errors before proceeding.

### 3. Fix issues

Common problems:
- Duplicate rule `id` values -- each id must be unique within the config
- Invalid `unit` value -- must be `cost_per_day`, `cost_per_week`, or `cost_per_month`
- Missing `thresholds` or `notification_target` inside `alerts` -- both are required when alerts is present
- `to_emails` missing when notification type is `email`

### 4. Apply

```bash
tfy apply -f budget-controls.yaml
```

## Checklist

- [ ] Fetched existing budget config to understand current state
- [ ] Rule IDs are unique within the config
- [ ] `unit` values are from the valid set (`cost_per_day`, `cost_per_week`, `cost_per_month`)
- [ ] `limit_to` values are in USD and reflect intended spend caps
- [ ] `budget_applies_per` correctly scopes counters (per user, team, model, etc.)
- [ ] Alert thresholds are percentages (0-100) and notification targets have required fields
- [ ] `when` matchers use correct subject patterns (`user:`, `team:`, or `*`)
- [ ] Considered `audit_mode: true` for initial rollout before enforcing
- [ ] Validated with `tfy apply --dry-run --show-diff` before applying
- [ ] Tested a request after apply to confirm budget tracking is active
