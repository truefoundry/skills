---
name: truefoundry-agents
description: UI-first guide for TrueFoundry Agent Registry. Use when creating, publishing, sharing, editing, testing, or attaching MCP servers and skills to TrueFoundry Agents. Agent authoring is not API-driven.
license: MIT
compatibility: Requires browser access to the TrueFoundry dashboard
allowed-tools: Bash(tfy*)
---

<objective>

# Agents

Guide the user through the TrueFoundry Agent Registry UI.

Agent authoring and interaction are dashboard workflows. Do not try to create, publish, edit, invoke, or delete agents through the API.

Use this skill when the user wants to:

- Create a TrueFoundry Agent.
- Register or manage a Remote Agent.
- Edit an existing agent configuration.
- Publish a new agent version.
- Attach MCP servers to an agent.
- Attach skills from the Skills Registry.
- Manage agent collaborators.
- Test an agent in the Agent Playground.
- Find where to monitor an agent.

</objective>

<instructions>

## Preflight

1. Verify `tfy login` is complete. If not, use `truefoundry-onboard`.
2. Ask the user for the tenant URL if it is not already known.
3. Open the TrueFoundry dashboard and guide the user through the UI.

Do not ask for API keys for agent authoring.

## Create a TrueFoundry Agent

Direct the user to:

```text
TrueFoundry Dashboard -> Agent Registry -> Create New Agent -> Build Agent on TrueFoundry
```

In Agent Playground:

1. Select a model from AI Gateway.
2. Write the system instructions.
3. Add MCP servers from the MCP Servers selector if tools are needed.
4. Add skills from the Skills selector if reusable instructions are needed.
5. Test in the chat interface.
6. Click `Save Agent`.
7. Choose `Save New Agent` for a new agent or `Save New Version` to publish a new version of an existing agent.

## Edit an Existing Agent

Direct the user to:

```text
TrueFoundry Dashboard -> Agent Registry -> Manage
```

Editable fields include:

- Name
- Description
- Tags
- Collaborators
- Model
- System instructions
- MCP servers
- Attached skills

After edits, test in the playground and save a new version.

## Attach MCP Servers

In Agent Playground:

1. Click `+` next to MCP Servers.
2. Search or browse available MCP servers.
3. Select the needed tools.
4. Test the agent before saving.

If the MCP server does not exist yet, use `truefoundry-mcp-servers` first.

## Attach Skills

In Agent Playground:

1. Click `+` next to Skills.
2. Select a skill from the Skills Registry.
3. Choose the version to pin.
4. Decide whether to preload `SKILL.md`.
5. Test the agent before saving.

Use preload only for short, always-relevant skills. Leave it off for long or situational skills.

If the skill does not exist yet, use `truefoundry-skills-registry` first.

## Collaborators

Use the agent edit form to grant:

- Agent Manager: can edit/manage the agent.
- Agent Access: can use/invoke the agent.

For broader teams and roles, use `truefoundry-platform`.

## Remote Agents

For agents running outside TrueFoundry:

```text
TrueFoundry Dashboard -> Agent Registry -> Create New Agent -> Remote Agent
```

Collect:

- Agent name
- Description
- Runtime endpoint or integration details shown by the UI
- Collaborators
- Tags

Then guide the user through the UI form.

## Delete

Do not delete agents for the user. If deletion is requested, direct them to the dashboard:

```text
TrueFoundry Dashboard -> Agent Registry -> Manage -> delete from the UI
```

</instructions>

<success_criteria>

- The user knows the exact UI path for the agent task.
- The agent does not claim API-based agent authoring.
- Agent creation/editing/publishing happens through Agent Registry or Agent Playground.
- MCP servers and Skills Registry are routed to their own skills when needed.

</success_criteria>
