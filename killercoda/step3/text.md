# Scale with Read Replicas

Now let's upgrade the deployment to add a **synchronous read replica**. This gives you high availability — if the primary fails, the replica can take over with zero data loss.

## Review the changes

Compare the step 2 values with step 1:

```bash
diff ~/step1-single-primary.yaml ~/step2-with-replicas.yaml
```

Key changes:
- `instances: 2` — adds a replica to node n1
- Synchronous replication is configured with `dataDurability: required`

## Upgrade the release

```bash
helm upgrade pgedge pgedge/pgedge -f ~/step2-with-replicas.yaml
```

## Watch the replica come up

```bash
kubectl get pods -w
```

Press `Ctrl+C` once you see both pods running. The new pod will have a `-2` suffix.

## Check the cluster status

```bash
kubectl cnpg status pgedge-n1
```

You should now see:
- **Instances:** 2
- **Ready instances:** 2
- One primary and one replica with **synchronous** replication

## Verify replication is working

```bash
kubectl cnpg psql pgedge-n1 -- -d app -c "SELECT client_addr, state, sync_state FROM pg_stat_replication;"
```

You should see one row with `sync_state = sync`, confirming the replica is receiving changes synchronously.

**Next:** Let's add a second pgEdge node for active-active multi-master replication.
