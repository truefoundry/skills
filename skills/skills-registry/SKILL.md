---
name: truefoundry-skills-registry
description: Manages TrueFoundry Skills Registry workflows. Covers creating, publishing, versioning, downloading, updating, and attaching reusable Agent Skills through UI or tfy apply.
license: MIT
compatibility: Requires Bash, tfy CLI, and access to a TrueFoundry tenant
allowed-tools: Bash(tfy*) Bash(python*) Bash(find*) Bash(rg*)
---

<objective>

# Skills Registry

Create and manage reusable Agent Skills in TrueFoundry Skills Registry.

Use this skill when the user wants to:

- Create a new Skill.
- Publish a `SKILL.md`.
- Upload a multi-file skill bundle.
- Download an existing skill bundle.
- Create a new skill version.
- Update skill metadata or body.
- Attach a skill to a TrueFoundry Agent.

</objective>

<instructions>

## Preflight

1. Verify `tfy login` is complete. If not, use `truefoundry-onboard`.
2. Confirm the target tenant and repository.
3. Decide the publish path:
   - UI: single-file `SKILL.md`.
   - `tfy apply`: declarative/GitOps flow when an `agent-skill` manifest is available.
   - Multi-file bundles: use the dashboard/registry workflow or exact product-provided command only after verifying it exists in `tfy --help`.

## UI Path

Use this path for single-file skills:

```text
TrueFoundry Dashboard -> Agents -> Skills -> Create New Skill -> Create from UI
```

The UI creates the frontmatter from form fields. The editor body should contain the skill procedure.

Required fields:

- Name
- Repository
- Description
- `SKILL.md` body

To create a new version later, open the skill and click `New Version`.

## Multi-File Bundles

Use this for multi-file skills with `references/`, `scripts/`, or `assets/`.

Expected local structure:

```text
my-skill/
  SKILL.md
  references/
  scripts/
  assets/
```

Before upload, inspect:

```bash
find ./my-skill -maxdepth 3 -type f | sort
```

Show the user the file list and ask for confirmation before publishing.

Do not run `tfy upload skill`; it is not present in `tfy 0.13.12`. If the product UI shows a generated command in the future, verify it with `tfy --help` before using it.

## Declarative Apply

Use `tfy apply` for GitOps-style skill publishing. Before final apply, show:

- Target tenant and repository.
- Plain-English summary.
- Full YAML/diff.
- Exact command.

Then ask for explicit confirmation.

## Download Existing Skill

Use the Usage tab in the Skill Detail page or the dashboard export/download flow.

After download, inspect the files before editing.

## Attach Skill to Agent

Skill attachment happens from the Agent Playground UI:

```text
Agent Playground -> Skills -> select skill -> choose version -> optional Preload SKILL.md -> Save Agent
```

Use `truefoundry-agents` for the agent-side flow.

## Versioning and Access

- Skills live inside a Repository.
- Repository RBAC controls who can discover, use, and publish skill versions.
- Skills can be pinned by version when attached to agents.
- UI upload currently supports single-file `SKILL.md`; multi-file skills should use the dashboard/registry workflow or declarative apply when a manifest is available.

## Delete

Do not delete skills from the agent. If deletion is requested, direct the user to the Skills Registry UI.

</instructions>

<success_criteria>

- The user knows whether UI, dashboard/registry workflow, or apply is the right publish path.
- Single-file and multi-file skill flows are clearly separated.
- New versions are created intentionally.
- Skill attachment is routed through Agent Playground.
- Final publish/apply is confirmed before execution.

</success_criteria>
