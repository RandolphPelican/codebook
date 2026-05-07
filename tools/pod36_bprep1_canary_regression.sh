#!/bin/bash
# Pod 3.6 B-prep-1: re-run Pod 3.5 B7-B24 canaries at Phase 1.1 BSS layout.
# Captures PNG sha256 before + after; compares for byte-exact preservation.
set -e
cd /mnt/c/Users/Rando/codebook

BASELINE=/tmp/pod35_baseline_sha.txt
NEW=/tmp/pod35_phase11_sha.txt

sha256sum build/pod35_b*.png > "$BASELINE"
echo "=== baseline saved ($(wc -l < $BASELINE) PNGs)"

bash tools/pod35_run_all_canaries.sh 2>&1 | tail -25

echo
echo "=== computing new sha256"
sha256sum build/pod35_b*.png > "$NEW"

echo
echo "=== diff (any line = drift):"
if diff "$BASELINE" "$NEW"; then
    echo "IDENTICAL — all $(wc -l < $NEW) canary PNGs byte-exact preserved"
else
    echo "DRIFT DETECTED — see diff above"
    exit 1
fi
