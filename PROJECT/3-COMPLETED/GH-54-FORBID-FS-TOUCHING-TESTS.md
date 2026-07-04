---
gh_issue: 54
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/54
title: "marathon brief: forbid in-turn execution of filesystem-touching tests"
status: Shipped 2026-07-04; targeted tests green; repo-wide validate rerun blocked only by unrelated live agy gate
created: 2026-07-04
updated: 2026-07-04
owner: noel
doc_type: bugfix
goal: >
  Teach the generated builder brief to recognize when the allowlisted covering tests are
  filesystem-touching and explicitly forbid running them in-turn, so a correct build is not thrown
  away by containment just because its self-verification created fixture files inside the isolated
  worktree.
complexity: 2
risk: 1
effort: 2
phases: 1
roadmap_exempt: false
non_goals:
  - Not changing the containment core or the worktree isolation contract
  - Not disabling the post-turn harness gate; verification still happens, just outside the builder worktree
  - Not banning all code reading of tests; the builder may inspect them as specs
related:
  - utils/swarm-preflight.sh
  - utils/marathon-plan.sh
  - test/swarm-preflight.sh
  - test/marathon-plan.sh
---

## Status

| What was just completed | What's next |
|---|---|
| Shipped in Plan B Wave 3: `swarm-preflight.sh` now emits the stronger "read-only spec" rule when allowlisted tests touch the filesystem, and `marathon-plan.sh` mirrors that warning in its generated "How to fire a lane" guidance. New checks are green in `test/swarm-preflight.sh` (T33) and `test/marathon-plan.sh` (N(c)). The full `validate.sh` rerun only failed at the unrelated live-network `test/relay-self-sufficiency.sh` agy gate. | No more code queued here. Keep only if a future lane needs finer-grained fs-touching detection than the current heuristic. |

## Problem

The generic scope-lock text says:

- do not run the full gate
- verify with only the specific test for the file(s) you changed

That advice becomes wrong for tests that create git fixtures or temporary files inside the isolated
worktree. Running them causes containment to observe off-lane writes and discard the entire turn
with `exit 6`, even when the implementation is correct. GH-37 required an ad hoc packet override to
forbid `test/agy-turn.sh` / `test/shim-worktree.sh`; this needs to be the default behavior when the
planner can see the same risk pattern again.

## Decision

Make the brief template conditional on the effective allowlist:

- If the lane's auto-included tests are ordinary non-fs-touching checks, keep the existing
  "verify with only the specific test" guidance.
- If any allowlisted `test/*.sh` is classified as filesystem-touching, replace that guidance with a
  stronger rule:
  - do not run the full gate
  - do not run those fs-touching tests in-turn either
  - read them as specs instead; the harness runs the real gate outside the worktree after the turn

`marathon-plan.sh` also needs the same operator-facing warning in its generated "How to fire a lane"
section, so the scheduling overlay does not suggest a launch pattern the packet later has to
contradict.

## Definition of done

- [x] `utils/swarm-preflight.sh` detects fs-touching allowlisted tests and emits the stronger no-test
      rule in `packet.md`.
- [x] `utils/marathon-plan.sh`'s generated "How to fire a lane" section warns that fs-touching tests
      in the allowlist are read-only specs in-turn; the harness gate verifies them post-turn.
- [x] `test/swarm-preflight.sh` covers the stronger brief text.
- [x] `test/marathon-plan.sh` covers the new planner warning.
- [ ] `bash validate.sh` green.
  Repo-wide rerun stopped on the unrelated live `test/relay-self-sufficiency.sh` agy gate; this
  lane's direct gates stayed green (`bash test/swarm-preflight.sh` and `bash test/marathon-plan.sh`).

## Reversibility & blast radius

**Easy.** Text-generation only; no kernel, token, or containment logic changes. The only blast
radius is the two brief-producing files that Plan B intentionally serialized as the Wave 3
cross-zone lane.

## Swarm Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "bash test/swarm-preflight.sh && bash test/marathon-plan.sh",
  "fix_probes": [
    { "type": "grep_absent", "path": "utils/swarm-preflight.sh", "pattern": "GH-54" }
  ],
  "artifacts": [
    "utils/swarm-preflight.sh",
    "utils/marathon-plan.sh",
    "test/swarm-preflight.sh",
    "test/marathon-plan.sh"
  ],
  "remediation": "In utils/swarm-preflight.sh, detect when the effective allowlist includes filesystem-touching test/*.sh scripts and emit a stronger scope-lock rule in packet.md: do not run the full gate and do not run those fs-touching tests in-turn either; read them as specs and rely on the outer harness gate after the turn. In utils/marathon-plan.sh, add the same operator-facing warning to the generated 'How to fire a lane' guidance so the planner and packet agree. Extend test/swarm-preflight.sh and test/marathon-plan.sh with assertions for the stronger warning text. GH-54 marker comments near both fixes.",
  "lanes": {
    "agy_safe": [
      "utils/swarm-preflight.sh",
      "utils/marathon-plan.sh",
      "test/swarm-preflight.sh",
      "test/marathon-plan.sh"
    ],
    "orchestrator_only": [],
    "note": "Cross-zone brief-template lane: run after #55 and #48 settle; do not fire beside either shared-file zone."
  }
}
```
