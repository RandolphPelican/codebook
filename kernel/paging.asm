; =============================================================================
; Identity-Mapped Page Table Builder for Codebook OS
; =============================================================================
;
; Functions:
;   paging_setup_identity - Builds PML4, PDP, PD, and PT entries for identity mapping.
;   paging_install_cr3   - Installs new CR3.
;
; Inputs:
;   - mmap_buf (from UEFI memory map, saved in Phase 1)
;   - fb_base, fb_size (from GOP)
;
; Outputs:
;   - New CR3 installed, paging enabled.

; --- Constants ---
PAGE_SIZE             equ 4096
PML4_ENTRIES          equ 512
PDP_ENTRIES           equ 512
PD_ENTRIES            equ 512
PT_ENTRIES            equ 512
PTE_PRESENT           equ 0x01
PTE_WRITABLE          equ 0x02
PTE_PAT               equ 0x1000
PTE_PS                equ 0x80  ; Page size (for 2MB/1GB pages)

; --- Global State ---
new_cr3               dq 0

; =============================================================================
; paging_setup_identity: Builds identity-mapped page tables.
; Input:  RDI = mmap_buf, RSI = fb_base, RDX = fb_size
; Output: RAX = 0 on success, error code on failure.
; =============================================================================
paging_setup_identity:
    ; 1. Allocate memory for PML4, PDP, PD, PT
    ;    (Assume we have a simple allocator; replace with your own)
    mov rcx, PML4_ENTRIES * 8
    call memory_allocate
    mov [new_cr3], rax
    mov r8, rax        ; PML4 base

    ; 2. Zero PML4, PDP, PD, PT
    mov rcx, PML4_ENTRIES * 8 * 4
    xor rax, rax
    rep stosq

    ; 3. Map conventional memory (identity)
    mov r9, 0          ; Start address
    mov r10, 0         ; Current PML4 entry
    mov r11, 0         ; Current PDP entry

.map_conventional:
    ; a. Map 1GB chunks (PDP entry)
    mov rax, r9
    shr rax, 30        ; 1GB = 2^30 bytes
    or rax, PTE_PRESENT | PTE_WRITABLE | PTE_PS
    mov [r8 + r10*8], rax
    inc r10
    add r9, 1073741824  ; 1GB

    ; b. Stop at end of conventional memory (or 4GB for now)
    cmp r9, 4294967296  ; 4GB
    jl .map_conventional

    ; 4. Map framebuffer MMIO range (identity)
    mov rax, rsi       ; fb_base
    mov rcx, rdx       ; fb_size
    call paging_map_mmio_range
    test rax, rax
    jnz .error

    ; 5. Install new CR3
    call paging_install_cr3
    test rax, rax
    jnz .error

    xor rax, rax
    ret

.error:
    mov rax, -1
    ret

; =============================================================================
; paging_map_mmio_range: Maps MMIO range (non-cacheable, write-combining).
; Input:  RDI = start, RSI = size
; Output: RAX = 0 on success, error code on failure.
; =============================================================================
paging_map_mmio_range:
    ; 1. Calculate end address
    add rsi, rdi

    ; 2. Map each 4K page with PAT/PCD flags
    mov rax, rdi
    and rax, ~0xFFF    ; Align to 4K

.map_loop:
    ; a. Get PT entry for this address
    mov rcx, rax
    shr rcx, 12        ; 4K page offset
    mov r8, [paging_get_pt_entry(rcx)]
    or dword [r8], PTE_PRESENT | PTE_WRITABLE | PTE_PAT | PTE_PCD

    ; b. Next page
    add rax, 4096
    cmp rax, rsi
    jl .map_loop

    xor rax, rax
    ret

; =============================================================================
; paging_install_cr3: Installs new CR3 and enables paging.
; Input:  RDI = new_cr3
; Output: RAX = 0 on success, error code on failure.
; =============================================================================
paging_install_cr3:
    ; 1. Load new CR3
    mov cr3, rdi

    ; 2. Enable paging (PG bit in CR0)
    mov rax, cr0
    or rax, 0x80000000
    mov cr0, rax

    ; 3. Flush TLB
    invlpg [0]

    xor rax, rax
    ret

; --- Helper Functions ---
paging_get_pt_entry:
    ; (Returns pointer to PT entry for given address)
    ret