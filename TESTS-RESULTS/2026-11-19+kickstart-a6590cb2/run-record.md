# Long run 2026-11-19 (session a6590cb2): observer / orchestrator / recovery

Status: AUTHORIZED 2026-11-19 by the operator (standing merge/close authority below). Parent: session a6590cb2 (observer/recovery). Child: see Dispatch.
Budgets: wall deadline 2026-11-20T06:00Z; max 2 attempts per item; then park and advance.

## Authority granted (one grant, covers the whole run)
- Merge PRs authored by noelsaw1 when: development merged in, the gate is green on that exact SHA,
  CodeRabbit has no open Major finding, and hosted checks are green.
- Close issues whose acceptance criteria are verified on development, with a comment that cites
  the commit.
- Post status comments on PRs and issues.
- Out of scope, so the run stops and asks: merging anyone else's PR, deploys, installed-skill updates,
  ledger rewrites outside the reconcile, anything owned by the flywheel session (#1400, #1418).

## Queue (execution order)
0a. #1526 (GH-1518, docs: start-task runs ci-local --fast; pre-push is the single full gate). Merge when CodeRabbit is clean.
0b. #1527 CODIFY THIS RUN (operator requirement): a deterministic queue builder so the next run is one command, not a hand-built list. See "Codify" below. Run it through start-task, after 0a and 1.
1. #1525 10days HAS-PR routing: CLEAN. Wait for CodeRabbit, then merge.
2. #1501 changelog written by the landing reconcile: CONFLICTING. Merge development in, gate, merge.
   This fixes the CHANGELOG drop hit on 11-17. Check overlap with #1473 and #1487 first.
3. #1507 timeout observations, with #1506: CONFLICTING. Merge development in, gate, merge, close #1506.
4. #1460 Daily Work Ledger, with #1459: CONFLICTING. Same steps.
5. Mergeability UNKNOWN: #1497, #1496, #1495, #1471, #1467, #1417. Refresh their state, then land them as
   one merge-cleanup batch (the fold/aggregate policy applies to 3+ PRs). Reconcile once at the end.
6. Drafts #1391 and #1024: finish or close, with evidence.
7. #1519 mypy preflight: small fix through start-task or jog.
8. #1517 stale merge-cleanup sentence: express docs fix.
9. #1500 intake.py copies .pyc files, and #1499 drift check reports 0/0 on a vendored tree:
   small fixes through jog.
10. #1522 AGENTS.md: only the operator's words count as instructions. Check whether it already landed;
    otherwise express docs fix.
11. #1508 per-repo PDDA override list.
12. Stale merge-batch and inventory issues #1412, #1408, #1398, #1394, #1386, #1441, #1523:
    close each once it is verified complete.
13. Refactors #1480–#1483, each only after its predecessor PR has landed (#1475, #1467, #1471).
14. Final QA pass on development: tier 1, plus the full gate in a disposable clone.

## Needs the operator (the run parks these and keeps going)
- #1518: should a green ci-local receipt for the exact commit satisfy pre-push?
  Recommend yes: it removes the second 13–17 minute gate on every code push.
- #1435 and #1427: decision on Claude spend caps.
- #1400 and #1418: owned by the flywheel session. Remind only, no writes.

## Recovery rules
- Gate red: classify it as the PR's own defect, environment (for example mypy), or a red development.
  Fix only the PR's own defects; file the rest as issues and move on.
- Child or session drop: verify who owns what before redispatching; never retry an unknown outcome.
- Two failures on the same item: park it in PARKED/ and advance.

## Codify (item 0b)
- Goal: `skills/1-hourly/kickstart/scripts/build_queue.py --repo-root . [--out PATH]` emits this file's
  Queue + Needs-operator sections from live state, deterministically (same inputs, same output).
- Inputs: `pr_minder.py --json` (it already classifies PRs, draft and held state) plus `gh issue list --json`.
  Reuse them; do not re-implement the classification.
- Ordering rules (a closed list, written down in the script and in kickstart SKILL.md):
  own CLEAN PRs → own CONFLICTING PRs → own UNKNOWN PRs as one merge-cleanup batch → drafts (finish or close)
  → small bug issues → docs issues → stale merge-batch and inventory issues (verify, then close)
  → refactors gated on a named predecessor → final QA. Held, others' PRs, decision-needed and
  other-session-owned items go to Needs-operator.
- Authority block: a fixed template the operator grants once; the run record holds it, so a resumed
  session re-reads it instead of asking again.
- Check: rerun it against today's state and diff the output with this hand-built queue; record that
  as a manual check under TESTS-RESULTS/ (no new test suite, GH-831).
- Kickstart SKILL.md: add one step to the parent ("build the queue with build_queue.py, record the
  authority grant, then dispatch").

## Dispatch
- Child is dispatched via T3 delegate_task. Never write the primary checkout (another session has
  unpushed relay commits on it). Use fresh clones per task, per start-task and merge-cleanup.

## Progress log (child appends; one line per item: item, outcome, SHA or PR, time)
- item 1 (#1525): MERGED via merge-cleanup, merge 476326496, reconcile ad22311e8; docs gate (pdda run) green at f8bbec34d; CR 2 Minor only; #1524 closed. 2026-11-19T22:53Z
- item 0a (#1526): IN REVIEW — merged development in (CHANGELOG both kept), fixed 2 CodeRabbit Majors (hook-installed + first-push precondition), head 5c5557936, docs gate green; CR rate-limited, "@coderabbitai review" posted; come back. 2026-11-19T22:59Z
- item 0b (#1527): PR READY https://github.com/HiQS-Labs/XYZ-forge/pull/1529 head 1e907aa82; plan+final Codex QA approved (r2 each); recorded check = TESTS-RESULTS/2026-11-19+GH-1527/manual-check.md (hand-queue diff explained, cmp 0); awaiting CodeRabbit. 2026-11-19T23:30Z
- item 2 (#1501): IN PROGRESS — merged development (ledger re-added GH-1487), fixed 3 CodeRabbit Majors (2 code in wave_reconcile, express text reverted; follow-up #1530 filed); focused suites + controls green; full pre-push gate running on 2e9bb2bdd. 2026-11-19T23:40Z
- item 12 (#1412 #1408 #1398 #1394 #1386 #1441 #1523): PARKED — none verified complete (open checklist items: deferred promotion/full hosted sweep, unverified acceptance; #1523 sweep exit 1); status comment posted on each, left open. 2026-11-19T23:47Z
- item 2 (#1501): MERGED 8009597c4 (head 2e9bb2bdd; full gate green 856s; CR reviewed head, 0 open Major). Follow-up #1530 filed. 2026-11-20T00:08Z
- item 0a (#1526): MERGED d7805a1c3 (reconcile 2a7867bed); head b7102ff9e full gate green 872s; CR reviewed head, 2 Minor/0 Major; body changed Closes->Refs #1518 so the decision issue stays open. 2026-11-20T01:04Z
- item 0b (#1527): MERGED 76d64e046 (PR #1529, reconcile b7957bca3); CR round fixed (incl. queued PR closing a parked issue); #1527 closed. Clones for #1529/#1526/#1501 retired to Trash; pr1501-a6590cb2-gate preserved (local probe branch). 2026-11-20T01:17Z
- item 3 (#1507 + #1506): MERGED f31b99205 (head 4b0ed0f7a; full gate green 836s on parent 3e269219b, docs gate on re-merge); no open CR threads; #1506 closed by merge. 2026-11-20T01:34Z
- item 11 (#1508): NEEDS-OPERATOR — issue carries two open design questions (committed override file acceptable? extend vs replace the default list); not decided by the run. 2026-11-20T01:42Z
- item 13 (#1480-#1483): BLOCKED — predecessors unlanded (#1475 open issue; #1467/#1471 are item-5 conflict hubs). 2026-11-20T01:42Z
- PARENT 2026-11-20T01:50Z: #1508 DECIDED by the operator: a committed per-repo override file that EXTENDS the default governance doc list (never replaces it). Item 11 is back in the queue, after #1519/#1499/#1517; build it through start-task. #1518 closed by the parent (landed in d7805a1c3).
- item 4 (#1460 + #1459): MERGED 3fb17abf9 (head 4fb99d619; full gate green 834s; 4 CR Majors fixed with pre-fix probes, CR re-reviewed head: Minors only); #1459 closed; PR had no CHANGELOG entry. 2026-11-20T01:59Z
- PARENT 2026-11-20T02:02Z: Codex review cap exhausted. Do NOT leave #1519/#1499/#1517/#1508 as drafts waiting on Codex: run their plan/final relay QA with agy as the reviewer (relay-xyz agy-turn.sh), which is the existing alternative path (flywheel ladder rung 1). Name the actual reviewer model in each receipt. Fall back to a draft only if agy is unavailable too.
- item 7 (#1519): DRAFT PR https://github.com/HiQS-Labs/XYZ-forge/pull/1532 head eea4c81a0, full gate green 836s; Codex final QA hit 3-round cap on a provenance nit (fixed after cap) -> NEEDS-OPERATOR: allow 4th round or accept. 2026-11-20T02:03Z
- PARENT 2026-11-20T02:06Z: CORRECTION to the 02:02Z note: the "cap" on #1519 was the 3-round relay cap, not Codex usage. The agy instruction is withdrawn; the round cap goes to the operator as the child did. Waiting on the operator to accept #1532 or allow a 4th round.
- item 9a (#1499): PR READY https://github.com/HiQS-Labs/XYZ-forge/pull/1533 head f5fdbd8ef; full gate green 835s; Codex final QA approved r2. item 9b (#1500): PARKED — changing the intake digest to skip .pyc changes receipts/recovery comparisons for existing payloads; needs a reviewed plan. 2026-11-20T02:18Z
- item 10 (#1522): MERGED a943bc50c (PR #1531, reconcile 0a87e686d); docs gate green; CR 2 Minor/0 Major; #1522 closed; CHANGELOG entry intact. 2026-11-20T02:28Z
- item 5b (#1417 #1467 #1471 #1497): PARKED (for now) — Codex sequence review FAIL (relay-system/2026-11-20/item5-hub-sequence-review.md in ~/kickstart-clones/review-a6590cb2, local only): needs one recorded batch w/ --landing-plan direct + reason, per-key ledger resolution via merge-cleanup B1, no extra local full sweep (full_suite=promotion); code-level interactions unverified (#1417 gate files vs #1526; #1471 releases_app/wave_reconcile vs #1501; #1467 relay_drive vs #1507). 2026-11-20T02:33Z
- item 5a (#1495, #1496): READY except CodeRabbit — heads 239183bf7 / 48e0f6b09, full gates green (831s / 828s), hosted green, 0 open threads; neither ever reviewed by CR (rate-limited since 11-16); "@coderabbitai review" posted once each; land as one 2-PR batch when reviewed. 2026-11-20T02:50Z
- item 6: #1391 CLOSED (superseded: #1390 landed af84ecbc2, restoration evidence already on dev; its "unmerged" claims are stale). #1024 -> NEEDS-OPERATOR (held: review authority limit / unresolved escalation). 2026-11-20T02:51Z
- item 8 (#1517): PR READY https://github.com/HiQS-Labs/XYZ-forge/pull/1534 head 855b43bc1; full gate green 836s; Codex final QA approved r2 (express refused: merge-cleanup is an execution-authority skill, so PR lane). 2026-11-20T03:04Z
- PARENT 2026-11-20T~03Z: #1519 / PR #1532 ACCEPTED as is by the operator (no 4th round). Marked ready. Land it like the others once CodeRabbit shows no open Major.
- PARENT 2026-11-20T~03:10Z: NEXT RUN (operator-approved): after this run hands back, the parent starts a new kickstart from build_queue.py with #1535 and #1536 first, then #1537 (pre-push own-diff routing, approved). CodeRabbit = advisory, 30-min max wait (#1536 comment).
- PARENT 2026-11-20T~03:12Z: AUTHORITY AMENDED BY THE OPERATOR, effective now for this run: CodeRabbit is advisory. A ready PR may merge once 30 min have passed since its review request with no review on the head; an open Major that CodeRabbit did post still blocks. The other conditions are unchanged (gate green on the exact SHA, QA approved, hosted checks green).
- item 14: FINAL QA on development 0a87e686d — tier 1 (pdda run) rc=0, full ./validate.sh in disposable clone rc=0 (0 failing). Re-run needed only if more PRs land after it. 2026-11-20T03:23Z
- item 8 (#1517): MERGED da1bfef4c (PR #1534, reconcile 27a7a35bc); CR 5 Minor/0 Major; #1517 closed; CHANGELOG intact. 2026-11-20T03:33Z
- PARENT 2026-11-20T03:45Z: REMAINING before handback: #1495, #1496, #1533 AND #1532 (#1519, accepted by the operator, now ready but conflicting: merge development in, gate, land). Apply the 03:12Z CodeRabbit-advisory amendment to all four. Re-run the final QA on the new tip if anything lands after 0a87e686d (it has: #1534).
- item 5a (#1495, #1496): MERGED as batch #1538 — #1495 d6bcb2cf0 (reconcile eee823202), #1496 2dec9a36f (reconcile 3f744823d) under the 03:12Z CodeRabbit-advisory amendment (no review posted >30 min after request). First #1496 attempt refused by an environment fault (gh api timeout reading #1485), recovered via --reconcile-pr 1495 + --resume. Sweep verdict recorded deferred (full_suite=promotion). #1023/#1050 still OPEN (no closing keyword; not verified here). 2026-11-20T04:29Z
- item 11 (#1508): PR https://github.com/HiQS-Labs/XYZ-forge/pull/1539 head aef83bbc1, tier-2 gate green, Codex final QA approved r2; CR requested 04:24Z. 2026-11-20T04:29Z
- item 9a (#1499): MERGED caf8e2724 (PR #1533, reconcile 008faf1b3); full gate green 1085s on 7dcd09532; CR advisory (request 02:22Z, no review); #1499 closed. 2026-11-20T04:58Z
- item 7 (#1519): MERGED 5db9db385 (PR #1532, reconcile 04979701a); full gate green 1042s on 2a3601a90; operator accepted at 3-round cap; CR advisory (request 04:47Z, none posted by 05:17Z). Batch with #1539.
- item 11 (#1508): PARKED mid-landing — PR #1539 head 1115f376d (full gate green 1038s, Codex QA approved r2) conflicted with #1532 reconcile (CHANGELOG/ledger); merge-cleanup B1 attempt 1/2 was reserved and then the run was killed by a 10-min tool timeout. Remote head unchanged (B1 never pushed); attempt record .tick/merge-cleanup/HiQS-Labs-XYZ-forge/pr-1539.json in landing clone left "in_progress". Unknown outcome -> not retried; next owner: parent. 2026-11-20T05:27Z
- PARENT 2026-11-20T05:45Z: NEXT RUN follows arc #1541 order (KS-02 #1535 → KS-03/04 #1536 → … → KS-10 #1537). Baseline for KS-18: 7 parent interventions, 12 merges, ~7.2h.
- item 14 (re-run): FINAL QA on development 04979701a (after #1534 #1495 #1496 #1533 #1532) — tier 1 pdda rc=0; full ./validate.sh in disposable clone rc=0, 408/408 (poll-driver.sh failed once in parallel, passed on the solo contention retry). Later commit 919421078 changes LEADERBOARD.md only. Batches #1538 and #1540 sweep verdicts recorded deferred (full_suite=promotion); #1540 still lists #1539 as planned. 2026-11-20T05:45Z
- HANDBACK 2026-11-20T05:45Z: child stops. Summary returned to parent; scratch copy kickstart-a6590cb2-handback.md.
