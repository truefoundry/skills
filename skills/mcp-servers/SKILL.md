---
name: truefoundry-mcp-servers
description: Manages TrueFoundry MCP Gateway server registry entries. Covers listing, creating, updating, tool selection, access control, and client attachment for remote, official remote, virtual, hosted STDIO, and OpenAPI-backed MCP servers. Delete operations are manual dashboard-only.
license: MIT
compatibility: Requires Bash, curl, tfy CLI, and access to a TrueFoundry tenant
allowed-tools: Bash(*/tfy-api.sh *) Bash(tfy*) Bash(curl*) Bash(python*)
---

<objective>

# MCP Servers

Manage MCP servers in TrueFoundry AI Gateway.

Use this skill when the user wants to:

- List registered MCP servers.
- Connect any remote MCP server by URL.
- Connect an official remote MCP server from the gateway catalog.
- Create a virtual MCP server from selected tools across multiple MCP servers.
- Create a hosted STDIO MCP server from an `mcpServers` JSON config.
- Import an OpenAPI spec as an MCP server.
- Enable or disable tools on normal remote/OpenAPI servers or virtual server source entries.
- Update MCP server auth, access, metadata, endpoint/spec, or selected tools.
- Add an MCP server to clients such as Cursor, VS Code, Claude Code, Python, TypeScript, Windsurf, or Codex.

Do not manage raw secrets here. Use `tfy-secret://...` references or route secret creation to the `platform` skill.

Do not delete MCP servers from the agent. If deletion is requested, direct the user to the TrueFoundry dashboard.

</objective>

<instructions>

## Preflight

1. Verify `tfy login` is complete. If not, use `truefoundry-onboard`.
2. Verify the target tenant from `TFY_BASE_URL`/`TFY_HOST`.
3. Confirm the workspace or registry scope with the user before applying changes.
4. Use `mcp-server-manager` as the default role when granting MCP server management access unless the user requests another role.
5. Use `tfy-secret://...` references for shared credentials whenever possible; never inline real credentials in chat.

Before every final `tfy apply`, always show:

- Plain-English summary of the change.
- Target tenant and workspace/scope.
- Full YAML or diff.
- Exact command to be run.

Then ask for explicit confirmation. Run only the dry-run before confirmation.

## List MCP Servers

Use the platform UI when available. For API fallback:

```bash
TFY_API_SH=~/.claude/skills/truefoundry-mcp-servers/scripts/tfy-api.sh
$TFY_API_SH GET /api/svc/v1/mcp-servers
```

Present:

```text
MCP Servers
| Name | Type | Auth | ID | URL / Source |
```

## Connect Any Remote MCP Server

Use this for an already deployed HTTP MCP endpoint.

Required inputs:

- `name`
- `description`
- `url`
- collaborators: `user:<email>` or `team:<slug>` with role, default `mcp-server-manager`
- auth enabled or disabled

If auth is disabled, omit `auth_data`.

```yaml
name: analytics-mcp
description: Analytics tools for internal workflows
url: https://analytics.example.com/mcp
collaborators:
  - subject: user:alice@example.com
    role_id: mcp-server-manager
type: mcp-server/remote
```

### API Key Auth

Use this when the downstream MCP server expects static request headers.

Ask whether credentials are:

- Shared credentials: one key used by everyone; prefer a `tfy-secret://...` reference.
- Individual credentials: each user supplies their own key; use a placeholder such as `Bearer {{API_KEY}}`.

```yaml
auth_data:
  type: header
  auth_level: global
  headers:
    Authorization: "Bearer tfy-secret://tenant:mcp-secrets:analytics-token"
```

For individual credentials:

```yaml
auth_data:
  type: header
  auth_level: per_user
  headers:
    Authorization: "Bearer {{API_KEY}}"
```

### OAuth2 Auth

Use this when users or a server-to-server client should obtain temporary access tokens from an OAuth provider.

Authorization code is for user-facing sign-in:

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

Client credentials is for server-to-server auth:

```yaml
auth_data:
  type: oauth2
  grant_type: client_credentials
  token_url: https://auth.example.com/token
  client_id: tfy-secret://tenant:mcp-secrets:oauth-client-id
  client_secret: tfy-secret://tenant:mcp-secrets:oauth-client-secret
  jwt_source: access_token
```

Optional OAuth2 fields may include scopes, PKCE/code challenge methods, registration URL for Dynamic Client Registration, and additional token parameters. Use the gateway YAML preview or fetched config as the source of truth for exact optional field names.

### Token Passthrough

Use this when the downstream MCP server should receive the caller's existing TrueFoundry auth token.

```yaml
auth_data:
  type: passthrough
```

## Connect Official Remote MCP Server

Use this when the user wants a built-in catalog server such as GitHub, Linear, Sentry, Atlassian, Figma, Slack, Notion, Stripe, HuggingFace, or similar.

Flow:

1. Identify the official server from the gateway catalog.
2. Confirm the catalog auth mode: no auth, OAuth2, or header auth.
3. For OAuth2, prepare the server config and tell the user they may need to complete the browser authentication flow after creation.
4. For header auth, collect the header names and use secret references or per-user placeholders.
5. Confirm collaborators.
6. Generate YAML or use the UI's `Apply using YAML` output.
7. Dry-run, show diff, then apply only after explicit confirmation.

## Create Virtual MCP Server

Use this to expose selected tools from multiple existing MCP servers through one virtual MCP server.

Required inputs:

- virtual MCP `name`
- `description`
- source MCP servers to include
- tools to expose from each source server
- collaborators and roles
- optional source-server auth header override, if the gateway requires it

Flow:

1. List registered MCP servers.
2. Select multiple source MCP servers.
3. For each source server, enumerate available tools from the gateway UI/API.
4. Ask which tools to expose from each source.
5. Omit `enabled_tools` for a source server only when exposing all tools from that server.
6. Add collaborators with `mcp-server-manager` unless the user requests a different role.
7. Show a plain-English summary with virtual server name, source servers, selected tools, and access.
8. Show the full YAML.
9. Run `tfy apply -f mcp-server.yaml --dry-run --show-diff`.
10. Run the final apply only after explicit confirmation.

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

## Create Hosted STDIO MCP Server

Use this when the user has a local-style MCP config and wants the gateway to host/expose it.

Required input:

- JSON containing an `mcpServers` object.

Example input:

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

Flow:

1. Ask the user for the STDIO config or JSON file.
2. Replace raw environment secrets with secret references where the gateway supports it, or tell the user exactly which values must be moved to secrets.
3. Use the gateway import flow or YAML preview as the source of truth for the generated manifest.
4. Show summary, YAML/diff, dry-run, and confirmation-gated apply.

## Import From OpenAPI Spec

Use this to expose OpenAPI operations as MCP tools.

Required inputs:

- `name`
- `description`
- OpenAPI spec source: remote URL or pasted inline spec
- selected tools/operations
- collaborators
- optional auth using the same auth modes as remote MCP servers

For remote specs, confirm the URL is trusted before use.

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

## Enable Or Disable Tools

Tool filtering is supported for both normal MCP servers and virtual MCP servers.

### Normal Remote/OpenAPI Server

Use this when the user wants to enable or disable tools exposed by a single non-virtual MCP server.

Flow:

1. Fetch the current MCP server config by ID.
2. Inspect the returned config or UI YAML preview for the existing tool-selection fields.
3. Fetch or confirm the available tool names from the gateway UI/API.
4. Modify only the explicit tool-selection fields requested by the user.
5. Preserve name, URL/spec, auth, collaborators, TLS, tags, and unrelated settings.
6. Show the before/after tool list or YAML diff.
7. Dry-run and apply only after explicit confirmation.

Do not invent field names for normal-server tool filtering. If the API response does not expose the tool-selection shape, direct the user to the dashboard MCP server edit screen or ask them to provide the `Apply using YAML` output.

### Virtual Server

Use `servers[].enabled_tools` for each source server. Omit `enabled_tools` only when exposing every tool from that source.

## Update Auth

Use update-by-manifest:

1. Fetch the current MCP server config.
2. Preserve name, URL/spec, selected tools, collaborators, TLS, tags, and unrelated settings.
3. Replace only the `auth_data` block requested by the user.
4. Use secret references for shared credentials.
5. Show the old auth mode and new auth mode.
6. Show YAML/diff, dry-run, and apply only after explicit confirmation.

## Access Control

Collaborators are part of MCP server creation and update.

Use subject formats:

- `user:<email>`
- `team:<slug>`
- `serviceaccount:<name>`
- `virtualaccount:<name>`

Default role for examples is `mcp-server-manager`.

To list access:

```bash
$TFY_API_SH GET '/api/svc/v1/collaborators?resourceType=mcp-server&resourceId=RESOURCE_ID'
```

Adding collaborators is allowed with confirmation. Removing collaborators is dashboard-only.

## Add To Client

The gateway UI can generate client setup snippets for:

- Cursor
- VS Code
- Claude Code
- Python
- TypeScript
- Windsurf
- Codex

Use the `Add to Client` UI or the generated snippet from the dashboard. Do not click, reveal, paste, or print API keys unless the user explicitly asks to reveal them and understands the exposure.

## Apply

Always run the dry-run first:

```bash
tfy apply -f mcp-server.yaml --dry-run --show-diff
```

Run the final apply only after explicit user confirmation:

```bash
tfy apply -f mcp-server.yaml
```

## Delete

Do not call DELETE APIs or `tfy` delete flows. Tell the user:

```text
To delete this MCP server, open the TrueFoundry dashboard, go to AI Gateway -> MCP Servers, select the server, and delete it from the UI.
```

</instructions>

<success_criteria>

- The user can list MCP servers.
- The user can create remote, official remote, virtual, OpenAPI, and hosted STDIO-backed MCP servers.
- Auth-disabled, API key, OAuth2, and token-passthrough configurations match the live gateway YAML shape.
- The user can enable or disable tools while preserving unrelated server config.
- The user can update auth and access control through reviewed full-manifest changes.
- Client attachment guidance covers Cursor, VS Code, Claude Code, Python, TypeScript, Windsurf, and Codex.
- Shared credentials use `tfy-secret://...` references or explicit user placeholders, never hidden raw secrets.
- Final `tfy apply` is gated by a summary, YAML/diff, exact command, and explicit confirmation.
- Deletes and collaborator removals are dashboard-only.

</success_criteria>
