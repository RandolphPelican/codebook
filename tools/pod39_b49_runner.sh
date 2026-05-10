#!/bin/bash
# Pod 3.9.E B49 top-K canary runner.
#
# Builds substrate with inputs/test_codebook_b49.txt (10 entries with
# distinct cosines vs query), runs B49 canary, captures PNG, then restores
# canonical (empty-codebook) substrate build.
set -e
cd /mnt/c/Users/Rando/codebook

echo "=== Pod 3.9 B49 top-K canary ==="
echo

# Step 1: Generate B49 test codebook input
python3 tools/gen_b49_codebook.py

# Step 2: Build substrate with B49 test codebook
echo
echo "[1/4] Building substrate with B49 test codebook..."
rm -f build/BOOTX64.EFI
CODEBOOK_INPUT="inputs/test_codebook_b49.txt" ./build.sh > /tmp/build_b49.log 2>&1
B49_SHA=$(sha256sum build/BOOTX64.EFI | awk '{print $1}')
echo "      B49 substrate sha: $B49_SHA"

# Two-build determinism check on B49 substrate
rm -f build/BOOTX64.EFI
CODEBOOK_INPUT="inputs/test_codebook_b49.txt" ./build.sh > /dev/null 2>&1
B49_SHA2=$(sha256sum build/BOOTX64.EFI | awk '{print $1}')
if [ "$B49_SHA" = "$B49_SHA2" ]; then
    echo "      B49 substrate two-build determinism: IDENTICAL"
else
    echo "      B49 substrate DRIFT: $B49_SHA != $B49_SHA2"
    exit 1
fi

# Step 3: Compile B49 canary surface
echo
echo "[2/4] Compiling B49 canary surface..."
python3 tools/atreyu_x86.py --pod39-top-k-b49-build surfaces/test_pod39_b49_top_k.cbc

# Step 4: Run canary
echo
echo "[3/4] Running B49 canary..."
bash tools/pod35_canary_test.sh test_pod39_b49_top_k pod39_b49_top_k > /tmp/can_b49.log 2>&1
if [ -f "build/pod39_b49_top_k.png" ]; then
    sz=$(stat -c %s "build/pod39_b49_top_k.png")
    echo "      PASS  pod39_b49_top_k.png ($sz bytes)"
else
    echo "      FAIL  no PNG produced"
    tail -10 /tmp/can_b49.log
    rm -f build/BOOTX64.EFI
    ./build.sh > /dev/null 2>&1
    exit 1
fi

# Step 5: Restore canonical build
echo
echo "[4/4] Restoring canonical substrate build..."
rm -f build/BOOTX64.EFI
./build.sh > /tmp/build_canonical.log 2>&1
CANONICAL_SHA=$(sha256sum build/BOOTX64.EFI | awk '{print $1}')
echo "      canonical sha: $CANONICAL_SHA"
echo "      (expected:     a6fa3debb834b1a71216b16ee2358e6c8fd7b9d005947883b0bcc061fbe2da99)"

if [ "$CANONICAL_SHA" = "a6fa3debb834b1a71216b16ee2358e6c8fd7b9d005947883b0bcc061fbe2da99" ]; then
    echo
    echo "=== Pod 3.9.E B49 runner: PASS — canonical contract preserved ==="
else
    echo
    echo "=== Pod 3.9.E B49 runner: WARNING — canonical contract drifted ==="
    exit 1
fi
