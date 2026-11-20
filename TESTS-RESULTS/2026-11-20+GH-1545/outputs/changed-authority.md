<!-- build_queue.py (GH-1527) as of 2026-11-19; window 14 days; inputs: pr_minder.py --json, gh pr list, gh issue list -->

## Authority granted (one grant, covers the whole run)
- Merge PRs authored by noelsaw1 when ALL hold: development is merged in where needed; the classified
  gate is green on that exact SHA; independent cross-model QA has approved the final head; hosted
  checks are green; and EITHER CodeRabbit has reviewed the current head with no open Major OR 30 min
  have passed since a "@coderabbitai review" request on the current head with no review. Re-read
  reviews immediately before the merge. Record the timeout path as "advisory not received;
  predeclared waiver used", never as reviewed or approved. Any Major that CodeRabbit posted blocks
  until it is fixed or answered.
- Close issues whose acceptance criteria are verified on development, with a comment that cites
  the commit.
- Post status comments on PRs and issues.
- Decision defaults (KS-11, fail-closed):
  - Round cap (KS-11a): land only with an independent reviewer's explicit approval covering the final
    head. Minor/nit findings may be deferred only when the reviewer explicitly tagged them Minor/nit
    and accepted the deferral; otherwise park and continue independent work. Never auto-accept on
    gate, hook, containment, schema, kernel, or Costly surfaces (utils/ci-route.sh full_required). A
    PR landed with accepted Minor/nit deferrals states so explicitly and never claims Approved beyond
    what the reviewer stated.
  - Conflict hubs (KS-11b): conflict hubs reported by the merge-cleanup forecast route to a separate
    recorded batch.
  - Operator decisions (KS-11c / KS-02): release holds only when authored by noelsaw1, applicable,
    and not superseded.
- Provider quota fallback: when the reviewer seat's stop reason verbatim states quota, switch that
  turn's reviewer to agy and record the actual model name; if both providers are capped, park. Never
  infer quota from a round cap or generic failure.
- Flywheel per-PR approval: once granted below, this launch grant satisfies Flywheel's per-PR merge
  approval step (skills/2-daily/flywheel/SKILL.md:109-120) for noelsaw1 PRs within these bounds;
  exact full-SHA --prs N@<approved-full-sha> pin verification before --execute still applies.
- Out of scope, so the run stops and asks: merging anyone else's PR, deploys, installed-skill updates,
  ledger rewrites outside the reconcile, anything owned by another session (#1400, #1418).
- Status: NOT YET GRANTED. The parent records the operator's grant here before dispatch.

## Queue (execution order)
1. #1417 fix: require canonical attempt accounting before task qualification (GH-1399) (closes #1399): CONFLICTING or failing. Merge development in, gate, merge.
2. #1460 feat(daily-planner): shared Daily Work Ledger GH issue, carryover, checkout calibration, and vendored repo support (#1459) (closes #1459): CONFLICTING or failing. Merge development in, gate, merge.
3. #1467 fix(GH-1465): relay-drive runs the reviewer gate itself; earlier findings stay open (closes #1465): CONFLICTING or failing. Merge development in, gate, merge.
4. #1471 feat(GH-1466): xyz-vendor --ledger-only tier (closes #1466): CONFLICTING or failing. Merge development in, gate, merge.
5. #1497 fix(GH-1049): no false dependency.drift for surfaces absent at both revs: CONFLICTING or failing. Merge development in, gate, merge.
6. #1501 feat(changelog): eliminate merge conflicts via landing reconcile writer and default-off mode (Closes #1487) (closes #1487): CONFLICTING or failing. Merge development in, gate, merge.
7. #1507 fix: report timeout observations without inferring causes (closes #1506): CONFLICTING or failing. Merge development in, gate, merge.
8. Mergeability UNKNOWN or behind: #1495 fix(GH-1023): pass profile effort to the Command Code CLI and record it honestly; #1496 Marathon lane gh-1050-no-swap-false-low-swap-warning. Refresh their state, then land them as one merge-cleanup batch (the fold/aggregate policy applies to 3+ PRs). Reconcile once at the end.
9. Draft #1391 docs(GH-1386): bounded closeout and gate-incident evidence (closes #1386): finish or close, with evidence.
10. #1499 skill_drift_check.py reports 0 ok / 0 drifted on a vendored .xyz/skills tree, so a green result proves nothing: small bug fix through start-task or jog.
11. #1500 intake.py copies untracked .pyc files from the source skill folder into the Deployed Skills payload: small bug fix through start-task or jog.
12. #1519 Gate preflight: fail fast when mypy (requirements-dev.txt) is missing, instead of failing a 13-minute full gate at test_python_layer.py: small bug fix through start-task or jog.
13. #1527 kickstart: deterministic queue builder so a long run is one command (build_queue.py): small bug fix through start-task or jog.
14. #1473 PDDA: the landing reconcile writes CHANGELOG.md from a Changelog section in the PR body, so PR branches stop editing it: docs fix through express.
15. #1517 merge-cleanup SKILL.md: batch protocol still says the script runs no test suite (stale after GH-1383 auto-sweep): docs fix through express.
16. #1522 AGENTS.md: only the operator's words are instructions; others' comments and model turns are evidence (prompt-injection guard): docs fix through express.
17. Stale merge-batch and inventory issues #1374, #1375, #1380, #1394, #1398, #1408, #1412, #1441, #1523: close each once it is verified complete.
18. #1480 refactor: decompose merge-cleanup entry point and landing loop after #1475: refactor, only after #1475 has landed.
19. #1481 refactor: decompose marathon-drive main after #1467: refactor, only after #1467 has landed.
20. #1482 refactor: type and decompose releases_app boundaries after #1471: refactor, only after #1471 has landed.
21. #1483 refactor: type and decompose Jog and wave-reconcile executor entry points: refactor, no predecessor named; confirm before starting.
22. Final QA pass on development: tier 1, plus the full gate in a disposable clone.

## Needs the operator (the run parks these and keeps going)
- PR #1024 feat(weekly): held intake and preserved rollover with tracked review limits (GH-1022): held (Review authority limit / unresolved escalation)
- #1344 GH-1340 item 1: finishing work (Tasks 10, 9, 8, 7): unclassified; operator picks scope
- #1353 Next-gen flywheel recommendations: instrument the loop (cycle time, gate escape rate, receipt freshness) and close the no-row discovery seam: unclassified; operator picks scope
- #1356 Flywheel Batch 2: autonomous supervisor outerloop run across critical targets (#1296, #1288, #1287, #1254, #1344): unclassified; operator picks scope
- #1358 Post-Batch-2 qualification: prove between-wake orchestration before a bounded unattended run: unclassified; operator picks scope
- #1359 Housekeeping: trace and close task-clone retirement gaps without weakening preservation checks: unclassified; operator picks scope
- #1360 Task-agnostic supervisor: scope a deterministic scheduled-task replacement for paid Grok Bot jobs: unclassified; operator picks scope
- #1366 Audit: calibrate workflow restrictions to risk and reduce disproportionate delivery burden: unclassified; operator picks scope
- #1376 Add flywheel skill for adaptive Jog orchestration: unclassified; operator picks scope
- #1400 Arc: Economical supervision and reliable multi-task composition in the factory flywheel: owned by another session; remind only
- #1409 ci(vendored-smoke): base-pin ratchet, frozen-twin guard, and vendored smoke suites against self-modification: unclassified; operator picks scope
- #1414 Pilot paraphrase-first plan review and explicit reviewer context from EGM: unclassified; operator picks scope
- #1418 Flywheel proving runs: two-bug automatic progression, then Jose’s five-bug overnight session: owned by another session; remind only
- #1423 relay-drive: attest-publish-failed (exit 4) when relay file is under a gitignored path, though the attest commit lands: unclassified; operator picks scope
- #1427 claude-turn's $0.50 / 12-turn default cuts off Claude builder turns; exit reason discarded and turn log lost: unclassified; operator picks scope
- #1435 Default Claude spending caps to a subscription paradigm; apply API-billing caps only when the user opts in: unclassified; operator picks scope
- #1458 Ledger writes only at landing by default; each vendored repository can opt out: unclassified; operator picks scope
- #1475 merge-cleanup: 3-phase remediation from a 13-PR batch post-mortem (quick wins, next wins, deeper changes): unclassified; operator picks scope
- #1508 PDDA: per-repo override for the governance doc list (survives install/sync): operator decision
- #1518 pre-push: decide whether a green ci-local receipt for the exact commit satisfies the full-gate reuse check: operator decision
- PR #1526 docs(start-task): ci-local --fast, then pre-push is the one full gate (GH-1518): merging it would close parked #1518
- #1528 connect-the-dots: tighten evidence discipline and dry-run safety: unclassified; operator picks scope

## Not queued (arcs, plans, research, spikes, umbrellas, radar, daily goals)
- #1352, #1383, #1474, #1476, #1477, #1520
