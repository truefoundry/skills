# Prerequisites

## Step 0: CLI and Login Check

Check if the TrueFoundry CLI is available:

```bash
tfy --version 2>/dev/null
```

If `TFY_API_KEY` is set and you use `tfy` CLI commands (`tfy apply`), ensure `TFY_HOST` is set:

```bash
export TFY_HOST="${TFY_HOST:-${TFY_BASE_URL%/}}"
```

If not found, install it:

```bash
pip install 'truefoundry==0.5.0'
```

> **Note:** The CLI (`tfy apply`) is the recommended deployment method, but it is not strictly required. All skills fall back to the REST API via `tfy-api.sh` when the CLI is unavailable.

Before any non-onboarding skill changes TrueFoundry resources, check that CLI login already exists:

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

If the user does not have a TrueFoundry tenant or CLI login yet, stop and use the `truefoundry-onboard` skill. Do not duplicate onboarding steps in other skills.

## Credential Check

Run this to verify your environment:

```bash
echo "TFY_BASE_URL: ${TFY_BASE_URL:-(not set)}"
echo "TFY_HOST: ${TFY_HOST:-(not set)}"
echo "TFY_API_KEY: ${TFY_API_KEY:+(set)}${TFY_API_KEY:-(not set)}"
echo "TFY_WORKSPACE_FQN: ${TFY_WORKSPACE_FQN:-(not set)}"
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `TFY_BASE_URL` | Yes | TrueFoundry platform URL (e.g., `https://your-org.truefoundry.cloud`) |
| `TFY_HOST` | For CLI commands | CLI host URL (usually same as `TFY_BASE_URL`, no trailing slash) |
| `TFY_API_KEY` | For direct REST helpers | API key for `tfy-api.sh` calls; not required for interactive `tfy login` |
| `TFY_WORKSPACE_FQN` | For resource creation | Workspace fully qualified name (e.g., `cluster-id:workspace-name`) |

### Variable Name Aliases

Different tools use different variable names. The `tfy-api.sh` script auto-resolves these:

| Canonical (used by scripts) | Alias (CLI) | Alias (.env files) | Notes |
|---|---|---|---|
| `TFY_BASE_URL` | `TFY_HOST` | `TFY_API_HOST` | `tfy-api.sh` checks all three in order |
| `TFY_API_KEY` | -- | -- | Same name everywhere |

If your `.env` uses `TFY_HOST` or `TFY_API_HOST`, the scripts will pick it up automatically. No manual renaming needed.

If your `.env` only has `TFY_BASE_URL`, derive CLI host before running `tfy apply`:

```bash
export TFY_HOST="${TFY_HOST:-${TFY_BASE_URL%/}}"
```

## Workspace FQN Rule — MANDATORY

> **HARD RULE: Never auto-pick a workspace. Never silently select a workspace. Always ask the user to confirm, even if there is only one workspace available.**

Applying to the wrong workspace can be disruptive and hard to reverse. You MUST follow this flow:

1. **If `TFY_WORKSPACE_FQN` is set in the environment** — confirm with the user: "I see workspace `X` in your environment. Should I use that?"
2. **If only one workspace is returned by the API** — still confirm: "You have access to workspace `X`. Should I use that?"
3. **If multiple workspaces exist** — present the list and ask the user to choose.
4. **If no workspace is found** — STOP and ask. Suggest using the `workspaces` skill or the TrueFoundry dashboard.

**Do NOT skip confirmation even when the choice seems obvious.** The user must explicitly approve the target workspace before any manifest is created or applied.

## .env File

Skills look for credentials in environment variables first, then fall back to `.env` in the working directory. The `tfy-api.sh` script handles this automatically.

## Generating API Keys

Only ask for an API key if a direct REST helper is needed. If the user is not already onboarded, route them to the `truefoundry-onboard` skill first.

See: [API Keys](https://docs.truefoundry.com/docs/generate-api-key)
