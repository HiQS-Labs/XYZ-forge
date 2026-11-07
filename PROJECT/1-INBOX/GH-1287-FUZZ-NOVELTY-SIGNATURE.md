---
gh_issue: 1287
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1287
title: "GH-1280 fuzz supervisor: no-new-signal stop never fires because usage signatures echo mutated tokens"
status: Parked (1-INBOX — prerequisite for a stateful factory-primitive campaign)
created: 2026-10-31
updated: 2026-10-31
owner: unassigned
doc_type: feedback
complexity: 1
risk: 1
effort: 1
phases: 1
ratings_provisional: true
non_goals:
  - Harness or production code changes
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1280
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1248
goal: >
  Make the campaign supervisor's no-new-signal stop able to fire by signing argparse usage
  refusals on the error kind only. Full problem, evidence and acceptance are in the issue.
---

## Key concepts

- GH-1280 disposition D6; 2,302 of 2,313 signatures were usage lines.
- Campaign tooling only (`TESTS-RESULTS/2026-10-30+GH-1280/tools/supervisor.py`).

## Status

| What was just completed | What's next |
|---|---|
| Captured via HQ (`/hq park`) for project **XYZ-forge** → repo `XYZ-forge`. The GitHub issue is the signal stream; this doc is the in-repo capture and back-reference. | Run Phase 0 check on `supervisor.py` signature generation before promoting. |

## Idea

The GH-1280 campaign supervisor's "no new signal" stop never fires because argparse echoes mutated tokens in usage lines, creating thousands of pseudo-novel signatures.

## Why

Prerequisite for a stateful `factory-primitive` campaign. Bounding runs by true signal novelty rather than arbitrary mutation counts ensures runs only terminate when exploration saturates.

## Phase 0 — Explore & scope

### Checklist

- [ ] Inspect `signature()` in `TESTS-RESULTS/2026-10-30+GH-1280/tools/supervisor.py`.
- [ ] Implement signature normalization for `usage`-class lines to isolate the error kind (`unrecognized arguments`, `invalid choice`, etc.) and strip tokens.
- [ ] Replay telemetry from `runs/long/telemetry.jsonl.gz` to verify usage signature stabilization.

### QA checklist — Phase 0

- [ ] Re-scored telemetry yields small, stable set of usage signatures (tens, not thousands).
- [ ] No harness or production code changes; tooling only.
- [ ] No new tests (GH-831).

## Ratings rationale

pri 50 / sev 40 / appeal 40 / effort 30 (prerequisite before stateful campaign).

## Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "python3 -m pytest test/test_python_layer.py",
  "fix_probes": [
    { "type": "grep_absent", "path": "TESTS-RESULTS/2026-10-30+GH-1280/tools/supervisor.py", "pattern": "normalize_usage_signature|argparse_error_kind",
      "note": "pre-fix: supervisor does not strip echoed tokens from usage signatures" }
  ],
  "artifacts": [ "TESTS-RESULTS/2026-10-30+GH-1280/tools/supervisor.py" ],
  "remediation": {
    "source": "issue#1287",
    "criteria": "Give usage-class cases a signature built from argparse error kind alone with echoed tokens removed. Re-scoring long-run telemetry yields tens of stable usage signatures; no new test files (GH-831)."
  }
}
```

## Merge evidence

- PR #1290 merged 2026-10-31 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
