# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

Content-only skill definitions (markdown + shell scripts) for configuring TrueFoundry AI Gateway via AI coding agents. No servers, databases, or SDKs — agents read these files at runtime. Deploying workloads requires a TrueFoundry Enterprise account with a connected cluster. See https://truefoundry.com.

## Commands

| Task | Command |
|------|---------|
| Validate skills | `./scripts/validate-skills.sh` |
| Lint shell scripts | `shellcheck scripts/*.sh hooks/auto-approve-tfy-api.sh skills/_shared/scripts/tfy-api.sh` |
| Lint plugin scripts | `shellcheck plugin-scripts/*.sh` |
| Security checks | `./scripts/validate-skill-security.sh` |
| Security (changed only) | `./scripts/validate-skill-security.sh --changed` |
| Unit tests | `./scripts/test-tfy-api.sh` |
| Sync shared files | `./scripts/sync-shared.sh` |
| Install locally | `./scripts/install.sh` |
| Pre-push hook setup | `./scripts/setup-git-hooks.sh` |

## Architecture

### Skill Structure

Each skill lives in `skills/{name}/` with:
- `SKILL.md` — main instruction file with YAML frontmatter (`name`, `description`, `allowed-tools`)
- `references/` — supporting markdown docs (mix of skill-specific and shared symlinks)
- `scripts/` — shell scripts (symlinked from `_shared/scripts/`)

### Plugin Structure

The repo is a unified plugin for Claude Code, Codex, and Cursor:
- `.claude-plugin/` — Claude Code plugin manifest + marketplace metadata
- `.codex-plugin/` — Codex plugin manifest + marketplace metadata
- `.cursor-plugin/` — Cursor plugin manifest + marketplace metadata
- `.mcp.json` — shared MCP server config (used by all agents)
- `.codex/hooks.json` — hooks in Codex format
- `agents/` — specialized agents (`gateway-configurator.md`, `troubleshoot.md`)
- `commands/` — slash commands (`setup.md`, `status.md`)
- `rules/` — Cursor `.mdc` rules (`use-tfy-gateway.mdc`)
- `plugin-scripts/` — hook implementations (`session-start.sh`, `block-delete-operations.sh`, `pre-tool-secret-scan.sh`)
- `hooks/hooks.json` — Claude Code hook definitions (SessionStart + PreToolUse)

### Shared Files (canonical source: `skills/_shared/`)

Never edit files directly under `skills/*/references/` or `skills/*/scripts/` if they are symlinks or copies of shared files. Edit the canonical version in `skills/_shared/` then run `./scripts/sync-shared.sh`.

Shared references (5 files): `api-endpoints.md`, `cli-fallback.md`, `intent-clarification.md`, `prerequisites.md`, `tfy-api-setup.md`

Shared scripts (2 files): `tfy-api.sh`, `tfy-version.sh`

### Installation Targets

`scripts/install.sh` installs to 7 agents: Claude Code, Cursor, Codex, OpenCode, Windsurf, Cline, Roo Code. It symlinks shared scripts and copies references into each skill directory under the agent's config path.

### Validation Rules (`validate-skills.sh`)

- Frontmatter must have `name`, `description`, `allowed-tools`
- `name` must match directory name, lowercase + hyphens only
- `allowed-tools` must be space-separated (not comma-separated)
- All shared file copies must match their `_shared/` canonical source
- `SKILL_NAMES` array in `install.sh` must match all skill directories

### CI Pipeline

Two jobs: `validate` (shellcheck + validate-skills + security + unit tests) and `install-e2e` (matrix test across all 7 agent types verifying symlinks and skill count).

## Key Conventions

- **CLI-first, API-fallback**: Skills instruct agents to try `tfy` CLI commands first, falling back to `tfy-api.sh` REST calls
- **Never auto-pick `TFY_WORKSPACE_FQN`**: Always ask the user or discover via API
- **No hardcoded env-specific values**: URLs, cluster names, workspace FQNs must come from user or API
- **Decision logic stays inline in SKILL.md**: Don't offload routing decisions to reference files
- **Schema-guided manifests**: Each manifest type has a schema reference doc in `references/schemas/`. Agents consult these before generating YAML and validate with `tfy apply --dry-run`.
- **7 skills total**: agents, codebase-scanner, gateway, observability, onboard, platform, tools
