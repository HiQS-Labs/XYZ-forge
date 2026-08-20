# GH-1/GH-10 adoption ledger — require_fixture across the fixture-creating suites

Status: COMPLETE. Unaudited suites: 0.

Method (issue #10 step 1, computed on every gate run by `test/gh1-adoption-guard.sh`):
a suite is unaudited when it contains `mktemp` AND (`git -C` | ` cd `) and neither sources
`test/lib/fixture-guard.sh`, nor sources `test/_setup.sh` (which performs the adoption centrally
— it creates the shared `$WORK` sandbox, calls `fixture_guard_init`, and guards `$A`/`$B`/`$REMOTE`),
nor carries a declared in-file exemption marker.

## Adoption (2026-08-19, GH-10 lane)

- `test/_setup.sh` — central adoption for every suite that sources it (the majority).
- 35 suites mechanically: source + `fixture_guard_init` after the sandbox root, and
  `require_fixture` after every per-suite `mktemp -d` under that root.
- 7 suites by hand where the shape was not mechanical: out-of-root fixtures nested under the
  suite's pinned sandbox (find-harness `FV`, gh308-frozen-twin-guard `exc`, gh536 `LOGS`,
  meter-release mutate `TMP`, swarm-preflight late `TMP`, relay-dep-drift + relay-turn-handoff
  per-case dirs), and aider-turn's real-code file-mktemp gained `require_fixture_file`.
- Suites whose `mktemp`/`git` mentions are fixture PAYLOAD (generated stub scripts), not this
  suite's code, are covered by their `_setup.sh`/own-root adoption: gh331-cost-summary,
  xyz-harness-hooks, xyz-vendor, aider-turn.

## Declared exemptions

| Suite | Reason (also declared in-file, where a reviewer trips over it) |
|---|---|
| `test/mktemp-trap-guard.sh` | Static source audit only — mentions mktemp/git patterns as DATA; creates no filesystem fixtures, so there are no fixture paths to guard. |

## Negative controls

Recorded from the 2026-08-19 run of `test/gh1-adoption-guard.sh` (controls are part of the
suite and run on every gate): an unguarded new suite is named on the offenders list; an adopted
suite with its guard lines stripped is named; an exemption marker removed from an exempt file
puts the file back on the list while the marker's presence keeps it off. Observed: all controls
green on the adopted tree, and the derivation itself names zero unaudited suites.
