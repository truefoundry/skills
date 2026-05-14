---
name: mcp-server-schema
description: Complete schema reference for MCP server types -- remote, OpenAPI, and virtual -- including transport, auth, TLS, and tool filtering configurations.
---

# MCP Server Schema Reference

Three MCP server types can be registered with the gateway: remote endpoints, OpenAPI spec wrappers, and virtual (composite) servers.

## Fetch Existing Config

```bash
# List all MCP servers
$TFY_API_SH GET /api/svc/v1/mcp-servers

# Get a specific MCP server by ID
$TFY_API_SH GET /api/svc/v1/mcp-servers/SERVER_ID
```

### Example Response

```json
{
  "data": [
    {
      "id": "mcp-abc123",
      "name": "my-remote-server",
      "type": "mcp-server/remote",
      "description": "Production analytics MCP server",
      "url": "https://analytics.example.com/mcp",
      "transport": "streamable-http",
      "auth_data": {
        "type": "header",
        "headers": {
          "Authorization": "Bearer tfy-secret://my-org:mcp-secrets:api-token"
        }
      },
      "collaborators": [
        { "subject": "user:jane@example.com", "role_id": "admin" }
      ],
      "tags": ["analytics", "production"]
    },
    {
      "id": "mcp-def456",
      "name": "dev-tools",
      "type": "mcp-server/virtual",
      "description": "Composite server",
      "servers": [ ... ]
    },
    {
      "id": "mcp-ghi789",
      "name": "petstore-api",
      "type": "mcp-server/openapi",
      "description": "Petstore API exposed as MCP tools",
      "spec": { "type": "remote", "url": "https://internal-api.example.com/openapi.json" }
    }
  ]
}
```

---

## Schema Reference

### Common Fields (All MCP Server Types)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Unique server name |
| `type` | string | Yes | `"mcp-server/remote"`, `"mcp-server/openapi"`, or `"mcp-server/virtual"` |
| `description` | string | No | Human-readable description |
| `collaborators` | array | No | Access control entries |
| `tags` | string[] | No | Tags for organization and filtering |

### Collaborator Entry

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `subject` | string | Yes | `user:<email>` or `team:<team-name>` |
| `role_id` | string | Yes | `"admin"` or `"viewer"` |

---

## Type 1: `mcp-server/remote`

Connects to an existing MCP endpoint over HTTP.

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Unique server name |
| `type` | string | Yes | `"mcp-server/remote"` |
| `url` | string | Yes | MCP endpoint URL |
| `transport` | string | Yes | `"streamable-http"` or `"sse"` |
| `auth_data` | object | No | Authentication config (see Auth Options) |
| `tls_settings` | object | No | TLS configuration (see TLS Settings) |
| `description` | string | No | Human-readable description |
| `collaborators` | array | No | Access control entries |
| `tags` | string[] | No | Tags for organization |

Internal URL pattern for cluster services: `http://{service-name}.{namespace}.svc.cluster.local:{port}/mcp`

### Auth Options

#### `header` -- Static Header Auth

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | string | Yes | `"header"` |
| `headers` | object | Yes | Key-value pairs of headers to send |

```yaml
auth_data:
  type: header
  headers:
    Authorization: "Bearer tfy-secret://my-org:mcp-secrets:api-token"
```

All header values containing credentials MUST use `tfy-secret://` references.

#### `oauth2` -- OAuth2 Auth

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | string | Yes | `"oauth2"` |
| `authorization_url` | string | Yes | OAuth2 authorization endpoint |
| `token_url` | string | Yes | OAuth2 token endpoint |
| `client_id` | string | Yes | OAuth2 client ID |
| `client_secret` | string | Yes | `tfy-secret://` reference to client secret |
| `jwt_source` | string | No | Token field to use (e.g., `"access_token"`) |
| `scopes` | string[] | No | OAuth2 scopes to request |
| `pkce` | boolean | No | Enable PKCE (`true`/`false`) |
| `dynamic_client_registration` | object | No | Dynamic client registration config |

```yaml
auth_data:
  type: oauth2
  authorization_url: https://auth.example.com/authorize
  token_url: https://auth.example.com/token
  client_id: my-client-id
  client_secret: tfy-secret://my-org:mcp-secrets:oauth-client-secret
  jwt_source: access_token
  scopes:
    - read
    - write
  pkce: true
```

##### Dynamic Client Registration (Optional)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `registration_endpoint` | string | Yes | Registration URL |
| `initial_access_token` | string | No | `tfy-secret://` reference to registration token |

```yaml
dynamic_client_registration:
  registration_endpoint: https://auth.example.com/register
  initial_access_token: tfy-secret://my-org:mcp-secrets:registration-token
```

#### `passthrough` -- Forward TFY Credentials

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | string | Yes | `"passthrough"` |

```yaml
auth_data:
  type: passthrough
```

Forwards TrueFoundry user credentials to the downstream MCP server.

### TLS Settings (Optional)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `ca_cert` | string | No | `tfy-secret://` reference to CA certificate PEM |
| `insecure_skip_verify` | boolean | No | Skip TLS verification (`false` recommended) |

```yaml
tls_settings:
  ca_cert: tfy-secret://my-org:mcp-secrets:ca-cert-pem
  insecure_skip_verify: false
```

### Full Remote Server Example

```yaml
name: my-remote-server
type: mcp-server/remote
description: Production analytics MCP server
url: https://analytics.example.com/mcp
transport: streamable-http
auth_data:
  type: header
  headers:
    Authorization: "Bearer tfy-secret://my-org:mcp-secrets:api-token"
tls_settings:
  ca_cert: tfy-secret://my-org:mcp-secrets:ca-cert-pem
  insecure_skip_verify: false
collaborators:
  - subject: user:jane@example.com
    role_id: admin
tags:
  - analytics
  - production
```

---

## Type 2: `mcp-server/openapi`

Wraps an OpenAPI specification as an MCP server. Operations in the spec become MCP tools (max 30 tools).

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Unique server name |
| `type` | string | Yes | `"mcp-server/openapi"` |
| `spec` | object | Yes | OpenAPI spec source (see Spec Options) |
| `auth_data` | object | No | Authentication config (same options as remote) |
| `description` | string | No | Human-readable description |
| `collaborators` | array | No | Access control entries |

### Spec Options

#### Remote Spec

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | string | Yes | `"remote"` |
| `url` | string | Yes | URL to the OpenAPI JSON/YAML spec |

```yaml
spec:
  type: remote
  url: https://internal-api.example.com/openapi.json
```

> **Security:** Remote specs are fetched at runtime and auto-converted into MCP tools. Only use trusted, verified spec URLs.

#### Inline Spec

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | string | Yes | `"inline"` |
| `content` | string | Yes | Full OpenAPI spec as a YAML or JSON string |

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
          summary: Check service health
          responses:
            "200":
              description: OK
```

Prefer `inline` for sensitive environments to eliminate runtime dependency on external endpoints.

### Full OpenAPI Server Example (Remote Spec)

```yaml
name: petstore-api
type: mcp-server/openapi
description: Petstore API exposed as MCP tools
spec:
  type: remote
  url: https://internal-api.example.com/openapi.json
collaborators:
  - subject: user:dev@example.com
    role_id: viewer
```

---

## Type 3: `mcp-server/virtual`

Composes multiple registered MCP servers into a single virtual server. Each sub-server can expose all or a filtered subset of its tools.

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Unique server name |
| `type` | string | Yes | `"mcp-server/virtual"` |
| `servers` | array | Yes | Array of sub-server references |
| `description` | string | No | Human-readable description |
| `collaborators` | array | No | Access control entries |

### Sub-Server Entry

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Name of an already-registered MCP server |
| `enabled_tools` | string[] | No | Subset of tools to expose. Omit to expose all tools. |

```yaml
servers:
  - name: code-analysis-server
    enabled_tools:
      - lint
      - format
      - analyze
  - name: deployment-server
    enabled_tools:
      - deploy
      - rollback
```

### Full Virtual Server Example

```yaml
name: dev-tools
type: mcp-server/virtual
description: Composite server combining code analysis and deployment tools
servers:
  - name: code-analysis-server
    enabled_tools:
      - lint
      - format
      - analyze
  - name: deployment-server
    enabled_tools:
      - deploy
      - rollback
collaborators:
  - subject: team:platform-eng
    role_id: viewer
```

---

## Generate and Validate Workflow

### 1. Write YAML manifest

Choose the appropriate type (`remote`, `openapi`, or `virtual`) and fill in all required fields per the schemas above.

### 2. Validate (dry run)

```bash
tfy apply -f mcp-server.yaml --dry-run --show-diff
```

### 3. Fix any errors

Common issues:
- Invalid `transport` value (must be `"streamable-http"` or `"sse"`)
- Missing `auth_data` fields for OAuth2 (requires `authorization_url`, `token_url`, `client_id`, `client_secret`)
- Raw credentials in `headers` instead of `tfy-secret://` references
- OpenAPI spec exceeds 30 tools limit
- Virtual server references a `name` that does not match any registered MCP server
- Inline spec has YAML syntax errors

### 4. Apply

```bash
tfy apply -f mcp-server.yaml
```

Or via direct API:

```bash
$TFY_API_SH PUT /api/svc/v1/apps "$(cat mcp-server.yaml | yq -o json)"
```

---

## Checklist

- [ ] Server `name` is unique
- [ ] `type` is one of: `mcp-server/remote`, `mcp-server/openapi`, `mcp-server/virtual`
- [ ] **Remote:** `url` is set and reachable from the cluster
- [ ] **Remote:** `transport` is `"streamable-http"` or `"sse"`
- [ ] **Remote:** All credential values in `auth_data.headers` use `tfy-secret://` references
- [ ] **Remote:** OAuth2 includes all required fields (`authorization_url`, `token_url`, `client_id`, `client_secret`)
- [ ] **Remote:** TLS `ca_cert` uses a `tfy-secret://` reference if specified
- [ ] **OpenAPI:** `spec.type` is `"remote"` or `"inline"`
- [ ] **OpenAPI:** Remote spec URL is trusted and verified by the user
- [ ] **OpenAPI:** Spec produces at most 30 tools
- [ ] **Virtual:** All servers listed in `servers[].name` are already registered
- [ ] **Virtual:** `enabled_tools` lists only valid tool names from the referenced server
- [ ] Collaborators are set appropriately for access control
- [ ] Dry-run passes: `tfy apply -f manifest.yaml --dry-run --show-diff`
