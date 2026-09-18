---
title: "GH-661/662/682: relay containment verification, offlane diagnostic lookalike fix, and reviewer probe environment injection"
status: Complete
created: 2026-09-18
updated: 2026-09-18
owner: operator
gh_issue: 661, 662, 682
source: https://github.com/HiQS-Labs/XYZ-forge/issues/661
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
ratings_provisional: false
branch: fix/gh661-662-682-relay-containment-env
goal: >
  Verify and document GH-661 containment bridge regression completion, repair GH-662
  offlane prefix lookalike diagnostic filtering in rtl.py, and implement GH-682 automated
  PYTHONDONTWRITEBYTECODE/TMPDIR process environment injection across all 8 Python turn shims for reviewer turns.
---

# GH-661 / GH-662 / GH-682 — Relay Containment & Reviewer Probe Upgrades

## Status

| What was just completed | What's next |
|---|---|
| Implemented lookalike prefix fix in `rtl.py`, added `apply_reviewer_turn_env` across all 8 Python turn shims, extended test suites (`gh654-offlane-log.sh` 10/10, `gh681-reviewer-probe-rules.sh` 27/0), passed double Relay QA (Plan + Final Approved). | Run validation gate, push branch `fix/gh661-662-682-relay-containment-env`, and open ready PR targeting `development`. |

## Context & Diagnosis

This effort resolves three closely coupled relay-containment and turn-shim issues:

1. **GH-661 (Relative relay-file initialization write scope)**:
   - The production bridge fix landed under commit `ac9fb274ef34` (#658).
   - Independent review gaps (Agy probe containment gap #666 / PR #669, test fixture safety #653 / #665 / PR #671) were resolved.
   - GH-661 regression coverage is verified in `test/gh654-offlane-log.sh` (`test_absolute_relay_file_normalizes_to_relative`) and closed out.

2. **GH-662 (Offlane prefix exemptions hide lookalike files)**:
   - In `utils/py/rtl.py`, `offlane_candidates` used `path.startswith(OFFLANE_EXEMPT)` with tuples `(".tick", ".relay-scratch", "relay-system")`.
   - As a result, lookalike files like `.tick-other.txt` and `relay-system-other.txt` were erroneously skipped from offlane candidate reporting.
   - Fix: check exact directory equality or slash-separated child (`any(bare == e or path.startswith(e + "/") for e in OFFLANE_EXEMPT)`).

3. **GH-682 (Harness-set PYTHONDONTWRITEBYTECODE / TMPDIR for reviewer turns)**:
   - Follow-up to GH-681. Reviewers may run narrow non-mutating probes under `.relay-scratch/` or `$TMPDIR`.
   - To prevent bytecode `.pyc` and stray temporary files from polluting `.relay-artifacts/` and altering signature hashes, the turn shims automatically inject `PYTHONDONTWRITEBYTECODE=1` and `TMPDIR=<run_cwd>/.relay-scratch/tmp` (creating the directory if absent) into the child CLI process environment on Reviewer turns.
   - Detection uses `rtl_is_reviewer_turn` via `_run_rtl` to reuse the canonical driver-aware role detection in `relay-turn-lib.sh`.
   - Touch points: `utils/py/rtl.py` (`apply_reviewer_turn_env`), and all 8 Python turn shims: `codex-turn.py`, `agy-turn.py`, `claude-turn.py`, `pi-turn.py`, `aider-turn.py`, `muse-turn.py`, `deepseek-turn.py`, `commandcode-turn.py`.

## Acceptance Criteria

- [x] `utils/py/rtl.py` correctly reports lookalike files (`.tick-other.txt`, `relay-system-other.txt`, `.relay-scratch-other.txt`) as offlane while preserving valid exemptions (`.tick/`, `.relay-scratch/`, `relay-system/`).
- [x] `bash test/gh654-offlane-log.sh` passes all assertions with lookalike negative controls and mutation check (10/10 PASS).
- [x] `utils/py/rtl.py` provides `apply_reviewer_turn_env(env, run_cwd, agent)` backed by `rtl_is_reviewer_turn` and all 8 turn shims inject `PYTHONDONTWRITEBYTECODE=1` and `TMPDIR` on reviewer turns.
- [x] `bash test/gh681-reviewer-probe-rules.sh` extended with reviewer environment injection checks and passes all cases (27/0 PASS).
- [x] Double Codex/Agy Relay QA (Plan + Final) complete and approved (`relay-system/2026-09-18/gh661-662-682-plan-qa.md`, `relay-system/2026-09-18/gh661-662-682-final-qa.md`).
- [ ] Full `./validate.sh` passes clean in isolated clone.
- [ ] Pull request opened targeting `development` with `Closes #661, Closes #662, Closes #682`.

## Review Evidence

- Plan QA Relay: `relay-system/2026-09-18/gh661-662-682-plan-qa.md` — Approved in Round 2 (Agy reviewer verified 8-shim scope and canonical role detection).
- Final QA Relay: `relay-system/2026-09-18/gh661-662-682-final-qa.md` — Approved in Round 1 (Agy reviewer verified code changes, local probes, test regressions, and absence of side effects).
