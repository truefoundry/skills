---
name: truefoundry-platform
description: Platform setup and access management for TrueFoundry. Covers connection status checks, new account onboarding, workspace and cluster discovery, role and team management, and personal access token lifecycle.
license: MIT
compatibility: Requires Bash, curl, and access to a TrueFoundry instance
allowed-tools: Bash(*/tfy-api.sh *) Bash(uv *) Bash(pip *) Bash(tfy*) Bash(curl*)
---

> Routing note: For ambiguous user intents, use the shared clarification templates in [references/intent-clarification.md](references/intent-clarification.md).

<objective>

# TrueFoundry Platform

Platform setup and access management: verify credentials, onboard new users, discover workspaces and clusters, manage roles/teams/collaborators, and handle personal access tokens.

## When to Use

- Verify TrueFoundry credentials and connectivity (preflight check before any operation)
- Register a new TrueFoundry account or set up credentials for the first time
- User says "get started", "set up", "register", "onboard", or "I'm new to TrueFoundry"
- List clusters, workspaces, GPU types, or base domains
- Find workspace FQNs for deployment targets
- List, create, or delete roles, teams, or collaborators
- Manage permissions, organize users into teams, or grant/revoke access to resources
- List, create, or delete personal access tokens (PATs)

## When NOT to Use

- User wants to deploy services or apps --> deploying workloads requires a TrueFoundry Enterprise account with a connected cluster. Contact TrueFoundry (https://truefoundry.com) to get started
- User wants to see running apps --> use `applications` skill
- User wants to configure AI Gateway --> use `gateway` skill
- User wants to add guardrails --> use `gateway` skill (Guardrails section)
- User wants to register MCP servers --> use `tools` skill (MCP Servers section)
- User wants to manage secrets --> use `tools` skill (Secrets section)
- User wants to check logs --> use `observability` skill (Application Logs section)

</objective>

<context>

## Required Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `TFY_BASE_URL` | TrueFoundry platform URL | `https://your-org.truefoundry.cloud` |
| `TFY_HOST` | CLI host alias (recommended when `TFY_API_KEY` is set for CLI commands) | `https://your-org.truefoundry.cloud` |
| `TFY_API_KEY` | API key (raw, no Bearer prefix) | `tfy-...` |

</context>

<instructions>

## Status Check

Verify TrueFoundry credentials and connectivity before performing platform operations.

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

Set TFY_BASE_URL and TFY_API_KEY in your environment or .env file.
If you do not have a TrueFoundry account yet, see the Onboarding section below.
Get an API key: https://docs.truefoundry.com/docs/generating-truefoundry-api-keys
```

## Onboarding

Guide a new user from zero to a working TrueFoundry setup: account creation, credential configuration, and first successful API call.

### Step 1: Detect Current State

Before starting the registration flow, check if the user already has credentials configured.

```bash
echo "TFY_BASE_URL: ${TFY_BASE_URL:-(not set)}"
echo "TFY_HOST: ${TFY_HOST:-(not set)}"
echo "TFY_API_KEY: ${TFY_API_KEY:+(set)}${TFY_API_KEY:-(not set)}"
[ -f .env ] && grep -c '^TFY_' .env 2>/dev/null && echo ".env has TFY_ vars" || echo "No .env with TFY_ vars"
```

**If credentials are already set**, skip to [Step 5: Verify Connection](#step-5-verify-connection).

**If credentials are missing**, ask the user:

> Do you already have a TrueFoundry account? If yes, I'll help you configure credentials. If not, I'll walk you through creating one.

- **Has account** --> skip to [Step 3: Configure Credentials](#step-3-configure-credentials)
- **No account** --> continue to Step 2

### Step 2: Register a New Account

Run the TrueFoundry registration CLI:

```bash
tfy register
```

If `tfy` is not installed yet, use:

```bash
uv run --from truefoundry tfy register
```

> **IMPORTANT:** `tfy register` is fully interactive -- it requires terminal input. Let the user drive this step. Do not attempt to pipe or automate the prompts.

#### What the CLI does (4-step wizard)

1. **Choose account details** -- prompts for:
   - **Tenant name** (3-15 chars, lowercase alphanumeric + dashes, e.g., `acme-ai`)
   - **Work email** (company email recommended)
   - **Password** (min 8 characters, confirmed twice)
   - **Primary use case** -- "ai gateway" or "llm ops"

2. **Confirm terms** -- displays links to Privacy Policy and Terms of Service; requires acceptance

3. **Complete human verification if required** -- some registration servers may open a browser for CAPTCHA or similar anti-abuse checks; let the user complete that step manually

4. **Create account** -- the CLI calls the TrueFoundry registration service and retries individual fields on validation errors

5. **Email verification** -- user must check their inbox, click the verification link, then press Enter to continue

#### After registration

The CLI outputs:
- The **tenant URL** (e.g., `https://acme-ai.truefoundry.cloud`)
- Instructions to create a **Personal Access Token (PAT)**
- Optionally offers to install TrueFoundry agent skills

If the registration server is configured to require CAPTCHA, the CLI may also need a browser-based verification step before registration completes. Do not try to script or bypass that step.

Tell the user:

> Your TrueFoundry tenant is ready at `<tenant-url>`.
> Next, create your first API key:
> 1. Open `<tenant-url>` in your browser
> 2. Go to **Settings** --> **Access** --> **Personal Access Tokens** --> **Generate New Token**
> 3. Copy the token -- you'll need it in the next step
>
> See: https://docs.truefoundry.com/docs/generate-api-key

### Step 3: Configure Credentials

Once the user has their tenant URL and API key, set up the environment.

#### Option A: Environment Variables (recommended for development)

```bash
export TFY_BASE_URL="https://your-org.truefoundry.cloud"
export TFY_API_KEY="tfy-..."
export TFY_HOST="${TFY_BASE_URL}"
```

#### Option B: .env File (recommended for project-scoped config)

```bash
cat > .env << 'EOF'
TFY_BASE_URL=https://your-org.truefoundry.cloud
TFY_API_KEY=tfy-...
EOF
```

> **Security:** Never commit `.env` files with API keys to Git. Ensure `.env` is in `.gitignore`.

Ask the user which option they prefer, then help them set the values with their actual tenant URL and API key.

### Step 4: Install the CLI (Optional)

The CLI is recommended but not required -- all skills fall back to the REST API.

```bash
tfy --version 2>/dev/null || echo "CLI not installed"
```

If not installed:

```bash
pip install 'truefoundry==0.5.0'
```

If `TFY_API_KEY` is set and the user will use CLI commands, ensure `TFY_HOST` is also set:

```bash
export TFY_HOST="${TFY_HOST:-${TFY_BASE_URL%/}}"
```

### Step 5: Verify Connection

Test that credentials work with a lightweight API call. Set `TFY_API_SH` to the full path of this skill's `scripts/tfy-api.sh`. See `references/tfy-api-setup.md` for paths per agent.

```bash
~/.claude/skills/truefoundry-platform/scripts/tfy-api.sh GET '/api/svc/v1/workspaces?limit=1'
```

Present the result:

```
TrueFoundry Status:
- Base URL: https://your-org.truefoundry.cloud [OK]
- API Key: configured [OK]
- Connection: OK [OK]

You're all set!
```

If the connection fails, see [Troubleshooting](#error-handling).

### Step 6: What's Next?

After successful setup, guide the user based on what they want to do:

> You're connected to TrueFoundry! Here's what you can do next:
>
> **AI Gateway**
> - Configure LLM routing --> `gateway` skill
> - Add safety guardrails --> `gateway` skill (Guardrails section)
> - Register MCP servers --> `tools` skill (MCP Servers section)
>
> **Manage**
> - List workspaces --> see the Workspaces section below
> - Check logs --> `observability` skill (Application Logs section)
>
> **Deploy & Run** (requires TrueFoundry Enterprise with a connected cluster -- see https://truefoundry.com)
> - Deploy services, LLMs, jobs, and notebooks via the TrueFoundry dashboard or CLI
>
> What would you like to do?

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

##### Via Tool Call

```
tfy_roles_delete(id="ROLE_ID")
```

**Note:** Requires human approval (HITL) via tool call.

##### Via Direct API

```bash
$TFY_API_SH DELETE /api/svc/v1/roles/ROLE_ID
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

##### Via Tool Call

```
tfy_teams_delete(id="TEAM_ID")
```

**Note:** Requires human approval (HITL) via tool call.

##### Via Direct API

```bash
$TFY_API_SH DELETE /api/svc/v1/teams/TEAM_ID
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

##### Via Tool Call

```
tfy_teams_remove_member(team_id="TEAM_ID", subject="user:alice@company.com")
```

**Note:** Requires human approval (HITL) via tool call.

##### Via Direct API

```bash
$TFY_API_SH DELETE /api/svc/v1/teams/TEAM_ID/members/SUBJECT
# Example SUBJECT: user:alice@company.com
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

##### Via Tool Call

```
tfy_collaborators_delete(payload={"resourceType": "workspace", "resourceId": "RESOURCE_ID", "subject": "user:alice@company.com"})
```

**Note:** Requires human approval (HITL) via tool call.

##### Via Direct API

```bash
$TFY_API_SH DELETE /api/svc/v1/collaborators '{"resourceType":"workspace","resourceId":"RESOURCE_ID","subject":"user:alice@company.com"}'
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

## Access Tokens

Manage TrueFoundry personal access tokens (PATs). List, create, and delete tokens used for API authentication, CI/CD pipelines, and AI Gateway access.

> **Security Policy: Credential Handling**
> - The agent MUST NOT repeat, store, or log token values in its own responses.
> - After creating a token, direct the user to copy the value from the API response output above -- do not re-display it.
> - Never include token values in summaries, follow-up messages, or any other output.

### Preflight

Verify `TFY_BASE_URL` and `TFY_API_KEY` are set and valid using the Status Check section above before proceeding with token operations.

If the user does not have an account or PAT yet, do not continue with the token APIs. First have them run `uv run tfy register`, complete any browser-based CAPTCHA or human verification the CLI requests, verify their email, open the tenant URL returned by the CLI, and create their first PAT from the tenant dashboard.

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

Ask for confirmation before deleting -- this is irreversible and will break any integrations using the token.

#### Via Tool Call
```
tfy_access_tokens_delete(id="TOKEN_ID")
```

**Note:** Requires human approval (HITL) via tool call.

#### Via Direct API
```bash
# Delete a personal access token
$TFY_API_SH DELETE /api/svc/v1/personal-access-tokens/TOKEN_ID
```

</instructions>

<success_criteria>

## Status Check
- The user can confirm whether TFY_BASE_URL and TFY_API_KEY are correctly set
- The agent has tested the API connection with a lightweight call and reported the result
- The user can see a clear status summary showing which components are configured and which are missing
- The agent has provided actionable next steps if any credential or connectivity issue was found

## Onboarding
- The user has a TrueFoundry account (either pre-existing or newly created via `tfy register`)
- `TFY_BASE_URL` and `TFY_API_KEY` are configured (via env vars or `.env`)
- A test API call has confirmed connectivity
- The user knows what they can do next
- No credentials have been logged, echoed, or stored by the agent

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
- The user can create a team and add/remove members
- The user can list collaborators on any resource type
- The user can add a collaborator (user, team, or service account) to a resource with a specific role
- The user can remove a collaborator from a resource
- The agent has confirmed any create/delete operations before executing

## Access Tokens
- The user can list all personal access tokens in a formatted table
- The user can create a new token and receives a masked preview by default
- Full token reveal happens only on explicit confirmation and only once
- The user has been warned to save the token value immediately
- The user can delete a token after confirmation
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
TFY_BASE_URL and TFY_API_KEY are required.
Set them via environment variables or add to .env in project root.
If the user is new to TrueFoundry, have them follow the Onboarding section,
complete any browser-based CAPTCHA or human verification it requests, verify their email,
open the returned tenant URL, and create a PAT there.
```

### CLI Host Missing (`TFY_HOST` error)
```
If tfy CLI says: "TFY_HOST env must be set since TFY_API_KEY env is set"
run: export TFY_HOST="${TFY_HOST:-${TFY_BASE_URL%/}}"
```

### `tfy register` fails
```
If tfy CLI is not installed:
  uv run --from truefoundry tfy register
  # or: pip install 'truefoundry>=0.5.0' && tfy register

If registration service is unreachable:
  Check network connectivity to https://registration.truefoundry.com

If a field validation error occurs (e.g., tenant name taken, invalid email):
  The CLI will retry only the failed field -- follow the prompts.

If the CLI says CAPTCHA or human verification is required:
  Let it open the browser and complete the verification there.
  If the browser does not open automatically, copy the URL shown by the CLI into your browser.
```

### Email verification not received
```
Check spam/junk folder. Try registering again with the same email.
If the problem persists, contact support@truefoundry.com.
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

### Cannot Delete Built-in Role
```
Built-in roles cannot be deleted. Only custom roles can be removed.
```

### Token Not Found
```
Token ID not found. List tokens first to find the correct ID.
```

### Token Name Already Exists
```
A token with this name already exists. Use a different name.
```

### Deleted Token Still In Use
```
If services fail after token deletion, they were using the deleted token.
Create a new token and update the affected services/pipelines.
```

### Cannot Retrieve Token Value
```
Token values are only shown at creation time. If lost, delete the old token
and create a new one, then update all services that used the old token.
```

</troubleshooting>

<references>

## Composability

- **After status OK**: Use any other skill (`ai-gateway`, `guardrails`, `secrets`, `mcp-servers`, `logs`, etc.)
- **To set credentials**: Export env vars or create .env file
- **If using tool calls**: Use `tfy_config_set` to persist credentials
- **AI Gateway**: PATs are used to authenticate AI Gateway requests (`gateway` skill)
- **GitOps / CI/CD**: PATs are needed for automated deployments and CI/CD pipelines
- **Secrets**: Store PATs as secrets for deployments (`tools` skill (Secrets section))
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
