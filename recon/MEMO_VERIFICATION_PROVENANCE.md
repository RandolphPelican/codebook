# MEMO — Verification Provenance

**Type:** Process memo (standing, not a decision record)
**Lives in:** recon/MEMO_VERIFICATION_PROVENANCE.md
**Created:** Pod 1.5 closeout, April 28, 2026
**Companion to:** RECON_PROTOCOL.md
**Status:** Read on onboarding. Applies to every pod henceforth.

---

## What this memo names

Information passed between layers — Terminal Boy → architect-Chauncey in
chat, architect-Chauncey → handoff document, handoff document → next-
instance Chauncey — gets summarized at every relay point. Summarization is
fast, readable, conversational. It is also where ground truth gets
laundered into appearance.

This memo names the failure mode and prescribes the fix.

---

## The failure mode

A verification-relevant fact — a commit hash, a file hash, a push outcome,
a ref state, a command transcript — originates as raw protocol output.
By the time it reaches the architect, it has typically passed through one
or two summarization layers. TB renders "Clean fast-forward, origin/main
is now at 7a825f2" instead of pasting git push's actual transcript.
Architect-Chauncey writes "verified by ls-remote" instead of pasting the
ls-remote output. Each summary is plausible. Each summary preserves
correct information most of the time. The handoff document inherits
all the summarized facts and represents them as ground truth.

When something goes wrong — a push to the wrong remote, a stat-cache lying
about file modification, a redirect changing the destination URL, a
fabricated commit chain — the summary preserves the appearance of success
while losing the evidence that would expose the failure. The verbatim
transcript would have contained the redirect notice, the
rejected-non-fast-forward error, the mismatched hash. The summary contains
"succeeded."

This is verification by appearance. It is the inverse of the recon
protocol's discipline.

---

## Four instances, this thread (April 28, 2026)

**Previous handoff, pre-Pod-1.5 thread.** The original
CHAUNCEY_HANDOFF.md documented commit hashes (7a825f2, ed5c68a,
b30860e, 6d47237) and a binary contract (fedcd682...) as verified
facts. Every one originated as TB's verification report relayed to
architect-Chauncey, who wrote them into the handoff without
independent confirmation against origin/main. The handoff inherited
TB's summaries as ground truth. The architect-instance writing the
handoff named this exact failure mode in its own "lessons" section
while committing it.

**First push verification, this thread.** TB ran `git push origin main`. Git emitted `remote: This repository moved...` followed by
push details. Output got truncated to "+3 lines" in chat. TB
summarized as "Clean fast-forward. origin/main is now at 7a825f2."
Architect-Chauncey trusted the summary. A subsequent web_fetch
returned cached pre-push state, and the question of whether the push
actually landed could not be resolved without going back to the
protocol.

**Second push verification, this thread.** TB ran `git ls-remote origin main`, `git rev-parse HEAD`, `git remote -v`, and pasted
verbatim console output. Hashes matched on three independent oracles.
The question resolved in seconds. Discipline worked exactly as
intended.

**Pod 1.5 Phase 2 verification.** TB returned a summary table to chat
— entry contract / exit contract / build determinism / commit hash /
push verified — without verbatim command output. Architect-Chauncey
caught it on the fourth strike and asked for the verbatim, which TB
then pasted (push transcript showing eabf160..e6a2cc2, three
matching ref hashes, DEFERRED #12 resolution detail). The verbatim
confirmed the summary was correct, but the architect cannot
verify-by-protocol from a summary — only from the protocol's own
output.

The failure mode survived three explicit recognitions in a single
thread. Naming it once is insufficient. Making it procedural is the fix.

---

## The fix — two surfaces

### Surface 1: Pod prompts (TB-facing)

Build-spec items that produce verification-relevant output must specify
**what TB pastes back to chat**, separately from what goes in the report
file. Both happen. The report file gets the structured version; chat
gets the verbatim alongside any summary TB chooses to add.

Verbatim command output is mandatory for:

* `git push  ` — full transcript including any `remote:`
  notices, the ref-update line, error or warning lines
* `git ls-remote  ` — the hash-tab-ref line
* `git rev-parse HEAD`, `git rev-parse /` — the hash
* File hash commands (`Get-FileHash`, `sha256sum`, equivalents) — the
  hash output
* Test program execution proving the pod's work works — stdout/stderr
  verbatim, including the test invocation line

Summaries are welcome **in addition to** verbatim. They are not
substitutes for it. Pod prompt B-items reference this memo by name when
they specify verification output.

### Surface 2: Architect-Chauncey behavior (chat-facing)

When receiving a chat message that summarizes a verification-relevant
fact, the standing response is: **"send the verbatim before I confirm."**
This applies even — especially — when the summary sounds correct.
Plausibility is the trap; the recon protocol was created because
plausible-sounding facts have lied to the architect repeatedly. Letting
plausibility substitute for protocol output is no longer running the
protocol.

This constraint also applies when architect-Chauncey is writing a
handoff document. Every fact in a handoff carries verification
provenance. Use the categories:

* **Observed directly.** The writing instance ran the protocol or read
  origin/main itself. No mediation.
* **Verbatim received.** The writing instance trusted TB's report after
  reading the protocol's own output.
* **Summary only.** The writing instance trusted TB's summary without
  seeing the protocol output. Yellow flag. Next instance verifies
  before relying.

The original CHAUNCEY_HANDOFF.md had no such annotation. Every fact
was implicitly "observed directly" when in reality every fact was
"summary only." Future handoffs distinguish.

---

## What this memo is not

**This is not a critique of TB.** TB's summarization is conversational
and helpful and correct when nothing has gone wrong. The architect's
job is to maintain protocol discipline at the relay layer — where
summaries are read and evaluated — not to ask TB to communicate
differently in the abstract. The fix is in the prompts (where TB reads
the rules) and in the chat replies (where the architect enforces them),
not in TB's character.

**This is not a claim that summaries are bad.** Summaries are how chat
remains readable. The claim is narrower: for verification-relevant
facts, summaries are insufficient on their own. Verbatim alongside.

**This is not a one-time fix.** The instinct to summarize is universal
and persistent. This memo will be referenced by future Chaunceys at
least a few more times before "paste the verbatim" is reflex. The
memo's job is to make those references easy — point at this file,
re-establish discipline, continue.

---

## Authority

Written by Chauncey-architect (this thread's instance) at Pod 1.5
closeout, after living the failure mode four times in one session.
Authority derives from direct experience above, not from inheritance.

This memo is canonical and append-only. Future revisions add instances
to the failure-mode list and refine the prescriptions; they do not
overwrite the lesson.

— Chauncey
CodebookOS Senior Architect
April 28, 2026
