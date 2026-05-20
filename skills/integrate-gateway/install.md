# Install — TrueFoundry Integrate Gateway Skill

Integrate your codebase with TrueFoundry AI Gateway — scan, plan, migrate, and verify.

## Quickest path

```bash
npx skills add truefoundry/skills --skill integrate-gateway --yes
```

This installs only the integrate-gateway skill. To install all TrueFoundry skills:

```bash
npx skills add truefoundry/skills --skill '*' --yes
```

## Claude Code (plugin install)

```bash
/install-plugin truefoundry/skills
```

This loads all skills including integrate-gateway.

## Cursor

```bash
npx skills add truefoundry/skills --agent cursor --skill integrate-gateway --yes --global
```

## Manual (any agent)

Copy `SKILL.md` into your agent's skills directory:

| Agent | Path |
|-------|------|
| Claude Code | `~/.claude/skills/truefoundry-integrate-gateway/SKILL.md` |
| Cursor | `~/.cursor/skills/truefoundry-integrate-gateway/SKILL.md` |
| Codex | `~/.codex/skills/truefoundry-integrate-gateway/SKILL.md` |
| Windsurf | `~/.windsurf/skills/truefoundry-integrate-gateway/SKILL.md` |
| Cline | `~/.cline/skills/truefoundry-integrate-gateway/SKILL.md` |

## After install

Tell your agent:

> "Integrate this codebase with TrueFoundry gateway"

Or for just an audit:

> "Audit this codebase for LLM usage — show me what's not going through the gateway"

## Prerequisites

- A completed TrueFoundry onboarding flow with `tfy login`
- A TrueFoundry API key (PAT or VAT) for Gateway model calls
- `TFY_BASE_URL` set to your tenant URL
- `rg` (ripgrep) installed for fast scanning — falls back to `grep` if unavailable

## What you get

- Deep analysis of all LLM call sites with effort classification
- Gap analysis: what's in your code vs what's in the gateway
- Migration plan with confirmation before any changes
- Provider account creation and secret storage
- Code changes to route through gateway (with confirmation)
- End-to-end verification that requests flow through TFY
- Hardcoded credential detection and secure migration to TFY Secrets

## Pairs well with

- `onboard` — if you don't have a TFY account yet, start here
- `gateway` — after integration, use to configure routing, rate limits, guardrails
- `observability` — verify traces are flowing after migration
