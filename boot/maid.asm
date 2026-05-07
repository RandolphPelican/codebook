; =============================================================
; Maid — substrate semantic-operations service (Pod 3.5)
;
; The lexical-computation pole of the substrate's surface. Pod 3 sealed
; lexical embedding substrate-prep (typed Embedding pool + accessors);
; Pod 3.5 lands the semantic operations layer that exercises substrate
; over its own content.
;
; Maid is the second Trinity component (per ARCHAEOLOGY): semantic
; housekeeper + codebook maintainer. V1.0 ships compute helpers for
; cosine similarity (primary), dot product, L2 distance, and
; lookup-top-1 over the embedding pool.
;
; Per D3.12 FP determinism doctrine: substrate FP arithmetic uses
; SSE scalar single-precision instructions only.
;   Allowed: movss, mulss, addss, subss, divss, sqrtss, comiss, ucomiss,
;            xorps (sign manipulation), cvtsi2ss, cvtss2si, movd
;   Forbidden: x87 (fld/fmul/faddp/fstp), SIMD-vector (mulps/addps),
;              FMA (vfmadd*), AVX, runtime-rounding-mode-dependent ops
; Bit-exact reproducibility across builds is non-negotiable; two-build
; determinism doctrine extends to FP results. Pod 3.5 establishes the
; substrate's first-ever FP convention at maximum-clarity moment:
; substrate is FP-virgin pre-Pod-3.5; future pods inherit by reading
; D3.12 + grepping the substrate (which has zero forbidden-list
; violations because there was nothing to violate).
;
; Per D3.13 witness doctrine generalization: compute-over-substrate-state
; ops bypass bit-check (Pod 1.10.2b1 D2.1.2 generalized). Cosine/dot/L2/
; lookup execute regardless of current_cap's bitmap. No new BIT_EMBEDDING_*
; bit added; substrate is witness, not police, for read-and-compute paths.
; Only state mutation requires forge bits.
;
; Per D3.14 cosine canonical evaluation order (Form A — separate sqrts):
;   1. dot       = sum_i a[i] * b[i]                    (384 mulss + 383 addss)
;   2. norm_a_sq = sum_i a[i] * a[i]                    (384 mulss + 383 addss)
;   3. norm_b_sq = sum_i b[i] * b[i]                    (384 mulss + 383 addss)
;   4. if norm_a_sq == 0.0f OR norm_b_sq == 0.0f → CF=1 (zero-norm fail)
;   5. norm_a    = sqrtss(norm_a_sq)
;   6. norm_b    = sqrtss(norm_b_sq)
;   7. denom     = norm_a * norm_b                      (mulss)
;   8. cosine    = dot / denom                          (divss)
; Form A's two-sqrt cost vs Form B's one-sqrt is ~30j marginal; stability
; advantage worth it for substrate-permanent reproducibility. The choice
; is bit-exactness-load-bearing: Pod 3.5 HALT 1 R10 empirically demonstrated
; cosine(v_e0, v_45deg) = 0x3F3504F4 (1 ulp from architect's algebraic
; prior 0x3F3504F3) due to Form A's norm_b_sq accumulation through
; (1/sqrt(2))^2 in f32 = 0x3EFFFFFF (rounds DOWN; not exactly 0.5).
; Any drift from Form A produces different bit patterns observable
; empirically; canonical order is THE bit-exactness specification.
;
; Per D3.18 lookup-top-1 MAC-verify-each-candidate: lookup scans pool
; with full MAC verification on each candidate (256 SipHash-over-196-qword
; verifies in worst case). Matches Pod 3 .embedding_accessor_common
; convention; corrupt slots skipped silently; lookup proceeds with
; valid remainder.
;
; Per D3.15 helper factoring + architect HALT 1 implementation note 3:
; helpers take raw slot pointers (post-MAC-verify, post-registry-lookup);
; callers (opcode handlers) do registry resolution + initial MAC verify
; per the existing .embedding_accessor_common pattern. lookup_top1 does
; per-candidate registry+MAC verify in its own loop (D3.18); compute_cosine_raw
; called with raw pointers — no internal re-resolution; saves redundant work.
; Helpers do NOT call .construct_ok_outcome — that's the opcode-handler's
; job. Helpers return primitive values; handlers wrap.
;
; xmm clobber convention micro-extension (HALT 1 implementation note 1):
; substrate's existing register convention is silent on xmm because no
; pre-existing helper has needed FP. Pod 3.5 helpers are first to claim
; xmm registers; doctrine micro-extension lands here. Helpers' clobber
; lists explicitly include xmm0-xmm6 (only registers actually used).
; =============================================================

; --- compute_cosine_raw(rdi=slot_ptr_a, rsi=slot_ptr_b) ---
; Pod 3.5 — D3.14 canonical Form A evaluation. Operates on raw slot
; pointers (post-MAC-verify by caller per D3.15 + D3.18).
;
; Input:    rdi = slot_ptr_a, rsi = slot_ptr_b
; Output:   rax = f32-as-i64 (cosine; 32-bit zero-extended) on success, CF=0
;           rax = 0 (sentinel; high bit clear), CF=1 on zero-norm rejection
; Clobbers: rax, rcx, rdx, r10, r11, xmm0, xmm1, xmm2, xmm3, xmm4, xmm5
; Preserves: rbx, rbp, r12, r13, r14, r15, rsi, rdi (input args remain valid)

compute_cosine_raw:
    ; Step 1: dot = sum_i a[i] * b[i]
    xorps   xmm0, xmm0                              ; dot accumulator
    mov     rcx, EMBEDDING_DIM                      ; 384
    lea     rdx, [rdi + EMBEDDING_OFF_VECTOR]
    lea     r10, [rsi + EMBEDDING_OFF_VECTOR]
.cos_dot_loop:
    movss   xmm1, [rdx]
    mulss   xmm1, [r10]
    addss   xmm0, xmm1
    add     rdx, 4
    add     r10, 4
    dec     rcx
    jnz     .cos_dot_loop
    movss   xmm4, xmm0                              ; xmm4 = dot

    ; Step 2: norm_a_sq = sum_i a[i] * a[i]
    xorps   xmm0, xmm0
    mov     rcx, EMBEDDING_DIM
    lea     rdx, [rdi + EMBEDDING_OFF_VECTOR]
.cos_norma_loop:
    movss   xmm1, [rdx]
    mulss   xmm1, xmm1
    addss   xmm0, xmm1
    add     rdx, 4
    dec     rcx
    jnz     .cos_norma_loop
    movss   xmm5, xmm0                              ; xmm5 = norm_a_sq

    ; Step 3: norm_b_sq = sum_i b[i] * b[i]
    xorps   xmm0, xmm0
    mov     rcx, EMBEDDING_DIM
    lea     rdx, [rsi + EMBEDDING_OFF_VECTOR]
.cos_normb_loop:
    movss   xmm1, [rdx]
    mulss   xmm1, xmm1
    addss   xmm0, xmm1
    add     rdx, 4
    dec     rcx
    jnz     .cos_normb_loop
    ; xmm0 = norm_b_sq; xmm5 = norm_a_sq; xmm4 = dot

    ; Step 4: zero-norm rejection (D3.14 Pre-A7 strict zero check)
    xorps   xmm2, xmm2                              ; xmm2 = 0.0 baseline
    ucomiss xmm5, xmm2                              ; norm_a_sq vs 0.0
    je      .cos_zero_norm_fail                     ; ZF=1 means equal → fail
    ucomiss xmm0, xmm2                              ; norm_b_sq vs 0.0
    je      .cos_zero_norm_fail

    ; Step 5-6: norm_a = sqrt(norm_a_sq); norm_b = sqrt(norm_b_sq)
    sqrtss  xmm5, xmm5                              ; xmm5 = norm_a
    sqrtss  xmm0, xmm0                              ; xmm0 = norm_b

    ; Step 7: denom = norm_a * norm_b
    mulss   xmm5, xmm0                              ; xmm5 = denom

    ; Step 8: cosine = dot / denom
    divss   xmm4, xmm5                              ; xmm4 = cosine

    ; Step 9: return cosine via rax (32-bit zero-extended to 64-bit)
    movd    eax, xmm4                               ; rax upper auto-zeroed
    clc                                             ; CF=0 (success)
    ret

.cos_zero_norm_fail:
    xor     rax, rax                                ; sentinel
    stc                                             ; CF=1 (zero-norm rejection)
    ret

; --- compute_dot_product(rdi=slot_ptr_a, rsi=slot_ptr_b) ---
; Pod 3.5 — D3.X dot product with no normalization, no zero check.
;
; Input:    rdi = slot_ptr_a, rsi = slot_ptr_b
; Output:   rax = f32-as-i64 (dot product; 32-bit zero-extended)
; Clobbers: rax, rcx, rdx, r10, xmm0, xmm1
; Preserves: rbx, rbp, r12-r15, rsi, rdi

compute_dot_product:
    xorps   xmm0, xmm0
    mov     rcx, EMBEDDING_DIM
    lea     rdx, [rdi + EMBEDDING_OFF_VECTOR]
    lea     r10, [rsi + EMBEDDING_OFF_VECTOR]
.dot_loop:
    movss   xmm1, [rdx]
    mulss   xmm1, [r10]
    addss   xmm0, xmm1
    add     rdx, 4
    add     r10, 4
    dec     rcx
    jnz     .dot_loop
    movd    eax, xmm0
    ret

; --- compute_l2_distance(rdi=slot_ptr_a, rsi=slot_ptr_b) ---
; Pod 3.5 — D3.X L2 distance via diff-square accumulation + sqrt.
;
; Input:    rdi = slot_ptr_a, rsi = slot_ptr_b
; Output:   rax = f32-as-i64 (L2 distance; 32-bit zero-extended)
; Clobbers: rax, rcx, rdx, r10, xmm0, xmm1
; Preserves: rbx, rbp, r12-r15, rsi, rdi

compute_l2_distance:
    xorps   xmm0, xmm0                              ; diff_sq accumulator
    mov     rcx, EMBEDDING_DIM
    lea     rdx, [rdi + EMBEDDING_OFF_VECTOR]
    lea     r10, [rsi + EMBEDDING_OFF_VECTOR]
.l2_loop:
    movss   xmm1, [rdx]
    subss   xmm1, [r10]                             ; (a[i] - b[i])
    mulss   xmm1, xmm1                              ; (a[i] - b[i])^2
    addss   xmm0, xmm1
    add     rdx, 4
    add     r10, 4
    dec     rcx
    jnz     .l2_loop
    sqrtss  xmm0, xmm0                              ; xmm0 = sqrt(diff_sq)
    movd    eax, xmm0
    ret

; --- lookup_top1(rdi=query_slot_ptr) ---
; Pod 3.5 — D3.18 MAC-verify-each-candidate top-1 lookup.
; Iterates 1..vm_embedding_next; for each candidate (excluding query):
;   resolve via registry_lookup_embedding → MAC verify → cosine vs query →
;   track best_score / best_id. Corrupt slots silently skipped.
; Returns 0 if pool empty / only-self / all candidates corrupt.
;
; Input:    rdi = query_slot_ptr (post-MAC-verify by caller)
; Output:   rax = best_match_embedding_id (0 if none)
; Clobbers: rax, rcx, rdx, r10, r11, xmm0-xmm6
; Preserves: rbx, rbp, r12, r13, r14, r15 (saved/restored via push/pop bracket)

lookup_top1:
    push    rbp
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15

    mov     rbx, rdi                                ; rbx = query_slot_ptr (preserved across calls)
    mov     r15, [rdi + EMBEDDING_OFF_ID_SELF]      ; r15 = query_id (for self-skip)

    ; Initialize best state
    xor     r12, r12                                ; r12 = best_id = 0
    mov     eax, 0xFF800000                         ; -infinity bit pattern
    movd    xmm6, eax                               ; xmm6 = best_score = -infinity (preserved across compute_cosine_raw)

    ; Loop bounds: 1..vm_embedding_next (inclusive)
    mov     r14, [rel vm_embedding_next]            ; r14 = upper bound (count of allocated slots; ids 1..r14)
    test    r14, r14
    jz      .lookup_done                            ; empty pool

    mov     r13, 1                                  ; r13 = current embed_id (1-based)

.lookup_loop:
    cmp     r13, r14
    jg      .lookup_done                            ; r13 > vm_embedding_next, done

    cmp     r13, r15
    je      .lookup_skip                            ; embed_id == query_id, skip self

    ; Resolve candidate via registry_lookup_embedding
    mov     rdi, r13
    call    registry_lookup_embedding               ; rax = slot_ptr or 0
    test    rax, rax
    jz      .lookup_skip                            ; sentinel/missing

    ; MAC verify candidate (D3.18 per-candidate MAC verify)
    push    rax                                     ; preserve candidate slot_ptr across siphash
    mov     rdi, rax
    mov     rsi, EMBEDDING_MAC_INPUT_QWORDS
    call    siphash_compute                         ; rax = recomputed MAC; preserves rdi (per registry contract; siphash uses rdi/rsi but loads from [rdi])
    pop     rdi                                     ; rdi = candidate slot_ptr
    cmp     rax, [rdi + EMBEDDING_OFF_MAC]
    jne     .lookup_skip                            ; MAC mismatch, skip silently

    ; Compute cosine(query_slot, candidate_slot)
    mov     rsi, rdi                                ; rsi = candidate_slot_ptr
    mov     rdi, rbx                                ; rdi = query_slot_ptr
    call    compute_cosine_raw                      ; rax = f32-as-i64; CF=1 on zero-norm
    jc      .lookup_skip                            ; zero-norm rejection (e.g., candidate is zero vector); skip silently

    ; Compare score to best_score
    movd    xmm0, eax                               ; xmm0 = score
    ucomiss xmm0, xmm6                              ; score vs best_score
    jbe     .lookup_skip                            ; score <= best_score, skip (ties go to first-encountered)

    ; New best
    movss   xmm6, xmm0                              ; best_score = score
    mov     r12, r13                                ; best_id = embed_id

.lookup_skip:
    inc     r13
    jmp     .lookup_loop

.lookup_done:
    mov     rax, r12                                ; return best_id (0 if none found)
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret
