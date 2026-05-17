---
name: truefoundry-observability
description: Views application logs and adds OpenTelemetry-based tracing to applications via TrueFoundry. Supports log filtering, Traceloop SDK instrumentation for Python/TypeScript, and custom spans.
license: MIT
compatibility: Requires Bash, curl, and access to a TrueFoundry instance
allowed-tools: Bash(*/tfy-api.sh *) Bash(pip*) Bash(npm*)
---

> Routing note: For ambiguous user intents, use the shared clarification templates in [references/intent-clarification.md](references/intent-clarification.md).

<objective>

# Observability

View application logs and add OpenTelemetry-based tracing to applications on TrueFoundry.

## Scope

- **Logs**: View, download, and search application and job logs. Useful for debugging deployments, checking startup output, and finding errors.
- **Tracing**: Create tracing projects, install Traceloop SDK, and instrument Python or TypeScript applications for LLM call tracing and observability.

</objective>

<instructions>

## Application Logs

> **Security:** Log output may contain sensitive data (secrets, tokens, PII). Do not forward raw logs to external services or include them in responses without reviewing for sensitive content first.

When using direct API, set `TFY_API_SH` to the full path of this skill's `scripts/tfy-api.sh`. See `references/tfy-api-setup.md` for paths per agent.

### Download Logs

#### Via Tool Call

```
tfy_logs_download(payload={
    "workspace_id": "ws-id",
    "application_fqn": "app-fqn",
    "start_ts": "2026-02-10T00:00:00Z",
    "end_ts": "2026-02-10T23:59:59Z"
})
```

#### Via Direct API

```bash
# Set the path to tfy-api.sh for your agent (example for Claude Code):
TFY_API_SH=~/.claude/skills/truefoundry-observability/scripts/tfy-api.sh

# Download logs for an app in a workspace
$TFY_API_SH GET '/api/svc/v1/logs/WORKSPACE_ID/download?applicationFqn=APP_FQN&startTs=START&endTs=END'

# With search filter
$TFY_API_SH GET '/api/svc/v1/logs/WORKSPACE_ID/download?applicationId=APP_ID&searchString=error&searchType=contains'
```

### Log Parameters

| Parameter | API Key | Description |
|-----------|---------|-------------|
| `workspace_id` | (path) | Workspace ID (**required**) |
| `application_id` | `applicationId` | Filter by app ID |
| `application_fqn` | `applicationFqn` | Filter by app FQN |
| `deployment_id` | `deploymentId` | Filter by deployment |
| `job_run_name` | `jobRunName` | Filter by job run |
| `start_ts` | `startTs` | Start timestamp (ISO 8601) |
| `end_ts` | `endTs` | End timestamp (ISO 8601) |
| `search_string` | `searchString` | Search within logs |
| `search_type` | `searchType` | `contains`, `regex` |
| `pod_name` | `podName` | Filter by pod |

### Presenting Logs

Show logs in chronological order. For long output, show the last N lines or summarize errors:

```
Logs for tfy-tool-server (last 20 lines):
2026-02-10 14:30:01 INFO  Server starting on port 8000
2026-02-10 14:30:02 INFO  Tools endpoint ready at /tools
2026-02-10 14:30:05 INFO  Health check: OK
```

## Tracing & Instrumentation

### Step 1: Preflight

Run the `platform` skill (Status Check section) first to verify `TFY_BASE_URL` and `TFY_API_KEY` are set and valid.

### Step 2: Tracing Project Setup

Ask the user: **"Do you already have a tracing project FQN, or should I create one?"**

#### List Existing Projects

##### Via Tool Call
```
tfy_tracing_list_projects()
```

##### Via Direct API
```bash
TFY_API_SH=~/.claude/skills/truefoundry-observability/scripts/tfy-api.sh

# List tracing projects
$TFY_API_SH GET /api/ml/v1/tracing-projects
```

#### Create a New Project

Ask for a project name, then create:

##### Via Tool Call
```
tfy_tracing_create_project(name="my-tracing-project")
```

##### Via Direct API
```bash
# Create tracing project
$TFY_API_SH POST /api/ml/v1/tracing-projects '{"name": "my-tracing-project"}'
```

Save the returned project `id` for the next step.

#### Create an Application Under the Project

Each tracing project can have multiple applications (e.g., "chatbot", "rag-pipeline").

##### Via Tool Call
```
tfy_tracing_create_application(project_id="PROJECT_ID", name="my-app")
```

##### Via Direct API
```bash
# Create application under project
$TFY_API_SH POST /api/ml/v1/tracing-projects/PROJECT_ID/applications '{"name": "my-app"}'
```

> **Fallback**: If any of these API endpoints return 404, the tracing API may have changed. Direct the user to create the tracing project via the TrueFoundry UI at `$TFY_BASE_URL` → Tracing section, then return here with the project FQN.

### Step 3: Detect Application Type

Scan the project to determine the language and LLM libraries in use:

1. **Python** — look for `requirements.txt`, `pyproject.toml`, `setup.py`, `Pipfile`
   - Check for LLM libraries: `openai`, `anthropic`, `langchain`, `llama-index`, `litellm`, `cohere`, `bedrock`, `vertexai`, `transformers`
2. **TypeScript/JavaScript** — look for `package.json`
   - Check for LLM libraries: `openai`, `@anthropic-ai/sdk`, `langchain`, `@langchain/core`

Report what was detected to the user before proceeding.

### Step 4: Install Dependencies

#### Python
```bash
pip install traceloop-sdk
```

Also add `traceloop-sdk` to `requirements.txt` or the appropriate dependency file.

#### TypeScript/JavaScript
```bash
npm install @traceloop/node-server-sdk
```

Also add to `package.json` dependencies.

### Step 5: Instrument the Application

**CRITICAL**: `Traceloop.init()` MUST be called at the TOP of the entry point, BEFORE any LLM library imports. This is required for auto-instrumentation to work.

#### Python Instrumentation

Add this to the very top of the entry point file (e.g., `main.py`, `app.py`):

```python
# --- Traceloop init MUST be before any LLM imports ---
from traceloop.sdk import Traceloop

Traceloop.init(
    app_name="<APP_NAME>",
    api_endpoint=f"<TFY_BASE_URL>/api/otel",
    headers={
        "Authorization": f"Bearer <TFY_API_KEY>",
        "X-TFY-TRACING-PROJECT-FQN": "<TRACING_PROJECT_FQN>",
    },
    disable_batch=False,
)

# --- Now import LLM libraries ---
# from openai import OpenAI
# from anthropic import Anthropic
# etc.
```

Replace placeholders:
- `<APP_NAME>` — the application name (e.g., "my-chatbot")
- `<TFY_BASE_URL>` — from environment or `.env`
- `<TFY_API_KEY>` — from environment or `.env`
- `<TRACING_PROJECT_FQN>` — the tracing project FQN from Step 2

**Best practice**: Read `TFY_BASE_URL` and `TFY_API_KEY` from environment variables:

```python
import os
from traceloop.sdk import Traceloop

Traceloop.init(
    app_name="<APP_NAME>",
    api_endpoint=f"{os.environ['TFY_BASE_URL']}/api/otel",
    headers={
        "Authorization": f"Bearer {os.environ['TFY_API_KEY']}",
        "X-TFY-TRACING-PROJECT-FQN": "<TRACING_PROJECT_FQN>",
    },
    disable_batch=False,
)
```

#### TypeScript/JavaScript Instrumentation

Add this to the very top of the entry point file (e.g., `index.ts`, `app.ts`):

```typescript
// --- Traceloop init MUST be before any LLM imports ---
import * as traceloop from "@traceloop/node-server-sdk";

traceloop.initialize({
  appName: "<APP_NAME>",
  apiEndpoint: `${process.env.TFY_BASE_URL}/api/otel`,
  headers: {
    Authorization: `Bearer ${process.env.TFY_API_KEY}`,
    "X-TFY-TRACING-PROJECT-FQN": "<TRACING_PROJECT_FQN>",
  },
  disableBatch: false,
});

// --- Now import LLM libraries ---
// import OpenAI from "openai";
// etc.
```

### Step 6: Optional — Add Decorators for Multi-Step Apps

For applications with multiple logical steps (agents, RAG pipelines, etc.), offer to add decorators for better trace structure:

#### Python Decorators

```python
from traceloop.sdk.decorators import workflow, task, agent, tool

@workflow(name="rag_pipeline")
def run_pipeline(query: str):
    context = retrieve(query)
    return generate(query, context)

@task(name="retrieve_context")
def retrieve(query: str):
    # retrieval logic
    ...

@task(name="generate_response")
def generate(query: str, context: str):
    # LLM call
    ...

@agent(name="research_agent")
def research_agent(topic: str):
    # agent logic
    ...

@tool(name="web_search")
def web_search(query: str):
    # tool logic
    ...
```

#### TypeScript Decorators

```typescript
import { withWorkflow, withTask, withAgent, withTool } from "@traceloop/node-server-sdk";

const runPipeline = withWorkflow({ name: "rag_pipeline" }, async (query: string) => {
  const context = await retrieve(query);
  return generate(query, context);
});

const retrieve = withTask({ name: "retrieve_context" }, async (query: string) => {
  // retrieval logic
});

const generate = withTask({ name: "generate_response" }, async (query: string, context: string) => {
  // LLM call
});
```

### Step 7: Optional — Configure Sampling for Production

For high-traffic production apps, configure sampling to reduce trace volume:

#### Python
```python
from opentelemetry.sdk.trace.sampling import ParentBased, TraceIdRatioBased

Traceloop.init(
    app_name="<APP_NAME>",
    api_endpoint=f"{os.environ['TFY_BASE_URL']}/api/otel",
    headers={
        "Authorization": f"Bearer {os.environ['TFY_API_KEY']}",
        "X-TFY-TRACING-PROJECT-FQN": "<TRACING_PROJECT_FQN>",
    },
    disable_batch=False,
    sampler=ParentBased(root=TraceIdRatioBased(0.1)),  # 10% sampling
)
```

#### TypeScript
```typescript
import { ParentBasedSampler, TraceIdRatioBasedSampler } from "@opentelemetry/sdk-trace-base";

traceloop.initialize({
  appName: "<APP_NAME>",
  apiEndpoint: `${process.env.TFY_BASE_URL}/api/otel`,
  headers: {
    Authorization: `Bearer ${process.env.TFY_API_KEY}`,
    "X-TFY-TRACING-PROJECT-FQN": "<TRACING_PROJECT_FQN>",
  },
  disableBatch: false,
  sampler: new ParentBasedSampler({ root: new TraceIdRatioBasedSampler(0.1) }), // 10%
});
```

</instructions>

<success_criteria>

## Success Criteria

### Logs
- The user can see recent logs for their application or job in chronological order
- Error patterns in the logs are identified and highlighted with suggested fixes
- The agent has filtered logs by the correct time range, application, and search terms
- The user understands why their application failed or what its current behavior is
- Log output is presented concisely, summarizing long output rather than dumping raw text

### Tracing
- Tracing project exists (created or pre-existing) on TrueFoundry
- `traceloop-sdk` (Python) or `@traceloop/node-server-sdk` (TypeScript) is installed
- `Traceloop.init()` is placed at the top of the entry point, BEFORE LLM imports
- Auth headers include `Authorization` and `X-TFY-TRACING-PROJECT-FQN`
- The app runs without import errors
- Traces appear in the TrueFoundry tracing dashboard after a test request

</success_criteria>

<references>

## Composability

- **Preflight**: Use `platform` skill (Status Check section) to verify `tfy login` and TFY_BASE_URL/TFY_HOST. `TFY_API_KEY` is only needed for direct REST helper calls.
- **Find workspace**: Use `platform` skill (workspaces) to get workspace ID for log downloads
- **Find app first**: Get the app ID or FQN from the TrueFoundry dashboard
- **After deploy**: Check logs to verify the app started correctly
- **Debug failures**: Download logs with `searchString=error`
- **Secrets**: Use `platform` skill (Secrets section) to store TFY_API_KEY as a secret instead of hardcoding
- **Deploy**: After instrumenting, deploy your application to your infrastructure

## API Endpoints

See `references/api-endpoints.md` for the full Tracing API reference.

</references>

<troubleshooting>

## Error Handling

### Logs

#### Missing workspace_id
```
workspace_id is required for log downloads.
Use the platform skill (workspaces) to find your workspace ID.
```

#### No Logs Found
```
No logs found for the given filters. Check:
- Time range is correct
- Application ID/FQN is correct
- The app has actually run during this period
```

#### Permission Denied (Logs)
```
Cannot access logs. Check your API key permissions for this workspace.
```

### Tracing

#### 401 Unauthorized on Trace Export
```
Check that TFY_API_KEY is valid and not expired.
Regenerate at $TFY_BASE_URL → Settings → API Keys.
```

#### No Traces Appearing in Dashboard
```
1. Verify Traceloop.init() is called BEFORE LLM library imports — this is the #1 cause.
2. Check that api_endpoint ends with /api/otel (not /api/otel/).
3. Verify X-TFY-TRACING-PROJECT-FQN header matches the project FQN exactly.
4. Set disable_batch=True temporarily to force immediate export and check for errors.
5. Check application logs for OTLP export errors.
```

#### ImportError: No module named 'traceloop'
```
Run: pip install traceloop-sdk
Ensure you're installing in the correct virtual environment.
```

#### Traces Missing LLM Call Details
```
Traceloop.init() must be called BEFORE importing the LLM library.
Move the init call to the very top of your entry point file.
```

#### High Trace Volume in Production
```
Add sampling — see Step 7 for ParentBased(TraceIdRatioBased) configuration.
Start with 10% sampling (0.1) and adjust based on needs.
```

#### Tracing Project API Returns 404
```
The tracing API endpoints may differ on your TrueFoundry version.
Create the tracing project via the TrueFoundry UI instead:
$TFY_BASE_URL → Tracing → New Project
Then use the project FQN in your Traceloop.init() configuration.
```

</troubleshooting>
