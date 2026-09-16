# RELAY · GH-645 hotfix follow-up final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-16.
-->

NEXT: Producer
STATUS: Approved
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
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-645-hotfix-follow-up-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **qa-review.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-16

### Artifact — qa-review.md
```
QA the GH-645 follow-up on this committed branch. Read skills/merge-cleanup/scripts/ledger_merge.py, test/gh645-merge-cleanup-xyz-tools.sh, and the GH-645 completed doc's Post-hotfix QA section.
1. Does the shell resolver use clone canonical, clone vendored, then primary fallback paths while preserving --root?
2. Does the existing Python lookup behavior remain intact?
3. Does the regression fail on the original hardcoded call and test the chosen shell path and target root?
4. Is the diff commensurate with this local path fix? Do not demand unrelated redesign.
Grade the stated consumer workflow. Read-only review; change only the relay thread. Cite concrete file:line findings. Approve if no blocking defects.
```
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

## Reviewer — codex — Round 1 (2026-09-16)

swept file: yes
VERDICT: PASS
Basis: Static review of all 549 lines of ledger_merge.py, the entire regression, and the completed GH-645 doc found no blocking defect in the stated consumer workflow and no additional pre-existing defect requiring a fix in this scope. The four embedded QA questions supply the acceptance criteria; Setup's DoD placeholder is unfilled. No source, artifact, test, or git command was executed. Runtime gate and mutation evidence remain the producer/harness's responsibility. The paginated graph project inventory contains no index for this worktree; exact local source was used rather than relying on another checkout's graph generation. Historical diff size was not independently measured because git is prohibited this turn.

- [Pass] Shell lookup order is clone canonical, clone vendored, primary canonical, primary vendored: skills/merge-cleanup/scripts/ledger_merge.py:256–266. The call at :480 selects directory="utils" and still passes "--root", str(clone), with clone as cwd. Fix: none.
- [Pass] Python callers retain the default "utils/py" and the existing root argument in skills/merge-cleanup/scripts/ledger_merge.py:256 and :269–270; test/gh645-merge-cleanup-xyz-tools.sh:41–53 and :78–88 retain Python precedence, fallback, missing-tool, and root assertions. Fix: none.
- [Pass] The new regression executes the selected shell stub, checks its target root against cwd, and asserts the exact selected path and --root command (test/gh645-merge-cleanup-xyz-tools.sh:55–76). By inspection, the original hardcoded clone path has no fixture script, so bash returns nonzero and the resolved assertion at :75 fails. This is static falsifiability analysis, not a claimed mutation run. Fix: none.
- [Pass] The implementation extends one existing resolver with a defaulted directory parameter and one shell caller (skills/merge-cleanup/scripts/ledger_merge.py:256–270, :480); the focused test adds one consumer-boundary case (:55–76). This is commensurate with the local path repair described in PROJECT/3-COMPLETED/GH-645-MERGE-CLEANUP-LEDGER-GATE-AND-RECONCILE-FAIL-IN-REPOS-THAT-V.md:43–52. Fix: none; no redesign requested.
- [Should] The completed doc's :59 cites TESTS-RESULTS/2026-09-16+GH-645-qa/provenance.jsonl, which is absent in this review checkout. The available express receipt records the original landing, not the follow-up. Fix: producer must include the actual follow-up passing and original-call failing receipts with the PR, or remove unsupported run claims at :43–48 and correct the evidence pointer. This does not reveal a blocking code defect; this approval does not attest to those runs or to merge readiness.

Relay closed (Approved), no further review turn needed. Producer claude-a owns the evidence follow-up and harness gate before landing.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
