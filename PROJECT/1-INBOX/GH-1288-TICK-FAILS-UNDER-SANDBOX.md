---
gh_issue: 1288
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1288
title: "factory-primitive tick fails (rc 1) under the GH-1280 sandbox profile on a clean root"
status: Parked (1-INBOX — prerequisite for a stateful factory-primitive campaign)
created: 2026-10-31
updated: 2026-10-31
owner: unassigned
doc_type: feedback
complexity: 2
risk: 1
effort: 2
phases: 1
ratings_provisional: true
non_goals:
  - Assuming a harness defect before the sandbox denial is identified
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1280
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1248
goal: >
  Name what `tick` needs that the campaign sandbox profile denies, then either widen the
  profile narrowly or document the limit. Full evidence and acceptance are in the issue.
---

## Key concepts

- GH-1280 disposition D5: clean `init` → `tick` is rc 0 unsandboxed, rc 1 under `profile-long.sb`.

## Status

| What was just completed | What's next |
|---|---|
| Captured via HQ (`/hq park`) for project **XYZ-forge** → repo `XYZ-forge`. The GitHub issue is the signal stream; this doc is the in-repo capture and back-reference. | Run Phase 0 investigation to identify sandbox denial log lines before promoting. |

## Idea

`factory-primitive tick` fails under the GH-1280 sandbox profile even on a correctly initialized run root.

## Why

Prerequisite for a stateful `factory-primitive` campaign. `tick` was excluded from fuzzing by design in GH-1280, but campaigns cannot fuzz state sequences until the denial is identified and resolved or scoped.

## Phase 0 — Explore & scope

### Checklist

- [ ] Re-run sandboxed `tick` under `profile-long.sb` and inspect macOS sandbox denial log (`log show --predicate 'sender == "Sandbox"'`).
- [ ] Inspect failed receipt in instance `state.db` / `telemetry/events.jsonl`.
- [ ] Determine whether to narrowly widen `profile-long.sb` or document why `tick` cannot run sandboxed.

### QA checklist — Phase 0

- [ ] Denied resource (path, syscall, or process spawn) named with supporting log line.
- [ ] Sandboxed clean `init` -> `tick` returns rc 0 with narrow profile change, or limit is documented.
- [ ] No new tests (GH-831).

## Ratings rationale

pri 50 / sev 40 / appeal 40 / effort 50 (prerequisite before stateful campaign).

## Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "python3 -m pytest test/test_python_layer.py",
  "fix_probes": [
    { "type": "grep_absent", "path": "utils/py/harness.py", "pattern": "sandbox_profile_tick_compat",
      "note": "pre-fix: harness.py has not documented or adapted tick execution under profile-long.sb" }
  ],
  "artifacts": [ "TESTS-RESULTS/2026-10-30+GH-1280/contracts/profile-long.sb", "utils/py/harness.py" ],
  "remediation": {
    "source": "issue#1288",
    "criteria": "Identify exact sandbox denial for tick on clean root; either widen profile narrowly or record limitation and adjust stateful campaign plan. No new tests (GH-831)."
  }
}
```

## Merge evidence

- PR #1290 merged 2026-10-31 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
