# Contributing

CodebookOS is a single-architect project at V1.0 SHIP. Public contributions aren't expected immediately, but the methodology is public so anyone can understand how the substrate is built and what a clean PR against it would look like at V2.0.

This document is also a fair record of *what kind of contribution would land*. The substrate has discipline; that discipline doesn't relax for outside contributors.

---

## The chunked-pod methodology

Every architectural change goes through a **pod** — a unit of bounded scope, codified upfront, executed in chunks, sealed with a decision record. The skeleton:

### 1. Recon (chunk A)
- Read the relevant existing source and prior decision records
- Identify the design space (what could land; what shouldn't)
- Produce a recon report: `recon/POD<N>_RECON_REPORT.md` or `_RECON_NOTES.md`
- End recon with **questions for the architect** — never start implementation while design ambiguity remains

### 2. HALT 1 — architectural ratification
- Architect reviews recon + questions
- Decisions made are codified as **doctrines** (D<phase>.<num>) before any code is written
- HALT 1 closes when every question has a ratified answer; the doctrines that will land are named upfront

### 3. Execution chunks (B-N)
- Each chunk is bounded (typically 1-3 hours of architect attention)
- Substrate edits happen in chunk-bounded slices
- Each chunk closes by running a canary (`tools/pod<N>_canary_test.sh`) that verifies the chunk's promises
- Substrate sha is verified at every chunk close (two-build determinism)

### 4. Canary verification
- The substrate canary boots the OS in QEMU, runs a target CBS demo, captures framebuffer, exits
- Pre-canary hash → post-canary hash comparison detects any drift
- Auxiliary substrate canaries (`tools/pod<N>_b<X>_b<Y>_runner.sh`) wrap a temporary substrate change (e.g., a codebook ingestion) for a single canary run, then revert

### 5. SEAL (final chunk)
- Pod's decision record (`recon/POD<N>_DECISION_RECORD.md`) lands every doctrine + catch profile + state at SEAL
- Three-oracle verification: `git rev-parse HEAD` = `git rev-parse origin/main` = `git ls-remote origin main`
- Commit message follows the format: `Pod <N>: <description>` ending with a SEAL-marker line
- Substrate sha invariant verified one more time across the SEAL commit

The methodology trades velocity for discipline. A pod takes 1-3 days of architect attention; that yields a substrate change with a codified rationale, byte-exact verification, and a paper trail.

---

## How to author a CBS demo

The 6 V1.0 canary demos in `surfaces/test_pod40f_b5*.cbc` are reference implementations. To add a new demo:

### Step 1 — add the AST emitter function

In `tools/atreyu_x86.py`, add a new function `demo_<name>()`:

```python
def demo_my_new_demo():
    """One-line description of what this demo proves."""
    return {
        'type': 'program',
        'body': [
            {'type': 'print', 'value': {'type': 'int', 'value': 42}},
            # ...more statements...
            {'type': 'return', 'value': {'type': 'int', 'value': 0}},
        ],
    }
```

Refer to existing `demo_pod40f_b5*` functions for the AST shape conventions. Read [CBS_LANGUAGE.md](CBS_LANGUAGE.md) for the full statement/expression vocabulary.

### Step 2 — register a CLI subcommand

In `tools/atreyu_x86.py`'s argparse block, add a build option that compiles your demo to a `.cbc` file:

```python
parser.add_argument('--my-new-demo-build', metavar='OUT.cbc',
                    help='Compile my new demo to OUT.cbc')
```

And dispatch:

```python
if args.my_new_demo_build:
    ast = demo_my_new_demo()
    compile_and_write(ast, args.my_new_demo_build)
```

### Step 3 — add a canary runner

Copy `tools/pod35_canary_test.sh` to `tools/my_new_demo_canary.sh`. Modify it to:
- Compile your demo via `python3 tools/atreyu_x86.py --my-new-demo-build surfaces/my_new_demo.cbc`
- Boot the substrate in QEMU
- Auto-type `load my_new_demo.cbc` at the Gmork prompt
- Capture framebuffer to `build/my_new_demo.png`

### Step 4 — predict and verify

Before running the canary, write a prediction document in `recon/`: what the demo should print, what energy should be consumed, what failure modes are expected. Then run the canary and verify byte-exact against your prediction.

If predictions match: doctrine-confirming. If they differ: investigate; either the prediction is wrong (most common) or the substrate has a bug (rare; landed as a D-numbered substrate-catch like D3.37).

---

## How to extend the substrate

Substrate-tier changes require a decision record in `recon/` and reseal the contract sha. The bar is high: every substrate change rewrites the SEAL contract sha, and the new sha is **chained** into the docs rather than overwriting the old one. **The substrate is byte-locked per release — V1.0 at `c9923b8cf9fb6caf4c195e2d0d0ea2ed4a8e51e4e9f827b1fc24dd0b28c1d900`, V1.1 at `58823aa9e9ad17c3fd0975cad557c934599c22588c38506d4454b6dbe1b5db6a`** (per D4.1 polish-vs-credential separation; V1.1 reseal per Pod 5). Polish-tier work must not touch any file under `boot/`.

### Substrate change checklist (V2.0+)

For a new opcode:

1. **Allocate an opcode byte in the right row** — see `boot/defines.asm` for row reservations (Sign 0xA0-0xAF, Energy 0xA8-0xAF, Cap 0xB0-0xBF, Embedding 0xC0-0xCF + 0xF0-0xF5, Outcome 0xE0-0xE6, demod-tier 0xE8-0xEF reserved, etc.)
2. **Document cost in joules** — anticipated worst-case per D3.17; add an entry to `boot/energy_costs.asm` with a doctrine-citing comment
3. **Implement handler in `boot/cbs_vm.asm`** — typically dispatch to a helper in the relevant surface file (e.g., `boot/maid.asm` for compute, `boot/cap.asm` for cap, `boot/babylon.asm` for spatial-merge)
4. **Add MAC verification at boundaries** — if the op reads MAC-protected slot fields, MAC-verify before read (D1.10.1.7 + D3.3 + D3.18)
5. **Add to dispatch table** — opcode → handler pointer
6. **Add AST emitter in `tools/atreyu_x86.py`** — the compile path so CBS programs can call your op
7. **Add NASM RIP-relative discipline** — `lea reg, [rel sym]; [reg + idx*scale]` (D3.37)
8. **Write a canary that exercises the new op** — predict output, run, verify byte-exact

### Substrate-catch discipline

If the substrate behaves unexpectedly during a canary, **investigate to root cause** before patching. Substrate-catches (like D3.37 RIP-relative or D3.41 forge-id literal discipline) are doctrine-grade landings — they shape every future op's implementation. Surface them in the pod's decision record and update governing doctrines.

---

## The polish-vs-credential rule (D4.1)

The repo has two disciplines:

| Discipline | Directories | What's allowed |
|---|---|---|
| **Credential** | `boot/`, `surfaces/`, `tools/`, `recon/` | Touches substrate sha; requires three-oracle verification, canary byte-exact, doctrine-grade rationale |
| **Polish** | `polish/` | Python only; cannot import from `boot/`; cannot regenerate `.cbc`; cannot affect substrate sha |

**The boundary is one-way**: polish code can read substrate artifacts (canary PNGs, demo MP4s); credential code cannot import or depend on `polish/`. The substrate must build, run, and pass canaries with `polish/` deleted entirely.

This separation is empirically verified at the **D4.1 byte-lock**: every Pod 4.0.X polish chunk closes with the substrate sha unchanged from V1.0 SEAL. A polish-tier change that mutates the substrate sha would be a violation; none have occurred through Pod 4.0.G.

---

## Style notes

### NASM (substrate)

- **Indent**: 4 spaces; tabs are forbidden in `.asm` files
- **Symbol naming**: `snake_case` for labels; `UPPER_SNAKE` for constants; surface-name-prefix for surface-specific helpers (`maid_compute_cosine_raw`, `babylon_ripple_energy_used`)
- **Comments**: doctrine-cite every non-obvious decision (`; D3.14 Form A — accumulation order is bit-exact load-bearing`)
- **RIP-relative**: always `lea reg, [rel sym]; [reg + idx*scale]` (D3.37). Never `[rel sym + reg*scale]`.
- **Stack alignment**: SysV AMD64 ABI 16-byte before any function call; substrate's own helpers can use a register-passing convention but must restore the stack on return
- **MAC verification**: every slot field read across a privileged boundary verifies the MAC first; helpers like `maid_compute_cosine_raw` MAC-check candidate vectors in the loop (D3.18)

### Python (compiler + polish)

- **Indent**: 4 spaces
- **Imports**: standard library first; third-party (PIL, pygame) second; project-local third — no wildcard imports
- **Style**: PEP 8 baseline; avoid premature abstraction; one Python file per polish animation/surface
- **Type hints**: not required at V1.0; ok to add if it clarifies intent
- **No emojis** in code or comments unless explicitly requested
- **No comment-narration of obvious code** — well-named functions are the documentation

### Markdown (docs + recon)

- **Frontmatter**: not used in this repo; titles are H1 at the top
- **Tables**: GitHub-flavored markdown; column alignment optional
- **Cross-references**: prefer `[Title](file.md)` over bare URLs; relative links for repo-internal docs
- **Voice**: declarative, present tense; no hedge words ("we believe", "should", "might") for established facts; reserve speculation for "deferred" / "V2.0 carry-forward" sections
- **Code blocks**: language-tagged (`bash`, `python`, `nasm`)

### Commit messages

```
Pod <N>: <surface or capability> — <one-line decision summary>

<optional 2-5 line body explaining the decision's empirical landing>

Closes #<issue> (if applicable)
```

The Pod prefix is mandatory for substrate-touching commits. Polish-tier commits use `Polish: <description>`. Each pod's final commit is the SEAL commit, which **must** include the substrate sha in the commit message body for empirical anchoring.

---

## Doctrine grammar

Doctrines are numbered globally:

- **D1.X** — substrate plumbing era (Pods 1.x)
- **D2.X** — Babylon spatial-merge era (Pods 2.x)
- **D3.X** — Embedding + Maid V1.0 era (Pods 3.x)
- **D4.X** — V1.0 SHIP polish-layer era (Pod 4.0.x)

Each doctrine has a name (after the em-dash) that describes its claim in one phrase: *D3.14 — Cosine canonical Form A; bit-exact load-bearing*. Cite by doctrine number in code comments and decision records. The numbering is monotonic; new doctrines append at the next available number within the era.

When a doctrine evolves (rather than being replaced), the original number stays and the evolution is noted in the original doctrine's home decision record (e.g., D3.14 picked up a "Form A non-guarantee extension at HALT 2B" sub-doctrine in the same pod that landed it).

When a doctrine is superseded, the new doctrine cites the old: *D2.1.1 — Cop renamed to Babylon (canon supersession)*. The old doctrine isn't erased; the canon-evolution trail is preserved.

---

## What doesn't land

- **Speculative features** without an empirical anchor (a canary verifying the design works)
- **Refactors that change substrate sha** without a doctrine landing the rationale
- **Comments that explain what code does** (well-named identifiers do that; cite **why** when non-obvious)
- **Backwards-compatibility shims** during V1.0 development — clean breaks are the substrate's privilege
- **Floating-point ops outside Form A canonical order** (D3.14)
- **NASM `[rel sym + reg*scale]` accesses** (D3.37 — silently miscompiles)
- **Doctrines retroactively renamed**, which would invalidate every prior citation
- **Polish-tier code under `boot/` / `surfaces/` / `tools/`**, which would violate D4.1

---

## License

License selection is deferred until V1.0 public flip. Likely candidates: MIT, Apache-2.0, or a custom permissive license. The substrate's hand-written nature means there is **no third-party code under non-permissive license** to worry about — `boot/` is pure original NASM; `tools/atreyu_x86.py` is pure original Python; `polish/` uses PIL + Pygame + FFmpeg (all permissive).

Contributors who land work post-V1.0-SHIP must agree to the chosen license at PR-merge time. Mythology naming follows fair-use literary reference; no commercial relationship with the Michael Ende estate is implied.

---

## How to start a contribution at V2.0

1. **Read** `RECONSTITUTION.md` (the V1.0+ canon) + `ROADMAP.md` (the V2.0 plan) + `DEFERRED.md` (the carry-forward list).
2. **Pick a deferral item** from DEFERRED.md or propose a new surface aligned with the trinity (Cop / Interpreter).
3. **Open a recon issue** describing the design space + open questions before any code lands.
4. **Wait for architect HALT 1** — a doctrine-grade ratification of what will and won't land.
5. **Implement in chunks**, with a canary at each chunk close.
6. **Submit one PR per pod**, with the pod's decision record included and three-oracle verification in the PR description.

The substrate is small (25.4 KB) and entirely auditable; the discipline is high but well-documented. A motivated contributor can ramp up by reading `recon/` in chronological order over a weekend.

---

## Where to ask questions

V1.0 SHIP-era contact: GitHub Issues at <https://github.com/RandolphPelican/codebook/issues>. The repo is single-architect at V1.0; expect response latency measured in days, not hours.

Reach the architect directly: see [README.md](README.md#license--author).

---

*Every opcode declares its cost. Every grant declares its parent. Every doctrine declares its scope. Every PR cites the doctrine.*
