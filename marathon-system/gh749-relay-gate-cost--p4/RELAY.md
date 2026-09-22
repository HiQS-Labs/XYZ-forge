# Marathon Phase p4
STATUS: Open
NEXT: agy (Reviewer)

<!-- marathon-drive: task=MARATHON-P4-TURN builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

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

Shortest diff (`/ponytail`); widen B.1's mechanism only; no new script or library. Never weaken `--qualify` (`exit 6`, no receipt) or the GH-528 solo re-run verdict. Suites stay registered as they are (no `TESTS` array change unless a new suite is added, which this lane should not need). Evidence under `TESTS-RESULTS/2026-09-22+GH-732/l4/` with red/green/boundary outputs and `provenance.jsonl`. `bash validate.sh` green is the phase gate.

## Acceptance / Guard

- Red: broken-php stub on PATH → `ENVIRONMENT FAULT: php …` line, and `gh268` reports a named skip, not `clean PHP did not pass`.
- Green: healthy php → `gh268` unchanged (syntax error fails, clean passes).
- Red: yaml-less `python3` shim → `ENVIRONMENT FAULT: python3 … cannot import yaml` line; `gh251` asserts it.
- Boundary: pytest-less shim → `--qualify` path exits non-zero with no receipt.
- B.2: fresh-clone full gate GREEN, zero re-runs, line recorded; four planted faults witnessed with their current output.


---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Implement the brief by creating/editing the artifact file(s): validate.sh, test/gh251-validate-pytest-skip.sh, test/gh268-relay-cue-and-target-checks.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/marathon-clones/marathon-gh-749-relay-gate-cost/bin/tick
   - /Users/noelsaw/marathon-clones/marathon-gh-749-relay-gate-cost/bin/tick claim MARATHON-P4-TURN --agent codex --paths "marathon-system/gh749-relay-gate-cost--p4/RELAY.md,validate.sh, test/gh251-validate-pytest-skip.sh, test/gh268-relay-cue-and-target-checks.sh"
   - /Users/noelsaw/marathon-clones/marathon-gh-749-relay-gate-cost/bin/tick ping MARATHON-P4-TURN --agent codex
   - /Users/noelsaw/marathon-clones/marathon-gh-749-relay-gate-cost/bin/tick release MARATHON-P4-TURN --agent codex --to agy
4. Edit ONLY these paths: marathon-system/gh749-relay-gate-cost--p4/RELAY.md and validate.sh, test/gh251-validate-pytest-skip.sh, test/gh268-relay-cue-and-target-checks.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to agy — agy, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: agy (Reviewer)`

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: validate.sh, test/gh251-validate-pytest-skip.sh, test/gh268-relay-cue-and-target-checks.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: codex (Builder)`, then: /Users/noelsaw/marathon-clones/marathon-gh-749-relay-gate-cost/bin/tick release MARATHON-P4-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/marathon-clones/marathon-gh-749-relay-gate-cost/bin/tick done MARATHON-P4-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/marathon-clones/marathon-gh-749-relay-gate-cost/bin/tick
   Edit ONLY marathon-system/gh749-relay-gate-cost--p4/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
4b. TO VERIFY A FINDING, WRITE PROBE FILES OUTSIDE THE REPO — under $TMPDIR, never inside the
   working tree. Creating even one scratch file in the repo is an off-lane write: containment
   reverts it and FAILS YOUR WHOLE TURN, discarding the review you just did (GH-441). Observed
   2026-08-08: a reviewer found a real latent crash, wrote two probe files in-tree to demonstrate
   it, and lost the turn for doing so — the finding survived only because RELAY.md happens to be
   on your allowlist. `cp` what you need to "$TMPDIR/probe.$$/" and work there instead. Verifying
   is wanted; verifying in-tree is what costs you the turn.
4c. A finding that asks for a behaviour change is a generalization unless you can paste the concrete
   input — a row, a value, a `file:line` — that fails under the current code (GH-681). Every
   `[Blocker]` or `[Should]` requesting a behaviour change MUST carry `Observed input:`,
   `Affected scope:` and `Falsifier:` lines; a `[Blocker]` must cite an observed failure. The Builder
   may disposition a request lacking these as `Declined — unproven generalization`.
5. HAND OFF EXPLICITLY (GH-268): end your turn by naming who acts next — "handing off to codex —
   codex, take your turn" when requesting changes, or "relay closed, no further turn needed" when
   approving. The beta report singled this out: the Reviewer turn did not tell the user to go back to the
   Producer, so the relay looked stalled when it was simply waiting. Do this EVERY round.


### Round 1 · Builder · codex

Implemented GH-732 B.1 in the three authorized artifact files:
- `validate.sh`: probes the current PATH before the pool (also visible in `--print-mode`), exports freshly computed comma-separated `XYZ_ENV_FAULTS`, names broken PHP only when both version and empty-file lint fail, names the yaml interpreter and gate-toolchain PATH hint, and repeats faults with NOT promotion evidence in the summary. Existing exit codes, qualification code, suite registration, and solo re-run verdict are unchanged.
- `test/gh268-relay-cue-and-target-checks.sh`: wraps the existing PHP assertions for reuse, reports the named skip when the fault list contains the exact php token, and adds a broken-PHP subprocess control using the validator's actual diagnostic block.
- `test/gh251-validate-pytest-skip.sh`: adds the missing-yaml interpreter shim and asserts the named diagnostic, repair PATH, and evidence limitation through `--print-mode`; existing pytest cases are unchanged.

Verification: `bash -n validate.sh test/gh251-validate-pytest-skip.sh test/gh268-relay-cue-and-target-checks.sh` exited 0. Narrow extracted regression blocks ran under `.relay-scratch/`: PHP fault control 1 pass/0 fail, YAML control passed; deleting the PHP marker caused exit 1 with the expected clean-PHP failure, and mutating the YAML diagnostic caused exit 1. Deterministic healthy-PHP stub control exercised both existing lint assertions (3 pass/0 fail including fault control); version-only and lint-only failures did not classify PHP as unusable, while both failing did. This host's actual PHP is broken (missing libaspell), so the healthy stub is branch evidence, not a real healthy-toolchain acceptance run. The actual Python also lacks yaml and was named correctly.

Evidence logs: `.relay-scratch/php-focused.log`, `php-mutant.log`, `yaml-focused.log`, `yaml-mutant.log`, `php-healthy-stub.log`, and the three single/both-failure logs. These are ephemeral turn evidence, not committed promotion provenance.

Outstanding harness/operator verification: full focused suites, the disposable-clone pytest-less qualification boundary (exit 6 and no receipt), B.2 fresh-clone full gate with zero re-runs and four planted faults, and retained TESTS-RESULTS provenance. The turn explicitly forbids Git, full-gate execution, and writes outside the four-file allowlist plus scratch, so those acceptance runs and retained evidence were not performed here. No full-gate success or phase completion is claimed. Reversibility: Easy; the diagnostic block and test changes are local and removable.

Handing off to agy for review.
