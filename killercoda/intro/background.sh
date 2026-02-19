#!/bin/bash
set -euo pipefail

# --- Killercoda background installer ---
# Installs Helm, cert-manager, CNPG operator, cnpg plugin, and pgEdge chart repo.
# The foreground script waits for /tmp/.background-done before proceeding.

echo "Installing Helm..."
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo "Installing cert-manager..."
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml

echo "Waiting for cert-manager pods..."
kubectl wait --for=condition=Available deployment --all -n cert-manager --timeout=120s

echo "Installing CloudNativePG operator..."
kubectl apply --server-side -f https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/main/releases/cnpg-1.25.1.yaml

echo "Waiting for CNPG operator..."
kubectl wait --for=condition=Available deployment -l app.kubernetes.io/name=cloudnative-pg -n cnpg-system --timeout=120s

echo "Installing cnpg kubectl plugin..."
curl -sSfL https://github.com/cloudnative-pg/cloudnative-pg/raw/main/hack/install-cnpg-plugin.sh | sh -s -- -b /usr/local/bin

echo "Adding pgEdge Helm repo..."
helm repo add pgedge https://pgedge.github.io/charts
helm repo update

touch /tmp/.background-done
echo "Background setup complete!"
