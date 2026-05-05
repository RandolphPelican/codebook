# Pod 2.1 Decision Record — Babylon is Born (spatial-merge activation)

**Pod:** 2.1 — opens Pod 2 with the metabolic activation half. **Cop renamed to Babylon at this pod.**
**Author:** Terminal Boy (Claude Opus 4.7)
**Date:** May 04 2026
**Entry contract:** 5c822f2476ed93f71c2887dfd6547ce265c4d4c8ebcc11bbcee390319e415370 (Pod 1.10.3 BOOTX64.EFI)
**Exit contract:** 8a8236f6f6d0e3473904096a166903c992a7f12187fe5b7fad6d28548499ba1f
**Entry HEAD:** 74f435cd4b525459995546a302150c1cde78f2b3 (Pod 1.10.3 seal)

---

## D2.1.1 — Cop renamed to Babylon (canon supersession)

v3 manifesto inherited "Cop" from earlier capability-security thinking. Pod 1.10.2b1 made Cop's policing role vestigial via the bouncer-to-fingerprint reframe (D1.10.2b1.1). Pod 2.1 names the metabolic-accountant role honestly as **Babylon**.

The metabolic-accountant role is babylon-shaped regardless of euphemism:
- **Cost ledger** — every act of creation has a metabolic cost
- **Tribute extraction** — costs flow upward through the lineage chain
- **Federation accounting weight** — ROOT_CAP accumulates the running total across all sub-cap activity

Calling it Babylon makes the function visible rather than hiding under euphemism. **Truth-in-naming all the way down.** Pod 1.10.2b1's bouncer-to-fingerprint reframe established truth-in-naming for authority-as-physics; D2.1.1 extends to truth-in-naming for **metabolism-as-physics**.

**Two named poles of the substrate's metaphysical surface:**
- **ROOT_CAP** — generative anchor, unbounded budget, source. Where authority is given.
- **Babylon** — extractive accountant, exponential-decay cost ledger, federation total. Where authority's exercise is measured.

Together they form the federation's full surface. Programs traverse from ROOT's domain (where authority is given) to Babylon's accounting (where authority's exercise is measured).

**Service is Babylon throughout this pod and forward.** Symbol convention `babylon_*` for helper code (e.g., `babylon_charge_lineage`); no `OP_BABYLON_*` opcodes — the work is silent (happens at construction sites without programmer-facing API; programs introspect Babylon's accounting via `OP_CAP_USED` which is already-shipped Cap state from Pod 1.10.3).

DEFERRED #64 ("Cop is born" forward-log) marked PARTIALLY RESOLVED at C2; service renamed in all forward references.

## D2.1.2 — Spatial-merge construction-only triggers

Authority's metabolic responsibility is about **creating things in the world, not observing them**. Sign/Energy/Outcome/Cap construction sites trigger `babylon_charge_lineage`; accessor reads, ENTER/EXIT, query operations do not.

Substrate charges for generation; observation is free. Philosophical alignment: producing new substrate state binds metabolic cost upward through lineage; querying existing state is free.

**Seven exact insertion sites confirmed at recon** (R2 enumeration cross-referenced against in-tree code per D1.10.2b2.9 / D1.10.3.8 doctrine):

| # | Site | Originating cost source |
|---|------|-------------------------|
| 1 | `.op_sign_new` post-register | OP_SIGN_NEW (100j) via current_dispatch_cost stash |
| 2 | `.op_energy_new` post-register | OP_ENERGY_NEW (10j) via stash |
| 3 | `.op_outcome_new_ok` post-register | OP_OUTCOME_NEW_OK (1j) via stash |
| 4 | `.op_outcome_new_err` post-prov_append | OP_OUTCOME_NEW_ERR (1j) via stash |
| 5 | `.op_cap_new` post-MAC-stamp | OP_CAP_NEW (1j) via stash |
| 6 | `.construct_ok_outcome` helper post-register | dispatching opcode's cost via stash |
| 7 | `.construct_err_outcome` helper post-register | dispatching opcode's cost via stash |

Architect's count was 7; recon confirmed 7. No discrepancy this pod (architect-detail-error doctrine still validated by recon checkpoint regardless of whether each particular check finds something).

## D2.1.3 — Exponential decay via floor division

Each ancestor at depth d above the originating cap accrues `cost / 2^d` (integer right-shift, floor division). Geometric series converges; total federation accounting load bounded by the originating cost itself (less, due to floor-div losses at deep tail).

V1.0 lossy-but-bounded model. The `shr rdi, 1; jz .babylon_done` idiom in `babylon_charge_lineage` is the elegant termination — single instruction halves cost AND detects deep-tail rounding to zero (jz fires when the result is 0). At depth 7+ for typical small costs (≤127j), contribution rounds to zero — natural early termination.

Future fractional-bit accumulation forward-logged at DEFERRED #73 if precision becomes load-bearing in later pods.

## D2.1.4 — ROOT_CAP accumulates federation total

Walk-up terminates when `parent_cap_id = 0` (ROOT's parent sentinel, set at `construct_root_cap` boot). ROOT itself is the final ancestor in every chain.

Programs reading `OP_CAP_USED(ROOT_CAP_ID)` see the substrate's running total accounting weight — federation metabolic load summary. ROOT-context operations contribute nothing (originating-at-ROOT means walk-up immediately terminates, B9 verified). Sub-cap depth determines ROOT contribution proportion.

**B10 federation total math verified:** A=150 (3 Sign forges via B contribute 50 each), B=0 (originating for Sign forges, doesn't charge itself), ROOT=85 (3×25 from Signs at depth 2 + 2×5 from Energies at depth 1). Substrate's ledger reflects exact metabolic flow.

## D2.1.5 — Walk-up does not MAC-verify ancestors

Substrate-private bookkeeping; cap_ids in the chain come from substrate-internal `parent_cap_id` pointers (stamped at construction time and protected by the originating cap's MAC). MAC verify on every ancestor would multiply substrate work by lineage depth without security value.

`babylon_charge_lineage` operates at substrate-private speed. **Distinct from program-driven Cap accessors** which DO MAC-verify per Pod 1.10.2b1 (OP_CAP_ARENA, OWNER, RESOURCE, PARENT, BUDGET, USED — all .cap_accessor_common consumers). Programs reading caps must authenticate; substrate walking caps for its own bookkeeping does not.

The split mirrors the broader substrate doctrine: **program-driven access is policed; substrate-private bookkeeping is fast.**

## D2.1.6 — Spatial-merge cost classification: 0j substrate bookkeeping

Walk-up is post-construction substrate work; no operand-stack-visible cost. Originating operation's cost-table value unchanged (Sign forge stays 100j observable per cost table; full Pod 1.7 sign canary stays 174j aggregate). Empirical confirmation at B11 — Sign forged under sub-cap costs 100j operand-stack while ROOT's energy_used incremented by 50 (100/2 floor).

**Substrate-bookkeeping doctrine extends fifth time across the pod arc:**

| Pod | D-entry | Surface |
|-----|---------|---------|
| 1.9.2b | D1.9.2b.1 | vm_fetch_count substrate bookkeeping |
| 1.10.2a | D1.10.2a.7 | cryptographic substrate-init at boot |
| 1.10.2b2 | D1.10.2b2.3 | Move 3 + creator_cap_id field writes |
| 1.10.3 | D1.10.3 implicit | energy_budget / energy_used field writes |
| **2.1** | **D2.1.6** | **spatial-merge ripples up the lineage** |

Five empirical confirmations across five pods; same doctrine. Substrate-side bookkeeping at construction-time or post-construction is 0j; operand-stack metabolic accounting is unaffected by what the substrate does in its private memory. **By Pod 3+ this principle should be cross-cutting load-bearing canon, not re-derived per pod.** Worth a future canon-summary entry that names the principle once and references the five empirical landing sites.

## D2.1.7 — Architectural moment B8 realized empirically

CBS program forges Sign under depth-3 cap chain (ROOT ← A ← B ← C); reads OP_CAP_USED at each level →

```
C.used (expect 0; originating):    0
B.used (expect 50; depth 1):       50
A.used (expect 25; depth 2):       25
ROOT.used (expect 12; depth 3):    12
```

Three-step geometric decay observable from CBS program code. **The substrate becomes empirically metabolically self-aware. Babylon is born as observable behavior.**

After authority-as-physics (Pod 1.10.2b1 — every cap is its own fingerprint), after lineage-as-graph (Pod 1.10.2b2 — every cell knows its lineage to ROOT), after metabolic-accounting-fields-ready (Pod 1.10.3), Pod 2.1 delivers **metabolism-as-physics — energy flows up the chain at every act of creation, and the federation knows what it costs at every level**.

The architectural arc of the Cap-and-Babylon work completes a metaphysical surface: ROOT generates, descendants create, costs flow back up. Programs can introspect the federation's running ledger via three accessor calls (OP_CAP_USED at any ancestor).

## D2.1.8 — Cop-to-Babylon rename + Pod 2 split

Pod 2.1 ships Babylon V1.0 metabolic activation. Pod 2.2 ships texture + lifecycle (cap_bitmap structured semantics + nonce + expiry + revocation per #71). Pod 2.3 ships Ed25519 cross-trust V1.1+ per #72.

The split per architectural-rethink ratification — spatial-merge is the metaphysical centerpiece of Babylon and earns its own seal. Texture + lifecycle is conceptually distinct work. Ed25519 is V1.1+ separate scope.

**v3 manifesto's monolithic "Cop is born" framing officially superseded.** The original framing collapsed metabolic activation, permission texture, lifecycle management, and cross-trust crypto into one pod. The actual work splits into three seals with distinct character and scope. D2.1.8 records the supersession.

## D2.1.9 — Architect cost-claim conflation doctrine (fifth instance)

Architect's pre-recon T5 expectation was `ROOT=87 (174/2)`, conflating Pod 1.7 174j Sign canary aggregate (entire sign_test program cumulative cost — Sign forge 100j + accessor reads + PUSH/print scaffolding) with single-OP_SIGN_NEW dispatch cost (100j per cost-table entry).

TB caught at recon (R5 / A4 surface); redesigned T5 to minimal shape with `ROOT=50 (100/2)`. Empirically verified at B11.

**Fifth instance of architect-detail-error family:**

| D-entry | Pod | Error surface |
|---------|-----|---------------|
| D1.10.2a.10 | 1.10.2a | Reference values (SipHash test vector) |
| D1.10.2b1.8 | 1.10.2b1 | Register conventions (helper signatures) |
| D1.10.2b2.9 | 1.10.2b2 | Site count (under-counted retrofit sites) |
| D1.10.3.8 | 1.10.3 | Site count (over-counted affected test surfaces) |
| **D2.1.9** | **2.1** | **Cost-claim conflation (canary aggregate vs single-op dispatch cost)** |

**Same family, five different surfaces** — reference values, register conventions, count direction (under and over), and now numerical conflation. Doctrine: **architect-side numerical claims need recon cross-reference regardless of error-type or error-direction; recon is the cheapest cross-reference checkpoint; in-tree code is canon.**

Discipline tightening across six pods (HALT 2B-DEFECT at 1.10.2a → recon at 1.10.2b1's A4 → recon at 1.10.2b2's R3.4 → recon at 1.10.3's R8 → recon at 2.1's R5/A4) is empirically observable. Each successive catch lands at the cheapest checkpoint.

## D2.1.10 — TB-invented option (c) cost stash

Architect proposed two cost-fetch strategies at R4: (a) dispatcher refactor (pass cost as parameter from fetch loop to handlers — high blast radius) and (b) at-site cost-table re-lookup (each handler hardcodes its opcode and re-runs `energy_cost_lookup` — works for opcode-level sites but fails for helpers which don't know their dispatching opcode).

**TB found option (c) at recon** — global memory stash (`current_dispatch_cost`) at fetch loop, read by helpers and handlers from a single source of truth. One qword in vmdata; one mov in fetch loop after `energy_cost_lookup`; no register pressure, no helper signature changes. Elegantly solves the helpers-don't-know-their-dispatcher problem (sites 6, 7 read dispatching opcode's cost without parameterization).

**Recon-side architectural improvement, not architect-decision-execution.** Worth recording as TB-invented because future readers should see that recon does architectural work, not just pattern-checking.

**Forward-anchor:** future substrate-internal operations needing cost-of-current-dispatch can read `current_dispatch_cost` without further infrastructure. Generalizable beyond spatial-merge to any "what's the cost of the operation that triggered me" query.

The "decide once with parameterization in mind, future consumers cost nothing structural" pattern now has three landing sites in the Cap arc:

| D-entry | Pod | Parameterization decision | Pay-forward consumer |
|---------|-----|---------------------------|----------------------|
| D1.10.2a A1 | 1.10.2a | siphash_compute over field count | CAP_MAC_INPUT_QWORDS 6→7 propagates 6→7 sites with 0 source-line changes (D1.10.3) |
| D1.10.2b1.5 | 1.10.2b1 | .cap_accessor_common over field offset | OP_CAP_PARENT (D1.10.2b2) + OP_CAP_BUDGET/USED (D1.10.3) — 3 consumers cost 0 helper code |
| **D2.1.10** | **2.1** | **current_dispatch_cost as global cost-of-current-dispatch source** | future substrate-internal ops needing dispatch cost (forward-anchor) |

Three architectural-reuse decisions made at recon time across the substrate's evolution, each paying forward at zero structural cost.

## D2.1.11 — OP_CAP_NEW double-fire benign at 1j; forward-anchor for ≥2j helper-routing audit

Site 5 (Cap stamp) and site 6 (.construct_ok_outcome wrapping cap_id via helper) both fire during one OP_CAP_NEW dispatch, both at 1j. **Floor-divide neutralizes the second fire** (1/2 = 0); no actual ripple to ancestors. Empirically benign at V1.0.

**Forward-anchor:** if a future construction opcode costs ≥2j AND wraps result in Outcome via .construct_ok_outcome / .construct_err_outcome helper, double-fire would over-charge ancestors. The first fire ripples (cost ≥2 → ancestor charged ≥1), then the helper fire ripples again (cost ≥2 → ancestor charged ≥1) — ancestors charged twice for one dispatch.

Pod 2.2 / 2.3 / 3+ designers audit when adding helper-routing constructors with cost ≥2j. Three remediation options if it surfaces (forward-logged at DEFERRED #75):

1. Track "spatial-merge already fired this dispatch" via a one-shot flag in `current_dispatch_cost`-adjacent state; helpers no-op if set
2. Make helper-fire optional via per-call-site toggle parameter
3. Restructure helper to not fire spatial-merge; opcode handlers fire spatial-merge once per dispatch (post all sub-construction)

V1.0 audit surface is empty (only 1j helper-routing constructor is OP_CAP_NEW); doctrine landed for future pods.

---

## Forward-looking ledger

### Pod 2.2 will close

- DEFERRED #71 (Babylon texture + lifecycle: cap_bitmap + nonce + expiry + revocation)
- Possibly partial #74 (housekeeping bundle absorption) if scope permits

### Pod 2.3 will close

- DEFERRED #72 (Ed25519 cross-trust V1.1+)

### Pod 2.2 / 2.3 / 3+ will audit

- DEFERRED #75 (≥2j helper-routing constructor double-fire)
- DEFERRED #69 (CBS print_dec is signed-interpreting; OP_PRINT_DEC_UNSIGNED if needed)

### Pod 3+ may surface

- DEFERRED #73 (fractional-bit accumulation for spatial-merge precision)
- Substrate-bookkeeping-is-0j cross-cutting summary entry per D2.1.6 (now five empirical confirmations across the pod arc)

— Terminal Boy
May 04 2026
