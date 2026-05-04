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
%define TEXT_RAWSZ   0x100000      ; 64KB for code+VM+programs
%define TEXT_VSZ     0x100000

%define RELOC_RVA    0x101000
%define RELOC_RAW    0x100200
%define RELOC_RAWSZ  0x200
%define RELOC_VSZ    0x200
%define IMAGE_SZ     0x102000

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

; --- Energy opcodes (Pod 1.8) ---
%define OP_ENERGY_NEW       0xD0
%define OP_ENERGY_JOULES    0xD1
%define OP_ENERGY_SOURCE_OP 0xD2
%define OP_ENERGY_FREE      0xD3

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

; --- Pod 1.9.3 — err_code values for typed error paths ---
; Code 0 reserved for "no err / uninitialized" (parallels TYPE_CODE_NONE).
%define ERR_INVALID_ID         1   ; registry_lookup_* returned 0 (id=0 or not in registry)
%define ERR_POOL_FULL          2   ; *_alloc returned 0 (pool at capacity)
%define ERR_STACK_UNDERFLOW    3   ; OP_RET on empty return stack (Pod 1.3 str_ret_underflow → typed)
%define ERR_STACK_OVERFLOW     4   ; OP_CALL on full return stack (Pod 1.3 str_call_overflow → typed)
%define ERR_INVALID_SIGN_ARG   5   ; OP_SIGN_NEW invalid label length / non-zero embedding_handle
%define ERR_INVALID_ENERGY_ARG 6   ; OP_ENERGY_NEW invalid joules/source_op (defined; unused V1.0 per A3)

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

; --- Energy struct layout (Pod 1.8) ---
%define ENERGY_OFF_JOULES    0x00
%define ENERGY_OFF_SOURCE_OP 0x08
%define ENERGY_SLOT_SIZE     0x80   ; 128 bytes
%define ENERGY_POOL_SLOTS    64

; --- Outcome struct layout (Pod 1.9.2a; D1.9.1.5 inline error context) ---
%define OUTCOME_SLOT_SIZE    0x80   ; 128 bytes
%define OUTCOME_POOL_SLOTS   64

; --- Canonical ID types (Pod 1.8.5b — Move 4) ---
; All canonical IDs are u64. ID 0 is reserved as null/invalid.
; sign_id and energy_id are retrofitted in this pod and now flow
; through registry indirection (boot/registry.asm) rather than
; mapping directly to slot indices.
; cap_id, demod_id, signal_id are reserved as types here; their
; primitives don't exist yet — Pod 1.10 (Cap), Pod 1.12 (Demod),
; Pod 4 (Interpreter) inherit the registry pattern when they land.
%define SIGN_ID_NULL    0
%define ENERGY_ID_NULL  0
%define CAP_ID_NULL     0
%define DEMOD_ID_NULL   0
%define SIGNAL_ID_NULL  0
%define OUTCOME_ID_NULL 0   ; Pod 1.9.2a — Outcome canonical-ID null sentinel

; --- Pod 1.9.2a — Outcome value_type_id codes (D1.9.1.1) ---
; Discriminant naming which canonical-ID type the success branch of
; an Outcome wraps. Code 0 (TYPE_CODE_NONE) is sentinel — an Outcome
; with this code is uninitialized and may be flagged by audit.
; Codes 1-6 are stable; 7+ reserved for future canonical-ID types.
%define TYPE_CODE_NONE     0
%define TYPE_CODE_SIGN     1
%define TYPE_CODE_ENERGY   2
%define TYPE_CODE_CAP      3   ; reserved for Pod 1.10
%define TYPE_CODE_DEMOD    4   ; reserved for Pod 1.12
%define TYPE_CODE_SIGNAL   5   ; reserved for Pod 4
%define TYPE_CODE_OUTCOME  6   ; reserved for Outcome wrapping Outcome
