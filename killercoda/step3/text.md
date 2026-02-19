# Scale with Read Replicas

Now let's upgrade the deployment to add a **synchronous read replica**. This gives you high availability — if the primary fails, the replica takes over with zero data loss.

## Review the changes

Compare the step 2 values with step 1:

```bash
diff ~/step1-single-primary.yaml ~/step2-with-replicas.yaml
```

Key changes:
- `instances: 1` → `instances: 2` — adds a replica to node n1
- Synchronous replication is configured with `dataDurability: required`

## Upgrade the release

This is a `helm upgrade`, not a new install. The existing primary stays running while the replica is added:

```bash
helm upgrade pgedge pgedge/pgedge -f ~/step2-with-replicas.yaml
```

## Watch the replica come up

This command watches pods in real time. Wait until you see a second pod (with a `-2` suffix) show `1/1 Running`, then press `Ctrl+C` to stop:

```bash
kubectl get pods -w
```

## Check the cluster status

You should now see 2 instances — one primary and one standby with `(sync)` role:

```bash
kubectl cnpg status pgedge-n1
```

## Verify replication is working

This query shows the replication connection from the primary's perspective. Look for `sync_state = sync` or `quorum`:

```bash
kubectl cnpg psql pgedge-n1 -- -d app -c "SELECT client_addr, state, sync_state FROM pg_stat_replication;"
```

The replica is receiving all changes synchronously — every committed write is guaranteed to be on both instances before the transaction completes.

**Next:** Let's add a second pgEdge node for active-active multi-master replication.
