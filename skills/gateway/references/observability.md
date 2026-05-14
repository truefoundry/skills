---
name: observability
description: How AI Gateway emits traces and metrics for each request and how to query data using SQL.
---

## Querying Gateway Observability Data

Gateway emits traces (OTEL spans) and metrics for each request which are stored in several tables.
A single request may involve multiple model calls, mcp calls, guardrail evaluations, etc and thus can generate multiple spans and metrics.
All spans and metrics of a user's request have the same `TraceId`.

### Understanding Table Columns

Available tables:

- `traces` - Stores OTEL compliant spans enriched with AI Gateway specific columns
- `gateway_model_metrics` - Stores metrics for model requests
- `gateway_mcp_metrics` - Stores metrics for MCP requests
- `gateway_guardrail_metrics` - Stores metrics for applied guardrails
- `gateway_config_metrics` - Stores metrics for applied rate limits, budget limits and load balancing rules
- `gateway_request_metrics` - Stores metrics for every incoming request to the gateway

For each table, there is a `references/tables/<table-name>.md` file which describes the table columns.

### Writing SQL Queries

When writing SQL queries against gateway observability data, follow these guidelines:

- Use the Datafusion SQL Query Engine dialect.
- Always quote table names and column names. Column names are case sensitive.
- Never guess column names. Read the table schema from `references/tables/<table-name>.md` if you don't already know the column names.
- Tables are accessed as `"{dataRoutingDestination}"."{tableName}"` e.g. `"default"."traces"`.
- `*_metrics` tables always exist in the `"default"` data routing destination.
- When no destination is specified, use `"default"` as the destination.
- Always add time range filters to queries. Larger time ranges are acceptable for metrics aggregations. For scan-type queries, use small time ranges, especially for the `traces` table. Default time range for metrics (if none specified) should be 7 days.

#### Examples

Query to get all traces in a time range:

```sql
SELECT * FROM "default"."traces" WHERE "Timestamp" > '2026-03-13T10:00:00Z' AND "Timestamp" < '2026-03-13T11:00:00Z'
```

### Checklist For SQL Queries

- [ ] Did I read the table schema and used the correct column names?
- [ ] Did I quote the table name and column names?
- [ ] Did I add time ranges and limits to the query?
- [ ] Did I only include the columns that are relevant to the task at hand?
