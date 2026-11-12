---
gh_issue: 1437
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1437
title: Fail fast for unsuitable gate Python
status: Planning
created: 2026-11-12
updated: 2026-11-12
owner: Codex
goal: Fix the reported contract and environment failure using existing validation owners.
---

# GH-1437 — Fail fast for unsuitable gate Python

## Status

| What was just completed | What's next |
|---|---|
| Issue and current source inspected. | Shared plan QA, implementation, focused and full verification. |

Shared plan: [GH-1436](GH-1436-CONTRACT-ENVIRONMENT.md).

Reported from `LTVera-Pandas`, while the #1426/#1427/#1428 fixes were landing on 2026-11-12. Related: #732 (GH-732 named environment faults), #1351 (introduced the first 3.10-only syntax).

## Symptom

On a Mac where `python3` resolves to Apple's `/usr/bin/python3` (3.9.6), the full pre-push gate goes red on clean branches. All three task sessions (#1426, #1427, #1428) hit it: 9, 4 and several failures. None of the failing files were in their diffs. Each session then built its **own** throwaway venv (3.12 or 3.13) and re-pushed, so the three "green" gates ran on different interpreters. One session needed 3 attempts to discover the missing packages one at a time.

The machine already had the canonical gate venv the whole time: `~/.cache/xyz-forge-test-venv` (Python 3.13.15, with `yaml`, `pytest` and `requests` all importable). Nothing told the sessions to use it until after the suites had already failed.

## Observed

| Claim | Command | Observed |
|---|---|---|
| 3.10-only code on development | `git grep -n "str \| None" origin/development -- utils/py/_marathon_plan.py` | lines 121-122, no `from __future__ import annotations` (since PR #1351, 2026-11-07) |
| It fails at import on 3.9 | `cd utils/py && /usr/bin/python3 -c "import _marathon_plan"` | `TypeError: unsupported operand type(s) for \|: 'type' and 'NoneType'` |
| Canonical venv exists and is complete | `~/.cache/xyz-forge-test-venv/bin/python3 -c "import yaml, pytest, requests"` | `ok`, Python 3.13.15 |
| Gate only probes `yaml` | `validate.sh:1033-1036` (GH-732 block) | checks `import yaml` only; no Python version floor, no `pytest`/`requests` probe |
| The fault is advisory only | same block | prints `ENVIRONMENT FAULT … put ~/.cache/xyz-forge-test-venv/bin first on PATH`, then runs every suite anyway and reports their failures as a red gate |
| Hook doesn't choose the interpreter | `githooks/pre-push`, `.git/hooks/pre-push` stub | uses whatever `python3` is first on PATH |
| No declared floor | `git grep "3\.10\|version_info" origin/development -- validate.sh githooks/ AGENTS.md README.md` | no hits |

Frequency: every full gate run on a stock macOS shell (deterministic).

## Root cause

Root cause: the repo's code now needs Python ≥3.10, but the gate neither declares that floor nor selects the gate-toolchain venv it already names. Its GH-732 fault probe checks only `yaml`. So an unsuitable interpreter produces a page of suite failures that look like real regressions, instead of one environment-fault line. Fix site: the GH-732 environment-fault block in `validate.sh` (and, optionally, PATH selection in `githooks/pre-push`). Why not change `_marathon_plan.py` back to 3.9 syntax: 3.9 is EOL, and the gate already has a named toolchain. The defect is that the gate doesn't use or enforce it.

## Acceptance

- [ ] The full gate, run with a `python3` older than 3.10 or one missing `pytest`/`requests`/`yaml`, stops **before running suites**. It prints one `ENVIRONMENT FAULT` line naming the interpreter, its version and the missing modules, plus the `~/.cache/xyz-forge-test-venv/bin` remedy, and exits non-zero with a status distinct from a suite failure. Red control: today, `/usr/bin/python3` first on PATH runs all suites and reports N unrelated failures.
- [ ] When `~/.cache/xyz-forge-test-venv/bin/python3` exists and passes the probe, the pre-push hook either uses it automatically (and says so in one line) or the fault message tells the operator the exact `PATH=` prefix to re-run with. Pick one and document it.
- [ ] The Python floor (≥3.10) is stated once, where the gate-toolchain venv is documented.
- [ ] A healthy interpreter gives the same gate result as today (no regression); `test/gh251-validate-pytest-skip.sh` and the GH-732 suites still pass. Evidence under `TESTS-RESULTS/` (no new suites, GH-831).

## Preflight Contract

```json
{
  "target": {"repo": ".", "ref": "development"},
  "gate": "bash test/gh251-validate-pytest-skip.sh",
  "fix_probes": [
    {"type": "grep", "path": "validate.sh", "pattern": "cannot import yaml"}
  ],
  "artifacts": ["validate.sh", "githooks/pre-push"]
}
```

## PRS proposal

pri 55: every agent session on a stock Mac burns one or more full-gate runs (about 9 minutes each) and then improvises its own interpreter.
sev 40: no wrong code lands, but red gates from the environment look like regressions, and gate evidence is not comparable across sessions.
appeal 55: turns a confusing failure into a one-line, self-explaining fault, using machinery GH-732 already built.
effort 75: one probe block in `validate.sh`, plus an optional PATH line in the hook.

## Non-goals

- Making the codebase 3.9-compatible again.
- Installing or upgrading the system Python, or creating the venv automatically.

