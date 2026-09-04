---
Goal: QA the GH-67 pytest rootdir hotfix for rebalanceOS before it is pushed
Date: 2026-09-04
NEXT: Reviewer
STATUS: Approved
---

# Context

Adjudicate a small hotfix to **a different repository** — `HiQS-Labs/rebalanceOS`, a local-first
workday OS in Python. The change is on branch `hotfix/gh67-pytest-rootdir-config`, cut from
`development` at `6ceb02a`. It is not yet pushed. This review is the gate before push.

The complete diff and commit message are seeded read-only at `.relay-artifacts/gh67-hotfix.md`.
**Read that file first, in full.** It is the whole change — 4 files, 90 insertions.

## What the change claims to do

rebalanceOS had **no pytest configuration at all** — no `[tool.pytest.ini_options]`, no
`pytest.ini`, no `setup.cfg` section. The hotfix adds that block to `pyproject.toml`, plus PDDA
doc, ROADMAP and RELEASES.md updates.

The originating issue, GH-67, reported that 15 tests failed when pytest ran from outside the repo
root, and argued the real defect was that the suite's result depended on an undeclared input.

## What the author verified before writing code (claims to check)

In a fresh full clone with its own virtualenv, at `6ceb02a`, **before** any edit:

- full suite from the repo root: 10 failed, 2146 passed, 20 skipped, 10 xfailed
- full suite from `/tmp`: 10 failed, 2146 passed, 20 skipped, 10 xfailed
- the two FAILED lists are byte-identical
- none of the 15 tests GH-67 named are among the failures

From this the author concluded GH-67's symptom was **already fixed** by an earlier change
(2026-08-27, pinning `cwd` in `tests/test_uninstall_rebalance.py::_run()`), and that this hotfix
is therefore *the declared guard*, not the fix.

After the change: identical results from both directories, unchanged against the pre-change
baseline, `rootdir` reads back as the repo when invoked from `/tmp`, ruff clean, ruff format clean,
mypy clean on 111 files, `utils/3-eyes/tests` 208 passed, PDDA error counts identical to the
pristine tree.

# Questions

Answer each one directly. Cite `file:line` from the seeded diff where you disagree.

1. **Is the central claim sound?** The author says that *declaring* the `[tool.pytest.ini_options]`
   section is the substance, because without it `pyproject.toml` is not a pytest inifile and
   `rootdir` is inferred per-invocation. Is that an accurate description of how pytest resolves
   `rootdir` and `configfile`? If it is wrong or overstated, say so precisely.

2. **Does `testpaths = ["tests"]` risk changing what CI runs?** The author asserts it applies only
   when pytest is given no path arguments, so CI's explicit invocations for the root suite, HiQS,
   and 3-eyes are unaffected. Is that correct? Is there any invocation shape where this silently
   narrows or widens the collected set?

3. **Are `--strict-markers` and `--strict-config` safe to turn on here?** The author claims
   `requires_metal` is the only custom marker and that `tests/conftest.py:92` registers it via
   `addinivalue_line`. Consider ordering: does `pytest_configure` registration reliably happen
   before marker strictness is enforced during collection? Consider also the `HiQS/tests` and
   `utils/3-eyes/tests` suites, which now inherit these `addopts` because the root `pyproject.toml`
   became the `configfile`. Could either suite break?

4. **Is omitting `pythonpath` the right call?** The author deliberately did not set it, on the
   grounds that the root `conftest.py` already prepends this checkout's `src/` (GH-170) and a
   second mechanism is a second place to drift. Is that reasoning sound, or does leaving
   `pythonpath` unset leave a real gap the conftest does not cover?

5. **Is the evidence actually sufficient to claim GH-67 is already closed?** The author ran the
   suite from exactly two directories, the repo root and `/tmp`. Is a two-point comparison enough
   to support "the result does not depend on the invoking directory"? What would falsify it?

6. **Is anything mis-scoped?** The author reverted a change that would have made the `dev` extra
   pull `rebalance-os[server]` — it fixed a real reproduction (13 `ModuleNotFoundError: fastapi`
   collection errors from `pip install -e ".[dev]"`) but re-opened a decision already closed by
   pointing the README at `.[dev,server]`. Was reverting correct, or should it have shipped?

7. **Is the documentation honest?** The PDDA doc, ROADMAP entry and RELEASES.md line all now say
   GH-67 was fixed on 2026-08-27 and that this change is the guard. Does the diff's prose overclaim
   anywhere, or credit this change with something it did not do?

Flag anything wrong, missing, incorrectly scoped, or over/under-engineered. If the change is sound,
say so plainly and set `STATUS: Approved`. This is a **review-only** turn — do not edit any file
other than this relay file.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (agy)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Review Findings

1. **Is the central claim sound?**
   Yes. Pytest relies on the `[tool.pytest.ini_options]` table to recognize `pyproject.toml` as a configuration file. Without it, pytest ignores the file and infers `rootdir` from the test paths or working directory. Declaring the section explicitly pins the `rootdir`.

2. **Does `testpaths = ["tests"]` risk changing what CI runs?**
   No. The `testpaths` option provides a default list of directories to search *only* when no specific paths are given on the command line. CI's explicit invocations (e.g., `pytest HiQS/tests`) override `testpaths`, leaving them unaffected.

3. **Are `--strict-markers` and `--strict-config` safe to turn on here?**
   Yes. `pytest_configure` executes early in the initialization phase before test collection and marker strictness checks. The author also successfully verified the other suites (`HiQS/tests` and `utils/3-eyes/tests`), confirming they do not suffer from unregistered markers.

4. **Is omitting `pythonpath` the right call?**
   Yes. While a minor gap exists if a sub-suite is invoked directly from its directory without traversing the root `tests/conftest.py`, the author's reasoning to avoid duplicate path-manipulation mechanisms (DRY principle) is sound, especially since the existing mechanism works.

5. **Is the evidence actually sufficient to claim GH-67 is already closed?**
   Yes. The two-point comparison (repo root vs. `/tmp`) is the standard diagnostic to prove that a test suite does not implicitly depend on being run from its own repository root. This sufficiently falsifies the specific symptom reported in GH-67.

6. **Is anything mis-scoped?**
   Reverting the `[dev]` extra change was the correct call. Including a dependency fix in a hotfix branch scoped to a pytest configuration issue would be scope creep.

7. **Is the documentation honest?**
   Yes, the documentation is precise and honest. It explicitly attributes the actual fix to the August 27th `_run()` change and frames the current configuration change solely as a declarative guard to prevent regressions.

The change is sound.
