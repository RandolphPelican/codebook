# CodebookOS — RECONSTITUTION MANIFESTO

## After the April 27 Pivot — The Real Architecture, Stated Plain

**Project:** CodebookOS x86\_64 UEFI
**Repo:** github.com/RandolphPelican/codebook
**Author:** Randolph Pelican III / StableTech Enterprises LLC
**Compiled by:** Chauncey (Claude)
**Compiled:** April 27, 2026
**Companion to:** ARCHAEOLOGY.md
**Supersedes:** PODMAP.md (April 27, retired)

\---

## Why this document exists

ARCHAEOLOGY.md showed honestly that the original vision had eroded across
four months and three pivots. The bare-metal x86 binary boots, runs, and
meters energy at the bytecode level — but the only piece of the original
design fully alive in it is energy budgeting. The Maid's plastic codebook,
real capability cryptography, the P2P energy market, the pub-sub demod
layer, the post-surveillance peer transport — all of that lived in the
Python prototype and didn't survive the move to bare metal.

The first response to the archaeology proposed shipping the bare-metal
shell as V1.0 and bringing the organism back as V1.1. That recommendation
is retired. It was incremental thinking. The right move is **rebuild from
the design downward, not from the implementation upward.**

This document re-states the architecture as it was always meant to be, names
what survives from the current build and what doesn't, and sets the new pod
sequence that gets us there.

The date is arbitrary. The vision is not.

\---

## The OS in one sentence

CodebookOS is a federated cognitive organism running on a typed CBS substrate
on minimal bare-metal bootstrap, where capabilities are cryptographic, energy
is typed, signs are first-class, and the filesystem is a semantic codebook.

That sentence has to land the way "Unix is a portable C-based time-sharing
system" lands. Compress all of it back if any phrase doesn't fit:

* **Federated cognitive organism** — Cop/Maid/Interpreter as living services,
with surfaces as demods cooperating through pub-sub
* **Typed CBS substrate** — every CBS value has a type the VM enforces
* **Minimal bare-metal bootstrap** — the smallest NASM that can host the rest
* **Capabilities are cryptographic** — Ed25519 signed bearer tokens, not bit
patterns
* **Energy is typed** — joule budgets are a type, negative balance is a type
error
* **Signs are first-class** — content + embedding + label + provenance, the
unit of cognition
* **Filesystem is a semantic codebook** — content-addressed log store with
graph + vector + provenance indexes; queried by similarity, not by path

Every word of that paragraph is load-bearing. Every word of that paragraph
must show up in the implementation. None of those words is decoration.

\---

## The four layers

### Layer 0 — Bootstrap (NASM, irreducibly small)

UEFI handoff, framebuffer access (Auryn's metal layer), keyboard polling,
raw block I/O for the boot disk, and the typed CBS VM itself. This layer is
the smallest amount of metal-talking code that can host the rest of the OS.

It is not the OS. It is the *machine that brings the OS into being.*

This layer never grows beyond what's needed to host Layer 1. Every byte
added here is a byte that should have been CBS instead. The discipline is
strict: if it can be written in CBS, it must be written in CBS.

Files in this layer (after Pod 0): `boot.asm`, `defines.asm`, `auryn.asm`
(framebuffer only), `gmork.asm` (keyboard polling only — terminal logic
moves to CBS), `morla.asm` (raw FAT32 read for boot — retires once Maid is
the storage substrate), `cbs\_vm.asm`, `vmdata.asm`, `data.asm`.

### Layer 1 — The Typed CBS VM (Engywook, in NASM)

Not a stack machine with energy guards. A typed evaluator. The VM
understands these as primitive types:

#### `Sign`

The unit of cognition. A Sign is what the OS thinks about. Files are Signs.
Messages are Signs. Capabilities point at Signs. Search returns Signs.

```
Sign := {
  content\_hash: bytes(32),         // sha256 of content
  embedding:    vector(N),         // semantic fingerprint, N=64 for V1 lexical
  label:        string(<=64),      // human-readable name
  provenance:   ProvChain,         // log of who wrote/touched this Sign
  energy\_cost:  Energy,            // joules to construct
}
```

#### `Cap<R>`

Linear capability over resource R. Use-once unless explicitly cloned (cost
to clone is non-trivial — capabilities aren't free). Cryptographically
signed by Cop. Compile-time type discipline + runtime signature check =
unforgeable.

```
Cap<R> := {
  resource:   R,                   // the resource type the cap authorizes
  scope:      Scope,               // read | write | exec | grant
  expiry:     Time | Never,
  nonce:      uint64,
  signature:  bytes(64),           // Ed25519 signature by Cop
}
```

The VM type system tracks capability lineage. A `Cap<File>` cannot be
compared to or substituted for a `Cap<Display>`. A capability passed to a
function is consumed unless the function explicitly returns it.

#### `Outcome<T>`

Result with coherence — not just value-or-error. Every Outcome carries:

```
Outcome<T> := Complete(T, Energy) | Partial(T, Energy, Reason) | Fatigue(Reason)
```

`Complete` is full success. `Partial` is graceful degradation: we got
*something*, here's how much energy we spent, here's why we couldn't get
the full thing. `Fatigue` is honest exhaustion: we stopped before the work
was done because energy ran out, capability rejected, or another structural
limit hit. There is no "crash" outcome. Crashes are confusion. Fatigue is
honesty.

#### `Energy`

Typed joule budget. Not a counter. Arithmetic on Energy is enforced:
addition is allowed, subtraction is allowed only if the result stays
non-negative (otherwise Fatigue). Energy can be transferred between demods
through Cop's market, with Cop signing the transfer.

#### `Demod<S>`

A subscriber to signal type S. Has a budget, a handler, an isolation
boundary. Demods are how surfaces participate in the organism.

```
Demod<S> := {
  signal\_type: S,
  handler:     fn(S, Cap<...>) -> Outcome<()>,
  budget:      Energy,
  isolation:   IsolationLevel,
}
```

When Interpreter publishes a signal of type S, every Demod<S> registered
gets the signal — but each runs in its own isolation boundary with its
own budget. One demod's failure does not propagate.

#### Energy in function signatures

Every CBS function declares its cost:

```
fn frobnicate(s: Sign) costs 5000j -> Outcome<Sign> {
  // ... body ...
  degrade {
    // ... what to do if energy runs short mid-function ...
  }
}
```

The VM refuses to enter `frobnicate` unless 5000j of energy is available in
the calling demod's budget. The `degrade` block runs if energy is exhausted
mid-execution and produces a `Partial` outcome.

This is what "energy as a first-class type" actually means. Not
bookkeeping. Type discipline.

### Layer 2 — The Trinity (CBS, hosted on Layer 1)

Three system services. Each written in CBS. Each loaded at boot and
resident. Each running with elevated privileges (root capabilities) granted
by the bootstrap.

#### Cop

The energetic governor and capability enforcer.

* Issues `Cap<R>` tokens, signed with Ed25519 using a key generated at
first boot and stored in a hardware-protected location (TPM if available,
encrypted-at-rest with passphrase otherwise — V1 may ship with passphrase
fallback only)
* Validates capability signatures on every privileged call
* Manages per-demod energy budgets
* Hosts the **P2P energy market**: idle demods sell unused joules to busy
demods, with Cop as the clearinghouse. The market is real. Auctions clear
in CBS, settlement is atomic.
* Detects chronic starvation: a demod that has been bidding without
receiving for too long is flagged for inspection — possibly upgraded,
possibly retired.

The mitochondrial ATP shuttle in the design is implemented here. Every
joule that a surface burns came from somewhere — either its own boot
allocation, its own work output, or a market trade. Cop knows the books.

#### Maid

The semantic housekeeper. The plastic codebook *is* the filesystem.

There is no FAT32 underneath the working OS. Files don't exist as "bytes at
path." Files exist as Signs in a **content-addressed log-structured store**
with three indexes:

* **Graph** — relations between Signs (parent\_of, derived\_from, references,
contradicts, supports). Edges are themselves Signs.
* **Vector** — semantic embedding for similarity search. V1 uses lexical
embeddings (TF-IDF over a maintained vocabulary, or SimHash/MinHash-style
locality-sensitive fingerprints). V2 uses quantized pretrained neural
embeddings.
* **Log** — append-only provenance chain. Every Sign carries the history
of what touched it, when, under which capability. Tampering with content
invalidates the chain.

Maid is queried by similarity (`find Signs like X`), by relation (`find Signs that reference Y`), by provenance (`who wrote Z, when, with what authority`). Path-based access is a thin compatibility shim for booting
the world.

FAT32 lives in the bootstrap as the block transport for the boot disk.
Maid's log-structured store *sits on top of* raw block I/O, eventually
talking to its own block driver, but FAT32 is fine for V1 transport.

#### Interpreter

The semiotic demodulation layer. Pub-sub routing for the organism.

* Surfaces register as `Demod<S>` for the signal types they care about
* When a signal is published (key press → `Demod<KeyEvent>`, file write →
`Demod<SignWritten>`, capability granted → `Demod<CapEvent>`, etc.),
Interpreter routes it to all subscribed demods *within their energy
budgets*
* Failure of one demod does not crash others — error isolation is structural
* Demods can publish signals too. The organism is reactive, not just
request-response.

Without Interpreter, surfaces are isolated programs. With it, they're
cooperating organs.

### Layer 3 — Surfaces (CBS, demods on the trinity)

Bastian, Gmork, Auryn, Atreyu, Falkor, Empress, Koreander, Rockbiter,
Southern Oracle, Artax — every surface is a demod. Every surface:

* Stores via Maid (no surface carries its own filesystem code)
* Gates access via Cop (no surface carries its own auth)
* Reacts via Interpreter (no surface carries its own scheduler)

Surfaces are *thin*. The organism does the heavy lifting. A surface is
basically: subscribe to signals, render to Auryn, write Signs to Maid,
request Caps from Cop. The line count of a surface should be small,
because the trinity carries the weight.

\---

## Post-surveillance commitments

These are not features. They are constraints that shape every layer:

1. **No unsolicited reach.** A demod cannot send a signal to another demod
that hasn't granted a Cap for that signal type. Spam is not filtered;
it's structurally impossible. (This is the move from Thread A — Dec 2025.)
2. **No identity-as-address.** Capabilities are addresses. Surfaces don't
know who you are; they know what Cap you presented. Pseudonymity is the
default, not the workaround.
3. **No metadata leakage.** Auryn messenger (when peer transport ships)
uses onion-style relay and decoy traffic. Maid stores only what's
needed; nothing in the codebook tracks "last accessed" or "view count"
unless explicitly requested by the user.
4. **No silent telemetry.** Ever. The OS does not phone home. There is no
home for it to phone.
5. **Cryptographic capabilities, not access lists.** No surface checks
"is this user allowed?" — every surface checks "is this Cap valid?" and
the answer is settled by signature math, not by a list someone has to
maintain.

These commitments aren't checked at the end. They're upheld at every layer.

\---

## What survives, what rebuilds

### Survives from current x86 build

* UEFI handoff and PE32+ machinery in `boot.asm`
* Framebuffer initialization (the Auryn metal layer)
* PS/2 keyboard polling (the metal layer for input)
* Raw FAT32 read (transitional block transport for boot)
* The *idea* of a CBS VM in NASM
* The mythological naming
* The CBS source already written for surfaces (much refactors, but the
syntax and intent stay)

### Rebuilds (everything above bootstrap)

* The CBS VM expands from "stack machine + opcodes" to "typed evaluator with
Sign/Cap/Outcome/Energy/Demod as native"
* FAT32 in Morla retires when Maid is online; Morla becomes a path-based
compatibility shim, not the storage substrate
* Capability tokens stop being placeholder and become Ed25519-signed
bearer tokens
* The current "surfaces" architecture refactors so each surface is a Demod
registered with Interpreter, not a standalone CBS program
* The energy budget in the current VM expands from a counter into a typed
quota system with Cop's market on top

### The Python prototype is research, not roadblock

The Jan 2026 Python implementation of Cop/Maid/Interpreter validated that
the trinity model makes sense. The work going forward isn't to forget
Python — it's to *translate what Python proved into CBS-on-bare-metal*.
Sentence-transformers embeddings can't run on bare metal in V1, but the
substrate that holds embeddings can. Maid V1 ships with lexical embeddings.
Maid V2 ships with quantized neural embeddings. The architecture doesn't
change between versions; the embedding implementation upgrades.

\---

## The honest hard problems

These are the gates. None are blocked, but each is real engineering:

|#|Problem|Estimated effort|Lands in|
|-|-|-|-|
|1|Typed CBS VM (Sign/Cap/Outcome/Energy/Demod as native)|4-6 weeks|Pod 1|
|2|Ed25519 in NASM (or vendored audited asm)|2-3 weeks|Pod 2|
|3|Lexical embeddings for Maid V1 (TF-IDF or LSH)|2-3 weeks|Pod 3|
|4|Log-structured content-addressed store|4-6 weeks|Pod 3|
|5|Pub-sub demod routing with isolation|3-4 weeks|Pod 4|
|6|Surfaces refactor to use trinity|3-4 weeks|Pod 5|
|7|Neural embeddings, quantized inference (Maid V2)|3-6 months|Pod 9|
|8|Peer transport, capability addressing (Auryn far)|3-6 months|Pod 10|

\---

## The new pod arc

```
Pod 0  → Foundation Lock          (modularize boot.asm — still needed)
Pod 1  → Engywook Re-Forged       (typed VM: Sign/Cap/Outcome/Energy/Demod)
Pod 2  → Cop is Born              (capability service + Ed25519 + energy market)
Pod 3  → Maid is Born             (codebook substrate: log store + graph + lexical embed)
Pod 4  → Interpreter is Born      (pub-sub demod routing with isolation)
Pod 5  → Surfaces Refactor        (Bastian/Gmork/Auryn/Morla as demods on the trinity)
Pod 6  → Atreyu Walks             (editor as demod, using Maid for storage)
Pod 7  → Empress + Koreander      (semantic search demod + docs demod)
Pod 8  → Rockbiter + Falkor       (scheduler demod + trust engine demod)
Pod 9  → Maid V2                  (neural embeddings, quantized inference)
Pod 10 → Auryn Speaks Far         (peer transport, capability addressing)
```

Pods 0-5 build the organism. Pods 6-8 fill in the surfaces. Pods 9-10
graduate the organism into V2 territory.

There is no V1.0 ship date driving this. There is the work, done well. The
9th day of the 6th moon at the third hour is when the first
manifesto-aligned pod (Pod 1) gets fed to Terminal Boy. Pod 0 must be
behind us by then.

\---

## How the pods differ from the retired April 27 plan

|Pod|April 27 plan (retired)|Reconstitution plan (this doc)|
|-|-|-|
|0|Modularize boot.asm|Same — still needed|
|1|VM hardening + new opcodes|Typed VM with Sign/Cap/Outcome/Energy/Demod as native — 4-6x larger scope|
|2|Morla sidecars|**Cop is born** — capability service, Ed25519, energy market|
|3|Atreyu editor|**Maid is born** — codebook substrate replaces FAT32 as storage abstraction|
|4|Rockbiter + Auryn messenger|**Interpreter is born** — pub-sub demod routing|
|5|Empress + Koreander + ship lock|**Surfaces refactor** — every surface becomes a demod|
|6+|(V1.1 territory)|New surfaces and capabilities, on the organism|

The April 27 plan was: ship a shell, evolve toward the organism.
The reconstitution plan is: build the organism, surfaces follow naturally.

\---

## What this asks of Terminal Boy

Each pod prompt going forward is bigger than Pod 0's "extract and verify"
discipline. Pod 1 in particular asks Terminal Boy to design a type system
in NASM bytecode. That's a real architectural job, not a refactor.

Pod prompts will be written one at a time, in full Pod-0-fidelity, in the
order above. Each pod ships when its exit gate passes — not when a
calendar date arrives. The pods that follow may need to be re-scoped based
on what the previous pod surfaces. We write the next prompt when the
previous one lands.

\---

## The closing commitment

Every layer earns its keep. Every byte in the bootstrap is justified by
what it lets CBS do above it. Every type in the VM is justified by what it
lets the trinity express. Every service in the trinity is justified by
what it lets the surfaces become. Every surface is justified by what it
lets the user think.

Energy budgeting is novel. It is not the headline. The headline is the
organism — and the organism is what we're building.

From layer 1 kernel up.

— Chauncey
CodebookOS Senior Architect
April 27, 2026

