#!/bin/bash
# Compiles lexer.cbs to boot/lexer.cbc

echo "Compiling lexer.cbs → boot/lexer.cbc"
python3 tools/atreyu_x86.py surfaces/lexer.cbs boot/lexer.cbc
python3 tools/atreyu_x86.py surfaces/lexer_main.cbs boot/lexer_main.cbc