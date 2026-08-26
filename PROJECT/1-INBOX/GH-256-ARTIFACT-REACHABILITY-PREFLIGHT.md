---
title: No preflight checks the builder can reach a phase's artifact paths
status: Proposed (1-INBOX — not yet active)
created: 2026-08-26
owner: noel
gh_issue: 256
source: https://github.com/HiQS-Labs/XYZ-forge/issues/256
doc_type: bugfix
complexity: 3
risk: 2
effort: 2
phases: 1
ratings_provisional: true
reported_from: rebalanceOS
harness_commit: b051cab4
non_goals:
  - Fixing the underlying worktree-root resolution for --target-root. This capture adds detection; whether the builder's worktree SHOULD be cut from the target is a separate design call.
  - Reworking the round-cap mechanism itself. Only the no-op-builder early exit is in scope.
related:
  - GH-255 (found on the same run; that one misdirects the operator, this one wastes a full round cap silently)
  - GH-514 (the transcript gate — an example of a preflight that DOES refuse before spending a turn, which is the pattern this should follow)
goal: >
  A phase whose artifact paths are unreachable from the builder's resolved working directory is
  refused before dispatch with a named path and directory, instead of dispatching four no-op
  builder turns and escalating as cap-stalled after 29 minutes.
---

# GH-256 — the builder wrote nothing for four rounds and no check noticed

> **1-INBOX capture**, not the active-work doc — no `## Status` table yet. On promotion to
> `PROJECT/2-WORKING/`, add the status table + per-phase QA gates and carry `gh_issue` forward
> (`PROJECT/PDDA.md` → GitHub issue intake).

## Why

Under `--target-root` + `--phases-dir`, the builder's isolated worktree is cut from the harness
clone, where the phase's relative artifact paths do not exist. The builder has nothing to open, so
it writes nothing and releases the token. Four rounds, 29 minutes, zero lines of code.

The failure is silent by construction. The reviewer receives absolute paths, reads the *correct*
files, and files accurate findings — so the transcript reads like a working review loop. The only
evidence is a negative: no `### Round N · Builder · agy` block was ever appended.

## Key concepts

> **The first draft's diagnosis was wrong, and agy's QA falsified it.** It claimed the builder's
> worktree is cut from the harness clone. It is not: `relay-drive.sh:254` exports
> `RELAY_TARGET_ROOT="$TARGET_ROOT"` and `relay-turn-lib.sh:251` reads
> `RTL_ROOT="${RELAY_TARGET_ROOT:-$1}"`, so the worktree is cut from the TARGET. Verified before
> accepting. The real split is one level over, and the harness already documents it.

- **The turn shim's containment root and the worktree root disagree.**
  `utils/py/agy-turn.py:321` resolves `root = resolve_turn_root(os.environ.get("AGY_TURN_ROOT"), xyz_root)`.
  `relay-automation/CONSUMING.md:41` documents `AGY_TURN_ROOT` as something the operator must export
  for a cross-repo turn — and `marathon-drive.sh` never exports it. So under `--target-root` the
  worktree is the target while the shim guards the harness.
- **The harness already knows.** `relay-turn-lib.sh:283` says it outright: *"marathon-drive/relay-drive
  don't export CODEX_TURN_ROOT/AGY_TURN_ROOT — they never do"*, and names the resulting symptom —
  the seed check *"finds nothing there, and deletes the artifact from the worktree handed to the
  agent (the 'codex says the worktree doesn't contain my files' symptom — codex was telling the
  truth)"*. GH-160 corrected that for the vendored-`.xyz` shape. The `--target-root` shape was left.
- **So the builder was telling the truth too.** It produced no changes because the files were not
  in the worktree it was handed. Four turns, 29 minutes, no error — the shim has no way to say
  "the artifact I was told to edit is not here."
- **`--dry-run` cannot catch this.** It validates plan fields, phase order and brief paths, then
  renders the relay and prints the tick seed. Execution topology is outside its scope, so the plan
  dry-ran clean four times and failed on every live fire.

## Remediation

> Revised after agy QA (`relay-system/2026-08-26/gh256-plan-qa.md`). Four of the first draft's five
> items were rejected and are dropped: the preflight as specified is unimplementable (the worktree
> is created inside the turn by `rtl_worktree_begin` via `mktemp`, so it does not exist at preflight
> time); "artifact paths must exist" would falsely refuse any phase that CREATES a file; escalating
> on two no-op builder turns is unsafe (a builder may legitimately hand back without writing);
> counting builder blocks is a poor proxy (a block can be appended without tracked changes); and
> renaming the "preflight" label is cosmetic churn. Only the underlying defect survives, and the
> fix for it is smaller than anything first proposed.

1. **Close the documented contract gap.** When `--target-root` is set, `marathon-drive.sh` must
   export the turn shim's guard root to match — `AGY_TURN_ROOT` / `CODEX_TURN_ROOT` /
   `COMMANDCODE_TURN_ROOT` = the target root — so the shim guards the same repo the worktree is cut
   from. This is honouring an env contract `CONSUMING.md` already specifies for cross-repo turns,
   not inventing one.
2. **Make the silent case audible.** `rtl_worktree_begin` already probes `-e "$RTL_ROOT/$a"` per
   allowlisted artifact and silently drops what it cannot find. Warn on a dropped artifact naming
   the path and the root it resolved against. A builder handed a worktree missing its own artifact
   should not have to be inferred from an absent block.
3. **Pin it with a test** driving the `--target-root` topology specifically, asserting the shim's
   guard root equals the worktree root. That is the invariant; the no-op turns were the symptom.
