---
title: "GH-492: nothing reconciles roadmap_items against issues closed outside a merged PR"
status: active
created: 2026-09-07
updated: 2026-09-07
owner: orchestrator (Claude Code)
goal: a roadmap row converges on its GitHub issue state regardless of how that issue was closed
gh_issue: 492
source: https://github.com/HiQS-Labs/XYZ-forge/issues/492
branch: feat/gh492-roadmap-state-sweep
doc_type: bugfix
marathon: 497
lane: B
related: [GH-491, GH-355, GH-232, GH-474]
context_tags: [releases, roadmap, reconciliation, pdda]
effort: 3
complexity: 3
risk: 2
---

## Status

| What was just completed | What's next |
|---|---|
| Filed with measured drift: 33 stale rows, oldest closed 13 days earlier, corrected in `11d3e77d` | Lane B of marathon #497 — wave 3, the payload, after A and C land |

## The measurement

Every non-Completed roadmap row was checked against `gh issue view` on 2026-09-07. **33 were stale.**

```
32 closed as COMPLETED, still 'In progress' / 'Queue':
  57 182 204 205 221 222 232 233 243 246 249 251 267 271 272 273 280 314
  349 351 353 358 360 365 405 410 411 412 413 419 473 474
 1 closed as NOT_PLANNED, still 'In progress':
  123
```

While stale, `releases_app.py next` recommended GH-204, GH-205 and GH-243 as upcoming work. All
three had been finished for nearly two weeks. That is the cost worth naming: not an untidy table,
but a planning surface confidently proposing completed work.

## What is already correct — do not "fix" it

This is **not** a defect in GH-232 or `wave_reconcile`. That path works and it does update the
ledger, not merely the docs: `utils/py/wave_reconcile.py:469-506` calls `roadmap move --section`
with `Completed` / `Deferred · vision`, and `fetch_issue_state` (`:193`) refuses to guess when `gh`
is unavailable rather than writing a wrong state.

The gap is the **trigger**. `wave_reconcile` is PR-driven, so an issue closed any other way is
never considered:

- closed by hand after the work landed under a different PR
- closed as a duplicate, or as `NOT_PLANNED`
- closed by a PR whose body did not link it in a recognised form
- closed by a PR that merged while reconciliation was skipped or failed

No other surface covers it. `releases roadmap sync` is one-way from legacy `ROADMAP.md` into
`roadmap_items` — it mirrors a markdown file, not GitHub. `pdda.sh issue-doc-sync` reads
`roadmap_items.doc_path` but only to check **document location**; it warns about docs stranded in
`2-WORKING` and says nothing about a row's section.

## Plan

1. New verb `releases roadmap reconcile-state [--dry-run]`: for each row whose section is not
   terminal, read the issue's `state` and `stateReason`; move `CLOSED/COMPLETED` → `Completed` and
   `CLOSED/NOT_PLANNED` → `Deferred · vision`.
2. Reuse `wave_reconcile.fetch_issue_state`'s refusal semantics verbatim. An unknowable state must
   never be written as a guess — that is the property which makes an automated sweep safe at all.
3. Validate the target section through lane A's shared vocabulary, not a second copy of the list.
4. Use lane C's `updated_at` to skip rows that cannot have moved, rather than re-querying every row
   on every run.
5. Call it from the existing post-merge chain so drift cannot accumulate between PRs; `--dry-run`
   stays the reviewable default for a manual run.
6. Have `pdda.sh issue-doc-sync` warn on section drift too — it already holds the issue number and
   a `gh` cache, so it is one query from reporting this class beside the doc-location warnings.

## Acceptance

- A fixture with a closed issue and an `In progress` row is corrected; the same fixture with an
  open issue is left alone.
- A `NOT_PLANNED` closure lands in `Deferred · vision`, not `Completed`.
- Red control: `gh` unavailable makes the sweep refuse rather than write a guessed state.
- The sweep is idempotent — a second run is a no-op.
- `--dry-run` writes nothing, proven by an unchanged `releases.db` mtime and digest.

## Swarm Preflight Contract

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [ { "type": "path_absent", "path": "test/gh492-roadmap-state-sweep.sh" } ],
  "artifacts":     [ "utils/py/releases_app.py", "utils/pdda/pdda.sh", "test/gh492-roadmap-state-sweep.sh" ],
  "artifacts_new": [ "test/gh492-roadmap-state-sweep.sh" ],
  "remediation":   { "source": "self#plan", "criteria": "a closed-issue row is corrected and an open-issue row is untouched; NOT_PLANNED lands in Deferred · vision; gh unavailable refuses rather than guesses; a second run is a no-op" },
  "lanes":         { "agy_safe": [ "utils/py/releases_app.py", "utils/pdda/pdda.sh", "test/gh492-roadmap-state-sweep.sh" ], "orchestrator_only": [ "validate.sh" ] }
}
```

## Dependency note for the runner

This lane is **third by necessity, not by preference**. Building the sweep before lane A means it
validates against a copy of the section list, which is the drift A exists to close. Building it
before lane C means every run re-reads every row. Neither is fatal, both are rework.
