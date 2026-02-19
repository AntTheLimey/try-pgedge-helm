# Deploy a Single Primary

Let's start with the simplest possible deployment: one pgEdge node running a single PostgreSQL instance.

## Install the chart

The values file defines just one node (`n1`) with 1 instance:

```bash
helm install pgedge pgedge/pgedge -f ~/step1-single-primary.yaml
```

The helm command takes about a minute — when it returns, the pod is ready. If you want to see what's happening while it runs, open **Tab 2** and run `kubectl get pods -w` to watch the pod come up. Switch back to **Tab 1** to continue.

## Check the cluster status

This shows instance count, replication state, and overall health:

```bash
kubectl cnpg status pgedge-n1
```

You should see:
- **Instances:** 1
- **Ready instances:** 1
- **Status:** Cluster in healthy state

## Connect and verify

The pgEdge chart creates a database called `app` with the Spock extension pre-installed. Let's connect and confirm it's working:

```bash
kubectl cnpg psql pgedge-n1 -- -d app -c "SELECT version();"
```

You now have a single PostgreSQL primary running in Kubernetes, managed by the CNPG operator and deployed via the pgEdge Helm chart.

**Next:** Let's add a read replica for high availability.
