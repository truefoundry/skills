---
name: truefoundry-prompts
description: Manages TrueFoundry Prompt Registry. Covers listing, creating, updating, versioning, tagging, and using prompts through the AI Gateway. Agent authoring belongs to the agents skill.
license: MIT
compatibility: Requires Bash, curl, and access to a TrueFoundry tenant
allowed-tools: Bash(*/tfy-api.sh *) Bash(tfy*) Bash(curl*) Bash(python*)
---

<objective>

# Prompts

Manage prompts in the TrueFoundry Prompt Registry.

Use this skill when the user wants to:

- List prompts.
- Inspect prompt versions.
- Create a prompt.
- Update a prompt by creating a new version.
- Tag a prompt version, for example `production`.
- Get a prompt version FQN for Gateway usage.
- Generate code snippets or usage guidance for a prompt.

Do not create or edit agents here. Use `truefoundry-agents` for Agent Registry UI workflows.

</objective>

<instructions>

## Preflight

1. Verify `tfy login` is complete. If not, use `truefoundry-onboard`.
2. Confirm the target tenant.
3. Confirm the ML repository or prompt repository where the prompt should live.
4. For destructive actions, use dashboard-only guidance.

## UI Path

The predictable UI path is:

```text
TrueFoundry Dashboard -> AI Gateway -> Prompt Management / Prompt Registry
```

Use the UI when the user wants to visually create, compare, or test prompts.

## Capability Matrix

| User intent | Supported path | Notes |
|-------------|----------------|-------|
| List prompts | API or UI | Present prompt name, ID, latest version, and tags. |
| Inspect prompt versions | API, SDK, or UI | Include version ID/FQN and tags. |
| Create a prompt | SDK or UI | Review messages/settings before creation. |
| Update a prompt | SDK or UI | Treat as a new version; do not overwrite silently. |
| Tag a version | SDK or UI | Confirm before moving stable tags like `production`. |
| Get prompt FQN | SDK or UI | Use for Gateway and Agent references. |

## List Prompts

API fallback:

```bash
TFY_API_SH=~/.claude/skills/truefoundry-prompts/scripts/tfy-api.sh
$TFY_API_SH GET /api/ml/v1/prompts
```

Present:

```text
Prompts
| Name | ID | Versions | Latest | Tags |
```

## Create or Update Prompt

Creating a new prompt or adding a new version should be treated as a reviewed change.

Collect:

- Prompt name
- Repository / ML repo
- System and user messages
- Variables
- Model, if the prompt stores one
- Temperature / top-p / max tokens, if needed

Show the final prompt content and settings before creating or updating.

Review format before create/update:

```text
Prompt Change
| Field | Value |
|-------|-------|
| Name | my-prompt |
| Repository | ml-repo-fqn |
| Change | create prompt / create new version |
| Variables | user_input |
| Model | model-catalog:openai:gpt-4 |
| Tags | none / production |
```

Then show the messages in order:

```text
System:
...

User:
...
```

SDK shape:

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
    )
)
```

## Versioning and Tags

Prompt edits create versions. Use tags such as `production` or `staging` to provide stable references.

Before applying a tag, show the current tag target if known and ask for explicit confirmation when the tag is stable or production-facing.

SDK shape:

```python
client.prompt_versions.apply_tags(
    prompt_version_id="version-id",
    tags=["production"],
    force=True,
)
```

## Get Prompt Version FQN

Use the UI or SDK to retrieve the FQN:

```python
client.prompt_versions.get_by_fqn(fqn="ml-repo:prompt-name:production")
```

The FQN is used by Gateway prompt run flows and by TrueFoundry Agents.

## Delete

Do not delete prompts or prompt versions from the agent. If deletion is requested, direct the user to the Prompt Registry UI.

</instructions>

<success_criteria>

- The user can list and inspect prompts.
- Prompt create/update is reviewed before execution.
- Prompt version tags are explained and applied only with confirmation.
- Prompt version FQNs are surfaced clearly.
- Agent authoring is routed to `truefoundry-agents`.

</success_criteria>
