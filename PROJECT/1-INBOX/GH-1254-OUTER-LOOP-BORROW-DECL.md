---
gh_issue: 1254
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1254
title: "Outer loop (#1248): borrow declared supervision and cache-warmth dispatch from clodex"
status: Proposed (1-INBOX — not yet active)
created: 2026-10-29
owner: unassigned
doc_type: feature
complexity: 2
risk: 2
effort: 3
phases: 1
ratings_provisional: true
non_goals:
  - no Clodex dependency
  - no intent parsing
  - no agent-to-agent messaging
  - no change to jog/marathon dispatch
  - no new test files (GH-831)
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1248
goal: >
  Borrow declared supervision (FACTORY_SUPERVISED=1) and cache-warmth dispatch into the #1248 outer loop primitive.
---

## Key concepts

- Declared-not-detected supervision: explicit `FACTORY_SUPERVISED=1`, refusing restart if undeclared.
- Cache-warmth-aware dispatch: record cache tokens, evaluate cold TTL, defer non-urgent items for cold arms.

## Status

| What was just completed | What's next |
|---|---|
| Captured via intake for project **XYZ-forge** → repo `XYZ-forge`. The GitHub issue is the signal stream; this doc is the in-repo capture. | Run Phase 0 explore pass before promoting to `2-WORKING`. |

## Idea

Borrow two high-value operational patterns from Clodex into the #1248 outer-loop primitive:
1. Declared-not-detected supervision: check `FACTORY_SUPERVISED=1` instead of inferring from PID/launchd.
2. Cache-warmth-aware dispatch: track prompt cache token states and defer low-priority calls when cache is cold.

## Why

Improves reliability and token efficiency of long-running autonomous software factory sessions without adding heavy orchestration dependencies.

## Phase 0 — Explore & scope

### Checklist

- [ ] Add `FACTORY_SUPERVISED` check to tick/watchdog in `utils/py/harness.py`.
- [ ] Enforce restart refusal when supervision is undeclared.
- [ ] Instrument cache-read vs cache-creation tokens in `#1248` telemetry.
- [ ] Add `urgent` flag and cold-context deferral logic.

### QA checklist — Phase 0

- [ ] Undeclared supervision causes self-restart to refuse with recorded receipt reason.
- [ ] Non-urgent items aimed at cold context defer up to configured slot limit; urgent items run immediately.
- [ ] No new test files (GH-831); verified against existing python layer test suite.

## Ratings rationale

pri 60 / sev 40 / appeal 65 / effort 50 (extends factory-primitive resilience and cost efficiency).

## Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "python3 -m pytest test/test_python_layer.py",
  "fix_probes": [
    { "type": "grep_absent", "path": "utils/py/harness.py", "pattern": "FACTORY_SUPERVISED",
      "note": "pre-fix: harness.py does not check FACTORY_SUPERVISED declaration" }
  ],
  "artifacts": [ "utils/py/harness.py" ],
  "remediation": {
    "source": "issue#1254",
    "criteria": "Check FACTORY_SUPERVISED in tick/watchdog and implement cache-warmth dispatch telemetry; no new tests (GH-831)."
  }
}
```
