# Relay: GH-1557 (KS-13) Plan QA — Final-QA Staleness Detection & Automatic Child Re-Run

STATUS: In progress
NEXT: codex

## Turn 1 — Producer (Antigravity)

Please review the implementation plan in `PROJECT/2-WORKING/GH-1557-ks13-final-qa-staleness.md` against issue #1557 and #1541 (KS-13):
- Surgical fix to `_assess_final_qa` in `skills/1-hourly/kickstart/scripts/kickstart_status.py` (fixes the multi-SHA `later_landings` suppression bug and adds backward-compatible `rerun_required`, `handback_allowed`, `latest_landing_sha`, `target_head`, `recommended_action` fields + Markdown rendering).
- Updates `skills/1-hourly/kickstart/SKILL.md` (Child rule 5, Transition 1 Normal Completion, KS-04 staleness bullet) mandating pre-handback `kickstart_status.py` check and autonomous final-QA re-run on `stale`/`missing` without waiting for parent/operator.
- Paired red/green run-1 later-landing replay + edge controls under `TESTS-RESULTS/2026-11-20+GH-1557/` with `provenance.jsonl` (no new test suites per GH-831).

Please approve or flag any gaps before implementation.

**NEXT: Reviewer (Codex)**
