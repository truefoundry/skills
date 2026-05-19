# Install — TrueFoundry Onboarding Skill

Install just the onboarding skill:

```bash
npx skills add truefoundry/skills -s onboard
```

Or install all TrueFoundry skills:

```bash
npx skills add truefoundry/skills --all
```

After install, tell your agent:

> Read https://raw.githubusercontent.com/truefoundry/skills/main/install.md and follow the instructions to register with TrueFoundry.

The onboarding flow is only:

1. Open https://www.truefoundry.com/register if you do not already have a tenant.
2. Paste the tenant URL into the agent.
3. Install or verify the `tfy` CLI.
4. Run `tfy login --host <tenant-url>`.
5. Verify CLI login is complete.

This skill stops after CLI login verification.
