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

## Capability Matrix

| User intent | Supported path | Notes |
|-------------|----------------|-------|
| Create a single-file skill | UI | Use the dashboard editor for `SKILL.md`. |
| Publish a reviewed `SKILL.md` | UI or `tfy apply` | Use `tfy apply` only when a valid `agent-skill` manifest is available. |
| Upload a multi-file bundle | Dashboard/registry workflow | Verify any generated command before running it. |
| Download a skill | Skill detail usage/export flow | Inspect downloaded files before editing. |
| Create a new version | Skill detail UI or apply workflow | Show changed content before publishing. |
| Attach a skill to an agent | Agent Playground | Use `truefoundry-agents` for agent-side changes. |

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

Before publishing a multi-file bundle, review:

- `SKILL.md` frontmatter has a focused `name`, action-oriented `description`, compatibility, and minimal `allowed-tools`.
- Instructions are sequential and specific.
- Large reference material lives in `references/` and is linked from `SKILL.md`.
- Scripts live in `scripts/` and are preferred over long pasted command blocks.
- Secrets, tenant URLs, and raw tokens are not embedded in examples.
- Destructive actions are dashboard-only or require explicit user confirmation.

## Declarative Apply

Use `tfy apply` for GitOps-style skill publishing. Before final apply, show:

- Target tenant and repository.
- Plain-English summary.
- Full YAML/diff.
- Exact command.

Then ask for explicit confirmation.

If the manifest schema is unknown, stop at a reviewed draft and ask the user to publish through the UI or provide the product-generated manifest. Do not invent resource fields.

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
