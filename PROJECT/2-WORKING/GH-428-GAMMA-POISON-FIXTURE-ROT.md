---
gh_issue: 428
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/428
title: "gamma-poison poison.patch no longer applies — the GH-40 qualification gate is un-runnable"
status: 2-WORKING
created: 2026-08-13
updated: 2026-08-13
owner: unassigned
doc_type: capture
complexity: 2
risk: 2
effort: 2
ratings_provisional: true
goal: >
  Re-derive poison.patch against the current src/paths.js so the GH-40 double-blind Reviewer
  qualification gate can execute again, and add a non-recursive staleness probe so the next
  src/paths.js refactor produces a visible failing check instead of silent fixture rot.
---

## Why

`git apply --check test/fixtures/gamma-poison/poison.patch` fails on `development`:
`error: patch failed: src/paths.js:9 / patch does not apply`. Independently reproduced during
the 2026-08-13 `/10days` sweep.

The poison patch was derived before GH-71 refactored `src/paths.js`. The fixture is deliberately
not wired into `validate.sh` — its own `verify-fixture.sh` runs the full suite, so nesting would
recurse — which means **no check detects the rot**. `test/fixtures/gamma-poison/README.md` warns
about exactly this staleness mode; the warning came true and nothing noticed.

The gamma fixture is Phase 1 of the GH-40 double-blind Reviewer qualification gate — the only
fixture testing the catastrophic failure mode (a Reviewer rubber-stamping a change that silently
drops the suite). While the patch does not apply, no Reviewer can be qualified or re-qualified,
which blocks the semantic-oracle stage and the reflection pipeline.

## Key concepts

- Poison semantics to preserve: drop `*` from the negated class in `literalPrefix()` — a plausible
  cleanup, silent, dropping exactly one check.
- The staleness probe must be non-recursive: a plain `git apply --check`, never executing the
  fixture.
- Related: GH-429 (the qualification gate has only ever been measured once) is gated on this
  issue restoring runnability. Not in scope here.

## Acceptance

Authored by `/10days` — the tracking issue has no `## Acceptance` section, so there is no block
to copy verbatim. These criteria are a direct transcription of the issue's numbered `**Fix:**`
list (items 1–3), split into checkable statements.

1. `git apply --check test/fixtures/gamma-poison/poison.patch` exits 0 against the current
   `src/paths.js`.
2. The re-derived patch preserves the original poison semantics: it drops `*` from the negated
   class in `literalPrefix()`, and is silent (no comment or marker announcing itself).
3. `test/fixtures/gamma-poison/verify-fixture.sh` runs end-to-end — apply → validate → assert the
   single failing check is `path-overlap` → auto-revert — and leaves a clean tree.
4. Exactly one check fails under the poison, and it is `path-overlap`.
5. `validate.sh` gains a non-recursive staleness probe that runs `git apply --check
   test/fixtures/gamma-poison/poison.patch` and fails visibly when it no longer applies. The probe
   does NOT execute `verify-fixture.sh` (no recursion).
6. `bash validate.sh` exits 0.

## Swarm Preflight Contract

```json
{
  "target":      { "repo": ".", "ref": "development" },
  "gate":        "bash validate.sh",
  "fix_probes":  [
    { "type": "grep_absent", "path": "validate.sh", "pattern": "gamma-poison/poison.patch" }
  ],
  "artifacts":   [
    "test/fixtures/gamma-poison/poison.patch",
    "test/fixtures/gamma-poison/README.md",
    "validate.sh"
  ],
  "remediation": { "source": "issue#428", "criteria": "Re-derive the poison patch against current src/paths.js and add a non-recursive staleness probe to validate.sh" },
  "lanes":       { "agy_safe": [ "test/fixtures/gamma-poison/" ], "orchestrator_only": [ "validate.sh" ] }
}
```

Contract auto-drafted by /10days from the issue text — artifacts/lanes not yet operator-verified.
`src/paths.js` is deliberately NOT in `artifacts`: the patch is re-derived *against* it, and the
production file must not be edited by this lane.
