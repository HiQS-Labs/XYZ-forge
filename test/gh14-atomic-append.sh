#!/usr/bin/env bash
# GH-14 — appendEvent must publish each event atomically: the JSON document is written to a
# `.tmp` name that readAllEvents' `.jsonl` filter never matches, then rename(2)'d onto the
# final path, so a concurrent reader observes either no file or the complete document — never
# a torn/partial/empty `.jsonl` (the pre-fix direct writeFileSync created the reader-visible
# file before its contents landed, letting readers throw parse errors or misclassify in-flight
# events as corrupt).
#
# Coverage:
#   1. Healthy-path bytes and filename are preserved exactly (byte-for-byte vs the documented
#      field order, deterministic via TICK_TS).
#   2. Mechanism pin (the deterministic discriminator): fs.writeFileSync/renameSync are traced;
#      the ONLY write must go to a non-`.jsonl` name in the same directory, followed by exactly
#      one rename onto the final `.jsonl` path, with nothing non-`.jsonl` left behind. This is
#      red on the pre-fix shape (a direct write to the `.jsonl` path, no rename).
#   3. A torn document at a `.tmp` name (crashed/in-flight writer) is invisible to
#      readAllEvents: no parse error, not counted, real events still read.
#   4. Cross-process stress: two writer processes append events while a reader process loops
#      readAllEvents, failing hard on ANY parse error or partial event, until all events are
#      observed. Then no `.tmp` residue and the final count is exact.
source "$(dirname "$0")/_setup.sh" gh14-atomic-append
unset TICK_TS

ROOT="$(cd -P "$(dirname "$0")/.." && pwd)"
EVENTS_SRC="$ROOT/src/events.js"
[ -f "$EVENTS_SRC" ] || fail "src/events.js not found at $EVENTS_SRC"
command -v node >/dev/null 2>&1 || fail "node is required for this test"

# --- Part 1: healthy-path bytes and filename preserved exactly --------------------------------
cat > "$WORK/bytes-check.js" <<'EOF'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const { appendEvent, SCHEMA_VERSION } = require(path.join(process.env.ROOT, 'src', 'events.js'));
const root = process.env.A;

process.env.TICK_TS = '2026-08-17T00:00:00.000Z';
const res = appendEvent(root, {
  type: 'task.created', task: 'GH14-T1', agent: 'agent-a',
  note: 'hello gh14', priority: 2,
});

const expected = {
  schema_version: SCHEMA_VERSION,
  ts: '2026-08-17T00:00:00.000Z',
  type: 'task.created',
  task: 'GH14-T1',
  agent: 'agent-a',
  note: 'hello gh14',
  priority: 2,
};
assert.strictEqual(fs.readFileSync(res.path, 'utf8'), JSON.stringify(expected) + '\n',
  'written bytes must equal the pre-fix format exactly');
assert.strictEqual(path.basename(res.path),
  '2026-08-17T00-00-00.000Z-agent-a-created-GH14-T1.jsonl', 'filename format preserved');
assert.deepStrictEqual(res.event, expected, 'returned event object unchanged');
console.log('bytes ok');
EOF
if ROOT="$ROOT" A="$A" node "$WORK/bytes-check.js" >"$WORK/bytes-check.out" 2>&1; then
  pass "healthy-path event bytes and filename preserved byte-for-byte"
else
  fail "healthy-path bytes changed: $(cat "$WORK/bytes-check.out")"
fi

# --- Part 2: mechanism pin — tmp write first, then exactly one atomic rename ------------------
cat > "$WORK/mechanism-check.js" <<'EOF'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const { appendEvent } = require(path.join(process.env.ROOT, 'src', 'events.js'));
const root = process.env.A;

const calls = [];
const origWrite = fs.writeFileSync;
const origRename = fs.renameSync;
fs.writeFileSync = (p, data, ...rest) => { calls.push({ op: 'write', path: String(p) }); return origWrite(p, data, ...rest); };
fs.renameSync = (from, to) => { calls.push({ op: 'rename', from: String(from), to: String(to) }); return origRename(from, to); };

process.env.TICK_TS = '2026-08-17T00:00:01.000Z';
const res = appendEvent(root, { type: 'task.heartbeat', task: 'GH14-T2', agent: 'agent-a' });

// No write may ever target a reader-visible .jsonl path.
const direct = calls.filter(c => c.op === 'write' && c.path.endsWith('.jsonl'));
assert.strictEqual(direct.length, 0, 'no direct write to a .jsonl path');
// Exactly one write, to a non-.jsonl temp name in the SAME directory (rename(2) is
// atomic only within a filesystem, so the temp file must not live elsewhere).
const writes = calls.filter(c => c.op === 'write');
assert.strictEqual(writes.length, 1, 'exactly one write per event');
assert.ok(!writes[0].path.endsWith('.jsonl'), 'write target is not reader-visible');
assert.strictEqual(path.dirname(writes[0].path), path.dirname(res.path), 'temp file lives next to the final path');
// Then exactly one rename from that temp name onto the final .jsonl path.
const renames = calls.filter(c => c.op === 'rename');
assert.strictEqual(renames.length, 1, 'exactly one rename per event');
assert.strictEqual(renames[0].from, writes[0].path, 'rename source is the temp file');
assert.strictEqual(renames[0].to, res.path, 'rename target is the final path');
assert.ok(res.path.endsWith('.jsonl'), 'final path is a .jsonl file');
// Nothing non-.jsonl may remain visible in the events directory.
const leftovers = fs.readdirSync(path.dirname(res.path)).filter(f => !f.endsWith('.jsonl'));
assert.deepStrictEqual(leftovers, [], 'no non-.jsonl leftovers after append');
console.log('mechanism ok');
EOF
if ROOT="$ROOT" A="$A" node "$WORK/mechanism-check.js" >"$WORK/mechanism-check.out" 2>&1; then
  pass "appendEvent writes via a temp name and one atomic rename onto the .jsonl path"
else
  fail "atomic-publish mechanism violated: $(cat "$WORK/mechanism-check.out")"
fi

# --- Part 3: a torn in-flight document at a .tmp name is invisible to readers -----------------
cat > "$WORK/tmp-tolerance-check.js" <<'EOF'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const { appendEvent, readAllEvents, eventsDir } = require(path.join(process.env.ROOT, 'src', 'events.js'));
const root = process.env.A;
const dir = eventsDir(root);

// Simulate a writer that crashed mid-write: torn JSON at the temp name. Use a
// timestamp DISTINCT from the event appended below, so this fixture cannot
// collide with the temp name appendEvent derives for that same event.
const tmpName = '2026-08-17T00-00-09.000Z-agent-a-created-GH14-T9.jsonl.tmp';
fs.writeFileSync(path.join(dir, tmpName), '{"schema_version":"0.2');
const before = readAllEvents(root).length;

process.env.TICK_TS = '2026-08-17T00:00:02.000Z';
appendEvent(root, { type: 'task.created', task: 'GH14-T3', agent: 'agent-a' });

const evs = readAllEvents(root);
assert.strictEqual(evs.length, before + 1, 'torn .tmp file must not be counted');
assert.ok(evs.every(e => e.schema_version && e.ts && e.type && e.task && e.agent),
  'every observed event is complete');
assert.ok(!evs.some(e => String(e._file).includes('.tmp')), 'no .tmp file surfaces as an event');
fs.unlinkSync(path.join(dir, tmpName));
console.log('tmp tolerance ok');
EOF
if ROOT="$ROOT" A="$A" node "$WORK/tmp-tolerance-check.js" >"$WORK/tmp-tolerance-check.out" 2>&1; then
  pass "readers never see a torn in-flight .tmp document and still read real events"
else
  fail "reader tripped over an in-flight .tmp document: $(cat "$WORK/tmp-tolerance-check.out")"
fi

# --- Part 4: cross-process stress — readers must never observe a torn file --------------------
cat > "$WORK/stress-writer.js" <<'EOF'
const path = require('path');
const { appendEvent } = require(path.join(process.env.ROOT, 'src', 'events.js'));
const root = process.env.A;
const prefix = process.argv[2];
const count = Number(process.argv[3]);
for (let i = 1; i <= count; i++) {
  const task = `${prefix}-${String(i).padStart(4, '0')}`;
  appendEvent(root, { type: 'task.commented', task, agent: `writer-${prefix}`, note: `note-${task}` });
}
console.log(`writer ${prefix} done`);
EOF
cat > "$WORK/stress-reader.js" <<'EOF'
const path = require('path');
const { readAllEvents } = require(path.join(process.env.ROOT, 'src', 'events.js'));
const root = process.env.A;
const expected = Number(process.argv[2]);
const deadline = Date.now() + 60000;
let iterations = 0;
for (;;) {
  iterations += 1;
  let evs;
  try {
    // readAllEvents JSON.parses every .jsonl it lists — a torn file throws here,
    // which is exactly the regression GH-14 fixes.
    evs = readAllEvents(root);
  } catch (err) {
    console.error(`TORN READ observed on iteration ${iterations}: ${err.message}`);
    process.exit(1);
  }
  for (const e of evs) {
    if (!e.schema_version || !e.ts || !e.type || !e.task || !e.agent) {
      console.error(`PARTIAL EVENT observed: ${JSON.stringify(e)}`);
      process.exit(1);
    }
    if (e.type === 'task.commented' && e.note !== `note-${e.task}`) {
      console.error(`CORRUPT PAYLOAD observed: ${JSON.stringify(e)}`);
      process.exit(1);
    }
  }
  const seen = evs.filter(e => e.type === 'task.commented').length;
  if (seen >= expected) {
    console.log(`reader ok: ${iterations} iterations, ${seen}/${expected} stress events, zero torn reads`);
    process.exit(0);
  }
  if (Date.now() > deadline) {
    console.error(`reader timeout: saw ${seen}/${expected} stress events`);
    process.exit(1);
  }
}
EOF
STRESS_PER_WRITER=150
ROOT="$ROOT" A="$A" node "$WORK/stress-writer.js" W1 "$STRESS_PER_WRITER" >"$WORK/writer-w1.out" 2>&1 &
W1_PID=$!
ROOT="$ROOT" A="$A" node "$WORK/stress-writer.js" W2 "$STRESS_PER_WRITER" >"$WORK/writer-w2.out" 2>&1 &
W2_PID=$!
ROOT="$ROOT" A="$A" node "$WORK/stress-reader.js" "$((STRESS_PER_WRITER * 2))" >"$WORK/reader.out" 2>&1 &
READER_PID=$!

wait "$W1_PID" || fail "stress writer W1 failed: $(cat "$WORK/writer-w1.out")"
wait "$W2_PID" || fail "stress writer W2 failed: $(cat "$WORK/writer-w2.out")"
if wait "$READER_PID"; then
  pass "concurrent readers never observed a torn file under cross-process load ($(cat "$WORK/reader.out"))"
else
  fail "concurrent reader observed a torn/partial event: $(cat "$WORK/reader.out")"
fi

if find "$A/.tick/events" -name '*.tmp' 2>/dev/null | grep -q .; then
  fail "temp-file residue left in the events directory after the stress run"
else
  pass "no .tmp residue in the events directory after the stress run"
fi
FINAL_COUNT="$(find "$A/.tick/events" -name '*.jsonl' | wc -l | tr -d ' ')"
EXPECTED_COUNT=$((3 + STRESS_PER_WRITER * 2))
[ "$FINAL_COUNT" = "$EXPECTED_COUNT" ] \
  && pass "final event count exact ($FINAL_COUNT)" \
  || fail "final event count wrong: expected $EXPECTED_COUNT, got $FINAL_COUNT"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
