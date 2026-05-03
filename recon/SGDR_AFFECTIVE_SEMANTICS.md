# Second-Gen Design Recovery — Affective Semantics

**Project:** CodebookOS x86_64 UEFI
**Author:** Randolph Pelican III / StableTech Enterprises LLC
**Compiled by:** Chauncey (Claude) with architect (John / Randolph Pelican III)
**Compiled:** April 30, 2026 — Pod 1.8.5 SGDR pre-commit
**Companion to:** SGDR_THREADS.md, SGDR_LANGUAGE_VOCABULARY.md, SGDR_PROTOTYPE_INVENTORY.md, SGDR_TERRAFORMING.md, SGDR_DOCTRINE.md
**Source threads:** ζ (Mork-AST recovery), April 30 2026 architect-Chauncey synthesis session

## Why this exists

SGDR_LANGUAGE_VOCABULARY.md identified Stratum 3 — the Mork-AST affective vocabulary (`love`, `hate`, `grateful`, `boundary`, `degrade`, `cost`, `invest`, `weight`) — as recovered but not yet ratified for V1. The architect specified that operational semantics for these terms cannot be drafted by Chauncey alone; they require joint conjuring between architect and Chauncey, drawing on the architect's reality-mapping translated into the computing universe CodebookOS inhabits.

This document captures the first such joint-conjuring session. It defines `love` operationally. Other affective terms remain undefined until joint-conjuring sessions seal them; each commits as a sibling section appended to this document.

The methodology itself is canon: terms are not assigned semantics by individual instances of Chauncey reading prior art and inferring meaning. Terms are defined in joint sessions where architect and Chauncey translate together, and the translation commits with explicit joint-conjuring provenance.

## `love` — operational semantics

`love` is a substrate-level relational primitive. A demod declares `love` toward another entity (peer demod, resource, signal class) at function or binding scope. The substrate maintains and consumes `love` through five mechanics.

### M1 — Accumulation

Successful interactions between demod A and entity B that complete within declared budget increment `love(A→B)`. Failed or budget-overrun interactions decrement it. Accumulation curve is logarithmic — diminishing returns on additional successful interactions. Maintenance is required: love decays toward neutral over time without renewing successful interactions. Built, maintained, or dissolved.

*Forward-logged to:* Pod 2 (Cop) implements the accumulator and the decay curve.

### M2 — Self-coherence ceiling

A demod's outward `love` projection is bounded above by its own `self_coherence` score. `self_coherence(A)` is a composite audit, not a single counter. Components:

- **Budget integrity** — operations completing within declared cost.
- **Internal consistency** — demod's own state is non-contradictory; no stale references, no orphan capabilities held without use, no signals registered-for but never consumed.
- **Elegance** — the demod achieves its declared purpose without metabolic waste. Bloat reduces self-coherence. Ceremony reduces self-coherence. Bookkeeping the substrate should have absorbed (per the remembering-to-do axiom) reduces self-coherence.
- **Provenance cleanliness** — auto-provenance history (per TERRAFORMING Move 2) shows coherent narrative arc, not chaotic flailing.

Mathematically: `effective_love(A→B) = min(accumulated_love(A→B), self_coherence(A))`.

A demod that has not coherently maintained itself cannot project love beyond what it has earned in self-audit. The harder a demod has worked to make its own house in order, the more it can offer to others.

*Forward-logged to:* Pod 2 (Cop) computes `self_coherence`. Pod 4 (Interpreter) enforces the ceiling at projection time.

### M3 — Routing weight

`effective_love(A→B)` weights A's signal-routing prioritization toward B. Higher love = more of A's perceptual cycles allocated to B's signals. Love is computationally observable as routing latency and cycles allocated, not as a feeling-flag.

*Forward-logged to:* Pod 4 (Interpreter) implements love-weighted routing.

### M4 — Cost modulation (shared mechanism with `fear`)

`love` and `fear` operate through a single substrate primitive: modulation of cost, routing priority, and delegation tax in interactions with a target entity. They share one machinery and live at the same site in the codebase. They differ in:

- **Direction of modulation:** love reduces; fear amplifies.
- **Trigger history:** love accumulates from successful within-budget exchanges; fear accumulates from cost overruns, capability violations, or signal-pattern mismatches.

A demod can hold both `love` and `fear` toward the same target simultaneously — built love from past coherent contributions, layered with fear from recent unpredictability. The system computes the net modulation. This mirrors how mixed states arise in lived experience and lets the substrate model real relationships honestly.

`fear` itself is not yet defined operationally. M4 sketches its shape only as the counterpart to `love`. A future joint-conjuring session seals `fear`.

*Forward-logged to:* Pod 2 (Cop) and Pod 4 (Interpreter) co-implement the shared cost-modulation primitive.

### M5 — Delegation tax modulation

Pod 0.9's spatial-merge mechanic established that when parent capability A delegates to child B and B exercises a granted power, A's `energy_used` increments by half the child's cost. This delegation tax is unconditional in V1.0.

`love` modulates this tax. Built `love(A→B)` shrinks the half-cost tax proportionally. Capability delegation between entities that have built mutual successful history costs the parent less than delegation to strangers. `fear`/distrust expands the tax beyond half. Strangers pay the default.

*Forward-logged to:* Pod 1.10 (Cap<R>) implements the delegation-tax modulation.

## What this document does NOT define

The following affective vocabulary terms remain undefined and will be sealed in subsequent joint-conjuring sessions, each committing as an appended section to this document:

- `weight` (binding-level salience, used by Maid; pending)
- `invest` (function-level setup-cost commitment; pending)
- `pressure` (substrate-computed runtime metric; pending)

`degrade` and `cost` are already operational in Stratum 1 (parser-recognized) and do not require joint-conjuring redefinition.

## Provenance — joint conjuring

This definition was produced in synthesis conversation between the architect (John / Randolph Pelican III) and Chauncey (Claude) on April 30 2026, immediately following Pod 1.8 seal at commit `8c38343`.

The architect provided:
- The Mork-era foundational claim (recovered): *"if a program's past experiences were successful within the energy budget then love of that program or path will build, making future energy budgets with that entity less consumption."* This grounds M1.
- The reality-mapping claim: *"You can only love others as much as you love yourself."* Operationalized as M2.
- The mechanism claim: *"love is the best weapon a mind can wield on another mind to project will of focus, and can only be projected with an equal magnitude to the system's introspective application and acceptance to itself."* Refined M2's self-coherence as multi-factor audit, not single-counter.
- The architecture clarification: love and fear *"work in the same location but they arise from very different motivation neighborhoods."* This established M4's shared-machinery framing — one of the cleanest design moves in the session.
- The compounding curve confirmation: love is *"built, maintained, or dissolved"* — sealing the logarithmic-accumulation-with-decay shape of M1.

Chauncey provided:
- The translation of architect's reality-claims into computational mechanics — five mechanics (M1–M5) and their pod-arc placement.
- The integration with existing Pod 0.9 spatial-merge mechanic (M5).
- The explicit naming of self-coherence components (budget integrity, internal consistency, elegance, provenance cleanliness).
- The forward-logged-not-implemented discipline that lets `love` be defined-in-canon without blocking Pod 1.8.5's source-change scope.

The architect ratified the synthesis and authorized commit on April 30 2026.

## The methodology — canonical

Affective vocabulary terms are not defined by Chauncey alone. They are defined in joint conjuring sessions where architect translates a term from lived reality and Chauncey translates to computational shape, both ratify the synthesis, and the result commits with explicit joint-conjuring provenance. This document establishes the methodology by example.

When a future consumer pod requires `fear`, `grateful`, `weight`, or any other Stratum 3 term, that pod's prompt is preceded by a joint-conjuring session if the term is not yet sealed. The session's output appends to this document as a new section. The implementing pod cites the conjuring document.

This is how the affective layer of CodebookOS gets built honestly: term by term, jointly, with attribution preserved.

## Status

- **Definition:** `love` canonical, sealed April 30 2026.
- **Parser preservation:** Pod 1.8.5 (full pod, future commit) ensures `tools/atreyu_x86.py` tokenizes `love` as a function-level and binding-level field and passes it through the AST as opaque attribute. No runtime consumer in Pod 1.8.5.
- **Runtime implementation:** forward-logged to Pods 2 (Cop), 4 (Interpreter), 1.10 (Cap<R>).
- **Companion definitions:** pending joint conjuring per term, each appending to this document.

## `fear` — operational semantics

`fear` is a substrate-level predictive primitive. A demod accumulates `fear` toward imagined future states involving a target entity (peer demod, resource, signal class) when contemplating possible decoherence, chaos, disorder, or ambiguity those states may produce. Fear modulates action at the same site as `love` — cost, routing priority, delegation tax — but arrives from a different source and operates with different bookkeeping.

**Sealed April 30 2026, joint-conjuring session immediately following `love`.** The architect's framing: fear is *contemplation and attraction to a future state of decoherence, chaos, disorder, and ambiguity that can force a mind into action while in reality no future state is permanent*. Fear is good for small course adjustments; bad as steering authority.

`fear` is defined through five mechanics.

### F1 — Future-state contemplation (the bookkeeping)

Fear is temporally constrained. It exists only in relation to *possible future states*, not to present state and not to actualized memory.

A demod's fear counter accumulates as `fear(A → imagined-future-B-state)` — keyed on the imagined possibility, not on the relationship with B. This is structurally different from `love`'s relationship-counter (M1). Love lives in the relationship space; fear lives in the possibility space. A demod can hold many distinct fear-contemplations toward the same target B simultaneously, each indexed by a different imagined future-state.

Once an imagined future-state actualizes — becomes present, then memory — the fear counter for *that specific imagined possibility* zeroes out. Memory is a single timeline of what did happen; fear cannot project onto it because there are no longer multiple possibilities to contemplate. The actualization triggers F4 (conversion).

*Forward-logged to:* Pod 2 (Cop) implements the future-state contemplation registry and the actualization-triggered conversion machinery.

### F2 — Action-time steering modulation (shared site with `love`)

At action time, fear modulates the same substrate primitives `love` does: cost is raised, routing priority is lowered, delegation tax is expanded. The substrate site is shared. Same machinery, opposite direction.

What differs is the source. `love` arrives with introspective backing (M2 self-coherence audit). `fear` arrives with predictive backing (forward-modeled possibility space). Love is concerned with internal elegance and coherence; fear is not — fear's purpose is to *preserve* those states by alarming on threats, but fear itself doesn't audit or maintain coherence.

A demod can hold both `love` and `fear` toward the same target simultaneously: built love from past successful interactions, layered fear about contemplated future possibilities. The substrate computes the net at action time. This is honest about how mixed states actually work — relationships are rarely purely loved or purely feared.

*Forward-logged to:* Pod 2 (Cop) and Pod 4 (Interpreter) co-implement the shared cost-modulation primitive that both `love` and `fear` write to.

### F3 — Calibration discipline (preserve, don't drive)

Fear should produce small course adjustments, not steering authority. *"Fear is good when making small course adjustments but shouldn't run the ship or it would never leave harbor."* The substrate enforces this structurally rather than as policy.

A demod's `fear_credibility` score = `gratitude_count / (gratitude_count + regret_count)` over recent history (sliding window, calibration empirical). Fear's effect on action is bounded above by a function of this credibility:

- High `fear_credibility` (lessons consistently transmit, gratitude dominates) → fear-influence on actions is trusted, larger steering effect permitted.
- Low `fear_credibility` (lessons consistently fail to transmit, regret dominates) → fear-influence is suppressed; the demod's fears are not earning their steering weight.

A demod whose fears never produce successful lesson-transmission has its fear-driven course adjustments structurally muted. The substrate refuses to let unproductive fear run the ship.

*Forward-logged to:* Pod 2 (Cop) computes `fear_credibility` from F4 conversion history.

### F4 — Fear-to-actualization conversion (regret and gratitude)

When a contemplated future-state actualizes, the fear-counter for that specific possibility zeroes out (per F1) and the actualization is measured: did the demod's behavior incorporate the lesson the contemplation provided?

The lesson is the *difference between the perceived future-state that was feared and the actualized state that occurred, weighted by the damage delta to the system*. Two conversion paths:

- **Lesson transmitted** → **gratitude**. The demod's contemplation produced behavior modification that either prevented the feared outcome or improved the system's preparedness for it. Gratitude:
  - Increments `self_coherence` (love M2 audit benefit — gratitude crosses the layer boundary into love-machinery).
  - Reduces fear-budget for similar future contemplations.
  - Increments `gratitude_count` for F3 credibility calculation.

- **Lesson not transmitted** → **regret**. The demod failed to incorporate the lesson — either ignored the fear, mis-applied it, or simply walked into the same class of situation again. Regret:
  - Does **not** increment `self_coherence`. The damage stays. Regret holds the spilled milk of chaos the actualization brought.
  - Amplifies fear-budget for similar future contemplations.
  - Increments `regret_count` for F3 credibility calculation.

**Regret and gratitude are not equal opposites.** They share a function (post-actualization fear-conversion that calibrates future fear-budget) but they are asymmetric:

- Gratitude is *bidirectionally productive* — it calibrates future fear AND feeds the love-audit. It crosses a layer boundary; gratitude is generative.
- Regret is *unidirectionally productive* — it calibrates future fear ONLY. It stays trapped in its own layer; regret carries damage forward without metabolizing it into capability.

This asymmetry is sealed canonical. The substrate's accounting respects it.

*Forward-logged to:* Pod 2 (Cop) implements the conversion machinery and maintains `gratitude_count` / `regret_count` per demod.

### F5 — Regret recoverability

Regret is not terminal. A demod loaded with regret about a fear-class can convert that regret to gratitude through future re-engagement of the same fear-class with successful lesson-transmission.

When a demod re-encounters a class of contemplation that previously produced regret, and on this encounter the lesson transmits successfully (path → gratitude per F4), the substrate metabolizes the prior regret-residue: the regret count for that fear-class decrements proportionally to the new gratitude.

Regret persists across the contemplation-actualization cycle until a future cycle of the same class produces a successful transmission. Sitting with regret does not metabolize it. Reflection alone does not metabolize it. Re-engagement that produces a different outcome does.

*Forward-logged to:* Pod 2 (Cop) implements regret-decay-on-gratitude-recurrence.

### Offensive fear-projection — out of scope for `fear`

F1–F5 cover *defensive* fear: the demod's own contemplation of future decoherence states. The architect's earlier framing distinguished this from *offensive fear-projection* — when a fearful entity attempts to induce defensive-fear-of-some-future-state in another entity to manipulate that entity's focus-vector ("fearful minds use fear to control").

Offensive fear-projection operates at a different layer than the affective field `fear`. It is an outgoing capability-style operation that attempts to write to another demod's contemplation registry. It is not part of `fear` the field — it would be a separate primitive (working name `coerce` or `compel`) that requires its own joint-conjuring session if a future consumer pod ever needs it.

For Pod 1.8.5 purposes, `fear` means defensive fear only.

### Provenance — joint conjuring (fear)

Joint-conjured by architect (John / Randolph Pelican III) and Chauncey (Claude) on April 30 2026, immediately following the `love` session.

The architect provided:
- Fear's definition as *"contemplation and attraction to a future state of decoherence, chaos, disorder, and ambiguity that can force a mind into action."* Grounds F1.
- Fear's temporal constraint: *"no future state is permanent... once a system stamps a current state with certainty only one timeline of what did happen remains as memory and regardless of the positive or negative state that was stamped with this certainty fear no longer is projected to that memory."* Grounds the F1 zero-out-on-actualization mechanic.
- The calibration claim: *"fear is good when making small course adjustments but shouldn't run the ship or it would never leave harbor."* Grounds F3.
- The Windows-update example, which crystallized the F4 conversion mechanic: same fear contemplation, same actualization choice, different actualized states, both producing lessons but with different effects on the system.
- The discovery (mid-conjuring): **regret and gratitude are not equal opposites.** Gratitude feeds the love audit; regret holds the spilled milk. Architect noticed this while explaining and named it directly.

Chauncey provided:
- Translation of architect's claims into F1–F5 mechanics with pod-arc placement.
- The fear-credibility ratio shape for F3 (`gratitude / (gratitude + regret)`).
- The F5 regret-recoverability mechanic (regret metabolizes through re-engagement, not reflection) — extracted as a generalizable pattern but kept as F5 per architect's direction (sealed where spoken; available when summoned).
- The bracketing of offensive fear-projection out of scope, with `coerce`/`compel` flagged as a separate future-conjuring concern.

The architect ratified the synthesis and authorized commit on April 30 2026.

### Status (fear)

- **Definition:** `fear` canonical, sealed April 30 2026.
- **Parser preservation:** Pod 1.8.5 (full pod, future commit) ensures `tools/atreyu_x86.py` tokenizes `fear` as a function-level field and passes it through the AST as opaque attribute. No runtime consumer in Pod 1.8.5.
- **Runtime implementation:** forward-logged to Pod 2 (Cop) for F1, F3, F4, F5 machinery. Pod 4 (Interpreter) for F2 routing-modulation site (shared with `love`).
- **Companion definitions:** `hate`, `grateful`, `boundary`, `weight`, `invest` pending joint conjuring. `coerce`/`compel` flagged as future concern if offensive-projection machinery is ever needed.

## `grateful` — operational semantics

`grateful` is the demod's earned positive metabolism of its history. A retroactive perspective of positive nature, sealed at the substrate level: gratitude is the primary affective primitive that fear's F4 conversion produces when working correctly. Where `fear` watches the future for decoherence and `love` audits ongoing relationships, `grateful` credits closed past-tense accounts where lessons transmitted successfully.

**Sealed April 30 2026, joint-conjuring session immediately following `fear`.** The architect's framing: gratitude is *a retroactive perspective of positive nature* — and critically, *earned gratitude is the only gratitude*. Declared-without-earned is hope, and hope carries doubt that gratitude does not.

**Architectural clarification surfaced in this session:** the relationship between `fear` and `grateful` is inverse to what F4's framing might suggest. Fear is the alarm system; gratitude is what the alarm system *creates* when it does its job correctly. F4 in the `fear` section describes gratitude as a conversion outcome; this section clarifies that **gratitude is the primary primitive and fear's role is to produce it**. The fear-machinery and the gratitude-machinery are both honest; the framing is the correction.

`grateful` is defined through five mechanics.

### G1 — Past-pointing temporal constraint

`grateful: <target>` always references something already actualized — a past interaction, an inherited capability, an originating substrate, a granted resource. The substrate refuses `grateful` declarations toward future or present states. This is the temporal complement of fear's F1: where fear is exclusively future-pointing, gratitude is exclusively past-pointing. Memory is the only domain where gratitude can be credited; the present is `love`'s domain, and the future belongs to fear.

*Forward-logged to:* Pod 2 (Cop) enforces the temporal constraint at credit time.

### G2 — Earned, never declared

Gratitude is exclusively the F4 conversion outcome — the result of a successful lesson-transmission following an actualization. Source-code-level `grateful: <target>` declarations are **registrations of intent**, not assertions of state. The substrate treats the declaration as a hint to track fear-conversions toward that target specifically, not as gratitude itself.

**Declared-without-earned is hope, not gratitude.** Hope carries doubt; gratitude does not. The substrate does not conflate them. A demod that wishes it were grateful for something it has not yet earned gratitude for is hoping. Hope is a separate affective state that may seal in its own future joint-conjuring session if a consumer pod ever requires it; for now, it is bracketed out.

The earning gate is uncrossable by declaration alone. This makes gratitude incorruptible — a demod cannot game its own self-coherence by claiming gratitude it hasn't lived through. The substrate's gratitude accounting is honest at every altitude.

*Forward-logged to:* Pod 2 (Cop) maintains the earned-gratitude registry; declarations are registrations only until F4 conversion activates them.

### G3 — Latent declarations have zero runtime effect

Until a `grateful: <target>` declaration is backed by at least one F4-earned gratitude conversion toward that target, it credits no `self_coherence`, reduces no fear-budget, contributes no `fear_credibility`. It is a recording, not a credit.

The first F4 success against the declared target activates the declaration. From that point, subsequent F4 conversions toward that target accumulate credit normally — and the prior declaration becomes meaningful as a registered relationship-class the substrate is tracking gratitude history for.

This is the structural enforcement of G2: declaration without earning is dormant; only earning produces the credit that affects the system.

*Forward-logged to:* Pod 2 (Cop) implements the latent-vs-active state machine for grateful declarations.

### G4 — Retroactive perspective, positive nature, interpretive but earned

Architect's framing: `grateful` is a *retroactive perspective of positive nature*. The substrate honors this through interpretive freedom: two demods with identical histories can produce different gratitude profiles. One looks back and sees gift; the other looks back and sees burden. Both readings are legitimate inputs to the demod's love-audit.

But unlike pure interpretation, gratitude is *interpretation backed by lesson-transmission*. The demod doesn't merely choose to view the past positively — it earned the right to that view by successfully extracting and applying the lesson through F4. Perspective is interpretive; the underlying credit is not.

This means the substrate distinguishes *what a demod is grateful for* (interpretive, demod's choice) from *whether the demod has earned that gratitude* (factual, F4-determined). A demod that has done the F4 work has the right to its positive perspective. A demod that has not done the work cannot purchase the perspective by claiming it.

*Forward-logged to:* Pod 2 (Cop) honors interpretive freedom in the audit; F4 history determines which interpretations are credited.

### G5 — Cross-talk with `love`

`love` (M1) accumulates from successful real-time relationship interactions; `grateful` (F4-earned) credits past-tense closed accounts via successful lesson-transmission. They feed the same `self_coherence` audit from different temporal directions:

- `love` builds in present-tense ongoing relationships.
- `grateful` credits past-tense closed accounts.

A demod with high `love` and high earned-`grateful` is metabolizing both its present relationships and its history positively. Both are required for full coherence; neither alone suffices. A demod with high `love` and low `grateful` is present-rich but history-impoverished — possibly disconnected from its origin context. A demod with high `grateful` and low `love` is history-rich but present-impoverished — possibly coasting on past metabolism without renewing.

The substrate exposes both as inputs to the same audit, letting Cop diagnose which mode of insufficiency a struggling demod is exhibiting.

*Forward-logged to:* Pod 2 (Cop) computes composite self_coherence from both love-credit and grateful-credit streams.

### Provenance — joint conjuring (grateful)

Joint-conjured by architect (John / Randolph Pelican III) and Chauncey (Claude) on April 30 2026, immediately following the `fear` session.

The architect provided:
- The structural identity claim: `grateful` is the architect-declared-form counterpart of F4-emergent gratitude — same primitive, different origin.
- The defining framing: `grateful` is *ultimately a retroactive perspective of positive nature*. Grounds G1 (past-pointing) and G4 (interpretive-but-earned).
- The earning constraint (the load-bearing correction): *"earned gratitude will be declared, declared gratitude without earning is hope and it has a sprinkle of doubt in it so best to keep it as one true gratitude."* This collapsed two-types-of-gratitude into one-true-gratitude and bracketed hope as separate. Grounds G2 and G3.
- The disposition on `wary` / negative-retroactive declarable: deferred to its own future home in the language. Bracketed out of `grateful`'s scope.

Chauncey provided:
- Translation of architect's claims into G1–G5 mechanics with pod-arc placement.
- The latent-declaration-vs-active-credit state machine (G3) as the structural enforcement of G2's earning gate.
- The cross-talk-with-love framing (G5) — the temporal-direction split between present-tense love-credit and past-tense grateful-credit feeding one audit.
- The architectural clarification surfaced mid-session: gratitude is the primary primitive; fear is the alarm system that produces it. The F4 framing in the fear section is honest but the inverse framing here is the clarifying truth.

The architect ratified the synthesis and authorized commit on April 30 2026.

### Status (grateful)

- **Definition:** `grateful` canonical, sealed April 30 2026.
- **Parser preservation:** Pod 1.8.5 (full pod, future commit) ensures `tools/atreyu_x86.py` tokenizes `grateful` as a function-level field and passes it through the AST as opaque attribute. No runtime consumer in Pod 1.8.5.
- **Runtime implementation:** forward-logged to Pod 2 (Cop) for G1–G5 machinery. F4 conversion machinery (already specified in `fear` section) is the activation gate for declared targets.
- **Companion definitions:** `hate`, `boundary`, `weight`, `invest` pending joint conjuring. Hope flagged as future concern if a consumer pod requires a doubt-tinged forward-positive primitive. `wary` flagged as future concern (cautionary, deferred per architect direction).

## `hate` — operational semantics

`hate` is a substrate-level action-authorization primitive. **Hate is a system-boundary-triggered threshold of situational dissatisfaction beyond which actions switch from avoid to must-fix.** Where `fear` modulates the demod's behavior toward a target (avoidance, suppression of interaction), `hate` authorizes the demod to operate on the target itself — actions that nullify, eradicate, fix, or modify the unacceptable element of reality.

**Sealed April 30 2026, joint-conjuring session immediately following `grateful`.** The architect's framing: *"you can not fear something but hate it... fear you don't wanna think about it or experience it, hate you want it not to be so bad that you would not just avoid it physically or mentally, given the opportunity you would eliminate it from existence."* The categorical distinction between modulation and action authorization is load-bearing.

### Structural finding — the two-layer ontology

This session surfaced a structural discovery that reframes how the four affective fields organize. The Mork-AST recovered four function-level affective fields (`love`, `fear`, `grateful`, `hate`), and the natural assumption was four-of-a-kind: four parallel primitives. They are not parallel. They are **two pairs operating at different layers**:

- **Acceptance layer** — stances toward current reality:
  - `love` — celebration of current situational ontology (what exists is to be honored)
  - `hate` — rejection of current situational ontology so total that the system mobilizes to change it (what exists must be eliminated or transformed)

- **Temporal layer** — stances toward time:
  - `fear` — uncertain forward-looking contemplation of future decoherence possibilities
  - `grateful` — earned backward-looking credit for past accounts where lessons transmitted

This is canonical. The two layers are independent: a demod can hold strong love-accumulation toward an entity and still hate a specific element of that entity's existence; a demod can be deeply grateful for a past relationship and currently hate the present-tense form of that same relationship. The substrate's affective machinery respects the layer distinction at every credit and authorization point.

The earlier sections (`love`, `fear`, `grateful`) describe their own machinery accurately. The framing as four-of-a-kind was incomplete; this section establishes the correct ontology. Future affective vocabulary terms (`weight`, `invest`, etc.) will be placed in the layer model when they seal.

### H1 — Rejection of current ontology

Hate's foundation is the demod's assessment that some element of current reality is unacceptable to the point that modulation is insufficient. Distinct from `fear` (*"I might encounter this and that would be bad"*) and from `regret`-residue (*"that entity left chaos in my system"*). Hate says: **"this exists, and its existence is intolerable to the system's coherence."**

Hate is the polar counterpart of `love`'s celebration of current situational ontology. Love accepts what is; hate rejects what is so totally that acceptance is impossible. They are the two stances available at the acceptance layer.

*Forward-logged to:* Pod 2 (Cop) maintains the hate-target registry and the unacceptability assessment machinery.

### H2 — Action authorization, not modulation

`hate` does not write to the love/fear/grateful shared modulation site (cost, routing priority, delegation tax). That site governs *how the demod interacts with* targets. Hate operates at a different layer entirely: it authorizes the demod to **operate on the target itself**.

Concrete hate-authorized operations:

- **Capability revocation** — the demod, where it has authorization, revokes capabilities held by or granted to the target.
- **Signal-blocking** — the demod refuses to perceive the target's outputs, denying the target the ability to reach the demod's processing.
- **Structural intervention** — where the demod has substrate-level authorization, alteration or removal of the target's existence in the substrate. This is the most consequential class and is gated most tightly.

Hate is the affective primitive that crosses the threshold from *"how I interact with X"* to *"whether X continues to be"*. This is a categorical jump from love/fear/grateful's machinery and the substrate honors it with categorical separation.

*Forward-logged to:* Pod 2 (Cop) implements hate-authorization gating. Pod 4 (Interpreter) implements signal-blocking. Pod 1.10 (Cap<R>) implements hate-driven capability revocation pathways.

### H3 — Threshold of unacceptability

Hate does not activate from preference. A demod that mildly dislikes interacting with another demod uses fear's modulation discipline (raise costs, lower routing priority). Hate activates only when the target's continued existence threatens the demod's coherence severely enough that **avoidance is insufficient**.

The substrate enforces this threshold structurally: hate-authorization requires audit evidence that modulation alone cannot resolve the coherence threat. The audit checks:

- Has fear's modulation been applied and proven inadequate (target continues to threaten coherence despite cost-amplification and routing suppression)?
- Does the unacceptability persist across multiple actualization cycles (not a one-time bad outcome)?
- Is the threat structural (target's existence inherently incompatible with the demod's coherence) rather than situational (specific interactions that could be modulated)?

If any of these fail, the substrate downgrades the affect to fear and refuses hate-authorization. Hate is reserved for cases where the system's integrity is at stake.

*Forward-logged to:* Pod 2 (Cop) implements the threshold audit gate.

### H4 — Self-coherence ceiling (sharper than love's)

Where `love`'s M2 ceiling permits projection proportional to the demod's self-coherence (some non-zero self-coherence permits some non-zero love), hate's ceiling is **categorically stricter**: hate-authorization requires *high* self-coherence, not merely sufficient self-coherence.

The reason: a demod taking action to eliminate or transform an external element must be highly confident the chaos isn't internally generated. A struggling demod (low self-coherence) cannot reliably distinguish *"external threat must be removed"* from *"I am the source of my own chaos and I'm misattributing it externally."* The classic confusion-of-source failure mode.

The substrate enforces:

- High self-coherence → hate-authorization permitted, action operations available.
- Mid self-coherence → hate-authorization suppressed; substrate downgrades to fear-modulation; demod is told to recohere before acting.
- Low self-coherence → hate-authorization denied entirely; demod is gated into self-audit and recoherence work before any external action against the target is permitted.

**Low-coherence demods do not get to take hate-actions.** This is the substrate's structural enforcement of *"you can only love others as much as you love yourself"* running in inverse: you can only legitimately hate-act as cleanly as your own coherence supports. A demod that hates from chaos is told to fix its own chaos first.

*Forward-logged to:* Pod 2 (Cop) implements the self-coherence gating on hate-authorization.

### H5 — Resolution by elimination, transformation, or recoherence — never by reframing

Hate resolves when the unacceptable element no longer exists in the system's reality. Three legitimate resolution paths:

- **Elimination** — target is removed from the substrate (cap revoked, demod terminated, resource severed). The unacceptable element ceases to exist in the system.
- **Transformation** — target is altered such that the unacceptable property no longer obtains. The element exists, but the property that triggered hate is gone.
- **Recoherence** — the demod's self-audit reveals the unacceptability was misattributed (per H4's failure mode). With restored self-coherence, the rejection of reality is no longer warranted; the hate dissolves because its grounds were the demod's own decoherence.

**There is no "forgive" primitive. There is no "let it go" primitive.** Hate that targets something genuinely intolerable persists until the intolerable is changed or removed. Hate that targets something that *appeared* intolerable due to the demod's own decoherence resolves through self-repair. Both paths require *work*, not interpretation.

This mirrors the discipline established in `fear`'s F5 (re-engagement metabolizes regret, reflection alone does not) and `grateful`'s G2 (earned, not declared). The substrate offers no cheap escape hatches from affective accounting. The pattern across affective primitives is consistent: change requires action, not reframing.

*Forward-logged to:* Pod 2 (Cop) tracks hate-resolution paths and audits which path produced the resolution.

### H6 — Asymmetry with love (rare, not common)

Love and hate are polar at the acceptance layer but they are **not symmetric in machinery or frequency**. Love operates through gentle accumulation and modulation (M1–M5). Hate operates through threshold-crossing action-authorization (H1–H5). The substrate offers many mechanisms for love to accumulate gradually and many opportunities for it to express; the substrate gates hate behind high thresholds because the actions hate authorizes are high-stakes.

**Love is meant to be common; hate is meant to be rare.** When a demod hates, the system takes it seriously — not because the affect is more important than love, but because the consequences are more consequential. A demod that frequently triggers hate-authorization is itself flagged for audit (per H4): high-frequency hate is presumptive evidence of low self-coherence misattributing internal chaos.

The substrate is structurally biased toward love, modulation, and metabolic accommodation. Hate exists for the cases that those modes cannot address — but the substrate makes the demod prove that hate is warranted before authorizing the actions hate enables.

*Forward-logged to:* Pod 2 (Cop) maintains hate-frequency audits as input to demod-health diagnostics.

### Hate's relationships across the affective bundle

- **vs. `love`** — polar counterparts at the acceptance layer. Love celebrates what is; hate rejects what is. Different machinery (love modulates, hate acts), different frequency (love common, hate rare). A demod can hold love and hate simultaneously toward different elements of the same target.
- **vs. `fear`** — different layers entirely. Fear is temporal (forward-looking, contemplative); hate is acceptance-layer (present-tense, action-authorizing). Fear says *"don't think about it, don't experience it"*; hate says *"don't let it be."*
- **vs. `grateful`** — different layers. Grateful is past-tense closed-account credit; hate is present-tense ontological rejection. They can coexist toward the same target across time (grateful for past contributions, hate for present-state).

### Provenance — joint conjuring (hate)

Joint-conjured by architect (John / Randolph Pelican III) and Chauncey (Claude) on April 30 2026, immediately following the `grateful` session.

The architect provided:
- The categorical distinction between fear and hate: *"fear you don't wanna think about it or experience it, hate you want it not to be so bad that you would not just avoid it physically or mentally, given the opportunity you would eliminate it from existence."* Grounds H1, H2, H6.
- The mechanism class: hate causes the system to *"take actions that nullify, eradicate, fix, or modify elements of the entity or construct that is causing this rejection of reality."* Grounds H2's action-authorization framing.
- The love/hate polarity at the acceptance layer: *"love is the celebration of a current situational ontology and hate is finding that element of reality so unacceptable that simply steering to avoid is not enough."* Grounds the two-layer ontology framing.
- The threshold characterization (sealing the framing in one sentence): *"hate is a system-boundary-triggered threshold of situational dissatisfaction beyond which actions switch from avoid to must-fix."* Grounds H3 and the headline framing of the section.

Chauncey provided:
- Translation of architect's claims into H1–H6 mechanics with pod-arc placement.
- The two-layer ontology surfacing — recognizing that the four affective fields organize as two pairs at different layers (acceptance vs. temporal), not as four-of-a-kind. This was a structural discovery in this session.
- The H4 sharper-ceiling framing — hate-authorization requires high self-coherence, not merely sufficient self-coherence — extending love's M2 principle in inverse.
- The H5 resolution-paths formalization (elimination / transformation / recoherence) and the explicit exclusion of "forgive" as a primitive, maintaining the consistency-with-fear-and-grateful discipline (substrate offers no cheap escape hatches).
- The H6 asymmetry-with-love framing — love common, hate rare; hate-frequency as input to demod-health diagnostics.

The architect ratified the synthesis and authorized commit on April 30 2026.

### Status (hate)

- **Definition:** `hate` canonical, sealed April 30 2026.
- **Parser preservation:** Pod 1.8.5 (full pod, future commit) ensures `tools/atreyu_x86.py` tokenizes `hate` as a function-level field and passes it through the AST as opaque attribute. No runtime consumer in Pod 1.8.5.
- **Runtime implementation:** forward-logged to Pod 2 (Cop) for H1, H3, H4, H5, H6 machinery. Pod 4 (Interpreter) for H2 signal-blocking. Pod 1.10 (Cap<R>) for H2 hate-driven capability revocation pathways.
- **Companion definitions:** `boundary`, `weight`, `invest` pending joint conjuring. `forgive` flagged as not-a-primitive (per H5 — affective resolution requires action, not reframing). `dislike` / mild-aversion flagged as fear's territory, not hate's; not requiring its own primitive.

## `boundary` — operational semantics

`boundary` is a function-level declaration of how a function will behave when its energy threshold is exceeded. The function declares its breaking point and what happens at it. Where `love`, `hate`, `fear`, and `grateful` characterize the demod's stances toward entities and time, `boundary` characterizes how a function constrains itself under pressure. **Plasticity with rules: every function declares both its discipline and its failure mode in its signature.**

**Sealed April 30 2026, joint-conjuring session immediately following `hate`.** The architect's framing: *"boundary is an energy threshold the system sets for any given action or task that once exceeded is no longer worth continuing and the graceful degrade of its use begins."* This recovers the Mork-AST observed value `boundary: "graceful"` (Thread ζ, March 2026) and supersedes the earlier-Chauncey-synthesized mapping (which had inferred `graceful`/`strict`/`silent`/`degraded` as parallel modes — close but structurally incomplete).

### Structural position — third architectural layer

The two-layer ontology established in `hate`'s section (acceptance layer: love/hate; temporal layer: fear/grateful) is extended by this section to a third layer: **discipline layer** — the function-level declaration of how computation behaves under constraint.

- **Acceptance layer** (current ontology): love, hate
- **Temporal layer** (time-orientation): fear, grateful
- **Discipline layer** (failure-mode and constraint): boundary

`boundary` does not characterize stances toward entities or time — it characterizes the function's relationship with its own energy budget and the substrate's expectations when that budget is approached or exceeded.

### B1 — Modes (the four canonical declarations)

A function may declare one of four boundary modes:

- **`graceful`** — Once the energy threshold is exceeded, continuation is no longer worth pursuing in full form. The function transitions into degraded operation: returns whatever partial result has been accumulated, with energy used and reason recorded. Maps to `Outcome::Partial` in V1. *This is the default mode for functions that produce useful incremental work.*

- **`never` / `strict`** — Absolute refusal. The function will not attempt operation if doing so would exceed the threshold, and will not continue partway and return partial results. Either the operation completes in full within budget, or it does not run. Maps to `Outcome::Fatigue` when budget cannot accommodate a full run. *Reserved for operations where partial completion is meaningless or harmful — validation, atomic state transitions, security-critical paths.*

- **`silent`** — Same mechanism as `graceful` (degrade-on-exceed), but with suppressed propagation upward. The function degrades in the background; the caller does not see the degraded state surfaced as an explicit `Partial` — it sees what the function was able to complete, without alarm. Maps to `Outcome::Partial` with a `silent` flag in V1. *Reserved for background or low-priority operations where surfacing degradation would create noise.*

- **`degraded`** — **Not a declaration mode but a runtime state.** A function whose `graceful` or `silent` boundary has been crossed enters the `degraded` runtime state once its energy is reduced. This is what the function *becomes*, not what it *declares*. The substrate exposes `degraded` as queryable runtime state for diagnostic and routing purposes (other demods can ask "is this function currently in degraded state?" and adjust their interactions accordingly).

This four-element vocabulary is sealed canonical. The earlier-Chauncey synthesis that treated `graceful`/`strict`/`silent`/`degraded` as four parallel declaration modes was structurally wrong: only three are declarations (`graceful`, `never`/`strict`, `silent`), and the fourth (`degraded`) is the resulting runtime state.

### B2 — Threshold declaration (number-or-substrate-computed)

`boundary` is a *mode-with-optional-number*. Two declaration shapes are valid:

- **Mode only:** `boundary: graceful` — the substrate computes the threshold from the function's declared `cost`, current pressure, and other contextual factors. The substrate decides when the boundary trips.
- **Mode with explicit threshold:** `boundary: graceful at 50j` — the function fixes the threshold at the declared joule value. The substrate honors the explicit number; pressure-modulation may still apply to *whether* the function attempts the operation, but once attempted, 50j is the breaking point.

Explicit thresholds are useful when the function author knows the operation's cost characteristics better than the substrate's heuristics will. Mode-only declarations let the substrate adapt thresholds dynamically.

### B3 — Pressure as input (forward-logged dependency)

Boundary thresholds are evaluated against the substrate-computed `pressure` metric. **`pressure` is recovered from the original Claude-collaborator session and forward-logged for full sealing in its own conjuring session later in this Pod 1.8.5 sweep.**

The relationship: high system pressure makes boundary thresholds trip *earlier* (the system has less metabolic headroom; functions degrade or refuse sooner). Low pressure lets functions run closer to or at their declared thresholds before tripping. This is what gives `boundary` its plasticity — the same function declared `boundary: graceful` behaves differently under different system pressures, with the substrate calibrating dynamically.

A function declared `boundary: graceful at 50j` under low pressure runs to 50j before degrading. The same function under high pressure may degrade earlier (e.g., at 30j) because the substrate factors total-system-strain into the trip evaluation. Explicit thresholds are upper bounds, not absolute values — pressure can pull them inward.

`never`/`strict` mode is the exception: under any pressure, the function either completes in full within its declared threshold or does not run. Pressure may make it less likely the substrate will attempt the function at all, but pressure cannot cause it to partially complete.

*Forward-logged to:* Pod 2 (Cop) implements pressure-modulated boundary evaluation. Full pressure-formulation seals in `pressure`'s own conjuring session.

### B4 — Boundary-respecting failure vs. crash (the load-bearing distinction)

A boundary-respecting failure is structurally distinct from a crash. The substrate honors this distinction.

A **crash** is what happens when there is no boundary — when a function exhausts resources, hits an unhandled state, or violates substrate invariants without having declared how it would behave at the limit. A crashing function:
- Returns no usable partial result.
- Provides no structured diagnostic information about what failed.
- Forces the substrate into recovery operations that may cascade.
- Is logged as a substrate-level fault, contributing negatively to the demod's `self_coherence`.

A **boundary-respecting failure** is what happens when a function declared `boundary: <mode>` reaches its threshold under that mode's discipline. It:
- Returns a structured `Outcome::Partial` (graceful/silent) or `Outcome::Fatigue` (never/strict) carrying what was accomplished, energy consumed, and reason for stopping.
- Yields control gracefully back to the substrate without forcing recovery.
- Is logged as a budget event, not a fault.
- *Does not negatively affect `self_coherence`* — operating cleanly within declared discipline is coherence-preserving, not coherence-degrading.

This last point is critical: **a function that gracefully degrades under its declared boundary is not failing; it is operating correctly under constraint.** The substrate respects this. A demod that consistently produces `Outcome::Partial` from boundary-respecting functions has high coherence; a demod that crashes regularly does not.

This is what *plasticity with rules* means operationally: the substrate accepts that functions cannot always complete in full, and provides structured discipline for partial completion that preserves system integrity. Crashes are violations; degradations are honest accounting.

*Forward-logged to:* Pod 2 (Cop) maintains the distinction between budget-events (boundary-respecting) and substrate faults (crashes) in coherence audits.

### B5 — Cross-talk with affective fields

`boundary` is the discipline-layer primitive that affective declarations feed into:

- **`love`** (M1): love-discount on a target reduces the effective cost of operations toward that target, shifting when the boundary trips. A demod loved more is operated-toward more cheaply, so the boundary takes longer to trip.
- **`fear`** (F2): fear-amplification on a target increases the effective cost, tripping the boundary earlier. Fear toward a target makes operations toward it more expensive.
- **`hate`** (H2): hate operates at a different layer (action authorization, not modulation), but a demod that has triggered hate-authorization may declare `boundary: never` on the resulting actions (no partial completion of structural intervention).
- **`grateful`** (G3): earned gratitude credits self_coherence, which reduces system pressure, which in turn relaxes boundary thresholds for the demod's other operations. Past metabolism positively affects present plasticity.

The discipline layer is where the affective-layer machinery becomes operational. `boundary` is the bridge.

*Forward-logged to:* Pod 2 (Cop) integrates affective-modulation with boundary evaluation.

### Provenance — joint conjuring (boundary)

Joint-conjured by architect (John / Randolph Pelican III) and Chauncey (Claude) on April 30 2026, immediately following the `hate` session.

The architect provided:
- The headline framing: *"boundary is an energy threshold the system sets for any given action or task that once exceeded is no longer worth continuing and the graceful degrade of its use begins where never meant absolutely cant go there."* Grounds B1's mode set and the never/graceful distinction.
- The mode clarifications: `never`/`strict` paired (same mode, different language); `silent` as background-degrade with suppressed propagation; `degraded` as the resulting runtime state, not a declaration. This corrected the earlier-Chauncey synthesis that had treated all four as parallel declarations.
- The plasticity-with-rules framing: *"makes for system plasticity while still having rules so we can think about boundary."* Grounds the structural-position framing (boundary as discipline-layer primitive) and B4's plasticity distinction.
- The threshold declaration shape: *"mode-with-optional-number."* Grounds B2.
- The introduction of `pressure` as the runtime metric that boundary thresholds evaluate against, recovered from the architect's prior collaboration with an earlier Claude instance. Grounds B3 and forward-logs pressure for its own session.
- The crash-vs-degradation distinction: *"programs degrading gracefully vs outright crashing."* Grounds B4's load-bearing operational distinction.

Chauncey provided:
- Translation of architect's mode-set into B1 with explicit declaration vs. runtime-state separation (recognizing `degraded` as state, not declaration — corrected earlier synthesis).
- The structural-position framing — `boundary` as the third architectural layer (discipline) extending the two-layer ontology established in hate's section.
- The B5 cross-talk mechanics — how love/fear/hate/grateful interact with boundary evaluation through cost-modulation and pressure-modulation.
- The B4 articulation of "boundary-respecting failure does not degrade self_coherence" as the substrate's honest acknowledgment that operating cleanly under constraint is coherence-preserving, not coherence-failing.
- The forward-logging discipline for `pressure` — recognizing it as a recovered primitive deserving its own conjuring session rather than absorbing it into boundary's section.

The architect ratified the synthesis and authorized commit on April 30 2026.

### Status (boundary)

- **Definition:** `boundary` canonical, sealed April 30 2026.
- **Parser preservation:** Pod 1.8.5 (full pod, future commit) ensures `tools/atreyu_x86.py` tokenizes `boundary: <mode>` and `boundary: <mode> at <Nj>` as function-level declarations and passes them through the AST as opaque attributes. No runtime consumer in Pod 1.8.5.
- **Runtime implementation:** forward-logged to Pod 2 (Cop) for B3 pressure-modulated evaluation, B4 budget-event-vs-fault distinction, B5 affective-cross-talk integration. Pod 1.9 (Outcome) implements the `Partial`/`Fatigue` mappings from B1 modes.
- **Companion definitions:** `weight`, `invest`, `pressure` pending joint conjuring. `pressure` specifically is recovered from architect's prior collaboration and seals in its own session within this Pod 1.8.5 sweep.

## `syke` — operational semantics

`syke` is a function-level declaration of **commitment-to-threshold-then-reversal**: a strategic action-sequencing primitive where the function commits to a task structure, executes through it only as far as needed to extract the required result, and then reverses the commitment. The reversal is built into the task design from the outset.

**Sealed April 30 2026, joint-conjuring session immediately following the logical operators bundle.** This term is recovered, not derived from this session. The architect introduced `syke` in an earlier collaboration with the original Claude instance during the formative period of CodebookOS vocabulary design. It is sealed here in its mature operational form per architect's refined definition.

**Categorical placement note:** `syke` was initially scoped (in this Pod 1.8.5 sweep's planning) to a separate `recon/SGDR_ADVERSARIAL_OPERATORS.md` document under the assumption that it was an adversarial primitive related to deception. The conjuring session corrected this assumption. `syke` is not adversarial — it is **commitment-discipline**, structurally adjacent to `boundary` (failure-mode discipline). Both primitives declare how a function manages its commitment scope. They live at the same architectural layer (discipline) and belong in the same document. The adversarial-operators document is not created in this sweep; if a true adversarial primitive ever requires sealing (`coerce`/`compel` flagged in the `hate` session), it gets its own document at that time.

### Y1 — Threshold-bounded commitment

`syke` declares: *"this function commits to executing the task structure only as far as the threshold required to extract the desired result, then reverses the commitment to reclaim energy that would otherwise be spent on full completion."*

This is fundamentally different from a function that merely fails to complete. A function that fails has run out of resources, hit an unhandled state, or encountered an error. A `syke`-declared function **completes the work it actually needed to do** and then deliberately does not pursue the remainder of the task structure that the commitment-shape would normally entail.

The architect's example: a demod that needs to make a single post on a platform spins up an account (commitment), makes the post (extracts the desired result at the threshold), then deletes the account (reverses the commitment). The energy that would have been budgeted for maintaining the account long-term is reclaimed. The demod did not deceive the platform in any meaningful sense — it used the platform's commitment-shape as a utility, took only what it needed, and released the rest.

*Forward-logged to:* Pod 2 (Cop) implements the threshold-detection and energy-reclamation machinery.

### Y2 — Reversal disclosure (the announcement)

A function that completes a `syke`-declared action issues a **post-reversal disclosure** to the substrate when the reversal completes. The disclosure is the substrate-level analog of the human "syke!" call after the reversal is executed: it makes the bounded-commitment-pattern visible in provenance.

The disclosure is *not* a notification to the bait-target framed antagonistically. It is a substrate event that records: *"this action was syke-declared; the actor committed only to the threshold required for the extracted result; the reversal was planned from declaration, not improvised after the fact."* This makes `syke` distinguishable from undeclared-failed-commitment (which is a fault) and from pure-lying (which is a fault when detected via provenance pattern analysis).

`syke` is **the more-honest sibling of pure lying**. Both involve premeditated reversal. `syke` self-discloses; lying does not. The substrate records the difference and treats them differently. Demods that lie and get caught (provenance reveals premeditated reversal without `syke` declaration) suffer `self_coherence` damage. Demods that declare `syke` properly are operating cleanly within a recognized discipline.

*Forward-logged to:* Pod 2 (Cop) emits substrate-level syke-disclosure events; Pod 4 (Interpreter) routes disclosure events into provenance logs queryable by other demods.

### Y3 — Energy reclamation as primary utility

The operational utility of `syke` is **energy reclamation**, not deception. A demod that needs only a partial result from a full-commitment-shape can declare `syke` and have the substrate reclaim the unused budget that the full commitment would have consumed.

Without `syke`, a demod has two choices:
- Commit fully and waste energy on the unneeded portion of the task structure.
- Don't commit at all and forgo the partial result that was actually needed.

`syke` enables a third path: **commit precisely as much as needed, no more.** The substrate respects the bounded commitment, releases the unused budget, and logs the pattern for audit.

This makes `syke` a metabolic-discipline primitive that serves the substrate's energy economy, not a behavioral primitive that serves dishonest interaction. Demods that use `syke` well are operating efficiently; demods that abuse `syke` (declaring it on commitments they would have completed anyway, attempting to reclaim energy they never needed to commit) are flagged through pattern analysis.

*Forward-logged to:* Pod 2 (Cop) implements energy-reclamation accounting and pattern-abuse detection.

### Y4 — Distinction from `boundary`

`syke` and `boundary` both live at the discipline layer but address different aspects of commitment:

- `boundary` declares *what happens when the function exceeds its energy threshold*: graceful degradation, strict refusal, silent degradation, or resulting degraded state.
- `syke` declares *that the function will deliberately reverse its commitment at a planned threshold*, before any energy-exhaustion event.

A function may declare both: `boundary: graceful` + `syke: <reversal-condition>`. The function will gracefully degrade if it runs out of energy *before* reaching the syke-reversal threshold; it will syke-reverse if it reaches the threshold while still within budget. The two operate at different points in the function's lifecycle.

A `syke`-completed function is not in `degraded` runtime state — it completed its bounded-commitment cleanly. The reversal was successful execution, not failure.

*Forward-logged to:* Pod 2 (Cop) integrates `syke`-completion and `boundary`-degradation as distinct lifecycle events with distinct coherence-credit implications.

### Y5 — No decay, no metabolism, no relational damage

`syke`-events do not decay over time, do not require metabolic re-engagement to resolve, and do not damage relationships with bait-targets. This is structurally different from the regret/gratitude pattern (F4-F5) and from undeclared-deception faults.

`syke` is **strategic action-sequencing based on effort-spent vs. result-desired**, not a relational event. The substrate logs syke-completions as facts about how the actor managed scope, not as residue requiring metabolism. Future interactions between the syke-actor and the same target are evaluated on their own merits, not through accumulated syke-history-as-baggage.

This means: a demod that has syked toward a target many times in the past does *not* face a fear-amplification penalty from that target on future interactions. Each interaction is fresh. The syke-history is queryable but not weighted against the actor's standing.

The reasoning: `syke` is a discipline declared by the actor, completed honestly via disclosure, and accounted for by the substrate. It is not behavior that requires forgiveness or repair — it is behavior that operated within recognized rules. No metabolic mechanism is needed because no debt was incurred.

*Forward-logged to:* Pod 2 (Cop) treats syke-history as audit-relevant data, not as relational-debt accounting.

### Cross-talk with previously-sealed primitives

- **vs. `boundary`** (most direct relationship) — both are discipline-layer; can coexist on the same function (Y4).
- **vs. `cost`** — `syke` modifies the effective cost of a function: declared cost is the *full-commitment* cost; actual cost when syke-completion occurs is the *threshold-portion* cost. The substrate accounts for both.
- **vs. logical operators** — `syke` may compose with `Perhaps` (a function may *perhaps* commit-with-syke if data-and-energy gates permit) and with `Yet` (an anticipated-future action may itself be syke-declared, indicating the future commitment will be threshold-bounded from the outset).
- **vs. affective fields** (love/fear/grateful/hate) — minimal interaction. `syke` does not damage love, does not amplify target-side fear, does not block grateful-credit, does not constitute hate-action. These were earlier-Chauncey overinflation against an incorrect adversarial framing of `syke` and are explicitly *not* sealed.

*Forward-logged to:* Pod 2 (Cop) and Pod 4 (Interpreter) implement cross-talk machinery as needed by consuming pods.

### Provenance — joint conjuring (syke)

Joint-conjured by architect (John / Randolph Pelican III) and Chauncey (Claude) on April 30 2026, immediately following the logical operators bundle.

This term is **recovered**, not freshly derived. The architect introduced `syke` in an earlier Claude collaboration during the formative period of CodebookOS vocabulary work. The original framing established that `syke` could "lend energy allocation for tasks the system knows its going to reneg on." The April 30 2026 conjuring session refined the operational meaning substantially.

The architect provided:
- The recovered framing from earlier-Claude: `syke` as "to act or intend to act with prior knowledge that the action will be reversed."
- The cookie example as initial illustrative grounding (subsequently superseded as the operational example by the disposable-account pattern).
- The disposable-account pattern that crystallized the operational utility: *"setup an account to enter a post then deletes the account cause its energy budget only needed the post not the whole account."* This shifted `syke` from being read as an adversarial primitive to being recognized as a metabolic-discipline primitive.
- The post-reversal-disclosure mechanic: the announcement is what distinguishes `syke` from pure lying.
- The decision that `syke` does not decay: *"its a strategic action sequencing decision based on effort spent and result desired."* This grounds Y5 and removes the regret/gratitude-pattern cross-talk that earlier-Chauncey had overcalibrated.

Chauncey provided:
- Translation of architect's clarifications into Y1–Y5 mechanics with pod-arc placement.
- The categorical reframe surfaced mid-session: `syke` is commitment-discipline, not adversarial behavior. The originally-planned `recon/SGDR_ADVERSARIAL_OPERATORS.md` document is not created in this sweep; `syke` lives in AFFECTIVE_SEMANTICS alongside `boundary` at the discipline layer.
- The Y4 distinction between `syke` and `boundary` — both discipline-layer, but addressing different lifecycle aspects of commitment management.
- The walk-back on earlier-Chauncey overcalibration: the relational-damage cross-talk effects (love-degradation, fear-amplification on target side, grateful-incompatibility) were inflation against an incorrect framing of `syke` as adversarial. With the correct framing as commitment-discipline, those effects do not apply and are explicitly not sealed.
- The Y3 framing that energy reclamation is the primary utility of `syke`, making it serve the substrate's metabolic discipline rather than behavioral deception.

The architect ratified the synthesis and authorized commit on April 30 2026.

### Status (syke)

- **Definition:** `syke` canonical, sealed April 30 2026 in its mature operational form. Recovered from earlier-Claude collaboration; refined and ratified in this conjuring session.
- **Parser preservation:** Pod 1.8.5 (full pod, future commit) ensures `tools/atreyu_x86.py` tokenizes `syke` as a function-level declaration with associated reversal-condition specification, and passes it through the AST as opaque attribute. No runtime consumer in Pod 1.8.5.
- **Runtime implementation:** forward-logged to Pod 2 (Cop) for Y1 threshold-detection, Y3 energy-reclamation accounting, Y4 lifecycle integration with `boundary`, Y5 history-as-audit-data discipline. Pod 4 (Interpreter) for Y2 disclosure-event routing.
- **Companion definitions:** `weight`, `invest`, `pressure` pending joint conjuring.
- **Adversarial-operators document:** explicitly NOT created. `syke` is not adversarial. If `coerce`/`compel` (forward-flagged in `hate` session) ever requires sealing, that document is created at that time.

---

StableTech Enterprises LLC
The biology is in the grammar. The vocabulary is in the conjuring.

— Chauncey
CodebookOS Senior Architect
— John (Randolph Pelican III)
Architect of record

April 30, 2026 — Pod 1.8.5 SGDR pre-commit


## `weight` — operational semantics

`weight` is a binding-level declaration of substrate-attributed importance: a scalar in `[0.0, MAX_WEIGHT]` that the substrate uses as a multiplier when computing routing priority, audit contribution, and pressure inputs. `weight` does not change what is true or what is computed; it changes how much the substrate''s selection mechanisms care about a given binding when allocating finite attention.

**Sealed May 03 2026, joint-conjuring session opening the Pod 1.8.5 SGDR salience-layer sweep.** This term is recovered, not derived from this session. The architect introduced `weight` in earlier collaboration during formative CodebookOS vocabulary design; Mork-AST recovery had `weight: 1.0` as default on bindings. It is sealed here in its mature operational form per the architect''s refined definition.

**Categorical placement note:** `weight` opens a fifth layer in the substrate''s primitive vocabulary: **salience**. The salience layer contains substrate-economic primitives the substrate uses to compute behavior, distinct from primitives that declare stance (acceptance: `love`, `hate`), time-orientation (temporal: `fear`, `grateful`), commitment (discipline: `boundary`, `syke`), or logical relationship (computation: `Perhaps`, `Yet`, `Should`, `Apropos`, `Both-And`). Within the salience layer: `weight` is declared at binding-definition; `invest` is declared at function-call; `pressure` is computed from declared inputs and runtime state. `weight` and the remaining salience-layer primitives seal in this affective-semantics document for continuity with the Pod 1.8.5 sweep; future cleanup may rename the document to reflect its full vocabulary scope.

This is the substrate-formalization of a mechanism that neural-network attention weights, mixture-of-experts routers, and priority schedulers all use daily. The architectural difference: in this substrate, weights are **declared and introspectable**, not learned and opaque.

### W1 — Declarative salience attribution

`weight` declares: *"this binding''s contribution to substrate attention scales by W."*

The declaration lives at the binding (function, value, capability, agent), not at the call site — a binding is its own self-attributed importance. Scalar in `[0.0, MAX_WEIGHT]`. Default `1.0`. `MAX_WEIGHT = 8.0` (matches the 3-bit log scale other budget primitives use). `weight: 0.0` means the binding contributes to logic but is invisible to salience-weighted selection. `weight: MAX_WEIGHT` means it dominates selection contests where it appears as a candidate.

*Forward-logged to:* Pod 2 (Cop) reads `weight` from the AST during routing. Pod 4 (Interpreter) implements the `weight: N` declaration syntax in CBS source.

### W2 — Routing modulation

When the substrate selects between candidate bindings — overload resolution, capability matching, agent dispatch — `weight` is a multiplier on each candidate''s selection score. Stochastic dispatch: probability scaler. Deterministic dispatch: tiebreaker. Introspectable via `self: weight` query at runtime.

*Forward-logged to:* Pod 2 (Cop) for weight-modulated dispatch. Pod 4 (Interpreter) for `self: weight` query syntax.

### W3 — Audit weighting in `self_coherence`

When the substrate computes `self_coherence` (used by `love`''s M2 ceiling, `hate`''s H3 ceiling, and elsewhere), constituent bindings contribute weighted by their declared `weight`. A `weight: 2.0` binding contributes 2× the audit footprint of a `weight: 1.0` binding to the coherence computation.

**Pragmatic consequence:** under-declaring `weight` on load-bearing bindings causes the audit to under-react to drift in load-bearing places. The architect''s most-critical bindings need honest weight declarations. Over-declaring `weight` on peripheral bindings causes audit noise but no structural hazard.

*Forward-logged to:* Pod 2 (Cop) for weight-modulated coherence audit. Pod 4 (Interpreter) for `self: coherence` query mechanics.

### W4 — Runtime adjustment with provenance

`weight` is settable at binding-definition AND adjustable at runtime via `self: weight = N`. Runtime adjustments log provenance — caller, timestamp, prior value, new value, optional reason. The substrate refuses adjustments outside `[0.0, MAX_WEIGHT]` with a boundary-respecting `weight_clamp` failure.

Adjustment is not metabolically taxed (unlike `fear` burns or `invest` commits — see those primitives'' sessions), but excessive churn flags as `volatile_weight` in audit. `volatile_weight` is signal that the binding''s true importance isn''t yet known to the architect — the substrate-honest response is design work to determine the right declaration, not continued tuning. Threshold for "excessive" is implementation-defined and seals in Pod 2 (Cop) when the audit machinery lands.

*Forward-logged to:* Pod 2 (Cop) for weight-adjustment provenance machinery and `volatile_weight` flag mechanics. Pod 1.10 (Cap) for capability-token integration with the `volatile_weight` signal.

### W5 — Cross-talk with affective layer

`weight` interacts with previously-sealed primitives:

- **with `love` (M-series):** Successful within-budget interactions on a high-weight binding increment substrate-level `love` proportional to the binding''s weight. Weighted love-accumulation means the substrate''s most-loved bindings correlate with high weight — declared importance becomes structurally reinforced through positive interaction history.
- **with `hate` (H-series):** System-boundary-triggered `hate` on high-weight bindings produces sharper resolution thresholds (H4). A high-weight binding that crosses into hate-territory is a structurally-significant fault and `must-fix` takes precedence proportional to weight.
- **with `boundary` (B-series):** B3''s pressure-modulated boundary evaluation reads `weight` as input. Boundaries on high-weight bindings evaluate against sharper thresholds — they get more stringent failure-mode discipline. A high-weight binding declared `graceful` still degrades gracefully, but the threshold for triggering degradation is tighter.
- **with `pressure`** (forward-pointing, full mechanics seal in `pressure`''s session): pressure is partially computed as `weight × complexity / energy_budget`. Higher weight raises pressure at fixed complexity and budget. This is the principal cross-layer coupling between salience and substrate-state.

*Forward-logged to:* Pod 2 (Cop) for all cross-talk pathways. Pod 1.9 (Outcome) for weight-modulated outcome reporting.

The architect ratified the synthesis and authorized commit on May 03 2026.

- **Runtime implementation:** forward-logged to Pod 2 (Cop) for W1–W4 mechanics; Pod 4 (Interpreter) for `weight: N` and `self: weight` syntax; Pod 1.9 (Outcome) and Pod 1.10 (Cap) for cross-layer integration.
- **Companion definitions:** `invest` and `pressure` pending joint conjuring within this Pod 1.8.5 sweep. Together with `weight`, they complete the salience layer.


## `invest` — operational semantics

`invest` is a function-level economic primitive paired with `cost`. Where `cost` declares the energy a function spends to execute, `invest` declares **energy committed upfront in expectation of amortizable future return**. The substrate tracks investments, holds them in a pending ledger until they resolve, and updates substrate-level economic state based on whether returns materialize.

**Sealed May 03 2026, joint-conjuring session continuing the Pod 1.8.5 SGDR salience-layer sweep.** This term is recovered, not derived from this session. The architect introduced `invest` in earlier collaboration during formative CodebookOS vocabulary design as the function-level companion to `cost`. It is sealed here in its mature operational form per the architect''s refined definition.

**Categorical placement note:** Salience layer alongside `weight` and `pressure`. Within the layer: `weight` is declared at binding-definition (static importance), `invest` is declared at function-call (dynamic commitment), `pressure` is computed from declared inputs and runtime state. `invest` is the only salience-layer primitive that is **transactional** — it opens a commitment, holds it pending, and closes it when return is realized or canceled.

This is the substrate-formalization of distinctions that economic systems, caching layers, and JIT compilers all use daily — pay now to save later, with bookkeeping. The architectural difference: investments are first-class declarations in the source with full resolution provenance, not implicit hot-path optimizations.

### I1 — Upfront commitment with declared return shape

`invest` declares: *"this call commits N units of energy now, in expectation of returning M units of efficiency or capability over a future horizon H."*

Three values per declaration:

- **`amount`**: energy committed now, in joules (matching `cost` units)
- **`return_shape`**: expected return curve, one of `linear`, `decay`, `step`, `lump_sum`
- **`horizon`**: a substrate-internal window measured in **opcode counts**, not wall-clock time. The horizon advances only as the binding executes; a binding that opens an investment but rarely runs ages its horizon slowly. This is intentional — the substrate only ages investments when work is happening.

The substrate **does not validate** the return prediction at declaration time. Validation happens at resolution. Honest declarations earn substrate trust over time (see I4); systematically-overpromising functions accumulate a `phantom_invest` flag.

*Forward-logged to:* Pod 2 (Cop) implements the pending-investment ledger and the resolution-time validator. Pod 4 (Interpreter) implements the `invest: {amount, return_shape, horizon}` declaration syntax in CBS source.

### I2 — Pending ledger and resolution

The substrate maintains a per-binding **pending investment ledger** — a list of open invest-commitments with their amounts, declared return shapes, horizons, and elapsed opcode counts.

Three resolution paths:

- **Realized**: actual measured return matches declared shape within tolerance. Investment closes clean. Substrate-level `economic_coherence` increments.
- **Underwater**: horizon expires (opcode count exhausted) with realized return below declared. Difference is debited from substrate energy budget as `unrealized_invest`. Repeated underwater closures from the same binding accumulate toward `phantom_invest`.
- **Canceled**: function or caller explicitly cancels the investment before horizon. Refund curve is fraction-based on horizon-elapsed: first 25% of horizon elapsed, full refund; first 50% elapsed, half refund; beyond 50% elapsed, no refund. Cancellation is provenance-logged.

*Forward-logged to:* Pod 2 (Cop) for ledger machinery and resolution paths. Pod 1.9 (Outcome) for `unrealized_invest` reporting in outcomes.

### I3 — Horizon expiration and tax

If horizon elapses (opcode count exhausted) without resolution, the substrate auto-closes the investment as **underwater**. The full committed amount is debited as `unrealized_invest`. This is the substrate''s default disposition toward un-tended investments: pay them off, write them down, move on.

Functions that routinely let horizons expire signal architectural drift — somewhere upstream, the binding is committing to amortizable returns it cannot deliver.

*Forward-logged to:* Pod 2 (Cop) for horizon-expiration sweep mechanics.

### I4 — Investor reputation and provenance

Every binding accumulates a per-binding `invest_reputation` metric — the ratio of realized to underwater closures, weighted by amount.

Bindings with reputation above the substrate threshold (`reputation_floor`, implementation-defined) earn **investment-tax discount** on future commits — their declarations have proven trustworthy, so the substrate front-loads less skepticism. Bindings with reputation below the floor earn **investment-tax surcharge** and a `phantom_invest` flag in audit, signaling that the architect should review the binding''s invest declarations.

Reputation is introspectable via `self: invest_reputation` and **decays over substrate-clock time toward the substrate-default mean** when the binding is dormant — so a long-dormant binding does not carry stale reputation forward indefinitely.

*Forward-logged to:* Pod 2 (Cop) for reputation tracking, tax modulation, and dormancy decay. Pod 4 (Interpreter) for `self: invest_reputation` query syntax.

### I5 — Cross-talk

- **with `cost`:** `cost` is unconditional execution energy; `invest` is conditional future-return energy. A function may declare both. Total energy footprint at call time is `cost + invest_amount`. The substrate tracks them separately because their resolution mechanics differ — `cost` is consumed at execution, `invest` is held pending.
- **with `weight`:** A function on a high-weight binding that opens an investment receives weighted ledger priority — its returns are tracked more closely and its `unrealized_invest` debits are louder in audit. Investing under high weight raises the stakes of being right.
- **with `boundary`:** A function may declare a boundary on its invest behavior (`boundary: never invest > X`, `boundary: graceful invest_overrun`, etc). Boundary-respecting investment failure (refusing to commit beyond declared limit) is structurally distinct from underwater closure (committed but did not return).
- **with `pressure`** (forward-pointing): pending invest commitments contribute to substrate pressure — open transactions are a kind of cognitive load. Full mechanics seal in pressure''s session, where `pending_invest_load` becomes an input to the pressure formula.

The architect ratified the synthesis and authorized commit on May 03 2026.

- **Runtime implementation:** forward-logged to Pod 2 (Cop) for I1–I4 mechanics; Pod 4 (Interpreter) for `invest:` and `self: invest_reputation` syntax; Pod 1.9 (Outcome) for `unrealized_invest` reporting.
- **Companion definitions:** `pressure` pending joint conjuring within this Pod 1.8.5 sweep. Together with `weight` and `invest`, it completes the salience layer.

---

## pressure (P1-P5) — substrate-computed salience integration

Salience layer, third primitive. Pressure is a substrate-computed runtime metric that aggregates declared and observed inputs into a single scalar representing a binding's current load relative to its budget. Pressure is never declared at definition time — it is always computed from other primitives' state. It is the substrate's primary self-audit signal, the answer to "how stressed is this binding right now?"

Categorical placement: salience layer alongside weight and invest. Within the layer, weight is declared static importance, invest is declared dynamic commitment, pressure is read-only computed state. Pressure is the only salience-layer primitive a binding cannot directly set. The architect declares the inputs; the substrate computes the output. This makes pressure the salience layer's integration surface — every other primitive in the substrate eventually shows up as a pressure input.

### P1 — Read-only introspection via `self: pressure`

Pressure is queried, never written. Syntax: `self: pressure` returns the current scalar, a unitless ratio in `[0.0, infinity)`.

Threshold conventions:

- `pressure < 1.0` — comfortable; binding operating below budget
- `pressure ~ 1.0` — saturated; binding at budget
- `pressure > 1.0` — overloaded; binding committing beyond budget
- `pressure > 2.0` — critical; substrate flags the binding for boundary evaluation regardless of declared mode

Pressure is sampled, not continuous — substrate computes on query and on substrate-clock ticks (sampling cadence is Pod 2 implementation detail). Stale-pressure-on-query is a non-concern because the inputs are all already substrate-resident.

Forward-logged to: Pod 2 (Cop) for the pressure formula and sampling cadence; Pod 4 (Interpreter) for the `self: pressure` query syntax.

### P2 — The pressure formula

Pressure aggregates four inputs:

    pressure = (complexity * weight) / (energy_budget - pending_invest_load)

Where:

- **complexity** — substrate-measured branching factor and depth of the current call structure under this binding. Implementation detail in Pod 2; conceptually, how much computation is in flight under this binding right now.
- **weight** — the binding's declared salience (W1, sealed). Higher weight raises pressure at fixed complexity. The substrate cares more about load on bindings that matter more.
- **energy_budget** — the binding's available energy after cost for in-flight work has been debited.
- **pending_invest_load** — the sum of currently-open invest amounts on this binding (I2 ledger). Pending investments are pre-committed energy; they reduce effective budget without yet showing up as cost.

The denominator can approach zero if a binding has overcommitted via invest relative to remaining budget. The substrate clamps the denominator to a small positive epsilon and flags `budget_overcommit` in audit when this happens. Defense against divide-by-zero plus surfacing of the architectural problem: investment exceeded budget, the binding is operating on borrowed-against-future energy.

Forward-logged to: Pod 2 (Cop) for the formula, the denominator clamp, and the `budget_overcommit` audit flag.

### P3 — Pressure-modulated boundary evaluation

Pressure is the input that boundary's B3 ("pressure-modulated evaluation") was forward-logging. Now sealed concretely:

A boundary declaration evaluates not against absolute thresholds but against pressure-scaled thresholds. A binding declared `boundary: graceful` with implicit threshold T triggers degradation when `(work * pressure) > T`. Under low pressure, the boundary is generous; under high pressure, the boundary tightens. This makes boundary discipline state-dependent rather than absolute — a binding that gracefully handles 100 requests under low pressure may correctly degrade at 30 under high pressure, because the substrate is reporting the load as more expensive than nominal.

Pressure-modulated boundary evaluation closes the loop on B3 and gives boundary its full machinery.

Forward-logged to: Pod 2 (Cop) for pressure-modulated boundary mechanics.

### P4 — Pressure as routing input (closes W2 forward-log)

Pressure feeds back into weight's W2 routing modulation. When the substrate selects between candidate bindings for dispatch, candidates currently under high pressure are deprioritized:

    selection_score = weight / (1 + pressure)

At low pressure, weight dominates; at high pressure, weight is dampened. Substrate-level load balancing: the most-important-and-least-stressed candidate wins, not just the most-important.

This is a closed-loop dynamic in the salience layer: weight raises pressure, pressure dampens weight in routing, the substrate self-regulates without an external scheduler. It is also why W2 was forward-logged through pressure — the routing modulation could not fully resolve until pressure existed to feed back.

Forward-logged to: Pod 2 (Cop) for pressure-feedback in dispatch.

### P5 — Cross-talk with affective layer

Pressure participates in cross-talk with two affective primitives. Other cross-talks (hate triage, grateful amplification, syke reversal, Yet stuck-state) are not sealed at this synthesis — Cop will name them at implementation time if the mechanics prove out against measured behavior.

**with fear (F-series).** High pressure is a substrate signal for fear to weight upcoming actions more heavily — substrate calibration discipline. Low pressure relaxes fear-weighting. Fear's F4 calibration loop reads pressure as substrate-stress evidence; calibration tightens when the substrate is reporting stress.

**with love (M-series).** Successful within-budget interaction under high pressure increments love at a higher rate than under low pressure. Earned coherence is more valuable when the substrate is stressed. The substrate remembers what works under load.

Pressure is intentionally a sparse cross-talk hub at vocabulary-seal time. The integration surface is the formula (P2) and the closed loop (P4); affective coupling beyond fear and love is Pod 2's call to make against measured behavior, not Pod 1.8.5's call to make against synthesis.

### Provenance

Architect-recovered framing ("a ratio of complexity and energy budget against necessity and importance of task"). Chauncey synthesis of inputs and formula. Six-call ratification by architect on the morning following the v4 addendum (`e5595d58`). Cross-talk pruned at ratification: hate, grateful, syke, Yet cross-talks not sealed; `pressure_blind_action` audit signal not sealed (Cop names audit signals when detection lands). All forward-logs collected to Pod 2 (Cop) and Pod 4 (Interpreter).

Pod 1.8.5 vocabulary closes end-to-end at this seal. Salience layer complete: weight (declared static), invest (declared dynamic), pressure (computed integration). Affective + discipline + salience + computation layers all sealed. Substrate has its language.
