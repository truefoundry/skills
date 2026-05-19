---
description: UI navigation notes for TrueFoundry MCP Gateway server creation, editing, client attachment, and access control.
---

# MCP Gateway UI Flows

Use this reference when operating or documenting the MCP Gateway dashboard. It captures observed UI paths from `AI Gateway -> MCP Gateway`.

## Server List

The MCP Gateway page shows server cards with:

- server name
- description
- type, such as `Remote` or `Virtual`
- auth mode, such as `No Auth`, `OAuth2`, `Header Auth`, or `Chained`
- primary action, such as `Add to Client` or `Authenticate`

The small action button on each card opens:

- `Edit`
- `Access Control`
- `Delete`

Do not use `Delete` from an agent. Delete remains dashboard-only manual work.

## Add Server Chooser

Click `Add Server` to open `Add new MCP Server`.

Observed creation options:

- `Connect Official Remote MCP Servers`
- `Connect any Remote MCP Server`
- `Create a Virtual MCP Server`
- `Create a Hosted STDIO-based MCP Server`
- `Import from OpenAPI Spec`

## Connect Any Remote MCP Server

Path: `Add Server` -> `Connect any Remote MCP Server`.

Base fields:

- `Name`
- `Description`
- `URL`
- `Collaborators`
- optional `Auth Data`
- `Show advanced fields`
- `Apply using YAML`
- `Add MCP Server`

Default collaborator observed:

- subject: current user
- displayed role: `MCP Server Manager`
- YAML role id: `mcp-server-manager`

Use `Apply using YAML` to inspect the manifest before creating or updating. Do not click `Add MCP Server` until the user has explicitly approved the final apply/create action.

## Remote MCP Auth Controls

`Auth Data` is optional. Toggle it on to choose:

- `API Key`
- `OAuth2`
- `Token Passthrough`

### API Key

API key mode is for static headers.

Configuration options:

- `Shared Credentials`: one key used by everyone.
- `Individual Credentials`: each user provides their own key.
- `Headers`: one or more header key/value pairs.

For shared credentials, prefer `tfy-secret://...` references. For individual credentials, use placeholders such as `Bearer {{API_KEY}}`.

### OAuth2

OAuth2 mode is for temporary access tokens from a third-party login or server-to-server auth.

Grant types:

- `Authorization Code`: user-facing sign-in flow.
- `Client Credentials`: server-to-server flow with shared client credentials.

Authorization Code fields observed:

- `Authorization URL`
- `Token URL`
- `Client ID`
- `Client Secret`
- `Registration URL (Used for Dynamic Client Registration)`
- `Code Challenge Methods Supported`
- `JWT Source`
- `Scopes`
- `Additional Token Parameters`

Client Credentials fields observed:

- `Token URL`
- `Client ID`
- `Client Secret`
- `JWT Source`
- `Scopes`
- `Additional Token Parameters`

### Token Passthrough

Token passthrough forwards the user's existing TrueFoundry auth token to the MCP server. No extra fields were shown.

## Create Virtual MCP Server

Path: `Add Server` -> `Create a Virtual MCP Server`.

Fields:

- `Name`
- `Description`
- `Collaborators`
- `Source MCP Servers`
- optional `Override authentication header`
- `Selected Tools`
- `Show advanced fields`
- `Apply using YAML`
- `Create Virtual MCP`

Observed behavior:

- Source servers can be selected from existing MCP servers.
- Tools can be selected from each source server.
- Edit screen can show available tools and `Enable All Tools`.
- Use `servers[].enabled_tools` in YAML for selected subsets.
- Omit `enabled_tools` only when exposing every tool from that source server.

## Create Hosted STDIO MCP Server

Path: `Add Server` -> `Create a Hosted STDIO-based MCP Server`.

Fields:

- `STDIO Configuration (JSON)`
- `Upload JSON file`
- `Import Manifest`

Input is a local-style `mcpServers` JSON object with `command`, `args`, and optional `env`.

Move real environment credentials to secret references or ask the user to manage them securely; do not preserve raw secrets in chat.

## Import From OpenAPI Spec

Path: `Add Server` -> `Import from OpenAPI Spec`.

Fields observed:

- `Import OpenAPI Spec`
- `Build via URL`
- `Paste Spec`
- `OpenAPI Spec URL`
- `Import Tools`
- `Continue to Next Step`

Use trusted spec URLs only. Prefer pasted/inline specs for sensitive private APIs.

## Add To Client

`Add to Client` opens a `How to use` modal.

Client tabs observed:

- Cursor
- VS Code
- Claude Code
- Python
- TypeScript
- Windsurf
- Codex

The modal includes:

- client config snippet
- `Copy`
- `Show API Key`

Do not click, reveal, print, or paste API keys unless the user explicitly asks and accepts exposure.

