---
Goal: Plan QA for GH-1409 (vendored-smoke base-pinning of judge files)
Date: 2026-11-10
NEXT: codex
STATUS: Open
---

# Context

Review the implementation plan in `PROJECT/2-WORKING/GH-1409-VENDORED-SMOKE-BASE-PIN.md` before any
code is written. The issue text is https://github.com/HiQS-Labs/XYZ-forge/issues/1409, and the
recon comment that narrowed it is linked from the plan.

**Operational envelope.** This is a public single-maintainer repo. Every PR is authored by one
account, and agents run under it. The goal is to stop a PR from weakening vendored-smoke's own
judge files in the same change. It is not a defence against a determined insider; the operator
explicitly accepted the `ci.yml` self-edit loophole and dropped CODEOWNERS. The repo forbids new
tests, new suites and new gate machinery (`AGENTS.md` "No new tests", GH-831). A new loose script
under `utils/` would also trip the inventory ratchet. Grade against the plan's requirements
R1–R5 and commensurate complexity. Do not ask for enterprise controls.

Read the following:
- `PROJECT/2-WORKING/GH-1409-VENDORED-SMOKE-BASE-PIN.md` (the plan)
- `.github/workflows/ci.yml`: the `vendored-smoke` job, about lines 524-583
- `utils/pdda/check_inventory_ratchet.py` and `utils/pdda/inventory_ratchet_baseline.json`
- `test/gh308-frozen-twin-guard.sh` (lines 1-80), `test/gh421-auto-wave-reconcile.sh` (head)
- The heads of `test/gh396-find-harness-roots.sh`, `test/gh393-deepseek-readiness.sh`,
  `test/gh358-wave-reconcile-vendored-paths.sh`, `test/gh292-worktree-vendored-discovery.sh`
- `relay-automation/xyz-vendor.sh` (`VENDOR_DIRS`, about line 432)
- `test/ci-workflow.sh` (around lines 355-362, which pin the twin guard's placement)

# Questions

1. **R1.** On a `pull_request` run, `actions/checkout` checks out `refs/pull/N/merge` with
   `fetch-depth: 0`. Is `HEAD^1` the right trusted base, and is failing closed when `HEAD^2` is
   absent correct? Does removing the gh308 step's step-level `BASE_SHA` env change its behaviour
   on PR merge refs?
2. **R4 (pin in place).** The plan claims that restoring each judge script in place with
   `git checkout "$BASE_SHA" -- <paths>` keeps it scanning the candidate tree, because each one
   resolves paths from its own location. It also claims `xyz-vendor.sh` then copies the base
   copies of the four suites into `.xyz/test`. Verify both against the cited lines. Is any judge
   script missed, or does any of them read a sibling file that would then mismatch?
3. **R2 (baseline monotonicity).** Does the planned comparison (scripts subset, bypass-file subset,
   count not larger) accept every legitimate `--update-baseline` shrink and reject every growth
   that `check_inventory_ratchet.py --check` would otherwise accept with an inflated baseline?
   Remember that the pinned ratchet then runs against the PR's own baseline.
4. **R3 (marker diff).** Is `git diff -U0 "$BASE_SHA" HEAD -- '*.py' '*.sh' ':!test/**'`, grepped
   for added `SQLITE-(BYPASS|GATEWAY)-OK:` lines, correctly scoped against what
   `scan_sqlite_bypasses` actually honours (`PRUNED_DIRS`, `SCRIPT_EXTS`)? Would it false-positive
   on a plain line move inside a file? If so, is that acceptable friction?
5. **R5 (label).** Is a live `gh pr view --json labels` lookup with `GH_TOKEN: github.token` under
   the workflow's `contents: read` permission workable on this public repo? Is "re-run after
   labelling" a sound operator flow?
6. **Scope.** Is the design surgical: one inline step, no new file, no new suite? Flag any
   over-engineering, and any requirement from the issue's Phase 1/2 that was dropped without a
   recorded reason.
7. **Verification.** Do the five manual controls (three red, one green, one label-adjacent) plus
   this PR's own hosted run actually falsify R2–R5? Is extracting the step's `run:` block and
   running it against a constructed `--no-ff` merge in a disposable clone a faithful reproduction?

Every `[Blocker]` or `[Should]` that asks for a behaviour change must carry `Observed input:`,
`Affected scope:` and `Falsifier:` lines. Cite `file:line`. Write your verdict below. Set
`STATUS: Approved` if the plan can proceed as written (or with only `[Nit]`s); otherwise hand back
with your findings.

## Log

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
