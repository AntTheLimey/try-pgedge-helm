# Go Multi-Master

This is where pgEdge shines. You'll add a **second pgEdge node** (`n2`) with **Spock active-active replication**. Both nodes will accept writes, and changes replicate bidirectionally.

Unlike the read replica in the previous step (which only accepts reads), both n1 and n2 are full read-write nodes.

## Review the changes

```bash
diff ~/step2-with-replicas.yaml ~/step3-multi-master.yaml
```

Key change: a second node `n2` is added to the `nodes` list with `bootstrap.mode: spock`, which tells the chart to set up Spock logical replication from n1 to n2 automatically.

## Upgrade the release

```bash
helm upgrade pgedge pgedge/pgedge -f ~/step3-multi-master.yaml
```

## Watch both nodes come up

This command watches pods in real time. Wait until you see pods for both `pgedge-n1` and `pgedge-n2` in `Running` state, then press `Ctrl+C` to stop:

```bash
kubectl get pods -w
```

## Check both clusters

Each pgEdge node is its own CNPG cluster:

```bash
kubectl cnpg status pgedge-n1
```

```bash
kubectl cnpg status pgedge-n2
```

## Verify Spock replication

Once both nodes are healthy, check the Spock subscription status. Each node subscribes to the other — that's what makes it active-active:

```bash
kubectl cnpg psql pgedge-n1 -- -d app -c "SELECT * FROM spock.sub_show_status();"
```

```bash
kubectl cnpg psql pgedge-n2 -- -d app -c "SELECT * FROM spock.sub_show_status();"
```

Both should show subscriptions with status `replicating`.

You now have a **distributed, active-active PostgreSQL cluster** running on Kubernetes. Both nodes accept reads and writes, with changes replicating automatically via Spock.

**Next:** Let's prove it works by writing data on one node and reading it on the other.
