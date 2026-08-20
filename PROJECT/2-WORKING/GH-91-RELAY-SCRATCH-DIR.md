---
gh_issue: 91
source: https://github.com/HiQS-Suite/XYZ-forge/issues/91
title: "fix(relay): a build turn has nowhere to write verification output — containment kills a complete, green turn"
status: Active (2-WORKING — built 2026-08-20)
created: 2026-08-20
updated: 2026-08-20
owner: noelsaw1
doc_type: bugfix
effort: 1
complexity: 2
risk: 3
goal: >
  Give every build turn a sanctioned place inside the tree for verification output —
  .relay-scratch/ — exempted like the other intrinsic write categories, pre-created by
  worktree isolation, named in the turn prompt, never copied back, discarded rather than
  committed on the non-worktree path. Containment otherwise unchanged: stray writes and
  lookalike prefixes still fail the turn.
related:
  - https://github.com/HiQS-Suite/XYZ-forge/issues/90
  - https://github.com/HiQS-Suite/XYZ-forge/issues/107
---

# GH-91: the sanctioned scratch directory

## Status

| What was just completed | What's next |
|---|---|
| **BUILT 2026-08-20 (linked worktree `XYZ-forge-gh91`, branch `fix/gh91-relay-scratch`)** — issue option 1 implemented across all four surfaces: `rtl_worktree_begin` pre-creates `.relay-scratch/` in the isolated worktree (the affordance physically exists, not prose); `rtl_worktree_end` exempts it intrinsically (no signature check — it is *meant* to be written, unlike the read-only `.relay-artifacts/` seed) and never copies it back; `rtl_check` on the non-worktree path exempts AND discards it (`rm -rf` — it lives in ROOT there and must neither linger nor ride into a commit); `rtl_turn_prompt` names it at the point of use with its disposition. `.gitignore` carries `.relay-scratch/` as defense in depth (the exemption is intrinsic in code and does not depend on it, per the `.tick` lesson). New suite `test/gh91-relay-scratch.sh` **15/0** with controls: stray writes still violate, lookalike prefix `.relay-scratch2` is NOT exempt, off-lane worktree turns still copy nothing back. Containment-pinning neighbors re-run green (worktree-isolation 33/0, shim-worktree 32/0, relay-artifact-file 13/0, rtl-orphan-backup 8/0, gh410 11/0, path-overlap, relay-xyz-skill-guard, untracked-file-warn, seeding-visibility, relay-target-root). | Full gate from a NORMAL clone (GH-45 refuses it from this worktree — by design), then PR into `development`. Watch the next daybreak re-fire: the builder should now put probe output in `.relay-scratch/` because the prompt says so at the point of use. If a lane still writes scratch elsewhere, that is a prompt-weighting question for GH-77's briefs, not a missing facility. |

## The defect (abridged from the issue)

The 0.7.2 daybreak wave-1 re-fire: the builder verified its work exactly as the brief required
(`collect.sh` → JSON → `triage.py --lenses --dry-run`, all green), saved the probe output next to
the thing being probed — and containment reverted all four JSON files at exit 6, failing a
complete, passing turn. Every other category of incidental write had an exemption
(`.tick/`, `.relay-artifacts/`, the transcript log, GH-107 tool caches); builder scratch had
none, and `$TMPDIR` was convention carried only in prose the builder demonstrably did not weight.
A rule a competent builder breaks while doing exactly what it was asked to do is a missing
affordance, not a discipline problem.

## The fix (issue option 1 — recommended)

`.relay-scratch/`, treated as an intrinsic write category:

| Surface | Change |
|---|---|
| `rtl_worktree_begin` | `mkdir -p "$wt/.relay-scratch"` — the affordance physically exists before the turn starts |
| `rtl_worktree_end` | intrinsic `case` exemption beside `.tick` (NO signature check — scratch is meant to be written); copyback iterates `RTL_ALLOW` only, so it is structurally never copied back |
| `rtl_check` (non-worktree) | exempt AND discard: `rm -rf "${RTL_ROOT:?}/.relay-scratch"` — the transcript-log drop is the precedent; `${RTL_ROOT:?}` guards the empty-prefix `rm -rf` (GH-567) |
| `rtl_turn_prompt` | one sentence naming the room and its disposition: exempt, never copied back, safe to leave; scratch elsewhere still fails the turn |
| `.gitignore` | `.relay-scratch/` (defense in depth; the code exemption does not depend on it) |

## Validation

| What | Result |
|---|---|
| `test/gh91-relay-scratch.sh` (new, registered in TESTS same commit) | **15/0** — lib-function level, no builder binary: scratch not a violation + discarded + lane edit untouched (both the file and collapsed-dir status forms); CONTROLS: stray write still exit-6s and is reverted, `.relay-scratch2` lookalike not exempt, worktree stray still off-lane with copyback withheld; begin pre-creates the dir; end exempts without copying back; prompt names the room and its disposition |
| Containment-pinning neighbors | worktree-isolation 33/0 · shim-worktree 32/0 · relay-artifact-file 13/0 · rtl-orphan-backup 8/0 · gh410 11/0 · path-overlap 1/0 · relay-xyz-skill-guard 11/0 · relay-untracked-file-warn 9/0 · relay-file-seeding-visibility 3/0 · relay-target-root 12/0 |
| shellcheck `-S error` on the lib | clean |
| Full `./validate.sh` | run from a NORMAL clone before the PR (the worktree itself refuses the gate — GH-45); result recorded here |

## Design notes

- **Why exempt-and-discard in `rtl_check` but leave-in inside worktrees**: under isolation the
  dir dies with the worktree, so leaving it is free; on the non-worktree path it lives in
  `RTL_ROOT`, where lingering untracked scratch would ride into someone's `git add -A` — the
  transcript-log drop is the standing precedent for "harness-owned, dropped, not flagged".
- **Why no signature check** (unlike `.relay-artifacts/`): the artifact seed is read-only under
  review, so any edit is a violation; scratch exists precisely to be written by the turn.
- **Why the prompt line matters as much as the exemption**: the phase brief already said "use
  `$TMPDIR`" and the builder wrote to CWD anyway. The affordance is now visible at the point of
  use, in the same sentence as the rule it replaces.

## Lessons Learned (For Future Agents)

- When a containment rule kills a turn whose deliverable is green, the question is not "how do
  we make the builder behave" but "what legitimate action has no sanctioned home". Inventory the
  write categories; each one missing a room becomes an exit 6 waiting to fire.
- An exemption is a room, not an amnesty: the suite pins that stray writes and lookalike
  prefixes (`.relay-scratch2`) still fail — otherwise the fix would just relocate the hole.
