#!/bin/bash
# Pre-compiles all .cbs files to .cbc in boot/ directory
# Requires: Python 3, atreyu_x86.py (dev tool only)

# Set paths
SRC_DIR="surfaces"
BUILD_DIR="boot"
COMPILER="tools/atreyu_x86.py"

echo "Pre-compiling all CBS surfaces to .cbc files..."

# Compile each .cbs file to .cbc in boot/
for file in "$SRC_DIR"/*.cbs; do
    base=$(basename "$file" .cbs)
    echo "Compiling $base.cbs → $BUILD_DIR/$base.cbc"
    python3 "$COMPILER" "$file" "$BUILD_DIR/$base.cbc"
    if [ $? -ne 0 ]; then
        echo "ERROR: Compilation failed for $file"
        exit 1
    fi
done

echo "All CBS surfaces compiled successfully."