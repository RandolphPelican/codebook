; =============================================================
; Cap — typed capability primitive
; Pod 1.10.2a — substrate plumbing (no opcode handlers)
;
; V1.0 ships the substrate; opcode handlers + retrofit + tests
; land in 1.10.2b. This file provides:
;   - SIPROUND macro (single SipHash-2-4 round)
;   - siphash_compute(rdi=field_ptr, rsi=qword_count) -> rax=mac
;     parameterized per A1 ratification at Pod 1.10.2a HALT 1
;     (D1.10.2a.8 supersedes D1.10.1.7's V1.0-specific signature)
;   - siphash_compute_cap_mac(rdi=slot_ptr) -> rax=mac
;     thin wrapper for Cap MAC over 6 qwords (rsi=6)
;   - registry_register_cap / registry_lookup_cap byte-for-byte
;     mirrors of registry.asm pattern with cap substitutions
;   - derive_siphash_key — CPUID probe RDSEED → RDRAND → hard-fail
;   - siphash_self_test_run (E1) — verify SipHash against published
;     vectors at boot; hard-fail on mismatch
;   - construct_root_cap — build ROOT_CAP slot, compute MAC, register
;   - verify_root_cap_mac (E3) — recompute and verify ROOT_CAP MAC
;
; Boot-time call sequence in efi_entry (post-locate_gop, pre-SEED→FORM):
;   call derive_siphash_key
;   call siphash_self_test_run
;   call construct_root_cap
;   call verify_root_cap_mac
; All four hard-fail with auryn_puts diagnostic + cli/hlt/jmp $
; on failure. Substrate refuses to boot if any verification fails.
;
; Linear scan acceptable for V1.0 — pool capacity is 64. Free-list
; mechanism deferred (DEFERRED #19 family).
; =============================================================

; --- SipHash-2-4 SIPROUND macro ---
; State: r8=v0, r9=v1, r10=v2, r11=v3
; Per Aumasson reference (https://www.aumasson.jp/siphash/siphash.pdf,
; reference C at https://github.com/veorq/SipHash/blob/master/siphash.c).
; 14 instructions per round.
%macro SIPROUND 0
    add     r8, r9              ; v0 += v1
    rol     r9, 13              ; v1 = rol(v1, 13)
    xor     r9, r8              ; v1 ^= v0
    rol     r8, 32              ; v0 = rol(v0, 32)
    add     r10, r11            ; v2 += v3
    rol     r11, 16             ; v3 = rol(v3, 16)
    xor     r11, r10            ; v3 ^= v2
    add     r8, r11             ; v0 += v3
    rol     r11, 21             ; v3 = rol(v3, 21)
    xor     r11, r8             ; v3 ^= v0
    add     r10, r9             ; v2 += v1
    rol     r9, 17              ; v1 = rol(v1, 17)
    xor     r9, r10             ; v1 ^= v2
    rol     r10, 32             ; v2 = rol(v2, 32)
%endmacro

; --- siphash_compute(rdi=field_ptr, rsi=qword_count) -> rax=mac ---
; Parameterized signature per A1 ratification at Pod 1.10.2a HALT 1.
; Reads `qword_count` qwords starting at field_ptr; computes
; SipHash-2-4 MAC under siphash_key. Output in rax.
;
; Internal calling convention (mirrors registry.asm shape):
;   Input:    rdi = field_ptr, rsi = qword_count (>=0; 0 OK = empty input)
;   Output:   rax = 64-bit MAC
;   Clobbers: rax, rcx, rdx, rsi, r8, r9, r10, r11
;   Preserves: r12, r13, r14, r15, rbx, rbp, rdi
siphash_compute:
    push    rbx
    push    rbp
    mov     rbx, rdi                ; rbx = field_ptr (preserved through compression)
    mov     rbp, rsi                ; rbp = qword_count (loop counter)
    ; Initialize state from siphash_key XOR magic constants
    ;   v0 = key[0] ^ "somepseu"
    ;   v1 = key[1] ^ "dorandom"
    ;   v2 = key[0] ^ "lygenera"
    ;   v3 = key[1] ^ "tedbytes"
    mov     r8, [rel siphash_key + 0]
    mov     rax, 0x736f6d6570736575
    xor     r8, rax
    mov     r9, [rel siphash_key + 8]
    mov     rax, 0x646f72616e646f6d
    xor     r9, rax
    mov     r10, [rel siphash_key + 0]
    mov     rax, 0x6c7967656e657261
    xor     r10, rax
    mov     r11, [rel siphash_key + 8]
    mov     rax, 0x7465646279746573
    xor     r11, rax
    ; Compression loop: for each 8-byte chunk
    test    rbp, rbp
    jz      .siphash_finalize
.siphash_compress_loop:
    mov     rdx, [rbx]              ; m = chunk
    xor     r11, rdx                ; v3 ^= m
    SIPROUND
    SIPROUND
    xor     r8, rdx                 ; v0 ^= m
    add     rbx, 8
    dec     rbp
    jnz     .siphash_compress_loop
.siphash_finalize:
    ; Build length tag: b = (qword_count * 8) << 56
    ; (no remainder bytes — input is always full qwords for V1.0)
    mov     rdx, rsi
    shl     rdx, 3                  ; rdx = inlen in bytes
    shl     rdx, 56                 ; rdx = inlen << 56
    ; Final block
    xor     r11, rdx                ; v3 ^= b
    SIPROUND
    SIPROUND
    xor     r8, rdx                 ; v0 ^= b
    ; Finalization — v2 ^= 0xFF (low-byte XOR; using r10b form to avoid
    ; NASM imm8 sign-extension which would XOR with 0xFFFFFFFFFFFFFFFF)
    xor     r10b, 0xFF              ; v2 ^= 0x00000000000000FF (per SipHash spec)
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

; --- siphash_compute_cap_mac(rdi=slot_ptr) -> rax=mac ---
; Thin wrapper for Cap MAC. Pod 1.10.3 expanded MAC-input range from
; 6 qwords to 7 (cap_id_self through energy_budget at slot+0x00..+0x30).
; Field count is symbolic via CAP_MAC_INPUT_QWORDS; no source change
; needed in this wrapper when constant updates.
siphash_compute_cap_mac:
    mov     rsi, CAP_MAC_INPUT_QWORDS
    jmp     siphash_compute         ; tail call

; --- registry_register_cap(rdi=slot_ptr) -> rax=cap_id ---
; Allocates next cap_id, appends {id, slot_ptr} to cap_registry.
; Byte-for-byte mirror of registry_register_outcome (Pod 1.9.2a) /
; registry_register_sign (Pod 1.8.5b) with cap substitutions.
;
; Input:  rdi = slot_ptr
; Output: rax = cap_id (>=1 on success, 0 if registry full)
; Clobbers: rax, rcx, rdx, rsi
; Preserves: r12, r13, r14, r15, rbx, rbp, rdi
registry_register_cap:
    mov     rcx, [rel cap_registry_count]
    cmp     rcx, CAP_POOL_SLOTS
    jge     .reg_cap_full
    mov     rax, rcx
    shl     rax, 4                  ; count * 16
    lea     rsi, [rel cap_registry]
    add     rsi, rax
    mov     rax, [rel cap_registry_next_id]
    mov     [rsi], rax              ; entry.id = next_id
    mov     [rsi + 8], rdi          ; entry.slot_ptr = arg
    inc     qword [rel cap_registry_next_id]
    inc     qword [rel cap_registry_count]
    ret
.reg_cap_full:
    xor     rax, rax
    ret

; --- registry_lookup_cap(rdi=cap_id) -> rax=slot_ptr ---
; Linear scan for cap_id; returns slot_ptr or 0 if not found.
; Same calling convention as registry_register_cap.
registry_lookup_cap:
    test    rdi, rdi
    jz      .lookup_cap_null        ; id 0 (CAP_ID_NULL) reserved
    mov     rcx, [rel cap_registry_count]
    test    rcx, rcx
    jz      .lookup_cap_null        ; empty registry
    lea     rsi, [rel cap_registry]
.lookup_cap_loop:
    mov     rax, [rsi]
    cmp     rax, rdi
    je      .lookup_cap_hit
    add     rsi, 16
    dec     rcx
    jnz     .lookup_cap_loop
.lookup_cap_null:
    xor     rax, rax
    ret
.lookup_cap_hit:
    mov     rax, [rsi + 8]
    ret

; --- derive_siphash_key ---
; Probes RDSEED via CPUID leaf 7 sub-leaf 0 EBX bit 18; falls back
; to RDRAND via CPUID leaf 1 ECX bit 30 if RDSEED unavailable.
; Hard-fail with str_no_entropy + auryn_puts + cli/hlt/jmp $ if both
; unavailable OR if entropy source exhausts retry budget (64 iterations).
;
; Per D1.10.1.6 / A1 ratification: no fixed-key fallback tier.
; Per-boot key regeneration; siphash_key_source flag (0=rdseed,
; 1=rdrand) preserved in substrate state for audit.
;
; Clobbers: rax, rbx, rcx, rdx (CPUID + entropy ops)
derive_siphash_key:
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
    jmp     .entropy_fail

.have_rdseed:
    mov     qword [rel siphash_key_source], 0
    ; First u64 with retry budget × 64
    mov     ecx, 64
.try1_rdseed:
    rdseed  rax
    jc      .got_lo_rdseed
    loop    .try1_rdseed
    jmp     .entropy_fail
.got_lo_rdseed:
    mov     [rel siphash_key + 0], rax
    ; Second u64
    mov     ecx, 64
.try2_rdseed:
    rdseed  rax
    jc      .got_hi_rdseed
    loop    .try2_rdseed
    jmp     .entropy_fail
.got_hi_rdseed:
    mov     [rel siphash_key + 8], rax
    ret

.have_rdrand:
    mov     qword [rel siphash_key_source], 1
    mov     ecx, 64
.try1_rdrand:
    rdrand  rax
    jc      .got_lo_rdrand
    loop    .try1_rdrand
    jmp     .entropy_fail
.got_lo_rdrand:
    mov     [rel siphash_key + 0], rax
    mov     ecx, 64
.try2_rdrand:
    rdrand  rax
    jc      .got_hi_rdrand
    loop    .try2_rdrand
    jmp     .entropy_fail
.got_hi_rdrand:
    mov     [rel siphash_key + 8], rax
    ret

.entropy_fail:
    lea     rsi, [rel str_no_entropy]
    call    auryn_puts
    cli
    hlt
    jmp     $

; --- siphash_self_test_run (E1) ---
; Verifies SipHash-2-4 against Aumasson published vector at boot.
;   Key:   0x0706050403020100, 0x0F0E0D0C0B0A0908
;   Input: 1 qword 0x0706050403020100
;   Expected MAC: 0xa129ca6149be45e5
; Hard-fail with str_siphash_self_test_fail on mismatch.
; Saves and restores siphash_key around the test.
siphash_self_test_run:
    ; Save current siphash_key (post-derive_siphash_key)
    mov     rax, [rel siphash_key + 0]
    mov     [rel siphash_key_save + 0], rax
    mov     rax, [rel siphash_key + 8]
    mov     [rel siphash_key_save + 8], rax
    ; Load test key
    mov     rax, 0x0706050403020100
    mov     [rel siphash_key + 0], rax
    mov     rax, 0x0F0E0D0C0B0A0908
    mov     [rel siphash_key + 8], rax
    ; Set up test input (1 qword)
    mov     rax, 0x0706050403020100
    mov     [rel siphash_self_test_input], rax
    ; Compute MAC over 1 qword
    lea     rdi, [rel siphash_self_test_input]
    mov     rsi, 1
    call    siphash_compute
    ; Compare to expected (canonical veorq vectors_sip64[8] little-endian u64)
    mov     rcx, 0x93f5f5799a932462
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

; --- construct_root_cap ---
; Builds ROOT_CAP slot at vm_cap_pool[0]:
;   cap_id_self=1, arena_id=0, owner_demod_id=0,
;   cap_bitmap=CAP_BITMAP_UNBOUNDED (Pod 2.2 D2.2.3 — was resource_descriptor=0
;   pre-2.2; same byte position, structured forge-bit semantics with all
;   bits set for ROOT keystone authority),
;   parent_cap_id=0, generation_counter=0,
;   energy_budget=ENERGY_BUDGET_UNBOUNDED (Pod 1.10.3 D1.10.3.3),
;   energy_used=0 (non-MAC, substrate-managed).
; Computes MAC via siphash_compute over 7 fields (Pod 1.10.3
; D1.10.3.4 — was 6 pre-1.10.3); stores at +0x38 (was +0x30).
; Pod 2.2 risk surface (D2.2.X): MAC content shifts at +0x18 from 0
; (placeholder) to MAX_U64 (CAP_BITMAP_UNBOUNDED), so ROOT_CAP MAC value
; differs from Pod 2.1's. construct/verify must agree on new content;
; mismatch fires verify_root_cap_mac FATAL before MIND phase per E3
; self-test pattern.
; Increments vm_cap_next; registers in cap_registry; sanity-checks
; that registry_register_cap returned cap_id=1.
; Hard-fail with str_root_cap_id_wrong if sanity check fails.
construct_root_cap:
    lea     rdi, [rel vm_cap_pool]
    mov     qword [rdi + CAP_OFF_CAP_ID_SELF],        ROOT_CAP_ID
    mov     qword [rdi + CAP_OFF_ARENA_ID],           0
    mov     qword [rdi + CAP_OFF_OWNER_DEMOD_ID],     0
    ; Pod 2.2 — CAP_BITMAP_UNBOUNDED = 0xFFFFFFFFFFFFFFFF (64-bit imm requires register intermediate).
    mov     rax, CAP_BITMAP_UNBOUNDED
    mov     [rdi + CAP_OFF_BITMAP], rax
    mov     qword [rdi + CAP_OFF_PARENT_CAP_ID],      0
    mov     qword [rdi + CAP_OFF_GENERATION_COUNTER], 0
    ; Pod 1.10.3 — energy_budget MAC-input (immutable); energy_used non-MAC (mutable).
    ; ENERGY_BUDGET_UNBOUNDED = 0xFFFFFFFFFFFFFFFF (64-bit imm requires register intermediate).
    mov     rax, ENERGY_BUDGET_UNBOUNDED
    mov     [rdi + CAP_OFF_ENERGY_BUDGET], rax
    mov     qword [rdi + CAP_OFF_ENERGY_USED], 0
    ; Compute MAC over 7 qwords (cap_id_self through energy_budget)
    push    rdi                     ; save slot_ptr across siphash_compute
    mov     rsi, CAP_MAC_INPUT_QWORDS
    call    siphash_compute
    pop     rdi
    mov     [rdi + CAP_OFF_MAC], rax
    ; Increment vm_cap_next (slot consumed)
    inc     qword [rel vm_cap_next]
    ; Register in cap_registry — assigns cap_id (must be 1 on first registration)
    call    registry_register_cap
    cmp     rax, ROOT_CAP_ID
    je      .root_cap_ok
    ; Sanity fail — registry assigned id ≠ ROOT_CAP_ID
    lea     rsi, [rel str_root_cap_id_wrong]
    call    auryn_puts
    cli
    hlt
    jmp     $
.root_cap_ok:
    ret

; --- verify_root_cap_mac (E3) ---
; Recomputes ROOT_CAP MAC and compares to stored MAC at +0x38 (Pod 1.10.3
; layout — was +0x30 pre-1.10.3; CAP_OFF_MAC constant updated).
; Catches: SipHash non-determinism over identical input, MAC stored
; at wrong offset, MAC computed over wrong field range. Pod 1.10.3
; relayout: 7-qword input range; relayout-wiring errors surface here
; at boot E3 self-test before MIND phase per D1.10.2a.5 doctrine.
; Hard-fail with str_root_cap_mac_mismatch on mismatch.
verify_root_cap_mac:
    lea     rdi, [rel vm_cap_pool]
    ; Save stored MAC
    mov     rax, [rdi + CAP_OFF_MAC]
    mov     [rel root_cap_mac_save], rax
    ; Recompute MAC over 7 qwords (Pod 1.10.3 — was 6 pre-1.10.3)
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
