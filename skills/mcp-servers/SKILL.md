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

- List MCP servers attached to a gateway.
- Connect remote or official remote MCP servers.
- Create virtual MCP servers from tools across multiple source servers.
- Create hosted STDIO MCP servers from `mcpServers` JSON.
- Import OpenAPI specs as MCP servers.
- Enable or disable tools.
- Update auth, access, metadata, endpoint/spec, or selected tools.
- Add MCP servers to clients such as Cursor, VS Code, Claude Code, Python, TypeScript, Windsurf, or Codex.

Do not delete MCP servers or remove collaborators from the agent. Route those requests to the TrueFoundry dashboard.

</objective>

<instructions>

## Reference Map

Load only the reference needed for the user's task:

| Task | Reference |
|------|-----------|
| Browser/UI operation, click paths, form fields, add-to-client modal | [references/mcp-gateway-ui-flows.md](references/mcp-gateway-ui-flows.md) |
| YAML examples for auth modes, server types, virtual tool selection, OpenAPI, hosted STDIO | [references/mcp-yaml-variations.md](references/mcp-yaml-variations.md) |

Treat the live dashboard `Apply using YAML` preview as the source of truth when it differs from examples.

## Safety Rules

- Verify `tfy login` is complete. If not, use `truefoundry-onboard`.
- Verify the target tenant from `TFY_BASE_URL`/`TFY_HOST`.
- Confirm the workspace or registry scope with the user before applying changes.
- Use `mcp-server-manager` as the default role unless the user requests another role.
- Use collaborator subjects as `user:<email>`, `team:<slug>`, `serviceaccount:<name>`, or `virtualaccount:<name>`.
- Use `tfy-secret://...` references for shared credentials whenever possible.
- Never print, paste, or reveal real credentials unless the user explicitly asks and accepts exposure.
- Do not call DELETE APIs, destructive CLI commands, or collaborator-removal flows.

Before every final `tfy apply`, show:

- Plain-English summary of the change.
- Target tenant and workspace/scope.
- Full YAML or diff.
- Exact command to be run.

Then ask for explicit confirmation. Run only dry-runs before confirmation.

## List MCP Servers

Prefer the dashboard when the user is working in the UI. For API fallback:

```bash
TFY_API_SH=~/.claude/skills/truefoundry-mcp-servers/scripts/tfy-api.sh
$TFY_API_SH GET /api/svc/v1/mcp-servers
```

Present servers as:

```text
MCP Servers
| Name | Type | Auth | ID | URL / Source |
```

## Connect Remote MCP Server

Use this for an existing HTTP MCP endpoint.

Collect:

- `name`
- `description`
- `url`
- collaborators and roles
- auth enabled or disabled
- if auth is enabled: API key/header, OAuth2, or token passthrough

Auth rules:

- No auth: omit `auth_data`.
- API key/header auth: support shared credentials and individual credentials; require at least one header.
- OAuth2: support authorization code and client credentials; include optional scopes, PKCE/code challenge methods, Dynamic Client Registration URL, and additional token params only when supplied or shown by the UI preview.
- Token passthrough: use the caller's existing TrueFoundry token; no extra fields are needed.

Use [references/mcp-yaml-variations.md](references/mcp-yaml-variations.md) for concrete YAML shapes.

## Connect Official Remote MCP Server

Use this for catalog servers such as GitHub, Linear, Sentry, Atlassian, Figma, Slack, Notion, Stripe, HuggingFace, or similar.

Flow:

1. Identify the official server in the gateway catalog.
2. Confirm the catalog auth mode.
3. For OAuth2, tell the user they may need to complete a browser authentication flow after creation.
4. For header auth, collect header names and use secret references or per-user placeholders.
5. Confirm collaborators.
6. Generate YAML from the UI preview or the YAML reference.
7. Dry-run, show diff, then apply only after confirmation.

## Create Virtual MCP Server

Use this to expose selected tools from multiple existing MCP servers through one virtual MCP server.

Collect:

- virtual MCP `name`
- `description`
- source MCP servers
- tools to expose from each source server
- collaborators and roles
- optional source-server auth header override if the gateway requires it

Flow:

1. List registered MCP servers.
2. Select source MCP servers.
3. Enumerate available tools for each source server.
4. Ask which tools to expose from each source.
5. Use `servers[].enabled_tools` for selected subsets.
6. Omit `enabled_tools` for a source only when exposing every tool from that source.
7. Add collaborators with `mcp-server-manager` unless requested otherwise.
8. Show virtual server name, source servers, selected tools, and access.
9. Show YAML, dry-run, and apply only after confirmation.

Use [references/mcp-yaml-variations.md](references/mcp-yaml-variations.md) for virtual server YAML examples.

## Create Hosted STDIO MCP Server

Use this when the user has a local-style MCP config and wants the gateway to host/expose it.

Collect JSON containing an `mcpServers` object with server `command`, `args`, and optional `env`.

Flow:

1. Ask for the STDIO JSON or file.
2. Replace raw environment secrets with secret references where supported, or tell the user which values must be moved to secrets.
3. Use the gateway import flow or YAML preview as the source of truth for the manifest generated after import.
4. Show summary, YAML/diff, dry-run, and confirmation-gated apply.

Use [references/mcp-yaml-variations.md](references/mcp-yaml-variations.md) for the input shape.

## Import From OpenAPI Spec

Use this to expose OpenAPI operations as MCP tools.

Collect:

- `name`
- `description`
- OpenAPI spec source: trusted remote URL or pasted inline spec
- selected tools/operations
- collaborators
- optional auth using the same modes as remote MCP servers

For remote specs, confirm the URL is trusted before use. Prefer pasted/inline specs for sensitive private APIs.

## Enable Or Disable Tools

Tool filtering is supported for normal remote/OpenAPI servers and virtual MCP servers.

For normal remote/OpenAPI servers:

1. Fetch the current MCP server config by ID.
2. Inspect the API response or UI YAML preview for the existing tool-selection shape.
3. Fetch or confirm available tool names.
4. Modify only the requested tool-selection fields.
5. Preserve name, URL/spec, auth, collaborators, TLS, tags, and unrelated settings.
6. Show the before/after tool list or YAML diff.
7. Dry-run and apply only after confirmation.

Do not invent field names for normal-server tool filtering. If the API response does not expose the shape, use the dashboard edit screen or ask the user for the `Apply using YAML` output.

For virtual servers, use `servers[].enabled_tools`; omit it only when exposing every tool from that source.

## Update Auth

Use update-by-manifest:

1. Fetch the current MCP server config.
2. Preserve name, URL/spec, selected tools, collaborators, TLS, tags, and unrelated settings.
3. Replace only the requested `auth_data` block.
4. Use secret references for shared credentials.
5. Show old auth mode and new auth mode.
6. Show YAML/diff, dry-run, and apply only after confirmation.

Use [references/mcp-yaml-variations.md](references/mcp-yaml-variations.md) for auth examples.

## Access Control

Adding collaborators is allowed with confirmation. Removing collaborators is dashboard-only.

To list access:

```bash
$TFY_API_SH GET '/api/svc/v1/collaborators?resourceType=mcp-server&resourceId=RESOURCE_ID'
```

When changing access, show the before/after collaborator list and preserve unrelated server config.

## Add To Client

The gateway UI can generate setup snippets for Cursor, VS Code, Claude Code, Python, TypeScript, Windsurf, and Codex.

Use the dashboard `Add to Client` modal or the generated snippet. Do not click, reveal, paste, or print API keys unless the user explicitly asks and understands the exposure.

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
- Tool enable/disable updates preserve unrelated server config.
- Auth and access changes use reviewed full-manifest updates.
- Client attachment guidance covers Cursor, VS Code, Claude Code, Python, TypeScript, Windsurf, and Codex.
- Shared credentials use `tfy-secret://...` references or explicit placeholders.
- Final `tfy apply` is gated by summary, YAML/diff, exact command, and explicit confirmation.
- Deletes and collaborator removals are dashboard-only.

</success_criteria>
