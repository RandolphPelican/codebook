# r/programming post — CodebookOS V1.0

## Title

I built a bare-metal OS with its own language in 30 hours over 3 months — here's what was learned

## Body

CodebookOS is a small bare-metal operating system I built solo in ~30 architect-hours across April-May 2026. Pure x86_64 NASM UEFI assembly, 25.4 KB of substrate, with its own programming language (CBS) that has a custom compiler and stack-VM. Six canary-verified demonstration programs.

Sharing the lessons rather than the headline numbers, because the lessons are the more interesting thing for this audience.

---

### Lesson 1 — Codify decisions before implementing them

The build methodology was a "chunked pod" pattern. Every architectural change starts with a recon report (read the relevant source, identify the design space, list open questions). Implementation does not start until the architect ratifies the questions and the resulting doctrines are codified by number. Every pod ends with a decision record in `recon/` documenting what landed and why.

44 doctrines through V1.0; each has a number (D3.14, D2.2.5, etc.), each is cited at use in code comments, each carries the rationale for the decision. None had to be reversed.

The doctrines that landed empirically as substrate-catches were the ones where the implementation language was less forgiving than expected. Example: NASM `-f bin` silently miscompiles `[rel sym + reg*scale]` addressing — the correct form is `lea reg, [rel sym]; [reg + idx*scale]`. This took a six-probe diagnostic chain to find, then landed as D3.37 so it never has to be caught again. Codify, don't memorize.

### Lesson 2 — Anticipated worst-case is better than measured average

Every opcode in the language has a documented joule cost in the cost table. The VM decrements an energy-budget register at every dispatch; depletion HALTs gracefully. The costs are **anticipated worst-case static prices**, not measured machine work.

I considered per-pod cost-table re-tuning based on measurements. Rejected it. Reasons:
- Static pricing keeps the cost table small and the substrate predictable.
- User-program budgets never undershoot (the substrate could finish early but never exceed).
- Empirical observability emerges naturally — a Fibonacci canary makes per-iteration energy visible at user-program scale (~28-36 joules per iteration; predictable accumulation).
- Audit surface stays minimal: 200 opcodes × 1 cost number each, not 200 × N measurements.

Conservative pricing was the right call.

### Lesson 3 — Naming is a real engineering tool

The substrate surfaces are named after characters in *The Neverending Story*: Bastian (home screen), Atreyu (programming language), Falkor (web browser, V2.0), Gmork (terminal shell), Auryn (framebuffer), Morla (filesystem), Maid (lexical-computation surface — 6 capabilities live at V1.0), Babylon (federation accounting), and so on.

This isn't flavor. It's metonymy that the design discussion can use without ambiguity. "Add a Maid capability" is unambiguous; "add a vector-op capability" requires three sentences of context. Naming the architectural surface gives the team a one-word reference that compresses an entire design rationale.

I'd recommend this to any solo or small-team project: pick a consistent naming scheme that maps surface → semantic role, and stick with it. The substrate file `boot/maid.asm` is, at a glance, "the computation-pole NASM file." That's load-bearing.

### Lesson 4 — Two-build determinism is cheap and load-bearing

The substrate compiles to a byte-exact identical `BOOTX64.EFI` across two clean rebuilds. The build script verifies this at every commit. The V1.0 SEAL contract sha `c9923b8c…` is empirically anchored across 16+ substrate-evolution pods.

Cost: one extra `nasm + sha256sum` at every SEAL. Benefit: catches latent nondeterminism early; certifies that the substrate sha is a meaningful contract; lets every PR cite a verifiable artifact rather than aspirational stability.

Without two-build determinism, the V1.0 SEAL contract sha would be a hope. With it, the sha is a check.

### Lesson 5 — Separate the credential from the polish, and verify the separation

V1.0 SHIP shipped with a 90-second demo video, a boot animation, an "about" demo, and three in-fiction surface mocks (for surfaces that don't ship at V1.0). All of these live in `polish/` — Python, separated by directory and by discipline from the substrate.

The discipline (codified as doctrine D4.1): the substrate sha must not change during polish work. Verified at every Pod 4.0 chunk close. Nine consecutive polish-tier chunks have honored this. The polish can be deleted entirely and the substrate still builds, boots, and passes all canaries. This separation is real because it is measured.

I'd recommend this to anyone building a project where the artifact itself is the credential and the presentation needs to make it visible without compromising it.

---

**What CodebookOS is**: 25.4 KB of hand-written NASM that boots in QEMU, runs 6 byte-exact CBS demonstration programs, with 44 doctrines codifying every architectural decision. One pillar of a planned cognitive trinity (Maid, the lexical-computation pole) complete at V1.0; the other two (Cop = capability inspector; Interpreter = text-to-bytecode runtime) carry forward to V2.0.

**What it's not**: a general-purpose OS, a networked system, a multi-user system. No process scheduler, no virtual memory beyond what UEFI gives you, no syscall surface beyond the capability-tokenized I/O. Honest scope.

📺 **90-second demo video**: {YOUTUBE_URL_TBD}
🔗 **Repo**: https://github.com/RandolphPelican/codebook

The substrate is auditable in a fortnight by a competent reviewer. The repo includes the full architecture doc, the language reference, and a contributor guide that documents the chunked-pod methodology.

I'd be happy to discuss the methodology, the doctrinal corpus, the naming choices, or the cost-table-conservative-pricing decision in the comments.

---

## Tone notes

- r/programming is broader audience than r/osdev — frame as lessons learned, not a technical deep-dive
- Lead with "30 hours" because that's the most surprising/compressed number
- Keep architectural detail just enough to substantiate the lessons; link to the repo for depth
- Avoid "if you're a real engineer you should..." framing — the lessons are not prescriptive

## Posting tactics

- Mid-morning to early afternoon US/EU; r/programming is wider distribution than r/osdev
- Engage with discussion-style replies; skip arguments about language choice
- One detailed comment-reply pre-loaded for the inevitable "why not Rust?" / "why bother with NASM?" questions

## Architect-only

Post when ready. TB cannot post.
