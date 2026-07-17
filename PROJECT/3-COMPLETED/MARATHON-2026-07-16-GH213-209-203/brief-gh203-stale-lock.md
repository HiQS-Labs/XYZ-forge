---
title: "Phase brief: GH-203 stale index.lock preflight warning (marathon builder input, not a capture doc)"
status: consumed 2026-07-16 (phase built and Approved — see PROJECT/2-WORKING/GH-203-STALE-INDEX-LOCK-PREFLIGHT.md)
created: 2026-07-16
updated: 2026-07-16
owner: noel
goal: >
  Phase-brief input consumed by relay-automation/marathon-drive.sh for the gh203 phase — not itself
  an active-doc capture; the canonical capture doc is GH-203-STALE-INDEX-LOCK-PREFLIGHT.md one level up.
roadmap_exempt: true
---

## Status

| What was just completed | What's next |
|---|---|
| Phase built and Approved 2026-07-16 (see the canonical capture doc's own Status table). | None — this brief's job (feeding the marathon builder turn) is done. |

## Phase: GH-203 — stale `.git/index.lock` preflight warning in swarm-preflight.sh

Full context: [GH-203-STALE-INDEX-LOCK-PREFLIGHT.md](../GH-203-STALE-INDEX-LOCK-PREFLIGHT.md).
GitHub issue: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/203

### Important scope boundary — read this first

The GitHub issue offers four fix options. Build ONLY the non-destructive, non-tick-internals one:

- ~~Reap on scope teardown (tick's release/done/reap/circuitBreak paths auto-clearing the lock)~~ —
  **OUT OF SCOPE.** Touches tick coordination internals.
- ~~Wrap git writes (a trap in agent git-write helpers)~~ — **OUT OF SCOPE.** Touches turn-taker shims.
- ~~Auto-clear with `--force`~~ — **OUT OF SCOPE.** Do not auto-remove the lock file under any flag;
  this phase is warn-only.
- **IN SCOPE:** a preflight check in `utils/swarm-preflight.sh` that warns (non-fatal) when a stale
  lock is present, plus a short doc note on the safe manual clear.

### What to build

Add a check near `utils/swarm-preflight.sh`'s existing Phase 3 freshness checks (around
`utils/swarm-preflight.sh:568-579` — the `DIRTY`/`FRESH_BLOCKED` computation; add yours in that same
neighborhood, following the same style: a plain bash boolean flag computed from a `git`/filesystem
probe against `$TARGET_ROOT`).

**Detection:** `$TARGET_ROOT/.git/index.lock` exists AND no live process currently holds it. Your
call on the exact "is it held" mechanism (e.g. `lsof` if available, or a `pgrep -f git` heuristic —
document whichever you pick and why), but it must not false-positive against a git operation that is
genuinely in flight at the moment `swarm-preflight.sh` runs.

**On detection:** surface a clear, visible warning in BOTH the text report and the JSON output
(`--format json` — follow the existing pattern of how `freshness`/other fields are threaded into
`run-candidate.json` via the `normalize.mjs` node helper and the `SP_*` env-var handoff convention
already used throughout this file). Name the lock path and the safe manual remediation: verify no
live git process (`pgrep -fl git`), then `rm .git/index.lock`.

**Must NOT do:**
- Must not change swarm-preflight's exit code or `VERDICT`/`CAND_STATE` on its own — this is
  fail-open/advisory (a stale lock might be a real in-progress operation caught mid-flight; it's a
  warning, not a BLOCKED state).
- Must not delete or touch the lock file itself.
- Must not touch `bin/tick`, `src/project.js`, or any file under `relay-automation/*-turn.sh`.

**Doc note:** add a short troubleshooting entry (in `relay-automation/README.md`'s troubleshooting
section, if one exists, or the nearest natural home you find — your call) documenting the safe manual
clear, so an operator who sees the new warning has somewhere to go beyond the one-line message.

### Tests to add (`test/swarm-preflight.sh` — extend the existing 87-case file)

1. A fixture repo with a stale, unheld `.git/index.lock` present — assert the new warning appears
   (both text and JSON report formats).
2. An ordinary clean repo (no lock file) — assert the warning is absent.
3. Confirm the check never turns an otherwise-ready candidate into `BLOCKED`/a different `VERDICT` —
   i.e. the exit code and verdict are unaffected by the stale lock's presence.

### Acceptance / done means

- `bash test/swarm-preflight.sh` green (existing 87 + your new cases).
- Full `validate.sh` green (or unchanged from before your change — the pre-existing `#208`
  environment red is expected and not yours to fix).
