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
; Pod 1.8.5c Move 1: indirected through current_demod_cost_table_ptr
;   so Pod 2 (Cop) can hand out per-demod tuned tables. V1.0 the pointer
;   defaults to the global energy_cost_table below (set in vmdata.asm).
energy_cost_lookup:
    push    rbx
    movzx   rbx, al
    mov     rax, [rel current_demod_cost_table_ptr]
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
; Row 0xA0–0xAF — Sign opcodes (Pod 1.7 D1.7.6 values; Pod 1.10.2b2 accessors at 0xA4-0xA6)
    dq 100                  ; 0xA0 — OP_SIGN_NEW
    dq 5                    ; 0xA1 — OP_SIGN_HASH
    dq 5                    ; 0xA2 — OP_SIGN_LABEL
    dq 5                    ; 0xA3 — OP_SIGN_ENERGY
    dq 0                    ; 0xA4 — OP_SIGN_ARENA (structural; no MAC verify per D1.10.2b2.5)
    dq 0                    ; 0xA5 — OP_SIGN_OWNER (structural)
    dq 0                    ; 0xA6 — OP_SIGN_CREATOR (structural)
    dq 1                    ; 0xA7 — OP_SIGN_EMBEDDING_HANDLE (Pod 3; metabolic; lookup + side-table read per D3.4)
    dq 1                    ; 0xA8 — reserved (Sign Pod 3.5+)
    dq 1, 1, 1, 1, 1       ; 0xA9–0xAD — reserved
    dq 1, 1                 ; 0xAE–0xAF — reserved
; Row 0xB0–0xBF — Cap opcodes (Pod 1.10.2b1 at 0xB0-0xB6, Pod 1.10.2b2 at 0xB7, Pod 1.10.3 at 0xB8-0xB9)
    dq 1                    ; 0xB0 — OP_CAP_NEW (metabolic construction; SipHash MAC compute over 7 qwords post-1.10.3)
    dq 1                    ; 0xB1 — OP_CAP_ENTER (metabolic; MAC verify per A1 — load-bearing forgery detection)
    dq 0                    ; 0xB2 — OP_CAP_EXIT (structural; cap_stack pop + cache restore; restored cap pre-authenticated)
    dq 0                    ; 0xB3 — OP_CAP_CURRENT (structural; pure substrate state read)
    dq 1                    ; 0xB4 — OP_CAP_ARENA (metabolic; lookup + MAC verify + slot read)
    dq 1                    ; 0xB5 — OP_CAP_OWNER (metabolic; lookup + MAC verify + slot read)
    dq 1                    ; 0xB6 — retired Pod 2.2 (was OP_CAP_RESOURCE; replaced by OP_CAP_BITMAP at 0xBA per D2.2.4); slot dead (no dispatch)
    dq 1                    ; 0xB7 — OP_CAP_PARENT (Pod 1.10.2b2; metabolic; lookup + MAC verify + parent_cap_id read)
    dq 1                    ; 0xB8 — OP_CAP_BUDGET (Pod 1.10.3; metabolic; lookup + MAC verify + energy_budget read)
    dq 1                    ; 0xB9 — OP_CAP_USED (Pod 1.10.3; metabolic; lookup + MAC verify + energy_used read)
    dq 1                    ; 0xBA — OP_CAP_BITMAP (Pod 2.2; metabolic; lookup + MAC verify + cap_bitmap read per D2.2.1)
    dq 1                    ; 0xBB — reserved
    dq 1, 1, 1, 1           ; 0xBC–0xBF — reserved
; Row 0xC0–0xCF — Embedding opcodes (Pod 3 substrate-prep + Pod 3.5 semantic ops)
    dq 100                  ; 0xC0 — OP_EMBEDDING_NEW (Pod 3; metabolic; pool alloc + 1536-byte vector copy + MAC over 196 qwords + registry register; D3.X cost basis matches Sign content-bearing primitive convention)
    dq 1                    ; 0xC1 — OP_EMBEDDING_ARENA (Pod 3; metabolic; lookup + MAC verify + slot read)
    dq 1                    ; 0xC2 — OP_EMBEDDING_OWNER (Pod 3)
    dq 1                    ; 0xC3 — OP_EMBEDDING_CREATOR (Pod 3)
    dq 1                    ; 0xC4 — OP_EMBEDDING_GET_DIM (Pod 3; metabolic; lookup + MAC verify + bounds-check + dim read)
    dq 1                    ; 0xC5 — OP_EMBEDDING_SIGN_HANDLE (Pod 3.5; metabolic; lookup + reverse side-table read per D3.20; mirrors 0xA7 cost shape)
    dq 400                  ; 0xC6 — OP_EMBEDDING_COSINE (Pod 3.5; static worst-case D3.16; 2× lookup + 2× MAC verify + 384-element compute per Form A: dot + 2× norm_sq + 2× sqrt + divisor; FP-determinism-load-bearing)
    dq 200                  ; 0xC7 — OP_EMBEDDING_DOT_PRODUCT (Pod 3.5; D3.16; 2× lookup + 2× MAC verify + 384 mul-add accumulation; ~half of cosine cost)
    dq 280                  ; 0xC8 — OP_EMBEDDING_L2_DISTANCE (Pod 3.5; D3.16; 2× lookup + 2× MAC verify + 384 sub-mul-add accumulation + sqrt; between dot and cosine)
    dq 100000               ; 0xC9 — OP_EMBEDDING_LOOKUP_TOP1 (Pod 3.5; FP-compute composite;
                            ; 256 × cosine internal + 256 × MAC verify; D3.17 anticipated-worst-case
                            ; static cost; D3.24 substrate budget scaled to 1M to accommodate;
                            ; demos may forge sub-caps for lineage tracking but dispatch is r14-bound)
    dq 500                  ; 0xCA — OP_EMBEDDING_ADD (Pod 3.6; SEAL-calibrated; B25/B26 empirical: ~503j matches; 384 mulss + 384 addss + forge + MAC + tuple write)
    dq 500                  ; 0xCB — OP_EMBEDDING_SUBTRACT (Pod 3.6; SEAL-calibrated; B27/B28 empirical: ~503j matches; same shape as ADD with subss)
    dq 500                  ; 0xCC — OP_EMBEDDING_SCALE (Pod 3.6; SEAL-calibrated; B29-B31 empirical: ~489j matches; 384 mulss + scalar broadcast + forge + MAC)
    dq 700                  ; 0xCD — OP_EMBEDDING_NORMALIZE (Pod 3.6; SEAL-calibrated; B32 empirical: ~699j matches; sum_sq + sqrt + 384 divss + forge + MAC; Form A per D3.14)
    dq 800                  ; 0xCE — OP_EMBEDDING_LERP (Pod 3.6; SEAL-calibrated; B34 empirical: ~804j matches; (1-t) precompute + 768 mulss + 384 addss + forge + MAC; Form A endpoint-byte-exact)
    dq 1                    ; 0xCF — OP_EMBEDDING_SYNTHESIS_HANDLE (Pod 3.6; witness; metabolic minimum; lookup + side-table read per D3.26; mirrors 0xC5 cost shape)
; Row 0xD0–0xDF — Energy opcodes (Pod 1.8) + Pod 1.8.5c 0xD4/0xD5 + Pod 1.10.2b2 accessors at 0xD6-0xD8
    dq 10                   ; 0xD0 — OP_ENERGY_NEW
    dq 1                    ; 0xD1 — OP_ENERGY_JOULES (accessor)
    dq 1                    ; 0xD2 — OP_ENERGY_SOURCE_OP (accessor)
    dq 0                    ; 0xD3 — OP_ENERGY_FREE (V1.0 no-op)
    dq 1                    ; 0xD4 — OP_ENERGY_RECOVER (Pod 1.8.5c Move 6, V1.0 no-op-with-log)
    dq 0                    ; 0xD5 — OP_PHASE_QUERY (Pod 1.8.5c Move 7, structural — 0j like HALT/RESERVE)
    dq 0                    ; 0xD6 — OP_ENERGY_ARENA (Pod 1.10.2b2; structural; no MAC verify per D1.10.2b2.5)
    dq 0                    ; 0xD7 — OP_ENERGY_OWNER (Pod 1.10.2b2; structural)
    dq 0                    ; 0xD8 — OP_ENERGY_CREATOR (Pod 1.10.2b2; structural)
    dq 1, 1, 1, 1, 1       ; 0xD9–0xDD — reserved
    dq 1, 1                 ; 0xDE–0xDF — reserved
; Row 0xE0–0xEF — Outcome opcodes (Pod 1.9.2b at 0xE0-0xE4 + Pod 1.10.2b2 accessors at 0xE5-0xE7) + Demod reserved (Pod 1.12 at 0xE8-0xEF)
    dq 1                    ; 0xE0 — OP_OUTCOME_NEW_OK (metabolic construction; A3 ratification)
    dq 1                    ; 0xE1 — OP_OUTCOME_NEW_ERR (metabolic construction; A3 ratification)
    dq 0                    ; 0xE2 — OP_OUTCOME_IS_OK (structural read; A3 ratification)
    dq 0                    ; 0xE3 — OP_OUTCOME_UNWRAP_OK (structural; diagnostic emit on err is structural side effect)
    dq 0                    ; 0xE4 — OP_OUTCOME_UNWRAP_ERR (structural; diagnostic emit on ok is structural side effect)
    dq 0                    ; 0xE5 — OP_OUTCOME_ARENA (Pod 1.10.2b2; structural; no MAC verify per D1.10.2b2.5)
    dq 0                    ; 0xE6 — OP_OUTCOME_OWNER (Pod 1.10.2b2; structural)
    dq 0                    ; 0xE7 — OP_OUTCOME_CREATOR (Pod 1.10.2b2; structural)
    dq 1, 1                 ; 0xE8–0xE9 — reserved (Demod Pod 1.12)
    dq 1, 1, 1, 1, 1       ; 0xEA–0xEE — reserved (Demod Pod 1.12)
    dq 1                    ; 0xEF — reserved (Demod Pod 1.12)
; Row 0xF0–0xFF — Pod 3.8/3.9/3.10/3.11 embedding-tier extensions (D3.32 / D3.34 / D3.38 / D3.42)
    dq 100000               ; 0xF0 — OP_EMBEDDING_IMPORT (Pod 3.8 D3.32; forge-tier; deferred handler per #91; cost reserved for runtime activation; matches OP_EMBEDDING_NEW shape with codebook-block source instead of operand-stack-vector source)
    dq 1                    ; 0xF1 — OP_EMBEDDING_IMPORTED_HANDLE (Pod 3.8 D3.13 witness; lookup + side-table read; mirrors 0xC5/0xCF cost shape per witness-op convention)
    dq 100000               ; 0xF2 — OP_EMBEDDING_LOOKUP_TOP_K (Pod 3.9 D3.35; recognition; matches lookup_top1 D3.17 anticipated-worst-case continuity; pool-bounded scan dominates cost; K-tracking marginal vs single-best-tracking)
    dq 1500                 ; 0xF3 — OP_EMBEDDING_PROJECT (Pod 3.10 D3.38; compound geometric op; ~2300 ops = 384 mulss + 384 addss × 2 dot loops + divss + 384 mulss scale; above synthesis tier 500-800j per Q6 ratification reflecting compound nature, below recognition tier 100,000j as not pool-bounded)
    dq 1500                 ; 0xF4 — OP_EMBEDDING_REJECT (Pod 3.10 D3.38; parity pricing per Q6 — reject's marginal +384 subss over project doesn't justify pricing-decision overhead; round-number aesthetic; project-reject duality preserves uniform-cost composability)
    dq 1                    ; 0xF5 — OP_EMBEDDING_CODEBOOK_META (Pod 3.11 D3.42; witness; substrate-private singleton-state accessor; matches 0xCF SYNTHESIS_HANDLE / 0xF1 IMPORTED_HANDLE per D3.13)
    dq 1, 1, 1, 1          ; 0xF6–0xF9 — reserved for embedding-tier extensions (D3.34)
    dq 1, 1, 1, 1, 1       ; 0xFA–0xFE — reserved for embedding-tier extensions
    dq 0                    ; 0xFF — OP_HALT (termination, free)
