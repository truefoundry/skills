---
name: truefoundry-tools
description: Registers MCP servers, manages secrets, and fetches TrueFoundry documentation. Covers remote/virtual/OpenAPI MCP servers, secret groups with key-value pairs, and platform docs.
license: MIT
compatibility: Requires Bash, curl, and access to a TrueFoundry instance
allowed-tools: Bash(*/tfy-api.sh *) Bash(curl *)
---

> Routing note: For ambiguous user intents, use the shared clarification templates in [references/intent-clarification.md](references/intent-clarification.md).

<objective>

# Tools

Manage MCP servers, secrets, and TrueFoundry documentation.

## Scope

- **MCP Servers**: Register, list, or delete MCP server registrations — including remote endpoints, virtual (composite) servers, and OpenAPI-to-MCP wrappers.
- **Secrets**: List, create, update, or delete secret groups and individual key-value secrets on TrueFoundry.
- **Documentation**: Fetch up-to-date TrueFoundry documentation for features, API reference, deployment guides, or troubleshooting.

</objective>

<instructions>

## MCP Servers

> **Security Policy: Credential Handling**
> - All credentials (API tokens, OAuth secrets, TLS certificates) in manifests MUST use `tfy-secret://` references. The agent MUST NOT accept or embed raw credential values in manifests.
> - If the user provides raw credentials, instruct them to create a TrueFoundry secret first (see Secrets section below), then reference it with `tfy-secret://`.
> - The agent MUST NOT echo, log, or display raw credential values.

When using direct API, set `TFY_API_SH` to the full path of this skill's `scripts/tfy-api.sh`. See `references/tfy-api-setup.md` for paths per agent.

### List MCP Servers

#### Via Tool Call

```
tfy_mcp_servers_list()
tfy_mcp_servers_list(id="mcp-server-id")  # get specific server
```

#### Via Direct API

```bash
# Set the path to tfy-api.sh for your agent (example for Claude Code):
TFY_API_SH=~/.claude/skills/truefoundry-tools/scripts/tfy-api.sh

# List all MCP servers
$TFY_API_SH GET /api/svc/v1/mcp-servers

# Get a specific MCP server
$TFY_API_SH GET /api/svc/v1/mcp-servers/SERVER_ID
```

### Presenting MCP Servers

```
MCP Servers:
| Name              | Type              | Transport       | ID         |
|-------------------|-------------------|-----------------|------------|
| my-remote-server  | mcp-server/remote | streamable-http | mcp-abc123 |
| composite-server  | mcp-server/virtual| —               | mcp-def456 |
| petstore-api      | mcp-server/openapi| —               | mcp-ghi789 |
```

### Register MCP Server (Remote)

Connects to an existing MCP endpoint over streamable-http or SSE.

> **Security gates (required before registration):**
> 1. Confirm the URL owner/domain with the user.
> 2. Require explicit user confirmation before using any new external URL.
> 3. Use secret references for all auth material (`tfy-secret://...`), never raw tokens.
> 4. Avoid logging full auth headers, client secrets, or certificates.

#### Attach an Existing TrueFoundry Deployment

Use this flow when the user says "attach deployment to MCP gateway" or already has a deployed MCP-compatible service.

1. Confirm the deployment is healthy (`DEPLOY_SUCCESS`) and endpoint is reachable
2. Collect endpoint details:
   - URL (public or internal)
   - transport (`streamable-http` or `sse`)
   - auth mode (`header`, `oauth2`, or `passthrough`)
3. Register it as `type: mcp-server/remote`
4. Return server ID and name so users can reference it from guardrails/policies

Example internal URL pattern for service deployments:
`http://{service-name}.{namespace}.svc.cluster.local:{port}/mcp`

#### Manifest

```yaml
name: my-remote-server
type: mcp-server/remote
description: Production analytics MCP server
url: https://analytics.example.com/mcp
transport: streamable-http
# SECURITY: Use tfy-secret:// references instead of hardcoding tokens in manifests.
# Hardcoded tokens in YAML files risk exposure via Git history and CI logs.
auth_data:
  type: header
  headers:
    Authorization: "Bearer tfy-secret://my-org:mcp-secrets:api-token"
collaborators:
  - subject: user:jane@example.com
    role_id: admin
tags:
  - analytics
  - production
```

#### Auth Options

**Static header (use secret references — never hardcode tokens):**

```yaml
auth_data:
  type: header
  headers:
    Authorization: "Bearer tfy-secret://my-org:mcp-secrets:api-token"
```

**OAuth2:**

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
  dynamic_client_registration:
    registration_endpoint: https://auth.example.com/register
    initial_access_token: tfy-secret://my-org:mcp-secrets:registration-token
```

**Passthrough (forwards TFY credentials):**

```yaml
auth_data:
  type: passthrough
```

#### TLS Settings (optional)

```yaml
tls_settings:
  # Prefer storing certificate material in a secret reference, then injecting at runtime.
  # Avoid inlining full certificate PEM blocks in manifests shared via chat or git.
  ca_cert: tfy-secret://my-org:mcp-secrets:ca-cert-pem
  insecure_skip_verify: false
```

#### Via CLI

```bash
tfy apply -f mcp-server-remote.yaml
```

#### Via Direct API

```bash
$TFY_API_SH PUT /api/svc/v1/apps "$(cat mcp-server-remote.yaml | yq -o json)"
```

### Register MCP Server (Virtual)

Composes multiple registered MCP servers into a single virtual server. Each sub-server can expose all or a subset of its tools.

#### Manifest

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

#### Via CLI

```bash
tfy apply -f mcp-server-virtual.yaml
```

#### Via Direct API

```bash
$TFY_API_SH PUT /api/svc/v1/apps "$(cat mcp-server-virtual.yaml | yq -o json)"
```

### Register MCP Server (OpenAPI)

Wraps an OpenAPI specification as an MCP server. Supports up to 30 tools derived from API operations.

> **Security: Remote OpenAPI specs are fetched at runtime and auto-converted into MCP tools that control agent capabilities. Only use trusted, verified spec URLs. For sensitive environments, prefer `spec.type: inline` to eliminate the runtime dependency on external endpoints.**
>
> **Execution policy:** Do not fetch or register a new remote spec URL until the user explicitly confirms the source is trusted for tool generation.

#### Manifest (remote spec URL)

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

#### Manifest (inline spec)

```yaml
name: internal-api
type: mcp-server/openapi
description: Internal API with inline OpenAPI spec
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
collaborators: []
```

#### Via CLI

```bash
tfy apply -f mcp-server-openapi.yaml
```

#### Via Direct API

```bash
$TFY_API_SH PUT /api/svc/v1/apps "$(cat mcp-server-openapi.yaml | yq -o json)"
```

### Registering Stdio-Based MCP Servers

Stdio-based MCP servers (e.g., `npx @modelcontextprotocol/server-*`) communicate over stdin/stdout and cannot be registered directly. Convert them to HTTP first using `mcp-proxy` or a similar wrapper, then register the HTTP endpoint.

#### Step 1: Wrap with mcp-proxy

Create a Dockerfile that runs the stdio server behind an HTTP transport:

```dockerfile
FROM node:22-slim
RUN npm install -g @anthropic-ai/mcp-proxy @modelcontextprotocol/server-filesystem
EXPOSE 8080
CMD ["mcp-proxy", "--transport", "streamable-http", "--port", "8080", "--", \
     "npx", "@modelcontextprotocol/server-filesystem", "/data"]
```

#### Step 2: Deploy to your infrastructure

Build and deploy the container to any platform that exposes HTTP (your cloud, Kubernetes, etc.). Note the resulting URL.

#### Step 3: Register as remote MCP server

```yaml
name: filesystem-mcp
type: mcp-server/remote
description: Filesystem access via MCP (stdio wrapped with mcp-proxy)
url: "https://your-mcp-proxy-endpoint.example.com/mcp"
transport: streamable-http
collaborators:
  - subject: "team:engineering"
    role_id: admin
```

```bash
tfy apply -f mcp-server-stdio-wrapped.yaml
```

> **Note:** Any stdio MCP server can be wrapped this way — GitHub, Slack, filesystem, database servers, etc. The key is converting the transport from stdio to HTTP before registering with TrueFoundry.

### Delete MCP Server

#### Via Tool Call

```
tfy_mcp_servers_delete(id="SERVER_ID")
```

**Note:** Requires human approval (HITL) via tool call.

#### Via Direct API

```bash
$TFY_API_SH DELETE /api/svc/v1/mcp-servers/SERVER_ID
```

## Secrets

> **Security Policy: Credential Handling**
> - The agent MUST NOT accept, store, log, echo, or display raw secret values in any context.
> - Always instruct the user to set secret values as environment variables before running commands.
> - If the user provides a raw secret value directly in conversation, warn them and refuse to use it. Instruct them to set it as an env var instead.
> - When displaying secrets, show only "(set)" or the first 4 characters followed by "***".

### List Secret Groups

#### Via Tool Call

```
tfy_secrets_list()
tfy_secrets_list(secret_group_id="group-id")  # get group + secrets
tfy_secrets_list(secret_id="secret-id")        # get one secret
```

#### Via Direct API

```bash
TFY_API_SH=~/.claude/skills/truefoundry-tools/scripts/tfy-api.sh

# List all secret groups
$TFY_API_SH GET /api/svc/v1/secret-groups

# Get a specific group
$TFY_API_SH GET /api/svc/v1/secret-groups/GROUP_ID

# List secrets in a group
$TFY_API_SH POST /api/svc/v1/secrets '{"secretGroupId":"GROUP_ID","limit":100,"offset":0}'

# Get a specific secret
$TFY_API_SH GET /api/svc/v1/secrets/SECRET_ID
```

### Presenting Secrets

```
Secret Groups:
| Name          | ID       | Secrets |
|---------------|----------|---------|
| prod-secrets  | sg-abc   | 5       |
| dev-secrets   | sg-def   | 3       |
```

**Security:** Never display secret values in full. Show only the first few characters or indicate "(set)". The agent must NEVER log, echo, or output raw secret values in any context.

### Create Secret Group

> **Security: Credential Handling**
> - The agent must NEVER accept, echo, or transmit raw secret values inline.
> - Never ask the user to paste secret values in chat.
> - Always instruct the user to store secret values in environment variables first, then reference those variables.
> - If the user provides a raw secret value directly, warn them and suggest using an env var instead.

#### Via Tool Call

```
# Prompt user to set secret values as environment variables first
tfy_secret_groups_create(payload={"name": "my-secrets", ...})
```

**Note:** Requires human approval (HITL) via tool call.

#### Via Direct API

```bash
# SECURITY: Never hardcode secret values in commands — they will appear in shell
# history and process listings. Read from environment variables or files instead.
# User must set: export DB_PASSWORD="..." before running this command.
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

Updates secrets in a group. A new version is created for every secret with a modified value. Secrets omitted from the array are deleted. At least one secret is required.

#### Via Tool Call

```
# Instruct user to set env vars with new values, then reference them.
# The agent must NEVER accept raw secret values — always use indirection.
tfy_secret_groups_update(
  id="GROUP_ID",
  payload={"secrets": [{"key": "DB_PASSWORD", "value": "<secure-input-from-env>"}, {"key": "API_KEY", "value": "<secure-input-from-env>"}]}
)
```

**Note:** Requires human approval (HITL) via tool call.

#### Via Direct API

```bash
# SECURITY: Read secret values from environment variables, not inline.
payload=$(jq -n \
  --arg db_password "$DB_PASSWORD" \
  --arg api_key "$NEW_API_KEY" \
  '{
    secrets: [
      {key: "DB_PASSWORD", value: $db_password},
      {key: "API_KEY", value: $api_key}
    ]
  }')
$TFY_API_SH PUT /api/svc/v1/secret-groups/GROUP_ID "$payload"
```

### Delete Secret Group

#### Via Tool Call

```
tfy_secret_groups_delete(id="GROUP_ID")
```

**Note:** Requires human approval (HITL) via tool call.

#### Via Direct API

```bash
$TFY_API_SH DELETE /api/svc/v1/secret-groups/GROUP_ID
```

### Finding the Integration ID

Before creating a secret group, you need the secret store integration ID for the workspace's cloud provider:

#### Via Direct API

```bash
# List all secret store provider accounts and their integrations
bash $TFY_API_SH GET '/api/svc/v1/provider-accounts?type=secret-store'
```

From the response, look for integrations with `type: "secret-store"`. Each provider account contains an `integrations` array -- pick the integration matching the workspace's cloud provider:
- AWS: `integration/secret-store/aws/secrets-manager` or `integration/secret-store/aws/parameter-store`
- Azure: `integration/secret-store/azure/vault`
- GCP: `integration/secret-store/gcp/secret-manager`

Use the `id` field of the matching integration as the `integrationId` when creating secret groups.

### Using Secrets in Deployments

After creating a secret group, reference individual secrets in deployment manifests using the `tfy-secret://` format:

```
tfy-secret://<TENANT_NAME>:<SECRET_GROUP_NAME>:<SECRET_KEY>
```

- `TENANT_NAME`: The subdomain of `TFY_BASE_URL` (e.g., `my-org` from `https://my-org.truefoundry.cloud`)
- `SECRET_GROUP_NAME`: The name you gave the secret group when creating it
- `SECRET_KEY`: The key of the individual secret within the group

#### Example: Manifest with Secret References

Given a secret group named `my-app-secrets` with keys `DB_PASSWORD` and `API_KEY`:

```yaml
name: my-app
type: service
image:
  type: image
  image_uri: docker.io/myorg/my-app:latest
ports:
  - port: 8000
    expose: false
    app_protocol: http
resources:
  cpu_request: 0.5
  cpu_limit: 1
  memory_request: 512
  memory_limit: 1024
  ephemeral_storage_request: 1000
  ephemeral_storage_limit: 2000
env:
  LOG_LEVEL: info
  DB_PASSWORD: tfy-secret://my-org:my-app-secrets:DB_PASSWORD
  API_KEY: tfy-secret://my-org:my-app-secrets:API_KEY
workspace_fqn: cluster-id:workspace-name
```

#### Workflow: Secrets Before Deploy

1. Identify sensitive env vars (passwords, tokens, keys, credentials)
2. Find the secret store integration ID (see above)
3. Create a secret group with all sensitive values
4. Reference secrets in the manifest `env` using `tfy-secret://` format
5. Deploy with `tfy apply -f manifest.yaml`

### Delete Individual Secret

#### Via Tool Call

```
tfy_secrets_delete(id="SECRET_ID")
```

**Note:** Requires human approval (HITL) via tool call.

#### Via Direct API

```bash
$TFY_API_SH DELETE /api/svc/v1/secrets/SECRET_ID
```

## Documentation

### Documentation Sources

#### API Reference

Full API docs:
```
https://truefoundry.com/docs/api-reference
```

Fetch a specific section:
```bash
curl -s https://truefoundry.com/docs/api-reference/applications/list-applications
```

#### Deployment Guides

| Topic | URL |
|-------|-----|
| Introduction to Services | `https://truefoundry.com/docs/introduction-to-a-service` |
| Deploy First Service | `https://truefoundry.com/docs/deploy-first-service` |
| Dockerize Code | `https://truefoundry.com/docs/dockerize-code` |
| Ports and Domains | `https://truefoundry.com/docs/define-ports-and-domains` |
| Endpoint Auth | `https://truefoundry.com/docs/endpoint-authentication` |
| Resources (CPU/Memory) | `https://truefoundry.com/docs/resources-cpu-memory-storage` |
| Fractional GPUs | `https://truefoundry.com/docs/using-fractional-gpus` |
| Environment Variables | `https://truefoundry.com/docs/environment-variables-and-secrets` |
| Autoscaling | `https://truefoundry.com/docs/autoscaling-overview` |
| Liveness/Readiness Probes | `https://truefoundry.com/docs/liveness-readiness-probe` |
| Rollout Strategy | `https://truefoundry.com/docs/rollout-strategy` |
| Deploy Programmatically | `https://truefoundry.com/docs/deploy-service-programatically` |
| CI/CD Setup | `https://truefoundry.com/docs/setting-up-cicd-for-your-service` |
| Monitoring | `https://truefoundry.com/docs/monitor-your-service` |

#### Job Deployment

| Topic | URL |
|-------|-----|
| Introduction to Jobs | `https://truefoundry.com/docs/introduction-to-a-job` |
| Deploy First Job | `https://truefoundry.com/docs/deploy-first-job` |

#### ML & LLM

| Topic | URL |
|-------|-----|
| ML Repos | `https://truefoundry.com/docs/ml-repos` |
| LLM Deployment | `https://truefoundry.com/docs/llm-deployment` |
| LLM Tracing | `https://truefoundry.com/docs/llm-tracing` |

#### Authentication

| Topic | URL |
|-------|-----|
| Generating API Keys | `https://docs.truefoundry.com/docs/generating-truefoundry-api-keys` |

### Fetching Docs

To fetch a specific docs page for the user:

```bash
curl -sL "https://truefoundry.com/docs/deploy-first-service" | head -200
```

Or use WebFetch if available in the agent.

</instructions>

<success_criteria>

## Success Criteria

### MCP Servers
- The user can list all registered MCP servers in a formatted table
- The user can register a remote MCP server with the correct transport and auth configuration
- The user can register a virtual MCP server composing multiple sub-servers with tool filtering
- The user can register an OpenAPI-to-MCP server with a remote or inline spec
- The user can delete an MCP server registration
- The agent has confirmed any create/delete operations before executing
- Collaborators are correctly specified when provided

### Secrets
- The user can list all secret groups and see their contents in a formatted table
- The user can create a new secret group with a specified name
- The user can update secrets in a group (rotate values, add/remove keys)
- The user can delete a secret group or an individual secret
- The agent has never displayed full secret values — only masked or "(set)" indicators
- The user can inspect individual secrets within a group by ID
- The agent has confirmed any create/update/delete operations before executing

### Documentation
- The user has received the relevant documentation content or URL for their question
- The agent has fetched and summarized the specific docs page rather than just linking to it
- The user understands the next steps based on the documentation provided
- If the docs page was unavailable, the agent has suggested alternative resources or related skills

</success_criteria>

<references>

## Composability

- **Preflight**: Use `platform` skill (Status Check section) to verify credentials before managing MCP servers or secrets
- **Before registering MCP servers**: Deploy the MCP server to your infrastructure, then register it here. Set up teams/roles for collaborators (use `platform` skill for access-control)
- **After registering MCP servers**: Reference MCP servers in agent manifests, configure guardrails for MCP tools
- **Before deploy**: Create secret groups, then reference in deployment config using `tfy-secret://` format
- **With applications**: Reference secret groups in application env vars
- **For API usage**: Reference `references/api-endpoints.md` in _shared
- **For troubleshooting**: Fetch relevant docs page and summarize

</references>

<troubleshooting>

## Error Handling

### MCP Servers

#### MCP Server Not Found
```
MCP server ID not found. List servers first to find the correct ID.
```

#### Permission Denied (MCP)
```
Cannot access MCP servers. Check your API key permissions.
```

#### Server Already Exists
```
MCP server with this name already exists. Use a different name or delete the existing one first.
```

#### Unreachable Remote URL
```
Cannot reach the MCP server URL. Verify the URL is correct and accessible from the cluster.
```

#### OpenAPI Spec Too Large
```
OpenAPI spec exceeds 30 tools limit. Reduce the number of operations in the spec.
```

#### Invalid Transport
```
Invalid transport type. Use "streamable-http" or "sse".
```

#### OAuth2 Configuration Error
```
OAuth2 auth_data missing required fields. Ensure authorization_url, token_url, client_id, and client_secret are provided.
```

#### Virtual Server Reference Not Found
```
Referenced server name not found. Ensure all servers listed in the virtual server are already registered.
```

### Secrets

#### Secret Group Not Found
```
Secret group ID not found. List groups first to find the correct ID.
```

#### Permission Denied (Secrets)
```
Cannot access secrets. Check your API key permissions.
```

#### Secret Already Exists
```
Secret group with this name already exists. Use a different name.
```

#### At Least One Secret Required
```
Cannot update secret group with zero secrets. Include at least one secret in the payload.
```

#### No Secret Store Configured
```
No secret store configured for this workspace. Contact your platform admin.
```

#### Key Name Restrictions (Azure Key Vault)
```
Key name does not support underscores (_)
```
Azure Key Vault does not allow underscores in secret key names. Use hyphens (`DB-PASSWORD`) or choose a different secret store integration (AWS Secrets Manager supports underscores).

#### Azure Key Vault: Secret Stuck in Soft-Delete State
```
Error: Secret <name> is already in a deleted state / conflict with soft-deleted resource
```
Azure Key Vault has a default 90-day soft-delete retention. The TrueFoundry API cannot purge soft-deleted secrets — only the Azure portal or CLI can.

**Recovery options:**
1. **Purge via Azure Portal:** Go to Key Vault → Manage deleted secrets → Purge
2. **Purge via Azure CLI:** `az keyvault secret purge --vault-name <vault> --name <secret-name>`
3. **Use a different name:** Create a new secret group with a different name (fastest workaround)

> **Note:** If the platform's Key Vault has soft-delete protection but not purge protection, options 1/2 work. If purge protection is also enabled, you must wait out the retention period (up to 90 days).

#### Missing Required Fields (Secrets)
```
Unprocessable entity. Ensure all secrets have both "key" and "value" fields.
```

### Documentation

#### Documentation page returns 404
```
The URL may have changed. Try searching the docs index:
  curl -sL "https://truefoundry.com/docs" | head -100

Or check the sitemap for the current URL structure.
```

#### curl fails or times out
```
Check network connectivity:
  curl -sI https://truefoundry.com

If behind a proxy, ensure HTTP_PROXY / HTTPS_PROXY are set.
If curl is unavailable, use WebFetch or suggest the user open the URL in a browser.
```

#### Documentation content is truncated or unparseable
```
Some pages render dynamically. Try:
  - Increasing the head limit (e.g., head -500)
  - Using WebFetch if available in the agent
  - Providing the direct URL to the user to open in a browser
```

</troubleshooting>
