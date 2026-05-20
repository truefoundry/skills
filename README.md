# TrueFoundry Skills

TrueFoundry Skills let coding agents configure and operate TrueFoundry AI Gateway through plain English.

## Install

```bash
npx skills add truefoundry/skills --yes
```

Then tell your coding agent:

```text
sign me up for truefoundry
```

The onboarding skill verifies the TrueFoundry CLI, sends you to browser signup if needed, runs `tfy login --host <tenant-url>`, and stops once login is verified.

## What You Can Ask

- "scan this codebase and migrate all LLM calls to the gateway"
- "add a PII guardrail to my gateway"
- "set up model routing for gpt 5.5 and sonnet 4.6"
- "configure rate limits for my model"
- "show my gateway usage and costs in the last 3 months"
- "register an MCP server"
- "create a prompt in the prompt registry"
- "publish a skill to the Skills Registry"

## Skills

| Skill | What it does |
|-------|-------------|
| `onboard` | First-time account and CLI login setup |
| `gateway` | Model routing, providers, guardrails, rate limits, budgets |
| `integrate-gateway` | Codebase scans and migration to AI Gateway |
| `observability` | Gateway usage, traces, cost, and error analysis |
| `platform` | Workspaces, secrets, access control, tokens, CLI preflight |
| `mcp-servers` | Remote, virtual, hosted, and OpenAPI MCP servers |
| `prompts` | Prompt registry management |
| `agents` | TrueFoundry Agent Registry workflows |
| `skills-registry` | Publishing reusable agent skills |

## Repo Shape

```text
truefoundry/skills/
├── skills/
│   ├── _shared/          # canonical shared references and scripts
│   ├── onboard/
│   ├── gateway/
│   ├── integrate-gateway/
│   ├── observability/
│   ├── platform/
│   ├── mcp-servers/
│   ├── prompts/
│   ├── agents/
│   └── skills-registry/
└── scripts/              # install, shared-link, and validation scripts
```

Shared files are maintained once in `skills/_shared/`. Individual skill folders expose local `references/...` and `scripts/...` paths through symlinks so agents can load nearby files normally.

## Development

```bash
./scripts/sync-shared.sh
./scripts/validate-skills.sh
./scripts/validate-skill-security.sh
./scripts/test-tfy-api.sh
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for skill authoring rules.

## Links

- [TrueFoundry](https://truefoundry.com)
- [Docs](https://docs.truefoundry.com)
- [Register](https://truefoundry.com/register)
