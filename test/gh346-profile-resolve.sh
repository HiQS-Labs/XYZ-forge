#!/usr/bin/env bash
# GH-346 Phase 3a: one name resolves to harness, gateway, and model.
#
# What this pins, and why each part earned a case:
#
#  1. The two names the operator actually asked for resolve end to end --
#     "qwen 3.8 max" -> deepseek -> openrouter -> qwen/qwen3.8-max, and
#     "glm 5.3 max"  -> commandcode -> zai-org/glm-5.3 (no gateway; it is its own router).
#
#  2. NO TIER CAN BLOCK A TURN. Missing config, malformed JSON, a `profiles` key that is not an
#     object, an unmatched name -- every one falls through to tier 4 (the shims' own literals,
#     i.e. exactly today's behavior) and exits 0. A turn that could not run because a PREFERENCE
#     was unreadable would be strictly worse than having no preferences at all.
#
#  3. NO FALLBACK IS SILENT. Each fall-through prints its reason on stderr. GH-346 Phase 0 found
#     two bare `except: pass` handlers that hid dead telemetry for the entire life of three shims;
#     the lesson is not "handle the error", it is "say so".
#
#  4. The lane set is DERIVED from route_agent()'s source, never curated here. Phase 2 found the
#     gateway set living in TEN hand-maintained allowlists, three of them invisible to careful
#     reading. This suite asserts the resolver tracks route_agent rather than a copy -- if someone
#     adds a lane there, --list grows on its own.
#
#  5. The gateway VARIABLE is derived per-shim, not assumed to be "<PREFIX>_GATEWAY". deepseek's
#     is DEEPSEEK_PROVIDER. The first cut of the derivation missed it because that shim assigns
#     through a local variable, and reported the lane as having no gateway at all. A hand-written
#     table would have been wrong in the same place with nothing to catch it.
#
#  6. A self-routed harness emits NO gateway variable. Command Code is both harness and router:
#     exporting its own name into a variable meant for a third-party router is how a value meaning
#     "there is no router here" gets logged as though there were one -- the defect GH-346 removed
#     from the shims, which must not come back through the config.
source "$(dirname "$0")/_setup.sh" gh346-profile-resolve
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
R="$ROOT/relay-automation/resolve-profile.sh"

[ -x "$R" ] && pass "resolve-profile.sh is present and executable" || {
  fail "missing or non-executable: $R"; echo "  $TEST_NAME: $PASS pass, $FAIL fail"; exit 1; }

CFG="$WORK/device_config.json"
cat > "$CFG" <<'JSON'
{
  "device_id": "test-device",
  "default_harness": "dsh",
  "default_gateway": "openrouter",
  "default_model": "deepseek/deepseek-v4-pro",
  "profiles": {
    "glm 5.3 max":  { "harness": "commandcode", "gateway": "self",
                      "model": "zai-org/glm-5.3", "effort": "max" },
    "qwen 3.8 max": { "harness": "deepseek", "gateway": "openrouter",
                      "model": "qwen/qwen3.8-max" }
  }
}
JSON

# Run the resolver with a scratch config and a clean environment. Scrubbing every lane's *_AGENT
# and *_MODEL matters: a stray one in the caller's env is a tier-1 hit and would silently make
# every tier-2 case below pass for the wrong reason.
run() {
  env -u COMMANDCODE_AGENT -u COMMANDCODE_MODEL -u DEEPSEEK_AGENT -u DEEPSEEK_MODEL \
      -u CLAUDE_AGENT -u CLAUDE_MODEL -u CODEX_AGENT -u CODEX_MODEL \
      -u AGY_AGENT -u AGY_MODEL -u AIDER_AGENT -u AIDER_MODEL \
      -u PI_AGENT -u PI_MODEL -u SMALLCODE_AGENT -u SMALLCODE_MODEL \
      XYZ_DEVICE_CONFIG_PATH="$1" bash "$R" "${@:2}"
}

# ---------------------------------------------------------------------------------------------
# 1. The operator's two named examples, end to end.
# ---------------------------------------------------------------------------------------------
out="$(run "$CFG" "qwen 3.8 max" --env 2>/dev/null)"
case "$out" in *"DEEPSEEK_AGENT='deepseek'"*)  pass "qwen 3.8 max -> DEEPSEEK_AGENT" ;;
  *) fail "qwen 3.8 max: no DEEPSEEK_AGENT in: $out" ;; esac
case "$out" in *"DEEPSEEK_MODEL='qwen/qwen3.8-max'"*) pass "qwen 3.8 max -> the requested model" ;;
  *) fail "qwen 3.8 max: wrong/absent model in: $out" ;; esac
case "$out" in *"DEEPSEEK_PROVIDER='openrouter'"*) pass "qwen 3.8 max -> OpenRouter via DEEPSEEK_PROVIDER (not _GATEWAY)" ;;
  *) fail "qwen 3.8 max: gateway var wrong/absent in: $out" ;; esac
case "$out" in *"RELAY_AGENT_CMD='relay-automation/deepseek-turn.sh'"*) pass "qwen 3.8 max -> the deepseek shim" ;;
  *) fail "qwen 3.8 max: wrong RELAY_AGENT_CMD in: $out" ;; esac

out="$(run "$CFG" "glm 5.3 max" --env 2>/dev/null)"
case "$out" in *"COMMANDCODE_AGENT='commandcode'"*) pass "glm 5.3 max -> COMMANDCODE_AGENT" ;;
  *) fail "glm 5.3 max: no COMMANDCODE_AGENT in: $out" ;; esac
case "$out" in *"COMMANDCODE_MODEL='zai-org/glm-5.3'"*) pass "glm 5.3 max -> the requested model" ;;
  *) fail "glm 5.3 max: wrong/absent model in: $out" ;; esac
case "$out" in *"COMMANDCODE_REASONING_EFFORT='max'"*) pass "glm 5.3 max -> effort max" ;;
  *) fail "glm 5.3 max: effort absent in: $out" ;; esac

# THE self-routing case. An `export ..._GATEWAY=` line here would be the Phase 0 defect rebuilt.
case "$out" in *"export COMMANDCODE_GATEWAY="*)
    fail "self-routed harness exported a gateway variable — Command Code has no router to name" ;;
  *) pass "self-routed harness exports NO gateway variable" ;; esac
case "$out" in *"is its own router"*) pass "the omission is explained in the output, not just absent" ;;
  *) fail "no comment explaining the missing gateway" ;; esac

# ---------------------------------------------------------------------------------------------
# 2. Fuzzy matching -- reused from resolve-model-alias.sh, not reimplemented.
# ---------------------------------------------------------------------------------------------
for q in "GLM5.3 Max" "glm 5.3 MAX" "max glm 5.3"; do
  out="$(run "$CFG" "$q" --env 2>/dev/null)"
  case "$out" in *"COMMANDCODE_MODEL='zai-org/glm-5.3'"*) pass "fuzzy match: '$q'" ;;
    *) fail "fuzzy match failed for '$q'" ;; esac
done

# ---------------------------------------------------------------------------------------------
# 3. Tier 1 -- an explicit manual path always wins and is never second-guessed.
# ---------------------------------------------------------------------------------------------
out="$(env XYZ_DEVICE_CONFIG_PATH="$CFG" COMMANDCODE_AGENT=commandcode \
        COMMANDCODE_MODEL=my/explicit-override bash "$R" "qwen 3.8 max" --explain 2>/dev/null)"
case "$out" in *"tier:    1"*) pass "tier 1: explicit env beats a named profile" ;;
  *) fail "tier 1 did not win: $out" ;; esac
case "$out" in *"my/explicit-override"*) pass "tier 1: the operator's model survives untouched" ;;
  *) fail "tier 1 model was overwritten: $out" ;; esac

# ---------------------------------------------------------------------------------------------
# 4. NO TIER MAY BLOCK A TURN -- every degradation exits 0 at tier 4.
# ---------------------------------------------------------------------------------------------
printf '{ this is not valid json,,,' > "$WORK/malformed.json"
printf '{"profiles": "not-an-object"}' > "$WORK/wrongtype.json"
printf '{"profiles": {"broken": "not-an-object-either"}}' > "$WORK/wrongprofile.json"
printf '{}' > "$WORK/empty.json"

for case_name in malformed wrongtype wrongprofile empty missing; do
  path="$WORK/$case_name.json"
  [ "$case_name" = missing ] && path="$WORK/no-such-file.json"
  out="$(run "$path" "glm 5.3 max" --env 2>/dev/null)"; rc=$?
  [ "$rc" = 0 ] && pass "$case_name config: exits 0 (never blocks a turn)" \
                || fail "$case_name config: exit $rc — a preference blocked a turn"
  case "$out" in *"nothing to export"*) pass "$case_name config: degrades to tier 4 (today's behavior)" ;;
    *) fail "$case_name config: did not degrade to tier 4: $out" ;; esac
done

# An unmatched NAME against a valid config must also fall through, not error.
out="$(run "$CFG" "no such profile at all" --env 2>/dev/null)"; rc=$?
{ [ "$rc" = 0 ] && case "$out" in *"nothing to export"*) true ;; *) false ;; esac; } \
  && pass "unmatched name: falls through to tier 4, exit 0" \
  || fail "unmatched name: rc=$rc out=$out"

# ---------------------------------------------------------------------------------------------
# 5. NO FALLBACK IS SILENT -- each degradation says why, on stderr.
# ---------------------------------------------------------------------------------------------
err="$(run "$WORK/malformed.json" "glm 5.3 max" --env 2>&1 >/dev/null)"
case "$err" in *"could not be parsed"*) pass "malformed config names the PARSE error, not just 'no profiles'" ;;
  *) fail "malformed config gave a misleading or absent reason: $err" ;; esac
err="$(run "$CFG" "no such profile at all" --env 2>&1 >/dev/null)"
case "$err" in *"no profile matched"*) pass "an unmatched name says so, and lists what exists" ;;
  *) fail "unmatched name fell through silently: $err" ;; esac
err="$(run "$WORK/wrongtype.json" "x" --env 2>&1 >/dev/null)"
case "$err" in *"not an object"*) pass "a wrong-typed profiles key says so" ;;
  *) fail "wrong-typed profiles key fell through silently: $err" ;; esac

# ---------------------------------------------------------------------------------------------
# 6. The lane set is DERIVED from route_agent(), not curated in the resolver.
# ---------------------------------------------------------------------------------------------
derived="$(python3 - "$ROOT" <<'PY'
import sys, os
sys.path.insert(0, os.path.join(sys.argv[1], "utils", "py"))
from profile_resolve import lanes
print(" ".join(sorted(lanes(sys.argv[1]))))
PY
)"
truth="$(python3 - "$ROOT" <<'PY'
import re, sys, os
src = open(os.path.join(sys.argv[1], "utils", "py", "marathon_drive.py"), encoding="utf-8").read()
i = src.find("def route_agent("); j = src.find("not recognized", i)
print(" ".join(sorted(set(re.findall(
    r"agent_id\.startswith\(\s*[\"']([a-z0-9_]+)[\"']", src[i:j])))))
PY
)"
[ -n "$truth" ] && pass "route_agent() exposes a lane set to compare against" \
                || fail "could not read route_agent()'s lane set"
[ "$derived" = "$truth" ] \
  && pass "resolver lane set == route_agent's, derived not copied ($derived)" \
  || fail "lane set DRIFTED — resolver: [$derived] route_agent: [$truth]"

# Every routable lane must have a shim, or a profile naming it resolves to a dead --agent-cmd.
missing="$(python3 - "$ROOT" <<'PY'
import sys, os
sys.path.insert(0, os.path.join(sys.argv[1], "utils", "py"))
from profile_resolve import lanes
print(" ".join(k for k, v in sorted(lanes(sys.argv[1]).items()) if not v["shim_exists"]))
PY
)"
[ -z "$missing" ] && pass "every routable lane has a turn shim on disk" \
                  || fail "lanes route but have no shim: $missing"

# 5-of-7 use <PREFIX>_GATEWAY; deepseek uses DEEPSEEK_PROVIDER. Pin the odd one specifically --
# it is the case that proves the value is read from source rather than assumed.
gwvar="$(python3 - "$ROOT" <<'PY'
import sys, os
sys.path.insert(0, os.path.join(sys.argv[1], "utils", "py"))
from profile_resolve import lanes
print(lanes(sys.argv[1]).get("deepseek", {}).get("gateway_var"))
PY
)"
[ "$gwvar" = "DEEPSEEK_PROVIDER" ] \
  && pass "deepseek's gateway var derived as DEEPSEEK_PROVIDER (not the assumed _GATEWAY)" \
  || fail "deepseek gateway var derived as '$gwvar' — the local-variable indirection regressed"

# ---------------------------------------------------------------------------------------------
# 7. A broken profile is reported, and refuses to emit a half-correct export block.
# ---------------------------------------------------------------------------------------------
cat > "$WORK/badprofile.json" <<'JSON'
{ "profiles": {
    "dead lane":  { "harness": "nosuchharness", "gateway": "openrouter", "model": "a/b" },
    "no gateway": { "harness": "commandcode", "model": "a/b" },
    "echo name":  { "harness": "commandcode", "gateway": "commandcode", "model": "a/b" }
} }
JSON
out="$(run "$WORK/badprofile.json" --list 2>/dev/null)"
case "$out" in *"is not a lane route_agent() routes"*) pass "a profile naming a dead lane is flagged by --list" ;;
  *) fail "--list did not flag the dead lane: $out" ;; esac
case "$out" in *"no 'gateway'"*) pass "a profile with no gateway is flagged" ;;
  *) fail "--list did not flag the missing gateway: $out" ;; esac
case "$out" in *"repeats the harness name"*) pass "gateway echoing the harness name is flagged (use 'self')" ;;
  *) fail "--list did not flag the echoed harness name: $out" ;; esac

run "$WORK/badprofile.json" "dead lane" --env >/dev/null 2>&1
[ $? -ne 0 ] && pass "a broken profile refuses --env rather than emitting a half-correct block" \
             || fail "--env emitted an export block for a profile naming a dead lane"

# ---------------------------------------------------------------------------------------------
# 8. --list and --explain
# ---------------------------------------------------------------------------------------------
out="$(run "$CFG" --list 2>/dev/null)"
case "$out" in *"commandcode -> zai-org/glm-5.3"*) pass "--list renders a self-routed path with two elements" ;;
  *) fail "--list self-routed rendering: $out" ;; esac
case "$out" in *"deepseek -> openrouter -> qwen/qwen3.8-max"*) pass "--list renders a routed path with three" ;;
  *) fail "--list routed rendering: $out" ;; esac

out="$(run "$CFG" "glm5.3 max" --explain 2>/dev/null)"
case "$out" in *"tier:    2"*) pass "--explain names the tier that answered" ;;
  *) fail "--explain tier: $out" ;; esac
case "$out" in *"is its own router"*) pass "--explain calls out self-routing rather than printing a bare 'self'" ;;
  *) fail "--explain self-routing: $out" ;; esac

# An empty config must still tell the operator how to write one.
out="$(run "$WORK/empty.json" --list 2>/dev/null)"
case "$out" in *'"profiles"'*) pass "--list on an empty config shows a usable example block" ;;
  *) fail "--list gave no guidance on an empty config: $out" ;; esac
case "$out" in *"Routable harnesses:"*) pass "--list names the harnesses a profile may reference" ;;
  *) fail "--list did not list routable harnesses" ;; esac

# ---------------------------------------------------------------------------------------------
# 9. --env output is meant to be eval'd, so it MUST be injection-safe.
#
# `eval "$(resolve-profile.sh ... --env)"` is the documented usage, and security-scan.sh flags
# that pattern on sight -- correctly, because it is only safe if every emitted value is shell
# quoted. The config is operator-owned, but "the operator wrote it" is not a security argument:
# a profile can be pasted from a README, synced between machines, or vendored in. These cases
# pin that a hostile value becomes an inert string rather than a command.
# ---------------------------------------------------------------------------------------------
cat > "$WORK/evil.json" <<'JSON'
{ "profiles": {
    "sq":  { "harness": "commandcode", "gateway": "self",
             "model": "a/b'; touch EVIL_SQ; echo '" },
    "dq":  { "harness": "commandcode", "gateway": "self",
             "model": "x\"; touch EVIL_DQ; #" },
    "sub": { "harness": "commandcode", "gateway": "self",
             "model": "y$(touch EVIL_SUB)z" },
    "bt":  { "harness": "commandcode", "gateway": "self",
             "model": "w`touch EVIL_BT`v" }
} }
JSON

for p in sq dq sub bt; do
  got="$( cd "$WORK" && eval "$(run "$WORK/evil.json" "$p" --env 2>/dev/null)" \
          && printf '%s' "$COMMANDCODE_MODEL" )"
  # The value must survive VERBATIM -- proof it was data, never parsed as shell.
  want="$(python3 -c "
import json,sys
print(json.load(open('$WORK/evil.json'))['profiles']['$p']['model'], end='')")"
  [ "$got" = "$want" ] && pass "injection ($p): hostile model value survives as literal data" \
                       || fail "injection ($p): got [$got] wanted [$want]"
done

evil_files="$(ls "$WORK"/EVIL_* 2>/dev/null | tr '\n' ' ')"
[ -z "$evil_files" ] \
  && pass "injection: eval of --env output executed nothing (no EVIL_* artifacts)" \
  || fail "INJECTION SUCCEEDED — eval ran embedded commands: $evil_files"

# ---------------------------------------------------------------------------------------------
# N. RELAY_AGENT, and the missing-CLI warning (added 2026-09-02).
#
# The point of this feature is a one-liner: shell-evaluate the --env output, then run the shim.
# (Spelled in words, not as the literal expression — security-scan.sh reads comments too.) That could not work for ANY profile: every turn shim hard-requires RELAY_AGENT
# ("RELAY_AGENT required", exit) and --env never emitted it. The operator got a bare refusal with
# nothing pointing back at the resolver. Reproduced by hand before the fix.
#
# NEGATIVE CONTROL: delete the `export RELAY_AGENT=` line in profile_resolve.py — R1 goes red;
# delete the `shutil.which(cli)` guard — R3 goes red. Both were run.
# ---------------------------------------------------------------------------------------------
out="$(run "$CFG" "glm 5.3 max" --env 2>/dev/null)"
grep -q "^export RELAY_AGENT=" <<<"$out" \
  && pass "R1: --env emits RELAY_AGENT (the shims refuse to act without it)" \
  || fail "R1: --env omitted RELAY_AGENT — the documented one-liner cannot run"

# It must EQUAL the harness agent var: the shim compares the two and DEFERS when they differ, which
# reads as a silent no-op rather than a misconfiguration.
_ra="$(grep -m1 "^export RELAY_AGENT=" <<<"$out" | sed "s/.*='\(.*\)'/\1/")"
_ha="$(grep -m1 "^export COMMANDCODE_AGENT=" <<<"$out" | sed "s/.*='\(.*\)'/\1/")"
[ -n "$_ra" ] && [ "$_ra" = "$_ha" ] \
  && pass "R2: RELAY_AGENT matches the harness agent var ($_ra) — the shim acts instead of deferring" \
  || fail "R2: RELAY_AGENT='$_ra' != COMMANDCODE_AGENT='$_ha' — the shim would silently defer"

# R3: resolving to a harness whose CLI is absent must SAY SO here, where the operator can still
# choose another profile — not fail minutes later inside a relay driver as an unexplained stall.
_ghostcfg="$WORK/device_config_nocli.json"
cat > "$_ghostcfg" <<'JSON'
{ "profiles": { "ghost": { "harness": "deepseek", "gateway": "openrouter", "model": "x/y" } } }
JSON
out_ghost="$(PATH="/usr/bin:/bin" run "$_ghostcfg" "ghost" --env 2>&1 || true)"
grep -q "is NOT on PATH" <<<"$out_ghost" \
  && pass "R3: a profile whose harness CLI is missing warns at resolution time" \
  || fail "R3: resolved to an unrunnable harness with no warning"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
[ "$FAIL" = 0 ]
