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

## 13. Stack-error mechanism design (revised Pod 1.4)

Pod 1.9 (Outcome<T>) must define the specific representation for
stack-violation errors: error codes, stack-frame tagging, how a
typed `Err(StackOverflow)` or `Err(StackUnderflow)` sits on the VM
stack alongside normal values. The principle is decided (Q8: stack
violations are typed Outcome results, not fatal traps), but the
encoding is deferred to Pod 1.9's recon phase. Pod 1.3's interim
implementation halts with diagnostic messages (`str_ret_underflow`,
`str_call_overflow`); Pod 1.9 replaces these with typed results.

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

## 16. Outcome error path for invalid canonical-ID lookups (added Pod 1.8.5b)

`registry_lookup_sign` and `registry_lookup_energy` return `0` when an
ID is not found (id == 0 or no matching entry). Current Sign/Energy
accessor handlers fall through to existing null-paths that push 0/null
on the operand stack — no typed `Outcome::Err` representation. Pod 1.9
(Outcome) formalizes the error type and accessor handlers should be
retrofitted to push `Err(InvalidId)` instead of silent null. Same
pattern will apply to `cap_id`, `demod_id`, `signal_id` registry
lookups when those primitives land.

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

## 33. tools/pod185b_qemu_test.sh + tools/pod185c_qemu_test.sh (added Pod 1.8.5c)

Two throwaway QEMU monitor-pipe scripts now untracked across two pods.
Both follow the same shape: inject a .cbc onto a scratch image, boot
QEMU daemonized, send keystrokes, screendump, quit. Either earn
permanent test-fixture status under `tools/test/` (parameterized to
take any test pair) or get removed in the housekeeping bundle pod.
Carryover from Pod 1.8.5b's housekeeping deferral.

## 34. tools/pod185c_b6_liveness.sh (added Pod 1.8.5c)

Third throwaway script — pristine-boot liveness probe with screendump.
Single-purpose, simpler than the round-trip harnesses but overlapping
with the existing `test_qemu.sh --headless` (which already does
liveness but does not screendump). Same disposition options as #33:
earn `tools/test/` status by merging into `test_qemu.sh` as a
`--headless-screendump` mode, or remove in housekeeping bundle.
