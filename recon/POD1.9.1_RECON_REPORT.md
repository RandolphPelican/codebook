# Pod 1.9.1 Recon Report — Outcome Canon and Design

**Pod:** 1.9.1 — recon-only canon pod (Outcome<T> design seal + RECONSTITUTION v9 patch)
**Author:** Terminal Boy (Claude Opus 4.7)
**Date:** May 03 2026
**Entry contract:** 03d2642998f41c4ce2080267b41033a78bdafafb96aded360396338f30fe8199 (Pod 1.8.5c BOOTX64.EFI; preserved through 1.9.1 — canon-only pod)
**Entry HEAD:** f5dccaf3f57f216a212391e9a4901f02197d0fcc (Pod 1.8.5c seal)
**Scope:** RECONSTITUTION.md, DEFERRED.md, binary_contracts.md, recon/POD1.9.1_*.md (new). No source touched.

---

## R1 — Pre-flight three-oracle

| Source | Hash | Match |
|--------|------|-------|
| `git rev-parse HEAD` | f5dccaf3f57f216a212391e9a4901f02197d0fcc | ✓ |
| `git rev-parse origin/main` | f5dccaf3f57f216a212391e9a4901f02197d0fcc | ✓ |
| `git ls-remote origin refs/heads/main` | f5dccaf3f57f216a212391e9a4901f02197d0fcc | ✓ |

Three-oracle agrees. Build artifacts (DEFERRED #10) and three throwaway scripts (DEFERRED #33-#34) untracked per protocol.

## R2 — Opcode space audit at 0xE0–0xE4 (+ adjacent)

`grep` for `0xE[0-9A-F]|OP_OUTCOME` across `boot/`:
- `energy_costs.asm:127` — comment block reserves entire row 0xE0-0xEF to "Demod 0xE0-0xEF Pod 1.12"
- No `%define` for any 0xE0-prefixed opcode in `boot/defines.asm`
- No dispatch entry (`cmp al, OP_*`) for any 0xE0-prefixed opcode in `boot/cbs_vm.asm`
- Other 0xE-prefix hits unrelated (BS_EXITBOOTSERV UEFI vector, font bitmap bytes, PE flag)

**0xE0–0xE4 fully unallocated.** No conflicts.

**Conflict-with-comment surfacing:** `energy_costs.asm:127` will need updating at Pod 1.9.2 source-pod time to reflect Pod 1.9 claiming 0xE0-0xE4 from the Demod-reserved row (Demod retains 0xE5-0xEF). 0xE5-0xEF stays available for future Outcome opcodes if needed (`OP_OUTCOME_MAP`, `OP_OUTCOME_AND_THEN`, etc.).

## R3 — Slot layout pre-plan (TB confirms architect's sketch)

Architect's layout sketch is internally consistent and fits the 128-byte symmetric slot exactly. Confirming verbatim:

```
+0x00  discriminant       u64   (0=ok, 1=err)
+0x08  value_type_id      u64   (canonical-ID type code per Pod 1.8.5b)
+0x10  value              u64   (canonical ID of success value if ok; unused if err)
+0x18  reserved           u64   (Pod 3+ handle pool extension)
+0x20  err_code           u64   (D2; unused if ok)
+0x28  err_source_op      u64   (D2; unused if ok)
+0x30  err_demod_id       u64   (D2; unused if ok)
+0x38  err_fetch_counter  u64   (D2; unused if ok)
+0x40  reserved           u64   (Pod 3+ error message handle extension)
+0x48  reserved           u64
+0x50  reserved           u64
+0x58  reserved           u64
+0x60  reserved           u64
+0x68  reserved           u64
+0x70  arena_id           u64   (Move 3 inheritance; Pod 1.10 Cap activates)
+0x78  owner_demod_id     u64   (Move 3 inheritance; Pod 1.12 Demod activates)
```

**Footprint check:**
- Header (D1 tagging): 32 bytes at +0x00–+0x1F (4 qwords)
- Inline error context (D5): 32 bytes at +0x20–+0x3F (4 qwords)
- Pod 3+ reserved: 48 bytes at +0x40–+0x6F (6 qwords)
- Move 3 inheritance: 16 bytes at +0x70–+0x7F (2 qwords)
- Total: 128 bytes ✓ (matches `OUTCOME_SLOT_SIZE = 0x80`)

No collision between architect's data sections and Move 3 fields. **No A-call needed on layout — confirmed as sketched.**

## R4 — Pool sizing pre-plan

Recommended:
- `OUTCOME_POOL_SLOTS = 64` (matches Sign and Energy precedent)
- `OUTCOME_SLOT_SIZE = 0x80` (128 bytes; matches Sign and Energy precedent)
- `vm_outcome_pool: times OUTCOME_POOL_SLOTS * OUTCOME_SLOT_SIZE db 0` (8KB pool)
- `vm_outcome_next: dq 0` (bump allocator index, Pod 1.7/1.8 pattern)
- Registry table: `outcome_registry_count`, `outcome_registry_next_id`, `outcome_registry: times OUTCOME_POOL_SLOTS * 16 db 0` (~1KB; Pod 1.8.5b precedent)

**Confirmed as-sized; no A-call.**

## R5 — Canonical ID type addition

Recommend `OUTCOME_ID_NULL equ 0` added to `boot/defines.asm` ID null-sentinel block alongside existing `SIGN_ID_NULL`, `ENERGY_ID_NULL`, `CAP_ID_NULL`, `DEMOD_ID_NULL`, `SIGNAL_ID_NULL`. Type code (the value placed in `value_type_id` per D1 to indicate "this Outcome wraps another Outcome") would be a separate concern — `value_type_id` is a discriminant naming the wrapped-T type. For Outcome wrapping Outcome (Outcome<Outcome<sign_id>>?), we'd need a code system. **This is an A-call (A3 below).**

## R6 — prov_append calling convention (verbatim from boot/provenance.asm:20-27)

```
;   Input:    rdi = opcode (low byte; high bits ignored)
;             rsi = demod_id
;             rdx = fetch_counter
;   Output:   none
;   Clobbers: rax, rcx
;   Preserves: r12, r13, r14, r15, rbx, rbp, rdi, rsi, rdx
```

- Cap-gate is **internal** to prov_append (checks `[rel current_demod_prov_enabled]`, jumps to .prov_append_done if 0). Caller does **not** check the gate; just calls prov_append unconditionally.
- All three input registers preserved by callee — caller can rely on rdi/rsi/rdx values surviving the call.

**Substrate gap surfaced:** No `fetch_counter` storage exists anywhere in the substrate today. No `vm_fetch_count` in vmdata.asm; no increment in the .fetch loop in cbs_vm.asm. The prov_append signature documents the parameter, but no caller has needed to source it yet (V1.0 has no automatic prov_append invocation). **D6's wire-up needs a source for fetch_counter.** Surfacing as A4 below.

Two related design questions arise from D6 wire-up:
- What `opcode` value does OP_OUTCOME_NEW_ERR pass? The construction opcode (0xE1) or the user-supplied `err_source_op`?
- What `demod_id` does it pass? The user-supplied `err_demod_id` (from the error context) or a "current demod" value (which doesn't exist beyond the singleton placeholder)?

Bundling all three sub-questions into A4.

## R7 — DEFERRED #13 and #16 verbatim

### #13 verbatim

> ## 13. Stack-error mechanism design (revised Pod 1.4)
>
> Pod 1.9 (Outcome<T>) must define the specific representation for
> stack-violation errors: error codes, stack-frame tagging, how a
> typed `Err(StackOverflow)` or `Err(StackUnderflow)` sits on the VM
> stack alongside normal values. The principle is decided (Q8: stack
> violations are typed Outcome results, not fatal traps), but the
> encoding is deferred to Pod 1.9's recon phase. Pod 1.3's interim
> implementation halts with diagnostic messages (`str_ret_underflow`,
> `str_call_overflow`); Pod 1.9 replaces these with typed results.

**Closure path:** Pod 1.9.1 design (this pod) defines D3 two-mode handlers and the inline error context shape — the architectural decision. Pod 1.9.2 source implementation lands the actual Outcome slot and the OP_OUTCOME_NEW_ERR / OP_OUTCOME_NEW_OK opcodes. Pod 1.9.3 then refits the existing stack-violation halt sites (`str_ret_underflow`, `str_call_overflow`) to push typed `Err(StackOverflow)` / `Err(StackUnderflow)` Outcomes instead of halting. **#13 closes when 1.9.3 commits.**

### #16 verbatim

> ## 16. Outcome error path for invalid canonical-ID lookups (added Pod 1.8.5b)
>
> `registry_lookup_sign` and `registry_lookup_energy` return `0` when an
> ID is not found (id == 0 or no matching entry). Current Sign/Energy
> accessor handlers fall through to existing null-paths that push 0/null
> on the operand stack — no typed `Outcome::Err` representation. Pod 1.9
> (Outcome) formalizes the error type and accessor handlers should be
> retrofitted to push `Err(InvalidId)` instead of silent null. Same
> pattern will apply to `cap_id`, `demod_id`, `signal_id` registry
> lookups when those primitives land.

**Closure path:** Pod 1.9.1 (this pod) defines the Err shape (D2 standard error context). Pod 1.9.3 source pod refits the existing accessor null-handlers to construct `Err(InvalidId)` Outcomes via OP_OUTCOME_NEW_ERR and push the resulting outcome_id. **#16 closes when 1.9.3 commits.**

Pod 1.9.1 forward-logs both as "in-flight" via two new DEFERRED entries (S3) but does not mark either resolved.

## R8 — RECONSTITUTION current version + insertion-point audit

**Current version:** v8 (post-Pod-1.8). Last update April 29, 2026.

**Outcome occurrences in current RECONSTITUTION:**

| Line | Content | Status under v9 |
|------|---------|-----------------|
| 100 | "stack bounds produce `Outcome<T>` errors" | Stays (Q8 reference) |
| **323** | **`\| `0xC0–0xCF` \| Outcome<T> \| 1.9 \|` opcode allocation** | **MUST CHANGE** — D4 places Outcome at 0xE0-0xE4 |
| **325** | **`\| `0xE0–0xEF` \| Demod<S> \| 1.12 \|`** | **MUST CHANGE** — Demod loses 0xE0-0xE4 to Outcome; gets 0xE5-0xEF |
| 332 | example opcode name `OP_OUTCOME_OK` | Stays (illustrative) |
| 338 | typed primitives list mentions Outcome<T> Pod 1.9 | Stays |
| 372-385 | "`Outcome<T>`, `Energy`, `Demod<S>` — v5 updates" subsection — placeholder text for Outcome | **REPLACE** — land canonical definition with D1.9.1.1-6 baked in |
| 540 | hard-problems table mentions Outcome | Stays |
| **589** | **pod-arc `1.9 Outcome<T>: typed errors + stack bounds (0xC0–0xCF) [planned]`** | **MUST CHANGE** — opcode range + sub-pod split (1.9.1/1.9.2/1.9.3) |

**v9 patch scope (TB-recommended bounded scope):**

1. Header: v8 → v9; add update-history line; add "Why v9 exists" subsection
2. Opcode allocation table (line 323 + 325): Outcome → 0xE0-0xE4; Demod → 0xE5-0xEF
3. Outcome subsection (lines 372-385): replace Outcome's portion with canonical D1.9.1 definition (layout, opcodes, decisions, forward-logs)
4. Pod arc (line 589): split Pod 1.9 into 1.9.1 (canon, this pod) / 1.9.2 (source) / 1.9.3 (refit); update opcode range

**Out of scope for v9 patch (other accumulated drift):**
- Pod 1.5.5 hash row uses `b560a6c` (not verified against repo this pod)
- Pod 1.8 row says `[DONE — Pod 1.8]` without explicit hash (actual `8c38343`)
- Pod 1.8.5, 1.8.5b, 1.8.5b.5, 1.8.5c — none in pod-arc table
- Cap<R> row says `0xB0-0xBF` but Pod 1.8.5b energy_costs.asm comment hints at 0xC0-0xCF for Cap

These represent broader pod-arc reconciliation that should be a separate housekeeping pod, not bundled into v9. Pod 1.9.1's v9 patch focuses on Outcome canon. Surfacing as A5 to confirm bounded scope.

## Section 2 — Architect calls before AUTHORIZED-1

### A1 — Slot layout (R3)

TB confirms architect's sketch verbatim. **No amendment requested.** 128 bytes total, no collision with Move 3 fields. Phase 2 S1 records as written.

### A2 — Pool sizing (R4)

TB confirms 64-slot / 128-byte / bump-allocator / registry sizing per Sign/Energy precedent. **No amendment requested.**

### A3 — Outcome `value_type_id` code system

D1 says `value_type_id` "names which canonical-ID type the success branch carries (sign_id, energy_id, cap_id, demod_id, signal_id; all u64 with semantic names per Pod 1.8.5b)." Currently `boot/defines.asm` defines null sentinels (`SIGN_ID_NULL = 0` etc.) but no per-type **identifier codes** for the discriminant.

Need: a small enum giving each canonical-ID type a u64 code that fits in `value_type_id`. Recommended:
```
TYPE_CODE_SIGN     equ 1
TYPE_CODE_ENERGY   equ 2
TYPE_CODE_CAP      equ 3
TYPE_CODE_DEMOD    equ 4
TYPE_CODE_SIGNAL   equ 5
TYPE_CODE_OUTCOME  equ 6   ; for Outcome wrapping Outcome (future)
```
Code 0 reserved as "no type" (parallels NULL sentinels).

Plus `OUTCOME_ID_NULL = 0` added to the existing null-sentinel block.

**TB recommendation:** add both at Pod 1.9.2 (source pod that needs the codes for handler implementation). Pod 1.9.1 design records the convention; Pod 1.9.2 lands the constants. Confirm or amend.

### A4 — D6 prov_append wiring details (R6 substrate gap)

OP_OUTCOME_NEW_ERR fires `prov_append(rdi=opcode, rsi=demod_id, rdx=fetch_counter)`. Three sub-questions:

**A4.a — Where does fetch_counter come from?** Substrate has none today.
- (i) **TB recommendation:** Pod 1.9.2 adds `vm_fetch_count: dq 0` to vmdata.asm and increments at .fetch loop head in cbs_vm.asm. Mechanical, ~3 lines, value useful for substrate audit beyond just D6.
- (ii) Pass 0 placeholder; Pod 2 (Cop) adds the counter when it activates auto-provenance. Defers the substrate gap.
- (iii) Use `[rel energy_used]` as proxy. Semantically loose (energy units, not fetch units).

**A4.b — What `opcode` value does OP_OUTCOME_NEW_ERR pass?**
- (i) The construction opcode itself (0xE1 = OP_OUTCOME_NEW_ERR). Records "this prov event was generated by an Outcome construction."
- (ii) **TB recommendation:** the user-supplied `err_source_op` (from the error context). Records the original error origin opcode, which is more semantically meaningful for audit.

**A4.c — What `demod_id` does it pass?**
- (i) **TB recommendation:** the user-supplied `err_demod_id` (from the error context). Ties the prov event to the demod the error was raised against.
- (ii) "current demod" — but no such state exists beyond the singleton placeholder; would default to 0 in V1.0.

### A5 — RECONSTITUTION v9 patch scope (R8)

TB recommends **bounded patch**: only what Outcome canon strictly requires (4 changes per R8). Out-of-scope drift items (pod-arc backfill for sub-pods, Pod 1.5.5 hash verification, Cap allocation reconciliation) recorded as a future housekeeping-bundle pod, not bundled into v9.

Confirm bounded scope, or expand to broader reconciliation.

### A6 — OP_OUTCOME_IS_OK consume vs. peek

The prompt says "Recommend peek-and-not-consume for Outcome interrogation pattern... Surface as architect call A6 if peek mechanism doesn't already exist in cbs_vm.asm."

**Substrate audit:** No existing opcode peeks-without-consuming. Every accessor follows the pop-args/push-results convention. The closest analog is `OP_DUP` (0x83) which dups TOS — a caller can `dup; is_ok` to keep the outcome_id available for subsequent unwrap.

**TB recommendation:** consume (Option A). OP_OUTCOME_IS_OK pops outcome_id, pushes 0 or 1. Caller dups the outcome_id first if they want to keep it for unwrap. Preserves substrate's consistent stack-effect convention. The "is_ok then unwrap" pattern becomes `DUP; IS_OK; <branch>; UNWRAP_*`.

Confirm or override (override would require adding a peek primitive to the substrate).

### A7 — OP_OUTCOME_UNWRAP_OK on err / OP_OUTCOME_UNWRAP_ERR on ok

The prompt says "if discriminant=1, fault (or push sentinel — TB recommends fault, surface as architect call if alternative needed)."

**Substrate audit:** V1.0 has no general-purpose fault path. Existing failure modes:
- `.fatigue` (insufficient energy → DEGRADED message + halt)
- `.sign_new_fail` / `.energy_new_fail` (push 0 sentinel)
- `str_ret_underflow` / `str_call_overflow` (halt with diagnostic; Q8 says these become Outcome<T> in Pod 1.9.3 itself)

**TB recommendation:** Pod 1.9.2 implements UNWRAP_OK on err (and UNWRAP_ERR on ok) as **push-sentinel-and-log**, not fault. Reasons:
- No general fault path exists; faulting would mean halting the VM
- Halting on unwrap_ok-of-err defeats the purpose of typed errors (the whole point of Outcome is to NOT halt on unexpected error)
- Sentinel + log matches the existing accessor-null-handler pattern

The "log" is a string-emit similar to `str_op_energy_recover_noop` from Pod 1.8.5c. Suggested strings: `str_unwrap_ok_on_err: db '  UNWRAP_OK on Err — sentinel returned',10,0` etc.

Pod 2 (Cop) hardens this if/when fault semantics get formalized.

Confirm or amend.

---

## Section 3 — Risks identified

- **R3.1** — Adding a substrate-wide fetch_counter (A4.a option i) is out of the explicit Pod 1.9.1/1.9.2 scope as stated in the original prompt's "five moves" wording. It's a small new substrate mechanism, surfaced by D6 wire-up necessity. Worth the explicit ratification.
- **R3.2** — RECONSTITUTION v8 carries multiple drift items beyond Outcome (Cap allocation, Pod 1.5.5 hash, missing 1.8.x sub-pod rows). The bounded v9 patch leaves that drift in place; future housekeeping pod must address.
- **R3.3** — `value_type_id` code space (A3) is a new enum convention. The first code (TYPE_CODE_SIGN = 1) and OUTCOME_ID_NULL = 0 conflict means: an Outcome with `value_type_id = 0` is "no type" (uninitialized / sentinel). Worth being explicit about the 0 case in design.
- **R3.4** — A6 / A7 lock substrate behavior on edge cases (is_ok consume, unwrap-on-wrong-discriminant). These shape downstream user code patterns; getting them right at design time matters more than at implementation time.

---

## Section 4 — Phase 2 execution gates (post-AUTHORIZED-1)

Once architect ratifies A1–A7:

- **S1** — write `recon/POD1.9.1_DESIGN_DECISIONS.md` with the six decisions, slot layout (R3 confirmed), opcode signatures, forward-log to 1.9.2/1.9.3
- **S2** — RECONSTITUTION v9 patch per A5 bounded scope (4 edits): version header, opcode allocation table (Outcome → 0xE0-0xE4, Demod → 0xE5-0xEF), Outcome subsection replacement, pod-arc Pod 1.9 row split
- **S3** — DEFERRED entries #35 and #36 (forward-looking 1.9.2 and 1.9.3 closes)
- **S4** — binary_contracts.md preserved row for 1.9.1
- Phase 3 — single commit, 5 files staged, three-oracle verify

---

## Section 5 — Surprises

- **S5.1** — Substrate has no fetch_counter despite ProvEvent declaring the field and prov_append documenting the parameter. Pod 1.8.5c shipped the conduit "for V1.0 default-OFF" so the gap was never load-bearing; it becomes load-bearing the moment any consumer wants to populate the field meaningfully.
- **S5.2** — RECONSTITUTION v8 has Outcome at 0xC0-0xCF, an old assignment that pre-dates the 1.8.5b/c work. The Cap allocation also drifted (energy_costs.asm comment hint at 0xC0-0xCF) without RECONSTITUTION update. Two sources of truth diverged.
- **S5.3** — Pod 1.9 splits into three sub-pods (1.9.1 canon, 1.9.2 source, 1.9.3 refit) based on the prompt's structure. This three-way split matches Pod 1.5/1.5.5/1.5.6 and Pod 1.6/1.7 patterns where canon, source, and refit landed separately. Worth recording in the pod-arc table as architectural precedent.

---

## Section 6 — HALT 1 status

- All R-items completed.
- No source files modified.
- No commits staged.
- 7 architect calls (A1-A7) surfaced; A1, A2 are confirm-only; A3-A7 require ratification.
- 4 risks surfaced (none blocking).
- 3 surprises surfaced.

**HALT 1 — awaiting AUTHORIZED.**

— Terminal Boy
May 03 2026
