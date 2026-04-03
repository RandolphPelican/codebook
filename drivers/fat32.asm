; fat32_load_file
; Searches the root directory cluster chain for a file whose
; 8.3 name matches the input, then loads its cluster chain
; sequentially into the output buffer.
; In:  rdi = null-terminated 8.3 uppercase ASCII filename
;      rsi = output buffer (caller ensures it is large enough)
; Out: rax = file size in bytes on success
;      rax = -1 (0xFFFFFFFFFFFFFFFF) on error or file not found
; Preserves: rbx, rbp, r12-r15 (all explicitly saved)
; =============================================================
=======
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
fat32_read_sector:
    push    rbx
    mov     ebx, edi            ; ebx = LBA (upper bits already 0)

    ; Wait for BSY clear before touching command registers
    mov     dx, IDE_CMD
.frs_bsy:
    in      al, dx
    test    al, 0x80            ; bit 7 = BSY
    jnz     .frs_bsy

    ; Drive/head register: LBA mode + master drive + LBA bits 27:24
    mov     eax, ebx
    shr     eax, 24
    and     al, 0x0F
    or      al, 0xE0            ; 1 = LBA, 0 = master
    mov     dx, IDE_DRVHEAD
    out     dx, al

    ; Sector count = 1
    mov     dx, IDE_SECCOUNT
    mov     al, 1
    out     dx, al

    ; LBA bytes low to high
    mov     eax, ebx
    mov     dx, IDE_LBA0
    out     dx, al              ; bits  7:0
    shr     eax, 8
    mov     dx, IDE_LBA1
    out     dx, al              ; bits 15:8
    shr     eax, 8
    mov     dx, IDE_LBA2
    out     dx, al              ; bits 23:16

    ; Issue READ SECTORS command
    mov     dx, IDE_CMD
    mov     al, IDE_CMD_READ
    out     dx, al

    ; Poll status: wait for BSY clear, then check ERR and DRQ
.frs_poll:
    in      al, dx
    test    al, 0x80            ; BSY?
    jnz     .frs_poll
    test    al, 0x01            ; ERR?
    jnz     .frs_err
    test    al, 0x08            ; DRQ?
    jz      .frs_poll

    ; Burst-read 256 words (512 bytes) from data port into buffer
    mov     rdi, rsi            ; rdi = destination (rsi is unchanged)
    mov     dx, IDE_DATA
    mov     ecx, 256
    cld
    rep insw

    xor     eax, eax            ; return 0 = OK
    pop     rbx
    ret

.frs_err:
    mov     eax, 1              ; return 1 = error
    pop     rbx
    ret
=======
; =============================================================
; fat32_read_sector
; Reads one 512-byte sector from the primary IDE channel via PIO.
; In:  rdi = 28-bit LBA address
;      rsi = destination buffer (512 bytes)
; Out: rax = 0 success, 1 error (ERR bit set in status register)
; Preserves: rbx, rsi, r8-r15
; Clobbers:  rax, rcx, rdx, rdi (advanced by 512 after rep insw)
; =============================================================
fat32_read_sector:
    jmp ide_pio_read_sector=============================================================
; FAT32 Read-Only Driver
; fat32_init, fat32_read_sector, fat32_load_file
; No UEFI dependency. Ring 0 required (IN/OUT instructions).
; Primary IDE PIO channel only (ports 0x1F0-0x1F7, 28-bit LBA).
;
; Exports: fat32_init, fat32_read_sector, fat32_load_file
; Data:    fat32_* variables must be declared in data.asm
; =============================================================

; --- IDE PIO primary channel ports ---
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


; =============================================================
; fat32_read_sector
; Reads one 512-byte sector from the primary IDE channel via PIO.
; In:  rdi = 28-bit LBA address
;      rsi = destination buffer (512 bytes)
; Out: rax = 0 success, 1 error (ERR bit set in status register)
; Preserves: rbx, rsi, r8-r15
; Clobbers:  rax, rcx, rdx, rdi (advanced by 512 after rep insw)
; =============================================================
fat32_read_sector:
    push    rbx
    mov     ebx, edi            ; ebx = LBA (upper bits already 0)

    ; Wait for BSY clear before touching command registers
    mov     dx, IDE_CMD
.frs_bsy:
    in      al, dx
    test    al, 0x80            ; bit 7 = BSY
    jnz     .frs_bsy

    ; Drive/head register: LBA mode + master drive + LBA bits 27:24
    mov     eax, ebx
    shr     eax, 24
    and     al, 0x0F
    or      al, 0xE0            ; 1 = LBA, 0 = master
    mov     dx, IDE_DRVHEAD
    out     dx, al

    ; Sector count = 1
    mov     dx, IDE_SECCOUNT
    mov     al, 1
    out     dx, al

    ; LBA bytes low to high
    mov     eax, ebx
    mov     dx, IDE_LBA0
    out     dx, al              ; bits  7:0
    shr     eax, 8
    mov     dx, IDE_LBA1
    out     dx, al              ; bits 15:8
    shr     eax, 8
    mov     dx, IDE_LBA2
    out     dx, al              ; bits 23:16

    ; Issue READ SECTORS command
    mov     dx, IDE_CMD
    mov     al, IDE_CMD_READ
    out     dx, al

    ; Poll status: wait for BSY clear, then check ERR and DRQ
.frs_poll:
    in      al, dx
    test    al, 0x80            ; BSY?
    jnz     .frs_poll
    test    al, 0x01            ; ERR?
    jnz     .frs_err
    test    al, 0x08            ; DRQ?
    jz      .frs_poll

    ; Burst-read 256 words (512 bytes) from data port into buffer
    mov     rdi, rsi            ; rdi = destination (rsi is unchanged)
    mov     dx, IDE_DATA
    mov     ecx, 256
    cld
    rep insw

    xor     eax, eax            ; return 0 = OK
    pop     rbx
    ret

.frs_err:
    mov     eax, 1              ; return 1 = error
    pop     rbx
    ret


; =============================================================
; fat32_init
; Reads MBR (LBA 0), finds the first FAT32 partition (type
; 0x0B or 0x0C), reads the VBR, parses the BPB, and stores
; the results into fat32_* variables declared in data.asm.
; Also computes fat32_data_start_lba for cluster → LBA math.
; In:  (none)
; Out: rax = 0 success, 1 error (read failure / no FAT32 part)
; Preserves: rbx, r12, r13 (explicitly saved)
; Clobbers:  rax, rcx, rdx, rdi, rsi
; =============================================================
fat32_init:
    push    rbx
    push    r12
    push    r13

    ; --- Read MBR ---
    xor     edi, edi
    lea     rsi, [rel fat32_sector_buf]
    call    fat32_read_sector
    test    rax, rax
    jnz     .fi_fail

    lea     rbx, [rel fat32_sector_buf]
    cmp     byte [rbx + 510], 0x55
    jne     .fi_fail
    cmp     byte [rbx + 511], 0xAA
    jne     .fi_fail

    ; --- Scan 4-entry MBR partition table (starts at offset 0x1BE) ---
    lea     r12, [rbx + 0x1BE]  ; r12 = first partition entry
    mov     r13d, 4             ; 4 entries

.fi_scan:
    test    r13d, r13d
    jz      .fi_fail
    dec     r13d
    movzx   eax, byte [r12 + PTBL_TYPE]
    cmp     al, 0x0B            ; FAT32 CHS
    je      .fi_found
    cmp     al, 0x0C            ; FAT32 LBA
    je      .fi_found
    add     r12, 16
    jmp     .fi_scan

.fi_found:
    ; LBA start is a dword at entry+8; zero-extend to qword for 64-bit arithmetic
    mov     eax, [r12 + PTBL_LBA_START]
    mov     [rel fat32_partition_lba], rax  ; store as qword
    mov     r12, rax                        ; r12 = partition_lba

    ; --- Read the partition's VBR (first sector of the partition) ---
    mov     rdi, r12
    lea     rsi, [rel fat32_sector_buf]
    call    fat32_read_sector
    test    rax, rax
    jnz     .fi_fail

    lea     rbx, [rel fat32_sector_buf]

    ; --- Parse BPB fields ---
    movzx   eax, word [rbx + BPB_BytsPerSec]
    mov     [rel fat32_bytes_per_sector], ax

    movzx   eax, byte [rbx + BPB_SecPerClus]
    mov     [rel fat32_sectors_per_cluster], al

    movzx   eax, word [rbx + BPB_RsvdSecCnt]
    mov     [rel fat32_reserved_sectors], ax

    movzx   eax, byte [rbx + BPB_NumFATs]
    mov     [rel fat32_fat_count], al

    mov     eax, [rbx + BPB_FATSz32]
    mov     [rel fat32_sectors_per_fat], eax

    mov     eax, [rbx + BPB_RootClus]
    mov     [rel fat32_root_cluster], eax

    ; --- Compute data_start_lba ---
    ; = partition_lba + reserved_sectors + fat_count * sectors_per_fat
    movzx   r13, word [rel fat32_reserved_sectors]
    movzx   rax, byte [rel fat32_fat_count]
    mov     ecx, [rel fat32_sectors_per_fat]   ; ecx zero-extends to rcx
    imul    rax, rcx
    add     rax, r13
    add     rax, r12            ; + partition_lba
    mov     [rel fat32_data_start_lba], rax

    xor     eax, eax
    jmp     .fi_done

.fi_fail:
    mov     eax, 1

.fi_done:
    pop     r13
    pop     r12
    pop     rbx
    ret


; =============================================================
; fat32_parse_name83  (internal helper)
; Converts "FILE.EXT\0" to the 11-byte space-padded FAT32 name
; format and writes it to fat32_name83.
; Examples:
;   "BASTIAN.CBC" → "BASTIAN CBC"
;   "PROG.CBS"    → "PROG    CBS"
;   "README.TXT"  → "README  TXT"
; In:  rdi = null-terminated 8.3 uppercase ASCII filename
; Out: fat32_name83 filled (no null terminator)
; Preserves: rbx, rdi (source pointer), rdx, r8-r15
; Clobbers:  rax, rcx, rsi
; =============================================================
fat32_parse_name83:
    push    rbx

    lea     rbx, [rel fat32_name83]

    ; Fill all 11 bytes with ASCII space (0x20)
    mov     dword [rbx+0],  0x20202020
    mov     dword [rbx+4],  0x20202020
    mov     word  [rbx+8],  0x2020
    mov     byte  [rbx+10], 0x20

    mov     rsi, rdi            ; rsi = walk pointer through source
    xor     ecx, ecx            ; ecx = column index into fat32_name83

.p83_name:
    movzx   eax, byte [rsi]
    test    al, al
    jz      .p83_done           ; end of string
    inc     rsi
    cmp     al, '.'
    je      .p83_ext            ; dot found — switch to extension columns
    cmp     ecx, 8
    jge     .p83_name           ; name > 8 chars: skip excess characters
    mov     [rbx + rcx], al
    inc     ecx
    jmp     .p83_name

.p83_ext:
    xor     ecx, ecx            ; reset index for extension (columns 8-10)

.p83_ext_loop:
    movzx   eax, byte [rsi]
    test    al, al
    jz      .p83_done
    inc     rsi
    cmp     ecx, 3
    jge     .p83_ext_loop       ; ext > 3 chars: skip excess
    mov     [rbx + 8 + rcx], al
    inc     ecx
    jmp     .p83_ext_loop

.p83_done:
    pop     rbx
    ret


; =============================================================
; fat32_next_cluster  (internal helper)
; Reads the FAT to find the next cluster in a chain.
; In:  r13d = current cluster number
; Out: r13d = next cluster (≥ FAT32_EOC means end-of-chain)
; Preserves: rbx, rcx, rdx (explicitly saved), r12-r15
; Clobbers:  rax, rdi, rsi (via fat32_read_sector)
; =============================================================
fat32_next_cluster:
    push    rbx
    push    rcx
    push    rdx

    ; FAT byte-offset for this cluster = cluster * 4
    mov     eax, r13d
    shl     rax, 2

    ; Byte offset within the 512-byte FAT sector = fat_offset & 0x1FF
    mov     ebx, eax
    and     ebx, 0x1FF          ; rbx = entry offset within sector

    ; FAT sector LBA = partition_lba + reserved_sectors + (fat_offset >> 9)
    shr     rax, 9
    movzx   rcx, word [rel fat32_reserved_sectors]
    add     rax, rcx
    add     rax, [rel fat32_partition_lba]

    ; Read the FAT sector — fat32_read_sector preserves rbx
    mov     rdi, rax
    lea     rsi, [rel fat32_fat_buf]
    call    fat32_read_sector

    ; Extract the 28-bit next-cluster value from the 4-byte FAT entry
    lea     rcx, [rel fat32_fat_buf]
    mov     eax, [rcx + rbx]
    and     eax, 0x0FFFFFFF
    mov     r13d, eax           ; r13d = next cluster (or EOC)

    pop     rdx
    pop     rcx
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
; =============================================================
fat32_load_file:
    push    rbx
    push    rbp
    push    r12
    push    r13
    push    r14
    push    r15

    mov     r12, rsi                        ; r12 = output buffer (constant)

    ; Convert "FILE.EXT" → 11-byte padded name in fat32_name83
    call    fat32_parse_name83              ; rdi preserved by the helper

    ; Begin directory scan at root cluster
    mov     r13d, [rel fat32_root_cluster]

; ========================
; Directory cluster loop
; ========================
.dir_cluster:
    mov     eax, r13d
    and     eax, 0x0FFFFFFF
    cmp     eax, FAT32_EOC
    jae     .not_found                      ; EOC before match = file not found

    ; Compute LBA of first sector of cluster r13:
    ;   LBA = data_start_lba + (cluster − 2) × sectors_per_cluster
    movzx   rax, byte [rel fat32_sectors_per_cluster]
    mov     rbx, r13
    sub     rbx, 2
    imul    rbx, rax
    add     rbx, [rel fat32_data_start_lba]
    ; rbx = first sector LBA of this directory cluster

    movzx   r14d, byte [rel fat32_sectors_per_cluster]  ; r14 = sectors remaining

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
    jnz     .err
    inc     rbx                             ; advance LBA to next sector

    lea     rbp, [rel fat32_sector_buf]     ; rbp = current entry pointer
    mov     r15d, 16                        ; 16 entries per 512-byte sector

.dir_entry:
    test    r15d, r15d
    jz      .dir_sector                     ; sector exhausted → next sector

    movzx   eax, byte [rbp + DIR_Name]
    test    al, al
    jz      .not_found                      ; 0x00 = directory has no more entries
    cmp     al, DIRENT_DELETED
    je      .dir_skip                       ; 0xE5 = deleted entry
    movzx   eax, byte [rbp + DIR_Attr]
    cmp     al, ATTR_LFN
    je      .dir_skip                       ; 0x0F = long filename entry

    ; Compare the 11-byte directory name against fat32_name83
    lea     rsi, [rel fat32_name83]
    mov     rdi, rbp                        ; rdi → name field of this entry
    mov     ecx, 11
    repe    cmpsb                           ; rbp itself is unchanged
    jne     .dir_skip

    ; ---- Found the file ----
    ; First cluster: high word at DIR_FstClusHI, low word at DIR_FstClusLO
    movzx   r13d, word [rbp + DIR_FstClusHI]
    shl     r13d, 16
    movzx   eax,  word [rbp + DIR_FstClusLO]
    or      r13d, eax                       ; r13d = file's first cluster

    mov     r14d, [rbp + DIR_FileSize]      ; r14d (zero-extends to r14) = file size
    jmp     .load_file

.dir_skip:
    dec     r15d
    add     rbp, 32                         ; advance to next 32-byte entry
    jmp     .dir_entry

.dir_next_cluster:
    call    fat32_next_cluster              ; r13d in → r13d out
    jmp     .dir_cluster

; ========================
; File cluster/sector load
; ========================
.load_file:
    mov     rbp, r12                        ; rbp = write pointer into output buffer

.file_cluster:
    mov     eax, r13d
    and     eax, 0x0FFFFFFF
    cmp     eax, FAT32_EOC
    jae     .load_done                      ; end of cluster chain

    ; Compute LBA of first sector of file cluster r13
    movzx   rax, byte [rel fat32_sectors_per_cluster]
    mov     rbx, r13
    sub     rbx, 2
    imul    rbx, rax
    add     rbx, [rel fat32_data_start_lba]

    movzx   r15d, byte [rel fat32_sectors_per_cluster]

.file_sector:
    test    r15d, r15d
    jz      .file_next_cluster

    dec     r15d
    push    rbx
    push    r15
    mov     rdi, rbx
    mov     rsi, rbp                        ; write directly into output buffer
    call    fat32_read_sector
    pop     r15
    pop     rbx
    test    rax, rax
    jnz     .err

    add     rbp, 512                        ; advance write pointer by one sector
    inc     rbx                             ; advance LBA
    jmp     .file_sector

.file_next_cluster:
    push    r14                             ; preserve file size across FAT read
    call    fat32_next_cluster
    pop     r14
    jmp     .file_cluster

.load_done:
    mov     rax, r14                        ; return file size in bytes
    jmp     .flf_done

.not_found:
.err:
    mov     rax, -1

.flf_done:
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbp
    pop     rbx
    ret
