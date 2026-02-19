#!/bin/bash
# Verify n1 has 2 instances running
kubectl cnpg status pgedge-n1 2>/dev/null | grep -q "Instances:.*2"
