---
title: "GH-481: consult.sh's agy lane answered from a months-old ~/.gemini scratch copy, not the throwaway worktree"
status: Parked
created: 2026-09-07
updated: 2026-09-07
owner: unassigned
goal: an advisor lane in consult.sh reads the worktree it was given, or fails loudly — never a stale copy of the repo found elsewhere on disk
gh_issue: 481
source: https://github.com/HiQS-Labs/XYZ-forge/issues/481
doc_type: bug
---

# GH-481 — a consult advisor answered from the wrong tree, confidently

## What happened

During the GH-474 adjudication, `consult.sh` fanned out to codex and agy in isolated throwaway
worktrees. codex read the real tree and its citations checked out. **agy answered that the entire
premise was fabricated**, and every checkable claim it made was false against the live tree:

| agy claimed | Actual |
| --- | --- |
| `AGENTS.md` has zero references to the dashboard | 2 |
| `LOCAL_DASHBOARD_STALE` does not exist | 2 occurrences in `utils/hq/hq-lib.sh` |
| `ROADMAP.md` is the canonical 252K source of truth | the file does not exist — GH-269 retired it |
| 0 commits in 14 days, last touched Aug 8 | 94 commits, last touched 2026-09-06 |
| no `releases_app.py` CLI exists | 5,127 lines |
| no `dashboard-staleness-guard.sh`, only a test | the hook exists and ran that night |

## Root cause, located

`/Users/noelsaw/.gemini/antigravity-cli/scratch/xyz-audit` — a months-stale copy of this repository,
mtime **2026-08-08 21:34**, with a `ROADMAP.md` of 252,726 bytes. Every one of agy's claims is true
of *that* tree. The lane read it instead of the throwaway worktree consult prepared.

The consult harness independently flagged the answer
(`prompt-trace classifier: agy echoed 1 cited claim from the PROMPT`), which is what made it
checkable rather than merely wrong.

## Why it matters

A cross-model consult's whole value is independence. A lane that silently reads a different tree
does not degrade to "one advisor" — it degrades to **one advisor plus a confident fabrication**,
which is worse, because the fabrication argues against the true premise. The GH-474 adjudication had
to be re-grounded by hand after this.

## What would fix it

Not yet designed. The shape is: the lane asserts it is running in the worktree consult handed it —
`git rev-parse --show-toplevel` matching the expected path, and HEAD matching the expected sha —
and refuses the turn if not, rather than answering from wherever it landed.

## Related

- `relay-system/2026-09-07/gh474-md-views-101147/gh474-md-views.agy.md` — the answer in full
- [[GH-482]] — a second way an advisor completes a turn without the input it was supposed to read
