---
name: mcp-server-schema
description: Schema reference for MCP server manifests -- remote, OpenAPI, virtual, and hosted STDIO-derived servers -- including auth, access control, and tool filtering workflows.
---

# MCP Server Schema Reference

MCP Gateway manages remote endpoints, OpenAPI-backed servers, virtual composite servers, and hosted STDIO-derived servers. Use the live gateway YAML preview as the source of truth when it exposes fields not covered here.

## Fetch Existing Config

```bash
# List all MCP servers
$TFY_API_SH GET /api/svc/v1/mcp-servers

# Get a specific MCP server by ID
$TFY_API_SH GET /api/svc/v1/mcp-servers/SERVER_ID
```

## Common Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Unique MCP server name |
| `type` | string | Yes | `mcp-server/remote`, `mcp-server/openapi`, or `mcp-server/virtual` |
| `description` | string | Yes | Human-readable purpose |
| `collaborators` | array | Yes | Access grants for users, teams, service accounts, or virtual accounts |
| `tags` | string[] | No | Tags for organization and filtering |

### Collaborator Entry

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `subject` | string | Yes | `user:<email>`, `team:<slug>`, `serviceaccount:<name>`, or `virtualaccount:<name>` |
| `role_id` | string | Yes | Use `mcp-server-manager` for management access unless another MCP server role is requested |

```yaml
collaborators:
  - subject: user:alice@example.com
    role_id: mcp-server-manager
```

## Remote MCP Server

Connects to an existing HTTP MCP endpoint.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Unique server name |
| `type` | string | Yes | `mcp-server/remote` |
| `description` | string | Yes | Human-readable purpose |
| `url` | string | Yes | MCP endpoint URL |
| `auth_data` | object | No | Omit when auth is disabled |
| `collaborators` | array | Yes | Access grants |
| `tls_settings` | object | No | TLS settings |
| `tags` | string[] | No | Tags |

Auth disabled:

```yaml
name: analytics-mcp
description: Analytics tools for internal workflows
url: https://analytics.example.com/mcp
collaborators:
  - subject: user:alice@example.com
    role_id: mcp-server-manager
type: mcp-server/remote
```

## Auth Data

### API Key / Header Auth

Use `type: header` when the downstream MCP server expects one or more request headers.

Shared credentials:

```yaml
auth_data:
  type: header
  auth_level: global
  headers:
    Authorization: "Bearer tfy-secret://tenant:mcp-secrets:analytics-token"
```

Individual credentials:

```yaml
auth_data:
  type: header
  auth_level: per_user
  headers:
    Authorization: "Bearer {{API_KEY}}"
```

Rules:

- `auth_level: global` means one shared credential is used for all callers.
- `auth_level: per_user` means each user supplies their own credential.
- Use `tfy-secret://...` references for shared real credentials.
- Use placeholders such as `{{API_KEY}}` for per-user values.

### OAuth2 Authorization Code

Use for user-facing OAuth login flows.

```yaml
auth_data:
  type: oauth2
  grant_type: authorization_code
  authorization_url: https://auth.example.com/authorize
  token_url: https://auth.example.com/token
  client_id: tfy-secret://tenant:mcp-secrets:oauth-client-id
  client_secret: tfy-secret://tenant:mcp-secrets:oauth-client-secret
  registration_url: https://auth.example.com/register
  jwt_source: access_token
```

Notes:

- `token_url` and `jwt_source` are required in the UI.
- `authorization_url`, `client_id`, `client_secret`, and `registration_url` may be optional depending on the provider and DCR support.
- Optional settings may include scopes, PKCE/code challenge methods, and additional token parameters.

### OAuth2 Client Credentials

Use for server-to-server OAuth.

```yaml
auth_data:
  type: oauth2
  grant_type: client_credentials
  token_url: https://auth.example.com/token
  client_id: tfy-secret://tenant:mcp-secrets:oauth-client-id
  client_secret: tfy-secret://tenant:mcp-secrets:oauth-client-secret
  jwt_source: access_token
```

Notes:

- `token_url`, `client_id`, `client_secret`, and `jwt_source` are required in the UI.
- Optional settings may include scopes and additional token parameters.

### Token Passthrough

Use when the downstream MCP server should receive the caller's existing TrueFoundry auth token.

```yaml
auth_data:
  type: passthrough
```

## TLS Settings

```yaml
tls_settings:
  ca_cert: tfy-secret://tenant:mcp-secrets:ca-cert-pem
  insecure_skip_verify: false
```

Use a secret reference for CA certificate PEM data. Keep `insecure_skip_verify: false` unless the user explicitly accepts the risk.

## OpenAPI MCP Server

Wraps an OpenAPI specification as MCP tools. Operations in the spec become tools.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Unique server name |
| `type` | string | Yes | `mcp-server/openapi` |
| `description` | string | Yes | Human-readable purpose |
| `spec` | object | Yes | Remote or inline OpenAPI spec |
| `auth_data` | object | No | Same auth options as remote server |
| `collaborators` | array | Yes | Access grants |

Remote spec:

```yaml
name: internal-api
description: Internal API exposed as MCP tools
type: mcp-server/openapi
spec:
  type: remote
  url: https://internal.example.com/openapi.json
collaborators:
  - subject: team:platform
    role_id: mcp-server-manager
```

Inline spec:

```yaml
spec:
  type: inline
  content: |
    openapi: "3.0.0"
    info:
      title: Internal API
      version: "1.0"
    paths:
      /health:
        get:
          operationId: healthCheck
          responses:
            "200":
              description: OK
```

Only use trusted remote spec URLs. Prefer inline specs for sensitive private APIs.

## Virtual MCP Server

Composes existing MCP servers into one virtual server. Each source can expose all tools or a selected subset.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Unique virtual server name |
| `type` | string | Yes | `mcp-server/virtual` |
| `description` | string | Yes | Human-readable purpose |
| `servers` | array | Yes | Source server entries |
| `collaborators` | array | Yes | Access grants |

Source server entry:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Name of an already registered MCP server |
| `enabled_tools` | string[] | No | Subset of tools to expose; omit to expose every tool from that source |

```yaml
name: dev-tools
description: Composite server for engineering workflows
type: mcp-server/virtual
servers:
  - name: linear
    enabled_tools:
      - list_issues
      - create_issue
  - name: deepwiki
    enabled_tools:
      - read_wiki_structure
      - read_wiki_contents
collaborators:
  - subject: team:platform
    role_id: mcp-server-manager
```

Creation flow:

1. Choose `name` and `description`.
2. Select source MCP servers.
3. Enumerate available tools for each source.
4. Include `enabled_tools` only for selected subsets.
5. Add collaborators.
6. Dry-run and apply only after explicit confirmation.

## Hosted STDIO-Derived Server

The UI accepts a local-style `mcpServers` JSON config and turns it into a gateway-hosted/exposed MCP server.

Input shape:

```json
{
  "mcpServers": {
    "exa-user1": {
      "command": "npx",
      "args": ["-y", "mcp-remote", "https://mcp.exa.ai/mcp"],
      "env": {
        "EXA_API_KEY": "REPLACE_WITH_EXA_API_KEY"
      }
    }
  }
}
```

Use the generated gateway YAML preview as the manifest source of truth. Move real env secrets into secret references wherever supported.

## Tool Enablement

### Normal Remote/OpenAPI Servers

The gateway UI supports enabling and disabling tools on normal remote/OpenAPI servers. When changing tool exposure for an existing non-virtual server:

1. Fetch the server by ID.
2. Inspect the API response or UI YAML preview for the existing tool-selection shape.
3. Modify only the requested tool-selection fields.
4. Preserve URL/spec, auth, TLS, collaborators, tags, and unrelated fields.
5. Dry-run with `tfy apply -f mcp-server.yaml --dry-run --show-diff`.
6. Apply only after explicit confirmation.

Do not guess field names for normal-server tool filtering.

### Virtual Servers

Use `servers[].enabled_tools`. Omit it only when exposing all tools from a source server.

## Generate And Validate

Dry-run first:

```bash
tfy apply -f mcp-server.yaml --dry-run --show-diff
```

Apply only after explicit confirmation:

```bash
tfy apply -f mcp-server.yaml
```

Common issues:

- Server `name` is not unique.
- Raw credentials are embedded instead of secret references or per-user placeholders.
- OAuth2 grant type does not match required fields.
- OpenAPI spec URL is untrusted or produces too many tools.
- Virtual server references unknown source server names.
- `enabled_tools` includes names that do not exist on the source server.
- YAML preview and hand-written manifest disagree; prefer the gateway preview.

## Checklist

- [ ] `name`, `description`, `type`, and collaborators are set.
- [ ] Auth disabled means `auth_data` is omitted.
- [ ] API key auth includes `type: header`, `auth_level`, and headers.
- [ ] OAuth2 auth includes `grant_type`, `token_url`, and `jwt_source`.
- [ ] Shared secrets use `tfy-secret://...`.
- [ ] Virtual server sources and `enabled_tools` are valid.
- [ ] Access grants use MCP server roles such as `mcp-server-manager`.
- [ ] Dry-run passes before any final apply.
