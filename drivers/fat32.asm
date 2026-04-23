; =============================================================
; FAT32 Read-Only Driver
; fat32_init, fat32_read_sector, fat32_load_file
; No UEFI dependency. Ring 0 required (IN/OUT instructions).
; Primary IDE PIO channel only (ports 0x1F0-0x1F7, 28-bit LBA).
;
; Exports: fat32_init, fat32_read_sector, fat32_load_file,
;          fat32_next_cluster, fat32_parse_name83
; Data:    fat32_* variables declared in boot/data.asm
;
; Write support lives in drivers/_future/fat32_write.asm
; pending V1.1 smoke-testing. Core concept preserved.
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
