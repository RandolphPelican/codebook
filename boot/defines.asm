; =============================================================
; CodebookOS — Global Defines
; UEFI offsets, PE layout, colors, CBS VM opcodes
; Extracted from boot.asm (Pod 0.1)
; =============================================================

%define FILE_ALIGN   0x200
%define SECT_ALIGN   0x1000
%define IMAGE_BASE   0x100000
%define HEADER_SZ    0x200

%define TEXT_RVA     0x1000
%define TEXT_RAW     0x200
%define TEXT_RAWSZ   0x500000      ; Pod 3.7 D3.29 — expanded from 0x100000 to accommodate ~3.4MB BSS growth (vm_embedding_pool 256→2048, vm_outcome_pool 64→4096, side-tables cascade); 5MB total budget for code+VM+programs+BSS
%define TEXT_VSZ     0x500000

%define RELOC_RVA    0x501000      ; Pod 3.7: shifted by TEXT_RAWSZ delta (0x101000 → 0x501000)
%define RELOC_RAW    0x500200      ; Pod 3.7: shifted (0x100200 → 0x500200)
%define RELOC_RAWSZ  0x200
%define RELOC_VSZ    0x200
%define IMAGE_SZ     0x502000      ; Pod 3.7: shifted (0x102000 → 0x502000)

%define ST_CONIN     0x30
%define ST_CONOUT    0x40
%define ST_RUNTIME   0x58
%define ST_BOOTSERV  0x60
%define CONOUT_OUTPUTSTR 0x08
%define CONOUT_CLEARSCR  0x30
%define CONIN_READKEY    0x08
%define CONIN_WAITKEY    0x10
%define BS_GETMEMMAP     0x38
%define BS_WAITFOREVENT  0x60
%define BS_EXITBOOTSERV  0xE8
%define BS_STALL         0xF8
%define BS_SETWATCHDOG   0x100
%define BS_LOCATEPROTOCOL 0x140
%define RS_RESETSYSTEM   0x68
%define GOP_MODE         0x18
%define GOPMODE_FBBASE   0x18
%define GOPMODE_FBSIZE   0x20
%define GOPMODE_INFO     0x08
%define GOPINFO_HRES     0x04
%define GOPINFO_VRES     0x08
%define GOPINFO_PIXFMT   0x0C
%define GOPINFO_PPSL     0x20

%define COLOR_GOLD   0x00FFD700
%define COLOR_BLACK  0x00000000
%define COLOR_WHITE  0x00FFFFFF
%define COLOR_RED    0x00FF0000
%define COLOR_GREEN  0x0000FF00
%define COLOR_BLUE   0x000000FF
%define COLOR_CYAN   0x0000FFFF

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

; --- Sign opcodes (Pod 1.7) ---
%define OP_SIGN_NEW    0xA0
%define OP_SIGN_HASH   0xA1
%define OP_SIGN_LABEL  0xA2
%define OP_SIGN_ENERGY 0xA3
; Pod 1.10.2b2 — Sign provenance accessors
%define OP_SIGN_ARENA    0xA4   ; pop sign_id, push Outcome<arena_id>
%define OP_SIGN_OWNER    0xA5   ; pop sign_id, push Outcome<owner_demod_id>
%define OP_SIGN_CREATOR  0xA6   ; pop sign_id, push Outcome<creator_cap_id>
%define OP_SIGN_EMBEDDING_HANDLE 0xA7   ; Pod 3 — pop sign_id, validate, push Outcome<embedding_handle> from side-table per D3.4

; --- Energy opcodes (Pod 1.8) ---
%define OP_ENERGY_NEW       0xD0
%define OP_ENERGY_JOULES    0xD1
%define OP_ENERGY_SOURCE_OP 0xD2
%define OP_ENERGY_FREE      0xD3
; Pod 1.10.2b2 — Energy provenance accessors
%define OP_ENERGY_ARENA    0xD6   ; pop energy_id, push Outcome<arena_id>
%define OP_ENERGY_OWNER    0xD7   ; pop energy_id, push Outcome<owner_demod_id>
%define OP_ENERGY_CREATOR  0xD8   ; pop energy_id, push Outcome<creator_cap_id>

; --- Pod 1.8.5c Move 6: OP_ENERGY_RECOVER (V1.0 no-op-with-log) ---
%define OP_ENERGY_RECOVER   0xD4

; --- Pod 1.8.5c Move 7: OP_PHASE_QUERY (reads vm_phase to operand stack) ---
%define OP_PHASE_QUERY      0xD5

; --- Pod 1.9.2b Outcome opcodes (D1.9.1.4) ---
%define OP_OUTCOME_NEW_OK     0xE0
%define OP_OUTCOME_NEW_ERR    0xE1
%define OP_OUTCOME_IS_OK      0xE2
%define OP_OUTCOME_UNWRAP_OK  0xE3
%define OP_OUTCOME_UNWRAP_ERR 0xE4
; Pod 1.10.2b2 — Outcome provenance accessors
%define OP_OUTCOME_ARENA    0xE5   ; pop outcome_id, push Outcome<arena_id>
%define OP_OUTCOME_OWNER    0xE6   ; pop outcome_id, push Outcome<owner_demod_id>
%define OP_OUTCOME_CREATOR  0xE7   ; pop outcome_id, push Outcome<creator_cap_id>

; --- Pod 1.9.3 — err_code values for typed error paths ---
; Code 0 reserved for "no err / uninitialized" (parallels TYPE_CODE_NONE).
%define ERR_INVALID_ID               1   ; registry_lookup_* returned 0 (id=0 or not in registry)
%define ERR_POOL_FULL                2   ; *_alloc returned 0 (pool at capacity)
%define ERR_STACK_UNDERFLOW          3   ; OP_RET on empty return stack (Pod 1.3 str_ret_underflow → typed)
%define ERR_STACK_OVERFLOW           4   ; OP_CALL on full return stack (Pod 1.3 str_call_overflow → typed)
%define ERR_INVALID_SIGN_ARG         5   ; OP_SIGN_NEW invalid label length / non-zero embedding_handle
%define ERR_INVALID_ENERGY_ARG       6   ; OP_ENERGY_NEW invalid joules/source_op (defined; unused V1.0 per A3)
%define ERR_CAP_AUTHORITY_EXCEEDED      7   ; OP_CAP_NEW subset-on-grant violation: granted_bitmap exceeds parent cap's bitmap (Pod 1.10.2a forward-anchor; activated Pod 2.2 per D2.2.5)
%define ERR_CAP_INSUFFICIENT_AUTHORITY  8   ; Bit-check failure at primitive-forge dispatch site: current_cap's bitmap lacks required BIT_*_FORGE (Pod 2.2 per D2.2.6)
%define ERR_INVALID_EMBEDDING_ARG       9   ; Pod 3 — OP_EMBEDDING_NEW invalid vector_addr / OP_EMBEDDING_GET_DIM dim_index out-of-bounds (>=384)

; --- Pod 1.10.2a Cap opcode constants (D1.10.1.2 / D1.10.1.3) ---
; Cross-asset constants verification per D1.9.2b.10: opcode constants
; land at substrate-plumbing pod (here), not handler pod (1.10.2b).
; Pod 1.10.2b1 supersession: OP_CAP_CHECK retired; three accessors
; (ARENA, OWNER, RESOURCE) ship instead per D1.10.2b1.1 bouncer-to-
; fingerprint reframe.
; Pod 2.2 supersession: OP_CAP_RESOURCE retires (D2.2.4); cap_bitmap
; structured semantics replace resource_descriptor placeholder.
; OP_CAP_BITMAP at 0xBA reads the same byte position with structured
; bit-vocabulary interpretation per D2.2.1.
%define OP_CAP_NEW       0xB0
%define OP_CAP_ENTER     0xB1
%define OP_CAP_EXIT      0xB2
%define OP_CAP_CURRENT   0xB3
%define OP_CAP_ARENA     0xB4   ; Pod 1.10.2b1 — pop cap_id, MAC verify, push Outcome<arena_id>
%define OP_CAP_OWNER     0xB5   ; Pod 1.10.2b1 — pop cap_id, MAC verify, push Outcome<owner_demod_id>
; 0xB6 retired (was OP_CAP_RESOURCE; replaced by OP_CAP_BITMAP at 0xBA per D2.2.4)
%define OP_CAP_PARENT    0xB7   ; Pod 1.10.2b2 — pop cap_id, MAC verify, push Outcome<parent_cap_id>
; Pod 1.10.3 — Cap metabolic accessors
%define OP_CAP_BUDGET    0xB8   ; pop cap_id, MAC verify, push Outcome<energy_budget>
%define OP_CAP_USED      0xB9   ; pop cap_id, MAC verify, push Outcome<energy_used>
; Pod 2.2 — Cap texture accessor
%define OP_CAP_BITMAP    0xBA   ; pop cap_id, MAC verify, push Outcome<cap_bitmap> per D2.2.1

; --- Pod 3 Embedding opcodes (D3.1; range 0xC0-0xCF allocated) ---
; Fifth typed primitive joins Sign/Energy/Outcome/Cap. Substrate-prep mode:
; ship the typed pool + accessors + forge bit; semantic operations
; (similarity, lookup-by-meaning, codebook ingestion) deferred to Pod 3.5+.
; 0xC5-0xCF reserved for Pod 3.5+ semantic ops.
%define OP_EMBEDDING_NEW       0xC0   ; pop vector_addr, push Outcome<embedding_id>
%define OP_EMBEDDING_ARENA     0xC1   ; pop embedding_id, MAC verify, push Outcome<arena_id>
%define OP_EMBEDDING_OWNER     0xC2   ; pop embedding_id, MAC verify, push Outcome<owner_demod_id>
%define OP_EMBEDDING_CREATOR   0xC3   ; pop embedding_id, MAC verify, push Outcome<creator_cap_id>
%define OP_EMBEDDING_GET_DIM   0xC4   ; pop embedding_id + dim_index, MAC verify, bounds-check, push Outcome<f32-bit-cast-as-i64>

; --- Pod 3.5 Embedding semantic operations (D3.12-D3.22) ---
; Witness doctrine generalizes from accessors to compute (D3.13):
; cosine/dot/L2/lookup execute regardless of current_cap's bitmap.
; FP determinism doctrine (D3.12): SSE scalar single-precision only.
; Cosine canonical Form A (D3.14): separate sqrts; bit-exact reproducibility.
%define OP_EMBEDDING_SIGN_HANDLE  0xC5   ; Pod 3.5 — pop embedding_id, validate, push Outcome<sign_id> from reverse side-table per D3.20
%define OP_EMBEDDING_COSINE       0xC6   ; Pod 3.5 — pop two embedding_ids, MAC verify both, push Outcome<f32-as-i64> per D3.14
%define OP_EMBEDDING_DOT_PRODUCT  0xC7   ; Pod 3.5 — pop two embedding_ids, MAC verify both, push Outcome<f32-as-i64>
%define OP_EMBEDDING_L2_DISTANCE  0xC8   ; Pod 3.5 — pop two embedding_ids, MAC verify both, push Outcome<f32-as-i64>
%define OP_EMBEDDING_LOOKUP_TOP1  0xC9   ; Pod 3.5 — pop query embedding_id, MAC verify, scan pool with per-candidate MAC verify, push Outcome<best_match_embedding_id> per D3.18

; --- Pod 3.6 Embedding synthesis operations (D3.25-D3.28) ---
; Forge-tier compute: each op (0xCA-0xCE) creates a new typed Embedding from
; existing ones, gated by BIT_EMBEDDING_FORGE (R9 inheritance — no new bit).
; Synthesis lineage tracked via D3.20-generalized non-MAC parallel side-table
; vm_embedding_synthesis (Layout 2 quad-tuple per D3.27). Witness accessor
; 0xCF reads synthesis lineage without forge bit (D3.13 inheritance).
; D3.25 frames Maid as lexical-computation pole: housekeeper plus composer.
; D3.28 codifies the FP-precision-prediction discipline surfaced empirically
; at HALT 1 R10 (normalize v_uniform 25-ulp drift; lerp irrational-t asymmetric).
%define OP_EMBEDDING_ADD              0xCA   ; Pod 3.6 — pop two embedding_ids, MAC verify both, forge result = a + b, write synthesis tuple, push Outcome<embedding_id>
%define OP_EMBEDDING_SUBTRACT         0xCB   ; Pod 3.6 — pop two embedding_ids, MAC verify both, forge result = a - b, write synthesis tuple, push Outcome<embedding_id>
%define OP_EMBEDDING_SCALE            0xCC   ; Pod 3.6 — pop embedding_id + scalar (f32-as-i64), MAC verify, forge result = scalar * a, write synthesis tuple
%define OP_EMBEDDING_NORMALIZE        0xCD   ; Pod 3.6 — pop embedding_id, MAC verify, forge result = a / |a| (Form A), zero-norm rejection per D3.14 precedent
%define OP_EMBEDDING_LERP             0xCE   ; Pod 3.6 — pop two embedding_ids + t (f32-as-i64), MAC verify both, forge result = (1-t)*a + t*b (Form A)
%define OP_EMBEDDING_SYNTHESIS_HANDLE 0xCF   ; Pod 3.6 — pop embedding_id, validate, push Outcome<synthesis_tuple_qword_0>; full tuple via further ops if needed

; Pod 3.6 — synthesis source-op codes (D3.27 quad-tuple op field)
; BSS-zero default = SYNTHESIS_OP_NONE; non-synthesized embeddings register as 0
; in vm_embedding_synthesis by construction (Sign-forged, raw OP_EMBEDDING_NEW).
%define SYNTHESIS_OP_NONE       0x00
%define SYNTHESIS_OP_ADD        0x01
%define SYNTHESIS_OP_SUBTRACT   0x02
%define SYNTHESIS_OP_SCALE      0x03
%define SYNTHESIS_OP_NORMALIZE  0x04
%define SYNTHESIS_OP_LERP       0x05
%define SYNTHESIS_OP_PROJECT    0x06   ; Pod 3.10 D3.38 — A's component along B's direction
%define SYNTHESIS_OP_REJECT     0x07   ; Pod 3.10 D3.38 — A's component orthogonal to B
; 0x08-0xFF reserved for Pod 3.11+ synthesis-op extensions

; Pod 3.6 — synthesis tuple Layout 2 quad-tuple (D3.27)
;   32 bytes per slot (16-byte aligned for SSE-friendly scalar field access).
;   op (qword) | source_a (qword) | source_b (qword) | scalar (qword; f32-as-i64)
;   Per-op shapes:
;     ADD/SUBTRACT: source_a=a_id, source_b=b_id, scalar=0
;     SCALE:        source_a=a_id, source_b=scalar (f32-as-i64), scalar=0
;     NORMALIZE:    source_a=a_id, source_b=0, scalar=0
;     LERP:         source_a=a_id, source_b=b_id, scalar=t (f32-as-i64)
;   Layout 2 chosen at Phase 1.1 to avoid mid-pod migration when ternary lerp
;   lands at Phase 3.1 (D3.27); one write convention across all five forge ops.
%define SYNTHESIS_TUPLE_BYTES         32
%define SYNTHESIS_TUPLE_OFF_OP        0
%define SYNTHESIS_TUPLE_OFF_SOURCE_A  8
%define SYNTHESIS_TUPLE_OFF_SOURCE_B  16
%define SYNTHESIS_TUPLE_OFF_SCALAR    24

; Pod 3.6 — Phase 3.2 synthesis tuple field index for OP_EMBEDDING_SYNTHESIS_HANDLE (0xCF)
; GET_DIM-style parameterized accessor; field_index in 0..3 selects which qword
; of the 4-qword tuple to read. Out-of-range → ERR_INVALID_EMBEDDING_ARG.
%define SYNTHESIS_FIELD_OP            0
%define SYNTHESIS_FIELD_SOURCE_A      1
%define SYNTHESIS_FIELD_SOURCE_B      2
%define SYNTHESIS_FIELD_SCALAR        3

; --- Pod 3.8 codebook-tier opcodes (D3.31; Q5 0xF0–0xFE row allocation) ---
; OP_EMBEDDING_IMPORT (0xF0): pop codebook_id + line_index, forge new
;   embedding from codebook block; bit-check BIT_EMBEDDING_FORGE; write
;   imported provenance tuple. Forge-class authority shared with synthesis
;   ops per D3.X (no new bit; FORGE reused).
; OP_EMBEDDING_IMPORTED_HANDLE (0xF1): GET_DIM-style witness accessor;
;   pop embedding_id + field_index (0..3), read imported tuple field.
; 0xF2-0xFE reserved for codebook-tier extensions (multi-codebook, codebook
;   metadata accessors, etc.) at Pod 3.9+.
%define OP_EMBEDDING_IMPORT          0xF0
%define OP_EMBEDDING_IMPORTED_HANDLE 0xF1

; --- Pod 3.9 Maid finds many: top-K + threshold (D3.35; 0xF2 in embedding-tier-extensions row) ---
; OP_EMBEDDING_LOOKUP_TOP_K (0xF2): pop query_id + K + threshold (f32-as-i64);
;   substrate scans embedding pool, returns ≤K best-cosine matches above threshold;
;   pushes K' embedding_ids (descending cosine order; best at top), then K' count last.
;   Threshold = -INF sentinel (0xFF800000 f32 bit pattern) for unfiltered top-K.
;   Static cost: 100,000j matching D3.17 lookup_top1 anticipated-worst-case.
;   Witness op (D3.13): no bit-check; recognition surface, not forge.
%define OP_EMBEDDING_LOOKUP_TOP_K    0xF2

; --- Pod 3.10 Maid orthogonalizes: project + reject (D3.38; 0xF3/0xF4 in embedding-tier-extensions row) ---
; OP_EMBEDDING_PROJECT (0xF3): pop A_id + B_id (B at TOS); MAC verify both;
;   forge result = (A·B / B·B) * B (Form A direct divss per D3.14 / D3.40); zero-norm
;   rejection on dot(B,B)==0 returns Err(InvalidEmbeddingArg) per D3.40 hybrid; tuple
;   write op=SYNTHESIS_OP_PROJECT=0x06, source_a=A_id, source_b=B_id, scalar=0 per D3.39.
;   Static cost: 1500j (compound geometric op tier; above synthesis 500-800j; below recognition).
; OP_EMBEDDING_REJECT (0xF4): same shape; result = A - project(A,B); single-pass per-element
;   subss(a[d], mulss(ratio, b[d])); same zero-norm rejection; tuple op=0x07.
%define OP_EMBEDDING_PROJECT         0xF3
%define OP_EMBEDDING_REJECT          0xF4

; --- Pod 3.11 Maid maintains: codebook metadata accessor (D3.42; 0xF5 in embedding-tier-extensions row) ---
; OP_EMBEDDING_CODEBOOK_META (0xF5): pop field_index (0..3); read qword at
;   vm_codebook_meta + field_index*8; wrap as Outcome::Ok. Substrate-private
;   singleton state (no embedding_id; no registry lookup; no MAC verify).
;   Static cost: 1j (D3.13 witness-tier metabolic minimum).
;   V1.0 single-codebook; codebook_id parameter deferred to #91 multi-codebook activation.
;   Field-index ∈ [0, 3]: 0=count, 1=dim, 2=scalar_type, 3=ingestion_status (per CBK_META_OFF_*).
;   Out-of-range field_index → Err(InvalidEmbeddingArg).
%define OP_EMBEDDING_CODEBOOK_META   0xF5

; Pod 3.11 — codebook META field indices (D3.42; user-surface field-id constants
; for OP_EMBEDDING_CODEBOOK_META; mirror CBK_META_OFF_* / 8 offset mapping)
%define META_FIELD_COUNT             0
%define META_FIELD_DIM               1
%define META_FIELD_SCALAR_TYPE       2
%define META_FIELD_INGESTION_STATUS  3

; --- Pod 3.9 top-K scratch sizing (D3.X axis-2 mechanical sizing applies) ---
; MAX_K bounds the top-K result count + sizes the BSS scratch arrays
; (top_k_scratch_ids: MAX_K × 8 = 2048 bytes; top_k_scratch_scores: MAX_K × 4 = 1024 bytes).
; Production scenarios typically K ≤ 32; MAX_K = 256 matches embedding-pool-Pod-3-cap
; era for headroom. Operand-stack capacity = vm_stack 512 qwords; K' = 256 fills half.
%define MAX_K                        256

; --- Pod 3.8 imported provenance tuple (D3.27 Layout-2 mirror) ---
; 32-byte quad-tuple at vm_embedding_imported[(embedding_id - 1) * 32].
; Same shape as vm_embedding_synthesis; mechanical Layout-2 inheritance.
%define IMPORTED_TUPLE_BYTES                  32
%define IMPORTED_TUPLE_OFF_CODEBOOK_ID        0
%define IMPORTED_TUPLE_OFF_LINE_INDEX         8
%define IMPORTED_TUPLE_OFF_RESERVED_HASH      16
%define IMPORTED_TUPLE_OFF_RESERVED_TIMESTAMP 24

; --- Pod 3.8 imported tuple field index for OP_EMBEDDING_IMPORTED_HANDLE ---
; Mirrors SYNTHESIS_FIELD_* shape. field_index 0..3 selects qword to read.
; Out-of-range → ERR_INVALID_EMBEDDING_ARG.
%define IMPORTED_FIELD_CODEBOOK_ID          0
%define IMPORTED_FIELD_LINE_INDEX           1
%define IMPORTED_FIELD_RESERVED_HASH        2
%define IMPORTED_FIELD_RESERVED_TIMESTAMP   3

; --- Pod 3.8 CBKBOK01 codebook image header layout ---
; 64-byte fixed header followed by contiguous f32 vector block.
; Build-tool tools/codebook_builder.py emits this format.
%define CBK_HEADER_BYTES                    64
%define CBK_HEADER_OFF_MAGIC                0    ; "CBKBOK01" 8 ASCII bytes
%define CBK_HEADER_OFF_COUNT                8    ; u64
%define CBK_HEADER_OFF_DIM                  16   ; u64
%define CBK_HEADER_OFF_SCALAR_TYPE          24   ; u32 (low 32 of qword)
%define CBK_HEADER_OFF_RESERVED1            28   ; u32 reserved
%define CBK_HEADER_OFF_VECTOR_BLOCK_OFFSET  32   ; u64
%define CBK_HEADER_OFF_VECTOR_BLOCK_BYTES   40   ; u64
%define CBK_HEADER_OFF_PAYLOAD_HASH         48   ; 16 bytes SHA-256-truncated

; --- Pod 3.8 CBKBOK01 magic comparator ---
; "CBKBOK01" ASCII = 0x43 0x42 0x4B 0x42 0x4F 0x4B 0x30 0x31
; Little-endian u64: byte 0 -> bits[7:0], byte 7 -> bits[63:56]
;   = 0x31 << 56 | 0x30 << 48 | 0x4B << 40 | 0x4F << 32 | 0x42 << 24 | 0x4B << 16 | 0x42 << 8 | 0x43
;   = 0x31304B4F424B4243
%define CBK_MAGIC_QWORD              0x31304B4F424B4243

; --- Pod 3.8 codebook scalar type ---
%define CBK_SCALAR_TYPE_F32          0

; --- Pod 3.8 codebook ingestion status (vm_codebook_meta +0x18) ---
%define CBK_STATUS_NOT_RUN           0
%define CBK_STATUS_SUCCESS           1
%define CBK_STATUS_ERR_BAD_MAGIC     2
%define CBK_STATUS_ERR_BAD_DIM       3
%define CBK_STATUS_ERR_POOL_FULL     4
%define CBK_STATUS_ERR_OTHER         255

; --- Pod 3.8 vm_codebook_meta block field offsets ---
%define CBK_META_OFF_COUNT             0    ; qword: imports ingested at boot
%define CBK_META_OFF_DIM               8    ; qword: codebook dimensionality
%define CBK_META_OFF_SCALAR_TYPE       16   ; qword: 0=f32
%define CBK_META_OFF_INGESTION_STATUS  24   ; qword: CBK_STATUS_*
%define CBK_META_OFF_PAYLOAD_HASH      32   ; 16 bytes
%define CBK_META_OFF_RESERVED          48   ; 16 bytes future

; --- Pod 1.10.2a Cap pool / slot constants (D1.10.1.10) ---
; CAP_ID_NULL=0 already defined above in canonical-ID null-sentinel block (Pod 1.8.5b).
%define CAP_POOL_SLOTS   64
%define CAP_SLOT_SIZE    0x80   ; 128 bytes
%define ROOT_CAP_ID      1      ; reserved cap_id for substrate-bootstrap ROOT_CAP

; --- Pod 1.10.2a cap_stack constant (D1.10.1.4) ---
%define CAP_STACK_DEPTH  256    ; parallel to vm_ret_stack capacity

; --- Pod 1.10.2a Cap slot field offsets (D1.10.1.1) ---
%define CAP_OFF_CAP_ID_SELF        0x00
%define CAP_OFF_ARENA_ID           0x08
%define CAP_OFF_OWNER_DEMOD_ID     0x10
%define CAP_OFF_BITMAP             0x18   ; Pod 2.2 — was CAP_OFF_RESOURCE_DESC pre-2.2; same byte position, structured bit-vocabulary semantic per D2.2.1
%define CAP_OFF_PARENT_CAP_ID      0x20
%define CAP_OFF_GENERATION_COUNTER 0x28
; Pod 1.10.3 layout shift: energy_budget joins MAC-input range at +0x30;
; MAC moves from +0x30 to +0x38; energy_used (non-MAC, mutable) at +0x40.
%define CAP_OFF_ENERGY_BUDGET      0x30   ; Pod 1.10.3 — MAC-input, immutable identity component
%define CAP_OFF_MAC                0x38   ; was 0x30 pre-1.10.3
%define CAP_OFF_ENERGY_USED        0x40   ; Pod 1.10.3 — non-MAC, substrate-managed mutable state
%define CAP_MAC_INPUT_QWORDS       7   ; was 6 pre-1.10.3 — cap_id_self through energy_budget (56 bytes)
%define ENERGY_BUDGET_UNBOUNDED    0xFFFFFFFFFFFFFFFF   ; Pod 1.10.3 — ROOT_CAP and any future unbounded grants
%define CAP_BITMAP_UNBOUNDED       0xFFFFFFFFFFFFFFFF   ; Pod 2.2 — ROOT_CAP texture pole (parallel to ENERGY_BUDGET_UNBOUNDED metabolic pole; D2.2.3)

; --- Pod 2.2 cap_bitmap V1.0 forge-bit vocabulary (D2.2.2) ---
; Four forge bits mirroring authority-exercise opcode set. Bits 4-63
; reserved for organic vocabulary growth across future pods (surface
; bits, driver bits, network bits, etc.). Each new bit lands at decision-
; record time when its consumer earns it.
%define BIT_SIGN_FORGE       (1 << 0)   ; 0x01 — gates OP_SIGN_NEW dispatch
%define BIT_ENERGY_FORGE     (1 << 1)   ; 0x02 — gates OP_ENERGY_NEW dispatch
%define BIT_OUTCOME_FORGE    (1 << 2)   ; 0x04 — gates OP_OUTCOME_NEW_OK / OP_OUTCOME_NEW_ERR dispatch
%define BIT_CAP_FORGE        (1 << 3)   ; 0x08 — gates OP_CAP_NEW dispatch + delegation (clear on grant = leaf cap)
%define BIT_EMBEDDING_FORGE  (1 << 4)   ; 0x10 — Pod 3 — gates OP_EMBEDDING_NEW dispatch; first reserved-bit consumer per D2.2.2 / D3.X

; --- Pod 1.8.5c Move 7: vm_phase enum ---
; Boot sequence steps SEED → FORM → CHANNELS → MIND in V1.0.
; MODES is enum-reserved for Pod 5 (Surfaces); not written by V1.0 boot
; per architect call A2 (collapse). MODES becomes a real transition
; when surface-mode-switching machinery exists.
%define VM_PHASE_SEED      0
%define VM_PHASE_FORM      1
%define VM_PHASE_CHANNELS  2
%define VM_PHASE_MODES     3
%define VM_PHASE_MIND      4

; --- Pod 1.8.5c Move 2: ProvEvent struct (32 bytes, cache-aligned per A4) ---
;   +0x00: opcode (u8) + 7 bytes pad
;   +0x08: demod_id (u64)
;   +0x10: fetch_counter (u64)
;   +0x18: reserved (u64) — future timestamp / source / outcome bits
; Ring buffer: 4KB / 32B = 128 entries (power-of-2; mask 0x7F).
%define PROV_EVENT_SIZE     0x20
%define PROV_RING_ENTRIES   128
%define PROV_RING_MASK      0x7F
%define PROV_OFF_OPCODE     0x00
%define PROV_OFF_DEMOD_ID   0x08
%define PROV_OFF_FETCH_CTR  0x10
%define PROV_OFF_RESERVED   0x18

; --- Sign struct layout (Pod 1.7; constants added Pod 1.8.5b for Energy parity) ---
%define SIGN_SLOT_SIZE       0x80   ; 128 bytes
%define SIGN_POOL_SLOTS      64
%define SIGN_OFF_CREATOR_CAP_ID    0x68   ; Pod 1.10.2b2 — reclaimed from embedding_handle slot
                                          ; (V1.0-unused Pod 3+ placeholder); Pod 1.8.5c reclamation
                                          ; pattern continues (provenance_handle->arena_id, V1.1
                                          ; sentinel->owner_demod_id, embedding_handle->creator_cap_id);
                                          ; OP_SIGN_NEW preserves 5-arg ABI (still validates
                                          ; embedding_handle=0 then silently discards)

; --- Energy struct layout (Pod 1.8) ---
%define ENERGY_OFF_JOULES    0x00
%define ENERGY_OFF_SOURCE_OP 0x08
%define ENERGY_SLOT_SIZE     0x80   ; 128 bytes
%define ENERGY_POOL_SLOTS    64
%define ENERGY_OFF_CREATOR_CAP_ID  0x20   ; Pod 1.10.2b2 — first qword of former reserved zone

; --- Outcome struct layout (Pod 1.9.2a; D1.9.1.5 inline error context) ---
%define OUTCOME_SLOT_SIZE    0x80   ; 128 bytes
%define OUTCOME_POOL_SLOTS   4096   ; Pod 3.7 D3.29 — proportional coupling: OUTCOME_POOL_SLOTS >= 2 * EMBEDDING_POOL_SLOTS (#90 RESOLVED); 64 (Pod 1.9.2a) -> 4096
%define OUTCOME_OFF_CREATOR_CAP_ID 0x68   ; Pod 1.10.2b2 — last qword of former Pod 3+ reserved zone

; --- Pod 3 Embedding typed primitive (D3.1; substrate-prep mode) ---
; f32[384] vector substrate-prep matching Pod 1.7 Sign / Pod 1.8 Energy pacing.
; Slot is MAC-protected (full vector under SipHash; mutation goes detected).
;
; Embedding slot layout (1576 bytes / 197 qwords):
;   +0x000  embedding_id_self   (registry-assigned u64)
;   +0x008  arena_id            (strict delegation per Pod 1.10.2b1)
;   +0x010  owner_demod_id      (strict delegation)
;   +0x018  creator_cap_id      (provenance per Pod 1.10.2b2)
;   +0x020  vector[384]         (1536 bytes; offsets 0x020 through 0x61F)
;   +0x620  MAC                 (siphash over 196 qwords header+vector per D3.3)
;
; No mutable fields — embeddings are immutable post-construction (no analog
; to Cap.energy_used). Full vector under MAC ensures content integrity.
%define EMBEDDING_DIM               384
%define EMBEDDING_VECTOR_BYTES      1536    ; 384 * 4
%define EMBEDDING_SLOT_BYTES        1576    ; 197 qwords (header 4 + vector 192 + MAC 1)
%define EMBEDDING_SLOT_QWORDS       197
%define EMBEDDING_POOL_SLOTS        2048  ; Pod 3.7 D3.29 — production codebook scale (#83 RESOLVED); 256 (Pod 3.5) -> 2048; side-tables vm_embedding_sign_handle/vm_embedding_synthesis cascade automatically per shared-constant discipline
%define EMBEDDING_MAC_INPUT_QWORDS  196     ; header (4) + vector (192); MAC at +0x620
%define EMBEDDING_OFF_ID_SELF       0x000
%define EMBEDDING_OFF_ARENA_ID      0x008
%define EMBEDDING_OFF_OWNER_DEMOD_ID 0x010
%define EMBEDDING_OFF_CREATOR_CAP_ID 0x018
%define EMBEDDING_OFF_VECTOR        0x020
%define EMBEDDING_OFF_MAC           0x620

; --- Canonical ID types (Pod 1.8.5b — Move 4) ---
; All canonical IDs are u64. ID 0 is reserved as null/invalid.
; sign_id and energy_id are retrofitted in this pod and now flow
; through registry indirection (boot/registry.asm) rather than
; mapping directly to slot indices.
; cap_id, demod_id, signal_id are reserved as types here; their
; primitives don't exist yet — Pod 1.10 (Cap), Pod 1.12 (Demod),
; Pod 4 (Interpreter) inherit the registry pattern when they land.
%define SIGN_ID_NULL      0
%define ENERGY_ID_NULL    0
%define CAP_ID_NULL       0
%define DEMOD_ID_NULL     0
%define SIGNAL_ID_NULL    0
%define OUTCOME_ID_NULL   0   ; Pod 1.9.2a — Outcome canonical-ID null sentinel
%define EMBEDDING_ID_NULL 0   ; Pod 3 — Embedding canonical-ID null sentinel

; --- Pod 1.9.2a — Outcome value_type_id codes (D1.9.1.1) ---
; Discriminant naming which canonical-ID type the success branch of
; an Outcome wraps. Code 0 (TYPE_CODE_NONE) is sentinel — an Outcome
; with this code is uninitialized and may be flagged by audit.
; Codes 1-6 are stable; 7+ reserved for future canonical-ID types.
%define TYPE_CODE_NONE       0
%define TYPE_CODE_SIGN       1
%define TYPE_CODE_ENERGY     2
%define TYPE_CODE_CAP        3   ; reserved for Pod 1.10
%define TYPE_CODE_DEMOD      4   ; reserved for Pod 1.12
%define TYPE_CODE_SIGNAL     5   ; reserved for Pod 4
%define TYPE_CODE_OUTCOME    6   ; reserved for Outcome wrapping Outcome
%define TYPE_CODE_EMBEDDING  7   ; Pod 3 — fifth typed primitive (f32[384] vector substrate)
