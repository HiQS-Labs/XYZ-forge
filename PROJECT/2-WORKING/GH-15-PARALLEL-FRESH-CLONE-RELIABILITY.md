---
gh_issue: 15
source: https://github.com/HiQS-Suite/XYZ-forge/issues/15
title: "GH-15: parallel runs are unreliable in a fresh clone; the GH-528 contention retry is not honoring its contract"
status: active
created: 2026-08-16
updated: 2026-08-16
owner: orchestrator (Claude Code)
doc_type: bugfix
complexity: 3
risk: 2
effort: 3
ratings_provisional: true
goal: >
  A stranger's first run of ./validate.sh in a fresh clone is green ten times out of ten, and a
  pooled failure that passes alone is reported as contention naming the suite — never as a failed
  run — with the contention source named, not retried around.
---

# GH-15 — parallel reliability in a fresh clone

## Status

| What was just completed | What's next |
|---|---|
| Capture promoted to 2-WORKING; contract authored; Ballast 0.7.0 manifest frozen | Preflight, then fire as a marathon lane on operator go |

## Bug

In a fresh clone the documented entry path produces a **different failing set on each parallel
run**; the same clone run serially is green. Issue #15 records three observed failing sets
(gh492, gh388, oracle-guard, improve-loop-qa, releases-skill, gh430, improve-loop-dogfood,
relay-dep-drift, gh292) and isolates the variable: same clone, same scrubbed environment, only
concurrency flipped — red parallel, green sequential. Every observed failure passes alone, so the
GH-528 retry contract (`validate.sh:458-469` — a pooled failure is re-run alone before being
believed, naming the contended suite) should have caught each one. None was caught. The defect is
in an existing mechanism, not a missing one: no test-infrastructure rewrite, no weakened
assertions.

Observed again 2026-08-16 during this run's own Part 0 gate: `gh388-run-log-durability` failed in
parallel AND alone in a clone located under `/tmp` — that instance was environmental (the clone's
own transcript root classifies non-durable under a tmp root), resolved by relocating the clone;
recorded here because it is the same suite family the issue names and a reminder that "fails
alone" must always be followed by "in what environment".

## Source of truth

- GitHub issue: [HiQS-Suite/XYZ-forge#15](https://github.com/HiQS-Suite/XYZ-forge/issues/15)

## Acceptance

- [ ] Determine empirically whether the `validate.sh:458-469` retry executes for these failures; record
  the observation either way.
- [ ] A pooled failure that passes when re-run alone is reported as **contention**, naming the suite —
  never counted as a failed run.
- [ ] Ten consecutive parallel runs in a fresh clone under a scrubbed environment produce zero failing
  runs, or produce only contention warnings.
- [ ] The contention source itself is named in the fix (which shared resource, which suites), not merely
  retried around.
- [ ] A recorded negative control demonstrates the check failing when the fix is reverted — per the
  standing rule that a check never observed failing is not evidence.
- [ ] A recorded negative control exists at `test/baselines/GH-15-parallel-contention-negative-control.md`

## Acceptance — deviations from the issue

- [added] A recorded negative control exists at `test/baselines/GH-15-parallel-contention-negative-control.md` — reason: pins this contract's staleness probe and the issue's negative-control criterion at the same file, so the acceptance and the probe cannot drift apart.

## Swarm Preflight Contract

```json
{
  "target":      { "repo": ".", "ref": "main" },
  "gate":        "bash validate.sh",
  "fix_probes":  [ { "type": "path_absent", "path": "test/baselines/GH-15-parallel-contention-negative-control.md" } ],
  "artifacts":   [ "validate.sh", "test/gh528-parallel-contention-retry.sh", "test/baselines/GH-15-parallel-contention-negative-control.md" ],
  "artifacts_new": ["test/baselines/GH-15-parallel-contention-negative-control.md"],
  "remediation": { "source": "issue#15", "criteria": "ten consecutive parallel fresh-clone runs green; contention named, never counted as failure" },
  "lanes":       { "agy_safe": [], "orchestrator_only": [] }
}
```

Probe polarity: `grep_absent` carries the FIX marker — the mandated negative-control record. The
lane is ready while that file does not exist and reports stale (exit 4) once it lands. NOTE for
the wave planner: this lane's artifacts include `validate.sh`, which #10's guard registration also
touches — serialize #15 and #10 into different waves.

## Verification

- Ten consecutive parallel runs in a fresh clone (durable location), scrubbed environment
  (`env -i` per the issue's isolation table), zero failing runs or contention-only warnings.
- `test/gh528-parallel-contention-retry.sh` extended to pin the retry actually firing and naming
  the suite; negative control recorded under `test/baselines/`.
