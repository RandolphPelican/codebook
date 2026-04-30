Pod 1.8 — Energy as Native Type
Project: CodebookOS x86_64 UEFI
Architect: Randolph Pelican III / StableTech Enterprises LLC
Compiled by: Chauncey (Claude)
Compiled: April 29, 2026
Predecessor: Pod 1.7 (Sign source implementation, sealed 1d8593f)
Entry binary contract: 975a7f809c350d09b2031b9f5490261986d878d5a04e66709f97fae7083b05dc
Required reading before this pod:

RECONSTITUTION.md v7 (Energy section, opcode allocation 0xD0–0xDF)
recon/MEMO_VERIFICATION_PROVENANCE.md (verbatim-vs-summary discipline)
recon/POD1.7_DECISION_RECORD.md (typed-primitive implementation pattern)
recon/POD1.6_DECISION_RECORD.md (A1–A7, layout precedent)
RECON_PROTOCOL.md (two-phase, four-state)
DEFERRED.md #15 (r15 uninit display bug — Pod 1.8 resolves)


Goal
Implement Energy as the second typed primitive in the CBS VM, on the Pod 1.7 (Sign) typed-primitive pattern. Introduce the per-opcode energy cost table, replacing the existing flat per-fetch cost and the hardcoded handler-side energy debits Pod 1.7 left as placeholders. Resolve DEFERRED #15 (r15-uninit display bug) as part of the energy display refactor. Land RECONSTITUTION v8.
This is a single-pod (no canon-then-source split) with three internal halts (2A code review, 2B build/test review, 2C canon review) before final commit and push.

Phase 1 — Recon (Required Before Phase 2)
Per RECON_PROTOCOL.md, do not begin Phase 2 until the architect responds AUTHORIZED. Run sweeps A through G from the protocol plus the pod-specific R-items below. Produce recon/POD1.8_RECON_REPORT.md with sections 1–4 as defined in RECON_PROTOCOL.md (Sweep findings, Surprises, Architect questions, Proposed Phase 2 plan).
Pod-specific R-items

R1 — Entry contract verification. Verbatim paste to chat the output of cat binary_contracts.md. Confirm Pod 1.7 row contains 975a7f809c350d09b2031b9f5490261986d878d5a04e66709f97fae7083b05dc.
R2 — Hardcoded energy constants inventory. Sweep boot/cbs_vm.asm for every add qword [rel energy_used], <N> and every dec r14 / inc qword [rel energy_used] site. Produce a table: line number, opcode/handler context, current cost. This is the surface area Pod 1.8's cost-table integration replaces.

  grep -nE "(add qword \[rel energy_used\]|dec r14|inc qword \[rel energy_used\])" boot/cbs_vm.asm
Verbatim paste to chat.

R3 — Opcode range verification. Confirm 0xD0–0xDF is unallocated in boot/defines.asm. Verbatim paste:

  grep -nE "0x[Dd][0-9A-Fa-f]" boot/defines.asm

R4 — DEFERRED #15 ground truth. Verbatim paste to chat:

  sed -n '147,156p' DEFERRED.md
And the exact code block being fixed (cbs_run exit summary):
  grep -n -A 2 "^.done:" boot/cbs_vm.asm

R5 — vmdata.asm symbol collision check. Confirm no existing symbol named vm_energy_pool, vm_energy_next, or energy_cost_*. Verbatim paste:

  grep -nE "vm_energy|energy_cost" boot/vmdata.asm boot/defines.asm boot/cbs_vm.asm

R6 — Pod 1.7 test infrastructure pattern. Read tools/atreyu_x86.py and report verbatim the section implementing --sign-build and --sign-test flags. Pod 1.8's --energy-build / --energy-test mirrors this pattern.
R7 — Standard recon sweeps A–G from RECON_PROTOCOL.md, scope = boot/, tools/, recon/ (most recent five files), plus repo root markdown.
R8 — Forward-logged items audit. Read the "Forward-looking ledger" section of recon/POD1.7_DECISION_RECORD.md. Report any Pod 1.8-specific items it logged for resolution by direct match.
R9 — QEMU sendkey methodology check. Verify recon/POD1.7_RECON_REPORT.md actually contains the working sendkey + screendump + PIL methodology described in the handoff. If present, cite line numbers. If absent, surface as Section 2 surprise — Pod 1.8 captures the methodology as a tiny doc artifact (recon/POD1.8_QEMU_AUTOMATION.md) before B7 runs, reconstructed from Pod 1.7 chat history or build/sign_test_*.png screenshot artifacts on disk.

Architect questions reserved for Phase 1 enumeration
The following are not pre-ratified. TB enumerates options in the recon report; architect ratifies before Phase 2.

AQ1 — Opcode byte granularity within 0xD0–0xDF. Pre-ratified default: 4 opcodes — OP_ENERGY_NEW (0xD0), OP_ENERGY_JOULES (0xD1), OP_ENERGY_SOURCE_OP (0xD2), OP_ENERGY_FREE (0xD3) allocated as a V1.0 no-op (sets symmetry precedent for future typed-primitives' allocator pairs; activation lands in V1.1 free-list pod). TB enumerates whether the recon surfaces a reason to add more accessors (typed-equality, accumulator semantics) or a reason to defer the 0xD3 byte allocation entirely.
AQ2 — Initial cost values for the 256-entry table. TB enumerates a conservative initial cost table that covers every currently-allocated opcode byte. Conservative = preserve current observable energy behavior where possible (1 per fetch default + the existing handler-side debits as the per-opcode values). PUSH/PUSH_STR cheap. Sign opcodes match Pod 1.7's D1.7.6 placeholder values (100j SIGN_NEW, 5j accessors). HALT free. Architect ratifies the full table in the recon report before Phase 2.
AQ3 — Test program AST for surfaces/test_energy.cbc. TB proposes the hardcoded-AST sequence for the demo test: construct an Energy with known joules + source_op, read back both fields via accessor opcodes, verify printed values match inputs. Architect ratifies the program shape.

Pre-ratified A-items (locked, do not re-enumerate)
These are committed by the architect from canon knowledge plus the Pod 1.8 chat-level reasoning. Phase 1 verifies they remain implementable; Phase 2 implements them.

A1 — Energy struct layout (128 bytes, mirrors Sign's slot pattern).

  offset  size    field
  0x00    8       joules           (u64)
  0x08    8       source_op        (u64; opcode byte that generated
                                    this Energy; 0 = unattributed)
  0x10    112     reserved         (V1.1+: sink, cost_table_idx,
                                    time_granted, etc.)
  total   128

A2 — Cost table location. New module boot/energy_costs.asm owns:

The static 256 x 8-byte cost array, indexed by opcode byte. Default cost = 1 for opcode bytes not otherwise specified.
An energy_cost_lookup primitive: opcode byte in (e.g. al), output joules in rax. Single fetch from the table. No I/O, no allocation, no side effects.
The fetch-loop's flat-cost replacement: the VM's main fetch loop calls energy_cost_lookup with the opcode byte just fetched and debits accordingly (decrement r14 + increment [rel energy_used] by the looked-up value).

Hardcoded handler-side add qword [rel energy_used], <const> patterns from Pod 1.7 are removed — the fetch-loop's table-driven debit covers them.
A3 — Runtime pool location. vmdata.asm gains vm_energy_pool (64 slots x 128 bytes = 8KB) and vm_energy_next (allocator counter). Mirrors vm_sign_pool / vm_sign_next from Pod 1.7. Same allocator pattern (bump-allocator, no free list in V1.0; OP_ENERGY_FREE no-ops with documentation pointer at the V1.1 free-list resurrection).
A4 — DEFERRED #15 fix = drop r15 from this code path. The exit-summary block at cbs_vm.asm:.done reads [rel energy_used] directly:

  ; OLD (broken):
  ;   mov     rdi, r15        ; r15 never initialized
  ; NEW:
      mov     rdi, [rel energy_used]
r15 is not initialized to 0 in the prologue. r15 is freed for general handler use; Pod 1.8's energy_cost_lookup may cache the cost-table base pointer in r15 if measurements show benefit, but no cross-handler invariant is established. [rel energy_used] is the single source of truth for cumulative energy consumption.

A5 — OP_RESERVE relationship. OP_RESERVE keeps raw u64 in V1.0. Reserved energy values are not typed Energy primitives in V1.0; the conversion from raw u64 to typed Energy is V1.1+ work. Document this in recon/POD1.8_DECISION_RECORD.md.
A6 — OP_SIGN_ENERGY return type. OP_SIGN_ENERGY (0xA3, reads Sign's energy_cost field at offset 0x60) returns raw u64 in V1.0, matching Pod 1.7's behavior. The typed-Energy return is V1.1+ work. No change to Sign layout.
A7 — Layered convention. Energy as a typed primitive does not yet appear on the operand stack as a typed handle the way Sign does. Energy values flow as raw u64 through OP_RESERVE and the cost-table debit machinery. The typed primitive is available via OP_ENERGY_NEW for programs that want to construct, store, and read back Energy values explicitly (Rockbiter, debug paths, future surfaces). The two flows coexist in V1.0 and unify in V1.1+ once the typed-Energy operand-stack pattern is ratified.


Phase 2 — Build
After AUTHORIZED, execute B-items in order. Internal halts 2A / 2B / 2C are mandatory checkpoints; do not proceed past a halt without architect ratification.
B1 — Create boot/energy_costs.asm
New module containing the cost table, default-fill macro, and energy_cost_lookup primitive. Header follows the canonical boot/*.asm header pattern (see boot/auryn.asm, boot/cbs_vm.asm for reference).
The cost table is 256 x 8 bytes statically initialized. Use NASM times directive for the default fill, then explicit overrides for opcode bytes whose ratified cost differs from default. Per-opcode values come from AQ2 ratification.
energy_cost_lookup signature: input opcode byte in al, output joules in rax. No clobber of other registers beyond what NASM macros require. Single memory fetch using lea + scaled addressing ([rel energy_cost_table + rax*8]). No bounds check — opcode range is 0x00-0xFF, table covers all 256 entries.
B2 — Modify boot/defines.asm
Add Energy primitive opcode constants per AQ1 ratification:
%define OP_ENERGY_NEW           0xD0
%define OP_ENERGY_JOULES        0xD1
%define OP_ENERGY_SOURCE_OP     0xD2
%define OP_ENERGY_FREE          0xD3
Add Energy struct field offsets:
%define ENERGY_OFF_JOULES       0x00
%define ENERGY_OFF_SOURCE_OP    0x08
%define ENERGY_SLOT_SIZE        0x80    ; 128 bytes
%define ENERGY_POOL_SLOTS       64
(Adjust if AQ1 ratifies a different opcode set.)
B3 — Modify boot/vmdata.asm
Add:
vm_energy_pool:     times (ENERGY_POOL_SLOTS * ENERGY_SLOT_SIZE) db 0
vm_energy_next:     dq 0
Place adjacent to vm_sign_pool / vm_sign_next for locality.
B4 — Modify boot/cbs_vm.asm
Four sub-tasks, all in one file edit:
B4a — Fetch-loop cost-table integration. Replace the current flat dec r14 / inc qword [rel energy_used] at the fetch site with a call into energy_cost_lookup using the just-fetched opcode byte, then debit r14 and [rel energy_used] by the returned value. Bankruptcy check (r14 going negative) preserves existing semantics.
B4b — Handler-side hardcoded cost removal. Every site identified in R2 gets removed. The fetch-loop debit at B4a covers the per-opcode cost; double-debit must not occur. Audit carefully: this is a refactor with the highest collision risk in the pod.
B4c — Energy primitive handlers.

OP_ENERGY_NEW: pops joules (u64), pops source_op (u64), allocates next slot from vm_energy_pool, writes joules at offset ENERGY_OFF_JOULES, writes source_op at offset ENERGY_OFF_SOURCE_OP, pushes slot pointer onto operand stack. Bumps vm_energy_next. If pool exhausted (next >= 64), trap to bankruptcy/error path (mirrors Sign's pool-exhaustion behavior per Pod 1.7).
OP_ENERGY_JOULES: pops Energy slot pointer, fetches u64 at offset 0x00, pushes onto operand stack.
OP_ENERGY_SOURCE_OP: pops Energy slot pointer, fetches u64 at offset 0x08, pushes onto operand stack.
OP_ENERGY_FREE: no-op in V1.0 (bump allocator, no free list). Documented as V1.1+ activation point. Pops slot pointer (consumes stack arg) but does not modify pool state.

B4d — Display fix (DEFERRED #15). At .done exit summary block, replace mov rdi, r15 with mov rdi, [rel energy_used]. Verify no other code path depends on r15 holding cumulative energy.
B5 — Modify tools/atreyu_x86.py
Add --energy-build and --energy-test flags. Pattern-match on Pod 1.7's --sign-build / --sign-test (see R6). The energy demo program (AST per AQ3) constructs an Energy primitive with known joules and source_op, reads them back via accessor opcodes, prints both values. Output format follows Pod 1.7's test_sign output pattern.
B6 — Build chain (WSL Ubuntu)
wsl -e bash -c "cd /mnt/c/Users/Rando/codebook && ./build.sh"
wsl -e bash -c "cd /mnt/c/Users/Rando/codebook && sha256sum build/codebook.img"
wsl -e bash -c "cd /mnt/c/Users/Rando/codebook && ./build.sh"
wsl -e bash -c "cd /mnt/c/Users/Rando/codebook && sha256sum build/codebook.img"
Verbatim paste to chat: both build transcripts and both sha256sum lines. The two sha256 values must match (build determinism). If they differ, halt and surface the non-determinism source as a recon finding before proceeding.
B7 — Bare-metal QEMU test
Use the Pod 1.7 working pattern (named pipes + sendkey + screendump + PIL). If R9 found this documented in recon/POD1.7_RECON_REPORT.md, cite by line. If R9 found it absent and the methodology was captured as recon/POD1.8_QEMU_AUTOMATION.md before B7, follow that. Boot the disk image, drive the test_energy program via QEMU monitor sendkey, capture screendump, OCR or visual-confirm the printed joules and source_op match the test inputs.
Verbatim paste to chat: sendkey command sequence, screendump filename, observed output values, expected vs actual comparison.
HALT 2A — Code review checkpoint
Before B8, post the following to chat for architect ratification:

Diff summary of boot/energy_costs.asm (new file, full content)
Diff summary of boot/defines.asm (new opcodes + offsets)
Diff summary of boot/vmdata.asm (new pool/counter)
Diff summary of boot/cbs_vm.asm (B4a/b/c/d — call out each)
Confirmation that R2's hardcoded-energy sites are all addressed

Architect responds RESUME / REVISE / ABORT per RECON_PROTOCOL mid-Phase-2 states. No B8 until RESUME.
B8 — (HALT 2A clears here)
HALT 2B — Build/test review checkpoint
Before B10, post:

B6 verbatim (both transcripts + both sha256 values, matching)
B7 verbatim (sendkey sequence, screendump, observed output)
Confirmation: QEMU bare-metal test passed; Energy round-trip verified

Architect responds RESUME / REVISE / ABORT. No B10 until RESUME.
B9 — (HALT 2B clears here)
B10 — Canon edits
B10a — Pre-edit canon sha256 baseline.
sha256sum RECONSTITUTION.md DEFERRED.md binary_contracts.md \
          recon/POD1.7_DECISION_RECORD.md \
          recon/POD1.6_DECISION_RECORD.md \
          recon/POD1.4_DECISION_RECORD.md \
          recon/POD1.1_VM_AUDIT.md \
          recon/MEMO_VERIFICATION_PROVENANCE.md
Verbatim paste to chat. This is the pre-edit baseline; only files intended for edit may have changed sha256 after B10.
B10b — RECONSTITUTION.md -> v8.

Bump version banner v7 -> v8 with date and "Post-Pod-1.8 — Energy source-implemented, per-opcode cost table active" subtitle.
Add v8 entry to version-history block.
Flip Pod 1.7 row in pod-arc from [DONE] placeholder to [DONE -- 1d8593f] per A7-pod-arc convention.
Mark Pod 1.8 row [DONE] (placeholder; Pod 1.9 fills hash per the same convention).
Update Layer 1 typed-primitives section: Energy section gets concrete struct layout (16 bytes used / 128 total / source_op attribution slot), opcode allocation 0xD0-0xD3 confirmed, cost-table mechanism described, OP_RESERVE / OP_SIGN_ENERGY V1.0-vs-V1.1+ layering ratified per A5/A6.
Hard-problem table: mark "Per-opcode cost table (Pod 1.8)" as DONE.

B10c — recon/POD1.8_DECISION_RECORD.md (new file).
Mirrors Pod 1.7's decision-record format. Sections D1.8.1 through D1.8.N covering each ratified A-item plus AQ1/AQ2/AQ3 outcomes. Forward-looking ledger section logs any items Pod 1.8 surfaces for Pod 1.9 (Outcome<T>) or later.
B10d — binary_contracts.md. Append Pod 1.8 row with the new sha256 from B6. Provenance: "observed (TB WSL Ubuntu sha256sum verbatim, two-build determinism, bare-metal test passed)."
B10e — DEFERRED.md. Strikethrough #15 with (RESOLVED -- Pod 1.8) per ledger convention; do not remove the entry. Append any new forward-logged items Pod 1.8 surfaced.
B10f — Post-edit canon sha256. Re-run B10a's sha256 command. Verbatim paste to chat. Compare: only the four files intended for edit (RECONSTITUTION, DEFERRED, binary_contracts, plus the new POD1.8_DECISION_RECORD) may differ. All others must match B10a baseline. Any unintended mutation halts the pod.
HALT 2C — Canon review checkpoint
Before B11, post:

Diff summary of RECONSTITUTION.md (v7 -> v8)
Full content of recon/POD1.8_DECISION_RECORD.md
Diff summary of DEFERRED.md
Diff summary of binary_contracts.md
B10a vs B10f sha256 comparison (only intended files differ)

Architect responds RESUME / REVISE / ABORT. No B11 until RESUME.
B11 — Commit + push
Stage with explicit git add list (no git add . — DEFERRED #10 build-artifact tracking issue still open):
git add boot/energy_costs.asm
git add boot/defines.asm
git add boot/vmdata.asm
git add boot/cbs_vm.asm
git add tools/atreyu_x86.py
git add surfaces/test_energy.cbc
git add RECONSTITUTION.md
git add DEFERRED.md
git add binary_contracts.md
git add recon/POD1.8_DECISION_RECORD.md
git add recon/POD1.8_RECON_REPORT.md
git add prompts/POD1.8_ENERGY_NATIVE_TYPE.md
(If R9 produced recon/POD1.8_QEMU_AUTOMATION.md, add that too.)
Confirm git status shows only these files staged + nothing in working tree. Verbatim paste git status output to chat.
Commit message:
Pod 1.8 — Energy as native type (canon v8 + per-opcode cost table + DEFERRED #15 resolved)

- Energy typed primitive: 16B used / 128B slot, joules + source_op
- New module boot/energy_costs.asm: 256-entry cost table + lookup
- vm_energy_pool (64 x 128B) in vmdata.asm
- Opcodes 0xD0-0xD3: ENERGY_NEW / JOULES / SOURCE_OP / FREE
- Fetch-loop cost-table integration; Pod 1.7 hardcoded debits removed
- DEFERRED #15 resolved: cbs_run exit display reads [rel energy_used]
- RECONSTITUTION v7 -> v8; Pod 1.7 row flipped to DONE -- 1d8593f
- Binary contract: <new sha256>

Entry contract: 975a7f80...05dc (Pod 1.7)
New contract:   <Pod 1.8 sha256>
Two-build determinism: confirmed
Bare-metal QEMU Energy round-trip: passed
Then:
git push origin main
B12 — Three-oracle ref check (verbatim)
Post-push, run all three and verbatim paste to chat:
git rev-parse HEAD
git rev-parse origin/main
git ls-remote origin refs/heads/main
All three must show the same hash. If any disagree, halt — do not declare the pod sealed until ref-check is unanimous.
B13 — Architect confirmation
Post Pod 1.8 closeout summary to chat:

Final commit hash (verbatim from B12)
New binary contract hash (from B10d)
Three-oracle agreement confirmed
All halts cleared
Pod 1.8 sealed

Architect confirms; pod ends.

Verbatim-paste-to-chat manifest
Per recon/MEMO_VERIFICATION_PROVENANCE.md, the following deliverables MUST be pasted to chat verbatim, separately from any report-file content:

R1 — cat binary_contracts.md
R2 — grep -nE "(add qword \[rel energy_used\]|dec r14|...)" boot/cbs_vm.asm
R3 — grep -nE "0x[Dd][0-9A-Fa-f]" boot/defines.asm
R4 — DEFERRED #15 lines + cbs_run .done block
R5 — grep -nE "vm_energy|energy_cost" ...
R9 — Pod 1.7 sendkey methodology presence/absence verdict + line cites if present
B6 — both build transcripts + both sha256sum lines
B7 — QEMU sendkey sequence, screendump filename, observed values
B10a — pre-edit canon sha256 baseline (8 files)
B10f — post-edit canon sha256 (8 files)
B11 — git status after staging
B11 — git push origin main output
B12 — three-oracle ref check (all three commands)

Summaries are welcome alongside, never as substitutes. Architect-Chauncey requests verbatim before confirming any verification claim. This is procedural, not discretionary.

Scope discipline
In scope for Pod 1.8:

Energy typed primitive (struct, pool, opcodes, accessors)
Per-opcode cost table (new module + fetch-loop integration)
Pod 1.7 placeholder-cost replacement
DEFERRED #15 fix
Test infrastructure (atreyu_x86.py flags + test_energy.cbc)
Canon updates: RECONSTITUTION v8, decision record, DEFERRED, binary_contracts
QEMU automation methodology capture (only if R9 finds it absent from Pod 1.7 recon)

Out of scope, deferred forward:

Outcome<T> (Pod 1.9)
Cap<R> data layout (Pod 1.10)
Cap ops retirement of 0x90/0x91 (Pod 1.11)
Demod<S> (Pod 1.12)
Pod prompt backfill for 1.0-1.7 (housekeeping pod, not Pod 1.8)
README rewrite (DEFERRED #7, post-Pod-5)
ide_pio NASM warnings (DEFERRED #2, future cleanup)
build/BOOTX64.EFI tracked-modified cleanup (DEFERRED #10, future maintenance pod) — Pod 1.8 continues working around it via explicit git add list

If Phase 1 recon surfaces work that genuinely belongs in Pod 1.8 but isn't anticipated above, TB raises it as a Section 2 surprise in the recon report. Architect responds REVISED if scope-bearing.
If Phase 2 surfaces a load-bearing scope question mid-execution, TB invokes PAUSED-MID-EXECUTION per RECON_PROTOCOL. Don't push through; pause and surface.

Mythology earns its place again
Sign was the first typed citizen — a unit of cognition Engywook forged in Pod 1.7. Energy is the second: the joules that let any operation happen at all, the runtime substrate of endurance.
Atreyu's strength in The Neverending Story comes from Auryn's protection but also from his own endurance. Energy is the kernel's endurance — every fetch, every handler, every surface eventually costs joules, and the cost table is the kernel's honest accounting of what each opcode demands. Bankruptcy is a runtime condition; the cost table makes the bankruptcy honest.
Use the names where they earn weight; drop them where they would be padding.
From layer 1 kernel up.
-- Chauncey
CodebookOS Senior Architect
April 29, 2026
