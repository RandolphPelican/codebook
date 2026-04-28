# Pod 1.0 — prompts/ Backfill Recon Report

**Date:** 2026-04-27
**Pod:** 1.0 (first sub-pod of Pod 1)
**Resolves:** DEFERRED.md #8
**Phase:** 1 (recon — halting for AUTHORIZED)

---

## P1 — Existing prompts verification

Two files already present in `prompts/`:

| File | sha256 | Status |
|------|--------|--------|
| POD0.0_REFERENCE_LOCK.md | `be68552a35577d075a3eb3adfc7c2ddd316fecb867e5f26b544b2eaf86580317` | Unchanged from committed state |
| POD0.3_CLEANUP.md | `505b915cd9283b7c6cfa0e0e2cb949d5ef1ce8dd6d6f169309b26d8e8092aea1` | Unchanged from committed state |

Both verified against git — no local modifications.

---

## P2 — Downloads folder inventory

**Path:** `C:\Users\Rando\.ssh\Downloads`

### Target backfill files — search results

| Target filename | Found at no-suffix? | Suffixed copies? | Status |
|-----------------|---------------------|-------------------|--------|
| POD0.1_DEFINES_EXTRACT.md | **NO** | None | Must reconstruct |
| POD0.2_AURYN_EXTRACT.md | **NO** | None | Must reconstruct |
| POD0.2.5_RECON_PASS.md | **NO** | None | Must reconstruct |
| POD0.3_MORLA_EXTRACT.md | **NO** | None | Must reconstruct |
| POD0.5_HEADER_POLISH.md | **NO** | None | Must reconstruct |
| POD0.6_DRIVERS_DATA.md | **NO** | None | Must reconstruct |
| POD0.7_AURYN_PUTS_CONSOLIDATION.md | **NO** | None | Must reconstruct |
| POD0.8_FOUNDATION_SIGNOFF.md | **NO** | None | Must reconstruct |

**None of the 8 target backfill files exist in Downloads under any name
or suffix.**

### Related files found in Downloads (not target backfill)

- `CODEBOOK_POD0_PROMPT.md` — the original all-in-one Pod 0 monolith
  extraction prompt (pre-sub-pod breakdown). Describes the full
  modularization plan before it was decomposed into 0.0–0.8. Not a
  per-sub-pod prompt.
- `CODEBOOK_TB_BRIEFING.md` — a TB briefing document from March 2026,
  pre-Pod-0 era. Not a pod prompt.
- `POD0.0_REFERENCE_LOCK.md` + (1), (2) suffixes — already in repo.
- `POD0.3_CLEANUP.md` + (1) suffix — already in repo.
- `POD0.9_CAP_GRAPH_DEEP_READ.md` + (1) suffix — this is the recon
  memo, not a prompt. Already committed to `recon/`.

### Conclusion

All 8 target backfill files require **reconstruction** from commit
history, recon reports, and conversation context. None were ever
downloaded as standalone files from the chat sessions — the prompts
were delivered conversationally and not exported as artifacts.

---

## P3 — Cross-reference: commits vs. prompts

Each sub-pod's commits and the work they describe, for reconstruction:

| Sub-pod | Commit(s) | Work performed |
|---------|-----------|----------------|
| 0.1 | `4f02dcd` | Extract `%define` constants from boot.asm into boot/defines.asm |
| 0.2 | `4489d01` | Extract auryn framebuffer renderer into boot/auryn.asm, header polish |
| 0.2.5 | `f1b223a`, `7facf2a` | RECON_PROTOCOL.md creation + repo-wide archaeology pass |
| 0.3 (MORLA, retired) | Never executed | Original morla extraction plan, superseded by cleanup |
| 0.5 | `9f86040` | Header polish across 5 boot/ modules (gmork, gmork_cmds, cbs_vm, bastian, vmdata) |
| 0.6 | `fbb8ba3`, `e6d41b3` | drivers/ header polish + _future/ standardization + data.asm section markers |
| 0.7 | `4ff12d8` | auryn_puts consolidation from morla.asm to auryn.asm (binary-changing) |
| 0.8 | `d68167c` | Doc-vs-code reconciliation + DEFERRED.md creation + pod0-complete tag |

All commits are consistent with the work described in their messages.

---

## P4 — POD0.3 MORLA vs. POD0.3 CLEANUP distinction

These are clearly distinguishable:
- **POD0.3_MORLA_EXTRACT.md** (to be reconstructed): Would have described
  extracting morla code from boot.asm. This plan was **retired before
  execution** when Pod 0.2.5's recon revealed morla extractions were
  already complete from prior sessions.
- **POD0.3_CLEANUP.md** (already in repo): Describes repo cleanup work —
  deleting cruft (`codebook/` directory), pruning branches, hardening
  `.gitignore`. Different scope entirely.

No confusion risk. Different filenames and completely different work.

---

## P5 — DEFERRED.md item #8

Item #8 reads as expected: "prompts/ directory backfill" describing the
exact gap this pod resolves. No other DEFERRED item references prompts/
backfill. No risk of double-resolving.

---

## P6 — RECON_PROTOCOL.md consistency

This prompt's two-phase structure (Phase 1 recon with halt, Phase 2
execution after AUTHORIZED) is consistent with RECON_PROTOCOL.md's
standard form. The sweeps are pod-specific (P1–P6 instead of standard
A–G) which is permitted — the protocol requires sweeps, not a fixed
sweep naming scheme.

---

## Cross-reference concern: DEFERRED item renumbering

RECONSTITUTION.md v3 references "DEFERRED.md item 9" (line 72) and
"DEFERRED #9" (line 197). If item #8 is removed and items renumbered,
these references break. Per the prompt's instruction: **do not renumber
— leave the gap and add a note explaining the gap policy.**

---

## Surprises

1. **All 8 backfill targets require reconstruction.** None were ever
   saved as downloads. The assumption that prompts were "downloaded to
   John's local Downloads folder" was incorrect — they were delivered
   in-conversation only.

2. **CODEBOOK_POD0_PROMPT.md exists** — the original all-in-one Pod 0
   prompt before sub-pod breakdown. This is a historical artifact worth
   preserving in `prompts/` as additional context, but it's not one of
   the 8 target files.

---

## Proposed Phase 2 plan

Since all 8 files require reconstruction:

1. Reconstruct all 8 prompts from commit history, conversation context,
   and the summary at the top of this conversation. Each gets the
   explicit `SOURCE: reconstructed` header per Part B.
2. POD0.3_MORLA_EXTRACT.md gets both the `SOURCE: reconstructed` header
   AND the `STATUS: RETIRED` header per Part C.
3. Create prompts/README.md per Part D.
4. Remove DEFERRED.md item #8 per Part E, preserving the numbering gap
   (items 9-10 keep their numbers due to RECONSTITUTION cross-refs).
5. Also copy CODEBOOK_POD0_PROMPT.md from Downloads to prompts/ as
   bonus context — **only if architect approves** (not in the original
   target inventory).
6. Single atomic commit per Part F.

---

**Awaiting AUTHORIZED / REVISED / HALTED.**
