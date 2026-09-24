---
gh_issue: 570
source: https://github.com/HiQS-Labs/XYZ-forge/issues/570
title: "hq_known_repos: a 0-byte / table-less HQ_REBALANCE_DB silently empties the repo list; two gate suites read the real one"
status: Complete
created: 2026-09-21
updated: 2026-09-24
owner: unassigned
doc_type: capture
complexity: 1
risk: 1
effort: 1
rating: "pri/sev/appeal/effort 60/60/90/60 · calc 270"
rating_ovr: null
is_manual_override: false
ratings_provisional: true
goal: >
  hq_known_repos survives an empty or table-less HQ_REBALANCE_DB with a warning instead of
  silently emptying the repo list, and the two gate suites that read the operator's real DB pin a
  fixture.
---

# GH-570 — hq_known_repos: a 0-byte / table-less HQ_REBALANCE_DB silently empties the repo list; two gate suites read the real one

## Status

| What was just completed | What's next |
|---|---|
| Queued by the 2026-09-21 `/10days` sweep: validity, reproducibility and not-already-done verified against HEAD e565c0fe (see Why); contract auto-drafted. | Marathon lane fires from `marathon/10days-2026-09-21` via `swarm-preflight → marathon-drive`, scoped by the contract's `artifacts`. |

## Why

`utils/hq/hq-lib.sh:193-216` runs `sqlite3 "$HQ_REBALANCE_DB" 'SELECT name FROM project_registry;'
2>/dev/null` whenever the file merely exists; a 0-byte file makes sqlite3 fail, the error is
discarded, and the brace group aborts under `set -euo pipefail` before the XYZ and PDDA registry
loops run. `test/hq-rollup.sh` and `test/gh239-hq-status-releases-mode.sh` do not pin
`HQ_REBALANCE_DB` (nine sibling HQ suites do, e.g. `test/hq.sh:55`). Both defects reproduce verbatim
at HEAD; no commit or PR references #570.

## Acceptance

Authored by `/10days` — the tracking issue has no `## Acceptance` section swarm-preflight recognises, so there is no block to copy verbatim. These criteria transcribe the issue's fix / expected-behaviour text.

- [ ] `hq_known_repos` guards the DB with `[ -s "$HQ_REBALANCE_DB" ]` (or a `.tables` check) and runs
      the query so it cannot abort the brace group; an unreadable, empty, or table-less DB
      prints a one-line stderr warning and the XYZ + PDDA registry repos are still listed. Red
      control: a 0-byte file at the DB path must still list the registry repos and print the
      warning.
- [ ] `test/hq-rollup.sh` and `test/gh239-hq-status-releases-mode.sh` pin `HQ_REBALANCE_DB` to a
      fixture or `/nonexistent` the way gh405 pins `XYZ_DEVICE_CONFIG_PATH`, and pass with any
      garbage at the operator's real path.
- [ ] `bash validate.sh` exits 0.
- [ ] `bash test/gh139-pipe-grep-guard.sh` stays green: every new assertion in `test/hq-hardening.sh` (and the other allowlisted suites) uses capture-then-match — `grep -q PAT <<<"$(cmd)"` — never `cmd | grep -q PAT` (marathon attempt 1 on 2026-09-22 grew the pipe-into-grep count 13→15 and failed the gate).

## Swarm Preflight Contract

```json
{
  "target": {
    "repo": ".",
    "ref": "development"
  },
  "gate": "bash validate.sh",
  "fix_probes": [
    {
      "type": "grep_present",
      "path": "utils/hq/hq-lib.sh",
      "pattern": "sqlite3 \"\\$HQ_REBALANCE_DB\" 'SELECT name FROM project_registry;' 2>/dev/null \\| sed"
    },
    {
      "type": "grep_absent",
      "path": "test/hq-rollup.sh",
      "pattern": "HQ_REBALANCE_DB"
    }
  ],
  "artifacts": [
    "utils/hq/hq-lib.sh",
    "test/hq-rollup.sh",
    "test/gh239-hq-status-releases-mode.sh"
  ],
  "remediation": {
    "source": "issue#570",
    "criteria": "Guard hq_known_repos against an unusable DB and pin HQ_REBALANCE_DB in the two unpinned gate suites"
  },
  "lanes": {
    "agy_safe": [
      "utils/hq/hq-lib.sh",
      "test/hq-rollup.sh",
      "test/gh239-hq-status-releases-mode.sh"
    ],
    "orchestrator_only": []
  }
}
```

Contract auto-drafted by /10days from the issue text — artifacts/lanes not yet operator-verified. Fix probes detect the BUG (`grep_present` = bug still there, `grep_absent` = fix landed), per swarm-preflight polarity.
