---
gh_issue: 1341
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1341
title: "todo-list: post a closeout comment to each GitHub issue the run touched"
status: In Progress
created: 2026-11-04
updated: 2026-11-04
owner: operator
doc_type: feedback
goal: "Every /todo-list run leaves one idempotent closeout comment on each GitHub issue it touched (or renders it in chat on Tier C), so later sessions resume without re-arguing settled work."
complexity: 1
risk: 1
effort: 1
phases: 1
---

## Status

| What was just completed | What's next |
|---|---|
| Issue filed, capture parked and rated `55/35/50/90`, promoted; recon and plan below. | Codex plan QA, then the `SKILL.md` edit, docs gate and smoke read. |

## Rating

`rated 55/35/50/90` (2026-11-04). Priority above severity because the operator asked for it and every
`/todo-list` and `/start-task` run that ends without it loses context; severity is moderate (lost
context and re-argued decisions, no data loss or breakage); appeal neutral 50; cheapness high
(~25 lines of instruction text, no code). Recurrence: unknown trend (no prior incidents filed).

## Problem

`skills/2-daily/todo-list/SKILL.md` (base `2b72d715`) has sections 0–3. Run end is defined in two
places, and neither writes to GitHub:

- section 3 step 4: cancel the watchdog (Tier A), verify readback, update the note, report the
  checklist;
- the section 2 scheduled wake prompt (the text a wake actually executes): "cancel **this**
  scheduled job, verify it is inactive, and report the final checklist status".

So the findings, evidence and decisions of a run live only in a git-ignored `temp/` note and chat.

## Recon

- **Consumer path.** `~/.claude/skills/todo-list` → Deployed Skills copy generated from this file by
  Skills Army HQ (`intake.py update todo-list`, GH-672). Codex/agy discovery links point at the same
  collection. The source here is the only edit surface.
- **Gate route.** `utils/ci-route.sh` classifies `skills/2-daily/todo-list/SKILL.md` as docs (it is
  not one of the full-gate Markdown surfaces), so the gate is `utils/pdda/pdda.sh run`.
- **Existing writers.** Nothing in the repo posts per-issue run summaries today. Issue closing and
  labels are owned by merge-cleanup and `wave_reconcile.py`; this step must not overlap them.
- **Prior art.** `prior_art_recon.py --query "todo-list closeout"`: no open or merged PRs, no
  matching roadmap rows.
- **gh primitives (no new helper):** list comments with
  `gh api repos/O/R/issues/N/comments --paginate`; create with `gh issue comment N -R O/R
  --body-file F` (prints the URL); edit with `gh api -X PATCH repos/O/R/issues/comments/ID
  -F body=@F`.

## Plan

Smallest bet: a new `## 4. Close the loop on GitHub` section (~20 lines) plus two pointer edits in
todo-list, and a ~5-line Step 9 bullet in start-task that reuses it.
Non-goals: no script, no helper, no test, no closing/relabelling, no change to `handsfree`.
Alternative rejected: leaving it to merge-cleanup — it only runs on landing, misses runs that end
without a PR, and has no access to the run's decisions.

1. Section 3 step 4 and the section 2 wake prompt: after cancelling the job (or on a halt), run
   section 4 before the final report.
2. New section 4:
   - Scope: issues the run touched (named by an item, or the work produced a PR/commit for it),
     as `owner/repo#N`; none → one line "closeout: no issues touched" and stop.
   - Body per issue: marker `<!-- todo-list closeout: <note-path> -->`, then done (PR/SHA links),
     evidence (test/CI results or manual checks with receipt location; unverified said so),
     decisions and why, still open, next step. Facts only; no credentials or absolute local paths
     beyond the note's repo-relative path.
   - Idempotency: look up a comment containing the marker (literal match, fully paginated); edit
     it if found, else create one. Only a successful lookup with no match permits a create. A failed
     lookup, post or edit is reported as `unposted` (or `unknown` when a write may have landed), the
     rendered text is kept for paste or a later rerun, and no URL is claimed; no blind retry.
   - Tier A/B: post with `gh` and record each comment URL in the note; Tier B without a working
     `gh` falls back to Tier C. Tier C: render each comment in chat, marked `(paste to owner/repo#N)`,
     with marker `chat <start timestamp>`.
   - Never close, reopen or relabel; report the comment URLs (or "rendered for paste") in the
     final checklist.
   - Nested runs: an issue that a `/start-task` inside this run already closed out (its
     `start-task closeout` marker) gets no second comment; list that comment's URL instead.
3. Frontmatter `description`: add the closeout.
4. `skills/1-hourly/start-task/SKILL.md` Step 9 (scope added 2026-11-04, operator; see the issue
   comment): after the PR is verified ready, or when a group ends blocked/deferred, post one
   closeout comment per tracked issue using todo-list §4's procedure with marker
   `<!-- start-task closeout: <branch> -->` (PR and head SHA, QA verdicts, gate results, plan
   decisions, blockers). Next step is "awaiting merge" only for a verified ready PR; a group that
   stopped earlier (plan QA unresolved, blocked gate, deferred) states its actual blocker and resume
   action, and runs the closeout at that stop rather than only on reaching Step 9. Defined once in
   todo-list §4; start-task only names its marker and timing (DRY). Never closes or relabels. Report
   the URL in the handoff. Gate route: docs (`utils/ci-route.sh:336-343` escalates merge-cleanup,
   relay-automation and relay-xyz, not these two files).
5. CHANGELOG entry.

## Verification (no new tests, GH-831)

- Docs gate: `utils/pdda/pdda.sh run` zero errors.
- Smoke (manual, `TESTS-RESULTS/2026-11-04+GH-1341/`): read section 4 from the clone's `SKILL.md`
  and, read-only, run the marker lookup against this issue (main path: no marker → create branch),
  then the same lookup after a closeout exists (adjacent path: rerun → edit branch), recording exit
  status and the matched marker/ID. The empty lookup is a negative case (absent → create), not a red
  control; a failed lookup (exit ≠ 0) must select `unposted`, never create.

## Rollback

Revert the commit; the deployed copy follows on the next `intake.py update todo-list`. Posted
comments stay (they are ordinary comments; the marker identifies them).
