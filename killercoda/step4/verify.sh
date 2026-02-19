#!/bin/bash
# Verify both n1 and n2 are healthy
kubectl cnpg status pgedge-n1 2>/dev/null | grep -q "Cluster in healthy state" && \
kubectl cnpg status pgedge-n2 2>/dev/null | grep -q "Cluster in healthy state"
