#!/usr/bin/env bash
# swe-diagram test: pure-Node fixtures for layout and filter logic without a browser.
# No browser: renderer.js's DOM-touching code (window.renderDiagram = function...) is never invoked,
# only the pure functions it exports for Node via the `typeof module !== 'undefined'` guard at the
# bottom of the file (a no-op when inlined into a <script> tag — zero behavior change shipped).
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
RENDERER="$HERE/../utils/swe-diagram/assets/renderer.js"
GENERATOR="$HERE/../utils/swe-diagram/scripts/git-history-to-json.js"
PASS=0; FAIL=0
pass(){ echo "  PASS: $*"; PASS=$((PASS+1)); }
fail(){ echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
echo "== test: swe-diagram =="

[ -f "$RENDERER" ] || { echo "  FAIL: renderer.js not found at $RENDERER" >&2; exit 1; }
[ -f "$GENERATOR" ] || { echo "  FAIL: Git history generator not found at $GENERATOR" >&2; exit 1; }

WORK="$(mktemp -d -t "swe-diagram.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

cat > "$WORK/fixtures.js" <<'JSEOF'
// window must exist as an object before require() parses renderer.js's top-level
// `window.renderDiagram = function (...) {...}` assignment; the function body (the only place that
// touches `document`) never runs since these fixtures only call exported pure functions.
global.window = {};
var r = require(process.argv[2]);
var hubRingLayout = r.hubRingLayout, matchesQuery = r.matchesQuery,
    topDownLayout = r.topDownLayout, gitLaneLayout = r.gitLaneLayout,
    trustClusteredLayout = r.trustClusteredLayout, trustTierOf = r.trustTierOf;

var results = [];
function check(label, ok, detail) { results.push([label, !!ok, detail || '']); }

function dist(hubCenter, p) {
  var cx = p.x + p.w / 2, cy = p.y + p.h / 2;
  return Math.sqrt(Math.pow(cx - hubCenter.x, 2) + Math.pow(cy - hubCenter.y, 2));
}

// --- gitLaneLayout: explicit lane rows + global chronological columns ---
(function () {
  var spec = {
    lanes: [
      { id: 'main', order: 0 },
      { id: 'development', order: 1 },
      { id: 'feature/x', order: 2 }
    ],
    nodes: [
      { id: 'a', lane: 'main', order: 0 },
      { id: 'b', lane: 'feature/x', order: 1 },
      { id: 'c', lane: 'main', order: 2 }
    ]
  };
  var pos = gitLaneLayout(spec);
  check('git lanes keep commits on fixed branch rows',
    pos.a.y === pos.c.y && pos.b.y > pos.a.y,
    'positions=' + JSON.stringify(pos));
  check('git lanes advance commit order left-to-right',
    pos.a.x < pos.b.x && pos.b.x < pos.c.x,
    'xs=' + JSON.stringify({ a: pos.a.x, b: pos.b.x, c: pos.c.x }));
})();

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

// --- trustTierOf: maps a node's `trust` field to a fixed tier index,
// independent of graph structure (GH-299) ---
check('trusted-containment-core -> spine tier (0)',
  trustTierOf({ trust: 'trusted-containment-core' }) === 0);
check('trusted-dispatch -> shim tier (1)',
  trustTierOf({ trust: 'trusted-dispatch' }) === 1);
check('untrusted-executor -> periphery tier (2)',
  trustTierOf({ trust: 'untrusted-executor' }) === 2);
check('shared-state -> state tier (3)',
  trustTierOf({ trust: 'shared-state' }) === 3);
check('governance-gate -> governance tier (4)',
  trustTierOf({ trust: 'governance-gate' }) === 4);
check('a parenthetical suffix still matches its prefix (e.g. "shared-state (control-channel)")',
  trustTierOf({ trust: 'shared-state (control-channel)' }) === 3);
check('a node with no trust field falls into the last (governance) band rather than vanishing',
  trustTierOf({}) === 4);

// --- trustClusteredLayout: containment core reads as a hub, never a leaf ---
(function () {
  var spec = {
    nodes: [
      { id: 'core', trust: 'trusted-containment-core' },
      { id: 'orch', trust: 'trusted-orchestrator' },
      { id: 'shim1', trust: 'trusted-dispatch' },
      { id: 'shim2', trust: 'trusted-dispatch' },
      { id: 'cli1', trust: 'untrusted-executor' },
      { id: 'thread', trust: 'shared-state' },
      { id: 'gate', trust: 'governance-gate' }
    ],
    edges: [
      { source: 'orch', target: 'shim1' }, { source: 'orch', target: 'shim2' },
      { source: 'shim1', target: 'cli1' },
      { source: 'shim1', target: 'core' }, { source: 'shim2', target: 'core' },
      { source: 'core', target: 'thread' }
    ]
  };
  var pos = trustClusteredLayout(spec);
  check('every node gets a position (no dangling nodes)',
    Object.keys(pos).length === spec.nodes.length);
  check('containment core sits in a strictly earlier column than the shims that dispatch to it',
    pos.core.x < pos.shim1.x && pos.core.x < pos.shim2.x);
  check('shim/periphery/state/governance land in 4 distinct columns after the spine',
    pos.shim1.x < pos.cli1.x && pos.cli1.x < pos.thread.x && pos.thread.x < pos.gate.x);
  check('orchestrator and containment core share the spine column (adjacent, not eye-jumping)',
    pos.core.x === pos.orch.x);
})();

(function () {
  // 10 periphery nodes should wrap into side-by-side sub-columns rather than
  // one very tall column (canvas-efficiency acceptance criterion).
  var nodes = [{ id: 'core', trust: 'trusted-containment-core' }];
  for (var i = 0; i < 10; i++) nodes.push({ id: 'p' + i, trust: 'untrusted-executor' });
  var pos = trustClusteredLayout({ nodes: nodes, edges: [] });
  var peripheryXs = {};
  nodes.slice(1).forEach(function (n) { peripheryXs[pos[n.id].x] = true; });
  check('a 10-node tier wraps into more than one sub-column',
    Object.keys(peripheryXs).length > 1,
    'distinct x columns=' + Object.keys(peripheryXs).length);
})();

check('trustClusteredLayout: empty spec -> no positions',
  Object.keys(trustClusteredLayout({ nodes: [], edges: [] })).length === 0);

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

var commitNode = { id: 'abc123', label: 'Fix login', type: 'commit', lane: 'fix/login',
                   author: 'Ada', refs: ['origin/fix/login'] };
check('query matches Git lane', matchesQuery(commitNode, 'fix/login', {}) === true);
check('query matches Git author', matchesQuery(commitNode, 'ada', {}) === true);
check('query matches Git refs', matchesQuery(commitNode, 'origin/fix', {}) === true);

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

# --- git-history-to-json: real temporary repository with two cuts + two merges ---
GIT_REPO="$WORK/git-repo"
mkdir -p "$GIT_REPO"
git -C "$GIT_REPO" init -q -b main
git -C "$GIT_REPO" config user.name "Diagram Test"
git -C "$GIT_REPO" config user.email "diagram@example.test"
printf 'base\n' > "$GIT_REPO/history.txt"
git -C "$GIT_REPO" add history.txt
git -C "$GIT_REPO" commit -q -m "base"
git -C "$GIT_REPO" switch -q -c development
printf 'development\n' >> "$GIT_REPO/history.txt"
git -C "$GIT_REPO" commit -qam "development commit"
git -C "$GIT_REPO" switch -q -c feature/x
printf 'feature one\n' >> "$GIT_REPO/history.txt"
git -C "$GIT_REPO" commit -qam "feature one"
printf 'feature two\n' >> "$GIT_REPO/history.txt"
git -C "$GIT_REPO" commit -qam "feature two"
git -C "$GIT_REPO" switch -q development
git -C "$GIT_REPO" merge -q --no-ff feature/x -m "merge feature"
git -C "$GIT_REPO" switch -q main
git -C "$GIT_REPO" merge -q --no-ff development -m "merge development"

GIT_JSON="$WORK/git-history.json"
if node "$GENERATOR" --repo "$GIT_REPO" --limit 6 --output "$GIT_JSON" >/dev/null; then
  pass "Git history generator runs on a branched+merged repository"
else
  fail "Git history generator runs on a branched+merged repository"
fi
if node -e 'var s=require(process.argv[1]); process.exit(s.layout === "git-lanes" && s.nodes.length === 6 ? 0 : 1)' "$GIT_JSON"; then
  pass "Git history generator honors the total commit limit"
else
  fail "Git history generator honors the total commit limit"
fi
if node -e 'var s=require(process.argv[1]), x=Object.fromEntries(s.lanes.map(function(l){return [l.id,l.order]})); process.exit(x.main===0 && x.development===1 && x["feature/x"]===2 ? 0 : 1)' "$GIT_JSON"; then
  pass "Git history lanes order main, development, then feature branch"
else
  fail "Git history lanes order main, development, then feature branch"
fi
if node -e 'var s=require(process.argv[1]), k=s.edges.map(function(e){return e.kind}); process.exit(k.includes("branch") && k.includes("merge") ? 0 : 1)' "$GIT_JSON"; then
  pass "Git history generator distinguishes branch cuts and merges"
else
  fail "Git history generator distinguishes branch cuts and merges"
fi
if node -e 'var s=require(process.argv[1]), ids=new Set(s.nodes.map(function(n){return n.id})); process.exit(s.edges.every(function(e){return ids.has(e.source)&&ids.has(e.target)}) ? 0 : 1)' "$GIT_JSON"; then
  pass "Git history generator emits no dangling edge endpoints"
else
  fail "Git history generator emits no dangling edge endpoints"
fi

echo "  swe-diagram: $PASS pass, $FAIL fail"
[ "$FAIL" = 0 ]
