# Pod 1.10.2a Decision Record — Cap substrate plumbing

**Pod:** 1.10.2a — first source pod of Section 2 of Pod 1.10 (per
D1.10.1.14 split: 1.10.2a substrate plumbing / 1.10.2b handlers +
retrofit + tests)
**Author:** Terminal Boy (Claude Opus 4.7)
**Date:** May 04 2026
**Entry contract:** 3bfb0c0a2410e90c9aa9d5def1c598ec26d6c058d68c73cf67cb2da5e737fff6 (Pod 1.9.3 BOOTX64.EFI; preserved through 1.9.4 + 1.10.1)
**Exit contract:** a7e610c44651b5e5edd9a903792d4fec6b923a2b92a345ee0aa5cb4111293a81
**Entry HEAD:** 91a5c9d3f06cd255edfa5b4baa28efcbe515c897 (Pod 1.10.1 seal)

---

## D1.10.2a.1 — Substrate plumbing only; no Cap behavior testable until 1.10.2b

Pod 1.10.2a lands the Cap storage substrate (slot pool, registry,
per-execution stack, cache fields, crypto state) and the boot-time
self-verifications that prove the substrate can hold a valid root
authority. Pod 1.10.2b lands the 5 OP_CAP_* opcode handlers, cost
table extension, allocator retrofit per D1.10.1.8, and Cap test
surfaces.

Clean intermediate state matches Pod 1.9.2a precedent (Outcome
substrate at 1.9.2a, Outcome handlers at 1.9.2b). The pattern works:
a substrate-only pod lands carriers + structural verifications, the
handler pod lands behavior + behavioral tests. Each pod is testable
on its own terms — 1.10.2a tests are pristine boot + substrate
self-verifications + canary invisibility; 1.10.2b tests will be
behavioral.

5 OP_CAP_* opcodes are reserved at substrate-plumbing time per
D1.9.2b.10 cross-asset-constants doctrine, but are undefined as
handlers — invoking them at the VM produces "Unknown opcode" until
1.10.2b dispatch lands.

## D1.10.2a.2 — RDSEED → RDRAND → hard-fail-and-halt policy implementation

Per D1.10.1.6 ratification: no fixed-key fallback tier. CPUID probe
sequence:
- RDSEED: leaf 7 sub-leaf 0 EBX bit 18
- RDRAND: leaf 1 ECX bit 30 (fallback)
- Both missing → hard-fail with `str_no_entropy` via `auryn_puts` +
  `cli; hlt; jmp $`

Retry budget: 64 iterations per entropy call (Intel's recommendation
for contention). Two u64 reads required per boot (siphash_key[0],
siphash_key[1]); each has its own 64-iteration budget.

`siphash_key_source` flag (0 = rdseed, 1 = rdrand) is preserved in
substrate state for audit purposes. Currently no consumer (deliberate
forward-log per D1.10.2a.4 doctrine note); Pod 2 (Cop) inherits per
DEFERRED #56.

Empirically confirmed at B4: QEMU `-cpu max` exposes RDSEED; pristine
boot post-fix took the rdseed branch silently.

## D1.10.2a.3 — SipHash self-test against canonical veorq vectors_sip64[8] at boot per E1

Boot-time SipHash-2-4 self-test against published vectors. Implementation
reads the canonical Aumasson reference (siphash.c at
github.com/veorq/SipHash). Self-test inputs:
- Key: `siphash_key[0] = 0x0706050403020100`,
       `siphash_key[1] = 0x0F0E0D0C0B0A0908`
- Input: 1 qword `0x0706050403020100`
- Expected MAC: `0x93f5f5799a932462` (canonical vectors_sip64[8]
  little-endian u64 read of bytes `62 24 93 9a 79 f5 f5 93`)

The self-test is correct against canonical reference (confirmed at
HALT 2B post-fix). The architect-side defect at HALT 2A specifying
wrong expected value (D1.10.2a.9) is recorded separately. The
implementation's SIPROUND macro, init, compression loop, and
finalization were never in question — only the comparison literal.

Save/restore real `siphash_key` around the test so production key
isn't disturbed. Hard-fail with `str_siphash_self_test_fail` on
mismatch (refuse-to-boot pattern).

## D1.10.2a.4 — cap_stack declared at substrate-plumbing time per E2

`cap_stack[256]` + `cap_stack_ptr` are declared in vmdata.asm at
substrate-plumbing time, with no current consumer. Pod 1.10.2b first-
consumes via OP_CAP_ENTER (push current_cap_id) and OP_CAP_EXIT (pop).

**Doctrine note:** future-consumed declared state ≠ vm_fetch_count
gap pattern. cap_stack is structurally part of the Cap substrate
(parent_cap_id chain mechanism for nested authority); declaring it
at substrate-plumbing time means OP_CAP_ENTER/EXIT in 1.10.2b have
storage to push into without retrofit. The vm_fetch_count gap was
about a missing variable that handlers were trying to read; cap_stack
is the inverse — variable declared, handlers will write to it next
pod. Both patterns honest about substrate state ahead of consumer
arrival.

## D1.10.2a.5 — ROOT_CAP MAC self-verification at boot per E3

`verify_root_cap_mac` recomputes the ROOT_CAP MAC over its 6 fields
(cap_id_self through generation_counter) and compares to the stored
MAC at +0x30. Catches:
- SipHash non-determinism over identical input (would indicate a
  compute bug)
- MAC stored at wrong offset (e.g., +0x28 vs +0x30)
- MAC computed over wrong field range (e.g., 5 or 7 qwords vs 6)

Hard-fail with `str_root_cap_mac_mismatch` on mismatch. Internal
consistency check at the cheapest point in the pod lifecycle —
catches any of the above bugs at boot rather than letting OP_CAP_CHECK
fail later in 1.10.2b with confusing symptoms.

The construct_root_cap path also includes a `cmp rax, ROOT_CAP_ID`
sanity check after registry_register_cap returns (ROOT_CAP must be
cap_id=1 since it's the first registration). Hard-fail with
`str_root_cap_id_wrong` if registry assigns id≠1. Currently a
paranoia check; if a future bug double-initializes the registry or
runs init twice, this catches it.

## D1.10.2a.6 — Cross-asset constants verification per D1.9.2b.10

17 Cap-related constants land in defines.asm at substrate-plumbing
pod time, not handler-pod time:
- 5 OP_CAP_* opcodes (NEW=0xB0, ENTER=0xB1, EXIT=0xB2, CURRENT=0xB3,
  CHECK=0xB4) per D1.10.1.2/D1.10.1.3
- CAP_POOL_SLOTS (64), CAP_SLOT_SIZE (0x80), CAP_ID_NULL (0),
  ROOT_CAP_ID (1), CAP_STACK_DEPTH (256)
- ERR_CAP_AUTHORITY_EXCEEDED (7)
- 8 CAP_OFF_* slot field offsets (CAP_ID_SELF, ARENA_ID,
  OWNER_DEMOD_ID, RESOURCE_DESC, PARENT_CAP_ID, GENERATION_COUNTER,
  MAC, plus the 2-qword reserved tail)
- CAP_MAC_INPUT_QWORDS (6) — siphash_compute_cap_mac wrapper constant

Pod 1.10.2b's handlers reference these constants without needing
additional defines.asm work. The doctrine ratified at Pod 1.9.2b
(D1.9.2b.10) generalizes: cross-asset constants ride with the
substrate-plumbing pod, not the handler pod.

## D1.10.2a.7 — Substrate-bookkeeping-is-0j doctrine extends to cryptographic substrate-init

D1.9.2a.3 originally ratified that substrate bookkeeping (vm_fetch_count
increments, registry inserts) is 0j on the runtime metabolic surface
because it's structural, not catalytic. Pod 1.10.2a's boot-time
work goes further: SipHash compression rounds + CPUID probes + ROOT_CAP
MAC computation all execute pre-VM (before the cbs_run fetch loop is
invoked). They cannot affect runtime canary accounting by construction
— they happen before the cost-table debit machinery is even active.

Empirically confirmed at B2/B3:
- Sign 174j canary: held verbatim (174j used / 99826j remaining)
- Energy 53j canary: held verbatim (53j used / 99947j remaining)

The doctrine generalizes: any substrate-init work landing in efi_entry
between the UEFI handoff and the cbs_run fetch loop is invisible to
runtime metabolism by construction, regardless of cryptographic cost.

## D1.10.2a.8 — SipHash signature parameterization

`siphash_compute(rdi=field_ptr, rsi=qword_count) -> rax=mac`
parameterized signature ratified at Pod 1.10.2a HALT 1 per A1.
`siphash_compute_cap_mac(rdi=slot_ptr) -> rax=mac` becomes a thin
wrapper passing rsi=CAP_MAC_INPUT_QWORDS=6.

D1.10.1.7's V1.0-specific signature recommendation
(`siphash_compute_cap_mac` hard-coded to 6 qwords with explicit
forward-log "generalize when a second use case appears") is
effectively superseded at 1.10.2a HALT 1 recon: the boot-time
self-test (E1) is the second consumer that triggers generalization,
earlier than the "future primitive needs MAC" expected at canon
time. The doctrine works as designed — recon catches the
parameterization need before implementation drift.

DEFERRED #58 forward-logs the supersession so future pods inherit
the lesson: when a doctrine specifies "generalize when X appears",
recon at the next pod where X might appear is the right checkpoint.

## D1.10.2a.9 — Self-test value defect at HALT 2B; refuse-to-boot pattern surfaced architect-side error

Architect-provided test vector value `0xa129ca6149be45e5` was
incorrect for the inlen=8 case. The value resembles canonical
inlen=15 vector bytes in some byte-shuffled form, but does not
match canonical vectors_sip64[8].

TB's independent verification at HALT 2B used two ports of the
canonical algorithm (C `#define SIPROUND` from siphash.c reference,
plus Python port) — both computed `0x93f5f5799a932462` for the
1-qword input. Architect-side verification against authoritative
source (github.com/veorq/SipHash/blob/master/vectors.h, antirez/
siphash mirror confirming) determined `0x93f5f5799a932462` is the
correct canonical value:
- vectors_sip64[8] bytes: `0x62 0x24 0x93 0x9a 0x79 0xf5 0xf5 0x93`
- read little-endian as u64: `0x93f5f5799a932462`

Defect localized at cap.asm:285; one-line fix changing the
comparison literal. The verbatim verification at HALT 2A passed
because the implementation was correct against the algorithm;
verbatim verification cannot catch wrong expected-value literals
downstream of architect spec. The empirical self-test caught it.
Two complementary verification surfaces functioning as designed.

The substrate's refuse-to-boot pattern (auryn_puts FATAL diagnostic
+ cli; hlt; jmp $) prevented promoting the pre-fix EFI hash
`9ca5aaa0...` to canon. Substrate refused to boot with a wrong
self-verification expected value; self-verification did its job.

Process honesty parallel to Pod 1.9.3 D1.9.3.8 (PAUSED-MID-EXECUTION
audit-trail honesty): there the failure shape was TB inferring from
no-input; here the failure shape is architect supplying recalled
magic numbers without cross-reference. Both architect-vs-executor-vs-
substrate failure modes; both got caught by layered discipline.
Recording the failure shape canonically makes the discipline
inherit-able.

## D1.10.2a.10 — Doctrine note: architect-supplied reference values must be cross-referenced against authoritative source

When architect provides reference values for boot-time self-tests
(or any verification mechanism comparing against external constants),
the architect must validate against authoritative source rather
than relying on recall. R3.1 risk classification — flagged at
recon, realized at HALT 2B — is now canon.

For this pod, authoritative source was
github.com/veorq/SipHash/blob/master/vectors.h (with antirez/siphash
mirror as cross-reference). Future pods involving cryptographic
primitives or other reference-value verification: the architect
provides the URL of the authoritative source alongside the value,
enabling executor-side cross-reference at recon time.

The verification surface that catches the mistake is cheaper at
recon than at boot, which is cheaper than at handler-pod test time.
HALT 1 recon is the right checkpoint; the value-comparison literal
should be one of the things the recon report cross-references against
authoritative source, not just transcribes from architect input.

The cap.asm:285 fix added a comment line recording source-of-truth
alongside the value as forward-anchor for future eyes:
```nasm
; Compare to expected (canonical veorq vectors_sip64[8] little-endian u64)
mov     rcx, 0x93f5f5799a932462
```

Comment rot is a real concern for source-anchor comments; the
mitigation is that the value itself is constrained by the algorithm
plus inputs, so future comment-vs-code drift gets caught by the
self-test the same way the original wrong literal was.

---

## Forward-looking ledger

### Pod 1.10.2b will close

- DEFERRED #57 (Pod 1.10.2b inheritance of 1.10.2a substrate)
- DEFERRED #54 (Pod 1.10.2b opcode handlers + retrofit + tests)
- DEFERRED #50 (ERR_INVALID_ENERGY_ARG defined-but-unused — Pod
  1.10.2b might find a consumer if Cap-gated Energy ops emerge;
  otherwise rolls forward)

### Pod 1.10.2b might surface

- Free-list mechanism question (DEFERRED #19 family) gets renewed
  attention if 64-slot Cap pool feels constraining under Cap delegation
  patterns
- Cap-gated Outcome construction: should OP_OUTCOME_NEW_OK / NEW_ERR
  consult current_cap_id for arena/owner attribution? Likely yes;
  ratification at 1.10.2b recon
- Generation counter advancement on revocation — might surface as
  a Pod 2 concern (per DEFERRED #56) but could also need substrate
  hooks at 1.10.2b

### Pod 1.10.2a does not close

DEFERRED #59 (housekeeping bundle gains pod1102a_canary_test.sh +
pod1102a_b5_b6_runner.sh; sixth and seventh throwaway scripts after
Pod 1.9.4 cleared the previous bundle). Forward-log per D1.9.4.1
removal-over-merge ratification.

### Pod 2 (Cop) substrate-secret hardening forward-log

Per DEFERRED #56:
- siphash_key rotation policy (per-arena? per-cap-grant burst?)
- generation_counter advancement protocol for cap revocation
- Cryptographic cost class refinement for OP_CAP_CHECK
- Spatial-merge delegation tax (from pre-v10 Cap design)

Pod 2 inherits substrate primitives + adds policy/tuning/auditing.
1.10.2a's siphash_key_source flag preserved for audit becomes
load-bearing at Pod 2.

— Terminal Boy
May 04 2026
