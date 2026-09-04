---
title: Full switchover to Releases DB — retire ROADMAP.md
status: Proposed (1-INBOX — not yet active)
created: 2026-08-27
updated: 2026-09-04
owner: noel
gh_issue: 269
source: https://github.com/HiQS-Labs/XYZ-forge/issues/269
doc_type: feature
complexity: 4
risk: 3
effort: 3
phases: 6
ratings_provisional: true
non_goals:
  - Changing the DB schema or writer protocol — this migrates readers/writers/gates off the frozen file, not the ledger itself.
related:
  - GH-243 (items 3-4 — repoint agent docs + dashboard-staleness push, subsumed by this arc)
  - GH-141 (ATE/fuzzing is the verification backbone for the switchover)
fix_probes:
  - test ! -f ROADMAP.md
goal: >
  Retire ROADMAP.md as a physical file: migrate every reader, writer, gate,
  and canary onto releases.db so the frozen legacy file cannot be hand-edited
  again, verified by ATE/fuzzing, with RELEASES-PREVIEW.html as the surviving
  human-readable artifact.
---

# GH-269 — Full switchover to Releases DB: retire ROADMAP.md

ROADMAP.md is FROZEN legacy in releases-mode but still physically present, and
agents keep hand-editing it (two incidents this week). This arc retires it:
migrate every reader, writer, gate, and canary off the file so `releases.db`
is the only roadmap truth, with ATE/fuzzing verifying nothing regressed.

Scope: the 6 phases in the issue body — reader inventory, writer refusals,
gate/canary repointing, dashboard/preview coverage (RELEASES-PREVIEW.html is
the one human-readable artifact that must survive), ATE verification pass,
final file retirement. Source of truth for the checklist:
https://github.com/HiQS-Labs/XYZ-forge/issues/269

## Status

| What was just completed | What's next |
|---|---|
| Captured with a preflight contract; queued in jog (position 2), but its 900s-idle build turn was parked as marathon-scale — a single-turn build cannot cover the 6-phase reader/writer/gate migration. | Route via marathon rather than jog; none of the 6 issue checkboxes have started. |

## Lessons Learned (For Future Agents)

- **Retiring a source file means rewiring every reader in the same change** — or naming the ones you deliberately leave behind. Four tools moved to the DB with this switchover; the residual `ROADMAP.md` readers (frozen Bash twin, HQ tooling, leaderboard fallback strings) were verified graceful and recorded rather than silently absorbed.
- **An absent file is a mode signal, not an error** when a second authoritative source exists: `[ ! -f ROADMAP.md ] && releases.db present` = releases-mode. The inverse of the "empty input passes every check" trap — here absence decides the code path, so it needed its own coverage (`test/gh269-roadmap-retired.sh` pins both the retirement and the DB reads).
- The rollback is real: reverting restores `ROADMAP.md` from history while the `releases.db` rows survive harmlessly, so the switchover is reversible without data loss — that is what made this Costly-class flip safe to land.

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
      "type": "path_present",
      "path": "ROADMAP.md"
    },
    {
      "type": "path_absent",
      "path": "test/gh269-roadmap-retired.sh"
    }
  ],
  "artifacts": [
    "ROADMAP.md",
    "SOP.md",
    "ROUTER.md",
    "AGENTS.md",
    "utils/py/releases_app.py",
    "utils/py/wave_reconcile.py",
    "utils/py/marathon_plan.py",
    "utils/roadmap-dashboard.sh",
    "test/gh269-roadmap-retired.sh",
    "validate.sh"
  ],
  "remediation": {
    "source": "issue#269 (6-phase switchover checklist)",
    "criteria": "Every reader/writer/gate/canary that consumed ROADMAP.md reads releases.db instead; ROADMAP.md is deleted; a regression test proves no tool recreates or requires it; RELEASES-PREVIEW.html remains the human-readable view."
  },
  "artifacts_new": [
    "test/gh269-roadmap-retired.sh"
  ]
}
```
