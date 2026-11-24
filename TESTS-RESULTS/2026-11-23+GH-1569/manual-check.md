# Manual check — GH-1569 (`build_queue.py --daily-goals` admits only unchecked checklist items)

- Issue: #1569 (refs #1541, KS-14 shipped in #1558/#1563). Base `2ac998d130d9b6940ab00884c4248f4672b2dabb` (`origin/development`).
- No new test or suite (GH-831). Evidence is a manual probe (`outputs/controls-probe-source.txt`, a copy of the exact
  script run, kept as evidence, not registered anywhere) plus real CLI runs; `provenance.jsonl` records hashes.
- Date note: machine date 2026-11-23; the task folder name carries the operator-requested 2026-11-24.

## Decision: a body with no task list keeps TODAY's behaviour (not fail-closed)
Smaller: no new refusal path, error text or doc'd exit code, and GH-1558's prose-only controls stay valid. Proof: with no
checkbox line the changed function takes the unchanged per-line loop (`tasklist` false, `refs` not truncated), and the full
CLI output for a prose-only body is byte-identical between base and candidate (`outputs/prose-only-base.md` vs
`prose-only-candidate.md`, check "5 CLI" in `controls-green.txt`). Edge: `+ [ ]` bullets now count as a checkbox (they did not
before); a body whose only checkbox is `+ [ ] ...` switches to task-list mode (judged correct: GitHub renders it as a task list).

## Other readers of the body
`parse_daily_goals_refs` is the only queue-admission reader. The safety reader (`parked_issues` -> `issue_hold_reason`, which
can park the goals issue itself via `after #N`/`HELD:`) is deliberately unchanged: row 8, `{1568}` on base and candidate.

## Red / green on #1568's ORIGINAL body
Recovered via GraphQL `userContentEdits` (nodes[1], editedAt 2026-11-20T17:07:07Z; the 17:07:56 edit rewrote `#N` as `GH-N`).
Issue universe is SYNTHETIC (every #N the body mentions, bug-labelled except #1537 and the #1541 arc).
- RED, unmodified base (`outputs/red-base-original-body.md`): Queue holds #1480 and #1483 (plus prose #1501 #1507 #1526 #1541);
  #1537 sits in Needs-the-operator.
- GREEN, candidate (`outputs/green-candidate-original-body.md`, `outputs/smoke-main.md`): Queue is exactly
  #1417 #1467 #1471 #1497 #1500 #1530 #1551; none of #1480 #1483 #1537 #1541 #1526 #1501 #1507 #1400 #1418 appears.
- Current body: 7 items; full output byte-identical base vs candidate (`current-body-base.md` / `current-body-candidate.md`).

## Matrix (`outputs/controls-green.txt`, `RESULT: ALL PASS`)
Discriminators differ on base: `- [ ] #10 after #1601` [10,1601]->[10]; `- [ ] #11 and also #12` [11,12]->[11]; checked + prose beside a
checklist [11,10]->[11]; foreign lead `other/repo#9 then #10` [10]->[]; same-repo-qualified lead [9,10]->[9]; self lead [10]->[];
unchecked no-ref line + prose `Out of scope: #7` [7]->[]; backticked lead [10,11]->[10]; nested indent / `+` / `1.` / `[X]`; dedupe;
`(GH-1500, GH-1417)` + `after #19` [20,19]->[20]. Controls identical on both: `(GH-1700)` -> [10]; prose-only [10,11]; all-checked [].
Nested refs behave as stated: `(GH-…)` never matches (no `#`); `after #N` after the lead is a reference, not an item.
Fail-closed: all-checked task list and checklist with no refs exit 1 ("selected zero open issues or PRs after resolution").

## Smoke (`outputs/smoke.txt`) — real CLI entry, not runpy
Main: `run.sh <script> inputs/1568-original-body.json --out ...` exit 0, the 7 items. Adjacent: (1) same command rerun, output
byte-identical; (2) the edited (current) body, same 7 items; (3) a checklist with no refs, exit 1 with the zero-selection message.

## Gate
`outputs/ci-route.txt`: `route=docs`, `tier=1` (the classifier treats `skills/**` as docs). `outputs/pdda-run.log`: 0 errors.
mypy: not installed on this host (`No module named mypy`), not run; `python3 -m py_compile` clean.
Attempt accounting: `gate_receipt.py attempt-start` booked with the task clone as `--repo` and accounting root
(the operator's instruction forbids touching the primary checkout, so the maintained-primary accounting root was not used).
