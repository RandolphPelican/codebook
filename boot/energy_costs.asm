; =============================================================
; Energy Costs — Per-Opcode Cost Table + Lookup
; The kernel's honest accounting of what each opcode demands.
; Functions: energy_cost_lookup
; Depends:   defines.asm (OP_* constants)
; Layer:     Layer 1 — Typed CBS VM (Pod 1.8)
;
; The cost table is a 256-entry array (one per possible opcode byte),
; each entry a qword (8 bytes) holding the joules cost. The fetch
; loop calls energy_cost_lookup with the opcode byte just fetched;
; the returned value is debited from r14 and added to [energy_used].
; Handlers run pure-semantic — they never touch energy.
;
; Philosophy (D1.8 decision record):
; The cost IS the cost. No hidden surcharges. Gating ops (HALT,
; RESERVE) = 0j: structural, not metabolic. Undefined opcodes
; default to 1j: defensive forward progress or eventual bankruptcy.
; =============================================================

; energy_cost_lookup — opcode byte in al, joules out in rax
; Clobbers: none beyond rax
; Single indexed fetch from the cost table.
energy_cost_lookup:
    push    rbx
    movzx   rbx, al
    lea     rax, [rel energy_cost_table]
    mov     rax, [rax + rbx * 8]
    pop     rbx
    ret

; === Static cost table (256 entries x 8 bytes = 2048 bytes) ===
; Indexed by opcode byte. Each entry = joules cost for that opcode.
; Laid out in 16-entry rows (0x_0 through 0x_F per row).
    align 16
energy_cost_table:
; Row 0x00–0x0F
    dq 1                    ; 0x00 — unused (default)
    dq 1                    ; 0x01 — OP_PUSH
    dq 1                    ; 0x02 — OP_PUSH_STR
    dq 1, 1, 1, 1, 1       ; 0x03–0x07 — unallocated
    dq 1, 1, 1, 1, 1       ; 0x08–0x0C — unallocated
    dq 1, 1, 1              ; 0x0D–0x0F — unallocated
; Row 0x10–0x1F
    dq 1                    ; 0x10 — OP_ADD
    dq 1                    ; 0x11 — OP_SUB
    dq 2                    ; 0x12 — OP_MUL
    dq 3                    ; 0x13 — OP_DIV
    dq 1                    ; 0x14 — OP_EQ
    dq 1                    ; 0x15 — OP_NE
    dq 1                    ; 0x16 — OP_LT
    dq 1                    ; 0x17 — OP_GT
    dq 1                    ; 0x18 — OP_LE
    dq 1                    ; 0x19 — OP_GE
    dq 3                    ; 0x1A — OP_MOD
    dq 1, 1, 1, 1, 1       ; 0x1B–0x1F — unallocated
; Row 0x20–0x2F
    dq 0                    ; 0x20 — OP_RESERVE (structural, not metabolic)
    dq 1, 1, 1, 1, 1       ; 0x21–0x25 — unallocated
    dq 1, 1, 1, 1, 1       ; 0x26–0x2A — unallocated
    dq 1, 1, 1, 1, 1       ; 0x2B–0x2F — unallocated
; Row 0x30–0x3F
    times 16 dq 1           ; 0x30–0x3F — unallocated
; Row 0x40–0x4F
    dq 1                    ; 0x40 — OP_JMP
    dq 1, 1, 1, 1, 1       ; 0x41–0x45 — unallocated
    dq 1, 1, 1, 1, 1       ; 0x46–0x4A — unallocated
    dq 1, 1, 1, 1, 1       ; 0x4B–0x4F — unallocated
; Row 0x50–0x5F
    dq 2                    ; 0x50 — OP_CALL
    dq 1, 1                 ; 0x51–0x52 — unallocated
    dq 1                    ; 0x53 — OP_RET
    dq 1                    ; 0x54 — unallocated
    dq 1                    ; 0x55 — OP_JIF
    dq 1                    ; 0x56 — OP_JBACK
    dq 1, 1, 1, 1, 1       ; 0x57–0x5B — unallocated
    dq 1, 1, 1, 1           ; 0x5C–0x5F — unallocated
; Row 0x60–0x6F
    times 16 dq 1           ; 0x60–0x6F — unallocated
; Row 0x70–0x7F
    dq 1                    ; 0x70 — OP_LOAD
    dq 1                    ; 0x71 — OP_STORE
    dq 1, 1, 1, 1, 1       ; 0x72–0x76 — unallocated
    dq 1, 1, 1, 1, 1       ; 0x77–0x7B — unallocated
    dq 1, 1, 1, 1           ; 0x7C–0x7F — unallocated
; Row 0x80–0x8F
    dq 2                    ; 0x80 — OP_PRINT_NUM (I/O)
    dq 2                    ; 0x81 — OP_EMIT (I/O)
    dq 1                    ; 0x82 — OP_NEWLINE
    dq 1                    ; 0x83 — OP_DUP
    dq 1                    ; 0x84 — OP_DROP
    dq 1                    ; 0x85 — OP_SWAP
    dq 3                    ; 0x86 — OP_PRINT_STR (I/O, string processing)
    dq 1                    ; 0x87 — OP_DUP2 (orphaned, still defined)
    dq 1, 1, 1, 1, 1       ; 0x88–0x8C — unallocated
    dq 1, 1, 1              ; 0x8D–0x8F — unallocated
; Row 0x90–0x9F
    dq 5                    ; 0x90 — OP_GRANT_CAP (capability operation)
    dq 5                    ; 0x91 — OP_USE_CAP (capability operation)
    dq 1, 1, 1, 1, 1       ; 0x92–0x96 — unallocated
    dq 1, 1, 1, 1, 1       ; 0x97–0x9B — unallocated
    dq 1, 1, 1, 1           ; 0x9C–0x9F — unallocated
; Row 0xA0–0xAF — Sign opcodes (Pod 1.7 D1.7.6 values)
    dq 100                  ; 0xA0 — OP_SIGN_NEW
    dq 5                    ; 0xA1 — OP_SIGN_HASH
    dq 5                    ; 0xA2 — OP_SIGN_LABEL
    dq 5                    ; 0xA3 — OP_SIGN_ENERGY
    dq 1, 1, 1, 1, 1       ; 0xA4–0xA8 — reserved (Sign Pod 3+)
    dq 1, 1, 1, 1, 1       ; 0xA9–0xAD — reserved
    dq 1, 1                 ; 0xAE–0xAF — reserved
; Row 0xB0–0xBF
    times 16 dq 1           ; 0xB0–0xBF — unallocated (Outcome 0xB0–0xBF Pod 1.9)
; Row 0xC0–0xCF
    times 16 dq 1           ; 0xC0–0xCF — unallocated (Cap 0xC0–0xCF Pod 1.10)
; Row 0xD0–0xDF — Energy opcodes (Pod 1.8)
    dq 10                   ; 0xD0 — OP_ENERGY_NEW
    dq 1                    ; 0xD1 — OP_ENERGY_JOULES (accessor)
    dq 1                    ; 0xD2 — OP_ENERGY_SOURCE_OP (accessor)
    dq 0                    ; 0xD3 — OP_ENERGY_FREE (V1.0 no-op)
    dq 1, 1, 1, 1, 1       ; 0xD4–0xD8 — reserved (Energy V1.1+)
    dq 1, 1, 1, 1, 1       ; 0xD9–0xDD — reserved
    dq 1, 1                 ; 0xDE–0xDF — reserved
; Row 0xE0–0xEF
    times 16 dq 1           ; 0xE0–0xEF — unallocated (Demod 0xE0–0xEF Pod 1.12)
; Row 0xF0–0xFF
    dq 1, 1, 1, 1, 1       ; 0xF0–0xF4 — unallocated
    dq 1, 1, 1, 1, 1       ; 0xF5–0xF9 — unallocated
    dq 1, 1, 1, 1, 1       ; 0xFA–0xFE — unallocated
    dq 0                    ; 0xFF — OP_HALT (termination, free)
