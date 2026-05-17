# Migration Code Patterns

Code change templates for routing LLM calls through TrueFoundry Gateway, verification scripts, and interaction guidelines.

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
