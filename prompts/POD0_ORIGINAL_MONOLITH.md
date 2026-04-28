<!--
STATUS: SUPERSEDED before execution.
SUPERSEDED BY: Sub-pod breakdown (POD0.0 through POD0.8).
REASON: Original monolithic Pod 0 plan was decomposed into sub-pods
after initial planning, before any execution. Preserved as historical
artifact showing pre-decomposition state of the plan. DO NOT EXECUTE.
-->

# CodebookOS — Pod 0 Coder Prompt

## Modularize boot.asm into NASM Includes

**Project:** CodebookOS x86\_64 UEFI  
**Repo:** github.com/RandolphPelican/codebook  
**Author:** Randolph Pelican III / StableTech Enterprises LLC  
**Pod:** 0 of 6 — Foundation Lock  
**Constraint:** Pure NASM. Zero C. Zero dependencies. Every byte is ours.

\---

## Mission

Split `boot/boot.asm` (2996 lines, one monolithic file) into focused NASM include
modules without changing any runtime behavior. The binary output of `build.sh`
must be bit-for-bit equivalent before and after this refactor. This is pure
surgical extraction — no new features, no fixes, no improvements. Those come in
Pod 1. Cut the monolith. Commit it clean.

\---

## What You Are Working With

### Current file structure

```
codebook-main/
├── boot/
│   ├── boot.asm          ← THE MONOLITH (2996 lines, all logic here)
│   ├── atreyu.cbs / .cbc
│   ├── bastian.cbs / .cbc
│   ├── rockbiter.cbs / .cbc
│   ├── demo.cbs / .cbc
│   └── boot.asm
├── build/
│   ├── BOOTX64.EFI
│   └── codebook.img
├── build.sh
├── test\_qemu.sh
├── compiler.py / lexer.py / parser.py / vm.py
└── tools/
    ├── atreyu\_x86.py
    └── compile\_x86.py
```

### What lives where inside boot.asm (line reference)

```
Lines 1–89      Global %define constants (PE layout, UEFI offsets, colors, CBS opcodes)
Lines 92–131    PE32+ header (dos\_header, pe\_sig, opt\_hdr, section table)
Lines 132–369   efi\_entry bootstrap (UEFI init, GOP, ConOut banner, Gmork launch)
                Also: cursor\_home, locate\_sfsp, locate\_gop, fixup\_color helpers
Lines 370–580   auryn\_fill, auryn\_scroll, auryn\_paint, auryn\_putc, auryn\_puts
Lines 581–801   morla\_write\_file, morla\_ls, morla\_run\_file, boot\_bastian,
                morla\_run\_file\_main
Lines 802–1017  String utilities: str\_eq, starts\_with, parse\_hex, print\_dec,
                print\_sdec
Lines 1018–1719 cbs\_run — the entire CBS bytecode VM (\~700 lines)
Lines 1720–1933 bastian\_home, bastian\_main, surface\_table (inline surface logic)
Lines 1934–2304 gmork\_main — terminal command dispatch loop
Lines 2305–2436 get\_mmap, show\_memmap, paint\_bars — system info commands
Lines 2437–2630 All static data: uefi\_data, gop\_ptr, fb\_\*, cursor\_\*, input\_buf,
                string literals, prog\_table, cbs\_demo, font\_data (2877–2977)
Lines 2978–2991 VM runtime data: energy\_budget, energy\_used, vm\_ret\_ptr,
                vm\_ret\_stack, vm\_stack, vm\_vars, mmap\_buf
Lines 2992–2996 reloc\_start (PE32+ .reloc section — must stay at end)
```

\---

## Target File Structure After Pod 0

```
codebook-main/
└── boot/
    ├── boot.asm          ← Thin orchestrator. PE32+ headers + %include chain only.
    ├── defines.asm       ← All %define constants (UEFI offsets, colors, opcodes)
    ├── auryn.asm         ← Framebuffer renderer (auryn\_fill through auryn\_puts)
    ├── gmork.asm         ← Terminal (gmork\_main, command dispatch, string utils)
    ├── morla.asm         ← FAT32 filesystem (morla\_write\_file, morla\_ls, morla\_run\_file)
    ├── cbs\_vm.asm        ← CBS bytecode VM (cbs\_run, all opcode handlers)
    ├── bastian.asm       ← Home surface logic (bastian\_home, bastian\_main, surface\_table)
    ├── data.asm          ← All static data, string literals, font\_data, prog\_table
    └── vmdata.asm        ← VM runtime data (energy\_budget, vm\_stack, vm\_vars, mmap\_buf)
```

\---

## Exact Extraction Map

### boot.asm (after refactor — thin orchestrator only)

Contains:

* File header comment block
* `BITS 64`
* `%include "defines.asm"` ← first, all %defines must be visible to everything
* PE32+ header verbatim (lines 92–131): dos\_header through section table
* `text\_start:` label
* efi\_entry function and its local helpers (cursor\_home, locate\_sfsp, locate\_gop,
fixup\_color) — lines 132–369
* `%include "auryn.asm"`
* `%include "morla.asm"`
* `%include "gmork.asm"`
* `%include "cbs\_vm.asm"`
* `%include "bastian.asm"`
* `%include "data.asm"`
* `%include "vmdata.asm"`
* reloc\_start block (lines 2992–2996) ← must remain physically last in the binary

### defines.asm

Extract lines 1–89 verbatim. Every `%define` in the file. Nothing else.
Start file with:

```nasm
; =============================================================
; CodebookOS — Global Defines
; UEFI offsets, PE layout, colors, CBS VM opcodes
; =============================================================
```

### auryn.asm

Extract lines 370–801 verbatim (auryn\_fill through auryn\_puts).
Start file with:

```nasm
; =============================================================
; Auryn — Framebuffer Renderer
; auryn\_fill, auryn\_scroll, auryn\_paint, auryn\_putc, auryn\_puts
; Depends: fb\_base, fb\_width, fb\_height, fb\_ppsl, cursor\_x,
;          cursor\_y, current\_color, font\_data (in data.asm)
; =============================================================
```

### morla.asm

Extract lines 581–801 verbatim... wait — lines 581–801 overlap with auryn\_puts.
Correct boundary: morla begins at `morla\_write\_file:` (line 581) and ends just
before `auryn\_puts:` (line 802). Extract lines 581–801.
Start file with:

```nasm
; =============================================================
; Morla — FAT32 Filesystem Driver
; morla\_write\_file, morla\_ls, morla\_run\_file, boot\_bastian,
; morla\_run\_file\_main
; Depends: sfsp\_ptr, root\_ptr, file\_ptr, auryn\_puts, cbs\_run
; =============================================================
```

### gmork.asm

Extract lines 1934–2436 verbatim (gmork\_main through paint\_bars).
Also extract string utilities (str\_eq, starts\_with, parse\_hex, print\_dec,
print\_sdec) from lines 816–1017 — these logically belong to the terminal layer.
Start file with:

```nasm
; =============================================================
; Gmork — Terminal \& Command Dispatch
; gmork\_main, get\_mmap, show\_memmap, paint\_bars
; String utils: str\_eq, starts\_with, parse\_hex, print\_dec, print\_sdec
; Depends: auryn\_puts, auryn\_putc, auryn\_fill, morla\_\*, cbs\_run
; =============================================================
```

### cbs\_vm.asm

Extract lines 1018–1719 verbatim (cbs\_run and all opcode handlers).
Start file with:

```nasm
; =============================================================
; CBS VM — CodebookScript Bytecode Interpreter
; cbs\_run: r12=bytecode ptr, r14=energy budget
; Stack: vm\_stack\[\], vars: vm\_vars\[\], energy: energy\_budget
; Opcodes: see defines.asm OP\_\* constants
; =============================================================
```

### bastian.asm

Extract lines 1720–1933 verbatim (bastian\_home, bastian\_main, surface\_table).
Start file with:

```nasm
; =============================================================
; Bastian — Home Surface
; bastian\_home, bastian\_main, surface\_table
; Depends: auryn\_puts, auryn\_fill, morla\_run\_file, gmork\_main
; =============================================================
```

### data.asm

Extract lines 2437–2977 verbatim. All static storage: uefi\_data block, gop\_ptr,
fb\_\* variables, cursor\_*, input\_buf, key\_data, all string literals, hex\_buf,
dec\_buf, mmap\_size, sfsp\_guid, root\_ptr, file\_ptr, file\_info\_buf, gop\_guid,
color\_table, mtypes, all c\_* command strings, str\_prog\_list, prog\_table,
cbs\_demo, atreyu\_cbs\_prog, rockbiter\_cbs\_prog, font\_data.
Start file with:

```nasm
; =============================================================
; Static Data — String literals, tables, font, program buffers
; font\_data: 8x8 bitmap font, 760 bytes (ASCII 0x20–0x7E)
; prog\_table: embedded .cbc program index
; =============================================================
```

### vmdata.asm

Extract lines 2978–2991 verbatim. VM runtime data only:
energy\_budget, energy\_used, vm\_ret\_ptr, vm\_ret\_stack, vm\_stack, vm\_vars,
mmap\_buf and their align directives.
Start file with:

```nasm
; =============================================================
; VM Runtime Data — Stack, variables, energy, memory map buffer
; Kept separate from static data for Pod 1 VM hardening
; =============================================================
```

\---

## Include Order in boot.asm — This Is Load-Bearing

NASM resolves labels at assemble time. The include order determines what is
visible when. Follow this exactly:

```nasm
BITS 64

%include "boot/defines.asm"   ; must be first — all %defines before any code

; === PE32+ Header (inline, not included) ===
dos\_header:
    ; ... verbatim from original lines 92–131 ...

; === UEFI Entry + Bootstrap Helpers (inline) ===
text\_start:
efi\_entry:
    ; ... verbatim from original lines 132–369 ...

%include "boot/auryn.asm"     ; no forward refs to other modules
%include "boot/morla.asm"     ; calls auryn\_puts, cbs\_run — both must be %included before link
%include "boot/gmork.asm"     ; calls auryn\_\*, morla\_\*, cbs\_run, bastian\_home
%include "boot/cbs\_vm.asm"    ; calls auryn\_puts — auryn must precede this
%include "boot/bastian.asm"   ; calls auryn\_\*, morla\_run\_file, gmork\_main
%include "boot/data.asm"      ; static data — no calls, just labels
%include "boot/vmdata.asm"    ; VM runtime data — must precede reloc padding

; === .reloc section padding — MUST be physically last ===
    times TEXT\_RAWSZ - ($ - text\_start) db 0
reloc\_start:
    dd 0, 10
    dw 0
    times RELOC\_RAWSZ - ($ - reloc\_start) db 0
```

**Why efi\_entry stays inline in boot.asm:** It references PE32+ header labels
(dos\_header, pe\_sig) and the `text\_start` padding calculation. Splitting it
would require passing those addresses as externs, which adds complexity for zero
benefit. The bootstrap is the seam — it stays in boot.asm.

\---

## Critical Rules — Do Not Break These

### 1\. No behavior changes

This pod is zero-behavior-change. If you notice a bug while extracting, note it
in a comment with `; TODO Pod1:` and move on. Fix it in Pod 1.

### 2\. The reloc block must remain physically last

The line `times TEXT\_RAWSZ - ($ - text\_start) db 0` pads the .text section to
exactly TEXT\_RAWSZ bytes. It depends on `$` (current position) and `text\_start`
being in the same file context. Keep this in boot.asm after all %includes, not
in any included file.

### 3\. No EXTERN declarations needed

NASM %include is textual inclusion — it's not linking. Every included file
assembles as if its contents were pasted inline. Forward references within the
single assembled unit are fine. Do not add `extern` or `global` declarations
unless they were already there.

### 4\. font\_data must stay in data.asm

`auryn\_putc` references `font\_data` via `lea r8,\[rel font\_data]`. Since data.asm
is included after auryn.asm, this is a forward reference — which NASM handles
fine in two-pass assembly. Do not move font\_data into auryn.asm.

### 5\. VM data must be in vmdata.asm, not cbs\_vm.asm

Pod 1 will harden the VM. Keeping runtime data (vm\_stack, vm\_vars, energy\_budget)
in a separate file means Pod 1 can extend vmdata.asm without touching the opcode
handlers in cbs\_vm.asm. This separation is intentional.

### 6\. Do not change build.sh

build.sh assembles `boot/boot.asm` with `nasm -f bin`. Since %include paths are
relative to the source file, `%include "boot/defines.asm"` will resolve correctly
when nasm is invoked from the project root. Verify this before committing.

\---

## Verification Protocol

After extraction, before committing:

### Step 1 — Build succeeds

```bash
./build.sh
# Must exit 0. Must produce build/BOOTX64.EFI and build/codebook.img.
# Check file size of BOOTX64.EFI — should match pre-refactor size exactly.
```

### Step 2 — Binary equivalence check

```bash
# Before refactor, save reference binary:
cp build/BOOTX64.EFI build/BOOTX64\_reference.EFI

# After refactor:
./build.sh
diff build/BOOTX64.EFI build/BOOTX64\_reference.EFI
# Must produce zero output. Zero. Any diff means something moved.
```

### Step 3 — QEMU boot test

```bash
./test\_qemu.sh
# Must:
# - Display gold-on-black framebuffer
# - Show Bastian home surface
# - Accept keyboard input in Gmork
# - Respond to: help, about, clear, colors, fb, mem
```

### Step 4 — Grep sanity check

```bash
# No orphaned defines — everything in defines.asm should be used somewhere
grep -h "%define" boot/defines.asm | awk '{print $2}' | while read d; do
  grep -r "$d" boot/ --include="\*.asm" | grep -v defines.asm | grep -q . || echo "ORPHANED: $d"
done

# No stray code in data.asm
grep -n "^\[a-z\_]\*:" boot/data.asm | grep -v "str\_\\|c\_\\|gop\_\\|fb\_\\|sfsp\\|mmap\\|color\\|prog\\|cbs\_\\|atreyu\\|rockbiter\\|font\\|mtypes\\|uefi\\|cursor\\|input\\|ascii\\|hex\\|dec\\|temp\\|key\\|event\\|bastian\\|external\\|file\\|root\\|atreyu\_size"
# Should return nothing — data.asm is data only
```

\---

## Commit Convention

Two commits, in order:

**Commit 1:**

```
git add boot/defines.asm boot/auryn.asm boot/morla.asm boot/gmork.asm \\
        boot/cbs\_vm.asm boot/bastian.asm boot/data.asm boot/vmdata.asm
git commit -m "pod0: extract modules from boot.asm monolith

defines.asm   — global constants
auryn.asm     — framebuffer renderer
morla.asm     — FAT32 filesystem
gmork.asm     — terminal + string utils
cbs\_vm.asm    — CBS bytecode VM
bastian.asm   — home surface
data.asm      — static data + font
vmdata.asm    — VM runtime data"
```

**Commit 2 (after binary equivalence confirmed):**

```
git add boot/boot.asm
git commit -m "pod0: boot.asm becomes thin orchestrator with %include chain

Binary output verified bit-for-bit equivalent to pre-refactor.
QEMU boot test passes. Pod 1 can now target individual modules."
```

\---

## Notes on CBS Spirit

This is CodebookOS. The naming convention is Neverending Story mythology and
it is not negotiable. The modules you are creating are:

* **Auryn** — the power amulet, renders reality (framebuffer)
* **Gmork** — the wolf of the Nothing, guards the terminal gate
* **Morla** — the ancient one who knows where things are stored (filesystem)
* **Bastian** — the boy who speaks the name, the home surface
* The VM has no mythological name yet — that comes in Pod 1

Do not rename anything. Do not refactor anything. Do not improve anything.
Extract. Verify. Commit. The Neverending Story continues in Pod 1.

\---

*StableTech Enterprises LLC — Atreyu named it.*
