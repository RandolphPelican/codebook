# Pod 1.10.3 Decision Record — Cap Metabolic Wiring

**Pod:** 1.10.3 — substrate prep for Cop (no behavior activation)
**Author:** Terminal Boy (Claude Opus 4.7)
**Date:** May 04 2026
**Entry contract:** 39ad88603422f68a41dec3e0430dedc0526fe92ba2e29f9fb40b6516aead0f25 (Pod 1.10.2b2 BOOTX64.EFI)
**Exit contract:** 5c822f2476ed93f71c2887dfd6547ce265c4d4c8ebcc11bbcee390319e415370
**Entry HEAD:** 5167287a4c3ecd4547e095c8bbe7f9da27ea9b62 (Pod 1.10.2b2 seal)

---

## D1.10.3.1 — Two new Cap fields with deliberate MAC/non-MAC split

`energy_budget` is **MAC-input** — immutable identity component of the
cap's grant. Tampering detected at MAC verify (the SipHash gate from
Pod 1.10.2a's E1 + ROOT_CAP MAC verify at boot). Lives at slot+0x30,
in the new 7-qword MAC input range.

`energy_used` is **non-MAC** — substrate-managed running tally;
mutable over the cap's lifetime once Cop activates spatial-merge in
Pod 2. Lives at slot+0x40, outside the MAC input range.

The split is deliberate: budget is identity (MAC protects); used is
state (substrate-private writes manage). **Spatial reflection of the
doctrine in slot layout** — MAC-input range covers identity fields;
outside-MAC range covers mutable state. Future substrate fields with
similar identity-vs-state distinction inherit this layout pattern.

## D1.10.3.2 — OP_CAP_NEW signature amended; honest canon evolution

OP_CAP_NEW pops `(resource_descriptor, energy_budget)` instead of
`resource_descriptor` only. Pop order: top-of-stack = energy_budget
(last pushed) per A3 — matches existing `.op_outcome_new_err` and
`.op_sign_new` conventions where multi-arg handlers pop top-first.

**Pod 1.10.2b1's A2 ratification (resource_descriptor only) was
correct for the substrate at that pod.** Strict delegation under
V1.0 with no metabolic accounting made arena_id and owner_demod_id
caller args vestigial; the recon at 1.10.2b1 narrowed the signature
honestly.

**Adding metabolic dimension introduces genuinely non-vestigial
caller input.** energy_budget is the cap's grant — it must come
from the caller, not from substrate state. This is canon evolution,
not contradiction. Substrate dimensions grow over the pod arc; opcode
signatures grow with them.

The decision record at each evolution point captures the reasoning
explicitly so future readers see "the prior ratification was correct
for the substrate at that pod; this one is correct for the substrate
at this pod."

## D1.10.3.3 — ROOT_CAP unbounded grant via ENERGY_BUDGET_UNBOUNDED

ROOT_CAP energy_budget = `0xFFFFFFFFFFFFFFFF` (= MAX_U64 = -1 as i64).
The substrate root has no upstream metabolic constraint; constraints
flow downward to sub-caps via future Cop spatial-merge.

Named constant: `%define ENERGY_BUDGET_UNBOUNDED 0xFFFFFFFFFFFFFFFF`
in defines.asm. Forward-anchor for any future "unbounded grant"
semantics — if Pod 2 introduces other unbounded-by-design resources
(unlimited demod registrations, unlimited signal subscriptions),
the constant generalizes. Identical bytes to a literal but better
audit-readability when Pod 2+ archaeologists trace meaning.

**Cross-language note:** Python `struct.pack('<q', -1)` emits the
identical 8 bytes as `0xFFFFFFFFFFFFFFFF` via signed two's-complement.
The atreyu_x86.py demo emitter uses `ENERGY_BUDGET_UNBOUNDED = -1`
to satisfy Python's signed i64 pack constraint; bytes emitted to .cbc
files are byte-identical to the unsigned NASM-side constant.

**Presentational note:** CBS `OP_PRINT_NUM` is signed-interpreting
(per DEFERRED #69 forward-log). ROOT_CAP budget renders as `-1`
rather than the decimal MAX_U64 literal. Substrate behavior is
correct (B7/B11 confirm round-trip stability); the demo expectation
comment was updated at C0 to `"expect -1 (signed i64 of MAX_U64)"`
matching the actual print output.

## D1.10.3.4 — Cap slot relayout

```
Pre-1.10.3:                    Post-1.10.3:
  +0x00 cap_id_self              +0x00 cap_id_self
  +0x08 arena_id                 +0x08 arena_id
  +0x10 owner_demod_id           +0x10 owner_demod_id
  +0x18 resource_descriptor      +0x18 resource_descriptor
  +0x20 parent_cap_id            +0x20 parent_cap_id
  +0x28 generation_counter       +0x28 generation_counter
  +0x30 mac                      +0x30 energy_budget       (NEW; MAC-input)
  +0x38..0x7F reserved (9q)      +0x38 mac                 (shifted)
                                 +0x40 energy_used         (NEW; non-MAC)
                                 +0x48..0x7F reserved (8q)

CAP_MAC_INPUT_QWORDS: 6 → 7
CAP_OFF_MAC: 0x30 → 0x38
CAP_OFF_ENERGY_BUDGET = 0x30
CAP_OFF_ENERGY_USED = 0x40
CAP_SLOT_SIZE = 0x80 (unchanged)
```

ROOT_CAP MAC recomputed at boot over the new 7-qword range;
`verify_root_cap_mac` (E3 self-test from Pod 1.10.2a) parallel —
both via the symbolic `CAP_MAC_INPUT_QWORDS` constant, no per-site
edit required (S5.1 — D1.10.2a A1 parameterization paying forward).

**B4 6837-byte canonical liveness empirically validates the
construct + stamp + verify chain.** The boot-time E3 self-test from
Pod 1.10.2a continues to do load-bearing layout-integrity validation
at every substrate evolution that touches MAC range. **Fourth pod
those self-tests have empirically validated layout integrity through**
(1.10.2a construct + 1.10.2b1 ENTER MAC-verify add + 1.10.2b2 retrofit
+ 1.10.3 layout shift). Same risk-class as Pod 1.10.2a's HALT 2B-DEFECT
(architect-supplied wrong magic number caught by E3); Pod 1.10.3's
cleared at HALT 2B with the layout passing.

## D1.10.3.5 — Two architectural-reuse dividends realized this pod

**(a) `.cap_accessor_common` reuse.** OP_CAP_BUDGET and OP_CAP_USED
become five-line dispatch stubs calling Pod 1.10.2b1's existing
helper at offsets 0x30 and 0x40. Fifth and sixth consumers of the
helper across three pods:

| Pod | Consumers |
|-----|-----------|
| 1.10.2b1 | OP_CAP_ARENA, OP_CAP_OWNER, OP_CAP_RESOURCE (3) |
| 1.10.2b2 | OP_CAP_PARENT (1) |
| 1.10.3 | OP_CAP_BUDGET, OP_CAP_USED (2) |

Six total consumers, six pods of forward-cost-zero structural reuse.

**(b) `CAP_MAC_INPUT_QWORDS` parameterization** (D1.10.2a A1
ratification). Updating `6 → 7` in defines.asm propagated through
five MAC compute/verify call sites with **zero source-line changes**:
- `cbs_vm.asm` `.op_cap_new` MAC compute at construction
- `cbs_vm.asm` `.op_cap_enter` MAC verify
- `cbs_vm.asm` `.cap_accessor_common` MAC verify
- `cap.asm` `siphash_compute_cap_mac` wrapper
- `cap.asm` `construct_root_cap` + `verify_root_cap_mac`

Both factorings made at recon time of prior pods; both pay forward
at zero structural cost. **Cross-cutting doctrine:** when factoring
decisions encode parameterization (helper-function-pointer shapes,
symbolic-constant references to layout dimensions), future substrate
evolution costs nothing structural. Future pods plan factoring with
this in mind.

The same architectural-reuse pattern that produced D1.10.2b1.5
(.cap_accessor_common) and D1.10.2a.8 (siphash_compute parameterized
signature) keeps earning structural credit. Two distinct factoring
families; both same principle: **decide once with parameterization
in mind, future consumers cost nothing structural**.

## D1.10.3.6 — Pod 1.10.3 substrate prep only; no behavior activation

`energy_used` stays 0 across all V1.0 paths. Nothing increments it
in 1.10.3 — the field is reserved for Pod 2 (Cop) spatial-merge
activation (delegation tax — every authority-exercise increments
ancestor energy_used by half-cost up the parent_cap_id chain).

Stating this explicitly per **D1.10.2b2.9 doctrine** (architect-
side count claims need cross-reference; same family of pre-emptive
scope clarity to forestall framing errors of the architect-
understatement family). The pod does what it does; spatial-merge
is Cop's job, not 1.10.3's. Future readers see the intent at
this seal point.

## D1.10.3.7 — Cap test regression baseline reset

Six prior-pod Cap-involving test surfaces rebuilt under amended
two-arg OP_CAP_NEW shape:

| Surface | Prior pod | Pre-rebuild bytes | Post-rebuild bytes | Δ |
|---------|-----------|-------------------|--------------------|---|
| test_cap_new_basic | 1.10.2b1 | 165 | 174 | +9 |
| test_cap_arena_owner_resource | 1.10.2b1 | 228 | 237 | +9 |
| test_cap_current | 1.10.2b1 | 313 | 322 | +9 |
| test_cap_stack_overflow | 1.10.2b1 | 3027 | 3036 | +9 |
| test_provenance_under_subcap | 1.10.2b2 | 478 | 487 | +9 |
| test_provenance_walk | 1.10.2b2 | 430 | 439 | +9 |

**Each gains exactly +9 bytes** (1 byte OP_PUSH opcode + 8 byte i64
immediate per cap_new invocation). The +9 byte prediction was
deterministic at HALT 1 R8 and verified empirically across all six
surfaces, demonstrating the bytecode shape model's predictability.

Semantics preserved across the shape shift:
- B12: cap_id=2 (still first user-created)
- B13: arena=0/owner=0/resource=42 (preserved)
- B14: ROOT(1)→ENTER A(2)→EXIT ROOT(1) (preserved)
- B17: 257-deep ENTER overflow (preserved)
- B18 (provenance walk): creator_of_S=2, parent_of_A=1,
  parent_of_ROOT=0 (preserved)

**Future regression baseline references Pod 1.10.3 seal**, not prior
pods. Forward-anchor: substrate evolution requires periodic baseline
resets at signature-amendment points. Subsequent pods (Pod 2 Cop and
beyond) compare to this seal.

## D1.10.3.8 — Architect over-count caught at recon

Architect-named "8 affected test surfaces" was actually 6 (in-tree
count). TB cross-referenced against tools/atreyu_x86.py demos using
`cap_new` AST emitter and found 6: `demo_cap_new_basic`,
`demo_cap_arena_owner_resource`, `demo_cap_current`,
`demo_cap_stack_overflow`, `demo_provenance_under_subcap`,
`demo_provenance_walk`. Two demos that the architect counted
(`demo_cap_invalid_id`, `demo_cap_stack_underflow`) don't construct
caps — they use `cap_arena_raw_id` and `raw_op_cap_exit` respectively.
Their bytecode is unaffected by the OP_CAP_NEW amendment.

**Same family as:**
- D1.10.2a.10 (architect-supplied reference values must be cross-
  referenced against authoritative source)
- D1.10.2b1.8 (architect outline register conventions must match
  in-tree helper signatures)
- D1.10.2b2.9 (architect-named site count under-count cross-
  referenced against in-tree code)

**Three pods running, four different surfaces** — reference values,
register conventions, site counts (under), site counts (over). The
doctrine is symmetric: architect-side count claims need cross-
reference regardless of direction (under or over).

**Same principle:** in-tree code is canon, architect outlines are
recommendations, recon is the cheapest cross-reference checkpoint.
The empirical pattern over four pods (HALT 2B-DEFECT at 1.10.2a →
recon at 1.10.2b1 A4 → recon at 1.10.2b2 R3.4 → recon at 1.10.3 R8)
shows successively cheaper catches. The discipline tightens with
every pod.

---

## Forward-looking ledger

### Pod 2 (Cop is born) inherits

Per DEFERRED #68: substrate where every cap has metabolic accounting
fields ready. Cop's scope is pure behavior on prepared substrate —
spatial-merge activation, cap_bitmap structured semantics, nonce +
expiry, Ed25519, revocation policy. **No further Cap slot additions
needed.** The substrate is complete-as-substrate.

### Pod 2 may surface

- DEFERRED #69 — `OP_PRINT_DEC_UNSIGNED` opcode if unsigned
  rendering for substrate-internal u64 values becomes load-bearing
  for Cop test surfaces
- DEFERRED #61 — ERR_CAP_AUTHORITY_EXCEEDED activation when sub-
  arena delegation lands at Cop
- DEFERRED #66 — Outcome four-path consolidation refactor
  opportunity (NEW_OK / NEW_ERR thinned to wrappers around
  .construct_ok_outcome / .construct_err_outcome)

### Pod 2 or Pod 3 housekeeping consideration

Per DEFERRED #70: ~12 throwaway test scripts now (three each from
1.10.2a, 1.10.2b1, 1.10.2b2, 1.10.3). Largest accumulation since
pre-1.9.4 cleanup. The canary test scripts are pod-agnostic by
design (argument-driven); a unified pod-agnostic runner could
absorb all 12 into one harness. Pod 2 or Pod 3 candidate for
absorption.

— Terminal Boy
May 04 2026
