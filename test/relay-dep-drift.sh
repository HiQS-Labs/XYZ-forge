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

# --- 1 & 2: emit schema + projection safety ---------------------------------------------------------
D="$(mkfixture)"; export TICK_REPO_ROOT="$D"; T="$D/bin/tick"
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
ok "no phantom 'post-commit' task in projection" "! printf '%s' \"\$proj\" | grep -q 'post-commit'"

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

# --- 4: end-to-end detection in rtl_enforce ---------------------------------------------------------
D2="$(mkfixture)"; export TICK_REPO_ROOT="$D2"; T2="$D2/bin/tick"
mkdir -p "$D2/src" "$D2/relay-system/x"
printf '// stub\nmodule.exports = {};\n' > "$D2/src/project.js"
printf '# thread\n\n**STATUS:** Open\n**NEXT:** agent-b\n' > "$D2/relay-system/x/thread.md"
git -C "$D2" add -A >/dev/null 2>&1; git -C "$D2" commit -qm seed
"$T2" log task.created RELAY-T --agent bootstrap >/dev/null
"$T2" claim RELAY-T --agent agent-a --paths "src/project.js,relay-system/x/thread.md" >/dev/null
# agent-a's turn changes the shared surface src/project.js (on-lane) + touches the relay file
printf '// stub v2 — API changed\nmodule.exports = { changed: true };\n' > "$D2/src/project.js"
printf 'turn note\n' >> "$D2/relay-system/x/thread.md"
( cd "$D2"
  export RELAY_FILE="relay-system/x/thread.md" RELAY_PEER="agent-b"
  # shellcheck disable=SC1090
  source "$LIB"
  rtl_init "$D2" "relay-system/x/thread.md" "src/project.js"
  rtl_before
  rtl_enforce RELAY-T agent-a /dev/null testtool
) >/dev/null 2>&1
drift_events="$(ls -1 "$D2/.tick/events/"*dependency.drift*.jsonl 2>/dev/null | wc -l | tr -d ' ')"
ok "rtl_enforce emitted a drift event for the changed surface" "[[ '$drift_events' -ge 1 ]]"
ok "emitted drift names src/project.js" "grep -lq '\"surface\":\"src/project.js\"' $D2/.tick/events/*dependency.drift*.jsonl 2>/dev/null"
# warn-only: the turn still committed (drift never fails the turn)
turn_log="$(git -C "$D2" log --oneline 2>/dev/null || true)"
ok "turn still committed (warn-only, non-blocking)" "[[ \"\$turn_log\" == *RELAY-T* ]]"
rm -rf "$D2"

echo "  relay-dep-drift: $pass pass, $fail fail"
[[ "$fail" -eq 0 ]]
