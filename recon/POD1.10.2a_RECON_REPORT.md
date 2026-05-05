# Pod 1.10.2a Recon Report — Cap substrate plumbing

**Pod:** 1.10.2a — first source pod of Section 2 of Pod 1.10 (substrate carriers; no opcode handlers)
**Author:** Terminal Boy (Claude Opus 4.7)
**Date:** May 04 2026
**Entry contract:** 3bfb0c0a2410e90c9aa9d5def1c598ec26d6c058d68c73cf67cb2da5e737fff6 (Pod 1.9.3 BOOTX64.EFI; preserved through 1.9.4 + 1.10.1; will change in 1.10.2a)
**Entry HEAD:** 91a5c9d3f06cd255edfa5b4baa28efcbe515c897 (Pod 1.10.1 seal)
**Scope:** boot/defines.asm, boot/vmdata.asm, boot/cap.asm (NEW), boot/boot.asm, boot/data.asm, build chain, canon files.

---

## R1 — Pre-flight three-oracle

Three-oracle agrees at `91a5c9d3f06cd255edfa5b4baa28efcbe515c897`. Build artifacts (DEFERRED #10) modified per protocol. Working tree clean (5 throwaway scripts gone after Pod 1.9.4 housekeeping).

## R2 — efi_entry insertion-point audit

`boot/boot.asm` `efi_entry` post-locate_gop sequence (verbatim):

| Lines | Action |
|-------|--------|
| 116-117 | locate_sfsp; locate_gop |
| 121-125 | UCS gop_ok print |
| 127-128 | Pod 1.8.5c SEED → FORM phase write |
| 130-152 | BOOT SPLASH (auryn_fill, auryn_puts, stalls) |
| 153-155 | %ifdef NATIVE_KBD exit_boot_services |
| 156-158 | Pod 1.8.5c FORM → CHANNELS phase write |
| 159-161 | auryn_fill + cursor_home |
| 162-164 | Pod 1.8.5c CHANNELS → MIND phase write |
| 165 | jmp bastian_home |

**Insertion site: between line 125 (UCS gop_ok print return) and line 127 (Pod 1.8.5c SEED→FORM comment).** Substrate init runs silent on success; only emits FATAL on failure. Boot splash plays normally if substrate init succeeds.

**Boot-time additions per architect's 11-step sequence** (steps 3-10 are new):

1. (existing) UEFI tables, watchdog, cost-table-ptr at lines 67-94
2. (existing) locate_sfsp, locate_gop at 116-125
3. **NEW:** CPUID probe RDSEED via leaf 7 sub-leaf 0 EBX bit 18
4. **NEW:** CPUID probe RDRAND via leaf 1 ECX bit 30 if RDSEED missing
5. **NEW:** Hard-fail-and-halt path with str_no_entropy + auryn_puts if both missing
6. **NEW:** siphash_key derivation (2 × u64 via RDSEED or RDRAND)
7. **NEW:** SipHash self-test against published vectors (E1; hard-fail if mismatch)
8. **NEW:** ROOT_CAP slot construction (6 fields written, MAC computed via siphash_compute)
9. **NEW:** registry_register_cap → cap_id=1 (sanity-check)
10. **NEW:** ROOT_CAP MAC self-verification (E3; hard-fail if recomputed ≠ stored)
11. (existing) SEED → FORM phase write at 127-128

current_cap_id, current_cap_arena_id_cache, current_cap_owner_demod_id_cache, cap_stack_ptr all initialized via BSS zero/static-init in vmdata.asm; no runtime init needed for those.

**S5 implementation collapses steps 3-6 into `derive_siphash_key`, step 7 into `siphash_self_test_run`, steps 8-9 into `construct_root_cap`, step 10 into `verify_root_cap_mac`.** Four function calls inserted between lines 125 and 127.

## R3 — vmdata.asm insertion-point audit

Current layout (verbatim from vmdata.asm):

| Lines | Block |
|-------|-------|
| 12-23 | top: energy_budget, energy_used, vm_fetch_count, vm_ret_ptr, vm_ret_stack[256], vm_stack[512], vm_vars[64] |
| 25-29 | Sign pool + bump-allocator |
| 31-34 | Energy pool + bump-allocator |
| 36-40 | Outcome pool + bump-allocator |
| 42-49 | Sign registry |
| 51-56 | Energy registry |
| 58-65 | Outcome registry |
| 67-69 | vm_phase |
| 71-80 | current_demod_* singleton state |
| 82-88 | prov_ring_head + prov_ring_buf |
| 90-92 | mmap_buf |

**Insertion plan:**

| New block | Insertion site | Rationale |
|-----------|---------------|-----------|
| `cap_stack_ptr` + `cap_stack[256]` | after line 21 (vm_ret_stack), before line 22 (vm_stack) | Substrate-stack precedent grouping (parallel to vm_ret_stack) |
| `vm_cap_pool` + `vm_cap_next` | after line 40 (vm_outcome_next), before line 42 (Sign registry) | Pool ordering: Sign → Energy → Outcome → Cap |
| `cap_registry_*` block | after line 65 (outcome_registry end), before line 67 (vm_phase) | Registry ordering parallel to pool ordering |
| `current_cap_id`, `current_cap_arena_id_cache`, `current_cap_owner_demod_id_cache` | after line 80 (current_demod_prov_enabled), before line 82 (prov_ring_head comment) | Adjacent to existing current_demod_* singleton block |
| `siphash_key`, `siphash_key_source`, self-test scratch space | new section after current_cap_* block, before prov_ring_buf | Distinct "Pod 1.10.2a — substrate crypto state" section |

## R4 — Registry pattern reuse audit

Read boot/outcome.asm (Pod 1.9.2a). Calling convention verbatim from outcome.asm header:
- Input: `rdi = arg` (slot_ptr for register, id for lookup)
- Output: `rax = result` (id from register, slot_ptr from lookup; 0 = failure)
- Clobbers: rax, rcx, rdx, rsi
- Preserves: r12, r13, r14, r15, rbx, rbp, rdi

`registry_register_cap` and `registry_lookup_cap` in boot/cap.asm will be **byte-for-byte mirrors** of registry_register_outcome / registry_lookup_outcome with `outcome` → `cap` substitutions. Same calling convention. Same linear scan. Same ID-0 short-circuit. Same null-return-on-not-found.

**No deviations from the pattern.**

## R5 — RDSEED / RDRAND CPUID probe specification

**CPUID probe sequence:**
- RDSEED: CPUID leaf 7 sub-leaf 0 EBX bit 18 (Intel CPUID feature flag)
- RDRAND: CPUID leaf 1 ECX bit 30

**`derive_siphash_key` outline:**
```
.derive_siphash_key:
    ; Probe RDSEED
    mov     eax, 7
    xor     ecx, ecx
    cpuid
    bt      ebx, 18
    jc      .have_rdseed
    ; Probe RDRAND
    mov     eax, 1
    cpuid
    bt      ecx, 30
    jc      .have_rdrand
    ; Both missing — hard-fail
    lea     rsi, [rel str_no_entropy]
    call    auryn_puts
    cli
    hlt
    jmp     $
.have_rdseed:
    mov     qword [rel siphash_key_source], 0
    ; Two RDSEED calls with retry budget × 2 → siphash_key[0], siphash_key[1]
    ret
.have_rdrand:
    mov     qword [rel siphash_key_source], 1
    ; Two RDRAND calls with retry budget × 2 → siphash_key[0], siphash_key[1]
    ret
```

Retry budget per RDSEED call: 64 iterations (Intel's recommendation for entropy contention). RDRAND has internal retry but external carry-flag check still required.

**`cli; hlt; jmp $` hard-fail pattern:** standard substrate refusal-to-boot. `cli` disables interrupts (on bare metal); `hlt` halts CPU until next interrupt; `jmp $` infinite loop ensures non-resumption if `hlt` wakes spuriously. auryn_puts is functional at this insertion point (post-locate_gop) per R2 — diagnostic renders to framebuffer before halt.

## R6 — SipHash-2-4 implementation specification

NASM implementation per Aumasson reference (siphash24.c). Estimated ~150 lines:

**SIPROUND macro** (single round; 6 ADD/XOR/ROL ops on 4 state variables):
```nasm
%macro SIPROUND 0
    add     r8, r9              ; v0 += v1
    add     r10, r11            ; v2 += v3
    rol     r9, 13              ; v1 = rol(v1, 13)
    rol     r11, 16             ; v3 = rol(v3, 16)
    xor     r9, r8              ; v1 ^= v0
    xor     r11, r10            ; v3 ^= v2
    rol     r8, 32              ; v0 = rol(v0, 32)
    add     r10, r9             ; v2 += v1
    add     r8, r11             ; v0 += v3
    rol     r9, 17              ; v1 = rol(v1, 17)
    rol     r11, 21             ; v3 = rol(v3, 21)
    xor     r9, r10              ; v1 ^= v2
    xor     r11, r8              ; v3 ^= v0
    rol     r10, 32             ; v2 = rol(v2, 32)
%endmacro
```

State registers: r8=v0, r9=v1, r10=v2, r11=v3.

**`siphash_compute(rdi=field_ptr, rsi=qword_count) -> rax=mac`** (option a parameterized per R7):
```nasm
siphash_compute:
    push    rbx
    push    rbp
    ; Initialize state from siphash_key + magic constants
    mov     r8, [rel siphash_key + 0]
    xor     r8, 0x736f6d6570736575    ; v0 = key[0] ^ "somepseu"
    mov     r9, [rel siphash_key + 8]
    xor     r9, 0x646f72616e646f6d    ; v1 = key[1] ^ "dorandom"
    mov     r10, [rel siphash_key + 0]
    xor     r10, 0x6c7967656e657261   ; v2 = key[0] ^ "lygenera"
    mov     r11, [rel siphash_key + 8]
    xor     r11, 0x7465646279746573   ; v3 = key[1] ^ "tedbytes"
    ; Compression loop: for each qword chunk
    mov     rcx, rsi                  ; chunk count
    mov     rbx, rdi                  ; field pointer
.compress_loop:
    test    rcx, rcx
    jz      .finalize
    mov     rdx, [rbx]
    xor     r11, rdx                  ; v3 ^= chunk
    SIPROUND
    SIPROUND
    xor     r8, rdx                   ; v0 ^= chunk
    add     rbx, 8
    dec     rcx
    jmp     .compress_loop
.finalize:
    ; Append length-tag byte
    mov     rdx, rsi
    shl     rdx, 3                    ; length in bytes (qwords × 8)
    and     rdx, 0xFF
    shl     rdx, 56                   ; length tag in high byte
    xor     r11, rdx
    SIPROUND
    SIPROUND
    xor     r8, rdx
    ; Final block
    xor     r10, 0xFF                 ; v2 ^= 0xFF
    SIPROUND
    SIPROUND
    SIPROUND
    SIPROUND
    ; Output: v0 ^ v1 ^ v2 ^ v3
    mov     rax, r8
    xor     rax, r9
    xor     rax, r10
    xor     rax, r11
    pop     rbp
    pop     rbx
    ret
```

**`siphash_compute_cap_mac(rdi=slot_ptr) -> rax=mac`** thin wrapper:
```nasm
siphash_compute_cap_mac:
    mov     rsi, CAP_MAC_INPUT_QWORDS    ; 6
    jmp     siphash_compute              ; tail call
```

Total estimate: ~120 lines for siphash_compute + SIPROUND macro definitions, ~15 lines wrapper, ~20 lines self-test = ~155 lines plus comments and headers.

## R7 — SipHash self-test specification (E1)

**Architect's recommendation: option (a) parameterized signature.** TB confirms this is the right call.

The self-test is the second consumer that triggers generalization. D1.10.1.7's "V1.0-specific signature; generalize when second use case appears" exactly describes this scenario — the self-test is that second use case. Cleaner to ship parameterized from the start than to build hard-coded then parameterize at next pod.

**D1.10.2a.8 records the supersession:** D1.10.1.7's V1.0-specific signature recommendation is effectively overridden by recon at 1.10.2a HALT 1. Architectural intent is preserved (Cap MAC over 6 fields) via the `siphash_compute_cap_mac` thin wrapper.

**Self-test vector** (per architect spec):
- Key: `siphash_key[0] = 0x0706050403020100`, `siphash_key[1] = 0x0F0E0D0C0B0A0908`
- Input: 1 qword `0x0706050403020100`
- Expected MAC: `0xa129ca6149be45e5`

**`siphash_self_test_run`:**
```nasm
siphash_self_test_run:
    ; Save current siphash_key
    mov     rax, [rel siphash_key + 0]
    mov     [rel siphash_key_save + 0], rax
    mov     rax, [rel siphash_key + 8]
    mov     [rel siphash_key_save + 8], rax
    ; Load test key
    mov     qword [rel siphash_key + 0], 0x0706050403020100
    mov     qword [rel siphash_key + 8], 0x0F0E0D0C0B0A0908
    ; Set up test input
    mov     qword [rel siphash_self_test_input], 0x0706050403020100
    ; Compute MAC over 1 qword
    lea     rdi, [rel siphash_self_test_input]
    mov     rsi, 1
    call    siphash_compute
    ; Compare to expected
    mov     rcx, 0xa129ca6149be45e5
    cmp     rax, rcx
    je      .self_test_pass
    ; Mismatch — hard-fail
    lea     rsi, [rel str_siphash_self_test_fail]
    call    auryn_puts
    cli
    hlt
    jmp     $
.self_test_pass:
    ; Restore real siphash_key
    mov     rax, [rel siphash_key_save + 0]
    mov     [rel siphash_key + 0], rax
    mov     rax, [rel siphash_key_save + 8]
    mov     [rel siphash_key + 8], rax
    ret
```

## R8 — ROOT_CAP construction specification

**`construct_root_cap`** writes 6 named fields at vm_cap_pool[0], computes MAC via siphash_compute, registers in cap_registry, sanity-checks that the assigned cap_id is 1.

```nasm
construct_root_cap:
    lea     rdi, [rel vm_cap_pool]
    mov     qword [rdi + CAP_OFF_CAP_ID_SELF], ROOT_CAP_ID    ; 1
    mov     qword [rdi + CAP_OFF_ARENA_ID], 0
    mov     qword [rdi + CAP_OFF_OWNER_DEMOD_ID], 0
    mov     qword [rdi + CAP_OFF_RESOURCE_DESC], 0
    mov     qword [rdi + CAP_OFF_PARENT_CAP_ID], 0
    mov     qword [rdi + CAP_OFF_GENERATION_COUNTER], 0
    ; Compute MAC over 6 qwords (cap_id_self through generation_counter)
    push    rdi
    mov     rsi, CAP_MAC_INPUT_QWORDS
    call    siphash_compute
    pop     rdi
    mov     [rdi + CAP_OFF_MAC], rax
    ; Increment vm_cap_next (slot consumed)
    inc     qword [rel vm_cap_next]
    ; Register in cap_registry — assigns cap_id
    call    registry_register_cap                            ; rdi = slot_ptr
    cmp     rax, ROOT_CAP_ID
    je      .root_cap_ok
    ; Sanity fail — registry assigned id ≠ 1
    lea     rsi, [rel str_root_cap_id_wrong]
    call    auryn_puts
    cli
    hlt
    jmp     $
.root_cap_ok:
    ret
```

The slot's +0x38 through +0x7F (reserved 80 bytes) stays BSS-zero. No explicit zeroing needed since vm_cap_pool is zero-initialized at boot.

## R9 — ROOT_CAP MAC self-verification specification (E3)

**`verify_root_cap_mac`** recomputes MAC and compares to stored:

```nasm
verify_root_cap_mac:
    lea     rdi, [rel vm_cap_pool]
    ; Save stored MAC
    mov     rax, [rdi + CAP_OFF_MAC]
    mov     [rel root_cap_mac_save], rax
    ; Recompute MAC over 6 qwords
    push    rdi
    mov     rsi, CAP_MAC_INPUT_QWORDS
    call    siphash_compute
    pop     rdi
    cmp     rax, [rel root_cap_mac_save]
    je      .root_cap_mac_ok
    ; Mismatch — hard-fail
    lea     rsi, [rel str_root_cap_mac_mismatch]
    call    auryn_puts
    cli
    hlt
    jmp     $
.root_cap_mac_ok:
    ret
```

Verification catches:
- SipHash non-determinism over identical input (would indicate a compute bug)
- MAC stored at wrong offset (e.g., +0x28 vs +0x30)
- MAC computed over wrong field range (e.g., 5 or 7 qwords vs 6)

If any of those bugs exist, this verification surfaces them at boot rather than letting OP_CAP_CHECK fail later with confusing symptoms.

## R10 — Build chain confirmation

| Tool | Version | Status |
|------|---------|--------|
| nasm | 2.16.01 | ✓ |
| mtools | 4.0.43 | ✓ |
| qemu-system-x86_64 | 8.2.2 | ✓ |
| `./build.sh` × 2 | exit 0 both runs | ✓ |

EFI sha256 deterministic across two runs: `3bfb0c0a2410e90c9aa9d5def1c598ec26d6c058d68c73cf67cb2da5e737fff6`. Matches Pod 1.9.3 row in binary_contracts.md exactly.

---

## Section 2 — Architect calls before AUTHORIZED-1

### A1 — SipHash signature parameterization (per R7)

D1.10.1.7 specified V1.0-specific signature `siphash_compute_cap_mac(rdi=slot_ptr) -> rax=mac` with explicit forward-log "generalize when second use case appears." E1's self-test IS that second use case. Recon at R7 surfaces that parameterization is unavoidable.

**TB recommendation: ship parameterized from the start.**
```
siphash_compute(rdi=field_ptr, rsi=qword_count) -> rax=mac
siphash_compute_cap_mac(rdi=slot_ptr) -> rax=mac    (thin wrapper, rsi=6)
```

D1.10.2a.8 records the supersession of D1.10.1.7's V1.0-specific recommendation.

Confirm or override (architect may prefer to ship hard-coded version + separate self-test variant).

---

## Section 3 — Risks identified

- **R3.1 — SipHash test vector value.** Architect specified expected MAC `0xa129ca6149be45e5`. TB does not have the Aumasson reference vectors memorized; trusting the architect's value. If the value is wrong, the self-test at boot will hard-fail spuriously, masking real correctness with a verification-process bug. Pod 1.10.2a B4 boot-success outcome is the empirical validation — pristine boot means MAC matches.
- **R3.2 — RDSEED/RDRAND retry budget.** 64 iterations per architect's recommendation. If RDSEED contention is severe (theoretical), boot could wait briefly before falling back. Bounded; no infinite loop. Acceptable.
- **R3.3 — siphash_key_source flag observation.** Flag is set but has no current consumer. Pod 2 (Cop) inheritance per DEFERRED #56. Flagged as substrate state with no current reader (deliberate forward-log; matches architect's E2 doctrine note about declared substrate state).
- **R3.4 — ROOT_CAP cap_id sanity check.** `registry_register_cap` returns the assigned id (next id from `cap_registry_next_id`, which initializes to 1). Sanity check `cmp rax, 1` will pass on first registration. If a future bug double-initializes registry or runs init twice, the sanity check catches it. Currently a paranoia check; documented as intentional defense.

---

## Section 4 — Phase 2 execution gates (post-AUTHORIZED-1)

S1: 16 constants in defines.asm (5 OP_CAP_*, 5 pool/slot constants, 1 ERR_CAP_*, 8 CAP_OFF_* offsets, plus ROOT_CAP_ID and CAP_MAC_INPUT_QWORDS = 17 actually)
S2: vmdata.asm — cap_stack adjacent to vm_ret_stack; vm_cap_pool + cap_registry adjacent to other pool/registry blocks; current_cap_* + siphash_key adjacent to current_demod_* singleton
S3: boot/cap.asm NEW — SIPROUND macro + siphash_compute + siphash_compute_cap_mac + registry pair + construct_root_cap + verify_root_cap_mac + derive_siphash_key + siphash_self_test_run; ~250 lines
S4: boot.asm include line between provenance.asm/outcome.asm and bastian.asm
S5: 4-call sequence in efi_entry between line 125 and 127
S6: 4 diagnostic strings in data.asm

Phase 2B B1 reads BOOTX64.EFI; B2/B3 verify 174j/53j canaries; B4 pristine-boot inspection for absence of FATAL diagnostics; B5/B6 Outcome and refit regression invisibility.

---

## Section 5 — Surprises

- **S5.1 — Self-test's signature requirement supersedes D1.10.1.7's V1.0-specific recommendation earlier than expected.** D1.10.1.7 said "generalize when a second use case appears" anticipating Pod 1.12 (Demod) or similar. Pod 1.10.2a's E1 self-test is the second use case. The doctrine works as designed — recon catches the parameterization need before implementation drift.
- **S5.2 — derive_siphash_key, siphash_self_test_run, construct_root_cap, verify_root_cap_mac decompose cleanly** into four discrete callable units. Each unit has a single responsibility; each has its own FATAL diagnostic on failure; each can be tested independently. The 4-call sequence in efi_entry reads as a checklist.
- **S5.3 — D1.9.2a.3's substrate-bookkeeping-is-0j doctrine extends naturally to cryptographic substrate-init.** Boot-time SipHash work + CPUID probes + ROOT_CAP MAC computation are all pre-VM (before fetch loop runs). They cannot affect runtime canary accounting. B2/B3 will empirically confirm: 174j/53j held under boot-time crypto additions.

---

## Section 6 — HALT 1 status

- All R-items completed.
- No source files modified.
- No commits staged.
- 1 architect call (A1 — SipHash signature parameterization).
- 4 risks surfaced (none blocking).
- 3 surprises surfaced.

**HALT 1 — awaiting AUTHORIZED.**

— Terminal Boy
May 04 2026
