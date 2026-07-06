---
gh_issue: 150
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/150
title: "marathon-plan: docOf() picks wrong doc (first PROJECT link, not the GH-<n> pointer) → false 'unrated'"
status: Active (2-WORKING) — scoped + contracted 2026-07-06
created: 2026-07-06
updated: 2026-07-06
owner: noel
doc_type: bugfix
complexity: 2
risk: 1
effort: 2
phases: 1
ratings_provisional: false
related:
  - utils/marathon-plan.sh
  - test/marathon-plan.sh
---

# GH-150 · marathon-plan docOf() resolves the wrong doc → false "unrated"

## Status

| What was just completed | What's next |
|---|---|
| **2026-07-06 — root-caused + scoped.** `docOf()` falls back to `mds[0]` (first `PROJECT/**.md` link in a ledger bullet) when the item has no `2-WORKING` doc; entries that cite a completed `MARATHON-PLAN-*.md` before their `→ GH-<n>` pointer resolve to that unrelated doc and read no ratings → false `unrated`. Confirmed live on **#109** (rated doc, still flagged); **#110** was fixed incidentally by promotion to `2-WORKING`. `frontmatter()` itself is correct. | Fire the lane: teach `docOf()` to prefer the `GH-<item.gh>-*.md` link in any directory ahead of `mds[0]`; add a hermetic regression to `test/marathon-plan.sh`; `validate.sh` green. |

## Bug

`utils/marathon-plan.sh` `docOf(item)`:

```js
const pick = mds.find((t) => /2-WORKING\/GH-\d+-/i.test(t))
          || mds.find((t) => /2-WORKING\//.test(t))
          || mds[0];   // blind first-link fallback — the bug
```

When the item's capture doc lives in `1-INBOX` or `3-COMPLETED` (not `2-WORKING`), both `2-WORKING` branches miss and `docOf` returns `mds[0]` — the **first** `PROJECT/**.md` link in the bullet. Ledger entries routinely cite a completed `MARATHON-PLAN-YYYY-MM-DD.md` in their prose before the trailing `→ GH-<n>-NAME.md` pointer, so `mds[0]` is that unrelated (ratings-less) doc and the item is mis-flagged `unrated`.

## Fix

Insert a preference, before the `mds[0]` fallback, for a link whose basename matches the item's own issue number (`GH-<item.gh>-*.md`) in **any** directory. Keep the `2-WORKING/GH-\d+-` priority first so promotion still wins. Fall back to `mds[0]` only for issue-less notes.

## Definition of done

- `docOf()` resolves to the item's own `GH-<n>-*.md` doc regardless of directory, ahead of `mds[0]`.
- Hermetic regression in `test/marathon-plan.sh` (labelled with `docOf`): a fixture ledger entry links a ratings-less distractor `PROJECT/**.md` **before** the `→ GH-<n>` pointer, with the real capture doc rated — assert the item is **rated**, not `unrated`.
- No regression in existing `test/marathon-plan.sh` cases; `bash validate.sh` green.

## Swarm Preflight Contract

```json
{"target":{"repo":".","ref":"main"},"gate":"bash test/marathon-plan.sh","fix_probes":[{"type":"grep_absent","path":"test/marathon-plan.sh","pattern":"docOf"}],"artifacts":["utils/marathon-plan.sh","test/marathon-plan.sh"],"remediation":{"source":"self#definition-of-done","criteria":"docOf() prefers a link whose basename matches the item's own GH-<n> in any directory ahead of the mds[0] fallback, keeping the 2-WORKING/GH-\\d+- priority first; a hermetic regression in test/marathon-plan.sh (labelled 'docOf') builds a fixture ledger entry linking a ratings-less distractor PROJECT doc BEFORE the -> GH-<n> pointer and asserts the item is rated, not unrated; bash test/marathon-plan.sh green; validate.sh green."},"lanes":{"orchestrator_only":[]}}
```
