#!/usr/bin/env bash
# TrueFoundry Gateway Verification — smoke test after migration
# Usage: ./verify-gateway.sh [model_id]
#
# Requires: OPENAI_BASE_URL and OPENAI_API_KEY (or TFY_API_KEY) set in env
set -euo pipefail

MODEL="${1:-openai-main/gpt-4o-mini}"
BASE_URL="${OPENAI_BASE_URL:-${TFY_GATEWAY_URL:-https://gateway.truefoundry.ai}}"
API_KEY="${OPENAI_API_KEY:-${TFY_API_KEY:-}}"

if [ -z "$API_KEY" ]; then
  echo "Error: No API key found. Set OPENAI_API_KEY or TFY_API_KEY" >&2
  exit 1
fi

echo "Verifying gateway routing..."
echo "  Endpoint: $BASE_URL"
echo "  Model:    $MODEL"
echo ""

RESPONSE=$(curl -s -w "\n%{http_code}" \
  "${BASE_URL}/chat/completions" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "'"$MODEL"'",
    "messages": [{"role": "user", "content": "Say ok and nothing else."}],
    "max_tokens": 5
  }')

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ]; then
  CONTENT=$(echo "$BODY" | python3 -c "import sys,json; r=json.load(sys.stdin); print(r['choices'][0]['message']['content'])" 2>/dev/null || echo "parse error")
  RESP_MODEL=$(echo "$BODY" | python3 -c "import sys,json; r=json.load(sys.stdin); print(r.get('model','unknown'))" 2>/dev/null || echo "unknown")
  TOKENS=$(echo "$BODY" | python3 -c "import sys,json; r=json.load(sys.stdin); u=r.get('usage',{}); print(f\"{u.get('prompt_tokens',0)} in / {u.get('completion_tokens',0)} out\")" 2>/dev/null || echo "unknown")

  echo "  Status:   OK (200)"
  echo "  Response: $CONTENT"
  echo "  Model:    $RESP_MODEL"
  echo "  Tokens:   $TOKENS"
  echo ""
  echo "Gateway routing verified successfully."
  exit 0
else
  echo "  Status:   FAILED ($HTTP_CODE)"
  echo "  Response: $BODY"
  echo ""

  case "$HTTP_CODE" in
    401) echo "Fix: API key is invalid or expired. Check TFY_API_KEY / OPENAI_API_KEY." ;;
    403) echo "Fix: Token does not have access to model '$MODEL'. Check VAT permissions." ;;
    404) echo "Fix: Model '$MODEL' not found in gateway. Check provider account config." ;;
    429) echo "Fix: Rate limited. Wait and retry, or check rate limit settings." ;;
    502|503) echo "Fix: Upstream provider error. Check provider status or model health." ;;
    *) echo "Fix: Unexpected error. Check gateway logs in TFY dashboard." ;;
  esac
  exit 1
fi
