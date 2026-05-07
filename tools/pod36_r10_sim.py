#!/usr/bin/env python3
"""Pod 3.6 HALT 1 R10 — bit-exact f32 simulation for synthesis ops.

Models the canonical evaluation orders documented in the Pod 3.6 recon report
under R10. All intermediate values are forced through f32 via struct.pack so
results match what NASM-emitted SSE-scalar code will produce on hardware.
"""

import struct
import math

DIM = 384


def f32(x: float) -> float:
    """Round x through f32 (single-precision)."""
    return struct.unpack('<f', struct.pack('<f', x))[0]


def bits(x: float) -> int:
    """f32 bit pattern as i32."""
    return struct.unpack('<I', struct.pack('<f', x))[0]


def hexbits(x: float) -> str:
    return f'0x{bits(x):08X}'


def addss(a: float, b: float) -> float:
    return f32(f32(a) + f32(b))


def subss(a: float, b: float) -> float:
    return f32(f32(a) - f32(b))


def mulss(a: float, b: float) -> float:
    return f32(f32(a) * f32(b))


def divss(a: float, b: float) -> float:
    return f32(f32(a) / f32(b))


def sqrtss(x: float) -> float:
    return f32(math.sqrt(f32(x)))


# --- canonical forms ---

def add_vec(a, b):
    return [addss(a[i], b[i]) for i in range(DIM)]


def sub_vec(a, b):
    return [subss(a[i], b[i]) for i in range(DIM)]


def scale_vec(s, a):
    sf = f32(s)
    return [mulss(sf, a[i]) for i in range(DIM)]


def normalize_vec(a):
    """Form A: norm_sq = sum a[i]*a[i] (left-to-right addss); norm = sqrtss(norm_sq);
    if norm_sq == 0.0f -> CF=1 (zero-norm rejection); result[i] = a[i] / norm."""
    norm_sq = 0.0
    for i in range(DIM):
        norm_sq = addss(norm_sq, mulss(a[i], a[i]))
    if bits(norm_sq) == 0:
        return None  # zero-norm rejection (CF=1)
    norm = sqrtss(norm_sq)
    return ([divss(a[i], norm) for i in range(DIM)], norm_sq, norm)


def lerp_vec(a, b, t):
    """Form A: one_minus_t = 1.0 - t; result[i] = (one_minus_t * a[i]) + (t * b[i])."""
    tf = f32(t)
    omt = subss(1.0, tf)
    return [addss(mulss(omt, a[i]), mulss(tf, b[i])) for i in range(DIM)]


# --- canonical test inputs ---

def e_unit(idx, val=1.0):
    v = [0.0] * DIM
    v[idx] = f32(val)
    return v


def zero_vec():
    return [0.0] * DIM


def v_uniform():
    val = f32(1.0 / math.sqrt(DIM))
    return [val] * DIM


def report_first_n(label, v, n=4):
    print(f'  {label}: ' + ', '.join(hexbits(v[i]) for i in range(n)))


def all_zero_after(v, k):
    return all(bits(v[i]) == 0 for i in range(k, DIM))


def all_eq(va, vb):
    return all(bits(va[i]) == bits(vb[i]) for i in range(DIM))


print('=== Pod 3.6 R10 — bit-exact f32 simulation ===\n')

# --- ADD ---
print('B25 add(e_unit_x, e_unit_y):')
r = add_vec(e_unit(0), e_unit(1))
report_first_n('result[0..3]', r)
print(f'  zeros from [2..]: {all_zero_after(r, 2)}')
print(f'  -> result[0]={hexbits(r[0])} (expect 0x3F800000), '
      f'result[1]={hexbits(r[1])} (expect 0x3F800000)')

print('\nB26 add(a, zero) for a = arbitrary nonzero pattern:')
a = [f32(0.1 + 0.01 * i) for i in range(DIM)]
r = add_vec(a, zero_vec())
print(f'  result == a byte-exact: {all_eq(r, a)}')

# --- SUBTRACT ---
print('\nB27 sub(e_unit_x, e_unit_y):')
r = sub_vec(e_unit(0), e_unit(1))
report_first_n('result[0..3]', r)
print(f'  -> result[0]={hexbits(r[0])} (expect 0x3F800000), '
      f'result[1]={hexbits(r[1])} (expect 0xBF800000)')

print('\nB28 sub(a, a) for a = arbitrary nonzero pattern:')
r = sub_vec(a, a)
print(f'  all elements byte-exact 0: {all(bits(r[i]) == 0 for i in range(DIM))}')

# --- SCALE ---
print('\nB29 scale(2.0, e_unit_x):')
r = scale_vec(2.0, e_unit(0))
print(f'  result[0]={hexbits(r[0])} (expect 0x40000000), '
      f'zeros[1..]: {all_zero_after(r, 1)}')

print('\nB30 scale(0.0, a):')
r = scale_vec(0.0, a)
print(f'  all elements byte-exact 0: {all(bits(r[i]) == 0 for i in range(DIM))}')

print('\nB31 scale(-1.0, a) (negation):')
r = scale_vec(-1.0, a)
expected = [f32(-a[i]) for i in range(DIM)]
print(f'  result == -a byte-exact: {all_eq(r, expected)}')

# --- NORMALIZE ---
print('\nB32 normalize(scale(2.0, e_unit_x)):')
inp = scale_vec(2.0, e_unit(0))
result = normalize_vec(inp)
if result is None:
    print('  ZERO-NORM REJECTION (unexpected)')
else:
    r, norm_sq, norm = result
    print(f'  norm_sq={hexbits(norm_sq)} (expect 0x40800000 = 4.0), '
          f'norm={hexbits(norm)} (expect 0x40000000 = 2.0)')
    print(f'  result[0]={hexbits(r[0])} (expect 0x3F800000 = 1.0), '
          f'zeros[1..]: {all_zero_after(r, 1)}')

print('\nB33 normalize(zero_vector):')
result = normalize_vec(zero_vec())
print(f'  zero-norm rejection (CF=1): {result is None}')

# --- LERP ---
print('\nB34 lerp(e_unit_x, e_unit_y, 0.5):')
r = lerp_vec(e_unit(0), e_unit(1), 0.5)
report_first_n('result[0..3]', r)
print(f'  -> result[0]={hexbits(r[0])} (expect 0x3F000000 = 0.5), '
      f'result[1]={hexbits(r[1])} (expect 0x3F000000 = 0.5)')

print('\nB35 lerp(a, b, 0.0):')
b_pat = [f32(0.5 - 0.005 * i) for i in range(DIM)]
r = lerp_vec(a, b_pat, 0.0)
print(f'  result == a byte-exact (Form A endpoint property): {all_eq(r, a)}')

print('\nB36 lerp(a, b, 1.0):')
r = lerp_vec(a, b_pat, 1.0)
print(f'  result == b byte-exact (Form A endpoint property): {all_eq(r, b_pat)}')

# --- A6 SURFACE PREDICTIONS ---
print('\n=== A6 surface candidates ===')

print('\n[Predicted Surprise] normalize(v_uniform) — accumulator drift:')
inp = v_uniform()
print(f'  v_uniform[i] = {hexbits(inp[0])} (= f32(1/sqrt(384)))')
result = normalize_vec(inp)
if result is None:
    print('  ZERO-NORM (UNEXPECTED)')
else:
    r, norm_sq, norm = result
    print(f'  norm_sq={hexbits(norm_sq)} (algebraic 1.0 = 0x3F800000)')
    print(f'  norm={hexbits(norm)} (algebraic 1.0 = 0x3F800000)')
    print(f'  result[0]={hexbits(r[0])} (algebraic prior {hexbits(inp[0])})')
    drift_count = sum(1 for i in range(DIM) if bits(r[i]) != bits(inp[0]))
    print(f'  elements drifting from input: {drift_count}/{DIM}')

print('\n[Predicted Surprise] lerp(e_unit_x, scale(2.0, e_unit_y), 1/3):')
r = lerp_vec(e_unit(0), scale_vec(2.0, e_unit(1)), 1.0/3.0)
omt = subss(1.0, f32(1.0/3.0))
algebraic_0 = f32(2.0/3.0)  # would be (1-1/3)*1 + (1/3)*0
algebraic_1 = f32(2.0/3.0)  # would be (1-1/3)*0 + (1/3)*2
print(f'  one_minus_t = {hexbits(omt)} (= subss(1.0, f32(1/3)))')
print(f'  result[0]={hexbits(r[0])} (algebraic prior {hexbits(algebraic_0)} = 2/3 in f32)')
print(f'  result[1]={hexbits(r[1])} (algebraic prior {hexbits(algebraic_1)} = 2/3 in f32)')
print(f'  result[0] drift from algebraic 2/3: {bits(r[0]) - bits(algebraic_0)} ulp(s)')
print(f'  result[1] drift from algebraic 2/3: {bits(r[1]) - bits(algebraic_1)} ulp(s)')

print('\n[Predicted Surprise] lerp at t=0.5 between asymmetric vectors:')
v_a = e_unit(0, 3.0)  # a = (3, 0, 0, ...)
v_b = e_unit(0, 1.0)  # b = (1, 0, 0, ...)
r = lerp_vec(v_a, v_b, 0.5)
algebraic = f32(2.0)  # 0.5*3 + 0.5*1 = 1.5 + 0.5 = 2.0
print(f'  lerp((3,0,...), (1,0,...), 0.5)')
print(f'  result[0]={hexbits(r[0])} (algebraic prior {hexbits(algebraic)} = 2.0)')
print(f'  drift: {bits(r[0]) - bits(algebraic)} ulp(s)')
