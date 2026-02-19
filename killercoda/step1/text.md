# Inspect Your Environment

Before deploying anything, let's verify that all the components installed correctly.

## Check Kubernetes

```bash
kubectl get nodes
```

You should see a single node in `Ready` state.

## Check Helm

```bash
helm version --short
```

## Check the CNPG operator

The CloudNativePG operator manages PostgreSQL clusters as native Kubernetes resources.

```bash
kubectl get deployment -n cnpg-system
```

## Check cert-manager

cert-manager handles TLS certificates for secure cluster communication.

```bash
kubectl get pods -n cert-manager
```

All pods should be `Running`.

## Check the cnpg plugin

```bash
kubectl cnpg version
```

## Check the pgEdge Helm chart

```bash
helm search repo pgedge
```

You should see the `pgedge/pgedge` chart listed.

## Review the values files

Three values files were placed in your home directory — one for each step of this tutorial:

```bash
ls ~/step*.yaml
```

Take a quick look at the first one:

```bash
cat ~/step1-single-primary.yaml
```

This defines a single pgEdge node (`n1`) with one Postgres instance. In the next steps, you'll upgrade this to add replicas and a second node.
