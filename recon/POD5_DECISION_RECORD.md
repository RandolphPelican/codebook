# Pod 5 Decision Record — Metabolic Enforcement (V1.1)

**Status: LANDED** on branch `v1.1-metabolic`, 8 chunks + demo + harness.
V1.1 SEAL: `58823aa9e9ad17c3fd0975cad557c934599c22588c38506d4454b6dbe1b5db6a`
(chain: V1.0 `c9923b8cf9fb6caf4c195e2d0d0ea2ed4a8e51e4e9f827b1fc24dd0b28c1d900`
→ V1.1). Two-build deterministic. Architecture drafted with AI
assistance (Claude) and revised after line-level review; substrate
chunks landed under two-build determinism and canary verification. The
V1.1 authorship boundary statement (what was hand-typed vs
AI-assisted, and how the README credential sentence reads
post-V1.1) is the author's to finalize before seal — see README
authorship note. This record supersedes
`POD5_DECISION_RECORD_DRAFT.md` (chat-side draft, retained nowhere —
this is the canonical record).

Landed as (main..v1.1-metabolic, in order):
- chunks 1–2: metabolic ledger constants + current-cap slot/budget cache
  plumbing (no behavior change)
- chunk 3: per-cap energy debit + bankruptcy check in `.fetch`;
  `.cap_fatigue` diagnostic halt
- chunk 4: settlement-on-exit with dispatched/settled watermark fold in
  `.op_cap_exit`
- chunk 5: `OP_CAP_DISPATCHED` (0xBB) accessor via `.cap_accessor_common`
- chunk 6: reset cap_stack + current_cap to ROOT at `cbs_run` entry
- chunk 7: sentinel-grant closure at `OP_CAP_NEW`
- B61: metabolic capability demo (demo-tier generator) + run-twice reset
  canary harness; bankruptcy and reset both verified
- chunk 8: atreyu `_expr` raises on unknown expression node (was a silent
  fallthrough emitting nothing)
- follow-up `a0bbbc4`: `cap_dispatched` expression node in atreyu;
  sealed bytecode verified unchanged

Actual scope: 118 added lines under `boot/`, 12 in
`tools/atreyu_x86.py` (chunk 8 raise + `cap_dispatched` node), plus the
demo-tier B61 generator and `tools/v11_runtwice.sh` harness. Review's
70–80 estimate was closer than the original 15–30; recorded for
calibration.

---

## D5.1 — Per-fetch current-cap metabolic debit (energy_dispatched)

Pre-5, the dispatch loop debited only the global ledger (`r14` +
`energy_used`). Cap slots carried `CAP_OFF_ENERGY_BUDGET` (MAC-input,
immutable per D1.10.3) — but nothing wrote per-cap state from the hot
path, and nothing compared anything to `budget`. The budget field was a
promise the substrate recorded and did not keep.

Pod 5 lands the debit at the Babylon cost-stash point in `.fetch` (post
cost-lookup, pre dispatch), writing a new field:

- `CAP_OFF_ENERGY_DISPATCHED` (+0x48, non-MAC, substrate-managed) — full
  cost of every opcode fetched under this cap's authority. See D5.4 for
  why this is not `energy_used`.

Mechanics as landed:

1. **Check-before-mutate ordering.** Cost lookup → global bankruptcy
   check (`r14`) → cap bankruptcy check → only then debit global AND
   cap. No partial state on any fatigue path.
2. **Overflow-safe compare.** `remaining = budget − dispatched;
   remaining < cost → .cap_fatigue`. The naive `dispatched + cost >
   budget` wraps on near-max budgets, which D5.5's grant check makes
   reachable. The check itself maintains the `dispatched ≤ budget`
   invariant that keeps the subtraction safe.
3. **Cache extension, not registry scan.** Extends the Pod 2.2 cache
   pattern with `current_cap_slot_ptr_cache` and
   `current_cap_budget_cache`, refreshed at OP_CAP_ENTER, OP_CAP_EXIT,
   and invocation entry (D5.2). Budget cache is sound because
   `energy_budget` is MAC-input immutable. Hot-path addition: one
   compare, one branch, one memory add.
4. **Runtime cache init, not static.** `dq vm_cap_pool` would bake a
   link-time absolute into a `-f bin` PE that UEFI may relocate — the
   reason every access in the tree is `lea [rel ...]`. Root cache init
   lands in `construct_root_cap`, which already holds
   `lea rdi, [rel vm_cap_pool]` and runs pre-MIND.
5. **Unbounded sentinel.** `budget == ENERGY_BUDGET_UNBOUNDED (-1)`
   skips the check but NOT the debit. ROOT's `dispatched` accumulates
   total program metabolic history — legible, uniform code path.

The MAC problem that would have made this pod expensive was pre-solved
at D1.10.3: mutable per-cap state sits outside `CAP_MAC_INPUT_QWORDS`
by design. Pod 5 is the payoff of that split.

## D5.2 — Bankruptcy is deterministic HALT; invocation reset is its precondition

When the current cap cannot afford the fetched opcode, the substrate
takes `.cap_fatigue`: print `CAP BANKRUPT` and the bankrupt cap's id,
then HALT — banner itself 0j (off-ledger, post-decision). Mirror of the
global `.fatigue` path. The banner deliberately does NOT print budget or
dispatched: the metabolic numbers are program-legible via
OP_CAP_DISPATCHED, and B61's between-rounds self-reads are where the
climb is displayed — the substrate announces the death, the program
narrates the dying. No
synthesized `Outcome::Err` at the fetch boundary — arbitrary opcodes
have no Err path. Typed exhaustion recovery (Err at forge sites, or a
handler continuation registered at OP_CAP_ENTER) is V2.0 DEFERRED.

**Precondition caught in review, landed as chunk 6:** `cbs_run` entry
previously reset `energy_used` and `vm_ret_ptr` only; `current_cap_id`
and `cap_stack_ptr` persisted across invocations. Under enforcement, a
program dying nested inside a bankrupt cap would leave the substrate
pointed at that cap, and the next invocation would instant-fatigue with
a banner naming a cap it never entered. Pre-enforcement this was
harmless; post-enforcement it is a substrate that eats itself after one
demo. `cbs_run` entry now resets `cap_stack_ptr = 0`,
`current_cap_id = ROOT_CAP_ID`, and refreshes all caches from the root
slot. Verified by `tools/v11_runtwice.sh`: surface 2 runs clean after
surface 1 dies bankrupt-nested.

**fetch-count note:** `vm_fetch_count` increments at the top of
`.fetch`, before cost lookup — an aborted (fatigued) fetch is counted.
Documented rather than moved at V1.1; provenance canaries on fatigue
paths must expect the off-by-one.

## D5.3 — Settlement-on-exit with watermark

True hierarchical containment (every ancestor bounds all descendant
spend) requires a cap_stack walk per fetch. Rejected for the hot path.
Landed instead:

- Per-fetch debit touches the **current cap only** — O(1).
- `.op_cap_exit` folds the exiting cap's **unsettled** dispatched into
  the parent: `parent.dispatched += child.dispatched − child.settled;
  child.settled = child.dispatched`, with `CAP_OFF_ENERGY_SETTLED`
  (+0x50, non-MAC). The watermark exists because the naive fold
  double-bills every prior session on re-entry (enter A, burn 100,
  exit, enter A, burn 50, exit must bill 150, not 250), and because
  zeroing at settlement would destroy the lifetime total the accessor
  reports.
- A parent that overcommitted its children detects overdraft at its own
  next fetch — one settlement late, deterministically.
- HALT while nested skips settlement; the program is over.

**Two "parent" notions, on purpose.** The cap_stack holds the *dynamic
caller* (any cap you hold can be entered); `parent_cap_id` holds the
*lineage parent* fixed at forge time. They are not the same cap.
**Settlement follows the stack; Babylon follows the lineage.** Bills go
to whoever ran you; construction echoes go to whoever made you. This
sentence exists so nobody reads the divergence in six months and
assumes a bug.

**Cost:** `OP_CAP_EXIT` was already priced 0j in the sealed cost table
— settlement lands on an op whose 0j status existing doctrine already
ratifies.

## D5.4 — Ledger separation axiom

The architecture draft originally wrote dispatch and settlement into
`CAP_OFF_ENERGY_USED` — the field Babylon owns. Review caught that this
made one number mean three things (decayed ancestral construction
ripples + own dispatch + settled descendant dispatch), made bankruptcy
a check against a blend of a decay series and a sum, and silently
invalidated every sealed number in the eight canaries reading
OP_CAP_USED (`test_babylon_initial_zero`, `_single_level`,
`_multi_level`, `_federation_total`, `_root_only_invisible`,
`_canary_subcap`, `test_synthesis_babylon_ripple`,
`test_cap_used_zero_at_construction`). Under PNG-eyeball verification
nothing would have failed loudly; the decision records would simply
have rotted.

As landed: **`energy_used` remains Babylon's pure decayed-ripple
ledger, untouched by Pod 5.** Dispatch and settlement write
`energy_dispatched`; bankruptcy checks `dispatched` against `budget`.
Each number means exactly one thing. Verified post-land:
`test_babylon_federation_total` still prints A=150 / B=0 / ROOT=85;
`test_cap_used_zero_at_construction` still prints 0. Blast radius on
the existing canary set: zero, by construction.

New accessor: `OP_CAP_DISPATCHED` at 0xBB via `.cap_accessor_common`,
1j, mirroring OP_CAP_USED.

**Compiler exposure (landed `a0bbbc4`):** atreyu exposes
`cap_dispatched` as an expression node emitting OP_CAP_DISPATCHED
(0xBB), verified against the sealed set before commit
(`test_babylon_federation_total.cbc` byte-identical post-change). B61
prints BOTH ledgers side by side — `cap_used` (Babylon, 0 for pure
loop work) and `cap_dispatched` (metabolic) — making the D5.4
separation directly visible in one framebuffer. Chunk 8's
raise-on-unknown guarded the interval where the node didn't exist:
loud failure, not bytecode holes.

## D5.5 — Bounded caps cannot grant the unbounded sentinel

`OP_CAP_NEW` subset-checked the bitmap but not the budget: a 50,000j
cap could forge a child with `budget = -1`, and D5.1's sentinel skip
would exempt that child from bankruptcy for its whole run. Settlement
still lands the bill at exit (bounded by `r14`), but "the budget bounds
the subtree" would be false while the child runs, and the escape was
one PUSH away.

Landed as chunk 7, exactly parallel to subset-on-grant (D2.2.5):
`granted_budget == UNBOUNDED && parent_budget != UNBOUNDED →
Err(ERR_CAP_AUTHORITY_EXCEEDED)`. The limit model otherwise stands:
bounded budgets bound, they do not reserve; overcommit is permitted at
grant time and punished at settlement. Only the sentinel is closed,
because the sentinel is the one grantable value that is not a limit.

## D5.6 — Substrate-bookkeeping doctrine, seventh empirical landing

Lineage: D1.9.2b.1 → D1.10.2a.7 → D1.10.2b2.3 → D1.10.3.X → D2.1.6 →
D2.2.9 → **D5.6 (this pod)**. The per-fetch debit, bankruptcy compare,
cache refreshes, invocation reset, watermark, and settlement fold are
substrate-private field work: **0j**. No cost-table pricing changes.
Only operand-visible work charges.

**Canary results at seal — measured vs reasoned, kept separate:**
- MEASURED post-land: `test_babylon_federation_total` (A=150 / B=0 /
  ROOT=85), `test_cap_used_zero_at_construction` (0), B61 bankruptcy
  banner, `v11_runtwice.sh` reset canary.
- REASONED (0j bookkeeping + unbounded ROOT sentinel imply no drift;
  re-measure at seal before tagging): B2 174j, B3 53j, B53 fib trace,
  B55 5,647j, and the remaining six of the eight OP_CAP_USED canaries.
  A reasoned claim is not a sealed number until the framebuffer says
  so.
- B61: 600j child dies mid-loop, CAP BANKRUPT banner names cap_id=2;
  run-twice harness (`tools/v11_runtwice.sh`) passes — surface 2 clean
  after surface 1 dies nested.
- Two-build determinism: byte-exact BOOTX64.EFI;
  V1.1 SEAL `58823aa9e9ad17c3fd0975cad557c934599c22588c38506d4454b6dbe1b5db6a`.

---

**Closing note — the metabolic observer effect.** OP_CAP_DISPATCHED
costs 1j and dispatch debits before the handler runs: reading your own
consumption consumes. A program cannot observe its metabolic state
without changing it, by exactly one priced quantum per observation. In
a substrate whose thesis is that computation is physical, measurement
is too. Not a wart; the thesis restated at the accessor boundary.

*The budget field stops being a promise and starts being a law.*
