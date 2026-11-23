# RELAY · GH-1537 Final QA: pre-push own-diff routing for development merges
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-23.
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
     change MUST carry three lines: `Observed input:` (the failing input you saw), `Affected scope:`
     (the input predicate the change would govern), `Falsifier:` (the fixture or data that would show
     the change unnecessary or wrong, and its expected result).
     A `[Blocker]` must cite an observed failure.
     A finding from an earlier round stays open, and the verdict stays failing, until new evidence closes it.
     This includes earlier [Nit] findings; only a newly raised [Nit] with VERDICT: PASS on STATUS: Approved remains optional.
     This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Manual relay: commit only the relay file** (`relay(gh1537-final-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: the implementation in `githooks/pre-push` (diff against base `5964566ef`:
  `relay-system/2026-11-23/gh1537-final-qa-code.diff`), the plan `PROJECT/2-WORKING/GH-1537-PREPUSH-OWN-DIFF-ROUTING.md`,
  and the evidence `TESTS-RESULTS/2026-11-23+GH-1537/` (`README.md`, `red-green-table.log`, `provenance.jsonl`, `check.sh`,
  `replay.sh`, `replay/replay.log`, `focused-suites.log`). Plan QA history: `relay-system/2026-11-23/gh1537-plan-qa.md`.
- Reviewer: codex (gpt-6-astra, reasoning effort high)   ·   Producer: claude-a
- Started: 2026-11-23
- Definition of Done: #1537 (a)-(d) plus KS-12 of arc #1541 are met by the smallest change that works, with no duplicate
  subsystem, no new suite, and evidence that rejects an unchanged candidate.

Issue #1537 (operator-approved policy 2026-11-19): a push whose only new integration content is `development` merged into the branch
is classified by the branch's own diff through the existing `utils/ci-route.sh`; the final landing still gets a full gate. Checks
(a) docs branch + development merge routes docs, (b) code branch + development merge routes full, (c) a merge from another branch
falls back to full, (d) a stale base falls back. Correction comment on #1537: the real mechanism is the update-range diff
`git diff --no-renames --name-only "$remote_sha" "$local_sha"`, not `:91`. KS-12 (#1541): classify the FINAL TREE against the verified
integration parent so conflict-resolution and evil-merge edits count; use it only for `route=docs`; refuse it for pushes to
`development`/`main`; keep live `ls-remote` freshness, per-ref checks, rename/deletion handling and the ambiguous-history fallback.

Operational envelope: grade against the stated requirements, commensurate complexity, and this repo's own threat model. XYZ-forge
forbids new tests (AGENTS.md, GH-831): a new `test/` suite or `validate.sh` TESTS entry in the diff is a finding; verification is the
existing suites plus the manual check with its red control. This is a gate/hook surface: do not suggest deferring a finding.

Process disclosure you must weigh: plan QA ended at its 3-round cap (r1 FAIL, r2 FAIL, r3 FAIL, STATUS: Escalated). The r3 residual
(a stale tracking ref OLDER than the merged commit let an "ours" merge slip to docs) was accepted and fixed AFTER the cap and has had no
plan-level re-review. Treat that fix as unreviewed and attack it here.

Questions (cite `file:line`; for each behaviour-change request give `Observed input:`, `Affected scope:`, `Falsifier:`):
1. **Residual F6.** In `own_diff_base`, does a tracking ref older than the merged commit (tracking B, advertised D, merge `(R,D)->M`
   keeping B's source) now return rc 2 and force full? Is any ordering of the checks still able to return rc 1 for a push that
   contains an own merge without consulting the live tip? Try: no local integration tracking ref; a merge whose `rev-list ... ^tip`
   output is empty because the merge commit is reachable from the tip; octopus merges; a first-parent-development merge.
2. **Soundness of docs acceptance.** Can any code path reach a push as `route=docs` when the branch's final tree against the verified
   integration merge-base carries code, with the new code? Check renames/deletions (`--no-renames`), several refs in one push, a
   failing second diff (classifier status now gates every route: `_cls="$(classify_push 2>/dev/null)" || _cls=""`), and the multi-ref
   `_own_pairs`/`_base_pairs` alignment.
3. **No regression of untouched paths.** Compare the diff against base for the first-push path (extracted `probe_integration_tips`,
   same notes and returns?), linear pushes (no probe, no network), pushes to `development`/`main`, tier-2 routing, receipt reuse, and
   `set -u` under bash 3.2 (macOS `/bin/bash`; the evidence ran under it): any empty-array expansion?
4. **Evidence.** Does the evidence reject an unchanged candidate (observed rejection: the 8 rows red on base), assert the gate that
   actually ran, and cover (a)-(d) and each KS-12 red control? Is the PR #1526 replay honest about what is stubbed (README "Limits")?
   Is any claim in the README unsupported by `provenance.jsonl`?
5. **Scope.** Is the change extend-not-duplicate (one hook file; no new suite, registry entry or classifier)? Anything over-built for
   the envelope, or a requirement of #1537/KS-12 missing? Note the stated consequence: a rejected candidate or non-docs own diff now
   takes the full gate even where the update range alone read docs.
6. Is the plan document consistent with what was built (item 3 order, item 4 routing, Risks)?

End with `swept file: yes|no`, `VERDICT: PASS|FAIL`, a Basis; set STATUS to Approved only on PASS.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
