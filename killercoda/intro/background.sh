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

echo "Adding pgEdge Helm repo..."
helm repo add pgedge https://pgedge.github.io/charts
helm repo update

echo "Installing pgEdge CloudNativePG operator..."
helm install cnpg pgedge/cloudnative-pg --namespace cnpg-system --create-namespace
kubectl wait --for=condition=Available deployment -l app.kubernetes.io/name=cloudnative-pg -n cnpg-system --timeout=120s

echo "Installing cnpg kubectl plugin..."
ARCH=$(uname -m | sed 's/x86_64/amd64/' | sed 's/aarch64/arm64/')
curl -sSfL "https://github.com/pgEdge/pgedge-cnpg-dist/releases/download/v1.28.0/kubectl-cnpg-linux-${ARCH}.tar.gz" \
  | tar xz -C /usr/local/bin

touch /tmp/.background-done
echo "Background setup complete!"
