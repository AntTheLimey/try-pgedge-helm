# pgEdge Kubernetes Interactive Demos — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build three "ways to try" the pgEdge Helm chart on Kubernetes: a Killercoda browser scenario, a GitHub Codespace with guided walkthrough, and a link to the existing quickstart.

**Architecture:** A single `try-pgedge-helm` repo contains Killercoda scenario files, a devcontainer for Codespaces, a VS Code Walkthrough, and an interactive CLI guide. All paths share the same tutorial content (deploy pgEdge, prove Spock replication). The "Run Locally" path links to the existing `pgedge-helm` quickstart with zero new work.

**Tech Stack:** Bash scripts, Killercoda scenario format (JSON + Markdown), VS Code Walkthrough API, devcontainer spec, Helm, kind, kubectl, CloudNativePG.

**Reference repos:**
- pgEdge Helm chart: `/Users/apegg/PROJECTS/pgedge-helm` (source for values, examples, Makefile patterns)
- Existing Codespace demo: `/Users/apegg/PROJECTS/try-pgedge-mcp-server` (devcontainer pattern)
- Design doc: `/Users/apegg/PROJECTS/try-pgedge-helm/docs/plans/2026-02-13-kubernetes-interactive-demos-design.md`

---

## Task 1: Validate Killercoda 4GB Resource Limits

This is the **gating task**. We must confirm that 3 pgEdge nodes fit in Killercoda's constrained environment before writing any tutorial content. This task is manual — you can't run Killercoda locally.

**Files:**
- Create: `killercoda/assets/values-killercoda.yaml`
- Create: `values-demo.yaml` (for Codespace/local — unconstrained)

**Step 1: Create the resource-constrained Killercoda values file**

This values file minimizes memory usage for the 4GB Killercoda environment. Each pgEdge node gets 1 CNPG instance with tight resource limits.

```yaml
# killercoda/assets/values-killercoda.yaml
pgEdge:
  appName: pgedge
  nodes:
    - name: n1
      hostname: pgedge-n1-rw
    - name: n2
      hostname: pgedge-n2-rw
    - name: n3
      hostname: pgedge-n3-rw
  clusterSpec:
    instances: 1
    storage:
      size: 512Mi
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 500m
        memory: 256Mi
```

**Step 2: Create the unconstrained Codespace/local values file**

This version has comfortable defaults for environments with 8GB+ RAM.

```yaml
# values-demo.yaml
pgEdge:
  appName: pgedge
  nodes:
    - name: n1
      hostname: pgedge-n1-rw
    - name: n2
      hostname: pgedge-n2-rw
    - name: n3
      hostname: pgedge-n3-rw
  clusterSpec:
    instances: 1
    storage:
      size: 1Gi
```

**Step 3: Test on Killercoda manually**

This step must be done by a human in a browser:

1. Go to https://killercoda.com/playgrounds/course/kubernetes-playgrounds/one-node-4GB
2. Wait for the environment to initialize
3. Run these commands to install prerequisites:

```bash
# Install Helm
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Add pgEdge Helm repo
helm repo add pgedge https://pgedge.github.io/charts && helm repo update

# Install CNPG operator
helm install cnpg pgedge/cloudnative-pg --namespace cnpg-system --create-namespace

# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.19.3/cert-manager.yaml
kubectl wait --for=condition=Available deployment -n cert-manager cert-manager cert-manager-cainjector cert-manager-webhook --timeout=120s
```

4. Check remaining memory:

```bash
kubectl top nodes 2>/dev/null || free -m
```

5. Create the values file (paste contents of `values-killercoda.yaml`) and deploy:

```bash
cat > values.yaml << 'EOF'
pgEdge:
  appName: pgedge
  nodes:
    - name: n1
      hostname: pgedge-n1-rw
    - name: n2
      hostname: pgedge-n2-rw
    - name: n3
      hostname: pgedge-n3-rw
  clusterSpec:
    instances: 1
    storage:
      size: 512Mi
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 500m
        memory: 256Mi
EOF

helm install pgedge pgedge/pgedge --values values.yaml --wait --timeout 300s
```

6. Check results:

```bash
kubectl get pods -o wide
kubectl top pods 2>/dev/null
```

7. **Record the outcome:**
   - If all 3 pgEdge pods reach Running + init-spock job completes: **3 nodes works**
   - If OOM or pods stuck Pending: try 2 nodes (remove n3 from values.yaml, redeploy)
   - If 2 nodes works: update `values-killercoda.yaml` to 2 nodes

**Step 4: Commit the values files**

```bash
git add killercoda/assets/values-killercoda.yaml values-demo.yaml
git commit -m "feat: add demo values files for Killercoda and Codespace

Killercoda values tuned for 4GB environment with tight resource limits.
Codespace values use comfortable defaults for 8GB+ environments."
```

---

## Task 2: Build Killercoda Scenario Structure

**Depends on:** Task 1 (need to know if 3 or 2 nodes fit)

**Files:**
- Create: `killercoda/index.json`
- Create: `killercoda/intro/text.md`
- Create: `killercoda/intro/background.sh`
- Create: `killercoda/intro/foreground.sh`
- Create: `killercoda/assets/wait-background.sh`

**Step 1: Create the scenario index.json**

This is the Killercoda scenario definition. It references the 4GB single-node K8s image and defines all steps.

```json
{
  "title": "Deploy pgEdge Distributed Postgres on Kubernetes",
  "description": "Deploy a multi-node pgEdge Postgres cluster using Helm and CloudNativePG, then prove active-active Spock replication works.",
  "details": {
    "intro": {
      "text": "intro/text.md",
      "background": "intro/background.sh",
      "foreground": "intro/foreground.sh"
    },
    "steps": [
      {
        "title": "Inspect Your Environment",
        "text": "step1/text.md",
        "verify": "step1/verify.sh"
      },
      {
        "title": "Configure Your Deployment",
        "text": "step2/text.md",
        "verify": "step2/verify.sh"
      },
      {
        "title": "Deploy pgEdge with Helm",
        "text": "step3/text.md",
        "verify": "step3/verify.sh"
      },
      {
        "title": "Verify Cluster Health",
        "text": "step4/text.md",
        "verify": "step4/verify.sh"
      },
      {
        "title": "Prove Active-Active Replication",
        "text": "step5/text.md",
        "verify": "step5/verify.sh"
      },
      {
        "title": "Explore and Next Steps",
        "text": "step6/text.md"
      }
    ],
    "finish": {
      "text": "finish/text.md"
    },
    "assets": {
      "host01": [
        {"file": "values-killercoda.yaml", "target": "/root", "chmod": "+r"},
        {"file": "wait-background.sh", "target": "/usr/local/bin", "chmod": "+x"}
      ]
    }
  },
  "backend": {
    "imageid": "kubernetes-kubeadm-1node-4GB"
  }
}
```

**Step 2: Create the intro text**

```markdown
# Deploy pgEdge Distributed Postgres on Kubernetes

In this tutorial, you'll deploy a **pgEdge Distributed PostgreSQL** cluster on Kubernetes using:

- **Helm** — the Kubernetes package manager
- **CloudNativePG (CNPG)** — the operator that manages PostgreSQL lifecycle
- **Spock** — pgEdge's active-active multi-master replication

## What You'll Build

You'll deploy multiple pgEdge Postgres nodes, each running as a separate CNPG-managed cluster. Spock replication connects them so you can **write to any node and read from any other** — true active-active distributed Postgres.

```
┌─────────────┐    Spock    ┌─────────────┐    Spock    ┌─────────────┐
│  pgEdge n1  │◄──────────►│  pgEdge n2  │◄──────────►│  pgEdge n3  │
│  (primary)  │  replicate  │  (primary)  │  replicate  │  (primary)  │
│  CNPG Cluster│            │  CNPG Cluster│            │  CNPG Cluster│
└─────────────┘             └─────────────┘             └─────────────┘
       ▲                           ▲                           ▲
       │         All managed by CloudNativePG Operator         │
       └───────────────────────────┴───────────────────────────┘
```

Every node is a primary — no read-only replicas. Conflicts are resolved automatically using last-update-wins.

## While You Wait

The environment is installing prerequisites in the background (Helm, CloudNativePG operator, cert-manager). This takes about 3-5 minutes. You'll see a "done" message when it's ready.
```

**Step 3: Create the background setup script**

```bash
#!/bin/bash
# killercoda/intro/background.sh
# Runs invisibly while user reads the intro

set -euo pipefail

# Wait for K8s node to be ready
while ! kubectl get nodes | grep -w "Ready"; do
  sleep 2
done

# Install Helm
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Add pgEdge Helm repo
helm repo add pgedge https://pgedge.github.io/charts && helm repo update

# Install CNPG operator
helm install cnpg pgedge/cloudnative-pg \
  --namespace cnpg-system \
  --create-namespace \
  --wait

# Install cert-manager
kubectl apply -f \
  https://github.com/cert-manager/cert-manager/releases/download/v1.19.3/cert-manager.yaml

kubectl wait --for=condition=Available deployment \
  -n cert-manager cert-manager cert-manager-cainjector cert-manager-webhook \
  --timeout=120s

# Install kubectl cnpg plugin
# NOTE: Update this URL to the latest release from https://github.com/pgEdge/pgedge-cnpg-dist/releases
CNPG_PLUGIN_VERSION="1.28.1"
curl -fsSL "https://github.com/pgEdge/pgedge-cnpg-dist/releases/download/kubectl-cnpg%2Fv${CNPG_PLUGIN_VERSION}/kubectl-cnpg_${CNPG_PLUGIN_VERSION}_linux_amd64.tar.gz" \
  | tar -xz -C /usr/local/bin kubectl-cnpg

# Signal completion
touch /tmp/.background-finished
```

**Step 4: Create the foreground spinner script**

```bash
#!/bin/bash
# killercoda/intro/foreground.sh
# Shows progress to the user while background.sh runs

echo "Setting up your environment..."
echo ""
echo -n "Installing Helm, CloudNativePG, and cert-manager"
while [ ! -f /tmp/.background-finished ]; do
  echo -n "."
  sleep 3
done
echo " done!"
echo ""
echo "Your environment is ready. Click 'Next' to begin."
```

**Step 5: Create the wait-background helper**

```bash
#!/bin/bash
# killercoda/assets/wait-background.sh
# Utility to wait for background setup from any step
if [ ! -f /tmp/.background-finished ]; then
  echo "Waiting for environment setup to complete..."
  while [ ! -f /tmp/.background-finished ]; do sleep 2; done
  echo "Ready!"
fi
```

**Step 6: Create directory structure and commit**

```bash
mkdir -p killercoda/{intro,step1,step2,step3,step4,step5,step6,finish,assets}
# (files created above go into their respective directories)
git add killercoda/index.json killercoda/intro/ killercoda/assets/wait-background.sh
git commit -m "feat: add Killercoda scenario structure and background setup

Scenario uses kubernetes-kubeadm-1node-4GB image. Background script
installs Helm, CNPG operator, cert-manager, and cnpg kubectl plugin
while user reads the intro page."
```

---

## Task 3: Write Killercoda Tutorial Steps

**Depends on:** Task 2

**Files:**
- Create: `killercoda/step1/text.md`, `killercoda/step1/verify.sh`
- Create: `killercoda/step2/text.md`, `killercoda/step2/verify.sh`
- Create: `killercoda/step3/text.md`, `killercoda/step3/verify.sh`
- Create: `killercoda/step4/text.md`, `killercoda/step4/verify.sh`
- Create: `killercoda/step5/text.md`, `killercoda/step5/verify.sh`
- Create: `killercoda/step6/text.md`
- Create: `killercoda/finish/text.md`

**Step 1: Write step1 — Inspect Your Environment**

`killercoda/step1/text.md`:
```markdown
# Inspect Your Environment

Let's confirm everything is ready.

Check that your Kubernetes node is running:

```{{exec}}
kubectl get nodes
```

Verify Helm is installed:

```{{exec}}
helm version --short
```

Check that the CloudNativePG operator is running:

```{{exec}}
kubectl get pods -n cnpg-system
```

Check that cert-manager is running:

```{{exec}}
kubectl get pods -n cert-manager
```

Verify the pgEdge Helm chart is available:

```{{exec}}
helm search repo pgedge/pgedge
```

Everything should show healthy pods and available charts. You're ready to deploy.
```

`killercoda/step1/verify.sh`:
```bash
#!/bin/bash
kubectl get pods -n cnpg-system 2>/dev/null | grep -q "Running" && \
kubectl get pods -n cert-manager 2>/dev/null | grep -q "Running" && \
helm search repo pgedge/pgedge 2>/dev/null | grep -q "pgedge"
```

**Step 2: Write step2 — Configure Your Deployment**

`killercoda/step2/text.md`:
```markdown
# Configure Your Deployment

A `values.yaml` file has been placed in your home directory. Let's examine it:

```{{exec}}
cat /root/values-killercoda.yaml
```

This configuration defines:

- **3 pgEdge nodes** (`n1`, `n2`, `n3`) — each becomes a separate CloudNativePG Cluster
- **1 instance per node** — the minimum for a demo (production would use 3 for HA)
- **512Mi storage** per node
- **Spock active-active replication** is enabled by default in the Helm chart

Each node is a full read-write primary. There are no read-only replicas — every node accepts writes, and Spock replicates changes between them.

Copy the values file to your working directory:

```{{exec}}
cp /root/values-killercoda.yaml /root/values.yaml
```

Feel free to examine the full chart defaults:

```{{exec}}
helm show values pgedge/pgedge | head -40
```
```

`killercoda/step2/verify.sh`:
```bash
#!/bin/bash
test -f /root/values.yaml
```

**Step 3: Write step3 — Deploy pgEdge with Helm**

`killercoda/step3/text.md`:
```markdown
# Deploy pgEdge with Helm

Now deploy the pgEdge cluster:

```{{exec}}
helm install pgedge pgedge/pgedge --values /root/values.yaml --wait --timeout 300s
```

This will:
1. Create Certificate resources for TLS authentication (managed by cert-manager)
2. Create 3 CloudNativePG Cluster resources (one per pgEdge node)
3. CNPG operator provisions a PostgreSQL pod for each cluster
4. Run the `init-spock` job to configure Spock replication between all nodes

This takes 2-4 minutes. The `--wait` flag holds until everything is ready.

While waiting, you can watch pods come up in another view:

```{{exec}}
kubectl get pods -w
```

Press `Ctrl+C` to stop watching once you see all pods Running.
```

`killercoda/step3/verify.sh`:
```bash
#!/bin/bash
# Check that all pgEdge pods are Running and the init-spock job completed
kubectl get pods 2>/dev/null | grep "pgedge-n1" | grep -q "Running" && \
kubectl get pods 2>/dev/null | grep "pgedge-n2" | grep -q "Running" && \
kubectl get jobs 2>/dev/null | grep "init-spock" | grep -q "Complete"
```

Note: If only 2 nodes are deployed (per Task 1 outcome), adjust the verify script to check for `n1` and `n2` only, and remove `n3` references from the text.

**Step 4: Write step4 — Verify Cluster Health**

`killercoda/step4/text.md`:
```markdown
# Verify Cluster Health

Use the CloudNativePG kubectl plugin to check the health of each pgEdge node:

```{{exec}}
kubectl cnpg status pgedge-n1
```

```{{exec}}
kubectl cnpg status pgedge-n2
```

```{{exec}}
kubectl cnpg status pgedge-n3
```

Each should report **"Cluster in healthy state"**.

You can also see all pods at a glance:

```{{exec}}
kubectl get pods -o wide
```

You now have 3 independent PostgreSQL primaries, all managed by CloudNativePG, with Spock replication connecting them.
```

`killercoda/step4/verify.sh`:
```bash
#!/bin/bash
kubectl cnpg status pgedge-n1 2>/dev/null | grep -q "Cluster in healthy state" && \
kubectl cnpg status pgedge-n2 2>/dev/null | grep -q "Cluster in healthy state"
```

**Step 5: Write step5 — Prove Active-Active Replication**

`killercoda/step5/text.md`:
```markdown
# Prove Active-Active Replication

This is the payoff. You'll write data on one node and read it from another — proving Spock active-active replication is working.

**Create a table on node 1:**

```{{exec}}
kubectl cnpg psql pgedge-n1 -- -U app app -c "CREATE TABLE demo (id int primary key, data text);"
```

**Insert a row on node 2** (not node 1!):

```{{exec}}
kubectl cnpg psql pgedge-n2 -- -U app app -c "INSERT INTO demo VALUES (1, 'Written on node 2');"
```

**Read it back on node 1** — the data replicated automatically:

```{{exec}}
kubectl cnpg psql pgedge-n1 -- -U app app -c "SELECT * FROM demo;"
```

**Now write on node 1:**

```{{exec}}
kubectl cnpg psql pgedge-n1 -- -U app app -c "INSERT INTO demo VALUES (2, 'Written on node 1');"
```

**Read from node 3** — every node has all the data:

```{{exec}}
kubectl cnpg psql pgedge-n3 -- -U app app -c "SELECT * FROM demo;"
```

That's active-active replication. Every node is a writable primary. Changes propagate automatically via Spock's logical replication.
```

`killercoda/step5/verify.sh`:
```bash
#!/bin/bash
# Verify that data written on one node is readable on another
kubectl cnpg psql pgedge-n1 -- -U app app -t -c "SELECT count(*) FROM demo;" 2>/dev/null | grep -q "2"
```

**Step 6: Write step6 — Explore and Next Steps**

`killercoda/step6/text.md`:
```markdown
# Explore and Next Steps

You've deployed pgEdge Distributed Postgres and proven active-active replication works. Here are some things to try:

## Load a Real Dataset

Load the Northwind sample database for more realistic exploration:

```{{exec}}
curl -fsSL https://downloads.pgedge.com/platform/examples/northwind/northwind.sql \
    | kubectl cnpg psql pgedge-n1 -- -U app app
```

Query it from another node:

```{{exec}}
kubectl cnpg psql pgedge-n2 -- -U app app -c "SELECT company_name, contact_name FROM northwind.customers LIMIT 5;"
```

## Check Spock Replication Status

```{{exec}}
kubectl cnpg psql pgedge-n1 -- -U app app -c "SELECT * FROM spock.subscription;"
```

## Inspect the Helm Release

```{{exec}}
helm get values pgedge
```

```{{exec}}
helm get manifest pgedge | head -80
```

## What's Next?

- **Full environment with no resource limits:** [Open in GitHub Codespace](https://github.com/pgEdge/try-pgedge-helm)
- **Run on your own infrastructure:** [Quickstart Guide](https://pgedge.github.io/pgedge-helm/quickstart/)
- **Production configuration:** [pgEdge Helm Documentation](https://pgedge.github.io/pgedge-helm/)
- **Source code:** [pgEdge Helm Chart on GitHub](https://github.com/pgEdge/pgedge-helm)
```

**Step 7: Write finish page**

`killercoda/finish/text.md`:
```markdown
# Congratulations!

You've successfully deployed pgEdge Distributed Postgres on Kubernetes and proven that Spock active-active replication works across multiple nodes.

**What you built:**
- A multi-node pgEdge cluster managed by CloudNativePG
- Spock active-active replication between all nodes
- TLS certificates managed by cert-manager

**Continue your evaluation:**
- [Open in GitHub Codespace](https://github.com/pgEdge/try-pgedge-helm) — full environment, no resource limits
- [pgEdge Helm Documentation](https://pgedge.github.io/pgedge-helm/) — production configuration, multi-cluster, monitoring
- [pgEdge on GitHub](https://github.com/pgEdge/pgedge-helm) — source code and examples
```

**Step 8: Commit all tutorial steps**

```bash
git add killercoda/step1/ killercoda/step2/ killercoda/step3/ killercoda/step4/ killercoda/step5/ killercoda/step6/ killercoda/finish/
git commit -m "feat: add Killercoda tutorial steps 1-6 and finish page

Covers: inspect environment, configure deployment, helm install,
verify health, prove Spock replication, explore and next steps."
```

---

## Task 4: Build Codespace Devcontainer

**Depends on:** Task 1 (values-demo.yaml)

**Files:**
- Create: `.devcontainer/devcontainer.json`
- Create: `.devcontainer/post-create.sh`

**Step 1: Create devcontainer.json**

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
  "postCreateCommand": "bash .devcontainer/post-create.sh",
  "customizations": {
    "vscode": {
      "extensions": [
        "stateful.runme"
      ],
      "settings": {
        "terminal.integrated.defaultProfile.linux": "bash",
        "workbench.startupEditor": "walkThrough"
      }
    }
  }
}
```

**Step 2: Create post-create.sh**

This installs tools not available as devcontainer features: kind and the kubectl cnpg plugin.

```bash
#!/bin/bash
# .devcontainer/post-create.sh
set -euo pipefail

echo "Installing kind..."
KIND_VERSION="v0.27.0"
curl -fsSLo /usr/local/bin/kind "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64"
chmod +x /usr/local/bin/kind

echo "Installing kubectl cnpg plugin..."
CNPG_PLUGIN_VERSION="1.28.1"
curl -fsSL "https://github.com/pgEdge/pgedge-cnpg-dist/releases/download/kubectl-cnpg%2Fv${CNPG_PLUGIN_VERSION}/kubectl-cnpg_${CNPG_PLUGIN_VERSION}_linux_amd64.tar.gz" \
  | tar -xz -C /usr/local/bin kubectl-cnpg

echo "Adding pgEdge Helm repo..."
helm repo add pgedge https://pgedge.github.io/charts
helm repo update

echo ""
echo "Environment ready! Run ./guide.sh to get started, or follow the VS Code Walkthrough."
```

**Step 3: Commit**

```bash
git add .devcontainer/
git commit -m "feat: add Codespace devcontainer with kind, helm, kubectl, cnpg plugin

Pre-installs all tools needed to deploy pgEdge on a local kind cluster.
Includes Runme extension for executable markdown."
```

---

## Task 5: Build Interactive CLI Guide

**Depends on:** Task 1 (values-demo.yaml), Task 4 (devcontainer)

**Files:**
- Create: `guide.sh`
- Create: `scripts/setup-cluster.sh`

**Step 1: Create setup-cluster.sh**

This script creates the kind cluster and installs operators. Used by both `guide.sh` and the VS Code Walkthrough.

```bash
#!/bin/bash
# scripts/setup-cluster.sh
# Creates a kind cluster and installs CNPG + cert-manager
set -euo pipefail

CLUSTER_NAME="${1:-pgedge-demo}"

echo "Creating kind cluster '${CLUSTER_NAME}'..."
kind create cluster --name "${CLUSTER_NAME}" --wait 60s

echo ""
echo "Installing CloudNativePG operator..."
helm install cnpg pgedge/cloudnative-pg \
  --namespace cnpg-system \
  --create-namespace \
  --wait

echo ""
echo "Installing cert-manager..."
kubectl apply -f \
  https://github.com/cert-manager/cert-manager/releases/download/v1.19.3/cert-manager.yaml

echo "Waiting for cert-manager to be ready..."
kubectl wait --for=condition=Available deployment \
  -n cert-manager cert-manager cert-manager-cainjector cert-manager-webhook \
  --timeout=120s

echo ""
echo "Cluster '${CLUSTER_NAME}' is ready with CNPG and cert-manager installed."
```

**Step 2: Create guide.sh**

This is the interactive CLI guide. It works in Codespaces, local machines, or any terminal with prerequisites.

```bash
#!/bin/bash
# guide.sh — Interactive guided walkthrough for deploying pgEdge on Kubernetes
set -euo pipefail

# Colors
BOLD='\033[1m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info()  { echo -e "${BLUE}$*${RESET}"; }
ok()    { echo -e "${GREEN}$*${RESET}"; }
warn()  { echo -e "${YELLOW}$*${RESET}"; }
header() { echo ""; echo -e "${BOLD}${CYAN}═══ $* ═══${RESET}"; echo ""; }

wait_for_user() {
  echo ""
  read -rp "$(echo -e "${BOLD}Press Enter to continue...${RESET}")" _
  echo ""
}

run_cmd() {
  echo -e "${YELLOW}\$ $*${RESET}"
  eval "$@"
}

# ─── Intro ───

header "pgEdge Distributed Postgres on Kubernetes"
info "This guide walks you through deploying a pgEdge distributed"
info "PostgreSQL cluster using Helm and CloudNativePG."
echo ""
info "You'll:"
info "  1. Create a Kubernetes cluster (kind)"
info "  2. Install the CloudNativePG operator and cert-manager"
info "  3. Deploy 3 pgEdge Postgres nodes with Spock replication"
info "  4. Prove active-active replication works"
echo ""
info "Estimated time: 10-15 minutes"

wait_for_user

# ─── Step 1: Check prerequisites ───

header "Step 1: Checking Prerequisites"

MISSING=()
for cmd in docker kind helm kubectl; do
  if command -v "$cmd" &>/dev/null; then
    ok "  ✓ $cmd found: $(command -v "$cmd")"
  else
    warn "  ✗ $cmd not found"
    MISSING+=("$cmd")
  fi
done

if command -v kubectl-cnpg &>/dev/null || kubectl cnpg version &>/dev/null 2>&1; then
  ok "  ✓ kubectl cnpg plugin found"
else
  warn "  ✗ kubectl cnpg plugin not found (optional but recommended)"
  info "    Install from: https://github.com/pgEdge/pgedge-cnpg-dist/releases"
fi

if [ ${#MISSING[@]} -gt 0 ]; then
  echo ""
  warn "Missing required tools: ${MISSING[*]}"
  warn "Please install them and re-run this guide."
  exit 1
fi

wait_for_user

# ─── Step 2: Create cluster ───

header "Step 2: Create Kubernetes Cluster"
info "Creating a kind cluster and installing CloudNativePG + cert-manager."
info "This takes 2-3 minutes."

wait_for_user

run_cmd bash "${SCRIPT_DIR}/scripts/setup-cluster.sh" pgedge-demo

ok ""
ok "Cluster created and operators installed."

wait_for_user

# ─── Step 3: Review configuration ───

header "Step 3: Review Deployment Configuration"
info "Here's the values.yaml that defines your pgEdge cluster:"
echo ""
run_cmd cat "${SCRIPT_DIR}/values-demo.yaml"
echo ""
info "This deploys 3 pgEdge nodes (n1, n2, n3), each as a separate"
info "CloudNativePG Cluster. Every node is a writable primary."
info "Spock active-active replication connects them automatically."

wait_for_user

# ─── Step 4: Deploy ───

header "Step 4: Deploy pgEdge"
info "Installing the pgEdge Helm chart. This creates:"
info "  - Certificate resources (TLS via cert-manager)"
info "  - 3 CloudNativePG Clusters (one per pgEdge node)"
info "  - init-spock job (configures Spock replication)"
echo ""
info "This takes 2-4 minutes."

wait_for_user

run_cmd helm install pgedge pgedge/pgedge \
  --values "${SCRIPT_DIR}/values-demo.yaml" \
  --wait --timeout 300s

ok ""
ok "pgEdge deployed successfully!"

wait_for_user

# ─── Step 5: Verify health ───

header "Step 5: Verify Cluster Health"
info "Checking health of each pgEdge node:"
echo ""

for node in n1 n2 n3; do
  info "--- pgedge-${node} ---"
  run_cmd kubectl cnpg status "pgedge-${node}" 2>/dev/null | head -5
  echo ""
done

wait_for_user

# ─── Step 6: Prove replication ───

header "Step 6: Prove Active-Active Replication"
info "Now the payoff — writing data on one node, reading on another."

echo ""
info "Creating a table on node 1:"
run_cmd kubectl cnpg psql pgedge-n1 -- -U app app \
  -c "\"CREATE TABLE demo (id int primary key, data text);\""

echo ""
info "Inserting a row on node 2:"
run_cmd kubectl cnpg psql pgedge-n2 -- -U app app \
  -c "\"INSERT INTO demo VALUES (1, 'Written on node 2');\""

echo ""
info "Reading from node 1 — data replicated via Spock:"
run_cmd kubectl cnpg psql pgedge-n1 -- -U app app \
  -c "\"SELECT * FROM demo;\""

echo ""
info "Writing on node 1:"
run_cmd kubectl cnpg psql pgedge-n1 -- -U app app \
  -c "\"INSERT INTO demo VALUES (2, 'Written on node 1');\""

echo ""
info "Reading from node 3 — all nodes have all data:"
run_cmd kubectl cnpg psql pgedge-n3 -- -U app app \
  -c "\"SELECT * FROM demo;\""

echo ""
ok "Active-active replication confirmed!"

wait_for_user

# ─── Done ───

header "Done!"
ok "You've deployed pgEdge Distributed Postgres on Kubernetes"
ok "and proven Spock active-active replication works."
echo ""
info "To explore further:"
info "  • Load Northwind dataset:  curl -fsSL https://downloads.pgedge.com/platform/examples/northwind/northwind.sql | kubectl cnpg psql pgedge-n1 -- -U app app"
info "  • Connect to any node:     kubectl cnpg psql pgedge-n1 -- -U app app"
info "  • Check replication:       kubectl cnpg psql pgedge-n1 -- -U app app -c 'SELECT * FROM spock.subscription;'"
info "  • Tear down:               kind delete cluster --name pgedge-demo"
echo ""
info "Documentation: https://pgedge.github.io/pgedge-helm/"
info "Source code:   https://github.com/pgEdge/pgedge-helm"
```

**Step 3: Make executable and commit**

```bash
chmod +x guide.sh scripts/setup-cluster.sh
git add guide.sh scripts/setup-cluster.sh
git commit -m "feat: add interactive CLI guide and cluster setup script

guide.sh walks users through deploying pgEdge step by step with
explanations and prompts. Works in Codespaces and locally.
setup-cluster.sh creates kind cluster with CNPG and cert-manager."
```

---

## Task 6: Build VS Code Walkthrough

**Depends on:** Task 4 (devcontainer), Task 5 (guide.sh, setup-cluster.sh)

**Files:**
- Create: `.vscode/walkthroughs/pgedge-k8s.json`
- Modify: `.devcontainer/devcontainer.json` (add walkthrough reference if needed)

**Step 1: Research the VS Code Walkthrough API**

Before writing, check the current VS Code Walkthrough contribution point spec. The walkthrough is defined in an extension's `package.json` under `contributes.walkthroughs`. However, for a **repo-level walkthrough** (not an extension), VS Code supports `.vscode/walkthroughs/` with a specific format.

Consult: https://code.visualstudio.com/api/references/contribution-points#contributes.walkthroughs

If repo-level walkthroughs are not supported (they require an extension), the fallback is:
- Use the Runme extension to make the README executable
- The `workbench.startupEditor: "readme"` setting opens the README on launch
- Each code block in the README has a play button via Runme

**Step 2: Create the walkthrough or Runme-compatible README**

This step requires research during implementation. The deliverable is either:
- A `.vscode/walkthroughs/` definition (if supported without an extension), OR
- A Runme-compatible `WALKTHROUGH.md` that opens on launch with executable code blocks

**Step 3: Commit**

```bash
git add .vscode/ # or WALKTHROUGH.md
git commit -m "feat: add VS Code Walkthrough for Codespace guided experience"
```

---

## Task 7: Write README Landing Page

**Depends on:** Tasks 2-6

**Files:**
- Create: `README.md`

**Step 1: Write the README**

The README serves as the landing page for the repo. It should have:
- A clear title and one-line description
- Codespace launch badge (prominent)
- Killercoda link
- Link to existing quickstart
- Brief architecture description
- Prerequisites for local usage

```markdown
# Try pgEdge Distributed Postgres on Kubernetes

Deploy a multi-node pgEdge PostgreSQL cluster on Kubernetes using Helm and CloudNativePG, with Spock active-active replication.

## Choose Your Path

### Zero Install — Try in Browser
[![Open in Killercoda](https://img.shields.io/badge/Killercoda-Try%20Now-blue?logo=kubernetes)](https://killercoda.com/pgedge/scenario/pgedge-helm-quickstart)

A guided tutorial in a real Kubernetes environment. No local setup needed.

### Full Environment — Open in Codespace
[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/pgEdge/try-pgedge-helm?quickstart=1)

A complete VS Code environment with kind, Helm, kubectl, and the pgEdge chart pre-configured. Run `./guide.sh` for a guided walkthrough or explore on your own.

### Run Locally
Already have kind, Helm, and kubectl? Follow the [pgEdge Helm Quickstart](https://pgedge.github.io/pgedge-helm/quickstart/).

---

## What You'll Build

```
┌─────────────┐    Spock    ┌─────────────┐    Spock    ┌─────────────┐
│  pgEdge n1  │◄──────────►│  pgEdge n2  │◄──────────►│  pgEdge n3  │
│  (primary)  │  replicate  │  (primary)  │  replicate  │  (primary)  │
└─────────────┘             └─────────────┘             └─────────────┘
```

Three pgEdge Postgres nodes, each managed by CloudNativePG, connected via Spock active-active replication. Every node is a writable primary — write anywhere, read everywhere.

## What's Included

- **Helm chart deployment** of pgEdge Distributed Postgres
- **CloudNativePG operator** managing PostgreSQL lifecycle
- **cert-manager** for automatic TLS certificate management
- **Spock replication** for active-active multi-master writes

## Learn More

- [pgEdge Helm Chart Documentation](https://pgedge.github.io/pgedge-helm/)
- [pgEdge Helm Chart Source](https://github.com/pgEdge/pgedge-helm)
- [CloudNativePG](https://cloudnative-pg.io/)
```

**Step 2: Commit**

```bash
git add README.md
git commit -m "feat: add README with three paths to try pgEdge on K8s

Codespace badge, Killercoda link, and quickstart reference."
```

---

## Task 8: Test End-to-End on Killercoda

**Depends on:** Tasks 1-3, Killercoda creator account setup

This is a manual testing task:

**Step 1: Set up Killercoda creator account**

1. Go to https://killercoda.com/creator/repository
2. Create a `pgedge` creator account (or use existing)
3. Connect the `try-pgedge-helm` GitHub repo
4. Set the scenario path to `killercoda/` subdirectory
5. Configure the webhook

**Step 2: Push to GitHub and test**

1. Create the `try-pgedge-helm` repo on GitHub under the pgEdge org
2. Push all commits
3. Verify the Killercoda scenario appears at `killercoda.com/pgedge/scenario/...`
4. Run through the entire scenario as a user
5. Verify each step works and verification scripts pass
6. Time the background setup — must complete before user finishes reading intro
7. Note any resource issues (OOM, slow pods)

**Step 3: Fix any issues found and commit**

---

## Task 9: Test End-to-End on Codespace

**Depends on:** Tasks 4-7, GitHub repo creation

**Step 1: Push to GitHub**

Create the repo on GitHub under the pgEdge org and push.

**Step 2: Launch a Codespace**

1. Click the Codespace badge in the README
2. Wait for devcontainer to build
3. Verify all tools are installed: `kind version`, `helm version`, `kubectl version`, `kubectl cnpg version`
4. Run `./guide.sh` and walk through the entire guide
5. Verify the VS Code Walkthrough (or Runme README) appears on launch

**Step 3: Time the experience**

- Devcontainer build time: target < 3 minutes
- `guide.sh` total run time: target < 15 minutes
- Note any issues

**Step 4: Fix any issues found and commit**

---

## Task 10: Update Dev Hub Prototype

**Depends on:** Tasks 8-9 (both paths tested and working)

**Files:**
- Modify: `/Users/apegg/PROJECTS/MARKETING MATERIALS/developer access/ant-dev-experience/src/components/ContainersSection.tsx`

**Step 1: Replace mock buttons with real links**

In `ContainersSection.tsx`, replace the mock toast behavior for the sandbox launch buttons with:
- "Try It Now" → `window.open('https://killercoda.com/pgedge/scenario/pgedge-helm-quickstart', '_blank')`
- "Open in Codespace" → `window.open('https://codespaces.new/pgEdge/try-pgedge-helm?quickstart=1', '_blank')`
- "Run Locally" → `window.open('https://pgedge.github.io/pgedge-helm/quickstart/', '_blank')`

Remove the Gitpod option (Gitpod is now Ona, no longer relevant).

**Step 2: Commit**

```bash
git add src/components/ContainersSection.tsx
git commit -m "feat: replace mock K8s sandbox buttons with real demo links

Killercoda for zero-install browser demo, Codespace for full
environment, quickstart link for local deployment. Remove Gitpod."
```
