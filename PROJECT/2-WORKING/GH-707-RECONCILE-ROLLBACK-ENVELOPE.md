---
gh_issue: 707
source: https://github.com/HiQS-Labs/XYZ-forge/issues/707
title: "wave_reconcile rollback (GH-698 F8) writes a bare record into .tick/events/ — the #694 shape; survives only because of #702's fold filter"
status: Active (2-WORKING)
created: 2026-09-21
updated: 2026-09-21
owner: unassigned
doc_type: capture
complexity: 2
risk: 3
effort: 1
rating: "pri/sev/appeal/effort 60/60/90/75 · calc 285"
rating_ovr: null
is_manual_override: false
ratings_provisional: true
goal: >
  wave_reconcile's rollback record carries the standard event envelope and no longer lands as a
  bare foreign record in tick's coordination log.
---

# GH-707 — wave_reconcile rollback (GH-698 F8) writes a bare record into .tick/events/ — the #694 shape; survives only because of #702's fold filter

## Status

| What was just completed | What's next |
|---|---|
| Queued by the 2026-09-21 `/10days` sweep: validity, reproducibility and not-already-done verified against HEAD e565c0fe (see Why); contract auto-drafted. | Marathon lane fires from `marathon/10days-2026-09-21` via `swarm-preflight → marathon-drive`, scoped by the contract's `artifacts`. |

## Why

`utils/py/wave_reconcile.py:180-187` (`TxnGuard.rollback()`, GH-698 F8) appends `{"event": "wave-
reconcile-rollback", "reason": …, "at": <epoch>}` to `.tick/events/<ts>-wave-reconcile-
rollback.jsonl` — no `schema_version`, `ts`, `type` or `task`, the exact #694 shape. It survives
only because #702's fold filter in `src/project.js:60-61` skips it; a vendored install without that
filter gets the #694 crash on its first rollback. `utils/py/express.py:110-125` already has the
envelope to reuse. No fix commit or PR references #707.

## Acceptance

Authored by `/10days` — the tracking issue has no `## Acceptance` section swarm-preflight recognises, so there is no block to copy verbatim. These criteria transcribe the issue's fix / expected-behaviour text.

- [ ] `TxnGuard.rollback()` emits the record with the envelope express uses (`schema_version:
      "0.2.0"`, ISO `ts`, `type: "wave_reconcile.rollback"`, `agent: "wave_reconcile"`, keeps
      `reason`), written beside the log under `.tick/reconcile/` (preferred) — or, if the
      minimal option is taken, keeps the location with a non-`task.*` `type`, no `task`, and
      this doc records that it relies on the #702 filter.
- [ ] `test/wave-reconcile.sh` forces a rollback in a fixture with a live `.tick/` and asserts `tick
      project` exits 0 and offers no phantom task; red control: the old bare record shape copied
      into `.tick/events/` on a `src/project.js` with the two filter lines removed reproduces
      the #694 phantom/crash.
- [ ] `bash validate.sh` exits 0.

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
      "path": "utils/py/wave_reconcile.py",
      "pattern": "\"event\": \"wave-reconcile-rollback\""
    }
  ],
  "artifacts": [
    "utils/py/wave_reconcile.py",
    "test/wave-reconcile.sh"
  ],
  "remediation": {
    "source": "issue#707",
    "criteria": "Give the rollback record the standard envelope (and a home outside .tick/events), pin with a live-.tick regression"
  },
  "lanes": {
    "agy_safe": [
      "test/wave-reconcile.sh"
    ],
    "orchestrator_only": [
      "utils/py/wave_reconcile.py"
    ]
  }
}
```

Contract auto-drafted by /10days from the issue text — artifacts/lanes not yet operator-verified. Fix probes detect the BUG (`grep_present` = bug still there, `grep_absent` = fix landed), per swarm-preflight polarity.
