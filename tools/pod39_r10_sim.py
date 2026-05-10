#!/usr/bin/env python3
"""Pod 3.9 HALT 1 R10 — bit-exact f32 top-K simulation for B49.

Replicates substrate's compute_cosine_raw Form A bit-exactly (mirrors
tools/pod36_r10_sim.py). For each codebook entry, computes cosine vs query
through the same f32 evaluation order the substrate uses; sorts descending;
returns top-K predicted ordering with bit-exact cosine values.

D3.28 framing: substrate's two-build determinism contract extends to FP
ordering — bit-exact cosine values per pair determine the substrate's
top-K output ordering deterministically. This sim's predicted ordering
should match B49 canary output byte-exact (substrate-runtime cosines via
compute_cosine_raw produce same bit patterns as Python struct.pack
simulation per D3.28 / Pod 3.6 B32-aux + B34-aux empirical anchors).
"""
import struct
import math

DIM = 384
COUNT = 10
K = 5
THRESHOLD_BITS = 0xFF800000   # -INF f32 sentinel; unfiltered top-K


def f32(x):
    return struct.unpack("<f", struct.pack("<f", x))[0]


def bits(x):
    return struct.unpack("<I", struct.pack("<f", x))[0]


def hexbits(x):
    return "0x%08X" % bits(x)


def addss(a, b):
    return f32(f32(a) + f32(b))


def mulss(a, b):
    return f32(f32(a) * f32(b))


def divss(a, b):
    return f32(f32(a) / f32(b))


def sqrtss(x):
    return f32(math.sqrt(f32(x)))


def cosine_form_a(a, b):
    """Bit-exact substrate compute_cosine_raw Form A."""
    # Step 1: dot = sum a[i] * b[i]
    dot = 0.0
    for i in range(DIM):
        dot = addss(dot, mulss(a[i], b[i]))

    # Step 2: norm_a_sq
    norm_a_sq = 0.0
    for i in range(DIM):
        norm_a_sq = addss(norm_a_sq, mulss(a[i], a[i]))

    # Step 3: norm_b_sq
    norm_b_sq = 0.0
    for i in range(DIM):
        norm_b_sq = addss(norm_b_sq, mulss(b[i], b[i]))

    # Step 4: zero-norm rejection
    if bits(norm_a_sq) == 0 or bits(norm_b_sq) == 0:
        return None

    # Step 5-6: norms
    norm_a = sqrtss(norm_a_sq)
    norm_b = sqrtss(norm_b_sq)

    # Step 7: denom
    denom = mulss(norm_a, norm_b)

    # Step 8: cosine
    return divss(dot, denom)


def make_query():
    """Query vector: (1.0, 0.0, 0.0, ..., 0.0) f32."""
    v = [0.0] * DIM
    v[0] = f32(1.0)
    return v


def make_codebook_entry(i):
    """Entry i (0-indexed): vec[0]=1.0, vec[1]=i*0.1, rest=0."""
    v = [0.0] * DIM
    v[0] = f32(1.0)
    v[1] = f32(i * 0.1)
    return v


def main():
    query = make_query()
    print("=== Pod 3.9 R10 — bit-exact top-K simulation for B49 ===")
    print("Query: vec[0]=%s vec[1]=%s rest=0.0" % (hexbits(query[0]), hexbits(query[1])))
    print("K=%d, threshold=%s (-INF; unfiltered top-K)" % (K, "0x%08X" % THRESHOLD_BITS))
    print()

    # Compute cosine(query, entry_i) for each codebook entry
    print("Per-entry cosine (substrate forge order: codebook_index → substrate_id = index+1):")
    scores = []
    for i in range(COUNT):
        entry = make_codebook_entry(i)
        cos = cosine_form_a(query, entry)
        scores.append((i, cos))
        sub_id = i + 1
        print("  id=%d codebook_index=%d cosine=%s (decimal=%d)" % (
            sub_id, i, hexbits(cos), bits(cos)))

    print()

    # Sort descending by cosine bits (using f32 ordering — but bits compare correctly
    # for positive values; cosines here are all in [0, 1] so unsigned bit compare works)
    scores.sort(key=lambda x: bits(x[1]), reverse=True)

    print("Predicted top-K ordering (descending cosine; substrate id):")
    top_k = scores[:K]
    for rank, (idx, cos) in enumerate(top_k):
        sub_id = idx + 1
        print("  rank=%d substrate_id=%d codebook_index=%d cosine=%s (decimal=%d)" % (
            rank, sub_id, idx, hexbits(cos), bits(cos)))

    print()
    print("Expected canary output ordering (best to worst):")
    print("  id_0 (best) = %d" % (top_k[0][0] + 1))
    for r in range(1, K):
        print("  id_%d        = %d" % (r, top_k[r][0] + 1))


if __name__ == "__main__":
    main()
