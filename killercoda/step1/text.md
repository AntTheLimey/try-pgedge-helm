# Inspect Your Environment

The background script installed several components while you were reading the intro. Let's verify everything is ready before deploying.

## Check Kubernetes

Your environment has a single-node Kubernetes cluster:

```bash
kubectl get nodes
```

You should see one node in `Ready` state.

## Check Helm

Helm is the package manager we'll use to deploy pgEdge:

```bash
helm version --short
```

## Check the CNPG operator

The CloudNativePG (CNPG) operator manages PostgreSQL clusters as native Kubernetes resources — it handles pod creation, failover, replication, and more:

```bash
kubectl get deployment -n cnpg-system
```

## Check cert-manager

cert-manager handles TLS certificates so that nodes communicate securely:

```bash
kubectl get pods -n cert-manager
```

All pods should be `Running`.

## Check the cnpg plugin

The cnpg kubectl plugin gives us commands like `cnpg status` and `cnpg psql`:

```bash
kubectl cnpg version
```

## Check the pgEdge Helm chart

The pgEdge chart is what we'll install and progressively upgrade:

```bash
helm search repo pgedge
```

You should see the `pgedge/pgedge` chart listed.

## Review the values files

Three values files are in your home directory — one for each step of this tutorial:

```bash
ls ~/step*.yaml
```

Take a quick look at the first one:

```bash
cat ~/step1-single-primary.yaml
```

This defines a single pgEdge node (`n1`) with one Postgres instance. In the next steps, you'll upgrade this to add replicas and a second node.
