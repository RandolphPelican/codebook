; =============================================================
; VM Runtime Data — Stack, Vars, Energy, Memory Map
; Engywook's notebook. The state he keeps to know whether the
; rules are being honored.
; Labels: energy_budget, energy_used, vm_ret_ptr, vm_ret_stack,
;         vm_stack, vm_vars, vm_sign_pool, vm_sign_next,
;         vm_energy_pool, vm_energy_next, mmap_buf
; Layer:  Layer 1 — VM runtime (kept separate from cbs_vm.asm so
;         Pod 1 can extend without touching opcode handlers)
; =============================================================

    align 16
; Pod 3.5 D3.24 — substrate metabolic ceiling scales with op tier introduction.
; Pod 0-3 substrate ops were ≤100j tier; default 100,000j was sufficient.
; Pod 3.5 introduces 100-400j compute tier (cosine/dot/l2) + 100,000j composite
; tier (lookup_top1). Default scaled 10× to 1,000,000j to accommodate compute-tier
; dispatch (r14 binds dispatch independent of cap.energy_budget per HALT 2B
; C2-redux finding: substrate r14 and cap budgets are orthogonal authority
; mechanisms; sub-cap entry doesn't reset r14). Twelfth architect-error doctrine
; landing (subtype "substrate-vs-cap budget model conflation") drove this scaling.
energy_budget: dq 1000000
energy_used:   dq 0
; Pod 1.9.2a — Substrate fetch counter (D1.9.1.7; closes ProvEvent gap
; declared in Pod 1.8.5c). Increments once per opcode fetch at .fetch
; loop head in cbs_vm.asm. Read by OP_OUTCOME_NEW_ERR (1.9.2b) for
; prov_append fetch_counter parameter; also useful for substrate audit.
vm_fetch_count: dq 0
vm_ret_ptr:     dq 0
vm_ret_stack:   times 256 dq 0
; Pod 1.10.2a — cap_stack (D1.10.1.4 / E2 / D1.10.2a.4)
;   256-entry parallel to vm_ret_stack. Substrate-stack precedent grouping.
;   1.10.2a declares; 1.10.2b first-consumes via OP_CAP_ENTER/EXIT.
;   Doctrine note: future-consumed declared state distinct from
;   vm_fetch_count gap pattern (declared substrate state with no planned
;   consumer). cap_stack is structurally part of Cap substrate.
cap_stack_ptr:  dq 0
cap_stack:      times CAP_STACK_DEPTH dq 0
vm_stack:   times 512 dq 0     ; 4KB VM stack
vm_vars:    times 64 dq 0      ; 512 bytes variables (64-bit, Pod 1.5)

; Sign pool (64 nodes × 128 bytes = 8KB, Pod 1.7;
;            named constants applied Pod 1.8.5b for Energy parity)
    align 16
vm_sign_pool:   times SIGN_POOL_SLOTS * SIGN_SLOT_SIZE db 0
vm_sign_next:   dq 0            ; bump allocator index (next free slot)

; Energy pool (64 nodes x 128 bytes = 8KB, Pod 1.8)
    align 16
vm_energy_pool:  times ENERGY_POOL_SLOTS * ENERGY_SLOT_SIZE db 0
vm_energy_next:  dq 0            ; bump allocator index (next free slot)

; Outcome pool (Pod 1.9.2a — D1.9.1.5 inline error context;
;               64 slots × 128 bytes = 8KB; bump-allocator)
    align 16
vm_outcome_pool: times OUTCOME_POOL_SLOTS * OUTCOME_SLOT_SIZE db 0
vm_outcome_next: dq 0            ; bump allocator index (next free slot)

; Cap pool (Pod 1.10.2a — D1.10.1.13; 64 slots × 128 bytes = 8KB; bump-allocator)
    align 16
vm_cap_pool: times CAP_POOL_SLOTS * CAP_SLOT_SIZE db 0
vm_cap_next: dq 0                ; bump allocator index (next free slot)

; Embedding pool (Pod 3 — D3.1; 64 slots × 1576 bytes = ~100KB; bump-allocator)
;   Fifth typed pool. Slot is MAC-protected (full vector under SipHash per D3.3).
;   Substrate-prep mode: pool + accessors land at this pod; semantic operations
;   (similarity, lookup-by-meaning) deferred to Pod 3.5+.
    align 16
vm_embedding_pool: times EMBEDDING_POOL_SLOTS * EMBEDDING_SLOT_BYTES db 0
vm_embedding_next: dq 0                ; bump allocator index (next free slot)

; Sign embedding-handle side-table (Pod 3 — D3.4; DEFERRED #65 resolution)
;   Parallel BSS array indexed by (sign_id - 1). Tracks Sign->Embedding linkage
;   without expanding Sign slot. SIGN_OFF_CREATOR_CAP_ID at +0x68 was reclaimed
;   from the original embedding_handle slot at Pod 1.10.2b2; this side-table
;   provides the linkage in a parallel structure matching Sign's existing
;   non-MAC integrity model. Initial value 0 = no embedding linked
;   (preserves backward-compat for all pre-Pod-3 Sign demos).
    align 16
vm_sign_embedding_handle: times SIGN_POOL_SLOTS dq 0

; Embedding reverse side-table (Pod 3.5 — D3.20; reverse of D3.4 forward direction)
;   Parallel BSS array indexed by (embedding_id - 1). Tracks Embedding->Sign linkage
;   for O(1) recovery of "which Sign owns this embedding". Written at OP_SIGN_NEW
;   post-registry_register_sign WHEN embedding_handle != 0:
;       vm_embedding_sign_handle[(embedding_handle - 1) * 8] = sign_id
;   Read via OP_EMBEDDING_SIGN_HANDLE accessor (0xC5). Returns 0 if no Sign linked.
;   Sized to EMBEDDING_POOL_SLOTS (256 post-Pod-3.5 expansion); 256 × 8 = 2048 bytes.
    align 16
vm_embedding_sign_handle: times EMBEDDING_POOL_SLOTS dq 0

; Sign registry (Pod 1.8.5b — Move 4)
;   Maps sign_id (opaque counter, 1-based) -> slot pointer (u64).
;   Each entry = {id: u64, slot_ptr: u64} = 16 bytes.
;   Capacity matches vm_sign_pool. ID 0 reserved as null.
    align 16
sign_registry_count:   dq 0
sign_registry_next_id: dq 1
sign_registry:         times SIGN_POOL_SLOTS * 16 db 0

; Energy registry (Pod 1.8.5b — Move 4)
;   Mirrors sign_registry shape. Capacity matches vm_energy_pool.
    align 16
energy_registry_count:   dq 0
energy_registry_next_id: dq 1
energy_registry:         times ENERGY_POOL_SLOTS * 16 db 0

; Outcome registry (Pod 1.9.2a; D1.9.1.1 + Pod 1.8.5b registry pattern)
;   Maps outcome_id (opaque counter, 1-based) -> slot pointer (u64).
;   Each entry = {id: u64, slot_ptr: u64} = 16 bytes.
;   Capacity matches vm_outcome_pool. ID 0 = OUTCOME_ID_NULL reserved.
    align 16
outcome_registry_count:   dq 0
outcome_registry_next_id: dq 1
outcome_registry:         times OUTCOME_POOL_SLOTS * 16 db 0

; Cap registry (Pod 1.10.2a; D1.10.1.13 + Pod 1.8.5b registry pattern)
;   Maps cap_id -> slot pointer. Capacity matches vm_cap_pool.
;   ROOT_CAP_ID=1 claims first allocation at boot.
    align 16
cap_registry_count:   dq 0
cap_registry_next_id: dq 1   ; ID 0 reserved as CAP_ID_NULL; ROOT_CAP claims id=1
cap_registry:         times CAP_POOL_SLOTS * 16 db 0

; Embedding registry (Pod 3; mirrors Pod 1.8.5b registry pattern)
;   Maps embedding_id -> slot pointer. Capacity matches vm_embedding_pool.
;   ID 0 = EMBEDDING_ID_NULL reserved.
    align 16
embedding_registry_count:   dq 0
embedding_registry_next_id: dq 1
embedding_registry:         times EMBEDDING_POOL_SLOTS * 16 db 0

; Pod 1.8.5c Move 7 — current VM phase (SEED at boot, advances through MIND)
    align 16
vm_phase: dq VM_PHASE_SEED

; Pod 1.8.5c Move 1 + Move 2 — current demod runtime state
;   V1.0 singleton placeholder. Pod 1.12 (Demod<S>) replaces with real
;   per-demod state. cost_table_ptr is initialized to energy_cost_table
;   at runtime in efi_entry (NASM -f bin cannot resolve dq <symbol>
;   to a runtime virtual address; static init would store a file offset
;   that dereferences to garbage). prov_enabled is cap-flag-gated
;   (Move 2), default OFF.
    align 16
current_demod_cost_table_ptr:  dq 0
current_demod_prov_enabled:    dq 0

; Pod 1.10.2a — current Cap singleton state (D1.10.1.13)
;   current_cap_id initialized to ROOT_CAP_ID=1 (substrate bootstrap).
;   Cache fields mirror current_cap slot's +0x08 / +0x10 for fast access
;   in Sign/Energy/Outcome allocator retrofit at Pod 1.10.2b.
    align 16
current_cap_id:                    dq 1   ; initialized to ROOT_CAP_ID
current_cap_arena_id_cache:        dq 0
current_cap_owner_demod_id_cache:  dq 0

; Pod 2.1 — Babylon spatial-merge cost stash (D2.1 / A1 ratification)
; Stashed at fetch loop after energy_cost_lookup; read at construction
; sites by handlers and helpers as the dispatching opcode's cost.
; Generalizable forward-anchor: any future substrate-internal operation
; that needs to know the cost of the operation triggering it reads
; current_dispatch_cost.
current_dispatch_cost:             dq 0

; Pod 1.10.2a — substrate crypto state (D1.10.1.6 / D1.10.1.7)
;   siphash_key derived at boot via RDSEED → RDRAND → hard-fail per
;   D1.10.1.6 / A1 ratification. siphash_key_source flag preserves
;   the entropy source for audit (0=rdseed, 1=rdrand). Self-test scratch
;   space holds the saved key during boot-time verification (E1).
    align 16
siphash_key:               dq 0, 0    ; 128-bit key (filled at boot)
siphash_key_source:        dq 0       ; 0=rdseed, 1=rdrand (qword for alignment)
siphash_key_save:          dq 0, 0    ; saved during siphash_self_test_run (E1)
siphash_self_test_input:   dq 0       ; 1-qword test input for self-test
root_cap_mac_save:         dq 0       ; saved during verify_root_cap_mac (E3)

; Pod 1.8.5c Move 2 — provenance ring buffer (4KB, 128 entries × 32 bytes)
;   Overwrite-on-full. prov_ring_head is the next write index, masked
;   by PROV_RING_MASK. V1.0 ships the conduit; Pod 2 (Cop) wires
;   automatic invocation behind cap grant.
    align 16
prov_ring_head: dq 0
prov_ring_buf:  times PROV_RING_ENTRIES * PROV_EVENT_SIZE db 0

; Memory map buffer (8KB)
    align 16
mmap_buf:   times 8192 db 0
