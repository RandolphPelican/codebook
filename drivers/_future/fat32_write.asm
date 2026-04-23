; =============================================================
; FAT32 Write Support � RESERVED FOR V1.1
; =============================================================
; This file is NOT included in the V1.0 boot image. Contents:
;   fat32_write_sector, fat32_allocate_cluster_chain,
;   fat32_update_directory_entry, fat32_write_file,
;   fat32_validate_filename, fat32_find_file_cluster,
;   fat32_update_fat_chain
;
; Dependencies for resurrection:
;   - ide_pio_write_sector (drivers/ide_pio.asm; untested)
;   - fat32_read_sector (drivers/fat32.asm)
;   - fat32_* runtime state (boot/data.asm)
;
; Resurrection checklist:
;   1. Hoist into drivers/fat32.asm OR %include from boot.asm
;   2. Smoke-test fat32_write_sector in QEMU with a known pattern
;   3. Stress-test dir entry update with long and short filenames
;   4. Wire a Morla surface command or CBS cap to expose writes
;
; %defines below are duplicated from drivers/fat32.asm so this
; file is self-contained when resurrected.
;
; Atreyu named it.
; =============================================================

%define IDE_DATA        0x1F0   ; 16-bit data (read 256 words per sector)
%define IDE_SECCOUNT    0x1F2   ; sector count register
%define IDE_LBA0        0x1F3   ; LBA bits  7:0
%define IDE_LBA1        0x1F4   ; LBA bits 15:8
%define IDE_LBA2        0x1F5   ; LBA bits 23:16
%define IDE_DRVHEAD     0x1F6   ; drive/head: 0xE0 | LBA bits 27:24 (LBA mode, master)
%define IDE_CMD         0x1F7   ; command (write) / status (read)
%define IDE_CMD_READ    0x20    ; READ SECTORS command

; --- FAT32 BPB field offsets within the VBR sector ---
%define BPB_BytsPerSec  0x0B   ; word  — bytes per sector (always 512 for this driver)
%define BPB_SecPerClus  0x0D   ; byte  — sectors per cluster (power of 2)
%define BPB_RsvdSecCnt  0x0E   ; word  — reserved sector count
%define BPB_NumFATs     0x10   ; byte  — number of FATs (always 2)
%define BPB_FATSz32     0x24   ; dword — sectors per FAT (FAT32-specific field)
%define BPB_RootClus    0x2C   ; dword — first cluster of root directory

; --- MBR partition table entry field offsets (each entry 16 bytes) ---
%define PTBL_TYPE       4      ; byte  — partition type
%define PTBL_LBA_START  8      ; dword — LBA address of first sector

; --- FAT32 directory entry field offsets (each entry 32 bytes) ---
%define DIR_Name        0      ; 11 bytes — 8.3 name (space-padded, no dot)
%define DIR_Attr        11     ; byte  — attribute flags
%define DIR_FstClusHI   0x14  ; word  — high 16 bits of first cluster
%define DIR_FstClusLO   0x1A  ; word  — low 16 bits of first cluster
%define DIR_FileSize    0x1C  ; dword — file size in bytes

%define ATTR_LFN        0x0F  ; all attribute bits set → long filename entry
%define DIRENT_DELETED  0xE5  ; first byte of name for a deleted entry
%define FAT32_EOC       0x0FFFFFF8  ; end-of-chain sentinel (≥ this value)


; --- Constants for FAT32 Write Support ---
FAT32_EOC_MARKER     equ 0x0FFFFFFF  ; End-of-cluster-chain marker
FAT32_FREE_CLUSTER   equ 0x00000000  ; Free cluster marker
FAT32_MAX_FILENAME   equ 11          ; Max 8.3 filename length

; =============================================================
; fat32_write_sector: Writes a 512-byte sector via IDE PIO.
; Input:  RSI = LBA, RCX = 1, RDI = Buffer
; Output: RAX = 0 on success, error code on failure.
; =============================================================
fat32_write_sector:
    jmp ide_pio_write_sector

; =============================================================
; fat32_allocate_cluster_chain: Allocates a new cluster chain in FAT.
; Input:  ECX = Number of clusters needed
; Output: EAX = First cluster in chain, or 0 on error.
; =============================================================
fat32_allocate_cluster_chain:
    push    rbx
    push    rbp
    push    r12
    push    r13
    push    r14
    push    r15

    mov     r12d, ecx            ; r12d = number of clusters needed
    xor     r13d, r13d           ; r13d = first cluster in chain
    xor     r14d, r14d           ; r14d = previous cluster
    xor     r15d, r15d           ; r15d = current cluster

    ; Start scanning from cluster 2 (cluster 0 and 1 are reserved)
    mov     r15d, 2

.scan_loop:
    ; Read FAT entry for current cluster
    mov     rdi, r15
    lea     rsi, [rel fat32_fat_buf]
    call    fat32_read_sector
    test    rax, rax
    jnz     .error

    ; Check if cluster is free
    lea     rbx, [rel fat32_fat_buf]
    mov     eax, [rbx + r15*4]
    and     eax, 0x0FFFFFFF
    cmp     eax, FAT32_FREE_CLUSTER
    jne     .next_cluster

    ; Found a free cluster
    test    r13d, r13d
    jnz     .add_to_chain
    mov     r13d, r15d           ; First cluster in chain
    jmp     .next_cluster

.add_to_chain:
    ; Link previous cluster to current cluster
    mov     rdi, r14
    lea     rsi, [rel fat32_fat_buf]
    call    fat32_read_sector
    test    rax, rax
    jnz     .error

    lea     rbx, [rel fat32_fat_buf]
    mov     [rbx + r14*4], r15d

    ; Write updated FAT sector
    mov     rdi, r14
    lea     rsi, [rel fat32_fat_buf]
    call    fat32_write_sector
    test    rax, rax
    jnz     .error

    dec     r12d
    jz      .chain_complete

.next_cluster:
    mov     r14d, r15d
    inc     r15d
    jmp     .scan_loop

.chain_complete:
    ; Mark last cluster as EOC
    mov     rdi, r15
    lea     rsi, [rel fat32_fat_buf]
    call    fat32_read_sector
    test    rax, rax
    jnz     .error

    lea     rbx, [rel fat32_fat_buf]
    mov     dword [rbx + r15*4], FAT32_EOC_MARKER

    ; Write updated FAT sector
    mov     rdi, r15
    lea     rsi, [rel fat32_fat_buf]
    call    fat32_write_sector
    test    rax, rax
    jnz     .error

    mov     eax, r13d           ; Return first cluster in chain
    jmp     .done

.error:
    xor     eax, eax

.done:
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbp
    pop     rbx
    ret

; =============================================================
; fat32_update_directory_entry: Updates a directory entry for a file.
; Input:  RSI = Filename, EDI = First cluster, ECX = File size
; Output: RAX = 0 on success, error code on failure.
; =============================================================
fat32_update_directory_entry:
    push    rbx
    push    rbp
    push    r12
    push    r13
    push    r14
    push    r15

    mov     r12, rsi            ; r12 = filename
    mov     r13d, edi            ; r13d = first cluster
    mov     r14d, ecx            ; r14d = file size

    ; Begin directory scan at root cluster
    mov     r15d, [rel fat32_root_cluster]

.dir_cluster:
    mov     eax, r15d
    and     eax, 0x0FFFFFFF
    cmp     eax, FAT32_EOC
    jae     .not_found

    ; Compute LBA of first sector of cluster r15
    movzx   rax, byte [rel fat32_sectors_per_cluster]
    mov     rbx, r15
    sub     rbx, 2
    imul    rbx, rax
    add     rbx, [rel fat32_data_start_lba]

    movzx   r14d, byte [rel fat32_sectors_per_cluster]

.dir_sector:
    test    r14d, r14d
    jz      .dir_next_cluster

    dec     r14d
    push    rbx
    push    r14
    mov     rdi, rbx
    lea     rsi, [rel fat32_sector_buf]
    call    fat32_read_sector
    pop     r14
    pop     rbx
    test    rax, rax
    jnz     .error
    inc     rbx

    lea     rbp, [rel fat32_sector_buf]
    mov     r14d, 16

.dir_entry:
    test    r14d, r14d
    jz      .dir_sector

    movzx   eax, byte [rbp + DIR_Name]
    test    al, al
    jz      .not_found
    cmp     al, DIRENT_DELETED
    je      .dir_skip
    movzx   eax, byte [rbp + DIR_Attr]
    cmp     al, ATTR_LFN
    je      .dir_skip

    ; Compare the 11-byte directory name against filename
    lea     rsi, [rel fat32_name83]
    mov     rdi, rbp
    mov     ecx, 11
    repe    cmpsb
    jne     .dir_skip

    ; Found the file - update the directory entry
    mov     [rbp + DIR_FstClusLO], r13w
    shr     r13d, 16
    mov     [rbp + DIR_FstClusHI], r13w
    mov     [rbp + DIR_FileSize], r14d

    ; Write the updated sector back to disk
    mov     rdi, rbx
    lea     rsi, [rel fat32_sector_buf]
    call    fat32_write_sector
    test    rax, rax
    jnz     .error

    xor     eax, eax
    jmp     .done

.dir_skip:
    dec     r14d
    add     rbp, 32
    jmp     .dir_entry

.dir_next_cluster:
    mov     r15d, [rel fat32_root_cluster]
    call    fat32_next_cluster
    jmp     .dir_cluster

.not_found:
.error:
    mov     rax, -1

.done:
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbp
    pop     rbx
    ret

; =============================================================
; fat32_write_file: Writes a file to FAT32 filesystem.
; Input:  RSI = Filename, RDX = Buffer, RCX = Buffer size, R8 = Create/Overwrite
; Output: RAX = 0 on success, error code on failure.
; =============================================================
fat32_write_file:
    push    rbx
    push    rbp
    push    r12
    push    r13
    push    r14
    push    r15

    mov     r12, rsi            ; r12 = filename
    mov     r13, rdx            ; r13 = buffer
    mov     r14d, ecx           ; r14d = buffer size
    mov     r15d, r8d            ; r15d = create/overwrite flag

    ; Validate filename (8.3 format)
    call    fat32_validate_filename
    test    rax, rax
    jnz     .error_invalid_filename

    ; If R8=1 (create), allocate cluster chain
    test    r15d, r15d
    jz      .overwrite

    ; Calculate number of clusters needed
    mov     eax, r14d
    add     eax, 511
    shr     eax, 9              ; Divide by 512 (sector size)
    mov     ecx, eax
    call    fat32_allocate_cluster_chain
    test    eax, eax
    jz      .error_no_space
    mov     r13d, eax           ; r13d = first cluster
    jmp     .write_data

.overwrite:
    ; Find existing file's cluster chain
    call    fat32_find_file_cluster
    test    eax, eax
    jz      .error_file_not_found
    mov     r13d, eax

.write_data:
    ; Write data in chunks of sectors
    mov     r9, r13             ; r9 = buffer pointer
    mov     r10d, r14d          ; r10d = buffer size
    xor     r11d, r11d          ; r11d = sector counter

.write_loop:
    ; Load buffer into sectors
    lea     rdi, [rel fat32_sector_buf]
    mov     rcx, 512
    mov     rsi, r9
    rep     movsb

    ; Write sector to disk
    mov     rsi, r13            ; LBA = cluster_to_sector(r13)
    lea     rdi, [rel fat32_sector_buf]
    call    fat32_write_sector
    test    rax, rax
    jnz     .error

    ; Update FAT chain
    mov     eax, r13d
    call    fat32_update_fat_chain

    ; Move to next cluster
    inc     r13d
    add     r9, 512
    sub     r10d, 512
    jnz     .write_loop

    ; Update directory entry
    mov     rsi, r12            ; filename
    mov     edi, r13d           ; first cluster
    mov     ecx, r14d           ; file size
    call    fat32_update_directory_entry
    test    rax, rax
    jnz     .error

    ; Return success
    xor     eax, eax
    jmp     .done

.error_invalid_filename:
.error_no_space:
.error_file_not_found:
.error:
    mov     rax, -1

.done:
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbp
    pop     rbx
    ret

; =============================================================
; fat32_validate_filename: Validates filename is 8.3 format.
; Input:  RSI = Filename
; Output: RAX = 0 on success, error code on failure.
; =============================================================
fat32_validate_filename:
    push    rbx
    push    rcx
    push    rdx

    mov     rbx, rsi            ; rbx = filename pointer
    xor     ecx, ecx            ; ecx = name length
    xor     edx, edx            ; edx = extension length

    ; Check name part (max 8 chars)
.name_loop:
    movzx   eax, byte [rbx]
    test    al, al
    jz      .check_extension
    cmp     al, '.'
    je      .extension
    inc     ecx
    cmp     ecx, 8
    ja      .error
    inc     rbx
    jmp     .name_loop

.extension:
    inc     rbx
    jmp     .extension_loop

.extension_loop:
    movzx   eax, byte [rbx]
    test    al, al
    jz      .check_extension
    inc     edx
    cmp     edx, 3
    ja      .error
    inc     rbx
    jmp     .extension_loop

.check_extension:
    test    edx, edx
    jz      .success
    cmp     edx, 3
    ja      .error

.success:
    xor     eax, eax
    jmp     .done

.error:
    mov     eax, -1

.done:
    pop     rdx
    pop     rcx
    pop     rbx
    ret

; =============================================================
; fat32_find_file_cluster: Finds a file's cluster chain.
; Input:  RSI = Filename
; Output: EAX = First cluster, or 0 on error.
; =============================================================
fat32_find_file_cluster:
    push    rbx
    push    rbp
    push    r12
    push    r13
    push    r14
    push    r15

    mov     r12, rsi            ; r12 = filename

    ; Begin directory scan at root cluster
    mov     r13d, [rel fat32_root_cluster]

.dir_cluster:
    mov     eax, r13d
    and     eax, 0x0FFFFFFF
    cmp     eax, FAT32_EOC
    jae     .not_found

    ; Compute LBA of first sector of cluster r13
    movzx   rax, byte [rel fat32_sectors_per_cluster]
    mov     rbx, r13
    sub     rbx, 2
    imul    rbx, rax
    add     rbx, [rel fat32_data_start_lba]

    movzx   r14d, byte [rel fat32_sectors_per_cluster]

.dir_sector:
    test    r14d, r14d
    jz      .dir_next_cluster

    dec     r14d
    push    rbx
    push    r14
    mov     rdi, rbx
    lea     rsi, [rel fat32_sector_buf]
    call    fat32_read_sector
    pop     r14
    pop     rbx
    test    rax, rax
    jnz     .error
    inc     rbx

    lea     rbp, [rel fat32_sector_buf]
    mov     r15d, 16

.dir_entry:
    test    r15d, r15d
    jz      .dir_sector

    movzx   eax, byte [rbp + DIR_Name]
    test    al, al
    jz      .not_found
    cmp     al, DIRENT_DELETED
    je      .dir_skip
    movzx   eax, byte [rbp + DIR_Attr]
    cmp     al, ATTR_LFN
    je      .dir_skip

    ; Compare the 11-byte directory name against filename
    lea     rsi, [rel fat32_name83]
    mov     rdi, rbp
    mov     ecx, 11
    repe    cmpsb
    jne     .dir_skip

    ; Found the file - return first cluster
    movzx   eax, word [rbp + DIR_FstClusLO]
    movzx   edx, word [rbp + DIR_FstClusHI]
    shl     edx, 16
    or      eax, edx
    jmp     .done

.dir_skip:
    dec     r15d
    add     rbp, 32
    jmp     .dir_entry

.dir_next_cluster:
    call    fat32_next_cluster
    jmp     .dir_cluster

.not_found:
.error:
    xor     eax, eax

.done:
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbp
    pop     rbx
    ret

; =============================================================
; fat32_update_fat_chain: Updates FAT entry for cluster chain.
; Input:  EAX = Current cluster
; Output: RAX = 0 on success, error code on failure.
; =============================================================
fat32_update_fat_chain:
    push    rbx
    push    rbp
    push    r12
    push    r13
    push    r14
    push    r15

    mov     r12d, eax            ; r12d = current cluster

    ; Read FAT sector containing the cluster
    mov     rdi, r12
    lea     rsi, [rel fat32_fat_buf]
    call    fat32_read_sector
    test    rax, rax
    jnz     .error

    ; Update FAT entry
    lea     rbx, [rel fat32_fat_buf]
    mov     eax, [rbx + r12*4]
    and     eax, 0x0FFFFFFF
    cmp     eax, FAT32_EOC_MARKER
    je      .done

    ; Write updated FAT sector
    mov     rdi, r12
    lea     rsi, [rel fat32_fat_buf]
    call    fat32_write_sector
    test    rax, rax
    jnz     .error

.done:
    xor     eax, eax
    jmp     .done

.error:
    mov     eax, -1

.done:
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbp
    pop     rbx
    ret

; =============================================================
; fat32_load_file
; Searches the root directory cluster chain for a file whose
; 8.3 name matches the input, then loads its cluster chain
; sequentially into the output buffer.
; In:  rdi = null-terminated 8.3 uppercase ASCII filename
;      rsi = output buffer (caller ensures it is large enough)
; Out: rax = file size in bytes on success
;      rax = -1 (0xFFFFFFFFFFFFFFFF) on error or file not found
; Preserves: rbx, rbp, r12-r15 (all explicitly saved)
; =============================================================fat32_read_sector
; Reads one 512-byte sector from the primary IDE channel via PIO.
; In:  rdi = 28-bit LBA address
;      rsi = destination buffer (512 bytes)
; Out: rax = 0 success, 1 error (ERR bit set in status register)
; Preserves: rbx, rsi, r8-r15
; Clobbers:  rax, rcx, rdx, rdi (advanced by 512 after rep insw)
; =============================================================
