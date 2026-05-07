#!/bin/bash
# Compile all Phase 3.x test surfaces.
set -e
cd /mnt/c/Users/Rando/codebook

NAMES=(
    "synthesis-lerp-basic"
    "synthesis-lerp-t-zero"
    "synthesis-lerp-t-one"
    "synthesis-lerp-irrational-drift"
    "synthesis-round-trip"
    "synthesis-unsynthesized"
    "analogical-reasoning"
    "synthesis-forge-authority"
    "synthesis-babylon-ripple"
    "synthesis-pool-capacity"
)

for name in "${NAMES[@]}"; do
    # Convert hyphens to underscores for filename
    fn=$(echo "$name" | tr '-' '_')
    python3 tools/atreyu_x86.py --${name}-build surfaces/test_${fn}.cbc 2>&1 | tail -1
done
