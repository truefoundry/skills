#!/usr/bin/env bash
# TrueFoundry Codebase Scanner — finds all LLM call sites, MCP configs, and credentials
# Usage: ./scan.sh [target_dir] [--json] [--skip-tests]
#
# Outputs a structured report of all findings.
set -euo pipefail

TARGET_DIR="${1:-.}"
SKIP_TESTS=0

# Parse args
for arg in "$@"; do
  case "$arg" in
    --json) ;; # reserved for future use
    --skip-tests) SKIP_TESTS=1 ;;
  esac
done

# Validate target
if [ ! -d "$TARGET_DIR" ]; then
  echo "Error: Directory '$TARGET_DIR' does not exist" >&2
  exit 1
fi

cd "$TARGET_DIR"

# ── Exclusion patterns ──────────────────────────────────────────────────────
EXCLUDE_DIRS="node_modules .venv venv __pycache__ dist build .git .next .nuxt .tox .mypy_cache .pytest_cache coverage .nyc_output vendor third_party"
RG_EXCLUDES=""
for d in $EXCLUDE_DIRS; do
  RG_EXCLUDES="$RG_EXCLUDES --glob '!$d/**'"
done

if [ "$SKIP_TESTS" -eq 1 ]; then
  RG_EXCLUDES="$RG_EXCLUDES --glob '!*test*' --glob '!*spec*' --glob '!*mock*' --glob '!*fixture*'"
fi

# Helper: run rg with exclusions
rg_scan() {
  eval "rg -n --no-heading $RG_EXCLUDES $*" 2>/dev/null || true
}

# ── Category: OpenAI SDK ─────────────────────────────────────────────────────
echo "=== OPENAI_SDK ==="
rg_scan "'(from openai import|import openai|new OpenAI\\(|OpenAI\\()' --include '*.py' --include '*.ts' --include '*.js' --include '*.tsx' --include '*.jsx'"

# ── Category: Anthropic SDK ──────────────────────────────────────────────────
echo ""
echo "=== ANTHROPIC_SDK ==="
rg_scan "'(from anthropic import|import anthropic|new Anthropic\\(|Anthropic\\()' --include '*.py' --include '*.ts' --include '*.js' --include '*.tsx'"

# ── Category: Azure OpenAI ───────────────────────────────────────────────────
echo ""
echo "=== AZURE_OPENAI ==="
rg_scan "'(AzureOpenAI\\(|from openai import AzureOpenAI|azure_endpoint|azure_deployment)' --include '*.py' --include '*.ts' --include '*.js'"

# ── Category: Google/Gemini ──────────────────────────────────────────────────
echo ""
echo "=== GOOGLE_GEMINI ==="
rg_scan "'(genai\\.GenerativeModel|ChatGoogleGenerativeAI|google\\.generativeai|@google/generative-ai)' --include '*.py' --include '*.ts' --include '*.js'"

# ── Category: LangChain ──────────────────────────────────────────────────────
echo ""
echo "=== LANGCHAIN ==="
rg_scan "'(ChatOpenAI\\(|ChatAnthropic\\(|AzureChatOpenAI\\(|ChatGoogleGenerativeAI\\(|from langchain|from langchain_openai|from langchain_anthropic)' --include '*.py' --include '*.ts' --include '*.js'"

# ── Category: LlamaIndex ─────────────────────────────────────────────────────
echo ""
echo "=== LLAMAINDEX ==="
rg_scan "'(from llama_index\\.llms|from llama_index\\.core\\.llms|from llama_index\\.embeddings)' --include '*.py'"

# ── Category: Vercel AI SDK ──────────────────────────────────────────────────
echo ""
echo "=== VERCEL_AI ==="
rg_scan "'(createOpenAI\\(|createAnthropic\\(|generateText\\(|streamText\\(|@ai-sdk/openai|@ai-sdk/anthropic)' --include '*.ts' --include '*.tsx' --include '*.js'"

# ── Category: LiteLLM ────────────────────────────────────────────────────────
echo ""
echo "=== LITELLM ==="
rg_scan "'(litellm\\.completion|litellm\\.acompletion|litellm\\.embedding|from litellm|import litellm)' --include '*.py'"

# ── Category: Hardcoded API Keys ─────────────────────────────────────────────
echo ""
echo "=== HARDCODED_KEYS ==="
rg_scan "'(sk-[a-zA-Z0-9]{20,}|sk-ant-[a-zA-Z0-9_-]{20,}|sk-proj-[a-zA-Z0-9_-]{20,})' --include '*.py' --include '*.ts' --include '*.js' --include '*.tsx' --include '*.jsx' --include '*.yaml' --include '*.yml'"

# ── Category: API Key Env References ─────────────────────────────────────────
echo ""
echo "=== API_KEY_ENV_REFS ==="
rg_scan "'(OPENAI_API_KEY|ANTHROPIC_API_KEY|AZURE_OPENAI_API_KEY|GOOGLE_API_KEY|GROQ_API_KEY|TOGETHER_API_KEY|MISTRAL_API_KEY)' --include '*.env*' --include '*.py' --include '*.ts' --include '*.js' --include '*.yaml' --include '*.yml' --include '*.toml'"

# ── Category: Direct Provider URLs ───────────────────────────────────────────
echo ""
echo "=== DIRECT_PROVIDER_URLS ==="
rg_scan "'(api\\.openai\\.com|api\\.anthropic\\.com|generativelanguage\\.googleapis\\.com|api\\.groq\\.com|api\\.together\\.xyz|api\\.mistral\\.ai)' --include '*.py' --include '*.ts' --include '*.js' --include '*.yaml' --include '*.yml' --include '*.env*' --include '*.json'"

# ── Category: Base URL Settings ──────────────────────────────────────────────
echo ""
echo "=== BASE_URL_SETTINGS ==="
rg_scan "'(OPENAI_BASE_URL|openai_api_base|base_url.*openai|baseURL.*openai)' --include '*.py' --include '*.ts' --include '*.js' --include '*.env*' --include '*.yaml' --include '*.yml'"

# ── Category: MCP Configurations ─────────────────────────────────────────────
echo ""
echo "=== MCP_CONFIGS ==="
rg_scan "'(mcpServers|mcp_servers|mcp-servers|MCPServer)' --include '*.json' --include '*.yaml' --include '*.yml' --include '*.toml' --include '*.py' --include '*.ts'"
echo ""
echo "--- MCP Config Files ---"
find . -name 'mcp.json' -o -name 'mcp_config.json' -o -name '.mcp.json' -o -name 'mcp.yaml' -o -name 'claude_desktop_config.json' -o -name '.cursor-mcp.json' 2>/dev/null | grep -v node_modules | grep -v .git || true

# ── Category: Model Names ────────────────────────────────────────────────────
echo ""
echo "=== MODEL_NAMES ==="
rg_scan "'\"(gpt-4o|gpt-4o-mini|gpt-4-turbo|gpt-3\\.5-turbo|gpt-4\\.1|gpt-4\\.1-mini|gpt-4\\.1-nano|claude-3|claude-sonnet|claude-opus|claude-haiku|gemini-pro|gemini-1\\.5|gemini-2|llama-3|mixtral|mistral-large|command-r)' --include '*.py' --include '*.ts' --include '*.js' --include '*.yaml' --include '*.yml' --include '*.env*' --include '*.json'"

# ── Category: Already Using TFY Gateway ──────────────────────────────────────
echo ""
echo "=== ALREADY_TFY ==="
rg_scan "'(gateway\\.truefoundry|truefoundry\\.cloud/api/llm|TFY_API_KEY|TFY_BASE_URL|tfy-secret://)'"

echo ""
echo "=== SCAN_COMPLETE ==="
