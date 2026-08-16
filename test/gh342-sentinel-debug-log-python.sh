#!/usr/bin/env bash
# test/gh342-sentinel-debug-log-python.sh — GH-342: the GH-281 Sentinel Tier-1 debug capture must
# work on the lane that ACTUALLY RUNS.
#
# The gap this pins: XYZ_DEBUG_LOG=1 was honored only by relay-automation/marathon-drive.sh, which
# exec's utils/py/marathon_drive.py near the top, and Python is the default lane since GH-264. So
# arming the capture on a normal run wrote nothing, silently.
#
# The existing GH-281 test (test/sentinel-driver-hooks.sh) could not catch this: it sed-extracts the
# helpers out of the BASH file and sources them, so it asserts a lane nobody runs. Every case below
# drives the DEFAULT lane — XYZ_PYTHON deliberately unset — or the Python module directly.
#
# Cases:
#   1  wiring: all six §1.3 hooks present in the PYTHON twin (the Bash-side mirror of this lives in
#      test/sentinel-driver-hooks.sh; both are needed while marathon-drive.sh stays a frozen twin)
#   2  default-off: unset and =0 write nothing — asserting the file's ABSENCE, not its emptiness
#   3  on-mode: one valid JSONL record per call, correct fields, adversarial input escaped
#   4  cross-lane parity: the Bash helper and the Python helper emit byte-identical records
#   5  robustness: an unwritable DEBUG_LOG_FILE raises nothing and changes no exit code
#   6  harvest gating: harvest-findings.sh is spawned only when armed AND executable
#   7  end-to-end on the default lane: a real marathon-drive run reclaiming a stale driver lock
#      appends the stale-lock record (and writes nothing when the flag is off)
source "$(dirname "$0")/_setup.sh" gh342-sentinel-debug-log-python

# See test/driver-lock.sh: inherited from a marathon gate, this would skip the very lock block
# case 7 exercises.
unset RELAY_DRIVER_LOCKED
# Load-bearing for the whole file: every case must exercise the DEFAULT lane.
unset XYZ_PYTHON
unset XYZ_DEBUG_LOG
unset DEBUG_LOG_FILE

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PY_TWIN="$REPO_ROOT/utils/py/marathon_drive.py"
SH_TWIN="$REPO_ROOT/relay-automation/marathon-drive.sh"
[ -f "$PY_TWIN" ] || fail "python twin not found: $PY_TWIN"

# ── 1. Wiring: the six GH-281 §1.3 hooks exist in the PYTHON twin ────────────────────────────
# Mirrors the `need=()` list in test/sentinel-driver-hooks.sh, retargeted at the Python lane. Greps,
# not behavior — behavior is cases 2-7; this is the cheap "did someone delete a call site" tripwire.
py_has() { grep -qF "$1" "$PY_TWIN"; }
py_has 'os.environ.get("XYZ_DEBUG_LOG", "0") == "1"' \
  && pass "1a: opt-in gate reads XYZ_DEBUG_LOG (default off)" || fail "1a: XYZ_DEBUG_LOG gate missing"
py_has 'def xyz_debug_log_append(' \
  && pass "1b: append helper defined" || fail "1b: xyz_debug_log_append missing"
py_has '"marathon.escalation"' \
  && pass "1c: escalation hook wired" || fail "1c: marathon.escalation hook missing"
py_has '"marathon.lane-park"' \
  && pass "1d: lane-park hook wired" || fail "1d: marathon.lane-park hook missing"
py_has 'marathon.stale-lock' \
  && pass "1e: stale-lock hook wired" || fail "1e: marathon.stale-lock hook missing"
py_has 'harvest-findings.sh' \
  && pass "1f: harvest hook wired" || fail "1f: harvest-findings.sh spawn missing"
# The escalation hook must sit inside escalate(), and the harvest spawn inside BOTH escalate() and
# save_transcript() — a helper defined but called from nowhere is exactly this bug in a new shape.
python3 - "$PY_TWIN" <<'PY' && pass "1g: hooks are called from escalate() and save_transcript(), not merely defined" \
  || fail "1g: a hook is defined but not wired into its call site"
import ast, sys
src = open(sys.argv[1]).read()
tree = ast.parse(src)
lines = src.splitlines()

def body_calls(fn_name):
    """Names called inside the nested def <fn_name>, anywhere in the module."""
    for node in ast.walk(tree):
        if isinstance(node, ast.FunctionDef) and node.name == fn_name:
            return {n.func.id for n in ast.walk(node)
                    if isinstance(n, ast.Call) and isinstance(n.func, ast.Name)}
    raise SystemExit(f"no def {fn_name}")

esc = body_calls("escalate")
assert "xyz_debug_log_append" in esc, f"escalate() does not append a finding: {sorted(esc)}"
assert "xyz_harvest_findings" in esc, f"escalate() does not harvest: {sorted(esc)}"
st = body_calls("save_transcript")
assert "xyz_harvest_findings" in st, f"save_transcript() does not harvest: {sorted(st)}"
gate = body_calls("lane_attempt_gate")
assert "xyz_debug_log_append" in gate, f"lane_attempt_gate() does not emit lane-park: {sorted(gate)}"
PY

# ── 2-6. Behavior, driving the Python module directly ────────────────────────────────────────
# Importable by design: these helpers live at MODULE scope precisely so their record contract is
# assertable without a full driven run (the GH-322 runlog_find_comment_id precedent).
python3 - "$REPO_ROOT" "$WORK" "$SH_TWIN" <<'PY'
import json, os, re, subprocess, sys, tempfile

repo_root, work, sh_twin = sys.argv[1], sys.argv[2], sys.argv[3]
sys.path.insert(0, os.path.join(repo_root, "utils", "py"))
import marathon_drive as md

P = F = 0
def ok(msg):
    global P; P += 1; print(f"  PASS: {msg}")
def bad(msg):
    global F; F += 1; print(f"  FAIL: {msg}", file=sys.stderr)

def fresh():
    d = tempfile.mkdtemp(dir=work)
    return d, os.path.join(d, "debug.log")

# ── 2. default-off ───────────────────────────────────────────────────────────
for label, val in (("unset", None), ("=0", "0"), ("=yes (not the literal 1)", "yes")):
    root, log = fresh()
    os.environ.pop("XYZ_DEBUG_LOG", None)
    if val is not None:
        os.environ["XYZ_DEBUG_LOG"] = val
    md.xyz_debug_log_append(root, "error", "marathon.escalation", "must not be written")
    md.xyz_debug_log_stale_lock(root)
    # ABSENCE, not emptiness: a helper that creates an empty file has already touched the repo, and
    # an emptiness check would pass for a helper that opens the file and writes nothing.
    if not os.path.exists(log):
        ok(f"2: XYZ_DEBUG_LOG {label} — debug.log not created at all")
    else:
        bad(f"2: XYZ_DEBUG_LOG {label} wrote {os.path.getsize(log)} bytes to debug.log")
os.environ.pop("XYZ_DEBUG_LOG", None)

# ── 3. on-mode record contract ────────────────────────────────────────────────
os.environ["XYZ_DEBUG_LOG"] = "1"
root, log = fresh()
md.xyz_debug_log_append(
    root, "error", "marathon.escalation",
    'no-progress\t"x" \\y\nsecond line\x00\x7f',
    file="phases/p1/RELAY.md", action="promote",
    phase_id="p1", relay_task="TASK-1")
with open(log) as fh:
    rows = fh.readlines()
if len(rows) == 1:
    ok("3a: exactly one line per append (a multi-line message stays one record)")
else:
    bad(f"3a: expected 1 line, got {len(rows)}")
row = json.loads(rows[0])
checks = [
    ("severity", "error"), ("check", "marathon.escalation"),
    ("file", "phases/p1/RELAY.md"), ("action", "promote"),
    ("phase", "p1"), ("task", "TASK-1"),
    ("scope", "harness"), ("repo", root), ("line", ""), ("probe", ""),
]
wrong = [(k, row.get(k), v) for k, v in checks if row.get(k) != v]
if not wrong:
    ok("3b: every field carries the expected value")
else:
    bad(f"3b: field mismatches {wrong}")
if not any(re.search(r"[\x00-\x1f\x7f]", str(v)) for v in row.values()):
    ok("3c: no raw C0/DEL byte survived into any field")
else:
    bad(f"3c: control byte leaked: {row!r}")
if '"x"' in row["message"] and "\\y" in row["message"]:
    ok("3d: quote and backslash survive escaping intact")
else:
    bad(f"3d: escaping lost content: {row['message']!r}")
if re.fullmatch(r"\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ", row["timestamp"]):
    ok("3e: timestamp is UTC ...Z, second precision")
else:
    bad(f"3e: bad timestamp {row['timestamp']!r}")

# target_root set → scope/repo both retarget (the --target-root lane)
root, log = fresh()
md.xyz_debug_log_append(root, "warn", "marathon.lane-park", "m", target_root="/tmp/other")
row = json.loads(open(log).readline())
if row["scope"] == "target:/tmp/other" and row["repo"] == "/tmp/other":
    ok("3f: --target-root run tags scope=target:<path> and repo=<path>")
else:
    bad(f"3f: target_root not honored: {row!r}")

# DEBUG_LOG_FILE override, including the empty-value fallback
root, _ = fresh()
alt = os.path.join(root, "nested", "custom.jsonl")
os.makedirs(os.path.dirname(alt))
os.environ["DEBUG_LOG_FILE"] = alt
md.xyz_debug_log_append(root, "info", "c", "m")
ok("3g: DEBUG_LOG_FILE honored") if os.path.exists(alt) else bad("3g: DEBUG_LOG_FILE ignored")
os.environ["DEBUG_LOG_FILE"] = ""
md.xyz_debug_log_append(root, "info", "c", "m")
if os.path.exists(os.path.join(root, "debug.log")):
    ok("3h: an EMPTY DEBUG_LOG_FILE falls back to $ROOT/debug.log (Bash `:=` semantics)")
else:
    bad("3h: empty DEBUG_LOG_FILE did not fall back")
os.environ.pop("DEBUG_LOG_FILE", None)

# ── 4. cross-lane parity: Bash helper vs Python helper, same bytes ────────────
# The Bash lane is the frozen twin, so this is the assertion that keeps the two in step. Extracted
# and sourced the same way test/sentinel-driver-hooks.sh does it; only the timestamp is normalized.
def norm(line):
    return re.sub(r'"timestamp":"[^"]*"', '"timestamp":"T"', line.strip())

root, log = fresh()
helpers = os.path.join(root, "helpers.sh")
extract = subprocess.run(
    ["sed", "-n", r"/^_json_esc()/,/^}/p; /^xyz_debug_log_append()/,/^}/p", sh_twin],
    stdout=subprocess.PIPE)
open(helpers, "wb").write(extract.stdout)
if b"xyz_debug_log_append" not in extract.stdout:
    bad("4: could not extract the Bash helper — parity unverifiable")
else:
    cases = [
        # (severity, check, message, file, action, probe, phase, task, target_root)
        ("error", "marathon.escalation", "no-progress (relay-drive-exit=3)",
         "phases/p1/RELAY.md", "promote to PROJECT/1-INBOX capture doc", "", "p1", "TASK-1", ""),
        ("warn", "marathon.lane-park", "lane gh342-lane parked at attempt cap",
         "", "re-anchor to QUEUE lanes or re-fire with --force", "", "p2", "TASK-2", ""),
        ("error", "marathon.escalation", 'adversarial\t"q" \\b and a\nnewline',
         "a/b.md", "act", "probe-1", "p3", "TASK-3", "/tmp/target-repo"),
    ]
    mismatched = []
    for i, (sev, chk, msg, f_, act, prb, ph, tk, tr) in enumerate(cases):
        sh_log = os.path.join(root, f"sh-{i}.log")
        py_log = os.path.join(root, f"py-{i}.log")
        env = dict(os.environ, XYZ_DEBUG_LOG="1", DEBUG_LOG_FILE=sh_log,
                   ROOT=root, TARGET_ROOT=tr, PHASE_ID=ph, RELAY_TASK=tk)
        subprocess.run(
            ["bash", "-c",
             f'source "{helpers}"; xyz_debug_log_append "$1" "$2" "$3" "$4" "$5" "$6"',
             "_", sev, chk, msg, f_, act, prb],
            env=env, check=True)
        os.environ["DEBUG_LOG_FILE"] = py_log
        md.xyz_debug_log_append(root, sev, chk, msg, file=f_, action=act, probe=prb,
                                target_root=(tr or None), phase_id=ph, relay_task=tk)
        os.environ.pop("DEBUG_LOG_FILE", None)
        a, b = norm(open(sh_log).readline()), norm(open(py_log).readline())
        if a != b:
            mismatched.append((i, a, b))
    if not mismatched:
        ok(f"4: Bash and Python emit byte-identical records ({len(cases)} cases, incl. adversarial "
           "input and a --target-root run)")
    else:
        for i, a, b in mismatched:
            bad(f"4: record {i} diverges\n    bash: {a}\n    py:   {b}")

# ── 5. an unwritable log never breaks the run ────────────────────────────────
root, _ = fresh()
os.environ["DEBUG_LOG_FILE"] = os.path.join(root, "no", "such", "dir", "debug.log")
try:
    md.xyz_debug_log_append(root, "error", "c", "m")
    md.xyz_debug_log_stale_lock(root)
    ok("5a: an unwritable DEBUG_LOG_FILE raises nothing (best-effort append)")
except Exception as exc:
    bad(f"5a: unwritable log raised {exc!r} — this would change the driven run's exit code")
if os.geteuid() != 0:
    ro = os.path.join(root, "ro")
    os.makedirs(ro)
    os.chmod(ro, 0o500)
    os.environ["DEBUG_LOG_FILE"] = os.path.join(ro, "debug.log")
    try:
        md.xyz_debug_log_append(root, "error", "c", "m")
        ok("5b: a read-only log directory raises nothing")
    except Exception as exc:
        bad(f"5b: read-only dir raised {exc!r}")
    os.chmod(ro, 0o700)
else:
    # Root defeats mode bits — say so rather than reporting a pass this run did not earn.
    print("  SKIP: 5b read-only-dir case (running as root; mode bits do not apply)")
os.environ.pop("DEBUG_LOG_FILE", None)

# ── 6. harvest spawn is gated ────────────────────────────────────────────────
root, _ = fresh()
marker = os.path.join(root, "harvested")
harvest = os.path.join(root, "harvest-findings.sh")
with open(harvest, "w") as fh:
    fh.write('#!/bin/sh\nprintf "%s\\n" "$@" > "$(dirname "$0")/harvested"\n')
os.chmod(harvest, 0o755)

os.environ.pop("XYZ_DEBUG_LOG", None)
md.xyz_harvest_findings(harvest, "relay.md", root, None, os.path.join(root, "debug.log"))
if not os.path.exists(marker):
    ok("6a: harvest NOT spawned when XYZ_DEBUG_LOG is unset")
else:
    bad("6a: harvest ran with the flag off")

os.environ["XYZ_DEBUG_LOG"] = "1"
md.xyz_harvest_findings(harvest, "relay.md", root, "/tmp/tr", os.path.join(root, "debug.log"))
if os.path.exists(marker):
    argv = open(marker).read().split("\n")
    if "--relay" in argv and "relay.md" in argv and "target:/tmp/tr" in argv:
        ok("6b: harvest spawned when armed, with --relay/--scope/--repo/--out")
    else:
        bad(f"6b: harvest argv wrong: {argv!r}")
else:
    bad("6b: harvest not spawned when armed")

# a non-executable / absent script is skipped, not raised
os.chmod(harvest, 0o644)
try:
    md.xyz_harvest_findings(harvest, "relay.md", root, None, os.path.join(root, "debug.log"))
    md.xyz_harvest_findings(os.path.join(root, "nope.sh"), "relay.md", root, None, "/dev/null")
    ok("6c: a non-executable or missing harvest script is skipped silently")
except Exception as exc:
    bad(f"6c: raised {exc!r}")
os.environ.pop("XYZ_DEBUG_LOG", None)

with open(os.path.join(work, "counts"), "w") as fh:
    fh.write(f"{P} {F}\n")
sys.exit(1 if F else 0)
PY
_py_rc=$?
# Fold the block's own tallies into this file's counters. Without this a FAIL inside the heredoc
# would print in red and still leave the file reporting "0 fail" — the exact shape of green-signal
# defect this test exists to close.
if [ -f "$WORK/counts" ]; then
  read -r _pp _pf < "$WORK/counts"
  PASS=$((PASS + _pp)); FAIL=$((FAIL + _pf))
  [ "$_pf" -eq 0 ] || fail "python behavior block reported $_pf failure(s) (see above)"
else
  fail "python behavior block did not report counts (exited $_py_rc before finishing)"
fi

# ── 7. End-to-end on the DEFAULT lane ────────────────────────────────────────────────────────
# The stale-driver-lock reclaim is the one Tier-1 hook reachable from --dry-run (the lock block runs
# long before the dry-run exit), which makes it the cheapest honest end-to-end proof that the capture
# fires on the lane that actually executes. Setup copied from test/driver-lock.sh.
#
# Deliberately NOT claimed here: the escalation and lane-park hooks sit past the --dry-run exit and
# would need a full driven relay to reach. They are covered by the wiring assertion (1g, an AST check
# that they are called from their real call sites) plus the record-level parity in case 4 — which is
# weaker than end-to-end, and is stated as such rather than papered over.
MD="$SH_TWIN"
LOCK="$A/.git/relay-driver.lock"
brief="$WORK/brief.md"; printf '# brief\n' >"$brief"
STUB_BIN="$WORK/stub-bin"; printf '#!/bin/sh\nexit 0\n' >"$STUB_BIN"; chmod +x "$STUB_BIN"
DBG="$WORK/e2e-debug.log"

run_md() {  # run_md <XYZ_DEBUG_LOG value or empty> [XYZ_PYTHON value]
  local dbg="$1" pyflag="${2-}"
  rm -rf "$LOCK"; mkdir -p "$LOCK"; printf '999999\n' >"$LOCK/pid"   # 999999: not a live pid
  rm -f "$DBG"
  env ${dbg:+XYZ_DEBUG_LOG="$dbg"} ${pyflag:+XYZ_PYTHON="$pyflag"} \
      DEBUG_LOG_FILE="$DBG" MARATHON_ROOT="$A" TICK_BIN="$TICK" \
      CODEX_BIN="$STUB_BIN" CLAUDE_BIN="$STUB_BIN" AGY_BIN="$STUB_BIN" \
      bash "$MD" --phase-brief "$brief" --reviewer agy --dry-run >/dev/null 2>&1
}

# 7a — armed, default lane: the record appears.
run_md 1; rc=$?
[ "$rc" -eq 0 ] && pass "7a: default-lane dry-run over a stale lock still exits 0" \
  || fail "7a: dry-run exited $rc (expected 0)"
if [ -s "$DBG" ] && grep -q '"check":"marathon.stale-lock"' "$DBG"; then
  pass "7a: default lane (XYZ_PYTHON unset) appended the stale-lock record"
else
  fail "7a: no stale-lock record on the default lane — the capture is still Bash-only"
fi
python3 - "$DBG" <<'PY' && pass "7a: the end-to-end record is valid JSON with the expected shape" \
  || fail "7a: end-to-end record malformed"
import json, sys
row = json.loads(open(sys.argv[1]).readline())
assert row["severity"] == "info", row
assert row["check"] == "marathon.stale-lock", row
assert row["scope"] == "harness", row
assert row["message"] == "stale driver lock reclaimed", row
assert row["action"] == "none (auto-healed)", row
PY

# 7b — flag off, default lane: nothing is created. The absence check again, end-to-end.
run_md ""; rc=$?
[ "$rc" -eq 0 ] && [ ! -e "$DBG" ] \
  && pass "7b: flag off — no debug.log created by a real default-lane run" \
  || fail "7b: flag off but debug.log exists (rc=$rc, exists=$([ -e "$DBG" ] && echo yes || echo no))"

# 7c — the two lanes agree end-to-end. This is the case that would have caught GH-342 on day one.
run_md 1 0
if [ -s "$DBG" ]; then
  sed 's/"timestamp":"[^"]*"/"timestamp":"T"/' "$DBG" > "$WORK/e2e-bash.norm"
  run_md 1
  sed 's/"timestamp":"[^"]*"/"timestamp":"T"/' "$DBG" > "$WORK/e2e-py.norm"
  if cmp -s "$WORK/e2e-bash.norm" "$WORK/e2e-py.norm"; then
    pass "7c: Bash lane and default lane produce identical stale-lock records end-to-end"
  else
    fail "7c: lanes diverge end-to-end: $(diff "$WORK/e2e-bash.norm" "$WORK/e2e-py.norm" | head -4)"
  fi
else
  # Bash needs `node` for bin/tick; if that path can't run here, say so instead of passing.
  echo "  SKIP: 7c cross-lane end-to-end (XYZ_PYTHON=0 run produced no record in this environment)"
fi
rm -rf "$LOCK"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
