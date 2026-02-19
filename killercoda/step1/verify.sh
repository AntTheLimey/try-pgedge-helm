#!/bin/bash
# Verify all components are available
kubectl get nodes | grep -q Ready && \
helm version --short > /dev/null 2>&1 && \
kubectl get deployment -n cnpg-system | grep -q cnpg-controller-manager && \
kubectl cnpg version > /dev/null 2>&1 && \
helm search repo pgedge | grep -q pgedge
