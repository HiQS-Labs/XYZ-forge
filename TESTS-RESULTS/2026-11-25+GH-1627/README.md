# GH-1627 evidence: gate selects the prepared test venv

Manual controls only (no new suite, GH-831). Driver: `run_controls.sh` (not registered anywhere).
All runs happened in ONE disposable full clone (`XYZ-forge-gh1627-venv-autoselect-2026-11-25-gate`, origin = canonical,
hooks installed and `--check`ed, HEAD/`core.bare`/`user.email` verified unchanged after the runs).

- base = `2ef6c3191` (`origin/development`), candidate = `06eac86f5` (`validate.sh` identical to the final change)
- "failing python3" = the **real** Homebrew `python3` 3.14.7 (no `mypy`) first on PATH, the reported incident; no shim.
- venv = the real `~/.cache/xyz-forge-test-venv` (Python 3.12.13, all four modules).
- provenance: `provenance.jsonl` (one line per run: id, rc, output path, output sha256, checkout SHA, UTC time);
  raw outputs under `raw/`; verdicts in `summary-abce.txt` (rows a, b, c, e), `summary-fd-run1.txt` (rows f, d, first run),
  `summary.txt` (row f rerun with the corrected pass predicate, plus a recheck line for gh436).

## Red/green table

| Row | Scenario | Base `2ef6c3191` | Candidate | Verdict |
|---|---|---|---|---|
| a | failing python3 first + real venv, `validate.sh --print-mode` | exit 3, `ENVIRONMENT FAULT: python3 (/opt/homebrew/bin/python3) version 3.14.7; missing modules: mypy` | exit 0, exactly one `GH-1627` notice naming `~/.cache/xyz-forge-test-venv/bin/python3 (version 3.12.13)` | red on base, green |
| a | same, tier-2 run (`--paths-file`, skills-army-hq) | exit 3, no pytest layer | exit 0, one notice, `Running python3 -m pytest`, `+ python:test_python_layer.py`, pytest header reports Python 3.12 | red on base, green |
| b1 | venv missing (`HOME` = empty dir) | exit 3, fault line | stdout+stderr byte-identical to base, exit 3 | preserved |
| b2 | venv present but failing | exit 3 | byte-identical to base; fault names 3.14, not the venv | preserved |
| c | healthy python3 at a path distinct from the venv, venv also present | exit 0, no notice | byte-identical; no notice; the PATH python3 answered the calls | preserved (venv not substituted) |
| d | real `git push` through the installed hook to a local bare remote, failing python3 first | hook `full validation RED (exit 3) after 1s — push REFUSED`, ref not advanced (hook exit 1) | notice, full gate `passed: 408 / 408`, `full gate GREEN in 1165s — pushing`, push exit 0, `git ls-remote` shows `06eac86f5` | red on base, green |
| e | merge-cleanup `gate_toolchain_fault_reason` under (a) | returns the `ENVIRONMENT FAULT` line | returns `''` (landing not deferred) | red on base, green |
| e | same under (b1), (b2) / (c) | fault line / `''` | same as base | preserved |
| f | existing suites on the change: gh251, gh732-l3, gh268, gh436 (Ran 227, OK), gh645, gh674, `pdda.sh run` | gh251 and gh732-l3 green on base | all green | no regression |
| f | selector + UNADJUSTED gh251 with the venv present | n/a | gh251's two refusal cases FAIL | shows the `HOME=` isolation edit is required |

## Notes

- One notice per `validate.sh` invocation; a normal push runs `--print-mode` and the gate, so the push transcript shows it twice.
- Row f first run: the driver's crude `FAIL` grep marked gh268 and gh436 red against green output (`35 pass, 0 fail`; `Ran 227 tests ... OK`).
  The predicate was tightened and rerun; gh436 was re-evaluated against the saved output (`summary.txt` last line).
- Not covered (parked): `ci-local.sh` calls `python3 -m pytest` / `json.tool` directly and has no probe or selection.
