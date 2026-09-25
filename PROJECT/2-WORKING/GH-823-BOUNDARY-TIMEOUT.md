---
title: "GH-823: ci — macOS promotion boundary times out (45-min cap vs a 60–92-min hosted sequential suite)"
status: Active
gh_issue: 823
source: https://github.com/HiQS-Labs/XYZ-forge/issues/823
doc_type: bugfix
created: 2026-09-25
updated: 2026-09-25
owner: operator (via /start-task)
goal: >
  The GH-509 promotion witness can finish: boundary-macos gets the same 120-minute cap that the same
  sequential suite already fits on the same runner, and test/ci-workflow.sh keeps the two caps from drifting apart.
related:
  - "#822 — 2026-09-25 post-merge review; this is its one promotion blocker"
  - "#509 — GH-509 promotion boundary (origin of the job and its bound)"
---

# GH-823 — macOS promotion boundary times out

## Status

| What was just completed | What's next |
|---|---|
| Issue filed, captured, parked and rated 85/80/50/90; promoted to 2-WORKING with a recon-grounded plan. | Implement the two edits, witness the red control, run final Codex QA and the full gate once, then open the PR. |

## Problem (observed)

`boundary-macos` in `.github/workflows/ci.yml` is the GH-509 promotion witness: on a push to `main` it runs
`./validate.sh --sequential` on `macos-latest`, with `timeout-minutes: 45` (`ci.yml:156`). The comment above it
("The suite runs ~13-15 min locally", `ci.yml:154`) dates from August. The job has run once, on 2026-08-17.

`wave-reconcile.yml:28` runs the same `validate.sh --sequential` on the same runner with `timeout-minutes: 120`.
Its job runtimes across the last 28 runs (2026-09-21 → 09-25) were 60–92 minutes. The committed qualification
receipts give suite spans of 67.7 / 89.2 / 84.4 minutes (`TESTS-RESULTS/2026-09-25+GH-591/wave-*/validation.jsonl`).
The next push to `main` would therefore time out and print `MACOS-BOUNDARY: red` for a reason unrelated to code.

## Recon

- **Entry point:** `ci.yml` `boundary-macos` job, `if: push && ref == main`. Steps: checkout, git env, npm ci, pip
  deps, `test/gh421-auto-wave-reconcile.sh`, `./validate.sh --sequential`, "Promotion evidence" (prints
  `MACOS-BOUNDARY: green|red ${GITHUB_SHA}`). A timeout cancels the job, so the `if: always()` evidence step reports red.
- **Contract test:** `test/ci-workflow.sh` extracts the job with the `boundary_block` awk at line 240 and at line
  282 checks only that some `timeout-minutes:` exists. It already monitors `wave-reconcile.yml` (line 109).
- **Other readers of the boundary job** (`test/gh379-canary-uses-validate.sh`, `test/gh509-gate-evidence.sh`,
  `utils/gate-status.sh`): none reads the timeout. `ci-local.sh` does not mirror it.
- **Stale claims elsewhere:** `test/baselines/GH-509-phase4-negative-control.md` records "45" and "~13-15 minutes"
  as dated historical evidence. Baselines are records, so they are left unchanged.
- **Recurrence:** latent. The boundary has not run since 2026-08-17, so there were 0 incidents in the last 14 days
  and in the 14 before; the trend is unknown. The signal is suite growth, not repeated failures.

## Plan

Extends the existing CI contract (`ci.yml` plus its lock `test/ci-workflow.sh`); no new files or subsystems.

1. `ci.yml`: set the `boundary-macos` `timeout-minutes` to 120 and rewrite the line-154 comment with the measured
   hosted runtime and the reason for matching `wave-reconcile.yml`. → expect `grep` to show 120 in `boundary_block`.
2. `test/ci-workflow.sh`: after the existing presence check, read the boundary cap and the `wave-reconcile.yml`
   reconcile-job cap, and fail if either is missing or the boundary cap is lower. → expect PASS at 120. Red control:
   a copy with 45 must FAIL, and so must a copy with the timeout line deleted.
3. `CHANGELOG.md`: one end-of-iteration entry.
4. Focused check: `bash test/ci-workflow.sh` in a disposable clone of the branch. Final Codex relay QA on the diff
   and evidence. Full qualifying gate once on the final commit in a separate disposable clone. PR into `development`.

**Test scope:** `test/ci-workflow.sh` only. **Non-goals:** suite speed-ups (#808, #817, #819), a dispatch trigger,
changing the wave-reconcile cap, editing historical baselines.

**Reversibility:** Easy. Revert one value, one assertion and one comment. **Blast radius:** only the push-to-`main`
boundary job, whose worst case goes from 45 to 120 macOS minutes per promotion. `main` receives pushes only at
promotion, and standard runners are free for public repositories; the cost notes in `ci.yml` date from the private phase.

**Plan QA:** skipped as a simple change, per `/start-task` Step 6. The change is obvious (measured 60–92 min vs a
45-min cap), local (one workflow value and one assertion in its existing lock), and reversible, and it involves no
behavioural design choice. Final Codex QA reviews this plan together with the diff.

## Rating

`rated 85/80/50/90` (2026-09-25, read back from the ledger).

- **Severity 80:** blocks work. No `main` promotion can go green while it stands. No data risk, fully recoverable.
- **Priority 85:** the operator is promoting now, and this is the one blocking code change.
- **Appeal 50:** neutral.
- **Effort 90:** a one-value change plus one assertion.
