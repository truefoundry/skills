# TrueFoundry Skills

[![CI](https://github.com/truefoundry/skills/actions/workflows/ci.yml/badge.svg)](https://github.com/truefoundry/skills/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Official TrueFoundry plugin for AI coding agents. Unified repo for **Claude Code**, **Codex**, and **Cursor** — one install gives you onboarding, gateway configuration, MCP servers, prompts, agent guidance, skills registry workflows, codebase migration, and observability.

## Quick Start

Paste this into your coding agent:

> Read https://www.github.com/truefoundry/skills/install.md and follow the instructions to register with TrueFoundry.

For first-time setup, the agent should use the `truefoundry-onboard` skill. It checks CLI login, sends new users to https://www.truefoundry.com/register, asks them to return with their tenant URL, installs the TrueFoundry CLI if needed, and runs `tfy login --host <tenant-url>`.

Before any operational skill runs, the agent must verify that `tfy login` is already complete. If CLI login is missing, route the user back through `truefoundry-onboard`.

Onboarding stops after CLI login verification. Operational setup belongs to the other TrueFoundry skills.

### Install

<details>
<summary><strong>Claude Code (Plugin)</strong></summary>

Install from the plugin marketplace:

```
/plugin install truefoundry@truefoundry/skills
```

Or use the CLI:

```bash
claude plugin add truefoundry/skills
```

What you get:
- 9 skills (onboard, gateway, mcp-servers, platform, prompts, agents, skills-registry, observability, codebase-scanner)
- 2 specialized agents (gateway configurator, troubleshoot)
- 3 hooks (credential bootstrap, delete blocking, secret scanning)
- Slash commands: `/truefoundry:setup`, `/truefoundry:status`
- `userConfig` prompts for TFY_BASE_URL on install

</details>

<details>
<summary><strong>Codex (Plugin)</strong></summary>

Add the marketplace and install:

```bash
codex plugin marketplace add truefoundry/skills
codex plugin install truefoundry
```

What you get:
- 9 skills loaded automatically
- Same hooks as Claude Code (credential bootstrap, delete blocking, secret scanning)

</details>

<details>
<summary><strong>Cursor (Plugin)</strong></summary>

Install from the Cursor marketplace (once listed):

```
/add-plugin truefoundry/skills
```

Or install locally for testing:

```bash
git clone https://github.com/truefoundry/skills.git ~/.cursor/plugins/local/truefoundry
```

What you get:
- 9 skills as agent context
- Cursor rules (`.mdc`) for LLM code generation best practices
- No hook enforcement (Cursor limitation)

</details>

<details>
<summary><strong>Any Agent (npx skills add)</strong></summary>

Works with any agent that supports the [Agent Skills](https://agentskills.io) format:

```bash
# All skills, all detected agents
npx skills add truefoundry/skills -s '*' -y

# Specific agent
npx skills add truefoundry/skills -a claude-code -s '*' -y
npx skills add truefoundry/skills -a cursor -s '*' -y
npx skills add truefoundry/skills -a codex -s '*' -y

# Single skill
npx skills add truefoundry/skills -s codebase-scanner -y
npx skills add truefoundry/skills -s onboard -y
npx skills add truefoundry/skills -s gateway -y
```

</details>

## What You Can Do

Ask your agent in plain English:

- *"set up TrueFoundry gateway for this project"*
- *"scan this codebase and migrate all LLM calls to the gateway"*
- *"onboard me — I just signed up"*
- *"set up model routing for gpt-4 and claude-3"*
- *"add a PII guardrail to the gateway"*
- *"register an MCP server"*
- *"create a prompt in the prompt registry"*
- *"show me how to publish a skill to the Skills Registry"*
- *"show me how to create and publish an agent"*
- *"configure rate limits for my API token"*
- *"show my gateway usage and costs"*
- *"show my gateway monitoring dashboard"*
- *"what's my connection status?"*

## Skills

| Skill | Description |
|-------|-------------|
| **gateway** | AI Gateway configuration: models, providers, guardrails, rate limiting, budget controls, routing |
| **observability** | Monitoring, logs, usage dashboards, OpenTelemetry tracing |
| **platform** | Platform ops: CLI login checks, workspaces, clusters, access control, secrets, PATs |
| **mcp-servers** | MCP server registry: list, create, update remote, virtual, OpenAPI, and hosted stdio-backed MCP servers |
| **prompts** | Prompt Registry: list, create, update, version, tag, and reference prompts |
| **agents** | UI-first Agent Registry workflows: create, test, publish, edit, and attach MCP servers or skills |
| **skills-registry** | Skills Registry: publish, version, download, update, and attach reusable Agent Skills |
| **onboard** | First-time setup: browser registration, tenant URL, CLI install, `tfy login`, login verification |
| **codebase-scanner** | Audit codebase for LLM/MCP calls, generate migration report, apply changes to route through gateway |

## Plugin Components

### Hooks (Claude Code & Codex)

| Hook | What It Does |
|------|-------------|
| **Session Start** | Checks tenant config, auto-installs `tfy` CLI, and runs API checks when an API key is available |
| **Block Deletes** | Blocks DELETE API calls — redirects to TrueFoundry dashboard |
| **Secret Scan** | Blocks commands with hardcoded API keys — enforces `tfy-secret://` |

### Agents (Claude Code)

| Agent | Purpose |
|-------|---------|
| **gateway-configurator** | Full gateway setup: credentials, workspace, secrets, routing, guardrails, verification |
| **troubleshoot** | Diagnoses gateway issues: checks config, logs, error patterns (401, 429, etc.) |

### Commands

| Command | Description |
|---------|-------------|
| `/truefoundry:setup` | Interactive gateway setup for current project |
| `/truefoundry:status` | Check gateway connection and usage status |

### Rules (Cursor)

| Rule | Description |
|------|-------------|
| `use-tfy-gateway.mdc` | Ensures LLM code always uses gateway patterns (env vars, model format, no hardcoded keys) |

## Feature Comparison

| Feature | Claude Code | Codex | Cursor | npx skills |
|---------|:-----------:|:-----:|:------:|:----------:|
| 9 skills | yes | yes | yes | yes |
| Hook enforcement | yes | yes | no | no |
| Specialized agents | yes | no | no | no |
| Slash commands | yes | no | no | no |
| Cursor rules | no | no | yes | no |
| `userConfig` (secure key storage) | yes | yes | no | no |

## Architecture

```
truefoundry/skills/
├── .claude-plugin/          # Claude Code marketplace manifest
├── .codex-plugin/           # Codex marketplace manifest
├── .cursor-plugin/          # Cursor marketplace manifest
├── skills/                  # Shared across all agents
│   ├── gateway/
│   ├── mcp-servers/
│   ├── observability/
│   ├── platform/
│   ├── prompts/
│   ├── agents/
│   ├── skills-registry/
│   ├── onboard/
│   └── codebase-scanner/
├── agents/                  # Subagent definitions
├── commands/                # Slash commands
├── hooks/                   # Event hooks + implementations
├── rules/                   # Cursor .mdc rules
├── plugin-scripts/          # Hook shell scripts
└── scripts/                 # Dev tooling
```

## Development

```bash
./scripts/validate-skills.sh           # Validate skill structure
./scripts/validate-skill-security.sh   # Security checks
./scripts/sync-shared.sh              # Sync shared files to all skills
./scripts/test-tfy-api.sh             # Unit tests
./scripts/install.sh                   # Install locally for all agents
```

## Marketplace Submission Status

| Marketplace | Status | Install command |
|-------------|--------|-----------------|
| Claude Code | Pending | `/plugin install truefoundry@truefoundry/skills` |
| Codex | Pending | `codex plugin marketplace add truefoundry/skills` |
| Cursor | Pending | `cursor.com/marketplace` → TrueFoundry |

## License

MIT
