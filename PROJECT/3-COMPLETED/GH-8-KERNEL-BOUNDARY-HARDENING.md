---
title: "GH-8: kernel boundary hardening — CLI numeric validation, task/agent format contract, stale-lock pinning"
status: active
created: 2026-08-22
updated: 2026-08-22
owner: orchestrator (Claude Code)
goal: reject malformed CLI input at the tick kernel's boundary instead of persisting NaN/null and unbounded strings into event files
gh_issue: 8
source: https://github.com/HiQS-Labs/XYZ-forge/issues/8
branch: gh-8/kernel-boundary-hardening
doc_type: bugfix
effort: 2
complexity: 2
risk: 1
related:
  - "#2 — same defensive-boundary family (unguarded I/O edges); disjoint write-set"
---

# GH-8 — kernel boundary hardening

## Status

| What was just completed | What's next |
|---|---|
| capture doc + preflight contract written (ready, exit 0; acceptance copied verbatim from the issue); queued as Bulkhead wave 1 (2026-08-22, release 0.7.3 "Bulkhead", #179) | Operator fires the marathon lane per MARATHON-PLAN-2026-08-23.md; builder executes ## Plan, reviewer verifies ## Acceptance |


Release 0.7.3 "Bulkhead" manifest member. Radar 2026-08-22: data-integrity class.

## Bug

`bin/tick` does `Number(flags.priority)` / `Number(flags.epoch)`: `tick claim --priority abc`
yields `NaN`, which `JSON.stringify` writes as `null` into the event file — a permanently
malformed field no reader flags. `safeSegment` (src/events.js) sanitizes only the filename;
stored `task`/`agent` event fields accept arbitrary strings (newlines, control chars, 10KB
blobs) that later render into STATE.md. Corrupt-file recovery already landed via #5/PR #7;
this issue is the rest of the boundary.

## Plan

1. `bin/tick`: validate numeric flags (reject NaN/negative/out-of-range with a named error,
   exit non-zero) before any event write.
2. `src/events.js`: enforce a format contract on `task`/`agent` values at `appendEvent`
   (charset + length cap), refusing rather than sanitizing silently.
3. New suite `test/gh8-kernel-boundary.sh`: malformed-input matrix (NaN priority, control-char
   agent, oversize task) — each refused, event file byte-identical after refusal; register in
   validate.sh TESTS.

## Acceptance

- [ ] `--priority abc` / `--epoch -1` / `--priority=3` all behave correctly (reject, reject, accept).
- [ ] Malformed `task`/`agent` strings are refused at write time with actionable errors.
- [ ] `test/unit/cli.test.js` and `test/unit/lock.test.js` exist and pass via `npm run test:unit`.
- [ ] Full `./validate.sh` green in a disposable clone.

## Swarm Preflight Contract

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [ { "type": "path_absent", "path": "test/unit/cli.test.js" },
                     { "type": "path_absent", "path": "test/unit/lock.test.js" } ],
  "artifacts":     [ "bin/tick", "src/events.js", "test/unit/cli.test.js", "test/unit/lock.test.js" ],
  "artifacts_new": [ "test/unit/cli.test.js", "test/unit/lock.test.js" ],
  "remediation":   { "source": "self#plan", "criteria": "malformed numeric/task/agent input refused at the boundary with a named error; no event write on refusal; gh8 suite green and registered" },
  "lanes":         { "agy_safe": [ "test/gh8-kernel-boundary.sh" ], "orchestrator_only": [ "bin/", ".tick/" ] }
}
```

## Lessons Learned (For Future Agents)

The relay's static-only reviewer turns earned their keep here: three rounds of read-only codex
review caught the exact acceptance-criterion gap (`--priority=3` equals-form unparsed), then two
successively deeper boundary defects (bare flags coerced to `1` via `Number(true)`, empty
equals-values coerced to `0` via `Number('')`, and `Infinity` surviving to `JSON.stringify` as
`null`) — none of which the builder's green unit runs surfaced, because the tests exercised only
the forms the builder had implemented. Lesson: when an acceptance criterion names an exact
invocation shape, the test must use that verbatim shape, not a semantically-similar one. The run
also escalated at the fixed round cap 5 while demonstrably converging (each round fixed the prior
round's real findings); manual resumption of the same relay file/task at cap 6 let the owed
reviewer turn land a legitimate Approved. That premature-escalation pattern is exactly what
GH-115 (same wave) then fixed — the two lanes validated each other.
