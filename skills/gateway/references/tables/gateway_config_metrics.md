---
name: gateway_config_metrics
description: Stores metrics for applied load balancing, rate limiting, budget limiting rules.
---

## Schema

```
TraceId: TEXT
    Trace tying the config evaluation to the user request.
SpanId: TEXT
    Span during which the configuration rule was applied or evaluated.
CreatedAt: TIMESTAMPTZ
    When the config was evaluated. UTC, microseconds.
ConversationId: TEXT, nullable
    Conversation context when applicable.
RuleId: TEXT, nullable
    Identifier of the configuration rule as requested or configured.
ResolvedRuleId: TEXT, nullable
    Identifier of the rule actually applied after resolution and inheritance.
ConfigType: TEXT
    Category of configuration.
RequestedModel: TEXT, nullable
    Model name from the request. E.g. can be virtual model name or slug
Model: TEXT, nullable
    Final Model name resolved after evaluating configs
LoadbalanceType: TEXT, nullable
    Load balancing strategy used (weight, latency, cost, etc.).
LoadbalanceFirstTarget: TEXT, nullable
    First target model or endpoint attempted in load balancing.
LoadbalanceFinalTarget: TEXT, nullable
    Target that ultimately served the request after retries or failover.
LoadbalanceTargetAttemptCount: INTEGER, nullable
    Number of backend targets tried for this routing decision.
LoadbalanceRuleId: TEXT, nullable
    Identifier of the load balancing rule configuration.
Status: TEXT, nullable
    Outcome of the config application.
Metadata: Map(Text, Text), nullable
    TrueFoundry Gateway and User Metadata, matches the "TfyGatewayMetadata" column in the "traces" table.
CreatedBySubjectSlug: TEXT
    Slug of the subject on whose request the config was evaluated. User email or virtual account name
CreatedBySubjectType: TEXT
    Type of the requesting subject. Possible values: user, virtualaccount.
```
