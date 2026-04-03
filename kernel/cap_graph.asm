; =============================================================================
; Capability Graph + Energy Budgeting for CodebookOS
; =============================================================================
;
; New VM Opcodes:
;   OP_GRANT_CAP (0xCA000003) - Grants a capability and energy budget.
;   OP_USE_CAP       (0xCA000004) - Uses a capability and deducts energy.
;
; Data Structures:
;   cap_graph: Array of nodes (parent, child, cap_bitmap, energy_budget).
;   cap_root:  Root node (energy budget = total system energy).

; --- Constants ---
MAX_CAP_NODES         equ 64      ; Max capability nodes
CAP_ROOT_TOKEN        equ 0xFFFFFFFF

; --- Capability Bitmap ---
CAP_READ              equ 1 << 0
CAP_WRITE             equ 1 << 1
CAP_EXEC              equ 1 << 2
CAP_GPU               equ 1 << 3
CAP_NETWORK           equ 1 << 4
; ... Add more as needed

; --- Capability Node ---
struc CAP_NODE
    .parent_token    resd 1
    .child_token     resd 1
    .cap_bitmap      resd 1
    .energy_budget   resd 1  ; Energy units (0-100%)
    .energy_used     resd 1
endstruc

; --- Global State ---
cap_graph: times CAP_NODE_size * MAX_CAP_NODES db 0
cap_next_index: dd 0
cap_root: CAP_NODE

; =============================================================================
; cap_init: Initializes the root capability node.
; =============================================================================
cap_init:
    ; Root node: no parent, energy = 10000 (arbitrary)
    mov dword [cap_root + CAP_NODE.parent_token], CAP_ROOT_TOKEN
    mov dword [cap_root + CAP_NODE.child_token], 0
    mov dword [cap_root + CAP_NODE.cap_bitmap], 0xFFFFFFFF  ; All caps
    mov dword [cap_root + CAP_NODE.energy_budget], 10000
    mov dword [cap_root + CAP_NODE.energy_used], 0
    ret

; =============================================================================
; cap_grant: OP_GRANT_CAP (0xCA000003)
; Input:  EDI = parent token, ESI = child token, EDX = cap_bitmap, ECX = energy_budget
; Output: EAX = 0 on success, error code on failure.
; =============================================================================
cap_grant:
    ; 1. Check parent has enough energy
    call cap_get_node
    test eax, eax
    jz .error_invalid_parent

    mov ebx, eax
    mov eax, [ebx + CAP_NODE.energy_budget]
    sub eax, ecx
    jl .error_insufficient_energy

    ; 2. Allocate new node for child
    call cap_alloc_node
    test eax, eax
    jz .error_no_space

    ; 3. Link child to parent
    mov [eax + CAP_NODE.parent_token], edi
    mov [eax + CAP_NODE.child_token], esi
    mov [eax + CAP_NODE.cap_bitmap], edx
    mov [eax + CAP_NODE.energy_budget], ecx
    mov [eax + CAP_NODE.energy_used], 0

    ; 4. Deduct energy from parent
    mov [ebx + CAP_NODE.energy_budget], eax

    ; 5. Return success
    xor eax, eax
    ret

.error_invalid_parent:
.error_insufficient_energy:
.error_no_space:
    mov eax, -1
    ret

; =============================================================================
; cap_use: OP_USE_CAP (0xCA000004)
; Input:  EDI = token, ESI = cap_bit (e.g., CAP_GPU)
; Output: EAX = 0 on success, error code on failure.
; =============================================================================
cap_use:
    ; 1. Check token exists and has cap
    call cap_get_node
    test eax, eax
    jz .error_invalid_token

    ; 2. Check token has energy
    mov ebx, eax
    mov eax, [ebx + CAP_NODE.energy_budget]
    sub eax, [ebx + CAP_NODE.energy_used]
    jle .error_insufficient_energy

    ; 3. Check capability is granted
    mov ecx, [ebx + CAP_NODE.cap_bitmap]
    test ecx, esi
    jz .error_cap_not_granted

    ; 4. Deduct energy
    mov edx, [ebx + CAP_NODE.energy_used]
    add edx, 100  ; Fixed cost per use (adjust as needed)
    mov [ebx + CAP_NODE.energy_used], edx

    ; 5. Check spatial merge: if parent has same cap, deduct from parent too
    mov edi, [ebx + CAP_NODE.parent_token]
    call cap_get_node
    test eax, eax
    jz .success  ; No parent or parent doesn't have cap

    mov ecx, [eax + CAP_NODE.cap_bitmap]
    test ecx, esi
    jz .success

    ; Deduct from parent too
    mov edx, [eax + CAP_NODE.energy_used]
    add edx, 50   ; Half cost for spatial merge
    mov [eax + CAP_NODE.energy_used], edx

.success:
    xor eax, eax
    ret

.error_invalid_token:
.error_insufficient_energy:
.error_cap_not_granted:
    mov eax, -1
    ret

; =============================================================================
; cap_get_node: Returns pointer to node for given token.
; Input:  EDI = token
; Output: EAX = node pointer, or 0 if not found.
; =============================================================================
cap_get_node:
    ; (Iterate through cap_graph to find token)
    ; For now: Assume token 0 is root, tokens 1-63 are in graph
    cmp edi, CAP_ROOT_TOKEN
    je .is_root
    cmp edi, 0
    je .is_root
    ; ... (real implementation scans cap_graph)
    xor eax, eax
    ret
.is_root:
    lea eax, [cap_root]
    ret

; =============================================================================
; cap_alloc_node: Allocates a new node in cap_graph.
; Output: EAX = node pointer, or 0 if no space.
; =============================================================================
cap_alloc_node:
    mov ecx, [cap_next_index]
    cmp ecx, MAX_CAP_NODES
    jge .error_no_space

    lea eax, [cap_graph + ecx * CAP_NODE_size]
    inc dword [cap_next_index]
    ret
.error_no_space:
    xor eax, eax
    ret