---
name: todo-list
description: >-
  Turn the recommendations or action list from the preceding assistant response into a numbered
  todo list in the recommended execution order, persist it across turns and context compaction,
  execute items serially right away, and arm a 10 x 10-minute (100-minute / 10-wake) watchdog
  timer via handsfree in case a running task does not wake the session. Degrades by tier:
  full in Claude Code; file note without timer in Claude Desktop Cowork; chat-only state block
  in plain Claude Desktop chat. At the end (or a halt) it leaves one idempotent closeout comment
  on each GitHub issue the run touched (rendered for paste in plain chat). Use for /todo-list,
  "todo-list", or "make a numbered todo list with the list you gave me above".
---

# Todo-list

Execute the operator's standing directive without making them re-type it:

> Make a numbered todo list for yourself with the list you gave me above, remember the list,
> and execute on it in the recommended order above. Also set a timer for yourself for every
> 10 x 10 minutes in case one of the running tasks doesn't wake you to review and continue on
> next steps.

## 0. Detect the harness and pick a tier

Decide the tier **once, at the start**, from live capability, never from the app's name alone.
Record the tier in the resume note (or the chat state block for Tier C). The Claude Code
behaviour (Tier A) is the full contract; the other tiers degrade only what the harness cannot
do and keep everything else identical.

| Tier | Harness signal | Resume note | Watchdog | Native task list |
| --- | --- | --- | --- | --- |
| **A** | File tools on a workspace **and** a same-conversation scheduler that passes `handsfree`'s create/readback/cancel check (Claude Code CLI, the desktop Code tab, IDE extensions). | `temp/todo-list-...md` in the repo | armed, `10 x 10m` | yes |
| **B** | File tools on a workspace folder, but no same-conversation scheduler (Claude Desktop **Cowork**, Codex CLI, Antigravity/Gemini CLI, any harness whose scheduled tasks start separate runs). | `temp/todo-list-...md` in the workspace folder (create `temp/` if absent; a plain folder is fine when it is not a git repo) | `scheduler: unarmed (<reason>)` | if present |
| **C** | No file tools at all (plain Claude Desktop / claude.ai chat, mobile). | **chat state block** (below) | unarmed | none |

Tier rules:

- **Tier A** runs sections 1-3 exactly as written.
- **Tier B** runs sections 1-3 with the note at the workspace root instead of "the current
  repo", skips arming, and states once: "No same-conversation timer here; say `continue` or
  `/todo-list` to resume if a background task does not wake me." Claude Desktop scheduled
  tasks (routines) start separate runs and do not return to this conversation, so they never
  count as the watchdog; offer one only as a separate opt-in per `handsfree`.
- **Tier C** replaces the file note with a **chat state block**: a fenced block titled
  `TODO-LIST STATE` carrying the same fields the note would (start time, deadline, wake
  counter, `scheduler: unarmed (no file/scheduler tools)`, tier, the full numbered checklist,
  active item, awaited evidence). Re-emit the **whole** block at the end of every turn in which
  any field changes, so the latest copy survives context compaction and can be pasted into a
  new chat (or into a Tier A/B session as the note body) to resume. Never store credentials in
  it. Tell the user once that there is no timer and no file, and that `continue` resumes.
- Never pretend a higher tier: no timer claim without the `handsfree` receipt, no "wrote the
  note" without a file tool result. If a capability appears mid-run (for example a folder is
  granted), promote the tier, write the note from the chat block, and say so in one line.

## 1. Extract and remember the numbered list

1. Read the preceding assistant turn (and any explicit user reordering or filtering in the
   current turn) and extract the actionable items in the **recommended execution order**.
   Exclude items the user explicitly cancelled, deferred, or marked out of scope. If no clear
   prior list exists in the conversation, ask the user which items to include before arming a
   timer or mutating state.
2. Render the **numbered todo list (`1..N`)** at the top of your response, with each item's
   concise title, target/acceptance check, and status (`[ ]` pending, `[-]` in flight,
   `[x]` verified complete, `[!]` blocked).
3. Persist the list in two places so context compaction and 10-minute wakes never lose track:
   - **In-conversation state:** update the session's native todo/task tool when available and
     echo checklist transitions in chat on material progress.
   - **Workspace resume note (Tier A/B; Tier C uses the chat state block instead):** write one
     unique, non-overwriting `temp/todo-list-YYYY-MM-DD-<session-token>.md` file in the current
     repo or workspace folder (`temp/` is gitignored here). Include:
     - Start timestamp, hard deadline (`start + 100 minutes`), and `10 x 10m` wake counter
       (`wake 0 / 10`).
     - Scheduler/job identity and exact cancellation method (from `handsfree` below).
     - The full numbered `[ ] / [-] / [x] / [!]` checklist in recommended order, the currently
       active item number, awaited task/run/command identity, and latest observed evidence.
     - Never store credentials in the note.

## 2. Arm the `10 x 10 minutes` watchdog via `handsfree`

Delegate all scheduler capability checks, job creation, active-job readback, and teardown
rules to [`handsfree`](https://github.com/HiQS-Labs/XYZ-forge/blob/development/skills/1-hourly/handsfree/SKILL.md)
(`skills/1-hourly/handsfree/SKILL.md` in this repo) with three subroutine overrides:

1. **Window & iteration cap override (`10 x 10 minutes`):** Set the hard deadline to **100
   minutes** from start and cap recurring 10-minute wakes at **10 iterations** (whichever is
   reached first), instead of `handsfree`'s standalone 3-hour / 18-wake default.
2. **Shared state-note override:** Point the scheduled wake prompt at
   `temp/todo-list-YYYY-MM-DD-<session-token>.md` (one shared note and one job identity; never
   create a second parallel note or duplicate timer).
3. **Checklist wake-action override:** Use this scheduled wake prompt (substituting the exact
   note path and job ID):

   > Resume the authorized numbered todo list in `temp/todo-list-...md` in this conversation.
   > Check the hard deadline (`100 minutes` / `10 wakes` max) first. Inspect the active
   > numbered item (`[-]`) and its live task/command/CI output. If the active item finished and
   > its check passed, mark it `[x]` in the note and chat, then immediately start the next
   > `[ ]` item in recommended order. If all items are `[x]`, or a hard blocker / user decision
   > / user stop / `10 x 10m` cap is reached, cancel **this** scheduled job, verify it is
   > inactive, run section 4 (close the loop on GitHub), and report the final checklist status.
   > Never mark an item `[x]` on pending, empty, or unverified output.

If the current harness lacks a verified native same-conversation scheduler (per `handsfree`'s
create/readback/cancel check; Tier B and C above), leave the wake unarmed, record
`scheduler: unarmed (<reason>)` in `temp/todo-list-...md` (or the chat state block), tell the
user plainly, and continue executing the numbered list now.

## 3. Execute immediately in recommended order

Below, "the note" means `temp/todo-list-YYYY-MM-DD-<session-token>.md` in Tier A/B and the
chat state block in Tier C.

1. Do **not** wait for the first 10-minute wake to start work. Immediately mark item `1` as
   `[-]` in the note and begin executing item `1` in the current turn.
2. Whenever an item completes synchronously in the current turn (or wakes the agent via normal
   reactive background-task completion before the 10-minute timer fires), verify its outcome,
   mark it `[x]` in the note and native task list, and advance immediately to item `k + 1`.
3. When an item launches an asynchronous command, review, or CI run that leaves nothing else
   actionable in the current turn, record the exact task/run ID in the note and end the turn
   so either the task's reactive completion wakeup or the next 10-minute watchdog wake resumes
   execution. In Tier B/C there is no watchdog: end the turn with the awaited identity visible
   and ask the user to say `continue` when it finishes.
4. As soon as the final item `N` is verified `[x]` (or execution halts on a hard blocker,
   required user decision, or the earlier of 100 minutes / 10 wakes), **cancel the scheduled
   job** in the same conversation (Tier A only), verify readback confirms it is inactive/absent
   per `handsfree`, update the note, run section 4, and report the completed numbered checklist.

## 4. Close the loop on GitHub

Run this once whenever section 3 step 4 ends the run (all items `[x]`, a halt, or the cap), before
the final report, so a later session resumes from the issue instead of re-arguing settled work.

1. **Which issues:** only those the run touched: an item named it, or the work produced a PR or
   commit for it. Write each as `owner/repo#N`. None touched: report `closeout: no issues touched`
   and stop. An issue a `/start-task` in this run already closed out (its `start-task closeout`
   marker) gets no second comment; list that comment's URL instead.
2. **What to post:** one comment per issue. First line is the marker
   `<!-- todo-list closeout: <note-path> -->`, with the note's repo-relative `temp/todo-list-...md`
   path (Tier C: `chat <start timestamp>` in its place). Then short sections: **Done** (PR and commit links with SHAs), **Evidence** (test/CI
   results, or manual checks and where their receipt lives), **Decisions** (what was decided and
   why), **Still open**, **Next step**. State only what this run observed; label anything
   unverified as unverified. No credentials, transcripts or absolute local paths.
3. **Post once, edit on rerun (Tier A/B):** write the body to a temp file, then look for an
   existing comment that starts with the exact marker (a comment merely quoting it does not count):
   `gh api repos/OWNER/REPO/issues/N/comments --paginate --jq '.[] | select(.body | startswith("<marker>")) | .id'`.
   If it returns an id, update it with
   `gh api -X PATCH repos/OWNER/REPO/issues/comments/ID -F body=@FILE`; otherwise create one with
   `gh issue comment N -R OWNER/REPO --body-file FILE`. Never use `--edit-last`. Only a lookup
   that exits 0 with no match permits a create. A failed lookup, create or edit is `unposted` (or
   `unknown` when the write may have landed): keep the rendered text for paste or a later rerun,
   claim no URL, do not retry blindly. Record each comment URL in the note. Tier B without a
   working, authenticated `gh` falls back to Tier C.
4. **Tier C:** render each comment in chat under `paste to owner/repo#N`, ready to copy.
5. Never close, reopen or relabel an issue here; merge-cleanup and reconcile own issue state. List
   each comment URL (or `rendered for paste`) in the final checklist report.
