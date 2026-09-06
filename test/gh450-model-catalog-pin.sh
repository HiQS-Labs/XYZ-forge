#!/usr/bin/env bash
# GH-450 (Model-catalog Phase 1): the vendored catalog pin and the generated alias YAML.
#
# What this pins. relay-automation/openrouter-model-aliases.yml is no longer hand-appended: it is
# GENERATED from relay-automation/model-catalog/catalog.json, a byte-identical vendored copy of
# HiQS-Labs/Model-catalog at one tag, by that repo's own renderer (vendored beside it). Two edges
# can silently rot and this suite makes both loud, with a negative control for each:
#
#   copy <-> upstream tag   the pin record (catalog.pin.json) carries the tag + sha256 of the copy
#                           and of the renderer; a flipped row in the copy is a sha mismatch.
#   copy <-> committed YAML the drift check re-renders the copy and demands byte equality; a
#                           hand-appended YAML line (the retired GH-120 flow) is a drift failure.
#
# Plus the telemetry edge: the vendored copy's `version` rides resolve-profile's export block and
# lands in harnesses.db invocation rows (model_catalog_version), so "resolved by catalog vX.Y.Z"
# is a fact in the row, not a guess from a date. All negative controls run on SCRATCH COPIES under
# $WORK — nothing here edits the tracked tree, and the checker is pointed at the copy with --root.
#
# Hand-written resolver assertions stay in test/model-alias.sh and still drive the real
# resolve-model-alias.sh (untouched by GH-450): a test generated from the catalog would be a
# tautology, so nothing here is derived from the catalog's rows.
source "$(dirname "$0")/_setup.sh" gh450-model-catalog-pin
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MC="$ROOT/utils/py/model_catalog.py"
CAT_DIR="relay-automation/model-catalog"
YAML="relay-automation/openrouter-model-aliases.yml"

run_check() { python3 "$MC" check --root "$1" 2>&1; }

# Snapshot the tracked-file state this suite must not change (compared at the end, so a dirty
# working tree the OPERATOR left is not blamed on the suite).
tracked_state() { git -C "$ROOT" status --porcelain -- harnesses.db harnesses.sql relay-automation 2>/dev/null; }
before_state="$(tracked_state)"

# ---------------------------------------------------------------------------------------------
# 1. The committed tree is green: pin sha256s agree, YAML == a fresh render.
# ---------------------------------------------------------------------------------------------
out="$(run_check "$ROOT")"; rc=$?
[ "$rc" = 0 ] && pass "check: committed tree is green ($out)" \
  || fail "check: committed tree is RED (rc=$rc): $out"

ver="$(python3 "$MC" version --root "$ROOT" 2>/dev/null)"
[ -n "$ver" ] && pass "version: vendored catalog reports v$ver" || fail "version verb printed nothing"

pin_ver="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"])' "$ROOT/$CAT_DIR/catalog.pin.json")"
pin_tag="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["tag"])' "$ROOT/$CAT_DIR/catalog.pin.json")"
[ "$pin_ver" = "$ver" ] && pass "pin record version ($pin_ver) == vendored catalog version" \
  || fail "pin record says $pin_ver, catalog says $ver"
[ "$pin_tag" = "v$ver" ] && pass "pin record tag ($pin_tag) names the version it vendors" \
  || fail "pin tag $pin_tag does not name v$ver"

# The generated YAML says where it came from, in its first line, with the version — a fresh reader
# must never mistake it for the hand-maintained GH-120 table it replaced.
yaml_head="$(head -1 "$ROOT/$YAML")"
case "$yaml_head" in *"GENERATED from HiQS-Labs/Model-catalog v$ver"*)
  pass "YAML header names the catalog version (v$ver) and says it is generated" ;;
  *) fail "YAML header does not name Model-catalog v$ver: $yaml_head" ;; esac

# Every non-comment YAML line is exactly one `openrouter` row from the copy, and every openrouter
# row is present — the native (AEGIS-Sleuth) rows must never leak into a table an OpenRouter
# resolver reads (Model-catalog consumer contract: same-target scoping).
yaml_rows="$(grep -c '^[^#].*:' "$ROOT/$YAML")"
cat_rows="$(python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(sum(1 for a in d["aliases"] if a["target"]=="openrouter"))' "$ROOT/$CAT_DIR/catalog.json")"
native_rows="$(python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(sum(1 for a in d["aliases"] if a["target"]=="native"))' "$ROOT/$CAT_DIR/catalog.json")"
[ "$yaml_rows" = "$cat_rows" ] && [ "$cat_rows" -gt 0 ] \
  && pass "YAML carries exactly the catalog's openrouter rows ($yaml_rows), none of its $native_rows native rows" \
  || fail "YAML has $yaml_rows rows; catalog has $cat_rows openrouter rows"

# Each rendered row resolves through the REAL resolver to its own canonical (the data->resolver
# edge). Order-independent here; the row-ORDER contract (squash-length desc) is the renderer's and
# is covered by byte-equality above.
R="$ROOT/relay-automation/resolve-model-alias.sh"
rows_ok=1
while IFS= read -r line; do
  case "$line" in ''|'#'*) continue ;; esac
  alias_part="${line%%:*}"; want="${line#*: }"
  got="$(bash "$R" "$alias_part" 2>/dev/null)"
  [ "$got" = "$want" ] || { rows_ok=0; echo "    row '$alias_part' -> '$got' (want '$want')" >&2; }
done < "$ROOT/$YAML"
[ "$rows_ok" = 1 ] && pass "every rendered row resolves through the real resolve-model-alias.sh" \
  || fail "a rendered row does not resolve through the real resolver"

# ---------------------------------------------------------------------------------------------
# 2. Scratch copy helper — the negative controls never touch the tracked tree.
# ---------------------------------------------------------------------------------------------
fresh_copy() {
  local dst="$1"
  rm -rf "$dst"; mkdir -p "$dst/relay-automation"
  cp -R "$ROOT/$CAT_DIR" "$dst/relay-automation/"
  cp "$ROOT/$YAML" "$dst/relay-automation/"
}

# --- 2a. A flipped row in the vendored copy: BOTH edges go red in one run. ---
T="$WORK/flip"; fresh_copy "$T"
python3 - "$T/$CAT_DIR/catalog.json" <<'PY'
import json, sys
p = sys.argv[1]; d = json.load(open(p))
row = next(a for a in d["aliases"] if a["target"] == "openrouter")
row["replace"] = row["replace"] + "-repinned"
json.dump(d, open(p, "w"), indent=2)
PY
out="$(run_check "$T")"; rc=$?
[ "$rc" != 0 ] && pass "negative control: a flipped row in the vendored copy turns check RED (rc=$rc)" \
  || fail "flipped row NOT caught: $out"
case "$out" in *"catalog sha256 mismatch"*) pass "  ...and names the pin edge (copy != pinned tag)" ;;
  *) fail "flipped row did not report the sha mismatch: $out" ;; esac
case "$out" in *"drift:"*) pass "  ...and names the drift edge (render != committed YAML)" ;;
  *) fail "flipped row did not report YAML drift: $out" ;; esac

# The sync-PR recipe is what turns it green again: `render` fixes drift (and only drift), `pin`
# re-records the copy deliberately. Each step closes exactly one edge, proving neither is a no-op.
python3 "$MC" render --root "$T" >/dev/null 2>&1
out="$(run_check "$T")"
case "$out" in *"drift:"*) fail "render did not close the drift edge: $out" ;;
  *) pass "sync recipe: 'render' closes the drift edge" ;; esac
case "$out" in *"catalog sha256 mismatch"*) pass "sync recipe: 'render' alone leaves the pin edge red (a re-pin is a deliberate act)" ;;
  *) fail "render silently re-pinned the copy: $out" ;; esac
# A pin is never self-certifying (PR #180 review, mirrored here): moving to a NEW tag must carry
# the release's sha256, or it would certify whatever bytes are on disk as "the tag".
if python3 "$MC" pin --root "$T" --tag "v9.9.9-test" --tag-commit "0000000" >/dev/null 2>"$T/pin-move.err"; then
  fail "pin accepted a tag move without --expect-sha256"
else
  case "$(cat "$T/pin-move.err")" in *"needs --expect-sha256"*) pass "negative control: pin refuses a tag move without --expect-sha256, by name" ;;
    *) fail "pin refused a tag move for the wrong reason: $(cat "$T/pin-move.err")" ;; esac
fi
if python3 "$MC" pin --root "$T" --tag "v9.9.9-test" --tag-commit "0000000" --expect-sha256 "$(printf '0%.0s' $(seq 64))" >/dev/null 2>"$T/pin-wrong.err"; then
  fail "pin accepted a tag move whose --expect-sha256 does not match the copy"
else
  case "$(cat "$T/pin-wrong.err")" in *"re-vendor from the tag before pinning"*) pass "negative control: a wrong --expect-sha256 is refused, by name" ;;
    *) fail "wrong-hash refusal named the wrong reason: $(cat "$T/pin-wrong.err")" ;; esac
fi
flipped_sha="$(python3 -c 'import hashlib,sys; print(hashlib.sha256(open(sys.argv[1],"rb").read()).hexdigest())' "$T/$CAT_DIR/catalog.json")"
python3 "$MC" pin --root "$T" --tag "v9.9.9-test" --tag-commit "0000000" --expect-sha256 "$flipped_sha" >/dev/null 2>&1
out="$(run_check "$T")"; rc=$?
[ "$rc" = 0 ] && pass "sync recipe: 'pin --expect-sha256 <release hash>' then re-check is green" || fail "pin did not make the scratch tree green: $out"

# --- 2a'. Provenance guard (PR #456 review): a changed renderer needs --renderer-commit. ---
T="$WORK/renderer"; fresh_copy "$T"
printf '\n# vendored-renderer change for the guard control\n' >> "$T/$CAT_DIR/render_openrouter.py"
if python3 "$MC" pin --root "$T" --tag "v1.0.0" --tag-commit "75e19139" >/dev/null 2>"$T/pin.err"; then
  fail "pin accepted a changed renderer without --renderer-commit (provenance would carry the old commit beside the new sha)"
else
  case "$(cat "$T/pin.err")" in *"no --renderer-commit"*) pass "negative control: pin refuses a changed renderer without --renderer-commit, by name" ;;
    *) fail "pin refused for the wrong reason: $(cat "$T/pin.err")" ;; esac
fi
python3 "$MC" pin --root "$T" --tag "v1.0.0" --tag-commit "75e19139" --renderer-commit "deadbeef" >/dev/null 2>&1 \
  && pass "pin accepts the changed renderer once --renderer-commit names its origin" \
  || fail "pin refused even with --renderer-commit"

# --- 2b. The retired hand-append flow: one line appended to the YAML is a drift failure. ---
T="$WORK/append"; fresh_copy "$T"
printf 'kimi k3: moonshot/kimi-k3\n' >> "$T/$YAML"
out="$(run_check "$T")"; rc=$?
[ "$rc" != 0 ] && pass "negative control: a hand-appended YAML line turns check RED (the GH-120 flow is retired)" \
  || fail "hand-appended line NOT caught: $out"
case "$out" in *"drift:"*"kimi k3: moonshot/kimi-k3"*) pass "  ...and names the offending line" ;;
  *) fail "drift report does not name the appended line: $out" ;; esac
case "$out" in *"sha256 mismatch"*) fail "a YAML-only edit must not be reported as a pin problem: $out" ;;
  *) pass "  ...without blaming the untouched vendored copy" ;; esac

# --- 2c. A stale pin record (sha edited, copy intact) is caught by name. ---
T="$WORK/pin"; fresh_copy "$T"
python3 - "$T/$CAT_DIR/catalog.pin.json" <<'PY'
import json, sys
p = sys.argv[1]; d = json.load(open(p)); d["catalog_sha256"] = "0" * 64
json.dump(d, open(p, "w"), indent=2)
PY
out="$(run_check "$T")"; rc=$?
[ "$rc" != 0 ] && pass "negative control: a stale pin sha turns check RED" || fail "stale pin NOT caught: $out"

# --- 2d. A missing vendored file is a named problem, not a crash or a pass. ---
T="$WORK/missing"; fresh_copy "$T"; rm -f "$T/$CAT_DIR/render_openrouter.py"
out="$(run_check "$T")"; rc=$?
[ "$rc" != 0 ] && case "$out" in *"missing: $CAT_DIR/render_openrouter.py"*) pass "negative control: a missing vendored renderer is named" ;;
  *) fail "missing renderer not named: $out" ;; esac || fail "missing renderer passed: $out"

# ---------------------------------------------------------------------------------------------
# 3. Telemetry: the catalog version rides resolve-profile and lands in the invocation row.
# ---------------------------------------------------------------------------------------------
PR="$ROOT/utils/py/profile_resolve.py"
out="$(XYZ_DEVICE_CONFIG_PATH=/dev/null python3 "$PR" --json 2>/dev/null)"
case "$out" in *"\"catalog_version\": \"$ver\""*) pass "resolve-profile --json carries catalog_version $ver" ;;
  *) fail "resolve-profile --json lacks catalog_version $ver: $out" ;; esac
out="$(XYZ_DEVICE_CONFIG_PATH=/dev/null python3 "$PR" --env 2>/dev/null)"
case "$out" in *"export XYZ_MODEL_CATALOG_VERSION='$ver'"*) pass "resolve-profile --env exports XYZ_MODEL_CATALOG_VERSION even on the tier-4 floor" ;;
  *) fail "resolve-profile --env does not export the catalog version: $out" ;; esac
out="$(XYZ_DEVICE_CONFIG_PATH=/dev/null python3 "$PR" --explain 2>/dev/null)"
case "$out" in *"catalog: v$ver"*) pass "resolve-profile --explain names the catalog version" ;;
  *) fail "--explain lacks the catalog line: $out" ;; esac

# The library read never raises and never blocks: a root with no vendored copy yields None.
out="$(python3 -c "import sys; sys.path.insert(0, '$ROOT/utils/py'); from model_catalog import catalog_version; print(catalog_version('$WORK/nowhere'))")"
[ "$out" = "None" ] && pass "catalog_version() on a root with no copy is None, not an exception" \
  || fail "catalog_version() on a missing copy: $out"

# A row actually lands with the version (dynamic, scratch DB — same shape as gh346-telemetry-row-written).
DB="$WORK/harnesses.db"
XYZ_HARNESS_DB="$DB" python3 "$ROOT/utils/py/harness_app.py" init >/dev/null 2>&1 \
  || fail "could not seed the scratch harnesses.db"
XYZ_HARNESS_LOGGING=1 XYZ_HARNESS_DB="$DB" XYZ_DEVICE_CONFIG_PATH=/dev/null python3 - "$ROOT" <<'PY' 2>"$WORK/probe.err"
import os, sys
root = sys.argv[1]; sys.path.insert(0, os.path.join(root, "utils", "py"))
from harness_turn_logger import HarnessTurnLogger
# default: read from the vendored copy under repo_root
with HarnessTurnLogger(harness_id="dsh", shim="deepseek-turn.py", task_scope="GH450-DEFAULT",
                       model_id="deepseek/deepseek-v4-pro", gateway="probe", reasoning_effort="high",
                       cli_flags=["--probe"], repo_root=root) as lg:
    lg.exit_code = 0
# the export block from resolve-profile wins over the copy on disk
os.environ["XYZ_MODEL_CATALOG_VERSION"] = "7.7.7-env"
with HarnessTurnLogger(harness_id="dsh", shim="deepseek-turn.py", task_scope="GH450-ENV",
                       model_id="deepseek/deepseek-v4-pro", gateway="probe", reasoning_effort="high",
                       cli_flags=["--probe"], repo_root=root) as lg:
    lg.exit_code = 0
PY
got="$(sqlite3 "$DB" "select model_catalog_version from invocation_logs where task_scope='GH450-DEFAULT'" 2>/dev/null)"
[ "$got" = "$ver" ] && pass "invocation row carries model_catalog_version=$ver read from the vendored copy" \
  || fail "invocation row model_catalog_version='$got' (want $ver): $(tail -2 "$WORK/probe.err")"
got="$(sqlite3 "$DB" "select model_catalog_version from invocation_logs where task_scope='GH450-ENV'" 2>/dev/null)"
[ "$got" = "7.7.7-env" ] && pass "XYZ_MODEL_CATALOG_VERSION (resolve-profile's export) takes precedence over the copy" \
  || fail "env precedence: got '$got'"

# A database created before GH-450 gains the column on open (additive, nullable) instead of
# failing every subsequent log with "no such column".
OLD="$WORK/old.db"
sqlite3 "$OLD" "CREATE TABLE invocation_logs (invocation_id TEXT PRIMARY KEY, device_id TEXT NOT NULL, harness_id TEXT NOT NULL, model_id TEXT NOT NULL, gateway TEXT NOT NULL, reasoning_effort TEXT, entry_point_shim TEXT NOT NULL, cli_flags TEXT NOT NULL, task_scope TEXT NOT NULL, wall_clock_seconds REAL, exit_code INTEGER NOT NULL, total_tokens INTEGER, prompt_tokens INTEGER, completion_tokens INTEGER, estimated_cost_usd REAL, repo_diff_stat TEXT, created_at DATETIME DEFAULT CURRENT_TIMESTAMP);"
cols="$(XYZ_HARNESS_DB="$OLD" python3 -c "import os, sys; sys.path.insert(0, '$ROOT/utils/py'); import harness_app as h; c = h.init_db(os.environ['XYZ_HARNESS_DB']); print(','.join(r[1] for r in c.execute('PRAGMA table_info(invocation_logs)')))")"
case "$cols" in *model_catalog_version*) pass "a pre-GH-450 harnesses.db is migrated in place (model_catalog_version added)" ;;
  *) fail "legacy DB not migrated: $cols" ;; esac

# The scratch DBs and scratch copies must be the ONLY things touched.
after_state="$(tracked_state)"
if [ "$after_state" = "$before_state" ]; then
  pass "tracked harnesses.db / harnesses.sql / relay-automation untouched by this suite"
else
  fail "this suite changed tracked-file state: before='$before_state' after='$after_state'"
fi

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
[ "$FAIL" = 0 ]
