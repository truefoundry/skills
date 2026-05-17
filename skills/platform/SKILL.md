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

Platform setup and access management: verify existing credentials, discover workspaces and clusters, manage roles/teams/collaborators, handle secret groups, and create personal access tokens.

## When to Use

- Verify TrueFoundry credentials and connectivity (preflight check before any operation)
- List clusters, workspaces, GPU types, or base domains
- Find workspace FQNs for deployment targets
- List or create roles, teams, or collaborators
- Manage permissions, organize users into teams, or grant access to resources
- List, create, or update secret groups and secret references
- List and create personal access tokens (PATs)

## When NOT to Use

- User wants to deploy services or apps --> deploying workloads requires a TrueFoundry Enterprise account with a connected cluster. Contact TrueFoundry (https://truefoundry.com) to get started
- User wants to see running apps --> use `applications` skill
- User wants to configure AI Gateway --> use `gateway` skill
- User wants to add guardrails --> use `gateway` skill (Guardrails section)
- User wants to register MCP servers --> use `mcp-servers` skill
- User wants to check logs --> use `observability` skill (Application Logs section)
- User needs first-time signup, tenant setup, or CLI login --> use `onboard` skill

</objective>

<context>

## Credential Surfaces

| Variable | Description | Example |
|----------|-------------|---------|
| `TFY_BASE_URL` | TrueFoundry platform URL | `https://your-org.truefoundry.cloud` |
| `TFY_HOST` | CLI host alias (recommended when `TFY_API_KEY` is set for CLI commands) | `https://your-org.truefoundry.cloud` |
| `TFY_API_KEY` | API key for direct REST helper calls (raw, no Bearer prefix) | `tfy-...` |

</context>

<instructions>

## Status Check

Verify TrueFoundry CLI login, tenant config, and connectivity before performing platform operations.

### Via Tool Call (if tfy-tool-server is configured)

If the TrueFoundry tool server is available, use this tool call:

```
tfy_config_status
```

This returns connection status, configured base URL, and whether an API key is set.

### Via Direct API

Check environment variables and test the connection. Set `TFY_API_SH` to the full path of this skill's `scripts/tfy-api.sh`. See `references/tfy-api-setup.md` for paths per agent.

```bash
# Check env vars are set
echo "TFY_BASE_URL: ${TFY_BASE_URL:-(not set)}"
echo "TFY_HOST: ${TFY_HOST:-(not set)}"
echo "TFY_API_KEY: ${TFY_API_KEY:+(set)}${TFY_API_KEY:-(not set)}"

# Test connection -- list workspaces (lightweight call). Use full path shown above.
# Example for Claude Code:
~/.claude/skills/truefoundry-platform/scripts/tfy-api.sh GET '/api/svc/v1/workspaces?limit=1'
```

### Via .env File

If env vars are not set, check for a `.env` file:

```bash
[ -f .env ] && echo ".env found" || echo "No .env file"
```

### Presenting Status

```
TrueFoundry Status:
- Base URL: https://your-org.truefoundry.cloud [OK]
- API Key: configured [OK]
- Connection: OK (listed 1 workspace)
```

Or if something is wrong:

```
TrueFoundry Status:
- Base URL: (not set) [MISSING]
- API Key: (not set) [MISSING]

Set TFY_BASE_URL in your environment or .env file. Set TFY_API_KEY only when direct API checks are needed.
If you need first-time setup, use the `truefoundry-onboard` skill.
```

## Workspaces

List TrueFoundry workspaces and clusters. Workspaces are the deploy targets; clusters are the underlying infrastructure.

### Execution Priority

For simple read/list operations, always use MCP tool calls first:
- `tfy_clusters_list`
- `tfy_workspaces_list`

If tool calls are unavailable because the MCP server is not configured, or a tool is missing, fall back automatically to direct API via `tfy-api.sh`.

When using direct API, set `TFY_API_SH` to the full path of this skill's `scripts/tfy-api.sh`. See `references/tfy-api-setup.md` for paths per agent.

### Recommended Flow: Cluster --> Workspace

**Never ask users to set `TFY_CLUSTER_ID` manually.** Instead, list clusters and let the user pick -- then filter workspaces by that cluster.

#### Step 1: List Clusters

```
# Via Tool Call
tfy_clusters_list()

# Via Direct API
$TFY_API_SH GET /api/svc/v1/clusters
```

Present as a table and ask the user to pick one:

```
Clusters:
| Name             | ID               | Connected |
|------------------|------------------|-----------|
| prod-cluster     | prod-cluster     | Yes       |
| dev-cluster      | dev-cluster      | Yes       |

Which cluster would you like to use?
```

#### Step 2: List Workspaces (Filtered by Cluster)

Once the user picks a cluster, list workspaces filtered to that cluster:

```
# Via Tool Call
tfy_workspaces_list(filters={"cluster_id": "selected-cluster-id"})

# Via Direct API
$TFY_API_SH GET '/api/svc/v1/workspaces?clusterId=SELECTED_CLUSTER_ID'
```

Present as a table and ask the user to pick one:

```
Workspaces in prod-cluster:
| Name       | FQN                        |
|------------|----------------------------|
| dev-ws     | prod-cluster:dev-ws        |
| staging-ws | prod-cluster:staging       |

Which workspace would you like to use?
```

**Key field**: `fqn` -- this is what `TFY_WORKSPACE_FQN` needs for deploy.

#### Shortcut: If Only One Cluster

If the user has access to only one cluster, skip the cluster selection step -- go straight to listing workspaces.

### List All Workspaces (Unfiltered)

```
# Via Tool Call
tfy_workspaces_list()

# Via Direct API
$TFY_API_SH GET /api/svc/v1/workspaces
```

### Get Specific Workspace

```bash
# Via Tool Call
tfy_workspaces_list(workspace_id="ws-id-here")

# Via API
$TFY_API_SH GET /api/svc/v1/workspaces/WORKSPACE_ID
```

### Get Cluster Details

```
# Via Tool Call
tfy_clusters_list(cluster_id="cluster-id")  # with status + addons

# Via Direct API
$TFY_API_SH GET /api/svc/v1/clusters/CLUSTER_ID
$TFY_API_SH GET /api/svc/v1/clusters/CLUSTER_ID/is-connected
$TFY_API_SH GET /api/svc/v1/clusters/CLUSTER_ID/get-addons
```

### Cluster Base Domains (for Public URLs)

When a user wants to expose a service publicly, you need the cluster's base domains to construct a valid hostname. Invalid hosts cause deploy failures. See `references/cluster-discovery.md` for how to look up base domains, extract cluster ID from workspace FQN, and construct public URLs.

### Available GPU Types

When a user needs GPU resources, discover what's available on the cluster before offering options.

**Option A: Check cluster addons/node pools**
```bash
$TFY_API_SH GET /api/svc/v1/clusters/CLUSTER_ID/get-addons
```

**Option B: The SDK/API error message tells you**

If you deploy with an unsupported GPU type, the error message lists all valid ones:
```
"None of the nodepools support A10G. Valid devices are [T4, A10_4GB, A10_8GB, A10_12GB, A10_24GB, H100_94GB]"
```

**Not all types are available on every cluster.** Always check before presenting options to the user.

For the full GPU type reference table and SDK usage examples, see `references/gpu-reference.md`.

## Access Control

Manage TrueFoundry roles, teams, and collaborators. Roles define permission sets, teams group users, and collaborators grant access to specific resources.

When using direct API, set `TFY_API_SH` to the full path of this skill's `scripts/tfy-api.sh`. See `references/tfy-api-setup.md` for paths per agent.

### Roles

Roles are named permission sets scoped to a resource type. Built-in roles vary by resource type (for example, `workspace-admin`, `workspace-member`).

#### List Roles

##### Via Tool Call

```
tfy_roles_list()
```

##### Via Direct API

```bash
# Set the path to tfy-api.sh for your agent (example for Claude Code):
TFY_API_SH=~/.claude/skills/truefoundry-platform/scripts/tfy-api.sh

# List all roles
$TFY_API_SH GET /api/svc/v1/roles
```

#### Presenting Roles

```
Roles:
| Name              | ID       | Resource Type | Permissions |
|-------------------|----------|---------------|-------------|
| workspace-admin   | role-abc | workspace     | 12          |
| workspace-member  | role-def | workspace     | 5           |
| custom-deployer   | role-ghi | workspace     | 3           |
```

#### Create Role

##### Via Tool Call

```
tfy_roles_create(payload={"name": "custom-deployer", "displayName": "Custom Deployer", "description": "Can deploy apps", "resourceType": "workspace", "permissions": ["deploy:create", "deploy:read"]})
```

**Note:** Requires human approval (HITL) via tool call.

##### Via Direct API

```bash
$TFY_API_SH POST /api/svc/v1/roles '{"name":"custom-deployer","displayName":"Custom Deployer","description":"Can deploy apps","resourceType":"workspace","permissions":["deploy:create","deploy:read"]}'
```

#### Delete Role

Do not delete roles from the agent. If deletion is requested, direct the user to the dashboard:

```text
To delete this role, open the TrueFoundry dashboard, go to Access Control -> Roles, select the role, and delete it from the UI.
```

### Teams

Teams group users for collective access management. Each team has a name, description, and members list.

#### List Teams

##### Via Tool Call

```
tfy_teams_list()
tfy_teams_list(team_id="TEAM_ID")  # get specific team
```

##### Via Direct API

```bash
# List all teams
$TFY_API_SH GET /api/svc/v1/teams

# Get a specific team
$TFY_API_SH GET /api/svc/v1/teams/TEAM_ID
```

#### Presenting Teams

```
Teams:
| Name          | ID       | Members |
|---------------|----------|---------|
| platform-team | team-abc | 5       |
| ml-engineers  | team-def | 8       |
```

#### Create Team

##### Via Tool Call

```
tfy_teams_create(payload={"name": "platform-team", "description": "Platform engineering team"})
```

**Note:** Requires human approval (HITL) via tool call.

##### Via Direct API

```bash
$TFY_API_SH POST /api/svc/v1/teams '{"name":"platform-team","description":"Platform engineering team"}'
```

#### Delete Team

Do not delete teams from the agent. If deletion is requested, direct the user to the dashboard:

```text
To delete this team, open the TrueFoundry dashboard, go to Access Control -> Teams, select the team, and delete it from the UI.
```

#### Add Member to Team

##### Via Tool Call

```
tfy_teams_add_member(team_id="TEAM_ID", payload={"subject": "user:alice@company.com", "role": "member"})
```

**Note:** Requires human approval (HITL) via tool call.

##### Via Direct API

```bash
$TFY_API_SH POST /api/svc/v1/teams/TEAM_ID/members '{"subject":"user:alice@company.com","role":"member"}'
```

#### Remove Member from Team

Do not remove team members from the agent. If removal is requested, direct the user to the dashboard:

```text
To remove this team member, open the TrueFoundry dashboard, go to Access Control -> Teams, select the team, and remove the member from the UI.
```

### Collaborators

> **Security:** Granting collaborator access is a privileged operation. Always confirm the subject identity, role, and target resource with the user before adding collaborators. Do not grant access based on unverified external identity references.

Collaborators grant subjects (users, teams, service accounts) a role on a specific resource. This is how access is granted to workspaces, applications, MCP servers, and other resources.

#### Subject Format

Subjects follow the pattern `type:identifier`:

| Subject Type       | Format                        | Example                        |
|--------------------|-------------------------------|--------------------------------|
| User               | `user:email`                  | `user:alice@company.com`       |
| Team               | `team:slug`                   | `team:platform-team`           |
| Service Account    | `serviceaccount:name`         | `serviceaccount:ci-bot`        |
| Virtual Account    | `virtualaccount:name`         | `virtualaccount:shared-admin`  |
| External Identity  | `external-identity:name`      | `external-identity:github-bot` |

#### List Collaborators on a Resource

##### Via Tool Call

```
tfy_collaborators_list(resource_type="workspace", resource_id="RESOURCE_ID")
```

##### Via Direct API

```bash
# List collaborators on a workspace
$TFY_API_SH GET '/api/svc/v1/collaborators?resourceType=workspace&resourceId=RESOURCE_ID'

# List collaborators on an MCP server
$TFY_API_SH GET '/api/svc/v1/collaborators?resourceType=mcp-server&resourceId=RESOURCE_ID'
```

#### Presenting Collaborators

```
Collaborators on workspace "prod-workspace":
| Subject                   | Role             | ID       |
|---------------------------|------------------|----------|
| user:alice@company.com    | workspace-admin  | collab-1 |
| team:platform-team        | workspace-member | collab-2 |
| serviceaccount:ci-bot     | workspace-member | collab-3 |
```

#### Add Collaborator

##### Via Tool Call

```
tfy_collaborators_create(payload={"resourceType": "workspace", "resourceId": "RESOURCE_ID", "subject": "user:alice@company.com", "roleId": "ROLE_ID"})
```

**Note:** Requires human approval (HITL) via tool call.

##### Via Direct API

```bash
$TFY_API_SH POST /api/svc/v1/collaborators '{"resourceType":"workspace","resourceId":"RESOURCE_ID","subject":"user:alice@company.com","roleId":"ROLE_ID"}'
```

#### Remove Collaborator

Do not remove collaborators from the agent. If removal is requested, direct the user to the dashboard:

```text
To remove this collaborator, open the TrueFoundry dashboard, go to the resource access settings, select the collaborator, and remove them from the UI.
```

### Common Access Control Workflows

#### Grant a User Access to a Workspace

1. List roles to find the appropriate role ID (e.g., `workspace-admin` or `workspace-member`)
2. Add the user as a collaborator on the workspace with that role

```bash
# 1. Find the role ID
$TFY_API_SH GET /api/svc/v1/roles

# 2. Add collaborator
$TFY_API_SH POST /api/svc/v1/collaborators '{"resourceType":"workspace","resourceId":"WORKSPACE_ID","subject":"user:alice@company.com","roleId":"ROLE_ID"}'
```

#### Create a Team and Grant Access

1. Create the team
2. Add members to the team
3. Add the team as a collaborator on the target resource

```bash
# 1. Create team
$TFY_API_SH POST /api/svc/v1/teams '{"name":"ml-engineers","description":"ML engineering team"}'

# 2. Add members (use team ID from response)
$TFY_API_SH POST /api/svc/v1/teams/TEAM_ID/members '{"subject":"user:alice@company.com","role":"member"}'

# 3. Grant team access to a workspace
$TFY_API_SH POST /api/svc/v1/collaborators '{"resourceType":"workspace","resourceId":"WORKSPACE_ID","subject":"team:ml-engineers","roleId":"ROLE_ID"}'
```

#### Audit Access on a Resource

List all collaborators to see who has access and with what role:

```bash
$TFY_API_SH GET '/api/svc/v1/collaborators?resourceType=workspace&resourceId=WORKSPACE_ID'
```

## Secrets

Manage TrueFoundry secret groups and secret references.

Use this section when the user wants to:

- List secret groups.
- Inspect which keys exist in a secret group without revealing values.
- Create a new secret group.
- Add or rotate secret values.
- Find the `tfy-secret://tenant:group:key` reference for use in manifests.

Never ask the user to paste raw secret values in chat. Ask them to set values in their shell or use the dashboard.

### List Secret Groups

```bash
TFY_API_SH=~/.claude/skills/truefoundry-platform/scripts/tfy-api.sh
$TFY_API_SH GET /api/svc/v1/secret-groups
```

Present:

```text
Secret Groups
| Name | ID | Keys | Updated |
```

Show key names only. Do not display secret values.

### Create Secret Group

Before creating, collect:

- Secret group name
- Secret store integration ID
- Key names
- Confirmation that values are available as environment variables or will be entered in the dashboard

Example API pattern:

```bash
payload=$(jq -n \
  --arg name "my-secrets" \
  --arg integration "INTEGRATION_ID" \
  --arg db_password "$DB_PASSWORD" \
  '{
    name: $name,
    integrationId: $integration,
    secrets: [{key: "DB_PASSWORD", value: $db_password}]
  }')
$TFY_API_SH POST /api/svc/v1/secret-groups "$payload"
```

### Update Secret Group

Secret group updates can remove omitted keys. Treat every update as sensitive:

1. Fetch the current group and key list.
2. Preserve every existing key unless the user explicitly says to remove it.
3. Ask the user to provide new values through environment variables or the dashboard.
4. Show the resulting key list without values.
5. Ask for explicit confirmation.

### Secret References

Use this format in manifests:

```text
tfy-secret://<tenant-name>:<secret-group-name>:<secret-key>
```

### Delete

Do not delete secret groups or individual secrets from the agent. If deletion is requested, direct the user to the TrueFoundry dashboard.

## Access Tokens

Manage TrueFoundry personal access tokens (PATs). List and create tokens used for API authentication, CI/CD pipelines, and AI Gateway access.

> **Security Policy: Credential Handling**
> - The agent MUST NOT repeat, store, or log token values in its own responses.
> - After creating a token, direct the user to copy the value from the API response output above -- do not re-display it.
> - Never include token values in summaries, follow-up messages, or any other output.

### Preflight

Verify existing credentials using the Status Check section before proceeding with token operations.

If the user does not have a tenant or CLI login yet, do not continue with token APIs. Use the `truefoundry-onboard` skill first.

When using direct API, set `TFY_API_SH` to the full path of this skill's `scripts/tfy-api.sh`. See `references/tfy-api-setup.md` for paths per agent.

### List Access Tokens

#### Via Tool Call
```
tfy_access_tokens_list()
```

#### Via Direct API
```bash
TFY_API_SH=~/.claude/skills/truefoundry-platform/scripts/tfy-api.sh

# List all personal access tokens
$TFY_API_SH GET /api/svc/v1/personal-access-tokens
```

Present results:
```
Personal Access Tokens:
| Name          | ID       | Created At  | Expires At  |
|---------------|----------|-------------|-------------|
| ci-pipeline   | pat-abc  | 2025-01-15  | 2025-07-15  |
| dev-local     | pat-def  | 2025-03-01  | Never       |
```

**Security:** Never display token values. They are only shown once at creation time.

### Create Access Token

Ask the user for a token name before creating.

#### Via Tool Call
```
tfy_access_tokens_create(payload={"name": "my-token"})
```

**Note:** Requires human approval (HITL) via tool call.

#### Via Direct API
```bash
# Create a new personal access token
$TFY_API_SH POST /api/svc/v1/personal-access-tokens '{"name":"my-token"}'
```

**IMPORTANT:** The token value is returned ONLY in the creation response.

> **Security: Token Display Policy**
> - Default to showing only a masked preview (for example: first 4 + last 4 characters).
> - Show the full token only after explicit user confirmation that they are ready to copy it now.
> - If a full token is shown, show it only once, in a minimal response, and never repeat it in summaries/follow-up messages.
> - The agent must NEVER store, log, or re-display the token value after the initial one-time reveal.
> - If the user asks to see the token again later, instruct them to create a new token.

Present the result:
```
Token created successfully!
Name: my-token
Token (masked): tfy_****...****

If user explicitly confirms they are ready to copy it:
One-time token: <full value from API response>

Save this token NOW -- it will not be shown again.
Store it in a password manager, CI/CD secret store, or TrueFoundry secret group.
Never commit tokens to Git or share them in plain text.
```

### Delete Access Token

Do not delete PATs from the agent. If deletion is requested, direct the user to the TrueFoundry dashboard.

</instructions>

<success_criteria>

## Status Check
- The user can confirm whether CLI login and TFY_BASE_URL/TFY_HOST are correctly set
- The agent has tested the API connection with a lightweight call and reported the result
- The user can see a clear status summary showing which components are configured and which are missing
- The agent has provided actionable next steps if any credential or connectivity issue was found

## Workspaces
- The user can see a formatted table of available workspaces with their FQNs
- The agent has identified the correct workspace FQN for the user's intended deployment target
- The user can see cluster connectivity status and available infrastructure
- The agent has discovered and presented available GPU types if the user needs GPU resources
- The user has the cluster base domain if they need to expose a service publicly

## Access Control
- The user can list all roles and see them in a formatted table
- The user can create a custom role with specific permissions
- The user can list all teams and their members
- The user can create a team and add members
- The user can list collaborators on any resource type
- The user can add a collaborator (user, team, or service account) to a resource with a specific role
- The agent directs destructive access-control changes to the dashboard
- The agent has confirmed any create operations before executing

## Access Tokens
- The user can list all personal access tokens in a formatted table
- The user can create a new token and receives a masked preview by default
- Full token reveal happens only on explicit confirmation and only once
- The user has been warned to save the token value immediately
- The agent directs token deletion to the dashboard
- The agent has never displayed existing token values -- only new tokens at creation time

</success_criteria>

<troubleshooting>

## Error Handling

### 401 Unauthorized
```
API key is invalid or expired. Generate a new one:
1. Open your tenant URL in browser
2. Go to Settings -> API Keys -> Generate New Key
3. Update TFY_API_KEY with the new value

See: https://docs.truefoundry.com/docs/generate-api-key
```

### Connection Refused / Timeout
```
Cannot reach TFY_BASE_URL. Check:
- URL is correct (include https://)
- Network/VPN is connected
- No trailing slash in the URL
```

### Missing Variables
```
TFY_BASE_URL is required for tenant-specific checks. TFY_API_KEY is required only for direct API checks.
Set them via environment variables or add them to .env in the project root when needed.
If the user needs first-time tenant setup or CLI login, use the `truefoundry-onboard` skill.
```

### CLI Host Missing (`TFY_HOST` error)
```
If tfy CLI says: "TFY_HOST env must be set since TFY_API_KEY env is set"
run: export TFY_HOST="${TFY_HOST:-${TFY_BASE_URL%/}}"
```

### `.env` not picked up
```
The .env file must be in the current working directory.
Variable names must match exactly: TFY_BASE_URL, TFY_API_KEY (no quotes around values).
The tfy-api.sh script handles .env parsing -- never use `source .env`.
```

### No Workspaces Found
```
No workspaces found. Check:
- The selected cluster may not have any workspaces
- Your API key may not have access to this cluster
- Try listing clusters first to pick a different one
```

### Permission Denied
```
Cannot perform operation. Check your API key permissions -- admin access may be required
for access control and token management operations.
```

### Role Not Found
```
Role ID not found. List roles first to find the correct ID.
```

### Team Not Found
```
Team ID not found. List teams first to find the correct ID.
```

### Collaborator Already Exists
```
Collaborator with this subject and role already exists on the resource. Use a different role or remove the existing collaborator first.
```

### Invalid Subject Format
```
Invalid subject format. Use the pattern "type:identifier" -- e.g., user:alice@company.com, team:platform-team, serviceaccount:ci-bot.
```

### Resource Not Found
```
Resource not found. Verify the resourceType and resourceId are correct. List the resources first to confirm.
```

### Built-in Role Cannot Be Changed
```
Built-in roles cannot be changed. Create a custom role when built-in permissions are not enough.
```

### Token Not Found
```
Token ID not found. List tokens first to find the correct ID.
```

### Token Name Already Exists
```
A token with this name already exists. Use a different name.
```

### Token Still In Use
```
If services depend on an old token, create a new token and update the affected services or pipelines before revoking the old one in the dashboard.
```

### Cannot Retrieve Token Value
```
Token values are only shown at creation time. If lost, create a new token, update all services that used the old token, then revoke the old token from the dashboard.
```

</troubleshooting>

<references>

## Composability

- **After status OK**: Use any other skill (`gateway`, `mcp-servers`, `prompts`, `skills-registry`, `observability`, etc.)
- **To set credentials**: Export env vars or create .env file
- **If using tool calls**: Use `tfy_config_set` to persist credentials
- **AI Gateway**: PATs are used to authenticate AI Gateway requests (`gateway` skill)
- **GitOps / CI/CD**: PATs are needed for automated deployments and CI/CD pipelines
- **Secrets**: Store PATs as secrets for deployments in this skill's Secrets section
- **Before deploy**: Set up teams and grant workspace access so team members can deploy
- **With MCP servers**: Manage MCP server collaborators and role assignments on registered servers
- **Dependency chain**: Create roles first, then create teams, then reference both when adding collaborators

## Related Documentation

- [Prerequisites](references/prerequisites.md) -- full credential reference
- [CLI Fallback](references/cli-fallback.md) -- how skills work without the CLI
- [API Endpoints](references/api-endpoints.md) -- full REST API reference
- [Cluster Discovery](references/cluster-discovery.md) -- base domains and cluster lookups
- [GPU Reference](references/gpu-reference.md) -- GPU type table and SDK examples
- [Generate API Key](https://docs.truefoundry.com/docs/generate-api-key)

</references>
