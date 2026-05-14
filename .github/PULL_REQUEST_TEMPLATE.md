## Summary

<!-- One or two sentences. What did you do and why? -->

## Affected areas

- [ ] Skills or shared references
- [ ] Scripts, hooks, or MCP config
- [ ] Plugin manifests or marketplace metadata
- [ ] GitHub templates or CI
- [ ] Documentation only
- [ ] Local/generated artifacts only

## Validation

<!-- Check only what applies. Paste any relevant output in the PR body. -->

- [ ] Ran `./scripts/validate-skills.sh`
- [ ] Ran `./scripts/validate-skill-security.sh`
- [ ] Ran `./scripts/test-tfy-api.sh`
- [ ] Ran `shellcheck scripts/*.sh hooks/auto-approve-tfy-api.sh skills/_shared/scripts/*.sh plugin-scripts/*.sh` if shell scripts changed
- [ ] Tested locally with `./scripts/install.sh` if install behavior changed
- [ ] Ran `./scripts/sync-shared.sh` (if shared files were edited)

## Safety checklist

- [ ] No hardcoded credentials, API keys, or private URLs
- [ ] No generated local agent install artifacts committed
- [ ] No root `AGENTS.md`, `CLAUDE.md`, or `claude.md` files reintroduced
