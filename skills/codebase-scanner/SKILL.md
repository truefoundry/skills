---
name: truefoundry-codebase-scanner
description: Audits a codebase to find all LLM and MCP calls, generates a migration report, and helps route everything through TrueFoundry AI Gateway. Post-sales tool for maximizing gateway adoption.
license: MIT
compatibility: Requires Bash, curl, and access to a TrueFoundry instance
allowed-tools: Bash(*/tfy-api.sh *) Bash(curl*) Bash(python*) Bash(grep*) Bash(find*) Bash(rg*) Bash(tfy*)
---

<objective>

# Codebase Scanner

Audit a customer's codebase to find every LLM call, MCP configuration, and hardcoded credential, then migrate them to route through TrueFoundry AI Gateway.

## When to Use

- Post-sales: customer has TFY account and wants full gateway adoption
- Customer wants to audit which LLM calls are NOT going through the gateway
- Customer wants a migration plan to route all AI traffic through TFY
- Customer wants to discover hardcoded API keys and move them to TFY Secrets
- Customer wants to ensure every model they use is configured in the gateway

## When NOT to Use

- First-time setup with no TFY account yet -> prefer `onboard` skill
- Just wants to call a model through the gateway -> prefer `gateway` skill
- Wants to deploy a self-hosted model -> Enterprise feature
- Wants to configure guardrails -> prefer `gateway` skill (Guardrails section)

</objective>

<context>

## How It Works

```
┌─────────────────────────────────────────────────────────────────────┐
│  1. AUDIT          2. REPORT         3. CONFIGURE     4. MIGRATE    │
│                                                                     │
│  Scan codebase  →  Show findings  →  Ensure models  → Apply        │
│  for LLM calls     with fixes        are in gateway    code changes │
│  MCP configs       per finding       Store secrets     Update envs  │
│  Hardcoded keys                      Gen manifests                  │
│                                                                     │
│                           5. VERIFY                                  │
│                     Smoke test through gateway                       │
└─────────────────────────────────────────────────────────────────────┘
```

## What Gets Scanned

| Category | Patterns | Files |
|----------|----------|-------|
| OpenAI SDK | `OpenAI(`, `openai.ChatCompletion`, `client.chat.completions.create` | `*.py`, `*.ts`, `*.js`, `*.jsx`, `*.tsx` |
| Anthropic SDK | `Anthropic(`, `anthropic.messages.create`, `client.messages.create` | `*.py`, `*.ts`, `*.js` |
| Azure OpenAI | `AzureOpenAI(`, `azure.openai` | `*.py`, `*.ts`, `*.js` |
| LangChain | `ChatOpenAI(`, `ChatAnthropic(`, `AzureChatOpenAI(`, `ChatGoogleGenerativeAI(` | `*.py`, `*.ts`, `*.js` |
| LlamaIndex | `from llama_index.llms`, `OpenAI(` in llama context | `*.py` |
| Vercel AI SDK | `createOpenAI(`, `createAnthropic(`, `generateText(`, `streamText(` | `*.ts`, `*.tsx`, `*.js` |
| LiteLLM | `litellm.completion(`, `litellm.acompletion(` | `*.py` |
| MCP configs | `mcpServers`, `mcp.json`, `mcp_servers` | `*.json`, `*.yaml`, `*.yml`, `*.toml` |
| API keys | `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `sk-...`, `sk-ant-...` | `*.env*`, `*.py`, `*.ts`, `*.js`, `*.yaml`, `*.yml`, `*.toml`, `*.json` |
| Base URLs | `OPENAI_BASE_URL`, `api.openai.com`, `api.anthropic.com` | All code files |

## Gateway Model ID Format

Models in TFY gateway use `{provider_account_name}/{model_name}`:
- `openai-main/gpt-4o` (not `gpt-4o`)
- `anthropic-main/claude-sonnet-4-20250514` (not `claude-sonnet-4-20250514`)

Or with virtual models, the customer can keep their existing model names and the gateway routes them.

## Prerequisites

- Customer has completed `tfy login`; if not, use `onboard` first
- Customer has a TFY API key (`TFY_API_KEY`) for Gateway model calls
- Customer has gateway access (`TFY_BASE_URL` or `https://gateway.truefoundry.ai`)
- This skill operates on the codebase in the current working directory

</context>

<instructions>

## Phase 1: Audit

Run a comprehensive scan of the codebase. Execute these searches and collect all findings.

### 1.1 Find LLM SDK Imports and Client Instantiation

```bash
# OpenAI SDK usage
rg -n --type-add 'code:*.py' --type-add 'code:*.ts' --type-add 'code:*.js' --type-add 'code:*.tsx' --type-add 'code:*.jsx' \
  -t code '(from openai import|import openai|new OpenAI\(|OpenAI\()' .

# Anthropic SDK usage
rg -n --type-add 'code:*.py' --type-add 'code:*.ts' --type-add 'code:*.js' \
  -t code '(from anthropic import|import anthropic|new Anthropic\(|Anthropic\()' .

# Azure OpenAI
rg -n --type-add 'code:*.py' --type-add 'code:*.ts' --type-add 'code:*.js' \
  -t code '(AzureOpenAI\(|from openai import AzureOpenAI|azure_endpoint)' .

# Google/Gemini
rg -n --type-add 'code:*.py' --type-add 'code:*.ts' --type-add 'code:*.js' \
  -t code '(genai\.GenerativeModel|ChatGoogleGenerativeAI|google\.generativeai)' .
```

### 1.2 Find Framework LLM Calls

```bash
# LangChain
rg -n --type-add 'code:*.py' --type-add 'code:*.ts' --type-add 'code:*.js' \
  -t code '(ChatOpenAI\(|ChatAnthropic\(|AzureChatOpenAI\(|ChatGoogleGenerativeAI\(|from langchain)' .

# LlamaIndex
rg -n -t py '(from llama_index\.llms|from llama_index\.core\.llms)' .

# Vercel AI SDK
rg -n --type-add 'code:*.ts' --type-add 'code:*.tsx' --type-add 'code:*.js' \
  -t code '(createOpenAI\(|createAnthropic\(|generateText\(|streamText\(|from .ai/openai|from .ai/anthropic)' .

# LiteLLM
rg -n -t py '(litellm\.completion|litellm\.acompletion|litellm\.embedding|from litellm)' .
```

### 1.3 Find Hardcoded Credentials and Base URLs

```bash
# API keys in code (not .env files)
rg -n --type-add 'code:*.py' --type-add 'code:*.ts' --type-add 'code:*.js' --type-add 'code:*.tsx' --type-add 'code:*.jsx' \
  -t code '(sk-[a-zA-Z0-9]{20,}|sk-ant-[a-zA-Z0-9-]{20,}|sk-proj-[a-zA-Z0-9-]{20,})' .

# API key env var references
rg -rn '(OPENAI_API_KEY|ANTHROPIC_API_KEY|AZURE_OPENAI_API_KEY|GOOGLE_API_KEY|GROQ_API_KEY|TOGETHER_API_KEY)' \
  --include='*.env*' --include='*.py' --include='*.ts' --include='*.js' --include='*.yaml' --include='*.yml' --include='*.toml' .

# Hardcoded base URLs (direct provider endpoints)
rg -rn '(api\.openai\.com|api\.anthropic\.com|generativelanguage\.googleapis\.com|api\.groq\.com|api\.together\.xyz)' \
  --include='*.py' --include='*.ts' --include='*.js' --include='*.yaml' --include='*.yml' --include='*.env*' .

# OPENAI_BASE_URL / base_url settings
rg -rn '(OPENAI_BASE_URL|base_url|api_base|baseURL|openai_api_base)' \
  --include='*.py' --include='*.ts' --include='*.js' --include='*.env*' --include='*.yaml' --include='*.yml' .
```

### 1.4 Find MCP Configurations

```bash
# MCP server configs
rg -rn '(mcpServers|mcp_servers|mcp-servers)' \
  --include='*.json' --include='*.yaml' --include='*.yml' --include='*.toml' .

# MCP config files
find . -name 'mcp.json' -o -name 'mcp_config.json' -o -name '.mcp.json' -o -name 'mcp.yaml' 2>/dev/null

# Claude Desktop / Cursor MCP configs
find . -name 'claude_desktop_config.json' -o -name '.cursor-mcp.json' 2>/dev/null
```

### 1.5 Find Model Name References

```bash
# Specific model names used in code
rg -n '(gpt-4o|gpt-4o-mini|gpt-4-turbo|gpt-3.5-turbo|claude-3|claude-sonnet|claude-opus|claude-haiku|gemini-pro|gemini-1.5|llama-3|mixtral)' \
  --include='*.py' --include='*.ts' --include='*.js' --include='*.yaml' --include='*.yml' --include='*.env*' .
```

### 1.6 Detect Existing Gateway Usage

```bash
# Already routing through TFY?
rg -rn '(gateway\.truefoundry|truefoundry\.cloud/api/llm|TFY_API_KEY|tfy-secret://)' .
```

---

## Phase 2: Generate Migration Report

After scanning, present findings in a structured report. Group by category and prioritize.

### Report Format

```markdown
# TrueFoundry Gateway Migration Report

## Summary
- **Total LLM call sites found:** X
- **Already routed through TFY:** Y
- **Need migration:** Z
- **Hardcoded credentials found:** N (CRITICAL)
- **MCP configurations found:** M
- **Unique models in use:** [list]
- **Unique providers in use:** [list]

## Critical: Hardcoded Credentials
| # | File | Line | Type | Action |
|---|------|------|------|--------|
| 1 | src/agent.py | 42 | OpenAI API key literal | Move to TFY Secrets, use env var |

## LLM Call Sites
| # | File | Line | SDK/Framework | Current Config | Migration Action |
|---|------|------|---------------|----------------|------------------|
| 1 | src/agent.py | 15 | OpenAI SDK | `OpenAI(api_key=os.environ["OPENAI_API_KEY"])` | Set `OPENAI_BASE_URL` env var, swap key to TFY PAT |
| 2 | src/chain.py | 8 | LangChain | `ChatOpenAI(model="gpt-4o")` | Add `base_url` param or set env var, prefix model |
| 3 | lib/embed.ts | 22 | OpenAI Node | `new OpenAI({ apiKey: process.env.OPENAI_API_KEY })` | Add `baseURL` or set env var |

## MCP Configurations
| # | File | Config | Action |
|---|------|--------|--------|
| 1 | .mcp.json | 3 servers | Register in TFY MCP registry for access control |

## Models to Configure in Gateway
| Model | Provider | Currently Configured? | Action |
|-------|----------|----------------------|--------|
| gpt-4o | OpenAI | Check | Ensure in provider account |
| claude-sonnet-4-20250514 | Anthropic | Check | Ensure in provider account |

## Environment Files
| File | Variables | Action |
|------|-----------|--------|
| .env | OPENAI_API_KEY, OPENAI_BASE_URL | Update base URL, swap key to TFY PAT |
| .env.production | OPENAI_API_KEY | Add OPENAI_BASE_URL, swap key |

## Migration Effort Estimate
- **Low effort (env var swap only):** X call sites
- **Medium effort (add base_url param):** Y call sites
- **High effort (model name changes):** Z call sites
```

---

## Phase 3: Configure Gateway

After the report, help the customer ensure their gateway has everything needed.

### 3.1 Check Existing Provider Accounts

```bash
TFY_API_SH="$(find ~/.claude/skills ~/.cursor/skills ~/.codex/skills -name tfy-api.sh 2>/dev/null | head -1)"
# Or use the skill's own script:
# TFY_API_SH=./scripts/tfy-api.sh

$TFY_API_SH GET /api/svc/v1/provider-accounts
```

Parse the response to see which providers and models are already configured.

### 3.2 Identify Gaps

Compare models found in the codebase against models configured in the gateway:
- Models in code but NOT in gateway -> need provider account or integration added
- Provider keys referenced in code but not stored in TFY Secrets -> need secret creation

### 3.3 Generate Provider Account Manifests (if needed)

For each missing provider, generate a manifest:

**OpenAI:**
```yaml
name: openai-main
type: provider-account/openai
collaborators:
  - role_id: provider-account-access
    subject: team:everyone
auth_data:
  api_key: tfy-secret://TENANT:llm-keys:OPENAI_API_KEY
  type: api-key
integrations:
  - cost:
      metric: public_cost
    name: gpt-4o
    type: integration/model/openai
    model_id: gpt-4o
    model_types:
      - chat
  # ... add each model found in the codebase
```

**Anthropic:**
```yaml
name: anthropic-main
type: provider-account/anthropic
collaborators:
  - role_id: provider-account-access
    subject: team:everyone
auth_data:
  api_key: tfy-secret://TENANT:llm-keys:ANTHROPIC_API_KEY
  type: api-key
integrations:
  - cost:
      metric: public_cost
    name: claude-sonnet-4-20250514
    type: integration/model/anthropic
    model_id: claude-sonnet-4-20250514
    model_types:
      - chat
```

**Google Gemini:**
```yaml
name: gemini-main
type: provider-account/google
collaborators:
  - role_id: provider-account-access
    subject: team:everyone
auth_data:
  api_key: tfy-secret://TENANT:llm-keys:GOOGLE_API_KEY
  type: api-key
integrations:
  - cost:
      metric: public_cost
    name: gemini-2.5-pro
    type: integration/model/google
    model_id: gemini-2.5-pro
    model_types:
      - chat
```

### 3.4 Store Provider Keys in TFY Secrets

Guide the user to store their provider API keys. The agent must NEVER handle raw keys.

Ask: **"I need to store your provider API keys in TrueFoundry Secrets. Please set them as environment variables first:"**

```bash
export OPENAI_API_KEY="your-key"
export ANTHROPIC_API_KEY="your-key"
```

Then create the secret group:
```bash
$TFY_API_SH POST /api/svc/v1/secret-groups \
  '{"name": "llm-keys", "type": "internal", "secrets": [
    {"key": "OPENAI_API_KEY", "value": "'"$OPENAI_API_KEY"'"},
    {"key": "ANTHROPIC_API_KEY", "value": "'"$ANTHROPIC_API_KEY"'"}
  ]}'
```

### 3.5 Apply Provider Account Manifests

```bash
tfy apply -f provider-account-openai.yaml --dry-run --show-diff
tfy apply -f provider-account-openai.yaml
```

---

## Phase 4: Apply Migration

Present the migration as a set of code changes. **Always ask for confirmation before modifying files.**

### 4.1 Environment-Only Migration (Lowest effort)

If the code already reads from env vars and does not hardcode base URLs:

```bash
# Update .env
cat >> .env << 'EOF'

# TrueFoundry AI Gateway
OPENAI_BASE_URL=https://gateway.truefoundry.ai
OPENAI_API_KEY=<tfy-pat-or-vat>
EOF
```

For Anthropic SDK:
```bash
cat >> .env << 'EOF'
ANTHROPIC_BASE_URL=https://gateway.truefoundry.ai
ANTHROPIC_API_KEY=<tfy-pat-or-vat>
EOF
```

### 4.2 Code Changes for Hardcoded Configs

**Python OpenAI SDK — remove hardcoded params:**
```python
# Before
client = OpenAI(
    api_key="sk-...",
    base_url="https://api.openai.com/v1"
)

# After — reads from OPENAI_BASE_URL and OPENAI_API_KEY env vars
client = OpenAI()
```

**Python OpenAI SDK — add base_url for gateway:**
```python
# Before
client = OpenAI(api_key=os.environ["OPENAI_API_KEY"])

# After
client = OpenAI(
    api_key=os.environ["TFY_API_KEY"],
    base_url=os.environ.get("TFY_GATEWAY_URL", "https://gateway.truefoundry.ai"),
)
```

**TypeScript/Node OpenAI SDK:**
```typescript
// Before
const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

// After — env vars handle routing
const client = new OpenAI();
// Or explicit:
const client = new OpenAI({
  apiKey: process.env.TFY_API_KEY,
  baseURL: process.env.OPENAI_BASE_URL || "https://gateway.truefoundry.ai",
});
```

**LangChain Python:**
```python
# Before
llm = ChatOpenAI(model="gpt-4o", api_key=os.environ["OPENAI_API_KEY"])

# After
llm = ChatOpenAI(
    model="openai-main/gpt-4o",
    api_key=os.environ["TFY_API_KEY"],
    base_url="https://gateway.truefoundry.ai",
)
# Or: set OPENAI_BASE_URL env var and use:
llm = ChatOpenAI(model="openai-main/gpt-4o")
```

**LlamaIndex:**
```python
# Before
from llama_index.llms.openai import OpenAI
llm = OpenAI(model="gpt-4o", api_key="sk-...")

# After
llm = OpenAI(
    model="openai-main/gpt-4o",
    api_key=os.environ["TFY_API_KEY"],
    api_base="https://gateway.truefoundry.ai",
)
```

**Vercel AI SDK:**
```typescript
// Before
import { createOpenAI } from "@ai-sdk/openai";
const openai = createOpenAI({ apiKey: process.env.OPENAI_API_KEY });

// After
const openai = createOpenAI({
  apiKey: process.env.TFY_API_KEY,
  baseURL: process.env.OPENAI_BASE_URL || "https://gateway.truefoundry.ai",
});
```

**LiteLLM:**
```python
# LiteLLM supports OPENAI_BASE_URL natively — just set env vars
# Or configure litellm proxy config:
import litellm
litellm.api_base = os.environ.get("TFY_GATEWAY_URL", "https://gateway.truefoundry.ai")
litellm.api_key = os.environ["TFY_API_KEY"]
```

### 4.3 Model Name Updates

Two strategies — choose based on customer preference:

**Strategy A: Update model names in code (explicit)**
- `"gpt-4o"` -> `"openai-main/gpt-4o"`
- `"claude-sonnet-4-20250514"` -> `"anthropic-main/claude-sonnet-4-20250514"`

**Strategy B: Create virtual models in gateway (no code changes)**
- Create virtual model `gpt-4o` that maps to `openai-main/gpt-4o`
- Existing model strings work unchanged
- Better for large codebases, but adds gateway config complexity

Ask the customer: **"Would you prefer to (A) update model names in code to use the gateway format, or (B) create virtual models so your existing model names work unchanged?"**

### 4.4 Update .gitignore

Ensure secrets are not committed:
```bash
# Add if not present
grep -q '.env' .gitignore 2>/dev/null || echo '.env' >> .gitignore
grep -q '.env.local' .gitignore 2>/dev/null || echo '.env.local' >> .gitignore
```

---

## Phase 5: Verify

Run a smoke test to confirm the migration works.

### 5.1 Python Verification

```python
import os
from openai import OpenAI

client = OpenAI(
    api_key=os.environ.get("OPENAI_API_KEY") or os.environ.get("TFY_API_KEY"),
    base_url=os.environ.get("OPENAI_BASE_URL", "https://gateway.truefoundry.ai"),
)

# Test each model found in the codebase
models_to_test = ["openai-main/gpt-4o-mini"]  # adjust per findings

for model in models_to_test:
    try:
        response = client.chat.completions.create(
            model=model,
            messages=[{"role": "user", "content": "Say 'ok' and nothing else."}],
            max_tokens=5,
        )
        print(f"  {model}: {response.choices[0].message.content} (tokens: {response.usage.total_tokens})")
    except Exception as e:
        print(f"  {model}: FAILED - {e}")
```

### 5.2 cURL Verification

```bash
curl -s "${OPENAI_BASE_URL:-https://gateway.truefoundry.ai}/chat/completions" \
  -H "Authorization: Bearer ${OPENAI_API_KEY:-$TFY_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"model": "openai-main/gpt-4o-mini", "messages": [{"role": "user", "content": "Say ok"}], "max_tokens": 5}' \
  | python3 -c "import sys,json; r=json.load(sys.stdin); print(f'Model: {r[\"model\"]}  Response: {r[\"choices\"][0][\"message\"][\"content\"]}')"
```

### 5.3 Post-Migration Report

```markdown
# Migration Complete

## Routing Status
- **Total call sites migrated:** X/Y
- **Models verified through gateway:** [list with status]
- **Remaining manual items:** [if any]

## What's Now Active
- Cost tracking: https://app.truefoundry.com -> AI Gateway -> Observability
- Request traces: Every call logged with latency, tokens, cost
- Model switching: Change routing config, no code deploy needed
- Budget controls: Set limits in dashboard

## Next Steps
- [ ] Set up budget alerts (gateway skill)
- [ ] Configure rate limits per user/team
- [ ] Add guardrails for content safety
- [ ] Create virtual models for load balancing / fallback
- [ ] Set up production VAT (instead of PAT) for deployed services
```

---

## Interaction Guidelines

1. **Always scan before recommending changes.** Never assume what's in the codebase.
2. **Present the report and ask for confirmation** before making any code changes.
3. **Offer both strategies** for model names (explicit prefix vs virtual models).
4. **Never echo or log API keys.** When the user provides a key, store it immediately.
5. **Check gateway config** before telling the user what models to add — some may already be there.
6. **Respect .gitignore patterns** — don't scan `node_modules/`, `.venv/`, `__pycache__/`, `dist/`, etc.
7. **Handle monorepos** — ask which service/package to scan if the repo contains multiple.
8. **Skip test files optionally** — ask if they want test mocks/fixtures included.

### Exclusion Patterns

Always exclude from scan:
```
node_modules/ .venv/ venv/ __pycache__/ dist/ build/ .git/ .next/ .nuxt/
*.min.js *.bundle.js *.map vendor/ third_party/
```

Use `rg` with `--glob '!node_modules'` or equivalent exclusions.

</instructions>

<success_criteria>

## Success Criteria

- Complete audit of all LLM call sites in the codebase with file/line references
- Migration report generated showing current state and required changes
- All models found in code are verified as configured in the gateway (or manifests generated)
- Provider API keys stored in TFY Secrets (not hardcoded)
- Code changes applied (with user confirmation) to route through gateway
- At least one smoke test request succeeds through the gateway
- User knows where to find cost tracking and traces in the dashboard
- No raw API keys visible in code, logs, or conversation

</success_criteria>

<references>

## Composability

- **Gateway config**: Use `gateway` skill after scan to configure routing, rate limits, guardrails
- **Secrets**: Use `platform` skill (Secrets section) to manage TFY secret groups
- **Provider accounts**: Use `gateway` skill to manage provider accounts after initial setup
- **Onboarding**: If customer has no TFY account yet, use `onboard` skill first
- **Observability**: Use `observability` skill to verify traces are flowing after migration
- **MCP servers**: Use `mcp-servers` skill to register discovered MCP servers

## Provider Account Reference

| Provider | Account Type | Integration Type | Auth Type |
|----------|-------------|-----------------|-----------|
| OpenAI | `provider-account/openai` | `integration/model/openai` | `api-key` |
| Anthropic | `provider-account/anthropic` | `integration/model/anthropic` | `api-key` |
| Google | `provider-account/google` | `integration/model/google` | `api-key` |
| Azure OpenAI | `provider-account/azure` | `integration/model/azure` | `azure-auth` |
| AWS Bedrock | `provider-account/aws-bedrock` | `integration/model/aws-bedrock` | `aws-irsa-auth` |
| Groq | `provider-account/groq` | `integration/model/groq` | `api-key` |
| Together AI | `provider-account/together-ai` | `integration/model/together-ai` | `api-key` |

## Model Name Mapping

Common model names and their gateway equivalents:

| Code Reference | Gateway Model ID |
|---------------|-----------------|
| `gpt-4o` | `openai-main/gpt-4o` |
| `gpt-4o-mini` | `openai-main/gpt-4o-mini` |
| `gpt-4-turbo` | `openai-main/gpt-4-turbo` |
| `claude-sonnet-4-20250514` | `anthropic-main/claude-sonnet-4-20250514` |
| `claude-opus-4-20250514` | `anthropic-main/claude-opus-4-20250514` |
| `gemini-2.5-pro` | `gemini-main/gemini-2.5-pro` |
| `llama-3.1-70b` | `together-main/llama-3.1-70b` |

Note: actual model IDs depend on the customer's provider account naming convention.

</references>

<troubleshooting>

## Error Handling

### No LLM Calls Found
```
No LLM SDK usage detected in this directory.
Check:
- Are you in the correct project root?
- Is the code in a subdirectory? Try specifying the path.
- Does the project use a framework not covered? (Tell me and I'll add patterns.)
```

### Gateway Returns 401 After Migration
```
Authentication failed after migration. Verify:
- TFY_API_KEY / OPENAI_API_KEY env var is set to a valid PAT or VAT
- The token has not expired
- For VATs: the token has access to the requested model
```

### Model Not Found in Gateway
```
The model used in code is not configured in the gateway.
Options:
1. Add it to an existing provider account (create integration)
2. Create a new provider account for this provider
3. Create a virtual model that maps the name
```

### Provider Key Already Exists in TFY Secrets
```
A secret with this key already exists. Options:
- Use existing secret reference in provider account
- Update the secret value (creates new version)
- Create a separate secret group for this project
```

### Mixed Direct and Gateway Calls
```
Some calls already go through the gateway while others are direct.
The report shows which are which. We'll migrate only the direct calls.
```

### Large Monorepo — Scan Too Broad
```
This looks like a monorepo. Which services/packages should I scan?
List the directories and I'll scope the audit.
```

### Code Uses LiteLLM as Router
```
LiteLLM detected as an existing router. Options:
1. Replace LiteLLM with TFY Gateway (handles same routing + adds observability)
2. Point LiteLLM's base_url at TFY Gateway (layer on observability only)
3. Keep LiteLLM for local dev, TFY Gateway for production
```

</troubleshooting>
