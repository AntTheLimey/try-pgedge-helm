# pgEdge Kubernetes Interactive Demo Experience — Design

**Date:** 2026-02-13
**Status:** Draft
**Scope:** Containers & Kubernetes section of the developer experience hub

## Context

pgEdge provides a Helm chart for deploying distributed PostgreSQL on Kubernetes, built on the CloudNativePG (CNPG) operator with Spock active-active replication. The developer hub prototype has a Kubernetes section with mock "try it" buttons. This design defines what those buttons actually do.

## Audience

DevOps and SysOps engineers evaluating pgEdge as their distributed Postgres solution on Kubernetes. They want to see real Helm charts, real `kubectl cnpg` commands, and actual cluster behavior — not a toy demo. They are the infrastructure decision-makers.

## Goals

1. Let evaluators deploy pgEdge via Helm + CNPG on a real K8s cluster
2. Prove Spock active-active replication works (write on node 1, read on node 2, and vice versa)
3. Guide them through doing it themselves (hand-holding, not pre-baked results)
4. Provide multiple paths at different friction levels
5. Zero pgEdge-managed infrastructure

## Non-Goals

- Browser-based terminal (explicitly out of scope — security and reliability concerns)
- Demonstrating pgEdge Enterprise Postgres without K8s (separate section of the dev hub)
- Multi-cluster deployments (stretch goal, not in initial scope)
- Custom sandbox infrastructure (no session manager, no sandbox.pgedge.com)

## Decision: Three "Ways to Try"

Each path targets a different friction level and user moment:

| Path | Mechanism | Friction | User Moment |
|------|-----------|----------|-------------|
| **Try It Now** | Killercoda scenario | Zero install | "I'm browsing the site, let me try this in 30 seconds" |
| **Open in Codespace** | GitHub Codespace | Low (GitHub account) | "I'm evaluating seriously, give me a full environment" |
| **Run Locally** | Link to existing quickstart | Medium (tools required) | "I want to run this on my own infra" |

## Repo Structure

One new repo: `try-pgedge-helm` (mirrors pattern of `try-pgedge-mcp-server`)

```
try-pgedge-helm/
  README.md                          # Landing page: Codespace badge, Killercoda link, local quickstart link
  .devcontainer/
    devcontainer.json                # Codespace config: kind, helm, kubectl, cnpg plugin, Docker-in-Docker
    Dockerfile                       # (if needed for tool pre-installation)
  .vscode/
    walkthroughs/
      pgedge-k8s.json               # VS Code Walkthrough definition
  killercoda/
    index.json                       # Scenario config, points to kubernetes-kubeadm-1node-4GB
    intro/
      text.md                        # Architecture overview
      background.sh                  # Installs helm, cert-manager, CNPG operator, cnpg plugin
      foreground.sh                  # Shows progress spinner
    step1/
      text.md                        # Inspect the environment
      verify.sh
    step2/
      text.md                        # Configure your deployment
      verify.sh
    step3/
      text.md                        # Deploy pgEdge with Helm
      verify.sh
    step4/
      text.md                        # Verify cluster health
      verify.sh
    step5/
      text.md                        # Prove Spock replication (the "aha" moment)
      verify.sh
    step6/
      text.md                        # Explore and next steps
    finish/
      text.md                        # Links to Codespace, docs, GitHub
    assets/
      values-demo.yaml               # Tuned for 4GB Killercoda environment
  guide.sh                           # Interactive CLI guide (used in Codespace terminal)
  values-demo.yaml                   # Demo-tuned Helm values for Codespace/local (3 nodes)
  scripts/
    setup-cluster.sh                 # Creates kind cluster + installs operators (Codespace)
    verify-health.sh                 # Checks all pgEdge nodes are healthy
    prove-replication.sh             # Runs the write-n1/read-n2 demo
```

## The Shared Tutorial Journey

All paths walk through the same 6 logical steps, adapted to each delivery mechanism:

### Step 1: Orient
What you're about to deploy: 3 pgEdge Postgres nodes, each managed by CloudNativePG, connected via Spock active-active replication. Architecture overview.

### Step 2: Bootstrap K8s Infrastructure
- **Killercoda:** Already done in background script (CNPG + cert-manager pre-installed while user reads intro)
- **Codespace:** User runs `./scripts/setup-cluster.sh` or follows VS Code Walkthrough steps
- **Local:** User follows existing quickstart (`kind create cluster` + operator installation)

### Step 3: Configure the Deployment
Examine `values.yaml`. Understand the key settings: node names, hostnames, storage size, Spock conflict resolution. User can modify or use the demo defaults.

### Step 4: Deploy pgEdge
```sh
helm install pgedge pgedge/pgedge --values values-demo.yaml --wait
```
Watch pods come up. Explain what CNPG is doing (managing Postgres lifecycle, bootstrapping instances).

### Step 5: Verify Health
```sh
kubectl cnpg status pgedge-n1
kubectl cnpg status pgedge-n2
kubectl cnpg status pgedge-n3
```
All clusters should report "Cluster in healthy state."

### Step 6: Prove Replication (The Payoff)
```sh
# Create table on node 1
kubectl cnpg psql pgedge-n1 -- -U app app -c "CREATE TABLE demo (id int primary key, data text);"

# Insert on node 2
kubectl cnpg psql pgedge-n2 -- -U app app -c "INSERT INTO demo VALUES (1, 'Hello from node 2!');"

# Read on node 1 — data is there via Spock replication
kubectl cnpg psql pgedge-n1 -- -U app app -c "SELECT * FROM demo;"

# Insert on node 1
kubectl cnpg psql pgedge-n1 -- -U app app -c "INSERT INTO demo VALUES (2, 'Hello from node 1!');"

# Read on node 3 — active-active proven
kubectl cnpg psql pgedge-n3 -- -U app app -c "SELECT * FROM demo;"
```

Optional: Load Northwind dataset for more realistic exploration.

## Path 1: Killercoda — Detailed Design

### Environment
- Image: `kubernetes-kubeadm-1node-4GB` (single K8s node, 4GB RAM, kubeadm)
- Session: 60 minutes (free tier), 4 hours (PLUS)

### Background Setup (runs while user reads intro)
`intro/background.sh` installs:
1. Helm (binary download)
2. kubectl cnpg plugin (binary download from pgEdge releases)
3. cert-manager (`kubectl apply`)
4. CNPG operator (Helm install from pgEdge chart repo)

Estimated time: 3-5 minutes. User reads architecture overview during this time.

### Resource-Constrained values.yaml
The Killercoda `values-demo.yaml` is tuned for 4GB:
- 3 pgEdge nodes (target), each with 1 CNPG instance
- Low resource requests: `cpu: 100m`, `memory: 128Mi` per Postgres pod
- Low resource limits: `cpu: 500m`, `memory: 256Mi` per Postgres pod
- Storage: `500Mi` per node
- If 3 nodes causes OOM, fall back to 2-node variant

### Verification Scripts
Each step has a `verify.sh` that gates progression:
- Step 1: `kubectl get nodes` returns Ready
- Step 2: `values.yaml` file exists
- Step 3: All pgEdge pods in Running state
- Step 4: `kubectl cnpg status` reports healthy for all nodes
- Step 5: Query returns expected data on cross-node read

### Finish Page
Links to:
- Codespace for deeper exploration (full environment, no resource limits)
- Existing quickstart for local deployment
- pgEdge Helm chart documentation
- GitHub repo

### Key Risk
3 Postgres pods + CNPG operator + cert-manager on 4GB may be too tight. **This must be validated empirically before writing tutorial content.** If it fails, the fallback is 2 nodes, which still proves active-active replication.

## Path 2: Codespace — Detailed Design

### Devcontainer Configuration
Based on the proven pattern from `try-pgedge-mcp-server`:

```json
{
  "name": "pgEdge Helm - Kubernetes Demo",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/devcontainers/features/docker-in-docker:2": {},
    "ghcr.io/devcontainers/features/kubectl-helm-minikube:1": {
      "helm": "latest",
      "kubectl": "latest",
      "minikube": "none"
    }
  },
  "postCreateCommand": ".devcontainer/post-create.sh",
  "customizations": {
    "vscode": {
      "extensions": ["stateful.runme"],
      "settings": {
        "workbench.startupEditor": "walkThrough"
      }
    }
  }
}
```

`post-create.sh` installs:
- kind (binary download)
- kubectl cnpg plugin (from pgEdge releases)

### VS Code Walkthrough
Uses the VS Code Walkthrough API (`.vscode/walkthroughs/pgedge-k8s.json`). Each step has:
- Title and description
- "Run in Terminal" command button
- Completion criteria (file exists, command succeeds)

Steps mirror the shared tutorial journey. The walkthrough appears automatically on Codespace launch.

### Interactive CLI Guide (`guide.sh`)
For terminal-first users. Colored output, explanations between commands, "Press Enter to continue" prompts. Runs in the Codespace terminal or on any machine with prerequisites installed.

### No Resource Constraints
Codespace provides 4-core/8GB minimum. Kind with 3 worker nodes + full pgEdge deployment runs comfortably. This is the "full experience" — 3 nodes, full Spock replication, room to experiment.

## Path 3: Run Locally — Existing Quickstart

The existing `pgedge-helm` quickstart doc already covers:
- Prerequisites (kind, helm, kubectl, cnpg plugin)
- Kind cluster creation
- Operator installation (CNPG + cert-manager)
- Helm chart installation with example values
- Connecting to each node
- Testing replication
- Loading Northwind sample data
- Uninstalling

The `examples/Makefile` automates infrastructure setup (`make single-up`).

**No new work needed.** The dev hub links to the existing quickstart.

## Dev Hub Integration

The prototype's Containers & Kubernetes section gets three launch options:

| Button | Target |
|--------|--------|
| "Try It Now" | `https://killercoda.com/pgedge/scenario/pgedge-helm-quickstart` |
| "Open in Codespace" | Codespace deeplink for `try-pgedge-helm` repo |
| "Run Locally" | Link to `pgedge-helm` quickstart documentation |

The existing terminal animations in the prototype stay — they preview the experience.

## Build Order

1. **Validate Killercoda resource limits** — Spin up a Killercoda 4GB environment manually. Install CNPG + cert-manager + 3-node pgEdge. Determine if 3 nodes fit or if we need 2. This is the gating question.
2. **Build Killercoda scenario** — Fastest path to a linkable, testable demo. Forces us to finalize tutorial content.
3. **Build Codespace** — Devcontainer + VS Code Walkthrough + guide.sh. Builds on the same tutorial content.
4. **Update dev hub prototype** — Replace mock buttons with real links.

## Open Questions

1. Does 3-node pgEdge fit in Killercoda's 4GB environment? (Must test empirically)
2. Killercoda creator account — does pgEdge already have one, or do we create `pgedge` on killercoda.com?
3. Should the Codespace `guide.sh` also be contributed to `pgedge-helm` as an alternative to the Makefile?
4. VHS terminal recordings for docs/marketing — worth generating in CI as a complement? (Stretch goal)
