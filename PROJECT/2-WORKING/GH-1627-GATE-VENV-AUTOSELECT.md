---
title: "pre-push gate: select the prepared test venv automatically when PATH's python3 fails the probe"
status: In Progress
created: 2026-11-25
updated: 2026-11-25
owner: Noel Saw
gh_issue: 1627
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1627
doc_type: bugfix
reported_from: XYZ-forge
harness_commit: 2ef6c3191
non_goals:
  - editing the system or Homebrew Python, a shell profile, or creating the venv automatically
  - a new venv path knob (the repo has no override today; only the documented default path is used)
  - replacing a python3 on PATH that passes the probe
  - changing merge-cleanup's probe, accounting, or the pre-push hook's routing
  - any new test suite or registry entry (AGENTS.md No new tests, GH-831)
related:
  - 1437
  - 1606
  - 732
goal: "When PATH's python3 fails the gate's toolchain probe and ~/.cache/xyz-forge-test-venv passes it, validate.sh uses the venv for the run and says so in one line; every other case behaves exactly as today."
---

# GH-1627 — gate selects the prepared test venv instead of refusing

## Status

| What was just completed | What's next |
|---|---|
| Recon and plan written (this document). | Codex plan QA (cap 4 rounds), then build, then run the real entry points in a disposable clone. |

## Observed problem (measured at base `2ef6c3191`)

| Claim | Source | Observed |
|---|---|---|
| The probe lives in one place | `validate.sh` GH-732 block (`# GH-732 environment faults BEGIN … END`) | inline loop over `yaml pytest requests mypy` plus `version_info >= (3, 10)` on `python3`; on failure prints `ENVIRONMENT FAULT` with the `PATH=` remedy and `exit 3` |
| The hook never picks an interpreter | `githooks/pre-push` | it runs `python3 utils/py/gate_receipt.py …` (admit, receipt check) and calls `validate.sh`, `validate.sh --print-mode`; all gate work is inside `validate.sh` |
| `gate_receipt.py` does not need the toolchain | `cd utils/py && /opt/homebrew/bin/python3 -c "import gate_receipt"` (3.14.7) | imports cleanly: the hook's own `python3` calls already work on a toolchain-less interpreter |
| merge-cleanup runs the same probe by calling it | `merge_cleanup.py:1071` `gate_toolchain_fault_reason` runs `bash validate.sh --print-mode`; rc 0 → no fault | it reads validate.sh's answer; it has no copy of the probe |
| `--print-mode` exits after the probe block | `validate.sh:1049` follows the block | a selection made inside the block is visible to `--print-mode`, the hook and merge-cleanup alike |
| No venv-path override exists | `git grep -i "test-venv\|TEST_VENV\|GATE_VENV"` | only the literal default `~/.cache/xyz-forge-test-venv` in `validate.sh`, README and `test/gh251-validate-pytest-skip.sh` |
| `ci-local.sh` does not run the probe | `ci-local.sh:226,325` call `python3 -m json.tool` / `python3 -m pytest` directly | outside this issue's scope ("anything that runs the same probe"); parked |
| Two existing assertions depend on the venv being absent | `test/gh251-validate-pytest-skip.sh` cases 2 and 3 put a failing `python3` shim first on PATH and expect exit 3 | on a Mac with a healthy venv, selection makes them go red; they must run with `HOME` pointed at an empty dir (an edit to the existing suite, not a new one) |

## Requirements (issue #1627, Acceptance)

1. PATH `python3` fails probe and venv passes: gate (and a real `git push`) runs on the venv and prints one line naming it.
2. Venv missing or failing: output and exit status exactly as today (exit 3, same fault line and remedy).
3. Healthy PATH `python3`: nothing changes; the venv is never substituted.
4. merge-cleanup's pre-flight probe agrees with the gate in all three cases.
5. Existing GH-732 / GH-1437 / gh251 suites pass; evidence under `TESTS-RESULTS/` (no new suites).

## Plan (smallest bet)

Extends only the existing GH-732 block in `validate.sh`.

1. **Make the existing probe a function, once.** Move the version read, the module loop and the `>= (3, 10)` check into `_xyz_python_probe <interpreter>`, which sets `_python_version` and `_python_missing` and returns 0 only when the interpreter is usable. The module list and floor are not copied anywhere else.
2. **Select the venv only on failure.**
   ```
   if ! _xyz_python_probe python3; then
     venv_bin="$HOME/.cache/xyz-forge-test-venv/bin"
     if [ -x "$venv_bin/python3" ] && _xyz_python_probe "$venv_bin/python3"; then
       PATH="$venv_bin:$PATH"; export PATH
       echo "validate.sh: python3 on PATH failed the toolchain probe; using <venv python> (<ver>) for this run (GH-1627)"
     fi
     _xyz_python_probe python3 || { <existing ENVIRONMENT FAULT line, byte-identical>; exit 3; }
   fi
   ```
   The second `_xyz_python_probe python3` recomputes the PATH interpreter's version/missing list, so a missing or failing venv leaves the fault line, remedy and exit 3 byte-identical to today. A healthy PATH `python3` never enters the branch.
3. **Everything downstream inherits it.** validate.sh's own `gate_receipt.py admit`, every suite worker, `--print-mode` (so merge-cleanup's probe and the hook's `--print-mode` report), and the pre-push hook's `validate.sh` calls all see the venv-first PATH. The hook's earlier `python3 gate_receipt.py` calls need no change (stdlib-only; imports on 3.14 as measured). **No change to `githooks/pre-push` or `merge_cleanup.py`**: merge-cleanup reads validate.sh's exit code, so it agrees by construction; this is proven by running it, not asserted.
4. **Docs.** README gate-toolchain paragraph (one sentence: the gate uses the prepared venv automatically when PATH's python3 fails the probe; otherwise the `PATH=` remedy), and the merge-cleanup SKILL.md GH-1606 sentence (one clause: this defers only when the venv cannot pass either).
5. **Existing suite.** `test/gh251-validate-pytest-skip.sh`: run its two failing-interpreter cases with `HOME="$WORK/nohome"` so they keep testing "no usable fallback" on machines that have the venv. No new assertions.

## Alternatives considered

| # | Alternative | Verdict |
|---|---|---|
| 1 | One selection step in the GH-732 block, reusing its probe (chosen) | One place, inherited by hook, `--print-mode`, merge-cleanup |
| 2 | Select in `githooks/pre-push` | Rejected: validate.sh is also run by hand and by ci/marathon; the hook is one of several callers |
| 3 | Change merge-cleanup to inject the venv | Rejected: it already reads validate.sh's answer; injecting there is a second selector |
| 4 | New env knob for the venv path | Rejected: none exists; YAGNI |
| 5 | Repoint the Mac-wide `python3` | Rejected by the operator (issue text) |

## Preflight Bet Check

- **Outcome sought:** a push or landing on a Mac whose default `python3` lacks the toolchain no longer stops for a hand-typed PATH prefix when the canonical venv is ready.
- **Smallest viable bet:** one function and one fallback branch in the existing block, two doc sentences, one `HOME=` isolation in the existing gh251 suite. Not built: path override, venv creation, hook change, merge-cleanup change, new tests.
- **Rollback / containment:** revert one validate.sh hunk. The branch only runs when the PATH interpreter already fails (today's exit 3), so the worst case is a venv run in a place that used to refuse.
- **Interpreter-substitution risk (accepted):** the gate evidence now comes from the venv (3.12) instead of the PATH interpreter. Mitigation: only after the PATH interpreter fails the probe and the venv passes the identical probe; the notice names the interpreter and its version.

## Rating (read back from the ledger after pickup)

pri 60 / sev 45 / appeal 50 (neutral, no operator preference) / effort 75, as proposed in the issue. Recurrence: the 2026-11-26 landing of PR #1622 stopped on this; #1437 and #1606 are the same class (two earlier incidents in 14 days). Uncertainty: none material.

## Acceptance and manual checks (no new tests, GH-831)

Run on a disposable full clone, base vs change, under `TESTS-RESULTS/2026-11-25+GH-1627/` with `provenance.jsonl`. "Failing python3" is a PATH-first shim that fails the probe (the same technique the gh251 suite uses); the healthy venv is the real `~/.cache/xyz-forge-test-venv`.

| ID | Scenario | Unchanged candidate is rejected because | Expected (change) |
|---|---|---|---|
| a | failing python3 first on PATH + real healthy venv; `validate.sh --print-mode`, then a real gate tier run | base exits 3 before any suite | exit 0, exactly one `GH-1627` notice line naming the venv python; suites run on the venv (the run's own python is the venv's) |
| b1 | venv missing (`HOME` = empty dir) | n/a (must equal base) | stdout/stderr and exit identical to base (exit 3, same fault text) |
| b2 | venv present but failing (`HOME` with a shim venv whose python3 fails the probe) | n/a (must equal base) | identical to base; exit 3, fault names the PATH interpreter, not the venv |
| c | healthy python3 on PATH, real venv also present | a candidate that always prepends the venv | no notice line, PATH untouched, output identical to base |
| d | a real `git push` through the installed hook, with a failing python3 first on PATH, to a local bare remote | base refuses (exit 3) | the hook reaches the gate, runs it on the venv, push lands |
| e | merge-cleanup's `gate_toolchain_fault_reason` on the clone under (a) and (b1/b2) | base returns the fault line for (a) | `''` for (a); fault line for (b1/b2), same as base |
| f | `gh251-validate-pytest-skip.sh`, GH-732 suites, GH-1437-related checks | any regression | green; on base the unmodified gh251 also green only without the venv (recorded) |

A smoke (GH-1088) is (a) as the main path and (b1)/(c) as the adjacent path.

## Parked (dropped, not in this PR)

- `ci-local.sh` calls `python3 -m pytest` / `json.tool` directly with no probe or selection; filed or parked separately.
