---
name: close-the-loop
description: >-
  Review the current session's available conversation for requested actions or agreed
  follow-ups that were sidetracked, especially documentation and GitHub issue/PR updates.
  Return a numbered list of possible orphaned tasks with evidence and next actions.
  Use for /close-the-loop, "what did we leave unfinished", or "check this conversation
  for forgotten follow-ups". Report-only; not a repository-wide backlog or device scan.
---

# Close the loop

Find commitments that may have fallen through the cracks when this conversation changed
subjects. Return candidates for follow-up; do not execute them or create tracking records.

## Review

Read the available conversation in order, including any continuation summary. Briefly state
its scope and disclose missing/compacted history; never imply access to unavailable turns.
Do not fetch other sessions, prompt logs or device-wide telemetry unless asked.

Trace each requested action, accepted decision and promised follow-up forward to its latest
outcome. Pay particular attention to docs, issue/PR bodies or comments, verification receipts,
and agreed implementation, merge or deployment follow-ups that were left behind after a pivot.
An assistant's suggestion or a brainstorm is not an agreed task. Respect later corrections,
cancellations, superseding decisions and deliberate deferrals; do not resurrect them unless
their stated revisit condition now applies. An intentional handoff is not forgotten work.

Check only directly relevant, named artifacts using available read-only tools. Bind issue/PR
numbers to the correct repository. Separate observed status from session recollection and
inference; a failed or unavailable query means unverified, not complete or absent. Do not run
tests, start workflows, edit files or post to GitHub to establish the report.

An open issue or unmerged PR alone is not an orphan. A merged PR can still have an explicitly
requested doc or deployment follow-up. Look for evidence that the obligation remains and
lacks a clear next action or handoff; do not list the whole backlog or every normal pending PR.
Deduplicate the same underlying follow-up while preserving distinct acceptance criteria.

## Report

Return one numbered list, ordered by explicit user priority, consequences and dependencies.
For each candidate give a concrete action, a short quote or faithful paraphrase locating its
conversation evidence, the target link/path when known, status (confirmed pending, possible,
or unverified), and the smallest next step. Name an owner only when the conversation does.
Keep items concise and frame uncertainty as uncertainty, not defect severity or a new blocker.

Example shape:
1. **Update the rollout issue** — Earlier request: “record the rollback result”; no later
   completion found. Target: <issue>. Status: unverified. Next: inspect its latest comments.

If none qualify, say "No likely orphaned follow-ups found in the available conversation."
Do not manufacture candidates to fill the list. Keep any visibility/access limitation visible.

Stop after the report. This invocation does not authorize executing the candidates, creating
issues, changing PR status, merging or deploying. If the user selects items or already requests
action alongside the sweep, honor that scope and existing authorization, recheck current state,
and reuse the existing issues/docs/workflows rather than creating duplicates.
