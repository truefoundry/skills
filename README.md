# TrueFoundry Skills

[![CI](https://github.com/truefoundry/skills/actions/workflows/ci.yml/badge.svg)](https://github.com/truefoundry/skills/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Official TrueFoundry plugin for AI coding agents. Unified repo for **Claude Code**, **Codex**, and **Cursor** — one install gives you gateway configuration, codebase migration, observability, and onboarding skills.

## Quick Start

### Prerequisites

```bash
export TFY_BASE_URL=https://your-org.truefoundry.cloud
export TFY_API_KEY=tfy-...
```

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
- 7 skills (gateway, platform, observability, tools, agents, onboard, codebase-scanner)
- 2 specialized agents (gateway configurator, troubleshoot)
- 3 hooks (credential bootstrap, delete blocking, secret scanning)
- MCP server for gateway observability tools
- Slash commands: `/truefoundry:setup`, `/truefoundry:status`
- `userConfig` prompts for TFY_BASE_URL + TFY_API_KEY on install

</details>

<details>
<summary><strong>Codex (Plugin)</strong></summary>

Add the marketplace and install:

```bash
codex plugin marketplace add truefoundry/skills
codex plugin install truefoundry
```

What you get:
- 7 skills loaded automatically
- MCP server for gateway tools
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
- 7 skills as agent context
- MCP server for gateway tools
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
- *"configure rate limits for my API token"*
- *"show my gateway usage and costs"*
- *"show my gateway monitoring dashboard"*
- *"what's my connection status?"*

## Skills

| Skill | Description |
|-------|-------------|
| **gateway** | AI Gateway configuration: models, providers, guardrails, rate limiting, budget controls, routing |
| **observability** | Monitoring, logs, usage dashboards, OpenTelemetry tracing |
| **platform** | Platform ops: workspaces, clusters, deployments, access control |
| **tools** | MCP server registration, secrets management, documentation |
| **agents** | Prompt registry and AI agent management |
| **onboard** | Interactive setup wizard: auth (email+OTP or PAT), provider keys, coding agent config |
| **codebase-scanner** | Audit codebase for LLM/MCP calls, generate migration report, apply changes to route through gateway |

## Plugin Components

### Hooks (Claude Code & Codex)

| Hook | What It Does |
|------|-------------|
| **Session Start** | Verifies credentials, auto-installs `tfy` CLI, tests API connectivity |
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
| 7 skills | yes | yes | yes | yes |
| Hook enforcement | yes | yes | no | no |
| MCP server | yes | yes | yes | no |
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
├── .mcp.json                # Shared MCP server config
├── skills/                  # Shared across all agents
│   ├── gateway/
│   ├── observability/
│   ├── platform/
│   ├── tools/
│   ├── agents/
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
