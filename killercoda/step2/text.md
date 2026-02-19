# Deploy a Single Primary

Let's start simple: one pgEdge node with a single PostgreSQL instance.

## Install the chart

```bash
helm install pgedge pgedge/pgedge -f ~/step1-single-primary.yaml
```

## Wait for the cluster to be ready

The CNPG operator will create a PostgreSQL cluster. Watch it come up:

```bash
kubectl get pods -w
```

Press `Ctrl+C` once you see the pod in `Running` state (this usually takes about 60 seconds).

## Check the cluster status

```bash
kubectl cnpg status pgedge-n1
```

You should see:
- **Instances:** 1
- **Ready instances:** 1
- **Status:** Cluster in healthy state

## Connect and verify

The pgEdge chart creates a database called `app` with the Spock extension. Let's connect and confirm:

```bash
kubectl cnpg psql pgedge-n1 -- -d app -c "SELECT version();"
```

You now have a single PostgreSQL primary running in Kubernetes, managed by the CNPG operator and deployed via the pgEdge Helm chart.

**Next:** Let's add a read replica for high availability.
