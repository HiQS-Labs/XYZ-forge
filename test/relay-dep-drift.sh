#!/usr/bin/env bash
set -euo pipefail
#
# relay-dep-drift.sh — GH-68 regression: warn-only cross-agent dependency-drift signal.
# Contract: decisions/2026-07-01-cross-agent-dep-conflict.md. Proves:
#   1. `tick drift` emits a dependency.drift event with the full first-class schema.
#   2. The event is inert in the projection — it NEVER seeds a phantom task in `tick project`.
#   3. rtl_drift_brief surfaces a peer's unread drift once (watermark advances), and never the
#      agent's OWN drift.
#   4. rtl_enforce emits a drift event when a landed turn changes a shared surface (src/project.js).
#   5. Surfaces absent at both revisions emit nothing; an added surface emits prior_sha none.
# Warn-only invariant: none of this blocks or fails a turn.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS="$(cd "$HERE/.." && pwd)"
LIB="$HARNESS/relay-turn-lib.sh"; [[ -f "$LIB" ]] || LIB="$HARNESS/relay-automation/relay-turn-lib.sh"

pass=0; fail=0
ok(){ if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }

# A fixture repo whose bin/tick is co-located with .tick (production shape). bin/tick resolves its own
# ../src (the REAL harness src) regardless of a symlink, so a fixture-tracked src/project.js is
# independent of the tick binary's logic — exactly what the detection test needs.
WORK="$(mktemp -d "${TMPDIR:-/tmp}/relay-dep-drift.XXXXXX")"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/fixture-guard.sh"   # GH-10: shared fixture containment
fixture_guard_init "$WORK"   # GH-10: pin the sandbox root

mkfixture() {
  local dir; dir="$(mktemp -d "$WORK/fixture.XXXXXX")"
  require_fixture "$dir" "dep-drift case fixture"  # GH-10
  git -C "$dir" init -q
  git -C "$dir" config user.email t@example.com; git -C "$dir" config user.name test
  ln -s "$HARNESS/bin" "$dir/bin"
  ( cd "$dir" && TICK_REPO_ROOT="$dir" "$dir/bin/tick" init >/dev/null 2>&1 || true )
  printf '%s' "$dir"
}

echo "relay-dep-drift (GH-68):"

D="$(mkfixture)"; export TICK_REPO_ROOT="$D"; T="$D/bin/tick"
mkdir -p "$D/src"
printf 'module.exports = {};\n' > "$D/src/project.js"
git -C "$D" add src/project.js >/dev/null 2>&1; git -C "$D" commit -qm seed
evfile="$("$T" drift "src/project.js" --agent agent-a --task post-commit \
           --prior-sha aaa --current-sha bbb --diff-lines 12 2>/dev/null)"
ev="$D/$evfile"
ok "tick drift wrote an event file" "[[ -f '$ev' ]]"
ok "event type is dependency.drift"  "grep -q '\"type\":\"dependency.drift\"' '$ev'"
ok "event stamps surface"            "grep -q '\"surface\":\"src/project.js\"' '$ev'"
ok "event stamps prior_sha/current_sha" "grep -q '\"prior_sha\":\"aaa\"' '$ev' && grep -q '\"current_sha\":\"bbb\"' '$ev'"
ok "event stamps numeric diff_lines" "grep -q '\"diff_lines\":12' '$ev'"
# Projection must NOT show a phantom 'post-commit' task from the drift event.
proj="$("$T" project 2>/dev/null || true)"
ok "no phantom 'post-commit' task in projection" "! grep -q 'post-commit' <<<\"\$proj\""

# --- 3: rtl_drift_brief watermark + own-event filter ------------------------------------------------
# shellcheck disable=SC1090
( source "$LIB"
  b1="$(rtl_drift_brief agent-b "$D")"
  [[ "$b1" == *"src/project.js"* && "$b1" == *"agent-a"* ]] || { echo "  FAIL: peer sees unread drift"; exit 11; }
  echo "  PASS: peer (agent-b) sees the unread drift once"
  b2="$(rtl_drift_brief agent-b "$D")"
  [[ -z "$b2" ]] || { echo "  FAIL: watermark did not advance (re-injected)"; exit 12; }
  echo "  PASS: second read is empty — watermark advanced"
  bo="$(rtl_drift_brief agent-a "$D")"
  [[ -z "$bo" ]] || { echo "  FAIL: agent saw its OWN drift"; exit 13; }
  echo "  PASS: agent-a never sees its own drift"
) && pass=$((pass+3)) || fail=$((fail+1))
rm -rf "$D"

# Run the production emitter in a fixture; its git mutations remain in the fixture sandbox.
enforce_turn() (
  local dir="$1" artifact="$2"
  require_fixture "$dir" "dep-drift enforcement"
  [[ -n "$dir" && -d "$dir" ]] || return 1
  cd "$dir"
  export RELAY_FILE="relay-system/x/thread.md" RELAY_PEER="agent-b"
  # shellcheck disable=SC1090
  source "$LIB"
  rtl_init "$dir" "relay-system/x/thread.md" "$artifact"
  rtl_before
  rtl_enforce RELAY-T agent-a /dev/null testtool
)

# --- 4: end-to-end detection in rtl_enforce ---------------------------------------------------------
D2="$(mkfixture)"; export TICK_REPO_ROOT="$D2"; T2="$D2/bin/tick"
mkdir -p "$D2/src" "$D2/relay-system/x"
printf '// stub\nmodule.exports = {};\n' > "$D2/src/project.js"
printf '# thread\n\n**STATUS:** Open\n**NEXT:** agent-b\n' > "$D2/relay-system/x/thread.md"
git -C "$D2" add -A >/dev/null 2>&1; git -C "$D2" commit -qm seed
"$T2" log task.created RELAY-T --agent bootstrap >/dev/null
"$T2" claim RELAY-T --agent agent-a --paths "src/project.js,relay-system/x/thread.md" >/dev/null
prior_sha="$(git -C "$D2" rev-parse --verify HEAD:src/project.js)"
# agent-a's turn changes the shared surface src/project.js (on-lane) + touches the relay file
printf '// stub v2 — API changed\nmodule.exports = { changed: true };\n' > "$D2/src/project.js"
printf 'turn note\n' >> "$D2/relay-system/x/thread.md"
current_sha="$(git -C "$D2" hash-object src/project.js)"
enforce_turn "$D2" "src/project.js" >/dev/null 2>&1
drift_events="$(ls -1 "$D2/.tick/events/"*dependency.drift*.jsonl 2>/dev/null | wc -l | tr -d ' ')"
ok "rtl_enforce emitted exactly one drift event for the changed surface" "[[ '$drift_events' -eq 1 ]]"
ok "emitted drift names src/project.js" "grep -lq '\"surface\":\"src/project.js\"' $D2/.tick/events/*dependency.drift*.jsonl 2>/dev/null"
# Read emitted artifacts rather than merely recomputing the expected IDs.
( python3 - "$D2/.tick/events" "$prior_sha" "$current_sha" <<'PYJSON'
import json, pathlib, sys
events = [json.loads(line) for path in pathlib.Path(sys.argv[1]).glob('*dependency.drift*.jsonl')
          for line in path.read_text().splitlines() if line.strip()]
assert len(events) == 1, events
event = events[0]
assert event['surface'] == 'src/project.js', event
assert event['prior_sha'] == sys.argv[2], event
assert event['current_sha'] == sys.argv[3], event
assert len(event['prior_sha']) == len(event['current_sha']) == 40, event
PYJSON
) && pass=$((pass+1)) || fail=$((fail+1))
# warn-only: the turn still committed (drift never fails the turn)
turn_log="$(git -C "$D2" log --oneline 2>/dev/null || true)"
ok "turn still committed (warn-only, non-blocking)" "[[ \"\$turn_log\" == *RELAY-T* ]]"
rm -rf "$D2"

# --- 5: absent at both revisions — a thread-only commit must emit no drift -------------------------
D3="$(mkfixture)"; export TICK_REPO_ROOT="$D3"; T3="$D3/bin/tick"
mkdir -p "$D3/relay-system/x"
printf '# thread\n\n**STATUS:** Open\n**NEXT:** agent-b\n' > "$D3/relay-system/x/thread.md"
git -C "$D3" add -A; git -C "$D3" commit -qm seed
"$T3" log task.created RELAY-T --agent bootstrap >/dev/null
"$T3" claim RELAY-T --agent agent-a --paths "relay-system/x/thread.md" >/dev/null
printf 'thread-only turn\n' >> "$D3/relay-system/x/thread.md"
enforce_turn "$D3" "relay-system/x/thread.md" >/dev/null 2>&1
( python3 - "$D3/.tick/events" <<'PYJSON'
import pathlib, sys
event_dir = pathlib.Path(sys.argv[1])
assert event_dir.is_dir(), event_dir
assert list(event_dir.glob('*.jsonl')), 'fixture must contain real task events'
assert not list(event_dir.glob('*dependency.drift*.jsonl'))
PYJSON
) && pass=$((pass+1)) || fail=$((fail+1))
turn_log="$(git -C "$D3" log --oneline)"
ok "absent-surface case made a real turn commit" "[[ \"\$turn_log\" == *RELAY-T* ]]"

# --- 6: a newly added shared surface emits once, with none -> real blob SHA ------------------------
"$T3" claim RELAY-T --agent agent-b --paths "src/project.js,relay-system/x/thread.md" >/dev/null
# The next turn is by agent-a, so return the token before enforcing it.
"$T3" release RELAY-T --agent agent-b --to agent-a >/dev/null
"$T3" claim RELAY-T --agent agent-a --paths "src/project.js,relay-system/x/thread.md" >/dev/null
mkdir -p "$D3/src"
printf 'module.exports = { added: true };\n' > "$D3/src/project.js"
printf 'added surface\n' >> "$D3/relay-system/x/thread.md"
added_sha="$(git -C "$D3" hash-object src/project.js)"
enforce_turn "$D3" "src/project.js" >/dev/null 2>&1
( python3 - "$D3/.tick/events" "$added_sha" <<'PYJSON'
import json, pathlib, sys
events = [json.loads(line) for path in pathlib.Path(sys.argv[1]).glob('*dependency.drift*.jsonl')
          for line in path.read_text().splitlines() if line.strip()]
assert len(events) == 1, events
assert events[0]['surface'] == 'src/project.js', events
assert events[0]['prior_sha'] == 'none', events
assert events[0]['current_sha'] == sys.argv[2], events
PYJSON
) && pass=$((pass+1)) || fail=$((fail+1))
# --- 7: a deleted shared surface emits once, with real blob SHA -> none -----------------------------
git -C "$D3" add -A; git -C "$D3" commit -qm "add surface" >/dev/null 2>&1 || true
"$T3" claim RELAY-T --agent agent-a --paths "src/project.js,relay-system/x/thread.md" >/dev/null 2>&1 || true
deleted_sha="$(git -C "$D3" rev-parse HEAD:src/project.js)"
rm -f "$D3/src/project.js"
printf 'deleted surface\n' >> "$D3/relay-system/x/thread.md"
rm -rf "$D3/.tick/events"/*dependency.drift*.jsonl 2>/dev/null
enforce_turn "$D3" "src/project.js" >/dev/null 2>&1
( python3 - "$D3/.tick/events" "$deleted_sha" <<'PYJSON'
import json, pathlib, sys
events = [json.loads(line) for path in pathlib.Path(sys.argv[1]).glob('*dependency.drift*.jsonl')
          for line in path.read_text().splitlines() if line.strip()]
assert len(events) == 1, events
assert events[0]['surface'] == 'src/project.js', events
assert events[0]['prior_sha'] == sys.argv[2], events
assert events[0]['current_sha'] == 'none', events
PYJSON
) && pass=$((pass+1)) || fail=$((fail+1))
rm -rf "$D3"

echo "  relay-dep-drift: $pass pass, $fail fail"
[[ "$fail" -eq 0 ]]
