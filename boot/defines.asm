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
