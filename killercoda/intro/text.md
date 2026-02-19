# pgEdge Distributed Postgres on Kubernetes

In this scenario you'll progressively build a **distributed PostgreSQL cluster** using pgEdge on Kubernetes. Instead of deploying everything at once, you'll evolve the architecture step-by-step:

| Step | What you'll do |
|------|---------------|
| **Single Primary** | Deploy one pgEdge node with a single Postgres instance |
| **HA with Replicas** | Add a synchronous read replica for high availability |
| **Multi-Master** | Add a second pgEdge node with Spock active-active replication |
| **Prove It Works** | Write data on one node, read it on the other |

Each step is a `helm upgrade`, so you'll see the cluster evolve in real time.

## What's being installed

While you read this, a background script is installing:

- **Helm** — Kubernetes package manager
- **CloudNativePG (CNPG)** operator — manages PostgreSQL clusters as Kubernetes resources
- **cert-manager** — handles TLS certificates for secure communication
- **cnpg kubectl plugin** — CLI tool for inspecting CNPG clusters
- **pgEdge Helm chart** — the chart you'll use to deploy pgEdge

This takes about 2 minutes. You'll see a confirmation when it's ready.
