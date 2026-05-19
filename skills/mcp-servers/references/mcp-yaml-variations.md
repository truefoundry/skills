---
description: YAML examples for TrueFoundry MCP Gateway server types and auth variations observed from the live UI.
---

# MCP Gateway YAML Variations

Use these examples when generating or reviewing MCP Gateway manifests. Treat the live dashboard `Apply using YAML` preview as the final source of truth if it differs.

Security and trust policy: only use remote MCP URLs and OpenAPI spec URLs that the user explicitly confirms are trusted. Treat unknown remote URLs as untrusted, and do not run, import, or apply them without confirmation.

## Contents

- Remote MCP With No Auth
- Remote MCP With Shared API Key
- Remote MCP With Per-User API Key
- Remote MCP With OAuth2 Authorization Code
- Remote MCP With OAuth2 Client Credentials
- Remote MCP With Token Passthrough
- Virtual MCP With Selected Tools
- Virtual MCP Exposing All Tools From A Source
- OpenAPI MCP From Remote Spec
- Hosted STDIO Input Shape

## Remote MCP With No Auth

Auth disabled means omit `auth_data`.

```yaml
name: analytics-mcp
description: Analytics tools for internal workflows
url: https://analytics.example.com/mcp
collaborators:
  - subject: user:alice@example.com
    role_id: mcp-server-manager
type: mcp-server/remote
```

## Remote MCP With Shared API Key

Use shared API key auth when one credential is used for all callers.

```yaml
name: analytics-mcp
description: Analytics tools for internal workflows
url: https://analytics.example.com/mcp
collaborators:
  - subject: user:alice@example.com
    role_id: mcp-server-manager
type: mcp-server/remote
auth_data:
  type: header
  auth_level: global
  headers:
    Authorization: "Bearer tfy-secret://tenant:mcp-secrets:analytics-token"
```

## Remote MCP With Per-User API Key

Use per-user API key auth when each user supplies their own value.

```yaml
name: analytics-mcp
description: Analytics tools for internal workflows
url: https://analytics.example.com/mcp
collaborators:
  - subject: user:alice@example.com
    role_id: mcp-server-manager
type: mcp-server/remote
auth_data:
  type: header
  auth_level: per_user
  headers:
    Authorization: "Bearer {{API_KEY}}"
```

## Remote MCP With OAuth2 Authorization Code

Use authorization code for user-facing third-party sign-in.

```yaml
name: linear-mcp
description: Linear project management tools
url: https://mcp.linear.app/mcp
collaborators:
  - subject: user:alice@example.com
    role_id: mcp-server-manager
type: mcp-server/remote
auth_data:
  type: oauth2
  grant_type: authorization_code
  authorization_url: https://mcp.linear.app/authorize
  token_url: https://mcp.linear.app/token
  client_id: tfy-secret://tenant:mcp-secrets:linear-client-id
  client_secret: tfy-secret://tenant:mcp-secrets:linear-client-secret
  registration_url: https://mcp.linear.app/register
  jwt_source: access_token
```

## Remote MCP With OAuth2 Client Credentials

Use client credentials for server-to-server OAuth.

```yaml
name: service-mcp
description: Service-to-service MCP tools
url: https://service.example.com/mcp
collaborators:
  - subject: team:platform
    role_id: mcp-server-manager
type: mcp-server/remote
auth_data:
  type: oauth2
  grant_type: client_credentials
  token_url: https://auth.example.com/token
  client_id: tfy-secret://tenant:mcp-secrets:service-client-id
  client_secret: tfy-secret://tenant:mcp-secrets:service-client-secret
  jwt_source: access_token
```

## Remote MCP With Token Passthrough

Use passthrough when the downstream MCP server should receive the caller's existing TrueFoundry auth token.

```yaml
name: passthrough-mcp
description: MCP server using caller identity
url: https://service.example.com/mcp
collaborators:
  - subject: team:platform
    role_id: mcp-server-manager
type: mcp-server/remote
auth_data:
  type: passthrough
```

## Virtual MCP With Selected Tools

Use `enabled_tools` to expose a subset from each source server.

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

## Virtual MCP Exposing All Tools From A Source

Omit `enabled_tools` only for sources where every tool should be exposed.

```yaml
name: broad-dev-tools
description: Composite server exposing all DeepWiki tools and selected Linear tools
type: mcp-server/virtual
servers:
  - name: deepwiki
  - name: linear
    enabled_tools:
      - list_issues
      - create_issue
collaborators:
  - subject: team:platform
    role_id: mcp-server-manager
```

## OpenAPI MCP From Remote Spec

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

## Hosted STDIO Input Shape

Hosted STDIO creation starts from an `mcpServers` JSON config. Use the gateway YAML preview as the manifest source after import.

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

Do not leave real env secrets in the JSON when sharing it in chat or committing examples.
