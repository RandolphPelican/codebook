#!/bin/bash
# Pod 3.9 B49 diagnostic probe runner.
#
# Builds substrate with inputs/test_codebook_b49.txt; runs probe canary
# (lookup_top1 + per-id cosines); restores canonical (empty-codebook) build.
set -e
cd /mnt/c/Users/Rando/codebook

echo "=== Pod 3.9 B49 probe runner ==="
echo

python3 tools/gen_b49_codebook.py

echo
echo "[1/4] Building substrate with B49 test codebook..."
rm -f build/BOOTX64.EFI
CODEBOOK_INPUT="inputs/test_codebook_b49.txt" ./build.sh > /tmp/build_b49_probe.log 2>&1
B49_SHA=$(sha256sum build/BOOTX64.EFI | awk '{print $1}')
echo "      B49 substrate sha: $B49_SHA"

echo
echo "[2/4] Compiling probe canary..."
python3 tools/atreyu_x86.py --pod39-b49-probe-build surfaces/test_pod39_b49_probe.cbc

echo
echo "[3/4] Running probe canary..."
bash tools/pod35_canary_test.sh test_pod39_b49_probe pod39_b49_probe > /tmp/can_b49_probe.log 2>&1
if [ -f "build/pod39_b49_probe.png" ]; then
    sz=$(stat -c %s "build/pod39_b49_probe.png")
    echo "      PASS  pod39_b49_probe.png ($sz bytes)"
else
    echo "      FAIL  no PNG produced"
    tail -20 /tmp/can_b49_probe.log
    rm -f build/BOOTX64.EFI
    ./build.sh > /dev/null 2>&1
    exit 1
fi

echo
echo "[4/4] Restoring canonical substrate..."
rm -f build/BOOTX64.EFI
./build.sh > /tmp/build_canonical.log 2>&1
CANONICAL_SHA=$(sha256sum build/BOOTX64.EFI | awk '{print $1}')
echo "      canonical sha: $CANONICAL_SHA"
echo "=== Probe runner done ==="
