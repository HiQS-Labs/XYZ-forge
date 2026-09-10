---
gh_issue: 423
source: https://github.com/HiQS-Labs/XYZ-forge/issues/423
title: "GH-423: releases roadmap render — emit the DB as the ledger markdown the planner parses"
status: 2-WORKING
created: 2026-09-04
updated: 2026-09-08
owner: unassigned
goal: "a render verb emits roadmap_items as ledger markdown that marathon-plan parses unchanged"
doc_type: bugfix
complexity: 1
risk: 1
effort: 1
phases: 1
marathon: gh-490
related:
  - "https://github.com/HiQS-Labs/XYZ-forge/issues/490 — marathon umbrella"
---


## Status

| What was just completed | What's next |
| --- | --- |
| Promoted from 1-INBOX with a swarm-preflight contract; lane of marathon gh-490 | Implement per the contract; lane brief in PROJECT/2-WORKING/MARATHON-PLAN-2026-09-08.md |

# GH-423: the renderer GH-418 actually needs


## Why this exists as its own issue

GH-418 has been repeatedly summarized as having three options, one of which was "accept
`QUEUE_PLAN_ROADMAP` as a documented shim." **That option is empty.** `marathon_plan.py:126` takes a
file path:

```python
roadmap = os.environ.get("QUEUE_PLAN_ROADMAP", os.path.join(root, "ROADMAP.md"))
```

and no file in the tree renders `roadmap_items` in the shape the planner parses. There is nothing to
point the shim at. GH-418 depends on a feature that does not exist; this is that feature.

## Why it is cheap

The two parsers already agree. `_marathon_plan.py`'s `_is_ledger_bullet` is a deliberate mirror of
`releases_app.py`'s, synchronized by hand after the mismatch broke a real repo — the engine's own
comment records it:

> *"a ROADMAP written entirely in link bullets parsed as ZERO items and the run died EngineExit(3)
> … Measured on LTVera-Pandas 2026-09-01, where it blocked wave_reconcile for four merged PRs."*

Two consumers, one grammar. And `roadmap_items` already stores `raw_text` — **the original ledger
bullet, verbatim**. So the renderer is a `## Ledger` heading, section grouping, and each row's
`raw_text` in `position` order. It is a replay of stored text, not a markdown generator that can
drift from what the grammar expects.

## Why a renderer, not a source branch in the engine

`_marathon_plan.py` is ~64KB and drives every marathon. A renderer leaves it byte-unchanged, is
independently falsifiable (render → parse → compare, no marathon involved), and serves the nine
other skills that still read the file — which an engine-internal branch would not.

## Proof — §13

**Red first:** against today's DB, `marathon_plan.py` must be observed *failing* to surface a
DB-only item. Pick one of the 37 rows with no `ROADMAP.md` line and record the run that omits it,
as a transcript in `test/baselines/` — not a sentence asserting a control happened.

**Round-trip, both parsers:**

- render → `_marathon_plan._parse_ledger` → parsed set equals the DB rows by `gh_number` and `title`
- render → `releases_app._is_ledger_bullet` → same count. If the two ever disagree on the
  renderer's own output, that is the LTVera bug again and this is where it should surface.

**Greens:**

- a row with no `gh_number` (a `TMP-` parked item) renders without breaking the parse
- a row with empty `raw_text` falls back to a synthesized bullet rather than emitting a blank line
  that silently drops the item
- two runs over an unchanged DB are byte-identical
- **`--out` refuses to overwrite a tracked `ROADMAP.md`.** A renderer that can target the frozen
  file is one typo away from un-freezing it and re-creating the two-sources problem this arc exists
  to end.

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
      "path": "utils/py/releases_app.py",
      "pattern": "roadmap_render",
      "note": "bug evidence \u2014 must fire unfixed at pre-work time"
    },
    {
      "type": "path_absent",
      "path": "test/gh423-roadmap-render.sh",
      "note": "new lane artifact \u2014 must not exist yet"
    },
    {
      "type": "path_absent",
      "path": "test/baselines/GH-423-negative-control.md",
      "note": "new lane artifact \u2014 must not exist yet"
    }
  ],
  "artifacts": [
    "utils/py/releases_app.py",
    "test/gh423-roadmap-render.sh",
    "test/baselines/GH-423-negative-control.md"
  ],
  "remediation": {
    "source": "issue#423",
    "criteria": "`releases roadmap render` writes ledger markdown that marathon_plan.py's parser accepts; pinned by the new suite"
  },
  "lanes": {
    "agy_safe": [
      "utils/py/",
      "utils/timeline/",
      "test/"
    ],
    "orchestrator_only": []
  },
  "artifacts_new": [
    "test/baselines/GH-423-negative-control.md",
    "test/gh423-roadmap-render.sh"
  ]
}
```

## Acceptance

- `releases roadmap render` writes ledger markdown that `marathon_plan.py`'s existing parser accepts, unchanged.
- Render output covers all `roadmap_items` rows, including the DB-only ones.
- Render → plan round-trip pinned by a new suite.

## Acceptance — reviewer-tightened criteria (CodeRabbit round 1)

- [ ] Two consecutive renders are byte-identical.
- [ ] The verb refuses to overwrite a tracked `ROADMAP.md`; `utils/py/_marathon_plan.py` is not modified.
- [ ] Render output is compared against BOTH parsers: `_marathon_plan._parse_ledger` and the planner's own reader.

## Merge evidence

- PR #495 merged 2026-09-10 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
