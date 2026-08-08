---
title: "Vendored .xyz copies silently miss safety guards — drift is reported but nothing propagates fixes"
status: "Active (2-WORKING) — promoted 2026-07-27 by the /10days sweep. Re-verified live: xyz-sync.sh has no guard manifest and cmd_update has no dirty/non-canonical-source check. Preflight contract below is LIVE."
created: 2026-07-27
updated: 2026-07-27
owner: unassigned
gh_issue: 293
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/293
doc_type: bugfix
complexity: 3
risk: 4
effort: 2
phases: 1
ratings_provisional: true
non_goals:
  - Auto-pulling updates into vendored copies. The pinned-and-manual update model stays (GH-96).
  - Changing `check`'s report-only contract — it must remain a warning, never a hard error.
  - Re-designing registry.tsv's schema wholesale; add a field if needed, don't rewrite it.
related:
  - relay-automation/xyz-sync.sh (check/update/list)
  - relay-automation/xyz-vendor.sh (register_vendor, materialize_vendor)
  - GH-312 (the preserve-list fix in the same swap path, shipped 2026-07-27)
goal: >
  An operator can tell whether a vendored `.xyz/` is missing a SAFETY-relevant fix, and
  `xyz-sync update` refuses to propagate a dirty or non-canonical harness state across the
  fleet in one command.
---

# GH-293 — vendored copies silently miss safety guards

## Status
| What was just completed | What's next |
|---|---|
| Selected by the 2026-07-27 `/10days` sweep as a critical bug. Re-verified in live source: `xyz-sync.sh` has **no** guard manifest, **no** special-casing for `source_commit=unknown` beyond generic unknown-string handling, and `cmd_update` has **no** dirty/non-canonical-source guard. Note the adjacent GH-312 fix (preserve target runtime state across the swap) shipped the same day and touches the same `xyz-vendor.sh` swap path — read it before scoping. | Fire the contract below. The issue's own correction comment (2026-07-23) narrows the real gap: a safety-relevant behavioral change (GH-245) shipped **without moving `tick_version`**, so the version contract cannot express "this copy is missing a safety guard." |

## Symptom

Two distinct failures, one root cause — the version contract can't express safety:

1. **Silent guard absence.** Vendored copies can be missing a safety-critical fix (e.g. GH-245's
   `--target-root` fast-fail) with no way for `check` to say so beyond an opaque commit-hash delta.
   `tick_version` didn't move when GH-245 landed, so the drift signal can't distinguish "cosmetic
   drift" from "missing a guard."
2. **Fleet-wide propagation of unstable code.** `xyz-sync update --all` has no guard against being
   run from a dirty, far-ahead, actively-mutating branch. The issue documents a near-miss where it
   would have pushed unmerged marathon-branch code into 9 vendored repos in one command, silently.

## Impact

Every vendored `.xyz/` install (~9 repos per the issue's registry dump). Not data loss in itself,
but an operator today cannot answer "is this vendored copy safe?" without a manual grep, and one
mistyped `update --all` from the wrong branch reaches the whole fleet.

## Swarm Preflight Contract

```json
{
  "target":      { "repo": ".", "ref": "development" },
  "gate":        "bash validate.sh",
  "fix_probes":  [
    { "type": "grep_absent", "path": "relay-automation/xyz-sync.sh", "pattern": "guard_manifest|GUARD_MANIFEST|dirty_source_guard" },
    { "type": "path_absent", "path": "test/gh293-vendored-guard-drift.sh" }
  ],
  "artifacts":   [
    "relay-automation/xyz-sync.sh",
    "relay-automation/xyz-vendor.sh",
    "test/gh293-vendored-guard-drift.sh",
    "validate.sh"
  ],
  "artifacts_new": [ "test/gh293-vendored-guard-drift.sh" ],
  "remediation": {
    "source":   "issue#293",
    "criteria": "(1) `xyz-sync check` can report that a vendored copy is missing a SAFETY-relevant guard, distinguishably from ordinary commit drift — via a guard manifest of safety-critical patterns rather than relying on tick_version alone. (2) `xyz-sync update` refuses (or requires an explicit override) when the harness source is dirty or not on a canonical branch, so `--all` cannot push unmerged code across the fleet silently. `check` stays REPORT-ONLY and never auto-pulls (GH-96 contract preserved). Regression test covers both, and is REGISTERED in validate.sh's TESTS array."
  },
  "lanes":       {
    "agy_safe":          [ "test/gh293-vendored-guard-drift.sh" ],
    "orchestrator_only": [ "bin/", ".tick/" ]
  }
}
```

## Phase 1 — Make safety drift visible and updates refuse unsafe sources

### Checklist

- [ ] Read the issue's own 2026-07-23 correction comment first (it fixes a wrong repo count and
      clarifies `tick_version` vs `source_commit` — it narrows the real gap)
- [ ] Read the GH-312 preserve-list change in `materialize_vendor()` before touching that path
- [ ] Land the regression test first, observe it fail
- [ ] Implement the guard manifest + the dirty/non-canonical-source refusal
- [ ] Register the new test in `validate.sh`'s `TESTS` array

### QA checklist — Phase 1

- [ ] `check` remains report-only — no hard error, no auto-pull (GH-96 contract intact)
- [ ] The GH-312 preserve list still works after any `xyz-vendor.sh` edit (run `test/gh312-vendor-preserves-state.sh`)
- [ ] The `update` refusal has an explicit, documented override rather than being unconditional
- [ ] `bash validate.sh` green with the new test registered
