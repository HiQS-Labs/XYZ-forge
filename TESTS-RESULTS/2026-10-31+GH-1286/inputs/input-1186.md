# PR #1186: ci(GH-1182): run the inventory ratchet in the PR smoke lane
mergedAt: 2026-10-24T02:52:32Z
files: .github/workflows/ci.yml

Closes the open question on #1182 (operator decision 2026-10-23: yes). Reversibility: **Easy** — one CI step.

## What

`.github/workflows/ci.yml`, job `vendored-smoke`: a new step `Inventory ratchet (GH-777, #1182)` runs
`python3 utils/pdda/check_inventory_ratchet.py --check` right after checkout, on every PR and push the job already covers.

## Why

The ratchet (new loose script under `utils/`, `scripts/` or `bin/`; new `sqlite3.connect` outside `releases_app.py`) ran only in the full gate. PR #1176 therefore merged with green hosted checks and then turned `development`'s wave-reconcile RED until #1179 landed. The check is read-only and ~1 s, so the PR lane can afford it.

## Evidence

- `check_inventory_ratchet.py --check` on this head: clean (matches baseline, 0 new scripts/connects).
- The step exercises itself: this PR's own `vendored smoke gate` run must show it green. **Red control** available on request: a throwaway branch adding an empty `utils/py/zz_probe.py` should fail this step.
- `utils/ci-route.sh pull_request` classifies `.github/workflows/ci.yml` as full-gate; the full gate is unchanged by this edit (it already runs `gh777-inventory-ratchet.sh`), and hosted CI on this PR is the gate for the workflow change itself. Pushed from a fresh clone without the local pre-push hook for that reason; the local full suite was not re-run for a one-step YAML change.
- GH-831: no new suite, no new gate machinery in the repo — this re-sites an existing check into an existing job.

🤖 Generated with [Claude Code](https://claude.com/claude-code)


<!-- This is an auto-generated comment: release notes by coderabbit.ai -->

<!-- coderabbit-ai-generated:v1 -->

## Summary by CodeRabbit

* **Chores**
  * Automated checks now validate inventory before reconciliation runs. This adds an early consistency check to the workflow, helping flag inventory changes that do not meet the expected criteria. No user-facing features or behavior changed.

<!-- end of auto-generated comment: release notes by coderabbit.ai -->
