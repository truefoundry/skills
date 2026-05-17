# TrueFoundry Skills

[TrueFoundry AI Gateway](https://truefoundry.com) is the proxy layer that sits between your applications and LLM providers and MCP servers. It's an enterprise-grade platform that gives you access to 1000+ LLMs through a unified interface while handling observability and governance.

This is the official skills repo — it lets your coding agent set up and manage the gateway through plain English.

## Setup

Paste into Claude Code, Codex, or Cursor:

```text
Read https://github.com/truefoundry/skills/install.md and follow the instructions to register with TrueFoundry.
```

The agent will walk you through registration, CLI install, and `tfy login`. Nothing else runs until login is verified.

<details>
<summary><strong>Install the plugin</strong></summary>

**Claude Code**

```shell
/plugin marketplace add truefoundry/skills
/plugin install truefoundry@truefoundry-skills
```

**Codex**

```shell
codex plugin marketplace add truefoundry/skills
```

Then open the plugin list with `/plugins` and install `truefoundry`.

**Cursor**

For local testing:

```bash
git clone https://github.com/truefoundry/skills.git ~/.cursor/plugins/local/truefoundry
```

For team-wide: import `https://github.com/truefoundry/skills` from Dashboard → Settings → Plugins → Import.

</details>

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
