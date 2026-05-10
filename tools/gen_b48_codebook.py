#!/usr/bin/env python3
"""Generate Pod 3.8 B48 test codebook input.

5 entries × 384 dims, each entry is a basis vector:
  entry i (1-indexed): dim (i-1) = 1.0, all other dims = 0
"""
import os

DIM = 384
COUNT = 5

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(REPO, "inputs", "test_codebook_b48.txt")
os.makedirs(os.path.dirname(OUT), exist_ok=True)

lines = []
lines.append("# Pod 3.8 B48 test codebook: 5 basis vectors")
lines.append("# entry i (1-indexed): dim (i-1) = 1.0, all other dims = 0")
lines.append("# Used by tools/pod38_b48_runner.sh; not part of canonical build")
for i in range(COUNT):
    vec = ["0.0"] * DIM
    vec[i] = "1.0"
    lines.append(", ".join(vec))

with open(OUT, "w") as f:
    f.write("\n".join(lines) + "\n")

print("wrote %s (%d entries x %d dims)" % (OUT, COUNT, DIM))
