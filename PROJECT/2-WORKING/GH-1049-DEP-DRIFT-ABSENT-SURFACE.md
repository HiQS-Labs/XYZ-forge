---
gh_issue: 1049
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1049
title: "dependency.drift: no false (0 lines) event when a watched surface is absent at both revs"
status: Active
created: 2026-11-15
updated: 2026-11-16
owner: noelsaw1
doc_type: bug
complexity: 1
risk: 2
effort: 1
phases: 1
ratings_provisional: true
non_goals:
  - Changing the dependency.drift event schema, the surface list or the heads-up injection
  - Suppressing a real surface addition or deletion
goal: >
  rtl_enforce emits no dependency.drift event for a watched surface absent at both revisions,
  still emits for real changes, and keeps emitting for a one-sided addition or deletion.
roadmap_exempt: true
---

# GH-1049 · Drift check on absent surfaces

## Status

| What was just completed | What's next |
|---|---|
| Captured with source evidence and settled one-side semantics against the GH-68 decision (GH-1400 dogfood round). | Implemented: surface lookups use `rev-parse --verify` and clear a failed lookup to empty; `test/relay-dep-drift.sh` covers absent-at-both, addition and deletion. |

## Evidence (development `be0a37520`)

- `relay-automation/relay-turn-lib.sh:1742-1744` capture `git rev-parse "$RTL_BEFORE_HEAD:$_surf" 2>/dev/null || true`. An unresolvable path makes `rev-parse` print its own argument, so two heads give two different strings and the event fires with `(0 lines)`.
- `git rev-parse --verify "<sha>:<missing>"` (stderr redirected, failure cleared to an empty string in `rtl_enforce`) yields no ID; that is the resolution the existing `[[ "$_psha" == "$_csha" ]]` comparison and the `${_psha:-none}` fallbacks were written for.
- Every Python turn shim reaches this Bash `rtl_enforce`; no Python copy of the emitter exists.

## One-side-missing semantics (settled)

`decisions/2026-07-01-cross-agent-dep-conflict.md` says the hook emits "if any surface changed", and the emitter already passes `--prior-sha "${_psha:-none}" --current-sha "${_csha:-none}"`. A surface added or deleted between the two heads is a real change and still emits, with `none` on the absent side. Only "absent at both revs" is skipped, which the existing equality check does once absence resolves to an empty string. This deliberately departs from the issue's "no-op when absent at either rev" suggestion so a real addition/deletion is not suppressed.

Blast radius: `relay-turn-lib.sh` is sourced by every relay turn (containment kernel). The change is limited to the warn-only drift block; turn outcome and the no-change path are unaffected. Reversibility: Easy (revert two lines).

## Acceptance

- [ ] Surfaces absent at both revs across a commit: zero `dependency.drift` events.
- [ ] A real change to a present surface still emits with real blob SHAs (existing positive case).
- [ ] A surface added between the two revs emits once with `prior_sha` `none`.
- [ ] `test/relay-dep-drift.sh` covers the three cases and passes.

Historical builder note (before the fix): the end-to-end fixture already lacked `relay-automation/relay-turn-lib.sh` and `src/events.js`, and its old `-ge 1` assertion hid the bug. That assertion is now tightened to exactly one event naming `src/project.js` (`test/relay-dep-drift.sh:100`), which covers absent-at-both without a new fixture.

## Correction after attempt 1 (gate evidence, GH-1400 dogfood round)

Attempt 1 (`f64bc2ba4`, reviewer-approved) failed the classified gate on two real findings; the original plan above is unchanged.

- `relay-pkg-freshness.sh`: `relay-pkg.tar.gz is stale — run skills/1-hourly/relay-automation/make-pkg.sh` (drift: `relay-automation/relay-turn-lib.sh`). Preparation omitted the packaged tarball from the artifacts; it is added. Regenerate it with `bash skills/1-hourly/relay-automation/make-pkg.sh` after the final `relay-turn-lib.sh` edit.
- `mktemp-trap-guard.sh`: `test/relay-dep-drift.sh:29 $dir assigned from mktemp, then BARE 'cd "$dir"' at test/relay-dep-drift.sh:75 (not scoped inside a subshell) with no non-empty/is-directory guard first`. Scope that `cd` inside a subshell (or guard it) per GH-177.

Additional acceptance:

- [ ] `test/relay-pkg-freshness.sh` and `test/mktemp-trap-guard.sh` pass.

## Swarm Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash validate.sh --auto development",
  "fix_probes": [
    { "type": "grep_present", "path": "relay-automation/relay-turn-lib.sh", "pattern": "rev-parse \"\\$RTL_BEFORE_HEAD:\\$_surf\"" }
  ],
  "artifacts": [
    "relay-automation/relay-turn-lib.sh",
    "test/relay-dep-drift.sh",
    "skills/1-hourly/relay-automation/relay-pkg.tar.gz"
  ],
  "remediation": {
    "source": "issue#1049",
    "criteria": "rtl_enforce resolves surface blobs with rev-parse --verify (stderr redirected, failed lookups cleared to empty) so absence is empty; absent-at-both emits nothing; real changes and one-sided additions/deletions still emit (none on the absent side); test/relay-dep-drift.sh covers all three."
  }
}
```
