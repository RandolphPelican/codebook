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

## 15. Energy display bug — r15 uninitialized (added Pod 1.7)

The CBS VM exit path prints r15 as "energy used" (alongside r14 as
"energy remaining"), but `cbs_run` never initializes r15. The value
displayed is whatever was in r15 at VM entry — typically a stale
register from UEFI context. r14 (energy remaining) is correct;
`[rel energy_used]` in memory is correct. The display line that prints
r15 is misleading. Fix in Pod 1.8 (Energy typed primitive) when the
energy display is redesigned. See D1.7.8 in
`recon/POD1.7_DECISION_RECORD.md`.
