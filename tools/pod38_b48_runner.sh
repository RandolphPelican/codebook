#!/bin/bash
# Pod 3.8.G B48 boot-ingestion canary runner.
#
# Builds substrate with inputs/test_codebook_b48.txt (non-empty codebook),
# runs B48 canary, captures PNG, then restores canonical (empty-codebook)
# substrate build. The canonical Pod 3.8 contract sha is preserved by the
# final rebuild step.
set -e
cd /mnt/c/Users/Rando/codebook

echo "=== Pod 3.8 B48 boot-ingestion canary ==="
echo

# Step 1: Generate B48 test codebook input (idempotent)
python3 tools/gen_b48_codebook.py

# Step 2: Build substrate with B48 test codebook
echo
echo "[1/4] Building substrate with B48 test codebook..."
rm -f build/BOOTX64.EFI
CODEBOOK_INPUT="inputs/test_codebook_b48.txt" ./build.sh > /tmp/build_b48.log 2>&1
B48_SHA=$(sha256sum build/BOOTX64.EFI | awk '{print $1}')
echo "      B48 substrate sha: $B48_SHA"

# Two-build determinism check on the B48-specific build
rm -f build/BOOTX64.EFI
CODEBOOK_INPUT="inputs/test_codebook_b48.txt" ./build.sh > /dev/null 2>&1
B48_SHA2=$(sha256sum build/BOOTX64.EFI | awk '{print $1}')
if [ "$B48_SHA" = "$B48_SHA2" ]; then
    echo "      B48 substrate two-build determinism: IDENTICAL"
else
    echo "      B48 substrate DRIFT: $B48_SHA != $B48_SHA2"
    exit 1
fi

# Step 3: Compile B48 canary surface
echo
echo "[2/4] Compiling B48 canary surface..."
python3 tools/atreyu_x86.py --pod38-codebook-imported-round-trip-build surfaces/test_pod38_b48_codebook_imported.cbc

# Step 4: Run canary (uses pod35_canary_test.sh; expects substrate already built)
echo
echo "[3/4] Running B48 canary..."
bash tools/pod35_canary_test.sh test_pod38_b48_codebook_imported pod38_b48_codebook_imported > /tmp/can_b48.log 2>&1
if [ -f "build/pod38_b48_codebook_imported.png" ]; then
    sz=$(stat -c %s "build/pod38_b48_codebook_imported.png")
    echo "      PASS  pod38_b48_codebook_imported.png ($sz bytes)"
else
    echo "      FAIL  no PNG produced"
    tail -10 /tmp/can_b48.log
    # Even if the canary failed, restore canonical build before exiting
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
echo "      (expected:     c09f2b3c449d9b32861b9ee3a1af85af3ccfba35224ccd05acb7a1ba72adb11f)"

if [ "$CANONICAL_SHA" = "c09f2b3c449d9b32861b9ee3a1af85af3ccfba35224ccd05acb7a1ba72adb11f" ]; then
    echo
    echo "=== Pod 3.8.G B48 runner: PASS — canonical contract preserved ==="
else
    echo
    echo "=== Pod 3.8.G B48 runner: WARNING — canonical contract drifted ==="
    exit 1
fi
