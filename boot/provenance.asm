; =============================================================
; Provenance — ProvEvent ring buffer + prov_append primitive
; Pod 1.8.5c — Move 2
;
; V1.0 ships the conduit, not the policy:
;   - Ring buffer (prov_ring_buf) defined in vmdata.asm
;   - prov_append checks current_demod_prov_enabled (Move 2 cap-flag,
;     default OFF). If 0, returns immediately. No automatic invocation
;     anywhere in V1.0.
;   - Pod 2 (Cop) wires automatic invocation behind cap grant. DeepSeek
;     overhead measurement (TERRAFORM-2) gates default-ON flip in a
;     later pod.
;
; ProvEvent layout (32 bytes, cache-aligned per A4):
;   +0x00 opcode (u8) + 7 bytes pad         — PROV_OFF_OPCODE
;   +0x08 demod_id (u64)                    — PROV_OFF_DEMOD_ID
;   +0x10 fetch_counter (u64)               — PROV_OFF_FETCH_CTR
;   +0x18 reserved (u64)                    — PROV_OFF_RESERVED (future)
;
; Internal calling convention (matches registry.asm shape):
;   Input:    rdi = opcode (low byte; high bits ignored)
;             rsi = demod_id
;             rdx = fetch_counter
;   Output:   none
;   Clobbers: rax, rcx
;   Preserves: r12 (instruction pointer), r13 (operand stack),
;              r14 (energy budget), r15, rbx, rbp, rdi, rsi, rdx
; =============================================================

; --- prov_append ---
; Append a ProvEvent to the ring buffer if provenance is enabled
; on the current demod. No-op when disabled (V1.0 default).
prov_append:
    ; Cap-gate: bail if provenance is disabled on current demod.
    mov     rax, [rel current_demod_prov_enabled]
    test    rax, rax
    jz      .prov_append_done
    ; Compute write address: prov_ring_buf + (head & MASK) * 32
    mov     rax, [rel prov_ring_head]
    and     rax, PROV_RING_MASK
    shl     rax, 5                  ; * PROV_EVENT_SIZE (32)
    lea     rcx, [rel prov_ring_buf]
    add     rcx, rax                ; rcx = entry address
    ; Write opcode (zero-extended from rdi low byte) at +0x00
    ; (zero the full qword first so high bytes are not stale)
    mov     qword [rcx + PROV_OFF_OPCODE], 0
    mov     al, dil
    mov     [rcx + PROV_OFF_OPCODE], al
    ; demod_id at +0x08
    mov     [rcx + PROV_OFF_DEMOD_ID], rsi
    ; fetch_counter at +0x10
    mov     [rcx + PROV_OFF_FETCH_CTR], rdx
    ; reserved at +0x18 (zero — future fields)
    mov     qword [rcx + PROV_OFF_RESERVED], 0
    ; Bump head (overwrite-on-full ring; mask applied on next read)
    inc     qword [rel prov_ring_head]
.prov_append_done:
    ret
