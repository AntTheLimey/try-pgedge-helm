# Go Multi-Master

This is where pgEdge shines. You'll add a **second pgEdge node** (`n2`) with **Spock active-active replication**. Both nodes can accept writes, and changes replicate bidirectionally.

## Review the changes

```bash
diff ~/step2-with-replicas.yaml ~/step3-multi-master.yaml
```

Key change: a second node `n2` is added to the `nodes` list. The pgEdge Helm chart automatically configures Spock logical replication between n1 and n2.

## Upgrade the release

```bash
helm upgrade pgedge pgedge/pgedge -f ~/step3-multi-master.yaml
```

## Watch both nodes come up

```bash
kubectl get pods -w
```

Press `Ctrl+C` once you see pods for both `pgedge-n1` and `pgedge-n2` in `Running` state.

## Check both clusters

```bash
kubectl cnpg status pgedge-n1
```

```bash
kubectl cnpg status pgedge-n2
```

## Verify Spock replication

Once both nodes are healthy, check the Spock subscription status:

```bash
kubectl cnpg psql pgedge-n1 -- -d app -c "SELECT * FROM spock.sub_show_status();"
```

```bash
kubectl cnpg psql pgedge-n2 -- -d app -c "SELECT * FROM spock.sub_show_status();"
```

Both should show subscriptions in a replicating state.

You now have a **distributed, active-active PostgreSQL cluster** running on Kubernetes. Both nodes accept reads and writes, with changes replicating automatically via Spock.

**Next:** Let's prove it works by writing data on one node and reading it on the other.
