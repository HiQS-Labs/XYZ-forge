---
title: "Phase brief: GH-293 gh293-vendored-guard-drift (marathon builder input, not a capture doc)"
status: not yet fired
created: 2026-07-27
updated: 2026-07-27
owner: noel
goal: >
  Phase-brief input consumed by relay-automation/marathon-drive.sh for the gh293-vendored-guard-drift phase of
  MARATHON-2026-07-27-GATE-AND-FLEET-INTEGRITY — not itself an active-doc capture; the canonical
  capture doc is GH-293-VENDORED-GUARD-DRIFT.md one level up.
roadmap_exempt: true
---

# Brief — GH-293: make missing safety guards visible, and refuse unsafe `update --all`

## Status

| What was just completed | What's next |
|---|---|
| Contract authored and preflighted by the 2026-07-27 /10days sweep — `swarm-preflight --gh-issue` exit 0 (READY). Not yet fired. | Fire as marathon phase 3 of 4. |

**Parent doc:** `PROJECT/2-WORKING/GH-293-VENDORED-GUARD-DRIFT.md`
**Issue:** https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/293
**Runs THIRD.**

## Read these two things first

1. **The issue's own correction comment (2026-07-23).** It fixes a wrong repo count and clarifies
   that `tick_version` (schema) and `source_commit` (harness commit) are distinct. It **narrows the
   real gap** to: a safety-relevant behavioral change (GH-245) shipped *without moving
   `tick_version`*, so the version contract cannot express "this copy is missing a safety guard."
   Scope to that, not to the issue's first framing.
2. **The GH-312 change to `materialize_vendor()`** (shipped 2026-07-27, commit `4ec5928`) — it added
   a preserve list carrying target-owned runtime state across the stage-then-swap. You are editing
   the same file. Do not regress it.

## The two failures (verified in source)

- `xyz-sync.sh` has **no** guard manifest and **no** special-casing for `source_commit=unknown`
  beyond generic unknown-string handling. `check` can only report an opaque commit-hash delta, so
  an operator cannot distinguish cosmetic drift from "missing a safety guard."
- `cmd_update` has **no** dirty/non-canonical-source guard. The issue documents a near-miss where
  `update --all` from a dirty, far-ahead, actively-mutating marathon branch would have pushed
  unmerged code into 9 vendored repos in one command, silently.

## Acceptance criteria

- `xyz-sync check` can report that a vendored copy is **missing a SAFETY-relevant guard**,
  distinguishably from ordinary commit drift — via a guard manifest of safety-critical patterns,
  rather than leaning on `tick_version` alone (which demonstrably didn't move for GH-245).
- `xyz-sync update` refuses, or requires an explicit documented override, when the harness source
  is dirty or not on a canonical branch — so `--all` cannot silently push unmerged code fleet-wide.
- `check` stays **REPORT-ONLY**: never a hard error, never an auto-pull. The GH-96 contract is
  preserved exactly.
- The refusal has an explicit override, not an unconditional block.
- **Run `test/gh312-vendor-preserves-state.sh` after any `xyz-vendor.sh` edit** and confirm 14/14.
- Land `test/gh293-vendored-guard-drift.sh` covering both behaviors, and register it in
  `validate.sh`'s `TESTS` array.

## Do not

- Auto-pull updates into vendored copies — the pinned-and-manual model stays.
- Turn `check` into a hard error.
- Rewrite `registry.tsv`'s schema wholesale; add a field if one is genuinely needed.

## Gate

`bash validate.sh`
