# Deferred Tasks

Items surfaced during Pod 0 that deserve future attention but didn't
warrant their own Pod 0 section. Append-only across pods. Items are
removed when resolved (with a note in the resolving pod's commit).

> **Numbering policy:** Numbers are stable across pods. Resolved items are
> removed; gaps are preserved to avoid breaking cross-document references.
> Item #N always means item #N. If you find a gap, that's an item that
> got resolved in some pod's commit; check git log for `DEFERRED #N`.

---

## 1. LLC / signing entity rename

Banner, file headers, and canonical doc author lines all read
"Randolph Pelican III / StableTech Enterprises LLC". When the
software-signing entity name is finalized (may differ from
StableTech), a single cleanup pod replaces all instances repo-wide.
Awaiting architect decision on entity name.

## 2. ide_pio.asm NASM warnings

`drivers/ide_pio.asm:82` emits "implicit DEFAULT ABS is deprecated"
and `drivers/ide_pio.asm:157` emits "unsigned byte exceeds bounds".
Both are non-fatal; binary builds correctly. Cleanup pod in Pod 1
or later when VM hardening touches I/O paths.

## 3. chauncey_test.md Legacy BIOS reference

`tools/chauncey_test.md` says "Boot Mode: Legacy BIOS (disable UEFI)"
but the project is UEFI-native. Architect to verify Chauncey hardware
supports UEFI; if so, doc gets corrected. If not, project has a real
hardware testing constraint to address.

## 4. Bastian slot expansion

V1 ships twelve-slot infrastructure with 4 surfaces wired (Bastian,
Gmork, Atreyu, Rockbiter) and 8 routing to coming-soon stubs. Each
stub gets wired as its surface comes online: Auryn standalone in
Pod 5, Empress and Koreander in Pod 7, Rockbiter expansion and
Falkor in Pod 8, etc.

## 5. Visual / banner refresh

Current banner styling is functional but provisional. Refresh deferred
until V1 surfaces are complete and a coherent visual identity is
designed.

## 6. Orphaned opcodes (revised Pod 1.2)

Three opcodes are defined in `boot/defines.asm` but not handled in
`boot/cbs_vm.asm`:

- `OP_DUP2` (0x87) — defined, handler exists at `cbs_vm.asm:645–652`
  but is not in the dispatch chain (dead code). Not addressed in
  Pod 1.3 (scope was OP_CALL/OP_RET only). Wire into dispatch or
  remove in a future cleanup pod.
- `OP_GRANT_CAP_NEW` (0xCA000003) — Phase 5.1 ghost. Not an opcode:
  4-byte value, but VM dispatches on single bytes — unreachable as
  an opcode. Actually a capability token constant, misnamed with OP_
  prefix. Removed when cap ops are retired in Pod 1.11.
- `OP_USE_CAP_NEW` (0xCA000004) — same as above.

## 7. README full rewrite + token header cleanup (revised Pod 1.4)

Current `README.md` is from the Python-era CBS toolchain phase. It
references `tools/cbsc.cbs` and `tools/vm.cbs`, mentions "Phase 8"
and "v4.0-reorganized-structure" — none of which describe the current
NASM-only build. Pod 0.8 patched it with a "Where to start" section
pointing at canon docs, but the body still describes an earlier
project state. Full rewrite deferred until V1.0 architecture is
fully implemented (post-Pod-5).

Additionally, README references a "23-byte surface token header" that
is a Python-toolchain-only artifact. The NASM VM does not parse it
(per Pod 1.1 audit, Q6 decision). The README rewrite should remove
or correctly scope the token header reference.

The Python toolchain (`tools/atreyu_x86.py`) was updated atomically
with the runtime in Pod 1.5 (D3 decision). Note: `tools/cbsc.cbs` is
Phase 8 detritus with a different bytecode format — the actual CBS
compiler is `tools/atreyu_x86.py`. The README rewrite should reference
the correct toolchain.

## 9. Paging implementation, post-V1

`kernel/_future/paging.asm` contains design notes (see
`recon/POD0.9_CAP_GRAPH_DEEP_READ.md` for the deep-read analysis).
V1.0 ships using UEFI's identity-mapped memory. Per Pod 0.9
analysis, V1.0 has no feature requirement that demands own-paging.
Post-V1 paging is deferred until a feature requires it: separate
userspace, write-combining framebuffer performance, NX bit on data,
etc.

When paging arrives, the design constraints from Pod 0.9 memo:
- Static page pool, not UEFI BS allocation
- 1GB-page identity map for low memory
- PAT/PCD flags for framebuffer write-combining (skip the framebuffer
  range from the 1GB map, then map separately with 4K pages)
- Build tables before ExitBootServices, install CR3 only after EBS

## 10. Pod 0.9 entry — to be addressed by future cleanup pod

`build/BOOTX64.EFI` is showing as tracked-and-modified in `git status`
because it was committed at some point in early Pod 0 history before
the gitignore was tightened. A one-line cleanup — `git rm --cached
build/BOOTX64.EFI` — removes it from tracking while leaving the file
on disk and gitignored. Not blocking; a 30-second fix whenever the
next maintenance pod runs.

## 11. cap_atreyu dead code (added Pod 1.2)

`cbs_vm.asm:408–493` implements six Atreyu editor operations
(get/set_size, get/set_char, insert, delete) with no dispatch entry
in `op_use_cap` — unreachable dead code. Left in place through Pod 1
cap ops retirement (Pod 1.11). Pod 6 (Atreyu Walks) decides whether
to rebuild from this skeleton or start fresh. See RECONSTITUTION v4
"Exiled in place" section and `recon/POD1.1_VM_AUDIT.md` T7.

## ~~12. Surface .cbc recompilation after 64-bit migration~~ (RESOLVED — Pod 1.5)

Resolved in Pod 1.5. demo.cbc regenerated via `tools/atreyu_x86.py --build`;
surface .cbc files (atreyu.cbc, bastian.cbc, rockbiter.cbc) hand-patched
with automated widening script. All value operands now 8-byte; positional
operands unchanged at 4-byte per D1.

## ~~13. Stack-error mechanism design (revised Pod 1.4)~~ (RESOLVED — Pod 1.9.3)

Pod 1.9 (Outcome<T>) must define the specific representation for
stack-violation errors: error codes, stack-frame tagging, how a
typed `Err(StackOverflow)` or `Err(StackUnderflow)` sits on the VM
stack alongside normal values. The principle is decided (Q8: stack
violations are typed Outcome results, not fatal traps), but the
encoding is deferred to Pod 1.9's recon phase. Pod 1.3's interim
implementation halts with diagnostic messages (`str_ret_underflow`,
`str_call_overflow`); Pod 1.9 replaces these with typed results.

**Resolved Pod 1.9.3 D1.9.3.2 (Pre-A2 option b — tag-the-halt):**
`.ret_underflow` and `.call_overflow` now construct `Err(ERR_STACK_UNDERFLOW)`
and `Err(ERR_STACK_OVERFLOW)` Outcomes via `.construct_err_outcome` helper,
push the outcome_id to the operand stack, then emit the existing diagnostic
and halt via `.done`. The Err is observable on the operand stack at halt
time (post-mortem). Continuing past stack violations remains Pod 2 (Cop)
territory. B6 and B7 confirmed via screen output: pre-violation marker →
diagnostic appears → halt clean (program does not reach post-violation
prints).

## 14. precompile_all.sh CRLF line endings (added Pod 1.7)

`tools/precompile_all.sh` has Windows CRLF line endings, causing
`\r': command not found` errors when run under WSL/Linux. The script
is non-blocking because fallback to existing `.cbc` files works, but
it should be converted to Unix line endings (`dos2unix` or `sed -i
's/\r$//'`). Low priority — only affects fresh recompilation workflow.

## ~~15. Energy display bug — r15 uninitialized (added Pod 1.7)~~ (RESOLVED — Pod 1.8)

The CBS VM exit path prints r15 as "energy used" (alongside r14 as
"energy remaining"), but `cbs_run` never initializes r15. The value
displayed is whatever was in r15 at VM entry — typically a stale
register from UEFI context. r14 (energy remaining) is correct;
`[rel energy_used]` in memory is correct. The display line that prints
r15 is misleading. Fix in Pod 1.8 (Energy typed primitive) when the
energy display is redesigned. See D1.7.8 in
`recon/POD1.7_DECISION_RECORD.md`.

## 16. Outcome error path for invalid canonical-ID lookups (added Pod 1.8.5b; PARTIALLY RESOLVED Pod 1.9.3)

`registry_lookup_sign` and `registry_lookup_energy` return `0` when an
ID is not found (id == 0 or no matching entry). Current Sign/Energy
accessor handlers fall through to existing null-paths that push 0/null
on the operand stack — no typed `Outcome::Err` representation. Pod 1.9
(Outcome) formalizes the error type and accessor handlers should be
retrofitted to push `Err(InvalidId)` instead of silent null. Same
pattern will apply to `cap_id`, `demod_id`, `signal_id` registry
lookups when those primitives land.

**PARTIAL CLOSURE — Pod 1.9.3 (D1.9.3.1, A1 i-revised):**
Single-value accessors refitted under Path A (success wraps in
Outcome::Ok via `.construct_ok_outcome`; failure constructs Err via
`.construct_err_outcome`):
- OP_SIGN_ENERGY ✓
- OP_ENERGY_JOULES ✓
- OP_ENERGY_SOURCE_OP ✓

**STILL OPEN — multi-value accessors (HASH, LABEL):**
- OP_SIGN_HASH (returns 4 hash qwords on success)
- OP_SIGN_LABEL (returns addr+length on success)

Outcome<T> per D1.9.1.1 wraps a single u64. Multi-value accessors
require either (a) new Outcome design supporting multi-value wrapping,
(b) handle-pool redesign returning single u64 handle to multi-value
data, or (c) substrate peek-without-consume primitive enabling
discriminant-then-shape-branching. Pod 3+ work; not blocking Pod 1.10
(Cap) or Pod 1.12 (Demod) since those typed primitives are likely
single-value (cap_id, demod_id).

## 17. Cap, Demod, Signal registry implementations (added Pod 1.8.5b)

`CAP_ID_NULL`, `DEMOD_ID_NULL`, `SIGNAL_ID_NULL` are reserved as types
in `boot/defines.asm` (Pod 1.8.5b Move 4) but the corresponding
registry tables and `registry_register_*` / `registry_lookup_*`
functions don't exist yet. Pod 1.10 (Cap), Pod 1.12 (Demod), and
Pod 4 (Interpreter) add their own registry pairs in `boot/registry.asm`
following the Sign/Energy shape established by this pod.

## 18. Linear-scan registry lookup optimization (added Pod 1.8.5b, post-V1)

`registry_lookup_sign` and `registry_lookup_energy` use linear scan
over `{id, slot_ptr}` entries (O(n) where n = pool capacity, currently
64). Acceptable for V1.0; at high pool capacities or high lookup
frequencies an open-addressing hash table or sorted-array binary
search would amortize. Defer until profiling shows accessor calls as
a hot path.

## 19. OP_*_FREE registry invalidation (added Pod 1.8.5b)

`OP_ENERGY_FREE` is a V1.0 no-op (consumes id, no slot recycling).
Future SIGN/ENERGY/CAP/etc. FREE primitives that reclaim slots must
also invalidate the registry entry — either set `slot_ptr = 0` and
have `registry_lookup_*` treat that as not-found, or compact the
registry on free. Without this, a freed-then-recycled slot would map
two distinct IDs to the same `slot_ptr`, breaking the canonical-ID
invariant. Sealed for whichever pod activates free-list recycling
(Pod 1.10+ or post-V1).

## 20. codebook.img non-determinism (mtools mformat random volume serial) (added Pod 1.8.5b)

`./build.sh` produces a `BOOTX64.EFI` that is byte-deterministic across
runs but a `codebook.img` (FAT32 wrapper) that is not — `mkfs.vfat` /
`mformat` injects a random volume serial number on each invocation
(observed e.g. `1F9C-6BAD` then different on rebuild). The substantive
product is the EFI; the .img is transport. `binary_contracts.md`
records EFI sha256 only, so this does not affect the contract chain.
Cleanup: pass a fixed serial via `mkfs.vfat -i HHHHHHHH` or equivalent
mtools flag in build.sh. Latent at least since Pod 1.8; surfaced
explicitly during Pod 1.8.5b R5 recon. Low priority.

## 21. .cbc test files not copied onto FAT32 image (added Pod 1.8.5b)

`./build.sh` copies only `BOOTX64.EFI` to the FAT32 image; .cbc files
in `surfaces/` (sign_test.cbc, test_energy.cbc, etc.) are not copied,
so `gmork> load <filename>` cannot find them out-of-the-box. Pod 1.7
and Pod 1.8 (and Pod 1.8.5b's B2/B3 round-trips) have been working
around this by manually `mcopy`-ing test files onto a scratch image
before launching QEMU. A `--with-tests` or `--full-image` flag in
build.sh that copies `surfaces/*.cbc` onto the image would make
testing more ergonomic. Low priority; document the workaround in
`recon/POD1.8_QEMU_AUTOMATION.md` if a fresh test setup is needed
before this is fixed.

## 22. morla.asm reuses str_run_bad for file-not-found (added Pod 1.8.5b)

`boot/morla.asm:193` and `:247` print `str_run_bad` ("Usage: run
<0-8>") when a `load <filename>` operation fails (file not found,
read error, etc.). The user sees a misleading message about the `run`
command when the actual issue is with `load`. Should be a dedicated
`str_load_failed` (or similar) message. Surfaced during Pod 1.8.5b
B2/B3 round-trip when test files were not on the image. Low priority,
cosmetic.

## 23. Bastian menu order (added Pod 1.8.5b)

`recon/POD1.8_QEMU_AUTOMATION.md` step-by-step example uses `sendkey 2`
to enter Gmork, which is correct under the current Bastian menu (item
1 = Bastian Home, item 2 = Gmork Terminal). Earlier QEMU-automation
narrative in chat-history canon stated `sendkey 1` for Gmork, which
matched a pre-Pod-0.7 menu ordering. Pod 1.8.5b round-trip script
`tools/pod185b_qemu_test.sh` (throwaway, not committed) uses `sendkey 2`
correctly. Reference doc is current; recording for context only.

## 24. Pod 1.8.5b.6: commit v4 main body verbatim (added Pod 1.8.5b.5)

Architect-direct paste to TB required. Original draft in prior Chauncey
session that produced `recon/CHAUNCEY_HANDOFF_v4_addendum.md` (committed
at `e5595d5`); preserved in architect's catchup-doc upload to current
Chauncey instance. Pod 1.8.5b.5 deferred this commit to avoid
Chauncey-mediated verbatim transcription with PowerShell escape
fragility. Priority: high (closes the bootstrap-paradox gap for v4
handoff main body).

## 25. ProvEvent struct fields finalized when first consumer lands (added Pod 1.8.5c)

`boot/provenance.asm` defines a 32-byte ProvEvent layout: opcode at
+0x00, demod_id at +0x08, fetch_counter at +0x10, reserved at +0x18.
The reserved 8-byte field is a deliberate growth surface — Pod 2 (Cop)
will be the first consumer that actually invokes `prov_append`
automatically, and may want to populate the reserved slot with a
timestamp, source_id, outcome bits, or per-Sign-keyed provenance handle
(see DEFERRED #30). Field semantics seal at first-consumer time.

## 26. Provenance ring buffer sizing tunable (added Pod 1.8.5c)

`prov_ring_buf` is sized 4KB / 32B = 128 entries (PROV_RING_ENTRIES).
Sized by symmetry, not measurement. Pod 2 (Cop) implements detection
and runs DeepSeek overhead measurement (TERRAFORM-2); ring buffer size
becomes empirical at that point. Power-of-2 ring math (mask 0x7F) means
resizing is a one-define change at the seal — re-tune `PROV_RING_ENTRIES`
to whatever the measurement says, update PROV_RING_MASK accordingly.

## 27. Per-demod cost table real differentiation (added Pod 1.8.5c)

V1.0 every demod's `current_demod_cost_table_ptr` defaults to the
single global `energy_cost_table`. The indirection exists; the
differentiation does not. Pod 2 (Cop) hands out tuned tables per demod
based on declared discipline (e.g., a graceful-degradation demod gets
gentler costs on its own surface but standard costs on cross-surface
calls). The hook is in place at `boot/energy_costs.asm:energy_cost_lookup`
which dereferences the per-demod pointer.

## 28. vm_phase boundary refinement (added Pod 1.8.5c)

V1.0 boot sequence advances SEED → FORM → CHANNELS → MIND with MODES
enum-reserved-but-unwritten (A2 collapse). If Pod 5 (Surfaces) discovers
natural phase splits the current 5-state model misses — particularly a
real MODES transition when surface-mode-switching machinery exists, or
intermediate states between CHANNELS and MIND when surface registration
becomes a multi-step process — the enum and the boot.asm phase-write
sites get refined at that pod. The current shape is honest for V1.0;
revisit at the pod that gives MODES real semantics.

## 29. arena_id / owner_demod_id real values (added Pod 1.8.5c)

V1.0 writes 0 to both fields at OP_SIGN_NEW and OP_ENERGY_NEW
construction. There is no real arena (single global) and no demod
ownership tracking. Pod 1.10 (Cap) introduces real arenas; Pod 1.12
(Demod) introduces real ownership tracking. At those pods, the field
writes shift from hardcoded `mov qword [...], 0` to reads from the
current cap-arena and current-demod runtime state.

## 30. provenance_handle field reclaimed in Pod 1.8.5c (added Pod 1.8.5c)

The Sign slot offset 0x70, formerly `provenance_handle` (V1.0 zeroed
and rejected if non-zero), is reclaimed for `arena_id` under Move 3
A1(d). Move 2's auto-provenance ring buffer absorbs the per-Sign
provenance role — chains route through ProvEvent rather than a per-Sign
handle. Pod 3+ handle pools that want per-Sign-keyed provenance must
route through ProvEvent's reserved 8 bytes (DEFERRED #25) or a separate
handle table. Do not re-add a `provenance_handle` field to the Sign
slot; the offset is structurally claimed.

## 31. V1.1 sentinel field reclaimed in Pod 1.8.5c (added Pod 1.8.5c)

The Sign slot offset 0x78, formerly the V1.1 sentinel placeholder, is
reclaimed for `owner_demod_id` under Move 3 A1(d). Future per-Sign
sentinel/version mechanisms must route through ProvEvent's reserved
slot or struct-level versioning (e.g., a separate version table keyed
by sign_id), not a slot byte. The offset is structurally claimed.

## 32. OP_SIGN_NEW signature: 5-arg shape preserved post-1.8.5c (added Pod 1.8.5c)

Pod 1.8.5c S6 decision: OP_SIGN_NEW continues to pop 5 args (ABI
preserved). The topmost arg (formerly `provenance_handle`, validated
as 0) is now silently discarded — the validation check was removed and
the slot field at +0x70 was reclaimed for `arena_id`. The popped value
is dead. Pod 3+ handle-pool work may either rebind the 5th arg to a
new field (e.g., a real provenance handle once ProvEvent is consumed)
or shrink to 4-arg with explicit ABI break and atomic atreyu_x86.py
update. Track this disposition at the handle-pool pod.

## ~~33. tools/pod185b_qemu_test.sh + tools/pod185c_qemu_test.sh (added Pod 1.8.5c)~~ (RESOLVED — Pod 1.9.4)

Two throwaway QEMU monitor-pipe scripts now untracked across two pods.
Both follow the same shape: inject a .cbc onto a scratch image, boot
QEMU daemonized, send keystrokes, screendump, quit. Either earn
permanent test-fixture status under `tools/test/` (parameterized to
take any test pair) or get removed in the housekeeping bundle pod.
Carryover from Pod 1.8.5b's housekeeping deferral.

## ~~34. tools/pod185c_b6_liveness.sh (added Pod 1.8.5c)~~ (RESOLVED — Pod 1.9.4)

Third throwaway script — pristine-boot liveness probe with screendump.
Single-purpose, simpler than the round-trip harnesses but overlapping
with the existing `test_qemu.sh --headless` (which already does
liveness but does not screendump). Same disposition options as #33:
earn `tools/test/` status by merging into `test_qemu.sh` as a
`--headless-screendump` mode, or remove in housekeeping bundle.

## 35. Pod 1.9.2 will close DEFERRED #13 (added Pod 1.9.1, forward-looking)

Pod 1.9.1 sealed the architectural decision (D1.9.1.3 two-mode
handlers + D1.9.1.4 five accessor opcodes). Pod 1.9.2 lands the
slot pool, registry, opcode handlers, and `vm_fetch_count` substrate
counter (D1.9.1.7). Pod 1.9.3 then refits the existing stack-violation
halt sites (`str_ret_underflow`, `str_call_overflow` per #13) to push
typed `Err(StackUnderflow)` / `Err(StackOverflow)` Outcomes via
OP_OUTCOME_NEW_ERR. **#13 closes when Pod 1.9.3 commits.** Tracking
here as in-flight; do not mark resolved until the refit lands.

## 36. Pod 1.9.3 will close DEFERRED #16 (added Pod 1.9.1, forward-looking)

Pod 1.9.1 sealed the err shape (D1.9.1.2 standard 32-byte error
context). Pod 1.9.3 source pod refits `OP_SIGN_HASH`, `OP_SIGN_LABEL`,
`OP_SIGN_ENERGY`, `OP_ENERGY_JOULES`, `OP_ENERGY_SOURCE_OP` (and any
other accessor reaching the registry-lookup-returns-0 null path) to
construct `Err(InvalidId)` Outcomes via OP_OUTCOME_NEW_ERR and push
the resulting outcome_id instead of the silent-null sentinel.
**#16 closes when Pod 1.9.3 commits.** Tracking here as in-flight.

## 37. RECONSTITUTION pod-arc reconciliation (added Pod 1.9.1)

v9 patch (Pod 1.9.1) was bounded to Outcome canon (4 edits per A5).
Other accumulated drift remains:

- **Pod 1.5.5 hash row** in pod arc says `b560a6c`; not verified
  against repo this pod. Verify and correct if drifted.
- **Pod 1.8 hash row** says `[DONE — Pod 1.8]` instead of an explicit
  hash. Actual sealing commit is `8c38343` (per Pod 1.8.5b.5 backfill
  notes). Replace placeholder with hash.
- **Pod 1.8.5, 1.8.5b, 1.8.5b.5, 1.8.5c, 1.9.1** sub-pods missing
  from the pod-arc table entirely. Add rows.
- **Cap<R> opcode allocation** in v9 still says `0xB0-0xBF` (carried
  forward from v8). Pod 1.8.5b's `boot/energy_costs.asm` comment
  hint at `0xC0-0xCF` for Cap was never canonicalized in
  RECONSTITUTION. Pod 1.10 (Cap source pod) decides the actual
  range; until then the v8 placeholder stays.

Bundle into a future RECONSTITUTION reconciliation pod (canon-only,
no source change). Could land alongside Pod 1.8.5b.6 (v4 main body
commit per #24) since both are RECONSTITUTION-class housekeeping.
Priority: medium (drift accumulates but does not block source pods).

## ~~38. Pod 1.9.2b: Outcome opcode handlers + dispatch entries (added Pod 1.9.2a, forward-looking)~~ (RESOLVED — Pod 1.9.2b)

Pod 1.9.2a landed substrate plumbing (slot pool, registry,
vm_fetch_count, constants); Pod 1.9.2b lands the five accessor
opcode handlers in cbs_vm.asm (OP_OUTCOME_NEW_OK, OP_OUTCOME_NEW_ERR,
OP_OUTCOME_IS_OK, OP_OUTCOME_UNWRAP_OK, OP_OUTCOME_UNWRAP_ERR at
0xE0-0xE4) plus dispatch entries in the .fetch chain. Per
D1.9.1.4 stack-effect specs and D1.9.1.8 sentinel-and-log
convention. Outcome behavior is not testable until 1.9.2b commits.

## ~~39. Pod 1.9.2b: cost table entries for 0xE0-0xE4 (added Pod 1.9.2a, forward-looking)~~ (RESOLVED — Pod 1.9.2b)

`boot/energy_costs.asm` cost table currently treats 0xE0-0xE4 as
default (1j) under the "Demod 0xE0-0xEF Pod 1.12" comment. Pod
1.9.2b updates: OP_OUTCOME_IS_OK (0xE2) costs 0j per D1.8.5c.8
structural classification (state query, not metabolic work);
OP_OUTCOME_NEW_OK / NEW_ERR / UNWRAP_OK / UNWRAP_ERR cost 1j
default (Pod 2 Cop tunes if measurement warrants). The cost-table
comment for row 0xE0-0xEF needs reclassification text (Outcome
0xE0-0xE4 + Demod 0xE5-0xEF).

## ~~40. Pod 1.9.2b: sentinel log strings (added Pod 1.9.2a, forward-looking)~~ (RESOLVED — Pod 1.9.2b)

D1.9.1.8 push-sentinel-and-log convention requires two new strings
in `boot/data.asm`:
- `str_unwrap_ok_on_err: db '  UNWRAP_OK on Err — sentinel returned',10,0`
- `str_unwrap_err_on_ok: db '  UNWRAP_ERR on Ok — zero sentinels returned',10,0`
OP_OUTCOME_UNWRAP_OK and OP_OUTCOME_UNWRAP_ERR handlers emit the
respective string via `auryn_puts` when discriminant mismatches.

## ~~41. Pod 1.9.2b: prov_append hook in OP_OUTCOME_NEW_ERR (added Pod 1.9.2a, forward-looking)~~ (RESOLVED — Pod 1.9.2b)

D1.9.1.6 wire-up: after writing the err context to the slot at
+0x20-+0x3F, OP_OUTCOME_NEW_ERR loads `[rbx+0x28]` (err_source_op)
into rdi, `[rbx+0x30]` (err_demod_id) into rsi, `[rel vm_fetch_count]`
into rdx, then calls prov_append. The cap-gate is internal to
prov_append (default-OFF per Move 2 doctrine). Caller-preserve
semantics from boot/provenance.asm preserve r12-r15 / rbx / rbp
across the call.

## ~~42. Pod 1.9.2b: tools/atreyu_x86.py support for Outcome opcodes (added Pod 1.9.2a, forward-looking)~~ (RESOLVED — Pod 1.9.2b)

Add 5 opcode constants (OP_OUTCOME_NEW_OK = 0xE0 through
OP_OUTCOME_UNWRAP_ERR = 0xE4); 5 AST handlers in `_expr` and
`_stmt`; 6 demo functions (`demo_outcome_ok`, `demo_outcome_err`,
`demo_outcome_is_ok`, `demo_outcome_unwrap_ok`,
`demo_outcome_unwrap_err`, `demo_outcome_dup_is_ok`); 6 build flags
(`--outcome-ok-build`, etc.). Output filenames per architect's list:
`test_outcome_ok.cbc`, `test_outcome_err.cbc`,
`test_outcome_is_ok.cbc`, `test_outcome_unwrap_ok.cbc`,
`test_outcome_unwrap_err.cbc`, `test_outcome_dup_is_ok.cbc`.

## ~~43. Pod 1.9.2b: vm_fetch_count smoke test exercised through prov_append (added Pod 1.9.2a, forward-looking)~~ (RESOLVED — Pod 1.9.2b)

B5 was skipped in Pod 1.9.2a because no clean instrumentation
mechanism exists for reading vm_fetch_count without the opcode
handlers. Pod 1.9.2b's OP_OUTCOME_NEW_ERR exercises the counter
through the prov_append fetch_counter argument. **Resolved**: B5
ran cleanly with cap-gate default-OFF (current_demod_prov_enabled=0
kept the prov_append call as a no-op), but the call site itself was
verified clean (no crash, VM state preserved across the call). When
Pod 2 (Cop) flips the cap, the existing wire-up activates without
further source change.

## ~~44. Pod 1.9.3: Sign accessor refit to return Outcome (added Pod 1.9.2b, forward-looking)~~ (PARTIALLY RESOLVED — Pod 1.9.3)

OP_SIGN_ENERGY refitted under Path A (success wraps in Outcome::Ok;
failure constructs Err). OP_SIGN_HASH and OP_SIGN_LABEL deferred per
A1 (i-revised) — multi-value accessor refit pending Outcome<T>
multi-value design or handle-pool redesign (see #16 still-open
section).

(Original entry text follows for context.)

Existing Sign accessors (OP_SIGN_HASH, OP_SIGN_LABEL, OP_SIGN_ENERGY)
fall through to silent-null sentinel paths when registry_lookup_sign
returns 0. Pod 1.9.3 refits each to construct `Err(InvalidId)` Outcome
via OP_OUTCOME_NEW_ERR and push the resulting outcome_id instead of
the silent null. Closes DEFERRED #16. The `value_type_id` for these
err-Outcomes is TYPE_CODE_SIGN per D1.9.2b.3 (expected-T-on-error).

## ~~45. Pod 1.9.3: Energy accessor refit to return Outcome (added Pod 1.9.2b, forward-looking)~~ (RESOLVED — Pod 1.9.3)

Same shape as #44 for Energy accessors (OP_ENERGY_JOULES,
OP_ENERGY_SOURCE_OP). Refit silent-null paths to push
`Err(InvalidId)` Outcomes. `value_type_id = TYPE_CODE_ENERGY`.

## ~~46. Pod 1.9.3: stack-violation halt sites refit to push Err Outcomes (added Pod 1.9.2b, forward-looking)~~ (RESOLVED — Pod 1.9.3)

Closes DEFERRED #13. Existing stack-violation halt sites
(`str_ret_underflow`, `str_call_overflow`) currently halt with a
diagnostic message. Pod 1.9.3 refits to push
`Err(StackUnderflow)` / `Err(StackOverflow)` Outcomes via
OP_OUTCOME_NEW_ERR. Specific err_code constants land in defines.asm
at 1.9.3 (e.g., `ERR_STACK_UNDERFLOW`, `ERR_STACK_OVERFLOW`).
`value_type_id` is the in-flight expected-T at the moment of
violation — needs design ratification at 1.9.3 recon (TB will
surface as A-call: stack violations may not have a stable
value_type_id since the typing depends on what was being computed).

## 47. Pool-full handling in OP_OUTCOME_NEW_OK / OP_OUTCOME_NEW_ERR (added Pod 1.9.2b, forward-looking)

Per D1.9.2b.8 (A2 ratification): V1.0 sentinel-only on capacity
exhaustion. NEW_OK / NEW_ERR push 0 sentinel if pool/registry full
(unreachable in V1.0 with capacity 64 + tests constructing 1-2
outcomes). Pod 2 (Cop) hardens with explicit log + audit signal +
possibly graceful degradation. May add `str_outcome_pool_full` at
that pod. Forward-log only; no immediate action needed.

## ~~48. tools/pod192b_qemu_test.sh joins housekeeping bundle (added Pod 1.9.2b)~~ (RESOLVED — Pod 1.9.4)

Fourth throwaway QEMU monitor-pipe test script (after
tools/pod185b_qemu_test.sh, tools/pod185c_qemu_test.sh,
tools/pod185c_b6_liveness.sh per #33-#34). Same disposition options:
earn `tools/test/` status by merging into `test_qemu.sh` as a
parameterized test runner, or remove in housekeeping bundle pod.
The bundle has now grown to four scripts spanning three source pods;
merge-into-test_qemu.sh option worth flagging as the more sustainable
path at the eventual reconciliation pod.

## 49. Outcome pool sizing review / free-list mechanism for Path A semantics (added Pod 1.9.3)

Pod 1.9.3 D1.9.3.1 ratified Path A: every successful single-value
accessor allocates an Outcome slot via `.construct_ok_outcome` and
registers it in `outcome_registry`. With OUTCOME_POOL_SLOTS=64 and
no free-list, a program calling accessors 64+ times across a single
VM run exhausts the pool. Test programs in V1.0 call accessors 1-3
times; exhaustion is multi-program territory across non-resetting
substrate state.

Pod 2 (Cop) territory:
- Pool sizing review (does 64 hold for production workloads?)
- Free-list mechanism for OP_OUTCOME_FREE (currently no such opcode;
  would need to land alongside the recycling)
- Or: "Outcome::Ok wrapping is opt-in via a separate UNWRAP_OK
  variant" if pool pressure becomes load-bearing — but that fragments
  the typed-primitive accessor pattern Pod 1.10 / Pod 1.12 inherit.

Not blocking V1.0 typed-primitive pods. Real concern for production
scale.

## 50. ERR_INVALID_ENERGY_ARG defined-but-unused (added Pod 1.9.3)

Pod 1.9.3 S1 added `ERR_INVALID_ENERGY_ARG equ 6` to defines.asm
per the original prompt's err_code list. Per A3 ratification,
`.energy_new_fail` uses single err_code ERR_POOL_FULL because
OP_ENERGY_NEW currently doesn't validate joules or source_op.

The constant is defined but unused in V1.0. When Energy NEW arg
validation lands (Pod 2 Cop or wherever), the constant activates
without redefinition. Honest forward-log of the architectural
intent.

## 51. T7 test_sign_pool_full forward-logged (added Pod 1.9.3)

Verifies OP_SIGN_NEW.sign_new_fail_pool_full path produces
Err(POOL_FULL) Outcome. Requires loop emission for 65 NEW_OK
constructions in atreyu_x86.py. Skipped Pod 1.9.3 per A4 — adds
substantial test bytecode without testing anything that can't be
validated by static review of the .sign_new_fail_pool_full handler.

Forward-log to a future verification pod (or to Pod 2 Cop when pool
pressure becomes a real concern per #49).

## ~~52. tools/pod193_qemu_test.sh joins housekeeping bundle (added Pod 1.9.3)~~ (RESOLVED — Pod 1.9.4)

## ~~53. Pod 1.10.2a substrate plumbing inherits D1.10.1.1-14 (added Pod 1.10.1, forward-looking)~~ (RESOLVED — Pod 1.10.2a)

Pod 1.10.2a lays the Cap substrate per D1.10.1.13: vm_cap_pool, cap_registry,
cap_stack + cap_stack_ptr, current_cap_id, current_cap_arena_id_cache,
current_cap_owner_demod_id_cache, siphash_key, siphash_key_source flag.
Plus new `boot/cap.asm` file (~250 lines: registry register/lookup +
SipHash-2-4 + ROOT_CAP construction helper). Plus boot.asm efi_entry
additions: siphash_key derivation (RDSEED → RDRAND → hard-fail per
D1.10.1.6), ROOT_CAP construction, current_cap_id init.

Cross-asset constants verification per D1.9.2b.10: Pod 1.10.2a lands
the 5 OP_CAP_* opcode constants (D1.10.1.2, D1.10.1.3) and
ERR_CAP_AUTHORITY_EXCEEDED (D1.10.1.9, value 7) and CAP_ID_NULL
(D1.10.1.10, value 0) in defines.asm at substrate-plumbing time, not
handler-pod time.

No opcode handlers, no dispatch entries, no allocator retrofit, no
tools changes. Pod 1.10.2b lands those.

## ~~54. Pod 1.10.2b opcode handlers + retrofit + tests inherits 1.10.2a substrate (added Pod 1.10.1, forward-looking)~~ (RESOLVED — Pod 1.10.2b2 closes Pod 1.10; substrate-wide authority introspection complete; D1.10.1.8 elegance unlock fully landed across Sign/Energy/Outcome via creator_cap_id + accessors)

Pod 1.10.2b lands:
- 5 opcode handlers (OP_CAP_NEW/ENTER/EXIT/CURRENT/CHECK) in cbs_vm.asm
  + dispatch entries
- Cost table extension in energy_costs.asm (5 new entries at 0xB0-0xB4
  per D1.10.1.3) + cleanup of stale comments at lines 113 (Outcome
  was at 0xB0-0xBF; relocated 0xE0-0xE4) and 115 (Cap moved from
  0xC0-0xCF hint to 0xB0-0xBF canon)
- Allocator retrofit (3 sites: .sign_alloc, .energy_alloc,
  .outcome_alloc) replacing zero-writes at +0x70/+0x78 (Sign, Outcome)
  or +0x10/+0x18 (Energy) with reads from current_cap cache fields
  per D1.10.1.8
- Tools support in tools/atreyu_x86.py (5 opcodes + AST handlers +
  demos + CLI flags)
- Test surfaces: test_cap_new.cbc, test_cap_enter_exit.cbc,
  test_cap_check.cbc, test_cap_delegation.cbc, test_cap_invalid_check.cbc,
  test_arena_owner_inheritance.cbc (verifies D1.10.1.8 retrofit)
- Sign/Energy regeneration regression to confirm 174j/53j canaries
  still hold under retrofitted allocators
- Closes DEFERRED #37 partial — energy_costs.asm comment cleanup at
  lines 113 and 115

## 55. Pod 1.12 (Demod) inherits Cap delegation pattern (added Pod 1.10.1, forward-looking)

D1.10.1.12 strict-delegation pattern likely applies to Demod
registration: a demod registers under current_cap's authority. Pod 1.12
recon ratifies whether Demod's slot is consumer-shape (inherits +0x70
/+0x78 mirrors) or source-shape (drops them like Cap per D1.10.1.1).
demod_id is itself the identifier in arena/owner pairs; Demod may also
be source-of-authority shape. Pod 1.12 recon decides.

D1.10.1.12 also flags potential Pod 1.12 inheritance: any operation
that registers a demod likely uses the strict-delegation pattern.

## 56. Pod 2 (Cop) inherits substrate-secret hardening from D1.10.1.6 (added Pod 1.10.1, forward-looking)

Pod 1.10.1 D1.10.1.6 ratified RDSEED → RDRAND → hard-fail policy. Pod 2
(Cop) hardens further:
- siphash_key rotation policy (per-arena? per-cap-grant burst?)
- generation_counter advancement protocol for cap revocation
- Cryptographic cost class for OP_CAP_CHECK (currently 1j flat;
  Pod 2 may refine)
- Spatial-merge delegation tax (forward-logged from pre-v10 Cap design;
  energy delegation tax is a Pod 2 discipline concern, not a Pod 1.10
  substrate concern)

Pod 2 Cop is the energy-market and cryptographic-discipline pod;
inherits substrate primitives (Cap, Outcome, Sign, Energy) and adds
policy/tuning/auditing.

Fifth throwaway QEMU monitor-pipe test script (after
pod185b_qemu_test.sh, pod185c_qemu_test.sh, pod185c_b6_liveness.sh,
pod192b_qemu_test.sh per #33-#34, #48). Same disposition; the
housekeeping bundle now spans four source pods (1.8.5b, 1.8.5c,
1.9.2b, 1.9.3). Merge-into-test_qemu.sh as a parameterized
fresh-boot harness is increasingly the right shape — each script
follows the same template (mkfifo / daemonize / sendkey /
screendump / quit) with only the test surface name varying.

## 57. Pod 1.10.2b inherits 1.10.2a substrate (added Pod 1.10.2a, forward-looking)

Pod 1.10.2b lands the Cap behavior layer on top of the substrate
plumbing sealed in 1.10.2a:
- 5 OP_CAP_* opcode handlers (NEW/ENTER/EXIT/CURRENT/CHECK) in
  cbs_vm.asm + dispatch entries
- Cost table extension in energy_costs.asm (5 new entries at
  0xB0-0xB4 per D1.10.1.3) + cleanup of stale comments per #54
- Allocator retrofit per D1.10.1.8: 3 sites (.sign_alloc,
  .energy_alloc, .outcome_alloc) replace zero-writes at the arena/
  owner offsets with reads from current_cap_arena_id_cache /
  current_cap_owner_demod_id_cache
- Tools support in tools/atreyu_x86.py (5 opcodes + AST handlers +
  demos + CLI flags)
- 6+ Cap test surfaces (test_cap_new, test_cap_enter_exit,
  test_cap_check, test_cap_delegation, test_cap_invalid_check,
  test_arena_owner_inheritance verifying D1.10.1.8 retrofit)
- Sign/Energy regeneration regression to confirm 174j/53j canaries
  still hold under retrofitted allocators
- Closes DEFERRED #54

## 58. SipHash signature parameterization superseded D1.10.1.7's V1.0-specific note (added Pod 1.10.2a)

D1.10.1.7 specified a V1.0-specific signature
`siphash_compute_cap_mac(rdi=slot_ptr) -> rax=mac` with the explicit
forward-log "generalize when a second use case appears." E1's
boot-time self-test IS that second use case — the self-test consumes
SipHash with a 1-qword input where the Cap MAC consumes a 6-qword
input. Recon at 1.10.2a HALT 1 (R7) surfaced this; A1 ratification
adopted parameterized signature
`siphash_compute(rdi=field_ptr, rsi=qword_count) -> rax=mac` with
`siphash_compute_cap_mac` becoming a thin wrapper passing rsi=6.

D1.10.2a.8 records the supersession formally. The doctrine works
as designed — recon catches the parameterization need before
implementation drift. Forward-log preserved here so future pods
inherit the lesson: when a doctrine specifies "generalize when X
appears", recon at the next pod where X might appear is the right
checkpoint.

## 59. Pod 1.10.2a throwaway test scripts join housekeeping bundle (added Pod 1.10.2a)

Three throwaway QEMU test scripts in working tree (all unstaged per
DEFERRED #10 + Pod 1.9.4 D1.9.4.1 precedent):
- tools/pod1102a_qemu_test.sh — B4 pristine boot liveness harness
  (mkfifo / daemonize / 8s wait / monitor screendump / PIL save)
- tools/pod1102a_canary_test.sh — generic surface canary harness
  (mcopy surface to FAT32 image, sendkey '2' for Gmork, sendkey
  preamble Enter, type "load <surface>.cbc", screendump via monitor
  pipe, PIL save to PNG)
- tools/pod1102a_b5_b6_runner.sh — B5/B6 batch runner with
  size-diff verdict against reference PNGs

After Pod 1.9.4 housekeeping cleared the previous bundle (per
D1.9.4.1 removal-over-merge ratification), this is the first
accumulation. Same disposition options as #33-#34, #48, #52:
merge-into-test_qemu.sh as parameterized harness, or remove. Pod
1.9.4 ratified removal-over-merge for fastest path; future bundle
dispositions inherit unless architect changes direction.

The B5/B6 runner extends pattern: harness preamble must match
prior reference harness preamble (one extra Enter before load
command) for PNG file-size byte-identity to hold under reference
comparison. Diagnosed at HALT 2B as harness-reproduction issue
distinguishable from VM regression by uniform byte-delta + fixed
bbox offset signature.

## ~~60. Pod 1.10.2b2 inherits 1.10.2b1 (added Pod 1.10.2b1, forward-looking)~~ (RESOLVED — Pod 1.10.2b2 inheritance chain complete; substrate state at seal: every primitive carries arena/owner/creator)

Substrate state at 1.10.2b1 seal: ROOT_CAP live + 7 Cap opcodes
shipped + cap_stack first-consumed by ENTER/EXIT. Pod 1.10.2b2
lands the substrate-wide arena/owner introspection and observably
activates D1.10.1.8's elegance unlock:

- Sign/Energy/Outcome arena/owner accessors (parallel shape to
  Pod 1.10.2b1's Cap accessors — three accessors per primitive
  reading slot fields)
- Three-allocator retrofit per D1.10.1.8: .sign_alloc,
  .energy_alloc, .outcome_alloc replace zero-writes at the arena/
  owner offsets with reads from current_cap_arena_id_cache /
  current_cap_owner_demod_id_cache
- Retrofit observability tests verifying that primitives
  constructed under non-ROOT context carry non-zero arena/owner
- Sign/Energy regeneration regression to confirm 174j/53j canaries
  still hold under retrofitted allocators (under ROOT context,
  cache fields = 0 means slots come out byte-identical to pre-
  retrofit reference; canaries unaffected)
- Closes DEFERRED #54 fully (handlers + Cap accessors + Sign/Energy/
  Outcome accessors + three-allocator retrofit all landed)

The architectural moment continues at 1.10.2b2: Sign/Energy/Outcome
primitives become substrate-self-witnessing too. Combined with
1.10.2b1's Cap accessors, the substrate-wide elegance unlock per
D1.10.1.8 is fully realized.

## 61. ERR_CAP_AUTHORITY_EXCEEDED defined-but-unused in V1.0 (added Pod 1.10.2b1, forward-looking)

V1.0 strict delegation (D1.10.1.12 / D1.10.2b1.2) makes OP_CAP_NEW
inherit parent's arena/owner exactly with no validation gate. The
ERR_CAP_AUTHORITY_EXCEEDED err_code (=7) stays defined in
defines.asm but has no consumer in V1.0.

Activates when sub-arena delegation lands at Pod 2 (Cop) or
wherever sub-cap-of-cap with strict-subset arena/owner becomes
meaningful. Pod 2's authority-exceeded check at OP_CAP_NEW would
emit this err_code. Forward-log preserved.

## 62. Pod 1.10.2b1 throwaway test scripts join housekeeping bundle (added Pod 1.10.2b1)

Three throwaway QEMU test scripts in working tree (all unstaged
per DEFERRED #10 + Pod 1.9.4 D1.9.4.1 precedent):
- tools/pod1102b1_qemu_test.sh — B4+B13 pristine boot harness
  (copied from pod1102a_qemu_test.sh; SCREEN basename swap)
- tools/pod1102b1_canary_test.sh — generic surface canary harness
  (copied unchanged from pod1102a; pod-agnostic by design)
- tools/pod1102b1_b5_b6_runner.sh — B5/B6 batch runner with
  reference paths swapped to pod1102a refs (since 1.10.2b1 file-
  size-identical-to-1.10.2a is the regression-invisibility target)

Bundle accumulating since 1.9.4 cleared; ~6 scripts now (three
from 1.10.2a per #59, three from 1.10.2b1 here). Same disposition
options as #33-#34, #48, #52, #59: merge-into-test_qemu.sh as
parameterized harness, or remove. Pod 1.9.4 ratified removal-over-
merge for fastest path; future bundle dispositions inherit unless
architect changes direction. Six-script accumulation is the
largest since pre-1.9.4 cleanup; merge-into-test_qemu.sh shape is
increasingly attractive. Schedule housekeeping pod when convenient.

## ~~63. Pod 1.10.3 Cap metabolic wiring (added Pod 1.10.2b2, forward-looking)~~ (RESOLVED — Pod 1.10.3)

Pod 1.10.3 lands the metabolic dimension on Cap slots, setting stage
for Pod 2 Cop's spatial-merge activation:
- energy_budget (u64) and energy_used (u64) fields on Cap slots —
  per-cap metabolic accounting, foundation for delegation tax
- OP_CAP_NEW signature amended to pop (resource_descriptor,
  energy_budget) — revisits Pod 1.10.2b1 A2 ratification (strict
  delegation kept args vestigial then; metabolic accounting
  introduces non-vestigial caller input now)
- OP_CAP_BUDGET / OP_CAP_USED accessors (1j metabolic per Cap
  accessor convention; MAC verify before read)
- Slot field placement requires audit — current Cap slot has
  reserved tail at +0x38-0x7F (8 qwords); two more u64 fields fit
  cleanly without expansion
- Sets stage for Cop's spatial-merge: every authority-exercise at
  Pod 2 increments ancestor energy_used by half-cost up the chain

Pod 1.10.3 is the next pod after Pod 1.10.2b2 seals Pod 1.10.

## 64. Pod 2 Cop is born (added Pod 1.10.2b2, forward-looking)

Pod 2 inherits a substrate where every primitive carries full
provenance (Sign/Energy/Outcome × arena/owner/creator) and every
cap has metabolic accounting fields ready (energy_budget /
energy_used per #63). Cop's actual scope:
- Spatial-merge activation (delegation tax — every authority-
  exercise increments ancestor energy_used by half-cost up the
  chain via parent_cap_id walk)
- cap_bitmap structured semantics — per-cap permission bitmap
- Nonce + expiry enforcement
- Ed25519 (V1.1+ cross-trust)
- Revocation policy via generation_counter advancement
- ERR_CAP_AUTHORITY_EXCEEDED activation (per #61) when sub-arena
  delegation lands

Smaller and more focused than v3 manifesto anticipated; substrate
prep moved into Pod 1.10.3 means Cop becomes behavior-on-prepared-
substrate rather than behavior + substrate prep. The "Cop is more
focused at birth than v3 anticipated" architectural read confirmed.

## 65. Sign embedding_handle relocation when Pod 3 (Maid) lands (added Pod 1.10.2b2, forward-looking)

Pod 1.10.2b2 reclaimed Sign slot +0x68 (formerly embedding_handle
placeholder) for creator_cap_id. The reclamation continues Pod
1.8.5c's discipline (provenance_handle → arena_id, V1.1 sentinel →
owner_demod_id, embedding_handle → creator_cap_id). OP_SIGN_NEW
preserves 5-arg ABI by validating handle=0 then silently
discarding.

Pod 3 (Maid) lands real lexical embeddings and needs a home for
embedding_handle. Three options:
- Slot expansion to 136 bytes (or 256 bytes for alignment) — pool
  size grows
- Side-table indexed by sign_id — embedding_handle lives outside
  the Sign slot, registry-resolved
- Another reclaimable field if any remain at Pod 3 entry

R3.1 forward-anchor from Pod 1.10.2b2 recon. Pod 3 recon decides
based on embedding pool sizing and handle semantics.

## 66. Outcome four-path consolidation refactor opportunity (added Pod 1.10.2b2)

Outcome construction lands at four paths in cbs_vm.asm:
- .op_outcome_new_ok (program-driven NEW_OK opcode)
- .op_outcome_new_err (program-driven NEW_ERR opcode)
- .construct_ok_outcome (helper called by accessor success paths)
- .construct_err_outcome (helper called by accessor failure paths)

Pod 1.10.2b2 R3.4 surfaced this: each retrofit (creator_cap_id
addition + arena/owner from substrate state) had to land at all
four sites identically. The audit was load-bearing — silent
provenance corruption (mismatched Outcome construction paths) is
the worst failure mode this kind of pod can ship.

Refactor opportunity: NEW_OK / NEW_ERR opcode handlers thinned to
wrappers around .construct_ok_outcome / .construct_err_outcome
helpers. Eliminates the four-site retrofit surface; future field
additions land at two helper sites rather than four parallel paths.

Pod 2 or Pod 3 candidate when convenient. Worth doing before the
next Outcome slot field addition (e.g., Pod 3+ embedding_handle
or any future provenance enrichment).

## 67. Pod 1.10.2b2 throwaway test scripts join housekeeping bundle (added Pod 1.10.2b2)

Three throwaway QEMU test scripts in working tree (all unstaged
per DEFERRED #10 + Pod 1.9.4 D1.9.4.1 precedent):
- tools/pod1102b2_qemu_test.sh — B4+B14 pristine boot harness
  (copied from pod1102b1; SCREEN basename swap)
- tools/pod1102b2_canary_test.sh — generic surface canary harness
  (copied unchanged from pod1102b1; pod-agnostic by design)
- tools/pod1102b2_b5_b6_runner.sh — B5/B6 batch runner with
  reference paths swapped to pod1102b1 refs (since 1.10.2b2
  file-size-identical-to-1.10.2b1 is the regression-invisibility
  target)

Bundle accumulating since 1.9.4 cleared; ~9 scripts now (three
from 1.10.2a per #59, three from 1.10.2b1 per #62, three from
1.10.2b2 here). Same disposition options as #33-#34, #48, #52,
#59, #62: merge-into-test_qemu.sh as parameterized harness, or
remove. Pod 1.9.4 ratified removal-over-merge for fastest path;
future bundle dispositions inherit unless architect changes
direction. Nine-script accumulation across three pods of
substrate work is the largest since pre-1.9.4 cleanup;
merge-into-test_qemu.sh shape is increasingly tractable.
Housekeeping pod (Pod 1.10.3 candidate or Pod 2 candidate)
worth scheduling.

## 68. Pod 2 (Cop is born) inherits Pod 1.10.3 substrate prep (added Pod 1.10.3, forward-looking)

Pod 1.10.3 closes the substrate-prep arc. Every cap has metabolic
accounting fields (energy_budget MAC-input + energy_used non-MAC).
Every primitive across all four typed pools (Sign, Energy, Outcome,
Cap) carries full provenance (arena/owner/creator). Pod 2 (Cop)
becomes pure behavior on prepared substrate:
- Spatial-merge activation (delegation tax — every authority-
  exercise increments ancestor energy_used by half-cost up the
  parent_cap_id chain via OP_CAP_PARENT walk)
- cap_bitmap structured semantics (per-cap permission bitmap)
- Nonce + expiry enforcement
- Ed25519 cross-trust (V1.1+)
- Revocation policy via generation_counter advancement
- ERR_CAP_AUTHORITY_EXCEEDED activation (per #61) when sub-arena
  delegation lands

**No further Cap slot additions needed.** The substrate is
complete-as-substrate. Cop is smaller and more focused than v3
manifesto anticipated; substrate prep moved into Pod 1.10.3 means
Cop becomes behavior-on-prepared-substrate rather than behavior +
substrate prep.

## 69. CBS print_dec is signed-interpreting (added Pod 1.10.3, forward-looking)

CBS `OP_PRINT_NUM` (which the demo emitter uses for numeric prints)
renders u64 values via signed i64 conversion. Values >= 2^63 render
as negative — e.g., `ENERGY_BUDGET_UNBOUNDED = 0xFFFFFFFFFFFFFFFF`
renders as `-1` rather than `18446744073709551615`.

Surfaced at Pod 1.10.3 B9 — substrate stored MAX_U64 correctly
(MAC verify at boot succeeded over 7-qword range; accessor read it
back identically), but the demo's expectation comment expected the
unsigned decimal rendering. Demo comment fixed at C0; substrate
behavior is correct.

For substrate-internal values that semantically represent unsigned
quantities (energy_budget, energy_used, joules, slot offsets), this
can mislead readers of test output if the value approaches/exceeds
2^63. Future pods consider `OP_PRINT_DEC_UNSIGNED` for explicit
unsigned rendering when semantically required. Not Pod 1.10.3's
task; Pod 2 (Cop) or Pod 3 may surface it.

## 70. Pod 1.10.3 throwaway test scripts join housekeeping bundle (added Pod 1.10.3)

Three throwaway QEMU test scripts in working tree (all unstaged
per DEFERRED #10 + Pod 1.9.4 D1.9.4.1 precedent):
- tools/pod1103_qemu_test.sh — B4+B19 pristine boot harness
  (copied from pod1102b2; SCREEN basename swap)
- tools/pod1103_canary_test.sh — generic surface canary harness
  (copied unchanged from pod1102b2; pod-agnostic by design)
- tools/pod1103_b5_b6_runner.sh — B5/B6 batch runner with
  reference paths swapped to pod1102b2 refs

Bundle accumulating since 1.9.4 cleared; ~12 scripts now (three
each from 1.10.2a per #59, 1.10.2b1 per #62, 1.10.2b2 per #67,
1.10.3 here). Same disposition options as #33-#34, #48, #52, #59,
#62, #67: merge-into-test_qemu.sh as parameterized harness, or
remove. Pod 1.9.4 ratified removal-over-merge for fastest path;
future bundle dispositions inherit unless architect changes
direction.

Twelve-script accumulation across four pods of substrate work is
the largest since pre-1.9.4 cleanup; merge-into-test_qemu.sh shape
is becoming tractable — the canary test scripts are pod-agnostic
by design (just argument-driven), so a unified pod-agnostic runner
would absorb all 12 into one harness. Pod 2 or Pod 3 candidate for
absorption.
