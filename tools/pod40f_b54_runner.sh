#!/bin/bash
# Pod 4.0.F.9 B54 Similarity Browser runner.
#
# Builds substrate with inputs/test_codebook_b48.txt (5 basis-vector entries;
# reused per B48/B49/B52 pattern); runs B54 canary; restores canonical
# (empty-codebook) substrate. Canonical Pod 4.0.F contract sha preserved
# by the final rebuild step (load-bearing per D4.1 byte-lock).
set -e
cd /mnt/c/Users/Rando/codebook

echo "=== Pod 4.0.F.9 B54 Similarity Browser canary ==="
echo

# Step 1: Generate B48 test codebook (idempotent; reused across B48/B52/B54)
python3 tools/gen_b48_codebook.py

# Step 2: Build substrate with B48 test codebook
echo
echo "[1/4] Building substrate with B48 test codebook..."
rm -f build/BOOTX64.EFI
CODEBOOK_INPUT="inputs/test_codebook_b48.txt" ./build.sh > /tmp/build_b54.log 2>&1
B54_SHA=$(sha256sum build/BOOTX64.EFI | awk '{print $1}')
echo "      B54 substrate sha: $B54_SHA"

# Two-build determinism check
rm -f build/BOOTX64.EFI
CODEBOOK_INPUT="inputs/test_codebook_b48.txt" ./build.sh > /dev/null 2>&1
B54_SHA2=$(sha256sum build/BOOTX64.EFI | awk '{print $1}')
if [ "$B54_SHA" = "$B54_SHA2" ]; then
    echo "      B54 substrate two-build determinism: IDENTICAL"
else
    echo "      B54 substrate DRIFT: $B54_SHA != $B54_SHA2"
    exit 1
fi

# Step 3: Compile B54 canary surface
echo
echo "[2/4] Compiling B54 canary surface..."
python3 tools/atreyu_x86.py --pod40f-b54-similarity-browser-build surfaces/test_pod40f_b54_similarity_browser.cbc

# Step 4: Run canary
echo
echo "[3/4] Running B54 canary..."
bash tools/pod35_canary_test.sh test_pod40f_b54_similarity_browser pod40f_b54_similarity_browser > /tmp/can_b54.log 2>&1
if [ -f "build/pod40f_b54_similarity_browser.png" ]; then
    sz=$(stat -c %s "build/pod40f_b54_similarity_browser.png")
    echo "      PASS  pod40f_b54_similarity_browser.png ($sz bytes)"
else
    echo "      FAIL  no PNG produced"
    tail -10 /tmp/can_b54.log
    rm -f build/BOOTX64.EFI
    ./build.sh > /dev/null 2>&1
    exit 1
fi

# Step 5: Restore canonical (empty-codebook) substrate
echo
echo "[4/4] Restoring canonical substrate build..."
rm -f build/BOOTX64.EFI
./build.sh > /tmp/build_canonical.log 2>&1
CANONICAL_SHA=$(sha256sum build/BOOTX64.EFI | awk '{print $1}')
echo "      canonical sha: $CANONICAL_SHA"
echo "      (expected:     c9923b8cf9fb6caf4c195e2d0d0ea2ed4a8e51e4e9f827b1fc24dd0b28c1d900)"

if [ "$CANONICAL_SHA" = "c9923b8cf9fb6caf4c195e2d0d0ea2ed4a8e51e4e9f827b1fc24dd0b28c1d900" ]; then
    echo
    echo "=== Pod 4.0.F.9 B54 runner: PASS - canonical contract preserved ==="
else
    echo
    echo "=== Pod 4.0.F.9 B54 runner: WARNING - canonical contract drifted ==="
    exit 1
fi
