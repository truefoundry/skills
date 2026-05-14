---
name: gateway_model_metrics
description: Stores metrics for both Models and Virtual Models.
---

## CRITICAL

- For a virtual model request,there will be multiple rows in the table, one row for the virtual model and one row for each of the underlying models till the request is fulfilled.
- A virtual model metrics row has `VirtualModelName` column set to the name of the virtual model while for the underlying model rows this column is set to `NULL`.
- Care should be taken to never query virtual model and underlying model rows together since virtual models themselves are not real models and are just a grouping of underlying models.

## Schema

```
TraceId: TEXT
    Trace tying this model metric to the gateway request span tree.
SpanId: TEXT
    Span associated with this model invocation (virtual or concrete target).
CreatedAt: TIMESTAMPTZ
    When the model call was started (UTC, microseconds).
ConversationId: TEXT, nullable
    Multi-turn conversation identifier when the call is part of a conversation.
ModelId: TEXT, nullable
    Internal identifier of the model used for this row.
ModelName: TEXT, nullable
    Actual model name used for the inference after resolving virtual models and policies
RequestedModelName: TEXT, nullable
    Model name as requested by the client before routing resolution.
VirtualModelName: TEXT, nullable
    For virtual model rows, this is the name of the virtual model. For underlying model rows, this is NULL.
VirtualModelSlug: TEXT, nullable
    URL-safe identifier of the virtual model when applicable.
VirtualModelId: TEXT, nullable
    Stable ID of the virtual model when applicable.
VirtualModelTargetAttempt: INTEGER, nullable
    Zero-based or ordinal attempt index when trying successive virtual model targets.
RequestType: TEXT, nullable
    API or request shape (e.g. chat completions, embeddings) for the call.
InputTokens: BIGINT, nullable
    Count of input (prompt) tokens billed or reported for the call.
OutputTokens: BIGINT, nullable
    Count of output (completion) tokens for the call.
LatencyMs: DOUBLE PRECISION, nullable
    End-to-end model call latency in milliseconds.
TimeToFirstTokenMs: DOUBLE PRECISION, nullable
    Time from request start to first streamed token, in milliseconds.
InterTokenLatencyMs: DOUBLE PRECISION, nullable
    Average or aggregate time between streamed tokens, in milliseconds.
Streaming: BOOLEAN, nullable
    Whether the response was streamed to the client.
CostInUSD: DOUBLE PRECISION, nullable
    Estimated or actual cost of the call in US dollars.
AppliedConfigIds: Map(Text, Array(Text)), nullable
    Maps config categories to lists of applied rule or config identifiers.
HttpStatusCode: INTEGER, nullable
    HTTP status returned for the gateway request wrapping the model call.
TfyMetadata: Map(Text, Text), nullable
    Unused column
IsFailure: BOOLEAN, nullable
    Whether the model call failed from the gateway's perspective.
ErrorType: TEXT, nullable
    Categorized error type when IsFailure is true.
ModelType: TEXT, nullable
    Classification of the model (e.g. chat, embedding) or integration flavor.
CacheType: TEXT, nullable
    Kind of response cache involved (e.g. semantic, exact) when applicable.
CacheHit: BOOLEAN, nullable
    Whether the response was served from cache.
PotentialCostSavings: DOUBLE PRECISION, nullable
    Estimated USD saved by serving from cache instead of the provider.
CacheLookupStatus: TEXT, nullable
    Outcome of the cache lookup (hit, miss, error, etc.).
CacheLookupLatencyMs: DOUBLE PRECISION, nullable
    Time spent on cache lookup in milliseconds.
CacheNamespace: TEXT, nullable
    Logical namespace or partition key for cache entries.
SemanticCacheSimilarityScore: DOUBLE PRECISION, nullable
    Similarity score for the matched semantic cache entry, when used.
SemanticCacheSimilarityThreshold: DOUBLE PRECISION, nullable
    Configured minimum similarity required for a semantic cache hit.
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
ProviderAccountType: TEXT, nullable
    Kind of provider account (cloud, BYOK, etc.).
ProviderIntegrationType: TEXT, nullable
    Integration flavor for the provider connection.
ProviderModelName: TEXT, nullable
    Upstream provider's model name as sent to the API.
```

## Checklist

- [ ] Did I make sure to include the correct condition for `VirtualModelName` column to make sure I have not mixed virtual model and underlying model rows together?
