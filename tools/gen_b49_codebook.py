#!/usr/bin/env python3
"""Generate Pod 3.9 B49 test codebook input.

10 entries × 384 dims with distinct cosine values vs query (1.0, 0.0, 0, ...):
  entry i (0-indexed; substrate id = i+1): vector (1.0, i*0.1, 0, ...)
  → cosine(query, entry_i) = 1.0 / sqrt(1 + (i*0.1)²) — monotonically decreasing
  → distinct cosines for each i; no tie-breaking ambiguity in sort verification

Best match: entry_0 (id=1) with cosine = 1.0 byte-exact (query is exact duplicate).
Worst: entry_9 (id=10) with cosine ≈ 1/sqrt(1.81) ≈ 0.7433.
"""
import os

DIM = 384
COUNT = 10

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(REPO, "inputs", "test_codebook_b49.txt")
os.makedirs(os.path.dirname(OUT), exist_ok=True)

lines = []
lines.append("# Pod 3.9 B49 test codebook: 10 entries with distinct cosines vs query")
lines.append("# entry i (0-indexed; substrate id = i+1): vec[0]=1.0, vec[1]=i*0.1, rest=0")
lines.append("# Used by tools/pod39_b49_runner.sh; not part of canonical build")
for i in range(COUNT):
    vec = ["0.0"] * DIM
    vec[0] = "1.0"
    vec[1] = "%g" % (i * 0.1)
    lines.append(", ".join(vec))

with open(OUT, "w") as f:
    f.write("\n".join(lines) + "\n")

print("wrote %s (%d entries x %d dims)" % (OUT, COUNT, DIM))
