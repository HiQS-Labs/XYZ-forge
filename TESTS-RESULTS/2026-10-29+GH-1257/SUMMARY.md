# GH-1257 — read-only backlog-to-wave pilot

- **Source:** `030db02d` on `feat/XYZ-forge-gh1257-backlog-wave-pilot-2026-10-29`, stacked on the GH-1248 branch (`89e1af53`)
- **Where:** disposable full clone `XYZ-forge-gh1257-backlog-wave-pilot-2026-10-29-verify`; identity bracketed around the suites and the gate
- **Platform:** macOS 15.6.1 arm64, Python 3.14.7, `/usr/bin/sandbox-exec`
- **Result:** the outer loop ran over 10 real roadmap issues and produced a brief for each plus a wave proposal. All controls and the eight focused existing suites pass. The repository ledger stayed byte-identical. Hand inspection found one unsafe under-count (#216). The full gate result is in `gate.txt`.

## What ran

`init --from-prs --limit 10` froze a copy of `releases.db`, the git branch and file listings, and one read-only `gh issue view` per candidate, taken from open `Queue / parked intake` rows the planner classes `ready` or `needs-contract`. Twelve compressed ticks then ran the rules arm (`pilot-2/`):

| Measure | Observed |
|---|---|
| Requests | 10 seeded, 0 excluded (no candidate was CLOSED or unreadable; the exclusion path is not exercised by this data) |
| Ticks | 12/12 completed; slots 1–10 each consumed a different request; slots 11–12 idle |
| Briefs | 3 ready (existing contract and sourced scope), 3 draft (sourced scope and write set), 4 needs-recon (no cited existing file) |
| Planner waves | 6 lanes in 2 waves, unchanged from the planner's own output |
| Provisional waves | 9 lanes in 4 waves: #216 joins wave 1; #1201 and #478 go to waves 3 and 4 |
| Held | 4, each `needs-recon: no sourced write set` |
| Ledger | `releases.db` and `releases.sql` byte-identical before and after every run |

**AC3 cases on real data.** Disjoint lanes: wave 1 holds six write-disjoint lanes. Collision: #478 shares `validate.sh` with #670. Zone cap: the `kernel` zone allows one lane per wave, so #670, #355, #1201 and #478 each take a separate wave. Seams: three shared-`utils/py/` seams in wave 1, reported for both views. Dependency: #418 depends on #423, which the planner classes `already-landed`, so the dependency is resolved. No unmet dependency exists in this data, so a recorded control shows a two-lane cycle is held under provisional packing and still forced into one wave under the CLI's packing.

The first run (`0fcda47f`) had two defects found in final QA and fixed in `030db02d`: a folded YAML `goal: >` was read as the literal scope `>` (it made #478 look scoped), and a planner-ready brief without sourced scope still entered provisional waves. `pilot-2/` is the rerun after the fix; #478 now carries its real goal text.

## Planner split parity

`Engine.run` was split into `compute()` plus rendering, and its wave packing and seam detection became methods. Base `f369773b` and candidate `030db02d`, on the same ledger with fixed time and gh off, produced byte-identical output and equal exit codes for `--dry-run`, `--format json`, `--policy derisk-first`, `--check` and the JSON-plus-policy mode, and an identical rendered `MARATHON-PLAN` doc (`parity.txt`; the mode-1 report is retained as `parity-mode1-report.txt`).

## Controls (`controls.txt`, all on `030db02d` except the direct-IP line, recorded on `0fcda47f` with the same sandbox profile)

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
| Same cited path, no sourced scope vs sourced scope (needs-contract) | `missing-scope` and held vs `draft` and placed |
| Planner-ready brief with vs without sourced scope | placed vs held as `missing-scope`; stays in the planner view both times |
| Frontmatter goal: folded, literal, inline, bare marker, absent | decoded text, decoded text, text, none, none |
| Two-lane dependency cycle | provisional packing holds both; CLI packing forces one wave (unchanged) |

## Hand inspection (three drafts, `pilot-2/`)

- **#478:** the write set (runaway guard, `proc_group.py`, the relay turn lib and the tests its plan names) and the decoded goal match its capture doc.
- **#1201:** an audit issue, so the cited files are broad. That is conservative: it only pushes the issue into a later wave.
- **#216: unsafe under-count.** The issue concerns the `marathon-plan.sh` ledger parser but names files without a directory, so the only sourced path is `PROJECT/PDDA.md`. The provisional proposal therefore puts #216 in wave 1 beside lanes that touch the planner. This is the false-parallelism risk the plan named; the draft label and human review are the only guard today.

## Lessons from the GH-1175 Phase 0 spike

- **Applied:** no git or ledger bookkeeping during runs (the spike's five bookkeeping commits blocked another session); recovery keys on receipts, not the heartbeat; the planner never writes its `MARATHON-PLAN` file.
- **Still open:** "ready" here is planner-ready only. The spike showed ledger-based readiness admitted five issues that all failed and that 7 of 11 contracts were stale; this pilot cannot run `swarm-preflight` because it fetches and creates worktrees. Intake also starts too late: the spike found 73% of open issues have no ledger row, and this pilot only sees ledger rows.

## Follow-ups noted, not done here

- Resolve a bare cited filename when it names exactly one tracked file (the #216 under-count).
- An init-time stale or delivered-but-open check, and seeding from open issues with no ledger row.
- Pre-existing: the planner's queue doc renders valid four-axis DB ratings as `—/—/—/—` through the old five-point formatter (`_marathon_plan.py` `_rating_num`); left unchanged in this parity-only split.

No adapters, dispatch, ledger or GitHub writes. The 24-hour synthetic soak, the watchdog and soak-v2 remain deferred.
