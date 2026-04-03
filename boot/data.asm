; CBS DEMO PROGRAMS (raw bytecode)
; =============================================================

; Program table (0-indexed internally, user sees 1-4)
prog_table:
    dq cbs_demo              ; 0 = full CBS demo
    dq prog1                 ; run 1
    dq prog2                 ; run 2
    dq prog3                 ; run 3
    dq prog4                 ; run 4
    dq surface_hello         ; run 5
    dq surface_sched_stub    ; run 6
    dq surface_compiler_stub ; run 7
=======
; =============================================================
; CBS Surfaces as First-Class Tokens
; =============================================================
; All .cbc files in boot/ are pre-compiled from surfaces/ at build time.
; Compiler tools (lexer.py, parser.py, compiler.py) are DEV TOOLS ONLY.
; They are not shipped in the final image.

section .rodata
str_cbs_tools_doc:
    db "CBS compiler tools (lexer.py, parser.py, compiler.py) are dev-only.", 10
    db "Final image contains only pre-compiled .cbc files.", 10, 0

; =============================================================
; CBS DEMO PROGRAMS (raw bytecode)
; =============================================================

; Program table (0-indexed internally, user sees 1-4)
prog_table:
    dq cbs_demo              ; 0 = full CBS demo
    dq prog1                 ; run 1
    dq prog2                 ; run 2
    dq prog3                 ; run 3
    dq prog4                 ; run 4
    dq surface_hello         ; run 5
    dq surface_sched_stub    ; run 6
    dq surface_compiler_stub ; run 7=============================================================
; Static Data — String literals, tables, font, program buffers
; font_data: 8x8 bitmap font, 760 bytes (ASCII 0x20–0x7E)
; prog_table: embedded .cbc program index
; =============================================================

; =============================================================
; DATA
; =============================================================
uefi_data:  dq 0,0,0,0,0,0,0
gop_ptr:    dq 0
gop_mode_ptr: dq 0
fb_base:    dq 0
fb_size:    dq 0
fb_width:   dd 0
fb_height:  dd 0
fb_ppsl:    dd 0
fb_pixfmt:  dd 0
current_color: dd 0x00FFD700
bastian_sel:   dd 1
temp_size: dq 0
ascii_buf: times 256 db 0
atreyu_size:    dq 0
external_prog_buf: times 65536 db 0
cursor_x:   dd 0
cursor_y:   dd 0
input_buf:  times 128 db 0
key_data:   dd 0
event_index: dq 0
hex_buf:    times 20 db 0
dec_buf:    times 12 db 0
mmap_size:  dq 0
mmap_key:   dq 0
mmap_desc_sz: dd 0
mmap_desc_ver: dd 0
uefi_exited:  db 0

; FAT32 driver state — populated by fat32_init
fat32_partition_lba:       dq 0   ; absolute LBA of the FAT32 partition start
fat32_bytes_per_sector:    dw 512 ; BPB offset 0x0B (always 512 for this driver)
fat32_sectors_per_cluster: db 0   ; BPB offset 0x0D
fat32_reserved_sectors:    dw 0   ; BPB offset 0x0E
fat32_fat_count:           db 0   ; BPB offset 0x10
fat32_sectors_per_fat:     dd 0   ; BPB offset 0x24 (FAT32 field)
fat32_root_cluster:        dd 0   ; BPB offset 0x2C
fat32_data_start_lba:      dq 0   ; computed: partition_lba + reserved + fat_count*sectors_per_fat

; FAT32 driver scratch buffers
fat32_name83:     times 11 db 0   ; 11-byte space-padded 8.3 name for directory comparison
                  db 0            ; guard byte
fat32_sector_buf: times 512 db 0  ; MBR / VBR / directory sector workspace
fat32_fat_buf:    times 512 db 0  ; FAT sector workspace (kept separate from sector_buf)

sfsp_guid:
    dd 0x964e5b22
    dw 0x6459, 0x11d2
    db 0x8e,0x39,0x00,0xa0,0xc9,0x69,0x72,0x3b
sfsp_ptr: dq 0
root_ptr: dq 0
file_ptr: dq 0
filename_ucs2: times 256 dw 0
file_info_buf: times 512 db 0

gop_guid:
    dd 0x9042a9de
    dw 0x23dc, 0x4a38
    db 0x96,0xfb,0x7a,0xde,0xd0,0x80,0x51,0x6a

color_table:
    dd COLOR_RED, 0x000080FF, 0x0000FFFF, COLOR_GREEN
    dd COLOR_CYAN, COLOR_BLUE, 0x00800080, COLOR_WHITE

mtypes:
    dq mt0,mt1,mt2,mt3,mt4,mt5,mt6,mt7,mt8,mt9,mt10,mt11,mt12,mt13,mt14
mt0:  db 'Reserved  ',0
mt1:  db 'LdrCode   ',0
mt2:  db 'LdrData   ',0
mt3:  db 'BSCode    ',0
mt4:  db 'BSData    ',0
mt5:  db 'RSCode    ',0
mt6:  db 'RSData    ',0
mt7:  db 'Convent   ',0
mt8:  db 'Unusable  ',0
mt9:  db 'ACPIRecl  ',0
mt10: db 'ACPINVS   ',0
mt11: db 'MMIO      ',0
mt12: db 'MMIOPort  ',0
mt13: db 'PalCode   ',0
mt14: db 'Persist   ',0

; Commands
c_help:     db 'help',0
c_about:    db 'about',0
c_clear:    db 'clear',0
c_colors:   db 'colors',0
c_fb:       db 'fb',0
c_mem:      db 'mem',0
c_reboot:   db 'reboot',0
c_progs:    db 'programs',0
c_ls:        db 'ls',0
c_load:      db 'load ',0
c_exit:     db 'exit',0
c_home:     db 'home',0
p_run:      db 'run ',0
p_echo:     db 'echo ',0
p_peek:     db 'peek ',0
p_dump:     db 'dump ',0
p_fill:     db 'fill ',0
p_compile:  db 'compile ',0

; UCS-2
ucs_locating:
    dw 0x0D,0x0A
    db 'C',0,'o',0,'d',0,'e',0,'b',0,'o',0,'o',0,'k',0,'O',0,'S',0
    db ' ',0,'+',0,' ',0,'C',0,'B',0,'S',0,' ',0,'V',0,'M',0
    dw 0x0D,0x0A
    db 'L',0,'o',0,'c',0,'a',0,'t',0,'i',0,'n',0,'g',0,' ',0
    db 'G',0,'O',0,'P',0,'.',0,'.',0,'.',0
    dw 0x0D,0x0A,0x0000
ucs_gop_ok:
    db 'G',0,'O',0,'P',0,' ',0,'f',0,'o',0,'u',0,'n',0,'d',0,'.',0
    db ' ',0,'A',0,'u',0,'r',0,'y',0,'n',0,' ',0,'a',0,'w',0,'a',0,'k',0,'e',0,'.',0
    dw 0x0D,0x0A,0x0000
ucs_no_gop:
    db 'E',0,'R',0,'R',0,':',0,' ',0,'N',0,'o',0,' ',0,'G',0,'O',0,'P',0
    dw 0x0D,0x0A,0x0000

str_ls_err: db '  FS not available.',10,0
str_bh_pad:   db 10,10,10,10,10,0
str_bh_title: db '     C O D E B O O K  O S',10,10,0
str_bh_sub:   db '  Metabolic Computing -- StableTech Enterprises LLC',10,10,0
str_bh_menu:
    db '  1. Gmork Terminal',10
    db '  2. Atreyu Editor',10
    db '  3. Rockbiter System Stats',10
    db '  4. Run CBS Program',10,10,0
str_bh_prompt:     db 'Select [1-4]: ',0
str_bh_run_prompt: db 'Program [0-7]: ',0

str_nl:     db 10,0
str_sp:     db ' ',0
str_col:    db ': ',0
str_spad:   db 10,10,10,10,10,10,10,10,10,10,10,10,0
str_sname:  db '        RANDOLPH PELICAN III',10,0
str_spres:  db '              presents',10,0
str_stitle: db '         C O D E B O O K   O S',10,0
str_sphase: db '       Phase 1 + CBS VM',10,0
str_prompt: db 'gmork> ',0
str_unk:    db 'Unknown: ',0

str_banner:
    db '  CodebookOS Phase 1 -- Gmork Terminal',10
    db '  Randolph Pelican III',10
    db '  StableTech Enterprises LLC',10,10
    db '  UEFI x86_64 + CBS Bytecode VM',10
    db '  Type help.',10,10,0

str_help:
    db 'Gmork Terminal -- CodebookOS',10
    db '  help           commands',10
    db '  about          system info',10
    db '  clear          clear screen',10
    db '  ls             list root files',10
    db '  load <file>    load and run CBS',10
    db '  fb             framebuffer info',10
    db '  mem            memory map',10
    db '  colors         color bars',10
    db '  echo <text>    echo',10
    db '  peek <addr>    read memory',10
    db '  dump <addr>    hex dump',10
    db '  fill <hex>     fill screen',10
    db '  reboot         reset',10,
    db '  home           home screen',10
    db '  programs       list CBS demos',10
    db '  run <0-4>      execute CBS program',10
    db '                 0=full demo',10,10,0

str_about:
    db '  CodebookOS -- Bare Metal x86_64',10
    db '  UEFI Direct, Zero Dependencies',10
    db '  Pure NASM + CBS Bytecode VM',10
    db '  Author: Randolph Pelican III',10
    db '  StableTech Enterprises LLC',10,10,0

str_fb1:    db '  Framebuffer:',10,0
str_fb_b:   db '  Base: ',0
str_fb_r:   db '  Res:  ',0
str_bars_ok: db 'Color bars painted.',10,0
str_pk1:    db '  [',0
str_pk2:    db '] = ',0
str_fill_ok: db '  Filled.',10,0
str_reboot: db '  Rebooting...',10,0

str_mhdr:   db '  Type       PhysStart          Pages',10,0
str_mt_unk: db 'Type?',0
str_pg:     db ' pg',10,0
str_mtot:   db '  Total: ',0
str_ment:   db ' entries',10,0
str_mfail:  db '  GetMemoryMap failed.',10,0
str_ebs_fail: db '  ExitBootServices failed — halting.',10,0
str_gpu_warning: db 'Warning: Framebuffer not validated. Using GOP values.',10,0
str_paging_warning: db 'Warning: Failed to set up identity page tables. Using firmware tables.',10,0
str_paging_success: db 'Identity page tables installed successfully.',10,0
str_compile_success: db 'Compiled and ran successfully!',10,0
str_compile_error: db 'Compile or run failed.',10,0

; CBS VM strings
str_vm_start: db '  --- CBS VM executing ---',10,0
str_vm_halt:  db '  HALT',10,0
str_vm_ret:   db '  Return: ',0
str_vm_void:  db '(void)',10,0
str_vm_eu:    db '  Energy: ',0
str_vm_jr:    db 'j used, ',0
str_vm_jl:    db 'j remaining',10,0
str_vm_rsv:   db '  Reserve ',0
str_vm_jok:   db 'j: OK',10,0
str_vm_deg:   db '  DEGRADED: insufficient energy',10,0
str_vm_unk:   db '  Unknown opcode: ',0
str_run_bad:  db '  Usage: run <0-7>',10,0

str_prog_list:
    db '  CBS Demo Programs:',10
    db '  1  Hello            print greeting',10
    db '  2  Math             42 + 8 with energy',10
    db '  3  Loop             count 1 to 10',10
    db '  4  Fibonacci        fib(10) = 55',10
    db '  5  Hello Surface    hello CBS surface',10
    db '  6  Sched Stub       scheduler stub active',10
    db '  7  Compiler Stub    compiler stub active',10,10,0


; =============================================================
; CBS DEMO PROGRAMS (raw bytecode)
; =============================================================

; Program table (0-indexed internally, user sees 1-4)
prog_table:
    dq cbs_demo              ; 0 = full CBS demo
    dq prog1                 ; run 1
    dq prog2                 ; run 2
    dq prog3                 ; run 3
    dq prog4                 ; run 4
    dq surface_hello         ; run 5
    dq surface_sched_stub    ; run 6
    dq surface_compiler_stub ; run 7

; --- Program 1: Hello ---
; Prints "Hello CodebookOS!" char by char
prog1:
    db OP_RESERVE
    dd 100                  ; 100j
    ; H=72 e=101 l=108 l=108 o=111 ' '=32
    ; C=67 o=111 d=100 e=101 b=98 o=111 o=111 k=107
    ; O=79 S=83 !=33
    db OP_PUSH
    dd 72
    db OP_EMIT              ; H
    db OP_PUSH
    dd 101
    db OP_EMIT              ; e
    db OP_PUSH
    dd 108
    db OP_EMIT              ; l
    db OP_PUSH
    dd 108
    db OP_EMIT              ; l
    db OP_PUSH
    dd 111
    db OP_EMIT              ; o
    db OP_PUSH
    dd 32
    db OP_EMIT              ; ' '
    db OP_PUSH
    dd 67
    db OP_EMIT              ; C
    db OP_PUSH
    dd 111
    db OP_EMIT              ; o
    db OP_PUSH
    dd 100
    db OP_EMIT              ; d
    db OP_PUSH
    dd 101
    db OP_EMIT              ; e
    db OP_PUSH
    dd 98
    db OP_EMIT              ; b
    db OP_PUSH
    dd 111
    db OP_EMIT              ; o
    db OP_PUSH
    dd 111
    db OP_EMIT              ; o
    db OP_PUSH
    dd 107
    db OP_EMIT              ; k
    db OP_PUSH
    dd 79
    db OP_EMIT              ; O
    db OP_PUSH
    dd 83
    db OP_EMIT              ; S
    db OP_PUSH
    dd 33
    db OP_EMIT              ; !
    db OP_NEWLINE
    db OP_HALT

; --- Program 2: Math with energy ---
; reserve 300j, push 42, push 8, add, print result
prog2:
    db OP_RESERVE
    dd 300
    db OP_PUSH
    dd 42
    db OP_PUSH
    dd 8
    db OP_ADD
    db OP_PRINT_NUM         ; prints 50
    db OP_NEWLINE
    ; Now multiply: 50 is consumed, redo
    db OP_PUSH
    dd 6
    db OP_PUSH
    dd 7
    db OP_MUL
    db OP_PRINT_NUM         ; prints 42
    db OP_NEWLINE
    ; Subtraction
    db OP_PUSH
    dd 100
    db OP_PUSH
    dd 58
    db OP_SUB
    db OP_PRINT_NUM         ; prints 42
    db OP_NEWLINE
    db OP_PUSH
    dd 42
    db OP_RET               ; return 42

; --- Program 3: Loop 1 to 10 ---
; var0 = 1, while var0 <= 10: print var0, var0 += 1
prog3:
    db OP_RESERVE
    dd 500
    ; var0 = 1
    db OP_PUSH
    dd 1
    db OP_STORE
    dd 0
    ; loop start (offset from here)
.loop3:
    ; load var0, push 10, compare LE
    db OP_LOAD
    dd 0
    db OP_PUSH
    dd 10
    db OP_LE
    ; if false, jump past loop body
    db OP_JIF
    dd (.loop3_end - .loop3_body)
.loop3_body:
    ; print var0
    db OP_LOAD
    dd 0
    db OP_PRINT_NUM
    db OP_PUSH
    dd 32              ; space
    db OP_EMIT
    ; var0 = var0 + 1
    db OP_LOAD
    dd 0
    db OP_PUSH
    dd 1
    db OP_ADD
    db OP_STORE
    dd 0
    ; jump back to loop start
    db OP_JBACK
    dd ($ + 4 - .loop3)
.loop3_end:
    db OP_NEWLINE
    db OP_HALT

; --- Program 4: Fibonacci fib(10) ---
; var0 = a = 0, var1 = b = 1, var2 = counter = 10
; loop: tmp=a+b, a=b, b=tmp, counter--, if counter>0 loop
; print b
prog4:
    db OP_RESERVE
    dd 800
    ; a = 0
    db OP_PUSH
    dd 0
    db OP_STORE
    dd 0
    ; b = 1
    db OP_PUSH
    dd 1
    db OP_STORE
    dd 1
    ; counter = 10
    db OP_PUSH
    dd 10
    db OP_STORE
    dd 2
.fib_loop:
    ; print current b
    db OP_LOAD
    dd 1
    db OP_PRINT_NUM
    db OP_PUSH
    dd 32
    db OP_EMIT
    ; tmp = a + b -> var3
    db OP_LOAD
    dd 0
    db OP_LOAD
    dd 1
    db OP_ADD
    db OP_STORE
    dd 3        ; var3 = tmp
    ; a = b
    db OP_LOAD
    dd 1
    db OP_STORE
    dd 0
    ; b = tmp
    db OP_LOAD
    dd 3
    db OP_STORE
    dd 1
    ; counter--
    db OP_LOAD
    dd 2
    db OP_PUSH
    dd 1
    db OP_SUB
    db OP_STORE
    dd 2
    ; if counter > 0, loop
    db OP_LOAD
    dd 2
    db OP_PUSH
    dd 0
    db OP_GT
    db OP_JIF
    dd (.fib_end - .fib_cont)
.fib_cont:
    db OP_JBACK
    dd ($ + 4 - .fib_loop)
.fib_end:
    db OP_NEWLINE
    ; final result = b
    db OP_LOAD
    dd 1
    db OP_RET

; --- Program 5: surface_hello ---
; RESERVE 50j, PUSH_STR "hello CBS surface", PRINT_STR, NEWLINE, HALT
; PUSH_STR format: opcode 0x02, dw len, raw bytes, pad to 4-byte alignment
; "hello CBS surface" = 17 bytes; 17 & 3 = 1 → pad 3
surface_hello:
    db OP_RESERVE
    dd 50
    db OP_PUSH_STR
    dw 17
    db 'hello CBS surface'
    db 0, 0, 0              ; alignment pad (17 % 4 = 1, pad = 3)
    db OP_PRINT_STR
    db OP_NEWLINE
    db OP_HALT

; --- Program 6: surface_sched_stub ---
; RESERVE 100j, PUSH_STR "scheduler stub active", PRINT_STR, NEWLINE, HALT
; "scheduler stub active" = 21 bytes; 21 & 3 = 1 → pad 3
surface_sched_stub:
    db OP_RESERVE
    dd 100
    db OP_PUSH_STR
    dw 21
    db 'scheduler stub active'
    db 0, 0, 0              ; alignment pad (21 % 4 = 1, pad = 3)
    db OP_PRINT_STR
    db OP_NEWLINE
    db OP_HALT

; --- Program 7: surface_compiler_stub ---
; RESERVE 100j, PUSH_STR "compiler stub active", PRINT_STR, NEWLINE, HALT
; "compiler stub active" = 20 bytes; 20 & 3 = 0 → no pad
surface_compiler_stub:
    db OP_RESERVE
    dd 100
    db OP_PUSH_STR
    dw 20
    db 'compiler stub active' ; no alignment pad needed (20 % 4 = 0)
    db OP_PRINT_STR
    db OP_NEWLINE
    db OP_HALT

; =============================================================
; CBS Demo — compiled bytecode (from atreyu_x86.py)
; =============================================================
cbs_demo:
    incbin "boot/demo.cbc"
cbs_demo_end:

atreyu_cbs_prog:
    incbin "boot/atreyu.cbc"
atreyu_cbs_prog_end:

rockbiter_cbs_prog:
    incbin "boot/rockbiter.cbc"
rockbiter_cbs_prog_end:



; =============================================================
; Font (ASCII 32-126)
; =============================================================
font_data:
    db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
    db 0x18,0x18,0x18,0x18,0x18,0x00,0x18,0x00
    db 0x6C,0x6C,0x6C,0x00,0x00,0x00,0x00,0x00
    db 0x6C,0x6C,0xFE,0x6C,0xFE,0x6C,0x6C,0x00
    db 0x18,0x7E,0xC0,0x7C,0x06,0xFC,0x18,0x00
    db 0x00,0xC6,0xCC,0x18,0x30,0x66,0xC6,0x00
    db 0x38,0x6C,0x38,0x76,0xDC,0xCC,0x76,0x00
    db 0x18,0x18,0x30,0x00,0x00,0x00,0x00,0x00
    db 0x0C,0x18,0x30,0x30,0x30,0x18,0x0C,0x00
    db 0x30,0x18,0x0C,0x0C,0x0C,0x18,0x30,0x00
    db 0x00,0x66,0x3C,0xFF,0x3C,0x66,0x00,0x00
    db 0x00,0x18,0x18,0x7E,0x18,0x18,0x00,0x00
    db 0x00,0x00,0x00,0x00,0x00,0x18,0x18,0x30
    db 0x00,0x00,0x00,0x7E,0x00,0x00,0x00,0x00
    db 0x00,0x00,0x00,0x00,0x00,0x18,0x18,0x00
    db 0x06,0x0C,0x18,0x30,0x60,0xC0,0x80,0x00
    db 0x7C,0xC6,0xCE,0xDE,0xF6,0xE6,0x7C,0x00
    db 0x18,0x38,0x78,0x18,0x18,0x18,0x7E,0x00
    db 0x7C,0xC6,0x06,0x1C,0x30,0x60,0xFE,0x00
    db 0x7C,0xC6,0x06,0x3C,0x06,0xC6,0x7C,0x00
    db 0x1C,0x3C,0x6C,0xCC,0xFE,0x0C,0x1E,0x00
    db 0xFE,0xC0,0xFC,0x06,0x06,0xC6,0x7C,0x00
    db 0x38,0x60,0xC0,0xFC,0xC6,0xC6,0x7C,0x00
    db 0xFE,0xC6,0x0C,0x18,0x30,0x30,0x30,0x00
    db 0x7C,0xC6,0xC6,0x7C,0xC6,0xC6,0x7C,0x00
    db 0x7C,0xC6,0xC6,0x7E,0x06,0x0C,0x78,0x00
    db 0x00,0x18,0x18,0x00,0x00,0x18,0x18,0x00
    db 0x00,0x18,0x18,0x00,0x00,0x18,0x18,0x30
    db 0x0C,0x18,0x30,0x60,0x30,0x18,0x0C,0x00
    db 0x00,0x00,0x7E,0x00,0x7E,0x00,0x00,0x00
    db 0x30,0x18,0x0C,0x06,0x0C,0x18,0x30,0x00
    db 0x7C,0xC6,0x0C,0x18,0x18,0x00,0x18,0x00
    db 0x7C,0xC6,0xDE,0xDE,0xDE,0xC0,0x78,0x00
    db 0x38,0x6C,0xC6,0xC6,0xFE,0xC6,0xC6,0x00
    db 0xFC,0x66,0x66,0x7C,0x66,0x66,0xFC,0x00
    db 0x3C,0x66,0xC0,0xC0,0xC0,0x66,0x3C,0x00
    db 0xF8,0x6C,0x66,0x66,0x66,0x6C,0xF8,0x00
    db 0xFE,0x62,0x68,0x78,0x68,0x62,0xFE,0x00
    db 0xFE,0x62,0x68,0x78,0x68,0x60,0xF0,0x00
    db 0x3C,0x66,0xC0,0xC0,0xCE,0x66,0x3E,0x00
    db 0xC6,0xC6,0xC6,0xFE,0xC6,0xC6,0xC6,0x00
    db 0x3C,0x18,0x18,0x18,0x18,0x18,0x3C,0x00
    db 0x1E,0x0C,0x0C,0x0C,0xCC,0xCC,0x78,0x00
    db 0xE6,0x66,0x6C,0x78,0x6C,0x66,0xE6,0x00
    db 0xF0,0x60,0x60,0x60,0x62,0x66,0xFE,0x00
    db 0xC6,0xEE,0xFE,0xFE,0xD6,0xC6,0xC6,0x00
    db 0xC6,0xE6,0xF6,0xDE,0xCE,0xC6,0xC6,0x00
    db 0x7C,0xC6,0xC6,0xC6,0xC6,0xC6,0x7C,0x00
    db 0xFC,0x66,0x66,0x7C,0x60,0x60,0xF0,0x00
    db 0x7C,0xC6,0xC6,0xC6,0xD6,0xDE,0x7C,0x06
    db 0xFC,0x66,0x66,0x7C,0x6C,0x66,0xE6,0x00
    db 0x7C,0xC6,0xE0,0x7C,0x0E,0xC6,0x7C,0x00
    db 0x7E,0x5A,0x18,0x18,0x18,0x18,0x3C,0x00
    db 0xC6,0xC6,0xC6,0xC6,0xC6,0xC6,0x7C,0x00
    db 0xC6,0xC6,0xC6,0xC6,0x6C,0x38,0x10,0x00
    db 0xC6,0xC6,0xC6,0xD6,0xFE,0xEE,0xC6,0x00
    db 0xC6,0xC6,0x6C,0x38,0x6C,0xC6,0xC6,0x00
    db 0x66,0x66,0x66,0x3C,0x18,0x18,0x3C,0x00
    db 0xFE,0xC6,0x8C,0x18,0x32,0x66,0xFE,0x00
    db 0x3C,0x30,0x30,0x30,0x30,0x30,0x3C,0x00
    db 0xC0,0x60,0x30,0x18,0x0C,0x06,0x02,0x00
    db 0x3C,0x0C,0x0C,0x0C,0x0C,0x0C,0x3C,0x00
    db 0x10,0x38,0x6C,0xC6,0x00,0x00,0x00,0x00
    db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xFF
    db 0x30,0x18,0x0C,0x00,0x00,0x00,0x00,0x00
    db 0x00,0x00,0x78,0x0C,0x7C,0xCC,0x76,0x00
    db 0xE0,0x60,0x60,0x7C,0x66,0x66,0xDC,0x00
    db 0x00,0x00,0x7C,0xC6,0xC0,0xC6,0x7C,0x00
    db 0x1C,0x0C,0x0C,0x7C,0xCC,0xCC,0x76,0x00
    db 0x00,0x00,0x7C,0xC6,0xFE,0xC0,0x7C,0x00
    db 0x38,0x6C,0x60,0xF0,0x60,0x60,0xF0,0x00
    db 0x00,0x00,0x76,0xCC,0xCC,0x7C,0x0C,0xF8
    db 0xE0,0x60,0x6C,0x76,0x66,0x66,0xE6,0x00
    db 0x18,0x00,0x38,0x18,0x18,0x18,0x3C,0x00
    db 0x06,0x00,0x06,0x06,0x06,0x66,0x66,0x3C
    db 0xE0,0x60,0x66,0x6C,0x78,0x6C,0xE6,0x00
    db 0x38,0x18,0x18,0x18,0x18,0x18,0x3C,0x00
    db 0x00,0x00,0xCC,0xFE,0xFE,0xD6,0xC6,0x00
    db 0x00,0x00,0xDC,0x66,0x66,0x66,0x66,0x00
    db 0x00,0x00,0x7C,0xC6,0xC6,0xC6,0x7C,0x00
    db 0x00,0x00,0xDC,0x66,0x66,0x7C,0x60,0xF0
    db 0x00,0x00,0x76,0xCC,0xCC,0x7C,0x0C,0x1E
    db 0x00,0x00,0xDC,0x76,0x66,0x60,0xF0,0x00
    db 0x00,0x00,0x7C,0xC0,0x7C,0x06,0xFC,0x00
    db 0x10,0x30,0x7C,0x30,0x30,0x34,0x18,0x00
    db 0x00,0x00,0xCC,0xCC,0xCC,0xCC,0x76,0x00
    db 0x00,0x00,0xC6,0xC6,0xC6,0x6C,0x38,0x00
    db 0x00,0x00,0xC6,0xD6,0xFE,0xFE,0x6C,0x00
    db 0x00,0x00,0xC6,0x6C,0x38,0x6C,0xC6,0x00
    db 0x00,0x00,0xC6,0xC6,0xCE,0x76,0x06,0xFE
    db 0x00,0x00,0xFE,0x0C,0x38,0x60,0xFE,0x00
    db 0x0E,0x18,0x18,0x70,0x18,0x18,0x0E,0x00
    db 0x18,0x18,0x18,0x00,0x18,0x18,0x18,0x00
    db 0x70,0x18,0x18,0x0E,0x18,0x18,0x70,0x00
    db 0x76,0xDC,0x00,0x00,0x00,0x00,0x00,0x00


; =============================================================
; VM runtime data
; =============================================================
