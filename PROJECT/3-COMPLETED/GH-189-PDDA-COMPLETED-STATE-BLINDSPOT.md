---
gh_issue: 189
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/189
title: "PDDA: sweeping a doc to 3-COMPLETED silences the only issue-state check watching it — shipped items can sit in ROADMAP as 'ready to fire' indefinitely"
status: Fixed and verified 2026-07-17 via a marathon lane, merged to `development`. Surfaced 48
  stale 3-COMPLETED docs + 15 real ROADMAP/issue-state mismatches as new findings (not fixed here).
created: 2026-07-08
updated: 2026-07-17
owner: noel
doc_type: bugfix
goal: >
  Close the PDDA blind spot in which moving a doc from 2-WORKING to 3-COMPLETED (the remediation
  PDDA itself recommends) removes it from the only check comparing it to GitHub issue state, so a
  shipped item's ROADMAP.md entry can keep advertising "ready to fire" indefinitely while
  `pdda.sh run` reports "all checks passed".
complexity: 2
risk: 2
effort: 2
phases: 1
ratings_provisional: false
non_goals:
  - Not making PDDA a blocking gate on ROADMAP status drift — warn-only, matching the existing issue-doc-sync severity
  - Not requiring network access — both checks must degrade to the existing "state unavailable, sync not evaluated" INFO path when gh is offline and no cached state exists
  - Not restructuring the 1-INBOX → 2-WORKING → 3-COMPLETED lifecycle itself; only extending what is observed
related:
  - utils/pdda/pdda.sh
  - utils/pdda/pdda-lib.sh
  - ROADMAP.md
---

## Status

| What was just completed | What's next |
|---|---|
| **Fixed and verified 2026-07-17** via a marathon lane (worktree-isolated Sonnet subagent). Added `check_roadmap_issue_state()` (new, registered as `pdda-check-roadmap-issue-state`, reuses the existing `_pdda_issue_state_table` resolver) and a new direction (c) in `check_issue_doc_sync()` scanning `3-COMPLETED` via a new `pdda_list_completed_docs()` helper (mirrors `pdda_list_working_docs()`). Both warn-only, both degrade to INFO offline. 7 new assertions in `test/pdda-roadmap-coverage.sh` (all 10 pass). Independently re-verified on the marathon branch: `bash validate.sh` 113/114 (only pre-existing tracked `acorn-extract.sh`/`worktree-isolation.sh` environmental reds); ran the new checks against this repo's own real docs — genuinely found 48 stale `3-COMPLETED` status words and 15 real ROADMAP/issue-state mismatches (not false positives; spot-checked #211: ledger says ✅ SHIPPED, issue is actually still OPEN — filed as a follow-up). | Closed out — nothing further for this lane. Follow-up: reconcile the 48+15 newly-surfaced drift findings (separate cleanup pass, not part of this lane). |

## Problem (grounded in the current code)

`check_issue_doc_sync()` (`utils/pdda/pdda.sh:507-542`) iterates **only** `pdda_list_working_docs()`,
scoped to `PDDA_WORKING_DIR` = `2-WORKING` (`utils/pdda/pdda-lib.sh:178`).

Its **direction (a)** fires on *issue CLOSED + doc still in `2-WORKING`*, and the remediation it
prints is a `git mv` into `3-COMPLETED` (`pdda.sh:524-531`):

```bash
"issue #$num is CLOSED but the doc is still in 2-WORKING — recommend: git mv ... $rel_target"
```

**Performing that remediation removes the doc from the check's scan set permanently.**
`PDDA_COMPLETED_DIR` (`pdda-lib.sh:10`) is referenced *only* to build that recommendation string —
no check ever reads a doc out of `3-COMPLETED`. Direction (b) (doc declares itself done while the
issue is still OPEN, `pdda.sh:534-541`) is likewise `2-WORKING`-only.

Independently, nothing validates the **`ROADMAP.md` ledger entry's status marker** against issue
state. `check_roadmap()` (`pdda.sh:227-267`) lints ROADMAP *structure* only — GFM task-list items,
execution-detail headings, and line/heading caps.

So the sweep half of the workflow ("move the doc") is enforced, while the flip half ("update
ROADMAP/CHANGELOG status") is not — and completing the enforced half silences the only check that
was watching.

## Reproduction (observed, not hypothetical)

At `9e2ce73`, before any correction:

- `PROJECT/3-COMPLETED/GH-107-CONTAINMENT-OFFLANE-TOOLCACHE.md` frontmatter → `status: captured 2026-07-04, rated …`
- `gh issue view 107 --json state` → `CLOSED`
- `ROADMAP.md:99` → `🆕 **captured 2026-07-04 · rated — KERNEL zone, Opus-serial**`
- `ROADMAP.md:40` → `**Ready to fire:** Marathon Plan C's Wave 1 (…) + its kernel track (#107, Opus-serial).`
- `utils/pdda/pdda.sh run` → `PDDA run complete: all checks passed`

All eight Plan C issues (#106, #107, #108, #116, #117, #124, #126, #127) were CLOSED for the whole
four-day window. The fix itself had been live at `relay-automation/relay-turn-lib.sh:345-364` since
`524d345`, `test/worktree-isolation.sh` 31/31 green.

## Why this matters

This is the exact failure class PDDA exists to prevent: the ledger asserting work is unbuilt when it
shipped days earlier. It nearly caused a **duplicate rebuild of a kernel-zone, risk-4 file**
(`relay-turn-lib.sh`, the containment core), which this repo's own convention routes to a serial
Opus track precisely because a mistake there is repo-wide rather than lane-scoped.

## Fix

Two deterministic checks, both reusing the existing `_pdda_issue_state_table` and
`_pdda_is_terminal_word` helpers, both **warn-only** (matching `issue-doc-sync`'s severity) and both
degrading to the existing `state unavailable … sync not evaluated` INFO path when `gh` is offline:

1. **`pdda-check-roadmap-issue-state`** — for each `ROADMAP.md` ledger entry carrying a `#<n>` issue
   link: warn when the issue is `CLOSED` but the entry's status marker is non-terminal
   (🆕 / `captured` / `Ready to fire`); and inversely, warn when an entry reads ✅ / `SHIPPED` while
   the issue is still `OPEN`.
2. **Extend `check_issue_doc_sync` to `3-COMPLETED`** — warn when a doc in `3-COMPLETED` has a
   non-terminal frontmatter `status` lead word (e.g. `captured`). This is precisely the inverse of
   the existing direction (b), and reuses `PDDA_TERMINAL_STATUS_WORDS` unchanged.

Either check alone would have caught all eight items on 2026-07-04, the same day the sweep ran.

## Definition of done

- [ ] `pdda-check-roadmap-issue-state` added and registered in `PDDA_DETERMINISTIC_CHECKS`.
- [ ] `check_issue_doc_sync` also scans `3-COMPLETED` for non-terminal frontmatter `status`.
- [ ] Both checks are warn-only and degrade to INFO (`sync not evaluated`) with `gh` offline and no
      cached state — no new hard network dependency in `pdda.sh run`.
- [ ] A regression fixture reproducing the GH-107 shape (doc in `3-COMPLETED`, `status: captured`,
      issue CLOSED, ROADMAP entry 🆕) is flagged by both checks.
- [ ] The inverse shape (doc `status: shipped`, issue OPEN) still flags via existing direction (b).
- [ ] `utils/pdda/pdda.sh run` green on this repo after the ROADMAP reconciliation already landed.
- [ ] `bash validate.sh` no worse than baseline (the two known environmental reds — `acorn-extract.sh`
      with npm `acorn` absent, `python:test_python_layer.py` with `pytest` absent — are pre-existing).

## Reversibility & blast radius

Low. Both changes are additive, warn-only checks in the doc-governance layer; neither touches the
harness runtime, the containment kernel, or any turn-taking path. Worst case is a noisy warning,
which is strictly better than the silent drift being fixed. No `decisions/` record required — this is
not a kernel-zone change.

## Provenance

Surfaced 2026-07-08 while acting on an operator request to extract and build Marathon Plan C's `#107`
kernel track standalone. The verification step (confirm the item is genuinely unbuilt before
building it) found the work already shipped and merged, and traced the four-day-stale ledger to this
scan-scope gap rather than to operator error. The accompanying reconciliation was **doc-only** —
nothing was rebuilt.

## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash validate.sh",
  "fix_probes": [
    { "type": "grep_absent", "path": "utils/pdda/pdda.sh", "pattern": "check_roadmap_issue_state" },
    { "type": "grep_absent", "path": "utils/pdda/pdda-lib.sh", "pattern": "pdda_list_completed_docs" }
  ],
  "artifacts": [
    "utils/pdda/pdda.sh",
    "utils/pdda/pdda-lib.sh"
  ],
  "remediation": {
    "source": "issue#189",
    "criteria": "(1) new check_roadmap_issue_state() added + registered in PDDA_DETERMINISTIC_CHECKS: warns when a ROADMAP.md ledger #<n> entry's status marker is non-terminal but the issue is CLOSED, or terminal (SHIPPED) while the issue is OPEN. (2) check_issue_doc_sync() extended via a new pdda_list_completed_docs() helper (mirroring pdda_list_working_docs) to also warn when a doc in 3-COMPLETED still carries a non-terminal frontmatter status. (3) both warn-only, both degrade to the existing 'state unavailable ... sync not evaluated' INFO path when gh is offline/no cached state. (4) a regression fixture reproduces the GH-107 shape (3-COMPLETED doc with status: captured, issue CLOSED, ROADMAP entry still non-terminal) and is flagged by both checks; the inverse shape (status: shipped, issue OPEN) still flags via the existing direction (b). (5) bash validate.sh green, no worse than the pre-existing #208/acorn/pytest environmental reds."
  },
  "lanes": { "agy_safe": [ "utils/pdda/pdda.sh", "utils/pdda/pdda-lib.sh" ], "orchestrator_only": [] }
}
```
