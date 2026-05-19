#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REFERENCE_FILE="$REPO_ROOT/skills/_shared/references/cli-reference.md"

if ! command -v tfy >/dev/null 2>&1; then
  echo "Skipping tfy CLI reference drift check: tfy is not installed."
  exit 0
fi

errors=0
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

fail() {
  echo "ERROR: $*" >&2
  errors=$((errors + 1))
}

commands_from_help() {
  sed -n -E 's/^│[[:space:]]+([a-z][a-z0-9-]*)[[:space:]]{2,}.*/\1/p' | sort -u
}

expected_subcommands() {
  case "$*" in
    "")
      printf '%s\n' \
        apply \
        delete \
        deploy \
        deploy-init \
        get \
        login \
        logout \
        ml \
        patch \
        patch-application \
        terminate \
        trigger
      ;;
    "delete")
      printf '%s\n' application workspace
      ;;
    "deploy")
      printf '%s\n' workflow
      ;;
    "deploy-init")
      printf '%s\n' model
      ;;
    "get")
      printf '%s\n' kubeconfig
      ;;
    "ml")
      printf '%s\n' download
      ;;
    "ml download")
      printf '%s\n' artifact model
      ;;
    "terminate")
      printf '%s\n' job
      ;;
    "trigger")
      printf '%s\n' job workflow
      ;;
    *)
      return 1
      ;;
  esac
}

check_command_group() {
  local group="$1"
  local label="tfy"
  local help_output
  local args=()
  local expected_file="$tmp_dir/expected-${group// /_}-commands.txt"
  local actual_file="$tmp_dir/actual-${group// /_}-commands.txt"
  local missing_file="$tmp_dir/missing-${group// /_}-commands.txt"
  local unexpected_file="$tmp_dir/unexpected-${group// /_}-commands.txt"

  if [[ -n "$group" ]]; then
    label="tfy $group"
    read -r -a args <<<"$group"
  fi

  if ! expected_subcommands "$group" >"$expected_file"; then
    fail "no expected command list configured for $label"
    return
  fi

  if [[ "${#args[@]}" -eq 0 ]]; then
    help_output="$(tfy --help 2>&1)" || {
      fail "$label --help failed"
      return
    }
  elif ! help_output="$(tfy "${args[@]}" --help 2>&1)"; then
    fail "$label --help failed"
    return
  fi

  printf '%s\n' "$help_output" | commands_from_help >"$actual_file"

  comm -23 "$expected_file" "$actual_file" >"$missing_file"
  comm -13 "$expected_file" "$actual_file" >"$unexpected_file"

  if [[ -s "$missing_file" ]]; then
    fail "$label --help is missing documented command(s): $(paste -sd ', ' "$missing_file")"
  fi

  if [[ -s "$unexpected_file" ]]; then
    fail "$label --help has new undocumented command(s): $(paste -sd ', ' "$unexpected_file")"
  fi
}

check_help_exists() {
  local command_path="$*"
  local args=()
  read -r -a args <<<"$command_path"

  if ! tfy "${args[@]}" --help >/dev/null 2>&1; then
    fail "documented command does not expose help: tfy $command_path --help"
  fi
}

check_invalid_command_fails() {
  local command_path="$*"
  local args=()
  read -r -a args <<<"$command_path"

  if tfy "${args[@]}" --help >/dev/null 2>&1; then
    fail "command is documented as invalid but exists: tfy $command_path"
  fi
}

check_reference_mentions() {
  local text="$1"

  if ! grep -Fq -- "$text" "$REFERENCE_FILE"; then
    fail "cli-reference.md does not mention expected text: $text"
  fi
}

echo "Checking tfy CLI reference against installed CLI..."
echo "Using $(tfy --version)"

check_command_group ""
check_command_group "delete"
check_command_group "deploy"
check_command_group "deploy-init"
check_command_group "get"
check_command_group "ml"
check_command_group "ml download"
check_command_group "terminate"
check_command_group "trigger"

while IFS= read -r command_path; do
  [[ -z "$command_path" ]] && continue
  check_help_exists "$command_path"
done <<'EOF'
apply
delete
delete application
delete workspace
deploy
deploy workflow
deploy-init model
get kubeconfig
login
logout
ml download artifact
ml download model
patch
patch-application
terminate job
trigger job
trigger workflow
EOF

while IFS= read -r command_path; do
  [[ -z "$command_path" ]] && continue
  check_invalid_command_fails "$command_path"
done <<'EOF'
whoami
show-config
status
config
list
describe
logs
exec
init
create
ask
download
upload
EOF

check_reference_mentions "This reference is grounded in \`tfy --help\` from \`tfy 0.13.12\`."
check_reference_mentions "| \`tfy get kubeconfig\` |"
check_reference_mentions "| \`tfy trigger workflow\` |"
check_reference_mentions "These commands exist in the CLI but must not be executed by these skills."
check_reference_mentions "- \`tfy show-config\`"

if [[ "$errors" -gt 0 ]]; then
  echo "tfy CLI reference drift check failed with $errors error(s)." >&2
  exit 1
fi

echo "tfy CLI reference drift check passed."
