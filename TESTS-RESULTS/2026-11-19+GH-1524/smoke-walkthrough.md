# GH-1524 Smoke Walkthrough & Red Control (2026-11-19)

Base commit: `5b861e85d5f455d016fffaa78958723666e33aff` (`origin/development`).
Note: This is an instruction-consistency walkthrough over the updated skill Markdown files; live unattended execution on `BinoidCBD/LTVera-Pandas` remains to be run by the operator.

## Red Control (pre-edit base `5b861e85d5f4`)

Checked against `git show 5b861e85d5f4:skills/3-weekly/10days/SKILL.md`, `git show 5b861e85d5f4:skills/2-daily/flywheel/SKILL.md`, and `git show 5b861e85d5f4:ARCHITECTURE.md`:

1. **No `HAS-PR` disposition:** `10days/SKILL.md` Step 3 only defined `"decision": "INCLUDE|HELD|EXCLUDE"` and ran `gh pr list --state merged` with zero open-PR check and zero routing to `pr-minder` / `merge-cleanup`.
2. **No post-Step-3 mode routing or single-harness exception:** `10days/SKILL.md` had no `remediate` or `serial` mode and no precedence statement over `start-task:235`'s unavailable-reviewer stop rule (`skills/1-hourly/start-task/SKILL.md:235`).
3. **Unconditional Jog prohibition in Flywheel:** `flywheel/SKILL.md:168` (*"Do not send its issues through Jog"*) and `flywheel/SKILL.md:209` (*"do not substitute Jog dispatch"*) both unconditionally blocked an explicit `10days` `serial` handoff.
4. **Missing Skills Index row:** `ARCHITECTURE.md` had no `pr-minder` entry under `### 2-daily`.

## Scenario 1 (Main path) — `LTVera-Pandas#1179`-shaped sweep into `HAS-PR` + `serial` single-harness Claude-Code-only mode

- **Input:** 27 open issues from a 10-day sweep (12 with open PRs — 4 green/mergeable, 4 conflicting, 2 changes-requested, 1 draft, 1 open; 10 bounded no-PR code fixes; 5 larger features), operator explicitly selects `10days` `serial` single-harness Claude-Code-only mode on the 10 bounded fixes (leaving open PRs out of build).
- **Walkthrough against updated `skills/3-weekly/10days/SKILL.md`:**
  1. **Step 3:** Open-PR lookup classifies all 12 open-PR items as `HAS-PR` with `open_prs` populated. Green/mergeable items map to `merge-cleanup`; behind/conflicting/failing/draft items map to `pr-minder`. None enter Step 4–7 build paths.
  2. **Step 3.5 (`serial` — direct raw-to-PR via `start-task`, single-harness):** Operator's explicit single-harness selection invokes the narrow single-harness exception over `start-task:235` for this run only (without modifying `start-task` globally). Each of the 10 bounded fixes runs serially in a fresh sibling full clone, preserves target-repo mandatory deterministic tests/gates, emits `Independent review did not run.` plus one factual line stating cross-model review is deferred to PR review on every PR and closeout comment, never claims cross-model approval, never auto-merges, and holds/skips any blocked item while continuing independent fixes.
  3. **Step 8:** Reports `Mode selected: serial (start-task, single-harness)`, the **HAS-PR Ledger** (all 12 items with PR state and `pr-minder`/`merge-cleanup` owner), **Held**, **Preparation**, and **Execution Ledger**.
- **Verdict:** PASS (instruction path reaches ready PRs without stalling at `start-task:235` and without rebuilding the 12 open PRs).

## Scenario 2 (Adjacent path A) — `remediate` prepare-only mode with a `HELD` item

- **Input:** Operator invokes `10days` in `remediate` mode on a batch containing 2 raw bounded issues and 1 ambiguous product-decision issue.
- **Walkthrough against updated `skills/3-weekly/10days/SKILL.md`:**
  1. **Step 3.5 (`remediate`):** Runs Step 4 (`conveyor` medium research, capture synthesis, `Swarm Preflight Contract`, parent-owned `roadmap pickup`, `swarm-preflight.sh --dry-run`) on the 2 bounded items and holds the ambiguous product-decision item in `HELD` without creating a dangling ledger row or fake contract.
  2. **Stop boundary:** Stops before execution (Steps 5–7 do not fire) and reports ready (exit 0) vs. `HELD` items and next owner (`jog`, `start-task`, or `marathon`) in Step 8.
- **Verdict:** PASS.

## Scenario 3 (Adjacent path B) — Literal `flywheel` Steps 1–3 walkthrough (`serial` vs. default `marathon`)

- **Input A (explicit `10days` `serial` `conveyor → jog`):**
  - `flywheel/SKILL.md` (`Daily observation and 10days batches` + Operating Flow Step 3): recognizes the operator-selected `10days` `serial` mode, permits handing committed Step 4 / `conveyor`-prepared survivors to `jog` under the same batch owner with no duplicate enqueueing and no auto-merge.
- **Input B (default `10days` `marathon`):**
  - `flywheel/SKILL.md` (`Daily observation and 10days batches` + Operating Flow Step 3): preserves default `marathon` ownership, uses `10days` preflight/collision checks/firing exception, and forbids substituting Jog dispatch or adding start-marathon confirmation.
- **Verdict:** PASS (zero contradiction between `10days/SKILL.md` and `flywheel/SKILL.md` across both modes).
