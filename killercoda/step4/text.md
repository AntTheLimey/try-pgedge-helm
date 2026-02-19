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

This upgrade takes a bit longer — the CNPG operator creates a new cluster for n2, and the pgEdge init-spock job wires up Spock subscriptions. If you want to watch, open **Tab 2** and run `kubectl get pods -w`. Switch back to **Tab 1** to continue.

## Check both clusters

When it finishes, both clusters are ready:

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
