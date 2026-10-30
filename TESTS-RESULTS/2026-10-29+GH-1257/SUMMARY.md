# GH-1257 — read-only backlog-to-wave pilot

- **Source:** `0fcda47f` on `feat/XYZ-forge-gh1257-backlog-wave-pilot-2026-10-29`, stacked on the GH-1248 branch (`89e1af53`)
- **Where:** disposable full clone `XYZ-forge-gh1257-backlog-wave-pilot-2026-10-29-verify`; identity unchanged before and after the suites
- **Platform:** macOS 15.6.1 arm64, Python 3.14.7, `/usr/bin/sandbox-exec`
- **Result:** the outer loop ran over 10 real roadmap issues and produced a brief for each plus a wave proposal. All controls and the eight focused existing suites pass. The repository ledger stayed byte-identical. One unsafe under-count was found by hand inspection (below).

## What ran

`init --from-prs --limit 10` froze a copy of `releases.db`, the git branch and file listings, and one read-only `gh issue view` per candidate, taken from open `Queue / parked intake` rows the planner classes `ready` or `needs-contract`. Twelve compressed ticks then ran the rules arm:

| Measure | Observed |
|---|---|
| Requests | 10 seeded, 0 excluded (no candidate was CLOSED or unreadable) |
| Ticks | 12/12 completed; slots 1–10 each consumed a different request; slots 11–12 idle |
| Briefs | 3 ready (existing contract), 3 draft (sourced scope and write set), 4 needs-recon (no cited existing file) |
| Planner waves | 6 lanes in 2 waves, unchanged from the planner's own output |
| Provisional waves | 9 lanes in 4 waves: #216 joins wave 1; #1201 and #478 get their own waves |
| Held | 4, each `needs-recon: no sourced write set` |
| Ledger | `releases.db` and `releases.sql` byte-identical before and after every run |

Sample outputs are in `pilot-1/`: the proposal, the briefs for #418 (ready), #1201, #216 and #478 (drafts), the manifest and the per-tick receipts.

## Planner split parity

`Engine.run` was split into `compute()` plus rendering, and its wave packing and seam detection became methods. On the live ledger with fixed time and gh off, base and candidate produced byte-identical output and equal exit codes for `--dry-run`, `--format json`, `--policy derisk-first`, `--check` and the JSON-plus-policy mode, and an identical rendered `MARATHON-PLAN` doc.

## Controls

| Control | Result |
|---|---|
| Failure after output written | `uncertain`, request quarantined, next slot drafts the next request |
| Wrong issue hash / removed key / Markdown ≠ JSON / missing proposal file | each `uncertain` + quarantined, with the verifier's reason recorded |
| Crash after verified output, before receipt | next tick reconciles to `uncertain`; request quarantined; proposal lists it under not accepted |
| Capture doc edited after init | tool refuses, tick `uncertain`, quarantined |
| PAUSE | tick `paused`, no draft written |
| Rerun a completed slot | returns the stored status; no files written |
| Unknown, consumed or extra-arg request id | `_validate` → `plan-draft-id-not-eligible` |
| Cited path traversal, absolute, symlink to `/etc/hosts` | dropped; only `utils/py/harness.py` admitted |
| Network inside the tool sandbox | DNS fails; direct IP connect `Operation not permitted` |
| Same cited path, no sourced scope vs sourced scope | `missing-scope` and held vs `draft` and placed in a provisional wave |

## Hand inspection (three drafts)

- **#478:** the write set (runaway guard, `proc_group.py`, the relay turn lib and the tests the plan names) matches its capture doc.
- **#1201:** an audit issue, so the cited files are broad. That is conservative: it only pushes the issue into its own wave.
- **#216: unsafe under-count.** The issue concerns the `marathon-plan.sh` ledger parser but names the file without a directory, so the only sourced path is `PROJECT/PDDA.md`. The provisional proposal therefore puts #216 in wave 1 beside lanes that touch the planner. This is the false-parallelism risk the plan named; the draft label and human review are the only guard today.

## Lessons from the GH-1175 Phase 0 spike

- **Applied:** no git or ledger bookkeeping during runs (the spike's five bookkeeping commits blocked another session); recovery keys on receipts, not the heartbeat; the planner never writes its `MARATHON-PLAN` file.
- **Still open:** "ready" here is planner-ready only. The spike showed ledger-based readiness admitted five issues that all failed and that 7 of 11 contracts were stale; this pilot cannot run `swarm-preflight` because it fetches and creates worktrees. #418, for one, looks delivered but still open. Intake also starts too late: the spike found 73% of open issues have no ledger row, and this pilot only sees ledger rows.

## Not done

No adapters, dispatch, ledger or GitHub writes. The 24-hour synthetic soak, the watchdog and soak-v2 remain deferred. Draft write sets come from cited paths only.
