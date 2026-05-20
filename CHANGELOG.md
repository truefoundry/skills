# Changelog

## Unreleased

### Changed

- Simplified the repo to a skills-only package.
- Removed plugin manifests, plugin scripts, top-level agent definitions, slash commands, runtime hooks, and Cursor rules.
- Centralized shared references and helper scripts under `skills/_shared/`.
- Replaced repeated shared files in skill folders with symlinks.
- Updated installer and validation scripts for the shared-symlink layout.
- Simplified install and contribution documentation.

### Removed

- `.claude-plugin/`, `.codex-plugin/`, `.cursor-plugin/`
- `.cursor/rules/`
- `agents/`
- `commands/`
- `hooks/`
- `plugin-scripts/`
- `rules/`
- per-skill install pages
- pull request template
