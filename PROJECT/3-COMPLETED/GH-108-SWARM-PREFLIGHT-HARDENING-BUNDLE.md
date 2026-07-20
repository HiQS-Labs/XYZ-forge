---
gh_issue: 108
gh_issues_bundled: [108, 126, 127]
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/108
title: "swarm-preflight hardening bundle: gate-scoping caveat (#108) + covering-test match tightening (#126) + fs-touching regex gap (#127)"
status: Closed — captured 2026-07-04, rated, ready to build
created: 2026-07-04
updated: 2026-07-04
owner: noel
doc_type: bugfix
goal: >
  Harden three swarm-preflight.sh heuristics discovered in the same review pass and touching the
  same file: an explicit scoping caveat for gate commands that look filtered but may not be (#108),
  a tighter covering-test reference check to reduce ALLOW_PATHS false positives (#126), and a
  broadened fs-touching detector that also catches bare '>' redirects (#127).
complexity: 3
risk: 2
effort: 3
phases: 1
ratings_provisional: false
non_goals:
  - "#108: not building cross-runner gate-scoping detection (npx jest <file> construction, runner auto-detect) — that's speculative/bigger, deferred; this pass is the documented-caveat minimum"
  - "#126: not requiring a full static-analysis reference check — a stronger token-boundary substring match is the target, not a source-graph"
  - "#127: not attempting a full shell-command AST parse — broadening the existing regex is the target, not a shell parser"
related:
  - utils/swarm-preflight.sh
  - test/swarm-preflight.sh
---

## Status

| What was just completed | What's next |
|---|---|
| Captured 2026-07-04. #108 is a live dogfood field report (3 of 3, sibling of #106/#107); #126/#127 were found reviewing PR #125 (the GH-54/55 lanes that built the code these two sub-fixes touch). Bundled into one lane because all three touch the same file (`utils/swarm-preflight.sh`) — the swarm-preflight shared-file zone would otherwise serialize them into three separate turns for what is, combined, still a small change. | Build all three sub-fixes in one lane, one turn. |

## Problem (grounded in the current code, three sub-issues)

### #108 — the emitted gate command isn't actually scoped

`GATE_CMD` (`utils/swarm-preflight.sh:600`) is read verbatim from the contract's `gate` field and
passed straight through as `--pre-advance-cmd '$GATE_CMD'` (`:737`). A contract author commonly
writes something like `npm test -- <name>`, assuming `-- <name>` filters to just that test — but
whether that actually scopes depends entirely on the target repo's own `test` script (reproduced
live: a target's `jest --forceExit && npm run test:node` did **not** filter, so the "scoped" gate
ran the whole 1188-test suite, and an unrelated flaky `EADDRINUSE` test failed an otherwise
67/67-green lane).

### #126 — covering-test inference is a raw substring match

`expand-artifacts.mjs`'s covering-test detection:

```js
if (declared.some((artifact) => raw.includes(artifact))) add(inferredTests, rel);
```

matches an artifact path appearing *anywhere* in a test file's text — a comment, an error string, an
unrelated mention — not just a genuine `source`/exec/require reference. This feeds directly into the
generated `ALLOW_PATHS` (write permission), so a false-positive inference widens what the builder
can edit beyond the intended covering test.

### #127 — the fs-touching detector misses a bare `>` redirect

`isFsTouching()`'s regex:

```js
/(mktemp|git(?:\s+-C\s+\S+)?\s+(?:worktree|init)|mkdir\s|touch\s|rm\s+-|cat\s+>|printf\s+.*>|>>|writeFileSync|appendFileSync|mkdtempSync)/s
```

catches `cat >`, `printf ...>`, `>>`, but not a bare single `>` from an arbitrary command (e.g.
`some-cmd > "$TMP/out"`) — a common, equally filesystem-touching pattern that would incorrectly get
the weaker "verify with only this test" guidance instead of GH-54's "do not run in-turn" rule.

## Fix (three sub-fixes, one lane)

1. **#108** — Level-1 (documented-caveat) fix only, matching this repo's "least code that clears the
   bar" convention for a first pass: when `GATE_CMD` matches a heuristic "looks like a filtered-runner
   invocation" shape (e.g. contains `-- ` following a test-runner-looking command), append an explicit
   caveat line to the generated packet/marathon-invocation output: the gate is passed through
   verbatim and its actual scoping depends on the target repo's own test-runner configuration —
   pre-green the full suite (or verify the filter genuinely scopes) before firing the lane. No attempt
   to auto-detect or reconstruct a "real" scoped command.
2. **#126** — tighten the substring match to require the artifact path appear in a stronger context
   than raw containment: immediately preceded by (or as a quoted argument to) `source`, `bash`,
   `node`, or `require(` — not merely present anywhere in the file's text.
3. **#127** — broaden `isFsTouching`'s regex to also catch a bare `>` redirect following a command
   (not just `>>`/`cat >`/`printf...>`), while guarding against false positives on `>=`/`->` and
   other non-redirect uses of `>` in non-shell test content.

## Definition of done

- [ ] #108: a heuristically "looks-filtered" `GATE_CMD` gets an explicit scoping caveat in the
      generated packet output; an already-plain gate (e.g. `bash test/foo.sh`) is unaffected.
- [ ] #126: the covering-test match requires a `source`/`bash`/`node`/`require(`-adjacent reference,
      not a bare substring anywhere in the file; existing T31/T32 fixtures (which use a real
      `source .../consult.sh` reference) still pass unchanged.
- [ ] #127: a test using only a bare `> file` redirect is now classified as fs-touching; existing
      T33 fixture (which uses `mktemp -d`) still passes unchanged; a control case with `2 >&1` /
      `>=` in a non-redirect context is NOT misclassified.
- [ ] `test/swarm-preflight.sh` gets new cases for all three (in addition to existing T31/T32/T33).
- [ ] `bash validate.sh` green.

## Reversibility & blast radius

**Low-medium.** All three sub-fixes tighten or annotate existing heuristics in one file
(`utils/swarm-preflight.sh`); none change the contract schema or the containment kernel. #126/#127
narrow an existing auto-inference (strictly reducing false positives, per their own filed issues),
so the risk direction is "slightly more conservative," not "more permissive." #108 is additive
(a new caveat line), not a behavior change to what gets emitted.

## Swarm Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "bash test/swarm-preflight.sh",
  "fix_probes": [
    { "type": "grep_absent", "path": "utils/swarm-preflight.sh", "pattern": "GH-108" }
  ],
  "artifacts": [
    "utils/swarm-preflight.sh",
    "test/swarm-preflight.sh"
  ],
  "remediation": "Three sub-fixes in utils/swarm-preflight.sh (expand-artifacts.mjs heredoc + the GATE_CMD/packet assembly), all bundled into one lane because they share the same file: (1) GH-108 -- when GATE_CMD heuristically looks like a filtered-runner invocation (contains ' -- ' after a test-runner-looking command), append an explicit caveat to the generated packet/marathon-invocation output stating the gate is passed through verbatim and its real scoping depends on the target repo's own test-runner config; (2) GH-126 -- tighten expand-artifacts.mjs's covering-test substring match (raw.includes(artifact)) to require the artifact path appear immediately preceded by or as a quoted argument to source/bash/node/require(, not merely present anywhere in the file text; (3) GH-127 -- broaden isFsTouching()'s regex to also catch a bare '>' redirect following a command (not just '>>'/'cat >'/'printf...>'), guarding against false positives on '>=' and '->' in non-shell content. Add test/swarm-preflight.sh coverage for all three while keeping existing T31/T32/T33 green. GH-108/GH-126/GH-127 marker comments near each fix.",
  "lanes": {
    "agy_safe": ["utils/swarm-preflight.sh", "test/swarm-preflight.sh"],
    "orchestrator_only": [],
    "note": "swarm-preflight.sh shared-file zone -- the only lane in this plan touching this file, so no serialization needed against other Plan C lanes. Bundles GH-108+GH-126+GH-127 into one turn specifically to avoid three separate same-file lanes for a combined small change."
  }
}
```

## Provenance

#108: field report from a real vendored-install marathon dogfood run (2026-07-04), one of three
independent friction points (siblings: #106, #107). #126/#127: found during independent code review
of PR #125 (the GH-54/GH-55 lanes that built the exact code these two sub-fixes tighten), filed as
separate issues at review time and bundled here purely for zone-collision efficiency.
