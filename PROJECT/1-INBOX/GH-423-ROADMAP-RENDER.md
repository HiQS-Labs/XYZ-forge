---
title: releases roadmap render — emit the DB as ledger markdown, the missing verb GH-418 depends on
status: Proposed (1-INBOX — not yet active)
created: 2026-09-04
owner: noelsaw1
gh_issue: 423
source: https://github.com/HiQS-Labs/XYZ-forge/issues/423
doc_type: feature
complexity: 1
risk: 1
effort: 1
phases: 1
ratings_provisional: true
non_goals:
  - Changing utils/py/_marathon_plan.py at all.
  - Wiring the planner to use the renderer — that is GH-418, which this unblocks.
  - Retiring ROADMAP.md — GH-269.
  - Any new file other than the test and its baseline. The verb sits beside `roadmap list`.
related:
  - GH-418 (blocked by this; becomes a three-line change once this lands)
  - GH-269 (nine skills still read ROADMAP.md and need the same artifact)
  - GH-421 (post-merge reconciliation — the writer half of the same flip)
goal: >
  Add `releases roadmap render` to releases_app.py, emitting roadmap_items as a `## Ledger`
  document in the grammar both existing parsers already accept, so the marathon planner (and the
  nine skills that still read ROADMAP.md) have a DB-backed file to read.
---

# GH-423: the renderer GH-418 actually needs

> **1-INBOX capture**, not an active-work doc. On promotion, create the status table.

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
  "target":      { "repo": ".", "ref": "development" },
  "gate":        "bash validate.sh",
  "fix_probes":  [ { "type": "grep_absent", "path": "utils/py/releases_app.py", "pattern": "roadmap_render" } ],
  "artifacts":   [
    "utils/py/releases_app.py",
    "test/gh423-roadmap-render.sh",
    "test/baselines/GH-423-negative-control.md"
  ],
  "remediation": { "source": "issue#423", "criteria": "`releases roadmap render` emits roadmap_items as a ## Ledger document; both existing ledger-bullet parsers agree on its output and recover every row; rendering twice over an unchanged DB is byte-identical; --out refuses to write a tracked ROADMAP.md; _marathon_plan.py is byte-unchanged" },
  "lanes":       { "agy_safe": [], "orchestrator_only": [] }
}
```
