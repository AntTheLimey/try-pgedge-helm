#!/bin/bash
set -euo pipefail

# Bootstrap script for curl-pipe installation:
#   curl -fsSL https://raw.githubusercontent.com/AntTheLimey/try-pgedge-helm/main/install.sh | bash

REPO="https://github.com/AntTheLimey/try-pgedge-helm.git"
DIR="try-pgedge-helm"

# Detect OS and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
case "$ARCH" in
  x86_64)  ARCH="amd64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

# Hard prerequisites — these require system-level installation
for cmd in git docker; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: $cmd is not installed."
    case "$cmd" in
      git)    echo "  Install: https://git-scm.com" ;;
      docker) echo "  Install: https://docs.docker.com/get-docker/" ;;
    esac
    exit 1
  fi
done

# Check Docker is actually running
if ! docker info &>/dev/null; then
  echo "Error: Docker is installed but not running."
  echo "  Please start Docker and try again."
  exit 1
fi

# Auto-install missing Kubernetes tooling
install_kind() {
  echo "Installing kind..."
  local version
  version=$(curl -fsSL https://api.github.com/repos/kubernetes-sigs/kind/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
  curl -fsSLo /tmp/kind "https://kind.sigs.k8s.io/dl/${version}/kind-${OS}-${ARCH}"
  chmod +x /tmp/kind
  sudo mv /tmp/kind /usr/local/bin/kind
  echo "  Installed kind ${version}"
}

install_kubectl() {
  echo "Installing kubectl..."
  local version
  version=$(curl -fsSL https://dl.k8s.io/release/stable.txt)
  curl -fsSLo /tmp/kubectl "https://dl.k8s.io/release/${version}/bin/${OS}/${ARCH}/kubectl"
  chmod +x /tmp/kubectl
  sudo mv /tmp/kubectl /usr/local/bin/kubectl
  echo "  Installed kubectl ${version}"
}

install_helm() {
  echo "Installing Helm..."
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  echo "  Installed Helm $(helm version --short)"
}

MISSING=()
for cmd in kind kubectl helm; do
  if ! command -v "$cmd" &>/dev/null; then
    MISSING+=("$cmd")
  fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "The following tools are missing and will be installed: ${MISSING[*]}"
  read -rp "Continue? [Y/n] " answer </dev/tty
  case "${answer:-y}" in
    [nN]*) echo "Aborted."; exit 1 ;;
  esac
  echo ""
  for cmd in "${MISSING[@]}"; do
    "install_${cmd}"
  done
  echo ""
fi

# Clone or update
if [ -d "$DIR" ]; then
  echo "Directory '$DIR' already exists, pulling latest..."
  git -C "$DIR" pull --ff-only
else
  git clone "$REPO"
fi

cd "$DIR"
exec ./guide.sh
