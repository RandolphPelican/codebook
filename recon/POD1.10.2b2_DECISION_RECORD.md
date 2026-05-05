# Pod 1.10.2b2 Decision Record — Witness substrate-wide + provenance anchoring

**Pod:** 1.10.2b2 — closes Section 2 of Pod 1.10; **seals Pod 1.10**
**Author:** Terminal Boy (Claude Opus 4.7)
**Date:** May 04 2026
**Entry contract:** 78b313ce8de2496235654e6ddfbc278321f818793404d1fbc1ba0e181f6f6e3e (Pod 1.10.2b1 BOOTX64.EFI)
**Exit contract:** 39ad88603422f68a41dec3e0430dedc0526fe92ba2e29f9fb40b6516aead0f25
**Entry HEAD:** 0b707f5ab1d7a1e1d868ddd4e5be101f6e8ce42c (Pod 1.10.2b1 seal)

---

## D1.10.2b2.1 — Provenance anchoring: creator_cap_id on Sign/Energy/Outcome slots

The substrate now records the specific cap under which each primitive
was forged, not just the arena/owner summary. New `creator_cap_id`
field added to Sign/Energy/Outcome slots:

- **Sign**: `SIGN_OFF_CREATOR_CAP_ID = 0x68` — reclaimed from
  embedding_handle slot (Pod 1.8.5c reclamation pattern continued:
  provenance_handle → arena_id, V1.1 sentinel → owner_demod_id,
  embedding_handle → creator_cap_id). OP_SIGN_NEW preserves 5-arg
  ABI by validating handle=0 then silently discarding.
- **Energy**: `ENERGY_OFF_CREATOR_CAP_ID = 0x20` — first qword of
  former 96-byte reserved zone. Energy slot now has all three I-fields
  contiguous at +0x10/+0x18/+0x20 (arena/owner/creator).
- **Outcome**: `OUTCOME_OFF_CREATOR_CAP_ID = 0x68` — last qword of
  former Pod 3+ reserved zone. Adjacent to arena_id at +0x70.

All slot sizes preserved at 128B; no pool size expansion. Creator
field placement is per-type optimal (D1.10.2b2.4 per-type pattern).

Enables provenance walking — chain traversal from any forged cell
back to ROOT via successive accessor calls.

## D1.10.2b2.2 — Three-primitive-type retrofit per D1.10.1.8 lands at six allocator sites

The architect's "three-allocator retrofit" expanded under recon
(R3.4) to six sites: Sign×1, Energy×1, Outcome×4 (NEW_OK direct,
NEW_ERR direct, .construct_ok_outcome helper, .construct_err_outcome
helper). Outcome's four-pathed construction (historical accumulation
of program-driven opcodes plus accessor-helper paths) requires the
retrofit to land at all four parallel paths identically.

Each site writes three substrate-state values into the new slot:
- `current_cap_arena_id_cache` → slot's arena_id offset
- `current_cap_owner_demod_id_cache` → slot's owner_demod_id offset
- `current_cap_id` → slot's creator_cap_id offset

Move 3 fields finally activated; D1.10.1.8 elegance unlock fully
landed across all four typed primitives.

## D1.10.2b2.3 — Substrate-bookkeeping-is-0j doctrine extends to creator_cap_id field write

D1.9.2b.1 / D1.10.2a.7 doctrine generalizes empirically once more.
Six retrofit sites add three substrate-state writes each (= 18
additional `mov` instructions across all allocators) and:
- **174j Sign canary held verbatim** at B2
- **53j Energy canary held verbatim** at B3

Substrate-side bookkeeping at construction is 0j regardless of how
many fields populate from substrate state. The doctrine has now been
empirically tested across:
- vm_fetch_count (Pod 1.9.2a)
- Move 3 fields arena/owner (Pod 1.10.2b1 implicit; this pod
  empirical via retrofit)
- creator_cap_id (this pod)

Future field additions at construction inherit the same 0j
classification by precedent.

## D1.10.2b2.4 — Per-type accessor pattern preserved over polymorphic dispatch

Authority context is substrate-universal but typing in CBS is
meaningful. `OP_SIGN_ARENA` asserts both "give me arena" and
"I am operating on a Sign." Polymorphism would dissolve typing
into substrate magic. Per-type dispatch respects CBS's type
discipline.

Three byte-parallel helpers shipped:
- `.sign_accessor_common` (calls `registry_lookup_sign`,
  TYPE_CODE_SIGN)
- `.energy_accessor_common` (calls `registry_lookup_energy`,
  TYPE_CODE_ENERGY)
- `.outcome_accessor_common` (calls `registry_lookup_outcome`,
  TYPE_CODE_OUTCOME)

Each helper is small (~25 lines), type-specific, no fn-pointer
indirection. ~120 factored lines vs ~180 for nine explicit
handlers. Three handlers per type as 5-line stubs calling the
appropriate helper with field offset and source_op.

The same per-type principle scales to slot layout: creator_cap_id
placement is per-type optimal (Sign at +0x68 reclaiming
embedding_handle, Energy at +0x20 contiguous with arena/owner,
Outcome at +0x68 last reserved qword) rather than cross-type
uniform offset.

## D1.10.2b2.5 — Cost asymmetry between non-MAC and MAC accessors

Per A1 ratification:
- 9 × 0j structural for Sign/Energy/Outcome accessors (registry
  lookup + slot field read; no cryptographic work; substrate
  bookkeeping per D1.9.2b.1)
- 1 × 1j metabolic for OP_CAP_PARENT (registry lookup + SipHash
  MAC verify + slot field read; real cryptographic work)

Empirically validated:
- B7-B13 all consume the new 0j accessors; B2/B3 canaries unchanged
- B11 budget shows 157j used, including 2 × 1j charges for two
  `cap_parent` calls — math sane

**Future-anchor:** when/if Sign/Energy/Outcome get MACs (provenance
integrity hardening at Pod 2+ for forgery detection), accessor
costs re-classify to 1j and the substrate-witness gate extends
substrate-wide. The asymmetry today is an honest reflection of
asymmetric work; tomorrow's symmetry would reflect symmetric
hardening.

## D1.10.2b2.6 — OP_CAP_PARENT zero-new-helper-code via D1.10.2b1.5 reuse

Pod 1.10.2b1 factored Cap accessor logic into `.cap_accessor_common`
(D1.10.2b1.5), which already MAC-verifies and reads any Cap-slot
field at any offset parameter. OP_CAP_PARENT consumes this helper
at offset `CAP_OFF_PARENT_CAP_ID = 0x20`:

```nasm
.op_cap_parent:
    sub     r13, 8
    mov     rdi, [r13]
    mov     rcx, CAP_OFF_PARENT_CAP_ID  ; 0x20
    mov     rsi, OP_CAP_PARENT
    call    .cap_accessor_common        ; existing 1.10.2b1 helper
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch
```

Five lines — dispatch + helper call + Outcome push. Plus a cost-
table entry and a defines.asm constant. **Zero new helper code.**

The architectural reuse pattern made empirical: factor once with
parameterization in mind; future consumers cost nothing structural.
Pod 1.10.2b1's factoring decision (one helper polymorphic over Cap-
slot field offsets) paying dividends one pod later. Forward-anchor
in helper comment block worthwhile so future readers see why
parameterization-over-hardcoding earned its keep.

## D1.10.2b2.7 — Provenance walk realized empirically

B11 / T5 — the architectural moment. CBS program forges Sign under
sub-cap A (resource_descriptor=42), then walks:

```
OP_SIGN_CREATOR(S)   → 2 (cap A's id)
OP_CAP_PARENT(2)     → 1 (ROOT)
OP_CAP_PARENT(1)     → 0 (anchor)
```

Three accessor calls trace lineage from forged cell back to
substrate anchor. The substrate narrates its own lineage from any
leaf cell to the keystone, observed from CBS program code for the
first time.

**D1.10.2b1.9** (substrate witnesses its current authority context)
**extends to D1.10.2b2.7** (substrate witnesses its full lineage
chain). The bouncer-to-fingerprint reframe goes from flat (single-
level current authority) to deep (traceable graph from leaf to
anchor). Pod 1.10's architectural moment delivered.

After Pod 1.9.2b's "Outcome wraps fallibility," after Pod 1.10.2a's
"ROOT_CAP anchors authority," after Pod 1.10.2b1's "every cap is
its own fingerprint" — Pod 1.10.2b2 delivers "every cell knows its
lineage back to ROOT."

## D1.10.2b2.8 — Pod 1.10 sealed at this seal point

Section 2 of Pod 1.10 complete. Cap primitive complete with:
- Construction (OP_CAP_NEW)
- Traversal (OP_CAP_ENTER, OP_CAP_EXIT, OP_CAP_CURRENT)
- Accessors (OP_CAP_ARENA, OP_CAP_OWNER, OP_CAP_RESOURCE,
  OP_CAP_PARENT)
- Full provenance via creator_cap_id on Sign/Energy/Outcome

Pod 1.10.3 (Cap metabolic wiring — energy_budget/energy_used fields
+ accessors + amended OP_CAP_NEW signature) is the next pod, sets
stage for Pod 2 Cop's spatial-merge activation. The "Cop is more
focused at birth than v3 anticipated" architectural read confirmed:
substrate prep moves into Pod 1.10.3 (metabolic accounting fields);
Cop becomes behavior-on-prepared-substrate (delegation tax via
parent_cap_id chain walk + cap_bitmap + nonce + expiry + Ed25519 +
revocation), not behavior + substrate prep.

DEFERRED #54 RESOLVED. #60 RESOLVED. #63 forward-logs Pod 1.10.3.
#64 forward-logs Pod 2 Cop. #65 forward-logs Pod 3 Maid embedding_
handle relocation. #66 forward-logs Outcome four-path consolidation.
#67 forward-logs throwaway-script bundle disposition.

## D1.10.2b2.9 — Recon-time site-count cross-reference doctrine

Architect-named "three-allocator retrofit" was actually six sites
(Outcome alone has four construction paths via historical
accumulation). Recon caught the discrepancy at R3.4. The retrofit
was load-bearing: any missed Outcome construction path produces
silently broken provenance (the worst failure mode this pod could
ship — silent because no diagnostic fires; stale because the cells
lie about their lineage).

**Same family of architect-side detail errors as:**
- **D1.10.2a.10** — architect-supplied reference values must be
  cross-referenced against authoritative source (caught at HALT 2B
  via boot-time self-test refuse-to-boot)
- **D1.10.2b1.8** — architect outline register conventions must
  match in-tree helper signatures (caught at recon)

**Same family, three different surfaces:** reference values,
register conventions, site counts.

**Same principle:** in-tree code is canon, architect outlines are
recommendations, recon is the cheapest cross-reference checkpoint.

**Future doctrine:** when architect names site counts in pod
prompts (or any other quantitative claim about code structure),
cross-reference against in-tree code at recon time before Phase 2A.
Discipline tightening across three pods (HALT 2B-DEFECT at 1.10.2a
→ recon at 1.10.2b1's A4 → recon at 1.10.2b2's R3.4) is empirically
observable. The cheapest checkpoint catches the most.

The R3.4 audit was empirically validated at HALT 2B:
- B9 covered NEW_OK direct path (Outcome forged via OP_OUTCOME_NEW_OK
  reads creator=1 under ROOT)
- B5 covered helper paths (6 Outcome regression tests use accessor
  success/failure that route through helpers, all byte-identical)
- B13 covered helper failure paths (four invalid-id paths construct
  Err Outcomes through .construct_err_outcome with source_op +
  err_code propagating cleanly)

The four parallel paths produce structurally equivalent outcomes —
HALT 2A side-by-side diff audit and Phase 2B empirical validation
both confirm. Silent provenance corruption prevented at both
architect-review and runtime-validation surfaces.

---

## Forward-looking ledger

### Pod 1.10.3 will close

- DEFERRED #63 (Cap metabolic wiring — energy_budget/used + accessors
  + amended OP_CAP_NEW signature)
- Possibly partial #66 (Outcome four-path consolidation) if scope
  permits
- Possibly partial #67 (throwaway-script housekeeping) if scope
  permits

### Pod 1.10.3 will surface

- Cap slot field placement audit (energy_budget + energy_used
  must fit; current Cap slot has 8 qwords reserved tail at +0x38-0x7F)
- OP_CAP_NEW signature amendment — non-vestigial caller input
  reverses Pod 1.10.2b1 A2 ratification at the metabolic-accounting
  layer
- Cost classification for OP_CAP_BUDGET / OP_CAP_USED accessors
  (1j metabolic per Cap accessor convention)

### Pod 2 (Cop) inherits

A substrate where every primitive carries full provenance (arena/
owner/creator) and every cap has metabolic accounting fields ready
(energy_budget/used). Per DEFERRED #64, Cop's scope:
- Spatial-merge activation (delegation tax via parent_cap_id chain
  walk — every authority-exercise increments ancestor energy_used
  by half-cost)
- cap_bitmap structured semantics
- Nonce + expiry enforcement
- Ed25519 cross-trust (V1.1+)
- Revocation policy via generation_counter advancement
- ERR_CAP_AUTHORITY_EXCEEDED activation when sub-arena delegation
  lands

### Pod 3 (Maid) inherits

Per DEFERRED #65, embedding_handle relocation when real lexical
embeddings activate. Pod 1.10.2b2's Sign slot reclamation at +0x68
is V1.0-correct; Pod 3 needs new home (slot expansion, side-table,
or another reclaimable field).

— Terminal Boy
May 04 2026
