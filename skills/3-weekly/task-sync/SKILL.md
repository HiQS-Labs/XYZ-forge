---
name: task-sync
description: >-
  Unified IDE task-list grooming for XYZ Forge: one central core with per-IDE adapters
  (ZCode, Antigravity) that date-stamp task titles with the task's own last-activity
  mm-dd, write last-action descriptions, and manage pins under one safety contract.
  Use when asked to groom/sync IDE task lists, set up the 15-minute heartbeat, install
  task-sync via Skills Army HQ, or run the health doctor.
when_to_use: The operator wants ZCode and/or Antigravity task titles date-stamped or
  re-summarized, tasks pinned, the heartbeat installed or repointed, or the doctor run.
license: Same as this repository.
metadata:
  repo: XYZ-forge
  tier: 3-weekly
---

# task-sync — unified IDE task-list grooming (GH-896)

One core, thin per-IDE adapters, one CLI, one heartbeat. Canonical home:
`skills/3-weekly/task-sync/` (Skills Army HQ-deployable). Ports the relay-proven
behavior of `utils/zcode/task-stamp` (PR #893) and `utils/skills/agy-task-sync`
(PR #894); both originals are superseded after soak, not modified.

## Semantics (operator-locked)

- **Stamp = the task's own last-activity date** (mm-dd, local). A task worked on
  09-29 and swept on 09-30 keeps `09-29` until it is touched again; continuing a
  conversation moves the stamp on the next heartbeat. Never wall-clock, never the
  original start date.
- **Pins are adapter-declared.** ZCode derives pins from the activity window
  (`--pin-hours`, default 24) and writes them. Antigravity is mirror-app-owned:
  `pinned_conversations_order` in `app_storage.json` is ground truth, mirrored to
  `annotations/*.pbtxt`; `--auto-pin` opts into derived pin writes (gated, backed
  up, atomic).
- **Descriptions.** ZCode raw prompt titles become agent-written ≤8-word last-action
  summaries (via `needs_summary`). Antigravity previews are extracted directly from
  session transcripts (`[Tool]`/`[Response]`/`[User]`).

## Safety contract (core-enforced)

- Dry-run by default; `--apply` commits.
- Schema-validate before any write; abort with a named, clear message on drift.
  Antigravity requires an explicitly present pin list; missing state is not empty.
- Write only on change — re-runs are no-ops.
- **A failed or empty-authoritative read never triggers a destructive write.**
  An unreadable `app_storage.json` aborts the whole Antigravity sweep (the
  superseded original stripped every annotation pin on this path — witnessed;
  the red control lives in the GH-896 TESTS-RESULTS receipt).
- Antigravity writes are gated while the app is running (fail closed: an
  undetectable app state counts as running). The Electron store is backed up
  (`.bak-<ts>`) and replaced via temp-file rename.
- One IDE's store failure never blocks the other; each IDE section carries its
  own error, and any adapter error exits nonzero (3).

## Commands

```bash
S=skills/3-weekly/task-sync/scripts/task_sync.py

python3 $S --doctor              # health: stores, schema, app gate, heartbeat receipt
python3 $S                       # dry-run both IDEs (merged JSON report)
python3 $S --apply               # the heartbeat invocation
python3 $S --ide zcode --apply   # one IDE only
python3 $S --set-title <id> "Reviewed LTVera PR 648, flagged changelog"  # per-IDE; not found is reported per IDE
python3 $S --set-title <agy-conv-id> "Ran validate.sh checks" --ide agy --apply --auto-pin
```

Probe/CI-safe store overrides (never point these at live stores from probes):
`--zcode-db PATH` (ZCode task index copy), `--agy-root PATH` (Antigravity fixture
root; its electron store is `<root>/app_storage.json`).

Doctor exit codes: `0` all green · `3` any red (missing store, schema drift,
app running → Agy writes gated). `heartbeat: pending — no receipt yet` is a
non-red state (nothing has applied on this machine yet); the receipt lives at
`~/.cache/task-sync/last-run.json` (machine-local, atomically written when an apply
sweep succeeds for at least one IDE, retaining errors from the other IDE).

## The heartbeat (single scheduler)

One 15-minute ZCode automation runs `task_sync.py --apply --ide zcode,agy` in this
workspace; the daemon/launchd/in-session `/schedule` options of the superseded
originals are dropped. The installer SOP below creates or repoints it. The
automation's own task is automation-owned and skipped by the ZCode adapter — no
self-restamping loop.

## Install SOP (this skill is the installer)

1. **Doctor first:** `python3 $S --doctor` — all stores must be green or
   pending-receipt before installing.
2. **Vendor via Skills Army HQ** (canonical source = this repo's skills tree):
   `intake.py add task-sync --source <forge>/skills/3-weekly/task-sync` (preview,
   then `--apply`) into the Deployed Skills collection, then `sync.py` to this
   device's app targets (ZCode `~/.zcode/skills/task-sync`, Antigravity
   `~/.gemini/antigravity/skills/task-sync`, `~/.gemini/antigravity-cli/skills/`
   when present). Verify each symlink resolves into the collection and the app's
   skill list picks it up.
3. **Heartbeat:** create or repoint the 15-minute ZCode automation (CronCreate,
   `intervalUnit: minute`, `interval: 15`) with the prompt: run
   `python3 <collection>/task-sync/scripts/task_sync.py --apply --ide zcode,agy`,
   then for each `needs_summary` entry in the ZCode section read the task's
   `searchable_text`, craft a ≤8-word last-action summary, apply
   `--ide zcode --apply --set-title <task_id> "<summary>"`, touch nothing else, and report one line
   (`task-sync: renamed=N pinned=M summarized=K`).
4. **Doctor again:** green (or Agy red only because the app is open — that gate
   clears on the next tick after the app closes).
5. **Retirement (post-soak):** after a soak period, retire
   `utils/zcode/task-stamp/` and `utils/skills/agy-task-sync/` via a follow-up PR,
   and close PRs #893/#894 as superseded by this skill.

## Caveats

- **App-overwrites-active-titles:** a running IDE can rewrite its own active
  session's title; the next heartbeat re-applies the stamp. Completed tasks stick.
- **UI refresh:** stores are the source of truth; an app may not re-render its
  task list until it refetches (switch workspace or restart).
- **Agy write gating:** while Antigravity runs, its adapter refuses writes
  (heartbeat reports the error and continues with ZCode); the gate clears once
  the app closes.
- **Discovery:** the skill is HQ-deployed by symlink; if it stops appearing,
  check the collection link (`ls -l ~/.zcode/skills/task-sync`).

## Verification note (GH-831)

No new `test/` suites — this skill is verified by the functional probe battery,
doctor fault injection, the A3 red control against the superseded original, one
full `validate.sh` on the final commit, and the TESTS-RESULTS receipt with
provenance (see `TESTS-RESULTS/2026-09-30+GH-896/`).
