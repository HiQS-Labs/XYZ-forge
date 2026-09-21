# RELAY · GH-740/741 final QA — hosted lane publish + report attribution (diff at 071f6c42)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-21.
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
     A `[Blocker]` must cite an observed failure. This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh740-741-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: utils/py/hosted_lane_publish.py, utils/py/hosted_lane_report.py, utils/py/wave_reconcile.py (the `--only-receipted` flag: argparse block + the partition replacing `qualify_landings` in `main`), .github/workflows/wave-reconcile.yml, test/gh740-hosted-lane-publish.sh, test/gh684-hosted-lane-report.sh, test/gh421-auto-wave-reconcile.sh (WorkflowTests + the `only_receipted` cases), validate.sh (one TESTS row), CHANGELOG.md (top entry), PROJECT/2-WORKING/GH-740-HOSTED-LANE-PUSH-RACE.md (the approved plan). Diff: `git diff b6bb8aab..071f6c42 -- <those paths>`.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-21
- Definition of Done: the implementation satisfies the **approved plan** (relay `gh740-741-plan-qa-delta2`, Approved) and each issue's acceptance, at commensurate complexity — no second subsystem, no merge queue, no widening of the bot's commit surface. Grade against the plan's Requirements table, not against speculative failure modes. Questions, each graded: (1) #740 — does `hosted_lane_publish.py` do exactly the fast path the inline step did when the push succeeds (allowlist first, explicit `git add`, bot identity, one commit, one push), and on rejection: discard (`reset --hard`), lift **only** receipt files from the discarded commit, publish them (≤3), recompute **once** with `RECONCILE_ARGS` + coalesced `--pr/--commit` + `--only-receipted --skip-pull`, never rebase, never force? (2) `wave_reconcile.py --only-receipted`: is the partition using the same matcher as the qualifier, are explicit unreceipted targets fail-closed, is `issue_owners` untouched, and does the flag refuse without `--catch-up --qualify`? (3) #741 — does `terminal_error()` never blame a green reconcile step's log, keep the red reconcile step's last error, and do skips from both logs still demand attention? Is the workflow passing the right values (`steps.reconcile.outcome`, `steps.publish.outcome`, publish log tee'd)? (4) Do the tests substantiate the claims: gh740's fixture drives a real bare remote and racer; the **production** `qualification_receipt_matches` accepts the published receipt and refuses a corrupted one; the stale clone's plain push is the red control; the second-race, no-receipts, undeclared, and F6a parser cases; gh421's four `--only-receipted` cases incl. the F6 open-reference retention; gh684's replay of run 35623940059 with the old `summarize()` as red control? Name any claim a test does **not** actually pin. (5) Are the gh421 pin moves the minimum (YAML extraction removed because no inline Python remains) and is anything that was pinned before no longer pinned? (6) Ratings `85/75/50/55` and `70/55/50/80` still match the delivered scope? (7) Anything in the diff outside the two issues' scope? Focused evidence: gh684 10/10, gh421 36/36, gh740 7/7, ci-workflow 0 failed; the full gate in a disposable clone is running in parallel and its receipt will be attached before the PR. Grade [Must]/[Should]/[Nit]; **Approved** when no [Must] remains.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
