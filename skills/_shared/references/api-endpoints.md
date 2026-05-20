# TrueFoundry API Reference

Base URL: `$TFY_BASE_URL` (e.g. `https://your-org.truefoundry.cloud`)
Auth: `Authorization: Bearer $TFY_API_KEY`
Helper: `$TFY_API_SH <METHOD> <PATH> [JSON_BODY]`

> **Priority order:** CLI (`tfy apply/delete`) for writes → REST API for reads and writes when CLI is unavailable.

---

## Quick Lookups (One Call Answers)

| Question | Call |
|----------|------|
| What models/providers are attached? | `GET /api/svc/v1/provider-accounts` |
| What models can I call through the gateway? | `GET /api/llm/models` |
| What guardrails are configured? | `GET /api/svc/v1/gateway-guardrails-configs` |
| What secret groups exist? | `GET /api/svc/v1/secret-groups` |
| What workspaces do I have? | `GET /api/svc/v1/workspaces` |
| What teams exist? | `GET /api/svc/v1/teams` |
| What MCP servers are registered? | `GET /api/svc/v1/mcp-servers` |
| Show recent gateway requests | `POST /api/svc/v1/spans/query` (see Traces below) |
| What applications are deployed? | `GET /api/svc/v1/apps` |
| Is the gateway alive? | `GET /api/llm/health` |

---

## Gateway (LLM Proxy)

Base path: `/api/llm`

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/llm/models` | List all models the current token can access (OpenAI-compatible) |
| GET | `/api/llm/health` | Health check |
| POST | `/api/llm/chat/completions` | Chat completions (OpenAI-compatible) |
| POST | `/api/llm/completions` | Text completions |
| POST | `/api/llm/embeddings` | Embeddings |
| POST | `/api/llm/images/generations` | Image generation |
| POST | `/api/llm/images/edits` | Image editing |
| POST | `/api/llm/audio/transcriptions` | Speech-to-text |
| POST | `/api/llm/audio/translations` | Audio translation |
| POST | `/api/llm/audio/speech` | Text-to-speech |
| POST | `/api/llm/rerank` | Reranking |
| POST | `/api/llm/moderations` | Content moderation |
| POST | `/api/llm/batches` | Batch processing |
| POST | `/api/llm/responses` | Responses API (OpenAI format) |
| POST | `/api/llm/fine_tuning/jobs` | Fine-tuning |

### List Available Models

```bash
curl -s "${TFY_BASE_URL}/api/llm/models" \
  -H "Authorization: Bearer ${TFY_API_KEY}" | jq '.data[].id'
```

Response:
```json
{"object": "list", "data": [{"id": "openai-main/gpt-4o", "object": "model", "owned_by": "openai-main"}]}
```

### Chat Completion

```bash
curl -s "${TFY_BASE_URL}/api/llm/chat/completions" \
  -H "Authorization: Bearer ${TFY_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"model": "openai-main/gpt-4o", "messages": [{"role": "user", "content": "Hello"}], "max_tokens": 50}'
```

---

## Provider Accounts

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/svc/v1/provider-accounts` | List all provider accounts |
| POST | `/api/svc/v1/provider-accounts` | Create a provider account |
| GET | `/api/svc/v1/provider-integrations` | List model integrations (filterable) |

### List Provider Accounts (What Models Are Attached?)

```bash
$TFY_API_SH GET /api/svc/v1/provider-accounts
```

Response shape:
```json
{
  "data": [
    {
      "id": "pa-xxx",
      "name": "openai-main",
      "fqn": "tenant:openai:openai-main",
      "provider": "openai",
      "manifest": {"type": "provider-account/openai", "integrations": [...]},
      "integrations": [{"id": "...", "name": "gpt-4o", "type": "integration/model/openai"}]
    }
  ],
  "pagination": {"total": 1, "offset": 0, "limit": 50}
}
```

### List Model Integrations

```bash
$TFY_API_SH GET '/api/svc/v1/provider-integrations?type=model&limit=100'
```

Query params: `type` (model), `fqn`, `id`, `offset`, `limit`

### Create Provider Account

```bash
$TFY_API_SH POST /api/svc/v1/provider-accounts '{
  "manifest": {
    "name": "openai-main",
    "type": "provider-account/openai",
    "collaborators": [
      {"role_id": "provider-account-manager", "subject": "user:admin@example.com"},
      {"role_id": "provider-account-access", "subject": "team:everyone"}
    ],
    "integrations": [
      {
        "name": "gpt-4o",
        "type": "integration/model/openai",
        "model_types": ["chat"],
        "auth_data": {
          "type": "bearer-auth",
          "bearer_token": "tfy-secret://TENANT:SECRET_GROUP:OPENAI_API_KEY"
        }
      }
    ]
  }
}'
```

### Create via Apply API (Alternative)

```bash
curl -X PUT "${TFY_BASE_URL}/api/svc/v1/apply" \
  -H "Authorization: Bearer ${TFY_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"manifest": {...}, "dryRun": false}'
```

---

## Secrets

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/svc/v1/secret-groups` | List secret groups |
| GET | `/api/svc/v1/secret-groups/{id}` | Get secret group by ID |
| POST | `/api/svc/v1/secret-groups` | Create secret group |
| PUT | `/api/svc/v1/secret-groups/{id}` | Update secrets (omitted keys are deleted) |
| DELETE | `/api/svc/v1/secret-groups/{id}` | Delete secret group |
| POST | `/api/svc/v1/secrets` | List secrets in a group (body: secretGroupId) |
| GET | `/api/svc/v1/secrets/{id}` | Get secret value |
| DELETE | `/api/svc/v1/secrets/{id}` | Delete a secret |

### List Secret Groups

```bash
$TFY_API_SH GET /api/svc/v1/secret-groups
```

### Search by FQN

```bash
$TFY_API_SH GET '/api/svc/v1/secret-groups?fqn=tenant-name:secret-group-name'
```

### Create Secret Group

```bash
$TFY_API_SH POST /api/svc/v1/secret-groups '{
  "manifest": {
    "name": "my-secrets",
    "type": "secret-group",
    "integration_fqn": "internal:aws:aws-1:secret-store:internal-secret-store",
    "collaborators": [
      {"role_id": "secret-group-admin", "subject": "user:admin@example.com"}
    ]
  }
}'
```

### Add/Update Secrets in Group

```bash
$TFY_API_SH PUT '/api/svc/v1/secret-groups/SECRET_GROUP_ID' '{
  "secrets": [
    {"key": "OPENAI_API_KEY", "value": "sk-..."},
    {"key": "ANTHROPIC_API_KEY", "value": "sk-ant-..."}
  ]
}'
```

> **Warning:** Omitted keys are deleted. Always include all keys when updating.

---

## Guardrails

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/svc/v1/provider-accounts?type=guardrail-config-group` | List guardrail config groups |
| POST | `/api/svc/v1/provider-accounts` | Create guardrail config group |
| GET | `/api/svc/v1/gateway-guardrails-configs` | List gateway guardrails configs |
| POST | `/api/svc/v1/gateway-guardrails-configs` | Create gateway guardrails config |
| PUT | `/api/svc/v1/gateway-guardrails-configs/{id}` | Update gateway guardrails config |

### List Guardrail Configs

```bash
$TFY_API_SH GET /api/svc/v1/gateway-guardrails-configs
```

---

## Traces & Observability

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/svc/v1/spans/query` | Query gateway request traces |
| POST | `/api/svc/v1/llm-gateway/metrics/query` | Query model metrics (aggregated) |

### Query Recent Requests

```bash
$TFY_API_SH POST /api/svc/v1/spans/query '{
  "dataRoutingDestination": "default",
  "startTime": "2026-05-15T00:00:00.000Z",
  "limit": 20,
  "sortDirection": "desc"
}'
```

### Query with Filters

```bash
# Only LLM spans
$TFY_API_SH POST /api/svc/v1/spans/query '{
  "dataRoutingDestination": "default",
  "startTime": "2026-05-15T00:00:00.000Z",
  "filters": [{"spanAttributeKey": "tfy.span_type", "operator": "EQUAL", "value": "Model"}],
  "limit": 50,
  "sortDirection": "desc"
}'
```

Filter types:
- `{"spanFieldName": "statusCode", "operator": "EQUAL", "value": "ERROR"}`
- `{"spanAttributeKey": "tfy.model.name", "operator": "STRING_CONTAINS", "value": "gpt"}`
- `{"gatewayRequestMetadataKey": "project", "operator": "EQUAL", "value": "my-app"}`

Operators: `EQUAL`, `IN`, `NOT_IN`, `STRING_CONTAINS`, `STRING_STARTS_WITH`, `STRING_ENDS_WITH`, `GREATER_THAN`, `LESS_THAN`

### Query Model Metrics (Aggregated)

```bash
$TFY_API_SH POST /api/svc/v1/llm-gateway/metrics/query '{
  "startTs": "2026-05-15T00:00:00.000Z",
  "endTs": "2026-05-16T00:00:00.000Z",
  "datasource": "modelMetrics",
  "type": "distribution",
  "aggregations": [
    {"type": "count", "column": "costInUSD"},
    {"type": "sum", "column": "costInUSD"},
    {"type": "sum", "column": "inputTokens"},
    {"type": "sum", "column": "outputTokens"}
  ],
  "groupBy": ["modelName"]
}'
```

Available aggregation columns: `costInUSD`, `inputTokens`, `outputTokens`, `latencyMs`, `interTokenLatencyMs`, `timeToFirstTokenMs`, `timePerOutputTokenLatencyMs`

Aggregation types: `count`, `sum`, `p50`, `p75`, `p90`, `p99`

Group-by dimensions: `modelName`, `userEmail`, `virtualaccount`, `team`, `virtualModel`, `errorCode`, `requestType`, `providerAccountType`, `providerModelName`, `metadata.<key>`

---

## MCP Servers

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/svc/v1/mcp-servers` | List MCP servers |
| GET | `/api/svc/v1/mcp-servers/{id}` | Get MCP server by ID |
| POST | `/api/svc/v1/mcp-servers` | Register a new MCP server |
| DELETE | `/api/svc/v1/mcp-servers/{id}` | Delete an MCP server |

### List MCP Servers

```bash
$TFY_API_SH GET /api/svc/v1/mcp-servers
```

---

## Applications

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/svc/v1/apps` | List applications |
| GET | `/api/svc/v1/apps/{appId}` | Get application by ID |
| GET | `/api/svc/v1/apps/{appId}/deployments` | List deployments |
| PUT | `/api/svc/v1/apps` | Create/update application |

### List Applications

```bash
$TFY_API_SH GET '/api/svc/v1/apps?workspaceFqn=WORKSPACE_FQN'
```

---

## Workspaces

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/svc/v1/workspaces` | List workspaces |
| GET | `/api/svc/v1/workspaces/{id}` | Get workspace by ID |

### List Workspaces

```bash
$TFY_API_SH GET /api/svc/v1/workspaces
```

---

## Clusters

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/svc/v1/clusters` | List clusters |
| GET | `/api/svc/v1/clusters/{id}` | Get cluster |
| GET | `/api/svc/v1/clusters/{id}/is-connected` | Cluster connection status |

---

## Teams

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/svc/v1/teams` | List teams |
| POST | `/api/svc/v1/teams` | Create a team |
| GET | `/api/svc/v1/teams/{id}` | Get team |
| POST | `/api/svc/v1/teams/{id}/members` | Add member to team |
| DELETE | `/api/svc/v1/teams/{id}` | Delete team |

---

## Users

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/svc/v1/users` | List users |
| GET | `/api/svc/v1/users/{id}` | Get user |
| POST | `/api/svc/v1/users/invite` | Invite user |

Invite and access grants are separate: invite with `/users/invite`, then add collaborators to resources after confirming role/resource.

---

## Personal Access Tokens

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/svc/v1/personal-access-tokens` | List PATs |
| POST | `/api/svc/v1/personal-access-tokens` | Create PAT |
| DELETE | `/api/svc/v1/personal-access-tokens/{id}` | Delete PAT |

---

## Virtual Accounts (VATs)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/svc/v1/virtual-accounts` | List virtual accounts |
| POST | `/api/svc/v1/virtual-accounts` | Create/update virtual account |
| GET | `/api/svc/v1/virtual-accounts/{id}` | Get virtual account |
| GET | `/api/svc/v1/virtual-accounts/{id}/token` | Get VAT token |
| POST | `/api/svc/v1/virtual-accounts/{id}/regenerate-token` | Regenerate token |
| DELETE | `/api/svc/v1/virtual-accounts/{id}` | Delete virtual account |

Service accounts are valid collaborator subjects as `serviceaccount:name`, but this reference does not currently include a verified service-account creation endpoint.

---

## Agents

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/svc/v1/agents` | List agents |
| POST | `/api/svc/v1/agents` | Create/update agent |
| GET | `/api/svc/v1/agents/{id}` | Get agent |
| DELETE | `/api/svc/v1/agents/{id}` | Delete agent |

---

## Prompts

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/ml/v1/prompts` | List prompts |
| GET | `/api/ml/v1/prompts/{id}` | Get prompt |
| GET | `/api/ml/v1/prompt-versions` | List prompt versions |
| POST | `/api/ml/v1/prompts` | Create/update prompt |
| DELETE | `/api/ml/v1/prompts/{id}` | Delete prompt |

---

## Tracing Projects

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/ml/v1/tracing-projects` | List tracing projects |
| POST | `/api/ml/v1/tracing-projects` | Create tracing project |
| GET | `/api/ml/v1/tracing-projects/{id}` | Get tracing project |

---

## Jobs

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/svc/v1/jobs/trigger` | Trigger a job run |
| GET | `/api/svc/v1/jobs/{jobId}/runs` | List job runs |
| GET | `/api/svc/v1/jobs/{jobId}/runs/{runName}` | Get specific run |

---

## Logs

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/svc/v1/logs` | Get logs (query: applicationId, startTs, endTs) |

---

## Apply API (Unified Create/Update)

| Method | Path | Description |
|--------|------|-------------|
| PUT | `/api/svc/v1/apply` | Create or update any supported resource type |
| DELETE | `/api/svc/v1/apply` | Delete resources by manifest |

The Apply API accepts the same manifest format as `tfy apply` but via REST:

```bash
curl -X PUT "${TFY_BASE_URL}/api/svc/v1/apply" \
  -H "Authorization: Bearer ${TFY_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"manifest": {...}, "dryRun": false}'
```

---

## Collaborators (RBAC)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/svc/v1/collaborators` | List collaborators on a resource |
| POST | `/api/svc/v1/collaborators` | Add collaborator |
| DELETE | `/api/svc/v1/collaborators` | Remove collaborator |

---

## Roles

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/svc/v1/roles` | List roles (query: resourceType) |
| POST | `/api/svc/v1/roles` | Create role |

---

## Pagination

Most list endpoints support:
- `offset` (integer) — skip N results
- `limit` (integer) — max results per page

Response includes `pagination: {total, offset, limit}`.

For spans/query, pagination uses `pageToken` / `nextPageToken`.

---

## Error Codes

| Code | Meaning |
|------|---------|
| 400 | Invalid request body or parameters |
| 401 | Missing or invalid API key |
| 403 | Insufficient permissions (check role bindings) |
| 404 | Resource not found |
| 409 | Name conflict (resource already exists) |
| 422 | Validation error (e.g. invalid secret reference) |
| 429 | Rate limited |
| 500+ | Server error |

---

## Full API Docs

- Interactive reference: `https://truefoundry.com/docs/api-reference`
- OpenAPI spec: `https://truefoundry.com/openapi.json`
- Generating API keys: `https://docs.truefoundry.com/docs/generating-truefoundry-api-keys`
