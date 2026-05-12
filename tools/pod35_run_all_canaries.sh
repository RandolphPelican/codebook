#!/bin/bash
# Pod 3.5 — Run all canary tests in sequence and produce screendumps.
# Throwaway test orchestrator.
set -e
cd /mnt/c/Users/Rando/codebook

# (surface, screendump_short_name)
TESTS=(
    "test_cosine_same_vector pod35_b7_cosine_same_vector"
    "test_cosine_orthogonal pod35_b8_cosine_orthogonal"
    "test_cosine_antipodal pod35_b9_cosine_antipodal"
    "test_cosine_zero_vector pod35_b11_cosine_zero_vector"
    "test_cosine_invalid_id pod35_b12_cosine_invalid_id"
    "test_dot_product_simple pod35_b13_dot_product_simple"
    "test_dot_product_invalid_id pod35_b14_dot_product_invalid_id"
    "test_l2_distance_same pod35_b15_l2_distance_same"
    "test_l2_distance_simple pod35_b16_l2_distance_simple"
    "test_l2_distance_invalid_id pod35_b17_l2_distance_invalid_id"
    "test_lookup_top1_basic pod35_b18_lookup_top1_basic"
    "test_lookup_top1_empty pod35_b19_lookup_top1_empty"
    "test_lookup_top1_invalid_query pod35_b20_lookup_top1_invalid_query"
    "test_embedding_sign_handle_linked pod35_b21_embedding_sign_handle_linked"
    "test_embedding_sign_handle_unlinked pod35_b22_embedding_sign_handle_unlinked"
    "test_compute_under_subcap pod35_b23_compute_under_subcap"
    "test_maid_composition pod35_b24_maid_composition"
)

for entry in "${TESTS[@]}"; do
    surface="${entry%% *}"
    out="${entry##* }"
    bash tools/pod35_canary_test.sh "$surface" "$out" > /tmp/canary_run.log 2>&1
    if [ -f "build/${out}.png" ]; then
        sz=$(stat -c %s "build/${out}.png")
        echo "PASS  $surface -> ${out}.png ($sz bytes)"
    else
        echo "FAIL  $surface (no PNG produced)"
    fi
done
