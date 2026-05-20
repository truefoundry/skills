# TrueFoundry Skills Install

## Installation

### Quick Install

Using `npx skills`:

Local (current project):

```bash
npx skills add truefoundry/skills --skill '*' --yes
```

Global (all projects):

```bash
npx skills add truefoundry/skills --skill '*' --yes --global
```

To link skills to a specific agent, for example Claude Code:

```bash
npx skills add truefoundry/skills --agent claude-code --skill '*' --yes --global
```

Paste this into Claude Code, Codex, Cursor, or any coding agent that can read a URL:

> Read https://raw.githubusercontent.com/truefoundry/skills/main/install.md and follow the instructions to register with TrueFoundry.

The agent should use the `truefoundry-onboard` skill and follow this exact flow:

1. Check whether `tfy login` is already complete.
2. If not, send the user to https://www.truefoundry.com/register.
3. Ask the user to come back with their tenant URL.
4. Install or verify the TrueFoundry CLI.
5. Ask the user to run `tfy login --host <tenant-url>`.
6. Verify CLI login before invoking any other TrueFoundry skill.

Stop after CLI login verification. Operational setup belongs to the other TrueFoundry skills.
