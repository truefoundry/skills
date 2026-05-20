# Contributing

This repo is a skills-only package. Keep the public surface simple: install with `npx skills add truefoundry/skills`, then use the skills.

## Local Checks

```bash
./scripts/sync-shared.sh
./scripts/validate-skills.sh
./scripts/validate-skill-security.sh
./scripts/test-tfy-api.sh
```

For shell changes, also run:

```bash
shellcheck scripts/*.sh skills/_shared/scripts/*.sh
```

## Adding A Skill

Create:

```text
skills/<name>/SKILL.md
```

Use frontmatter like:

```yaml
---
name: truefoundry-<name>
description: When the agent should use this skill.
allowed-tools: Bash(*/tfy-api.sh *)
---
```

Then:

1. Add the skill name to `SKILL_NAMES` in `scripts/install.sh`.
2. Keep `SKILL.md` concise and route deeper details to `references/...`.
3. Use shared files through local symlinks, not duplicate copies.
4. Run `./scripts/sync-shared.sh`.
5. Run the local checks.

## Shared Files

Canonical shared files live in `skills/_shared/`.

Each skill exposes those files through local paths:

```text
skills/<skill>/references/prerequisites.md
skills/<skill>/scripts/tfy-api.sh
```

Those entries are symlinks back to `skills/_shared/`. Edit the canonical file, then run:

```bash
./scripts/sync-shared.sh
```

## Skill Rules

- Use CLI-first guidance when the command exists.
- Use direct REST API fallback through `scripts/tfy-api.sh` when needed.
- Never auto-pick `TFY_WORKSPACE_FQN`; ask the user.
- Never execute destructive delete flows from skills. Route deletion to the dashboard.
- Keep decision logic inline in `SKILL.md`; move only lookup tables, schemas, long examples, and helper scripts into references.
- Do not hardcode tenant URLs, API keys, tokens, or workspace-specific values.

## Repo Scripts

| Script | Purpose |
|--------|---------|
| `scripts/install.sh` | Installs skills into detected agent skill directories |
| `scripts/sync-shared.sh` | Rebuilds shared symlinks in each skill |
| `scripts/validate-skills.sh` | Checks skill metadata, shared symlinks, install coverage, and CLI reference drift |
| `scripts/validate-skill-security.sh` | Runs local safety checks over skill Markdown |
| `scripts/test-tfy-api.sh` | Tests the shared REST helper failure modes |
| `scripts/check-tfy-cli-reference.sh` | Verifies documented CLI commands against live `tfy --help` |
