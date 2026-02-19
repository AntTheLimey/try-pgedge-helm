# Try pgEdge on Kubernetes

Deploy **distributed, active-active PostgreSQL** on Kubernetes — step by step.

This repo walks you through a progressive tutorial:

| Step | What happens |
|------|-------------|
| **Single Primary** | Deploy one pgEdge node with a single Postgres instance |
| **HA with Replicas** | Add a synchronous read replica for high availability |
| **Multi-Master** | Add a second node with Spock active-active replication |
| **Prove It Works** | Write on one node, read on the other |

Each step is a `helm upgrade`, so you watch the cluster evolve.

## Quick Start

### Option 1: Browser (Killercoda)

Zero install — runs entirely in your browser on a pre-configured Kubernetes environment.

[![Open in Killercoda](https://img.shields.io/badge/Open%20in-Killercoda-blue?logo=kubernetes)](https://killercoda.com/antthelimey/scenario/killercoda)

### Option 2: GitHub Codespace

Full development environment with VS Code, kubectl, Helm, and kind.

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/AntTheLimey/try-pgedge-helm?quickstart=1)

Once the Codespace is ready, run:

```bash
./guide.sh
```

Or open `WALKTHROUGH.md` in the editor — each code block has a **Run** button you can click to execute it directly.

### Option 3: Run Locally

Requirements: Docker and git. The install script will auto-install kind, kubectl, and Helm if missing.

```bash
curl -fsSL https://raw.githubusercontent.com/AntTheLimey/try-pgedge-helm/main/install.sh | bash
```

### Option 4: Use Your Own Cluster

If you already have a Kubernetes cluster (EKS, GKE, AKS, bare metal, etc.) with `kubectl` configured, Docker and kind are **not required**. The install script detects your cluster automatically and only installs the operators (cert-manager and CloudNativePG).

```bash
# Verify kubectl can reach your cluster
kubectl cluster-info

# Then run the same install script — it skips Docker/kind automatically
curl -fsSL https://raw.githubusercontent.com/AntTheLimey/try-pgedge-helm/main/install.sh | bash
```

## Architecture

```
┌─────────────────────────────────────────────────┐
│                  Kubernetes                      │
│                                                  │
│  ┌──────────────┐       ┌──────────────┐        │
│  │  pgEdge n1   │◄─────►│  pgEdge n2   │        │
│  │              │ Spock  │              │        │
│  │  ┌────────┐  │  A-A   │  ┌────────┐  │        │
│  │  │Primary │  │       │  │Primary │  │        │
│  │  └────────┘  │       │  └────────┘  │        │
│  │  ┌────────┐  │       │              │        │
│  │  │Replica │  │       │              │        │
│  │  └────────┘  │       │              │        │
│  │  (CNPG HA)  │       │  (CNPG)     │        │
│  └──────────────┘       └──────────────┘        │
│                                                  │
│  cert-manager  ·  CloudNativePG operator         │
└─────────────────────────────────────────────────┘
```

**pgEdge** adds active-active multi-master replication to PostgreSQL via [Spock](https://docs.pgedge.com), deployed with the [pgEdge Helm chart](https://github.com/pgedge/pgedge-helm). Each node is a CNPG-managed PostgreSQL cluster that can independently accept reads and writes.

## What's Inside

```
├── killercoda/          # Killercoda browser scenario
│   ├── index.json       # Scenario configuration
│   ├── intro/           # Background installer + intro text
│   ├── step1-6/         # Tutorial steps with verification
│   ├── finish/          # Congratulations page
│   └── assets/          # Values files (resource-constrained)
├── values/              # Values files (unconstrained, for Codespace/local)
├── scripts/
│   └── setup-cluster.sh # Kind + operator installer
├── guide.sh             # Interactive CLI walkthrough
├── WALKTHROUGH.md       # Runme-compatible step-by-step guide
└── .devcontainer/       # GitHub Codespace configuration
```

## Learn More

- [pgEdge Helm Chart](https://github.com/pgedge/pgedge-helm) — Full chart documentation
- [pgEdge Documentation](https://docs.pgedge.com) — Spock replication, conflict resolution, and more
- [pgEdge Cloud](https://www.pgedge.com) — Managed distributed PostgreSQL
