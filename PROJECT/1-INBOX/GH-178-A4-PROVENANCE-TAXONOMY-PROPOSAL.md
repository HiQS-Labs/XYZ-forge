---
gh_issue: 178
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/178
title: "Proposal: full firsthand-vs-asserted provenance taxonomy (GH-178 A4's deferred fuller scope)"
status: "PROPOSAL — not promoted to 2-WORKING, not yet filed as its own GitHub issue, nothing implemented or shipped. This document argues for filing a new issue (see 'Process recommendation') rather than reopening #178 or being folded silently into #226."
created: 2026-07-17
updated: 2026-07-17
owner: noel
doc_type: design-proposal
complexity: 4
risk: 2
effort: 4
phases: 0
ratings_provisional: true
roadmap_exempt: true
related:
  - PROJECT/2-WORKING/GH-178-EPISTEMIC-RECONCILIATION-HARDENING.md
  - PROJECT/1-INBOX/GH-226-PROVENANCE-SUMMARY-SURFACE-COORDINATION.md
  - PROJECT/2-WORKING/GH-223-CONSULT-PY-CITATION-STAMP-PARITY.md
  - PROJECT/1-INBOX/GH-211-CONSULT-RELAY-TLDR-SUMMARIES.md
  - relay-automation/consult.sh
  - relay-automation/relay-turn-lib.sh
  - skills/consult/SKILL.md
  - GUIDING-PRINCIPLES.md
non_goals:
  - Not an implementation — no code, tests, or skill edits are made by this document.
  - Not a re-litigation or reopening of GH-178's shipped A2/A4 slice — that mechanism is treated as
    correct-as-shipped and as the extension point, not as something to redo.
  - Not vendoring, reproducing, or guessing the contents of the external `ra-to-xyz-transfer.md`
    ("seven transfers" / advisor-echo / false-consensus / reconciler-laundering / prompt-drift /
    model-version-drift catalog) — that document is unavailable to the author of this proposal (not
    in this repo, confirmed absent). Terminology below that resembles that catalog's named failure
    modes (e.g. "echoed") is this author's own mechanical guess at a checkable proxy, not a citation
    of that catalog's actual definitions. See "External dependency gap" below.
  - Not deciding GH-226's open question (whether fuller provenance and the GH-211 summary-surface
    rework land as one coordinated pass or split by repo/surface) — this document assumes GH-226's
    coordination question gets answered first and designs so either answer stays workable, but does
    not answer it here.
  - Not scoping relay-side (as opposed to consult-side) provenance — GH-178's A2/A4 slice and this
    proposal are both `consult.sh`-scoped; whether the relay turn/review path needs the same
    treatment is explicitly left to GH-226 or a later issue.
goal: >
  Propose the full firsthand-vs-asserted-vs-inference provenance taxonomy that GH-178's A4 item
  originally asked for and that its shipped 2026-07-08 slice deliberately did not cover (see that
  doc's A4 row and Non-goals section) — a mechanically-checkable distinction between a fact an
  advisor verifiably read/searched for itself, a fact that only traces back to text the operator put
  in the consult prompt, and an advisor's own unsupported inference — plus a bounded way to flag a
  reconciled verdict as conditional when it rests entirely on the asserted-only category. Scoped as a
  proposal to be evaluated, not a build to be merged.
---

# GH-178 A4 · full firsthand-vs-asserted provenance taxonomy — design proposal

## Status

| What was just completed | What's next |
|---|---|
| This proposal drafted 2026-07-17, in response to GH-178's explicit Non-goals hand-off ("A future issue can pick up the fuller distinction"). Nothing implemented. Not promoted to 2-WORKING. No GitHub issue filed for it. | Operator reviews this proposal, decides whether to file it as its own issue (recommended below, see "Process recommendation"), and whether to sequence it before or after GH-226's coordination question is resolved. |

## Why this document exists

GH-178's A4 item asked the Consult/Relay panel to distinguish facts an advisor verified firsthand
from facts the operator merely asserted in the prompt, and to flag verdicts that rest entirely on
asserted facts as conditional. What shipped 2026-07-08 (`relay-automation/consult.sh:310-336`,
reusing `relay-turn-lib.sh`'s `rtl_has_uncited_claim()`) is narrower: a presence/absence check —
does a claim-bearing line have *any* citation-shaped string (`file:line` or a quoted span) within a
3-line window? If not, stamp `NO FIRSTHAND VERIFICATION CITED`. That is a real, mechanically sound
check, and it is *not* what A4 asked for: it cannot tell the difference between an advisor that read
`consult.sh:117` itself and one that is simply repeating back a `file:line` string the operator typed
directly into the consult prompt. Both look identical to the shipped check — both have a citation
nearby. This proposal is the design for closing that specific gap.

---

## 1. The distinction itself

The shipped slice's blind spot is structural: **presence of a citation-shaped string is not evidence
of independent discovery.** An operator can — and in practice does — paste file paths, line numbers,
and exact quotes into a consult prompt as context. An advisor that repeats those back verbatim is not
demonstrating firsthand verification; it is demonstrating that it can copy text. The mechanically
checkable distinction this proposal proposes is therefore not "cited vs. uncited" (already shipped)
but **"citation traceable only to the prompt" vs. "citation not present anywhere in the prompt."**

Four categories, all computed per claim-bearing line (a "claim" is the same trigger the shipped
mechanism already uses — a `[Pass]` tag or `RTL_CLAIM_WORD_RE` match in `relay-turn-lib.sh`):

| Category | Definition | Mechanical test |
|---|---|---|
| **FIRSTHAND** | Claim has a nearby citation (existing `RTL_CITATION_RE` window match — `file:line` or quoted span), AND that exact citation string does **not** appear anywhere in the operator-supplied prompt text. | citation-window match = true; substring match against persisted `PROMPT_TEXT` = false. |
| **ECHOED** | Claim has a nearby citation, but that exact citation string **does** appear (verbatim, whitespace-normalized) in the operator-supplied prompt text. The advisor is citing something it was handed, not something it found. | citation-window match = true; substring match against `PROMPT_TEXT` = true. |
| **INFERENCE** | Claim has no nearby citation, AND the claim's own text is not a near-verbatim restatement of prompt text. This is the advisor's own reasoning/synthesis — not firsthand, not a prompt echo, and not automatically suspect; it is a distinct third thing the shipped binary check collapses into "uncited." | citation-window match = false; claim-line substring/fuzzy match against `PROMPT_TEXT` = false. |
| **UNSUPPORTED-ASSERTED** | Claim has no nearby citation, AND the claim's own text closely matches prompt text (the advisor is restating what the operator told it as if it were an independent finding). This is the shipped mechanism's exact trigger case, sharpened: today's check would flag this identically to INFERENCE; this proposal splits them because they carry different epistemic weight. | citation-window match = false; claim-line substring/fuzzy match against `PROMPT_TEXT` = true. |

Note what this taxonomy deliberately does **not** attempt: verifying that a present citation is
*accurate* (that `consult.sh:117` really says what the advisor claims it says). That remains out of
scope here, same as the shipped slice — see Non-goals and Section 4.

This is the author's own mechanical proxy for the kind of distinction the (unavailable)
`ra-to-xyz-transfer.md` catalog reportedly names "advisor echo" as one of five failure modes — see
"External dependency gap" below for why that correspondence is a guess, not a citation.

---

## 2. Where in the pipeline this gets computed

Extends the existing A2/A4 mechanism rather than forking a new one (per Principle 7 and the
Appendix's "new relay path vs. reuse" tie-breaker). Concretely, in `relay-automation/consult.sh`:

1. **New: persist the operator-supplied prompt text.** Today `consult.sh:117-126` builds
   `FULL_PROMPT` (boilerplate `PREAMBLE` + operator's `PROMPT_TEXT`) as an in-memory bash variable
   and passes it directly to each advisor CLI invocation — it is never written to `$RUN_DIR`. The
   ECHOED/UNSUPPORTED-ASSERTED test above needs something to diff citations against, so `consult.sh`
   would additionally write `$RUN_DIR/${LABEL}.PROMPT.txt` containing `PROMPT_TEXT` only (not
   `PREAMBLE` — the boilerplate is not operator content and would create false ECHOED matches on the
   preamble's own instructional language, e.g. its request that advisors "cite evidence"). This is a
   small, additive, non-containment-relevant write inside the run's own `$RUN_DIR` — no new allowlist
   or worktree-isolation surface.
2. **New predicate in `relay-turn-lib.sh`, sibling to `rtl_has_uncited_claim()`.** Something like
   `rtl_classify_claims(<transcript_file>, <prompt_file>)` that runs the same `awk` claim-detection
   pass (reusing `RTL_CLAIM_WORD_RE`/`RTL_CITATION_RE` verbatim so the "what counts as a claim/
   citation" definition stays in lockstep with B3 and the shipped A4 slice, per that file's own
   comment at `relay-turn-lib.sh:653-656`) but additionally checks each citation/claim span against
   the prompt file, and emits a count per category instead of a single boolean.
3. **Reuse the exact stdout + prepended-transcript + sidecar mechanism**, extended, not replaced:
   - The existing `NO FIRSTHAND VERIFICATION CITED` stamp keeps firing on exactly the cases it fires
     on today (INFERENCE ∪ UNSUPPORTED-ASSERTED, i.e. "no nearby citation") — **no regression**, and
     `test/consult.sh`'s existing assertions and GH-223's Python-parity port both stay valid as-is.
   - A new, additive sidecar per answered advisor — `$RUN_DIR/${LABEL}.${model}.PROVENANCE.txt` —
     carrying the per-category counts and, for any ECHOED claim specifically, the matched prompt
     span, so a reader can see *which* citation was a prompt-echo without re-deriving it.
   - A new stdout `warn` line only when ECHOED claims are found on an otherwise-"cited" transcript
     (this is the actual new information: a transcript that looks clean under the shipped check but
     is entirely prompt-echoed underneath it).
4. **Nothing in step 1-3 touches a headless turn's write path, allowlist, or worktree isolation** —
   this is read-only post-hoc analysis of already-produced transcripts plus one new read-only sidecar
   file, the same containment posture the shipped A2/A4 mechanism already has.

Why not compute this earlier (e.g., have the advisor self-report firsthand vs. asserted in its own
output)? Because that would be model-compliance-dependent, not structural — exactly the failure mode
GH-178's own A4 row calls out from its live example ("a confident, dated, self-hedged claim that was
still wrong — the hedge alone didn't prevent the error"). The mechanism must stay a mechanical,
outside-the-model check, consistent with why the shipped slice is a post-hoc stamp rather than a
prompt instruction alone.

---

## 3. Flagging a verdict that rests entirely on asserted facts as conditional

This is the part of A4 the shipped slice explicitly does not attempt, and it is genuinely harder than
Sections 1-2, because it requires connecting a **downstream** claim (a line in the *reconciled*
verdict — the synthesis an agent writes after reading all advisors' answers, per
`skills/consult/SKILL.md`'s "Disagree → Agree → Reconciled call" structure) to the **upstream**
per-advisor facts that back it. Sections 1-2 classify facts within a single advisor's transcript;
this section is about tracing a conclusion that may synthesize several advisors' facts into one
sentence.

**Full dependency tracing (which exact verdict sentence depends on which exact upstream fact) is out
of v1 scope** — see Section 4 for why. What this proposal designs instead is a **bounded mechanical
backstop**, applying the same claim/citation-window technique one layer up:

- The reconciliation/synthesis step is currently free-form prose written by whichever agent runs the
  consult (per `skills/consult/SKILL.md`), not a deterministic script — GH-211 already reshaped this
  layer's *format* (TLDR + sorted Blocking/Worth-doing/Skip categories) without touching its
  semantics. Any verdict-provenance change must plug into that already-changed shape, not a stale
  pre-GH-211 one (this is exactly the coordination gap GH-226 opened to own — see Section 7).
- Proposed addition to `skills/consult/SKILL.md`'s reconciliation instructions: the reconciling agent
  states, next to each "Reconciled call" claim, which advisor(s)' FIRSTHAND-category facts (from
  Section 1-2's per-advisor sidecars) support it — a lightweight citation-of-citations, not a new
  data structure.
- A deterministic backstop mirroring `rtl_check_uncited_findings()`'s existing per-line downgrade:
  scan the "Reconciled call" section text for a claim-word match (`RTL_CLAIM_WORD_RE`, the same
  vocabulary already used) with **no FIRSTHAND-tagged reference nearby** (all upstream support was
  ECHOED, INFERENCE, or UNSUPPORTED-ASSERTED, or absent) → mechanically append
  `[CONDITIONAL — rests on asserted-only facts]`, same non-destructive prepend/append posture as the
  shipped mechanism (never deletes or rewrites the agent's actual words).

**Honest limitation of this backstop:** it checks whether the *reconciliation prose itself* cites a
FIRSTHAND-tagged upstream fact nearby — it does not verify that the cited fact *actually entails* the
verdict sentence (that would require semantic understanding, not string matching). It catches "the
reconciling agent asserted a verdict and cited nothing/only-echoed facts near it," which is the same
class of gap B3 and the shipped A4 slice already catch one layer down — extended upward, not a
qualitatively new capability. True dependency tracing (Section 4's deferred item) would need either a
structured per-claim ID scheme threaded through advisor output and the reconciliation text, or an
LLM-graded verification step — both bigger asks, deliberately deferred.

---

## 4. Explicit scope boundaries — v1 vs. deferred

Per Principle 7 ("least code that clears the bar — no premature abstraction"): a smaller
mechanically-checkable slice that gets most of the value, not a big-bang taxonomy.

**v1 (proposed for a future implementation pass):**
- Persisting `PROMPT_TEXT` to a sidecar file per consult run (Section 2, step 1).
- The 4-category per-claim classification (FIRSTHAND / ECHOED / INFERENCE / UNSUPPORTED-ASSERTED)
  as a new predicate sibling to `rtl_has_uncited_claim()`, with the existing `NO FIRSTHAND
  VERIFICATION CITED` stamp's trigger condition unchanged (no regression).
- The new `PROVENANCE.txt` per-advisor sidecar with category counts.
- The bounded reconciliation-layer backstop in Section 3, scoped only to `skills/consult/SKILL.md`'s
  synthesis instructions plus one deterministic scan — not a new data structure or storage format.

**Explicitly deferred, and why:**
- **Citation accuracy verification** (does a present `file:line`/quote actually say what's claimed) —
  same non-goal the shipped slice already carries; would need a real content-diffing engine against
  the advisor's assigned worktree, a materially larger and riskier build (touches read access into
  worktree state during post-hoc analysis, not just transcript text).
- **True semantic dependency tracing** between a specific verdict sentence and a specific upstream
  fact (Section 3) — would need either a structured per-claim ID contract threaded through every
  advisor's output format (a larger, more invasive change to the consult output contract than
  anything shipped so far) or an LLM-graded verification pass, which per Principle 12 would itself
  need independent/separated grading, adding real cost. Flagged as a possible v2, not v1.
- **The external failure-mode catalog** (advisor echo / false consensus / reconciler laundering /
  prompt drift / model-version drift, and the "seven transfers") — still not vendored, still not
  owned here, per GH-178's existing Non-goals. This proposal's ECHOED category is this author's own
  guess at a mechanical proxy for one of those five named modes, not a reproduction of it.
- **False-consensus detection** (two+ advisors agreeing, but for the same ECHOED/asserted reason
  rather than independent verification) — a cross-advisor check, not a per-advisor one; likely also
  inside the external catalog's scope; deferred to a later pass once/if that catalog is obtained.
- **Relay-side provenance** (as opposed to consult-side) — GH-178's A2/A4 slice and this whole
  proposal are `consult.sh`-scoped. Whether `relay-automation/`'s producer/reviewer turn loop needs
  the same treatment is a real open question this document does not answer — see Section 7 and
  GH-226.
- **`utils/py/consult.py` parity** — GH-223 already tracks porting the *shipped* slice to Python; a
  v1 implementation of this proposal would need its own follow-on parity item, not scoped here.

---

## 5. Self-graded checklist (GUIDING-PRINCIPLES.md Appendix)

Run honestly, not defensively — including where this proposal falls short.

| # | Heuristic | Verdict | Notes |
|---|---|---|---|
| 1 | Containment preserved? | **Pass** | Everything proposed is read-only post-hoc analysis of already-produced transcripts plus one new sidecar write inside `$RUN_DIR` (the consult run's own output directory). No new headless-turn write path, no allowlist change, no worktree-isolation change. |
| 2 | Skill-first respected? | **Pass, with a caveat** | Section 3's reconciliation-layer change is explicitly scoped as a `skills/consult/SKILL.md` edit, not an improvised harness workaround. Caveat: this document does not itself make that edit — a future implementation pass must actually land it in the skill, not bolt it on elsewhere. |
| 3 | Coordination through the event log? | **Pass (trivially)** | Nothing here reads or writes `.tick/` state; this is entirely transcript/prompt-text analysis. Not applicable rather than actively satisfied. |
| 4 | Done verifiable? | **Fails today, by design** | This is a proposal, not an implementation — there is no runnable gate yet. A future implementation pass would need: new `test/consult.sh` assertions (mirroring the 5+2 already covering the shipped slice), a Python-parity assertion once ported, and `./validate.sh` green. Naming this honestly as "not yet verifiable" rather than claiming a false pass. |
| 5 | Drift reduced, not created? | **Pass** | Explicitly extends `rtl_has_uncited_claim()`/`RTL_CLAIM_WORD_RE`/`RTL_CITATION_RE` and the stdout+transcript+sidecar stamp pattern rather than forking parallel definitions. Explicitly defers to GH-226 rather than reworking the operator-facing summary surface a second, uncoordinated time. |
| 6 | Next action singular? | **Pass** | Section 7 gives one explicit recommendation (file a new issue, coordinated with #226) rather than presenting multiple options as equally valid. |
| 7 | Operator control explicit? | **Pass** | The proposed `[CONDITIONAL — ...]` stamp is additive/non-destructive (append, never delete/rewrite), matching the shipped mechanism's posture. No auto-retry, no silent masking proposed anywhere. |
| 8 | Four pillars (Attested/Relevant/Fresh/Structured)? | **Partial** | **Attested**: strong — every mechanism reference cites real current code (line ranges in `consult.sh`, `relay-turn-lib.sh`). **Fresh**: reflects the 2026-07-17 state of `consult.sh`/GH-226/GH-223, checked directly against the live files, not from memory. **Structured**: one shape (numbered sections matching the task's own ask). **Relevant is the honest miss**: a 4-category taxonomy plus a verdict-layer backstop is more moving parts than the "least code that clears the bar" principle prefers on first instinct; see the weakest-part callout below. |

**Tie-breakers:** Containment vs. speed — not in tension here (nothing proposed trades containment for
speed). New relay path vs. reuse — reuse, explicitly (Section 2). Ambitious vs. resumable — the v1/
deferred split in Section 4 exists specifically so a future implementer can land v1 alone and stop; it
does not require the deferred items to be resumable.

**Reject/escalate conditions:** none triggered — no headless path lacking allowlist/isolation/
commit-bypass guard is proposed; "not yet verifiable" is stated honestly rather than claimed as done;
no relay-lane or event-log-kernel change is proposed without a decision record (none is proposed at
all); no hardcoded paths or silent destructive ops.

**Honest weakest point:** the 4-category split (FIRSTHAND/ECHOED/INFERENCE/UNSUPPORTED-ASSERTED) is
more surface area than the 1-bit check that shipped, and Section 8's heuristic-4 failure is real, not
cosmetic — there is no running code proving any of this actually holds up against a real prompt/
transcript pair yet. A tighter v0 might collapse ECHOED and UNSUPPORTED-ASSERTED into one bucket
("traces to the prompt") for a first cut, deferring the ECHOED/UNSUPPORTED-ASSERTED split (whether the
prompt-echo carries a citation dressing or not) to a follow-up once the prompt-persistence plumbing
and substring-match logic are proven out on real data. This proposal presents the 4-category version
because the task asked for "the distinction itself" in full, but an implementer applying Principle 7
strictly should seriously consider shipping the 2-category collapse first.

---

## 6. External dependency gap — `ra-to-xyz-transfer.md`

That document is not in this repo and was not available to write this proposal — confirmed absent,
referenced-not-vendored per GH-178's own Non-goals. Before finalizing this taxonomy for
implementation, it should be checked against that document for at least three things: (1) whether its
"advisor echo" failure mode is defined more precisely or differently than this proposal's ECHOED
category guesses at, in which case this taxonomy's terminology and mechanical test should be
reconciled to match rather than drift into a second, competing definition of the same concept; (2)
whether "false consensus," "reconciler laundering," "prompt drift," or "model-version drift" imply
additional mechanical checks that belong in this same v1 slice rather than being deferred, if any of
them turn out to be cheap; and (3) whether the "seven transfers" it defines include a transfer this
taxonomy's Section 1 categories map onto directly, which would mean adopting that document's naming
instead of this proposal's ad hoc one. Anyone implementing this should either obtain and read that
document first, or explicitly accept (as GH-178's own Non-goals already does) proceeding without it
and risk a later terminology/scope reconciliation pass.

---

## 7. Process recommendation

**Recommendation: file this as its own new GitHub issue, explicitly linked to and coordinated with
#226 — do not reopen #178, and do not fold it silently into #226 as buried scope.**

Reasoning:

- **Principle 11 (issue-first)** requires a GH issue before any non-trivial change lands, and this is
  unambiguously non-trivial — new persisted state (a prompt sidecar), a new classification predicate,
  a new sidecar format, and a `skills/consult/SKILL.md` edit. It is well past the "≤2-3 line fix"
  exemption.
- **Not #178**: that issue's own Status line already reads "all five #178 items now have a shipped
  fix," and its Non-goals section explicitly says "A future issue can pick up the fuller distinction"
  — #178 is written and closed-shaped as a finished record of what shipped 2026-07-08. Reopening it to
  attach a materially different, larger, unshipped design would blur that historical record and
  violate the same "one canonical source of truth, no drift" spirit (Principle 2) this proposal is
  itself trying to serve — #178 should stay the record of what happened, not become the record of
  what might happen next.
- **Not silently folded into #226**: #226 is a *coordination* issue — its explicit job (see its
  Definition of done) is to inventory the GH-211 summary-surface work and this taxonomy's future
  home, and decide whether they land as one pass or split. Its own Non-goals says "Not implementing
  the fuller provenance taxonomy in this capture doc" — meaning #226 has already declared this
  document's content out of its own scope. Treating this proposal as done once #226 exists would
  contradict #226's own stated boundary.
- **A new, linked issue respects both**: it gives this design its own machine-queryable signal stream
  (satisfying Principle 11) while explicit `related:` links (already in this doc's frontmatter) keep
  #226's coordination question answerable — #226 can decide, once this issue exists, whether its
  execution happens standalone or merges into whatever #226 spins off. That ordering also respects
  GH-226's own Definition of done, which anticipates exactly this branch ("promote #226... or split
  into narrower follow-up issue(s)").

Concretely: open the new issue referencing this document, cross-link it from both #178 (as "the
future issue" its Non-goals already promised) and #226 (as one of the "narrower follow-up issues" its
Definition of done anticipates), and let #226's coordination question resolve before implementation
starts — implementing this taxonomy's v1 before knowing whether the operator-facing surface is being
reworked again by #226 risks exactly the double-edit GH-226 exists to prevent.
