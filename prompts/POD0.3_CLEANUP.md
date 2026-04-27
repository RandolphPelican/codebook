# CodebookOS — Pod 0.3 Coder Prompt

## Repo Cleanup — Cruft Removal + Branch Hygiene

**Project:** CodebookOS x86_64 UEFI
**Repo:** github.com/RandolphPelican/codebook
**Author:** Randolph Pelican III / StableTech Enterprises LLC
**Pod:** 0.3 of 10.9 — Foundation Lock, Section 3 (revised post-recon)
**Constraint:** Binary must remain bit-for-bit identical to `build/BOOTX64_reference.EFI`. Tracked source files must not change.
**Prerequisite:** Pod 0.2.5 committed (7facf2a). Recon report at `recon/POD0.2.5_RECON_REPORT.md`. Architect canon updates committed (RECONSTITUTION v2 + ARCHAEOLOGY_REPO_RECORD.md, see commit history).

---

## Why this pod exists

Pod 0.2.5's recon surfaced cruft from the April 23 LLM-prep session:
the nested `codebook/` directory (entire repo snapshot), the
`codebook_full_dump.txt` and `codebook_full_history.txt` files (text
dumps for context window stuffing). All untracked, all takes-up-space,
all serves no purpose now that the recon has captured the actual
repo state in proper canonical documents.

Recon also confirmed two historical branches (`codebook-compiler` and
`phase-1-lexer-parser`) appear superseded by main. This pod verifies
that and deletes them if confirmed.

This is a hygiene pod. No source code changes. No binary changes. The
goal is a clean working tree that no future session mistakes for the
real source.

---

## Phase 1 — Recon (Required Before Phase 2)

Per RECON_PROTOCOL.md, this pod runs in two phases. Phase 1 produces a
report and waits for AUTHORIZED before any change.

The standard recon sweeps from RECON_PROTOCOL.md mostly already ran in
Pod 0.2.5 — that's the value of having the recon protocol. The
pod-specific additions for this pod focus on the cleanup targets:

### Sweep K — Confirm cruft is still untracked

```bash
git status --short
```

Verify that `codebook/`, `codebook_full_dump.txt`, and
`codebook_full_history.txt` still appear in the untracked list (they
should — they were untracked in Pod 0.2.5 and nothing has been added
since). If any of them have somehow become tracked, halt and report.

### Sweep L — Verify branches have no unique work

For each historical branch, list commits that exist on it but not on
main:

```bash
echo "=== codebook-compiler ==="
git log codebook-compiler ^main --oneline 2>&1
echo "=== phase-1-lexer-parser ==="
git log phase-1-lexer-parser ^main --oneline 2>&1
```

Expected output: empty for both branches (zero unique commits). If
either branch has unique commits, list them and halt — the architect
decides whether they need cherry-picking before deletion.

### Sweep M — Confirm gitignore patterns

```bash
cat .gitignore
```

Report current contents. Phase 2 will add patterns for the dump files;
need to know what's already there.

### Sweep N — File size sanity

```bash
du -sh codebook/ codebook_full_dump.txt codebook_full_history.txt 2>/dev/null
```

Report sizes. Just confirms scope of cleanup.

### Recon report format

Submit findings in the standard format from RECON_PROTOCOL.md (sections
1-4). Section 4 (proposed Phase 2 plan) should explicitly list:

- Whether `codebook/` is safe to delete (yes if Sweep K confirms still
  untracked)
- Whether the `codebook_full_*.txt` files are safe to delete
- Whether `codebook-compiler` and `phase-1-lexer-parser` branches are
  safe to delete (yes if Sweep L returns empty for both)
- The exact `.gitignore` patterns to add

Wait for AUTHORIZED before Phase 2.

---

## Phase 2 — Cleanup Actions (after AUTHORIZED)

### A. Delete the nested clone and dump files

```bash
rm -rf codebook/
rm -f codebook_full_dump.txt codebook_full_history.txt
```

These are untracked, so this only affects the working tree. Git doesn't
care — the repo doesn't track them.

### B. Update .gitignore

Add these patterns to `.gitignore` (preserving any existing content):

```
# LLM context preparation artifacts (Apr 23, 2026 era)
# These are text dumps of repo source/history for feeding into context windows.
# Don't commit them — the actual repo and git log are the canonical record.
codebook_full_dump.txt
codebook_full_history.txt
codebook_full_*.txt
codebook_chunk_*

# Nested clones / snapshots — never commit these
/codebook/
```

The leading `/` in `/codebook/` matters: it anchors to repo root only,
so it doesn't accidentally ignore some legitimate `codebook/` directory
deeper in the tree (unlikely to exist, but safe to be explicit).

### C. Delete defunct branches (if Sweep L confirmed empty)

```bash
git branch -D codebook-compiler 2>&1 || echo "branch already gone"
git branch -D phase-1-lexer-parser 2>&1 || echo "branch already gone"
git push origin --delete codebook-compiler 2>&1 || echo "remote branch already gone"
git push origin --delete phase-1-lexer-parser 2>&1 || echo "remote branch already gone"
```

If the Phase 1 sweep showed unique commits on either branch, do NOT
delete that branch. Wait for architect guidance.

---

## Critical Rules — Do Not Break These

### 1. Binary equivalence is the contract

`tools/verify_binary.sh` must print `OK: binary matches reference` after
your changes. This pod doesn't touch source files, so this should be
trivial — but verify anyway.

### 2. No tracked source files change

`git diff --stat` after Phase 2 should show only `.gitignore` modified
and (depending on git version) maybe a deletion confirmation for the
removed files (which were untracked, so probably nothing). It should
NOT show changes to anything in `boot/`, `drivers/`, `kernel/`,
`surfaces/`, or `tools/`.

### 3. Branch deletion is irreversible from the local perspective

Once `git branch -D` runs and `git push --delete` runs, the branch tip
is no longer reachable from any ref. The commits themselves still exist
in the reflog for ~30 days but recovery is annoying. Only delete
branches that the recon confirmed have zero unique commits relative to
main.

### 4. Don't delete .git or any tracked files

The deletions in Phase 2 are specific: `codebook/` (untracked nested
dir), `codebook_full_dump.txt` (untracked), `codebook_full_history.txt`
(untracked). Nothing else. Especially nothing inside `.git/`.

### 5. Untracked is not the same as forgotten

The dump files served their purpose — they were the source material for
the original ARCHAEOLOGY.md compilation. We don't need them anymore
because the canon now contains what they revealed. Deleting them is
moving from "stuff hanging around" to "just the work." That's the goal.

---

## Verification Protocol

### Check 1 — Binary equivalence

```bash
./tools/verify_binary.sh
```

Must print `OK: binary matches reference`.

### Check 2 — Cruft is gone

```bash
ls codebook/ 2>&1 | head -5
ls codebook_full_dump.txt 2>&1
ls codebook_full_history.txt 2>&1
```

All three should report "No such file or directory."

### Check 3 — git status is clean

```bash
git status
```

Should show only `.gitignore` as modified. No untracked files (the
dump files and codebook/ are gone). Deletion of files that were never
tracked doesn't appear in git status.

### Check 4 — Branches deleted (if applicable)

```bash
git branch -a
```

Should show only `main` and remote tracking branches for main. The
`codebook-compiler` and `phase-1-lexer-parser` branches should not
appear locally or as `remotes/origin/...`.

### Check 5 — .gitignore patterns active

```bash
# Create a fake dump to verify the pattern catches it
touch codebook_full_test.txt
git status | grep codebook_full_test
# Should be EMPTY — file is ignored
rm codebook_full_test.txt
```

If the test file shows up in `git status`, the gitignore pattern isn't
matching. Adjust the pattern.

---

## Commit Convention

One commit:

```bash
git add .gitignore
git commit -m "pod0.3: repo cleanup — remove Apr 23 LLM-prep artifacts

Removed (untracked):
- codebook/                       (nested repo snapshot, ~1MB)
- codebook_full_dump.txt          (256 KB text dump of repo source)
- codebook_full_history.txt       (652 KB text dump of git log)

Added .gitignore patterns to prevent recreation:
- codebook_full_dump.txt, codebook_full_*.txt, codebook_chunk_*
- /codebook/

Deleted defunct branches (verified zero unique commits vs main):
- codebook-compiler
- phase-1-lexer-parser

The recon report at recon/POD0.2.5_RECON_REPORT.md is the canonical
record of what these artifacts contained. The repo and git history
contain the same information without the redundancy.

Binary verified bit-for-bit equivalent to build/BOOTX64_reference.EFI.
The Pod 0.0 contract holds.

Pod 0.4 is architect-side canon updates (RECONSTITUTION v2 +
ARCHAEOLOGY_REPO_RECORD.md). Pod 0.5 polishes remaining boot/ module
headers."
git push origin main
```

---

## What's Next — Pod 0.4 and Beyond

**Pod 0.4 has no TB component.** It is architect-side canon update
commits: pushing the v2 RECONSTITUTION.md and the new
ARCHAEOLOGY_REPO_RECORD.md to the repo. The architect handles this
directly without writing a TB prompt for it.

**Pod 0.5** polishes the remaining `boot/` module headers (gmork,
gmork_cmds, cbs_vm, bastian, vmdata) to the same spec as
auryn/morla/defines. Mostly comment edits, no binary impact.

**Pod 0.6** standardizes `drivers/` headers (kbd_ps2, ide_pio, fat32)
and the `_future/` resurrection checklists. Comment-only.

**Pod 0.7** is the only Pod 0 binary-changing pod: consolidating
`auryn_puts` from `morla.asm` back into `auryn.asm`. Verify carefully.

**Pod 0.8** is final Pod 0 sign-off: another full recon, confirm
everything is consistent, prepare Pod 1 entry.

**Pod 0.9** is the prep for Pod 1: the architect deeply reads
`kernel/_future/cap_graph.asm` and drafts the typed `Cap<R>` design
incorporating its salvageable parts.

---

## Notes on CBS Spirit

A house cannot be built where rubble has not been cleared. Atreyu didn't
fight the Nothing in the Swamps of Sadness — he had to leave the swamps
first. This pod is leaving the swamps. The codebook/ snapshot was
useful; it served its purpose; it is no longer useful; it goes. Same
for the dump files. Same for the branches. The clean working tree is
the launching pad for Pod 1.

Engywook keeps a tidy notebook because a messy notebook lies about what
it knows.

---

*StableTech Enterprises LLC — clear the rubble, sharpen the focus.*

— Chauncey
CodebookOS Senior Architect
April 27, 2026
