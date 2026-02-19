# Explore & Next Steps

Congratulations — you have a working distributed PostgreSQL cluster! Here are some things to try.

## Load sample data

```bash
kubectl cnpg psql pgedge-n1 -- -d app -c "
CREATE TABLE products (
  id INT PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT,
  price DECIMAL(10,2)
);

INSERT INTO products (id, name, category, price) VALUES
  (1, 'Chai', 'Beverages', 18.00),
  (2, 'Chang', 'Beverages', 19.00),
  (3, 'Aniseed Syrup', 'Condiments', 10.00),
  (4, 'Cajun Seasoning', 'Condiments', 22.00),
  (5, 'Olive Oil', 'Condiments', 21.35);"
```

Verify it replicated:

```bash
kubectl cnpg psql pgedge-n2 -- -d app -c "SELECT * FROM products;"
```

## Inspect Spock configuration

See how Spock manages replication sets:

```bash
kubectl cnpg psql pgedge-n1 -- -d app -c "SELECT * FROM spock.replication_set;"
```

```bash
kubectl cnpg psql pgedge-n1 -- -d app -c "SELECT * FROM spock.node;"
```

## Optional: Add a third node

If resources allow, you can add a third pgEdge node. Create a new values file:

```bash
cat > ~/step4-three-nodes.yaml << 'EOF'
pgEdge:
  appName: pgedge
  nodes:
    - name: n1
      hostname: pgedge-n1-rw
      clusterSpec:
        instances: 2
        postgresql:
          synchronous:
            method: any
            number: 1
            dataDurability: required
    - name: n2
      hostname: pgedge-n2-rw
    - name: n3
      hostname: pgedge-n3-rw
      bootstrap:
        mode: spock
        sourceNode: n1
  clusterSpec:
    instances: 1
    storage:
      size: 512Mi
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 500m
        memory: 256Mi
EOF
```

```bash
helm upgrade pgedge pgedge/pgedge -f ~/step4-three-nodes.yaml
```

> **Note:** Adding a third node requires additional resources. In the Killercoda 4GB environment, this may cause memory pressure. If pods get stuck in `Pending` or are `OOMKilled`, that's expected — it just means you've hit the environment limits.

## Useful commands reference

| Command | What it does |
|---------|-------------|
| `kubectl cnpg status <cluster>` | Show cluster health and replication |
| `kubectl cnpg psql <cluster> -- -d app` | Open a psql shell to the app database |
| `kubectl get pods -o wide` | See all pods with node placement |
| `kubectl logs <pod>` | View pod logs |
| `helm list` | See installed Helm releases |
| `helm get values pgedge` | See current values for the release |
