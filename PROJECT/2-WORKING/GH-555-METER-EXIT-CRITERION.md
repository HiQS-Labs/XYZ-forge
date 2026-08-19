---
gh_issue: 555
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/555
title: "Meter 0.6.0 has no exit criterion — build test/meter-release.sh --release-gate, and make it RED on arrival"
status: 2-WORKING
# roadmap_exempt: this doc carries the UPSTREAM repo's GH numbering (pre-migration). Its ledger
# entry left ROADMAP.md in the 2026-08-19 upstream purge (#69) and is preserved verbatim in
# docs/ROADMAP-UPSTREAM-ARCHIVE.md. Exempt rather than re-pointed so old-numbered tasks stay
# out of the live ledger; if this work is picked back up, file it under a NEW GH number first.
roadmap_exempt: true
created: 2026-08-15
updated: 2026-08-15
owner: unassigned
doc_type: capture
complexity: 3
risk: 2
effort: 3
ratings_provisional: true
related:
  - "https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/555 — Meter's exit criterion; every other Meter entry is unverifiable until it exists"
goal: >
  Give Meter 0.6.0 a definition of done that is a command, and prove it capable of failing by shipping it RED.
---

## Status

| What was just completed | What's next |
|---|---|
| Captured 2026-08-15. Filed and admitted to the Meter frozen manifest as entry seven by explicit operator decision. | Build it FIRST, before any other Meter entry. Every other entry is unverifiable until this exists. |

## Why this runs FIRST

Litmus and Nightwatch both wrote their exit criterion before fixing any member, and that ordering is
the reason each could tell a finished entry from a claimed one. Meter has six other entries and no
definition of done, so none of them is currently falsifiable.

## Why it must be RED on arrival

A release gate that passes the day it is written has not been shown capable of failing — the #419
defect, applied to the release boundary itself. The red run is recorded evidence, not a failure.

## Acceptance

- [ ] `test/meter-release.sh --release-gate` exists, is executable, and is registered in `validate.sh`'s `TESTS`.
- [ ] Half A audits all seven manifest entries against EXISTS / REGISTERED / RECORDED-CONTROL, and cross-checks the list against `RELEASES.md`'s `Manifest:` line.
- [ ] Half B executes the six member cases above rather than reading a declaration about them.
- [ ] `--mutate-evidence` detects an unregistered gate AND a deleted control, and re-checks the unmutated inputs green in the same run.
- [ ] **It is RED on arrival.** A release gate that passes the day it is written has not been shown capable of failing; the red run is recorded in `test/baselines/`.
- [ ] The honest limit is stated in the script, as Litmus's and Nightwatch's both are: Half A reads a declaration and a filename and cannot know a recorded control was honestly recorded.

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
      "type": "grep_absent",
      "path": "test/meter-release.sh",
      "pattern": "release-gate",
      "why": "fix marker: the gate does not exist yet"
    }
  ],
  "artifacts": [
    "test/meter-release.sh",
    "validate.sh"
  ],
  "remediation": {
    "source": "issue#555",
    "criteria": "SUMMARY FOR RANKING ONLY \u2014 the definition of done is the verbatim ## Acceptance block above"
  },
  "lanes": {
    "agy_safe": [],
    "orchestrator_only": [
      "validate.sh"
    ]
  }
}
```

Contract auto-drafted from the issue text — artifacts/lanes not yet operator-verified.
