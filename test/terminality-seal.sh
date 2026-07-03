#!/usr/bin/env bash
# GH-41 terminality-seal — foldWithMeta must SEAL an authorized terminal so a completed token
# can never be silently resurrected or corrupted. These scenarios were surfaced by the cross-model
# review of PR #99 (Codex) on top of the canary-token-reuse fixture: the canary covers only the
# higher-epoch-LATER-ts reclaim; this pins the edge cases the first implementation got wrong —
# a post-terminal RELEASE (done->open corruption), the ts==terminal.ts BOUNDARY (same-ts higher-epoch
# reclaim), post-terminal scope_changed, and a post-terminal reclaimer's own done — while proving the
# legitimate reclaim-BEFORE-terminal and owner-can-finish cases still fold clean.
source "$(dirname "$0")/_setup.sh" terminality-seal

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export PJ="$ROOT/src/project"

# check <name> <expected "status|comma,reasons"> <events-json>
check() {
  local name="$1" want="$2" evs="$3" got
  got="$(node -e '
    const {foldWithMeta}=require(process.env.PJ);
    const r=foldWithMeta(JSON.parse(process.argv[1]));
    const t=r.tasks.get("T");
    process.stdout.write((t?t.status:"none")+"|"+r.rejections.map(x=>x.reason).join(","));
  ' "$evs")"
  [ "$got" = "$want" ] && pass "$name -> $got" || fail "$name: expected '$want' got '$got'"
}

C='{"type":"task.claimed","task":"T","agent":"%s","epoch":%d,"ts":"2026-01-01T00:00:0%d.000Z"}'
D='{"type":"task.done","task":"T","agent":"%s","epoch":%d,"ts":"2026-01-01T00:00:0%d.000Z"}'
B='{"type":"task.circuit_break","task":"T","agent":"%s","epoch":%d,"ts":"2026-01-01T00:00:0%d.000Z","reason":"x"}'
R='{"type":"task.released","task":"T","agent":"%s","epoch":%d,"ts":"2026-01-01T00:00:0%d.000Z"}'
Rto='{"type":"task.released","task":"T","agent":"%s","epoch":%d,"ts":"2026-01-01T00:00:0%d.000Z","to_agent":"%s"}'
S='{"type":"task.scope_changed","task":"T","agent":"%s","epoch":%d,"ts":"2026-01-01T00:00:0%d.000Z","paths":["x"]}'
c(){ printf "$C" "$1" "$2" "$3"; }; d(){ printf "$D" "$1" "$2" "$3"; }; b(){ printf "$B" "$1" "$2" "$3"; }
r(){ printf "$R" "$1" "$2" "$3"; }; rto(){ printf "$Rto" "$1" "$2" "$3" "$4"; }; s(){ printf "$S" "$1" "$2" "$3"; }
arr(){ local IFS=,; echo "[$*]"; }

# --- the seal must FIRE (status stays terminal, exactly one claim-after-terminal) ---
check "post-terminal higher-epoch reclaim" "done|claim-after-terminal"        "$(arr "$(c A 1 1)" "$(d A 1 2)" "$(c B 2 3)")"
check "post-terminal RELEASE (no done->open)" "done|claim-after-terminal"     "$(arr "$(c A 1 1)" "$(d A 1 2)" "$(r A 1 3)")"
check "ts==terminal boundary (same-ts reclaim)" "done|claim-after-terminal"   "$(arr "$(c A 1 1)" "$(d A 1 2)" "$(c B 2 2)")"
check "post-terminal scope_changed" "done|claim-after-terminal"               "$(arr "$(c A 1 1)" "$(d A 1 2)" "$(s B 2 3)")"
check "post-terminal reclaimer's own done" "done|claim-after-terminal"        "$(arr "$(c A 1 1)" "$(d A 1 2)" "$(c B 2 3)" "$(d B 2 4)")"
check "circuit_break is terminal too" "circuit_broken|claim-after-terminal"   "$(arr "$(c A 1 1)" "$(b A 1 2)" "$(c B 2 3)")"

# --- the seal must NOT fire (legitimate lifecycles fold clean, zero rejections) ---
check "clean single terminal" "done|"                                         "$(arr "$(c A 1 1)" "$(d A 1 2)")"
check "owner claim+done at same ts" "done|"                                   "$(arr "$(c A 1 2)" "$(d A 1 2)")"
check "legit reclaim BEFORE terminal (handoff)" "done|"                       "$(arr "$(c A 1 1)" "$(rto A 1 2 B)" "$(c B 2 3)" "$(d B 2 4)")"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
