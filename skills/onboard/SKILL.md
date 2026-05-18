---
name: truefoundry-onboard
description: First-time TrueFoundry setup. Handles tenant registration, CLI installation, tfy login, and login verification. Use when no TrueFoundry credentials exist or when other skills report missing login.
license: MIT
compatibility: Requires Bash, Python 3, and the tfy CLI
allowed-tools: Bash(tfy*) Bash(pip*) Bash(uv*) Bash(python*) Bash(cat*) Bash(mkdir*)
---

<objective>

# TrueFoundry Onboarding

Get the user to one stable state:

1. They have a TrueFoundry tenant URL.
2. The TrueFoundry CLI is installed.
3. `tfy login --host <tenant-url>` has completed.
4. Other TrueFoundry skills can run against that tenant.

Stop after CLI login verification. Operational setup belongs to the other TrueFoundry skills.

</objective>

<instructions>

## Flow

### Step 1: Check CLI Installation

The first check is the CLI version. This tells you whether the TrueFoundry Python package and `tfy` entrypoint are installed.

Run:

```bash
tfy --version 2>/dev/null
```

If this fails, install the CLI:

```bash
pip install 'truefoundry==0.5.0'
```

If `pip` is unavailable and `uv` exists, use:

```bash
uv tool install --python 3.12 'truefoundry==0.5.0'
```

Then rerun:

```bash
tfy --version
```

Do not guess common status/config commands. `tfy whoami`, `tfy show-config`, `tfy status`, and `tfy config ...` are invalid for this CLI.

### Step 2: Check Existing Login

After `tfy --version` works, check whether CLI login is already present:

```bash
python3 - <<'PY'
import json
from pathlib import Path

path = Path.home() / ".truefoundry" / "credentials.json"
try:
    data = json.loads(path.read_text())
except Exception:
    data = {}

host = data.get("host") or data.get("base_url") or ""
token = data.get("access_token") or data.get("refresh_token") or ""
if host and token:
    print(f"tfy login: ok ({host})")
else:
    print("tfy login: missing")
PY
```

If login is already present, tell the user the tenant host and stop. The next requested TrueFoundry skill can continue.

### Step 3: Get Tenant URL If Login Is Missing

If the login check prints `tfy login: missing`, say:

```text
Looks like the tenant is not set or CLI login is not done.
If you have not already, create an account at https://www.truefoundry.com/register, complete the onboarding/signup flow, and paste your tenant URL here.
```

Accept a full tenant URL, for example:

```text
https://acme.truefoundry.cloud
```

Use browser registration only for new tenants.

### Step 4: Login

After the user provides the tenant URL, ask them to complete interactive login:

```bash
tfy login --host "<tenant-url>"
```

The command may open a browser. Wait for the user to confirm it succeeded. This sets the CLI host and stores CLI credentials on the machine.

### Step 5: Verify

Run the login check from Step 2 again.

If it prints `tfy login: ok (...)`, onboarding is complete. Report:

```text
TrueFoundry CLI login is complete for <tenant-url>.
You can now use the other TrueFoundry skills. CLI-based flows should work from here.
```

If it still prints missing, ask the user to rerun `tfy login --host <tenant-url>` and paste any error message.

### After Onboarding — What NOT to Do

Once `tfy login` succeeds:
- Do NOT probe for verification commands (`tfy whoami`, `tfy show-config`, `tfy config get`, `tfy get workspace`, `tfy status`) — they don't exist.
- Do NOT re-verify by fetching READMEs or documentation.
- The single valid verification is the credentials.json check above. If that passes, login is done.
- Direct REST helper calls via `tfy-api.sh` may still require `TFY_API_KEY`; do not claim that a separate API key exists unless it is actually set.
- If the user immediately asks a follow-up like "what models are attached?", the answer is one API call: `$TFY_API_SH GET /api/svc/v1/provider-accounts`. Go straight there.

</instructions>

<success_criteria>

- The user has a tenant URL.
- `tfy --version` works.
- `~/.truefoundry/credentials.json` contains a host plus access or refresh token.
- The agent does not configure anything beyond CLI login.

</success_criteria>

<troubleshooting>

## CLI Not Found After Install

Ask the user to open a new terminal, or add the CLI install location to `PATH`.

## Login Opens Browser But Does Not Finish

Ask the user to retry:

```bash
tfy login --host "<tenant-url>"
```

Then collect the exact error message.

## Wrong Tenant

Run login again with the intended tenant:

```bash
tfy login --host "<correct-tenant-url>"
```

</troubleshooting>
