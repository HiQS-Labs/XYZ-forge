# GH-809 — JSONL line-reader verification

- Base revision: `3d536139b420fc76933eb47311ae4beec3efb372`
- Candidate revision: `3d536139b420fc76933eb47311ae4beec3efb372` plus the uncommitted `src/events.js` change
- Runtime: Node.js `v22.22.3`, macOS
- Fixture: temporary `TICK_REPO_ROOT` created with `mktemp -d -t tick-gh809.XXXXXX`

## Commands and observed results

1. **Red control, valid two-line fixture, unmodified base**
   ```bash
   TICK_REPO_ROOT="$FIXTURE" bin/tick info GH-809
   ```
   Exit 1. Stderr: `tick: error: Unexpected non-whitespace character after JSON at position 115 (line 2 column 1)`. See `red-info.*`.

2. **Green control, unchanged valid two-line fixture**
   ```bash
   TICK_REPO_ROOT="$FIXTURE" bin/tick info GH-809
   ```
   Exit 0. Stdout contained `status: open`; stderr was empty. See `green-info.*`.

3. **Direct ordering and provenance assertion**
   ```bash
   FIXTURE="$FIXTURE" node <<'NODE'
   const assert = require('node:assert/strict');
   const { readAllEvents } = require('./src/events');
   const all = readAllEvents(process.env.FIXTURE);
   assert.deepStrictEqual(all.map(e => e.type), ['task.created', 'task.commented']);
   assert.deepStrictEqual(all.map(e => e._file), ['x.jsonl', 'x.jsonl']);
   NODE
   ```
   Exit 0; both assertions passed. See `direct-ordering.*`.

4. **Invalid second line**
   ```bash
   TICK_REPO_ROOT="$FIXTURE" bin/tick info GH-809
   ```
   After replacing line 2 with `{not-json}`, exit 0 and stdout contained `status: open`. Stderr contained exactly one warning: `tick: warning: skipping invalid JSON in x.jsonl:2: Expected property name or '}' in JSON at position 1 (line 1 column 2)`. See `invalid-info.*`.

5. **Existing unit regression**
   ```bash
   node --test test/unit/events.test.js
   ```
   Exit 0; 4 tests passed, 0 failed. See `unit-events.*`.

## Verdict

**PASS.** The pre-fix control failed on valid JSONL as required. The candidate reads both events in physical line order with the expected `_file`, recovers from an invalid line with the specified warning, and passes the existing unit regression.

## Final QA strict-claims verification

Candidate revision remains `3d536139b420fc76933eb47311ae4beec3efb372` plus uncommitted changes to `src/events.js`, `bin/tick`, and the GH-809 plan. A fresh temporary `TICK_REPO_ROOT` was used and deleted after these checks.

6. **Valid two-line claims audit**
   ```bash
   TICK_REPO_ROOT="$FIXTURE" bin/tick claims --json
   ```
   Exit 0. Stdout parsed as valid JSON with a `claimed` array. See `claims-valid.*`.

7. **Malformed second line fails claims closed**
   ```bash
   TICK_REPO_ROOT="$FIXTURE" bin/tick claims --json
   ```
   After replacing line 2 with `{not-json}`, exit 3. Stderr contained `events-unreadable` and `x.jsonl:2`. See `claims-invalid.*`.

8. **Non-strict info regression on the same malformed fixture**
   ```bash
   TICK_REPO_ROOT="$FIXTURE" bin/tick info GH-809
   ```
   Exit 0 with `status: open` and the exact `x.jsonl:2` skip warning. See `strict-info-invalid.*`.

9. **Existing unit regression after strict-mode change**
   ```bash
   node --test test/unit/events.test.js
   ```
   Exit 0; 4 tests passed, 0 failed. See `unit-events-strict.*`.

**Final QA verdict: PASS.** The claims safety query fails closed on malformed JSON, while ordinary readers retain skip-and-warn behavior.
