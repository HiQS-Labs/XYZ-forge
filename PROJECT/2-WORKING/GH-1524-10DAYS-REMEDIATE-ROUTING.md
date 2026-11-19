---
gh_issue: 1524
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1524
title: "GH-1524: 10days HAS-PR routing and remediate / serial-JIT / marathon modes"
status: Active
created: 2026-11-19
updated: 2026-11-19
owner: noelsaw
doc_type: plan
rating: "pri/sev/appeal/effort 75/60/50/85 · calc 270"
rating_ovr: null
is_manual_override: false
goal: "Add HAS-PR routing and explicit remediate / serial-JIT / marathon modes to /10days without duplicating queues or runners."
---

# GH-1524: 10days HAS-PR routing and remediate / serial-JIT / marathon modes

Tracking issue: [#1524](https://github.com/HiQS-Labs/XYZ-forge/issues/1524)

## Status

| What was just completed | What's next |
|---|---|
| Codex Plan QA Approved in round 2 (`f54231c2c15d`), admitted GH-1524 (`--accepted-start`), implemented docs edits in `10days/SKILL.md`, `flywheel/SKILL.md`, `ARCHITECTURE.md`, and `CHANGELOG.md`, and ran PDDA + smoke/red-control checks (`TESTS-RESULTS/2026-11-19+GH-1524/`) | Run Codex Final QA relay (`relay-xyz`), push through pre-push gate, open ready PR against `development`, post closeout comment on `#1524`, and retire task checkout |

## Preflight Bet Check (Solution-Fit)

- **Outcome sought:** Real `/10days` sweeps on raw backlogs (such as `BinoidCBD/LTVera-Pandas#1179` and `HiQS-Labs/XYZ-forge#1441`) cleanly separate already-open-PR issues from no-PR issues and give operators an explicit, non-stalling route from raw issues to ready PRs (prepare-only, serial JIT per-task, or parallel marathon waves).
- **Smallest viable bet (Easy reversibility — revert PR):** Documentation-only updates to three files (`skills/3-weekly/10days/SKILL.md`, `skills/2-daily/flywheel/SKILL.md`, `ARCHITECTURE.md`) composing existing owners (`conveyor`, `pr-minder`, `merge-cleanup`, `jog`, `start-task`, `kickstart`, and `10days` Steps 5–7).
  - **Explicit Non-Goals:** Zero runtime code edits (`jog_run.py`, `swarm_preflight.py`, `marathon_plan.py` stay deterministic and unchanged); no new queue, runner, daemon, schema, or test suite (GH-831); no automatic PR merging or issue closing.
- **Alternatives rejected:**
  1. Adding a prose remediation hook inside `utils/py/jog_run.py`: rejected because `jog/SKILL.md:42` explicitly reserves RAW prose intake for `conveyor`/preparation and keeping `jog_run.py` deterministic avoids blurring admission authority.
  2. Creating a new `/remediate` skill: rejected via `connect-the-dots` because `conveyor` (already wired into `10days` Step 4 by PR #1514), `pr-minder`, `start-task`, `jog`, and `kickstart` (PR #1521) already own every required capability.
- **Rollback / containment:** Easy — pure Markdown skill/index changes; revert the single PR to undo with zero state or schema migration.

## Grounded Recon (Base `5b861e85d5f4`)

- `skills/3-weekly/10days/SKILL.md`:
  - Lines 95–112 (`Optional Flywheel coordination`): currently states *"10days remains the batch owner; Flywheel does not re-enqueue these issues into Jog"*, which conflicts with an operator explicitly choosing a serial `conveyor → jog` route from a `10days` sweep.
  - Lines 239–282 (`Step 3`): defines `decision: "INCLUDE|HELD|EXCLUDE"` with `gh pr list --state merged`, but has **no** check for open PRs and **no** `HAS-PR` disposition routing open-PR items to `pr-minder` / `merge-cleanup`.
  - Lines 290–536 (`Steps 4–7`): PR #1514 (`a9836095de`) wired `conveyor`'s RAW research-depth policy into Step 4, but Steps 5–7 still assume every survivor proceeds directly into all-at-once parallel Marathon planning and branch execution (`marathon-plan.sh` + `swarm-preflight.sh` + wave worktrees), with no explicit `remediate` (prepare-only) or `serial` (JIT prepare → execute one task at a time) mode.
  - Lines 540–566 (`Step 8 Report`): lists Scan Window, PRS Ratings, Exclusion Ledger, Held, Preparation, and Execution Ledger, but has no `HAS-PR` table and no selected-mode field.
- `skills/2-daily/flywheel/SKILL.md`:
  - Lines 164–171 (`Daily observation and 10days batches`): states *"Do not send its issues through Jog or start a second sweep to resume it."*
  - Lines 208–210 (`One ordered operating flow`, Step 3): independently states *"For 10days, use its preflight, collision checks and existing firing exception; do not substitute Jog dispatch or add start-marathon confirmation to that explicitly requested sweep."*
  - Both sites need narrow mode-qualified alignment for explicit operator-selected `10days` `serial` mode while keeping default `marathon` ownership unchanged.
- `skills/1-hourly/start-task/SKILL.md`:
  - Lines 38–44 define the neutral `Skipped independent review` reporting rule (**Independent review did not run.**), while line 235 stops implementation when an independent reviewer is unavailable. Therefore `10days` must declare an explicit, narrow, operator-selected single-harness exception (precedence over `start-task`'s unavailable-reviewer stop rule for that explicitly selected run only), without altering `start-task` globally.
- `ARCHITECTURE.md`:
  - Lines 78–104 (`2-daily` Skills Index): `pr-minder` (`skills/2-daily/pr-minder/SKILL.md`, landed in GH-1498) is missing from the Skills Index table.
- Test-pin check: `grep -rn 'flywheel/SKILL.md\|10days/SKILL.md' test/` shows zero literal-string test pins on either skill's prose (`test/gh400-source-url.sh:5` is a comment only).
- Prior-art check: `prior_art_recon.py --query "10days remediate"` returned 0 conflicting open PRs or issues after PRs #1514 and #1521 landed.

## Ordered Implementation Plan

1. **Plan QA (Step 6):** Commit this plan and `releases.db`/`releases.sql` pickup row; run Codex Plan QA relay via `relay-xyz` (paraphrase-first + source-backed review) until Approved.
2. **Task admission (Step 7):** Run `python3 utils/py/releases_app.py roadmap update --gid <OWNED_ROW> --accepted-start` after Plan QA approval.
3. **Update `skills/3-weekly/10days/SKILL.md`:**
   - In Step 3: add an open-PR check (`gh pr list --state open --search "<N>"`) and `HAS-PR` disposition (`"decision": "INCLUDE|HAS-PR|HELD|EXCLUDE"`, `"open_prs": [...]`) that routes open-PR survivors to `pr-minder` (behind/conflicting/failing/stale) or `merge-cleanup` (green/mergeable) and keeps them out of Step 4–7 build paths (never creating duplicate PRs or auto-merging).
   - Add a **Post-Step-3 Execution Mode Routing** section (and update Guardrails / `Optional Flywheel coordination`) defining three explicit modes over committed Step 3 `INCLUDE` survivors (ordered by `ovr` → `calc` → `sev` → `pri`):
     - **`remediate` (prepare-only):** run Step 4 (`conveyor` research + capture + contract + parent-owned pickup + `swarm-preflight --dry-run`) and stop before execution; report ready vs. held items and next owner (`jog` / `start-task` / `marathon`).
     - **`serial` (JIT prepare → execute one item at a time):** process selected survivors serially so one unready/blocked item stays `HELD` and independent survivors continue without stalling the batch. Supports two existing execution paths without adding any queue:
       - *Multi-harness (`conveyor → jog` / `kickstart`):* prepare each selected item to preflight exit 0 (Step 4 / `conveyor`), then run it serially through `jog` (`--builder codex|agy --reviewer <distinct>`) — preserving `jog`'s deterministic admission (`jog_run.py` never accepts raw prose).
       - *Direct raw-to-PR (`start-task`, including single-harness Claude-Code-only setups):* run each selected survivor serially through `start-task` (fresh sibling full clone, capture + rating, recon, build, target repo checks, ready PR against `development`, retire clone). **Narrow single-harness exception:** when and only when the operator explicitly selects `10days` `serial` single-harness mode (e.g. a Claude-Code-only machine where cross-model review is explicitly deferred to PR review), this operator choice takes precedence over `start-task` Step 6/8's unavailable-reviewer stop rule (`skills/1-hourly/start-task/SKILL.md:235`) for that run only — without modifying `start-task` globally. Target-repository mandatory deterministic tests/gates remain non-negotiable; every PR and issue closeout comment MUST carry `start-task`'s verbatim disclosure (**Independent review did not run.** plus one factual line stating cross-model review is deferred to PR review), must never claim cross-model approval, must never silently substitute headless Claude as a multi-harness builder, and must never auto-merge.
     - **`marathon` (default parallel waves):** existing Steps 4 → 5 → 6 → 6.5 → 7, strictly over exit-0 preflighted items.
   - Update Step 8 Report to include **Mode selected** and a **HAS-PR Ledger** (issue, open PR(s), PR state, handoff owner `pr-minder` vs. `merge-cleanup`).
   - -> expect: clean, self-consistent instructions with zero contradiction against `conveyor`, `jog`, `start-task`, `pr-minder`, or `merge-cleanup`.
4. **Update `skills/2-daily/flywheel/SKILL.md`:**
   - Qualify BOTH `Daily observation and 10days batches` (`:164-171`) AND `One ordered operating flow` Step 3 (`:208-210`) by selected mode: default `10days` (`marathon`) keeps `10days` waves with no Jog substitution; an explicit operator-selected `10days` `serial` mode may hand committed survivors to `jog` (after Step 4 / `conveyor` prep) or `start-task` under one batch owner (no silent re-enqueueing, no duplicate sweeps, no reset of attempt counters, no auto-merge).
   - -> expect: `10days` and `flywheel` (both sections) agree verbatim on ownership and mode-qualified `serial` vs. default `marathon` routing.
5. **Update `ARCHITECTURE.md`:**
   - Add the `pr-minder` row under `### 2-daily` pointing to `skills/2-daily/pr-minder/SKILL.md`.
   - -> expect: link resolves on disk.
6. **Verify & Smoke (Step 7):**
   - Run `git diff --name-only origin/development..HEAD | bash utils/ci-route.sh pull_request` -> expect `docs_only=true`, `route=docs`, `tier=1`.
   - Run `bash utils/pdda/pdda.sh run` -> expect exit 0, 0 errors.
   - Run `python3 utils/py/releases_app.py check` -> expect exit 0, 0 failures.
   - Run manual smoke walkthroughs:
     1. *Main path:* `LTVera-Pandas#1179`-shaped sweep → Step 3 separates 12 `HAS-PR` items (routed to `pr-minder`/`merge-cleanup`) and selects 10 raw bounded fixes into `serial` single-harness Claude-Code-only mode → confirms the narrow single-harness exception supersedes `start-task:235`, keeps target gates mandatory, emits verbatim `Independent review did not run.` disclosure, and leaves PRs awaiting cross-model review.
     2. *Adjacent paths:* (a) `remediate`-only mode preparing raw items via Step 4 / `conveyor` and stopping before execution while holding an unready item; (b) literal walkthrough of `flywheel` Steps 1–3 for both explicit `10days` `serial` (`conveyor → jog` allowed) and default `10days` `marathon` (no Jog substitution).
     3. *Red control:* pre-edit `10days/SKILL.md` and `flywheel/SKILL.md` at `5b861e85d5f4` lack `HAS-PR`, lack the narrow single-harness exception over `start-task:235`, and unconditionally forbid Jog dispatch at `flywheel:168` and `:209`.
     Retain receipts under `TESTS-RESULTS/2026-11-19+GH-1524/` with `provenance.jsonl`.
7. **Final Codex QA & Publish (Steps 8–9):**
   - Append `CHANGELOG.md` entry, decide `LESSONS-LEARNED.md` (`NO_ENTRY` unless non-confounded evidence exists), run Codex Final QA relay until Approved, push through pre-push gate, open ready PR targeting `development`, post closeout comment on `#1524`, and retire task checkout via `merge_cleanup.py --retire-published-pr`.

## Acceptance

- [x] `skills/3-weekly/10days/SKILL.md` Step 3 defines `HAS-PR` (recording open PR numbers/state) and hands `HAS-PR` items to `pr-minder` (behind/conflicting/failing/stale) or `merge-cleanup` (green/mergeable) without entering Step 4–7 build paths.
- [x] `skills/3-weekly/10days/SKILL.md` defines three explicit post-Step-3 modes (`remediate`, `serial`, `marathon` default) reusing existing `conveyor`, `jog`, `start-task`, `kickstart`, and Steps 5–7 with zero new queues or runners.
- [x] `serial` mode documents both multi-harness (`conveyor → jog`) and single-harness (e.g. Claude-Code-only via `start-task` with explicit `Independent review did not run.` disclosure per `start-task`, deferring cross-model review to PR review) without weakening multi-harness defaults or auto-merging PRs.
- [x] `skills/3-weekly/10days/SKILL.md` and `skills/2-daily/flywheel/SKILL.md` agree on `10days` ownership and operator-selected `serial` handoff with no contradiction.
- [x] `skills/3-weekly/10days/SKILL.md` Step 8 Report includes `HAS-PR` items and the selected execution mode.
- [x] `ARCHITECTURE.md` Skills Index includes `pr-minder` pointing to `skills/2-daily/pr-minder/SKILL.md`.
- [x] `ci-route.sh pull_request` classifies the diff as `docs_only=true / tier=1`, `utils/pdda/pdda.sh run` exits 0 with 0 errors, `releases_app.py check` exits 0 with 0 failures, and manual smoke walkthroughs (main path + adjacent path) are retained under `TESTS-RESULTS/` with `provenance.jsonl`.

## Rating Rationale

- **Date:** 2026-11-19 · **Scores:** `rated 75/60/50/85` (`calc = 270`, `ovr = null`).
- **Priority (75):** Operator requested this immediately to unblock Jose's LTVera 10-fix delivery workflow directly on top of merged PRs #1514 and #1521.
- **Severity (60):** Causes full sweep-to-execution stalls on raw backlogs (workflow block, not data corruption).
- **Recurrence:** Two distinct observed sweeps in the 2026-11-05..2026-11-19 window (`HiQS-Labs/XYZ-forge#1441` on 2026-11-11: "10 valid, 0 fireable"; `BinoidCBD/LTVera-Pandas#1179` on 2026-11-18: 12 open-PR + 15 raw no-PR items stopped read-only). Preceding 14-day window (2026-10-22..2026-11-04) was not systematically censused → trend unknown.
- **Appeal (50):** Neutral default per `start-task` rating policy.
- **Effort/cheapness (85):** Small, Easy-reversibility Markdown-only edit across 3 files with zero runtime code changes.

## Lessons Learned (For Future Agents)

`NO_ENTRY` — docs-only instruction composition with paper walkthroughs only; no live runtime run yet (single unexecuted instruction edit would be confounded under `LESSONS-LEARNED.md` admission rules).
