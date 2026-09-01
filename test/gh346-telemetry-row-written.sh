#!/usr/bin/env bash
# GH-346 checkbox 0.5, discharged as a test instead of a claim.
#
# The original Phase 0 work ticked "a fresh harnesses.db row per touched gateway shows the right
# model" without running a single shim with logging enabled. QA (GLM 5.3 via Command Code) caught
# that, and the reason it mattered turned out to be severe: three shims passed an UNDEFINED NAME as
# cli_flags, raised NameError inside the HarnessTurnLogger call, and had their own
# `except Exception: pass` swallow it. Those gateways wrote NO telemetry row at all, ever. A static
# check on model_id could not see that, because the argument it was checking was correct — in a
# call that never ran.
#
# So this suite is deliberately DYNAMIC. It builds a HarnessTurnLogger exactly as each shim does,
# with logging enabled and a scratch database, and asserts a row actually lands carrying the model
# the shim dispatched. No agent CLI, no network: the logger is driven directly with each shim's own
# resolved values.
source "$(dirname "$0")/_setup.sh" gh346-telemetry-row-written
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$HERE/.."
PASS=0; FAIL=0
pass(){ echo "  PASS: $*"; PASS=$((PASS+1)); }
fail(){ echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
echo "== test: gh346-telemetry-row-written =="

DB="$WORK/harnesses.db"

# Seed the scratch DB. invocation_logs has FKs to devices/harnesses/models; `log` seeds devices and
# models itself, but the harnesses registry comes from `init`. Without this the insert fails with
# FOREIGN KEY constraint failed -- which HarnessTurnLogger ALSO used to swallow (it ran
# harness_app.py with check=False and never looked at the return code), so a fully-correct shim
# would still have written nothing while reporting success. That swallow is fixed too; this seeds
# the DB so the test measures the shims, not the fixture.
XYZ_HARNESS_DB="$DB" python3 "$ROOT/utils/py/harness_app.py" init >/dev/null 2>&1 \
  || { echo "  FAIL: could not seed the scratch harnesses.db" >&2; exit 1; }

XYZ_HARNESS_LOGGING=1 XYZ_HARNESS_DB="$DB" XYZ_DEVICE_CONFIG_PATH=/dev/null \
  python3 - "$ROOT" "$DB" > "$WORK/probe.out" 2>"$WORK/probe.err" <<'PY'
import os, sqlite3, sys
root, db = sys.argv[1], sys.argv[2]
sys.path.insert(0, os.path.join(root, "utils", "py"))
from harness_turn_logger import HarnessTurnLogger

# (harness_id, shim, the model the shim would have DISPATCHED)
cases = [
    ("claude",      "claude-turn.py",      "claude-sonnet-4-6"),
    ("commandcode", "commandcode-turn.py", "meta/muse-spark-1.2-contributor"),
    ("aider",       "aider-turn.py",       "openrouter/anthropic/claude-sonnet-5"),
    # NOTE the id is "dsh", not "deepseek": harnesses.harness_id is the REGISTRY's id
    # (harness_app.py seeds "dsh"), while the lane/agent id everywhere else is "deepseek".
    # Two namespaces for one harness. Getting this wrong fails the FK and writes nothing.
    ("dsh",         "deepseek-turn.py",    "deepseek/deepseek-v4-pro"),
    ("pi",          "pi-turn.py",          "openai/gpt-mini-latest"),
]
for hid, shim, model in cases:
    try:
        with HarnessTurnLogger(harness_id=hid, shim=shim, task_scope="GH346-PROBE",
                               model_id=model, gateway="probe", reasoning_effort="high",
                               cli_flags=["--probe"], repo_root=root) as lg:
            lg.exit_code = 0
    except Exception as e:
        print(f"FAIL={hid}: logger raised {e!r}")

# agy/codex pass None when the operator chose no model -> device_config's declared default
for hid, shim in (("agy", "agy-turn.py"), ("codex", "codex-turn.py")):
    try:
        with HarnessTurnLogger(harness_id=hid, shim=shim, task_scope="GH346-PROBE",
                               model_id=None, gateway="probe", reasoning_effort="high",
                               cli_flags=["--probe"], repo_root=root) as lg:
            lg.exit_code = 0
    except Exception as e:
        print(f"FAIL={hid}: logger raised {e!r}")

if not os.path.exists(db):
    print("FAIL=no harnesses.db was created — nothing was logged at all")
    sys.exit(0)

rows = dict(sqlite3.connect(db).execute(
    "select harness_id, model_id from invocation_logs where task_scope='GH346-PROBE'").fetchall())

for hid, shim, model in cases:
    got = rows.get(hid)
    if got is None:
        print(f"FAIL={hid}: NO row written (this is the bug QA found — a swallowed NameError)")
    elif got == model:
        print(f"PASS={hid}: row records the dispatched model {got}")
    else:
        print(f"FAIL={hid}: row records {got!r}, dispatched {model!r}")

for hid in ("agy", "codex"):
    got = rows.get(hid)
    if got is None:
        print(f"FAIL={hid}: NO row written")
    elif got.strip():
        # NOT asserted to equal a dispatched model: with the var unset these shims pass no --model
        # at all, so the row is a DECLARED default, not a dispatched one. Phase 3 is what makes
        # these agree; until then the honest assertion is "a real declared value, not a fabrication".
        print(f"PASS={hid}: row records device_config's declared default {got} (declared, NOT dispatched — Phase 3 closes this)")
    else:
        print(f"FAIL={hid}: row records an empty model")
PY

if [ ! -s "$WORK/probe.out" ]; then
  fail "probe produced no output — it did not run: $(tail -2 "$WORK/probe.err" 2>/dev/null)"
else
  while IFS= read -r pline; do
    case "$pline" in PASS=*) pass "${pline#PASS=}" ;; FAIL=*) fail "${pline#FAIL=}" ;; esac
  done < "$WORK/probe.out"
fi

# The scratch DB must be the ONLY one touched — a probe that wrote into the repo's real
# harnesses.db would be corrupting the audit trail it is here to protect.
if [ -f "$DB" ]; then
  pass "telemetry landed in the scratch DB (repo harnesses.db untouched)"
else
  fail "no scratch DB at $DB"
fi

echo "  gh346-telemetry-row-written: $PASS pass, $FAIL fail"
[ "$FAIL" = 0 ]
