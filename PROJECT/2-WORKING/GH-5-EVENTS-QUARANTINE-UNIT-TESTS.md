---
title: "GH-5: readAllEvents corrupt-file recovery + node:test unit runner for src/"
status: active
created: 2026-08-15
updated: 2026-08-15
owner: orchestrator (Claude Code)
goal: a corrupt .jsonl event file must not take down every tick verb; give the kernel a direct unit-test runner
gh_issue: 5
source: https://github.com/HiQS-Suite/XYZ-forge/issues/5
branch: gh-5/events-quarantine-unit-tests
doc_type: bugfix
effort: 1
complexity: 2
risk: 1
related: "[kernel robustness, test tooling floor]"
---

# GH-5 — readAllEvents corrupt-file recovery + unit-test runner

Captured and promoted in the same PR (issue-first SOP): the issue was filed 2026-08-15 against the
public repo and execution starts immediately.

## Status

| What was just completed | What's next |
|---|---|
| Issue filed; capture promoted to 2-WORKING | Implement quarantine + unit tests; verify; open PR |

## Bug

`src/events.js` `readAllEvents` maps `JSON.parse` over every `.jsonl` file with no per-file error
handling. One malformed/truncated file (a writer killed mid-`writeFileSync`) throws and takes down
every `tick` verb, including read-only `next`/`info`/`analyze`. The coordination kernel is the tool
agents reach for when things go wrong; it must survive a damaged log.

Secondarily, `src/` has no unit-test runner — `foldWithMeta` is a pure function of the event set
but is exercised only through bash acceptance tests, and `package.json` has zero devDependencies.

## Source of truth

- GitHub issue: [HiQS-Suite/XYZ-forge#5](https://github.com/HiQS-Suite/XYZ-forge/issues/5)

## Plan

1. `readAllEvents`: wrap parsing per file; on failure rename the file to `<name>.corrupt`
   (quarantine so it is not re-parsed every run), warn on stderr with the file name and error,
   and continue. Empty files are skipped silently.
2. Unit tests under `test/unit/` using the built-in `node:test` runner (zero new dependencies):
   - `events.test.js` — append/read round-trip, chronological ordering, corrupt-file quarantine,
     empty-file tolerance, unknown-type rejection.
   - `project.test.js` — fold invariants: idempotence, claim/release/done projection, epoch fencing
     rejects stale writer, terminal seal.
3. `package.json`: add `"test:unit": "node --test test/unit/"`. Leave `npm test` → `validate.sh`
   untouched.

## Verification

- `npm run test:unit` → expect all pass.
- Manual: write a valid event, corrupt a second file, `bin/tick next` still answers and the corrupt
  file is renamed `.corrupt` with a stderr warning.
- Existing acceptance suites unaffected (no behavior change on the healthy-log path — quarantine
  only fires where the old code threw).

## Non-goals

- eslint/prettier adoption (separate change), repairing corrupt files, fsync/durability work.
