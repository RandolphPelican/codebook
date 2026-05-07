#!/bin/bash
# Pod 3.6 Phase 2.2 — run B29-B33 + B32-aux canaries via pod35_canary_test harness.
set -e
cd /mnt/c/Users/Rando/codebook

TESTS=(
    "test_synthesis_scale_basic pod36_b29_synthesis_scale_basic"
    "test_synthesis_scale_zero pod36_b30_synthesis_scale_zero"
    "test_synthesis_scale_negative pod36_b31_synthesis_scale_negative"
    "test_synthesis_normalize_basic pod36_b32_synthesis_normalize_basic"
    "test_synthesis_normalize_v_uniform_drift pod36_b32aux_normalize_v_uniform_drift"
    "test_synthesis_normalize_zero_reject pod36_b33_synthesis_normalize_zero_reject"
)

for entry in "${TESTS[@]}"; do
    surface="${entry%% *}"
    out="${entry##* }"
    bash tools/pod35_canary_test.sh "$surface" "$out" > /tmp/can_phase22.log 2>&1
    if [ -f "build/${out}.png" ]; then
        sz=$(stat -c %s "build/${out}.png")
        echo "PASS  $surface -> ${out}.png ($sz bytes)"
    else
        echo "FAIL  $surface (no PNG)"
        tail -10 /tmp/can_phase22.log
    fi
done
