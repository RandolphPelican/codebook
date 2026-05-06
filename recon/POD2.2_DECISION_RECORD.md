# Pod 2.2 Decision Record — Babylon's Vocabulary (cap_bitmap texture + bit-check enforcement)

**Pod:** 2.2 — closes Pod 2 with the textural activation half. **Babylon V1.0 sealed (metabolism + texture).**
**Author:** Terminal Boy (Claude Opus 4.7)
**Date:** 2026-05-05
**Entry contract:** 8a8236f6f6d0e3473904096a166903c992a7f12187fe5b7fad6d28548499ba1f (Pod 2.1 BOOTX64.EFI)
**Exit contract:** 0f598ec585245820da7d1cf89d6611cd80cb3327b76da74e5fe35c7590ccdb5f
**Entry HEAD:** f3f0f06249183ed870a8511ee448b731fcd09cd2 (Pod 2.1 seal — Babylon is born)

---

## D2.2.1 — cap_bitmap structured semantics: texture as physics

The placeholder `resource_descriptor` from Pod 1.10.2b1 (D1.10.2b1.2 / D1.10.2b1.6) finally has meaning. Pod 2.2 reinterprets the same byte position (+0x18 in Cap slot, MAC-input range) as a structured 64-bit forge-bit vocabulary.

Authority is no longer just *"this cap exists at this lineage with this metabolic accounting."* Authority has **shape**. The 64-bit field carries a vocabulary of what the cap is **permitted to do**.

**The reframe parallel structure:**
- Pod 1.10.2b1: bouncer-to-fingerprint — substrate as witness, programs are the cap they hold
- Pod 1.10.2b2: lineage as graph — substrate-wide provenance via accessor walks
- Pod 2.1: metabolism as physics — every act of creation has measured cost
- **Pod 2.2: authority shape as physics** — every act of creation is gated by what the originating cap is permitted to do

Programs don't ask permission and aren't gated by policy. Programs **are the bit pattern they hold**, and operations that exceed the bit pattern fail because the substrate physics doesn't carry that authority — not because some bouncer rejected them.

After the seal, both poles of capability physics are operative: production carries cost (Pod 2.1 metabolism), exercise carries shape (Pod 2.2 texture). Babylon's vocabulary lands as load-bearing dispatch behavior.

## D2.2.2 — V1.0 bit vocabulary: four forge bits

Constants in `boot/defines.asm`:
```
BIT_SIGN_FORGE     = (1 << 0)   ; 0x01 — gates OP_SIGN_NEW dispatch
BIT_ENERGY_FORGE   = (1 << 1)   ; 0x02 — gates OP_ENERGY_NEW dispatch
BIT_OUTCOME_FORGE  = (1 << 2)   ; 0x04 — gates OP_OUTCOME_NEW_OK / OP_OUTCOME_NEW_ERR
BIT_CAP_FORGE      = (1 << 3)   ; 0x08 — gates OP_CAP_NEW dispatch + delegation
```

The vocabulary mirrors the current authority-exercise opcode set. Bits 4-63 reserved for organic vocabulary growth across future pods.

**Decide-once-with-parameterization-in-mind doctrine** (cross-cutting design family). Pre-allocating bit ranges per future-pod intent is rejected. Claim 4 in V1.0; document each new bit at decision-record time when its consumer earns it. Forward-anchored as DEFERRED #76 — Pod 3 Maid likely claims surface bits + file-op bits; Pod 4+ Trinity surface bits + driver bits; V1.1+ network/cross-trust bits.

**BIT_CAP_FORGE does double duty.** Exercise-site check at OP_CAP_NEW (parent must carry CAP_FORGE to construct children) AND gating bit for further delegation (clearing CAP_FORGE on grant produces a leaf cap that does its forge work but cannot make children). Real capability-semantics axis. ROOT has CAP_FORGE; users who want non-delegating sub-caps clear the bit on grant.

## D2.2.3 — ROOT_CAP bitmap = CAP_BITMAP_UNBOUNDED

Named constant `CAP_BITMAP_UNBOUNDED = 0xFFFFFFFFFFFFFFFF` for forward-anchor readability, parallels `ENERGY_BUDGET_UNBOUNDED` from Pod 1.10.3 D1.10.3.3.

**Both poles of ROOT's keystone authority are structurally explicit and honestly named:**
- **Metabolic pole**: `energy_budget = ENERGY_BUDGET_UNBOUNDED` — ROOT has no spending limit
- **Textural pole**: `cap_bitmap = CAP_BITMAP_UNBOUNDED` — ROOT can do anything

Truth-in-naming consistency at the substrate's keystone. The substrate's two unbounded values aren't accidents; they're load-bearing semantic claims about what ROOT means. Both visible at construction time (`construct_root_cap` writes both via 64-bit immediate-via-register pattern); both protected by SipHash MAC over 7 qwords; both readable via observation accessors (`OP_CAP_BUDGET` / `OP_CAP_BITMAP`).

## D2.2.4 — OP_CAP_NEW signature third evolution: semantic-only

Pod 2.2 amends OP_CAP_NEW's pop semantics for the third time across the pod arc:
- **Pod 1.10.2b1 D1.10.2b1.2**: pops `resource_descriptor` (1-arg shape)
- **Pod 1.10.3 D1.10.3.2**: pops `(resource_descriptor, energy_budget)` (2-arg shape; +9 bytes per call site)
- **Pod 2.2 D2.2.4**: pops `(granted_bitmap, energy_budget)` — **semantic-only reinterpretation; bytecode shape unchanged**

The variable formerly known as `resource_descriptor` (the second pop, into r10) becomes `granted_bitmap`. Same byte position (+0x18); structured forge-bit semantics now load-bearing.

**Bytecode shape: zero ripple at OP_CAP_NEW callers.** Pod 1.10.3 demos that pushed `42` for resource_descriptor are rebuilt to push `CAP_BITMAP_UNBOUNDED` (or specific bit values for tests exercising bit semantics). Bytecode size identical (OP_PUSH + i64 = 9 bytes regardless of value). **Baseline-reset doctrine D1.10.3.7 generalizes** to a new category: value-rebind (semantic shift over unchanged bytecode position).

**OP_CAP_RESOURCE retired at 0xB6.** The old accessor opcode at the field's old name retires entirely per A2 / D1.10.3.7 baseline-reset precedent. `OP_CAP_BITMAP` at 0xBA replaces it as a five-line stub — seventh consumer of the Pod 1.10.2b1 D1.10.2b1.5 `.cap_accessor_common` helper across four pods. The architectural-reuse pattern continues earning structural credit pod-by-pod.

`test_cap_arena_owner_resource.cbc` retired; rebuilt as `test_cap_arena_owner_bitmap.cbc` reading via OP_CAP_BITMAP and printing CAP_BITMAP_UNBOUNDED (-1).

## D2.2.5 — Subset-on-grant capability-correctness invariant

OP_CAP_NEW enforces `(granted_bitmap & parent_bitmap) == granted_bitmap` at construction time. Violation returns `Outcome::Err(source_op=OP_CAP_NEW, err_code=ERR_CAP_AUTHORITY_EXCEEDED)`.

**V1.0 baseline guarantee: no privilege escalation possible via delegation.** A program that holds cap A with bitmap X cannot construct cap B with bitmap Y where Y has bits not in X. The substrate physics refuses.

**DEFERRED #61 RESOLVED.** ERR_CAP_AUTHORITY_EXCEEDED was reserved at Pod 1.10.2a (D1.10.1.9), forward-logged at Pod 1.10.2b1 (D1.10.2b1.2 marking it "defined-but-unused V1.0"), carried unchanged through Pods 1.10.2b2 / 1.10.3 / 2.1, and lands as load-bearing capability-correctness invariant at Pod 2.2 — **with zero new constant allocation**. The forward-log discipline pays out empirically: anchor laid at 1.10.2a with explicit error code reservation, cashed at 2.2 with mechanical implementation. Capability semantics carry through pod boundaries via documented reservation rather than memory or coordination overhead.

**B9 architectural moment empirically validated** the invariant from CBS program code:
```
B is_ok (expect 0 = err): 0
source_op (expect 176 = OP_CAP_NEW): 176
err_code (expect 7 = ERR_CAP_AUTHORITY_EXCEEDED): 7
```

Cap A under ROOT with `BIT_SIGN_FORGE | BIT_CAP_FORGE`; ENTER A; attempted construct B with `BIT_SIGN_FORGE | BIT_OUTCOME_FORGE` — A lacks BIT_OUTCOME_FORGE → subset rule fires → typed Outcome::Err. The substrate refuses delegation that exceeds parent authority and names what it refused.

## D2.2.6 — Two error codes for two failure modes

The substrate distinguishes three semantic failure shapes at OP_CAP_NEW / forge dispatch:

| err_code | Name | Semantic | Source sites |
|---|---|---|---|
| 1 | ERR_INVALID_ID | "your cap doesn't authenticate" (registry lookup or MAC mismatch) | All accessors (existing) |
| 7 | ERR_CAP_AUTHORITY_EXCEEDED | "you're trying to grant authority you don't possess" | OP_CAP_NEW subset-on-grant only |
| 8 | ERR_CAP_INSUFFICIENT_AUTHORITY | "your cap is fine, you don't have permission for this operation" | All 4 forge dispatch sites + OP_CAP_NEW BIT_CAP_FORGE check |

Three failure modes, three codes; **no collapse of distinct semantic violations into a single code**. Tag-the-halt convention from Pod 1.9.3 D1.9.3.2 inherited — `err_source_op` propagates for B-item observability so programs can read which opcode rejected.

`ERR_CAP_INSUFFICIENT_AUTHORITY = 8` is the only new error code allocation; `ERR_CAP_AUTHORITY_EXCEEDED` already existed at value 7 (D2.2.5 forward-anchor activation).

**B11 architectural moment empirically validated** the bit-check from CBS program code:
```
is_ok (expect 0 = err): 0
source_op (expect 208 = OP_ENERGY_NEW): 208
err_code (expect 8 = ERR_CAP_INSUFFICIENT_AUTHORITY): 8
```

Cap A with `BIT_SIGN_FORGE | BIT_CAP_FORGE` (deliberately omits BIT_ENERGY_FORGE); ENTER A; attempt Energy forge → bit-check at `.op_energy_new` insertion point fires → routes through `.construct_err_outcome` → typed Outcome::Err. Authority shape becomes load-bearing dispatch behavior.

## D2.2.7 — Path A retrofit for OP_SIGN_NEW / OP_ENERGY_NEW

Pre-Pod 2.2, OP_SIGN_NEW and OP_ENERGY_NEW success paths pushed bare `typed_id` to operand stack (Pod 1.7 / Pod 1.8 vintage); Pod 1.9.3 retrofitted only the failure paths to use `.construct_err_outcome`, deliberately preserving asymmetry at that pod's scope-boundary (D1.9.3.5).

**Pod 2.2 closes the asymmetry.** Success paths now wrap typed_id via `.construct_ok_outcome` helper, pushing `Outcome::Ok(typed_id)`. This:

1. **Unifies primitive construction contract** — every primitive returns Outcome (Sign, Energy, Outcome direct paths, Cap)
2. **Routes bit-check failure uniformly** through `.construct_err_outcome` with proper source_op tagging
3. **Bytecode shape**: +1 byte per Sign/Energy forge call site. Emitter (`tools/atreyu_x86.py`) auto-appends `OP_OUTCOME_UNWRAP_OK` after every `OP_SIGN_NEW` / `OP_ENERGY_NEW` so test surfaces consume bare typed_id transparently. `'wrap': True` AST flag opts out of auto-unwrap for Outcome-inspection tests.

**Architect's R6 prompt template incomplete on two points caught at recon (R6.a):**
1. Missing `mov r8, TYPE_CODE_*` (helper signature requirement)
2. Missing operand-stack push (caller responsibility post-helper)

TB recon-corrected pattern shipped at HALT 2A. Empirical confirmation of architect-detail-error doctrine seventh landing (D2.2.11).

**The "what's no longer there" verbatim was as load-bearing as the "what's now there" verbatim.** Pod 2.1's handler-explicit `babylon_charge_lineage` block at lines 906-911 (Sign) and 1067-1072 (Energy) was DELETED at this retrofit — D2.2.10 single-fire axiom.

Sharpens DEFERRED #66 — `.construct_ok_outcome` is now consumed by all five primitive construction success sites; OP_OUTCOME_NEW_OK / OP_OUTCOME_NEW_ERR direct paths become structural outliers; future consolidation pod has natural fit.

## D2.2.8 — Two architectural moments empirically realized

Pod 2.2's two architectural moments observable from CBS program code:

**B9 — subset rule fires.** Constructs cap with bitmap exceeding parent grant; `Outcome::Err(source_op=OP_CAP_NEW, err_code=ERR_CAP_AUTHORITY_EXCEEDED)` returned. DEFERRED #61 cashes after four pods of forward-anchor.

**B11 — bit-check fires.** Attempts forge under cap that doesn't carry the required bit; `Outcome::Err(source_op=<dispatching_opcode>, err_code=ERR_CAP_INSUFFICIENT_AUTHORITY)` returned. Authority shape distinguishes operations at the dispatch path.

After Pod 2.1's metabolism-as-physics, **Pod 2.2's authority-shape-as-physics** is the second behavioral seal in the post-substrate-prep arc. The substrate distinguishes operations by authority bit pattern at the dispatch path; programs see their cap's specificity reflected in execution outcomes.

**Pod 2.2 seals Babylon V1.0** — both poles of the metabolic-accountant role are operative:
- Cost ledger (Pod 2.1 metabolism activation)
- Dictionary of authority (Pod 2.2 vocabulary activation)

## D2.2.9 — Substrate-bookkeeping doctrine sixth empirical extension

Sixth empirical landing of the doctrine extension family:
- **D1.9.2b.1** — `vm_fetch_count` substrate gap closure (Pod 1.9.2b)
- **D1.10.2a.7** — cryptographic init (RDSEED probe + SipHash self-test + ROOT_CAP MAC)
- **D1.10.2b2.3** — Move 3 + creator_cap_id field writes at six allocator sites
- **D1.10.3.X** — energy_budget MAC-input + energy_used non-MAC field writes
- **D2.1.6** — spatial-merge ripple writes at seven construction sites
- **D2.2.9** (this pod) — bit-check at four forge dispatch sites + subset-on-grant at OP_CAP_NEW

The principle holds across six pods and six architectural axes: **substrate-private operations (counter increments, field writes, MAC compute, spatial-merge ripples, bit-checks) are 0j; only operand-visible work charges.** Originating opcode's cost-table value unchanged at Pod 2.2 — Sign 100j, Energy 50j, Outcome 1j, Cap 1j. Bit-check is post-pop / pre-construct substrate work; not visible to operand-stack cost accounting.

**174j Sign canary and 53j Energy canary held verbatim** under ROOT context with bit-check active (B2/B3 empirical confirmation):
- B2: `Energy: 174j used, 99826j remaining` — Sign canary unchanged
- B3: `Energy: 53j used, 99947j remaining` — Energy canary unchanged

By Pod 3 a cross-cutting summary D-entry is appropriate; for Pod 2.2 it stays as an extension within D2.2.9. The substrate's quiet doctrine, holding across every evolution.

## D2.2.10 — Single-fire substrate axiom for Sign/Energy success

Pod 2.1 D2.1 established that `babylon_charge_lineage` fires at every successful primitive construction site. Pod 2.2 establishes a **stronger axiom** for OP_SIGN_NEW and OP_ENERGY_NEW success: **single-fire per dispatch**.

**The risk that recon caught.** TB at HALT 1 Surprise 1 / R6.b: `.construct_ok_outcome` already fires `babylon_charge_lineage` internally (Pod 2.1 D2.1 spatial-merge insertion site #6). Naive Path A retrofit (just replacing bare push with helper call) would produce **double-fire**:
1. Handler-explicit babylon at lines 906-911 (Sign) / 1067-1072 (Energy) — first fire
2. `.construct_ok_outcome`'s internal babylon — second fire
3. Both reading current_dispatch_cost = 100j (Sign) / 50j (Energy)
4. Sub-cap parent ripple: 50+50 = 100j Sign / 25+25 = 50j Energy (vs. Pod 2.1 single-fire 50j / 25j)

**174j and 53j canaries would NOT have held under naive retrofit.** Pre-A14's "sixth empirical confirmation" claim would have broken.

**The resolution.** Path A retrofit at Sign/Energy MUST remove handler-explicit babylon calls; let `.construct_ok_outcome`'s internal call be the single fire site. The substrate axiom "every successful primitive construction fires babylon" relocates to the construct-ok-outcome boundary; the Sign-wrapped-in-Outcome::Ok IS the construction event in the post-retrofit framing.

**B13 sub-cap canary empirically validated the resolution:**
```
A.used (expect 0; originating): 0
ROOT.used (expect 50; 100/2 floor): 50
```

ROOT.used=50 confirms single-fire. If ROOT.used=100, double-fire wasn't resolved and the substrate would have shipped doctrine-violating accounting that only surfaced under sub-cap workloads. **The architect's blind spot caught at HALT 1 prevented a real failure mode.**

**Scope discipline.** OP_CAP_NEW's existing benign double-fire (1j cost; 1/2=0 floor-neutralized) per D2.1.11 stays unchanged in this pod — in-scope discipline. Future hygiene pod (DEFERRED #75 amended) can address universal single-fire across all construction sites if desired. OP_OUTCOME_NEW_OK / OP_OUTCOME_NEW_ERR direct paths fire babylon explicitly (no helper routing); single-fire by construction.

The verification provenance discipline working at full strength: **discovered at recon, resolved at AUTHORIZED-1, validated at HALT 2B**.

## D2.2.11 — Architect-detail-error doctrine three-surface pod

Pod 2.2 surfaced **three distinct architect-detail-error subtypes at recon**, each caught and corrected before Phase 2A source changes:

1. **A3 — numeric count claim drift.** Architect estimate of Path A retrofit affected surfaces: ~10. Recon enumeration: 13 (12 single-forge + 1 multi-forge `federation_total`). Within architect-stated range "10-25 plausibly more" but caught and surfaced explicitly per the doctrine that says architect counts go in either direction.

2. **R6.a — mechanical-completeness gap.** Architect's R6 retrofit template missing two pieces: `mov r8, TYPE_CODE_*` (helper signature requirement) and operand-stack push (caller responsibility). Identified by reading helper signature against actual usage pattern across six existing consumers.

3. **R6.b — side-effect-cross-reference blindness.** Architect's R6 retrofit template didn't account for `.construct_ok_outcome`'s internal `babylon_charge_lineage` call. Naive retrofit would have double-fired spatial-merge for Sign/Energy. The most load-bearing of the three — silent doctrine-violating accounting under sub-cap workloads.

**Sixth, seventh, eighth empirical instances** of the doctrine family:
- D1.10.2a.10 (architect cost-table claim caught at recon)
- D1.10.2b1.8 (architect register-clobber claim)
- D1.10.2b2.9 (architect retrofit-count claim)
- D1.10.3.8 (architect bytecode-shape claim)
- D2.1.9 (architect site-enumeration claim)
- D2.2.11.A3 (architect retrofit-count claim — sixth)
- D2.2.11.R6.a (architect helper-signature claim — seventh)
- D2.2.11.R6.b (architect side-effect claim — eighth, load-bearing)

**The doctrine performs across all error subtypes** — count direction (under and over), mechanical completeness, side-effect tracking. Recon checks every architect-side claim regardless of subtype; in-tree code is canon. The verification provenance discipline (D1.5.6 / MEMO_VERIFICATION_PROVENANCE.md) holds at every architect-supplied surface.

The R6.b catch is the canonical demonstration: discovered at HALT 1 (TB recon enumerating helper signatures + spatial-merge insertion sites), resolved at AUTHORIZED-1 (architect ratified handler-explicit babylon deletion as the resolution), validated at HALT 2B (B13 ROOT.used=50 empirical confirmation). End-to-end recon-discipline pays out in mechanical accounting integrity.

---

## Resolution summary

| # | Description | Status |
|---|---|---|
| #61 | ERR_CAP_AUTHORITY_EXCEEDED defined-but-unused | **RESOLVED** — activated via D2.2.5 subset-on-grant; B9 empirical |
| #66 | Outcome four-path consolidation | **SHARPENED** — five-of-six sites now route through helper post-D2.2.7 |
| #71 | Pod 2.2 Babylon texture + lifecycle | **PARTIALLY RESOLVED** — texture activated; lifecycle splits to #77 |
| #75 | Future ≥2j helper-routing constructors require audit | **PARTIALLY RESOLVED** — Sign/Energy audit landed via fourth-option resolution |
| #76 | Bit vocabulary expansion | **NEW** — Pod 3+ as consumers earn bits |
| #77 | Pod 2.3 Babylon revocation | **NEW** — returns when Maid pool pinch becomes empirical |
| #78 | Pod 2.2 throwaway test scripts | **NEW** — 18-script accumulation across 7 pods |
| #79 | .gitattributes line-ending normalization | **NEW** — Windows-checkout CRLF noise hygiene |

## Substrate state at seal

Every cap carries full identity:
- `cap_id_self` (registry-assigned)
- `arena_id` (strict delegation from current_cap)
- `owner_demod_id` (strict delegation)
- **`granted_bitmap`** (Pod 2.2: structured 4-forge-bit V1.0 vocabulary; was placeholder `resource_descriptor` pre-2.2)
- `parent_cap_id` (lineage anchor)
- `generation_counter` (revocation hook; Pod 2.3 activates consumer)
- `energy_budget` (MAC-input metabolic capacity)
- SipHash MAC over 7 qwords (immutable identity)
- `energy_used` (mutable, outside MAC range)

Every primitive across all four typed pools (Sign, Energy, Outcome, Cap) carries full provenance (arena/owner/creator). Every successful primitive construction triggers spatial-merge ripple up the lineage chain via single-fire floor-divided geometric decay (Sign/Energy via `.construct_ok_outcome` post-D2.2.7; Outcome direct paths via handler-explicit; OP_CAP_NEW via existing 1j benign double-fire).

**Every act of creation is bit-check-gated** by the originating cap's bitmap. **Subset-on-grant prevents privilege escalation** across delegation. ROOT_CAP at cap_id=1 anchors all chains with both poles unbounded — `ENERGY_BUDGET_UNBOUNDED` (metabolic) and `CAP_BITMAP_UNBOUNDED` (textural). Both honestly named.

**Babylon V1.0 sealed: metabolism + texture.** Cap is now substrate-complete for Maid V1.0's needs — identity, lineage, metabolism, authority shape.

Pod 3 (Maid is born) is the next move per Path α pacing ratification — semantic codebook substrate, lexical embeddings, file primitives. The work shifts from substrate-evolution to substrate-use.
