---
name: span-attributes
description: Understanding the span attributes in the traces table.
---

## Understanding Span Attributes

Each span you query from LLM Gateway captures key request and model details. These are stored in the `SpanAttributesString`, `SpanAttributesNumber`, `SpanAttributesBool`, `SpanAttributesStringList`, `SpanAttributesNumberList`, `SpanAttributesBoolList` columns.

### Core Span Attributes

| Attribute                      | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `tfy.span_type`                | Type of span, with possible values:<br />• `"ChatCompletion"` - Complete chat request lifecycle<br />• `"Completion"` - Text completion requests without chat context<br />• `"MCP"` - Model Context Protocol server interactions and tool calls<br />• `"Rerank"` - Document reranking operations for search relevance<br />• `"Embedding"` - Vector embedding generation operations<br />• `"Model"` - Actual LLM model inference processing<br />• `"AgentResponse"` - Multi-tool agent orchestration workflows<br />• `"Guardrail"` - Safety, compliance, and content validation checks |
| `tfy.input`                    | Complete input data sent to the model, mcp\_server, guardrail, etc..                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| `tfy.output`                   | Complete output response from the model, mcp\_server, guardrail, etc..                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| `tfy.input_short_hand`         | Abbreviated version of the input for display purposes                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| `tfy.error_message`            | Error message if the request failed                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| `tfy.prompt_version_fqn`       | FQN of the prompt version used (if applicable)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| `tfy.prompt_variables`         | Variables used in prompt templating                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| `tfy.triggered_guardrail_fqns` | List of guardrails that were triggered during the request                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |

### Request Context Attributes

| Attribute                              | Description                                                              |
| -------------------------------------- | ------------------------------------------------------------------------ |
| `tfy.request.model_name`               | Name of the model that was requested                                     |
| `tfy.request.created_by_subject`       | Subject (user/service account) that made the request                     |
| `tfy.request.created_by_subject_teams` | Teams associated with the requesting subject                             |
| `tfy.request.metadata`                 | Additional metadata associated with the request (e.g., `{'foo': 'bar'}`) |
| `tfy.request.conversation_id`          | Unique identifier for the conversation (if part of a chat)               |

### Model Attributes

| Attribute                | Description                                                                                                                           |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------- |
| `tfy.model.id`           | Unique identifier of the model                                                                                                        |
| `tfy.model.name`         | Display name of the model                                                                                                             |
| `tfy.model.fqn`          | Fully qualified name of the model                                                                                                     |
| `tfy.model.request_url`  | URL endpoint used for the model request                                                                                               |
| `tfy.model.streaming`    | Whether the request used streaming mode                                                                                               |
| `tfy.model.request_type` | Type of request (e.g., `"ChatCompletion", "Completion", "Embedding", "Rerank", "AgentResponse", "MCPGateway", "CreateModelResponse"`) |

### Model Performance Metrics

| Attribute                                    | Description                                       |
| -------------------------------------------- | ------------------------------------------------- |
| `tfy.model.metric.time_to_first_token_in_ms` | Time taken to receive the first token (streaming) |
| `tfy.model.metric.latency_in_ms`             | Total request latency in milliseconds             |
| `tfy.model.metric.input_tokens`              | Number of tokens in the model input               |
| `tfy.model.metric.output_tokens`             | Number of tokens in the model output              |
| `tfy.model.metric.cost_in_usd`               | Cost of the request in USD                        |
| `tfy.model.metric.inter_token_latency_in_ms` | Average latency between tokens (streaming)        |

### Load Balancing Attributes

| Attribute                      | Description                                                                |
| ------------------------------ | -------------------------------------------------------------------------- |
| `applied_loadbalance_rule_ids` | IDs of load balancing rules that were applied (e.g., `['gpt-4-dev-load']`) |

### Budget Control Attributes

| Attribute                 | Description                                                                                        |
| ------------------------- | -------------------------------------------------------------------------------------------------- |
| `applied_budget_rule_ids` | IDs of budget rules that were applied to this request (e.g., `['virtualaccount1-monthly-budget']`) |

### Rate Limiting Attributes

| Attribute                    | Description                                                                                    |
| ---------------------------- | ---------------------------------------------------------------------------------------------- |
| `applied_ratelimit_rule_ids` | IDs of all rate limiting rules that were applied (e.g., `['virtualaccount1-daily-ratelimit']`) |

### MCP (Model Context Protocol) Server Attributes

| Attribute                                     | Description                                    |
| --------------------------------------------- | ---------------------------------------------- |
| `tfy.mcp_server.id`                           | Unique identifier of the MCP server            |
| `tfy.mcp_server.name`                         | Display name of the MCP server                 |
| `tfy.mcp_server.url`                          | URL endpoint of the MCP server                 |
| `tfy.mcp_server.fqn`                          | Fully qualified name of the MCP server         |
| `tfy.mcp_server.server_name`                  | Internal name of the MCP server                |
| `tfy.mcp_server.method`                       | MCP method that was called                     |
| `tfy.mcp_server.primitive_name`               | Name of the MCP primitive used                 |
| `tfy.mcp_server.error_code`                   | Error code if the MCP call failed              |
| `tfy.mcp_server.is_tool_call_execution_error` | Whether the error was from tool call execution |

### MCP Server Metrics

| Attribute                               | Description                                    |
| --------------------------------------- | ---------------------------------------------- |
| `tfy.mcp_server.metric.latency_in_ms`   | Latency of the MCP server call in milliseconds |
| `tfy.mcp_server.metric.number_of_tools` | Number of tools available in the MCP server    |

### Guardrail Attributes

| Attribute              | Description                                                          |
| ---------------------- | -------------------------------------------------------------------- |
| `tfy.guardrail.id`     | Unique identifier of the guardrail                                   |
| `tfy.guardrail.name`   | Display name of the guardrail                                        |
| `tfy.guardrail.fqn`    | Fully qualified name of the guardrail                                |
| `tfy.guardrail.result` | Result of the guardrail check (e.g., `'pass'`, `'mutate'`, `'flag'`) |

### Guardrail Applied Entity Attributes

| Attribute                               | Description                                 |
| --------------------------------------- | ------------------------------------------- |
| `tfy.guardrail.applied_on_entity.type`  | Type of entity the guardrail was applied to |
| `tfy.guardrail.applied_on_entity.id`    | ID of the entity                            |
| `tfy.guardrail.applied_on_entity.name`  | Name of the entity                          |
| `tfy.guardrail.applied_on_entity.fqn`   | FQN of the entity                           |
| `tfy.guardrail.applied_on_entity.scope` | Scope of the entity                         |

### Guardrail Metrics

| Attribute                            | Description                                        |
| ------------------------------------ | -------------------------------------------------- |
| `tfy.guardrail.metric.latency_in_ms` | Time taken for the guardrail check in milliseconds |

### HTTP Response Attributes

| Attribute                   | Description                      |
| --------------------------- | -------------------------------- |
| `http.response.status_code` | HTTP status code of the response |
