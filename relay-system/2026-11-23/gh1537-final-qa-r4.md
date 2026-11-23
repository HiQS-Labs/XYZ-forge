# RELAY · GH-1537 Final QA round 4: side-branch merge before the ancestor exemption
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-23.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 1

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
6. **Manual relay: commit only the relay file** (`relay(gh1537-final-qa-r4): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `githooks/pre-push` at head `7105c7785d464b9f96f069d6efa9fbe412725e43` (PR #1584). The change under
  review is the delta from the previously approved head `9c18e49f0`: `relay-system/2026-11-23/gh1537-r4-delta.diff` (37 lines);
  the full diff against base `5964566ef` is `relay-system/2026-11-23/gh1537-final-qa-code.diff`. Plan:
  `PROJECT/2-WORKING/GH-1537-PREPUSH-OWN-DIFF-ROUTING.md` (item 3). Evidence: `TESTS-RESULTS/2026-11-23+GH-1537/`
  (`README.md`, `red-green-table.log`, `previous-head-vs-repaired.log`, `provenance.jsonl`, `suites-provenance.jsonl`, `check.sh`).
  Prior history: `gh1537-plan-qa.md`, `gh1537-final-qa.md` (r3 PASS at `9c18e49f0`).
- Reviewer: codex (gpt-6-astra, reasoning effort high)   ·   Producer: claude-a
- Started: 2026-11-23
- Authorization: the operator approved exactly ONE extra round on PR #1584, limited to CodeRabbit's Major, recorded on #1537 as the
  comment "Operator decision 2026-11-23" (https://github.com/HiQS-Labs/XYZ-forge/issues/1537#issuecomment-7114076730; relayed by parent
  session a6590cb2). It also accepts the plan-QA cap deviation (plan QA ended FAIL at r3; final QA r3 PASS). This thread's cap is 1.
- Definition of Done: CodeRabbit's Major is fixed as stated, with no regression of the 20 earlier scenarios.

CodeRabbit Major (PR #1584, `own_diff_base`): "the early `return 1` for an ancestor merge base runs before the non-first-parent check. A new
merge of a side branch whose parent is not on the verified integration tip therefore keeps the update range. If that side commit changes
only the README, the update range can route to docs." Requested: move the ancestor check after the non-first-parent loop; keep rc 1 for
merges whose non-first parents are all on the tip; drop "or a merge of the branch's own sub-branch" from the plan's rc 1 bullet; add a
verification case: a README-only side-branch merge pushed after the integration tip is already in the remote branch must route full.

Operational envelope: grade against the stated requirements, commensurate complexity and this repo's own threat model. XYZ-forge forbids
new tests (AGENTS.md, GH-831): a new `test/` suite or `validate.sh` TESTS entry is a finding; verification is existing suites plus the
manual check with its red control. Gate/hook surface: do not suggest deferring a finding. Other CodeRabbit comments on the PR (the push-URL
argument, the plan-QA probe record, the replay `OUT` path) were NOT part of the operator's authorization and are not in this round; if
you find a defect in code this change touches, report it anyway.

Questions (cite `file:line`; behaviour-change requests carry `Observed input:`, `Affected scope:`, `Falsifier:`):
1. Is the reordering exactly what the Major asks, and is the resulting `own_diff_base` order correct and complete (dest, tracking tip,
   any merge, live probe, freshness, `^tip` exclusion, merge-base, non-first-parent rejection, ancestor exemption, narrow)? Is there
   any input that previously returned rc 0 or rc 1 correctly and now returns rc 2 unnecessarily or the reverse (octopus; a merge of
   a side commit already on the tip; `mbs` an ancestor of `remote_sha` with every own merge on the tip)?
2. Does the new scenario `side_merge_after_integration` reproduce CodeRabbit's case through a real `git push` (README-only side
   commit, integration tip already in the remote branch), red at `9c18e49f0` (docs) and green at the head (full)? See
   `previous-head-vs-repaired.log` (it must show this as the only scenario that changed) and `provenance.jsonl`.
3. Were all 20 earlier scenarios rerun on the new hook (`red-green-table.log`: 21 rows, 0 candidate mismatches, 10 red on base), and the
   six existing suites rerun at the new hook (`suites-provenance.jsonl`: tested commit `b48f00a0f`, hook sha256 `062ada684bedf828`,
   clone identity unchanged)? Is any claim in the README or plan unsupported?
4. Does the plan text match the code (item 3 bullets, the removed "sub-branch" wording, the verification list)?
5. Whole-file sweep: any defect in `githooks/pre-push` introduced or touched by this change? Scope: still one hook file, no new suite.

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
