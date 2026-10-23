# GH-1184 — manual smoke receipt (GH-1088 / GH-831: no new suite)

Change under test: `skills/3-weekly/weekly-planner/scripts/planner_core.py` (`--mode stalled`, `## 5. Stalled & stale`
in `--mode daily`, per-device weekly-issue comment) and the two planner SKILL.md files. Commit in `provenance.jsonl`.

## Stub runs (disposable clone, stub `gh` on PATH, logging `git` wrapper) — `smoke-results.txt`: 38 PASS, 0 FAIL

| Acceptance line | Evidence |
|---|---|
| Section with dated rows + next action | `stub-run-STALLED.md`: every row carries `last activity <date>` and `→ next action` |
| Held never Stalled | PR #10 (`HOLD` title), #11 (evidence carrier), #12 (label `hold`), issue #101 (`Owner decision: hold`) all under **Held**; idle PR #13 and assigned idle issue #100 under **Stalled**; fresh PR #14 and unassigned #102 absent |
| Two devices → two comments; same-day re-run edits own | run 2 `PATCH` on the same id (count 2 → 2); `--device-id other-mac` → POST (2 → 3); `stub-run-gh-argv.log` |
| Failed/truncated lookup = coverage gap | `prfail` → coverage `failed`; 300-row PR list → `truncated`; comment **list** failure → no POST, exit 3; comment **write** failure → exit 3 |
| Local scan read-only | `stub-run-git-argv.log` (7 calls, non-empty) has no `fetch/prune/push/checkout/pull/reset/clean`; `.git/index` sha identical before/after a stat-only touch; **red control:** a log with one `fetch` line fails the check |
| No contents/secrets posted | comment body non-empty and free of the `SENTINEL-7f3a9c` planted in a PARKED note; **red control:** contaminated body fails |
| Plan-QA findings | F2 old no-upstream branch listed; F3 merged-name branch = `retire? name match — verify with /merge-cleanup`, reused name with an OPEN PR not a candidate; F4 resolved note and README excluded, open relay listed, approved relay excluded |
| Daily mode unchanged without baseline | nonzero with the `/weekly-planner` hint; with a baseline, `## 5. Stalled & stale` rendered and nothing posted without `--team-issue` |

## Live runs (task clone, real `gh`, this Mac `noels-mac-studio`)

- `--mode stalled --repo-root . --gh-repo HiQS-Labs/XYZ-forge` (no `--team-issue`): 5 stalled, 1 held (PR #1024 — review
  authority limit), 136 local rows across 20 clones under `~/marathon-clones`, 3 coverage gaps (clone-of-clone origins
  unresolved after one hop), ~9 s, nothing posted — `live-run-STALLED.md`, `live-run-stalled.json`.
- `--team-issue 1048` (the current weekly issue): comment created
  <https://github.com/HiQS-Labs/XYZ-forge/issues/1048#issuecomment-6358850907>; immediate re-run → `edited comment
  6358850907`; exactly one `planner-stalled:` comment on the issue afterwards.

## Not covered here

- `validate.sh --parallel 4` and `check_inventory_ratchet.py --check` ran in the disposable `-gate` clone (results in the
  PR body), not in this folder.
- XYZ-mini: both planner skills are `adapted`; this change is forge-only by design.
- The #1168 scheduler is not enabled; `--mode stalled` is the entry point it will call.
