---
gh_issue: 55
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/55
title: "swarm-preflight: auto-include a changed artifact's covering tests in the builder allowlist"
status: Shipped 2026-07-04; targeted tests green; repo-wide validate rerun blocked only by unrelated live agy gate
created: 2026-07-04
updated: 2026-07-04
owner: noel
doc_type: bugfix
goal: >
  Expand swarm-preflight's generated builder allowlist from the contract's primary artifacts to an
  effective writable set that also includes the covering tests and test helpers that explicitly
  reference those artifacts, so a builder can update the real regression surface without
  containment discarding the test edits as off-lane.
complexity: 2
risk: 1
effort: 2
phases: 1
roadmap_exempt: false
non_goals:
  - Not changing the contract schema: artifacts[] stays the canonical declared write-set for readiness/freshness checks
  - Not heuristically sweeping the whole test tree into ALLOW_PATHS; only explicit coverage links are auto-included
  - Not weakening containment; this only widens the generated allowlist for files the planner can justify
related:
  - utils/swarm-preflight.sh
  - test/swarm-preflight.sh
  - relay-automation/marathon-drive.sh
---

## Status

| What was just completed | What's next |
|---|---|
| Shipped in Plan B Wave 2: `utils/swarm-preflight.sh` now derives an effective allowlist that auto-includes explicit covering tests and sourced helpers; `test/swarm-preflight.sh` is green (75/75, incl. new T31/T32). The full `validate.sh` rerun did **not** close cleanly, but only because the pre-existing live-network `test/relay-self-sufficiency.sh` agy turn failed; this lane's own surfaces stayed green. | No more code queued here. Keep only if a broader allowlist heuristic is wanted later; otherwise this doc is archival record. |

## Problem

`swarm-preflight.sh` currently passes the contract's raw `artifacts[]` list straight through to
`marathon-drive.sh --artifact ...`, and the packet's scope lock mirrors that exact list. That is
too narrow when a fix to `relay-automation/foo.sh` also needs its covering test(s) and shared test
helper(s) updated:

- the builder edits the test file
- containment sees the test edit outside `ALLOW_PATHS`
- the turn is reverted with `exit 6`, even though the edit is part of the legitimate fix

The GH-37 dogfood hit the concrete version of this: the packet named the two shims, but the real
behavior change also needed `test/agy-turn.sh` / `test/shim-worktree.sh`, and could have needed
`test/_setup.sh`.

## Decision

Keep `artifacts[]` canonical in the contract, but derive an **effective builder allowlist** for the
packet / invocation:

1. Start from the declared `artifacts[]`.
2. Scan `test/` under the evaluated target root for files that explicitly reference any declared
   artifact path string; auto-include those covering tests.
3. For each included test, recursively include local test helpers it sources from the same `test/`
   tree (for this repo, the important case is `test/_setup.sh`).
4. De-duplicate, preserve deterministic order, and use that effective list for:
   - `marathon-invocation.txt` `--artifact ...`
   - packet `Artifacts:` / scope-lock text
   - lane-plan metadata that describes the writable lane surface

Readiness/freshness gates remain based on the contract's own `artifacts[]`; the derived test/helper
paths are a containment/runtime affordance, not a contract rewrite.

## Definition of done

- [x] `utils/swarm-preflight.sh` derives an effective artifact list from contract artifacts +
      covering tests + sourced test helpers.
- [x] The derivation is deterministic and de-duplicated.
- [x] The generated packet / invocation uses the effective list, not the raw `artifacts[]`.
- [x] The contract JSON itself stays unchanged as the source of truth for freshness/readiness.
- [x] `test/swarm-preflight.sh` covers:
      - a primary artifact auto-pulls its covering `test/*.sh`
      - sourced helpers (e.g. `test/_setup.sh`) are also auto-pulled
      - an already-declared test is not duplicated
- [ ] `bash validate.sh` green.
  Repo-wide rerun stopped on the unrelated live `test/relay-self-sufficiency.sh` agy gate; this
  lane's direct gate stayed green (`bash test/swarm-preflight.sh`).

## Reversibility & blast radius

**Easy.** This does not touch the containment kernel; it only changes how the preflight packet
chooses the builder's writable list. The blast radius is `utils/swarm-preflight.sh` plus its tests,
the exact shared-file zone Plan B already isolated as `#89 → #55`.

## Swarm Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "bash test/swarm-preflight.sh",
  "fix_probes": [
    { "type": "grep_absent", "path": "utils/swarm-preflight.sh", "pattern": "GH-55" }
  ],
  "artifacts": [
    "utils/swarm-preflight.sh",
    "test/swarm-preflight.sh"
  ],
  "remediation": "In utils/swarm-preflight.sh, keep contract artifacts[] canonical for freshness/readiness, but derive an effective builder allowlist for the generated packet: start from artifacts[], then scan target-root test/ files for explicit references to those artifact paths and include the matching covering tests; recursively include local test helpers sourced from those tests (for example test/_setup.sh). De-duplicate deterministically and use the effective list for marathon-invocation.txt --artifact, the packet's Artifacts line, and the scope-lock writable-path text, without rewriting the contract JSON itself. Extend test/swarm-preflight.sh with a fixture proving a changed artifact auto-pulls its covering test and sourced helper, and that a test already declared in artifacts[] is not duplicated. GH-55 marker comment near the fix.",
  "lanes": {
    "agy_safe": ["utils/swarm-preflight.sh", "test/swarm-preflight.sh"],
    "orchestrator_only": [],
    "note": "Second lane of the swarm-preflight.sh shared-file zone (collision map: #89 -> #55, serialize). Parallel-safe with #48 once #89 is already landed."
  }
}
```
