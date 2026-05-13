# r/osdev post — CodebookOS V1.0

## Title

CodebookOS V1.0 — typed-primitive substrate with capability-tokenized I/O and energy-accounted opcodes, ~25 KB hand-written NASM x86_64 UEFI

## Body

I've been building a small bare-metal OS over the last three months and just sealed V1.0. Posting here because I think this audience will appreciate the architectural choices over the headline numbers.

**The substrate (`boot/` directory, pure x86_64 NASM, ~25.4 KB non-zero bytes):**

Five typed primitive pools, each pre-allocated:

- **Sign** (256 slots) — declaration objects with embedding_handle to typed Embedding pool
- **Energy** (256 slots) — non-renewable metabolic-budget primitive
- **Outcome** (4096 slots) — tagged `Ok<T> | Err` with `value_type_id` discriminant + 32-byte error context
- **Cap** (256 slots) — capability tokens with SipHash-2-4 MAC over 6 u64 fields; bitmap-typed authority; tree rooted at ROOT_CAP with subset-on-grant
- **Embedding** (2048 slots) — 384-dim f32 vectors (matches all-MiniLM-L6-v2 dim) with MAC over the full 1,536-byte body

**Energy accounting at the opcode level:**

Each opcode in the dispatch table has a documented joule cost (`boot/energy_costs.asm`). The VM decrements an active-budget register (r14) at each fetch; depletion HALTs gracefully. Costs are anticipated-worst-case static prices, not measured machine work — chose this over per-pod re-tuning because (a) the substrate stays predictable, (b) user-program budgets never undershoot, (c) empirical observability emerges from cost-table internal consistency without needing measurement infrastructure.

A Fibonacci canary makes this empirical: iterating fib(2)..fib(12) consumes 87..407 joules cumulatively, ~28-36j per iteration, predictable accumulation.

**Capability-tokenized I/O surface:**

Every CBS program → substrate interaction goes through one opcode (`OP_USE_CAP`, 0x91) with one of four V1.0 capability tokens:

- `CAP_AURYN_DISPLAY` (0xCA000001) — framebuffer
- `CAP_GMORK_CONIN` (0xCA000002) — non-blocking keyboard read
- `CAP_MORLA_FS` (0xCA000003) — filesystem
- `CAP_ROCKBITER` (0xCA000004) — energy introspection (budget / used)

V2.0 surfaces add new tokens, not new opcodes. The dispatch table for capabilities is a flat enum keyed by token. This is doctrine D4.2 in the corpus.

**The language (CBS):**

Custom compiler (`tools/atreyu_x86.py`, ~4,200 lines Python), custom stack-VM (`boot/cbs_vm.asm`, ~3,900 lines NASM), ~200 opcodes. AST is the canonical authoring path at V1.0; the substrate also includes a self-hosted parser chain (`surfaces/parser.cbs` + `surfaces/lexer.cbs`) but the AST path is what the 6 canary demos use.

**F32 byte-exact determinism (D3.12 + D3.14):**

SSE-scalar single-precision only — no x87 80-bit, no AVX2 reorderings under user control, just movss/mulss/addss. Cosine evaluation uses Form A canonical accumulation order; same input vector produces the same f32 bit pattern across runs, builds, and architectures (when ported). The vector-composer canary (B55) demonstrates this with a 4-step chain whose final orthogonal-projection dot-product is byte-exact 0.0.

**Methodology — chunked pods:**

Every architectural change goes through a pod: recon → HALT 1 architectural ratification (doctrines codified before code lands) → execution chunks (each with a canary at chunk close) → SEAL (decision record + three-oracle commit). 44 doctrines through V1.0 SEAL; the corpus is the substrate's audit trail. Decision records live in `recon/`.

**Subtle catches that landed as doctrine:**

- **D3.37** — NASM `-f bin` silently miscompiles `[rel sym + reg*scale]`; correct form is `lea reg, [rel sym]; [reg + idx*scale]`. Caught via a six-probe diagnostic chain in Pod 3.9; codified so it never has to be caught again.
- **D3.40** — Hybrid IEEE-degeneracy convention: zero-norm vectors and clean-cancellation regimes both fold to byte-exact 0.0; documented as canonical so orthogonality tests are reliable across implementations.

**Two-build determinism preserved across 16+ substrate-pod chunks.** V1.0 SEAL contract sha `c9923b8cf9fb6caf4c195e2d0d0ea2ed4a8e51e4e9f827b1fc24dd0b28c1d900` is empirically anchored at every chunk close.

**What's V1.0 vs V2.0:** V1.0 ships one pillar of a three-pillar cognitive trinity (Maid, the lexical-computation pole — six capabilities live). The other two pillars (Cop = capability inspector; Interpreter = text-to-bytecode runtime) are V2.0 carry-forward, framework-tested per the D3.43 deferral framework at activation time. Cap revocation, federation_total ripple, demod-tier surfaces (0xE8-0xEF row reserved), Falkor/Atreyu-editor/Rockbiter-scheduler as live surfaces — all V2.0.

**Demo video (90s):** {YOUTUBE_URL_TBD}

**Repo:** https://github.com/RandolphPelican/codebook

Happy to discuss the typed-primitive design, the cap framework, the F32 determinism canon, the cost-table conservative-pricing choice, or anything in the source. Specific architectural questions welcome — every decision has a doctrine number and a decision record citing the rationale.

---

## Tone notes

- Technical-depth audience; this subreddit appreciates concrete architectural detail over polish
- Lead with the typed-primitives + capability-tokenized I/O angle (most differentiating from typical hobby OSes)
- Anchor every claim to a doctrine number or a file path
- Mention the subtle NASM catch (D3.37) — r/osdev will appreciate the specific debugging story

## Posting tactics

- Mid-week, ~10am-2pm UTC (catches both EU and US morning)
- Engage with technical questions; ignore "why not write it in Zig" hot-takes
- Be ready to link to specific files when asked architectural questions

## Architect-only

Post when ready. TB cannot post.
