#!/usr/bin/env bash
# GH-312 — `xyz-sync update` / `xyz-vendor.sh` must NOT destroy the target's live runtime state.
#
# materialize_vendor() stages a fresh mirror from $HARNESS_ROOT and then does an unconditional
#   rm -rf "$VENDOR_DIR"; mv "$STAGE_DIR" "$VENDOR_DIR"
# The stage is built purely from harness source, so anything the TARGET accumulated at runtime --
# relay-system/ threads, .tick/ event logs, .relay-driver.lock -- was deleted unread. That state is
# invisible to git by construction (ensure_gitignore puts .xyz/ in .gitignore), so there is no
# reflog/stash/fsck recovery: a destroyed relay thread is simply gone.
#
# These assertions pin the contract both ways: target-owned RUNTIME STATE survives, and harness
# CODE still updates (a fix that preserved state by skipping the update would be worse than the bug).
source "$(dirname "$0")/_setup.sh" gh312-vendor-preserves-state

ROOT="$(cd -P "$(dirname "$0")/.." && pwd)"
VENDOR="$ROOT/relay-automation/xyz-vendor.sh"
SYNC="$ROOT/relay-automation/xyz-sync.sh"

export XYZ_REGISTRY="$WORK/registry.tsv"
mkdir -p "$WORK/foreign"; git init -q "$WORK/foreign"; REPO="$(cd "$WORK/foreign" && pwd -P)"

# Seed every target-owned runtime path with recognizable content.
#
# The intake report named only relay-system/, .tick/ and .relay-driver.lock. Auditing what `.xyz/`
# actually accumulates (repo .gitignore + GH-75) turned up more state with the same exposure:
# XYZ.json is the GH-75 completion-telemetry record array, XYZ.heartbeat.json its liveness stamp,
# and XYZ.json.lock/ the mkdir-based advisory lock guarding it. None are in VENDOR_DIRS, so the
# stage never recreates them and the swap deleted them exactly like the three named paths.
seed_state() {
  mkdir -p "$REPO/.xyz/relay-system/2026-07-27" "$REPO/.xyz/.tick/events"
  printf 'PRODUCER-TURN-1\n' > "$REPO/.xyz/relay-system/2026-07-27/thread.md"
  printf '{"seq":1,"verb":"claim"}\n' > "$REPO/.xyz/.tick/events/agent-a.jsonl"
  printf 'pid=4242\n' > "$REPO/.xyz/.relay-driver.lock"
  printf '[{"harness":"relay","health":"green"}]\n' > "$REPO/.xyz/XYZ.json"
  printf '{"beat":1}\n' > "$REPO/.xyz/XYZ.heartbeat.json"
}

assert_state_survived() {
  local label="$1"
  [ "$(cat "$REPO/.xyz/relay-system/2026-07-27/thread.md" 2>/dev/null)" = "PRODUCER-TURN-1" ] \
    && pass "$label: relay-system/ thread survived with content intact" \
    || fail "$label: relay-system/ thread destroyed or corrupted"
  [ "$(cat "$REPO/.xyz/.tick/events/agent-a.jsonl" 2>/dev/null)" = '{"seq":1,"verb":"claim"}' ] \
    && pass "$label: .tick/ event log survived with content intact" \
    || fail "$label: .tick/ event log destroyed or corrupted"
  [ "$(cat "$REPO/.xyz/.relay-driver.lock" 2>/dev/null)" = "pid=4242" ] \
    && pass "$label: .relay-driver.lock survived" \
    || fail "$label: .relay-driver.lock destroyed"
  [ "$(cat "$REPO/.xyz/XYZ.json" 2>/dev/null)" = '[{"harness":"relay","health":"green"}]' ] \
    && pass "$label: XYZ.json telemetry survived with content intact" \
    || fail "$label: XYZ.json telemetry destroyed or corrupted"
  [ "$(cat "$REPO/.xyz/XYZ.heartbeat.json" 2>/dev/null)" = '{"beat":1}' ] \
    && pass "$label: XYZ.heartbeat.json survived" \
    || fail "$label: XYZ.heartbeat.json destroyed"
}

HEAD="$(git -C "$ROOT" rev-parse HEAD)"

# --- path 1: xyz-sync update (the command in the reported incident) ---
"$VENDOR" "$REPO" >/dev/null 2>&1 || fail "initial vendor exited non-zero"
seed_state
printf 'source_commit=deadbeef\ntick_version=x\nvendored_utc=x\n' > "$REPO/.xyz/VERSION"
"$SYNC" update "$REPO" >/dev/null 2>&1 || fail "xyz-sync update exited non-zero"
assert_state_survived "xyz-sync update"
grep -q "^source_commit=$HEAD$" "$REPO/.xyz/VERSION" \
  && pass "xyz-sync update still restamps VERSION to live HEAD (code really updated)" \
  || fail "xyz-sync update did not restamp VERSION — state preserved by skipping the update"
[ -x "$REPO/.xyz/bin/tick" ] && pass "xyz-sync update: harness code intact (bin/tick present)" \
  || fail "xyz-sync update: harness code missing after update"

# --- path 2: a direct xyz-vendor.sh re-run over an existing .xyz/ (same destructive swap) ---
seed_state
"$VENDOR" "$REPO" >/dev/null 2>&1 || fail "re-vendor exited non-zero"
assert_state_survived "xyz-vendor re-run"

# --- a vendor into a repo with NO prior state must still work (no preserve-list crash) ---
mkdir -p "$WORK/fresh"; git init -q "$WORK/fresh"; FRESH="$(cd "$WORK/fresh" && pwd -P)"
"$VENDOR" "$FRESH" >/dev/null 2>&1 || fail "fresh vendor (no prior state) exited non-zero"
[ -x "$FRESH/.xyz/bin/tick" ] && pass "fresh vendor unaffected by preservation logic" \
  || fail "fresh vendor broken"
[ -e "$FRESH/.xyz/relay-system" ] && fail "fresh vendor invented a relay-system/ dir" \
  || pass "fresh vendor does not fabricate empty runtime dirs"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
