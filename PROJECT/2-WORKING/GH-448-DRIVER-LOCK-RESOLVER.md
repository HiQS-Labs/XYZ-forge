---
gh_issue: 448
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/448
title: "Every driver-lock CONSUMER resolves the path with 2 branches while the drivers use 3, so from a linked worktree the monitors report a LIVE marathon as IDLE"
status: "Active (2-WORKING) — implemented and tested; landing via PR into development"
created: 2026-08-08
updated: 2026-08-08
owner: noel
doc_type: bugfix
complexity: 3
risk: 2
effort: 3
phases: 1
ratings_provisional: false
non_goals:
  - Not touching relay-drive.sh / relay_drive.py — the driver-side 2-branch defect there is the
    sibling issue #376's scope, not this one's.
  - Not editing relay-automation/marathon-drive.sh (GH-308 FROZEN twin) — it is already correct
    (3-branch); left byte-unchanged per the issue's own acceptance criterion, no
    Frozen-twin-exception needed since no behavior change is required there.
  - Not changing lock ACQUISITION/reclaim semantics anywhere — this is a read-only path-resolution
    fix for consumers, not a change to how or when the driver takes or releases the lock.
related:
  - utils/py/rtl.py
  - utils/py/marathon_drive.py
  - relay-automation/driver-lock-lib.sh
  - relay-automation/marathon-ls.sh
  - utils/hq/marathon-live.sh
  - skills/relay-xyz/find-harness.sh
  - test/gh448-driver-lock-resolver.sh
  - PROJECT/1-INBOX/GH-354-CONCURRENT-SWARMS.md
goal: >
  One shared driver-lock-path resolver (a Bash lib + a Python function, agreeing byte-for-byte),
  used by every read-only consumer of the lock, so a linked worktree's held lock is observed as
  LIVE/driving/blocking instead of silently misread as IDLE/not-driving/no-warning.
roadmap_exempt: false
---

# GH-448 · Driver-lock resolver: one shared path, not five inline guesses

**Why:** `marathon-drive` (both the frozen `.sh` and the authoritative `utils/py/marathon_drive.py`)
correctly resolves its lock with 3 branches — `.git` dir (normal clone), `.git` file (linked
worktree → the git **common dir**), or absent (vendored `.xyz/`). Every read-only consumer of that
lock had drifted to a 2-branch guess that only handles "dir" vs "everything else," so from a linked
worktree it probes a path the driver never writes. The consumer doesn't report "couldn't tell" — it
reports the *positive, reassuring* wrong answer: `marathon-ls.sh` says `IDLE`, `utils/hq/marathon-
live.sh` says "claimed, not driving", `skills/relay-xyz/find-harness.sh --check` says nothing at all.
Found live during the Litmus wave-2 marathon (2026-08-08), running from a linked worktree.

**Audit (from the issue):** 7 sites construct this path; 5 use the wrong 2-branch version.
`relay-drive.sh`/`relay_drive.py` are tracked separately by sibling issue **#376** (the driver-side
half of the same defect class). This doc's scope is the other three: `marathon-ls.sh`,
`utils/hq/marathon-live.sh`, `skills/relay-xyz/find-harness.sh`.

## Status

| What was just completed | What's next |
|---|---|
| Implemented + tested in one pass 2026-08-08: shared resolver (`utils/py/rtl.py::driver_lock_path` + new `relay-automation/driver-lock-lib.sh`, byte-for-byte parity asserted by test); `marathon_drive.py` refactored to call it (no behavior change, confirmed by `test/driver-lock.sh` still 4/4); the three broken consumers (`marathon-ls.sh`, `utils/hq/marathon-live.sh`, `find-harness.sh`) now call the shared resolver instead of guessing inline. New `test/gh448-driver-lock-resolver.sh` (17/17): bash/python parity across all 3 branches, a negative control replaying the OLD 2-branch logic against a REAL `git worktree add` fixture (observed missing the lock), and an end-to-end run of the three real, fixed scripts against that same fixture (observed LIVE / 🟢 live / held-lock warning). Existing regression suites (`marathon-monitor.sh`, `hq-marathon-live.sh`, `find-harness.sh`, `driver-lock.sh`) still green. | Open the PR into `development`. Sibling **#376** (driver-side `relay-drive.sh`/`relay_drive.py` 2-branch fix) is out of this doc's scope and stays a separate follow-up. |

## Acceptance (transcribed from #448)

- [x] A single shared resolver produces the driver-lock path; the in-scope consumers (marathon-ls.sh,
      marathon-live.sh, find-harness.sh) call it instead of constructing the path inline.
      `marathon-drive.sh` (frozen) is unchanged since it was already correct; `relay-drive.sh`/
      `relay_drive.py` are explicitly #376's scope, not re-litigated here.
- [x] The shell and Python resolvers agree on all inputs asserted by a test (`.git` dir, `.git` file
      via a REAL `git worktree add`, absent/vendored) — `test/gh448-driver-lock-resolver.sh` section A.
- [x] From a **linked worktree** with a driver holding the lock: `marathon-ls` reports `LIVE`,
      `marathon-live` reports 🟢 live, and `find-harness.sh --check` prints its held-lock warning
      naming the real (common-dir) path — all three **observed** against real fixed scripts + a real
      `git worktree add`, not inferred — section C.
- [x] The negative control is observed and recorded per #419: section B replays each site's ORIGINAL
      2-branch logic verbatim against the identical worktree fixture and shows it misses the held
      lock, before section C shows the fixed logic finding it — both revisions, same fixture, written
      into the test itself (not just asserted in prose here).
- [x] `relay-automation/marathon-drive.sh` is a GH-308 frozen twin — left byte-unchanged (no
      `Frozen-twin-exception:` needed, since it required no behavior change).
- [~] "A consumer that genuinely cannot determine the lock state reports that, distinctly from IDLE":
      not implemented as a new formal state. The shared resolver mirrors the driver's OWN fallback
      behavior exactly (on a `git rev-parse --git-common-dir` failure it falls back to
      `<repo>/.relay-driver.lock`, same as the driver would), so a consumer now sees exactly what the
      driver would resolve to in every case the driver itself handles — there is no case left where
      the consumer "can't tell" that the driver itself could. Scoped out as disproportionate net-new
      state-machine surface for a resolution path the driver never treats as unknown either.

## Reconciled: the `.xyz/` 4th case

`utils/hq/marathon-live.sh` checked `<repo>/.xyz/.relay-driver.lock` for the vendored case — a path
the driver **never writes** (the driver's vendored fallback is `<repo>/.relay-driver.lock`, same
hidden-file-at-root shape as the clone case, just without `.git/`). Reconciled by deletion: the
shared resolver has no `.xyz/`-scoped branch, and `marathon-live.sh` now agrees with the driver.
