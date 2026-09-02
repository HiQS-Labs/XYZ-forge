---
gh_issue: 368
source: https://github.com/HiQS-Labs/XYZ-forge/issues/368
title: "Same-lane builder + reviewer cannot route: one env slot per model lane (AGY_AGENT) is overwritten by route_agent"
goal: >
  a builder and a reviewer on the same model lane must both be routable
status: Complete
# Staged 2026-09-01 by the LTVera marathon orchestrator alongside the marathon plan at
# PROJECT/2-WORKING/2026-09-01-xyz-harness-quickwins/ — commit to XYZ-forge when the
# marathon fires. Exempt from ROADMAP parking while it travels inside the plan bundle.
roadmap_exempt: true
created: 2026-09-01
updated: 2026-09-02
owner: unassigned
doc_type: capture
complexity: 2
risk: 2
effort: 2
ratings_provisional: true
related:
  - "all seven findings originate from one live run: the 2026-09-01 LTVera health-and-isolation marathon"
---

# GH-368 — Same-lane builder + reviewer cannot route

## Status

| What was just completed | What's next |
|---|---|
| Capture doc authored with preflight contract. | Marathon phase execution. |

Capture of [XYZ-forge issue #368](https://github.com/HiQS-Labs/XYZ-forge/issues/368).

Observed 2026-09-01 in a vendored `.xyz` marathon run (LTVera-Pandas) after the
codex workspace ran out of credits: with builder `agy` + reviewer `agy-qa`, the second
`route_agent` call overwrites `AGY_AGENT`, `marathon-agent.sh` dies with
`unknown agent 'agy'`, and even with routing fixed `agy-turn.sh` no-ops because it
re-checks exact actor equality (`actor agy is not the agy agent (agy-qa) — deferring`).
The documented fallback ("agy is the other cost-blind option") is unusable whenever
codex is unavailable, because builder and reviewer must then share the agy lane.

## Remediation

Per-actor routing: `marathon-agent.sh` matches on lane membership (prefix or a
lane list) rather than one exact id per env slot, and `agy-turn.sh` (plus its Python
twin) trusts the dispatcher instead of re-checking `RELAY_AGENT == AGY_AGENT` verbatim.
Keep the ownership guard (the claim check) — only the actor-id equality check changes.

The fix MUST leave a `GH-368` marker comment at the primary change site — the
preflight probe below keys on it.

## COUPLING ADDED 2026-09-01 — this fix will silently break the GH-346 profile resolver

`utils/py/profile_resolve.py` shipped to `development` in **XYZ-forge PR #375** hours after this
capture was written, so the bundle predates it. It resolves one operator-facing name
(`"glm 5.3 max"`) into a complete harness -> gateway -> model path, and it derives the lane set by
reading `route_agent`'s SOURCE rather than keeping a copy — deliberately, because GH-346 Phase 2
found that same lane set living in ten hand-maintained allowlists, three of which were invisible
until a test failed.

The derivation matches this exact shape (`profile_resolve.py:138`):

```python
r"agent_id\.startswith\(\s*[\"']([a-z0-9_]+)[\"']\s*\)\s*:\s*os\.environ\[\s*[\"']([A-Z0-9_]+)[\"']\s*\]"
```

Both fix directions this issue proposes — lane-prefix membership, or an `AGY_AGENTS` list — rewrite
that shape. The regex then matches nothing, `lanes()` returns empty, and **every profile degrades to
tier 4**: the resolver stops resolving. It will not crash and will not block a turn (by design,
every tier is skippable), and it prints `no lanes derived from route_agent()` on stderr — but a
degradation that only announces itself in stderr on a working command is the kind that goes
unnoticed for weeks.

**What p1 must do:** update the derivation in `profile_resolve.py` in the same change as
`route_agent`, and keep them in lockstep. `test/gh346-profile-resolve.sh` already asserts
`resolver lane set == route_agent's, derived not copied` — so this fails LOUDLY in the gate rather
than drifting, which is why the test exists. Both files are added to the artifacts below.

Do not "fix" this by hardcoding the lane list in the resolver. That would make it the eleventh
allowlist, which is the defect GH-346 spent three phases removing.

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
      "path": "relay-automation/marathon-agent.sh",
      "pattern": "GH-368"
    }
  ],
  "artifacts":   ["utils/py/marathon_drive.py", "utils/py/agy-turn.py", "relay-automation/marathon-agent.sh", "utils/py/profile_resolve.py", "test/gh346-profile-resolve.sh"],
  "remediation": {
    "source": "issue#368",
    "criteria": "Same-lane builder + reviewer cannot route: one env slot per model lane"
  },
  "lanes": {
    "agy_safe": [
      "relay-automation/marathon-agent.sh",
      "relay-automation/agy-turn.sh",
      "utils/py/agy-turn.py",
      "utils/py/marathon_drive.py",
      "utils/py/profile_resolve.py",
      "test/gh346-profile-resolve.sh"
    ],
    "orchestrator_only": []
  }
}
```

## Lessons Learned (For Future Agents)

- When builder and reviewer share the same model lane prefix (e.g. `agy` and `agy-qa`), `route_agent` must preserve both in the environment slot (comma-separated), `marathon-agent.sh` must dispatch by lane membership, and the turn shim must check set membership rather than strict string equality before deferring.
- Multi-actor lane configurations allow fallback workflows when one provider/workspace runs out of credits or encounters limits.
