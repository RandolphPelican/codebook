# Pod 4.0.I Decision Record — Manifesto PDF + release artifacts + public-post drafts

**Chunk:** Pod 4.0.I — depth-doc manifesto PDF + USB image end-to-end verification + four public-post drafts (HN / r/osdev / r/programming / Twitter).
**Author:** Terminal Boy (Claude Opus 4.7)
**Date:** 2026-05-12
**Entry HEAD:** `2611c8508b4352e3948cbeed2373471e5a665eee` (Pod 4.0.H — Documentation pass)
**V1.0 SEAL substrate contract:** `c9923b8cf9fb6caf4c195e2d0d0ea2ed4a8e51e4e9f827b1fc24dd0b28c1d900` (**UNCHANGED** — D4.1 byte-lock holds; 10th consecutive chunk)

---

## D4.6 — Release-artifact discipline doctrine

**Landed at this SEAL.** Documents the V1.0 SHIP release-artifact contract.

**The discipline:**

1. **Every release artifact is honest about what it is.** No aspirational claims. The manifesto cites measured anchors (25.4 KB / 44 doctrines / 6 canary demos / V1.0 SEAL sha). The 90s demo video shows real canary PNGs from real substrate runs, framed Ken Burns + subtitle. The USB image is the canonical build; the SHA256SUMS file (Pod 4.0.J) certifies integrity at flip-time.
2. **No aspirational claims in release notes.** V1.0 ships exactly what's built. V2.0 carry-forward items are framework-tested per D3.43 at activation time. The drafts document V1.0/V2.0 status honestly per surface.
3. **Checksums file for verification.** SHA256SUMS (Pod 4.0.J) covers every artifact in `release/`. Downloaders verify against the published file.
4. **Manifesto targets the depth-doc audience.** The 90s demo video is the breadth-doc; the manifesto PDF is the fortnight-auditor's companion. Two artifacts, two audiences, both honest.
5. **PDF engine: pragmatic.** Per the 4.0.C deferral allowance ("pick what works on the WSL2 environment"), this pod used `fpdf2` (pure-Python, no system deps) after probing showed pandoc/wkhtmltopdf/texlive all absent. Doctrine codifies the pragmatic-engine principle, not a specific binary.

**Why:** Release artifacts are the public-facing surface of the credential. They must not undermine the audit-anchored discipline that produced the substrate. Every claim in every artifact must be backed by a substrate-canon anchor (sha / doctrine number / canary PNG / measured byte count).

---

## Manifesto PDF — `release/codebookos_v1.0_manifesto.pdf`

**Path:** `release/codebookos_v1.0_manifesto.pdf`
**Engine:** `fpdf2` 2.8.7 (pure-Python; installed via `pip3 install --user --break-system-packages fpdf2`)
**Source:** `polish/build_manifesto.py` (~620 lines)
**Output:** 22 pages, 32.4 KB

**Structure:**

| Section | Content |
|---|---|
| Cover | Title + tagline + 6 measured anchors + author + repo URL |
| 1. What CodebookOS is | Executive summary + headline anchors + manifesto purpose |
| 2. The substrate | 5 typed primitives walked through (Sign / Energy / Outcome / Cap / Embedding) + Maid V1.0 capability table |
| 3. The language — CBS | Authoring model + capability-tokenized I/O + per-opcode cost-table excerpt |
| 4. Walked demonstration | B53 fib energy + B55 vector composer + B56 cap lifecycle + B57/B54/B58 summaries |
| 5. The doctrinal corpus | 44 + 8 codified decisions; load-bearing doctrines per era (D1.X / D2.X / D3.X / D4.X) |
| 6. The build methodology | Chunked pods: Recon → HALT 1 → execution chunks → canary → SEAL |
| 7. Empirical verification | Two-build determinism + F32 byte-exact + pool sizing + cost-table empirical anchoring |
| 8. The polish layer | D4.1 separation + byte-lock chain |
| 9. V1.0 SEAL — honest scope | V1.0 vs V2.0 per surface + "what V1.0 is NOT" + "what V1.0 IS" |
| 10. The mythology | Surface-name → role table; load-bearing engineering scaffolding |
| 11. What was learned | 5 lessons distilled from the build |
| 12. Repository reference | Reading-order for fortnight-audit |
| Closing | Quote + author block |

**Verification:**
- ✓ File exists at expected path
- ✓ 22 pages (target was 20-40)
- ✓ 32.4 KB (compact; pure-text PDF without embedded fonts inflation)
- ✓ Cover page references V1.0 SEAL sha `c9923b8c…`
- ✓ Cross-references match repo state (44 doctrines, 6 canary demos, etc.)

**Why fpdf2 rather than pandoc → LaTeX/wkhtmltopdf:**
- Pandoc not installed; no architect appetite to fight LaTeX (per 4.0.C deferral)
- fpdf2 is pure-Python (zero system dependencies)
- Pure-Python rendering means full layout control (cover / headers / footers / tricolor accent line / page numbers)
- Non-Latin-1 typographical chars (em-dash, en-dash, curly quotes) auto-stripped to ASCII at build time via a one-shot helper

---

## USB image end-to-end verification

**Image:** `build/codebook.img` (67,108,864 bytes; FAT32 with EFI/BOOT/BOOTX64.EFI)
**Substrate sha:** `c9923b8cf9fb6caf4c195e2d0d0ea2ed4a8e51e4e9f827b1fc24dd0b28c1d900` (canonical V1.0 SEAL)

### Verification path

**Step 1 — Headless liveness probe** (`bash test_qemu.sh --headless`):
```
=== CodebookOS QEMU Smoke Test ===
OVMF: /usr/share/OVMF/OVMF_CODE.fd
IMG:  /mnt/c/Users/Rando/codebook/build/codebook.img
Headless mode: 8-second liveness probe...
PASS: VM alive at t+8s (in event loop)
```
Substrate boots cleanly through UEFI + reaches the event loop. No early-boot crash, no firmware refusal.

**Step 2 — End-to-end CBS demo execution** (`bash tools/pod35_canary_test.sh test_pod40f_b53_fib_energy pod40i_verify_b53_fib`):
- Boot UEFI → OVMF → BOOTX64.EFI
- Substrate initializes (capability/sign/energy/outcome/embedding pools; ROOT_CAP MAC-verified at boot)
- Bastian (home screen) renders
- Auto-sendkey '2' enters Gmork terminal
- Auto-type `load test_pod40f_b53_fib_energy.cbc<Enter>`
- Substrate dispatches CBS bytecode; B53 demo runs through full fib(0)..fib(12) trace
- Framebuffer captured: `build/pod40i_verify_b53_fib.png` (14,059 bytes)
- QEMU exits cleanly

**Step 3 — Post-canary substrate sha verification:**
```
c9923b8cf9fb6caf4c195e2d0d0ea2ed4a8e51e4e9f827b1fc24dd0b28c1d900  build/BOOTX64.EFI
```
Substrate sha unchanged post-canary. Canonical V1.0 SEAL preserved.

### What this proves

| Surface | Verified at Pod 4.0.I |
|---|---|
| UEFI boot path | ✓ — substrate enters event loop within 8s |
| Bastian home screen | ✓ — auto-sendkey reaches it; renders for >8s |
| Gmork shell | ✓ — accepts `load` command; reads from FAT32 root |
| Morla filesystem (read) | ✓ — `load <file>.cbc` resolves against image FS |
| CBS VM dispatch | ✓ — full Fibonacci trace executes |
| Auryn framebuffer | ✓ — output renders to display; PNG captures it |
| Rockbiter energy introspection | ✓ — energy budget printed in trace |
| Capability framework | ✓ — every opcode dispatched under ROOT_CAP authority |

Real-hardware boot test is architect-executed if/when he gets to it. **QEMU end-to-end is sufficient for 4.0.I SEAL** per architect framing.

### Verification artifact

`build/pod40i_verify_b53_fib.png` (14,059 bytes) — empirical framebuffer capture from this end-to-end run. Cited in the decision record as the canary PNG anchoring this pod's verification claim.

---

## Public-post drafts — `drafts/`

| Draft | Lines | Audience | Tone |
|---|---:|---|---|
| `hn_post.md` | 54 | Hacker News (broad technical audience) | Architectural-truth; measured anchors do the selling; no "next Linux" overclaim |
| `reddit_osdev.md` | 82 | r/osdev (technical-depth audience) | Concrete architectural detail; typed-primitives + cap-tokenized-I/O + F32 determinism angles |
| `reddit_programming.md` | 89 | r/programming (broader audience) | Lessons-learned framing; 5 distilled lessons from the build; not prescriptive |
| `twitter_thread.md` | 105 | Twitter/X | 8-tweet thread; one credential anchor per tweet; demo video as primary asset |

**All four drafts:**
- Reference the demo video URL via `{YOUTUBE_URL_TBD}` placeholder (architect substitutes at Pod 4.0.J or post-flip)
- Cite the V1.0 SEAL sha `c9923b8c…` for audit-anchoring
- Honestly frame V1.0 vs V2.0 scope (one pillar of cognitive trinity complete)
- Include "Tone notes" section describing voice + framing decisions
- Include "Posting tactics" section with timing + engagement strategy
- Close with "Architect-only" note: TB cannot post; architect publishes on his own timeline

**Architect publishes when ready.** TB does not post to any platform (per D4.7 public-repo-flip discipline anticipation — TB self-execution of platform actions is prohibited; only repo-local artifacts get TB-prepared).

---

## Catch profile

- **Build-time catches**: 0
- **Substrate catches**: 0 (no substrate edits)
- **Polish-tier catches**: **2 minor, both resolved same chunk**:
  1. fpdf2's helvetica is Latin-1 only; em-dashes / curly quotes / arrows in source caused `FPDFUnicodeEncodingException`. Resolved by writing a one-shot ASCII-fix helper (`tools/_ascii_fix.py`) and applying it to `polish/build_manifesto.py`; helper deleted after use.
  2. WSL2 has no pandoc / wkhtmltopdf / weasyprint / texlive installed. Resolved by switching to `pip3 install --user --break-system-packages fpdf2` (pure-Python, no system deps).
- **Architect-framing-corrections**: 0

D3.44 catch-surface-migration prediction holds: polish-tier work catches at the polish tier (tooling pragma + Unicode-encoding catches); no bleed to substrate or inheritance tiers.

---

## D4.1 byte-lock empirical chain — pre/post Pod 4.0.I

Pre-pod: `c9923b8cf9fb6caf4c195e2d0d0ea2ed4a8e51e4e9f827b1fc24dd0b28c1d900`
Post-pod: `c9923b8cf9fb6caf4c195e2d0d0ea2ed4a8e51e4e9f827b1fc24dd0b28c1d900`

**10th consecutive chunk** with substrate sha invariant under polish-tier work. The byte-lock is now a firmly-established empirical discipline through Pod 4.0.A → 4.0.I.

---

## Substrate state at Pod 4.0.I SEAL

- BOOTX64.EFI sha: `c9923b8cf9fb6caf4c195e2d0d0ea2ed4a8e51e4e9f827b1fc24dd0b28c1d900` (**UNCHANGED**)
- Two-build determinism: preserved (substrate untouched)
- All 37 prior + 6 Pod 4.0.F canaries: deductive equivalence (substrate untouched)
- New canary artifact at Pod 4.0.I: `build/pod40i_verify_b53_fib.png` (B53 end-to-end re-verification against canonical USB image)
- D4.1 byte-lock empirical chain: **10 consecutive chunks** (Pod 4.0.C, D, E, F partial, F.7, F.8, F.9, F SEAL, G, H, I)

---

## Files landed at Pod 4.0.I

```
polish/build_manifesto.py                         ~620 lines  (new; fpdf2 orchestrator)
release/codebookos_v1.0_manifesto.pdf             32.4 KB     (new; 22 pages)
drafts/hn_post.md                                 54 lines    (new)
drafts/reddit_osdev.md                            82 lines    (new)
drafts/reddit_programming.md                      89 lines    (new)
drafts/twitter_thread.md                          105 lines   (new)
build/pod40i_verify_b53_fib.png                   14,059 b    (canary verification artifact)
recon/POD4.0I_DECISION_RECORD.md                  this file
```

---

## New doctrines landed at Pod 4.0.I

**D4.6 — Release-artifact discipline.** (Codified above.)

---

## Pod 4.0 progress

| Sub-pod | Status |
|---|---|
| 4.0.A sit + plan | DONE |
| 4.0.B V1.0 SEAL closeout | DONE (`v1.0-seal` tag) |
| 4.0.C wrapper tooling spike | DONE |
| 4.0.D boot anim + About demo | DONE |
| 4.0.E in-fiction surface mocks | DONE |
| 4.0.F real CBS demos suite (6/6 PASS) | DONE |
| 4.0.G demo video composition | DONE |
| 4.0.H documentation pass | DONE |
| **4.0.I manifesto PDF + release artifacts + drafts** | **DONE (this commit)** |
| 4.0.J V1.0 SHIP — public flip | pending |

---

## Headline moment

**The V1.0 SHIP credential is now distribution-ready.**

- **Substrate** — boot/, surfaces/, tools/ — locked at V1.0 SEAL sha `c9923b8c…` since Pod 3.12. The credential itself.
- **90-second demo video** — `polish/dist/codebookos_v1.0_demo.mp4`. The breadth-doc.
- **22-page manifesto PDF** — `release/codebookos_v1.0_manifesto.pdf`. The depth-doc.
- **USB image end-to-end verified** — `build/codebook.img` boots in QEMU, runs B53 fib-energy demo, exits clean.
- **5 public-facing docs at repo root** — README + GETTING_STARTED + CBS_LANGUAGE + ARCHITECTURE + CONTRIBUTING (Pod 4.0.H).
- **4 public-post drafts** — HN + r/osdev + r/programming + Twitter, all ready-to-post when architect chooses to publish.

What remains for V1.0 SHIP: stage `release/` (Pod 4.0.J), write SHA256SUMS + RELEASE_NOTES.md, draft the `v1.0-ship` tag message, write the pre-flip checklist, and SEAL. After that, V1.0 SHIP is architect-action-only: GitHub Settings → Visibility → Public, push the `v1.0-ship` tag, upload `release/` to GitHub Releases, post the drafts on his cadence.

Standing by for **Pod 4.0.J** — V1.0 SHIP staging.
