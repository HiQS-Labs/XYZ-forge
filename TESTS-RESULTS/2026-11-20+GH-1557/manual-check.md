---
issue: GH-1557
milestone: KS-13
date: 2026-11-20
route: docs
---

# GH-1557 (KS-13) Manual Check — Final-QA Staleness Detection & Autonomous Child Re-Run

## Scope & Architecture
- `skills/1-hourly/kickstart/scripts/kickstart_status.py`:
  - Fixes multi-SHA `later_landings` staleness bug (checking `bool(shas)` and `all(_sha_matches(s, qa_sha) is True for s in shas)`).
  - Fixes `qa_line` lookup bug where `run_record.py` stores `"line_no"` on parsed `GATE:` records while `_assess_final_qa` previously read only `"line"` (causing `qa_line=0` and falsely flagging pre-QA earlier landings as later landings after a re-run).
  - Exposes `rerun_required`, `handback_allowed`, `latest_landing_sha`, `target_head`, and `recommended_action` in both JSON and Markdown output.
- `skills/1-hourly/kickstart/SKILL.md`: Enforces Child rule 5, Transition 1, and KS-04 staleness contract with a single reconciled decision table covering 0-landing exception, stale-QA autonomous re-run (merge -> re-verify -> fresh final QA -> post-QA head re-verification), and fresh-QA handback.

## Controls Executed (`outputs/ks13-probe.py` -> `outputs/ks13-controls.txt`)
1. **Part A (Executed CLI/Parser Controls — Red vs Green):**
   - Baseline (`origin/development` `6062aa2ea7`) vs Candidate (`HEAD`) against synthetic run records covering:
     - Multi-SHA later landings (1 landing vs 2+ landings, partial vs complete merge into `HEAD`).
     - Boundary controls: same-SHA only vs SHA-less later landings.
     - Run-1 sequence via real `run_record.py append` (earlier PR #1534 SHA1 -> initial final-QA SHA1 -> later PR #1539 SHA2 -> failed red rerun -> green rerun on SHA2 while concurrent SHA3 landed -> fresh green rerun on verified SHA3). This probe also caught and verified the `line_no` fix.
     - 0-landing exception and missing `--development-head` handling.
2. **Part B (Explicitly Labeled Simulated Consumer Walkthrough):**
   - Exercises the `SKILL.md` decision table transitions against real `kickstart_status.py --json` outputs (explicitly labeled as simulated orchestration; live full-gate execution is run 2).
3. **Static & Governance Checks:**
   - `mypy --allow-untyped-defs --allow-incomplete-defs skills/1-hourly/kickstart/scripts/kickstart_status.py` -> `outputs/mypy.log` (0 issues).
   - `./utils/ci-route.sh pull_request` -> `outputs/ci-route.log` (`route=docs`).
   - `./utils/pdda/pdda.sh run` -> `outputs/pdda-run.log` (0 errors).
   - Exact diff retained in `outputs/code-and-docs.patch`.

All output files are hashed in `provenance.jsonl`.
