---
gh_issue: 107
source: https://github.com/HiQS-Labs/XYZ-forge/issues/107
title: "Connect /10days, /radar, and PARKED to the RELEASES DB (read-only seams, no new writers)"
status: Complete
created: 2026-08-28
updated: 2026-08-28
owner: noel
doc_type: feedback
release: 0.9.0 Cargo (dialed in per manifest_items)
goal: >
  Make /10days, /radar, and PARKED read the RELEASES DB through read-only seams instead of re-deriving ground truth by hand.
fix_probes:
  - path_absent:test/gh107-timeline-json-seam.sh
effort: 2
complexity: 2
risk: 1
phases: 1
---
## Status

| What was just completed | What's next |
|---|---|
| Promoted to active working contract via jog | Execute implementation and verify probes |

# GH-107: read-only RELEASES-DB seams for /10days, /radar, and PARKED

## Why

The RELEASES DB holds machine-readable ground truth that `/10days`, `/radar`, and the PARKED
convention each re-derive by hand today. Observed failure: `/10days`' validity sweep would
have accepted #79–#81 as open work while the ledger already knew wave 1 had landed.
Integration stays **read-only consumption** — the CLI dual path remains the only writer.

## Acceptance criteria — the build is DONE when these hold

- [ ] `utils/timeline/export_timeline.py --json` prints the same `data.json` projection the
      HTML viewer uses to stdout as valid JSON, with no other stdout output (the shared query
      seam for `/radar` and `/10days`).
- [ ] `skills/10days/SKILL.md` gains a ledger cross-check step: before calling a swept issue
      valid, query `releases.db` (manifest/marathon/roadmap rows by GH number) and grep recent
      `GH-nn` commits for completion evidence. Prompt edit only — no code.
- [ ] `skills/radar/SKILL.md`'s drift lens reads the DB (`releases check`, `releases roadmap
      sync --dry-run`, the `--json` payload) instead of hand-parsing `RELEASES.md`, citing
      generation numbers in the report.
- [ ] The two older park files (`PARKED/2026-08-16-*.md`, `PARKED/2026-08-19-session-close.md`)
      carry the standup lens-8 read-only `check:` field, and the PARKED format notes the
      convention so parked-but-finished rot is machine-detectable.
- [ ] `bash test/gh107-timeline-json-seam.sh` exists and pins the `--json` seam (stdout parses
      as JSON; drift guard behavior unchanged without the flag).
- [ ] No skill writes to `releases.db` or `RELEASES.md` — read-only seams only (issue non-goal).

## Non-goals

- No sync daemon, no webhooks, `/radar` never files drift fixes itself; the band rule stays
  human-adjudicated. The "outside-the-box" research items in the issue are explicitly out of
  scope for this lane.

## Swarm Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash validate.sh",
  "fix_probes": [ { "type": "path_absent", "path": "test/gh107-timeline-json-seam.sh" } ],
  "artifacts": [
    "utils/timeline/export_timeline.py",
    "skills/10days/SKILL.md",
    "skills/radar/SKILL.md",
    "PARKED/2026-08-16-xyz-forge-2143.md",
    "PARKED/2026-08-19-session-close.md",
    "PARKED/README.md",
    "test/gh107-timeline-json-seam.sh"
  ],
  "artifacts_new": [ "test/gh107-timeline-json-seam.sh" ]
}
```

## Lessons Learned (For Future Agents)
- The jog → marathon executor path landed this lane end-to-end: one containment failure
  (in-tree `scratch/` probe files, preserved in `.tick/orphan-backups/`), one fresh-token
  retry-build, and two gate-only retries after intake-hygiene gate failures — no manual Tick,
  branch, or PR surgery.
- Intake hygiene is gate-load-bearing: a 2-WORKING doc without a `goal:` key or a roadmap
  ledger row (with a regenerated dashboard) fails validate.sh's pdda suites; park the roadmap
  row and regenerate ROADMAP-DASHBOARD.md BEFORE the first jog run, not after a red gate.
