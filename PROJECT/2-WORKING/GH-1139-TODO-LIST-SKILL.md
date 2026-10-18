---
gh_issue: 1139
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1139
title: "todo-list: daily skill delegating 10x10m wake loop to handsfree"
status: In Progress
created: 2026-10-18
updated: 2026-10-18
owner: Antigravity
goal: "Add a Markdown-only daily todo-list skill that turns the preceding assistant list into an ordered checklist and delegates the 10x10m watchdog wake loop to handsfree."
doc_type: feature
complexity: 1
risk: 1
effort: 1
phases: 1
---

# GH-1139 — `todo-list` daily skill delegating 10x10m wake loop to `handsfree`

## Status

| What was just completed | What's next |
|---|---|
| Issue #1139 created, fresh task clone provisioned off `origin/development` (`4fd5dca809`), recon and rating completed. | Plan QA via Codex relay, admit accepted-start, implement `skills/2-daily/todo-list/SKILL.md` + `handsfree/SKILL.md` override clause + `ARCHITECTURE.md` index, run PDDA/skill gates, and run final Codex relay QA. |

## Observed Problem & Recon

The operator frequently instructs an agent after receiving a list of recommendations:

> Make a numbered todo list for yourself with the list you gave me above, remember the list, and execute on it in the recommended order above. Also set a timer for yourself for every 10 x 10 minutes in case one of the running tasks doesn't wake you to review and continue on next steps.

Typing this out manually across sessions is repetitive. Recon of `skills/` (`base_sha: 4fd5dca809cc4953a1a72599c3c3033dddf45d69`) shows:
- `skills/1-hourly/handsfree/SKILL.md` (added in GH-825) already owns the per-harness 10-minute native same-conversation scheduler, active-job readback, `temp/handsfree-YYYY-MM-DD-<session-token>.md` state note, and auto-cancel lifecycle across ChatGPT/Codex app, Claude Code (`/loop 10m`), and Antigravity (`/schedule`), with a default 3-hour (18-wake) cap.
- `skills/2-daily/jog/SKILL.md` manages the heavy SQLite-backed `releases.db` (`jog_queue`) + Marathon/preflight driver for repo-level GitHub issues, which is overkill for an in-session conversational todo list.
- `skills/2-daily/close-the-loop/SKILL.md` (GH-1077) is a report-only conversation sweep that does not execute items or arm timers.
- `ARCHITECTURE.md` (`## Skills Index` → `### 2-daily — A few times a day (20)`) and `test/gh778-review-code-skill.sh:45-46` / `test/gh798-status-skill.sh:42` enforce that the header count matches `find skills/2-daily -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l`.
- `utils/ci-route.sh` classifies `skills/2-daily/todo-list/SKILL.md`, `skills/1-hourly/handsfree/SKILL.md`, `ARCHITECTURE.md`, `PROJECT/**`, and `releases.*` as `route=docs` / `tier=1` (`docs_only=true`).

## Preflight Bet Check (Solution-Fit)

- **Outcome sought:** One slash-command/skill trigger (`/todo-list`) that extracts the assistant's preceding list into a numbered checklist in recommended execution order, remembers it across turns/compaction, executes items serially right away, and arms a `10 x 10 minutes` (100-minute) watchdog timer without duplicating `handsfree`'s per-harness scheduler logic.
- **Smallest viable bet:**
  1. `skills/2-daily/todo-list/SKILL.md` (Markdown-only): defines checklist extraction, dual persistence (in-chat/native task tool + gitignored `temp/todo-list-YYYY-MM-DD-<session-token>.md`), immediate serial execution in recommended order, and delegation of the 10-minute scheduler/wake/cancel mechanics to `skills/1-hourly/handsfree/SKILL.md` with two explicit subroutine overrides (`10 x 10 minutes` = 100-minute / 10-wake deadline cap, and checklist-advancement wake behavior).
  2. `skills/1-hourly/handsfree/SKILL.md`: 1-paragraph subroutine-override hook in `## Start` allowing caller skills (such as `todo-list`) to supply a tighter deadline/iteration cap (`10 x 10 minutes`) and a checklist note path (`temp/todo-list-YYYY-MM-DD-<session-token>.md`).
  3. `ARCHITECTURE.md`: add `todo-list` row under `### 2-daily — A few times a day (21)`.
- **Explicit non-goals:**
  - No Python or Bash scripts (cannot inspect prior chat turn or arm IDE/CLI in-conversation schedulers deterministically).
  - No new CI test files or `validate.sh` registry entries (`AGENTS.md` *No new tests*, GH-831).
  - No local machine skill deployment/symlinking in this task (operator selected PR-only in intake clarification).
- **Alternatives rejected:**
  - *Standalone self-contained `todo-list` duplicating scheduler rules:* rejected per `GUIDING-PRINCIPLES.md` (*The North Star* / DRY) because duplicating Codex/Claude/Antigravity scheduler instructions across two skills creates silent drift.
  - *Folding everything into `handsfree` with no `todo-list` folder:* rejected because `/todo-list` would not resolve as a direct skill slash command in IDE/CLI discovery.
- **Reversibility & Rollback:** **Easy** (pure Markdown addition + 1-line index update + small override clause in `handsfree/SKILL.md`). Rollback is a single `git revert`.

## Rating Rationale (2026-10-18)

- **Score:** `rated 65/20/50/85` (sum `220`, no operator `ovr`).
- **Priority (`65`):** Explicitly requested daily operator workflow improvement; moderate-high scheduling priority right now, no production outage.
- **Severity (`20`):** Ergonomic prompt-automation feature; absence only requires manual typing of the 2-sentence prompt (no crash or data loss).
- **Appeal (`50`):** Neutral default per policy (no explicit numeric score supplied by operator).
- **Effort/cheapness (`85`):** Quick, low-risk Markdown-only skill + index update extending `handsfree`.
- **Recurrence evidence:** Ran `gh issue list --repo HiQS-Labs/XYZ-forge --search "handsfree OR todo-list created:>=2026-09-20" --state all --limit 20` across `2026-10-04..2026-10-18` (last 14d) vs `2026-09-20..2026-10-03` (prior 14d): returned 6 matches (`#1139`, `#1081`, `#940`, `#849`, `#825`, `#727`), with 0 defect incidents in either window (`#825` was the initial `handsfree` feature addition on `2026-10-03`; the others are unrelated landing/feature issues).

## Ordered Implementation & Verification Plan

1. Register intake in `PROJECT/1-INBOX/GH-1139-TODO-LIST-SKILL.md`, park in `releases.db` (`releases roadmap add`), and record `rated 65/20/50/85` (`releases roadmap rate`). -> expect `releases roadmap list` and `releases check` to succeed.
2. Run pre-implementation Codex plan QA via `relay-xyz`. -> expect Codex `Approved` verdict on the plan.
3. Promote `PROJECT/1-INBOX/GH-1139-TODO-LIST-SKILL.md` to `PROJECT/2-WORKING/GH-1139-TODO-LIST-SKILL.md`, repoint roadmap row, and mark `--accepted-start` on the owned ledger row (`rmi-01M57TAW0AA2BSWT4BKPYND10X`). -> expect `pdda.sh issue-doc-sync` and `releases check` clean.
4. Create `skills/2-daily/todo-list/SKILL.md`, add the caller-override clause to `skills/1-hourly/handsfree/SKILL.md` (preserving all existing create/readback/cancel/no-duplicate protections and the standalone 3-hour default when not overridden), and add the `todo-list` entry (updating count `20` -> `21`) in `ARCHITECTURE.md`. -> expect `utils/pdda/pdda.sh run` and `releases check` to pass with 0 errors.
5. Provision a separate disposable verification full clone (`../XYZ-forge-gh1139-todo-list-skill-2026-10-18-verify`, never running `test/*.sh` in the working task clone per `AGENTS.md` GH-564):
   - Witness a deterministic red/green control on `bash test/gh778-review-code-skill.sh` and `bash test/gh798-status-skill.sh` in the disposable `-verify` clone by backing up `cp ARCHITECTURE.md ARCHITECTURE.md.bak`, mutating the `2-daily` header count to `20` while 21 daily skills exist on disk (expect exit 1 failure on the `2-daily count matches disk (21)` assertion), then restoring from `ARCHITECTURE.md.bak` (`mv ARCHITECTURE.md.bak ARCHITECTURE.md`) and re-running both suites green (expect exit 0).
   - Record a bounded manual acceptance walkthrough in `TESTS-RESULTS/2026-10-18+GH-1139/session-example.md` using a preceding two-item assistant list (where Item 1 launches an async task and Item 2 follows after it), verifying: (a) ordered numbered checklist extraction + dual persistence in chat/native task tool and `temp/todo-list-YYYY-MM-DD-<session-token>.md`, (b) immediate execution of Item 1 in the current turn, (c) shared note/job identity and checklist advancement (`[x]` Item 1 -> start Item 2) on a 10-minute wake when the async task did not wake the session, (d) stop cap at the earlier of 100 minutes or 10 wakes (`10 x 10 minutes`), (e) early timer cancellation upon checklist completion or hard blocker, (f) honest unarmed reporting when the current harness lacks a same-conversation scheduler, and (g) a paper red control showing that retaining the un-overridden 3-hour / 18-wake default or omitting the numbered checklist fails the acceptance check.
   - Commit `TESTS-RESULTS/2026-10-18+GH-1139/provenance.jsonl` and `TESTS-RESULTS/2026-10-18+GH-1139/session-example.md` in the task branch. -> expect committed provenance receipt and 0 PDDA errors.
6. Run final Codex relay QA via `relay-xyz`, resolve any grounded findings, push through the pre-push hook, open the PR against `development`, and retire the published task checkout and `-verify` helper clone via `merge_cleanup.py --retire-published-pr`. -> expect open PR on `development` and retired task/helper clones.
