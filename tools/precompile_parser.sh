#!/bin/bash
# Compiles parser.cbs to boot/parser.cbc

echo "Compiling parser.cbs → boot/parser.cbc"
python3 tools/atreyu_x86.py surfaces/parser.cbs boot/parser.cbc
python3 tools/atreyu_x86.py surfaces/parser_main.cbs boot/parser_main.cbc