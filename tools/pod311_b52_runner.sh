#!/bin/bash
# Pod 3.11.D B52 codebook-meta canary runner.
#
# Builds substrate with inputs/test_codebook_b48.txt (reused; 5 basis vectors),
# runs B52 canary that reads vm_codebook_meta via OP_EMBEDDING_CODEBOOK_META,
# then restores canonical (empty-codebook) substrate build. Canonical Pod 3.11
# contract sha is preserved by the final rebuild step.
set -e
cd /mnt/c/Users/Rando/codebook

echo "=== Pod 3.11 B52 codebook-meta canary ==="
echo

# Step 1: Generate B48 test codebook (idempotent; B52 reuses Pod 3.8's input)
python3 tools/gen_b48_codebook.py

# Step 2: Build substrate with B48-format test codebook
echo
echo "[1/4] Building substrate with test codebook (5 entries)..."
rm -f build/BOOTX64.EFI
CODEBOOK_INPUT="inputs/test_codebook_b48.txt" ./build.sh > /tmp/build_b52.log 2>&1
B52_SHA=$(sha256sum build/BOOTX64.EFI | awk '{print $1}')
echo "      B52 substrate sha: $B52_SHA"

# Two-build determinism check on the B52-specific build
rm -f build/BOOTX64.EFI
CODEBOOK_INPUT="inputs/test_codebook_b48.txt" ./build.sh > /dev/null 2>&1
B52_SHA2=$(sha256sum build/BOOTX64.EFI | awk '{print $1}')
if [ "$B52_SHA" = "$B52_SHA2" ]; then
    echo "      B52 substrate two-build determinism: IDENTICAL"
else
    echo "      B52 substrate DRIFT: $B52_SHA != $B52_SHA2"
    exit 1
fi

# Step 3: Compile B52 canary surface
echo
echo "[2/4] Compiling B52 canary surface..."
python3 tools/atreyu_x86.py --pod311-b52-meta-build surfaces/test_pod311_b52_codebook_meta.cbc

# Step 4: Run canary
echo
echo "[3/4] Running B52 canary..."
bash tools/pod35_canary_test.sh test_pod311_b52_codebook_meta pod311_b52_codebook_meta > /tmp/can_b52.log 2>&1
if [ -f "build/pod311_b52_codebook_meta.png" ]; then
    sz=$(stat -c %s "build/pod311_b52_codebook_meta.png")
    echo "      PASS  pod311_b52_codebook_meta.png ($sz bytes)"
else
    echo "      FAIL  no PNG produced"
    tail -10 /tmp/can_b52.log
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
echo "      (expected:     58823aa9e9ad17c3fd0975cad557c934599c22588c38506d4454b6dbe1b5db6a)"
echo "      (chain: V1.0 c9923b8cf9fb6caf... -> V1.1, per Pod 5 reseal)"

if [ "$CANONICAL_SHA" = "58823aa9e9ad17c3fd0975cad557c934599c22588c38506d4454b6dbe1b5db6a" ]; then
    echo
    echo "=== Pod 3.11.D B52 runner: PASS — canonical contract preserved ==="
else
    echo
    echo "=== Pod 3.11.D B52 runner: WARNING — canonical contract drifted ==="
    exit 1
fi
