# Pre-Flip Checklist — V1.0 SHIP

**Purpose:** Verification checklist before the architect executes the public-flip actions.
**Authority:** Architect-only execution; TB cannot perform any of the architect-only-action items.
**Doctrine:** D4.7 — Public-repo-flip discipline (landed at Pod 4.0.J SEAL).

---

## Repo-state verification (TB-verified at Pod 4.0.J SEAL)

### 1. No secrets in git history

**Check:**
```bash
git log --all -p | grep -iE "(api[_-]?key|password|token|secret)" | grep -v -E "^-|^\+\+\+|^---"
```

**Result at Pod 4.0.J SEAL:** Only word-occurrences in legitimate documentation contexts ("capability tokens", "substrate-secret bootstrap", "credential pitch", etc.). No actual credential strings, API keys, passwords, or secret tokens. ✓

**Check (file-existence pattern):**
```bash
git log --all --diff-filter=A --name-only | grep -iE "\.(env|key|pem|p12|pfx)$|credential|secret|password"
```

**Result at Pod 4.0.J SEAL:** No `.env`, `.key`, `.pem`, `.p12`, or `.pfx` files have ever been committed. ✓

### 2. All artifact paths resolve in docs

**Check:**
```bash
python3 -m pytest polish/test/test_docs.py -v
```

**Result at Pod 4.0.J SEAL (pre-flip):** 25/25 PASS (full 5-doc + relative-link + cross-doc consistency). ✓

(Note: re-run before flip; doc paths can drift if files are renamed between 4.0.J SEAL and the public-flip moment.)

### 3. v1.0-seal tag still points to canonical commit

**Check:**
```bash
git rev-parse v1.0-seal
```

**Expected:** `92e069c5b95bcc7d38d166be727221a2baf6ee02` (V1.0 SEAL closeout commit at Pod 4.0.B)
**Result at Pod 4.0.J SEAL:** Tag points to the expected commit. ✓

### 4. Substrate sha unchanged at V1.0 SEAL contract

**Check:**
```bash
sha256sum build/BOOTX64.EFI
```

**Expected:** `c9923b8cf9fb6caf4c195e2d0d0ea2ed4a8e51e4e9f827b1fc24dd0b28c1d900`
**Result at Pod 4.0.J SEAL:** Substrate sha matches V1.0 SEAL contract; D4.1 byte-lock holds for the 11th consecutive Pod 4.0 chunk. ✓

### 5. Drafts ready in `drafts/`

| Draft | Path | Status |
|---|---|---|
| HN post | `drafts/hn_post.md` | ✓ Ready (54 lines) |
| r/osdev post | `drafts/reddit_osdev.md` | ✓ Ready (82 lines) |
| r/programming post | `drafts/reddit_programming.md` | ✓ Ready (89 lines) |
| Twitter thread | `drafts/twitter_thread.md` | ✓ Ready (105 lines, 8 tweets) |

All four drafts include `{YOUTUBE_URL_TBD}` placeholder for the demo video URL. **Architect substitutes the real URL before posting.**

### 6. Release directory staged

| Artifact | Path | Status |
|---|---|---|
| USB image | `release/codebookos_v1.0.img` | ✓ 64 MB; copied from canonical `build/codebook.img` |
| Demo video | `release/codebookos_v1.0_demo.mp4` | ✓ 9.4 MB; 90.000000s; h264+yuv420p |
| Manifesto PDF | `release/codebookos_v1.0_manifesto.pdf` | ✓ 22 pages; 32.4 KB |
| Checksums | `release/SHA256SUMS` | ✓ sha256 over all three artifacts above |
| Release notes | `release/RELEASE_NOTES.md` | ✓ GitHub Releases page copy |
| Tag message | `release/v1.0-ship_TAG_MESSAGE.txt` | ✓ Annotated tag body |

### 7. v1.0-ship tag NOT pushed

**TB has NOT created or pushed the `v1.0-ship` tag.** The tag message is drafted in `release/v1.0-ship_TAG_MESSAGE.txt` for architect to use at flip-time.

**Check (must be empty):**
```bash
git tag -l v1.0-ship
git ls-remote --tags origin | grep v1.0-ship
```

**Result at Pod 4.0.J SEAL:** No `v1.0-ship` tag exists locally or remotely. ✓

### 8. Cross-document consistency

| Document | V1.0 SEAL sha cited | Quickstart? | Headline numbers consistent? |
|---|---|---|---|
| README.md | ✓ | ✓ (5-command) | ✓ (25.4 KB / 44 doctrines / 6 demos) |
| GETTING_STARTED.md | ✓ | ✓ | ✓ |
| CBS_LANGUAGE.md | ✓ | — | ✓ |
| ARCHITECTURE.md | ✓ | — | ✓ |
| CONTRIBUTING.md | ✓ | — | ✓ |
| RELEASE_NOTES.md | ✓ | ✓ | ✓ |
| Manifesto PDF | ✓ | — | ✓ |

All seven primary docs cite the V1.0 SEAL sha `c9923b8c…` consistently. Headline numbers (25.4 KB / 44 doctrines / 6 demos / 30 architect-hours) consistent across docs.

---

## Architect-only action checklist (post-Pod-4.0.J-SEAL)

**These actions are NOT performed by TB.** TB-performed actions stop at the Pod 4.0.J SEAL commit + push to main. The actions below are explicit architect-authorization-gate-only execution per **D4.7 Public-repo-flip discipline**.

### Step 1 — GitHub Settings → Visibility → Public

**One-way action.** Repo currently private. Going public is the public-flip moment.

- [ ] Navigate: https://github.com/RandolphPelican/codebook/settings
- [ ] Scroll to "Danger Zone" → "Change repository visibility"
- [ ] Click "Change visibility" → "Make public"
- [ ] Type the repo name to confirm
- [ ] Verify the public URL works in an incognito browser tab: https://github.com/RandolphPelican/codebook

### Step 2 — Push v1.0-ship annotated tag

```bash
git tag -a v1.0-ship -F release/v1.0-ship_TAG_MESSAGE.txt
git push origin v1.0-ship
```

- [ ] Tag created locally with annotated message from `release/v1.0-ship_TAG_MESSAGE.txt`
- [ ] Tag pushed to origin
- [ ] Verify in GitHub Releases interface: https://github.com/RandolphPelican/codebook/tags

### Step 3 — Upload release/ contents to GitHub Releases page

- [ ] Navigate: https://github.com/RandolphPelican/codebook/releases/new
- [ ] Select tag: `v1.0-ship`
- [ ] Release title: `CodebookOS V1.0 SHIP`
- [ ] Release description: paste contents of `release/RELEASE_NOTES.md`
- [ ] Attach binaries (drag-and-drop):
  - `release/codebookos_v1.0.img`
  - `release/codebookos_v1.0_demo.mp4`
  - `release/codebookos_v1.0_manifesto.pdf`
  - `release/SHA256SUMS`
- [ ] Mark as "Latest release" (checkbox)
- [ ] Publish

### Step 4 — Substitute demo video URL in drafts (one-time)

Architect should publish the demo MP4 to YouTube (or a CDN), then update the four draft files to replace `{YOUTUBE_URL_TBD}`:

```bash
# Once you have the URL:
sed -i 's|{YOUTUBE_URL_TBD}|https://youtu.be/YOUR_ID_HERE|g' drafts/*.md
```

Optional: commit the substitution as a post-flip `Polish:` commit if architect prefers a permanent record. Otherwise leave the drafts as-is (the public-post copies live outside the repo).

### Step 5 — Post to platforms on architect's cadence

The drafts are not gated to a specific timing. Architect publishes on his own schedule:

- [ ] **Hacker News** — paste `drafts/hn_post.md` body; Show HN prefix optional
- [ ] **r/osdev** — paste `drafts/reddit_osdev.md`
- [ ] **r/programming** — paste `drafts/reddit_programming.md`
- [ ] **Twitter/X** — paste `drafts/twitter_thread.md` as a thread

Each draft has its own "Posting tactics" section with recommended timing.

### Step 6 — (Optional) Real-hardware boot test

QEMU end-to-end was sufficient for V1.0 SHIP. Real-hardware boot test is a nice-to-have:

```bash
# Identify USB stick FIRST; replace sdX:
lsblk
sudo dd if=release/codebookos_v1.0.img of=/dev/sdX bs=4M status=progress oflag=sync
```

Then boot a UEFI-mode machine from the USB. Architect-executes when convenient; not required for V1.0 SHIP.

---

## Rollback considerations

**Flipping a repo from private to public is one-way at the platform level.** GitHub does NOT support flipping back to private without losing forks, stars, and watch state accumulated while public. **Treat the public-flip as irreversible.**

If a critical issue is found post-flip, the appropriate response is a **`v1.0.1` patch release** with the fix, **not** an attempt to "unship" V1.0. The substrate is byte-locked at `c9923b8c…`; the manifesto, docs, and demo video are immutable historical artifacts of what shipped.

**The `v1.0-seal` predecessor tag is permanent**: it documents the substrate canon-binding moment and should never be moved or deleted.

---

## D4.7 — Public-repo-flip discipline doctrine

**Lands at Pod 4.0.J SEAL.** Documents:

1. **One-way action.** GitHub Visibility → Public is permanent; treat as irreversible.
2. **Pre-flip checklist required.** This file (`recon/PREFLIP_CHECKLIST.md`) is the canonical pre-flip discipline.
3. **Explicit architect-authorization-gate-only execution.** TB cannot perform any platform-side action (GitHub Settings, tag push to remote outside of three-oracle SEAL workflow, GitHub Releases upload, social-media posts).
4. **No TB self-execution of platform actions.** TB-performed actions stop at the SEAL commit + repo-local push to `origin/main`. Everything platform-side (visibility flip, release-page upload, social posts) is architect-execute-only.
5. **Rollback acceptance.** Public-flip is treated as irreversible by design; mistakes are handled forward via `v1.0.1` patches, never via "unship" attempts.

**Why this discipline:** the substrate is the architect's; the public-flip moment is the architect's. Automation should not be able to make this call. The checklist exists so the flip is deliberate, not reflexive, and so every claim that goes public is verifiable against a substrate-canon anchor.

---

## Final state summary at Pod 4.0.J SEAL

| Surface | State |
|---|---|
| Substrate sha (V1.0 SEAL contract) | `c9923b8c…` UNCHANGED (D4.1 byte-lock; 11th consecutive chunk) |
| `v1.0-seal` tag | Points to `92e069c5…` (Pod 4.0.B closeout); preserved |
| `v1.0-ship` tag | NOT YET CREATED — architect creates at flip-time |
| Public docs at repo root | 5/5 present (README + GETTING_STARTED + CBS_LANGUAGE + ARCHITECTURE + CONTRIBUTING) |
| Demo video | `polish/dist/codebookos_v1.0_demo.mp4` + `release/codebookos_v1.0_demo.mp4` |
| Manifesto PDF | `release/codebookos_v1.0_manifesto.pdf` (22 pages, 32.4 KB) |
| USB image | `release/codebookos_v1.0.img` (64 MB; verified end-to-end QEMU boot at Pod 4.0.I) |
| SHA256SUMS | `release/SHA256SUMS` (3 entries) |
| RELEASE_NOTES.md | `release/RELEASE_NOTES.md` (GitHub Releases page copy) |
| v1.0-ship tag message | `release/v1.0-ship_TAG_MESSAGE.txt` (architect uses at flip-time) |
| 4 public-post drafts | `drafts/{hn_post,reddit_osdev,reddit_programming,twitter_thread}.md` |
| pytest harness | 72/72 PASS (47 polish + 25 doc) |
| Doctrinal corpus | 44 (D3.X complete) + 8 D4.X = 52 codified architectural doctrines |

**CodebookOS V1.0 is ship-ready.** The next action is architect-executed: GitHub Visibility → Public, push `v1.0-ship` tag, upload `release/` to GitHub Releases, post drafts on architect's cadence.

---

*Every opcode declares its cost. Every grant declares its parent. Every doctrine declares its scope. Every flip declares its checklist.*
