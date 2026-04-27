# CodebookOS — ARCHAEOLOGY APPENDIX
## The Repo Record

**Compiled:** April 27, 2026
**Compiled by:** Chauncey (Claude)
**Source:** Pod 0.2.5 recon report (commit 7facf2a, recon/POD0.2.5_RECON_REPORT.md)
**Companion to:** ARCHAEOLOGY.md (this is a parallel section, not a replacement)

---

## Why this appendix exists

ARCHAEOLOGY.md was built from Claude thread history alone. It honestly named
its sources but it could only see what was in those threads. Pod 0.2's verify
run surfaced a NASM warning that pointed to `drivers/ide_pio.asm` — and Pod
0.2.5's recon then revealed a parallel development arc that the thread record
never captured.

This appendix is "The Repo Record" as a parallel section to ARCHAEOLOGY.md's
"The Threads." It captures what the git log, git tags, and on-disk file
inventory know that the threads didn't.

---

## The Phase numbering system (predates Pods)

Before Pod numbering came in with the April 27 reconstitution, development
proceeded under a "Phase X.Y" numbering scheme. The phases exist only in
commit messages — there is no PHASES.md, no formal document. They are
nevertheless real and load-bearing. From git log analysis:

| Phase | Title (per commit msg) | What it landed | Approximate era |
|-------|------------------------|----------------|-----------------|
| 1.1   | UEFI Boot              | First successful UEFI handoff, GOP framebuffer, white text | early UEFI era |
| 2.1   | PS/2 Keyboard Driver   | `drivers/kbd_ps2.asm` — `native_keyboard_read`, scancode-to-ASCII | UEFI era |
| 2.3.5 | IDE PIO Driver         | `drivers/ide_pio.asm` — disk I/O via legacy PIO | UEFI era |
| 2.4   | Native FAT32 Write     | FAT32 write support (later exiled in 1c189c9) | UEFI era |
| 3.1   | Framebuffer Ownership Lock | Intel iGPU modeset (later exiled in b0fe54d) | UEFI era |
| 3.2   | Physical Memory Map + Identity Page Tables | `kernel/paging.asm` (later exiled) | UEFI era |
| 5.1   | Capability Graph + Energy Budgeting | `kernel/cap_graph.asm` — CAP_NODE struct, cap_init/grant/use (later exiled) | UEFI era |
| 5.3   | Hardware test           | First boot on real Dell hardware | UEFI era |
| 8.1   | (latest pre-Pod commit) | Repo restructure + cleanup before Pod 0 | March 2026 |

Phases are orthogonal to Pods. Phases were the original implementation
sequence. Pods are the refactoring + organism-build sequence per
RECONSTITUTION.md. Existing code from Phases 1.1, 2.1, 2.3.5 lives in
`drivers/` and is load-bearing in the current build. Code from Phases 2.4,
3.1, 3.2, 5.1 lives in `_future/` directories and is documented as fixable
but currently broken.

## The exile event — commit b0fe54d (March 2026)

`fix(kernel): exile gpu_intel/paging/cap_graph to _future/, stub call sites`

Three files moved out of the active build into `_future/` subdirectories:

- `kernel/paging.asm` → `kernel/_future/paging.asm`
- `kernel/cap_graph.asm` → `kernel/_future/cap_graph.asm`
- `drivers/gpu_intel.asm` → `drivers/_future/gpu_intel.asm`

The exile was deliberate. Each exiled file received a header documenting
"Issues blocking reintegration" and a "Resurrection checklist." This was
not a deletion — it was a parking lot with notes.

**cap_graph.asm (204 lines)** is especially significant for Pod 1. It
defines:

- A `CAP_NODE` struct: parent (4 bytes), child (4 bytes), cap_bitmap (4 bytes),
  energy_budget (8 bytes) = 20 bytes per node
- 64 maximum nodes
- Capability bits: `CAP_READ`, `CAP_WRITE`, `CAP_EXEC`, `CAP_GPU`, `CAP_NETWORK`
- Functions: `cap_init`, `cap_grant`, `cap_use`, `cap_get_node`, `cap_alloc_node`
- Opcodes: `OP_GRANT_CAP_NEW`, `OP_USE_CAP_NEW`

**Documented bugs preventing reintegration:**

- All pointer arithmetic uses 32-bit operations in 64-bit long mode →
  pointers get corrupted on access
- `OP_GRANT_CAP_NEW` and `OP_USE_CAP_NEW` are 32-bit values, but the VM
  reads single-byte opcodes → the new opcodes are unreachable dead code
- Some struct instantiation appears invalid

Pod 1's typed VM design (the `Cap<R>` primitive) reads this file before
designing the new capability layer. The data structure is mostly sound; the
bugs are in the integration. Resurrection-with-fixes is the path, not
greenfield reinvention.

**paging.asm (156 lines)** sets up standard x86_64 4-level identity
page tables. Documented bugs: undefined `memory_allocate` symbol, C-style
call syntax in NASM, missing constants, data declared in code section.
Needs a bump allocator or static page-table pool to function. Will be
required when CodebookOS exits UEFI Boot Services and runs in true
post-EBS mode (Pod 1 or 2 territory).

**gpu_intel.asm (155 lines)** documents NASM-specific issues: assemble-time
shift expressions, immediate port width problems, `section .data` in bin
mode. Lower priority; not required for V1 since UEFI GOP already provides
framebuffer.

## The FAT32 dedup event — commit 1c189c9

`fix(fat32): dedupe read_sector, extract write-half to _future/`

`drivers/fat32_write.asm` (619 lines) was extracted into
`drivers/_future/fat32_write.asm`. The exile was deliberate scope reduction
— V1.0 ships read-only FAT32. Write support has a documented resurrection
checklist and depends on `ide_pio_write_sector` (which exists in active
`ide_pio.asm`) and `fat32_read_sector` (which exists in active
`fat32.asm`). Resurrection is straightforward; it was deferred not blocked.

## Pre-UEFI artifact trail

Several files at repo root predate the UEFI era:

- `codebook_os.asm`, `codebook_os.exe`, `codebook_os.obj` — original x86
  prototype targeting Windows PE format. Defines `_start`, `merge_surfaces`,
  `hash_token`, `check_collision`, `energy_query`. Historical record of the
  earliest concrete CodebookOS code.
- `compiler.py`, `lexer.py`, `parser.py`, `vm.py`, `compile_surface.py` —
  pre-UEFI Python CBS toolchain. Functional but superseded by the
  bare-metal NASM CBS VM at `boot/cbs_vm.asm`.
- `compiler.cbs`, `lexer.cbs`, `parser.cbs`, `hello.cbs` — root-level CBS
  source files from the self-hosted compiler era.
- `cbsc.cb` — compiled bytecode artifact.
- `compile_surface.txt` — empty file, possibly placeholder.

These are tracked in git but not part of the current build. They are
historical record. A future Pod 0.7 may move them to an `_archive/`
directory; for now they remain at root.

## The two historical branches

- `codebook-compiler` — 10 commits of CBS compiler/scheduler work,
  diverged early from main. Primary commits include `[CBS] Add cb_compiler
  surface and scheduler update` and `[CBS] Fix cb_compiler surface and
  scheduler`.
- `phase-1-lexer-parser` — 10 commits of early lexer/parser work, diverged
  early from main.

Both appear fully superseded by main's current state. Pod 0.3 cleanup
verifies via `git log <branch> ^main --oneline` whether any unique work
exists; if zero unique commits, branches are deleted.

## The 25 pre-UEFI tags

Tags `v0.1` through `v4.0` cover the Python/CBS toolchain era. They
document the original development arc:

- v0.x — initial Python implementation
- v1.x — CBS language design and lexer
- v2.x — parser and AST
- v3.x — compiler and bytecode
- v4.x — VM and surface execution

No tags exist for UEFI-era work (Phases 1.1 through 8.1) or Pod 0 work.
The architect may choose to retroactively tag UEFI-era milestones for
consistency, or leave the gap as a marker between "pre-UEFI" and
"current" eras.

## Untracked artifacts at root (Apr 23 dumps)

- `codebook_full_dump.txt` (256 KB) — text dump of repo source
- `codebook_full_history.txt` (652 KB) — text dump of git log
- `codebook/` — entire repo snapshot as a nested directory, including its
  own `boot/`, `drivers/`, `kernel/`, `surfaces/`, `tools/`, plus chunked
  versions of the dump files

Created April 23, 2026 — same day ARCHAEOLOGY.md was compiled. These are
LLM context preparation artifacts: the repo split into chunks small enough
to feed into Claude's context window. They served their purpose. Pod 0.3
cleanup deletes them.

## Reading order

For anyone cold-loading CodebookOS context, the recommended reading order
is:

1. README.md — project introduction
2. RECONSTITUTION.md — current architecture (after Pod 0.4 update)
3. ARCHAEOLOGY.md — Claude thread history of design decisions
4. ARCHAEOLOGY_REPO_RECORD.md (this file) — git/repo history
5. RECON_PROTOCOL.md — verify-before-build discipline
6. ROADMAP.md — current sequence and target dates
7. recon/POD*.md — recon reports from each pod
8. prompts/POD*.md — pod prompts (chronological order)
9. kernel/_future/cap_graph.asm — prior art for Pod 1's typed Cap<R>
10. kernel/_future/paging.asm — prior art for post-EBS execution

Together these documents and code files constitute the canonical record of
what CodebookOS is, how it got here, and where it's going.

---

*StableTech Enterprises LLC — the repo also remembers.*

— Chauncey
CodebookOS Senior Architect
April 27, 2026
