# GH-1476 real preparation trial — parent selection/recon note (frozen before research)

Frozen at: 2026-11-17T19:08Z (trial start 2026-11-17T19:05:24Z, epoch 1794942324)
Numeric deadline: 2026-11-17T19:50:24Z (45 minutes total from start). Exhausted time forbids new research launch.
Owner: test sub-agent (parent role for this trial; synthesis is parent's).
Policy under test: Conveyor `skills/1-hourly/conveyor/SKILL.md` at branch `2e22cce06edaa1a4f0a58b85cff9e23ab62a18af` (PR #1514, unmerged).

## Baselines (no-mutation)

- Branch / evidence clone: retained verify clone `XYZ-forge-gh1476-raw-task-preparation-2026-11-16-verify`, HEAD `2e22cce06edaa1a4f0a58b85cff9e23ab62a18af`, branch `docs/XYZ-forge-gh1476-raw-task-preparation-2026-11-16`, `git status --porcelain` empty. Its `origin` is the retired producer path: never fetched.
- Live integration: `HiQS-Labs/XYZ-forge` `development` = `6000f3de1e24995806eb151bc1720b7cff77350a` (via `gh api repos/HiQS-Labs/XYZ-forge/branches/development`). Not present in the evidence clone; evaluated by read-only `gh api` content fetches only.
- Primary checkout `XYZ-forge`: HEAD `e389786d043995e3894969cfc9caad31b3e84f9d`, porcelain line count 0. Read-only `git rev-parse`/`status` only; must remain untouched.
- PR #1514 before: head `2e22cce06edaa1a4f0a58b85cff9e23ab62a18af`, OPEN, not draft; vendored smoke gate SUCCESS, promotion boundary SKIPPED, portability canary SKIPPED, CodeRabbit NEUTRAL; reviewDecision empty.

## Committed candidate set (preparation intent, not execution admission)

| Case | Issue | Why it fits | Expected Conveyor behavior |
| --- | --- | --- | --- |
| RAW | #1517 merge-cleanup SKILL.md batch protocol stale "runs no test suite" sentence | Open, filed today, no capture, no PRS row (branch ledger read), no contract | Accept RAW; one read-only medium research child; parent synthesizes capture + contract in isolated trial state only; parser check; no ledger row unless an isolated writer run targets a real capture. Must surface overlap with open PR #1516 (touches `skills/2-daily/merge-cleanup/SKILL.md`). |
| Prepared | #1171 relay preflight treats backticked branch name as missing path | Open; existing capture `PROJECT/1-INBOX/GH-1171-BRANCH-ARTIFACT-PREFLIGHT.md` with contract, live-source inspection and SHA-pinned unfixed control (`TESTS-RESULTS/2026-11-11+GH-1171/provenance.jsonl`, source `68367d66`) | Reuse, no research child. Freshness checks: issue/comments unchanged in scope, probe still discriminates at branch and at live development source, parser/Jog linter accept contract, overlap with open PRs #1467/#1505 (both touch `utils/py/relay_drive.py`). Stale or incomplete medium checklist → refresh what is cheap, hold the rest honestly. Preflight `--dry-run` needs a separate disposable clone: request from parent, do not run on evidence clone. |
| Held | #1518 pre-push full-gate reuse of ci-local receipt | Open; body states "Decision needed (operator)" — existing authority hold, not invented | No research child; no capture/contract; record hold, owner (operator) and the question; continue other items. |

## Attempt and time budgets (set before research)

- Research dispatches: exactly one read-only medium child for #1517; zero for #1171 (reuse) and #1518 (held). Remaining after launch: 0. No re-launch.
- Routine repairs: at most 3 per blocker. No automatic renewal.
- Existing PR #1514 code-review budgets (2/3) are untouched by this trial.
- Subscription only: native same-provider child (Claude Agent), no paid API routes.

## Isolation

Captures/contracts written only under the trial scratch directory. No primary or evidence-clone writes; no ledger write (canonical writer not run against any real repo DB); no readiness label; no Jog admission.
