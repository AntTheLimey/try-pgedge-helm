# pgEdge Kubernetes Walkthrough

Step-by-step guide to deploying distributed PostgreSQL on Kubernetes with pgEdge.
Each code block below has a **Run** button — click it to execute the command directly in the terminal.

## Step 1: Set Up the Cluster

Create a kind cluster and install the required operators (cert-manager, CNPG, pgEdge chart repo):

```bash
bash scripts/setup-cluster.sh
```

Verify everything is running:

```bash
kubectl get nodes
```

```bash
kubectl get deployment -n cnpg-system
```

```bash
kubectl get pods -n cert-manager
```

## Step 2: Deploy a Single Primary

Start with one pgEdge node running a single Postgres instance:

```bash
helm install pgedge pgedge/pgedge -f values/step1-single-primary.yaml
```

The CNPG operator is creating a PostgreSQL pod. Wait for it to be ready, then check the status:

```bash
kubectl wait --for=condition=Ready pod -l cnpg.io/cluster=pgedge-n1 --timeout=180s
```

```bash
kubectl cnpg status pgedge-n1
```

Verify the database is reachable:

```bash
kubectl cnpg psql pgedge-n1 -- -d app -c "SELECT version();"
```

## Step 3: Scale with Read Replicas

Upgrade to add a synchronous read replica (instances: 1 → 2):

```bash
helm upgrade pgedge pgedge/pgedge -f values/step2-with-replicas.yaml
```

A second pod is spinning up as a synchronous replica. Wait for it to be ready:

```bash
kubectl wait --for=condition=Ready pod -l cnpg.io/cluster=pgedge-n1 --timeout=180s
```

```bash
kubectl cnpg status pgedge-n1
```

Verify synchronous replication:

```bash
kubectl cnpg psql pgedge-n1 -- -d app -c "SELECT client_addr, state, sync_state FROM pg_stat_replication;"
```

## Step 4: Go Multi-Master

Add a second pgEdge node with Spock active-active replication:

```bash
helm upgrade pgedge pgedge/pgedge -f values/step3-multi-master.yaml
```

The CNPG operator is creating a new cluster for n2, and the pgEdge init-spock job will wire up Spock subscriptions. Wait for both clusters:

```bash
kubectl wait --for=condition=Ready pod -l cnpg.io/cluster=pgedge-n1 --timeout=180s
kubectl wait --for=condition=Ready pod -l cnpg.io/cluster=pgedge-n2 --timeout=180s
```

Check both clusters:

```bash
kubectl cnpg status pgedge-n1
```

```bash
kubectl cnpg status pgedge-n2
```

Verify Spock replication:

```bash
kubectl cnpg psql pgedge-n1 -- -d app -c "SELECT * FROM spock.sub_show_status();"
```

## Step 5: Prove Replication

Create a table and insert data on n1:

```bash
kubectl cnpg psql pgedge-n1 -- -d app -c "
CREATE TABLE cities (
  id INT PRIMARY KEY,
  name TEXT NOT NULL,
  country TEXT NOT NULL
);"
```

```bash
kubectl cnpg psql pgedge-n1 -- -d app -c "
INSERT INTO cities (id, name, country) VALUES
  (1, 'New York', 'USA'),
  (2, 'London', 'UK'),
  (3, 'Tokyo', 'Japan');"
```

Read on n2 — data should already be there:

```bash
kubectl cnpg psql pgedge-n2 -- -d app -c "SELECT * FROM cities;"
```

Write on n2:

```bash
kubectl cnpg psql pgedge-n2 -- -d app -c "
INSERT INTO cities (id, name, country) VALUES
  (4, 'Sydney', 'Australia'),
  (5, 'Berlin', 'Germany');"
```

Read back on n1 — all 5 rows should be there:

```bash
kubectl cnpg psql pgedge-n1 -- -d app -c "SELECT * FROM cities ORDER BY id;"
```

## Cleanup

To tear down the demo environment:

```bash
helm uninstall pgedge
```

```bash
kind delete cluster --name pgedge-demo
```

## Learn More

- [pgEdge Helm Chart](https://github.com/pgedge/pgedge-helm)
- [pgEdge Documentation](https://docs.pgedge.com)
- [pgEdge Cloud](https://www.pgedge.com)
