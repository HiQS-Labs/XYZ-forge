---
title: "L4 brief — #732 B.1/B.2: a present-but-broken toolchain is a named environment fault (umbrella #749)"
status: "Brief (input to the GH-749 marathon — not a tracked plan)"
created: 2026-09-22
updated: 2026-09-22
owner: Noel Saw
goal: >
  When the ordinary validator meets a present-but-broken php or an interpreter missing yaml, it says so
  by name instead of turning a suite red; --qualify keeps refusing with exit 6 and no receipt.
roadmap_exempt: true
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/749
  - https://github.com/HiQS-Labs/XYZ-forge/issues/732
  - https://github.com/HiQS-Labs/XYZ-forge/issues/251
  - https://github.com/HiQS-Labs/XYZ-forge/issues/268
---

# L4 — #732 B.1/B.2: environment faults get a name

## Status

| What was just completed | What's next |
|---|---|
| Brief authored at marathon plan time (2026-09-22) | Phase p4 fires after p3 is approved (last in the chain; p3 also edits `validate.sh`) |

Umbrella: #749 · Issue: #732 items B.1 and B.2 · Phase p4 · `depends_on: p3`

## Ground truth (verified at `origin/development` a0776330)

- `validate.sh:1409-1413`: an **absent** `pytest` is a named `SKIPPED: python:test_python_layer.py (pytest not importable …)` — GH-251; `test/gh251-validate-pytest-skip.sh` pins it (`:16-17` branches on `python3 -c "import pytest"`).
- `test/gh268-relay-cue-and-target-checks.sh:97`: the `php` assertions run only `if command -v php`; an **absent** php is skipped, a **present but broken** one (the 2026-09-17 case: `php@8.3` on PATH with a missing `libaspell` dylib — fails `-v` and `-l`) reads as `"clean PHP did not pass (exit N)"` — a suite failure with no environment name. The gate is `relay-automation/target-checks.sh` (`php -l`, `:12`).
- `test/ci-workflow.sh:137-142`: the `yaml` consumer — it probes `import yaml` and skips when absent; a `python3` that is the wrong interpreter (Homebrew 3.14 without PyYAML while the venv has it) is reported as a plain skip/fail with no name. This is the "interpreter missing yaml" subcase the issue called unverified — it is verified here; its red control is planted by putting a `python3` shim on PATH whose `-c "import yaml"` fails.
- `utils/py/wave_reconcile.py:580-600` (`qualify_landings`): `--qualify` runs `python3 -c "import pytest"` and **dies with exit 6 and no receipt** when it fails. This is correct and is the boundary this lane must not move.

## Deliverables (the lane's write-set — nothing else)

1. **`validate.sh`** — extend the existing skip/diagnostic path (the same place GH-251 prints its named SKIPPED line; no new precheck facility, no unconditional top-level dependency gate) so that:
   - a `php` on PATH that fails both `php -v` and `php -l` on an empty file is announced once, before the pool, as `ENVIRONMENT FAULT: php present but unusable (<first stderr line>) — suites needing php will report this fault, not a failure`; and
   - a `python3` that cannot `import yaml` is announced the same way, naming the interpreter path (`command -v python3`) and the venv hint from `gate-toolchain` (`~/.cache/xyz-forge-test-venv/bin` first on PATH).
   Export the fault(s) in one env var the suites can read (e.g. `XYZ_ENV_FAULTS="php,yaml"`), and print them again in the summary next to `QUARANTINED` (`:1520-1522`) so a red run names its real cause. A run with a named fault is **not promotion evidence** (say so on the same line, like the GH-379 quarantine text). Exit code semantics unchanged. Tag `GH-732`.
2. **`test/gh268-relay-cue-and-target-checks.sh`** — when `XYZ_ENV_FAULTS` names `php`, the php block reports `SKIP: environment fault (php present but unusable)` and does not run the `-l` assertions; when php is healthy the existing assertions run unchanged (syntax error still fails the gate, clean file still passes). Add the **red control** as a self-contained case: a temp dir with a `php` stub that exits non-zero for `-v` and `-l`, prepended to PATH for a sub-invocation of the relevant assertions, must produce the named fault line and no `"clean PHP did not pass"` failure.
3. **`test/gh251-validate-pytest-skip.sh`** — add the `yaml` sibling: a temp `python3` shim on PATH that fails `-c "import yaml"` (delegating everything else to the real interpreter) makes `validate.sh --print-mode`/the pre-pool announcement print the named fault; the existing absent-pytest assertions stay as they are.
4. **Boundary control (evidence, not code)**: in a disposable clone with a `python3` shim that fails `import pytest`, `python3 utils/py/wave_reconcile.py --pr <any merged PR> --catch-up --gate --qualify --dry-run` (or the narrowest invocation that reaches `qualify_landings`) still exits non-zero with **no** qualification receipt written. Record the command and exit code under the evidence dir. If a change to `validate.sh` would make `--qualify` pass without pytest coverage, the change is wrong.

**B.2 acceptance run** (the lane's closing evidence, not a code change): a fresh full clone of `development` on the documented PATH → `bash validate.sh` GREEN with **zero** `vp_rerun_alone` re-runs; paste the hook-style `GREEN in Ns` line and the telemetry path. Plant, one at a time, the four faults the issue names (broken php; missing yaml; a `skills/agent2agent/__pycache__/` dir; a `PROJECT/1-INBOX/GH-<open>-*.md` doc with no ledger row) and record what the gate now says for each — the first two must be the new named lines; for the other two, record the current behaviour verbatim (they belong to #730 and #667 — **do not fix them here**, just witness them).

## Rules

**Retry note (2026-09-22):** the first attempt landed this lane (`10836fc9`, Approved) but its gate went red on `security-scan.sh`: the gh268 red control ran the validator's fault block through `eval "$(sed -n … validate.sh)"` (`eval-unsanitized`, a real finding — never baseline it). The corrected shape is already in the tree: prove the diagnostic with `bash validate.sh --print-mode` on the shimmed PATH (as the gh251 half does) and prove the suite's skip path by exporting `XYZ_ENV_FAULTS=php` — the contract validate.sh exports to suites. If the lane is present, verify it against the acceptance list and hand off; do not reintroduce `eval`.

Shortest diff (`/ponytail`); widen B.1's mechanism only; no new script or library. Never weaken `--qualify` (`exit 6`, no receipt) or the GH-528 solo re-run verdict. Suites stay registered as they are (no `TESTS` array change unless a new suite is added, which this lane should not need). Evidence under `TESTS-RESULTS/2026-09-22+GH-732/l4/` with red/green/boundary outputs and `provenance.jsonl`. `bash validate.sh` green is the phase gate.

## Acceptance / Guard

- Red: broken-php stub on PATH → `ENVIRONMENT FAULT: php …` line, and `gh268` reports a named skip, not `clean PHP did not pass`.
- Green: healthy php → `gh268` unchanged (syntax error fails, clean passes).
- Red: yaml-less `python3` shim → `ENVIRONMENT FAULT: python3 … cannot import yaml` line; `gh251` asserts it.
- Boundary: pytest-less shim → `--qualify` path exits non-zero with no receipt.
- B.2: fresh-clone full gate GREEN, zero re-runs, line recorded; four planted faults witnessed with their current output.
