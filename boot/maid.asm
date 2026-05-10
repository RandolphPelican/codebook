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

; --- compute_top_k_raw(rdi=query_slot_ptr, rsi=K, rdx=threshold_f32_as_i64) → rax = K' ---
; Pod 3.9 — D3.35 housekeeper-tier generalization of compute_lookup_top1.
;
; Iterates 1..vm_embedding_next; for each candidate (excluding query_id):
;   resolve via registry_lookup_embedding → MAC verify → cosine vs query →
;   if score >= threshold AND insertion conditions met: write into BSS scratch.
; After scan: selection-sort scratch[0..K'-1] descending; return K' in rax.
;
; Sorted-array K-tracking via find-min-replace (not insertion sort during
; collection): scratch is unsorted while collecting; min-tracked via linear
; scan when array is full and a new candidate qualifies. Final O(K²) selection
; sort places in descending cosine order before return. For K ≤ 32 typical,
; total cost dominated by N × cosine compute (per-candidate ~400j); K-tracking
; overhead negligible (D3.X cost framing matches lookup_top1 100,000j).
;
; Threshold semantics: score >= threshold (inclusive comparison via ucomiss).
; Threshold = -INF sentinel (0xFF800000 f32 bit pattern) → unfiltered top-K
; (any finite score passes; -INF >= -INF holds via IEEE 754).
;
; K silently clamped to MAX_K (=256) at helper entry. Caller (handler in Pod 3.9.D)
; expected to validate K ≤ MAX_K and return Err(InvalidEmbeddingArg) if exceeded;
; helper-side clamp is defensive (protects scratch bounds against caller bugs).
;
; Substrate-state side effects: top_k_scratch_ids[0..K'-1] populated with
; embedding_ids in descending-cosine order; top_k_scratch_scores[0..K'-1]
; populated with corresponding f32 scores. Handler (3.9.D) reads these and
; pushes K' ids + count onto operand stack; this helper does NOT touch operand
; stack (substrate-private; mirrors compute_*_raw convention).
;
; Input:    rdi = query_slot_ptr (post-MAC-verify by caller per D3.18 / D3.15)
;           rsi = K (max number of results; clamped to MAX_K)
;           rdx = threshold (f32-as-i64; only low 32 bits used)
; Output:   rax = K' (count of results; ≤ K)
;           Side effect: top_k_scratch_ids + top_k_scratch_scores populated
; Clobbers: rcx, rdx, rsi, rdi, r8-r11, xmm0-xmm5
; Preserves: rbx, rbp, r12-r15, xmm6-xmm15 (saved/restored via push/pop bracket)

compute_top_k_raw:
    push    rbx
    push    rbp
    push    r12
    push    r13
    push    r14
    push    r15

    mov     rbx, rdi                                ; rbx = query_slot_ptr (preserved across calls)
    mov     r15, [rdi + EMBEDDING_OFF_ID_SELF]      ; r15 = query_id (for self-skip)

    ; Clamp K to MAX_K (defensive; handler should validate but belt+suspenders)
    mov     rax, MAX_K
    cmp     rsi, rax
    cmovg   rsi, rax
    mov     rbp, rsi                                ; rbp = clamped K

    ; Stash threshold in xmm6 (preserved across compute_cosine_raw clobbers xmm0-5)
    movd    xmm6, edx                               ; xmm6 = threshold (low 32 of rdx)

    ; K' = 0 (running result count)
    xor     r12, r12                                ; r12 = K' (preserved across loop)

    ; K = 0 → return 0 immediately
    test    rbp, rbp
    jz      .top_k_done

    ; Empty pool → return 0
    mov     r14, [rel vm_embedding_next]
    test    r14, r14
    jz      .top_k_done

    mov     r13, 1                                  ; r13 = current candidate id (1-based)

.top_k_loop:
    cmp     r13, r14
    jg      .top_k_scan_done                         ; scanned all candidates → sort + return

    cmp     r13, r15
    je      .top_k_skip                              ; embed_id == query_id, self-skip

    ; Resolve candidate via registry_lookup_embedding
    mov     rdi, r13
    call    registry_lookup_embedding               ; rax = slot_ptr or 0; rdi preserved
    test    rax, rax
    jz      .top_k_skip                              ; not found, silent skip

    ; MAC verify candidate (D3.18 per-candidate verification)
    push    rax                                     ; preserve candidate slot_ptr across siphash
    mov     rdi, rax
    mov     rsi, EMBEDDING_MAC_INPUT_QWORDS
    call    siphash_compute                         ; rax = MAC; rdi preserved per siphash contract
    pop     rdi                                     ; rdi = candidate slot_ptr
    cmp     rax, [rdi + EMBEDDING_OFF_MAC]
    jne     .top_k_skip                              ; MAC mismatch silent skip

    ; Compute cosine(query, candidate)
    mov     rsi, rdi                                ; rsi = candidate slot_ptr
    mov     rdi, rbx                                ; rdi = query slot_ptr
    call    compute_cosine_raw                      ; rax = score (f32-as-i64); CF=1 on zero-norm
    jc      .top_k_skip                              ; zero-norm rejection (silent skip)

    ; Threshold check: score >= threshold (inclusive)
    movd    xmm0, eax                               ; xmm0 = score
    ucomiss xmm0, xmm6                              ; score vs threshold
    jb      .top_k_skip                              ; score < threshold, skip

    ; Score qualifies. Insert into scratch.
    cmp     r12, rbp
    jge     .top_k_array_full                        ; K' == K, find-min-replace

    ; Array not full: append at scratch[K']
    ; (NASM `[rel sym + reg*scale]` does NOT generate correct code; use lea+base then [base + idx*scale])
    lea     r10, [rel top_k_scratch_ids]
    mov     [r10 + r12*8], r13                       ; scratch_ids[K'] = candidate_id
    lea     r10, [rel top_k_scratch_scores]
    movss   [r10 + r12*4], xmm0                      ; scratch_scores[K'] = score
    inc     r12
    jmp     .top_k_skip

.top_k_array_full:
    ; Array full (K'==K). Find min in scratch_scores[0..rbp-1]; replace if score > min.
    lea     r11, [rel top_k_scratch_scores]          ; r11 = scores base (no helper calls in this path)
    xor     rcx, rcx                                ; rcx = scan_idx
    xor     r9, r9                                  ; r9 = min_idx
    movss   xmm1, [r11]                             ; xmm1 = current min (start with [0])
.find_min_loop:
    cmp     rcx, rbp
    jge     .find_min_done
    movss   xmm2, [r11 + rcx*4]
    ucomiss xmm1, xmm2
    jbe     .find_min_skip                           ; xmm1 <= xmm2, no update
    ; xmm1 > xmm2; xmm2 is new min
    movss   xmm1, xmm2
    mov     r9, rcx
.find_min_skip:
    inc     rcx
    jmp     .find_min_loop
.find_min_done:
    ; xmm1 = min_score; r9 = min_idx
    ucomiss xmm0, xmm1                              ; new score vs min
    jbe     .top_k_skip                              ; score <= min, don't replace
    ; New score > min; replace at min_idx
    lea     r10, [rel top_k_scratch_ids]
    mov     [r10 + r9*8], r13
    movss   [r11 + r9*4], xmm0                      ; r11 still scores base from find-min

.top_k_skip:
    inc     r13
    jmp     .top_k_loop

.top_k_scan_done:
    ; Selection sort scratch[0..K'-1] descending (one-time post-collection cost)
    test    r12, r12
    jz      .top_k_done                              ; K' == 0, nothing to sort
    ; lea bases (no helper calls in sort path; r10/r11 freely usable)
    lea     r10, [rel top_k_scratch_ids]             ; r10 = ids base
    lea     r11, [rel top_k_scratch_scores]          ; r11 = scores base
    xor     r8, r8                                  ; r8 = i (outer loop)
.sort_outer:
    cmp     r8, r12
    jge     .top_k_done
    mov     r9, r8                                  ; r9 = max_idx (initially i)
    movss   xmm0, [r11 + r8*4]                      ; xmm0 = max_score (initially scratch[i])
    mov     rcx, r8
    inc     rcx                                     ; rcx = j (inner loop)
.sort_inner:
    cmp     rcx, r12
    jge     .sort_swap
    movss   xmm1, [r11 + rcx*4]
    ucomiss xmm1, xmm0                              ; scratch[j] vs max
    jbe     .sort_inner_skip                         ; scratch[j] <= max
    movss   xmm0, xmm1                              ; new max
    mov     r9, rcx
.sort_inner_skip:
    inc     rcx
    jmp     .sort_inner
.sort_swap:
    cmp     r9, r8
    je      .sort_outer_advance                      ; max_idx == i, no swap

    ; Swap scratch_ids[i] <-> scratch_ids[max_idx] (use rsi/rdi as temps; r10/r11 hold bases)
    mov     rax, [r10 + r8*8]
    mov     rsi, [r10 + r9*8]
    mov     [r10 + r8*8], rsi
    mov     [r10 + r9*8], rax

    ; Swap scratch_scores[i] <-> scratch_scores[max_idx]
    mov     eax, [r11 + r8*4]
    mov     esi, [r11 + r9*4]
    mov     [r11 + r8*4], esi
    mov     [r11 + r9*4], eax

.sort_outer_advance:
    inc     r8
    jmp     .sort_outer

.top_k_done:
    mov     rax, r12                                ; return K'
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbp
    pop     rbx
    ret

; --- compute_add_raw(rdi=slot_a_ptr, rsi=slot_b_ptr, rdx=dest_slot_ptr) ---
; Pod 3.6 — D3.25 forge-tier ADD compute helper (Maid composes).
; Per-element a[i] + b[i] → dest[i] across 384 elements; no reduction;
; no zero-norm rejection (ADD has no degenerate input shape). Operates on
; raw slot pointers (post-MAC-verify by caller per D3.15 + R4 step 8).
;
; Mirrors compute_dot_product / compute_l2_distance simple-loop shape;
; differs by writing per-element to dest+EMBEDDING_OFF_VECTOR rather than
; accumulating to scalar register. Per D3.28 R10 simulation: bit-exact
; deterministic by construction (single addss per element, no accumulator
; depth, no form-traversal asymmetry). 12/12 R10 primary canary patterns.
;
; Input:    rdi = slot_a_ptr, rsi = slot_b_ptr, rdx = dest_slot_ptr
; Output:   none (writes 1536 bytes to [rdx + EMBEDDING_OFF_VECTOR])
; Clobbers: rcx, r8, r9, r10, xmm0
; Preserves: rax, rbx, rbp, r12-r15, rsi, rdi, rdx (input args remain valid)
;            xmm1-xmm15 (helper uses xmm0 only; xmm1 reserved-but-unused
;            per D3.15 forge-tier compute-helper xmm clobber convention)

compute_add_raw:
    mov     rcx, EMBEDDING_DIM                      ; 384
    lea     r8,  [rdi + EMBEDDING_OFF_VECTOR]       ; src a vector base
    lea     r9,  [rsi + EMBEDDING_OFF_VECTOR]       ; src b vector base
    lea     r10, [rdx + EMBEDDING_OFF_VECTOR]       ; dest vector base
.add_loop:
    movss   xmm0, [r8]
    addss   xmm0, [r9]
    movss   [r10], xmm0
    add     r8,  4
    add     r9,  4
    add     r10, 4
    dec     rcx
    jnz     .add_loop
    ret

; --- compute_subtract_raw(rdi=slot_a_ptr, rsi=slot_b_ptr, rdx=dest_slot_ptr) ---
; Pod 3.6 — D3.25 forge-tier SUBTRACT compute helper. Inherits compute_add_raw
; shape verbatim with subss replacing addss. Per-element a[i] - b[i] → dest[i]
; across 384 elements; no reduction; no zero-norm rejection. Per D3.28 R10:
; bit-exact deterministic (subss has no accumulator depth); subss(x, x) = +0.0
; byte-exact for finite non-NaN x (B28 endpoint property).
;
; Input/Output/Clobbers/Preserves: identical to compute_add_raw.

compute_subtract_raw:
    mov     rcx, EMBEDDING_DIM
    lea     r8,  [rdi + EMBEDDING_OFF_VECTOR]
    lea     r9,  [rsi + EMBEDDING_OFF_VECTOR]
    lea     r10, [rdx + EMBEDDING_OFF_VECTOR]
.sub_loop:
    movss   xmm0, [r8]
    subss   xmm0, [r9]
    movss   [r10], xmm0
    add     r8,  4
    add     r9,  4
    add     r10, 4
    dec     rcx
    jnz     .sub_loop
    ret

; --- compute_scale_raw(rdi=slot_a_ptr, rsi=scalar_f32_as_i64, rdx=dest_slot_ptr) ---
; Pod 3.6 — D3.25 forge-tier SCALE compute helper. First scalar-mixed compute
; in synthesis tier. Scalar passed as f32-as-i64 in low 32 bits of rsi (high
; 32 bits zeroed on operand-stack pop; broadcast into xmm1 once via movd, then
; per-element movss/mulss/movss). Per D3.28 R10: bit-exact deterministic;
; mulss(0.0, x) = 0 (B30); mulss(-1.0, x) = -x (B31); single-rounding event.
;
; Input:    rdi = slot_a_ptr, rsi = scalar (f32-as-i64), rdx = dest_slot_ptr
; Output:   none (writes 1536 bytes to [rdx + EMBEDDING_OFF_VECTOR])
; Clobbers: rcx, r8, r10, xmm0, xmm1
; Preserves: rax, rbx, rbp, r12-r15, rsi, rdi, rdx (input args remain valid)

compute_scale_raw:
    mov     rcx, EMBEDDING_DIM
    movd    xmm1, esi                                ; xmm1 = scalar (low 32 bits of rsi)
    lea     r8,  [rdi + EMBEDDING_OFF_VECTOR]
    lea     r10, [rdx + EMBEDDING_OFF_VECTOR]
.scale_loop:
    movss   xmm0, [r8]
    mulss   xmm0, xmm1
    movss   [r10], xmm0
    add     r8,  4
    add     r10, 4
    dec     rcx
    jnz     .scale_loop
    ret

; --- compute_normalize_raw(rdi=slot_a_ptr, rdx=dest_slot_ptr) ---
; Pod 3.6 — D3.14 Form A normalize. First unary forge compute helper + first
; synthesis-tier zero-norm rejection (mirrors compute_cosine_raw zero-norm path).
;
; Form A (per D3.14 / D3.28): norm_sq accumulator → zero check → sqrtss(norm_sq)
; → per-element divss. Form B (a[i] * (1.0/norm)) considered + rejected:
; same 25-ulp norm_sq drift would feed reciprocal; extra divss-then-mulss with
; no compensating accuracy benefit. Form A's per-element divss is fewer rounding
; events. Architect-ratified at AUTHORIZED-1 with v_uniform anti-pattern note
; and B32-aux as self-verifying canon for the predicted 25-ulp drift.
;
; Input:    rdi = slot_a_ptr, rdx = dest_slot_ptr
; Output:   CF=0 success (dest vector written); CF=1 zero-norm rejection (dest unwritten)
; Clobbers: rcx, r8, r10, xmm0, xmm1, xmm2
; Preserves: rax, rbx, rbp, r12-r15, rsi, rdi, rdx (input args remain valid)

compute_normalize_raw:
    ; Step 1: norm_sq = sum_i a[i] * a[i]
    xorps   xmm0, xmm0                               ; norm_sq accumulator
    mov     rcx, EMBEDDING_DIM
    lea     r8,  [rdi + EMBEDDING_OFF_VECTOR]
.normalize_norm_sq_loop:
    movss   xmm1, [r8]
    mulss   xmm1, xmm1
    addss   xmm0, xmm1
    add     r8,  4
    dec     rcx
    jnz     .normalize_norm_sq_loop

    ; Step 2: zero-norm rejection (D3.14 Pre-A7 strict zero check)
    xorps   xmm2, xmm2                               ; xmm2 = 0.0 baseline
    ucomiss xmm0, xmm2                               ; norm_sq vs 0.0
    je      .normalize_zero_norm_fail

    ; Step 3: norm = sqrtss(norm_sq)
    sqrtss  xmm0, xmm0                               ; xmm0 = norm

    ; Step 4: result[i] = a[i] / norm  (per-element divss)
    mov     rcx, EMBEDDING_DIM
    lea     r8,  [rdi + EMBEDDING_OFF_VECTOR]
    lea     r10, [rdx + EMBEDDING_OFF_VECTOR]
.normalize_div_loop:
    movss   xmm1, [r8]
    divss   xmm1, xmm0
    movss   [r10], xmm1
    add     r8,  4
    add     r10, 4
    dec     rcx
    jnz     .normalize_div_loop

    clc                                              ; CF=0 success
    ret

.normalize_zero_norm_fail:
    stc                                              ; CF=1 zero-norm rejection
    ret

; --- compute_lerp_raw(rdi=slot_a_ptr, rsi=slot_b_ptr, rdx=dest_slot_ptr, r8=t_as_i64) ---
; Pod 3.6 — D3.14 Form A linear interpolation. First ternary forge compute helper.
;
; Form A: one_minus_t = subss(1.0, t); result[i] = (one_minus_t * a[i]) + (t * b[i])
;   2 mulss + 1 addss per element.
; Form chosen for endpoint-byte-exactness at t=0.0 / t=1.0 (B35/B36):
;   t=0: (1.0 * a[i]) + (0.0 * b[i]) = a[i] + 0.0 = a[i] byte-exact
;   t=1: (0.0 * a[i]) + (1.0 * b[i]) = 0.0 + b[i] = b[i] byte-exact
; D3.28 R10 simulation: irrational-t inputs produce asymmetric drift via
; one_minus_t lossy traversal (B34-aux self-verifies the predicted asymmetry).
;
; Input:    rdi = slot_a_ptr, rsi = slot_b_ptr, rdx = dest_slot_ptr, r8 = t (f32-as-i64)
; Output:   none (writes 1536 bytes to [rdx + EMBEDDING_OFF_VECTOR])
; Clobbers: rcx, r9, r10, r11, xmm0, xmm1, xmm2, xmm3
; Preserves: rax, rbx, rbp, r12-r15, rsi, rdi, rdx, r8 (input args remain valid)

compute_lerp_raw:
    ; Setup: xmm1 = t; xmm0 = one_minus_t = subss(1.0, t)
    movd    xmm1, r8d                                ; xmm1 = t (low 32 of r8)
    mov     ecx, 0x3F800000                          ; bit pattern for f32(1.0)
    movd    xmm0, ecx                                ; xmm0 = 1.0
    subss   xmm0, xmm1                               ; xmm0 = 1.0 - t = one_minus_t

    ; Per-element loop: result[i] = (one_minus_t * a[i]) + (t * b[i])
    mov     rcx, EMBEDDING_DIM
    lea     r9,  [rdi + EMBEDDING_OFF_VECTOR]        ; src a
    lea     r10, [rsi + EMBEDDING_OFF_VECTOR]        ; src b
    lea     r11, [rdx + EMBEDDING_OFF_VECTOR]        ; dest
.lerp_loop:
    movss   xmm2, [r9]                               ; a[i]
    mulss   xmm2, xmm0                               ; one_minus_t * a[i]
    movss   xmm3, [r10]                              ; b[i]
    mulss   xmm3, xmm1                               ; t * b[i]
    addss   xmm2, xmm3                               ; sum
    movss   [r11], xmm2                              ; store
    add     r9,  4
    add     r10, 4
    add     r11, 4
    dec     rcx
    jnz     .lerp_loop
    ret
