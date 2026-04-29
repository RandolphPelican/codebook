# Pod 1.6 — Sign as Native Type — Recon Report

**Date:** 2026-04-28
**Pod:** 1.6 (canon-only, no source changes)
**Author:** Terminal Boy (Claude)
**Entry contract:** `32d404ed779fbc3ea9a06d44c0f3e7b801b8a04db7f67d9e549a12964344c0c6` (preserved — no source changes)
**Predecessor:** Pod 1.5.6 (sealed at ea23a8f)

---

## Section 1 — Sweep Findings

### Sweep A — File Inventory

| File | sha256 |
|------|--------|
| RECONSTITUTION.md | c98380cd384daced7bcbc4400562e03dd8281f8f0da33f19ed72d9f2616ebc95 |
| boot/defines.asm | (verified — 89 lines, opcode section at lines 55–89) |
| boot/vmdata.asm | (verified — 22 lines, VM runtime data) |
| recon/POD0.9_CAP_GRAPH_DEEP_READ.md | (verified — 444 lines) |
| recon/POD1.4_DECISION_RECORD.md | (verified — 127 lines) |

### Sweep B — Opcode Allocation Table

`boot/defines.asm` opcode section (lines 55–89), verbatim:

```nasm
; --- CBS VM Opcodes ---
%define OP_PUSH       0x01
%define OP_ADD        0x10
%define OP_SUB        0x11
%define OP_MUL        0x12
%define OP_DIV        0x13
%define OP_EQ         0x14
%define OP_NE         0x15
%define OP_LT         0x16
%define OP_GT         0x17
%define OP_LE         0x18
%define OP_GE         0x19
%define OP_RESERVE    0x20
%define OP_RET        0x53
%define OP_JIF        0x55
%define OP_JBACK      0x56
%define OP_LOAD       0x70
%define OP_STORE      0x71
%define OP_PRINT_NUM  0x80
%define OP_EMIT       0x81
%define OP_NEWLINE    0x82
%define OP_DUP        0x83
%define OP_DROP       0x84
%define OP_SWAP       0x85
%define OP_PRINT_STR  0x86
%define OP_JMP        0x40
%define OP_PUSH_STR   0x02
%define OP_MOD        0x1A
%define OP_CALL       0x50
%define OP_DUP2       0x87
%define OP_GRANT_CAP  0x90
%define OP_USE_CAP    0x91
%define OP_HALT       0xFF
%define OP_GRANT_CAP_NEW 0xCA000003
%define OP_USE_CAP_NEW 0xCA000004
```

**0xA0–0xAF range: entirely free.** No defines in that range. Confirmed.

### Sweep C/D/G

N/A — no cross-module symbol changes, no new directories, cemeteries unchanged.

### Sweep E — Git Log + Ref State

Last 5 commits:

```
ea23a8f Pod 1.5.6 — RECONSTITUTION v5 pod-arc reconciliation + MEMO_VERIFICATION_PROVENANCE commit
b560a6c Pod 1.5.5 — pre-Pod-1.6 architect orientation recon
e6a2cc2 Pod 1.5: 64-bit integer width migration — runtime, toolchain, bytecode
eabf160 Pod 1.5: Phase 1 recon report (R1-R12)
7a825f2 Pod 1.4: RECONSTITUTION v5 — width-migration decisions, VM fixes retroactive, arc slide
```

Three-oracle ref check:

```
git rev-parse HEAD:        ea23a8f9df12af55b26e9016c7f08a1f9416660e
git rev-parse origin/main: ea23a8f9df12af55b26e9016c7f08a1f9416660e
git ls-remote origin main: ea23a8f9df12af55b26e9016c7f08a1f9416660e
```

All three match. Pod 1.5.6 seal confirmed at HEAD.

### Sweep F — Markdown Inventory

`recon/POD1.6_DECISION_RECORD.md`: confirmed absent (does not yet exist).
`RECONSTITUTION.md`: 407 lines, sha256 `c98380cd384daced7bcbc4400562e03dd8281f8f0da33f19ed72d9f2616ebc95`.

---

## R3 — cap_graph static pool excerpt

From `recon/POD0.9_CAP_GRAPH_DEEP_READ.md` lines 168–184:

```
struct CapNode {
    u64 parent;           // index into cap_pool, 0 = root
    u64 child;             // first child index (linked list head)
    u64 sibling;           // next sibling (for traversal)
    u64 cap_bitmap;       // 64 bits of capability resources
    u64 energy_budget;    // joules granted
    u64 energy_used;      // joules consumed
    u64 nonce;             // anti-replay
    u64 expiry;            // time-bound (0 = never)
    u8  signature[64];   // Ed25519 over the above
}
// Total: 8*8 + 64 = 128 bytes per node, 16x the original 20 bytes
// At 64 nodes, total cap graph storage = 8 KB
```

Cap pool: 64 nodes × 128 bytes = 8KB.
Sign pool (A1): 64 nodes × 256 bytes = 16KB.
Sign pool is 2× cap pool per slot due to label (64B) and hash (32B) fields.

### Recommendation from Pod 0.9 memo

From line 311: "Recommendation: **static pool.** Simplicity, determinism,
no UEFI BS allocation." This directly supports A1's static pool decision.

---

## R4 — Pod 1.4 Decision Record

See `recon/POD1.4_DECISION_RECORD.md` (127 lines). Read in full. Format:
D1/D2/D3 decisions with Decision/Rationale/Impact sections, plus
retroactive Pod 1.3 documentation, protocol additions, and arc slide.
Pod 1.6 decision record will follow this format structure.

---

## R6 — boot/vmdata.asm Static Memory Layout

```nasm
    align 16
energy_budget: dq 100000
energy_used:   dq 0
vm_ret_ptr:     dq 0
vm_ret_stack:   times 256 dq 0     ; 2KB return stack
vm_stack:   times 512 dq 0     ; 4KB VM stack
vm_vars:    times 64 dq 0      ; 512 bytes variables (64-bit, Pod 1.5)

; Memory map buffer (8KB)
    align 16
mmap_buf:   times 8192 db 0
```

Current static allocations:
- energy_budget: 8 bytes
- energy_used: 8 bytes
- vm_ret_ptr: 8 bytes
- vm_ret_stack: 2,048 bytes (256 × 8)
- vm_stack: 4,096 bytes (512 × 8)
- vm_vars: 512 bytes (64 × 8)
- mmap_buf: 8,192 bytes
- **Total: ~14,872 bytes**

Adding `vm_sign_pool` (64 × 256 = 16,384 bytes) would roughly double
the static VM data. No conflict with existing allocations — this is
static BSS-style data in a PE section. Room is available.

---

## Verification of pre-ratified decisions

### A1 verification — Static pool with stack handle

**Does v5's Sign definition or any v4/v5 decision-record canon already
commit to a representation that contradicts static-pool?**

**No.** v5's Sign definition (lines 110–116) is abstract:
```
Sign := {
  content_hash: bytes(32),
  embedding:    vector(N),
  label:        string(<=64),
  provenance:   ProvChain,
  energy_cost:  Energy,
}
```
No representation commitment. v5's Cap<R> section (lines 172–174)
explicitly uses the static pool precedent: "The static cap pool is sized
at 64 nodes for V1.0 (per the original Phase 5.1 design). 64 × 128 bytes
= 8 KB total." Pod 0.9 recommended static pool (line 311). A1 is
consistent.

**VERIFIED: no contradiction.**

### A2 verification — Sign field list matches v5 baseline

**Does v5's Sign field list match the v3 baseline
(hash, embedding, label, provenance, energy_cost)?**

**Yes.** v5 line 107 says "(Unchanged from v2.)" The five fields in v5
(lines 111–115) are: content_hash bytes(32), embedding vector(N), label
string(<=64), provenance ProvChain, energy_cost Energy. Exact match with
A2's field list. A2's concrete byte layout maps these fields to fixed
offsets with handles for variable-sized fields (embedding, provenance).

**VERIFIED: field list matches.**

### A3 verification — 0xA0–0xAF range is free

**Is 0xA0–0xAF entirely free in current `boot/defines.asm`?**

**Yes.** Highest allocated single-byte opcode is 0x91 (OP_USE_CAP). Next
is 0xFF (OP_HALT). The 0xA0–0xAF range has zero defines. v5's opcode
allocation table (lines 212–218) reserves this range for Sign at Pod 1.6.

**VERIFIED: range is free.**

### A4 verification — No canon commitment to use-time validation

**Does any v4/v5 canon commit to use-time validation for typed
primitives?**

**No.** v5's Cap<R> section (line 163) says "V1.0 leaves the field as
zeros and validates only structure (parent valid, bitmap match, energy
sufficient)" — this is construction/structure validation, not use-time
content re-validation. No v4/v5 decision record mentions validation
timing for typed primitives.

**VERIFIED: no contradiction.**

### A5 verification — No Energy representation constraint

**Does v5 already commit to an Energy representation that would
constrain Sign's energy_cost field?**

**No.** v5 defines energy_cost as type `Energy` in Sign's abstract
definition but provides no concrete representation. The opcode table
allocates 0xD0–0xDF for Energy at Pod 1.7. No byte layout for Energy
exists in any canon document.

**VERIFIED: no contradiction.**

### A6 verification — No mutability semantics committed

**Does v5 commit to mutability semantics for typed primitives?**

**No.** v5's ProvChain reference in Sign's definition implies append
behavior ("log of who wrote/touched this Sign"), which is consistent
with A6's separate-pool mutability model. No explicit mutability
decision exists in v4/v5 canon.

**VERIFIED: no contradiction.**

### A7 verification — OP_DUP2 still orphaned

**Is OP_DUP2 still orphaned?**

**Yes.** `boot/defines.asm:84` defines `OP_DUP2 0x87`. Handler exists at
`boot/cbs_vm.asm:660` (`.op_dup2:` label). Dispatch chain (lines 57–118)
has no `cmp al, OP_DUP2` / `je .op_dup2` entry. Still orphaned per
Pod 1.5.5 §B, DEFERRED #6.

**VERIFIED: still orphaned.**

---

## Section 2 — Surprises

No surprises. All seven verifications returned expected results. v5's
Sign definition is unchanged from v2 baseline. Opcode range is free.
Static pool precedent is consistent. No canon contradictions found.

---

## Section 3 — Architect Questions

None. All pre-ratified decisions verified against current canon.
No contradictions, no ambiguities requiring resolution.

---

*Phase 1 complete. All seven A-item verifications passed. Halting for
architect AUTHORIZED.*

*From layer 1 kernel up.*
