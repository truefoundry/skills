---
name: truefoundry-platform
description: Platform access management for TrueFoundry. Covers connection status checks, workspace and cluster discovery, role and team management, secret groups, and personal access token lifecycle.
license: MIT
compatibility: Requires Bash, curl, and access to a TrueFoundry instance
allowed-tools: Bash(*/tfy-api.sh *) Bash(uv *) Bash(pip *) Bash(tfy*) Bash(curl*)
---

> Routing note: For ambiguous user intents, use the shared clarification templates in [references/intent-clarification.md](references/intent-clarification.md).

<objective>

# TrueFoundry Platform

Platform setup and access management: verify credentials, discover workspaces and clusters, manage roles/teams/collaborators, handle secret groups, and create personal access tokens.

## When to Use

- Verify TrueFoundry credentials and connectivity (preflight check)
- List clusters, workspaces, GPU types, or base domains
- Find workspace FQNs for deployment targets
- Invite users by email
- List or create roles, teams, or collaborators
- Manage secret groups and secret references (`tfy-secret://`)
- List and create personal access tokens (PATs) and virtual accounts (VATs)

## When NOT to Use

- Deploy services/apps -> requires TrueFoundry Enterprise with connected cluster
- Configure AI Gateway -> `gateway` skill
- Register MCP servers -> `mcp-servers` skill
- Check logs -> `observability` skill
- First-time signup/login -> `onboard` skill

</objective>

<context>

## Credential Surfaces

| Variable | Description | Example |
|----------|-------------|---------|
| `TFY_BASE_URL` | Platform URL | `https://your-org.truefoundry.cloud` |
| `TFY_HOST` | CLI host (set when `TFY_API_KEY` is set) | `https://your-org.truefoundry.cloud` |
| `TFY_API_KEY` | API key for REST calls | `tfy-...` |

</context>

<instructions>

## Status Check

Verify credentials and connectivity:

```bash
echo "TFY_BASE_URL: ${TFY_BASE_URL:-(not set)}"
echo "TFY_API_KEY: ${TFY_API_KEY:+(set)}${TFY_API_KEY:-(not set)}"

# Test connection
TFY_API_SH=~/.claude/skills/truefoundry-platform/scripts/tfy-api.sh
$TFY_API_SH GET '/api/svc/v1/workspaces?limit=1'
```

Present result as status summary. If login missing, use `truefoundry-onboard`.

## Workspaces

### Recommended Flow: Cluster -> Workspace

**Never auto-pick a workspace.** Always confirm with the user.

```bash
# Step 1: List clusters
$TFY_API_SH GET /api/svc/v1/clusters

# Step 2: List workspaces filtered by selected cluster
$TFY_API_SH GET '/api/svc/v1/workspaces?clusterId=SELECTED_CLUSTER_ID'
```

Present both as tables. Key field: `fqn` (needed for `TFY_WORKSPACE_FQN`).

If only one cluster exists, skip cluster selection and go to workspaces directly.

### GPU Types

```bash
$TFY_API_SH GET /api/svc/v1/clusters/CLUSTER_ID/get-addons
```

For full GPU type table and cluster base domain lookups, see [references/gpu-reference.md](references/gpu-reference.md) and [references/cluster-discovery.md](references/cluster-discovery.md).

## Access Control

Manage roles, teams, and collaborators. For full API calls, tool call syntax, presentation templates, common workflows, and subject format reference, see [references/access-control.md](references/access-control.md).

### Quick Reference

| Action | API Call |
|--------|---------|
| Invite user | `$TFY_API_SH POST /api/svc/v1/users/invite '{...}'` |
| List roles | `$TFY_API_SH GET /api/svc/v1/roles` |
| List teams | `$TFY_API_SH GET /api/svc/v1/teams` |
| List collaborators | `$TFY_API_SH GET '/api/svc/v1/collaborators?resourceType=TYPE&resourceId=ID'` |
| Create role | `$TFY_API_SH POST /api/svc/v1/roles '{...}'` |
| Create team | `$TFY_API_SH POST /api/svc/v1/teams '{...}'` |
| Add collaborator | `$TFY_API_SH POST /api/svc/v1/collaborators '{...}'` |

Subject format: `user:email`, `team:slug`, `serviceaccount:name`, `virtualaccount:name`.

> **Security:** Confirm subject, role, and resource with the user before granting access.

Destructive operations (delete roles, teams, collaborators): direct to dashboard.

### Invite Users

Use this for "invite new users by email" requests.

1. Collect email addresses.
2. Confirm target tenant.
3. Ask whether to only invite or also grant access to a resource.
4. If granting access, list roles/resources first and ask for explicit confirmation.

```bash
$TFY_API_SH POST /api/svc/v1/users/invite '{"emails":["alice@example.com"]}'
```

## Secrets

Manage secret groups and `tfy-secret://` references. Never ask user to paste secret values in chat.

### Quick Reference

| Action | API Call |
|--------|---------|
| List secret groups | `$TFY_API_SH GET /api/svc/v1/secret-groups` |
| Create secret group | `$TFY_API_SH POST /api/svc/v1/secret-groups '{...}'` |
| Update secrets | `$TFY_API_SH PUT '/api/svc/v1/secret-groups/ID' '{"secrets":[...]}'` |

Reference format: `tfy-secret://<tenant>:<group>:<key>`

> **Warning:** Update operations delete omitted keys. Always include all keys.

For full create/update flows, API patterns, and security policies, see [references/secrets-and-tokens.md](references/secrets-and-tokens.md).

## Access Tokens

List and create PATs and manage virtual accounts/VATs. Token values are shown only once at creation or retrieval/regeneration time.

| Action | API Call |
|--------|---------|
| List PATs | `$TFY_API_SH GET /api/svc/v1/personal-access-tokens` |
| Create PAT | `$TFY_API_SH POST /api/svc/v1/personal-access-tokens '{"name":"..."}'` |
| List virtual accounts | `$TFY_API_SH GET /api/svc/v1/virtual-accounts` |
| Create/update virtual account | `$TFY_API_SH POST /api/svc/v1/virtual-accounts '{...}'` |
| Get VAT token | `$TFY_API_SH GET /api/svc/v1/virtual-accounts/ID/token` |
| Regenerate VAT token | `$TFY_API_SH POST /api/svc/v1/virtual-accounts/ID/regenerate-token` |

> **Security:** Never repeat, store, or log token values. Show masked preview by default; full value only on explicit confirmation.

For full token display policy and security rules, see [references/secrets-and-tokens.md](references/secrets-and-tokens.md).

Deletion: direct to dashboard.

Service accounts: this skill can grant roles to existing service account subjects using `serviceaccount:name`. Do not claim service-account creation is supported until the create endpoint or dashboard flow is verified.

</instructions>

<success_criteria>

## Success Criteria

- Status check confirms connectivity or provides actionable next steps
- Workspaces presented in formatted table with FQNs
- Cluster/GPU discovery completed before offering resource options
- Access control operations confirmed before executing
- Secret groups listed without revealing values
- Token values shown only once at creation with masked preview default
- Destructive operations directed to dashboard

</success_criteria>

<troubleshooting>

## Error Handling

### 401 Unauthorized
API key invalid or expired. Generate new one: Dashboard -> Access -> API Keys.

### Connection Refused / Timeout
Check: URL correct (include https://), network/VPN connected, no trailing slash.

### CLI Host Missing
If tfy CLI says "TFY_HOST env must be set": `export TFY_HOST="${TFY_HOST:-${TFY_BASE_URL%/}}"`

### No Workspaces Found
Selected cluster may have no workspaces, or API key lacks access. Try different cluster.

### Permission Denied
Admin access may be required for access control and token operations.

### Invalid Subject Format
Use pattern `type:identifier` — e.g., `user:alice@company.com`, `team:platform-team`.

### Token Value Lost
Token values only shown at creation. Create a new token, update affected services, revoke old one in dashboard.

</troubleshooting>

<references>

## References

- [access-control.md](references/access-control.md) — Roles, teams, collaborators: full API calls, workflows, presentation
- [secrets-and-tokens.md](references/secrets-and-tokens.md) — Secret groups, PATs: create/update flows, security policies
- [cli-reference.md](references/cli-reference.md) — CLI commands and what doesn't exist
- [api-endpoints.md](references/api-endpoints.md) — Full REST API reference
- [cluster-discovery.md](references/cluster-discovery.md) — Base domains and cluster lookups
- [gpu-reference.md](references/gpu-reference.md) — GPU type table and SDK examples
- [prerequisites.md](references/prerequisites.md) — Credential reference and workspace FQN rules

## Composability

- **After status OK**: Use any other skill (gateway, mcp-servers, prompts, etc.)
- **AI Gateway auth**: PATs authenticate gateway requests (gateway skill)
- **Before deploy**: Set up teams and grant workspace access first
- **Dependency chain**: Create roles -> create teams -> add collaborators

</references>
