# Pod 1.9.4 Decision Record — Throwaway test script removal

**Pod:** 1.9.4 — housekeeping pod (throwaway QEMU test script removal)
**Author:** Terminal Boy (Claude Opus 4.7)
**Date:** May 03 2026
**Entry contract:** 3bfb0c0a2410e90c9aa9d5def1c598ec26d6c058d68c73cf67cb2da5e737fff6 (Pod 1.9.3 BOOTX64.EFI; preserved through 1.9.4)
**Exit contract:** 3bfb0c0a2410e90c9aa9d5def1c598ec26d6c058d68c73cf67cb2da5e737fff6 (preserved; no source change)
**Entry HEAD:** e1c06e759868dee91c353fbe25fd20893cdb3fb4 (Pod 1.9.3 seal)

---

## D1.9.4.1 — Removal over merge

The throwaway script bundle reached five files spanning four source
pods (1.8.5b, 1.8.5c × 2, 1.9.2b, 1.9.3). The original DEFERRED
entries (#33, #34, #48, #52) offered two disposition options:
- **Merge** into `test_qemu.sh` as a parameterized fresh-boot harness
  earning permanent `tools/test/` status
- **Remove** the throwaway scripts entirely

Architect ratified removal as the fastest path. Rationale: each script
served its pod's B-item testing and is now dead weight. The
value-of-keeping (potential reuse for future test harness work) is
lower than the cost-of-keeping (repo clutter, maintenance ambiguity,
five subtly-different copies of the same fresh-boot pattern). Future
pods needing QEMU test harnesses write what they need at that point.

**Pod 1.9.4 takes no position on the merge-into-test_qemu.sh option;
the option is closed by removal.** If a future pod writes a QEMU test
harness, that pod owns the disposition decision (parameterize from
scratch vs. inline as needed for its specific tests).

**R2 finding made the removal even more mechanical than drafted:** all
five scripts were untracked working-tree-only carryover. None had ever
been committed. `git ls-files` returned empty for all five paths.
Removal collapsed to 5 × `Remove-Item` with no `git rm` needed; no
git history affected. The scripts simply disappear from the working
tree.

## D1.9.4.2 — Canon hygiene scope discipline

Pod 1.9.4 was originally scoped to bundle three housekeeping items:
1. Throwaway script removal (DEFERRED #33, #34, #48, #52)
2. RECONSTITUTION pod-arc reconciliation (DEFERRED #37 — Pod 1.5.5
   hash verification, Pod 1.8 hash placeholder, missing 1.8.x sub-pod
   rows, Cap allocation drift)
3. v4 main body commit (DEFERRED #24 — architect-direct verbatim paste
   to commit `recon/CHAUNCEY_HANDOFF_v4.md` as sibling to the
   committed addendum)

Architect narrowed scope to script removal only, on the principle
that **canon hygiene serves the OS rather than the OS serving canon**.
RECONSTITUTION drift items (#24, #37) stay open without blocking
Pod 1.10 (Cap) work. The pod-arc table being out of date is a
documentation lag; the actual substrate is correct, binary contracts
are accurate, and the decision-record-and-commit-history chain
preserves the authoritative record of what happened in each pod.

The narrowing is the right shape because:
- #24 v4 main body requires architect-direct verbatim paste — TB
  cannot synthesize without introducing drift
- #37 pod-arc reconciliation requires careful audit of git history
  against pod-arc claims (Pod 1.5.5 hash `b560a6c` verification;
  Pod 1.8 hash backfill; sub-pod row additions for 1.8.5–1.9.4;
  Cap allocation reconciliation) — non-trivial work that benefits
  from its own pod with its own recon and ratification cycle

Pod 1.10 (Cap) does not depend on RECONSTITUTION accuracy or v4
main body presence. Both can land later in a dedicated documentation
pod when architect prioritizes.

---

## Summary

| Decision | Resolution |
|----------|-----------|
| D1.9.4.1 | Remove over merge — fastest path; future pods own their own harness disposition |
| D1.9.4.2 | Canon hygiene scope discipline — script removal only this pod; #24 and #37 stay open |

DEFERRED #33, #34, #48, #52 RESOLVED. #24 and #37 STAY OPEN.

— Terminal Boy
May 03 2026
