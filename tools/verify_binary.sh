#!/usr/bin/env bash
# tools/verify_binary.sh
# Pod 0 exit-gate check: build current source, diff against reference.
# Exits 0 on bit-for-bit match, 1 on any difference, 2 on missing reference.

set -e

if [ ! -f build/BOOTX64_reference.EFI ]; then
    echo "ERROR: build/BOOTX64_reference.EFI not found"
    echo "       Run Pod 0.0 to capture the reference, or pull it from git"
    exit 2
fi

./build.sh > /dev/null

if cmp -s build/BOOTX64.EFI build/BOOTX64_reference.EFI; then
    echo "OK: binary matches reference"
    exit 0
else
    REF_SIZE=$(wc -c < build/BOOTX64_reference.EFI)
    NEW_SIZE=$(wc -c < build/BOOTX64.EFI)
    echo "MISMATCH: build/BOOTX64.EFI differs from reference"
    echo "  reference: $REF_SIZE bytes"
    echo "  current:   $NEW_SIZE bytes"
    echo
    echo "First differing byte:"
    cmp build/BOOTX64.EFI build/BOOTX64_reference.EFI || true
    exit 1
fi
