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

## Sweep — final, empirical (the static anchor sweep missed three times)

Two static passes found 19, then 25 suites. The acceptance witness — vendor this checkout into a
throwaway consumer (`xyz-vendor.sh --with-releases`) and run **every** shipped suite from
`.xyz/test/` — is what settled it: **397 suites → 323 pass, 60 witnessed skips, 14 fail**
(`relay-system/2026-09-18/gh708-vendored-run.txt`; three of the 14 skip on a clean tree and failed
only because an earlier suite had created `.git` under the vendored root — see follow-ups).

62 suites now call `require_forge_root`, naming the checked-in forge-root path each one reads:

| forge-root path | suites |
|---|---|
| `validate.sh` (± `ci-local.sh`) | ballast-release, ci-route, ci-workflow, gh141-synthetic-registry, gh182-healer-facade-safety, gh251-validate-pytest-skip, gh298-ate-gen4-ci-smoke, gh306-registry-bidirectional, gh365-driver-lane-registry, gh365-runner-envelope, gh365-tier-fail-closed, gh365-validate-telemetry, gh379-canary-uses-validate, gh4-ungated-clone-warning, gh419-gate-inventory, gh441-gate-env-contract, gh528-parallel-contention-retry, gh648-l3-consult-cap, gh77-standup-triage, gh-gen4-phase1-domain-oracles, meter-release, nightwatch-release, path-integrity |
| `ci-local.sh` only | gh35-test-tiers (+githooks), gh365-shellcheck-parallel, gh536-evidence-detail, gh544-parallel-default |
| `githooks/` | gh267-express-skill, gh544-pre-push-gate |
| `.github/workflows/*` | gh421-auto-wave-reconcile, gh509-gate-evidence, gh567, gh568 |
| `releases.db` / `.gitattributes` | gh107-timeline-json-seam, gh153-releases-sidebar-rollup, gh269-roadmap-retired, gh32-releases-artifacts, gh53-releases-merge-resolve, gh549-work-events, gh567-roadmap-dashboard-retired, gh568-releases-md-retired |
| `harnesses.db` | gh174-harness-registry, gh205-gate-idempotency, gh496-telemetry-isolation |
| the forge as a git repo (`.git`, `.gitignore`) | gh-gen4-phase3-fuzz-engine, gh-gen4-phase5-campaign, gh413-launch-artifact-destination-guard, gh430-state-dir-tracked-default, gh436-merge-cleanup (+`.gitattributes`, `WORKTREE-SAFETY.md`), gh589-consult-no-tick, gh589-xyz-mini-sync (+`mini/`), gh620-skills-army-mini-sync, marathon-root-audit |
| governance / docs | gh378 (`decisions/…`), gh379-claude-builder-diagnosis + gh384-crash-recovery + runner-loop (`README.md`), gh415 + gh527 (`AGENTS.md`), pdda-install-startup-docs + releases-skill (`ROUTER.md`, `PROJECT/PDDA.md`), sentinel-overlay (`sentinel-overlay/`), swe-diagram (`ARCHITECTURE/`), registry-lock-concurrency (`install.sh`) |

Also fixed in passing (same failure surface, one-line each): eight suites sourced `test/_setup.sh`
relative to the **CWD** and so only ran from the repo root — `gh204`, `gh205`, `gh238`, `gh239`,
`gh257`, `gh269`, `gh413`, `gh496-phase2` now source it script-relative like their siblings.

Not in the list: `oracle-guard.sh` already skips its one sub-test when `$ROOT/validate.sh` is
absent (the wording this helper adopts).

**Follow-ups (not this issue — tracked in #715):** 11 suites still fail in a vendored copy
for other reasons: python module paths that assume the forge layout (`agent-chorus`,
`gh-gen4-phase4-repro-synth`, `gh478-runaway-guard`, `gh589-skill-viewer`) and behavioural
differences (`gh141-fuzz-inputs`, `gh155-phase1-metamorphic-invariants`,
`gh273-marathon-root-audit-python-shape`, `gh649-pdda-migration`, `relay-xyz-skill-guard`,
`swarm-preflight`, `test-agy-isolation`). Two suites write into the vendored root while running
(`gh218-synthetic-nested-driver-lock` creates `.git/`; `hq-promote` creates `PROJECT/`) — a
containment defect that also masks the `.git` skips of later suites.

## Plan

1. `test/lib/fixture-guard.sh`: add `require_forge_root <relpath>…` beside `require_fixture`. For
   each relpath: present under `$HERE/..` → continue; absent and the tree is a vendored install
   (`$HERE/../VERSION` carries `source_commit=` — the stamp `xyz-vendor.sh` writes) → print
   `skip: not vendored — <suite> needs <relpath> (forge-root only; source_commit=<sha>)` on stdout
   and `exit 0`; absent in a non-vendored tree → `forge-root: REFUSING — …` on stderr, `exit 2`
   (a check that cannot fail is not a check). One helper, same file the issue proposed, same
   fail-closed voice as its neighbours.
2. Each affected suite (62 at landing) calls it once, right after sourcing the guard, naming exactly the paths it
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

- [x] `gh708-vendored-suite-skips.sh` green (17/17), its red control witnessed.
- [x] Forge gate unchanged: every touched suite still runs (no skip line) in the forge — verified per suite, 62/62 green.
- [x] Empirical witness: 397 vendored suites → 323 pass, 60 skip, 14 fail (3 of them skip on a clean tree); the 11 true leftovers are named above and tracked separately.
- [ ] Consumer: `bash .xyz/test/gh267-express-skill.sh` on LTVera prints the skip and exits 0.

## Rating (2026-09-18) — `rated 65/55/50/80`

- sev 55: every vendored install reports a false red on a shipped suite; misleading, no data or
  work lost.
- pri 65: blocks LTVera#551 Step 2 acceptance ("failures block Step 3+"); ordered after #710 which
  breaks the consumer's reconcile.
- appeal 50: neutral.
- effort 80: one helper, 62 one-line call sites, one suite with a vendor witness.
- Recurrence: first report of this class (vendored suite red for a forge-only path); GH-197 (tier
  split) and GH-312 (preserve list) were vendor-manifest issues of a different class.

## Status

active — plan r1 reviewed by agy (`relay-system/2026-09-18/gh710-gh708-plan-qa.md`): r1 sweep corrected (−oracle-guard, +gh4-ungated-clone-warning); r2 (agy, block rejected by the relay validator for a missing `VERDICT:` line — findings taken from its turn log): fallback order confirmed, no more oracle-guard-class false positives, six `validate.sh` suites added; r3 pending.

## Merge evidence

(filled at landing)

## Lessons Learned (For Future Agents)

(filled at landing)
