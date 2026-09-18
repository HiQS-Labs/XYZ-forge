---
title: "GH-708: suites that need forge-root-only paths are red from every vendored .xyz/ — make them witnessed skips"
status: active
created: 2026-09-18
updated: 2026-09-18
owner: unassigned
goal: a vendored install can run any shipped suite and get either a real verdict or a named `skip: not vendored`, never a spurious red
gh_issue: 708
source: https://github.com/HiQS-Labs/XYZ-forge/issues/708
doc_type: bug
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/710
  - https://github.com/HiQS-Labs/XYZ-forge/issues/197
  - https://github.com/BinoidCBD/LTVera-Pandas/issues/551
context_tags: [xyz-vendor, test-harness, consumer-repo, fixture-guard]
non_goals:
  - Vendoring githooks/, validate.sh, ci-local.sh or .github/ into .xyz/ (see decision)
  - Making /express run in a vendored install
  - A vendored validate.sh or any new runner
---

# GH-708 — forge-root-only suites are red from a vendored `.xyz/`

## Problem (observed, LTVera-Pandas `.xyz` at `2707ddb0`)

`test/gh267-express-skill.sh:110` copies `$HERE/../githooks/install.sh`; `xyz-vendor.sh:432` ships
`VENDOR_DIRS="relay-automation bin src utils test skills"` — no `githooks/` — so the suite is rc 1
on every vendored target while 108/0 green in the forge at the same SHA. `test/` is vendored "so a
vendored repo can self-verify" (`xyz-vendor.sh:422`), so a red that only means "this is not the
forge" is a false signal.

## Decision: skip, do not vendor `githooks/`

- `utils/py/express.py` resolves `<repo-root>/githooks/install.sh` — the *consumer's* root, never
  `.xyz/` — so vendoring the directory would not make express work there.
- `githooks/pre-push` refuses any push when `<root>/validate.sh` is missing (`pre-push:52-56`);
  installing the forge's hook into a consumer would block all of its pushes. Express is forge-only
  by design; the `gate-unwired` refusal is correct in a vendored install.
- Therefore the suite (and every suite that needs a forge-root-only path) should announce a
  **witnessed skip** in a vendored install and keep refusing loudly in a forge checkout where the
  path is unexpectedly missing.

## Sweep (anchored on the forge root, not on fixtures; comments excluded)

19 suites reach a path outside `VENDOR_DIRS` through `$HERE/..` (or a ROOT derived from it):

| forge-root path | suites |
|---|---|
| `validate.sh` | ballast-release, ci-workflow, gh365-driver-lane-registry, gh365-runner-envelope, gh365-validate-telemetry, gh379-canary-uses-validate, meter-release, nightwatch-release, oracle-guard |
| `ci-local.sh` | ci-workflow, gh35-test-tiers, gh365-runner-envelope, gh365-shellcheck-parallel, gh365-validate-telemetry, gh536-evidence-detail, gh544-parallel-default |
| `githooks/` | gh267-express-skill, gh35-test-tiers, gh544-pre-push-gate |
| `.github/` | gh544-parallel-default, gh544-pre-push-gate |
| `sentinel-overlay/` | sentinel-overlay |
| `AGENTS.md` / `ROUTER.md` / `README.md` | gh527-destructive-git-guard / pdda-install-startup-docs / runner-loop |

Method: every `$VAR/<path>` reference in `test/*.sh` whose `VAR` is assigned from `$HERE/..`,
`cd "$HERE/.." && pwd`, `cd -P "$(dirname "$0")/.."`, or `git rev-parse --show-toplevel`; fixture
roots (`$FIX`, `$WORK/...`) are excluded; `swe-diagram.sh` mentions `ARCHITECTURE/` only in a
comment. Sweep transcript: `relay-system/2026-09-18/gh708-sweep.txt`.

## Plan

1. `test/lib/fixture-guard.sh`: add `require_forge_root <relpath>…` beside `require_fixture`. For
   each relpath: present under `$HERE/..` → continue; absent and the tree is a vendored install
   (`$HERE/../VERSION` carries `source_commit=` — the stamp `xyz-vendor.sh` writes) → print
   `skip: not vendored — <suite> needs <relpath> (forge-root only; source_commit=<sha>)` on stdout
   and `exit 0`; absent in a non-vendored tree → `forge-root: REFUSING — …` on stderr, `exit 2`
   (a check that cannot fail is not a check). One helper, same file the issue proposed, same
   fail-closed voice as its neighbours.
2. Each of the 19 suites calls it once, right after sourcing the guard, naming exactly the paths it
   needs (e.g. `require_forge_root githooks/install.sh`). Suites that do not source fixture-guard
   today source it for this call only.
3. New `test/gh708-vendored-suite-skips.sh` (registered in `validate.sh`): (a) a fixture tree with
   `VERSION` + `test/lib/fixture-guard.sh` + a probe suite → `skip: not vendored` line and rc 0;
   (b) the same tree without `VERSION` → rc 2 and `REFUSING` on stderr (red control); (c) the path
   present → the probe continues and prints nothing; (d) the real witness: `xyz-vendor.sh` this
   checkout into a throwaway target and run `.xyz/test/gh267-express-skill.sh` → the skip line,
   rc 0; and the pre-fix failure mode (`cp: … No such file`) must not appear.
4. Verification: `bash test/gh708-vendored-suite-skips.sh`, `bash test/gh267-express-skill.sh`
   (still 108/0 in the forge — the helper is a no-op here), `bash test/xyz-vendor.sh` (unchanged
   manifest), and on LTVera after re-vendor: `bash .xyz/test/gh267-express-skill.sh` → skip.

## Non-goals

Vendoring forge-only infrastructure; a vendored runner; touching suites whose only "outside"
references are fixture-relative.

## Risks / rollback

Easy — additive helper and one line per suite; revert restores the reds. Risk: a suite that
*creates* the path it names (none in the 19 — each reads a checked-in file) would skip wrongly in a
vendored tree; the witness in 3(d) plus the per-suite line naming a checked-in path bounds it.

## Acceptance

- [ ] `gh708-vendored-suite-skips.sh` green, its red control witnessed.
- [ ] Forge gate unchanged: the 19 suites still run (no skip line) in the forge.
- [ ] Consumer: `bash .xyz/test/gh267-express-skill.sh` on LTVera prints the skip and exits 0.

## Rating (2026-09-18) — `rated 65/55/50/80`

- sev 55: every vendored install reports a false red on a shipped suite; misleading, no data or
  work lost.
- pri 65: blocks LTVera#551 Step 2 acceptance ("failures block Step 3+"); ordered after #710 which
  breaks the consumer's reconcile.
- appeal 50: neutral.
- effort 80: one helper, 19 one-line call sites, one suite with a vendor witness.
- Recurrence: first report of this class (vendored suite red for a forge-only path); GH-197 (tier
  split) and GH-312 (preserve list) were vendor-manifest issues of a different class.

## Status

active — plan under review (relay), implementation pending.

## Merge evidence

(filled at landing)

## Lessons Learned (For Future Agents)

(filled at landing)
