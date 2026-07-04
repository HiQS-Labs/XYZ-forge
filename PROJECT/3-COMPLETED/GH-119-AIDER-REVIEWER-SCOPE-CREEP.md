---
gh_issue: 119
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/119
title: "aider-turn.sh: reviewer can auto-add and edit out-of-scope tracked files under --yes-always; all-or-nothing containment discards the valid in-lane edit too [sibling of #54/#107]"
status: Shipped (93e2366) — issue #119 closed 2026-07-04
created: 2026-07-03
updated: 2026-07-03
owner: noel
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
roadmap_exempt: false
goal: >
  Close the scope-creep gap where a review-only Aider turn could emit an edit for a file
  outside its allowlist (via --yes-always auto-adding it), causing the harness's all-or-nothing
  containment to discard the whole turn — by pre-seeding the diff's changed files as --read so
  they are structurally unwritable, regardless of --yes-always.
non_goals:
  - Not touching the containment kernel (relay-turn-lib.sh) — #54/#107 already own that layer;
    this lane closes the gap one level up, at the Aider tool-config layer.
  - Not changing the build/fix-turn path (ALLOW_PATHS non-empty, artifact IS meant to be edited) —
    scoped strictly to ALLOW_PATHS="" review-only turns.
related:
  - relay-automation/aider-turn.sh
  - relay-automation/relay-turn-lib.sh (read-only context; not modified by this lane)
---

# GH-119 — Aider reviewer scope-creep discards a valid turn under all-or-nothing containment

## Status

| What was just completed | What's next |
|---|---|
| Shipped 2026-07-03 as marathon Lane D (`93e2366`): `aider-turn.sh` now pre-seeds a review-only turn's diff-changed files as `--read`; new `test/aider-turn.sh` case (12) proves a diff-referenced file is passed `--read`, never `--file`. `validate.sh`: 36/36 for this shim. Independently re-verified twice via reverse-dogfood reviews (GLM 5.2 succeeded at 24-file scale; Nemotron Ultra 3 did not engage meaningfully at any scale tested) — both confirmed zero writable surface, zero scope-creep, even across large multi-file diffs. Issue #119 closed 2026-07-04. | Nothing — done. |

## Bug

Surfaced live 2026-07-03 while testing GH-118's fix (`AIDER_FLAGS=--edit-format diff`) against
GLM-5.2 in a Reviewer-only relay turn (`ALLOW_PATHS=""`, only the relay file allowlisted):

1. The model correctly reviewed the diff, found a real bug, and wrote a valid review block for
   the relay file.
2. It *also* emitted a SEARCH/REPLACE edit for a file never added via `--file`/`--read`
   (`relay-automation/marathon-drive.sh`). Aider's `--yes-always` auto-confirmed the implicit
   "add this file to the chat?" prompt and applied the edit.
3. `relay-turn-lib.sh`'s off-lane detection correctly caught the untracked-allowlist change and
   discarded the **whole worktree diff** — including the otherwise-valid, correctly-scoped
   relay-file edit — exiting 6.

Same containment mechanism as #54 (in-turn fs-touching tests) and #107 (builder tool-cache
writes), but a **third, distinct trigger**: a deliberate, role-violating edit rather than an
incidental side-effect. The relay's ground rule ("Reviewer never edits the artifact") is a
prompt convention, not a structural constraint on what Aider can write to — with `--yes-always`,
any file the model names becomes writable regardless of role.

## Fix direction

For review-only turns (`ALLOW_PATHS=""`), pre-seed the diff's changed files as `--read` (not just
the raw diff text) in `aider-turn.sh`'s `aider_args` construction (around line 135-142). `--read`
files are structurally read-only to Aider even under `--yes-always` — full context for the
Reviewer to reason about, with no path it can write to. This complements #54/#107's
containment-level fixes rather than replacing them: it closes the gap at the tool-config layer,
before containment ever needs to catch it.

## Definition of done

- Review-only Aider turns (`ALLOW_PATHS=""`) pass the diff/artifact's changed files as `--read`.
- A Reviewer model attempting to edit a `--read` file fails to apply the edit (no path to write),
  rather than succeeding and then being silently discarded at the containment layer.
- Build/fix-turn behavior (`ALLOW_PATHS` non-empty) is unchanged.
- `test/aider-turn.sh` gets a new case covering the review-only `--read`-seeding behavior.

## Swarm Preflight Contract

Consumed by `utils/swarm-preflight.sh`. Same-repo build (`target.ref: main`). Shim zone
(agy-safe), single script + an extended existing test.

```json
{
  "target":      { "repo": ".", "ref": "main" },
  "gate":        "bash test/aider-turn.sh",
  "fix_probes":  [ { "type": "grep_absent", "path": "relay-automation/aider-turn.sh", "pattern": "GH-119" } ],
  "artifacts":   [ "relay-automation/aider-turn.sh", "test/aider-turn.sh" ],
  "remediation": { "source": "GH-119#fix-direction", "criteria": "For review-only turns (ALLOW_PATHS empty), aider-turn.sh derives the diff/artifact's changed files and passes each as an additional --read flag alongside the existing artifact --read; --read files are structurally unwritable by Aider even under --yes-always; build/fix-turn behavior (ALLOW_PATHS non-empty) is unchanged; test/aider-turn.sh gets a new case asserting a review-only turn cannot apply an edit to a non-allowlisted, --read-seeded file; GH-119 marker comment." },
  "lanes":       { "agy_safe": [ "relay-automation/aider-turn.sh", "test/aider-turn.sh" ], "orchestrator_only": [] }
}
```
