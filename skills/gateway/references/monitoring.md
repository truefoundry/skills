# AI Monitoring & Traces

Query gateway request traces, costs, latency, errors, and token usage via the spans query API.

### Required Parameter

Every query requires one of these two parameters. Ask the user which one to use:

| Parameter | Description |
|-----------|-------------|
| `tracingProjectFqn` | Fully qualified name of the tracing project, e.g. `tenant:tracing-project:name` |
| `dataRoutingDestination` | Data routing destination name, e.g. `default` |

If the user does not know which to use, suggest `"dataRoutingDestination": "default"` as a starting point.

### Query Spans API

**Endpoint:** `POST /api/svc/v1/spans/query`

```bash
# Basic query: recent spans in the last 24 hours
$TFY_API_SH POST '/api/svc/v1/spans/query' '{
  "startTime": "2026-03-26T00:00:00.000Z",
  "endTime": "2026-03-27T00:00:00.000Z",
  "dataRoutingDestination": "default",
  "limit": 50,
  "sortDirection": "desc"
}'
```

### Common Monitoring Use Cases

#### 1. Show Recent Requests

```bash
$TFY_API_SH POST '/api/svc/v1/spans/query' '{
  "startTime": "2026-03-26T00:00:00.000Z",
  "dataRoutingDestination": "default",
  "limit": 20,
  "sortDirection": "desc"
}'
```

#### 2. Cost Analysis (LLM Spans)

Filter for LLM spans and extract cost attributes:

```bash
$TFY_API_SH POST '/api/svc/v1/spans/query' '{
  "startTime": "2026-03-26T00:00:00.000Z",
  "dataRoutingDestination": "default",
  "filters": [
    {"spanAttributeKey": "tfy.span_type", "operator": "eq", "value": "LLM"}
  ],
  "limit": 200,
  "sortDirection": "desc"
}'
```

Cost fields in `spanAttributes`:
- `gen_ai.usage.cost` or `tfy.request_cost` -- cost of the request
- `gen_ai.usage.input_tokens` -- input token count
- `gen_ai.usage.output_tokens` -- output token count

#### 3. Show Errors

```bash
$TFY_API_SH POST '/api/svc/v1/spans/query' '{
  "startTime": "2026-03-26T00:00:00.000Z",
  "dataRoutingDestination": "default",
  "filters": [
    {"spanFieldName": "statusCode", "operator": "eq", "value": "ERROR"}
  ],
  "limit": 50,
  "sortDirection": "desc"
}'
```

#### 4. Model Usage Breakdown

Query all LLM spans and extract model info from span attributes to see which models are being used:

```bash
$TFY_API_SH POST '/api/svc/v1/spans/query' '{
  "startTime": "2026-03-26T00:00:00.000Z",
  "dataRoutingDestination": "default",
  "filters": [
    {"spanAttributeKey": "tfy.span_type", "operator": "eq", "value": "LLM"}
  ],
  "limit": 200,
  "sortDirection": "desc"
}'
```

Parse `spanAttributes` in the response for model name fields.

#### 5. Requests by a Specific User

```bash
$TFY_API_SH POST '/api/svc/v1/spans/query' '{
  "startTime": "2026-03-26T00:00:00.000Z",
  "dataRoutingDestination": "default",
  "createdBySubjectSlugs": ["user@example.com"],
  "limit": 50,
  "sortDirection": "desc"
}'
```

You can also filter by subject type:

```bash
$TFY_API_SH POST '/api/svc/v1/spans/query' '{
  "startTime": "2026-03-26T00:00:00.000Z",
  "dataRoutingDestination": "default",
  "createdBySubjectTypes": ["virtualaccount"],
  "limit": 50,
  "sortDirection": "desc"
}'
```

#### 6. MCP Tool Calls

```bash
$TFY_API_SH POST '/api/svc/v1/spans/query' '{
  "startTime": "2026-03-26T00:00:00.000Z",
  "dataRoutingDestination": "default",
  "filters": [
    {"spanAttributeKey": "tfy.span_type", "operator": "eq", "value": "MCP"}
  ],
  "limit": 50,
  "sortDirection": "desc"
}'
```

For MCP Gateway spans use `"value": "MCPGateway"` instead.

#### 7. Filter by Application Name

```bash
$TFY_API_SH POST '/api/svc/v1/spans/query' '{
  "startTime": "2026-03-26T00:00:00.000Z",
  "dataRoutingDestination": "default",
  "applicationNames": ["tfy-llm-gateway"],
  "limit": 50,
  "sortDirection": "desc"
}'
```

#### 8. Filter by Span Name (endpoint pattern)

```bash
$TFY_API_SH POST '/api/svc/v1/spans/query' '{
  "startTime": "2026-03-26T00:00:00.000Z",
  "dataRoutingDestination": "default",
  "filters": [
    {"spanFieldName": "spanName", "operator": "contains", "value": "completions"}
  ],
  "limit": 50,
  "sortDirection": "desc"
}'
```

#### 9. Filter by Gateway Request Metadata

```bash
$TFY_API_SH POST '/api/svc/v1/spans/query' '{
  "startTime": "2026-03-26T00:00:00.000Z",
  "dataRoutingDestination": "default",
  "filters": [
    {"gatewayRequestMetadataKey": "tfy_gateway_region", "operator": "eq", "value": "US"}
  ],
  "limit": 50,
  "sortDirection": "desc"
}'
```

### Request Body Reference

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `startTime` | string (ISO 8601) | Yes | Start of time range |
| `endTime` | string (ISO 8601) | No | End of time range (defaults to now) |
| `tracingProjectFqn` | string | One of this or `dataRoutingDestination` | Tracing project FQN |
| `dataRoutingDestination` | string | One of this or `tracingProjectFqn` | Data routing destination |
| `traceIds` | string[] | No | Filter by trace IDs |
| `spanIds` | string[] | No | Filter by span IDs |
| `parentSpanIds` | string[] | No | Filter by parent span IDs |
| `createdBySubjectTypes` | string[] | No | Filter by subject type (`user`, `virtualaccount`) |
| `createdBySubjectSlugs` | string[] | No | Filter by subject slug (e.g. email) |
| `applicationNames` | string[] | No | Filter by application name |
| `limit` | integer | No | Max results (default 200) |
| `sortDirection` | string | No | `asc` or `desc` |
| `pageToken` | string | No | Pagination token from previous response |
| `filters` | array | No | Array of filter objects (see Filter Types) |
| `includeFeedbacks` | boolean | No | Include feedback data |

### Filter Types

#### SpanFieldFilter

```json
{"spanFieldName": "<field>", "operator": "<op>", "value": "<val>"}
```

Fields: `spanName`, `serviceName`, `spanKind`, `statusCode`, etc.

#### SpanAttributeFilter

```json
{"spanAttributeKey": "<key>", "operator": "<op>", "value": "<val>"}
```

Any key from the `spanAttributes` dict (e.g. `tfy.span_type`, `gen_ai.usage.cost`).

#### GatewayRequestMetadataFilter

```json
{"gatewayRequestMetadataKey": "<key>", "operator": "<op>", "value": "<val>"}
```

Custom metadata keys set via `X-TFY-LOGGING-CONFIG` headers.

#### Filter Operators

`eq`, `neq`, `contains`, `not_contains`, `starts_with`, `ends_with`

### Response Structure

```json
{
  "data": [
    {
      "spanId": "...",
      "traceId": "...",
      "parentSpanId": "...",
      "serviceName": "tfy-llm-gateway",
      "spanName": "POST https://api.openai.com/v1/chat/completions",
      "spanKind": "Client",
      "scopeName": "...",
      "scopeVersion": "...",
      "timestamp": "2026-03-26T14:30:00.000Z",
      "durationNs": 1234567890,
      "statusCode": "OK",
      "statusMessage": "",
      "spanAttributes": {
        "gen_ai.usage.input_tokens": 150,
        "gen_ai.usage.output_tokens": 80,
        "gen_ai.usage.cost": 0.0023,
        "tfy.request_cost": 0.0023,
        "tfy.span_type": "LLM"
      },
      "events": [],
      "createdBySubject": {
        "subjectId": "...",
        "subjectSlug": "user@example.com",
        "subjectType": "user",
        "tenantName": "my-tenant"
      },
      "feedbacks": []
    }
  ],
  "pagination": {
    "nextPageToken": "..."
  }
}
```

### Pagination

When the response includes `pagination.nextPageToken`, pass it as `pageToken` in the next request to fetch the next page:

```bash
$TFY_API_SH POST '/api/svc/v1/spans/query' '{
  "startTime": "2026-03-26T00:00:00.000Z",
  "dataRoutingDestination": "default",
  "limit": 200,
  "pageToken": "TOKEN_FROM_PREVIOUS_RESPONSE"
}'
```

Continue until `nextPageToken` is null or absent.

### Presenting Results

Format results as tables for readability:

```
Recent Gateway Requests (last 24h):
| Time                | Model          | Status | Tokens (in/out) | Cost     | Latency   | User              |
|---------------------|----------------|--------|-----------------|----------|-----------|-------------------|
| 2026-03-26 14:30:00 | openai/gpt-4o  | OK     | 150 / 80        | $0.0023  | 1.23s     | user@example.com  |
| 2026-03-26 14:29:55 | anthropic/...  | OK     | 200 / 120       | $0.0045  | 2.10s     | bot@svc           |
| 2026-03-26 14:29:30 | openai/gpt-4o  | ERROR  | 100 / 0         | $0.0000  | 0.45s     | user@example.com  |
```

For cost summaries, aggregate across spans:

```
Cost Summary (last 24h):
| Model              | Requests | Total Cost | Avg Cost/Req | Total Tokens |
|--------------------|----------|------------|--------------|--------------|
| openai/gpt-4o      | 142      | $3.21      | $0.023       | 45,200       |
| anthropic/claude    | 58       | $1.87      | $0.032       | 22,100       |
| Total               | 200      | $5.08      | $0.025       | 67,300       |
```

Convert `durationNs` (nanoseconds) to human-readable format: divide by 1,000,000,000 for seconds.
