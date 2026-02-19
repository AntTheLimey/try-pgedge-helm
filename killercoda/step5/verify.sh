#!/bin/bash
# Verify data replicated to both nodes
kubectl cnpg psql pgedge-n1 -- -d app -c "SELECT count(*) FROM cities;" 2>/dev/null | grep -q "5" && \
kubectl cnpg psql pgedge-n2 -- -d app -c "SELECT count(*) FROM cities;" 2>/dev/null | grep -q "5"
