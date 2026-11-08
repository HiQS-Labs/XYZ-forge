---
gh_issue: 1296
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1296
title: "factory-primitive launch packets: lanes fail preflight on a stale artifact path or missing Preflight Contract"
status: Proposed (1-INBOX — not yet active)
created: 2026-10-31
owner: noelsaw1
doc_type: feedback
complexity: 2
risk: 1
effort: 2
phases: 1
ratings_provisional: true
non_goals:
  - no auto-repair of contracts (separate optional track)
  - no new tests (GH-831)
related:
  - #1279
  - #1298
  - #522
  - #1251
goal: >
  Packets are not emitted for lanes the live preflight would reject, or each emitted lane names its preflight result; the frozen #1279 set is re-checked with residuals reported.
---

## Key concepts

- stale paths and missing contracts pass structure checks
- live preflight is the discriminator
- fold into the #522 admission work

> **Note for plan writers:** apply the `/ponytail` lens — favor the laziest approach that actually
> works over new infrastructure, and question whether new surface needs to exist at all.

# factory-primitive launch packets: lanes fail preflight on a stale artifact path or missing lane contract

## Status

| What was just completed | What's next |
|---|---|
| PR #1324 repairs malformed contract input, path comparison, and selected capture freshness. Current-wave paired replay and independent implementation QA are retained in `TESTS-RESULTS/2026-11-08+GH-1296-review/`; full `validate.sh` passed 409/409 on reviewed runtime `a0f65126`. | Original #1279 frozen backlog is unavailable after bounded search and operator confirmation. Exact historical replay remains incomplete; current-wave evidence does not replace it. Leave #1296 open for outer inspection and final gate/publication. |

## Idea

Launch lanes that fail the preflight dry run are still emitted. See the issue for the four observed lanes.

## Why

Found by the #1279 window: #722 (moved artifact path) and #1204, #216, #446 (no Preflight Contract) passed the structure checks but failed preflight. Low severity because preflight catches them before launch; it caps how many lanes a loop can use.

## Phase 0 — Explore & scope

### Checklist

- [ ] Inspect `utils/py/harness.py` launch packet generator (`_packet`) to identify preflight check point.
- [ ] Determine whether packet generation should withhold failing lanes or flag preflight status in `brief.md`.
- [ ] Verify that stale artifact paths (#722) and missing contracts (#1204, #216, #446) are flagged before launch packet emission.

### QA checklist — Phase 0

- [ ] Lanes with failing preflight dry-runs are not presented as launchable without an explicit warning or refusal.
- [ ] No new tests added (GH-831); verified against existing python layer suite.

## Ratings rationale

pri 50 / sev 40 / appeal 50 / effort 75 (low severity because preflight catches them before launch; caps usable loop lanes).

## Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "python3 -m pytest test/test_python_layer.py && bash test/swarm-preflight.sh",
  "fix_probes": [
    { "type": "grep_absent", "path": "utils/py/harness.py", "pattern": "preflight_filter|withhold_unpreflighted",
      "note": "pre-fix: harness.py packet builder does not filter lanes by preflight readiness" }
  ],
  "artifacts": [ "utils/py/harness.py" ],
  "remediation": {
    "source": "issue#1296",
    "criteria": "Lanes that fail live preflight dry-run are either withheld or flagged in emitted launch packets; no new test file (GH-831)."
  }
}
```

## Merge evidence

- PR #1302 merged 2026-10-31 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Merge evidence

- PR #1304 merged 2026-10-31 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
