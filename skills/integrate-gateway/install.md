# Install — TrueFoundry Codebase Scanner Skill

Scan your codebase for all LLM calls and migrate them to route through TrueFoundry AI Gateway.

## Quickest path

```bash
npx skills add truefoundry/skills -s codebase-scanner
```

This installs only the codebase scanner skill. To install all TrueFoundry skills:

```bash
npx skills add truefoundry/skills --all
```

## Claude Code (plugin install)

```bash
/install-plugin truefoundry/skills
```

This loads all skills including the codebase scanner.

## Cursor

```bash
npx skills add truefoundry/skills -g -a cursor -s codebase-scanner -y
```

## Manual (any agent)

Copy `SKILL.md` into your agent's skills directory:

| Agent | Path |
|-------|------|
| Claude Code | `~/.claude/skills/truefoundry-codebase-scanner/SKILL.md` |
| Cursor | `~/.cursor/skills/truefoundry-codebase-scanner/SKILL.md` |
| Codex | `~/.codex/skills/truefoundry-codebase-scanner/SKILL.md` |
| Windsurf | `~/.windsurf/skills/truefoundry-codebase-scanner/SKILL.md` |
| Cline | `~/.cline/skills/truefoundry-codebase-scanner/SKILL.md` |

## After install

Tell your agent:

> "Scan this codebase and migrate all LLM calls to TrueFoundry gateway"

Or for just an audit:

> "Audit this codebase for LLM usage — show me what's not going through the gateway"

## Prerequisites

- A completed TrueFoundry onboarding flow with `tfy login`
- A TrueFoundry API key (PAT or VAT) for Gateway model calls
- Gateway access (SaaS: `https://gateway.truefoundry.ai`)
- `rg` (ripgrep) installed for fast scanning — falls back to `grep` if unavailable
- At least one provider configured in the gateway

## What you get

- Complete inventory of all LLM call sites in your codebase
- Migration report with per-file action items
- Automatic provider account manifest generation
- Code changes to route through gateway (with confirmation)
- Verification that requests flow through TFY with observability
- Hardcoded credential detection and secure migration to TFY Secrets

## Pairs well with

- `onboard` — if you don't have a TFY account yet, start here
- `gateway` — after scanning, use to configure routing, rate limits, guardrails
- `observability` — verify traces are flowing after migration
