#!/bin/bash
# Pod 3.7 regression — re-execute all Pod 3.6 canaries (B25-B42 + B-aux) at Pod 3.7 BSS layout.
# Captures current PNG sha256s as baseline; re-runs; diffs.
set -e
cd /mnt/c/Users/Rando/codebook

BASELINE=/tmp/pod36_baseline_sha.txt
NEW=/tmp/pod36_pod37_sha.txt

# Pod 3.6 canary outputs at build/pod36_*.png
sha256sum build/pod36_*.png > "$BASELINE"
echo "=== baseline saved ($(wc -l < $BASELINE) Pod 3.6 PNGs)"

# All Pod 3.6 canaries
TESTS=(
    "test_synthesis_add_basic pod36_b25_synthesis_add_basic"
    "test_synthesis_add_zero pod36_b26_synthesis_add_zero"
    "test_synthesis_subtract_basic pod36_b27_synthesis_subtract_basic"
    "test_synthesis_subtract_self pod36_b28_synthesis_subtract_self"
    "test_synthesis_scale_basic pod36_b29_synthesis_scale_basic"
    "test_synthesis_scale_zero pod36_b30_synthesis_scale_zero"
    "test_synthesis_scale_negative pod36_b31_synthesis_scale_negative"
    "test_synthesis_normalize_basic pod36_b32_synthesis_normalize_basic"
    "test_synthesis_normalize_v_uniform_drift pod36_b32aux_normalize_v_uniform_drift"
    "test_synthesis_normalize_zero_reject pod36_b33_synthesis_normalize_zero_reject"
    "test_synthesis_lerp_basic pod36_b34_synthesis_lerp_basic"
    "test_synthesis_lerp_t_zero pod36_b35_synthesis_lerp_t_zero"
    "test_synthesis_lerp_t_one pod36_b36_synthesis_lerp_t_one"
    "test_synthesis_lerp_irrational_drift pod36_b34aux_lerp_irrational_drift"
    "test_synthesis_round_trip pod36_b37_synthesis_round_trip"
    "test_synthesis_unsynthesized pod36_b38_synthesis_unsynthesized"
    "test_analogical_reasoning pod36_b39_analogical_reasoning"
    "test_synthesis_forge_authority pod36_b40_synthesis_forge_authority"
    "test_synthesis_babylon_ripple pod36_b41_synthesis_babylon_ripple"
)

for entry in "${TESTS[@]}"; do
    surface="${entry%% *}"
    out="${entry##* }"
    bash tools/pod35_canary_test.sh "$surface" "$out" > /tmp/can_p37reg.log 2>&1
    if [ -f "build/${out}.png" ]; then
        echo "  PASS $surface"
    else
        echo "  FAIL $surface"
        tail -10 /tmp/can_p37reg.log
        exit 1
    fi
done

echo
sha256sum build/pod36_*.png > "$NEW"
echo "=== diff (any line = drift):"
if diff "$BASELINE" "$NEW"; then
    echo "IDENTICAL — all $(wc -l < $NEW) Pod 3.6 PNGs byte-exact preserved at Pod 3.7 layout"
else
    echo "DRIFT DETECTED"
    exit 1
fi
