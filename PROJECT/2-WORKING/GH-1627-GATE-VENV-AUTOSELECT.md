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
| Plan approved by Codex (round 2, `relay-system/2026-11-25/gh1627-plan-qa.md`). Built (`1f2d5738a`) and proven on the real entry points in a disposable clone: rows a-f green, red on base for a, d, e(a) (`TESTS-RESULTS/2026-11-25+GH-1627/README.md`). | Orchestrator final QA, then push through the hook, open the PR (Closes #1627). No LESSONS-LEARNED entry (`NO_ENTRY`: one confounded run per row, no repeated observation). |

## Observed problem (measured at base `2ef6c3191`)

| Claim | Source | Observed |
|---|---|---|
| The probe lives in one place | `validate.sh` GH-732 block (`# GH-732 environment faults BEGIN … END`) | inline loop over `yaml pytest requests mypy` plus `version_info >= (3, 10)` on `python3`; on failure prints `ENVIRONMENT FAULT` with the `PATH=` remedy and `exit 3` |
| The hook never picks an interpreter | `githooks/pre-push` | it runs `python3 utils/py/gate_receipt.py …` (admit `:90-99`, receipt check `:426`) and, on the tier-2 and full routes, `validate.sh --print-mode` then the real `validate.sh` (`:354-359`, `:445-453`). Two routes skip `validate.sh`: the docs route (`:390-395`, runs `utils/pdda/pdda.sh`) and exact-commit receipt reuse (`:421-440`). On a gate failure the hook exits **1** (`:455-472`) with the inner gate's exit status (3 for a toolchain fault) printed in its message. Each `validate.sh` invocation selects independently: its PATH export reaches its children, not the parent hook, so the notice appears once per `validate.sh` invocation (a normal push runs `--print-mode` and the gate: two notices), not once per push |
| `gate_receipt.py` does not need the toolchain | `cd utils/py && /opt/homebrew/bin/python3 -c "import gate_receipt"` (3.14.7) | imports cleanly: the hook's own `python3` calls already work on a toolchain-less interpreter |
| merge-cleanup runs the same probe by calling it | `merge_cleanup.py:1071` `gate_toolchain_fault_reason` runs `bash validate.sh --print-mode`; rc 0 → no fault | it reads validate.sh's answer; it has no copy of the probe |
| `--print-mode` exits after the probe block | `validate.sh:1049` follows the block | a selection made inside the block is visible to `--print-mode`, the hook and merge-cleanup alike |
| No venv-path override exists | `git grep -i "test-venv\|TEST_VENV\|GATE_VENV"` | only the literal default `~/.cache/xyz-forge-test-venv` in `validate.sh`, README and `test/gh251-validate-pytest-skip.sh` |
| `ci-local.sh` does not run the probe | `ci-local.sh:226,325` call `python3 -m json.tool` / `python3 -m pytest` directly | outside this issue's scope ("anything that runs the same probe"); parked |
| Two existing assertions depend on the venv being absent *once the selector exists* | `test/gh251-validate-pytest-skip.sh` cases 2 and 3 put a failing `python3` shim first on PATH and expect exit 3 | base `validate.sh` never reads the venv (it appears only in the fault text), so base gh251 is green with or without the venv. With the selector and the unadjusted suite, a Mac with a healthy venv would run the suites instead of exiting 3 and those cases go red; they must run with `HOME` pointed at an empty dir (an edit to the existing suite, not a new one) |

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

Rows a, d and e(a) are the **rejecting** controls: base fails them and the change must pass. Rows b1, b2, c, e(b/c) and f are **preservation** controls: they must give the same observable result on base and on the change (they are not expected to turn red on base); c additionally rejects an always-prepend candidate.

| ID | Scenario | Base (expected) | Change (expected) |
|---|---|---|---|
| a | failing python3 shim first on PATH + real healthy venv; `validate.sh --print-mode`, then a real tier run of `validate.sh` | `--print-mode` exits 3 with the fault line; no suite starts | exit 0, exactly one `GH-1627` notice line naming the venv python, and suites run on the venv (the interpreter observed inside a suite child is the venv's) |
| b1 | venv missing (`HOME` = empty dir), same failing shim | exit 3, fault line | stdout/stderr and exit byte-identical to base |
| b2 | venv present but failing (`HOME` holds a shim venv whose python3 fails the probe) | exit 3, fault line | byte-identical to base; the fault names the PATH interpreter, not the venv |
| c | healthy python3 on PATH that is a path **distinct from** the venv (real Homebrew python with the four modules, or a copy-shim that execs the venv python under another path), real venv also present | no notice; PATH untouched | no notice; the interpreter observed in a child is the PATH one, not the venv path; output identical to base |
| d | a real `git push` through the installed hook of the disposable clone, to a local bare remote, with a failing python3 first on PATH, valid attempt accounting, and a code path change that routes to the tier-2 or full gate (not docs, no receipt on the commit) | the gate's toolchain fault (inner exit 3, hook exit 1, message `RED (exit 3)`), and the remote ref does not advance | the hook runs `validate.sh` (transcript shows the notice and suite results, no `--no-verify`, no receipt reuse), hook exit 0, `git ls-remote` on the bare remote shows the candidate SHA |
| e | merge-cleanup's `gate_toolchain_fault_reason(clone)` under: (a) failing shim + healthy venv; (b1) venv missing; (b2) venv failing; (c) healthy distinct PATH python | (a) the fault line | (a) `''`; (b1)/(b2) the same fault line as base; (c) `''` |
| f | `gh251-validate-pytest-skip.sh`, the GH-732 suites and the GH-1437-related checks, run (1) on base, (2) on the change with the gh251 edit, with the real venv present | green | green. (The selector with the *unadjusted* gh251 on a machine with the venv is also run once to show why the `HOME=` isolation is needed; no recorded result is claimed before that run.) |

A smoke (GH-1088) is (a) as the main path and (b1)/(c) as the adjacent path. The docs route and receipt-reuse route are not selector paths: they do not invoke `validate.sh`, so they are unchanged by this work and stated as such (d forces a code-path diff so the gate is reached).

## Parked (dropped, not in this PR)

- `ci-local.sh` calls `python3 -m pytest` / `json.tool` directly with no probe or selection; filed or parked separately.
