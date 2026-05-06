; =============================================================
; Babylon — substrate metabolic-accountant (Pod 2.1)
;
; The cost-ledger pole of the substrate's metaphysical surface.
; ROOT_CAP is generative anchor (unbounded budget, source); Babylon
; is extractive accountant (cost ledger, exponential decay, federation
; total). Together they form the federation's full surface — programs
; traverse from ROOT's domain (where authority is given) to Babylon's
; accounting (where authority's exercise is measured).
;
; Cop renamed to Babylon at Pod 2.1 canon supersession (D2.1.1).
; v3 manifesto inherited "Cop" from earlier capability-security
; thinking; Pod 1.10.2b1 made Cop's policing role vestigial; this
; pod names the metabolic-accountant role honestly. Truth-in-naming
; all the way down per D1.10.2b1.1 / D1.10.2b2.1 doctrine extension.
;
; Spatial-merge fires after every successful primitive construction
; site (Sign×1, Energy×1, Outcome×4 paths, Cap×1 — 7 sites total
; per R2 enumeration). Walks up the originating cap's parent chain,
; charging each ancestor energy_used += cost / 2^depth via floor
; division. Geometric series; deep-tail rounds to zero, natural
; early termination.
;
; Per Pre-A6 / D2.1.6: spatial-merge is 0j substrate bookkeeping.
; The walk-up is post-construction work; not visible to operand-stack
; cost accounting; canaries hold verbatim.
;
; Per Pre-A5 / D2.1.5: no MAC verify on ancestors. Substrate-private
; bookkeeping; parent_cap_id pointers were stamped at construction
; time and protected by originating cap's MAC. babylon_charge_lineage
; reads parent_cap_id and writes energy_used at substrate-private speed.
;
; Per Pre-A4 / D2.1.4: ROOT_CAP accumulates federation total. Walk-up
; terminates when parent_cap_id = 0 (ROOT's parent sentinel).
; Programs reading OP_CAP_USED(ROOT_CAP_ID) see substrate's running
; accounting weight summary.
; =============================================================

; --- babylon_charge_lineage(rdi=cost, rsi=originating_cap_id) ---
; Walks up originating cap's parent chain, charging each ancestor
; energy_used += halved cost via floor division.
;
; Walk semantics:
;   1. Look up originating cap → get its parent_cap_id (first ancestor)
;   2. While ancestor != 0:
;        halve cost (shr 1; floor div)
;        if cost == 0: early-terminate (deep-tail rounds away)
;        look up ancestor slot
;        add halved cost to ancestor's energy_used
;        advance to next ancestor via that ancestor's parent_cap_id
;   3. Terminate when ancestor = 0 (ROOT's parent sentinel)
;
; Originating cap doesn't charge itself. Walk starts at parent.
; ROOT-context operations (originating = ROOT) terminate immediately
; (ROOT.parent_cap_id = 0 by construct_root_cap construction).
;
; Input:    rdi = cost in joules (typically [rel current_dispatch_cost])
;           rsi = originating_cap_id (typically [rel current_cap_id])
; Output:   none (side effects on ancestor slots' energy_used field)
; Clobbers: rax, rcx, rdx, rsi, rdi
; Preserves: r12, r13, r14, r15, rbx, rbp (caller VM state survives)

babylon_charge_lineage:
    ; Look up originating cap to get its parent_cap_id (first ancestor)
    push    rdi                              ; preserve cost across registry call
    mov     rdi, rsi
    call    registry_lookup_cap              ; rax = slot_ptr or 0
    pop     rdi                              ; restore cost
    test    rax, rax
    jz      .babylon_done                    ; broken originating (defensive)

    mov     rcx, [rax + CAP_OFF_PARENT_CAP_ID]  ; rcx = first ancestor cap_id

.babylon_loop:
    test    rcx, rcx
    jz      .babylon_done                    ; reached ROOT.parent=0; chain end
    shr     rdi, 1                           ; halve cost (floor div)
    jz      .babylon_done                    ; cost decayed to 0; deep-tail rounds away

    ; Look up ancestor slot
    push    rdi                              ; preserve halved cost
    push    rcx                              ; preserve current ancestor id
    mov     rdi, rcx
    call    registry_lookup_cap              ; rax = ancestor slot_ptr or 0
    pop     rcx
    pop     rdi
    test    rax, rax
    jz      .babylon_done                    ; broken lineage (defensive)

    ; Charge ancestor and advance
    add     [rax + CAP_OFF_ENERGY_USED], rdi
    mov     rcx, [rax + CAP_OFF_PARENT_CAP_ID]
    jmp     .babylon_loop

.babylon_done:
    ret

; --- babylon_check_authority(rdi=required_bit_mask, rsi=cap_id) ---
; Pod 2.2 — Babylon's second helper. Substrate-private bit-check at
; primitive-forge dispatch sites. Verifies that the named cap's slot
; carries all bits in required_bit_mask.
;
; Per D2.2.X / Pod 1.10.2b1 D2.1.5 substrate-private convention: no MAC
; verify on the current cap. current_cap_id is canonical (validated at
; OP_CAP_ENTER); cap_bitmap is in MAC-input range and was protected at
; construction time by originating cap's MAC.
;
; Per D2.2.9 substrate-bookkeeping doctrine extension (sixth empirical
; landing — D1.9.2b.1 → D1.10.2a.7 → D1.10.2b2.3 → D1.10.3 → D2.1.6 →
; D2.2.9): 0j cost. Single registry lookup + AND + CMP + JNE; no
; operand-stack-visible work.
;
; Asymmetry with babylon_charge_lineage worth noting at HALT 2C:
;   - charge_lineage fires at all 7 successful primitive construction
;     sites (every act of creation has metabolic cost)
;   - check_authority fires at 5 dispatch sites (every program-driven
;     authority exercise — the 4 primitive-forge dispatches plus
;     OP_CAP_NEW; accessor/observation paths bypass per D2.1.2)
;
; Input:    rdi = required_bit_mask
;           rsi = cap_id (typically [rel current_cap_id])
; Output:   rax = 0 (authority sufficient) or rax = 1 (insufficient/broken)
; Clobbers: rax, rcx, rsi, rdi (matches babylon_charge_lineage convention)
; Preserves: r12, r13, r14, r15, rbx, rbp (caller VM state survives)

babylon_check_authority:
    push    rdi                              ; preserve required_bit_mask across registry call
    mov     rdi, rsi
    call    registry_lookup_cap              ; rax = slot_ptr or 0
    pop     rdi                              ; restore required_bit_mask
    test    rax, rax
    jz      .babylon_authority_fail          ; broken cap_id → fail-safe
    mov     rcx, [rax + CAP_OFF_BITMAP]
    and     rcx, rdi
    cmp     rcx, rdi
    jne     .babylon_authority_fail          ; required bits not all set
    xor     rax, rax                         ; ok
    ret
.babylon_authority_fail:
    mov     rax, 1
    ret
