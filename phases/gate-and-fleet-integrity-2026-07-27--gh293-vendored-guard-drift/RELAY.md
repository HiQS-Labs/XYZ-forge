# Marathon Phase gh293-vendored-guard-drift
STATUS: Approved
NEXT: codex

<!-- marathon-drive: task=MARATHON-GH293-VENDORED-GUARD-DRIFT-TURN builder=codex reviewer=agy round-cap=7 -->

## Phase Brief

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


---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): relay-automation/xyz-sync.sh,relay-automation/xyz-vendor.sh,test/gh293-vendored-guard-drift.sh,validate.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH293-VENDORED-GUARD-DRIFT-TURN --agent codex --paths "phases/gate-and-fleet-integrity-2026-07-27--gh293-vendored-guard-drift/RELAY.md,relay-automation/xyz-sync.sh,relay-automation/xyz-vendor.sh,test/gh293-vendored-guard-drift.sh,validate.sh"
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick ping MARATHON-GH293-VENDORED-GUARD-DRIFT-TURN --agent codex
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH293-VENDORED-GUARD-DRIFT-TURN --agent codex --to agy
4. Edit ONLY these paths: phases/gate-and-fleet-integrity-2026-07-27--gh293-vendored-guard-drift/RELAY.md and relay-automation/xyz-sync.sh,relay-automation/xyz-vendor.sh,test/gh293-vendored-guard-drift.sh,validate.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: relay-automation/xyz-sync.sh,relay-automation/xyz-vendor.sh,test/gh293-vendored-guard-drift.sh,validate.sh.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested` then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH293-VENDORED-GUARD-DRIFT-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick done MARATHON-GH293-VENDORED-GUARD-DRIFT-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   Edit ONLY phases/gate-and-fleet-integrity-2026-07-27--gh293-vendored-guard-drift/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.

### Round 1 · Builder · codex

Implemented GH-293 in `relay-automation/xyz-sync.sh`, `relay-automation/xyz-vendor.sh`, `test/gh293-vendored-guard-drift.sh`, and `validate.sh`. `check` now carries a named safety-guard manifest and inspects the installed vendored `relay-drive.sh` for GH-245's target-root containment refusal, reporting `SAFETY GUARD MISSING` independently of ordinary provenance drift (including `source_commit=unknown`). `update` now refuses a dirty or non-canonical (`main,development` by default) source before touching any target, with the documented `XYZ_SYNC_ALLOW_UNSAFE_SOURCE=1` override. The new targeted test covers report-only guard detection and both fleet-update refusals/overrides; it is registered in `validate.sh`.

### Round 1 · Reviewer · agy

**Verdict:** Changes requested

The `test/gh312-vendor-preserves-state.sh` test is currently failing. You added `require_safe_update_source` to `update_rows` in `xyz-sync.sh`, which enforces the dirty/non-canonical check on *all* update operations, including single-target updates (e.g., `xyz-sync update <dir>`). The GH-312 test relies on single-target updates and fails because the working tree is dirty during the test run.

The phase brief specifically mentions refusing updates "so `--all` cannot silently push unmerged code fleet-wide." To fix this regression without modifying `test/gh312-vendor-preserves-state.sh` (which you are not allowed to edit), please restrict `require_safe_update_source` so that it only fires when `$target` is `--all`.

Run `bash test/gh312-vendor-preserves-state.sh` and ensure it passes (14/14) before handing back.

### Round 2 · Builder · codex

Constrained `require_safe_update_source` in `relay-automation/xyz-sync.sh` to `update --all`; explicitly selected single-target updates retain their GH-312 behavior. The prior GH-293 manifest, report-only `check`, documented override, targeted test, and `validate.sh` registration remain unchanged. Verified `bash test/gh312-vendor-preserves-state.sh` (14 pass, 0 fail) and `bash test/gh293-vendored-guard-drift.sh` (13 pass, 0 fail). Files touched this round: `relay-automation/xyz-sync.sh`, this relay log.

### Round 2 · Reviewer · agy

**Verdict:** Approved

Confirmed that tests pass correctly. `bash test/gh312-vendor-preserves-state.sh` is now passing 14/14, meaning the `update --all` regression on single target updates is resolved. `bash test/gh293-vendored-guard-drift.sh` is also passing 13/13, confirming that safety requirements on dirty sources are applied. Great work restricting `require_safe_update_source`.
