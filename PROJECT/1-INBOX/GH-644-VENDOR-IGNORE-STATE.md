---
title: "GH-644: xyz-vendor.sh reconcile_ignore_state — part B: stop re-asserting .xyz/ on repos that deliberately track the harness"
status: active
created: 2026-09-17
updated: 2026-09-17
owner: unassigned
goal: decide and land the #314 refinement so a target that has committed .xyz/ keeps it tracked while its runtime-state subpaths stay ignored
gh_issue: 644
source: https://github.com/HiQS-Labs/XYZ-forge/issues/644
doc_type: bug
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/314
  - https://github.com/HiQS-Labs/XYZ-forge/issues/440
  - https://github.com/HiQS-Labs/XYZ-forge/issues/642
  - https://github.com/HiQS-Labs/XYZ-forge/pull/685
context_tags: [xyz-vendor, gitignore, containment, consumer-repo]
non_goals:
  - Part A (trailing-newline fusion) — landed in PR #685 (4af5bcfc)
  - Any new CLI flag; detection must read observed git state
  - Un-ignoring runtime state (.xyz/relay-system, .xyz/.tick, locks, XYZ.json*) on any target
effort: 1
complexity: 2
risk: 2
---

# GH-644 — xyz-vendor.sh reconcile_ignore_state, part B

## Status

| What was just completed | What's next |
|---|---|
| Part A landed: PR #685 (4af5bcfc) terminates the exclude file before appending; red-before/green-after fixture in `test/xyz-vendor.sh`; full gate 394/394 | Operator decides the #314 refinement (below); if yes, land B with its own fixture (tracked-`.xyz/` target → `.xyz/` absent from the exclude, runtime subpaths present); re-vendor Needle-fork and confirm `git diff .gitignore` is empty |

## Quad Concepts
- `.xyz/` is two things → harness code (refreshable, sometimes deliberately committed) vs runtime state (never committable)
- Unconditional re-assert → on a repo that tracks `.xyz/`, every vendor run re-adds the ignore; left in place it would untrack ~1,470 files on the next `git add`
- Detection by observed git state → `git -C "$TARGET_REPO" ls-files --error-unmatch -- .xyz` succeeding means the operator already committed the harness; ignore only the runtime subpaths then
- Recorded decision → this refines #314 / GH-440, so the operator who recorded it says yes before it lands

## Decision needed

If the target has already committed `.xyz/`, should `reconcile_ignore_state` ignore only `.xyz/relay-system/`, `.xyz/.tick/`, `.xyz/.relay-driver.lock`, `.xyz/XYZ.json*`, `.xyz/XYZ.heartbeat.json` instead of the whole directory? Current behaviour stays exactly as-is for every other target.

## Lessons Learned (For Future Agents)
- A `.gitignore`/exclude append is a mutation of the consumer's policy; guard the file shape (trailing newline) and the operator's intent (already-tracked paths) separately — they are different failure classes and different lanes (hotfix vs decision).
- `/express` refuses edited `.sh` under `relay-automation/` (GH-551) by design; the PR lane with a green base is minutes, so do not look for an override.
