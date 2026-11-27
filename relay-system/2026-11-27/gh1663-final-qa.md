# RELAY · GH-1663 final QA: ci-optimize SKILL.md small defects
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-27.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 3

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
     change MUST carry `Observed input:`, `Affected scope:` (the input predicate the change would govern),
     and `Falsifier:` (the fixture or data that would show the change unnecessary or wrong, and its expected
     result). `Observed input:` accepts two strict, non-speculative forms:
     (1) **Form 1 (observed failure or artifact contradiction):** a failing probe/gate output, or a concrete
     `fileA:line` vs `fileB:line` contradiction (e.g. IAM SA mismatch, inverted test, sibling guard omission);
     (2) **Form 2 (unrunnable runtime hazard trace):** permitted ONLY when reproduction requires an external
     service, multi-process concurrency, or a browser/container runtime forbidden in the relay worktree —
     must supply a hop-by-hop `file:line` trace plus an exact `Clone probe:` command/script for the Producer's
     disposable full clone. Default severity for an unexecuted Form 2 hazard is `[Should]`.
     A `[Blocker]` must cite an observed failure (Form 1); an unexecuted Form 2 hazard stays `[Should]`
     until a probe reproduces it, and remains pending probe verification until the Producer runs
     `Clone probe:` in a disposable full clone.
     A finding from an earlier round stays open, and the verdict stays failing, until new evidence closes it.
     This includes earlier [Nit] findings; only a newly raised [Nit] with VERDICT: PASS on STATUS: Approved remains optional.
     This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking Form 1 evidence and lacking a complete Form 2 trace + `Clone probe:` as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request lacking Form 1 evidence and
     lacking a complete Form 2 trace + `Observed input:` / `Affected scope:` / `Falsifier:` / `Clone probe:`).
     For every Form 2 `Clone probe:` finding, read the probe before running it — refuse any probe that reaches
     the network, credentials, or paths outside the disposable clone and record the refusal as
     `[Unverified — clone probe failed/unavailable]` — then execute safe probes in a disposable full clone and
     record one of three outcomes: (a) Reproduced → fix and paste failing-before / passing-after probe output;
     (b) Falsified → `Declined — falsified by clone probe: <cmd → exit + output>`; (c) Errored, refused, or
     environment unavailable → keep the finding OPEN (`[Unverified — clone probe failed/unavailable]`, blocking
     `STATUS: Approved` until re-run cleanly or escalated/parked). Make approved changes, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Manual relay: commit only the relay file** (`relay(gh1663-final-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1663-CI-OPTIMIZE-SKILL-DEFECTS.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1663-CI-OPTIMIZE-SKILL-DEFECTS.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude
- Started: 2026-11-27
- Definition of Done: the committed change satisfies the approved plan (`.relay-artifacts/GH-1663-CI-OPTIMIZE-SKILL-DEFECTS.md`, plan QA approved in `relay-system/2026-11-27/gh1663-plan-qa.md`): `skills/4-occasional/ci-optimize/SKILL.md` is self-consistent and portable; no principle's requirement or the rubric's scoring changed; the retained checks substantiate the claims.

### Operational envelope and non-goals
- Documentation-only edit of one skill file in XYZ-forge. Grade against the plan's requirements and commensurate complexity; the repo's own threat model governs. Challenge bloat; do not manufacture scope. `skills/2-daily/merge-cleanup/` is another agent's parallel work and must not be touched.
- XYZ-forge forbids new tests (`AGENTS.md` *No new tests*, GH-831): a new `test/` suite, `validate.sh` entry or gate machinery in the diff is itself a finding. The retained checker lives in the evidence directory `TESTS-RESULTS/2026-11-27+GH-1663/` as a manual check with `provenance.jsonl`.

### What to review
Run read-only: `git diff 52813e56f HEAD --stat` and `git diff 52813e56f HEAD -- skills/` (base is 52813e56f). Read the whole of `skills/4-occasional/ci-optimize/SKILL.md`, the plan, and `TESTS-RESULTS/2026-11-27+GH-1663/` (`provenance.jsonl`, `check_ci_optimize.py`, `base.out.json`, `candidate.out.txt`, the two suite logs). You may run the checker read-only with `export PYTHONDONTWRITEBYTECODE=1` and output under `.relay-scratch/`; you may NOT run `validate.sh` or `test/*.sh` here (the two existing suites were run in a disposable full clone: see the logs; mark anything only measurable that way `[Unverified — needs clone run]`).

### Questions (cite file:line)
1. Is each requirement in the plan's per-file change list (edits 1-6) implemented exactly, with no principle's requirement, no P13/P14 text, no score row or band changed? Quote the diff spans.
2. Is each of the six extra statements true as written: the new heading intro, the scorecard note, "Principles 1-12" in the roadmap sentence, "P9 Hosted CI" in the Wave 4 node, the description wording, and the provenance split by repo? Does anything read as "ignore P13/P14"?
3. Provenance: are the nine numbers split correctly by subject? Spot-check at least four rows of the `issue-subject-lookup` records in `provenance.jsonl` against the sentence in SKILL.md. (The plan records that the brief proposed labeling all nine as XYZ-forge; the plan departs from it with evidence.)
4. Does the retained checker substantiate the claims: base exit 1 with a1-a8 false, candidate exit 0, six single-edit red controls each flipping exactly their own assertion? Run it (read-only) on the candidate and base (`git show 52813e56f:skills/4-occasional/ci-optimize/SKILL.md` into `.relay-scratch/`) and quote exit statuses. What prevents an unfixed or partially fixed candidate from being reported as delivered, and where is the observed rejection?
5. Is the persisted rating (30/15/45/85, from the operator brief) consistent with the evidence (docs-only, no runtime effect)?
6. Is the diff surgical and DRY (one skill file plus the harness's plan, ledger, relay and evidence files; no new suite or registry entry; no `/Users/` absolute path; nothing under `skills/2-daily/merge-cleanup/`)?
7. Anything wrong, missing or over-engineered, including pre-existing defects in the skill file that you can prove?

Required lines in your block: `swept file: yes|no`, `VERDICT:` (PASS, FAIL or PARKED), `Basis:`. Use bold labels, never markdown heading lines. Set `STATUS: Approved` only if it passes.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
