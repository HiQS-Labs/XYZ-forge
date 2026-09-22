---
gh_issue: 741
source: https://github.com/HiQS-Labs/XYZ-forge/issues/741
title: "hosted_lane_report.py blames the last 'wave-reconcile: ERROR' line — on a --qualify run that is a unit test's expected output (#735 named 'invalid merged_at timestamp'; the run failed on the push step)"
status: Active (2-WORKING)
created: 2026-09-21
updated: 2026-09-22
owner: unassigned
doc_type: capture
complexity: 2
risk: 3
effort: 2
rating: "pri/sev/appeal/effort 60/60/90/70 · calc 280"
rating_ovr: null
is_manual_override: false
ratings_provisional: true
goal: >
  hosted_lane_report.py names the step that actually failed (push vs reconcile) instead of blaming
  the last `wave-reconcile: ERROR` line in the whole tee'd log.
---

# GH-741 — hosted_lane_report.py blames the last 'wave-reconcile: ERROR' line — on a --qualify run that is a unit test's expected output (#735 named 'invalid merged_at timestamp'; the run failed on the push step)

## Status

| What was just completed | What's next |
|---|---|
| Queued by the 2026-09-21 `/10days` sweep: validity, reproducibility and not-already-done verified against HEAD e565c0fe (see Why); contract auto-drafted. | Marathon lane fires from `marathon/10days-2026-09-21` via `swarm-preflight → marathon-drive`, scoped by the contract's `artifacts`. |

## Why

`utils/py/hosted_lane_report.py:53-57` `summarize()` returns `errors[-1]` over the entire
`reconcile.log`, and `.github/workflows/wave-reconcile.yml` passes only `job.status` — the reconcile
and push steps have no `id:` so their outcomes are invisible. On run 35623940059 the push step was
rejected (`[rejected] … (fetch first)`) but the issue blamed `invalid merged_at timestamp` from an
earlier qualify pass. Build fix shape 2 (step-aware report): give the steps ids, capture the push
step's git stderr to `$RUNNER_TEMP/push.log`, and pass `--reconcile-outcome`/`--push-
outcome`/`--push-log` to the reporter. No fix commit or PR references #741.

## Acceptance
- [ ] Replaying run 35623940059's `reconcile.log` with `job.status=failure` and reconcile-step outcome `success` through `hosted_lane_report.py` yields a body naming the push-step failure (`[rejected] … (fetch first)`), **not** `invalid merged_at timestamp`.
- [ ] Red control: a green reconcile log containing test-emitted `wave-reconcile: ERROR —` lines with `job.status=success` yields no issue (today's `summarize()` still finds an "error" there).
- [ ] A genuine reconcile-step `die(...)` is still reported verbatim as the terminal error.
- [ ] `bash test/gh421-auto-wave-reconcile.sh` stays green: `WorkflowTests.test_publish_allowlist_and_plan_lands` extracts the publish step's inline Python from `.github/workflows/wave-reconcile.yml` and runs it; adding step `id:`s / capturing the push log must not change that step's extracted body or make it exit early (marathon attempt 1 on 2026-09-22 failed it with `SystemExit: 0`). Read the test's extraction before editing the workflow.

## Acceptance — deviations from the issue

The issue states its acceptance as plain bullets; each is carried below as a checkbox with the wording
unchanged so the preflight packet inlines it as the builder's definition of done.

- [added] Replaying run 35623940059's `reconcile.log` with `job.status=failure` and reconcile-step outcome `success` through `hosted_lane_report.py` yields a body naming the push-step failure (`[rejected] … (fetch first)`), **not** `invalid merged_at timestamp`. — reason: issue states this criterion as a plain bullet; carried as a checkbox, wording unchanged, so the packet carries it as the builder's definition of done
- [added] Red control: a green reconcile log containing test-emitted `wave-reconcile: ERROR —` lines with `job.status=success` yields no issue (today's `summarize()` still finds an "error" there). — reason: issue states this criterion as a plain bullet; carried as a checkbox, wording unchanged, so the packet carries it as the builder's definition of done
- [added] A genuine reconcile-step `die(...)` is still reported verbatim as the terminal error. — reason: issue states this criterion as a plain bullet; carried as a checkbox, wording unchanged, so the packet carries it as the builder's definition of done
- [added] `bash test/gh421-auto-wave-reconcile.sh` stays green: `WorkflowTests.test_publish_allowlist_and_plan_lands` extracts the publish step's inline Python from `.github/workflows/wave-reconcile.yml` and runs it; adding step `id:`s / capturing the push log must not change that step's extracted body or make it exit early (marathon attempt 1 on 2026-09-22 failed it with `SystemExit: 0`). Read the test's extraction before editing the workflow. — reason: wave-gate regression on marathon attempt 1 (2026-09-22); carried as a criterion so attempt 2 builds against it

## Swarm Preflight Contract

```json
{
  "target": {
    "repo": ".",
    "ref": "development"
  },
  "gate": "bash validate.sh",
  "fix_probes": [
    {
      "type": "grep_present",
      "path": "utils/py/hosted_lane_report.py",
      "pattern": "return \\(errors\\[-1\\] if errors else None\\), skips"
    },
    {
      "type": "path_absent",
      "path": "test/fixtures/gh741-run-35623940059-reconcile.log"
    }
  ],
  "artifacts": [
    "utils/py/hosted_lane_report.py",
    ".github/workflows/wave-reconcile.yml",
    "test/gh684-hosted-lane-report.sh",
    "test/fixtures/gh741-run-35623940059-reconcile.log"
  ],
  "artifacts_new": [
    "test/fixtures/gh741-run-35623940059-reconcile.log"
  ],
  "remediation": {
    "source": "issue#741",
    "criteria": "Step-aware hosted lane report: pass step outcomes + push log from the workflow, replay run 35623940059 as the regression"
  },
  "lanes": {
    "agy_safe": [
      "utils/py/hosted_lane_report.py",
      "test/gh684-hosted-lane-report.sh",
      "test/fixtures/gh741-run-35623940059-reconcile.log"
    ],
    "orchestrator_only": [
      ".github/workflows/wave-reconcile.yml"
    ]
  }
}
```

Contract auto-drafted by /10days from the issue text — artifacts/lanes not yet operator-verified. Fix probes detect the BUG (`grep_present` = bug still there, `grep_absent` = fix landed), per swarm-preflight polarity.