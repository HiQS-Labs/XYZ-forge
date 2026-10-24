# GH-1195 — marathon-plan reads the primary clone's ledger from a sibling clone

Fix commit `5623dfd7` (one line: `utils/py/marathon_plan.py` default root = `repo_root(anchor_file=__file__)`).
Base `development` @ `80e67677`. GH-831: no new tests; everything below is an existing suite or a recorded manual check.

## Before fix (red control, live primary — not repeated)
`before-fix-red-control.txt`, `before-fix-NOTE.md`, `before-fix-primary-write.diff`: with the task clone's
`releases.db` moved away, `bash utils/marathon-plan.sh --format json` still produced a report (planner rc=4) and
wrote `PROJECT/2-WORKING/MARATHON-PLAN-2026-10-24.md` into the PRIMARY clone (reverted by hand). Root cause:
`~/.zshrc:67` exports `XYZ_HARNESS` to the primary and `harness_home()` prefers it over the script's own tree.

## Checks on `5623dfd7` (`checks-5623dfd7/`, driver `checks.sh`, log `checks-driver.log`, hashes in `provenance.jsonl`)
Two disposable clones: A = candidate (`-verify`, at 5623dfd7), B = alternate (`-verify-b`, at 80e67677), `XYZ_HARNESS=B`,
every planner run `--dry-run --format json`, planner exit captured directly.

| Check | Reverted code (80e67677 planner) | Fixed code | Result |
|---|---|---|---|
| A — A's `releases.db` absent | rc=4, nonempty report (read B) | rc=3 `cannot read releases.db … unable to open database file` (read A) | PASS; B tree byte-identical before/after |
| B — resolver probe (`checkB-resolver.txt`) | `repo_root()` → B | `repo_root(anchor_file=…)` → A; simulated vendored anchor → consumer root | PASS |
| Smoke main — sentinel row GH-987654 added only in B; A unpinned | sentinel PRESENT (read B) — red control | sentinel ABSENT (read A) | PASS |
| Smoke adjacent — fixed, `QUEUE_PLAN_ROOT=B` | — | sentinel PRESENT (override wins) | PASS |

`smoke-reevaluation.txt`: the driver's smoke assertions grepped the literal `#987654`; the engine renders
`GH-987654-SENTINEL.md` in a drift finding, so the two FAIL lines in `checks-driver.log` are assertion-string
errors. The retained artifacts were re-evaluated with pattern `987654`: 3/3 PASS. Artifacts unchanged.

## Existing suites on `5623dfd7` in clone A (`focused-suites-5623dfd7.log`)
marathon-plan.sh rc=0 · wave-reconcile.sh 23/23 · gh358-wave-reconcile-vendored-paths.sh rc=0 ·
gh429-wave-reconcile-vendored-observe.sh rc=0 · gh418-planner-ledger-source.sh rc=0 · gh362-marathon-plan-link-bullets.sh rc=0.
Boundary: marathon-plan.sh pins `QUEUE_PLAN_ROOT` (override path); gh358/gh429 stub the planner. The default-root
behaviour is witnessed by checks A and smoke above, the vendored root by check B's anchored probe (simulated file).

## Final gate
Route for the changed paths: `tier=3` (kernel/gate surface). `bash ci-local.sh` in the disposable `-gate` clone:
see `full-gate-*.log` (added when the run completes; identity checked before/after).

## Final-QA round 1 dispositions (reviewer codex, `relay-system/2026-10-24/gh1195-final-qa.md`)
- **R1 accepted — byte identity of B.** `checkA-digest-5623dfd7/`: check A repeated with content digests (sha256 of
  every tracked + untracked non-ignored file in B) before and after the reverted and fixed runs, compared with `cmp`,
  plus a falsifier (one appended byte in B's `releases.sql` makes the comparison fail; restored). The original run's
  porcelain-text comparison is kept as recorded; this is an added receipt, not a relabel.
- **R2 accepted — acceptance bullet 2 explicitly DEFERRED.** Issue #1195's second bullet (a closing-issue
  `wave_reconcile.py --pr N` from a fresh landing clone with no `QUEUE_PLAN_ROOT`) needs a merged PR that closes an
  issue; none exists inside this task, and `test/wave-reconcile.sh:203-208` mocks the planner, so no suite stands in
  for it. The first real witness is this PR's own landing: it closes #1195, so its local reconcile from a sibling
  landing clone must succeed without env pinning. Record that outcome on #1195 at landing time. Until then the
  repaired planner is proven only in isolation (checks A/smoke) and composed only through mocked suites.
- **R3 accepted — attestation.** `checks-5623dfd7/provenance.jsonl` now carries `focused-suites-5623dfd7.log` with
  its command, revision and exit; `scope-80e67677-to-head.txt` lists every changed path from base to the reviewed
  head and shows the protected-surface delta is exactly `utils/py/marathon_plan.py`.
