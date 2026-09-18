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
| Decision made (cross-model consult, Codex + agy, synthesis on #644): refinement A + one shared runtime-path list + two guards. Part B built: `XYZ_RUNTIME_PATHS` hoisted (one definition for preserve + ignore), tracked-`.xyz/` targets get only the runtime subpath ignores, an operator-owned blanket `.xyz/` line is never removed (WARNING + remedy), tracked runtime content is WARNED by path; 14 new assertions in `test/xyz-vendor.sh` (red before, green after; suite 94/94) | PR review + merge; then re-vendor Needle-fork from merged `development` and confirm the exclude gains only `.xyz/<runtime>` lines and `git diff .gitignore` is empty |

## Quad Concepts
- `.xyz/` is two things → harness code (refreshable, sometimes deliberately committed) vs runtime state (never committable)
- Unconditional re-assert → on a repo that tracks `.xyz/`, every vendor run re-adds the ignore. Corrected premise (Codex, consult): an ignore rule never untracks indexed files, so nothing is lost; the harm is that every NEW harness file a re-vendor brings is silently not staged (the committed copy drifts) and the operator fights a reappearing rule
- Detection by observed git state → `git -C "$TARGET_REPO" ls-files --error-unmatch -- .xyz` succeeding means something under `.xyz/` is indexed; ignore only the runtime subpaths then. It is not proof the harness was deliberately vendored, so tracked content under a runtime path is WARNED by name (still ignored going forward)
- Recorded decision → this refines #314 / GH-440, so the operator who recorded it says yes before it lands

## Decision (recorded 2026-09-17)

Yes — refinement A. If the target already tracks `.xyz/`, `reconcile_ignore_state` ignores only the runtime subpaths (`.xyz/<p>` for each entry of `XYZ_RUNTIME_PATHS`, the same list `materialize_vendor` preserves) plus `/.tick/`; every other target keeps the blanket `.xyz/` rule unchanged. Guards from the consult: an existing blanket `.xyz/` ignore is never deleted (report + remedy), and tracked runtime content is named in a WARNING. Ranking A > B (refuse to vendor) > C (leave as-is): C fights the operator every run (GUIDING-PRINCIPLES #8), B blocks a valid turnkey workflow (GH-642). No new flag.

## Lessons Learned (For Future Agents)
- A `.gitignore`/exclude append is a mutation of the consumer's policy; guard the file shape (trailing newline) and the operator's intent (already-tracked paths) separately — they are different failure classes and different lanes (hotfix vs decision).
- `/express` refuses edited `.sh` under `relay-automation/` (GH-551) by design; the PR lane with a green base is minutes, so do not look for an override.
