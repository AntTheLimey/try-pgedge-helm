#!/bin/bash
set -euo pipefail

# Bootstrap script for curl-pipe installation:
#   curl -fsSL https://raw.githubusercontent.com/AntTheLimey/try-pgedge-helm/main/install.sh | bash

REPO="https://github.com/AntTheLimey/try-pgedge-helm.git"
DIR="try-pgedge-helm"

# Check prerequisites
for cmd in git docker kind kubectl helm; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: $cmd is not installed."
    case "$cmd" in
      git)     echo "  Install: https://git-scm.com" ;;
      docker)  echo "  Install: https://docs.docker.com/get-docker/" ;;
      kind)    echo "  Install: https://kind.sigs.k8s.io/docs/user/quick-start/#installation" ;;
      kubectl) echo "  Install: https://kubernetes.io/docs/tasks/tools/" ;;
      helm)    echo "  Install: https://helm.sh/docs/intro/install/" ;;
    esac
    exit 1
  fi
done

# Clone or update
if [ -d "$DIR" ]; then
  echo "Directory '$DIR' already exists, pulling latest..."
  git -C "$DIR" pull --ff-only
else
  git clone "$REPO"
fi

cd "$DIR"
exec ./guide.sh
