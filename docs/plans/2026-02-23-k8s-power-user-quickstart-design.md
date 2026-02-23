# Kubernetes Power-User Quickstart — Design

**Date:** 2026-02-23
**Status:** Approved
**Project:** try-pgedge-helm (prototyping; migrates to pgedge-helm once blessed)

---

## Problem

The 4th card on the prototype Kubernetes page ("Chart Repo & Quickstart")
links to the official pgedge-helm quickstart. That quickstart doesn't exist
yet in a form that serves the Kubernetes power user — someone who already has
kubectl, already has a cluster (or knows how to spin one up), and wants to get
straight to the meat.

User research (Matt Mols interview, 2026-02-23) confirms:

- Power users skip cluster setup instructions entirely
- They want Helm primitives, not wrapper scripts
- They trust `kubectl apply` and `helm install` — not `bash setup.sh`
- The selling point is multi-master replication; a single-node deploy is
  something they can get from plain CloudNativePG
- After getting it running, they want to understand topologies and operations

Key quote: *"Don't block me from getting what I need that I know I need."*

## Design

Create a new `QUICKSTART.md` in try-pgedge-helm that serves the K8s power
user. The existing `WALKTHROUGH.md` stays as the Codespace/Runme progressive
experience. Two docs, two audiences.

### Audience

Kubernetes practitioner. Has kubectl. Has a cluster (minikube, kind, EKS, GKE,
AKS — doesn't matter). Knows what Helm is. May or may not know Postgres deeply,
but knows K8s patterns. Wants to evaluate pgEdge's multi-master capabilities.

### Document structure

Five sections, ~50 lines of content. No narrative prose, no preamble.

#### 1. Header + escape hatch (3 lines)

Title and one-line description. Immediately below, a single line linking to
guided alternatives for those who need them:

> *Want a guided walkthrough instead? [Killercoda](link) | [Codespaces](link)
> | [Local guide](link)*

This addresses Matt's concern: *"don't think you need to waste above the fold
space on [beginners]"* — the link is there but doesn't dominate.

#### 2. Prerequisites (~15 lines)

Assumes the user has a Kubernetes cluster and kubectl + helm installed.
Shows the pgEdge-specific prerequisites as raw kubectl/helm commands:

1. Install cert-manager (`kubectl apply` + `kubectl wait`)
2. Install CloudNativePG operator (`kubectl apply --server-side` + `kubectl wait`)
3. Install cnpg kubectl plugin (one-liner curl)
4. Add pgEdge Helm repo (`helm repo add` + `helm repo update`)

All kubectl primitives — exactly what Matt trusts: *"I can kind of trust this
one because it's just kubectl and that's it."*

No `bash scripts/setup-cluster.sh`. No kind cluster creation. No Docker
instructions.

#### 3. Deploy (~15 lines)

Single `helm install` with a new `values/quickstart.yaml` that creates a
2-node multi-master cluster (n1 + n2 with Spock). Then wait for ready.

The values file:

```yaml
pgEdge:
  appName: pgedge
  nodes:
    - name: n1
      hostname: pgedge-n1-rw
    - name: n2
      hostname: pgedge-n2-rw
  clusterSpec:
    instances: 1
    storage:
      size: 1Gi
```

Note: n2 requires `bootstrap.mode: spock` and `sourceNode: n1` — will confirm
exact shape against the existing step3-multi-master.yaml during implementation.

Why 2 nodes, not 1: the power user is here to see distributed Postgres. A
single-node deployment is table stakes they can get from CNPG alone. Two nodes
shows multi-master working with the minimum resources.

Why not 3 nodes: 2 is sufficient to prove bi-directional replication and keeps
resource usage low. The 3-node example is in `helm-examples/multi-master/`.

#### 4. Verify replication (~10 lines)

Three commands using `kubectl cnpg psql`:

1. Create table on n1
2. Insert row on n2
3. Select from n1 — row is there via Spock

Mic-drop moment in 3 commands.

#### 5. What's Next (~15 lines)

**Topology examples** — reference the `helm-examples/` directory:

| Topology | Nodes | Instances | Use case |
|---|---|---|---|
| `single-primary/` | 1 | 1 | Dev/test, CI pipelines |
| `primary-with-replicas/` | 1 | 3 | Read scaling, single-region HA |
| `multi-master/` | 3 | 3 | Active-active writes |
| `multi-master-with-replicas/` | 3 | 9 | Full production — multi-master + HA per region |

Each directory includes `values.yaml` + `kind.yaml` for local testing.

**Documentation links** — Configuration reference, operations (upgrades,
backups, monitoring, scaling), pgEdge docs. Links only, no inline content.

**Progressive walkthrough** — link to WALKTHROUGH.md for those who want the
step-by-step Primary → Replicas → Multi-Master story.

### Prototype update

Update the 4th card in ContainersSection.tsx to point to the new QUICKSTART.md
in try-pgedge-helm (GitHub Pages or raw GitHub link). The card keeps its current
appearance but the link target changes.

### What stays

- `WALKTHROUGH.md` — unchanged, remains the Codespace/Runme progressive guide
- `guide.sh` — unchanged, remains the interactive local CLI experience
- `values/step1-single-primary.yaml`, `step2-with-replicas.yaml`,
  `step3-multi-master.yaml` — unchanged, used by the progressive walkthrough
- `helm-examples/` — referenced by the quickstart's What's Next section

### What's new

- `QUICKSTART.md` — the power-user quickstart
- `values/quickstart.yaml` — 2-node multi-master values for fresh install

### User research references

- Observation guide: `observation-guide.md`
- Interview transcript: `k8_power_user_research_matt.md`
- Key findings informing this design:
  - Skip cluster setup for power users
  - Show Helm/kubectl primitives, not wrapper scripts
  - Jump to multi-master (the differentiator), not single-node
  - Link to operations docs, don't bloat the quickstart
  - Provide escape hatch to guided experiences, don't gate on them
