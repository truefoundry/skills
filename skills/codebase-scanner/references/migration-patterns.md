# Migration Patterns Reference

Complete reference for migrating LLM calls from direct provider access to TrueFoundry Gateway.

## Principle

TrueFoundry Gateway is OpenAI-compatible. Migration means:
1. Point `base_url` to gateway endpoint
2. Swap API key to TFY PAT/VAT
3. (Optional) Prefix model names with provider account name

The simplest migration is setting two env vars — no code changes needed if the code reads from `OPENAI_BASE_URL` and `OPENAI_API_KEY`.

---

## Python — OpenAI SDK

### Pattern: Constructor with hardcoded values

```python
# BEFORE
from openai import OpenAI
client = OpenAI(api_key="sk-...", base_url="https://api.openai.com/v1")

# AFTER (env var approach — recommended)
from openai import OpenAI
client = OpenAI()  # reads OPENAI_BASE_URL + OPENAI_API_KEY from env

# AFTER (explicit approach)
import os
from openai import OpenAI
client = OpenAI(
    api_key=os.environ["TFY_API_KEY"],
    base_url=os.environ.get("TFY_GATEWAY_URL", "https://gateway.truefoundry.ai"),
)
```

### Pattern: Only api_key set, no base_url

```python
# BEFORE
client = OpenAI(api_key=os.environ["OPENAI_API_KEY"])

# AFTER — just set env vars, no code change needed:
# OPENAI_BASE_URL=https://gateway.truefoundry.ai
# OPENAI_API_KEY=<tfy-pat>
client = OpenAI(api_key=os.environ["OPENAI_API_KEY"])
```

### Pattern: Async client

```python
# BEFORE
from openai import AsyncOpenAI
client = AsyncOpenAI(api_key="sk-...")

# AFTER
from openai import AsyncOpenAI
client = AsyncOpenAI()  # reads from env
```

---

## Python — Anthropic SDK

```python
# BEFORE
from anthropic import Anthropic
client = Anthropic(api_key=os.environ["ANTHROPIC_API_KEY"])
response = client.messages.create(model="claude-sonnet-4-20250514", ...)

# AFTER (option 1: env vars)
# Set: ANTHROPIC_BASE_URL=https://gateway.truefoundry.ai
#      ANTHROPIC_API_KEY=<tfy-pat>
client = Anthropic()  # reads from env
response = client.messages.create(model="anthropic-main/claude-sonnet-4-20250514", ...)

# AFTER (option 2: use OpenAI SDK through gateway — recommended for consistency)
from openai import OpenAI
client = OpenAI(
    api_key=os.environ["TFY_API_KEY"],
    base_url="https://gateway.truefoundry.ai",
)
response = client.chat.completions.create(
    model="anthropic-main/claude-sonnet-4-20250514",
    messages=[...],
)
```

---

## TypeScript/JavaScript — OpenAI SDK

```typescript
// BEFORE
import OpenAI from "openai";
const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

// AFTER (env var approach)
// Set: OPENAI_BASE_URL=https://gateway.truefoundry.ai
//      OPENAI_API_KEY=<tfy-pat>
const client = new OpenAI();  // reads from env

// AFTER (explicit)
const client = new OpenAI({
  apiKey: process.env.TFY_API_KEY,
  baseURL: process.env.OPENAI_BASE_URL || "https://gateway.truefoundry.ai",
});
```

---

## TypeScript — Vercel AI SDK

```typescript
// BEFORE
import { createOpenAI } from "@ai-sdk/openai";
const openai = createOpenAI({ apiKey: process.env.OPENAI_API_KEY });

// AFTER
const openai = createOpenAI({
  apiKey: process.env.TFY_API_KEY || process.env.OPENAI_API_KEY,
  baseURL: process.env.OPENAI_BASE_URL || "https://gateway.truefoundry.ai",
});

// Model references
// BEFORE: openai("gpt-4o")
// AFTER:  openai("openai-main/gpt-4o")  — or use virtual models
```

---

## Python — LangChain

```python
# BEFORE
from langchain_openai import ChatOpenAI
llm = ChatOpenAI(model="gpt-4o", api_key=os.environ["OPENAI_API_KEY"])

# AFTER (env var approach — minimal change)
# Set: OPENAI_BASE_URL=https://gateway.truefoundry.ai
#      OPENAI_API_KEY=<tfy-pat>
llm = ChatOpenAI(model="openai-main/gpt-4o")

# AFTER (explicit)
llm = ChatOpenAI(
    model="openai-main/gpt-4o",
    api_key=os.environ["TFY_API_KEY"],
    base_url="https://gateway.truefoundry.ai",
)
```

### LangChain Anthropic

```python
# BEFORE
from langchain_anthropic import ChatAnthropic
llm = ChatAnthropic(model="claude-sonnet-4-20250514")

# AFTER — route Anthropic through gateway via OpenAI-compatible endpoint
from langchain_openai import ChatOpenAI
llm = ChatOpenAI(
    model="anthropic-main/claude-sonnet-4-20250514",
    api_key=os.environ["TFY_API_KEY"],
    base_url="https://gateway.truefoundry.ai",
)
```

---

## Python — LlamaIndex

```python
# BEFORE
from llama_index.llms.openai import OpenAI
llm = OpenAI(model="gpt-4o", api_key="sk-...")

# AFTER
from llama_index.llms.openai import OpenAI
llm = OpenAI(
    model="openai-main/gpt-4o",
    api_key=os.environ["TFY_API_KEY"],
    api_base="https://gateway.truefoundry.ai",
)
```

---

## Python — LiteLLM

```python
# LiteLLM respects OPENAI_BASE_URL natively
# BEFORE
import litellm
response = litellm.completion(model="gpt-4o", messages=[...])

# AFTER (env var — no code change)
# Set: OPENAI_BASE_URL=https://gateway.truefoundry.ai
#      OPENAI_API_KEY=<tfy-pat>
response = litellm.completion(model="openai-main/gpt-4o", messages=[...])

# Or set litellm-specific:
litellm.api_base = "https://gateway.truefoundry.ai"
litellm.api_key = os.environ["TFY_API_KEY"]
```

---

## Environment File Patterns

### .env / .env.local

```bash
# BEFORE
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
# No base URL set (defaults to provider)

# AFTER
OPENAI_API_KEY=tfy-pat-...
OPENAI_BASE_URL=https://gateway.truefoundry.ai
ANTHROPIC_API_KEY=tfy-pat-...
ANTHROPIC_BASE_URL=https://gateway.truefoundry.ai

# Keep original keys in TFY Secrets, not in .env
# Original provider keys are now stored as:
#   tfy-secret://TENANT:llm-keys:OPENAI_API_KEY
#   tfy-secret://TENANT:llm-keys:ANTHROPIC_API_KEY
```

### docker-compose.yml

```yaml
# BEFORE
services:
  app:
    environment:
      OPENAI_API_KEY: ${OPENAI_API_KEY}

# AFTER
services:
  app:
    environment:
      OPENAI_API_KEY: ${TFY_API_KEY}
      OPENAI_BASE_URL: https://gateway.truefoundry.ai
```

### Kubernetes secrets / configmaps

```yaml
# BEFORE (k8s secret)
apiVersion: v1
kind: Secret
data:
  OPENAI_API_KEY: <base64-encoded-sk-...>

# AFTER — reference TFY secret in deployment manifest instead
# env:
#   OPENAI_API_KEY: tfy-secret://TENANT:llm-keys:TFY_PAT
#   OPENAI_BASE_URL: https://gateway.truefoundry.ai
```

---

## MCP Configuration Migration

### Claude Desktop / Cursor MCP

MCP server configurations don't need base_url changes — they are tool servers, not LLM calls. However, they should be registered in TFY for:
- Access control (who can use which tools)
- Observability (track tool invocations)
- Discovery (central registry)

The `tools` skill (MCP Servers section) handles registration.

---

## Decision Matrix: Migration Effort

| Current Pattern | Effort | Migration |
|----------------|--------|-----------|
| Code reads from env vars, no hardcoded URLs | **Low** | Just update .env |
| Code has `api_key=os.environ[...]` but no base_url | **Low** | Add `OPENAI_BASE_URL` to env |
| Code has hardcoded `api_key="sk-..."` | **Medium** | Remove literal, switch to env var |
| Code has hardcoded `base_url="https://api.openai.com/v1"` | **Medium** | Remove or swap to env var |
| Code uses provider-specific SDK (Anthropic) | **Medium** | Can keep SDK + set env vars, or switch to OpenAI SDK |
| Code uses framework (LangChain) with explicit params | **Medium** | Add base_url param or rely on env vars |
| Code has model names hardcoded in many places | **Medium-High** | Update all, or create virtual models |
| Code uses multiple providers with different keys | **High** | Consolidate to single TFY key + gateway routing |
