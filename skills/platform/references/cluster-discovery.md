# Cluster Discovery

## Base Domains

When exposing a service publicly, you need the cluster's base domain to construct a valid hostname. Invalid hosts cause deploy failures.

### Get Cluster Base Domains

```bash
$TFY_API_SH GET /api/svc/v1/clusters/CLUSTER_ID
```

Look for `baseDomain` or `ingressDomain` in the response. Typical format: `*.your-cluster.truefoundry.cloud`.

### Construct Public URL

```
https://<service-name>-<workspace>.<base-domain>
```

Example: `https://my-api-prod.cluster1.truefoundry.cloud`

## Extract Cluster ID from Workspace FQN

Workspace FQN format: `<cluster-id>:<workspace-name>`

```bash
CLUSTER_ID="${TFY_WORKSPACE_FQN%%:*}"
WORKSPACE_NAME="${TFY_WORKSPACE_FQN#*:}"
```

## List All Clusters

```bash
$TFY_API_SH GET /api/svc/v1/clusters
```

Response includes: `id`, `name`, `provider` (aws/gcp/azure), `region`, connection status.

## Check Cluster Connectivity

```bash
$TFY_API_SH GET /api/svc/v1/clusters/CLUSTER_ID/is-connected
```

Returns `{"connected": true/false}`. A disconnected cluster cannot accept deployments.

## Cluster Addons

```bash
$TFY_API_SH GET /api/svc/v1/clusters/CLUSTER_ID/get-addons
```

Lists installed infrastructure: GPU node pools, storage classes, ingress controllers, monitoring stack.
