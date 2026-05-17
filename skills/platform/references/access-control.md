# Access Control

Manage roles, teams, and collaborators. Roles define permission sets, teams group users, collaborators grant access to resources.

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
