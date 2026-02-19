#!/bin/bash
set -euo pipefail

# Creates a kind cluster and installs CNPG operator + cert-manager.
# Used by guide.sh for Codespace/local environments.

CLUSTER_NAME="${1:-pgedge-demo}"

# Wait for a deployment to become available, with retry on failure.
# On timeout, checks for image pull errors and offers to retry.
wait_for_deployment() {
  local namespace="$1"
  local selector="$2"
  local label="$3"

  while true; do
    if kubectl wait --for=condition=Available deployment ${selector} -n "$namespace" --timeout=120s 2>/dev/null; then
      return 0
    fi

    echo ""
    echo "Timed out waiting for ${label}. Checking why..."
    echo ""

    # Check for image pull issues
    local pull_errors
    pull_errors=$(kubectl get pods -n "$namespace" -o jsonpath='{range .items[*]}{.status.containerStatuses[*].state.waiting.reason}{"\n"}{end}' 2>/dev/null | grep -c "ImagePull" || true)

    if [ "$pull_errors" -gt 0 ]; then
      echo "  Container images are failing to download. This is usually a"
      echo "  transient issue with the container registry (rate limits, outages)."
      echo ""
      kubectl get pods -n "$namespace" --no-headers 2>/dev/null | while read -r line; do
        echo "  $line"
      done
    else
      echo "  Pods are not ready yet:"
      echo ""
      kubectl get pods -n "$namespace" --no-headers 2>/dev/null | while read -r line; do
        echo "  $line"
      done
    fi

    echo ""
    read -rp "  Retry? [Y/n] " answer
    case "${answer:-y}" in
      [nN]*) echo "Aborting."; exit 1 ;;
    esac

    # Delete failed pods to force a fresh pull attempt
    if [ "$pull_errors" -gt 0 ]; then
      echo ""
      echo "  Deleting failed pods to retry image pulls..."
      kubectl delete pods -n "$namespace" --field-selector=status.phase!=Running --ignore-not-found 2>/dev/null || true
      sleep 5
    fi

    echo ""
    echo "  Waiting for ${label}..."
  done
}

echo "=== Setting up Kubernetes cluster ==="

# Check prerequisites
for cmd in kind kubectl helm; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: $cmd is not installed. Please install it first."
    exit 1
  fi
done

# Create kind cluster if it doesn't exist
if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
  echo "Kind cluster '${CLUSTER_NAME}' already exists, reusing it."
else
  echo "Creating kind cluster '${CLUSTER_NAME}'..."
  kind create cluster --name "$CLUSTER_NAME" --wait 60s
fi

echo ""
echo "Installing cert-manager..."
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml
echo "Waiting for cert-manager..."
wait_for_deployment "cert-manager" "--all" "cert-manager"

echo ""
echo "Installing CloudNativePG operator..."
kubectl apply --server-side -f https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/main/releases/cnpg-1.25.1.yaml
echo "Waiting for CNPG operator..."
wait_for_deployment "cnpg-system" "-l app.kubernetes.io/name=cloudnative-pg" "CNPG operator"

echo ""
echo "Adding pgEdge Helm repo..."
helm repo add pgedge https://pgedge.github.io/charts 2>/dev/null || true
helm repo update

echo ""
echo "=== Cluster is ready! ==="
echo ""
kubectl get nodes
