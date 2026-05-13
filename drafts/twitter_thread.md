# Twitter / X thread — CodebookOS V1.0

## Thread (8 tweets)

---

**1/8**

I built a bare-metal OS with its own programming language.

25.4 KB of hand-written x86_64 NASM UEFI assembly. Boots in QEMU; flashes to USB. 6 canary-verified demo programs in a custom language with a custom compiler and stack-VM.

Solo. 30 hours. 3 months.

📺 {YOUTUBE_URL_TBD}

---

**2/8**

Five typed primitive pools: Sign / Energy / Outcome / Cap / Embedding. Each MAC-protected where applicable. Each in its own pre-allocated pool.

Every opcode in the custom language declares its cost in joules. The VM enforces an energy budget at every dispatch. Depleted budget → graceful HALT.

---

**3/8**

Capabilities from layer 1. ROOT_CAP at cap_id=1 with unbounded budget; child caps forged via cap_new with subset-on-grant semantics. SipHash-2-4 MAC over six u64 fields per cap.

The substrate cannot execute beyond a cap's authorized budget. There is no privileged escape hatch.

---

**4/8**

F32 IEEE 754 byte-exact determinism. SSE-scalar single-precision only — no x87 80-bit, no AVX2 reorderings, just movss/mulss/addss in canonical Form A evaluation order.

Same input vector → same f32 bit pattern across runs, builds, and architectures (when ported).

---

**5/8**

44 codified architectural doctrines. Every decision lives as a numbered entry in `recon/POD*_DECISION_RECORD.md` with rationale, alternatives considered, and empirical evidence that ratified it.

The doctrine corpus is the substrate's audit trail. None were reversed.

---

**6/8**

Two-build determinism preserved across 16+ substrate-evolution pods.

V1.0 SEAL contract sha:
`c9923b8cf9fb6caf4c195e2d0d0ea2ed4a8e51e4e9f827b1fc24dd0b28c1d900`

Empirically anchored at every commit. Not aspirational; measured.

---

**7/8**

The substrate is auditable in a fortnight by a competent reviewer.

Six canary CBS demos exercise the full surface:
- Fibonacci with per-iteration energy trace
- 5-doctrine vector composition with byte-exact orthogonality
- Capability lifecycle
- Press-X interactive
- Top-K semantic similarity
- F32 drift anchor

---

**8/8**

CodebookOS V1.0 is one pillar of a planned cognitive trinity (Maid, the lexical-computation pole). The other two (Cop = capability inspector, Interpreter = text-to-bytecode runtime) carry forward to V2.0 framework-tested per the deferral discipline.

🔗 github.com/RandolphPelican/codebook

---

## Tone notes

- One credential anchor per tweet
- Demo video link in tweet 1 as primary asset (highest engagement on visual content)
- Numerical anchors front-and-center (25.4 KB / 44 doctrines / 6 demos / 30 hours / V1.0 SEAL sha)
- No hashtags in body; consider adding #osdev #nasm #x86_64 at thread end if architect prefers
- Avoid "the next Linux" / "rewrite of X" framing

## Optional 9th tweet — for engagement

If thread takes off, add a closing tweet linking to ARCHITECTURE.md and inviting questions: "Doctrinal depth + reading order + load-bearing decisions: [link to ARCHITECTURE.md]. Happy to discuss any architectural choice."

## Posting tactics

- Best time: Tuesday-Thursday, ~9-11am ET
- Post thread as a single batch (use Twitter's thread-builder); don't space out tweets
- Pin the thread on the architect's profile if relevant
- Demo video embed in tweet 1 — Twitter's auto-play boosts engagement

## Architect-only

Post when ready. TB cannot post.
