#!/usr/bin/env python3
"""Pod 3.10 HALT 1 R10 — bit-exact f32 simulation for project + reject.

Replicates substrate's compute_project_raw / compute_reject_raw evaluation order
per Form A canon (3.10.B):
  - project(A, B): ratio = divss(dot_AB, dot_BB); result[d] = mulss(ratio, B[d])
  - reject(A, B):  same ratio; result[d] = subss(A[d], mulss(ratio, B[d])) (single-pass)

D3.40 hybrid degeneracy: bits(dot_BB) == 0 → CF=1 zero-norm rejection (None return).

D3.28 self-verifying canon: predicted bit patterns match substrate runtime
byte-exact. Drift instances (dot(reject(A, B), B) for non-orthogonal A) are
self-verifying via R10 prediction.
"""

import struct
import math

DIM = 384


def f32(x: float) -> float:
    return struct.unpack('<f', struct.pack('<f', x))[0]


def bits(x: float) -> int:
    return struct.unpack('<I', struct.pack('<f', x))[0]


def hexbits(x: float) -> str:
    return f'0x{bits(x):08X}'


def addss(a, b): return f32(f32(a) + f32(b))
def subss(a, b): return f32(f32(a) - f32(b))
def mulss(a, b): return f32(f32(a) * f32(b))
def divss(a, b): return f32(f32(a) / f32(b))


# --- Canonical f32 helpers (mirror substrate compute_dot_product) ---

def dot(a, b):
    """Form A: left-to-right per-dim accumulator; xorps init."""
    acc = 0.0
    for i in range(DIM):
        acc = addss(acc, mulss(a[i], b[i]))
    return acc


# --- compute_project_raw / compute_reject_raw bit-exact mirrors ---

def project_vec(a, b):
    """Form A: dot_AB / dot_BB ratio; per-element mulss(ratio, b[d]).
    Returns None on bits(dot_BB) == 0 (CF=1 zero-norm rejection per D3.40)."""
    dot_ab = dot(a, b)
    dot_bb = dot(b, b)
    if bits(dot_bb) == 0:
        return None
    ratio = divss(dot_ab, dot_bb)
    return ([mulss(ratio, b[i]) for i in range(DIM)], dot_ab, dot_bb, ratio)


def reject_vec(a, b):
    """Form A single-pass: per-element subss(a[d], mulss(ratio, b[d]));
    two rounding events per dim. Returns None on bits(dot_BB) == 0."""
    dot_ab = dot(a, b)
    dot_bb = dot(b, b)
    if bits(dot_bb) == 0:
        return None
    ratio = divss(dot_ab, dot_bb)
    return ([subss(a[i], mulss(ratio, b[i])) for i in range(DIM)], dot_ab, dot_bb, ratio)


# --- Test inputs ---

def zero_vec(): return [0.0] * DIM


def e_unit(idx, val=1.0):
    v = [0.0] * DIM
    v[idx] = f32(val)
    return v


def vec_from(*pairs):
    """Build vec with vec[idx]=val pairs; rest = 0."""
    v = [0.0] * DIM
    for idx, val in pairs:
        v[idx] = f32(val)
    return v


def all_eq(va, vb):
    return all(bits(va[i]) == bits(vb[i]) for i in range(DIM))


def all_zero(v):
    return all(bits(v[i]) == 0 for i in range(DIM))


def report_dims(label, v, indices):
    parts = [f'[{i}]={hexbits(v[i])}' for i in indices]
    print(f'  {label}: ' + ', '.join(parts))


# --- B50 PROJECT identities + drift ---

print('=== Pod 3.10 R10 — bit-exact f32 simulation for project + reject ===\n')

print('--- B50 PROJECT identities ---\n')

# B50 identity 1: project(A, A) = A byte-exact (A nonzero)
print('B50.id1 project(A, A) = A byte-exact (A nonzero):')
A_id1 = vec_from((0, 1.0), (1, 2.0), (5, 3.0))
r = project_vec(A_id1, A_id1)
if r is None:
    print('  CF=1 (UNEXPECTED)')
else:
    res, dab, dbb, ratio = r
    print(f'  dot_AA = {hexbits(dab)} (expect 0x41600000 = 14.0; 1+4+9)')
    print(f'  ratio = dot_AA/dot_AA = {hexbits(ratio)} (expect 0x3F800000 = 1.0 byte-exact)')
    print(f'  result == A byte-exact: {all_eq(res, A_id1)}')
    report_dims('result sample', res, [0, 1, 5])

# B50 identity 2: project(zero, B) = zero (B nonzero)
print('\nB50.id2 project(zero, B) = zero (B nonzero):')
B_id2 = vec_from((0, 3.0), (1, 4.0))
r = project_vec(zero_vec(), B_id2)
if r is None:
    print('  CF=1 (UNEXPECTED)')
else:
    res, dab, dbb, ratio = r
    print(f'  dot_AB = {hexbits(dab)} (expect 0x00000000 = +0)')
    print(f'  ratio = 0/dot_BB = {hexbits(ratio)} (expect 0x00000000 = +0)')
    print(f'  result all zero: {all_zero(res)}')

# B50 identity 3: project(A, zero) → CF=1 (zero-norm rejection)
print('\nB50.id3 project(A, zero) → CF=1 (zero-norm rejection):')
A_id3 = vec_from((0, 1.0), (1, 1.0))
r = project_vec(A_id3, zero_vec())
print(f'  CF=1 (zero-norm rejection): {r is None}')

# B50 concrete: project((1,1,0,..), (1,0,0,..)) = (1,0,0,..)
print('\nB50.c1 project((1,1,0..), (1,0,0..)):')
A_c1 = vec_from((0, 1.0), (1, 1.0))
B_c1 = vec_from((0, 1.0))
r = project_vec(A_c1, B_c1)
res, dab, dbb, ratio = r
print(f'  dot_AB = {hexbits(dab)} (expect 0x3F800000 = 1.0)')
print(f'  dot_BB = {hexbits(dbb)} (expect 0x3F800000 = 1.0)')
print(f'  ratio  = {hexbits(ratio)} (expect 0x3F800000 = 1.0)')
report_dims('result', res, [0, 1, 2])
print(f'  result == B byte-exact: {all_eq(res, B_c1)}')

# B50 concrete: project((3,4,0,..), (1,0,0,..)) = (3,0,0,..)
print('\nB50.c2 project((3,4,0..), (1,0,0..)):')
A_c2 = vec_from((0, 3.0), (1, 4.0))
B_c2 = vec_from((0, 1.0))
r = project_vec(A_c2, B_c2)
res, dab, dbb, ratio = r
print(f'  dot_AB = {hexbits(dab)} (expect 0x40400000 = 3.0)')
print(f'  ratio  = {hexbits(ratio)} (expect 0x40400000 = 3.0)')
report_dims('result', res, [0, 1])
print(f'  expect result[0]=0x40400000 (3.0), result[1]=0x00000000 (0.0)')

# --- B51 REJECT identities + drift ---

print('\n\n--- B51 REJECT identities + orthogonality drift ---\n')

# B51 identity 1: reject(A, A) = +0 vector byte-exact (A nonzero)
print('B51.id1 reject(A, A) = +0 vector byte-exact (A nonzero):')
A_rid1 = vec_from((0, 1.0), (1, 2.0), (5, 3.0))
r = reject_vec(A_rid1, A_rid1)
if r is None:
    print('  CF=1 (UNEXPECTED)')
else:
    res, dab, dbb, ratio = r
    print(f'  ratio = {hexbits(ratio)} (expect 0x3F800000 = 1.0 byte-exact)')
    print(f'  result all +0 byte-exact: {all_zero(res)}')
    print(f'  ↳ subss(x, mulss(1.0, x)) = subss(x, x) = +0.0 via B28 endpoint property')
    print(f'  ↳ downstream normalize/cosine on result triggers zero-norm CF=1 per D3.40')

# B51 identity 2: reject(zero, B) = zero
print('\nB51.id2 reject(zero, B) = zero (B nonzero):')
B_rid2 = vec_from((0, 3.0), (1, 4.0))
r = reject_vec(zero_vec(), B_rid2)
res, _, _, _ = r
print(f'  result all zero: {all_zero(res)}')

# B51 identity 3: reject(A, zero) → CF=1
print('\nB51.id3 reject(A, zero) → CF=1 (zero-norm rejection):')
r = reject_vec(vec_from((0, 1.0)), zero_vec())
print(f'  CF=1: {r is None}')

# B51 concrete: reject((1,1,0,..), (1,0,0,..)) = (0,1,0,..)
print('\nB51.c1 reject((1,1,0..), (1,0,0..)):')
A_rc1 = vec_from((0, 1.0), (1, 1.0))
B_rc1 = vec_from((0, 1.0))
r = reject_vec(A_rc1, B_rc1)
res, dab, dbb, ratio = r
print(f'  ratio  = {hexbits(ratio)} (expect 0x3F800000 = 1.0)')
report_dims('result', res, [0, 1, 2])
expected = vec_from((1, 1.0))
print(f'  result == (0,1,0..) byte-exact: {all_eq(res, expected)}')

# B51 concrete: reject((3,4,0,..), (1,0,0,..)) = (0,4,0,..)
print('\nB51.c2 reject((3,4,0..), (1,0,0..)):')
A_rc2 = vec_from((0, 3.0), (1, 4.0))
B_rc2 = vec_from((0, 1.0))
r = reject_vec(A_rc2, B_rc2)
res, _, _, _ = r
report_dims('result', res, [0, 1])
print(f'  expect result[0]=0x00000000 (0.0), result[1]=0x40800000 (4.0)')

# --- B51 ORTHOGONALITY DRIFT PANEL (D3.28 self-verifying canon for Pod 3.10) ---

print('\n\n--- B51 orthogonality drift panel (D3.28 self-verifying canon for Pod 3.10) ---\n')
print('Mathematical identity: dot(reject(A, B), B) = 0 for all A, B nonzero.')
print('In f32 single-pass reject: compound rounding (mulss + subss + dot accumulator)')
print('produces a finite drift; NOT byte-exact zero in general. R10 predicts the')
print('exact bit pattern; B51 canary verifies substrate matches predicted drift.\n')

# Drift case 1: A and B share dim 0 only — drift should still arise
print('B51.drift1 A=(1,1,0..) B=(1,0,0..) (B perpendicular to (0,1,..)):')
res, dab, dbb, ratio = reject_vec(A_rc1, B_rc1)
d = dot(res, B_rc1)
print(f'  dot(reject, B) = {hexbits(d)}')
print(f'  byte-exact zero: {bits(d) == 0}')
print(f'  ↳ trivial case: reject = (0,1,0,..); B = (1,0,..); dim-0 product = 0; sum = 0')

# Drift case 2: irrational ratio — A=(1,1,0..) B=(3,4,0..)
print('\nB51.drift2 A=(1,1,0..) B=(3,4,0..) (ratio = 7/25 not exactly representable):')
A_d2 = vec_from((0, 1.0), (1, 1.0))
B_d2 = vec_from((0, 3.0), (1, 4.0))
r = reject_vec(A_d2, B_d2)
res, dab, dbb, ratio = r
print(f'  dot_AB = {hexbits(dab)} (= 7.0)')
print(f'  dot_BB = {hexbits(dbb)} (= 25.0)')
print(f'  ratio  = {hexbits(ratio)} (= 7/25 ≈ 0.28; not byte-exact representable)')
report_dims('reject', res, [0, 1])
d = dot(res, B_d2)
print(f'  dot(reject, B) = {hexbits(d)} (drift; mathematical 0; substrate must match this bit pattern)')

# Drift case 3: A and B with multiple shared nonzero dims
print('\nB51.drift3 A=(1,2,3,0..) B=(1,1,1,0..) (ratio = 6/3 = 2.0 byte-exact):')
A_d3 = vec_from((0, 1.0), (1, 2.0), (2, 3.0))
B_d3 = vec_from((0, 1.0), (1, 1.0), (2, 1.0))
r = reject_vec(A_d3, B_d3)
res, dab, dbb, ratio = r
print(f'  dot_AB = {hexbits(dab)} (= 6.0)')
print(f'  dot_BB = {hexbits(dbb)} (= 3.0)')
print(f'  ratio  = {hexbits(ratio)} (expect 0x40000000 = 2.0 byte-exact)')
report_dims('reject', res, [0, 1, 2])
print(f'  expect reject = (1-2, 2-2, 3-2, 0..) = (-1, 0, 1, 0..)')
d = dot(res, B_d3)
print(f'  dot(reject, B) = {hexbits(d)} (= -1+0+1 = 0 byte-exact in this case)')

print('\n=== R10 sim complete ===')
