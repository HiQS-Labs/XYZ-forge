---
title: merge-cleanup refuses .tick clones as "tick binary not found" although tick is installed; per-Mac harness config is never prompted
status: In progress
created: 2026-11-20
updated: 2026-11-20
owner: noelsaw1
gh_issue: 1567
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1567
doc_type: bugfix
complexity: 1
risk: 1
effort: 1
phases: 1
ratings_provisional: false
reported_from: LTVera-Pandas
non_goals:
  - Relaxing GH-1362 / GH-744 (the audited tree's vendored tick is never trusted by scan_clones).
  - Auto-writing ~/.config/xyz/harness from xyz-sync or Skills Army (issue option 3).
  - Any new test, suite or registry entry (AGENTS.md "No new tests", GH-831).
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1362
goal: >
  A Mac whose repos vendor .xyz is told, by find-harness.sh --check, to save the per-device harness
  config, and scan_clones' "tick binary not found" refusal names that remedy. The trust rule is unchanged.
---

# GH-1567 — tick "not found" although installed: name the per-Mac config remedy

## Symptom

`scan_clones.py` reports `PRESERVE_UNVERIFIED_SESSION: Cannot verify tick claims: tick binary not found` for every
clone holding `.tick/`, on a Mac where every repo vendors `.xyz/` and `~/.config/xyz/harness` was never written.
`relay-xyz/find-harness.sh --check` meanwhile prints `ok tick CLI (<repo>/.xyz/bin/tick)`, so nothing prompts the setup.

## Cause (observed)

- `skills/2-daily/merge-cleanup/scripts/scan_clones.py::_tick_binary` (GH-1362) deliberately refuses the audited tree's
  `.xyz/bin/tick`; with `MERGE_CLEANUP_TICK_BIN`, `XYZ_HARNESS`, the config file and PATH all absent it returns `None`
  and `inspect_tick_claims` returns the bare string `tick binary not found`.
- `skills/1-hourly/relay-xyz/find-harness.sh --check` prints its `save this harness on this Mac` hint only when
  `VENDORED=0` (`:424-431`). A vendored resolution never reaches it, although `LIVE_HARNESS` is already computed.

## Plan

Existing subsystems extended; no new writer, no new file other than this doc.

1. `scan_clones.py:323` — the refusal detail names the remedy: save the XYZ-forge clone path to
   `~/.config/xyz/harness` or set `XYZ_HARNESS` (`relay-xyz/find-harness.sh --check` prints the command).
   Fail-closed behavior and `verified: False` are unchanged.
2. `find-harness.sh --check` — in the vendored branch, print the per-device config as its own line: `ok` with the
   path when `_read_config` resolves, otherwise a `!` line plus the existing `save this harness on this Mac: mkdir …`
   command for the known canonical live harness (`_canonical_clone "$LIVE_HARNESS"`). Still advisory, exit 0.
   When no canonical live harness is known, the `!` line says so and points to the SKILL.md manual command.
3. `skills/1-hourly/relay-xyz/SKILL.md` — one sentence: the save line also appears on vendored resolutions.

### Acceptance (no new tests)

- Red control: in an isolated `XDG_CONFIG_HOME` with `env -u XYZ_HARNESS -u MERGE_CLEANUP_TICK_BIN`, the unfixed
  scanner returns the bare string and the unfixed `--check` (from a vendored repo) prints no config line.
- After: scanner detail contains `~/.config/xyz/harness` and `XYZ_HARNESS`; `--check` from a vendored fixture prints
  the `!` config line + save command when config is absent, the `ok` line once the printed command is run, and the
  saved config makes `_tick_binary()` resolve (`verified: True`).
- Existing suites: `test/find-harness.sh`, `test/gh396-find-harness-roots.sh`, `test/gh534_phase_a_tests.py`,
  `test/gh436-merge-cleanup.py`, relay-xyz skill guard. No existing assertion pins the old string.
- Smoke receipts under `TESTS-RESULTS/2026-11-20+GH-1567/`.

### Preflight bet check

- Outcome: an operator on a vendored-only Mac learns the one-time setup from either failure point.
- Smallest bet: two message/print changes. Not built: auto-write of the config, any trust-rule change.
- Rejected: accepting vendored tick (undoes GH-1362); auto-writing config from xyz-sync (writes outside the repo
  without consent; not needed once the hint exists).
- Rollback: revert the commit; both changes are output text only. Reversibility: Easy.

## Status

| What was just completed | What's next |
|---|---|
| Recon complete; plan drafted; rated 50/40/50/85 (see below). | Codex plan QA, implement, gate, smoke, final QA, PR. |

## PRS rating rationale (2026-11-20)

Rated **50/40/50/85** (pri/sev/appeal/effort). Severity moderate: fails closed, no data lost, but cleanup stalls and
operators remove clones by hand. Priority medium per the issue label. Appeal neutral 50 (no operator value). Effort
cheapness high: two output-text changes. Recurrence: same class as #1362 (closed 2026-11-08), different gap (per-Mac
config prompt); one incident in the last 14 days, trend unknown beyond that.
