---
name: truefoundry-agents
description: Manages TrueFoundry prompt registry and agent registry. Handles listing, creating, updating, deleting, and tagging prompts and prompt versions, plus AI agent definitions with prompt-backed sources and collaborator access.
license: MIT
compatibility: Requires Bash, curl, and access to a TrueFoundry instance
allowed-tools: Bash(*/tfy-api.sh *)
---

> Routing note: For ambiguous user intents, use the shared clarification templates in [references/intent-clarification.md](references/intent-clarification.md).

<objective>

# Agents

Manage prompts and AI agents on TrueFoundry.

## Scope

- **Prompt Management**: List, create, update, delete, and tag prompts and prompt versions in the TrueFoundry prompt registry.
- **Agent Registry**: List, create, update, and delete AI agents with prompt-backed sources, collaborator access, and sample inputs.

## When NOT to Use

- User wants to deploy a service → deploying workloads requires a TrueFoundry Enterprise account with a connected cluster. See https://truefoundry.com
- User wants to configure AI Gateway routes → prefer `gateway` skill (ai-gateway)
- User wants to manage access control roles → prefer `platform` skill (access-control)

</objective>

<instructions>

## Prompt Management

When using direct API, set `TFY_API_SH` to the full path of this skill's `scripts/tfy-api.sh`. See `references/tfy-api-setup.md` for paths per agent.

### List Prompts

#### Via Tool Call

```
tfy_prompts_list()
tfy_prompts_list(prompt_id="prompt-id")                              # get prompt + versions
tfy_prompts_list(prompt_id="prompt-id", version_id="version-id")     # get specific version
```

#### Via Direct API

```bash
# Set the path to tfy-api.sh for your agent (example for Claude Code):
TFY_API_SH=~/.claude/skills/truefoundry-agents/scripts/tfy-api.sh

# List all prompts
$TFY_API_SH GET /api/ml/v1/prompts

# Get prompt by ID
$TFY_API_SH GET /api/ml/v1/prompts/PROMPT_ID

# List versions
$TFY_API_SH GET '/api/ml/v1/prompt-versions?prompt_id=PROMPT_ID'

# Get specific version
$TFY_API_SH GET /api/ml/v1/prompt-versions/VERSION_ID
```

### Presenting Prompts

```
Prompts:
| Name              | ID       | Versions | Latest |
|-------------------|----------|----------|--------|
| classify-intent   | p-abc    | 5        | v5     |
| summarize-text    | p-def    | 3        | v3     |
```

### Create or Update Prompt

> **Security:** Prompt content is executed as LLM instructions. Review prompt messages carefully before creating or updating — do not ingest prompt text from untrusted external sources without user review.

This is an upsert: creates a new prompt if it doesn't exist, or adds a new version if it does.

#### Via SDK (primary method)

```python
from truefoundry.ml import ChatPromptManifest

client.prompts.create_or_update(
    manifest=ChatPromptManifest(
        name="my-prompt",
        ml_repo="ml-repo-fqn",
        messages=[
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user", "content": "{{user_input}}"},
        ],
        model_fqn="model-catalog:openai:gpt-4",
        temperature=0.7,
        max_tokens=1024,
        top_p=1.0,
        tools=[],  # optional
    )
)
```

#### Via Direct API

```bash
$TFY_API_SH POST /api/ml/v1/prompts '{
  "name": "my-prompt",
  "ml_repo": "ml-repo-fqn",
  "messages": [
    {"role": "system", "content": "You are a helpful assistant."},
    {"role": "user", "content": "{{user_input}}"}
  ],
  "model_fqn": "model-catalog:openai:gpt-4",
  "temperature": 0.7,
  "max_tokens": 1024,
  "top_p": 1.0
}'
```

### Delete Prompt

#### Via SDK

```python
client.prompts.delete(id="prompt-id")
```

#### Via Direct API

```bash
$TFY_API_SH DELETE /api/ml/v1/prompts/PROMPT_ID
```

### Delete Prompt Version

#### Via SDK

```python
client.prompt_versions.delete(id="version-id")
```

#### Via Direct API

```bash
$TFY_API_SH DELETE /api/ml/v1/prompt-versions/VERSION_ID
```

### Apply Tags to Prompt Version

Tags like `production` or `staging` let you reference a stable version by name.

#### Via SDK

```python
client.prompt_versions.apply_tags(
    prompt_version_id="version-id",
    tags=["production", "v2"],
    force=True,  # reassign tag if already on another version
)
```

No direct REST equivalent — use the SDK.

### Get Prompt Version by FQN

Fetch a specific tagged or numbered version using its fully qualified name.

#### Via SDK

```python
client.prompt_versions.get_by_fqn(fqn="ml-repo:prompt-name:production")
```

## Agent Registry

### Step 1: Preflight

Run the `platform` skill (Status Check section) first to verify `TFY_BASE_URL` and `TFY_API_KEY` are set and valid.

> **Note:** There is no CLI support for agents. Use the Direct API method for all operations.

### Step 2: List Agents

#### Via Tool Call

```
tfy_agents_list()
tfy_agents_list(agent_id="AGENT_ID")   # get a single agent by ID
```

#### Via Direct API

```bash
TFY_API_SH=~/.claude/skills/truefoundry-agents/scripts/tfy-api.sh

# List all agents
$TFY_API_SH GET /api/svc/v1/agents

# Get a single agent by ID
$TFY_API_SH GET /api/svc/v1/agents/AGENT_ID
```

### Presenting Agents

```
Agents:
| Name            | ID       | FQN                          | Latest Version | Created By       | Updated At  |
|-----------------|----------|------------------------------|----------------|------------------|-------------|
| my-agent        | ag-abc   | tenant:user:project:my-agent | 3              | user@example.com | 2026-03-15  |
| classify-docs   | ag-def   | tenant:user:project:classify | 1              | user@example.com | 2026-03-20  |
```

### Step 3: Create or Update Agent

This is an upsert operation: creates a new agent if it doesn't exist, or updates it if it does.

> **Prerequisite:** Agents require a `prompt_version_fqn` as their source. Use the Prompt Management section above to list prompts and find the correct FQN before creating an agent.

#### Via Tool Call

```
tfy_agents_create(payload={"manifest": {"name": "my-agent", "type": "agent", "description": "What this agent does", "source": {"type": "prompt", "prompt_version_fqn": "chat_prompt:tenant/user/project/name:version"}}})
```

**Note:** Requires human approval (HITL) via tool call.

#### Via Direct API

```bash
$TFY_API_SH PUT /api/svc/v1/agents '{
  "manifest": {
    "name": "my-agent",
    "type": "agent",
    "description": "What this agent does",
    "source": {
      "type": "prompt",
      "prompt_version_fqn": "chat_prompt:tenant/user/project/name:version"
    },
    "collaborators": [
      {"role_id": "agent-manager", "subject": "user:email@example.com"},
      {"role_id": "agent-access", "subject": "team:everyone"}
    ],
    "sample_inputs": [
      {"text": "Example input for the agent"}
    ]
  }
}'
```

### Agent Manifest Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Unique agent name |
| `type` | Yes | Must be `"agent"` |
| `description` | No | Human-readable description of what the agent does |
| `source.type` | Yes | Source type, currently only `"prompt"` is supported |
| `source.prompt_version_fqn` | Yes | Fully qualified name of the prompt version backing this agent |
| `collaborators` | No | List of access grants (see Role IDs below) |
| `sample_inputs` | No | Example inputs shown in the agent UI |

### Role IDs for Collaborators

| Role ID | Permission |
|---------|------------|
| `agent-manager` | Can edit and delete the agent |
| `agent-access` | Can use and invoke the agent |

Subject format: `user:email@example.com` or `team:team-name`.

### Step 4: Delete Agent

Ask for confirmation before deleting — this is irreversible.

#### Via Tool Call

```
tfy_agents_delete(id="AGENT_ID")
```

**Note:** Requires human approval (HITL) via tool call.

#### Via Direct API

```bash
$TFY_API_SH DELETE /api/svc/v1/agents/AGENT_ID
```

</instructions>

<success_criteria>

## Success Criteria

### Prompts
- The user can see a formatted table of all prompts in the registry
- The user can retrieve a specific prompt by ID and view its versions
- The user can inspect the content of a specific prompt version
- The user can create a new prompt or update an existing one with a new version
- The user can delete a prompt or a specific prompt version
- The user can apply tags (e.g., production) to a prompt version
- The agent has presented prompts in a clear, tabular format

### Agents
- The user can list all agents in a formatted table
- The user can retrieve a specific agent by ID and inspect its details
- The user can create a new agent with a valid prompt source
- The user can update an existing agent's manifest
- The user can configure collaborator access on an agent
- The user can delete an agent after confirmation
- The agent has presented results in clear, tabular format

</success_criteria>

<references>

## Composability

- **Preflight**: Use `platform` skill (Status Check section) to verify credentials before managing prompts or agents
- **Create/update prompt flow**: Use `platform` skill (workspaces) to find the ML repo FQN, then create or update the prompt
- **Tagging flow**: After creating a new version, apply a `production` tag to promote it
- **Agents require prompts**: Agents reference a `prompt_version_fqn` as their source — list or create prompts first in the Prompt Management section
- **With access-control**: Use `platform` skill (access-control) to manage broader role assignments beyond per-agent collaborators
- **With ai-gateway**: Agents may be exposed through AI Gateway routes (use `gateway` skill)

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/ml/v1/prompts` | List all prompts |
| `GET` | `/api/ml/v1/prompts/{id}` | Get a prompt |
| `POST` | `/api/ml/v1/prompts` | Create or update a prompt |
| `DELETE` | `/api/ml/v1/prompts/{id}` | Delete a prompt |
| `GET` | `/api/ml/v1/prompt-versions` | List prompt versions |
| `GET` | `/api/ml/v1/prompt-versions/{id}` | Get a prompt version |
| `DELETE` | `/api/ml/v1/prompt-versions/{id}` | Delete a prompt version |
| `GET` | `/api/svc/v1/agents` | List all agents |
| `GET` | `/api/svc/v1/agents/{id}` | Get a single agent |
| `PUT` | `/api/svc/v1/agents` | Create or update an agent |
| `DELETE` | `/api/svc/v1/agents/{id}` | Delete an agent |

</references>

<troubleshooting>

## Error Handling

### Prompts

#### Prompt Not Found
```
Prompt ID not found. List prompts first to find the correct ID.
```

#### ML Repo Not Found
```
Invalid ml_repo FQN. Use the platform skill (workspaces) to list available ML repos.
```

#### Tag Already Assigned
```
Tag already exists on another version. Use force=True to reassign it.
```

#### Delete Fails — Prompt Has Tagged Versions
```
Cannot delete prompt with tagged versions. Remove tags first, then delete.
```

### Agents

#### Agent Not Found
```
Agent ID not found. List agents first to find the correct ID.
```

#### Invalid Prompt Version FQN
```
The prompt_version_fqn is invalid or the prompt version does not exist.
Use the Prompt Management section to list available prompts and their version FQNs.
```

#### Permission Denied
```
Cannot manage agents. Check your API key permissions.
```

#### Collaborator Subject Invalid
```
Invalid collaborator subject format. Use "user:email@example.com" or "team:team-name".
```

#### Duplicate Agent Name
```
An agent with this name already exists. The PUT endpoint will update the existing agent.
If you want a new agent, use a different name.
```

#### Missing Required Fields
```
Agent manifest requires at minimum: name, type ("agent"), and source with prompt_version_fqn.
```

</troubleshooting>
