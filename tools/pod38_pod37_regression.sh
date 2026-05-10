#!/bin/bash
# Pod 3.8 regression — re-execute Pod 3.7 substrate canaries (B43/B44/B45) at new BSS layout.
set -e
cd /mnt/c/Users/Rando/codebook

BASELINE=/tmp/pod37_baseline_sha.txt
NEW=/tmp/pod37_at_pod38c_sha.txt

sha256sum build/pod37_*.png > "$BASELINE"
echo "=== Pod 3.7 baseline saved ($(wc -l < $BASELINE) PNGs)"

TESTS=(
    "test_pod37_embedding_pool_capacity pod37_b43_embedding_pool_capacity_at_2048"
    "test_pod37_outcome_pool_load pod37_b44_outcome_pool_under_synthesis_load"
    "test_pod37_mixed_workload pod37_b45_mixed_workload_within_capacity"
)

for entry in "${TESTS[@]}"; do
    surface="${entry%% *}"
    out="${entry##* }"
    bash tools/pod35_canary_test.sh "$surface" "$out" > /tmp/can_p38c.log 2>&1
    if [ -f "build/${out}.png" ]; then
        echo "  PASS $surface"
    else
        echo "  FAIL $surface"
        tail -10 /tmp/can_p38c.log
        exit 1
    fi
done

sha256sum build/pod37_*.png > "$NEW"
echo
echo "=== diff (any line = drift):"
if diff "$BASELINE" "$NEW"; then
    echo "IDENTICAL — all $(wc -l < $NEW) Pod 3.7 PNGs byte-exact preserved at Pod 3.8.C layout"
else
    echo "DRIFT DETECTED"
    exit 1
fi
