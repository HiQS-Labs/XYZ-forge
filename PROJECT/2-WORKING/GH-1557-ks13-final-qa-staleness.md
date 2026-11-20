---
issue: 1557
title: "kickstart(KS-13): final-QA staleness detection in kickstart_status.py and automatic child re-run"
status: active
roadmap_id: rmi-01M7W9AQ0HTSQA0ACDS41XVPW8
parent_arc: 1541
milestone: KS-13
owner: antigravity
goal: "Fix multi-SHA later-landing staleness suppression in kickstart_status.py, expose deterministic rerun_required/handback_allowed/recommended_action fields with a single reconciled decision table, mandate autonomous child pre-handback final-QA re-run with post-QA head re-verification in SKILL.md, and retain a paired red/green run-1 later-landing replay."
created: 2026-11-20
updated: 2026-11-20
---

# GH-1557 (KS-13) — Final-QA Staleness Detection & Automatic Child Re-Run

Parent arc: #1541 (milestone KS-13).

## Status

| What was just completed | What's next |
|---|---|
| Revised plan for Plan QA R2 addressing all 3 Codex findings (isolated multi-SHA red controls, single reconciled decision table including no-landing exception, post-QA head re-verification, failed-rerun red control, and explicit separation of CLI replay vs simulated child walkthrough). | Codex Plan QA R2 approval -> implement -> paired red/green replay -> Codex Final QA -> PR -> land. |

## Problem & Recon Findings
In run 1, PR #1539 landed after an earlier `GATE: final-QA` pass, and the child did not detect staleness or re-run final QA autonomously — requiring manual parent intervention.
Recon of `skills/1-hourly/kickstart/scripts/kickstart_status.py` (landed in KS-04, PR #1550) and `skills/1-hourly/kickstart/SKILL.md` identified three gaps:
1. **Multi-SHA later-landing bug in `_assess_final_qa`:** `later_landings` excludes any post-`qa_line` `MERGED` line where `any(_sha_matches(s, qa_sha) for s in shas)`. If a later `MERGED` line cites both `qa_sha` and a new merge/reconcile SHA, `any()` falsely suppresses staleness (verified: `head=None -> unknown, later_landings=0`; `head=qa_sha -> fresh, later_landings=0`).
2. **Missing actionable handback contract in `kickstart_status.py`:** `final_qa` reports `status` (`fresh` | `stale` | `missing` | `unknown`), but does not emit deterministic handback/re-run decision fields (`rerun_required`, `handback_allowed`, `latest_landing_sha`, `target_head`, `recommended_action`), nor render them in Markdown output.
3. **Missing mandatory child pre-handback rule in `SKILL.md`:** `### Child (Outer-Loop Executor)` and `### Transition 1: Normal Completion` do not yet require the child to query `kickstart_status.py` against a freshly verified `origin/development` head before handback, follow a single reconciled decision table (including the no-landing exception and post-QA head re-verification), and automatically re-run final QA on `rerun_required == true` without waiting to be told.

## Single Reconciled Decision Table (Code + `SKILL.md`)

| `final_qa.status` | Condition | `rerun_required` | `handback_allowed` | `recommended_action` | Required Child Action |
|---|---|---|---|---|---|
| `fresh` | Green canonical `GATE: final-QA` matches verified `--development-head` with 0 later landings | `false` | `true` | `handback-ready` | Proceed to Normal Completion handback. |
| `missing` | No `GATE: final-QA` and 0 `MERGED` landings in run | `false` | `true` | `handback-ready-no-landings` | Proceed to handback without unnecessary full QA (empty/no-landing run). |
| `missing` | No `GATE: final-QA` and >=1 `MERGED` landings in run | `true` | `false` | `run-final-qa` | Autonomously run final QA on freshly fetched `origin/development`, re-verify remote head AFTER QA completes, record `GATE: final-QA`, and re-assess. |
| `stale` | Latest `GATE: final-QA` is `red`, OR >=1 later landings after `qa_line`, OR verified `--development-head` differs from `final_qa_sha` | `true` | `false` | `rerun-final-qa` | Autonomously re-run final QA on freshly fetched `origin/development`, re-verify remote head AFTER QA completes (so a landing during QA cannot be certified using a stale head), record `GATE: final-QA`, and re-assess. |
| `unknown` | Green `GATE: final-QA` with 0 later record landings, but `--development-head` omitted/unverified | `false` | `false` | `verify-development-head` | Fetch/verify live `origin/development` head and re-run `kickstart_status.py`; if remote head cannot be verified, hold handback (never claim normal completion). |

## Implementation Plan (Surgical, `route=docs`, No New Test Suites per GH-831)
1. **`skills/1-hourly/kickstart/scripts/kickstart_status.py`:**
   - Fix `later_landings` filter in `_assess_final_qa`: exclude a post-`qa_line` `MERGED` entry ONLY when `shas` is non-empty and `all(_sha_matches(s, qa_sha) is True for s in shas)` (so multi-SHA lines citing both `qa_sha` and a new SHA, and SHA-less later `MERGED` lines, are BOTH caught as later landings; same-SHA-only lines remain excluded).
   - Emit the additive, backward-compatible fields from the decision table above (`rerun_required`, `handback_allowed`, `latest_landing_sha`, `target_head`, `recommended_action`) in `final_qa`, and render them (plus any `later_landings` line refs) in `render_markdown()`.
2. **`skills/1-hourly/kickstart/SKILL.md`:**
   - Add Child rule 5 (Pre-Handback Final-QA Staleness Gate & Autonomous Re-Run, KS-13), update `### Transition 1: Normal Completion`, and update the KS-04 `Final-QA staleness` bullet using the exact single decision table above:
     - Hand back ONLY when `handback_allowed == true` (`fresh`, or `missing` with 0 landings).
     - On `rerun_required == true` (`stale` or `missing` with landings): autonomously run/re-run final QA (tier 1 + full disposable-clone gate, backgrounded per KS-07) without waiting for parent/operator; append `GATE: final-QA <tested-sha> full <Ns> green` ONLY after both checks pass; then **re-fetch and re-verify live `origin/development` AFTER QA completes** and re-run `kickstart_status.py` so any landing that occurred during QA invalidates the pass and triggers another check rather than certifying a stale head.
     - On failed re-run: append `GATE: final-QA <tested-sha> full <Ns> red`, keep `handback_allowed=false`, do NOT claim Normal Completion, and hand back with failure evidence within budget.
     - On `unknown`: verify live remote `origin/development` head and reassess; if verification fails, hold handback.
3. **Paired Red/Green Evidence (`TESTS-RESULTS/2026-11-20+GH-1557/`, no new test suites per GH-831):**
   - Retain the exact runnable probe source verbatim alongside its captured outputs, plus `mypy`, `ci-route.sh` (`route=docs`), `pdda.sh run`, `code-and-docs.patch`, and SHA-256 `provenance.jsonl`.
   - **Part A — Executed CLI & Parser Controls (Baseline pre-change `origin/development` vs Candidate):**
     1. *Isolated multi-SHA suppression red/green control:* post-`qa_line` `MERGED` line citing `[qa_sha, new_sha]` tested with (a) `development_head=None` (baseline `unknown`, `later_landings=0` -> candidate `stale`, `later_landings=1`, `rerun_required=True`, `handback_allowed=False`) and (b) `development_head=qa_sha` (baseline `fresh`, `later_landings=0` -> candidate `stale`, `later_landings=1`, `rerun_required=True`, `handback_allowed=False`).
     2. *Nonempty/all-True boundary controls:* same-SHA-only post-`qa_line` `MERGED` line (`[qa_sha]`) -> excluded (`later_landings=0`, `fresh`); SHA-less post-`qa_line` `MERGED` line (`[]`) -> included (`later_landings=1`, `stale`).
     3. *Run-1 later-landing sequence replay (CLI + `run_record.py append`):*
        - Step 1: initial `MERGED PR #1534` + `GATE: final-QA <sha1> full 920s green` with `--development-head <sha1>` -> `fresh`, `handback_allowed=True`.
        - Step 2: later `MERGED PR #1539` (`<sha2>`) with `--development-head <sha2>` -> `stale`, `rerun_required=True`, `handback_allowed=False`, `recommended_action="rerun-final-qa"`.
        - Step 3 (failed-rerun control): append `GATE: final-QA <sha2> full 300s red` via `run_record.py append` -> `stale`, `rerun_required=True`, `handback_allowed=False` (blocks handback).
        - Step 4 (landing-during-QA re-verification control): append `GATE: final-QA <sha2> full 890s green`, then re-check against newer remote `--development-head <sha3>` -> `stale`, `handback_allowed=False` (prevents certifying stale head).
        - Step 5 (green on final verified head): append `GATE: final-QA <sha3> full 890s green` and re-check with `--development-head <sha3>` -> `fresh`, `rerun_required=False`, `handback_allowed=True`, `recommended_action="handback-ready"`.
     4. *Decision-table edge controls:* non-landing task `GATE:` after `final-QA` stays `fresh`; `missing` with landings -> `run-final-qa` / `handback_allowed=False`; `missing` with 0 landings -> `handback-ready-no-landings` / `handback_allowed=True` / `rerun_required=False`; unverified `--development-head` -> `unknown` / `verify-development-head` / `handback_allowed=False`.
   - **Part B — Simulated Pre-Handback Consumer Walkthrough (explicitly labeled simulated; no live full-gate runtime claim):** Exercises a minimal consumer loop reading `kickstart_status.py --json` across the decision table (no-landing empty run, stale -> autonomous rerun -> post-QA re-verify, failed rerun -> hold, unknown -> fetch head -> hold on failure). Explicitly documents that Part B validates the decision contract/CLI integration and does not claim a live full-gate execution (which is `route=docs` for this docs/skill-script PR and exercised live in run 2).
4. **Governance & Changelog:** Follow repo `CHANGELOG_WRITES` configuration (check `.pdda.conf` / repo convention; update `CHANGELOG.md` only if configured/required by `pdda.sh run`), Codex Final QA, PR, link PR, `@coderabbitai review`.
