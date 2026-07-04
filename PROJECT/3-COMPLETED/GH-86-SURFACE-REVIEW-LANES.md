---
gh_issue: 86
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/86
title: marathon-plan — surface PR-review lanes so they don't silently drop
status: Shipped (`2ce409b`) — issue #86 closed 2026-07-04
created: 2026-07-02
updated: 2026-07-04
owner: noel
doc_type: enhancement
goal: >
  Add a Level 1 "Review lanes" section to marathon-plan.sh's rendered output that detects today's
  PROJECT/2-WORKING/PR-REVIEW-QUEUE-<today>.md overlay (if present) and surfaces it, so a defined
  PR-review lane is visible in the generated plan instead of only in a manual doc nothing points at.
complexity: 2
risk: 1
effort: 2
phases: 1
roadmap_exempt: false
non_goals:
  - Level 1 (surface) is the core; auto-generating review lanes from open PRs (Level 3) is a stretch, not required
  - Not auto-firing reviews headless — surfacing/tracking is enough to stop the silent drop
  - Not building Level 2 (per-lane run/not-run/verdict tracking) in this pass -- surfacing the
    overlay's existence and a link to it is the minimum that would have caught the original loss
    (the doc's own DoD says as much); tracking can be a follow-up once Level 1 is proven useful.
related:
  - utils/marathon-plan.sh
  - PROJECT/2-WORKING/PR-REVIEW-QUEUE-2026-07-02.md
  - relay-automation/relay-drive.sh
  - test/marathon-plan.sh
---

## Status

| What was just completed | What's next |
|---|---|
| **Shipped** (`2ce409b`): added `parseLanesTable()` (a dedicated parser for the overlay's `## Lanes` table, keyed by column name rather than reusing the ledger's fixed bullet shape) and a `renderQueueDoc()` section that pushes `## Review lanes (manual overlay — run via relay-xyz)` + a Lane/PR/Reviewer table only when `PR-REVIEW-QUEUE-${TODAY}.md` exists — verified zero output diff for the absent case. 2 new `test/marathon-plan.sh` scenarios (46/46 pass), `validate.sh` full-suite green at integration. Level 1 only, as scoped. | Nothing — done. Level 2 (tracking) / Level 3 (auto-generation) remain explicit non-goals, follow-up if ever wanted. |

## Problem (grounded in the current code)

`renderQueueDoc()` (`utils/marathon-plan.sh:766`) builds its markdown output section-by-section via
`o.push(...)` — `## Status`, `## The one safety rule`, `## Collision map`, `## Per-item scoring`,
`## Recommended waves`, `## Contract seams`, `## Held / flagged`, `## How to fire a lane` — every
section derived from the **ROADMAP.md build ledger**. There is no section derived from
`PROJECT/2-WORKING/PR-REVIEW-QUEUE-<date>.md`, the manual overlay where **review** lanes (a
different shape — reviewing an existing PR diff, not remediating a ledger item) live today. Nothing
in the generated plan points at that overlay's existence at all, which is exactly how two defined
review lanes (PR #79, #81) were silently never run — caught only by the operator noticing directly,
2026-07-02.

## Fix (Level 1 — surface)

Add one new section to `renderQueueDoc()`'s output, checking for
`$QUEUE_DIR/PR-REVIEW-QUEUE-${TODAY}.md` (same `QUEUE_DIR`/`TODAY` resolution `renderQueueDoc`
already uses for `MARATHON-PLAN-${TODAY}.md` itself — `utils/marathon-plan.sh:58,60,110`):

- **File absent:** no section at all (today's silent-by-default behavior for a day with no review
  queue — this is correct, not a gap; only a day *with* an overlay and nothing surfacing it was the
  bug).
- **File present:** push a `## Review lanes (manual overlay — run via relay-xyz)` section naming the
  overlay doc (linked), and — reusing the existing markdown-table parsing this file already has for
  the ROADMAP ledger (`parseBullet`/`parseLedger`, `utils/marathon-plan.sh:293-325`, generalized to
  the overlay's `## Lanes` table shape: `| Lane | PR | Reviewer | Artifact | Fire |`) — list each
  named lane by its `Lane`/`PR`/`Reviewer` columns, so an operator running `marathon-plan.sh` sees
  "there are N review lanes queued, here's the doc" without having to separately know the overlay
  convention exists.

This is Level 1 only, per the doc's own non-goals: existence + a link + the lane list is the
surfacing that would have caught the original loss; per-lane run/verdict tracking (Level 2) and
auto-generating lanes from `gh pr list` (Level 3, stretch) are explicitly out of scope here.

## Definition of done

- [x] A day with no `PR-REVIEW-QUEUE-<today>.md` renders identically to today (no new section,
  zero output diff for the common case).
- [x] A day **with** the overlay renders a `## Review lanes` section naming the doc and listing each
  lane from its `## Lanes` table.
- [x] `test/marathon-plan.sh` gets fixtures for both cases (overlay absent → no section; overlay
  present with N lanes → section lists all N).
- [x] `bash validate.sh` green.

## Reversibility & blast radius

**Trivial, leaf-level.** One new, purely additive render section in `renderQueueDoc()`; the overlay
file is read-only input (never written), and the new section only appears when the file exists — no
change to any existing section's output. Touches `utils/marathon-plan.sh`, the same shared-file zone
as #48 (collision map: `#86 → #48`, serialize) — this lane runs **first** in that zone, exactly as
Plan B's wave ordering already requires (#48 stays excluded from this firing round entirely, queued
behind this lane per its own doc).

## Swarm Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "bash test/marathon-plan.sh",
  "fix_probes": [
    { "type": "grep_absent", "path": "utils/marathon-plan.sh", "pattern": "GH-86" }
  ],
  "artifacts": [
    "utils/marathon-plan.sh",
    "test/marathon-plan.sh"
  ],
  "remediation": "In utils/marathon-plan.sh's renderQueueDoc(), add a section that checks for $QUEUE_DIR/PR-REVIEW-QUEUE-${TODAY}.md (same QUEUE_DIR/TODAY resolution already used for MARATHON-PLAN-${TODAY}.md). When absent, render nothing new (zero output diff from today's behavior). When present, push a '## Review lanes (manual overlay -- run via relay-xyz)' section linking the overlay doc and listing each lane from its '## Lanes' markdown table (Lane/PR/Reviewer/Artifact/Fire columns), reusing the existing ledger-table parsing helpers generalized to that table shape. Add test/marathon-plan.sh fixtures for both the overlay-absent (no section) and overlay-present (section lists all lanes) cases. GH-86 marker comment near the fix. Scope note: Level 1 (surface) only -- per-lane run/verdict tracking and auto-generating lanes from gh pr list are explicitly out of scope, see the doc's non_goals.",
  "lanes": {
    "agy_safe": ["utils/marathon-plan.sh", "test/marathon-plan.sh"],
    "orchestrator_only": [],
    "note": "First lane of the marathon-plan.sh shared-file zone (collision map: #86 -> #48, serialize) -- #48 stays excluded from this firing round entirely (its own consult-vetted design doc is queued behind this lane, not fired now). Parallel-safe with any other Wave 1 lane that doesn't touch utils/marathon-plan.sh."
  }
}
```

## Provenance

Two defined review lanes (PR #79, #81) were silently never run because `marathon-plan.sh` only
generates build lanes and nothing surfaces the manual `PR-REVIEW-QUEUE-<date>.md` overlay where
review lanes live — caught only by the operator noticing directly, 2026-07-02; recovered via
`relay-xyz`. Promoted to `2-WORKING` 2026-07-04 as part of Marathon Plan B Wave 1 (the 5 lanes
cleared for firing after #23/#61 removal and Plan A confirmation — see
[MARATHON-PLAN-2026-07-03-B-PARALLEL.md](MARATHON-PLAN-2026-07-03-B-PARALLEL.md)).
