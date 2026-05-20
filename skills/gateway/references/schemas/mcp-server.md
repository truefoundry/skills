---
name: mcp-server-schema
description: Compact schema reference for MCP Gateway manifests. For full YAML examples, use the MCP servers skill references.
---

# MCP Server Schema Reference

This file is a compact schema index for gateway-related work. The canonical MCP Gateway workflow lives in `skills/mcp-servers/SKILL.md`.

For detailed examples, read:

- `../../../mcp-servers/references/mcp-yaml-variations.md`
- `../../../mcp-servers/references/mcp-gateway-ui-flows.md`

Treat the live dashboard `Apply using YAML` preview as the source of truth when it differs from static examples.

## Fetch Existing Config

```bash
# List all MCP servers
$TFY_API_SH GET /api/svc/v1/mcp-servers

# Get a specific MCP server by ID
$TFY_API_SH GET /api/svc/v1/mcp-servers/SERVER_ID
```

## Common Fields

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `name` | string | Yes | Unique MCP server name |
| `type` | string | Yes | `mcp-server/remote`, `mcp-server/openapi`, or `mcp-server/virtual` |
| `description` | string | Yes | Human-readable purpose |
| `collaborators` | array | Yes | Access grants |
| `tags` | string[] | No | Organization/filtering metadata |

Collaborator subjects:

- `user:<email>`
- `team:<slug>`
- `serviceaccount:<name>`
- `virtualaccount:<name>`

Use `role_id: mcp-server-manager` for management access unless the user requests another role.

## Server Types

### Remote

Connects to an existing HTTP MCP endpoint.

Required fields:

- `name`
- `description`
- `type: mcp-server/remote`
- `url`
- `collaborators`

Optional fields include `auth_data`, `tls_settings`, and `tags`.

### OpenAPI

Wraps OpenAPI operations as MCP tools.

Required fields:

- `name`
- `description`
- `type: mcp-server/openapi`
- `spec`
- `collaborators`

Use only trusted remote spec URLs. Prefer inline specs for sensitive private APIs.

### Virtual

Composes existing MCP servers into one virtual server.

Required fields:

- `name`
- `description`
- `type: mcp-server/virtual`
- `servers`
- `collaborators`

Each `servers[]` entry needs `name`. Add `enabled_tools` only when exposing a selected subset. Omit `enabled_tools` when exposing every tool from that source.

### Hosted STDIO-Derived

The UI starts from an `mcpServers` JSON object with `command`, `args`, and optional `env`, then generates the gateway manifest. Use the generated YAML preview as the manifest source of truth.

## Auth Data

No auth means omit `auth_data`.

Supported auth modes:

| UI mode | YAML shape |
|---------|------------|
| API Key / shared credentials | `auth_data.type: header`, `auth_level: global`, `headers` |
| API Key / individual credentials | `auth_data.type: header`, `auth_level: per_user`, `headers` with placeholders |
| OAuth2 authorization code | `auth_data.type: oauth2`, `grant_type: authorization_code` |
| OAuth2 client credentials | `auth_data.type: oauth2`, `grant_type: client_credentials` |
| Token passthrough | `auth_data.type: passthrough` |

Use `tfy-secret://...` references for shared real credentials. Use placeholders such as `{{API_KEY}}` for per-user values.

Read `../../../mcp-servers/references/mcp-yaml-variations.md` for concrete auth examples.

## Tool Enablement

For normal remote/OpenAPI servers:

1. Fetch the current server config.
2. Inspect the API response or UI YAML preview for the tool-selection shape.
3. Modify only the requested tool-selection fields.
4. Preserve URL/spec, auth, TLS, collaborators, tags, and unrelated fields.

Do not guess field names for normal-server tool filtering.

For virtual servers, use `servers[].enabled_tools`.

## Generate And Validate

Dry-run first:

```bash
tfy apply -f mcp-server.yaml --dry-run --show-diff
```

Apply only after explicit confirmation:

```bash
tfy apply -f mcp-server.yaml
```

Common checks:

- `name`, `description`, `type`, and collaborators are set.
- Auth disabled omits `auth_data`.
- API key auth includes `type: header`, `auth_level`, and headers.
- OAuth2 auth includes the right `grant_type`, `token_url`, and `jwt_source`.
- Shared secrets use `tfy-secret://...`.
- Virtual source servers and `enabled_tools` are valid.
- YAML preview and hand-written manifest agree; prefer the gateway preview.
