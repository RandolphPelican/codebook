# Pod 1.10.2b1 Decision Record — Cap operations + Cap accessors

**Pod:** 1.10.2b1 — first half of Section 2 part B of Pod 1.10
**Author:** Terminal Boy (Claude Opus 4.7)
**Date:** May 04 2026
**Entry contract:** a7e610c44651b5e5edd9a903792d4fec6b923a2b92a345ee0aa5cb4111293a81 (Pod 1.10.2a BOOTX64.EFI)
**Exit contract:** 78b313ce8de2496235654e6ddfbc278321f818793404d1fbc1ba0e181f6f6e3e
**Entry HEAD:** f642ca0473219938e0ce5a413e18512268aea660 (Pod 1.10.2a seal)

---

## D1.10.2b1.1 — OP_CAP_CHECK retired; three Cap accessors ship instead

The Pod 1.10.1 canon (D1.10.1.3 / D1.10.1.11) specified OP_CAP_CHECK
as authenticity + authorization. Pod 1.10.2b1 supersedes that with
three Cap accessors — OP_CAP_ARENA, OP_CAP_OWNER, OP_CAP_RESOURCE —
that read slot fields with MAC verification but do not enforce
authorization. The reframe: **the substrate is witness, not police.**

Programs holding cap_ids can introspect what their caps mean;
the substrate doesn't enforce match-against-expected. Authority is
embodied in what each cell carries (Move 3 fields on every primitive's
slot), not enforced as gate-checked policy. Programs verifying
authority context use OP_CAP_CURRENT + accessor + comparison rather
than substrate-mediated check.

This is closer to CodebookOS metaphysics: every cell carries the I;
authority is fingerprint not bouncer; provenance is in the data not
in a check site.

Real canon supersession at implementation pod time. Architect pre-
recon ratification (Pre-A1) recorded honestly. The pattern from
Pod 1.10.2a D1.10.2a.9 (architect-supplied test vector defect caught
at HALT 2B) and Pod 1.9.3 D1.9.3.8 (TB-inferred Path A course
correction at Phase 2B) continues: design canon is improvable when
implementation reveals a better shape, and the discipline is to
record the supersession honestly.

## D1.10.2b1.2 — OP_CAP_NEW pops only resource_descriptor in V1.0

Per Pre-A2 ratification: strict delegation (D1.10.1.12) makes
arena_id and owner_demod_id args vestigial. Substrate reads them
from current_cap_arena_id_cache / current_cap_owner_demod_id_cache
at handler time; child cap inherits parent's exactly.

ERR_CAP_AUTHORITY_EXCEEDED stays defined in defines.asm but
defined-but-unused in V1.0 (forward-log #61). Activates when sub-
arena delegation lands at Pod 2 (Cop) or wherever sub-cap-of-cap
with strict-subset arena/owner becomes meaningful.

D1.10.1.3's stack-effect spec amended: OP_CAP_NEW pops 1 (not 3)
operands.

## D1.10.2b1.3 — Pod 1.10.2b split into 1.10.2b1 / 1.10.2b2

Per architectural depth, Pod 1.10.2b sealed too much for one source
pod. Split:

- **1.10.2b1 (this pod):** Cap primitive complete — Cap operations
  (NEW/ENTER/EXIT/CURRENT) + Cap-side accessors (ARENA/OWNER/
  RESOURCE). The bouncer-to-fingerprint reframe lands here.
- **1.10.2b2:** Substrate-wide authority introspection — Sign/Energy/
  Outcome arena/owner accessors + three-allocator retrofit per
  D1.10.1.8 + retrofit observability tests. The substrate-wide
  elegance unlock lands at that seal.

DEFERRED #54 partially resolved here; #60 forward-logs the
1.10.2b2 inheritance.

## D1.10.2b1.4 — Three Cap accessors ARENA/OWNER/RESOURCE

Each pops cap_id, MAC-verifies the slot, reads the requested field,
returns Outcome<u64>. Cost 1j metabolic per accessor (SipHash crypto
work per D1.9.2b.1 metabolic-vs-structural classification). Path A
semantics inherited from Pod 1.9.3: success path constructs
Outcome::Ok via .construct_ok_outcome; failure path constructs
Outcome::Err via .construct_err_outcome.

Opcode allocation:
- OP_CAP_ARENA = 0xB4
- OP_CAP_OWNER = 0xB5
- OP_CAP_RESOURCE = 0xB6

Replaces the single OP_CAP_CHECK = 0xB4 from D1.10.1.2 / D1.10.1.3.

## D1.10.2b1.5 — .cap_accessor_common helper factored across three accessors

Single MAC-verification site keeps the cryptographic surface
auditable. Pattern parallel to Pod 1.9.3 .construct_err_outcome /
.construct_ok_outcome factoring (consolidate Path A semantics into
helpers; per-opcode handlers reduce to thin dispatch into shared
logic).

Helper signature follows in-tree r8=value_type_id convention.
Architect's R6/R9 outlines used `mov rsi, value_type_id` — TB
strict-corrected against in-tree code at recon (per A4 / D1.10.2b1.8;
detail-level catch at the cheapest checkpoint).

## D1.10.2b1.6 — OP_CAP_ENTER and OP_CAP_EXIT return Outcome<NONE> on every path

Per A2 ratification: Path A consistency for fallible operations.
Both ENTER and EXIT push Outcome on every path:
- Success: Outcome::Ok with value=0, value_type_id=TYPE_CODE_NONE
- Failure (invalid id, MAC mismatch, stack overflow/underflow):
  Outcome::Err with appropriate err_code and source_op

This introduces the **"Outcome::Ok succeeded with no meaningful
value"** pattern — first ever use. UNWRAP_OK on it returns 0
sentinel; IS_OK returns 1 (success indicator). The pattern
generalizes for Pod 1.10.2b2 onward: any fallible structural opcode
inherits this shape.

**Value_type_id convention on Err Outcomes:**
- Domain failures (invalid id, MAC mismatch on accessors and ENTER):
  carry the input type (TYPE_CODE_CAP) — caller knows the call was
  about a cap primitive
- Stack-violation failures (cap_stack underflow/overflow):
  carry TYPE_CODE_NONE per D1.9.3.3 inherited convention — stack
  violations have no expected-T

Internally consistent across all .op_cap_enter/exit/accessor
failure paths; formalized here so 1.10.2b2 onward doesn't re-
litigate.

## D1.10.2b1.7 — MAC-failure err_code collapsed to ERR_INVALID_ID for V1.0

Per A3 ratification: from caller's perspective, "cap_id doesn't
operationally work" is operationally identical whether the cap is
unregistered or MAC-mismatched. V1.0 ships honest "this cap doesn't
work" semantics.

Pod 2 (Cop) per DEFERRED #56 may distinguish ERR_CAP_MAC_INVALID
for substrate-secret audit and revocation policy. Forgery detection
at audit-distinguishability level is V2+ concern.

## D1.10.2b1.8 — Recon caught architect-side detail-level inconsistency

Architect's R6/R9 handler outlines used `mov rsi, value_type_id`;
actual Pod 1.9.3 helper signatures (.construct_ok_outcome /
.construct_err_outcome at boot/cbs_vm.asm:1303-1307 area) use r8.
TB strict-correction against in-tree code at recon (cheapest
checkpoint).

Same risk-shape as Pod 1.10.2a's HALT 2B-DEFECT (architect-supplied
wrong magic number) but caught one phase earlier — recon vs HALT 2B.
Same family as D1.10.2a.10 (architect-supplied reference values
cross-referenced against authoritative source) — different surface
(helper signatures vs cryptographic test vectors), same principle:
when architect outlines reference existing helper signatures or
external constants, the in-tree code or authoritative source is
canon, not the outline.

Future pods inherit the doctrine: recon is the right place to
cross-reference architect outlines against in-tree code.

## D1.10.2b1.9 — Substrate witnesses its own authority context for the first time

B8 / T2 empirically realized: a CBS program (test_cap_arena_owner_
resource.cbc) ran three accessor opcodes against a constructed cap,
each MAC-verifying the slot before reading the field. Output:
arena=0, owner=0, resource=42. The substrate confirmed by direct
introspection what the program had constructed.

The "every cell carries the I" Rastafari-architecture principle is
now testable from program code, not just doctrine in decision
records. D1.10.2b1.1's bouncer-to-fingerprint reframe ratified by
execution.

The architectural moment generalizes at 1.10.2b2: Sign/Energy/Outcome
become substrate-self-witnessing too. The substrate-wide elegance
unlock per D1.10.1.8 fully lands at that seal. ENTER's 1j metabolic
cost per A1 (the authentication metabolism at the authority-shift
boundary) is the load-bearing cost — programs deeply nested in
cap_stack pay for their authority traversals. The energy economy
and the authority economy are the same economy. Pod 1.10.2b1 is
where that becomes structural.

---

## Forward-looking ledger

### Pod 1.10.2b2 will close

- DEFERRED #54 fully (Sign/Energy/Outcome accessors + three-
  allocator retrofit + retrofit observability tests)
- DEFERRED #60 (Pod 1.10.2b2 inheritance from 1.10.2b1)

### Pod 1.10.2b2 might surface

- Sign/Energy/Outcome accessor cost classification (1j metabolic
  per the precedent here, since each accessor reads a slot field
  with potential authenticity verification — though V1.0 Sign/
  Energy slots don't carry MACs yet, so the verification surface
  is registry-lookup-only)
- Pool sizing review under non-trivial Cap delegation patterns
  (DEFERRED #19 family)
- Forward-anchor for Pod 1.12 (Demod) inheritance: demod slots
  may carry arena/owner under the same retrofit pattern

### Pod 2 (Cop) substrate-secret hardening forward-log per DEFERRED #56

- ERR_CAP_MAC_INVALID distinct err_code (per D1.10.2b1.7 forward
  note)
- siphash_key rotation policy
- generation_counter advancement protocol for cap revocation
- Cryptographic cost class refinement for OP_CAP_* accessors

— Terminal Boy
May 04 2026
