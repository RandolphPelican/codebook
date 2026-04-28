# CodebookOS — RECON PROTOCOL
## The Verify-Before-Build Canon

**Project:** CodebookOS x86_64 UEFI
**Author:** Randolph Pelican III / StableTech Enterprises LLC
**Compiled by:** Chauncey (Claude)
**Compiled:** April 27, 2026
**Companion to:** ARCHAEOLOGY.md, RECONSTITUTION.md
**Mandatory for:** Every pod from 0.2.5 forward.

---

## Why this document exists

ARCHAEOLOGY.md was assembled from Claude thread history. It was honest about
its sources — but it was incomplete. The repo carried real work that
ARCHAEOLOGY didn't capture: a `drivers/` directory with native PS/2 keyboard,
IDE PIO, FAT32 driver code, plus an `_future/` cemetery containing exiled
GPU/paging/cap_graph implementations. None of that surfaced to the architect
until Pod 0.2 happened to grep for warnings and saw `drivers/ide_pio.asm`
named in NASM output.

That gap is not a one-time accident. It is the structural consequence of
building canon from one source. There will be more gaps. The remedy is not
"compile a perfect archaeology" — that's impossible — but "verify before
building, every pod, no exceptions."

This document defines the verification protocol that every pod prompt from
0.2.5 forward must include and execute before any source change.

---

## The Two-Phase Pattern

Every pod from now on splits into two phases:

### Phase 1 — RECON

Terminal Boy, the architect, or anyone touching the pod first runs a recon
sweep against the repo. The recon answers:

- What files exist in the scope of this pod?
- What labels/symbols/exports does each file contain?
- What does each file depend on or get depended on by?
- What does git history say about this scope?
- What unexpected files, directories, or commits exist that the pod
  prompt didn't anticipate?

The recon produces a report. The report is read by the architect.

If the report contains anything the prompt didn't predict — a file that
shouldn't exist, a label in the wrong module, history of work that wasn't
in ARCHAEOLOGY, anything surprising at all — the pod halts. The architect
either updates the prompt to reflect ground truth, updates ARCHAEOLOGY
and RECONSTITUTION to capture the new finding, or both.

Phase 1 ends only when the architect says "Phase 2 authorized."

### Phase 2 — BUILD

Only after Phase 1 authorization does any source change happen. Phase 2
follows the original Pod 0 / pod prompt structure: edits, verify, commit,
push.

The recon report from Phase 1 is included in the commit message (or
referenced by file path if it's long). Future pods can read past recon
reports to understand how the repo evolved.

---

## The Recon Sweep — Standard Commands

Every Phase 1 recon runs at minimum these commands. The prompt for any
specific pod may add more; it must not subtract.

### Sweep A — File inventory in scope

```bash
# Replace SCOPE with the directory or file pattern relevant to the pod
find SCOPE -type f \( -name "*.asm" -o -name "*.cbs" -o -name "*.cbc" -o -name "*.md" -o -name "*.sh" -o -name "*.py" \) | sort
```

For Pod 0.x sections, SCOPE is typically `boot/` and `tools/`.
For Pod 1+, SCOPE expands to include `surfaces/`, `drivers/`, and any
other relevant directory.

### Sweep B — Symbol inventory

```bash
# All non-local labels in every .asm file in scope
for f in $(find SCOPE -name "*.asm"); do
  echo "=== $f ==="
  grep -n '^[a-zA-Z_][a-zA-Z0-9_]*:' "$f" | head -50
done
```

This surfaces every function name, every data label, every entry point.
If a symbol shows up in a module the prompt didn't expect, that's a
signal to halt.

### Sweep C — Cross-module dependencies

```bash
# What does each module call that isn't defined locally?
for f in $(find SCOPE -name "*.asm"); do
  echo "=== $f ==="
  # Find call sites and lea/mov references
  grep -nE '\b(call|jmp|lea|mov)\s+\S*\b(auryn|morla|gmork|bastian|cbs|engywook|cop|maid|interpreter|fat32|kbd|ide|gpu)_\w+' "$f" | head -30
done
```

The grep keywords cover the families we know about. If a recon surfaces
calls to a family we don't know about (e.g. `falkor_*` showing up in
module that "shouldn't" reference Falkor), that's halt-worthy.

### Sweep D — Unexpected directories

```bash
# Top-level directories that aren't accounted for in pod scope
ls -la
echo "---"
find . -maxdepth 2 -type d | grep -v -E '^\.($|/\.git|/\.github|/build|/prompts)' | sort
```

If a directory exists that the pod prompt didn't mention — `drivers/`,
`scripts/`, `assets/`, `_future/`, anything — surface it in the report.

### Sweep E — Recent git history in scope

```bash
git log --all --oneline -20 -- SCOPE
echo "---"
git log --all --oneline --diff-filter=D -- SCOPE | head -10
```

The first command shows the 20 most recent commits affecting the scope.
The second shows commits that deleted files in scope — useful for
catching exiled work like the cap_graph removal mentioned in commit
b0fe54d.

### Sweep F — Documentation surface

```bash
ls -la *.md docs/*.md prompts/*.md 2>/dev/null
echo "---"
# Headers of every markdown file in repo root
for f in *.md; do
  echo "=== $f ==="
  head -5 "$f"
  echo
done
```

If documentation exists that wasn't already part of the canon
(ARCHAEOLOGY, RECONSTITUTION, RECON_PROTOCOL, ROADMAP, README), surface
it. Old PHASES.md, TODO.md, NOTES.md files are common hiding spots for
prior architectural intent.

### Sweep G — _future/ and other cemeteries

```bash
find . -type d -name "_future" -o -name "_archive" -o -name "_old" -o -name "_deprecated" 2>/dev/null
echo "---"
# Read top of every file in any cemetery dir
for d in $(find . -type d -name "_future" -o -name "_archive" -o -name "_old" -o -name "_deprecated"); do
  for f in "$d"/*; do
    [ -f "$f" ] || continue
    echo "=== $f ==="
    head -10 "$f"
    echo
  done
done
```

Exiled code is exiled for a reason — but the reason matters. If we're
about to build something new, and exiled code already attempted it, we
read the exiled code first.

---

## The Recon Report — Required Sections

Every Phase 1 recon produces a report with these sections, in this order:

### Section 1 — Sweep findings

For each Sweep (A through G), what was found. Bullet form is fine. Volume
is fine. Honesty is required. If a sweep returned nothing surprising, say
"nothing surprising" — don't omit the section.

### Section 2 — Surprises

A clearly labeled list of every finding the pod prompt did not anticipate.
This is the section the architect reads first. If this section has zero
items, Phase 2 is probably authorizable. If it has items, the architect
addresses each one before authorizing.

For each surprise, three fields: **what**, **where**, **possible
significance**. Example:

> **What:** `drivers/cap_graph.asm` referenced in commit b0fe54d, file
> not present in current tree
> **Where:** Implied by `git log --diff-filter=D` output
> **Possible significance:** Capability graph code was started and then
> exiled. Highly relevant to Pod 1 (typed VM with Cap\<R\>). Architect
> should review the deleted file via `git show b0fe54d:drivers/cap_graph.asm`
> before designing Pod 1's capability type.

### Section 3 — Architect questions

Specific questions where TB needs the architect's input before Phase 2
can proceed. Examples: "Should `drivers/fat32.asm` be considered part of
morla's scope, or is it a separate module?" "Is the `_future/` directory
a dead-letter office or a queue for re-integration?"

If TB has zero questions, that section says "no questions." But the
default is to ask — confidence without verification was the failure
mode that produced this protocol in the first place.

### Section 4 — Proposed Phase 2 plan

What TB intends to do in Phase 2 if authorized. This is the architect's
last chance to redirect before code moves. The proposed plan should be
specific: which files will be created, modified, or read; what symbols
will move; what header text will be written.

---

## Architect Authorization

After reading the recon report, the architect responds with one of four
states:

- **AUTHORIZED** — Phase 2 may proceed as proposed. May include minor
  adjustments ("proceed but use header X instead of header Y").
- **REVISED** — The pod prompt or canon needs updating before Phase 2.
  Architect issues a revised prompt, or updates ARCHAEOLOGY/RECONSTITUTION,
  then re-authorizes.
- **HALTED** — Something in the recon revealed a gap that needs a separate
  investigative pod (a "0.x.5" pod, like the one this document accompanies).
  The current pod is paused until the investigation completes.
- **PAUSED-MID-EXECUTION** — Phase 2 has been authorized and partially
  executed, but the conversation context was exhausted or interrupted
  before completion. This state records what was done, what remains,
  and the exact point of interruption. The next conversation resumes
  Phase 2 from the recorded state — it does not re-run Phase 1 or
  re-request authorization. The architect may issue PAUSED-MID-EXECUTION
  proactively when context limits approach, or TB may request it when
  detecting imminent exhaustion. The pause record includes: (a) which
  X-sections or build steps completed, (b) which remain, (c) any
  intermediate state that the resuming session needs (file hashes,
  partial edits, decisions made during execution). PAUSED-MID-EXECUTION
  is not a failure state — it is the disciplined acknowledgment that
  some pods exceed a single context window.

There is no implicit authorization. Silence is not consent. TB does not
proceed to Phase 2 without an explicit AUTHORIZED response from the
architect.

---

## When the protocol gets boring

The protocol is meant to feel boring most of the time. By the time we're
in Pod 5 or Pod 8, the recon for any given pod will likely surface
nothing surprising — the canon will be increasingly accurate, the repo
will be increasingly understood, and the surprises will be in territory
we haven't built yet.

That is the goal. Boring recon = trustworthy canon. The first few times
this protocol runs, it will catch real surprises (`drivers/`, exiled
`cap_graph`, possibly more we haven't seen). After that, the surprises
taper, and the recon becomes a quick formality.

But it never goes away. Every pod runs it. Even when we're confident we
know everything. Especially then.

---

## Updating canonical documents

If a recon surfaces a finding that should be permanent record:

- **New module discovered** → add to RECONSTITUTION.md's layer mapping
- **Historical work uncovered** (commits, threads, exiled code) → add to
  ARCHAEOLOGY.md as a new thread or section
- **Refactor of how we think about an existing module** → update both

The architect makes these updates as separate commits, not bundled into
the pod's build commit. The pod's recon report references the canon
update commit by hash.

---

## Invocation in pod prompts

Every pod prompt from 0.2.5 forward includes this section near the top:

> ### Phase 1 — Recon (Required Before Phase 2)
>
> Per RECON_PROTOCOL.md, this pod runs in two phases. Phase 1 is the
> recon sweep producing a report. Do not begin Phase 2 (any source
> changes) until the architect responds with AUTHORIZED.
>
> Run sweeps A through G as defined in RECON_PROTOCOL.md, against scope
> [pod-specific scope]. Produce the report with sections 1-4 as defined.
>
> Specific recon additions for this pod:
> [pod-specific commands beyond the standard A-G]

That section is mandatory. No pod prompt is complete without it.

---

## Notes on CBS Spirit

Engywook the gnome did not invent the borders of Fantastica. He observed
them. He kept a notebook because what he had not yet observed was always
larger than what he had. The architect of CodebookOS occupies the same
position. ARCHAEOLOGY captures what has been observed. The repo always
contains more than what has been observed.

The recon protocol is the discipline of looking before naming. The
protocol is small. The discipline it enforces is the difference between
an OS that is honest about what it is and an OS that lies to its
designer.

Every pod knows its blind spot. Every recon names what was found.

---

*StableTech Enterprises LLC — verify before naming.*

— Chauncey
CodebookOS Senior Architect
April 27, 2026
