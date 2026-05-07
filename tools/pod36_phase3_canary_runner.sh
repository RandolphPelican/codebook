#!/bin/bash
# Pod 3.6 Phase 3.x — run B34-B42 + B34-aux canaries.
set -e
cd /mnt/c/Users/Rando/codebook

TESTS=(
    "test_synthesis_lerp_basic pod36_b34_synthesis_lerp_basic"
    "test_synthesis_lerp_t_zero pod36_b35_synthesis_lerp_t_zero"
    "test_synthesis_lerp_t_one pod36_b36_synthesis_lerp_t_one"
    "test_synthesis_lerp_irrational_drift pod36_b34aux_lerp_irrational_drift"
    "test_synthesis_round_trip pod36_b37_synthesis_round_trip"
    "test_synthesis_unsynthesized pod36_b38_synthesis_unsynthesized"
    "test_analogical_reasoning pod36_b39_analogical_reasoning"
    "test_synthesis_forge_authority pod36_b40_synthesis_forge_authority"
    "test_synthesis_babylon_ripple pod36_b41_synthesis_babylon_ripple"
    "test_synthesis_pool_capacity pod36_b42_synthesis_pool_capacity"
)

for entry in "${TESTS[@]}"; do
    surface="${entry%% *}"
    out="${entry##* }"
    bash tools/pod35_canary_test.sh "$surface" "$out" > /tmp/can_phase3.log 2>&1
    if [ -f "build/${out}.png" ]; then
        sz=$(stat -c %s "build/${out}.png")
        echo "PASS  $surface -> ${out}.png ($sz bytes)"
    else
        echo "FAIL  $surface (no PNG)"
        tail -10 /tmp/can_phase3.log
    fi
done
