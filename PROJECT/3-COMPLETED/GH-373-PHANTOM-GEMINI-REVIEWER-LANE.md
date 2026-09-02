---
gh_issue: 373
source: https://github.com/HiQS-Labs/XYZ-forge/issues/373
title: "Reviewer validation accepts gemini* but no gemini lane exists (no GEMINI_AGENT routing, no gemini-turn.sh)"
goal: >
  the accepted reviewer set, the router, and --help must agree
status: Complete
# Staged 2026-09-01 by the LTVera marathon orchestrator alongside the marathon plan at
# PROJECT/2-WORKING/2026-09-01-xyz-harness-quickwins/ — commit to XYZ-forge when the
# marathon fires. Exempt from ROADMAP parking while it travels inside the plan bundle.
roadmap_exempt: true
created: 2026-09-01
updated: 2026-09-02
owner: unassigned
doc_type: capture
complexity: 1
risk: 1
effort: 1
ratings_provisional: true
related:
  - "all seven findings originate from one live run: the 2026-09-01 LTVera health-and-isolation marathon"
---

# GH-373 — Reviewer validation accepts gemini* but no gemini lane exists (no GEMINI_AGENT routing, no gemini-turn.sh)

## Status

| What was just completed | What's next |
|---|---|
| Capture doc authored with preflight contract. | Marathon phase execution. |

Capture of [XYZ-forge issue #373](https://github.com/HiQS-Labs/XYZ-forge/issues/373).

`--reviewer` validation accepts `codex*|gemini*|agy*` (utils/py/marathon_drive.py,
relay-automation/marathon-drive.sh, bin/marathon-yaml) but `route_agent` has no gemini
branch, marathon-agent.sh has no GEMINI lane, and relay-automation/ ships no
gemini-turn.sh — so `reviewer: gemini` dies in routing with a message that never
mentions gemini. The --help text actively invites the configuration.

## STOP — two of the three surfaces are ALREADY FIXED (verified on `development` @ b56e32d3)

This capture was written against `development @ 6fe36fbb`, but the fix for two of the three
surfaces had already landed there in **XYZ-forge PR #367 (GH-346 Phase 2)**. Re-read before
starting: most of the described work is done, and the contract below pointed the builder at the
two files that no longer need it.

| Surface | State today | Evidence |
|---|---|---|
| `utils/py/marathon_drive.py` `route_agent` | **FIXED** — no gemini branch; a comment records the removal | GH-346 Phase 2 |
| `bin/marathon-yaml` (+ `src/marathon-yaml.js`) | **FIXED** — the reviewer regex is `/^(codex\|agy)/` at `:99` | GH-346 Phase 2 |
| `relay-automation/marathon-drive.sh` (FROZEN twin) | **STILL WRONG** — accepts `gemini*` at `:795`, advertises it at `:33`, `:593`, `:772`, `:794` | verified 2026-09-01 |

## Remediation — what actually remains

**Only the frozen Bash twin.** Drop the dead `gemini*` arm at `marathon-drive.sh:795` and correct
the four help/comment lines that advertise a lane which cannot run. Do NOT touch
`marathon_drive.py` or `bin/marathon-yaml` for this issue — they are already correct, and editing
them to satisfy a stale probe would be a change made to please a checkbox.

**This is a frozen-twin edit (GH-308) and needs a `Frozen-twin-exception:` trailer on the commit.**
That is the whole reason this residue survived #367: the Python side was fixed and the twin was
deliberately left alone. Decide explicitly whether the exception is worth spending here, or whether
the honest move is to close #373 as "fixed where it can dispatch" and let the twin retire with
GH-308. Either is defensible; silently re-fixing the Python side is not.

## Contract Rescope Notes

The original contract probed `grep_absent GH-373` in `utils/py/marathon_drive.py` and listed that
file plus `bin/marathon-yaml` as the artifacts. Both are already fixed, and the one file that still
carries the defect — `relay-automation/marathon-drive.sh` — was in `lanes.agy_safe` but **not in
`artifacts`**. A builder following it would have edited correct code and left the real defect in
place, then satisfied the probe by adding a marker comment to a file it did not need to change.

The fix MUST leave a `GH-373` marker comment at the primary change site — the
preflight probe below keys on it.

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
      "path": "utils/py/marathon_drive.py",
      "pattern": "GH-373"
    }
  ],
  "artifacts":   ["utils/py/marathon_drive.py"],
  "remediation": {
    "source": "issue#373",
    "criteria": "Reviewer validation accepts gemini* but no gemini lane exists"
  },
  "lanes": {
    "agy_safe": [
      "utils/py/marathon_drive.py"
    ],
    "orchestrator_only": []
  }
}
```

## Lessons Learned (For Future Agents)

- CLI help text and option validation must agree with actual dispatch capabilities. Accepting options for unimplemented backends (such as phantom gemini routing) leads to confusing failures down the pipeline.
