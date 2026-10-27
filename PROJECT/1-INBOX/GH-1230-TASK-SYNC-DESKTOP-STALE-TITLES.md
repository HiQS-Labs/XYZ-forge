---
title: "task-sync Desktop: titles go stale (user-set titles, >24h rows, busy sessions)"
status: Inbox
created: 2026-10-26
updated: 2026-10-26
owner: claude
gh_issue: 1230
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1230
doc_type: bug
complexity: 2
risk: 2
effort: 2
phases: 1
non_goals:
  - An approval queue or any step that needs the operator (operator, 2026-10-26)
  - Pins (GH-1196 behaviour unchanged), other IDEs, CLIO
  - Add test/ suites (AGENTS.md, GH-831)
related:
  - GH-1191
  - GH-1196
goal: >
  Every non-archived Claude Desktop session title on a device carries its own
  last-activity mm-dd within one sweep interval, including busy sessions,
  sessions older than a day and titles the operator typed, with no manual step.
---

# GH-1230 - task-sync Desktop: titles go stale

## Status

| What was just completed | What's next |
|---|---|
| Issue filed; deciding probe run; plan drafted | Codex plan QA |

## Key concepts

- The scheduled task is the durable clock, but its sessions can't overwrite a title the operator typed. An open interactive session can.
- A stamp is correct when its mm-dd equals the session's own last activity on this device's local date. Age and busyness don't change that.
- Scheduled runs are themselves sessions, so the sweep's inventory fills up with them.

## Scope

Operator, 2026-10-26: "It should be working without any manual intervention", then "Yes, plan the fixes."

| # | Requirement | Acceptance check |
|---|---|---|
| R1 | Titles the operator typed are re-stamped automatically | Live: a `titleSource: user` row is renamed with no operator turn and no decline |
| R2 | A wrong stamp is corrected whatever the session's age | Probe: a row active 3 days ago with a wrong stamp is proposed |
| R3 | Busy (running) sessions are stamped | Probe: a running row with a wrong stamp is proposed; live: a running session renamed and the title persists after its turn ends |
| R4 | The inventory stays complete as run sessions accumulate | Live: the sweep's snapshot holds every non-archived session; the scheduled task's own finished runs older than one day are archived |
| R5 | No approval queue, no operator step | The procedure has no "pending approval" state; declines are retried automatically by the sweeper |

## Evidence (one device, 2026-10-26; sanitized)

| Fact | Source |
|---|---|
| All 53 scheduled runs ran with `permissionMode: bypassPermissions` | each run's app session record |
| A scheduled run reported `declined=1` for a user-set title | run summary, 2026-10-26 |
| The stale example's last activity was ~25 h before the run, so the 24 h window excluded it | the run's saved snapshot |
| Rename of a **running** session persisted, `titleSource: tool` | live, 2026-10-26 (this session renamed itself mid-turn) |
| **Deciding probe:** a `CronCreate` one-shot wake in an open interactive bypass session, with no operator turn, renamed a `titleSource: user` title; `titleSource` became `tool` | `~/.cache/task-sync/probe-wake-rename.txt` on the device |
| 64 sessions listed, mostly scheduled runs (one new one per run) | `list_sessions(limit=200)` |

## Recon (base `08c2a2fb`)

| Seam | Location | Finding |
|---|---|---|
| Window and busy skip | `skills/3-weekly/task-sync/scripts/adapters/claude.py`, `ClaudeDesktopAdapter.sweep` | `cutoff = captured - hours*3600`; titles skip `running or at < cutoff`. Pins use `pin_cutoff` separately (GH-1196). |
| Recheck | `SKILL.md` "Claude Desktop (GH-1191)", procedure step 3 | Requires `isRunning: false` and the **same** `lastActivityAt`, which a running row never satisfies. |
| Inventory | procedure step 1 and the per-device prompt | `list_sessions(limit=100)`. |
| Declines | procedure step 4 | "a decline is a skip": the source of the stale user-set titles. |
| Scheduler | per-device task prompt (private recipe) | Titles only, every 30 min. |

## Plan

0. **Probe the forwarding path first** (decides step 3's shape; no code).
   - From a scheduled-task run, send a sweep request to an open interactive bypass session: once with `SendMessage`, once with `mcp__ccd_session_mgmt__send_message`.
   - In the receiving session, rename a `titleSource: user` title.
   - Record which route renames without a decline, as the GH-1230 receipt `forward-probe.md`.
   - If neither does, stop and bring the result back to the operator. The fallback is step 3b, which isn't fully automatic across app restarts.

1. **Planner** (`ClaudeDesktopAdapter.sweep`):
   - **Running rows:** they're eligible for titles. The existing fail-closed rules stay: non-literal `isArchived` or non-boolean `isRunning` is skipped; a running row with missing or bad activity is skipped, an idle one aborts.
   - **No age window:** drop the window for titles, so every row is proposed when its stamp differs from its activity date. `--hours` keeps applying to every other adapter. For `claude-desktop` it becomes a no-op for titles, and the help text says so.
   - **Pins** are unchanged (`pin_hours`).
   - **No change** to report shape or CLI surface.

2. **`SKILL.md` Desktop procedure:**
   - **Step 1:** `list_sessions(limit=500)`. If the result has exactly `limit` rows, treat the inventory as possibly truncated and say so in the report line.
   - **Recheck (step 3):** same title, not archived, not self, and the **local date** of the current `lastActivityAt` equals the proposal's date. The exact timestamp and `isRunning: false` are no longer required, because a running session's activity moves.
   - **Decline:** see step 3.
   - Remove "Undo only while…" wording that assumes an idle row. Undo itself is unchanged.

3. **Sweeper (R1, R5).**
   - **3a (if step 0 finds a working route):** the scheduled task keeps sweeping every 30 min. When `set_session_title` declines, it forwards the declined ids, with old and new titles, to the device's **sweeper session** over the probed route. The sweeper re-runs the recheck and renames.
     - The sweeper is one named, pinned interactive Desktop session in bypass mode. Its standing instruction comes from the operator once, at setup, and is recorded in the private recipe.
     - That rename flips the title to `titleSource: tool`, so later runs re-stamp it directly.
     - If the sweeper is missing or doesn't reply, the run reports `forward_failed=N`. It isn't silent and isn't an error.
   - **3b (fallback only):** the sweeper session arms its own 30-minute `CronCreate` loop, which the probe showed can rename user-set titles. It is session-only and expires after 7 days, so it needs re-arming. That's why 3b isn't the primary path.

4. **Run-session hygiene (R4).** At the end of each run, the scheduled task archives its **own** earlier run sessions: those whose `get_session` shows this task's `scheduledTaskId`, not running, finished more than 24 h ago.
   - It never touches any other session.
   - Archive, not delete, so it's reversible with `unarchive_session`.
   - Pins already skip these sessions (GH-1196).

5. **Probes** under `TESTS-RESULTS/2026-10-26+GH-1230/`:
   - a running row with a wrong stamp → proposed;
   - an idle row active 3 days ago with a wrong stamp → proposed;
   - a correct stamp on an old row → not proposed;
   - the fail-closed rules unchanged (archived/self/non-boolean running/bad activity);
   - pins unchanged (the GH-1196 battery passes).

   The GH-1191 battery's "running skipped" and "outside window" probes change by design. Re-run it and list those expected deltas, each with its reason. Red control: restore the window and watch the old-row probe fail.

6. **Live:** on the operator's device, with the step 0 route:
   - a typed title renamed by the forward path (R1);
   - a running session renamed and the title still there after its turn ends (R3);
   - one run archiving its old run sessions, and the snapshot holding every non-archived session (R4).

7. **Gate:** `utils/ci-route.sh pull_request` with the changed paths on stdin, then CHANGELOG. The private per-device recipe (task prompt, sweeper setup) is updated after merge, through Skills Army HQ publication, with no hand edits.

## Bet check

- **Outcome:** no stale stamp survives more than one sweep interval, with zero operator steps.
- **Smallest bet:** drop two skips in the existing loop, loosen one recheck, add one forwarding hop. No new adapter, CLI flag or writer: `set_session_title` stays the only title writer, and archiving is limited to the task's own runs.
- **Alternatives rejected:**
  - writing the app's session JSON directly (unsupported, and the app owns it);
  - an approval list (operator rejected it);
  - stamping today's date instead of activity (wrong semantics).
- **Rollback:** revert the PR. Renames are in the receipt; archived runs can be unarchived.

## Risks

- **First run after the window drop renames many old sessions at once.** Expected and correct: each gets its own activity date.
- **The forwarding route may hold peer messages for approval if the modes differ.** Both sides run in bypass mode; step 0 proves the route.
- **The sweeper session is a single point.** If it's gone, renames of typed titles stop and `forward_failed` reports it. Everything else keeps working.

## Rating rationale (2026-10-26)

`rated 70/40/45/60`.
- `pri` 70: the operator expects zero-touch stamps and observed stale ones.
- `sev` 40: wrong dates in the sidebar mislead, but no data is lost.
- `appeal` 45.
- `effort` 60: small loop change plus one probe-gated forwarding hop.
