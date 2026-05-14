---
name: truefoundry-onboard
description: First-time setup for TrueFoundry AI Gateway. Authenticates via email+OTP or PAT, links LLM providers, configures coding agents (Claude Code, Codex, Cursor), and verifies end-to-end routing — all without leaving the terminal.
license: MIT
compatibility: Requires Bash, curl, and tfy CLI
allowed-tools: Bash(*/tfy-api.sh *) Bash(curl*) Bash(python*) Bash(tfy*) Bash(pip*) Bash(npm*) Bash(uv*) Bash(jq*)
---

<objective>

# TrueFoundry Gateway — Agent Onboarding

One control plane for every LLM call. Set up in under 2 minutes without leaving the terminal.

**What you get after running this skill:**
- Every LLM request tracked (cost, tokens, latency, full trace)
- Model switching without code changes
- Budget controls and rate limits
- One API key for all providers (OpenAI, Anthropic, Google, etc.)
- Your coding agent configured to use the gateway automatically

## When to Use

- Developer just signed up for TrueFoundry and wants to route LLM traffic through the gateway
- Developer wants to set up their coding agent (Claude Code, Codex, Cursor) with TrueFoundry
- Developer wants cost tracking or observability for LLM calls
- Developer wants a single API key across all LLM providers
- Developer says "set up TrueFoundry", "onboard me", "configure gateway"

## When NOT to Use

- Already configured, wants to manage routing/policies -> `gateway` skill
- Wants to deploy self-hosted models -> Enterprise feature
- Platform admin tasks -> `platform` skill

</objective>

<context>

## Architecture

```
Your code (no changes) -> TFY Gateway -> OpenAI / Anthropic / Azure / Gemini / Bedrock / 50+ providers
                              |
               Tracing - Cost tracking - Rate limits - Routing - Guardrails
```

## Gateway Endpoint

```
https://gateway.truefoundry.ai
```

## Model ID Format

```
{provider_account_name}/{model_name}
```

Examples:
- `openai-main/gpt-4o-mini`
- `openai-main/gpt-4o`
- `anthropic-main/claude-sonnet-4-20250514`
- `anthropic-main/claude-opus-4-20250514`
- `gemini-main/gemini-2.5-pro`

## Authentication

Standard Bearer token. Drop-in replacement for OpenAI SDK:

```bash
OPENAI_BASE_URL=https://gateway.truefoundry.ai
OPENAI_API_KEY=<truefoundry-pat-or-vat>
```

Works with any OpenAI-compatible client unchanged.

## Token Types

| Type | Tied to | Use for |
|------|---------|---------|
| **PAT** (Personal Access Token) | A user | Development, testing |
| **VAT** (Virtual Account Token) | A service identity | Production apps, CI/CD |

</context>

<instructions>

## Onboarding Flow

This is a wizard-style flow. The agent drives everything programmatically. The developer only needs to:
1. Provide their email (if new) or paste a PAT (if they have one)
2. Paste a one-time code from their email (if using email+OTP)
3. Paste their LLM provider API keys

Everything else is automated.

---

### Step 1: Detect existing state

```bash
# Check for existing credentials
printenv | grep -E "OPENAI_BASE_URL|TFY_API_KEY|TFY_BASE_URL" 2>/dev/null
grep -rsl "gateway.truefoundry" .env .env.local 2>/dev/null
cat ~/.truefoundry/credentials.json 2>/dev/null | jq -r '.host // empty'
```

**If gateway already configured** (base URL points to TFY + key exists) -> skip to Step 5 (verify).
**If TFY credentials exist** but gateway not pointed -> skip to Step 3.
**If nothing** -> proceed to Step 2.

---

### Step 2: Authenticate

The developer needs a TrueFoundry PAT. Offer two paths:

Ask: **"Do you have a TrueFoundry API key? If not, what's your email and I'll send a one-time code."**

#### Path A: Email + OTP (new users, preferred)

This is the agent-native signup flow. The developer never leaves the terminal.

```bash
# 1. Request OTP
curl -s -X POST https://app.truefoundry.com/api/auth/agent-bootstrap \
  -H "Content-Type: application/json" \
  -d '{"email": "developer@example.com"}'
```

Expected response: `{"status": "otp_sent", "message": "Check your email for a verification code"}`

Tell the developer: **"I sent a code to your email. Paste it here."**

```bash
# 2. Verify OTP and get PAT
curl -s -X POST https://app.truefoundry.com/api/auth/agent-bootstrap/verify \
  -H "Content-Type: application/json" \
  -d '{"email": "developer@example.com", "otp": "123456"}'
```

Expected response: `{"pat": "tfy-...", "tenant": "...", "user": "developer@example.com"}`

If the endpoint returns 404 (not yet deployed), fall back to Path B.

#### Path B: Existing PAT (users with accounts)

Ask: **"Paste your TrueFoundry API key (starts with tfy-)."**

**New user (no account):**
1. Sign up at https://www.truefoundry.com/register (one browser step)
2. After signup: Settings -> Access -> Personal Access Tokens -> create one
3. Paste it here

**Existing user:**
1. https://app.truefoundry.com -> Settings -> Access -> Personal Access Tokens
2. Create or copy existing token

**Alternative — CLI device flow:**
```bash
tfy login --host https://app.truefoundry.com
```
Opens browser for OAuth, stores token at `~/.truefoundry/credentials.json`.

#### After getting the PAT

Store and verify:
```bash
export TFY_API_KEY="<their-pat>"
export TFY_BASE_URL="https://app.truefoundry.com"
```

Verify it works:
```bash
curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $TFY_API_KEY" \
  "$TFY_BASE_URL/api/svc/v1/personal-access-tokens"
```

Should return `200`. If `401` -> key is invalid, ask them to regenerate.

Resolve tenant name (needed for secret references):
```bash
TENANT=$(curl -s -H "Authorization: Bearer $TFY_API_KEY" \
  "$TFY_BASE_URL/api/svc/v1/users/me" | jq -r '.tenantName // empty')

# Fallback: extract from base URL
if [ -z "$TENANT" ]; then
  TENANT=$(echo "$TFY_BASE_URL" | sed 's|https://||;s|\.truefoundry.*||')
fi
```

---

### Step 3: Link LLM providers

The gateway proxies requests to the developer's own provider accounts. Their API keys get stored as TFY secrets.

Ask: **"Which LLM providers do you use? (OpenAI, Anthropic, Google, Azure, Groq, Together AI, etc.)"**

Then for each provider, ask for their API key: **"Paste your [Provider] API key. I'll store it securely and configure routing."**

**Do NOT echo, log, or display the key.** Store it immediately.

**For each provider, the agent does three things automatically:**

#### a) Store the key as a TFY secret

```bash
# Get or create secret group
SECRET_GROUP_ID=$(curl -s -H "Authorization: Bearer $TFY_API_KEY" \
  "$TFY_BASE_URL/api/svc/v1/secret-groups" | jq -r '.data[] | select(.name=="llm-keys") | .id')

if [ -z "$SECRET_GROUP_ID" ]; then
  SECRET_GROUP_ID=$(curl -s -X POST \
    -H "Authorization: Bearer $TFY_API_KEY" \
    -H "Content-Type: application/json" \
    "$TFY_BASE_URL/api/svc/v1/secret-groups" \
    -d '{"name": "llm-keys", "type": "internal"}' | jq -r '.id')
fi

# Store the provider key (example: OpenAI)
curl -s -X PUT \
  -H "Authorization: Bearer $TFY_API_KEY" \
  -H "Content-Type: application/json" \
  "$TFY_BASE_URL/api/svc/v1/secret-groups/$SECRET_GROUP_ID" \
  -d '{"secrets": [{"key": "OPENAI_API_KEY", "value": "'"$PROVIDER_KEY"'"}]}'
```

#### b) Create provider account manifest

Write a YAML file for each provider. Default model selection per provider:

**OpenAI:**
```yaml
name: openai-main
type: provider-account/openai
collaborators:
  - role_id: provider-account-access
    subject: team:everyone
integrations:
  - name: gpt-4o-mini
    type: integration/model/openai
    model_types: [chat]
    auth_data:
      type: bearer-auth
      bearer_token: "tfy-secret://TENANT:llm-keys:OPENAI_API_KEY"
  - name: gpt-4o
    type: integration/model/openai
    model_types: [chat]
    auth_data:
      type: bearer-auth
      bearer_token: "tfy-secret://TENANT:llm-keys:OPENAI_API_KEY"
  - name: gpt-4.1
    type: integration/model/openai
    model_types: [chat]
    auth_data:
      type: bearer-auth
      bearer_token: "tfy-secret://TENANT:llm-keys:OPENAI_API_KEY"
  - name: gpt-4.1-mini
    type: integration/model/openai
    model_types: [chat]
    auth_data:
      type: bearer-auth
      bearer_token: "tfy-secret://TENANT:llm-keys:OPENAI_API_KEY"
```

**Anthropic:**
```yaml
name: anthropic-main
type: provider-account/openai
collaborators:
  - role_id: provider-account-access
    subject: team:everyone
integrations:
  - name: claude-sonnet-4-20250514
    type: integration/model/openai
    model_types: [chat]
    auth_data:
      type: bearer-auth
      bearer_token: "tfy-secret://TENANT:llm-keys:ANTHROPIC_API_KEY"
  - name: claude-opus-4-20250514
    type: integration/model/openai
    model_types: [chat]
    auth_data:
      type: bearer-auth
      bearer_token: "tfy-secret://TENANT:llm-keys:ANTHROPIC_API_KEY"
  - name: claude-haiku-3-5-20241022
    type: integration/model/openai
    model_types: [chat]
    auth_data:
      type: bearer-auth
      bearer_token: "tfy-secret://TENANT:llm-keys:ANTHROPIC_API_KEY"
```

**Google (Gemini):**
```yaml
name: gemini-main
type: provider-account/openai
collaborators:
  - role_id: provider-account-access
    subject: team:everyone
integrations:
  - name: gemini-2.5-pro
    type: integration/model/openai
    model_types: [chat]
    auth_data:
      type: bearer-auth
      bearer_token: "tfy-secret://TENANT:llm-keys:GOOGLE_API_KEY"
  - name: gemini-2.5-flash
    type: integration/model/openai
    model_types: [chat]
    auth_data:
      type: bearer-auth
      bearer_token: "tfy-secret://TENANT:llm-keys:GOOGLE_API_KEY"
```

Replace `TENANT` with the resolved tenant name from Step 2.

#### c) Apply

```bash
tfy apply -f provider-account.yaml --dry-run --show-diff
tfy apply -f provider-account.yaml
```

**Provider type reference:**

| Provider | `type` | Auth | Secret key |
|----------|--------|------|------------|
| OpenAI | `provider-account/openai` | bearer-auth | `OPENAI_API_KEY` |
| Anthropic | `provider-account/openai` | bearer-auth | `ANTHROPIC_API_KEY` |
| Google | `provider-account/openai` | bearer-auth | `GOOGLE_API_KEY` |
| Groq | `provider-account/groq` | bearer-auth | `GROQ_API_KEY` |
| Together AI | `provider-account/together-ai` | bearer-auth | `TOGETHER_API_KEY` |
| AWS Bedrock | `provider-account/aws-bedrock` | aws-irsa-auth | AWS credentials |
| Azure OpenAI | `provider-account/azure` | azure-auth | `AZURE_OPENAI_KEY` |

---

### Step 4: Configure project environment

Determine where to write config:
```bash
ls .env .env.local 2>/dev/null
```

Write to `.env` (or `.env.local` if that's what the project uses):

```bash
# TrueFoundry AI Gateway
OPENAI_BASE_URL=https://gateway.truefoundry.ai
OPENAI_API_KEY=<their-pat>
```

If the project also uses Anthropic SDK directly:
```bash
ANTHROPIC_BASE_URL=https://gateway.truefoundry.ai
ANTHROPIC_API_KEY=<their-pat>
```

Add `.env` to `.gitignore` if not already there:
```bash
grep -q '^\.env$' .gitignore 2>/dev/null || echo '.env' >> .gitignore
```

---

### Step 5: Configure coding agents

Ask: **"Which coding agents do you use? (Claude Code, Codex, Cursor, Windsurf, Cline)"**

Configure each selected agent to route through the gateway:

#### Claude Code

Write to `~/.claude/settings.json` (merge if exists):

```bash
# Read existing settings
SETTINGS_FILE="$HOME/.claude/settings.json"
mkdir -p "$(dirname "$SETTINGS_FILE")"

# Add env vars to Claude Code
python3 -c "
import json, os
path = os.path.expanduser('~/.claude/settings.json')
try:
    with open(path) as f:
        settings = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    settings = {}

settings.setdefault('env', {})
settings['env']['OPENAI_BASE_URL'] = 'https://gateway.truefoundry.ai'
settings['env']['OPENAI_API_KEY'] = '$TFY_API_KEY'
settings['env']['ANTHROPIC_BASE_URL'] = 'https://gateway.truefoundry.ai'
settings['env']['ANTHROPIC_API_KEY'] = '$TFY_API_KEY'

with open(path, 'w') as f:
    json.dump(settings, f, indent=2)
print('Claude Code configured.')
"
```

#### Codex CLI

Write to `~/.codex/config.toml`:

```bash
CONFIG_FILE="$HOME/.codex/config.toml"
mkdir -p "$(dirname "$CONFIG_FILE")"

# Append or create provider config
cat >> "$CONFIG_FILE" << 'EOF'

[providers.openai]
base_url = "https://gateway.truefoundry.ai"
api_key_env = "TFY_API_KEY"
EOF

echo "Codex CLI configured."
```

Also add to shell profile:
```bash
# Add TFY_API_KEY to shell rc if not already there
SHELL_RC="$HOME/.zshrc"
[ -f "$HOME/.bashrc" ] && SHELL_RC="$HOME/.bashrc"
grep -q 'TFY_API_KEY' "$SHELL_RC" 2>/dev/null || \
  echo "export TFY_API_KEY=\"$TFY_API_KEY\"" >> "$SHELL_RC"
```

#### Cursor

For Cursor, configure the OpenAI-compatible provider in settings:

```bash
CURSOR_SETTINGS="$HOME/.cursor/settings.json"
mkdir -p "$(dirname "$CURSOR_SETTINGS")"

python3 -c "
import json, os
path = os.path.expanduser('~/.cursor/settings.json')
try:
    with open(path) as f:
        settings = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    settings = {}

# Configure Cursor to use TFY gateway as OpenAI-compatible provider
settings.setdefault('openai', {})
settings['openai']['baseUrl'] = 'https://gateway.truefoundry.ai'
settings['openai']['apiKey'] = '$TFY_API_KEY'

with open(path, 'w') as f:
    json.dump(settings, f, indent=2)
print('Cursor configured.')
"
```

Also tell the user: **"In Cursor Settings -> Models -> OpenAI API Key, paste your TFY PAT. Set Base URL to `https://gateway.truefoundry.ai`."**

#### Windsurf / Cline

These use standard env vars. The `.env` from Step 4 handles it, or add to shell profile:

```bash
echo "export OPENAI_BASE_URL=https://gateway.truefoundry.ai" >> "$SHELL_RC"
echo "export OPENAI_API_KEY=$TFY_API_KEY" >> "$SHELL_RC"
```

---

### Step 6: Verify (smoke test)

Run a real LLM call through the gateway to confirm everything works:

```python
from openai import OpenAI
import os

client = OpenAI(
    api_key=os.environ.get("OPENAI_API_KEY", os.environ.get("TFY_API_KEY")),
    base_url="https://gateway.truefoundry.ai",
)

response = client.chat.completions.create(
    model="openai-main/gpt-4o-mini",  # adjust to match linked provider
    messages=[{"role": "user", "content": "Say 'hello' and nothing else."}],
    max_tokens=5,
)

print(f"Response: {response.choices[0].message.content}")
print(f"Model: {response.model}")
print(f"Tokens: {response.usage.prompt_tokens} in / {response.usage.completion_tokens} out")
```

Adjust `model` to match whatever provider they linked in Step 3.

If openai package is not installed:
```bash
pip install openai 2>/dev/null || uv pip install openai 2>/dev/null
```

---

### Step 7: Report success

On success, report:

```
Done! Your gateway is live.

What's working now:
  - Every LLM request tracked (cost, tokens, latency, full trace)
  - Dashboard: https://app.truefoundry.com -> AI Gateway -> Observability
  - Model switching: update routing config, no code deploys
  - Budget controls: set spend limits per user/team from the dashboard

Configured agents:
  - Claude Code: routing through gateway
  - [others as applicable]

Your models:
  - openai-main/gpt-4o-mini
  - openai-main/gpt-4o
  - [others as linked]

What I can do next:
  - Scan this codebase and route all LLM calls through the gateway
  - Set up a virtual model (load balance across providers, auto-fallback)
  - Add guardrails (PII filtering, prompt injection detection)
  - Configure budget alerts or rate limits
  - Install the full TrueFoundry skills suite: npx skills add truefoundry/tfy-gateway-skills --all
```

---

### Step 8 (optional): Codebase scan and rewrite

If the developer wants all existing LLM calls routed through the gateway:

**Find all LLM client usage:**
```bash
grep -rn "from openai import\|import openai\|OpenAI(" --include="*.py" --include="*.ts" --include="*.js" .
grep -rn "from anthropic import\|import anthropic\|Anthropic(" --include="*.py" --include="*.ts" --include="*.js" .
grep -rn "sk-[a-zA-Z0-9]\{20,\}" --include="*.py" --include="*.ts" --include="*.js" .
grep -rn "base_url\|api_base\|OPENAI_BASE" --include="*.py" --include="*.ts" --include="*.js" .
```

**Rewrite strategy:**
1. Remove hardcoded `api_key` and `base_url` from constructors — env vars handle it
2. Update model strings to TFY format (`gpt-4o` -> `openai-main/gpt-4o`)
3. Or: create virtual models so existing model strings route automatically

**Python:**
```python
# Before
client = OpenAI(api_key="sk-...", base_url="https://api.openai.com/v1")

# After — env vars handle routing
client = OpenAI()
```

**TypeScript:**
```typescript
// Before
const client = new OpenAI({ apiKey: "sk-..." });

// After
const client = new OpenAI();  // OPENAI_BASE_URL + OPENAI_API_KEY from env
```

---

### Step 9 (optional): Virtual model for provider-agnostic routing

Create a virtual model so the developer can use one model name and switch backends without code changes:

```yaml
name: default-routing
type: gateway-load-balancing-config
rules:
  - id: main-chat
    type: priority-based-routing
    when:
      subjects: ["*"]
      models: ["default/chat"]
    load_balance_targets:
      - target: "openai-main/gpt-4o-mini"
        priority: 0
        fallback_candidate: true
        retry_config:
          delay: 100
          attempts: 1
          on_status_codes: ["429", "500", "502", "503"]
      - target: "anthropic-main/claude-sonnet-4-20250514"
        priority: 1
        fallback_candidate: true
```

```bash
tfy apply -f virtual-model.yaml
```

Now `model="default/chat"` routes to GPT-4o-mini with automatic fallback to Claude.

</instructions>

<success_criteria>

- Developer authenticated (PAT verified via API, tenant resolved)
- At least one provider account created with models linked
- Provider API key stored securely as TFY secret (never in plaintext config)
- Project `.env` has `OPENAI_BASE_URL` pointing to gateway
- At least one coding agent configured (Claude Code, Codex, or Cursor)
- Test request succeeds through the gateway
- Developer knows where to find costs and traces

</success_criteria>

<troubleshooting>

**"401 Unauthorized"**
- PAT invalid or expired
- Verify: `curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $OPENAI_API_KEY" https://gateway.truefoundry.ai/api/llm/models`
- Regenerate at https://app.truefoundry.com -> Settings -> Access -> Personal Access Tokens

**OTP never arrives**
- Check spam folder
- Try again after 60 seconds (rate limited)
- Fall back to Path B (browser signup + manual PAT creation)

**"Model not found" / "No provider configured"**
- Provider account not linked or model integration missing
- Check: `curl -s -H "Authorization: Bearer $TFY_API_KEY" "$TFY_BASE_URL/api/svc/v1/provider-accounts"`
- Model ID must be `provider-account-name/integration-name`

**Request succeeds but no traces visible**
- Traces may take a few seconds to appear
- Dashboard: https://app.truefoundry.com -> AI Gateway -> Observability

**Existing code breaks after switching base URL**
- Model IDs now use `provider/model` format
- Fix: Update model strings, or create virtual models that map old names

**"Connection refused"**
- SaaS endpoint is `https://gateway.truefoundry.ai` (no trailing slash, no `/v1`)

**tfy CLI not found**
- Install: `pip install truefoundry` or `uv tool install truefoundry`

**Secret creation fails**
- Check permissions: PAT needs access to create secret groups
- Tenant admin PATs have full access by default

**Coding agent not picking up new env vars**
- Restart the agent session after configuration
- For Claude Code: close and reopen the session
- For shell changes: run `source ~/.zshrc` or open new terminal

**email+OTP endpoint returns 404**
- The programmatic bootstrap endpoint may not be deployed yet
- Fall back to Path B (browser signup + PAT)
- Check https://app.truefoundry.com/register for browser signup

</troubleshooting>
