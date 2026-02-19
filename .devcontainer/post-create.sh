#!/bin/bash
set -euo pipefail

echo "=== pgEdge Kubernetes Demo — Post-Create Setup ==="

# Install kind
echo "Installing kind..."
KIND_VERSION=$(curl -s https://api.github.com/repos/kubernetes-sigs/kind/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
curl -Lo /tmp/kind "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64"
chmod +x /tmp/kind
sudo mv /tmp/kind /usr/local/bin/kind

# Install cnpg kubectl plugin
echo "Installing cnpg kubectl plugin..."
curl -sSfL https://github.com/cloudnative-pg/cloudnative-pg/raw/main/hack/install-cnpg-plugin.sh | sh -s -- -b /usr/local/bin

# Add pgEdge Helm repo
echo "Adding pgEdge Helm repo..."
helm repo add pgedge https://pgedge.github.io/charts
helm repo update

echo ""
echo "Setup complete! Run ./guide.sh to start the interactive tutorial."
echo "Or open WALKTHROUGH.md for a step-by-step guide."
