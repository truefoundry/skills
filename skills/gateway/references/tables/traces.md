---
name: traces
description: Stores OTEL compliant spans with additional columns for gateway specific information.
---

## CRITICAL

- `TfyGatewayInput` and `TfyGatewayOutput` columns store the request and response payloads of the gateway. These are huge json serialized payloads that contain sensitive data. Only fetch these when necessary
- When working with `SpanAttributes.*` columns, refer to [span-attributes.md](../span-attributes.md) to understand keys inside these columns.

## Schema

```
Timestamp: TIMESTAMPTZ
    Start time of the span in UTC (microsecond precision).
TraceId: TEXT
    W3C trace identifier linking all spans in one distributed request.
SpanId: TEXT
    Unique identifier for this span within the trace.
ParentSpanId: TEXT
    Span ID of the parent span; empty when this is a root span.
SpanName: TEXT
    Operation name for the span (e.g. HTTP route or RPC method).
SpanKind: TEXT
    OpenTelemetry span kind (client, server, internal, producer, consumer).
Duration: BIGINT
    Span duration in the pipeline's native unit (typically nanoseconds per OpenTelemetry).
StatusCode: TEXT, nullable
    OpenTelemetry span status code (Unset, Ok, Error).
StatusMessage: TEXT, nullable
    Optional human-readable message for span status, often on errors.
HttpStatusCode: INTEGER, nullable
    HTTP response status code when the span represents an HTTP operation.
GenAIRequestModel: TEXT, nullable
    Model identifier from GenAI-related request telemetry when present.
TfyGatewayConversationID: TEXT, nullable
    AI Gateway conversation identifier tying multi-turn or related gateway calls.
TfyGatewayMetadata: Map(Text, Text), nullable
    TrueFoundry Gateway Metadata - contains both user supplied and system generated metadata
TfyGatewayInput: TEXT, nullable
    JSON serialized gateway input payload. Contains sensitive data
TfyGatewayOutput: TEXT, nullable
    JSON serialized gateway output payload. Contains sensitive data
TfyGatewaySpanType: TEXT, nullable
    Classifies the gateway span (e.g. model call, MCP, guardrail) for analysis.
SpanAttributesString: Map(Text, Text), nullable
    String-valued OpenTelemetry span attributes as a key-value map.
SpanAttributesNumber: Map(Text, DOUBLE PRECISION), nullable
    Numeric span attributes (stored as float64) as a key-value map.
SpanAttributesBool: Map(Text, BOOLEAN), nullable
    Boolean span attributes as a key-value map.
SpanAttributesStringList: Map(Text, Array(Text)), nullable
    Span attributes whose values are lists of strings.
SpanAttributesNumberList: Map(Text, Array(DOUBLE PRECISION)), nullable
    Span attributes whose values are lists of numbers.
SpanAttributesBoolList: Map(Text, Array(BOOLEAN)), nullable
    Span attributes whose values are lists of booleans.
TfyCreatedBySubjectSlug: TEXT, nullable
    URL-safe slug for the TrueFoundry subject that created the span. User email or virtual account name
TfyCreatedBySubjectType: TEXT, nullable
    Type of the requesting subject. Possible values: user, virtualaccount.
TfyCreatedBySubjectId: TEXT, nullable
    Stable identifier of the TrueFoundry subject.
TfyCreatedBySubject: TEXT
    Identity of the caller or principal attributed to the span (TrueFoundry subject).
```

## Checklist

- [ ] Did I refer to [span-attributes.md](../span-attributes.md) to understand the span attributes?
