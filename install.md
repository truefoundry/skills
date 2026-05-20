# Install TrueFoundry Skills

## Install All Skills

Local project:

```bash
npx skills add truefoundry/skills --skill '*' --yes
```

Global:

```bash
npx skills add truefoundry/skills --skill '*' --yes --global
```

## Onboard

After installing, tell your coding agent:

```text
sign me up for truefoundry
```

The agent should use `truefoundry-onboard` and follow this flow:

1. Verify the TrueFoundry CLI is installed.
2. Check whether `tfy login` is already complete.
3. If login is missing, open `https://www.truefoundry.com/register`.
4. Ask for the tenant URL after signup.
5. Run `tfy login --host <tenant-url>`.
6. Verify CLI login before using other TrueFoundry skills.

Stop after CLI login verification. Operational setup belongs to the other skills.
