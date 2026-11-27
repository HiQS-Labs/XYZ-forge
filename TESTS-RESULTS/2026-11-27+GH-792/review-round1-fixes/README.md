# GH-792: dispositions for preparation review round 1 (Codex)

Thread: `relay-system/2026-11-27/gh1626-gh792-prep-qa.md`.

- **F2 (reverse containment): fixed.** The probe adds case 1b: a checkout already at `<base2>/clone` with the source nested at `<base2>/clone/nested`. That call must refuse with zero recorded `makedirs`/`rmtree`/`subprocess` calls, leaving both checkouts intact. The goal and remediation criteria now name all three overlap shapes. Results:
  - `base.txt`: exit 1. The source is deleted in the equal-path case.
  - `symmetric-fix.txt`: exit 0, using `simulated-fix.patch`.
  - `forward-only-early-check.txt`: exit 1. This variant moves only the old predicate before the mutations, and the reverse case now catches it.
- **F3 (ambient Git settings): fixed.** `isolate_git()` drops `GIT_*`, ignores global and system config and points `core.hooksPath` at an empty fixture directory. It covers the whole process, including the product's `git clone`. The setup used `GIT_DIR=<scratch>/outside.git` plus a `GIT_CONFIG_GLOBAL` whose hooks write a scratch sentinel:
  - `hostile-env-fixed.txt`: exit 0 on the fixed tree. The sentinel stayed absent and `outside.git` was unchanged.
  - `hostile-env-base.txt`: exit 1 on base, sentinel absent.
  - Negative control `hostile-env-old-probe.txt`: the pre-isolation probe under the same global hook ran it twice. The sentinel was written.
- **F4 (builder could rewrite its own proof): fixed.** The artifacts are now the product file plus `delivery.md`, listed in `artifacts_new` with a `path_absent` probe. The inferred `test/gh-gen4-phase5-campaign.sh` is documented, and editing it is a non-goal.
- **F5 (history wording / ref): fixed**, the same way as for #1626.
