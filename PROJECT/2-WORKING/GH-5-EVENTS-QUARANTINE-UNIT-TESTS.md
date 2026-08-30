---
title: "GH-5: node:test unit runner for src/"
status: active
created: 2026-08-15
updated: 2026-08-16
owner: orchestrator (Claude Code)
goal: this lane delivers ONLY the node:test unit runner and the first direct unit tests for src/. The corrupt-file recovery is re-routed to #14 (atomic write first; quarantine only on top of atomic writes), per the correction on #5.
gh_issue: 5
source: https://github.com/HiQS-Labs/XYZ-forge/issues/5
branch: gh-5/events-quarantine-unit-tests
doc_type: bugfix
effort: 1
complexity: 2
risk: 1
related: "[kernel robustness, test tooling floor]"
---

# GH-5 — node:test unit runner

Captured and promoted in the same PR (issue-first SOP): the issue was filed 2026-08-15 against the
public repo and execution starts immediately.

## Status

| What was just completed | What's next |
|---|---|
| Issue filed; capture promoted to 2-WORKING | Split applied on orchestrator review: tests half lands here, reader recovery → #14 | Merge; **#5 stays open until this PR's tests and #14's atomic write have both landed** — do not close it on the tests half alone |

## Bug

`src/events.js` `readAllEvents` maps `JSON.parse` over every `.jsonl` file with no per-file error
handling. One malformed/truncated file (a writer killed mid-`writeFileSync`) throws and takes down
every `tick` verb, including read-only `next`/`info`/`analyze`. The coordination kernel is the tool
agents reach for when things go wrong; it must survive a damaged log.

Secondarily, `src/` has no unit-test runner — `foldWithMeta` is a pure function of the event set
but is exercised only through bash acceptance tests, and `package.json` has zero devDependencies.

The reader-recovery half was rejected on review (unsafe while writes are non-atomic — it can quarantine a valid in-flight event, which is silent permanent event loss) and moved to #14.

## Source of truth

- GitHub issue: [HiQS-Labs/XYZ-forge#5](https://github.com/HiQS-Labs/XYZ-forge/issues/5)

## Plan

1. Unit tests under `test/unit/` using the built-in `node:test` runner (zero new dependencies):
   - `events.test.js` — append/read round-trip, chronological ordering, unknown-type rejection.
   - `project.test.js` — fold invariants: idempotence, claim/release/done projection, epoch fencing
     rejects stale writer, terminal seal.
2. `package.json`: add `"test:unit": "node --test test/unit/"`. Leave `npm test` → `validate.sh`
   untouched.

## Verification

- `npm run test:unit` → expect all pass (11 tests now).
- Existing acceptance suites unaffected (`./validate.sh` green).

## Non-goals

- eslint/prettier adoption (separate change), repairing corrupt files, fsync/durability work.
- reader-side corrupt-file recovery (→ #14: atomic write in `appendEvent`, quarantine layered on top only after that).
