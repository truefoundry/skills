# TrueFoundry CLI Reference

The `tfy` CLI is a thin deployment tool. It does NOT have subcommands for querying, listing, or inspecting resources. For read operations, use the REST API via `tfy-api.sh`.

## Installation

```bash
pip install -U "truefoundry"
```

Requires Python 3.9–3.14. Optional extras:
- `pip install -U "truefoundry[workflow]"` — workflow support (Python 3.9–3.12)
- `pip install -U "truefoundry[workflow,spark]"` — workflow + Spark

## Commands

### tfy login

Authenticate the CLI against a TrueFoundry tenant.

```bash
# Interactive (opens browser for device code flow) — recommended
tfy login --host https://your-org.truefoundry.cloud

# Non-interactive (CI/CD only — key appears in shell history)
tfy login --host https://your-org.truefoundry.cloud --api-key "$TFY_API_KEY"
```

Stores credentials in `~/.truefoundry/credentials.json`.

| Flag | Required | Description |
|------|----------|-------------|
| `--host` | Yes | Tenant URL (e.g. `https://acme.truefoundry.cloud`) |
| `--api-key` | No | API key for non-interactive login (CI/CD) |

### tfy apply

Create or update resources from YAML manifests.

```bash
# Single file
tfy apply -f manifest.yaml

# Multiple files
tfy apply -f manifest1.yaml -f manifest2.yaml

# Entire directory (recursive, discovers *.yaml and *.yml)
tfy apply --dir ./manifests
```

| Flag | Description |
|------|-------------|
| `-f <file>` | Manifest file(s) to apply. Repeatable. |
| `--dir <path>` | Directory of manifests (cannot combine with `-f`) |
| `--dry-run` | Simulate changes without persisting |
| `--show-diff` | Show diff between manifest and deployed state |
| `--diffs-only` | Apply only changed files vs HEAD (requires `--dir`) |
| `--ref <ref>` | Git ref to diff against (default: HEAD). Use with `--diffs-only` |
| `--sync` | Delete platform resources for removed YAML files (requires `--dir` + `--diffs-only`) |

**Supported resource types:** provider-account, gateway-load-balancing-config, gateway-rate-limiting-config, gateway-budget-config, gateway-guardrails-config, mcp-server, workspace, cluster, application, secret-group, ml-repo, agent, agent-skill

**Environment:** Requires `TFY_HOST` to be set when `TFY_API_KEY` is in the environment:
```bash
export TFY_HOST="${TFY_HOST:-${TFY_BASE_URL%/}}"
```

### tfy delete

Delete resources using the same manifest files used with `tfy apply`.

```bash
# Single file
tfy delete -f manifest.yaml

# Multiple files
tfy delete -f manifest1.yaml -f manifest2.yaml
```

| Flag | Description |
|------|-------------|
| `-f <file>` | Manifest file(s) identifying resources to delete. Repeatable. |

### tfy --version

Print the installed CLI version.

```bash
tfy --version
# Output: tfy version X.Y.Z
```

## Commands That DO NOT Exist

The following are **not valid** `tfy` subcommands. Do not attempt them:

- `tfy get` / `tfy list` / `tfy describe`
- `tfy config` / `tfy config get` / `tfy config set`
- `tfy whoami` / `tfy status`
- `tfy download` / `tfy upload`
- `tfy init` / `tfy create`
- `tfy logs` / `tfy exec`

For all read/query operations, use the REST API directly via `tfy-api.sh` or `curl`.

## Authentication Modes

| Mode | How | When |
|------|-----|------|
| Interactive login | `tfy login --host <url>` | Local development |
| Environment variables | `TFY_HOST` + `TFY_API_KEY` | CI/CD, scripts, `tfy-api.sh` |
| Non-interactive login | `tfy login --host <url> --api-key <key>` | CI/CD (key in history — prefer env vars) |

## Credential Storage

After `tfy login`, credentials are stored at:
```
~/.truefoundry/credentials.json
```

Fields: `host`, `access_token`, `refresh_token`.

## Decision Tree

```
Need to CREATE/UPDATE/DELETE a resource?
  → tfy apply / tfy delete

Need to READ/LIST/QUERY a resource?
  → REST API via tfy-api.sh or curl

Need to verify login?
  → Check ~/.truefoundry/credentials.json (see prerequisites.md)
```
