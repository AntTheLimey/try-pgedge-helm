# pgEdge Quickstart

Deploy distributed, active-active PostgreSQL on Kubernetes in under 5 minutes.

> Want a guided walkthrough instead?
> [Killercoda](https://killercoda.com/pgedge/scenario/distributed-postgres) (browser)
> | [Codespaces](https://codespaces.new/AntTheLimey/try-pgedge-helm?quickstart=1) (VS Code)
> | [Local guide](./guide.sh) (Docker + kind)

## Prerequisites

A Kubernetes cluster with kubectl and Helm installed.

### Install cert-manager and CloudNativePG operator

```bash
# cert-manager — handles TLS certificates for database connections
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml
kubectl wait --for=condition=Available deployment --all -n cert-manager --timeout=120s

# CloudNativePG — manages PostgreSQL as a native Kubernetes resource
kubectl apply --server-side -f https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/main/releases/cnpg-1.25.1.yaml
kubectl wait --for=condition=Available deployment -l app.kubernetes.io/name=cloudnative-pg -n cnpg-system --timeout=120s
```

### Install the cnpg kubectl plugin

```bash
curl -sSfL https://github.com/cloudnative-pg/cloudnative-pg/raw/main/hack/install-cnpg-plugin.sh | sudo sh -s -- -b /usr/local/bin
```

### Add the pgEdge Helm repo

```bash
helm repo add pgedge https://pgedge.github.io/charts
helm repo update
```

## Deploy

Install a 2-node multi-master cluster. Both nodes accept reads and writes
via Spock active-active replication:

```bash
helm install pgedge pgedge/pgedge -f values/quickstart.yaml
```

Wait for both nodes to be ready:

```bash
kubectl wait --for=condition=Ready pod -l cnpg.io/cluster=pgedge-n1 --timeout=300s
kubectl wait --for=condition=Ready pod -l cnpg.io/cluster=pgedge-n2 --timeout=300s
```

Check Spock subscriptions are active:

```bash
kubectl cnpg psql pgedge-n1 -- -d app -c "SELECT sub_name, status FROM spock.sub_show_status();"
```

## Verify replication

Create a table on n1, insert on n2, read back on n1:

```bash
kubectl cnpg psql pgedge-n1 -- -d app -c "CREATE TABLE test (id int primary key, data text);"
kubectl cnpg psql pgedge-n2 -- -d app -c "INSERT INTO test VALUES (1, 'written on n2');"
kubectl cnpg psql pgedge-n1 -- -d app -c "SELECT * FROM test;"
```

If you see the row on n1, active-active replication is working.

## What's next

### More topologies

The [`helm-examples/`](./helm-examples/) directory has ready-to-deploy values for common topologies:

| Topology | Nodes | Instances | Use case |
|---|---|---|---|
| [`single-primary/`](./helm-examples/single-primary/) | 1 | 1 | Dev/test, CI pipelines |
| [`primary-with-replicas/`](./helm-examples/primary-with-replicas/) | 1 | 3 | Read scaling, single-region HA |
| [`multi-master/`](./helm-examples/multi-master/) | 3 | 3 | Active-active writes across 3 regions |
| [`multi-master-with-replicas/`](./helm-examples/multi-master-with-replicas/) | 3 | 9 | Full production — multi-master + HA per region |

Each includes a `kind.yaml` for local testing.

### Step-by-step walkthrough

Want to see how the architecture evolves from a single primary through HA to multi-master? See [WALKTHROUGH.md](./WALKTHROUGH.md) for the progressive guide.

### Documentation

- [pgEdge Helm Chart](https://github.com/pgedge/pgedge-helm) — full configuration reference
- [pgEdge Documentation](https://docs.pgedge.com) — Spock replication, conflict resolution, operations
- [pgEdge Cloud](https://www.pgedge.com) — managed distributed PostgreSQL

## Cleanup

```bash
helm uninstall pgedge
```
