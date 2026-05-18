# TrueFoundry CLI Reference

This reference is grounded in `tfy --help` from `tfy 0.13.12`.

Do not guess `tfy` subcommands from common CLI patterns. Before using any `tfy` command not shown in this file, run `tfy --help` or `tfy <subcommand> --help` and use only commands that appear in that help output.

For gateway/platform read operations, prefer the REST API via `tfy-api.sh`. The CLI has `tfy get kubeconfig`, but it does not provide general list/describe/status commands for TrueFoundry resources.

## Installation

```bash
pip install -U "truefoundry"
```

Requires Python 3.9-3.14. Optional extras:
- `pip install -U "truefoundry[workflow]"` - workflow support (Python 3.9-3.12)
- `pip install -U "truefoundry[workflow,spark]"` - workflow + Spark

## Global Options

| Command | Purpose |
|---|---|
| `tfy --version` | Print the installed CLI version. |
| `tfy --json <command>` | Output entities in JSON format where the command supports entities. |
| `tfy --debug <command>` | Enable debug logging. Can also be set with `TFY_DEBUG=1`. |
| `tfy --help` / `tfy -h` | Show top-level help. |

## Command Index

| Command | Purpose | Skill usage guidance |
|---|---|---|
| `tfy apply` | Create/update resources from manifest files. | Allowed only after dry-run/diff plus explicit user confirmation. |
| `tfy delete` | Delete resources. | Do not execute from skills; provide manual dashboard instructions instead. |
| `tfy deploy` | Deploy an application from a `truefoundry.yaml` file. | Confirm workspace before use. |
| `tfy deploy workflow` | Deploy a workflow file. | Confirm workspace before use. |
| `tfy deploy-init model` | Generate model server application code for a model version. | Safe scaffolding command; still confirm output path. |
| `tfy get kubeconfig` | Update kubeconfig for a TrueFoundry cluster. | Only CLI read-style command observed. |
| `tfy login` | Login to a TrueFoundry tenant. | Valid onboarding command. |
| `tfy logout` | Logout from the current session. | Do not run unless the user explicitly asks. |
| `tfy ml download artifact` | Download a logged artifact version. | Writes files locally; confirm path/overwrite. |
| `tfy ml download model` | Download a logged model version. | Writes files locally; confirm path/overwrite. |
| `tfy patch` | Patch a local YAML file with a `yq` filter. | Local file mutation; review target file/output path first. |
| `tfy patch-application` | Patch and deploy an existing application. | Deployment mutation; requires explicit user confirmation. |
| `tfy terminate job` | Terminate a job run. | Do not execute from skills; destructive operational action. |
| `tfy trigger job` | Trigger a job run asynchronously. | Ask before triggering; may start compute/cost. |
| `tfy trigger workflow` | Trigger a workflow run. | Ask before triggering; may start compute/cost. |

## Authentication

### `tfy login`

Authenticate the CLI against a TrueFoundry tenant.

```bash
# Interactive login
tfy login --host https://your-org.truefoundry.cloud

# Non-interactive login
tfy login --host https://your-org.truefoundry.cloud --api-key "$TFY_API_KEY"
```

Options:
- `--host TEXT` - required tenant URL; can be set with `TFY_HOST`.
- `--api-key TEXT` / `--api_key TEXT` - API key for non-interactive login.
- `--relogin` - force relogin.
- `--help` / `-h` - show command help.

After `tfy login`, credentials are stored in:

```text
~/.truefoundry/credentials.json
```

Fields include `host`, `access_token`, and `refresh_token`.

### `tfy logout`

Logout from the current TrueFoundry session.

```bash
tfy logout
```

Do not run this unless the user explicitly asks to logout.

## Apply And Deploy

### `tfy apply`

Create or update resources from manifest files.

```bash
tfy apply -f manifest.yaml
tfy apply -f manifest1.yaml -f manifest2.yaml
tfy apply -f manifest.yaml --dry-run --show-diff
```

Options:
- `--file FILE` / `-f FILE` - required manifest file. Repeat for multiple files.
- `--dry-run` / `--dry_run` - simulate without applying.
- `--show-diff` / `--show_diff` - print manifest differences when using `--dry-run`.
- `--help` / `-h` - show command help.

Before the final non-dry-run apply, show the target host/workspace, an English summary, the YAML or diff, the exact command, and wait for explicit user confirmation.

### `tfy deploy`

Deploy an application to TrueFoundry.

```bash
tfy deploy -f truefoundry.yaml -w "<workspace-fqn>"
```

Options:
- `--file FILE` / `-f FILE` - path to `truefoundry.yaml`.
- `--workspace-fqn TEXT` / `--workspace_fqn TEXT` / `-w TEXT` - workspace FQN. If omitted, the CLI reads it from the deployment spec when available.
- `--wait` / `--no-wait` / `--no_wait` - wait and tail deployment progress. Defaults to wait.
- `--force` / `--no-force` - cancel ongoing deployments and force a new one. Defaults to no-force.
- `--trigger-on-deploy` / `--trigger_on_deploy` / `--no-trigger-on-deploy` / `--no_trigger_on_deploy` - trigger a job run after deployment succeeds. No effect for non-job deployments.
- `--help` / `-h` - show command help.

Always confirm the workspace before deployment. Treat `--force` and trigger-on-deploy as higher-risk options requiring explicit user confirmation.

### `tfy deploy workflow`

Deploy a workflow file.

```bash
tfy deploy workflow --name "<workflow-name>" -f workflow.py -w "<workspace-fqn>"
```

Options:
- `--name TEXT` / `-n TEXT` - required workflow name.
- `--file FILE` / `-f FILE` - required workflow file.
- `--workspace-fqn TEXT` / `--workspace_fqn TEXT` / `-w TEXT` - required workspace FQN.
- `--help` / `-h` - show command help.

### `tfy deploy-init model`

Generate application code for a model server deployment.

```bash
tfy deploy-init model \
  --name "<application-name>" \
  --model-version-fqn "<model-version-fqn>" \
  --workspace-fqn "<workspace-fqn>" \
  --model-server fastapi \
  --output-dir ./model-server
```

Options:
- `--name APPLICATION-NAME` - required model server deployment name.
- `--model-version-fqn NON-EMPTY-STRING` / `--model_version_fqn` - required model version FQN.
- `--workspace-fqn NON-EMPTY-STRING` / `--workspace_fqn` / `-w` - required workspace FQN.
- `--model-server [triton|fastapi]` / `--model_server` - model server type. Defaults to `fastapi`.
- `--output-dir DIRECTORY` / `--output_dir` - output directory for generated code.
- `--help` / `-h` - show command help.

## Local Patching

### `tfy patch`

Patch a local YAML file with a `yq` filter.

```bash
tfy patch -f servicefoundry.yaml --filter '.image.image_uri = "repo/image:tag"' -o patched.yaml
```

Options:
- `--file FILE` / `-f FILE` - path to servicefoundry YAML. Defaults to `./servicefoundry.yaml`.
- `--filter TEXT` - required `yq` filter.
- `--output-file PATH` / `-o PATH` - write output to a file.
- `--indent INTEGER` / `-I INTEGER` - output indent. Defaults to `4`.
- `--help` / `-h` - show command help.

### `tfy patch-application`

Patch and deploy an existing application.

```bash
tfy patch-application --application-fqn "<application-fqn>" --patch-file patch.yaml
tfy patch-application --application-fqn "<application-fqn>" --patch '{"key":"value"}'
```

Options:
- `--patch-file FILE` / `--patch_file FILE` / `-f FILE` - YAML patch file.
- `--patch TEXT` / `-p TEXT` - JSON patch string.
- `--application-fqn TEXT` / `--application_fqn TEXT` / `-a TEXT` - required application FQN.
- `--wait` / `--no-wait` / `--no_wait` - wait and tail deployment progress. Defaults to wait.
- `--help` / `-h` - show command help.

This mutates a live application. Show the patch and wait for explicit user confirmation before running.

## Read-Style Commands

### `tfy get kubeconfig`

Update kubeconfig to access a cluster attached to the TrueFoundry Control Plane.

```bash
tfy get kubeconfig --cluster "<cluster-id>" --overwrite
```

Options:
- `--cluster TEXT` / `-c TEXT` - cluster ID. If omitted, the CLI opens an interactive cluster picker.
- `--overwrite` - overwrite an existing cluster entry without prompting.
- `--help` / `-h` - show command help.

This writes to `~/.kube/config` by default, or to the first path in `KUBECONFIG`.

## Triggering Work

### `tfy trigger job`

Trigger a job asynchronously.

```bash
tfy trigger job --application-fqn "<cluster:workspace:job>"
tfy trigger job --application-fqn "<cluster:workspace:job>" --command "python run.py"
tfy trigger job --application-fqn "<cluster:workspace:job>" -- --param value
```

Options:
- `--application-fqn TEXT` / `--application_fqn TEXT` - required job deployment FQN.
- `--command TEXT` - command to run.
- `--run-name-alias TEXT` / `--run_name_alias TEXT` - alias for the job run name.
- `--help` / `-h` - show command help.

Ask before triggering jobs because it can start compute and cost.

### `tfy trigger workflow`

Trigger a workflow.

```bash
tfy trigger workflow --application-fqn "<cluster:workspace:workflow>"
tfy trigger workflow --application-fqn "<cluster:workspace:workflow>" -- --input value
```

Options:
- `--application-fqn TEXT` / `--application_fqn TEXT` - required workflow application FQN.
- `--help` / `-h` - show command help.

Ask before triggering workflows because it can start compute and cost.

## ML Downloads

### `tfy ml download artifact`

Download a logged artifact version.

```bash
tfy ml download artifact --fqn "<artifact-version-fqn>" --path ./downloads
```

Options:
- `--fqn TEXT` - required artifact version FQN.
- `--path DIRECTORY` - download destination. Defaults to `./`.
- `--overwrite` - overwrite existing files in the destination.
- `--progress` / `--no-progress` - show or hide progress while downloading.
- `--help` / `-h` - show command help.

### `tfy ml download model`

Download a logged model version.

```bash
tfy ml download model --fqn "<model-version-fqn>" --path ./models
```

Options:
- `--fqn TEXT` - required model version FQN.
- `--path DIRECTORY` - download destination. Defaults to `./`.
- `--overwrite` - overwrite existing files in the destination.
- `--progress` / `--no-progress` - show or hide progress while downloading.
- `--help` / `-h` - show command help.

## Destructive Or Blocked Commands

These commands exist in the CLI but must not be executed by these skills. Provide manual dashboard instructions instead.

### `tfy delete`

Delete TrueFoundry resources.

Observed forms:
- `tfy delete -f manifest.yaml`
- `tfy delete application --application-fqn "<application-fqn>"`
- `tfy delete workspace --workspace-fqn "<workspace-fqn>"`

Options:
- `--file FILE` / `-f FILE` - manifest file(s) identifying resources to delete.
- `tfy delete application`: `--application-fqn TEXT` / `--application_fqn TEXT`, `--yes`.
- `tfy delete workspace`: `--workspace-fqn TEXT` / `--workspace_fqn TEXT` / `-w TEXT`, `--yes`.

### `tfy terminate job`

Terminate a job run.

```bash
tfy terminate job --job-fqn "<job-fqn>" --job-run-name "<run-name>"
```

Options:
- `--job-fqn TEXT` / `--job_fqn TEXT` - required job FQN.
- `--job-run-name TEXT` / `--job_run_name TEXT` - required run name.
- `--help` / `-h` - show command help.

## Commands That Do Not Exist In `tfy 0.13.12`

The following are not valid `tfy` commands. Do not attempt them:

- `tfy whoami`
- `tfy show-config`
- `tfy status`
- `tfy config`, `tfy config get`, `tfy config set`
- `tfy list`
- `tfy describe`
- `tfy logs`
- `tfy exec`
- `tfy init`
- `tfy create`
- `tfy ask`
- top-level `tfy download` or `tfy upload` (`tfy ml download ...` is valid)

## Decision Tree

```text
Need to verify login?
  -> Check ~/.truefoundry/credentials.json (see prerequisites.md)

Need to read/list/query gateway or platform resources?
  -> Use the REST API via tfy-api.sh or curl

Need kubeconfig?
  -> tfy get kubeconfig

Need to create/update resources from manifests?
  -> tfy apply with dry-run/diff first, then explicit user confirmation

Need to deploy or patch live applications?
  -> tfy deploy / tfy patch-application only after workspace confirmation and user approval

Need to delete, terminate, revoke, remove, or purge anything?
  -> Do not run CLI/API destructive commands; provide manual dashboard steps
```
