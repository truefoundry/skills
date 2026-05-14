---
name: gateway_request_metrics
description: Stores metrics for each gateway request. This table is used to track the overall usage of the gateway.
---

## Schema

```
TraceId: TEXT
    Trace for the entire gateway request (all child spans share this ID).
SpanId: TEXT
    Root or request-level span ID for this gateway invocation.
CreatedAt: TIMESTAMPTZ
    When the gateway request was received (UTC, microseconds).
ConversationId: TEXT, nullable
    Conversation identifier for multi-turn gateway usage.
RequestType: TEXT, nullable
    High-level API family (chat, messages, MCP, agent, etc.).
SpanType: TEXT, nullable
    Gateway classification of the root span (e.g. ChatCompletion, MCPGateway).
LatencyMs: DOUBLE PRECISION, nullable
    Total gateway request duration in milliseconds.
Streaming: BOOLEAN, nullable
    Whether the client used a streaming response for this request.
HttpStatusCode: INTEGER, nullable
    Final HTTP status code returned to the client.
RequestMethod: TEXT, nullable
    HTTP method (GET, POST, etc.) of the gateway request.
RequestPath: TEXT, nullable
    URL path of the gateway endpoint that was invoked.
Metadata: Map(Text, Text), nullable
    TrueFoundry Gateway and User Metadata, matches the "TfyGatewayMetadata" column in the "traces" table.
CreatedBySubjectSlug: TEXT
    Slug of the subject on whose request the config was evaluated. User email or virtual account name
CreatedBySubjectType: TEXT
    Type of the requesting subject. Possible values: user, virtualaccount.
Teams: Array(Text), nullable
    Teams attributed to the caller.
CreatedBySubjectId: TEXT
    Identifier of the subject for the request.
CreatedBySubject: TEXT
    Full caller identity for the request.
```
