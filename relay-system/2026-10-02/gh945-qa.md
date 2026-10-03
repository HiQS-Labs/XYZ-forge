# RELAY · GH-945 final QA — radar verification-asset recommendation
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-02.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 2

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
     **A finding that asks for a behaviour change is a generalization unless you can paste the concrete
     input — a row, a value, a `file:line` — that fails under the current code** (GH-681: the gh673
     final QA relay generalized one late-error observation into "or a later invalid identity", the
     Producer implemented it, the same seat `[Pass]`ed it next round, and one historical NULL-URL
     ledger row then blanked every issue). Every `[Blocker]` or `[Should]` requesting a behaviour
     change MUST carry three lines: `Observed input:` (the failing input you saw), `Affected scope:`
     (the input predicate the change would govern), `Falsifier:` (the fixture or data that would show
     the change unnecessary or wrong, and its expected result).
     A `[Blocker]` must cite an observed failure. This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh945-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh945-relay-diff.patch** — the read-only path that
  `relay-drive.sh --artifact-file /Users/noelsaw/marathon-clones/forge-gh945-radar-verify-reco/temp/gh945-relay-diff.patch` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-02
- Definition of Done: commit 12d9a9c1 (GH-945) is QA-clean:
  (a) the new sibling section matches the settled design: conditional (real target AND detected asset), cited detection (Cite or drop), recommendation-only (never executes/gates), silent otherwise, extend-coverage framing, no reciprocal pointer;
  (b) body-only: frontmatter byte-identical to base, gh779 pinned strings intact;
  (c) consistent with radar's existing guardrails and the sanity-check sibling's shape;
  (d) ledger/pointer-doc changes sane.
Operational envelope: doc-only skill instruction, local developer CLI repo (XYZ-forge). Commensurate complexity; GH-831 applies (no new tests is CORRECT there).

## Reviewer questions (answer each; cite file:line or quoted spans)
1. Does the section fire only when both a qualifying target and a detected asset exist? Any wording that would make it fire (or nag) unconditionally?
2. Is the detection list concrete and reasonable (fuzzers/property suites/script targets/gate entry points)? Anything load-bearing misnamed?
3. Does anything in the diff let radar execute, gate, or auto-invoke anything? Any conflict with the recite/guardrails sections?
4. Is the insert position and voice consistent with the sanity-check sibling and the ## Boundaries table that follows?
5. Are the pointer doc and releases.sql changes consistent with the issue?
6. Commensurate complexity: over- or under-engineered for a doc-only sibling recommendation?

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: FAIL
Basis: The recommendation itself meets the settled design; the active pointer document needs lifecycle reconciliation before approval.
swept file: yes

Scope: read the entire Radar skill, entire new pointer doc, and entire seeded patch, including all ledger changes. Ledger review is bounded to the affected row, generation and receipts, not an audit of unrelated historical rows. Used direct text reads for these non-code artifacts; no Git commands or suites ran.

- [Pass] Q1–2: the trigger is conjunctive and relevant: “When Lens 2 surfaces” a mechanically checkable target, then “If one exists and covers” its surface; lines 664–667 explicitly require silence without either target or detected asset. The examples at skills/3-weekly/radar/SKILL.md:652–655 are recognizable asset families, not invented commands. Detection must cite its file/config/entry point (lines 659–661). No required change.
- [Pass] Q3–4: the addition authorizes a recommendation to the operator, not execution or gating (skills/3-weekly/radar/SKILL.md:656–667), and favors extending adjacent coverage. It sits immediately after the sanity-check sibling and before Boundaries, matching that sibling's operator-facing voice and non-reciprocal routing. No required change to the new recommendation's scope.
- [Pass] Q6/body-only: the seeded patch's sole skill hunk is an insertion at old line 644, after frontmatter and existing GH-779 sections; no existing skill bytes are removed. This supports unchanged frontmatter relative to the supplied patch base, not an independently fetched commit comparison. One short prose section is commensurate; no new suites or machinery.
- [Pass] GH-779 literal probe: command was Python reading SKILL.md and test/gh779-radar-ci-health.sh as text, extracting pins with `[shlex.split(x)[2] for x in test_text.splitlines() if x.startswith('pin "')]`, checking each against the skill, and removing the first pin in memory as a red control. Exit 0; decisive output: `pins=17 missing=[]`, `red_control_detected= True`. This is a text probe, not execution of the shell suite.
- [Should] Q5: promote the active GH-945 document and repoint its ledger row through the canonical DB verbs. The new doc remains `PROJECT/1-INBOX/GH-945-RADAR-VERIFY-ASSET-RECO.md` with `status: Proposed` (line 5), while the patch's roadmap row says `In progress` / `in-progress` and includes an accepted-start event. PROJECT/PDDA.md:272–281 requires promotion to 2-WORKING when execution starts; ROUTER.md's promotion rule requires DB repoint/update. Update its status and “just completed / next” row to reflect implementation and QA, preserving a next action for the PR. The issue number, URL, rating 55/35/50/85, three generation increments and receipt chain otherwise agree within the patch.
  Observed input: the GH-945 roadmap INSERT points to an inbox Proposed doc despite `accepted_start: true` and the already-present implementation.
  Affected scope: this one active GH-945 pointer and its ledger doc_path/status, not unrelated ledger history.
  Falsifier: an applicable explicit exemption allowing this implemented task to remain Proposed in 1-INBOX would remove the need; none is documented in the supplied task or lifecycle policy.
- [Nit] Whole-file sweep found a pre-existing wording tension: skills/3-weekly/radar/SKILL.md:322–324 requires executing guards in disposable clones, while line 677 says “Radar never executes anything.” Interpret the new sibling's non-execution rule locally to its recommendations; a follow-up clarification can distinguish diagnostic guard runs from executing fixes/recommended assets without removing GH-779's pinned behavior.
  Observed input: “run it against every open PR head” versus “Radar never executes anything.”
  Affected scope: existing diagnostic-execution wording only.
  Falsifier: an explicit existing definition limiting “executes” to fixes would resolve the ambiguity; the quoted boundary currently says “anything.”
- [Unverified — needs clone run] Shell gate/PDDA execution and exact-commit attestation remain for the harness's disposable full-clone gate. No suite result is claimed here.

Handing off to Producer (claude-a): reconcile the GH-945 active document and ledger pointer, then return for round 2.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
