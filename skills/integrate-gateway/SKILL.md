---
name: integrate-gateway
description: Integrates a codebase with TrueFoundry AI Gateway. Scans for all LLM calls, MCP configs, and credentials, diffs against existing gateway config, generates a migration plan, applies code changes, and verifies routing end-to-end. Invoked from within the customer's codebase.
license: MIT
compatibility: Requires Bash, curl, rg (ripgrep), and access to a TrueFoundry instance
allowed-tools: Bash(*/tfy-api.sh *) Bash(curl*) Bash(python*) Bash(grep*) Bash(find*) Bash(rg*) Bash(tfy*) Bash(*/scan.sh *) Bash(*/verify-gateway.sh *)
---

<objective>

# Integrate Gateway

Integrate the current codebase with TrueFoundry AI Gateway. This skill runs inside the customer's repo and has full filesystem access — use it for deep analysis, not surface scanning.

## When to Use

- Customer has a TFY account and wants to route AI traffic through the gateway
- Audit which LLM calls bypass the gateway
- Migrate hardcoded credentials to TFY Secrets
- Ensure every model in use is configured in the gateway
- Customer says "integrate", "connect to gateway", "route through TrueFoundry", "audit my AI calls"

## When NOT to Use

- No TFY account yet -> `onboard` skill first
- Just wants to call a model -> `gateway` skill
- Wants to configure routing/guardrails without migration -> `gateway` skill
- Wants to deploy a model -> Enterprise feature

</objective>

<context>

## What This Skill Does That Others Don't

This skill has the codebase. It can:
- Read actual source files to understand how clients are instantiated
- Trace env var references to `.env` files and docker-compose configs
- Detect whether code uses env vars (easy migration) or hardcodes values (needs edits)
- Identify the framework stack (bare SDK vs LangChain vs LlamaIndex vs Vercel AI)
- Check if `.env` is gitignored before any key operations
- Detect monorepo structure and scope appropriately
- Find model names used across the codebase for virtual model planning
- Read existing CI/CD configs to understand deployment flow

## Integration Flow

```
1. PREFLIGHT     2. SCAN         3. DIFF          4. PLAN         5. APPLY        6. VERIFY
Check login   →  Find all AI  →  Compare with →  Present     →  Make changes → Smoke test
& .env safety    call sites      gateway state    migration      (with conf)    each model
```

## Gateway Model ID Format

Models in the gateway use `{provider_account_name}/{model_name}`:
- `openai-main/gpt-4o` (not `gpt-4o`)
- `anthropic-main/claude-sonnet-4-20250514` (not `claude-sonnet-4-20250514`)

Virtual models allow keeping original names — gateway handles the mapping.

</context>

<instructions>

## Phase 1: Preflight

Before touching anything, verify safety:

```bash
# 1. Check TFY login exists
python3 -c "
import json; from pathlib import Path
d = json.loads((Path.home()/'.truefoundry'/'credentials.json').read_text())
host = d.get('host') or d.get('base_url') or ''
token = d.get('access_token') or d.get('refresh_token') or ''
print(f'tfy login: {\"ok (\" + host + \")\" if host and token else \"missing\"}')" 2>/dev/null || echo "tfy login: missing"

# 2. Check .env is gitignored (CRITICAL — before any key operations)
if [ -f .env ]; then
  git check-ignore .env >/dev/null 2>&1 && echo ".env: gitignored (safe)" || echo ".env: NOT GITIGNORED — fix this first"
fi

# 3. Check TFY env vars
echo "TFY_BASE_URL: ${TFY_BASE_URL:-(not set)}"
echo "TFY_API_KEY: ${TFY_API_KEY:+(set)}${TFY_API_KEY:-(not set)}"
```

**Stop if:**
- `tfy login: missing` -> use `onboard` skill
- `.env: NOT GITIGNORED` -> fix `.gitignore` before proceeding
- `TFY_API_KEY: (not set)` -> user needs a PAT from dashboard

## Phase 2: Deep Scan

Run the scanner script for structured output:

```bash
scripts/scan.sh . --skip-tests
```

Then go deeper — read the actual files to understand patterns:

### 2.1 Understand Client Instantiation

For each LLM call site found, read the surrounding code to classify:

| Pattern | Effort | Migration |
|---------|--------|-----------|
| `OpenAI()` — no args, reads env | **None** | Just update env vars |
| `OpenAI(api_key=os.environ["X"])` — key from env, no base_url | **Low** | Add `OPENAI_BASE_URL` to env |
| `OpenAI(api_key="sk-...", base_url="...")` — hardcoded | **Medium** | Rewrite to use env vars |
| `ChatOpenAI(model="gpt-4o")` — framework with params | **Medium** | Add base_url or set env |
| Multiple providers with different keys | **High** | Consolidate to single TFY PAT |

### 2.2 Trace the Dependency Chain

```bash
# Where do env vars get set?
rg -rn 'OPENAI_API_KEY|OPENAI_BASE_URL' --include='*.env*' --include='docker-compose*' --include='*.yaml' --include='*.yml' .

# CI/CD pipeline env injection?
find . -name '*.yml' -path '*/.github/*' -exec grep -l 'OPENAI\|ANTHROPIC\|LLM' {} \;
find . -name 'Dockerfile*' -exec grep -l 'OPENAI\|ANTHROPIC\|API_KEY' {} \;
```

### 2.3 Detect Framework & Architecture

```bash
# Package manager files reveal the stack
cat package.json 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin).get('dependencies',{}); [print(k) for k in d if 'openai' in k or 'anthropic' in k or 'ai-sdk' in k or 'langchain' in k]" 2>/dev/null
cat requirements.txt 2>/dev/null | grep -i 'openai\|anthropic\|langchain\|llama.index\|litellm' 2>/dev/null
cat pyproject.toml 2>/dev/null | grep -i 'openai\|anthropic\|langchain\|llama.index\|litellm' 2>/dev/null
```

## Phase 3: Diff Against Gateway

Compare what the codebase uses against what's already configured:

```bash
TFY_API_SH="$(find ~/.claude/skills ~/.cursor/skills ~/.codex/skills -name tfy-api.sh 2>/dev/null | head -1)"

# What's already in the gateway?
$TFY_API_SH GET /api/svc/v1/provider-accounts

# What models are callable?
curl -s "${TFY_BASE_URL}/api/llm/models" -H "Authorization: Bearer ${TFY_API_KEY}" | python3 -c "import sys,json; [print(m['id']) for m in json.load(sys.stdin).get('data',[])]"
```

Produce a gap analysis:
- Models in code but NOT in gateway -> need provider account or integration
- Models in gateway but NOT in code -> already configured, no action
- Provider keys in `.env` but NOT in TFY Secrets -> need secret creation

## Phase 4: Present Migration Plan

Present findings as an actionable report. Format:

```
## Integration Summary

| Metric | Count |
|--------|-------|
| LLM call sites found | X |
| Already routed through TFY | Y |
| Need migration | Z |
| Hardcoded credentials (CRITICAL) | N |
| Models missing from gateway | M |

## Call Sites (by migration effort)

### No changes needed (env-var driven)
| File | Line | SDK | Why it works already |
...

### Low effort (add env var)
| File | Line | SDK | What to add |
...

### Medium effort (code change)
| File | Line | SDK | Current → Required change |
...

## Gateway Gaps
| Model | Provider | Status | Action |
...

## Recommended approach:
- [ ] Strategy A or B for model names? (ask user)
- [ ] N env files to update
- [ ] M provider accounts to create
- [ ] Estimated: X minutes
```

**Ask for confirmation before proceeding to Phase 5.**

## Phase 5: Apply Changes

### 5.1 Store Provider Keys in TFY Secrets

Never handle raw keys. Tell the user:

> "Set your provider keys as environment variables, then I'll store them in TFY Secrets:
> `! export OPENAI_API_KEY=<your-key>`"

Then create secret group:
```bash
$TFY_API_SH POST /api/svc/v1/secret-groups "$payload"
```

### 5.2 Create Missing Provider Accounts

For templates, see [references/provider-manifests.md](references/provider-manifests.md).

```bash
tfy apply -f provider-account.yaml --dry-run --show-diff
tfy apply -f provider-account.yaml
```

### 5.3 Create Virtual Models (if Strategy B)

If user chose "keep existing model names", create virtual model routing config. See `gateway` skill [references/calling-models.md] for `gateway-load-balancing-config` manifest.

### 5.4 Update Environment Files

Replace provider keys with TFY PAT and add base URL:

```bash
# .env — always use TFY_BASE_URL, never hardcode gateway.truefoundry.ai
OPENAI_API_KEY=<tfy-pat>
OPENAI_BASE_URL=${TFY_BASE_URL}/api/llm
```

**Safety:** Keep original `.env` backed up. Original provider keys are now in TFY Secrets — confirm they're accessible before removing from `.env`.

### 5.5 Apply Code Changes (if needed)

For complete before/after patterns per framework, see [references/migration-code-patterns.md](references/migration-code-patterns.md).

**Always ask for confirmation before modifying source files.**

### 5.6 Update .gitignore

```bash
grep -q '^\.env$' .gitignore 2>/dev/null || echo '.env' >> .gitignore
grep -q '^\.env\.local$' .gitignore 2>/dev/null || echo '.env.local' >> .gitignore
```

## Phase 6: Verify

Test each model found in the codebase:

```bash
scripts/verify-gateway.sh "openai-main/gpt-4o-mini"
```

Or if using virtual models (Strategy B):
```bash
scripts/verify-gateway.sh "gpt-4o-mini"
```

Present final status:

```
## Integration Complete

| Model | Status | Latency |
|-------|--------|---------|
| openai-main/gpt-4o | OK | 1.2s |
| anthropic-main/claude-sonnet | OK | 0.8s |

What's now active:
- Cost tracking in TFY dashboard → AI Gateway → Observability
- Request traces with latency, tokens, cost per call
- Budget controls and rate limiting available

Next steps:
- [ ] Set up budget alerts (gateway skill)
- [ ] Add guardrails for content safety
- [ ] Create production VAT for deployed services
- [ ] Configure CI/CD to use TFY_API_KEY secret
```

</instructions>

<success_criteria>

- Preflight confirms login, .env safety, and API key availability
- Deep scan identifies all LLM call sites with file/line/pattern classification
- Gap analysis shows exactly what's missing from gateway config
- Migration plan presented with effort estimates before any changes
- User confirms before any file modifications
- Provider keys stored in TFY Secrets (never in conversation)
- All models verified working through gateway
- Original provider keys confirmed accessible in TFY Secrets before removal from .env

</success_criteria>

<references>

## References

- [migration-code-patterns.md](references/migration-code-patterns.md) — Before/after code patterns per framework, verification scripts
- [migration-patterns.md](references/migration-patterns.md) — Full migration pattern reference with decision matrix
- [provider-manifests.md](references/provider-manifests.md) — Provider account YAML templates
- [cli-reference.md](references/cli-reference.md) — CLI commands (`tfy apply`, `tfy login`)
- [api-endpoints.md](references/api-endpoints.md) — REST API reference

## Scripts

- `scripts/scan.sh [dir] [--skip-tests]` — Structured codebase scan (run first)
- `scripts/verify-gateway.sh [model_id]` — Smoke test a model through the gateway

## Composability

- **Gateway config**: `gateway` skill for routing, rate limits, guardrails, virtual models
- **Secrets**: `platform` skill (Secrets section) for advanced secret management
- **MCP servers**: `mcp-servers` skill to register discovered MCP configs in the registry
- **Onboarding**: `onboard` skill if customer has no TFY account

</references>

<troubleshooting>

### .env Not Gitignored
STOP. Fix this before any key operations: `echo '.env' >> .gitignore && git add .gitignore`

### tfy login Missing
Use `onboard` skill. Do not proceed with integration.

### No LLM Calls Found
Check: correct project root? Code in subdirectory? Try `scripts/scan.sh ./src`. Ask if framework isn't covered.

### Model Not Found After Provider Account Creation
Verify: integration has correct `model_types`, collaborators include `team:everyone`, provider account status is active.

### 401 After Migration
Check: TFY_API_KEY set to valid PAT/VAT, OPENAI_BASE_URL points to `${TFY_BASE_URL}/api/llm` (not hardcoded gateway URL).

### Original Keys Lost
Keys should remain in TFY Secrets. Check: `$TFY_API_SH GET /api/svc/v1/secret-groups` and verify the group exists.

### Monorepo — Scan Too Broad
Ask which services to scan. Scope: `scripts/scan.sh ./services/api --skip-tests`

### LiteLLM Already Used as Router
Options: (1) replace with TFY Gateway, (2) point LiteLLM at gateway for observability, (3) keep LiteLLM for dev only.

</troubleshooting>
