#!/usr/bin/env bash
# Link shared files from _shared/ into each skill directory.
# Run after editing files in skills/_shared/.
# Must be run from the repository root (directory containing scripts/ and skills/).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILLS_DIR="$REPO_ROOT/skills"
SHARED_DIR="$SKILLS_DIR/_shared"

if [ ! -d "$SHARED_DIR" ]; then
  echo "Error: $SHARED_DIR not found" >&2
  exit 1
fi

count=0
for skill_dir in "$SKILLS_DIR"/*/; do
  skill_name=$(basename "$skill_dir")
  [[ "$skill_name" == _* ]] && continue
  [[ "$skill_name" == onboard ]] && continue
  [ -f "$skill_dir/SKILL.md" ] || continue

  while IFS= read -r shared_file; do
    rel_path="${shared_file#"$SHARED_DIR"/}"
    target="$skill_dir/$rel_path"
    mkdir -p "$(dirname "$target")"
    rm -f "$target"
    ln -s "../../_shared/$rel_path" "$target"
  done < <(find "$SHARED_DIR" -type f | sort)

  count=$((count + 1))
done

# Verify links point to the canonical source.
errors=0
for skill_dir in "$SKILLS_DIR"/*/; do
  skill_name=$(basename "$skill_dir")
  [[ "$skill_name" == _* ]] && continue
  [[ "$skill_name" == onboard ]] && continue
  [ -f "$skill_dir/SKILL.md" ] || continue

  for shared_file in "$SHARED_DIR"/scripts/* "$SHARED_DIR"/references/*; do
    [ -f "$shared_file" ] || continue
    rel_path="${shared_file#"$SHARED_DIR"/}"
    target="$skill_dir/$rel_path"
    expected="../../_shared/$rel_path"
    if [ ! -L "$target" ]; then
      echo "ERROR: $skill_name/$rel_path is not a symlink to _shared/" >&2
      errors=$((errors + 1))
      continue
    fi
    if [ "$(readlink "$target")" != "$expected" ]; then
      echo "ERROR: $skill_name/$rel_path points to $(readlink "$target"), expected $expected" >&2
      errors=$((errors + 1))
      continue
    fi
    if [ ! -e "$target" ]; then
      echo "ERROR: $skill_name/$rel_path is a broken symlink" >&2
      errors=$((errors + 1))
    fi
  done
done

if [ "$errors" -gt 0 ]; then
  echo "FAILED: $errors shared links are invalid" >&2
  exit 1
fi

echo "Linked shared files into $count skills."
