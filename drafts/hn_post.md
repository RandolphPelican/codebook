# Hacker News post — CodebookOS V1.0

## Title

CodebookOS – a 25.4 KB bare-metal x86_64 OS with a custom language (NASM)

## URL

https://github.com/RandolphPelican/codebook

## Body (optional — Show HN posts can include this in the first comment)

CodebookOS is a bare-metal operating system I built in 30 hours across three months, entirely in hand-written x86_64 NASM UEFI assembly. It boots in QEMU, flashes to USB, and runs six byte-exact-verified programs written in its own custom programming language (CBS). No borrowed code. No linker. No C. No gnu-efi.

Some measured anchors:

- **25.4 KB** of non-zero substrate bytes in the EFI binary
- **44 codified architectural doctrines** through V1.0 SEAL, each preserved as a decision record in the repo (`recon/POD*_DECISION_RECORD.md`)
- **6 canary-verified CBS demonstration programs** covering the full Maid V1.0 capability surface (Fibonacci with per-iteration energy trace; 5-doctrine vector composition with byte-exact orthogonality; capability lifecycle; interactive press-X with non-blocking keyboard polling; top-K semantic similarity against a boot-time-ingested codebook; F32 drift anchor)
- **Two-build determinism preserved** across 16+ substrate-evolution pods; V1.0 SEAL contract sha `c9923b8c…` byte-locked across the entire polish/SHIP arc

The substrate is built around **five typed primitives** (Sign / Energy / Outcome / Cap / Embedding), each in its own pre-allocated pool, each with SipHash-2-4 MAC protection where applicable. Every opcode declares its cost in joules; the VM decrements an energy budget at each dispatch; depletion HALTs gracefully. Capabilities are enforced from layer 1 — ROOT_CAP at cap_id=1 with subset-on-grant semantics; the substrate cannot execute beyond a cap's budget.

The language (CBS) has a custom compiler (Python, ~4,200 lines) targeting a custom stack-VM (NASM, ~3,900 lines) with ~200 opcodes. F32 IEEE 754 byte-exact determinism is preserved via Form A canonical evaluation order — same input vector produces the same f32 bit pattern across runs, builds, and architectures when ported.

The substrate is auditable in a fortnight by a competent reviewer. I think that's the interesting claim: not "look how fast it runs" but "look how small it stays, and how every decision is preserved."

V1.0 ships one of three planned cognitive-trinity pillars complete (Maid, the lexical-computation pole). The other two — Cop (capability inspector) and Interpreter (text-to-bytecode runtime) — carry forward to V2.0 framework-tested per the deferral discipline.

📺 **90-second demo video:** {YOUTUBE_URL_TBD}

Happy to discuss the methodology, the doctrinal corpus, or anything in the source. The repo includes a full architecture doc (`ARCHITECTURE.md`) and a contributor guide that documents the chunked-pod methodology that produced the substrate.

Not "the next Linux." Just a small disciplined OS with its own language, built as a credential and documented as an audit trail.

---

## Tone notes

- No marketing-speak; let the measured anchors do the selling
- Frame as a credential / audit-anchored artifact, not a product
- Explicitly disclaim the "next Linux" overclaim
- Sub-2-minute read; one screen on a laptop

## Posting tactics

- Best time: Tuesday-Thursday, ~7-9am PT
- "Show HN:" prefix optional; the substrate-as-credential framing reads well without it
- First comment should preempt the "why not Rust?" / "why not POSIX?" questions with a short link to ARCHITECTURE.md
- Don't reply defensively to skeptics — let the substrate sha and the canary PNGs speak

## Architect-only

Post when ready. TB cannot post.
