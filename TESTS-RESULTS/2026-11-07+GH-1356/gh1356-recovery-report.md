## Batch 2 continuation: admission repaired; publication prerequisite exposed

Baseline primary `f5fe23793`; no duplicate replay of #1344 (partial PR #1350 already merged) or #1296 (open PR #1324). Existing pending #1344/#1345 Jog entries preserved. Prior child report lookup returned thread_not_found.

Selected only #1287; `roadmap pickup --issue-num 1287` exited 0 and **reused** its existing proposal row. This does not prove no-row pickup. `jog add GH-1287 --pos 1` initially refused because the primary was not pinned; configured the exact origin-specific primary pin and reran successfully (agent setup repair, one round). Primary C3 local checkpoint: `0b24095502b926e7e721f902e685eb77d9fbedf2`.

Disposable full clone: `/Users/noelsaw/Documents/GitHub/XYZ-forge-gh1356-1287-runner-20261107`; origin restored to canonical GitHub URL; pre-push hooks installed. No mutation-heavy gates run in primary or a linked worktree.

Admission repair rounds for #1287 (2):
1. `swarm_preflight.py --project-doc PROJECT/1-INBOX/GH-1287-FUZZ-NOVELTY-SIGNATURE.md --dry-run` exited 5: missing Acceptance section. Copied issue block verbatim in runner commit `2a3a8a4b6`; retry exited 0 but warned it inlined zero criteria because issue bullets are not checkboxes.
2. Converted those exact bullets to checkboxes with explicit formatting deviations, commit `48e4f6aaa`. Retry exited 0, readiness=1, **three** inlined criteria and acceptance match. Evidence: runner `temp/gh1287-preflight.log`. A first output redirect failed because fresh clone lacked temp/; created it and reran (agent setup correction, no failed preflight hidden).

`python3 -c 'import requests,yaml,pytest'` exited 1: system Python lacks requests. No gate-success claim; isolated environment setup remains outstanding.

`FACTORY_SUPERVISED=1 python3 utils/py/releases_app.py jog run --target-root <runner> --builder agy --reviewer codex --max-tasks 1` exited 2 before dispatch: **execution clone already has ledger changes**. Runner is clean; `jog_run.py:534-538` also compares committed ledger changes against `origin/development...HEAD`. Thus the local C3 checkpoint itself requires publication before admission. Evidence: primary `temp/gh1356-jog-1287.log`. No check modified or bypassed, no attempt caps raised, no worker tokens spent.

Parent prerequisite: inspect and publish the scoped primary selection checkpoint through the normal disposable-clone push gate, then refresh the runner's origin reference. Local-checkpoint authority was explicit; no merge or promotion performed. Preserve runner acceptance repairs. This is agent-assisted setup, not built-in recovery or autonomous qualification. No receipt-tail recovery, PR artifacts or landing evidence yet. No new human intervention beyond existing authorization. #1358 captured separately as unstarted intake, without a row or execution.
