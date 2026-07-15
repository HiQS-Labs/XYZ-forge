#!/usr/bin/env bash
# swe-diagram test: pure-Node fixtures for layout and filter logic without a browser.
# No browser: renderer.js's DOM-touching code (window.renderDiagram = function...) is never invoked,
# only the two pure functions it exports for Node via the `typeof module !== 'undefined'` guard at the
# bottom of the file (a no-op when inlined into a <script> tag — zero behavior change shipped).
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
RENDERER="$HERE/../utils/swe-diagram/assets/renderer.js"
PASS=0; FAIL=0
pass(){ echo "  PASS: $*"; PASS=$((PASS+1)); }
fail(){ echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
echo "== test: swe-diagram =="

[ -f "$RENDERER" ] || { echo "  FAIL: renderer.js not found at $RENDERER" >&2; exit 1; }

WORK="$(mktemp -d -t "swe-diagram.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

cat > "$WORK/fixtures.js" <<'JSEOF'
// window must exist as an object before require() parses renderer.js's top-level
// `window.renderDiagram = function (...) {...}` assignment; the function body (the only place that
// touches `document`) never runs since these fixtures only call exported pure functions.
global.window = {};
var r = require(process.argv[2]);
var hubRingLayout = r.hubRingLayout, matchesQuery = r.matchesQuery, topDownLayout = r.topDownLayout;

var results = [];
function check(label, ok, detail) { results.push([label, !!ok, detail || '']); }

function dist(hubCenter, p) {
  var cx = p.x + p.w / 2, cy = p.y + p.h / 2;
  return Math.sqrt(Math.pow(cx - hubCenter.x, 2) + Math.pow(cy - hubCenter.y, 2));
}

// --- topDownLayout: ranks flow downward and peers spread horizontally ---
(function () {
  var spec = {
    nodes: [{ id: 'ui' }, { id: 'api' }, { id: 'db' }, { id: 'queue', tech: 'NATS' }],
    edges: [
      { source: 'ui', target: 'api' },
      { source: 'api', target: 'db' },
      { source: 'api', target: 'queue' }
    ]
  };
  var pos = topDownLayout(spec);
  check('top-down ranks follow source -> target direction',
    pos.ui.y < pos.api.y && pos.api.y < pos.db.y && pos.api.y < pos.queue.y,
    'ys=' + JSON.stringify({ ui: pos.ui.y, api: pos.api.y, db: pos.db.y, queue: pos.queue.y }));
  check('top-down peers share a row and do not overlap horizontally',
    pos.db.y === pos.queue.y && Math.abs(pos.db.x - pos.queue.x) >= pos.db.w,
    'db=' + JSON.stringify(pos.db) + ', queue=' + JSON.stringify(pos.queue));
})();

// --- hubRingLayout: base cases ---
check('empty spec -> no positions', Object.keys(hubRingLayout({ nodes: [], edges: [] })).length === 0);

(function () {
  var pos = hubRingLayout({ nodes: [{ id: 'solo' }], edges: [] });
  check('single node -> exactly one position', Object.keys(pos).length === 1 && !!pos.solo);
})();

// --- hubRingLayout: explicit spec.hub wins over degree auto-pick ---
(function () {
  var spec = {
    hub: 'b',
    nodes: [{ id: 'a' }, { id: 'b' }, { id: 'c' }],
    edges: [{ source: 'a', target: 'c' }, { source: 'a', target: 'c' }] // a/c have higher degree than b
  };
  var pos = hubRingLayout(spec);
  var hubCenter = { x: pos.b.x + pos.b.w / 2, y: pos.b.y + pos.b.h / 2 };
  check('explicit spec.hub is honored even when another node has higher degree',
    Math.abs(hubCenter.x) < 1e-6 && Math.abs(hubCenter.y) < 1e-6,
    'hub center=' + JSON.stringify(hubCenter));
})();

// --- hubRingLayout: auto-pick by highest edge degree ---
(function () {
  var spec = {
    nodes: [{ id: 'a' }, { id: 'b' }, { id: 'c' }, { id: 'd' }],
    edges: [
      { source: 'b', target: 'a' }, { source: 'b', target: 'c' }, { source: 'b', target: 'd' }
    ] // b: degree 3, everyone else: degree 1
  };
  var pos = hubRingLayout(spec);
  var hubCenter = { x: pos.b.x + pos.b.w / 2, y: pos.b.y + pos.b.h / 2 };
  check('highest-degree node auto-picked as hub (no spec.hub given)',
    Math.abs(hubCenter.x) < 1e-6 && Math.abs(hubCenter.y) < 1e-6,
    'hub center=' + JSON.stringify(hubCenter));
})();

// --- hubRingLayout: THE regression this session caught — 10 ring nodes must split 5/5,
// not a naive greedy 8-then-2-stray-spokes fill (GH-146 fix commit) ---
(function () {
  var nodes = [{ id: 'hub' }];
  for (var i = 0; i < 10; i++) nodes.push({ id: 'n' + i });
  var edges = nodes.slice(1).map(function (n) { return { source: 'hub', target: n.id }; });
  var pos = hubRingLayout({ hub: 'hub', nodes: nodes, edges: edges });
  var hubCenter = { x: pos.hub.x + pos.hub.w / 2, y: pos.hub.y + pos.hub.h / 2 };
  var radii = nodes.slice(1).map(function (n) { return Math.round(dist(hubCenter, pos[n.id])); });
  var byRadius = {};
  radii.forEach(function (r) { byRadius[r] = (byRadius[r] || 0) + 1; });
  var counts = Object.keys(byRadius).map(function (k) { return byRadius[k]; }).sort(function (a, b) { return a - b; });
  check('10 ring nodes split into two EVEN rings of 5 (not a lopsided 8/2)',
    counts.length === 2 && counts[0] === 5 && counts[1] === 5,
    'ring sizes=' + JSON.stringify(counts));
})();

(function () {
  // 17 ring nodes: numRings = ceil(17/8) = 3, chunkSize = ceil(17/3) = 6 -> 6/6/5
  var nodes = [{ id: 'hub' }];
  for (var i = 0; i < 17; i++) nodes.push({ id: 'n' + i });
  var pos = hubRingLayout({ hub: 'hub', nodes: nodes, edges: [] });
  var hubCenter = { x: pos.hub.x + pos.hub.w / 2, y: pos.hub.y + pos.hub.h / 2 };
  var radii = nodes.slice(1).map(function (n) { return Math.round(dist(hubCenter, pos[n.id])); });
  var byRadius = {};
  radii.forEach(function (r) { byRadius[r] = (byRadius[r] || 0) + 1; });
  var counts = Object.keys(byRadius).map(function (k) { return byRadius[k]; }).sort(function (a, b) { return a - b; });
  check('17 ring nodes split into three near-even rings (6/6/5)',
    counts.length === 3 && counts[0] === 5 && counts[1] === 6 && counts[2] === 6,
    'ring sizes=' + JSON.stringify(counts));
})();

// --- matchesQuery: base cases ---
var authNode = { id: 'auth-svc', label: 'Auth Service', type: 'service', tech: 'FastAPI',
                 description: 'Handles login and session tokens' };

check('empty query, no exclusions -> matches', matchesQuery(authNode, '', {}) === true);
check('query matches label (case-folded at call time, substring)', matchesQuery(authNode, 'auth service', {}) === true);
check('query matches id', matchesQuery(authNode, 'auth-svc', {}) === true);
check('query matches description', matchesQuery(authNode, 'session tokens', {}) === true);
check('query matches tech', matchesQuery(authNode, 'fastapi', {}) === true);
check('query matches nothing -> no match', matchesQuery(authNode, 'nonexistent-xyz', {}) === false);
check('uppercase query does not match (caller is responsible for lowercasing, matching real call site)',
  matchesQuery(authNode, 'AUTH', {}) === false);

// --- matchesQuery: type exclusion is independent of (and dominates) text match ---
check('excluded type -> no match even with empty query', matchesQuery(authNode, '', { service: true }) === false);
check('excluded type -> no match even when text WOULD have matched',
  matchesQuery(authNode, 'auth', { service: true }) === false);
check('non-excluded type + matching query -> still matches',
  matchesQuery(authNode, 'auth', { database: true }) === true);

var typelessNode = { id: 'mystery', label: 'Mystery Node' };
check('node with no type falls into the "default" bucket for exclusion',
  matchesQuery(typelessNode, '', { default: true }) === false);

results.forEach(function (r) {
  console.log('RESULT\t' + r[0] + '\t' + (r[1] ? 'ok' : 'fail') + '\t' + r[2]);
});
var anyFail = results.some(function (r) { return !r[1]; });
process.exit(anyFail ? 1 : 0);
JSEOF

node "$WORK/fixtures.js" "$RENDERER" > "$WORK/out.tsv" 2> "$WORK/err"
node_rc=$?

if [ ! -s "$WORK/out.tsv" ]; then
  fail "fixtures.js produced no output (node exit $node_rc): $(cat "$WORK/err")"
else
  while IFS=$'\t' read -r tag label status detail; do
    [ "$tag" = "RESULT" ] || continue
    if [ "$status" = "ok" ]; then
      pass "$label"
    else
      fail "$label ($detail)"
    fi
  done < "$WORK/out.tsv"
fi

echo "  swe-diagram: $PASS pass, $FAIL fail"
[ "$FAIL" = 0 ]
