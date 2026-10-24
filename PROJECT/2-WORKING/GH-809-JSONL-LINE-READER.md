---
title: "tick: readAllEvents parses each .jsonl FILE as one JSON doc"
status: In Progress
created: 2026-10-24
updated: 2026-10-24
owner: agent
goal: "tick read verbs survive multi-line .jsonl event files: one event per line, bad lines skipped with a warning."
complexity: 1
risk: 1
effort: 1
phases: 1
gh_issue: 809
source: https://github.com/HiQS-Labs/XYZ-forge/issues/809
doc_type: bugfix
non_goals:
  - Quarantine/rename of corrupt event files (GH-5's scope)
  - A src/ unit-test runner (GH-5's scope; no new tests per GH-831)
  - Rewriting the wave_reconcile rollback writer (already disambiguated by pid + random suffix)
---

# GH-809 — tick reads `.jsonl` event files as one JSON document

## Status

| What was just completed | What's next |
|---|---|
| Plan written by Kimi K3.1 (planner/builder for this task); plan QA by Claude approved round 1. | Kimi builds `readAllEvents` per the plan; red/green manual control and existing suites; Claude final QA; PR. |

## Plan QA (2026-10-24, reviewer: Claude; operator named Claude as reviewer in place of Codex)

Verdict: **Approved, round 1.** Checked against source: `TICK_REPO_ROOT`
(`bin/tick:19`), `task.created`/`task.commented` in `EVENT_TYPES`
(`src/events.js:12,16`), `status:` line of `tick info` (`bin/tick:466`), 21
`readAllEvents` call sites outside `src/events.js`, and `test/unit/events.test.js`
present. Scope stays in one function, no new tests or writers, GH-5 excluded.
Non-blocking: `test/unit/events.test.js` is not in the `validate.sh` registry, so
it is a manual regression run, not gate evidence.

## Ask

`src/events.js` `readAllEvents` reads each `.tick/events/*.jsonl` file with
`JSON.parse(raw)` as a single document. A file holding two JSON lines throws
`Unexpected non-whitespace character after JSON`, and every verb that reads the
event log (`claim`, `release`, `info`, `reap`, ...) dies on that machine.

## Acceptance (from the issue)

- `readAllEvents` parses per line (JSONL semantics, matching the extension).
- An unparseable line is skipped with a warning naming the file, rather than
  killing the scan.
- Red control: a fixture `.tick/events/x.jsonl` with two valid lines makes
  `tick info` fail before the fix and return state after it; a mutated invalid
  line warns instead of dying.

## Rating (2026-10-24) — rated 72/82/50/88

- sev 82: work-blocking — one multi-line file stops every coordination verb on
  the machine; recoverable by deleting the file, no data corruption.
- pri 72: severity-led; still reachable today (live files on disk) but the
  writer that produced them is fixed, lowering new-incident odds.
- appeal 50: neutral (no operator preference given).
- effort 88: one function in one file, existing suites cover the read path.
- Recurrence: 3 incidents 2026-09-21..24 (one writer, double-fires); none found
  in 2026-09-26..10-24 issues. Trend: flat since the writer fix; coverage limited
  to GitHub issues.

## Status at capture (2026-10-24)

- Reader defect: still live on `origin/development` (`c5ef7a2e`).
- Writer defect: already addressed — the rollback filename now carries
  `<pid>-<random hex>` (`utils/py/wave_reconcile.py:192`), so a double-fire no
  longer appends to one file.
- Live multi-line files remain in at least one local clone
  (`XYZ-forge-gh676/.tick/events/2026-09-21T*-wave-reconcile-rollback.jsonl`).

## Plan

### Observed problem

`readAllEvents` filters and sorts `.jsonl` filenames, then reads each whole file,
trims it, and calls `JSON.parse` once (`src/events.js:204-213`, especially
`:208-212`). Two JSON objects separated by a newline therefore throw instead of
producing two events; one malformed line likewise aborts the entire scan. The
existing writer publishes one object plus newline per file
(`src/events.js:188-195`), but the reader must also tolerate existing multi-line
files. The GitHub issue confirms the user-facing failure through `tick info` and
other coordination verbs.

### Callers and blast radius

All direct callers were traced with `readAllEvents` searches under `src/` and
`bin/`:

- `project()` reads at `src/project.js:343`; `bin/tick:219-232` exposes it through
  `project`/`fences`, and `bin/tick:458-475` through `info`.
- Claim and routing paths read at `src/claim.js:34`, `src/take.js:25`, and
  `src/next.js:22`.
- `scope()` and `reap()` read at `src/scope.js:54` and `:168`; the ownership
  fallback at `src/scope.js:28` also serves `release`, `break`, `done`, and `ping`
  through the callers at `:90`, `:105`, `:121`, and `:146`.
- Analysis reads at `src/analyze.js:416`; the read-only `claims` audit reads at
  `bin/tick:441` and retains its existing unreadable-events error handling.
- Thus malformed event input can stop projection, claims, mutation ownership
  checks, routing, reaping, analysis, and audit consumers. `tick log` and the
  other append-only paths do not call the reader and are not changed. No caller
  changes, schema changes, event writes, or new modules are needed.

This is an **Easy**, local reader change: it broadens accepted input and warns on
bad lines, while leaving files and all writer contracts untouched. Filesystem
read/list failures remain fatal; only per-line JSON parse failures become
fail-soft.

### Exact intended change

Replace the single-object `files.map` body in `readAllEvents` with a flattened
per-file/per-line scan (approximately 15 lines in `src/events.js`):

- Keep the existing missing-directory behavior, `.jsonl` filter, filename sort,
  and synchronous file reads.
- Split each file on `/\r?\n/`; ignore lines whose trimmed content is empty.
- Parse each remaining line independently in a per-line `try`/`catch`. On success,
  stamp the existing `_file` basename and return that one event. On parse failure,
  emit the warning below and return no event for that line, then continue with
  subsequent lines and files.
- Use `flatMap` (or equivalent loops) so no nested arrays escape. Do not catch
  `readFileSync`/`readdirSync` errors, add schema validation, quarantine files, or
  alter `appendEvent`.
- Update the `readAllEvents` ordering comment at `src/events.js:198-203` to state
  filename order followed by line order and the skip-and-warn behavior. Leave the
  atomic-publish comments accurate and unchanged.

### Ordering and warning contract

Files remain in lexically sorted filename order (`src/events.js:207`). Events
within one multi-line file are emitted in physical top-to-bottom line order;
there is no additional timestamp sort. Valid lines after a bad line retain their
original relative positions, and every returned event carries `_file` equal to
its source basename. Blank lines emit neither events nor warnings.

For each malformed line, write exactly this prefix and the native parse message
to stderr, with a trailing newline:

```text
tick: warning: skipping invalid JSON in <file>:<1-based-line-number>: <JSON.parse error>
```

For example: `tick: warning: skipping invalid JSON in x.jsonl:2: ...`. Do not
print valid event contents or add a second logging mechanism.

### Rollback

Revert only the `readAllEvents` body and its adjacent function comment in
`src/events.js`. There is no migration or persisted output to unwind, and skipped
lines are never modified or deleted. Rollback restores the old whole-file parse
failure but cannot damage event data.

### Non-goals

- No GH-5 quarantine/rename behavior and no new unit-test runner.
- No new test files, test cases, `validate.sh` registry entries, or gate machinery
  (GH-831); use the existing suites and manual evidence below.
- No change to the rollback writer. Its exclusive-create filename already includes
  milliseconds, pid, and random suffix at `utils/py/wave_reconcile.py:185-194`.
- No new read/write paths, dependencies, refactors, or event schema/validation work.

### Existing verification

Run these existing files unchanged from a separate disposable full clone (not a
linked worktree or valued checkout):

```bash
node --test test/unit/events.test.js
bash test/gh14-atomic-append.sh
bash test/projection-idempotent.sh
bash test/gh23-path-overlap-enforcement.sh
```

Their read-path coverage was inspected directly: `test/unit/events.test.js:18-45`
checks returned events, `_file`, and filename ordering;
`test/gh14-atomic-append.sh:108-139` and `:154-207` exercise direct reads and
concurrent reader behavior; `test/projection-idempotent.sh:5-19` checks repeated
projection; and `test/gh23-path-overlap-enforcement.sh:29-34` plus `:73-79`
exercises claim/scope reads and `tick info`. These are regression checks, not a
claim that the old suites already cover multi-line input; the red/green control
below supplies that discriminator.

### Manual red/green control

Use a temporary `TICK_REPO_ROOT`, never a live `.tick` directory. Run the setup
and valid-file invocation on the unmodified base first; retain its nonzero status
and JSON error. Then apply only the reader change, rerun the same valid-file
invocation, and continue with the direct ordering/provenance assertion and the
invalid-line case.

```bash
ROOT=$(pwd -P)
TICK="$ROOT/bin/tick"
EVIDENCE="$ROOT/TESTS-RESULTS/2026-10-24+GH-809"
WORK=$(mktemp -d -t tick-gh809.XXXXXX)
FIXTURE="$WORK/repo"
mkdir -p "$FIXTURE/.tick/events" "$EVIDENCE"
cat >"$FIXTURE/.tick/events/x.jsonl" <<'EOF'
{"schema_version":"0.2.0","ts":"2026-10-24T00:00:00.000Z","type":"task.created","task":"GH-809","agent":"fixture"}
{"schema_version":"0.2.0","ts":"2026-10-24T00:00:01.000Z","type":"task.commented","task":"GH-809","agent":"fixture","note":"second"}
EOF
[ "$(wc -l <"$FIXTURE/.tick/events/x.jsonl")" -eq 2 ] || exit 1

# BEFORE: expect nonzero and a whole-file JSON.parse error; save red-info.*.
set +e
TICK_REPO_ROOT="$FIXTURE" "$TICK" info GH-809 \
  >"$EVIDENCE/red-info.out" 2>"$EVIDENCE/red-info.err"
red_rc=$?
set -e
printf '%s\n' "$red_rc" >"$EVIDENCE/red-info.rc"
[ "$red_rc" -ne 0 ] && grep -q 'JSON\|Unexpected' "$EVIDENCE/red-info.err"

# AFTER: rerun against the unchanged fixture; expect rc=0 and projected state.
TICK_REPO_ROOT="$FIXTURE" "$TICK" info GH-809 \
  >"$EVIDENCE/green-info.out" 2>"$EVIDENCE/green-info.err"
printf '%s\n' "$?" >"$EVIDENCE/green-info.rc"
grep -Eq '^status:[[:space:]]+open$' "$EVIDENCE/green-info.out"

# AFTER: independently prove both lines survive in order with the same _file.
FIXTURE="$FIXTURE" node <<'NODE'
const assert = require('node:assert/strict');
const { readAllEvents } = require('./src/events');
const all = readAllEvents(process.env.FIXTURE);
assert.deepStrictEqual(all.map(e => e.type), ['task.created', 'task.commented']);
assert.deepStrictEqual(all.map(e => e._file), ['x.jsonl', 'x.jsonl']);
NODE

# AFTER: replace line 2 with invalid JSON; valid line 1 still projects and line 2 warns.
printf '%s\n' \
  '{"schema_version":"0.2.0","ts":"2026-10-24T00:00:00.000Z","type":"task.created","task":"GH-809","agent":"fixture"}' \
  '{not-json}' >"$FIXTURE/.tick/events/x.jsonl"
TICK_REPO_ROOT="$FIXTURE" "$TICK" info GH-809 \
  >"$EVIDENCE/invalid-info.out" 2>"$EVIDENCE/invalid-info.err"
printf '%s\n' "$?" >"$EVIDENCE/invalid-info.rc"
grep -Eq '^status:[[:space:]]+open$' "$EVIDENCE/invalid-info.out"
grep -F 'tick: warning: skipping invalid JSON in x.jsonl:2:' \
  "$EVIDENCE/invalid-info.err"
```

Retain the red and green outputs, exit codes, direct assertion result, exact base
and candidate revisions, runtime versions, commands, and outcomes in
`TESTS-RESULTS/2026-10-24+GH-809/SUMMARY.md` and `provenance.jsonl`. A green run
without the recorded pre-fix nonzero control is insufficient.

### Ordered implementation

1. Record the base revision and run the valid two-line manual control above.
   -> expect `tick info` to fail nonzero with the whole-file JSON parse error.
2. Edit only `readAllEvents` and its adjacent ordering comment in `src/events.js`
   as specified; do not touch callers or writers.
   -> expect a surgical diff with per-line parsing, `_file`, blank-line skipping,
   and per-line warning recovery.
3. Run the valid-file green command and direct ordering/provenance assertion.
   -> expect `tick info` to return `status: open` and the reader to return both
   events in line order, both with `_file: "x.jsonl"`.
4. Run the invalid-line command.
   -> expect exit 0, valid-line state in stdout, and the exact `x.jsonl:2`
   warning prefix in stderr rather than a crash.
5. Run the four existing verification commands in a disposable full clone.
   -> expect all four to pass without modifying tests or the registry.
6. Review the final diff and event fixtures, then retain the manual artifacts and
   `provenance.jsonl` under `TESTS-RESULTS/2026-10-24+GH-809/`.
   -> expect production changes confined to `src/events.js`, with documented
   before/after evidence and no new test or writer files.
