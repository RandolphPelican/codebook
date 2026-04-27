# CodebookOS — Pod 0.0 Coder Prompt

## Reference Lock — Canonical Docs + Verification Substrate

**Project:** CodebookOS x86_64 UEFI
**Repo:** github.com/RandolphPelican/codebook
**Author:** Randolph Pelican III / StableTech Enterprises LLC
**Pod:** 0.0 of 10.9 — Foundation Lock, Section 0
**Constraint:** Zero source-file edits. Capture and commit only.
**Prerequisite:** `boot/boot.asm` is the monolith. `build.sh` exists and runs clean.

---

## Mission

Before any source line moves, the foundation must hold the weight ahead.
This section commits the architectural canon to the repo, captures the
immutable reference binary that every downstream Pod 0 section diffs
against, and creates the verification script that automates exit-gate
checks.

**Zero source code is refactored in this section.** Pod 0.1 starts that.
0.0 is the scaffold.

---

## What You Produce

Three artifacts. One commit.

### A. Canonical documents at repo root

The architect provides two files (already in the working sandbox or
pulled from the architect's drop):

- `ARCHAEOLOGY.md` — thread audit of CodebookOS history through April 23, 2026
- `RECONSTITUTION.md` — architecture manifesto after the April 27 pivot

These live at repo root, next to `README.md`. They are committed
**verbatim**. Do not edit them — not even typos. They are canonical
record. If something needs correcting, that's a separate commit by the
architect, not Terminal Boy.

### B. Reference binary

From the project root:

```bash
./build.sh
cp build/BOOTX64.EFI build/BOOTX64_reference.EFI
```

This is the pre-Pod-0 monolithic build. It is immutable. Every Pod 0
section from 0.1 through 0.9 must produce a binary that is bit-for-bit
identical to this reference.

Yes — a binary file in git. ~66KB. This is the one intentional exception
to the "git is for source" rule, because the binary *is* the contract.
Every diff against it is a verification that no runtime behavior changed
during the refactor. The reference is the truth that proves we didn't
lie.

Document the exception by updating `.gitignore` so the build directory
stays ignored *except* for the reference binary:

```
# build/ is normally ignored, EXCEPT the reference binary which is the
# Pod 0 exit-gate contract. Do NOT delete BOOTX64_reference.EFI.
build/*
!build/BOOTX64_reference.EFI
```

### C. Verification script

Create `tools/verify_binary.sh` with the following contents:

```bash
#!/usr/bin/env bash
# tools/verify_binary.sh
# Pod 0 exit-gate check: build current source, diff against reference.
# Exits 0 on bit-for-bit match, 1 on any difference, 2 on missing reference.

set -e

if [ ! -f build/BOOTX64_reference.EFI ]; then
    echo "ERROR: build/BOOTX64_reference.EFI not found"
    echo "       Run Pod 0.0 to capture the reference, or pull it from git"
    exit 2
fi

./build.sh > /dev/null

if cmp -s build/BOOTX64.EFI build/BOOTX64_reference.EFI; then
    echo "OK: binary matches reference"
    exit 0
else
    REF_SIZE=$(wc -c < build/BOOTX64_reference.EFI)
    NEW_SIZE=$(wc -c < build/BOOTX64.EFI)
    echo "MISMATCH: build/BOOTX64.EFI differs from reference"
    echo "  reference: $REF_SIZE bytes"
    echo "  current:   $NEW_SIZE bytes"
    echo
    echo "First differing byte:"
    cmp build/BOOTX64.EFI build/BOOTX64_reference.EFI || true
    exit 1
fi
```

Make it executable:

```bash
chmod +x tools/verify_binary.sh
```

---

## Critical Rules — Do Not Break These

### 1. No source edits

Don't touch `boot/boot.asm`. Don't touch any `.asm` file. Don't touch
`build.sh`. The whole point of capturing the reference binary is to lock
in *current* behavior. Any source edit before the capture invalidates
the lock.

### 2. The reference binary is committed despite being a binary

This is intentional. The `.gitignore` exception is the contract. If a
future contributor `git rm`s `BOOTX64_reference.EFI`, they have broken
the Pod 0 exit gate — recovering it requires checking out the original
monolithic boot.asm and re-capturing, which is friction we don't want.
Leave it in. Document why in the `.gitignore` comment.

### 3. Manifesto and archaeology are committed verbatim

If `ARCHAEOLOGY.md` says "Compiled: April 23, 2026" — that line stays.
If `RECONSTITUTION.md` has any wording the architect later wants to
revise, that's a separate commit, not part of 0.0. Verbatim means
verbatim.

### 4. The verify script exits 0 on success, silently

This matters for downstream automation and for keeping Terminal Boy's
output clean across many sections. On success: print `OK: binary matches
reference` and exit 0. Don't print stats, don't print byte counts, don't
print anything else when the binary matches. On failure: be loud and
specific, because failure is where humans need information.

### 5. The script handles "reference missing" with exit code 2

Distinguishing "reference missing" (exit 2) from "binary mismatch" (exit
1) lets future CI scripts treat them differently. Missing reference is a
setup problem; mismatch is a real failure. Don't conflate them.

---

## Verification Protocol

After this section, run these checks in order. Every one must pass.

### Check 1 — Canonical docs in place

```bash
ls -la ARCHAEOLOGY.md RECONSTITUTION.md
```

Both files visible at repo root, both readable, both non-empty.

### Check 2 — Reference binary captured

```bash
ls -la build/BOOTX64_reference.EFI
```

File exists, ~66KB.

### Check 3 — Binaries match (sanity, since we just copied)

```bash
cmp build/BOOTX64.EFI build/BOOTX64_reference.EFI && echo "match" || echo "MISMATCH"
```

Must print `match`.

### Check 4 — Verify script works

```bash
./tools/verify_binary.sh
```

Must print `OK: binary matches reference` and exit with status 0.

### Check 5 — Verify script catches a mismatch (negative test)

```bash
# Sanity test: corrupt a copy, verify the script detects it
cp build/BOOTX64.EFI /tmp/safe_copy.EFI
echo "tampered" >> build/BOOTX64.EFI
./tools/verify_binary.sh
# Must exit 1 with MISMATCH output
echo "Exit code was: $?"

# Restore
cp /tmp/safe_copy.EFI build/BOOTX64.EFI
rm /tmp/safe_copy.EFI

# Re-verify
./tools/verify_binary.sh
# Must exit 0 again
```

The negative test is critical. A verification script that always returns
OK is worse than no script — it's a false sense of security. Confirm it
fails when it should.

### Check 6 — Git status clean before commit

```bash
git status
```

Must show only the new files: `ARCHAEOLOGY.md`, `RECONSTITUTION.md`,
`build/BOOTX64_reference.EFI`, `tools/verify_binary.sh`, modified
`.gitignore`. No other changes — confirming Critical Rule 1 was honored.

---

## Commit Convention

One commit:

```bash
git add ARCHAEOLOGY.md \
        RECONSTITUTION.md \
        build/BOOTX64_reference.EFI \
        tools/verify_binary.sh \
        .gitignore

git commit -m "pod0.0: foundation lock — canonical docs + reference binary

ARCHAEOLOGY.md     — thread audit of CodebookOS history through Apr 23
RECONSTITUTION.md  — architecture manifesto after the Apr 27 pivot
build/BOOTX64_reference.EFI — pre-Pod-0 monolithic build, immutable
tools/verify_binary.sh — diffs current build against reference
.gitignore — preserves reference binary while ignoring rest of build/

The reference binary is the contract. Every Pod 0 section through 0.9
must produce a build/BOOTX64.EFI that is bit-for-bit identical to
build/BOOTX64_reference.EFI. tools/verify_binary.sh enforces this.

Pod 0.1 begins extraction of %defines into boot/defines.asm against
this lock."
```

Push when verification passes:

```bash
git push origin main
```

---

## Notes on CBS Spirit

This section has no mythological role yet. It is the cornerstone — the
stone laid before any other stone. The Neverending Story does not begin
with Atreyu setting out; it begins with Bastian climbing into an attic
with a stolen book. This section is the attic. The story comes after.

What this section commits is honesty: a binary we promise not to break,
and the script that holds us to the promise. Foundation that holds
weight is foundation that does not lie about its weight.

---

## What's Next — Pod 0.1 Preview

Pod 0.1 extracts the first module: `boot/defines.asm`. All `%define`
constants from lines 1–89 of the monolith move to a new file, included
first in `boot.asm` before any code references the constants. The binary
must remain identical (defines are pure assembler constants with no
runtime impact). `tools/verify_binary.sh` is the gate.

When 0.0 lands clean — verify script reports OK on the fresh-pushed
repo, both negative and positive tests pass — the architect feeds Pod
0.1.

---

*StableTech Enterprises LLC — foundation holds weight.*

— Chauncey
CodebookOS Senior Architect
April 27, 2026
