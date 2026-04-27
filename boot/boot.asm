; =============================================================
; CodebookOS — x86_64 UEFI Boot Orchestrator
; Thin orchestrator: PE32+ headers + %include chain
; Pod 0: monolith modularized into focused modules
; "Atreyu named it."
; =============================================================

BITS 64

%include "boot/defines.asm"

; CHECK_BS_LIVE — guard macro for any code that calls into Boot Services.
; Reads uefi_exited; jumps to .bs_dead in the caller if EBS has run.
%macro CHECK_BS_LIVE 0
    cmp byte [rel uefi_exited], 1
    je  .bs_dead
%endmacro

; =============================================================
; PE32+ Headers
; =============================================================
dos_header:
    dw 0x5A4D
    times 29 dw 0
    dd pe_sig - dos_header
pe_sig:
    dd 0x00004550
    dw 0x8664, 2
    dd 0, 0, 0
    dw opt_hdr_end - opt_hdr
    dw 0x0022
opt_hdr:
    dw 0x020B
    db 1, 0
    dd TEXT_RAWSZ, 0, 0
    dd TEXT_RVA, TEXT_RVA
    dq IMAGE_BASE
    dd SECT_ALIGN, FILE_ALIGN
    dw 0,0,0,0,0,0
    dd 0, IMAGE_SZ, HEADER_SZ, 0
    dw 10, 0
    dq 0x10000, 0x10000, 0x10000, 0
    dd 0, 6
    dd 0,0, 0,0, 0,0, 0,0, 0,0
    dd RELOC_RVA, RELOC_RAWSZ
opt_hdr_end:
    db '.text',0,0,0
    dd TEXT_VSZ, TEXT_RVA, TEXT_RAWSZ, TEXT_RAW
    dd 0,0
    dw 0,0
    dd 0xE0000060
    db '.reloc',0,0
    dd RELOC_VSZ, RELOC_RVA, RELOC_RAWSZ, RELOC_RAW
    dd 0,0
    dw 0,0
    dd 0x42000040
    times TEXT_RAW - ($ - $$) db 0

; =============================================================
text_start:
; =============================================================

; =============================================================
; Entry Point
; =============================================================
efi_entry:
    push    rbx
    push    rbp
    push    rdi
    push    rsi
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 104

    lea     rbx, [rel uefi_data]
    mov     [rbx],      rcx
    mov     [rbx + 8],  rdx
    mov     rax, [rdx + ST_CONOUT]
    mov     [rbx + 16], rax
    mov     rax, [rdx + ST_CONIN]
    mov     [rbx + 24], rax
    mov     rax, [rdx + ST_BOOTSERV]
    mov     [rbx + 32], rax
    mov     rax, [rdx + ST_RUNTIME]
    mov     [rbx + 40], rax

    ; Disable watchdog
    mov     rax, [rbx + 32]
    mov     rax, [rax + BS_SETWATCHDOG]
    xor     ecx, ecx
    xor     edx, edx
    xor     r8d, r8d
    xor     r9d, r9d
    call    rax

    lea     rbx, [rel uefi_data]
    mov     rcx, [rbx + 16]
    mov     rax, [rcx + CONOUT_CLEARSCR]
    call    rax

    lea     rbx, [rel uefi_data]
    lea     rdx, [rel ucs_locating]
    mov     rcx, [rbx + 16]
    mov     rax, [rcx + CONOUT_OUTPUTSTR]
    call    rax

    call    locate_sfsp
    call    locate_gop
    test    rax, rax
    jnz     .no_gop

    lea     rbx, [rel uefi_data]
    lea     rdx, [rel ucs_gop_ok]
    mov     rcx, [rbx + 16]
    mov     rax, [rcx + CONOUT_OUTPUTSTR]
    call    rax

    ; === BOOT SPLASH ===
    mov     edi, COLOR_BLACK
    call    auryn_fill
    call    cursor_home
    call    stall_500
    lea     rsi, [rel str_spad]
    call    auryn_puts
    lea     rsi, [rel str_sname]
    call    auryn_puts
    call    stall_1500
    lea     rsi, [rel str_spres]
    call    auryn_puts
    call    stall_1000
    mov     edi, COLOR_BLACK
    call    auryn_fill
    call    cursor_home
    lea     rsi, [rel str_spad]
    call    auryn_puts
    lea     rsi, [rel str_stitle]
    call    auryn_puts
    lea     rsi, [rel str_sphase]
    call    auryn_puts
    call    stall_2000
%ifdef NATIVE_KBD
    call    exit_boot_services
%endif
    mov     edi, COLOR_BLACK
    call    auryn_fill
    call    cursor_home
    jmp     bastian_home

.no_gop:
    lea     rbx, [rel uefi_data]
    lea     rdx, [rel ucs_no_gop]
    mov     rcx, [rbx + 16]
    mov     rax, [rcx + CONOUT_OUTPUTSTR]
    call    rax
.hang:  hlt
    jmp     .hang

; =============================================================
; Stall helpers
; =============================================================
stall_500:
    push rbx
    lea rbx,[rel uefi_data]
    mov rax,[rbx+32]
    mov rax,[rax+BS_STALL]
    mov ecx,500000
    call rax
    pop rbx
    ret
stall_1000:
    push rbx
    lea rbx,[rel uefi_data]
    mov rax,[rbx+32]
    mov rax,[rax+BS_STALL]
    mov ecx,1000000
    call rax
    pop rbx
    ret
stall_1500:
    push rbx
    lea rbx,[rel uefi_data]
    mov rax,[rbx+32]
    mov rax,[rax+BS_STALL]
    mov ecx,1500000
    call rax
    pop rbx
    ret
stall_2000:
    push rbx
    lea rbx,[rel uefi_data]
    mov rax,[rbx+32]
    mov rax,[rax+BS_STALL]
    mov ecx,2000000
    call rax
    pop rbx
    ret

cursor_home:
    mov dword [rel cursor_x], 0
    mov dword [rel cursor_y], 0
    ret

; =============================================================
; exit_boot_services
; Captures a fresh mmap_key via get_mmap, then calls
; BS->ExitBootServices(ImageHandle, mmap_key).
; Retries once on EFI_INVALID_PARAMETER (stale key).
; Success: uefi_data[32] (BootServices) and uefi_data[24] (ConIn)
;          are set to NULL; uefi_exited is set to 1; returns 0.
; Fatal:   prints error string; returns 1.
; =============================================================
exit_boot_services:
    push    rbx
    push    rbp
    mov     rbp, rsp
    sub     rsp, 48

    call    get_mmap
    test    rax, rax
    jnz     .fatal

    lea     rbx, [rel uefi_data]
    mov     rcx, [rbx]              ; ImageHandle = uefi_data[0]
    mov     rdx, [rel mmap_key]
    mov     rax, [rbx+32]           ; BootServices table pointer
    mov     rax, [rax+BS_EXITBOOTSERV]
    call    rax
    test    rax, rax
    jz      .success

    ; EFI_INVALID_PARAMETER (stale key) → get a fresh key and retry once
    mov     rbx, 0x8000000000000002
    cmp     rax, rbx
    jne     .fatal

    call    get_mmap
    test    rax, rax
    jnz     .fatal

    lea     rbx, [rel uefi_data]
    mov     rcx, [rbx]
    mov     rdx, [rel mmap_key]
    mov     rax, [rbx+32]
    mov     rax, [rax+BS_EXITBOOTSERV]
    call    rax
    test    rax, rax
    jnz     .fatal

.success:
    lea     rbx, [rel uefi_data]
    mov     qword [rbx+32], 0       ; BootServices = NULL
    mov     qword [rbx+24], 0       ; ConIn = NULL
    mov     byte [rel uefi_exited], 1

    ; (GPU validation + identity paging deferred to V1.1; stubs
    ;  exiled to drivers/_future/ and kernel/_future/ pending
    ;  smoke-testing. Core concepts preserved.)
    xor     eax, eax
    leave
    pop     rbx
    ret

.fatal:
    lea     rsi, [rel str_ebs_fail]
    call    auryn_puts
    mov     eax, 1
    leave
    pop     rbx
    ret

; =============================================================
; locate_gop
; =============================================================

locate_sfsp:
    push rbx
    push rbp
    mov rbp,rsp
    sub rsp,32
    lea rbx,[rel uefi_data]
    mov rax,[rbx+32]
    mov rax,[rax+BS_LOCATEPROTOCOL]
    lea rcx,[rel sfsp_guid]
    xor edx,edx
    lea r8,[rel sfsp_ptr]
    call rax
    test rax,rax
    jnz .f

    ; Store SFSP in uefi_data
    lea rbx,[rel uefi_data]
    mov rax,[rel sfsp_ptr]
    mov [rbx+48],rax

    mov rbx,[rel sfsp_ptr]
    mov rax,[rbx+0x08] ; OpenVolume
    mov rcx,rbx
    lea rdx,[rel root_ptr]
    call rax
    test rax,rax
    jnz .f
    xor eax,eax
    jmp .d
.f: mov eax,1
.d: leave
    pop rbx
    ret

locate_gop:
    push rbx
    push rbp
    mov rbp,rsp
    sub rsp,48
    lea rbx,[rel uefi_data]
    mov rax,[rbx+32]
    mov rax,[rax+BS_LOCATEPROTOCOL]
    lea rcx,[rel gop_guid]
    xor edx,edx
    lea r8,[rel gop_ptr]
    call rax
    test rax,rax
    jnz .f
    mov rax,[rel gop_ptr]
    mov rax,[rax+GOP_MODE]
    mov [rel gop_mode_ptr],rax
    mov rcx,[rax+GOPMODE_FBBASE]
    mov [rel fb_base],rcx
    mov rcx,[rax+GOPMODE_FBSIZE]
    mov [rel fb_size],rcx
    mov rax,[rel gop_mode_ptr]
    mov rax,[rax+GOPMODE_INFO]
    mov ecx,[rax+GOPINFO_HRES]
    mov [rel fb_width],ecx
    mov ecx,[rax+GOPINFO_VRES]
    mov [rel fb_height],ecx
    mov ecx,[rax+GOPINFO_PPSL]
    mov [rel fb_ppsl],ecx
    mov ecx,[rax+GOPINFO_PIXFMT]
    mov [rel fb_pixfmt],ecx
    xor eax,eax
    jmp .d
.f: mov eax,1
.d: leave
    pop rbx
    ret

; =============================================================
; fixup_color: swap R and B bytes if pixfmt != 1 (BGRX)
; in:  eax = color (BGRX format)
; out: eax = color adjusted for current fb_pixfmt
; clobbers ecx only
; =============================================================
fixup_color:
    cmp dword [rel fb_pixfmt], 1
    je .fc_done
    mov ecx, eax
    and ecx, 0x00FF00FF
    rol ecx, 16
    and eax, 0xFF00FF00
    or  eax, ecx
.fc_done:
    ret

%include "boot/auryn.asm"      ; auryn_fill, scroll, paint, putc
%include "boot/morla.asm"      ; morla FAT32 + auryn_puts (preserves original order)
%include "boot/gmork.asm"      ; string utils: str_eq, starts_with, parse_hex, print_*
%include "boot/cbs_vm.asm"     ; CBS bytecode VM
%include "boot/bastian.asm"    ; home surface (bastian precedes gmork_main in original)
%include "boot/gmork_cmds.asm"  ; gmork_main, get_mmap, show_memmap, paint_bars
%include "drivers/kbd_ps2.asm"  ; PS/2 keyboard driver — native_keyboard_read
%include "drivers/ide_pio.asm"   ; IDE PIO driver — ide_pio_init, ide_pio_read_sector, ide_pio_write_sector
%include "drivers/fat32.asm"     ; FAT32 read-only driver — fat32_init, fat32_read_sector, fat32_load_file
%include "boot/data.asm"        ; static data, strings, font, program bytecode
%include "boot/vmdata.asm"     ; VM runtime data: stack, vars, energy, mmap_buf

; === .reloc section padding — MUST be physically last ===
    times TEXT_RAWSZ - ($ - text_start) db 0
reloc_start:
    dd 0, 10
    dw 0
    times RELOC_RAWSZ - ($ - reloc_start) db 0
