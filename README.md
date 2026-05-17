# TrueFoundry Skills

Route every LLM call through a managed gateway. One plugin gives your coding agent the ability to set up routing, guardrails, rate limits, observability, and codebase migration — all through plain English.

```
  "set up the gateway for this project"
  │
  ● agent reads your codebase
  │
  ● finds every LLM call (OpenAI, Anthropic, LangChain, …)
  │
  ● rewrites them to route through TrueFoundry Gateway
  │
  ✓ unified billing, guardrails, model routing — done
```

## Setup

Paste into Claude Code, Codex, or Cursor:

```text
Read https://github.com/truefoundry/skills/install.md and follow the instructions to register with TrueFoundry.
```

The agent will walk you through registration, CLI install, and `tfy login`. Nothing else runs until login is verified.

### Install

```bash
npx skills add truefoundry/skills -s '*' -y
```

This works with any agent that supports [Agent Skills](https://agentskills.io) — Claude Code, Codex, Cursor, etc.

## What you can ask

- *"scan this codebase and migrate all LLM calls to the gateway"*
- *"add a PII guardrail to my gateway"*
- *"set up model routing for gpt-4 and claude-3"*
- *"configure rate limits for my model"*
- *"show my gateway usage and costs"*
- *"register an MCP server"*
- *"create a prompt in the prompt registry"*
- *"publish a skill to the Skills Registry"*
- *"create and publish an agent"*

## Skills

| Skill | What it does |
|-------|-------------|
| `gateway` | Model routing, providers, guardrails, rate limits, budget controls |
| `codebase-scanner` | Finds every LLM call in your code, generates migration plan, rewrites to gateway |
| `observability` | Usage dashboards, logs, OpenTelemetry tracing |
| `platform` | CLI login, workspaces, clusters, secrets, access control |
| `mcp-servers` | Create and manage remote, virtual, and hosted MCP servers |
| `prompts` | Prompt registry — versioning, tagging, references |
| `agents` | Agent registry — create, test, publish, attach MCP servers |
| `skills-registry` | Publish and version reusable agent skills |
| `onboard` | First-time setup flow — registration through login verification |

## Architecture

```
truefoundry/skills/
├── skills/              ← shared skill definitions (all agents read these)
│   ├── gateway/
│   ├── codebase-scanner/
│   ├── observability/
│   ├── platform/
│   ├── mcp-servers/
│   ├── prompts/
│   ├── agents/
│   ├── skills-registry/
│   └── onboard/
├── agents/              ← subagent definitions (Claude Code)
├── hooks/               ← event hooks (credential bootstrap, secret scanning)
├── commands/            ← slash commands
├── rules/               ← Cursor .mdc rules
├── .claude-plugin/      ← Claude Code manifest
├── .codex-plugin/       ← Codex manifest
└── .cursor-plugin/      ← Cursor manifest
```

## Hooks

Three hooks run automatically on Claude Code and Codex:

- **Session start** — verifies tenant config, installs CLI if missing
- **Block deletes** — prevents DELETE API calls, redirects to dashboard
- **Secret scan** — blocks hardcoded API keys, enforces `tfy-secret://` references

## Contributing

Bug fixes, doc improvements, and new skills are welcome. If you're adding a skill, follow the structure in `skills/gateway/` as a reference.

---

[TrueFoundry](https://truefoundry.com) | [Docs](https://docs.truefoundry.com) | [Register](https://truefoundry.com/register)

## License

MIT
