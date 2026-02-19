#!/bin/bash
# Verify the single primary is running
kubectl cnpg status pgedge-n1 2>/dev/null | grep -q "Cluster in healthy state"
