---
title: "GH-879: correct the CI suite audit method"
status: active
created: 2026-09-28
updated: 2026-09-30
owner: "XYZ Forge maintainers"
goal: "Make the October 8 full-suite audit's verdicts and evidence auditable."
gh_issue: 879
effort: 2
complexity: 3
risk: 2
phases: 1
---

# GH-879 — CI suite audit method fixes

## Status

| What was just completed | What's next |
|---|---|
| Corrected the skill rules on staging, recorded red-control and full-gate evidence, and obtained independent Agy QA. The roadmap row is rated 75/55/70/85. | Land through #854 Landing 2, then run the full audit on October 8. |

## Scope and decision

The [issue](https://github.com/HiQS-Labs/XYZ-forge/issues/879) owns the detailed findings. Edit the existing text-only `ci-suite-audit` skill: remove KEEP defaults and conflicting flake rules, require four saved evidence sources with honest denominators, pin the target and registry count, compute runtime from compatible receipts, and fix the remaining restore and SHA instructions. Do not add a runner, gate, or new test suite.

The latest #854 handoff schedules the full audit for 2026-10-08 after Landing 2. Its newer classification of gh610, gh123, and registry-lock-concurrency as INVESTIGATE supersedes #879's earlier instruction to quarantine them on historical divergence alone.

## QA gate

- `git diff --check` and a manual contradiction scan of the skill.
- Check the existing `measured.json` and suite source for the three seeded flakes, calibration files, and source counts. Record a witnessed bad-rule control in `TESTS-RESULTS/` with provenance.
- Independent relay review of the final skill and GH-139 guard, plus the relevant existing repo checks in a separate disposable full clone.

## Lessons Learned (For Future Agents)

One aggregate gate-runtime denominator and each suite's failure-run denominator answer different questions. Keep them separate; issue and commit counts provide attribution, not extra runs.

## Merge evidence

- PR #895 merged 2026-09-30 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
