---
name: task-stamp
description: Groom the ZCode app task list — stamp task titles with a U.S. mm-dd date, replace raw prompt titles with a short description of the task's last action, and pin recently-active tasks. Use when asked to rename/stamp task titles, refresh the task list, add tasks to pinned, or set up the recurring task-refresh automation.
when_to_use: The operator wants ZCode task titles date-stamped or re-summarized, tasks auto-pinned, or the 15-minute task refresh set up or run.
license: Same as this repository.
metadata:
  repo: XYZ-forge
---

# task-stamp — ZCode task-list grooming

Keeps the ZCode app's task list matching the operator's convention:
`MM-DD <short description of the task's last action>`, with recently-active
tasks pinned. Real files live in `utils/zcode/task-stamp/`; the `.zcode/skills/
task-stamp` symlink (same pattern the repo uses for relay-xyz in
`~/.claude/skills/`) makes ZCode discover this skill in-workspace without
duplicating files. `.zcode/` (not `.agents/`) keeps it ZCode-only.

## How it works

The ZCode app indexes its task list in `~/.zcode/v2/tasks-index.sqlite`
(columns `title`, `title_overridden`, `pinned`, `meta_json`; tables
`task_groups` / `task_group_members` for named pin groups). The sweep script
writes there directly with short WAL transactions — safe while the app is
open. There is no description field in the index, so the "description with
the last action" **is the title's base**: after the `MM-DD ` stamp.

```bash
# Report what would change (always start here)
python3 utils/zcode/task-stamp/scripts/sweep_tasks.py --sweep --dry-run

# Apply: stamp titles updated in the last 24h + pin tasks active in 24h
python3 utils/zcode/task-stamp/scripts/sweep_tasks.py --sweep

# One-time backfill of older tasks (stamps from each task's own last
# activity date; does not pin history)
python3 utils/zcode/task-stamp/scripts/sweep_tasks.py --sweep --all --no-pin

# Replace a raw prompt title with a reviewed summary (agent-written)
python3 utils/zcode/task-stamp/scripts/sweep_tasks.py \
  --set-title sess_<uuid> "Fix relay driver lock parity"
```

Useful flags: `--hours N` (sweep window, default 24) · `--pin-hours N`
(pin window, default 24) · `--no-pin` · `--unpin-days N` (unpin stale pins)
· `--include-cron` (default skips automation-owned tasks — their titles
come from the automation and the sweep's own runs must not be restamped)
· `--group NAME` (also add pinned-window tasks to a named task group;
a task can belong to only one group) · `--db PATH` (test against a copy).

## Agent workflow (the "refresh")

1. Run `--sweep --dry-run`, review the JSON report.
2. Run `--sweep` for real.
3. For each entry in the report's `needs_summary` (titles still raw prompt
   text), craft a ≤8-word present-tense description of what the task last
   did — read its `searchable_text` from the DB if needed — then apply with
   `--set-title <task_id> "<description>"` (the stamp is auto-prepended).
4. Report one line: renamed / pinned / summarized counts.

## Recurring refresh (every 15 minutes)

Create the automation with the CronCreate tool (runs in this workspace):

- **Schedule:** every 15 minutes (`intervalUnit: minute`, `interval: 15`).
- **Prompt:** run the sweep script by absolute path, then for any
  `needs_summary` entries craft and apply summaries per the workflow above,
  touch nothing else, and finish with a one-line count report.

The automation's own task is automation-owned, so the sweep skips it —
no self-restamping loop.

## Caveats (read before debugging)

- **UI refresh:** the app may not re-render the task list until it next
  refetches (switch workspace or restart the app). The DB is the source of
  truth; rows verify with plain `sqlite3`.
- **Active sessions can revert:** the app rewrites the title of a session
  it is actively running. The sweep re-applies the stamp on the next pass;
  completed tasks stick.
- **Schema drift:** the script validates expected columns and aborts with
  a clear message if the app changes its index shape.
- **Timestamps are ms epoch local time; the stamp comes from the task's own
  `updated_at`**, never from wall-clock at sweep time — backfills are correct.
- **Discovery:** skill discovery follows the `.zcode/skills/task-stamp`
  symlink. If the skill stops appearing in XYZ-forge sessions, check the
  symlink is intact (`ls -l .zcode/skills/`).

## Verification note (GH-831 test policy)

This is agent-IDE tooling under `utils/`; no `test/` suite is added for it
(a new suite in the diff would itself be a finding). Verify by running the
script against a **copy** of the DB first (`--db /tmp/copy.sqlite`), then a
live `--dry-run`, then a live sweep — record outputs in the PR.
