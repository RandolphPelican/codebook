# Pod 2.2 Recon Report — Babylon's Vocabulary

**Pod:** 2.2 — cap_bitmap texture + bit-check enforcement
**Entry HEAD:** f3f0f06249183ed870a8511ee448b731fcd09cd2 (Pod 2.1 seal)
**Entry binary contract:** 8a8236f6f6d0e3473904096a166903c992a7f12187fe5b7fad6d28548499ba1f (verified)
**Recon date:** 2026-05-05

---

## R1 — Pre-flight three-oracle

```
HEAD:           f3f0f06249183ed870a8511ee448b731fcd09cd2
origin/main:    f3f0f06249183ed870a8511ee448b731fcd09cd2
ls-remote:      f3f0f06249183ed870a8511ee448b731fcd09cd2  refs/heads/main
```

Three-oracle agreement verified at f3f0f06 (Pod 2.1 seal — Babylon
spatial-merge activation; Cop renamed to Babylon).

`git status` shows pre-existing housekeeping deferral state:
- `modified: build/BOOTX64.EFI`, `modified: build/codebook.img` — DEFERRED #10
- 15 untracked `tools/pod*_*.sh` scripts (3 each for 1.10.2a, 1.10.2b1,
  1.10.2b2, 1.10.3, 2.1) — DEFERRED #67/#70/#74

No surprises. Substrate at expected entry state.

---

## R2 — Verb canonicality + field rename audit

### R2.a — Verb canonicality (A1 surface)

Grepped boot/ for `\b(forge|FORGE|create|CREATE)\b`: **no matches**.
Boot identifier-space uses neither verb in opcode constants or handler
labels.

Tree-canonical identifier verb: **NEW** (opcode suffix). Examples:
- Constants: `OP_SIGN_NEW` (0xA0), `OP_ENERGY_NEW` (0xD0),
  `OP_OUTCOME_NEW_OK` (0xE0), `OP_OUTCOME_NEW_ERR` (0xE1),
  `OP_CAP_NEW` (0xB0)
- Handler labels: `.op_sign_new`, `.op_energy_new`,
  `.op_outcome_new_ok`, `.op_outcome_new_err`, `.op_cap_new`

Tree-canonical narrative verb: **forge**. Grep of `tools/atreyu_x86.py`
for `forge` (case-insensitive) found 9+ matches in docstrings:
- "forge cap A under ROOT" (line 888)
- "Forge cap A under ROOT, ENTER A, forge Sign S inside A" (line 914)
- "Forge Sign x3 under B" (line 1188)
- "Forge Energy x2 under A" (line 1194)
- "Sub-cap canary. Sign forge under sub-cap A." (line 1208)
- (and similar)

**No existing `BIT_*_FORGE`, `BIT_*_NEW`, or `BIT_*_CREATE` constants
exist** — this is fresh territory.

**TB recommendation A1: ratify architect prior `BIT_SIGN_FORGE /
BIT_ENERGY_FORGE / BIT_OUTCOME_FORGE / BIT_CAP_FORGE`.** Identifier-space
verb (NEW) is the opcode-dispatch convention; narrative verb (forge) is
the conceptual operation. Bit constants name the conceptual authority,
not the dispatch path. The bit IS the authority to forge — naming as
forge reads naturally as a noun-phrase ("SIGN_FORGE authority"); naming
as NEW reads awkwardly ("SIGN_NEW authority"). Matches established
narrative convention from Pod 1.7+ etymology.

### R2.b — Field rename audit

References to `CAP_OFF_RESOURCE_DESC`, `resource_descriptor`, and
`OP_CAP_RESOURCE` enumerated below.

**`CAP_OFF_RESOURCE_DESC` (5 in-tree code references):**
```
boot/defines.asm:169     %define CAP_OFF_RESOURCE_DESC      0x18
boot/cap.asm:320         mov     qword [rdi + CAP_OFF_RESOURCE_DESC],      0   ; construct_root_cap
boot/cbs_vm.asm:1431     mov     [rbx + CAP_OFF_RESOURCE_DESC], r10            ; .op_cap_new
boot/cbs_vm.asm:1653     mov     rcx, CAP_OFF_RESOURCE_DESC                    ; .op_cap_resource
```
Plus historical references in `recon/POD1.10.2*` and `recon/POD1.10.3*`
docs (informational; canon docs evolve forward, recon reports preserved
as point-in-time).

**`resource_descriptor` (in-tree code/comment references):**
- `boot/cap.asm:307` — comment in `construct_root_cap` header
- `boot/cbs_vm.asm:1400, 1412` — comments in `.op_cap_new`
- `boot/defines.asm:150` — comment on `OP_CAP_RESOURCE` constant
- `RECONSTITUTION.md:306, 317` — canon doc references (will update at
  v11)
- `binary_contracts.md:36` — provenance text (will update at C1)
- `tools/atreyu_x86.py:341, 347, 736, 746, 751, 770, 824, 893, 923,
  1022, 1037, 1087, 1105, 1127, 1130, 1133, 1183, 1186, 1218` — emitter
  + 14 demo emissions (rebuild ripple per A2)
- `DEFERRED.md:803, 979` — items referencing it

**`OP_CAP_RESOURCE` (in-tree code references):**
```
boot/defines.asm:150         %define OP_CAP_RESOURCE  0xB6
boot/cbs_vm.asm:178          cmp     al, OP_CAP_RESOURCE       ; dispatch
boot/cbs_vm.asm:1649-1654    .op_cap_resource handler header + source_op tag
boot/energy_costs.asm:122    dq 1                              ; 0xB6 cost row
tools/atreyu_x86.py:70       OP_CAP_RESOURCE  = 0xB6
tools/atreyu_x86.py:367      e.emit(OP_CAP_RESOURCE)           ; AST emitter
```

Per-file edit summary for the rename:
- `boot/defines.asm`: 1 line for CAP_OFF_RESOURCE_DESC, 1 line for
  OP_CAP_RESOURCE (+ comment updates)
- `boot/cap.asm`: 2 lines (1 code, 1 comment)
- `boot/cbs_vm.asm`: 4 code locations + 2 comments + dispatch table entry
- `boot/energy_costs.asm`: 1 line (cost table comment)
- `tools/atreyu_x86.py`: ~20 lines (constant + emitter + 14 demo
  emissions)

No accidental shadowing observed. The rename propagates via `%define`
constant rebinding — `CAP_OFF_RESOURCE_DESC` → `CAP_OFF_BITMAP` —
plus a renamed accessor opcode constant.

---

## R3 — OP_CAP_NEW signature amendment plan

Read `.op_cap_new` verbatim at `boot/cbs_vm.asm:1408-1487`.

**Current Pod 1.10.3 shape:**
```
.op_cap_new:
    sub     r13, 8
    mov     r9, [r13]                       ; energy_budget (top of stack; Pod 1.10.3)
    sub     r13, 8
    mov     r10, [r13]                      ; resource_descriptor
    [pool capacity check, slot writes, MAC stamp, spatial-merge,
     Outcome::Ok wrap]
.op_cap_new_pool_full:
    [.construct_err_outcome path with ERR_POOL_FULL]
```

**Pod 2.2 amendment**: semantic-only reinterpretation. Pop order
unchanged; bytecode shape unchanged. The variable formerly known as
`resource_descriptor` (popped into r10) becomes `granted_bitmap`. Bit-
check and subset-on-grant insertions go between operand pop and pool
capacity check.

**Bytecode shape: zero ripple at OP_CAP_NEW callers.** Pod 1.10.3 amended
the signature shape (1-arg → 2-arg, +9 bytes per call site). Pod 2.2
preserves the shape; only the semantic meaning of the second arg
changes. Pod 1.10.3 demos that pushed `42` for resource_descriptor now
push meaningful bitmap values (typically `CAP_BITMAP_UNBOUNDED` for
tests not exercising bit semantics, specific bit values for tests that
do). This is a baseline-reset semantic shift in the D1.10.3.7 family.

---

## R4 — Subset-on-grant logic + register preservation

Architect-supplied logic at prompt R4 reviewed against actual
`.op_cap_new` shape. **Register preservation needs minor adjustment**:

The architect's R4 plan pushes `r9, r10` across both `.babylon_check_authority`
and the second `registry_lookup_cap` call, then restores. This is
correct — `r9` (energy_budget) and `r10` (granted_bitmap) must survive
to slot writes at lines ~1438 and ~1431.

**However:** the architect's R4 helper template does this:
```
push    r9
push    r10
mov     rdi, BIT_CAP_FORGE
mov     rsi, [rel current_cap_id]
call    .babylon_check_authority
test    rax, rax
pop     r10
pop     r9
jnz     .cap_new_insufficient_authority
```

Issue: `test rax, rax / jnz` against the helper return value happens
*after* the pops. Standard pattern: `pop rax-trash` would clobber the
test result. The architect's pattern works because rax is preserved by
the pops (pops only touch r10/r9). Register-preservation correctness
verified against actual `babylon_charge_lineage` clobber set
(rax, rcx, rdx, rsi, rdi clobbered; r12-r15, rbx, rbp preserved). The
proposed `babylon_check_authority` should follow the same convention.

**Subset check** (second stage) inputs: `parent_bitmap` from
`current_cap_id`'s slot at `+CAP_OFF_BITMAP`; `granted_bitmap` from r10
operand. AND/CMP gives subset comparison. Defensive failure path for
unresolvable `current_cap_id` (should-not-fire defense) routes to
`ERR_INVALID_ID` per the architect's R4 plan — this matches existing
`.op_cap_enter_invalid` pattern.

**Three failure routes confirmed correct:**
- `.cap_new_insufficient_authority` — ERR_CAP_INSUFFICIENT_AUTHORITY
- `.cap_new_authority_exceeded` — ERR_CAP_AUTHORITY_EXCEEDED
- `.cap_new_subset_lookup_fail` — ERR_INVALID_ID (defensive)

All three route through `.construct_err_outcome` with `source_op =
OP_CAP_NEW`, which fires `babylon_charge_lineage` once per Pod 2.1
spatial-merge convention.

---

## R5 — Bit-check insertion at four primitive-forge sites

Read each handler verbatim:
- `.op_sign_new` at boot/cbs_vm.asm:848-938
- `.op_energy_new` at boot/cbs_vm.asm:1035-1088
- `.op_outcome_new_ok` at boot/cbs_vm.asm:1188-1233
- `.op_outcome_new_err` at boot/cbs_vm.asm:1241-1310

**Per-site insertion table:**

| Handler | Line | Required bit | source_op | Pop state at insertion |
|---|---|---|---|---|
| .op_sign_new | after 864 (post-pop, before label-len check at 866) | BIT_SIGN_FORGE | OP_SIGN_NEW | r8, r9, r10, r11, rbx hold popped args |
| .op_energy_new | after 1040 (post-pop, before alloc at 1042) | BIT_ENERGY_FORGE | OP_ENERGY_NEW | rbx (source_op), rcx (joules) hold popped args |
| .op_outcome_new_ok | after 1192 (post-pop, before alloc at 1193) | BIT_OUTCOME_FORGE | OP_OUTCOME_NEW_OK | r10 (value), r11 (value_type_id) hold popped args |
| .op_outcome_new_err | after 1251 (post-pop, before alloc at 1252) | BIT_OUTCOME_FORGE | OP_OUTCOME_NEW_ERR | r8, r9, r10, r11, rcx hold popped args |

**Register preservation requirement per site:** push the in-flight
operand registers (per the table) across `babylon_check_authority` call,
restore after; route to `<handler>_insufficient_authority` failure label
on non-zero rax. Failure label calls `.construct_err_outcome` with
appropriate source_op + ERR_CAP_INSUFFICIENT_AUTHORITY.

**Architectural note re: .op_outcome_new_ok / .op_outcome_new_err:**
these handlers currently do NOT use `.construct_err_outcome` on
pool-full failure (they push 0 sentinel directly at lines 1231 and 1308).
This is by design — they construct Outcome slots directly via
`.outcome_alloc` rather than via the helpers. Bit-check failure on these
handlers WILL route through `.construct_err_outcome` per the prompt,
producing a proper Outcome::Err. Architectural asymmetry (pool-full →
sentinel-0; bit-check → Outcome::Err) is intentional but worth noting
as a small consistency surface for future consolidation
(DEFERRED #66 territory).

**0j cost classification confirmed at architect Pre-A14:** post-pop /
pre-construct substrate work; not visible to operand-stack cost
accounting. Sixth empirical confirmation of substrate-bookkeeping
doctrine (D1.9.2b.1 → D1.10.2a.7 → D1.10.2b2.3 → D1.10.3 → D2.1.6)
contingent on B2/B3 canary verification.

---

## R6 — Path A retrofit + .construct_ok_outcome signature

### R6.a — Helper signature

Read `.construct_ok_outcome` verbatim at boot/cbs_vm.asm:1952-2000.

```
;   Input:    rdi = value, r8 = value_type_id
;   Output:   rax = outcome_id (>=1 on success, 0 if Outcome pool full)
;   Clobbers: rax, rbx, rcx, rdx, rsi, rdi
;   Preserves: r12, r13, r14, r15, rbp, r8, r9, r10, r11
```

**Caller pattern** (extracted from existing six consumers — sign_energy,
energy_joules, energy_source_op, .cap_accessor_common, op_cap_enter,
op_cap_exit, op_cap_new):
```
mov     rdi, <value>            ; e.g., sign_id
mov     r8, TYPE_CODE_SIGN      ; or TYPE_CODE_ENERGY/OUTCOME/CAP/NONE
call    .construct_ok_outcome
mov     [r13], rax              ; caller pushes outcome_id
add     r13, 8
jmp     .fetch
```

**Architect's R6 prompt template incomplete on two points:**
1. Missing `mov r8, TYPE_CODE_*` — caller must set r8 with the type
   code (TYPE_CODE_SIGN = 0/1, TYPE_CODE_ENERGY, TYPE_CODE_CAP = 3, etc.)
2. Missing operand-stack push — `.construct_ok_outcome` returns rax;
   caller must `mov [r13], rax; add r13, 8` before `jmp .fetch`.

These are minor mechanical corrections at HALT 2A; substantive
architecture unchanged.

### R6.b — DOUBLE-FIRE LOAD-BEARING CONCERN

**Critical finding flagged for architect.**

`.construct_ok_outcome` ALREADY fires `babylon_charge_lineage` internally
at lines 1991-1995 (Pod 2.1 spatial-merge insertion site #6 +
.construct_err_outcome's matching insertion at 2056-2061 = site #7).

Current `.op_sign_new` SUCCESS PATH (Pod 2.1):
```
[lines 906-911]
push    rax                                 ; preserve sign_id
mov     rdi, [rel current_dispatch_cost]
mov     rsi, [rel current_cap_id]
call    babylon_charge_lineage              ; fire #1 — handler explicit
pop     rax
[lines 912-914]
mov     [r13], rax                          ; bare sign_id push
add     r13, 8
jmp     .fetch
```

**Architect's proposed Pod 2.2 Path A retrofit pattern** (R6 prompt):
```
; Replaces: mov [r13], rax; add r13, 8; jmp .fetch
; With:
mov     rdi, rax
call    .construct_ok_outcome               ; fire #2 — internal to helper
jmp     .fetch
```

Naively applied (replacing only the bare push, leaving lines 906-911
untouched), this produces **DOUBLE-FIRE**: handler fires babylon at
100j (Sign cost), then `.construct_ok_outcome` fires babylon at 100j
again (current_dispatch_cost is still 100j). Under sub-cap context,
ROOT receives 50j+50j = 100j ripple per Sign forge instead of Pod 2.1's
50j.

**Sign 174j and Energy 53j sub-cap canaries from D2.1.6 will NOT hold
verbatim under naive retrofit.** Specifically:
- Sign 100j → Pod 2.1 single-fire ripple to ROOT = 50j; double-fire = 100j
- Energy 50j → Pod 2.1 single-fire ripple = 25j; double-fire = 50j

OP_OUTCOME_NEW_OK / OP_OUTCOME_NEW_ERR (1j) and OP_CAP_NEW (1j) are
unaffected — 1/2 = 0 floor → no actual ripple → double-fire neutralized.
OP_CAP_NEW already runs the double-fire pattern in Pod 2.1; the
architect's comment at lines 1461-1463 explicitly notes this and relies
on floor-divide neutralization.

**TB recommendation:** Path A retrofit must REMOVE the handler-explicit
babylon calls in `.op_sign_new` (lines 906-911) and `.op_energy_new`
(lines 1067-1072). Let `.construct_ok_outcome`'s internal babylon fire
be the single spatial-merge site for Sign / Energy success. This:
- Preserves Sign 174j and Energy 53j sub-cap canaries (single ripple)
- Maintains the substrate axiom: "every successful primitive
  construction fires babylon" (just relocated to the
  construct-ok-outcome boundary)
- Aligns with the architectural framing: in the post-retrofit world,
  Sign-wrapped-in-Outcome::Ok IS the result; one construction event,
  one fire
- Simplifies code by removing redundant explicit calls

**Alternative interpretation:** the architect intends Sign-then-Outcome
as two construction events, accepting the canary delta. In this case
Pre-A14 needs revision (canary values change; sixth empirical
confirmation modified to "modified canaries due to Path A retrofit
double-fire").

**This is the load-bearing surface for HALT 1 architect adjudication.**

---

## R7 — Affected test surface enumeration

Grepped `tools/atreyu_x86.py` for `'sign_new'` and `'energy_new'` AST
node literals.

**`'sign_new'` AST emissions: 12** (lines 469, 642, 843, 899, 927, 1109,
1137, 1162, 1190, 1191, 1192, 1222) across 10 demo functions.

**`'energy_new'` AST emissions: 5** (lines 667, 859, 1195, 1196, 1251)
across 4 demo functions.

**Affected demo functions (13 unique surfaces):**

| # | Demo function | Surface | Forges |
|---|---|---|---|
| 1 | demo_sign | sign_test.cbc | Sign |
| 2 | demo_sign_invalid_id | test_sign_invalid_id.cbc | Sign |
| 3 | demo_sign_provenance_root | test_sign_provenance_root.cbc | Sign |
| 4 | demo_provenance_under_subcap | test_provenance_under_subcap.cbc | Sign |
| 5 | demo_provenance_walk | test_provenance_walk.cbc | Sign |
| 6 | demo_babylon_single_level | test_babylon_single_level.cbc | Sign |
| 7 | demo_babylon_multi_level | test_babylon_multi_level.cbc | Sign |
| 8 | demo_babylon_root_only_invisible | test_babylon_root_only_invisible.cbc | Sign |
| 9 | demo_babylon_federation_total | test_babylon_federation_total.cbc | Sign×3 + Energy×2 |
| 10 | demo_babylon_canary_subcap | test_babylon_canary_subcap.cbc | Sign |
| 11 | demo_energy | test_energy.cbc | Energy |
| 12 | demo_energy_invalid_id | test_energy_invalid_id.cbc | Energy |
| 13 | demo_energy_provenance_root | test_energy_provenance_root.cbc | Energy |

**13 surfaces total.** Architect estimate ~10. Within architect-stated
range "10-25 plausibly more." Surface as A3 finding per
D1.10.2b2.9 / D1.10.3.8 / D2.1.9 doctrine — actual count = architect
estimate + 30%. Doctrine empirically symmetric: under and over-counts
both happen, recon catches both.

**Plus 14 OP_CAP_NEW demo emissions** (per the resource_descriptor grep
in R2.b) — these need rebuild for the semantic reinterpretation
(push meaningful bitmap value instead of placeholder `42`/`99`/`77`).
Bytecode shape unchanged for OP_CAP_NEW; just AST emitter constant
update. Combined with the 13 Path A retrofit surfaces (some overlap —
e.g., demo_provenance_walk forges Sign AND constructs cap), the total
rebuilt surface count is approximately **20–22 surfaces**. TB enumerates
exact list at HALT 2A diff stats.

---

## R8 — Build chain confirmation

**Tool versions** (WSL Ubuntu):
```
NASM version 2.16.01                                ✓ matches
mcopy (GNU mtools) 4.0.43                           ✓ matches
QEMU emulator version 8.2.2 (Debian 1:8.2.2+ds-0ubuntu1.16)  ✓ matches
```

**Two-build determinism on Pod 2.1 entry contract:**
```
build1 sha256: 8a8236f6f6d0e3473904096a166903c992a7f12187fe5b7fad6d28548499ba1f  build/BOOTX64.EFI
build2 sha256: 8a8236f6f6d0e3473904096a166903c992a7f12187fe5b7fad6d28548499ba1f  build/BOOTX64.EFI
```

Both builds produced byte-identical 1,049,600-byte BOOTX64.EFI. SHA256
matches Pod 2.1 entry contract `8a8236f6f6d0e3473904096a166903c992a7f12187fe5b7fad6d28548499ba1f`
exactly. Build chain verified deterministic. Pod 2.2 changes can begin
from a known-clean substrate state.

(Side note: `tools/precompile_all.sh` emits CRLF-line-ending warnings
under WSL bash. Build script handles gracefully via `[warn] precompile
returned non-zero; using existing .cbc` fallback. Pre-existing
housekeeping issue, not a Pod 2.2 concern. nasm assembly + image build
proceed normally.)

---

## A-call surfaces

### A1 — Tree-canonical primitive-construction verb

**Architect proposal:** `BIT_SIGN_FORGE / BIT_ENERGY_FORGE /
BIT_OUTCOME_FORGE / BIT_CAP_FORGE`.

**Tree finding:** identifier-space verb is `NEW` (opcode suffix);
narrative-space verb is `forge` (docstring convention from Pod 1.7+).
No existing BIT_*_* constants — fresh territory.

**TB recommendation: ratify architect prior `BIT_*_FORGE`.** The bit
constants name conceptual authority (forge), not opcode dispatch path
(NEW). Reads naturally as authority noun-phrase ("SIGN_FORGE
authority"); aligns with established narrative convention.

### A2 — OP_CAP_RESOURCE legacy alias vs full retirement

**Architect option:** keep OP_CAP_RESOURCE as legacy alias for
OP_CAP_BITMAP (two opcode constants → one handler) OR retire entirely
and rebuild test_cap_arena_owner_resource.cbc.

**TB recommendation: full retirement per D1.10.3.7 baseline-reset
doctrine.** Retire `OP_CAP_RESOURCE` constant; rebuild
test_cap_arena_owner_resource.cbc as test_cap_arena_owner_bitmap.cbc
under the new accessor name. Pod 1.10.3 retired the old MAC offset
without alias; this is the established pattern. Aliases accumulate
maintenance debt without buying anything that a clean baseline doesn't
provide.

### A3 — Path A retrofit affected count

**Architect estimate:** ~10 surfaces.
**TB recon enumeration:** **13 surfaces** (Sign-forging or
Energy-forging demos; counted in R7 above).

Plus 14 OP_CAP_NEW emissions need bitmap-value updates (semantic
reinterpretation, no bytecode shape change). Combined rebuilt-surface
count approximately 20–22 (with overlap). Within architect-stated range
"10–25 plausibly more."

Surface as A3 finding. Architect count empirically symmetric — recon
catches both under and over-counts. Sixth empirical confirmation of the
"architect count claims unreliable in either direction" doctrine
(D1.10.2b2.9 / D1.10.3.8 / D2.1.9).

### A4 — Error code numeric values

**Finding:** `ERR_CAP_AUTHORITY_EXCEEDED` already exists in
`boot/defines.asm:136` at value **7**, marked "Pod 1.10.2a; D1.10.1.9;
defined-but-unused V1.0 per D1.10.2b1.2." This is the four-pod forward-
anchor that DEFERRED #61 has been tracking. Pod 2.2 doesn't define this
code — it activates it.

**`ERR_CAP_INSUFFICIENT_AUTHORITY`** does not exist; needs new
allocation. Next-available numeric: **8**.

Existing error code allocations:
```
ERR_INVALID_ID                = 1
ERR_POOL_FULL                 = 2
ERR_STACK_UNDERFLOW           = 3
ERR_STACK_OVERFLOW            = 4
ERR_INVALID_SIGN_ARG          = 5
ERR_INVALID_ENERGY_ARG        = 6
ERR_CAP_AUTHORITY_EXCEEDED    = 7   (forward-anchored; Pod 2.2 activates)
ERR_CAP_INSUFFICIENT_AUTHORITY = 8  (Pod 2.2 — proposed)
```

**TB recommendation A4:** `ERR_CAP_INSUFFICIENT_AUTHORITY = 8`. Update
the existing comment on `ERR_CAP_AUTHORITY_EXCEEDED` from "defined-but-
unused V1.0 per D1.10.2b1.2" to "Pod 2.2 — subset-on-grant violation
at OP_CAP_NEW per D2.2.5".

### A5 — .construct_ok_outcome signature shape

**Finding:** Helper at `boot/cbs_vm.asm:1952` accepts `rdi = value, r8
= value_type_id`. Returns `rax = outcome_id`. Caller is responsible for
operand-stack push (`mov [r13], rax; add r13, 8`).

**Architect's R6 retrofit template needs two corrections** (per R6.a
above):
1. Add `mov r8, TYPE_CODE_<TYPE>` before the helper call (TYPE_CODE_SIGN
   for OP_SIGN_NEW retrofit, TYPE_CODE_ENERGY for OP_ENERGY_NEW)
2. Add `mov [r13], rax; add r13, 8` after the helper call to push the
   outcome_id

**TB recommendation A5:** corrected retrofit pattern is:
```
; Replaces handler success-path bare typed_id push
; (Sign: lines 912-914; Energy: lines 1073-1075)
; AND removes handler-explicit babylon call (Sign: 906-911;
; Energy: 1067-1072) per R6.b double-fire resolution
mov     rdi, rax                            ; typed_id from registry
mov     r8, TYPE_CODE_SIGN                  ; or TYPE_CODE_ENERGY
call    .construct_ok_outcome               ; single babylon fire here
mov     [r13], rax                          ; push outcome_id
add     r13, 8
jmp     .fetch
```

---

## Surprises

### Surprise 1 (load-bearing) — DOUBLE-FIRE babylon ripple under naive Path A retrofit

Documented in R6.b above. Under naive Path A retrofit (just replacing
bare push with `.construct_ok_outcome` call without removing handler-
explicit babylon), Sign forge under sub-cap charges parent 100j (vs Pod
2.1's 50j) and Energy forge charges 50j (vs 25j). Pre-A14 canary
preservation claim does not survive this naive form.

**Architect adjudication needed at AUTHORIZED-1.** TB recommendation:
remove handler-explicit babylon calls; let `.construct_ok_outcome` be
the single fire site for Sign / Energy success. Maintains "every
successful primitive construction fires babylon" axiom; preserves
canaries; simpler code.

### Surprise 2 — Babylon helper label convention

`babylon_charge_lineage` is a **top-level label** at boot/babylon.asm:63,
not a dot-prefixed local label. Architect's prompt uses
`.babylon_check_authority` (with dot-prefix) throughout the helper
sketch.

**TB recommendation:** match in-tree convention. New helper is
`babylon_check_authority` (top-level), not `.babylon_check_authority`.
Boot/babylon.asm imports as `extern babylon_charge_lineage` and
`extern babylon_check_authority` from cbs_vm.asm callers.

Also: `babylon_charge_lineage` clobbers rax, rcx, rdx, rsi, rdi
(preserves r12-r15, rbx, rbp). Architect's proposed helper claims to
preserve rdi, rsi via push/pop bracket — that's fine (the helper
internals push them) but the documented contract should reflect the
established pattern: clobber rax, rcx (and rdx if the helper were to
call into siphash); preserve r12-r15, rbx, rbp (and rdi, rsi if the
helper itself preserves them via push/pop).

### Surprise 3 — ERR_CAP_AUTHORITY_EXCEEDED forward-anchor

Already documented under A4. The error code is sitting in
defines.asm:136 since Pod 1.10.2a, value 7, marked unused. Pod 2.2 just
activates it via subset-on-grant logic. Forward-log discipline
empirically pays out — DEFERRED #61's mechanical implementation requires
zero new constant allocation.

### Surprise 4 — energy_costs.asm 0xBA cost row already reserved

Cost table at `boot/energy_costs.asm:126` reads `dq 1, 1` for 0xBA-0xBB,
both marked "reserved". No row replacement needed; just split the line
to give 0xBA its own labeled row matching Pod 1.10.3 pattern (lines
124-125 for 0xB8/0xB9). This was forward-allocated; Pod 2.2 just claims
the slot. 1j metabolic per architect Pre-A12 / Pre-A14.

---

## HALT 1 conclusion

Recon-only phase complete. No source files modified; no commits staged.
The three load-bearing items needing architect adjudication at
AUTHORIZED-1:

1. **R6.b DOUBLE-FIRE concern** (Sign / Energy canary preservation
   under Path A retrofit) — TB recommends removing handler-explicit
   babylon calls; substrate maintains "primitive construction fires
   babylon" axiom via `.construct_ok_outcome`'s internal call.

2. **A1 verb naming** — TB recommends ratifying `BIT_*_FORGE`.

3. **A2 OP_CAP_RESOURCE retirement** — TB recommends full retirement
   per D1.10.3.7 precedent.

Plus mechanical adjustments at A3 (count = 13, not ~10), A4
(ERR_CAP_INSUFFICIENT_AUTHORITY = 8), A5 (helper signature corrections),
and Surprise 2 (top-level label convention for `babylon_check_authority`).

Substrate state at HALT 1: f3f0f06 sealed; build chain deterministic;
Pod 2.1 entry contract verified; ERR_CAP_AUTHORITY_EXCEEDED already
forward-anchored at value 7 awaiting activation; cost-table 0xBA slot
already reserved awaiting OP_CAP_BITMAP claim.

Awaiting AUTHORIZED-1 to begin Phase 2A.
