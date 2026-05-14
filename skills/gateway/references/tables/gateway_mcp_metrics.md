---
name: gateway_mcp_metrics
description: Stores metrics for MCP calls.
---

## Schema

```
TraceId: TEXT
    Trace linking this MCP metric to the broader gateway request.
SpanId: TEXT
    Span representing this MCP server or tool interaction.
CreatedAt: TIMESTAMPTZ
    Time the MCP span was emitted. UTC, microseconds.
McpServerId: TEXT, nullable
    Database identifier of the MCP server entity.
McpServerName: TEXT, nullable
    Human-readable MCP server name.
Method: TEXT
    MCP JSON-RPC method or gateway operation name executed.
PrimitiveName: TEXT, nullable
    Name of the MCP primitive invoked
HttpStatusCode: INTEGER, nullable
    HTTP status from the MCP or transport layer when HTTP is used.
LatencyMs: DOUBLE PRECISION, nullable
    MCP operation latency in milliseconds.
ErrorCode: INTEGER, nullable
    Application or JSON-RPC error code when the call failed.
IsToolCallExecutionError: BOOLEAN, nullable
    True when a tool execution step failed, distinct from transport errors.
ConversationId: TEXT, nullable
    Conversation context when MCP is used inside a multi-turn flow.
IsCached: BOOLEAN, nullable
    Whether MCP response or tool result was served from cache.
McpServerUrl: TEXT, nullable
    Endpoint URL of the MCP server when remote.
Metadata: Map(Text, Text), nullable
    TrueFoundry Gateway and User Metadata, matches the "TfyGatewayMetadata" column in the "traces" table.
CreatedBySubjectSlug: TEXT
    Slug of the subject that invoked the MCP path. User email or virtual account name
CreatedBySubjectType: TEXT
    Type of the calling subject. Possible values: user, virtualaccount.
Teams: Array(Text), nullable
    Teams associated with the caller for attribution.
CreatedBySubjectId: TEXT
    Identifier of the subject that invoked the MCP path.
```
