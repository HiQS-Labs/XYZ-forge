---
issue: 1557
title: "kickstart(KS-13): final-QA staleness detection in kickstart_status.py and automatic child re-run"
status: active
roadmap_id: rmi-01M7W9AQ0HTSQA0ACDS41XVPW8
parent_arc: 1541
milestone: KS-13
owner: antigravity
goal: "Fix multi-SHA later-landing staleness suppression in kickstart_status.py, expose deterministic rerun_required/handback_allowed/recommended_action fields, mandate autonomous child pre-handback final-QA re-run in SKILL.md, and retain a paired red/green run-1 later-landing replay."
created: 2026-11-20
updated: 2026-11-20
---

# GH-1557 (KS-13) — Final-QA Staleness Detection & Automatic Child Re-Run

Parent arc: #1541 (milestone KS-13).

## Status

| What was just completed | What's next |
|---|---|
| Grounded recon of KS-04 `kickstart_status.py` and `SKILL.md`; drafted surgical KS-13 plan. | Codex Plan QA -> implement -> paired red/green run-1 replay -> Codex Final QA -> PR -> land. |

## Problem & Recon Findings
In run 1, PR #1539 landed after an earlier `GATE: final-QA` pass, and the child did not detect staleness or re-run final QA autonomously — requiring manual parent intervention.
Recon of `skills/1-hourly/kickstart/scripts/kickstart_status.py` (landed in KS-04, PR #1550) and `skills/1-hourly/kickstart/SKILL.md` identified three gaps:
1. **Multi-SHA later-landing bug in `_assess_final_qa`:** `later_landings` excludes any post-`qa_line` `MERGED` line where `any(_sha_matches(s, qa_sha) for s in shas)`. If a later `MERGED` line cites both `qa_sha` (e.g. prior/base head) and a new merge/reconcile SHA, `any()` falsely suppresses staleness. Fix: exclude a post-`qa_line` `MERGED` line ONLY when `shas` is non-empty and *every* SHA on that line matches `qa_sha`.
2. **Missing actionable handback contract in `kickstart_status.py`:** `final_qa` reports `status` (`fresh` | `stale` | `missing` | `unknown`), but does not emit deterministic handback/re-run decision fields (`rerun_required`, `handback_allowed`, `latest_landing_sha`, `target_head`, `recommended_action`), nor render them in Markdown output.
3. **Missing mandatory child pre-handback rule in `SKILL.md`:** `### Child (Outer-Loop Executor)` and `### Transition 1: Normal Completion` do not yet require the child to query `kickstart_status.py --record <record> --development-head <origin/development-sha> --skip-prs --json` before handback, automatically re-run final QA (tier 1 + full disposable-clone gate) and append a new canonical `GATE: final-QA` line when `handback_allowed` is false (`stale`/`missing`), and re-verify `status == "fresh"` before handing back — without waiting to be told.

## Implementation Plan (Surgical, `route=docs`, No New Test Suites per GH-831)
1. **`skills/1-hourly/kickstart/scripts/kickstart_status.py`:**
   - Fix `later_landings` filter in `_assess_final_qa`: exclude a post-`qa_line` `MERGED` entry ONLY when `shas` is non-empty and `all(_sha_matches(s, qa_sha) is True for s in shas)`.
   - Extend `final_qa` dict (strictly additive, backward-compatible with KS-04) with:
     - `rerun_required: bool` (`True` for `stale`, or `missing` when `merged_landings` is non-empty; `False` for `fresh`, `missing` with 0 landings, or `unknown` pending `--development-head`).
     - `handback_allowed: bool` (`True` ONLY for `fresh`, or `missing` with 0 landings; fail-closed `False` for `stale`, `unknown`, or `missing` with landings).
     - `latest_landing_sha: str | None` and `target_head: str | None` (`development_head` if supplied, else `latest_landing_sha`).
     - `recommended_action: str` (`handback-ready` | `handback-ready-no-landings` | `rerun-final-qa` | `run-final-qa` | `verify-development-head`).
   - Update `render_markdown()` to display `Handback allowed`, `Rerun required`, `Recommended action`, and any `Later landings` lines.
2. **`skills/1-hourly/kickstart/SKILL.md`:**
   - Add Child rule 5 (Pre-Handback Final-QA Staleness Gate & Autonomous Re-Run, KS-13) and update `### Transition 1: Normal Completion` + the KS-04 `Final-QA staleness` bullet so the child MUST verify `kickstart_status.py` against live `origin/development` before handback, automatically re-run final QA + record `GATE: final-QA` on `stale`/`missing` without being told, and halt/report red if the re-run fails.
3. **Paired Red/Green Verification (`TESTS-RESULTS/2026-11-20+GH-1557/`, no new test suites):**
   - **Pre-change red control:** Replay run-1's later-landing sequence (initial `GATE: final-QA <sha1>`, later `MERGED PR #1539` including multi-SHA line citing `<sha1>` + `<sha2>`) on pre-change `origin/development` `kickstart_status.py` and `SKILL.md`.
   - **Post-change green control:** Replay the exact same run-1 sequence through changed `kickstart_status.py` + `run_record.py append` + deterministic pre-handback re-run loop (initial `fresh` -> later landing `stale`/`rerun-final-qa`/`handback_allowed=False` -> autonomous re-run appends `GATE: final-QA <sha2> full 890s green` -> re-check `fresh`/`handback_allowed=True`), plus edge controls (non-landing task `GATE:`, missing with/without landings, unverified `--development-head`, red `final-QA`). Retain exact probe source + outputs + `mypy` + `ci-route.sh` + `pdda.sh run` + `provenance.jsonl`.
4. **Governance & Changelog:** Update `CHANGELOG.md`, Codex Final QA, open PR, link PR, `@coderabbitai review`.
