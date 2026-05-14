---
name: gateway_guardrail_metrics
description: Stores metrics for guardrail calls.
---

## Schema

```
TraceId: TEXT
    Trace linking the guardrail span to the user request.
SpanId: TEXT
    Span representing this guardrail invocation.
CreatedAt: TIMESTAMPTZ
    When the guardrail was evaluated. UTC, microseconds.
GuardrailId: TEXT, nullable
    Identifier of the guardrail configuration or integration instance.
GuardrailName: TEXT, nullable
    Human-readable guardrail name.
GuardrailFqn: TEXT, nullable
    Fully qualified name of the guardrail in TrueFoundry.
LatencyMs: DOUBLE PRECISION, nullable
    Time taken to run the guardrail check in milliseconds.
GuardrailResult: TEXT, nullable
    Policy outcome or result label.
IsFailure: BOOLEAN
    Whether the guardrail evaluation failed (error) versus completed with a policy outcome.
AppliedOnEntityScope: TEXT, nullable
    Scope at which the guardrail was applied.
AppliedOnEntityId: TEXT, nullable
    ID of the entity the guardrail was bound to.
AppliedOnEntityName: TEXT, nullable
    Name of the entity the guardrail was bound to.
AppliedOnEntityFqn: TEXT, nullable
    Fully qualified name of the entity the guardrail was applied on.
AppliedOnEntityType: TEXT, nullable
    Type of entity (model, MCP server, etc.) the guardrail targeted.
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
ProviderAccountId: TEXT, nullable
    External guardrail provider account when checks delegate to a vendor.
ProviderIntegrationType: TEXT, nullable
    Integration type for the guardrail provider connection.
```
