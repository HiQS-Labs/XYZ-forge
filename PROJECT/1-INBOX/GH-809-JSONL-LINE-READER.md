---
title: "tick: readAllEvents parses each .jsonl FILE as one JSON doc"
status: "Proposed (1-INBOX - not yet active)"
created: 2026-10-24
gh_issue: 809
source: https://github.com/HiQS-Labs/XYZ-forge/issues/809
doc_type: bugfix
non_goals:
  - Quarantine/rename of corrupt event files (GH-5's scope)
  - A src/ unit-test runner (GH-5's scope; no new tests per GH-831)
  - Rewriting the wave_reconcile rollback writer (already disambiguated by pid + random suffix)
---

# GH-809 — tick reads `.jsonl` event files as one JSON document

## Ask

`src/events.js` `readAllEvents` reads each `.tick/events/*.jsonl` file with
`JSON.parse(raw)` as a single document. A file holding two JSON lines throws
`Unexpected non-whitespace character after JSON`, and every verb that reads the
event log (`claim`, `release`, `info`, `reap`, ...) dies on that machine.

## Acceptance (from the issue)

- `readAllEvents` parses per line (JSONL semantics, matching the extension).
- An unparseable line is skipped with a warning naming the file, rather than
  killing the scan.
- Red control: a fixture `.tick/events/x.jsonl` with two valid lines makes
  `tick info` fail before the fix and return state after it; a mutated invalid
  line warns instead of dying.

## Rating (2026-10-24) — rated 72/82/50/88

- sev 82: work-blocking — one multi-line file stops every coordination verb on
  the machine; recoverable by deleting the file, no data corruption.
- pri 72: severity-led; still reachable today (live files on disk) but the
  writer that produced them is fixed, lowering new-incident odds.
- appeal 50: neutral (no operator preference given).
- effort 88: one function in one file, existing suites cover the read path.
- Recurrence: 3 incidents 2026-09-21..24 (one writer, double-fires); none found
  in 2026-09-26..10-24 issues. Trend: flat since the writer fix; coverage limited
  to GitHub issues.

## Status at capture (2026-10-24)

- Reader defect: still live on `origin/development` (`c5ef7a2e`).
- Writer defect: already addressed — the rollback filename now carries
  `<pid>-<random hex>` (`utils/py/wave_reconcile.py:192`), so a double-fire no
  longer appends to one file.
- Live multi-line files remain in at least one local clone
  (`XYZ-forge-gh676/.tick/events/2026-09-21T*-wave-reconcile-rollback.jsonl`).
