# Install — TrueFoundry Gateway Onboarding Skill

One command. Works with Claude Code, Cursor, Codex, Windsurf, Cline, Roo Code, and OpenCode.

## Quickest path

```bash
npx skills add truefoundry/skills -s onboard
```

This installs only the onboarding skill. To install all TrueFoundry skills (gateway config, observability, platform admin, etc.):

```bash
npx skills add truefoundry/skills --all
```

## Claude Code (plugin install)

```bash
/install-plugin truefoundry/skills
```

This loads all skills + enforcement hooks (secret scanning, delete blocking, auto-approve for API calls).

## Cursor

```bash
npx skills add truefoundry/skills -g -a cursor -s onboard -y
```

## Codex CLI

```bash
npx skills add truefoundry/skills -g -a codex -s onboard -y
```

## Manual (any agent)

Copy `SKILL.md` into your agent's skills directory:

| Agent | Path |
|-------|------|
| Claude Code | `~/.claude/skills/truefoundry-onboard/SKILL.md` |
| Cursor | `~/.cursor/skills/truefoundry-onboard/SKILL.md` |
| Codex | `~/.codex/skills/truefoundry-onboard/SKILL.md` |
| Windsurf | `~/.windsurf/skills/truefoundry-onboard/SKILL.md` |
| Cline | `~/.cline/skills/truefoundry-onboard/SKILL.md` |
| Roo Code | `~/.roo-code/skills/truefoundry-onboard/SKILL.md` |
| OpenCode | `~/.config/opencode/skill/truefoundry-onboard/SKILL.md` |

## After install

Just tell your agent:

> "Set up TrueFoundry gateway for this project"

Or more specifically:

> "Onboard me to TrueFoundry — I have my email ready"

The skill handles the rest — auth, provider linking, agent config, env setup, smoke test.

## What you need

- An email address (for new signups via OTP) or an existing TrueFoundry PAT
- At least one LLM provider key (OpenAI, Anthropic, Google, etc.) to link

## What you get

- Every LLM request tracked (cost, tokens, latency)
- Model switching without code changes
- Budget controls and rate limits
- Full request tracing and observability
- One API key for all providers
- Your coding agent (Claude Code, Codex, Cursor) pre-configured

## Flow overview

```
1. Auth      -> email+OTP (no browser) or paste existing PAT
2. Providers -> paste API keys, agent stores as secrets + creates accounts
3. Env       -> .env written with gateway URL + key
4. Agents    -> Claude Code / Codex / Cursor configured automatically
5. Verify    -> live LLM call through the gateway confirms everything works
```

Total time: ~2 minutes for a new user, ~30 seconds if you already have a PAT.
