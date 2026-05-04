# Pod 1.9.2a Recon Report — Outcome substrate plumbing

**Pod:** 1.9.2a — first source pod of Section 2 (Outcome source implementation; substrate carriers only, no opcode handlers)
**Author:** Terminal Boy (Claude Opus 4.7)
**Date:** May 03 2026
**Entry contract:** 03d2642998f41c4ce2080267b41033a78bdafafb96aded360396338f30fe8199 (Pod 1.8.5c BOOTX64.EFI; preserved through 1.9.1)
**Entry HEAD:** e4c1e0083db43e9eae22364c4062548af8d85f51 (Pod 1.9.1 seal)
**Scope:** boot/defines.asm, boot/vmdata.asm, boot/cbs_vm.asm, boot/boot.asm, boot/outcome.asm (NEW), build chain, canon files.

---

## R1 — Pre-flight three-oracle

| Source | Hash | Match |
|--------|------|-------|
| `git rev-parse HEAD` | e4c1e0083db43e9eae22364c4062548af8d85f51 | ✓ |
| `git rev-parse origin/main` | e4c1e0083db43e9eae22364c4062548af8d85f51 | ✓ |
| `git ls-remote origin refs/heads/main` | e4c1e0083db43e9eae22364c4062548af8d85f51 | ✓ |

Three-oracle agrees. Build artifacts (DEFERRED #10) and three throwaway scripts (DEFERRED #33-#34) untracked per protocol.

## R2 — vmdata.asm insertion-point audit

Current vmdata.asm structure (verbatim):

| Lines | Block |
|-------|-------|
| 12-18 | top: energy_budget, energy_used, vm_ret_*, vm_stack, vm_vars |
| 20-24 | Sign pool + bump-allocator |
| 26-29 | Energy pool + bump-allocator |
| 31-38 | Sign registry (count, next_id, table) |
| 40-45 | Energy registry (count, next_id, table) |
| 47-49 | vm_phase (Pod 1.8.5c Move 7) |
| 51-60 | current_demod_* singleton state (Pod 1.8.5c Move 1+2) |
| 62-68 | prov_ring_head + prov_ring_buf (Pod 1.8.5c Move 2) |
| 70-72 | mmap_buf |

**Insertion plan:**

| New block | Insertion site | Rationale |
|-----------|---------------|-----------|
| `vm_outcome_pool` + `vm_outcome_next` | after line 29 (energy pool block), before line 31 (Sign registry) | Pool ordering matches Sign→Energy→Outcome |
| `outcome_registry_count` + `outcome_registry_next_id` + `outcome_registry` | after line 45 (Energy registry block), before line 47 (vm_phase) | Registry ordering parallel to pool ordering |
| `vm_fetch_count` | after line 14 (energy_used), before line 15 (vm_ret_ptr) | Substrate-wide counter shape; adjacent to existing substrate counter (energy_used) |

## R3 — Registry pattern (boot/registry.asm) — calling convention verbatim

```
;   Input:    rdi = arg (slot_ptr for register, id for lookup)
;   Output:   rax = result (id from register, slot_ptr from lookup;
;             0 means failure: full registry on register, not-found on lookup)
;   Clobbers: rax, rcx, rdx, rsi
;   Preserves: r12 (instruction pointer), r13 (operand stack),
;              r14 (energy budget), r15, rbx, rbp, rdi
```

`registry_register_sign` and `registry_lookup_sign` patterns are byte-identical to `_energy` versions modulo symbol substitutions. Outcome version mirrors exactly with `outcome_registry`, `outcome_registry_count`, `outcome_registry_next_id`, `OUTCOME_POOL_SLOTS` substitutions. Same calling convention; same null-return-on-not-found behavior; same linear scan; same ID-0 short-circuit in lookup.

**boot/outcome.asm shape recommendation (verbatim plan):**
- Header doc-comment block matching boot/registry.asm style
- `registry_register_outcome` mirroring `registry_register_sign`/`_energy` exactly
- `registry_lookup_outcome` mirroring `registry_lookup_sign`/`_energy` exactly
- Estimated 60-70 lines including comments

## R4 — vm_fetch_count substrate gap recon

`.fetch` loop head verbatim (boot/cbs_vm.asm:52-67):

```
.fetch:
    ; Fetch opcode byte
    movzx   eax, byte [r12]
    inc     r12
    ; Per-opcode energy cost (Pod 1.8: cost table replaces flat 1j/fetch)
    push    rax                     ; preserve opcode across call
    call    energy_cost_lookup      ; al = opcode byte → rax = joules
    mov     rbx, rax                ; rbx = cost
    pop     rax                     ; restore opcode byte
    ; Bankruptcy check: can we afford this opcode?
    cmp     r14, rbx
    jl      .fatigue
    ; Debit energy
    sub     r14, rbx
    add     [rel energy_used], rbx
```

**Insertion site (D1.9.1.7 spec: "after the opcode is fetched and before dispatch"):**

Between line 55 (`inc r12`) and line 56 (`; Per-opcode energy cost ...`):

```
.fetch:
    ; Fetch opcode byte
    movzx   eax, byte [r12]
    inc     r12
    ; Pod 1.9.2a D1.9.1.7 — substrate fetch counter for ProvEvent.
    inc     qword [rel vm_fetch_count]
    ; Per-opcode energy cost (Pod 1.8: cost table replaces flat 1j/fetch)
    push    rax                     ; preserve opcode across call
    ...
```

**Design questions resolved:**
- **Counter increments on OP_HALT and structural opcodes:** YES. Counter measures substrate activity (fetches), not metabolic work. HALT is a real fetch even though its cost is 0j. Same for OP_RESERVE, OP_PHASE_QUERY.
- **u64 wrap protection:** NOT NEEDED. At GHz fetch rates, 2^64 ≈ 5.85 × 10^11 seconds ≈ 18,000 years. Document the wrap behavior in the decision record but no source-level guard.
- **Counter increments on .fatigue path:** YES. The increment fires before the bankruptcy check, so a fetch that triggers .fatigue still counts. Semantically: "we read the opcode, but couldn't afford to execute it" — the read happened.

No A-call surfaced; insertion site is unambiguous.

## R5 — Constants placement audit (boot/defines.asm)

Current end of file:

```
; --- Energy struct layout (Pod 1.8) ---
%define ENERGY_OFF_JOULES    0x00
%define ENERGY_OFF_SOURCE_OP 0x08
%define ENERGY_SLOT_SIZE     0x80   ; 128 bytes
%define ENERGY_POOL_SLOTS    64

; --- Canonical ID types (Pod 1.8.5b — Move 4) ---
; All canonical IDs are u64. ID 0 is reserved as null/invalid.
; ...
%define SIGN_ID_NULL    0
%define ENERGY_ID_NULL  0
%define CAP_ID_NULL     0
%define DEMOD_ID_NULL   0
%define SIGNAL_ID_NULL  0
```

(End of file at line 156.)

**Insertion plan:**

| Addition | Insertion site | Notes |
|----------|---------------|-------|
| `OUTCOME_SLOT_SIZE 0x80` + `OUTCOME_POOL_SLOTS 64` | after line 142 (ENERGY_POOL_SLOTS); new section header | Parallel to Sign and Energy struct-layout blocks |
| `OUTCOME_ID_NULL equ 0` | after line 156 (SIGNAL_ID_NULL) | Joins the canonical-ID null-sentinel block |
| `TYPE_CODE_*` enum block | after the OUTCOME_ID_NULL line; new section header "Pod 1.9.2a — Outcome value_type_id codes (D1.9.1.1)" | Adjacent to ID-null block; same conceptual layer |

Verified: no existing `OUTCOME_*`, `TYPE_CODE_*` defines anywhere in defines.asm. Clean adds.

## R6 — boot.asm include site

Current include chain (verbatim):

```
%include "boot/cbs_vm.asm"     ; CBS bytecode VM
%include "boot/registry.asm"   ; Pod 1.8.5b: canonical-ID registry for Sign and Energy
%include "boot/provenance.asm" ; Pod 1.8.5c Move 2: ProvEvent struct + prov_append
%include "boot/bastian.asm"    ; home surface (bastian precedes gmork_main in original)
```

**Insertion site:** between line 388 (`provenance.asm`) and line 389 (`bastian.asm`). Substrate primitives (registry, provenance, outcome) before surfaces (bastian, gmork_cmds). Matches Pod 1.8.5b and Pod 1.8.5c precedents.

## R7 — Pool capacity constant naming

Recommended adds to defines.asm (per R5 plan):

```
; --- Outcome struct layout (Pod 1.9.2a) ---
%define OUTCOME_SLOT_SIZE    0x80   ; 128 bytes
%define OUTCOME_POOL_SLOTS   64
```

No naming conflicts. Mirrors Sign and Energy convention exactly.

## R8 — Build chain confirmation (WSL Ubuntu)

| Tool | Version | Status |
|------|---------|--------|
| nasm | 2.16.01 | ✓ |
| mtools | 4.0.43 | ✓ |
| qemu-system-x86_64 | 8.2.2 (Debian 1:8.2.2+ds-0ubuntu1.16) | ✓ |
| `./build.sh` × 2 | exit 0 both runs | ✓ |

**Determinism / entry contract:**
- Run 1 EFI sha256: `03d2642998f41c4ce2080267b41033a78bdafafb96aded360396338f30fe8199` ✓
- Run 2 EFI sha256: `03d2642998f41c4ce2080267b41033a78bdafafb96aded360396338f30fe8199` ✓
- ENTRY_DETERMINISM: MATCH ✓
- ENTRY_CONTRACT: MATCHES Pod 1.8.5c row in binary_contracts.md ✓

---

## Section 2 — Architect calls before AUTHORIZED-1

**No architect calls surfaced.** All R-items resolved with unambiguous answers per the prompt's specification and existing precedent (Pod 1.8.5b registry shape, Pod 1.8.5c vmdata layout, D1.9.1.7 fetch-counter spec). Phase 2A executes S1-S5 as written.

---

## Section 3 — Risks identified

- **R3.1 — vm_fetch_count is observable from any opcode handler.** D1.9.1.6 specifies OP_OUTCOME_NEW_ERR reads it for prov_append; future Pod 2 (Cop) may also read it for rate-limiting / fairness accounting. The counter is now substrate-wide state. No isolation between consumers in V1.0; Pod 2 (Cop) introduces per-binding counters if needed.
- **R3.2 — One extra `inc qword [rel ...]` per fetch is a measurable energy cost.** ~3-4 cycles per fetch. At GHz scale, 99% noise; not load-bearing. Matters only if the substrate ever needs sub-microsecond fetch budgets. Flag for awareness.
- **R3.3 — Outcome plumbing without handlers is a partial-state binary.** A user calling OP_OUTCOME_NEW_OK in 1.9.2a would hit "Unknown opcode" (the opcode is undefined, not just unhandled). Tests must avoid Outcome opcodes until 1.9.2b lands handlers. Flag explicitly.
- **R3.4 — TYPE_CODE_OUTCOME = 6 conflict potential.** If Pod 1.10 (Cap) introduces a primitive code numbering different from the type-code numbering, drift could happen. The type codes are independent of the canonical-ID null sentinels (which are all 0); only their type-code-discriminant role matters. Document the convention in D1.9.2a.

---

## Section 4 — Phase 2 execution gates (post-AUTHORIZED-1)

S1: defines.asm — OUTCOME_SLOT_SIZE/OUTCOME_POOL_SLOTS new section + OUTCOME_ID_NULL + TYPE_CODE_* enum block
S2: vmdata.asm — vm_fetch_count after energy_used; vm_outcome_pool/next after energy_pool block; outcome_registry block after energy_registry block
S3: boot/outcome.asm NEW — registry register/lookup mirroring boot/registry.asm
S4: boot.asm — include line between provenance.asm and bastian.asm
S5: cbs_vm.asm — inc qword [rel vm_fetch_count] between line 55 (inc r12) and line 56 (energy cost lookup comment)

Phase 2B B1 reads BOOTX64.EFI for two-build determinism. B2/B3 verify Sign and Energy regression invisibility — output must match Pod 1.8.5c reference byte-for-byte.

---

## Section 5 — Surprises

- **S5.1 — D1.9.1.7 spec aligns perfectly with the natural .fetch loop site.** The "after fetch, before dispatch" wording maps to a single insertion line between `inc r12` and the energy-cost-lookup push. No design slack to ratify.
- **S5.2 — outcome_registry sizing is mechanical.** Pool capacity 64 → registry table 64×16=1024 bytes. Identical to Sign and Energy registries from Pod 1.8.5b. Pod 1.8.5b's "1:1 capacity" decision applies (D1.8.5b.3).
- **S5.3 — boot/outcome.asm body is byte-identical to boot/registry.asm with substitutions.** No new algorithmic content. The substrate is now mature enough that adding a typed primitive is mostly a copy-paste-and-rename of the established pattern. Worth recording as substrate-maturity evidence.

---

## Section 6 — HALT 1 status

- All R-items completed.
- No source files modified.
- No commits staged.
- 0 architect calls.
- 4 risks surfaced (none blocking).
- 3 surprises surfaced.

**HALT 1 — awaiting AUTHORIZED.**

— Terminal Boy
May 03 2026
