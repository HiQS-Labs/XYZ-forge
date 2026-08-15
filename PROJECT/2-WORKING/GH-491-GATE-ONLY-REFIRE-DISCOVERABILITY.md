---
gh_issue: 491
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/491
title: "The gate-only re-fire path exists but is undiscoverable, and --retry silently rebuilds instead — three builds and three reviews spent for nothing"
status: 2-WORKING
created: 2026-08-15
updated: 2026-08-15
owner: unassigned
doc_type: capture
complexity: 2
risk: 2
effort: 2
ratings_provisional: true
related:
  - "https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/555 — Meter's exit criterion; every other Meter entry is unverifiable until it exists"
goal: >
  Make the cheap gate-only re-fire path discoverable, and stop --retry silently taking the expensive one.
---

## Status

| What was just completed | What's next |
|---|---|
| Captured 2026-08-15 for the Meter 0.6.0 marathon. Acceptance copied verbatim from the issue; contract authored. | Lane execution. Not started. |

## Why this is a Meter entry

It is the release's sentence almost verbatim: a run that re-spends on work the driver already has is
a run that did not account for what it spends. Three codex builds plus three agy reviews were spent
re-running work that a cheap gate-only path already covered — the path exists, nothing points at it,
and `--retry` silently takes the expensive one.

## Acceptance

- [ ] `--retry`'s help text states when it is the wrong choice: if the phase's relay is already terminal with `STATUS: Approved` and its token is `done`, re-firing the plan **without** `--retry` re-runs only the pre-advance gate and dispatches no turns. The current one-line description mentions only the suffix mechanism.
- [ ] When `--retry` is passed for a phase whose relay **is** terminal/`Approved` with a `done` token, the driver logs — before dispatching a builder turn — that a plain re-fire would have re-run only the gate, and that this run will rebuild instead. Advisory only.
- [ ] The advisory does **not** refuse, skip, or alter `--retry`'s behaviour. A deliberate rebuild of an approved phase is legitimate (a bad artifact that passed review is exactly when you want one), and `completed_relay_task()`'s rule that a retry must never be satisfied by the attempt it retries stays intact.
- [ ] A test asserts the advisory fires on a terminal/`Approved`/`done` fixture under `--retry`, **with a negative control observed**: a non-terminal fixture, or one whose token is not `done`, must produce no advisory. Without the control this is indistinguishable from a line that always prints — the same defect as the warning in #492.
- [ ] The `already-satisfied` path itself is unchanged. It works; this issue adds no behaviour to it.

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
      "path": "utils/py/marathon_drive.py",
      "pattern": "retry",
      "why": "--retry currently rebuilds; the bug is that it does not offer the gate-only path"
    }
  ],
  "artifacts": [
    "utils/py/marathon_drive.py",
    "test/gh491-gate-only-refire.sh"
  ],
  "remediation": {
    "source": "issue#491",
    "criteria": "SUMMARY FOR RANKING ONLY \u2014 the definition of done is the verbatim ## Acceptance block above"
  },
  "lanes": {
    "agy_safe": [],
    "orchestrator_only": [
      "utils/py/marathon_drive.py"
    ]
  }
}
```

Contract auto-drafted from the issue text — artifacts/lanes not yet operator-verified.
