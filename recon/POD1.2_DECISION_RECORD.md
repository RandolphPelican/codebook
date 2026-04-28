# Pod 1.2 — Decision Record

**Date:** 2026-04-27
**Pod:** 1.2 (canon-only, no source changes)
**Input:** `recon/POD1.1_VM_AUDIT.md` questions Q1–Q8
**Output:** Architect decisions canonized in RECONSTITUTION.md v4
**Decided by:** Chauncey (architect)

---

## Q1 — Cap ops: extend or replace?

**Decision:** Replace entirely. Retire `OP_GRANT_CAP` (0x90) and
`OP_USE_CAP` (0x91) in Pod 1.9. Typed Cap<R> opcodes in the
`0xB0–0xBF` range replace them.

**Rationale:** The current cap ops are magic-number token dispatchers
— they create untyped `0xCA000000 + resource_id` tokens and dispatch
via hardcoded `cmp` chains. This is not a capability system; it's a
switch statement wearing a capability costume. Extending it would
preserve the wrong abstraction. The spatial-merge design from Pod 0.9
informs the replacement architecture, but no current cap code
survives into the typed system.

**Affects:** `boot/cbs_vm.asm` (op_grant_cap, op_use_cap, all
cap_* handlers), `boot/defines.asm` (OP_GRANT_CAP, OP_USE_CAP,
OP_GRANT_CAP_NEW, OP_USE_CAP_NEW).

---

## Q2 — OP_RET semantics: exit VM or return from call?

**Decision:** Option (a) — `OP_RET` pops from `vm_ret_stack` and
resumes at saved PC (subroutine return). A new `OP_HALT` opcode
exits the VM. Pod 1.3 implements this.

**Rationale:** `OP_CALL` already saves a return address to
`vm_ret_stack`. The infrastructure for subroutine calls exists but
is half-built — `OP_RET` exits the VM instead of reading
`vm_ret_stack`. The intent was clearly subroutine semantics; the
current behavior is a bug, not a design choice. Making
`OP_CALL`/`OP_RET` a functioning pair enables structured CBS
programs without goto-spaghetti.

**Affects:** `boot/cbs_vm.asm` (`.op_ret` handler, new `.op_halt`
handler + dispatch entry), `boot/defines.asm` (new `OP_HALT`
define).

---

## Q3 — Atreyu cap handler: dead code or missing dispatch?

**Decision:** Option (b) — leave dead until Pod 1.9 exiles it
alongside the rest of the cap ops. Pod 6 (Atreyu Walks) decides
whether to rebuild from this skeleton or start fresh.

**Rationale:** Wiring `cap_atreyu` now would connect dead code to a
system (`OP_USE_CAP`) that is itself being retired. Removing it now
saves nothing — the code is inert and harmless. Leaving it preserves
the design notes (six operations that a future Atreyu editor might
need) without pretending it works. DEFERRED #11 tracks the exile.

**Affects:** No code changes. `cap_atreyu` at `cbs_vm.asm:408–493`
remains as-is until Pod 1.9.

---

## Q4 — Integer width: 32-bit or 64-bit?

**Decision:** Option (a) — widen to 64-bit throughout. All
arithmetic uses `rax`/`rbx`. `OP_PUSH` operands become 8 bytes.
Pod 1.4 implements the migration.

**Rationale:** The VM runs on a 64-bit CPU with 64-bit stack slots.
Using 32-bit arithmetic (`eax`/`ebx`) while storing results in
64-bit slots creates a dual-width system where the upper 32 bits of
every stack entry are undefined. Pod 1's typed primitives (Cap<R>
with 64-bit fields, Energy with 64-bit budgets) need full-width
values. One integer width eliminates an entire class of truncation
bugs. The cost — wider bytecode operands — is trivial for an
embedded VM with no external bytecode ecosystem to preserve.

**Affects:** `boot/cbs_vm.asm` (every arithmetic handler, OP_PUSH
operand fetch, OP_LOAD/OP_STORE), `boot/data.asm` (embedded .cbc
programs need recompilation — see DEFERRED #12).

---

## Q5 — Opcode space allocation for Pod 1 types

**Decision:** Typed primitives claim `0xA0–0xEF` (80 slots),
allocated by primitive:

- `0xA0–0xAF` — Sign (Pod 1.5)
- `0xB0–0xBF` — Cap<R> (Pod 1.8–1.9)
- `0xC0–0xCF` — Outcome<T> (Pod 1.7)
- `0xD0–0xDF` — Energy (Pod 1.6)
- `0xE0–0xEF` — Demod<S> (Pod 1.10)
- `0xF0–0xFF` — reserved for future expansion

**Rationale:** The largest contiguous free block in the current
opcode map is `0x92–0xFE` (109 slots). Allocating `0xA0–0xEF`
takes 80 of those 109, leaving `0x92–0x9F` (14 slots) as a buffer
between existing ops and typed primitives, and `0xF0–0xFF` (16
slots) as headroom. Each primitive gets 16 slots — enough for
create/read/update/delete plus type-specific operations.

**Affects:** `boot/defines.asm` (new OP_* defines in each pod),
`boot/cbs_vm.asm` (new dispatch entries in each pod).

---

## Q6 — Surface token header alignment

**Decision:** Option (c) — ignore the Python toolchain header
entirely. The NASM VM is the authority.

**Rationale:** The 23-byte surface token header exists in
`tools/cbsc.cbs` (Python toolchain). The NASM VM's `cbs_run` does
not parse it — execution begins at byte 0 of the bytecode stream.
There is no Python toolchain compatibility requirement. The NASM VM
is the only runtime, and it defines the bytecode format. README's
reference to the token header is a stale artifact (tracked in
DEFERRED #7 for cleanup in the README rewrite).

**Affects:** No code changes. README rewrite (DEFERRED #7) will
remove or correctly scope the token header reference.

---

## Q7 — Energy: per-fetch or per-opcode-type?

**Decision:** Option (b) — per-opcode-type cost table. The flat
per-fetch base cost is replaced, not supplemented. Pod 1.6
implements this.

**Rationale:** ROADMAP.md describes "every CBS function declares
costs Nj" — the intent was always differential pricing. A flat
1-joule-per-fetch model means `OP_NOP` costs the same as
`OP_GRANT_CAP`, which defeats the purpose of energy as a resource
accounting primitive. A cost table lets the system express that
capability operations are expensive, I/O is expensive, arithmetic
is cheap — which is the metabolic model the organism needs.

**Affects:** `boot/cbs_vm.asm` (fetch loop energy debit replaced
with table lookup), `boot/vmdata.asm` or `boot/data.asm` (new
opcode cost table).

---

## Q8 — Stack bounds checking

**Decision:** Option (c) — `Outcome<T>` typed errors. Stack
underflow and overflow produce typed error results. The specific
error representation is deferred to Pod 1.7 when `Outcome<T>`
becomes a native VM type.

**Rationale:** Fatal halts (option a) are too aggressive — a
single stack miscalculation kills the entire VM, which is wrong
for a system that wants to run multiple surfaces. Silent
degradation (option b) hides bugs. Typed errors (option c) let
the caller decide: a surface can catch the error and recover, or
let it propagate to the system level. This is consistent with the
CBS design principle that everything is a typed value — errors
included.

**Affects:** `boot/cbs_vm.asm` (stack push/pop wrappers with
bounds checks, Pod 1.7), `boot/defines.asm` (error type constants,
Pod 1.7). DEFERRED #13 tracks the encoding design.

---

## Closing

Eight decisions. All canonized in RECONSTITUTION.md v4. The VM
substrate audit (Pod 1.1) asked the questions; this record captures
why the answers are what they are. Future pods implementing these
decisions should read this memo to understand the constraints, not
just the conclusions.
