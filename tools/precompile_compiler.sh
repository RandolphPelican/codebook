#!/bin/bash
# Compiles compiler.cbs and cb_compiler.cbs to boot/

echo "Compiling compiler.cbs → boot/compiler.cbc"
python3 tools/atreyu_x86.py surfaces/compiler.cbs boot/compiler.cbc
python3 tools/atreyu_x86.py surfaces/compiler_main.cbs boot/compiler_main.cbc
python3 tools/atreyu_x86.py surfaces/cb_compiler.cbs boot/cb_compiler.cbc