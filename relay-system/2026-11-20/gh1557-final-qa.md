# Final QA Relay — GH-1557 (KS-13: Final-QA Staleness Detection & Autonomous Child Re-Run)

STATUS: Ready for review

- **Issue:** #1557 (parent arc #1541, milestone KS-13)
- **Candidate Head:** `ab8b4ee3a8ceb8195d510746fb3a5026c8e06a56`
- **Base Head (`origin/development`):** `6062aa2ea77a01a9d395f0cee971a0bdcf62c3e0`
- **Plan QA Relay:** `relay-system/2026-11-20/gh1557-plan-qa.md` (Turn 4 `Approved`)
- **Route:** `docs`

## Turn 1 — Producer (Antigravity)

Implemented GH-1557 (KS-13) per the Codex Plan QA R2 approved plan (`relay-system/2026-11-20/gh1557-plan-qa.md`, Turn 4 `Approved`) on candidate HEAD `ab8b4ee3a8ceb8195d510746fb3a5026c8e06a56` (based on `origin/development` `6062aa2ea7`):

- `skills/1-hourly/kickstart/scripts/kickstart_status.py`:
  - Fixed the multi-SHA `later_landings` staleness check (`shas and all(_sha_matches(s, qa_sha) is True for s in shas)`).
  - Fixed a real `line_no` vs `line` bug caught by our executable probe: `run_record.py` writes `"line_no"` on parsed `GATE:` entries whereas `_assess_final_qa` previously read `g.get("line", 0)`, causing `qa_line=0` and falsely flagging pre-QA landings as later landings after a re-run. Now reads `line_no` with fallback to `line`.
  - Added explicit machine-readable and Markdown fields (`rerun_required`, `handback_allowed`, `latest_landing_sha`, `target_head`, `recommended_action`).
- `skills/1-hourly/kickstart/SKILL.md`: Updated Child rule 5, Transition 1, and the KS-04 staleness section with a single reconciled decision table (including the 0-landing exception and post-QA head re-verification).
- `CHANGELOG.md`: Recorded the GH-1557 entry.
- `TESTS-RESULTS/2026-11-20+GH-1557/`: Retained executable probe `outputs/ks13-probe.py`, full output `outputs/ks13-controls.txt` (Part A executed red/green CLI controls against baseline `6062aa2ea7` vs candidate + Part B explicitly labeled simulated consumer walkthrough), `outputs/mypy.log`, `outputs/ci-route.log` (`route=docs`), `outputs/pdda-run.log`, `outputs/code-and-docs.patch`, `manual-check.md`, and `provenance.jsonl`.

Please review for Final QA approval.

**NEXT: Reviewer (Codex)**
