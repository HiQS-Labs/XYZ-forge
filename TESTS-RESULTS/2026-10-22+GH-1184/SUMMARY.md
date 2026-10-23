# GH-1184 — manual smoke receipt (GH-1088 / GH-831: no new suite)

Change under test: `skills/3-weekly/weekly-planner/scripts/planner_core.py` (`--mode stalled`, `## 5. Stalled & stale`
in `--mode daily`, per-device weekly-issue comment) and the two planner SKILL.md files. Commit in `provenance.jsonl`
(refreshed after final-QA round 1: F1–F5 + nits fixed).

## Stub runs (disposable clone, stub `gh` on PATH, logging `git` wrapper) — `smoke-results.txt`: 45 PASS, 0 FAIL

| Acceptance line / finding | Evidence |
|---|---|
| Section with dated rows + next action | `stub-run-STALLED.md`: every Stalled, Local **and Held** row carries `last activity <date>` and `→ next action` (F5) |
| Held never Stalled | PR #10 (`HOLD` title), #11 (evidence carrier), #12 (label `hold`), issue #101 (`Owner decision: hold`) under **Held**; idle PR #13 (→ rebase) and assigned idle issue #100 under **Stalled**; fresh PR #14 and unassigned #102 absent |
| Two devices → two comments; same-day re-run edits own | run 2 `PATCH` on the same id (count 2 → 2); `--device-id other-mac` → POST (2 → 3); `stub-run-gh-argv.log` |
| Prior-device gap uses the LOCAL date (F2) | `no report since 2026-10-20` for `other-mac`; this device `today` |
| Failed/truncated lookup = coverage gap, never "nothing stalled" | **open-PR lookup failure → report still produced, rc 0, `failed open PRs` coverage, Stalled renders `coverage incomplete` (F1)**; 300-row PR list → `truncated`; comment **list** failure → no POST, exit 3; comment **write** failure → exit 3 |
| Local scan read-only | `stub-run-git-argv.log` non-empty, no `fetch/prune/push/checkout/pull/reset/clean`; `.git/index` sha identical before/after a stat-only touch (`--no-optional-locks`); **red control:** a log with one `fetch` line fails the check |
| No contents/secrets posted | comment body non-empty and free of the `SENTINEL-7f3a9c` planted in a PARKED note; **red control:** contaminated body fails |
| Notes | open note listed; resolved note and README excluded; `Closed-loop review…` prose NOT treated as resolved; **old note with only an unstaged edit today is listed (F3)**; all 15 PARKED notes in the JSON, rendering shows 10 + `+5 more` (F4); open relay listed, approved relay excluded |
| Local branches | recent and 3-week-old no-upstream branches both listed; merged-name branch = `retire? name match — verify with /merge-cleanup`; reused name with an OPEN PR not a candidate; never "safe to retire" |
| Daily mode | without baseline → nonzero with the `/weekly-planner` hint (unchanged); with a baseline → `## 5. Stalled & stale` rendered, nothing posted without `--team-issue` |

## Live runs (task clone, real `gh`, this Mac `noels-mac-studio`)

- `--mode stalled --repo-root . --gh-repo HiQS-Labs/XYZ-forge` (no `--team-issue`): 5 stalled, 1 held (PR #1024 — review
  authority limit), 137 local rows across 20 clones under `~/marathon-clones`, 3 coverage gaps (clone-of-clone origins
  unresolved after one hop), ~9 s, nothing posted — `live-run-STALLED.md`, `live-run-stalled.json`.
- `--team-issue 1048` (the current weekly issue): first run created
  <https://github.com/HiQS-Labs/XYZ-forge/issues/1048#issuecomment-6358850907>; every later run (including after the
  round-1 fixes) `edited comment 6358850907`; exactly one `planner-stalled:` comment on the issue throughout.

## Gates

- `full-gate-b3138992.log`: `validate.sh --parallel 4` in the disposable `-gate` clone at the first implementation
  commit — **passed 409/409, rc 0**; `check_inventory_ratchet.py --check` clean; `ci-route.sh pull_request` → docs/tier 1.
  The final commit re-runs the same gate before the push (result in the PR body).

## Not covered here

- XYZ-mini: both planner skills are `adapted`; this change is forge-only by design.
- The #1168 scheduler is not enabled; `--mode stalled` is the entry point it will call.
