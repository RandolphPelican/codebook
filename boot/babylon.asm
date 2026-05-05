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
