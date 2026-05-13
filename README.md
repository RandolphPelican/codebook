# CodebookOS

A 64KB-class bare-metal operating system with its own programming language. Pure x86_64 NASM UEFI. No borrowed code.

```
25.4 KB hand-crafted NASM substrate
44 codified architectural doctrines
6 canary-verified CBS demonstration programs
Built solo in 30 architect-hours across 3 months
```

V1.0 SEAL contract sha: `c9923b8cf9fb6caf4c195e2d0d0ea2ed4a8e51e4e9f827b1fc24dd0b28c1d900`
V1.0 SEAL tag: [`v1.0-seal`](https://github.com/RandolphPelican/codebook/releases/tag/v1.0-seal)

📺 **Demo video (90s):** {YOUTUBE_URL_TBD}

---

## What this is

CodebookOS is two things wrapped in one repository:

1. **An operating system.** Pure x86_64 NASM UEFI. Boots in QEMU; flashes to USB. Five typed primitives — Sign / Energy / Outcome / Cap / Embedding — each with SipHash-2-4 MAC integrity. Every opcode has a documented cost in joules. Two-build determinism across a 16-pod substrate-evolution sequence.

2. **A programming language.** CBS — custom bytecode + custom compiler (`tools/atreyu_x86.py`) + custom stack-VM (`boot/cbs_vm.asm`). Lexer, parser, AST emitter, ~200 opcodes, energy-accounted dispatch. Demonstrably working: six canary programs validate the full surface at byte-exact precision.

The substrate is auditable in a fortnight by a competent reviewer. Every architectural decision is codified as one of 44 doctrines in `recon/`. The polish layer (boot animation, About demo, demo video) is Python; the credential is the NASM. The boundary is **`boot/` + `surfaces/` + `tools/`** (credential) vs **`polish/`** (showroom) — auditable on first inspection.

---

## Quickstart (5 commands, ~5 minutes)

```bash
git clone https://github.com/RandolphPelican/codebook.git
cd codebook
sudo apt install nasm mtools dosfstools qemu-system-x86 ovmf   # Ubuntu/Debian
./build.sh
./test_qemu.sh
```

QEMU opens. You see Bastian (the home screen). Press `2` to enter Gmork (the shell). Type `help` for command list.

Full hands-on guide: [GETTING_STARTED.md](GETTING_STARTED.md).

---

## The credential

| Anchor | Empirical value | Reference |
|---|---|---|
| Substrate size | 26,031 non-zero bytes (~25.4 KB) | `wc -c < BOOTX64.EFI` after zero-stripping |
| Codified doctrines | 44 architectural decisions through V1.0 SEAL | `recon/POD*_DECISION_RECORD.md` |
| Demonstrated capabilities | 6 CBS programs canary-verified | `surfaces/test_pod40f_b5*.cbc` |
| Two-build determinism | preserved across 16-pod substrate sequence | sha verified at every chunk SEAL |
| Built solo | 30 architect-hours, April-May 2026 | git log |

The Maid V1.0 capability surface (the lexical-computation pole of the substrate's planned cognitive trinity) is complete:

| Surface | Pod | Capabilities |
|---|---|---|
| Housekeeper | 3.5 | cosine + dot + L2 + lookup_top1 + sign_handle |
| Composer | 3.6 | add + subtract + scale + normalize + lerp + synthesis_handle |
| Importer | 3.8 | boot_ingest_codebook + imported_handle |
| Finder-of-many | 3.9 | lookup_top_k with threshold |
| Orthogonalizer | 3.10 | project + reject |
| Maintainer | 3.11 | codebook_meta |

---

## What's V1.0 vs V2.0

| Surface | V1.0 status | V2.0 carry-forward |
|---|---|---|
| Substrate (5 typed pools) | ✅ Complete | — |
| Maid V1.0 (6 capabilities) | ✅ Complete | — |
| CBS language + compiler + VM | ✅ Complete | — |
| Capability framework (grant / use / lineage) | ✅ Complete | cap_revoke; federation_total; spatial-merge ripple |
| Codebook ingestion (boot-time + read surface) | ✅ Complete | Runtime IMPORT (#91); multi-codebook |
| Stream-stability / aggregation ops | ❌ Deferred | #92 — Result[T] sixth pool if production demand |
| Cop (capability inspector) — trinity pillar 2 | ❌ Deferred | V2.0 |
| Interpreter (text-to-bytecode runtime) — trinity pillar 3 | ❌ Deferred | V2.0 |
| Demod-tier surface (0xE8-0xEF reserved) | ❌ Deferred | V2.0 |
| Falkor / Atreyu / Rockbiter as live surfaces | ❌ Deferred (in-fiction mocks in `polish/`) | V2.0 |

V1.0 honestly ships what's built; V2.0 carry-forward items framework-tested per **D3.43 V1.0-deferral framework** at activation time.

---

## How it's structured

```
boot/             Substrate (NASM x86_64 UEFI)              — CREDENTIAL
  ├── boot.asm    PE32+ entry + boot init
  ├── cbs_vm.asm  Stack-VM + dispatch + per-opcode handlers  (~3,900 lines)
  ├── maid.asm    Maid V1.0 compute helpers                  (~700 lines)
  ├── cap.asm     Capability primitives + SipHash MAC
  └── ...         37 NASM source files total
surfaces/         CBS bytecode demos (.cbc compiled)         — CREDENTIAL
  └── test_pod40f_b53..b58 — 6 canary-verified demonstrations
tools/            Build tools (Python; not at runtime)       — CREDENTIAL infra
  ├── atreyu_x86.py — CBS compiler (~4,200 lines)
  └── pod35_canary_test.sh — substrate-canary harness
polish/           Python showroom layer (D4.1 separation)    — POLISH
  ├── boot_anim.py / about_codebookos.py
  ├── falkor_browser.py / atreyu_editor.py / rockbiter_scheduler.py
  ├── build_demo_video.py — 90s master video composer
  └── dist/ — rendered MP4 artifacts
recon/            Architectural decision records             — CREDENTIAL doctrine
  └── 44 D3.X doctrines through V1.0 SEAL + 6 D4.X doctrines through V1.0 SHIP
build/            Build artifacts (BOOTX64.EFI + canary PNGs)
```

Read [ARCHITECTURE.md](ARCHITECTURE.md) for the doctrinal depth tour.

---

## Documentation map

- **[README.md](README.md)** — this file; the front door
- **[GETTING_STARTED.md](GETTING_STARTED.md)** — hands-on: clone → build → boot → Gmork → CBS demo, in 10 minutes
- **[CBS_LANGUAGE.md](CBS_LANGUAGE.md)** — language reference; syntax + opcode cost table + walked demo examples
- **[ARCHITECTURE.md](ARCHITECTURE.md)** — doctrinal depth; mythology + typed primitives + 44-doctrine corpus + polish-vs-credential separation
- **[CONTRIBUTING.md](CONTRIBUTING.md)** — collaborator-facing: pod methodology + writing a CBS demo + extending substrate + style notes

Additional canon at the repo root: [RECONSTITUTION.md](RECONSTITUTION.md) (v11 manifesto, post-V1.0-SEAL), [ROADMAP.md](ROADMAP.md), [DEFERRED.md](DEFERRED.md), [RECON_PROTOCOL.md](RECON_PROTOCOL.md), [ARCHAEOLOGY.md](ARCHAEOLOGY.md).

---

## Why this exists

The substrate is the credential. The polish makes the credential visible. The demo video shows it works in 90 seconds; the repo lets you audit every byte over a fortnight.

If you want to build a surface, extend CBS, port the trinity, or just understand how an operating system is actually built from bytes upward — **clone, audit, contribute**.

> *Every opcode declares its cost. Every grant declares its parent. Every doctrine declares its scope.*

---

## License + author

Built by Randolph Pelican III / StableTech Enterprises LLC. License TBD before public flip; details in [CONTRIBUTING.md](CONTRIBUTING.md#license).

Mythology naming honors *The Neverending Story* (Bastian, Atreyu, Falkor, Gmork, Auryn, Rockbiter, Morla, Koreander, Southern Oracle, Artax, Empress). Architectural decisions named after the Maid (lexical-computation pole, V1.0 complete) and Babylon (spatial-merge metabolism); the trinity completes at V2.0 with Cop + Interpreter.
