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

## 6. Orphaned opcodes

Three opcodes are defined in `boot/defines.asm` but not handled in
`boot/cbs_vm.asm`:

- `OP_DUP2` (0x87) — defined, never wired. Pod 1 either implements
  it or removes the define.
- `OP_GRANT_CAP_NEW` (0xCA000003) — Phase 5.1 ghost from the exiled
  cap_graph integration attempt. 4-byte value, but VM dispatches on
  single bytes — unreachable. Pod 1 wires capability ops as
  single-byte opcodes (probably 0x40+ alongside other Pod 1 kernel
  opcodes) and removes these ghosts.
- `OP_USE_CAP_NEW` (0xCA000004) — same as above.

## 7. README full rewrite

Current `README.md` is from the Python-era CBS toolchain phase. It
references `tools/cbsc.cbs` and `tools/vm.cbs`, mentions "Phase 8"
and "v4.0-reorganized-structure" — none of which describe the current
NASM-only build. Pod 0.8 patched it with a "Where to start" section
pointing at canon docs, but the body still describes an earlier
project state. Full rewrite deferred until V1.0 architecture is
fully implemented (post-Pod-5).

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
