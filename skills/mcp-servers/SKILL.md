---
name: truefoundry-mcp-servers
description: Manages TrueFoundry MCP server registry entries. Covers listing, creating, and updating remote, virtual, OpenAPI-backed, and hosted stdio MCP servers. Delete operations are manual dashboard-only.
license: MIT
compatibility: Requires Bash, curl, tfy CLI, and access to a TrueFoundry tenant
allowed-tools: Bash(*/tfy-api.sh *) Bash(tfy*) Bash(curl*) Bash(python*)
---

<objective>

# MCP Servers

Manage MCP servers in TrueFoundry AI Gateway.

Use this skill when the user wants to:

- List registered MCP servers.
- Add a remote MCP server.
- Add a virtual MCP server composed from existing servers.
- Add an OpenAPI-backed MCP server.
- Register a hosted stdio MCP server after it is exposed over HTTP.
- Update an existing MCP server by fetching its current config, editing it, and re-applying the full manifest.

Do not manage secrets here. Use the `platform` skill for secret groups and secret references.

Do not delete MCP servers from the agent. If deletion is requested, direct the user to the TrueFoundry dashboard.

</objective>

<instructions>

## Preflight

1. Verify `tfy login` is complete. If not, use `truefoundry-onboard`.
2. Verify the target tenant from `TFY_BASE_URL`/`TFY_HOST`.
3. Confirm the workspace or registry scope with the user before applying changes.
4. Use `tfy-secret://...` references for any auth material.

Before final `tfy apply`, always show:

- Plain-English summary of the change.
- Target tenant and workspace/scope.
- Full YAML or diff.
- Exact command to be run.

Then ask for explicit confirmation.

## List MCP Servers

Use the platform UI when available. For API fallback:

```bash
TFY_API_SH=~/.claude/skills/truefoundry-mcp-servers/scripts/tfy-api.sh
$TFY_API_SH GET /api/svc/v1/mcp-servers
```

Present:

```text
MCP Servers
| Name | Type | Transport | ID | URL |
```

## Add Remote MCP Server

Use this for an already deployed MCP-compatible HTTP endpoint.

Required inputs:

- Name
- URL
- Transport: `streamable-http` or `sse`
- Auth mode: `header`, `oauth2`, or `passthrough`
- Collaborators, if any

Manifest:

```yaml
name: my-remote-server
type: mcp-server/remote
description: Production analytics MCP server
url: https://analytics.example.com/mcp
transport: streamable-http
auth_data:
  type: header
  headers:
    Authorization: "Bearer tfy-secret://tenant:mcp-secrets:api-token"
collaborators:
  - subject: team:platform
    role_id: viewer
```

## Add Virtual MCP Server

Use this to expose selected tools from multiple existing MCP servers through one server.

Manifest:

```yaml
name: dev-tools
type: mcp-server/virtual
description: Composite server for development workflows
servers:
  - name: code-analysis-server
    enabled_tools:
      - lint
      - analyze
  - name: deployment-server
    enabled_tools:
      - deploy
collaborators:
  - subject: team:platform
    role_id: viewer
```

## Add OpenAPI MCP Server

Use this to expose an OpenAPI spec as MCP tools. Remote spec URLs must be confirmed by the user as trusted before use.

Manifest:

```yaml
name: internal-api
type: mcp-server/openapi
description: Internal API exposed as MCP tools
spec:
  type: remote
  url: https://internal.example.com/openapi.json
collaborators:
  - subject: team:platform
    role_id: viewer
```

For sensitive APIs, prefer inline specs:

```yaml
spec:
  type: inline
  content: |
    openapi: "3.0.0"
    info:
      title: Internal API
      version: "1.0"
    paths: {}
```

## Hosted Stdio MCP Server

Stdio MCP servers cannot be registered directly. First expose them over HTTP using `mcp-proxy` or an equivalent wrapper, deploy that HTTP service, then register it as `mcp-server/remote`.

## Edit Existing MCP Server

Use update-by-manifest:

1. Fetch the current MCP server config.
2. Convert it into the corresponding manifest shape.
3. Modify only the requested fields.
4. Preserve collaborators, auth settings, and existing server/tool lists unless the user asked to change them.
5. Show the diff and get confirmation.
6. Apply the full updated manifest.

Do not patch blindly from memory.

## Apply

```bash
tfy apply -f mcp-server.yaml --dry-run --show-diff
tfy apply -f mcp-server.yaml
```

Run the final apply only after explicit user confirmation.

## Delete

Do not call DELETE APIs or `tfy` delete flows. Tell the user:

```text
To delete this MCP server, open the TrueFoundry dashboard, go to AI Gateway -> MCP Servers, select the server, and delete it from the UI.
```

</instructions>

<success_criteria>

- The user can list MCP servers.
- The user can add remote, virtual, OpenAPI, or hosted stdio-backed MCP servers.
- The user can update an existing MCP server through a reviewed full-manifest apply.
- Secrets are referenced with `tfy-secret://...`, never embedded.
- Final `tfy apply` is gated by a summary, YAML/diff, exact command, and explicit confirmation.
- Deletes are dashboard-only.

</success_criteria>
