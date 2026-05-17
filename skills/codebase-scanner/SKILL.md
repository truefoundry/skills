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
- Audit which LLM calls are NOT going through the gateway
- Generate migration plan to route all AI traffic through TFY
- Discover hardcoded API keys and move them to TFY Secrets
- Ensure every model in use is configured in the gateway

## When NOT to Use

- First-time setup -> `onboard` skill
- Just call a model through gateway -> `gateway` skill
- Deploy a self-hosted model -> Enterprise feature
- Configure guardrails -> `gateway` skill (Guardrails section)

</objective>

<context>

## How It Works

```
1. AUDIT       2. REPORT       3. CONFIGURE     4. MIGRATE      5. VERIFY
Scan for    →  Show findings →  Ensure models →  Apply code  →  Smoke test
LLM calls      with fixes      in gateway       changes        through GW
```

## What Gets Scanned

| Category | Patterns | Files |
|----------|----------|-------|
| OpenAI SDK | `OpenAI(`, `client.chat.completions.create` | `*.py`, `*.ts`, `*.js`, `*.tsx` |
| Anthropic | `Anthropic(`, `client.messages.create` | `*.py`, `*.ts`, `*.js` |
| Azure OpenAI | `AzureOpenAI(` | `*.py`, `*.ts`, `*.js` |
| LangChain | `ChatOpenAI(`, `ChatAnthropic(` | `*.py`, `*.ts`, `*.js` |
| LlamaIndex | `from llama_index.llms` | `*.py` |
| Vercel AI SDK | `createOpenAI(`, `generateText(` | `*.ts`, `*.tsx`, `*.js` |
| LiteLLM | `litellm.completion(` | `*.py` |
| MCP configs | `mcpServers`, `mcp.json` | `*.json`, `*.yaml`, `*.toml` |
| API keys | `sk-...`, `OPENAI_API_KEY` | `*.env*`, code files |
| Base URLs | `api.openai.com`, `OPENAI_BASE_URL` | All code files |

## Gateway Model ID Format

Models use `{provider_account_name}/{model_name}`: `openai-main/gpt-4o`, `anthropic-main/claude-sonnet-4-20250514`.

## Prerequisites

- Customer has completed `tfy login` (if not, use `onboard` first)
- `TFY_API_KEY` set for gateway calls
- `TFY_BASE_URL` set

</context>

<instructions>

## Phase 1: Audit

Scan the codebase comprehensively. Always exclude: `node_modules/`, `.venv/`, `__pycache__/`, `dist/`, `build/`, `.git/`, `vendor/`.

### 1.1 LLM SDK Imports

```bash
rg -n --type-add 'code:*.py' --type-add 'code:*.ts' --type-add 'code:*.js' --type-add 'code:*.tsx' --type-add 'code:*.jsx' \
  -t code '(from openai import|new OpenAI\(|OpenAI\()' .

rg -n -t code '(from anthropic import|new Anthropic\(|Anthropic\()' .

rg -n -t code '(AzureOpenAI\(|azure_endpoint)' .
```

### 1.2 Framework LLM Calls

```bash
rg -n -t code '(ChatOpenAI\(|ChatAnthropic\(|AzureChatOpenAI\(|from langchain)' .
rg -n -t py '(from llama_index\.llms|from llama_index\.core\.llms)' .
rg -n -t code '(createOpenAI\(|generateText\(|streamText\()' .
rg -n -t py '(litellm\.completion|litellm\.acompletion|from litellm)' .
```

### 1.3 Hardcoded Credentials

```bash
rg -n -t code '(sk-[a-zA-Z0-9]{20,}|sk-ant-[a-zA-Z0-9-]{20,})' .
rg -rn '(OPENAI_API_KEY|ANTHROPIC_API_KEY|AZURE_OPENAI_API_KEY|GROQ_API_KEY)' .
rg -rn '(api\.openai\.com|api\.anthropic\.com|api\.groq\.com)' .
```

### 1.4 MCP Configurations

```bash
rg -rn '(mcpServers|mcp_servers)' --include='*.json' --include='*.yaml' .
find . -name 'mcp.json' -o -name 'mcp_config.json' -o -name '.mcp.json' 2>/dev/null
```

### 1.5 Existing Gateway Usage

```bash
rg -rn '(gateway\.truefoundry|truefoundry\.cloud/api/llm|TFY_API_KEY|tfy-secret://)' .
```

---

## Phase 2: Generate Migration Report

Present findings grouped by category. See [references/migration-patterns.md](references/migration-patterns.md) for the full report template format.

Key sections: Summary (total sites, already routed, need migration), Critical credentials, LLM call sites table, MCP configs, models to configure, environment files, effort estimate.

---

## Phase 3: Configure Gateway

### 3.1 Check Existing Provider Accounts

```bash
TFY_API_SH="$(find ~/.claude/skills ~/.cursor/skills ~/.codex/skills -name tfy-api.sh 2>/dev/null | head -1)"
$TFY_API_SH GET /api/svc/v1/provider-accounts
```

### 3.2 Identify Gaps

Compare models in code against gateway config. Missing models need provider accounts or integrations added.

### 3.3 Generate & Apply Manifests

For provider manifest templates, see [references/provider-manifests.md](references/provider-manifests.md).

```bash
tfy apply -f provider-account-openai.yaml --dry-run --show-diff
tfy apply -f provider-account-openai.yaml
```

### 3.4 Store Keys in TFY Secrets

Never handle raw keys. Ask user to set as env vars, then create secret group via API. See `platform` skill (Secrets section).

---

## Phase 4: Apply Migration

**Always ask for confirmation before modifying files.**

For complete code change templates (Python, TypeScript, LangChain, LlamaIndex, Vercel AI, LiteLLM), model name strategies, and .gitignore updates, see [references/migration-code-patterns.md](references/migration-code-patterns.md).

Two model name strategies — always ask the customer:
- **A: Update names in code** — `"gpt-4o"` -> `"openai-main/gpt-4o"`
- **B: Virtual models** — gateway maps existing names, no code changes

---

## Phase 5: Verify

Smoke test through the gateway:

```bash
curl -s "${TFY_BASE_URL}/api/llm/chat/completions" \
  -H "Authorization: Bearer ${TFY_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"model": "openai-main/gpt-4o-mini", "messages": [{"role": "user", "content": "Say ok"}], "max_tokens": 5}'
```

For full Python verification script and post-migration report template, see [references/migration-code-patterns.md](references/migration-code-patterns.md).

</instructions>

<success_criteria>

- Complete audit with file/line references for all LLM call sites
- Migration report generated showing current state and required changes
- All models verified as configured in gateway (or manifests generated)
- Provider keys stored in TFY Secrets
- Code changes applied with user confirmation
- At least one smoke test succeeds through gateway
- No raw API keys visible in code, logs, or conversation

</success_criteria>

<references>

## References

- [migration-code-patterns.md](references/migration-code-patterns.md) — Code change templates, verification scripts, interaction guidelines
- [migration-patterns.md](references/migration-patterns.md) — Report format template
- [provider-manifests.md](references/provider-manifests.md) — Provider account YAML templates
- [cli-reference.md](references/cli-reference.md) — CLI commands reference
- [api-endpoints.md](references/api-endpoints.md) — REST API reference

## Provider Account Reference

| Provider | Account Type | Auth Type |
|----------|-------------|-----------|
| OpenAI | `provider-account/openai` | `api-key` |
| Anthropic | `provider-account/anthropic` | `api-key` |
| Google | `provider-account/google` | `api-key` |
| Azure OpenAI | `provider-account/azure` | `azure-auth` |
| AWS Bedrock | `provider-account/aws-bedrock` | `aws-irsa-auth` |
| Groq | `provider-account/groq` | `api-key` |
| Together AI | `provider-account/together-ai` | `api-key` |

## Composability

- **Gateway config**: `gateway` skill for routing, rate limits, guardrails
- **Secrets**: `platform` skill (Secrets section) for TFY secret groups
- **Onboarding**: `onboard` skill if no TFY account
- **MCP servers**: `mcp-servers` skill to register discovered MCP configs

</references>

<troubleshooting>

### No LLM Calls Found
Check: correct project root, code in subdirectory, framework not covered (tell me and I'll add patterns).

### 401 After Migration
Verify: TFY_API_KEY set to valid PAT/VAT, token not expired, VAT has model access.

### Model Not Found in Gateway
Options: add to existing provider account, create new provider account, create virtual model mapping.

### Large Monorepo
Ask which services/packages to scan. Scope the audit to specific directories.

### LiteLLM Already Used as Router
Options: replace with TFY Gateway, point LiteLLM at TFY Gateway (adds observability), keep LiteLLM for dev only.

</troubleshooting>
