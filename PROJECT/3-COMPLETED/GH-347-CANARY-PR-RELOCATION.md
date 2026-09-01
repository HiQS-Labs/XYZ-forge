---
title: "GH-347: move the advisory Ubuntu portability canary off the pull-request path"
status: Complete
created: 2026-08-31
updated: 2026-09-01
owner: noelsaw1
goal: relocate the non-gating Ubuntu portability canary to integration time while preserving an accurate, actionable promotion-time status
gh_issue: 347
source: https://github.com/HiQS-Labs/XYZ-forge/issues/347
branch: fix/gh347-canary-relocation
doc_type: bugfix
effort: 1
complexity: 2
risk: 2
phases: 1
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/344
  - https://github.com/HiQS-Labs/XYZ-forge/issues/365
non_goals:
  - Making the Ubuntu canary green
  - Promoting parallel validation to qualifying evidence
  - Changing the macOS promotion boundary
---

# GH-347 · Move the advisory Ubuntu canary off pull requests

## Status

| What was just completed | What's next |
|---|---|
| PR #366 merged to `development`; its hosted PR workflow completed in 2 seconds with both jobs skipped and zero runner minutes, and the result is recorded on #347. | Broader suite measurement, parallel-equivalence evidence, and smoke-lane decisions continue separately in #365. |

## Why

The advisory Ubuntu job is the pull-request long pole and the entire sampled runner-minute bill even
though `continue-on-error: true` prevents it from gating a merge. Its useful consumption point is the
promotion decision, not an author waiting for PR feedback.

The existing promotion reader also queries the workflow-run conclusion. An advisory job may conclude
failure while the workflow concludes success, so that query can print a false-green portability
status. Relocation must correct that reader or it would preserve only the appearance of an actionable
signal.

## Decision

Run the canary on pushes to `development`, where integrated work becomes visible, and retain
`workflow_dispatch` as the deliberate fallback. Do not run it for `pull_request` or a push to `main`.
This cuts it from the PR critical path, avoids paying twice for PR-head and post-merge runs, and leaves
one fresh integration signal before promotion.

`utils/gate-status.sh` reads the latest completed push-on-development workflow and then the
`canary-ubuntu` job's conclusion from that run. It must never infer the canary from the enclosing
workflow conclusion.

## Acceptance criteria

- [x] `canary-ubuntu` runs on push to `development` and on `workflow_dispatch`.
- [x] `canary-ubuntu` does not run for `pull_request` or push to `main`.
- [x] `continue-on-error: true`, the verdict step, and `fetch-depth: 0` remain intact.
- [x] The promotion reader reports the canary job's conclusion and includes its source SHA.
- [x] A negative control proves a successful workflow containing a failed canary reports drift.
- [x] Workflow-contract tests pin the relocation without weakening automatic CI triggers.
- [x] The post-change PR run is measured and the new critical path recorded on #347.
- [x] Full sequential macOS validation remains the promotion-evidence contract.

## Verification

- `bash test/ci-workflow.sh`
- `bash test/gh509-gate-evidence.sh`
- `bash ci-local.sh` in a separate disposable full clone
- Witness the pull-request workflow and record its elapsed time and job conclusions

## Lessons Learned

- `continue-on-error` changes the enclosing workflow conclusion, so workflow-level success is not
  evidence that an advisory job passed. Promotion tooling must inspect the named job.
- A relocation assertion should inspect the workflow's effective `if:` block, not comments around
  it; otherwise explanatory prose can make a negative trigger test fail for the wrong reason.
- The suite's optional local gate record can refuse after a green run when a benchmark suite mutates
  tracked registry artifacts. The full gate verdict and clone-identity invariant remain distinct
  evidence, and the dirty artifacts must not be committed from the disposable clone.
