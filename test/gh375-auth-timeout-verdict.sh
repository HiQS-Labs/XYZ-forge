#!/usr/bin/env bash
# gate-evidence: {"form":"pre-fix-replay","observed":true,"result":"reproducer: bash test/gh375-auth-timeout-verdict.sh. The pre-fix revision is replayed by patching COPIES of agy-turn.py and consult.py back to their old TimeoutExpired branches (unconditional fatal: rc=7 / return False, with no consultation of the captured output). Pre-fix result: a probe that timed out AFTER already printing agy's TTY diagnostic blocked the lane -- agy-turn exits 7 and consult drops the agy seat -- which is what cost a real /consult its agy advisor on 2026-08-09. Post-fix result: the same fixture proceeds, while a timeout with NO diagnostic and a timeout with an interactive-login prompt both still block. All observed in one run."}
# GH-375 follow-up: the timeout branch was still a false block.
#
# GH-375's three-state fix covered `agy whoami` EXITING with a TTY error -> unverifiable -> proceed.
# It never covered the probe blowing its timeout, which went straight to fatal. That is the branch
# that actually fired: a /consult on 2026-08-09 lost its agy seat to
#
#   consult: agy auth pre-flight timed out after 5s; likely expired auth opening an interactive
#            login. Run `agy login` in a normal terminal, then retry.
#
# measured in the same minute on the same machine:
#
#   $ agy whoami   -> CLI error: bubbletea: error opening TTY: ... /dev/tty: device not configured
#   $ agy -p "..." -> answered correctly
#
# So the guard blocked a lane whose builder demonstrably worked -- the same failure DIRECTION GH-375's
# own fix exists to avoid, one branch over. Margin, measured idle on that machine: 1.3s / 1.9s / 2.3s
# against an AGY_AUTH_TIMEOUT_S default of 5. Under 2x, and concurrent load closed it.
#
# The rule pinned here: reclassify a timeout ONLY on positive evidence of the TTY cause.
#   (1) timeout + TTY diagnostic already in the output -> unverifiable, lane proceeds
#   (2) timeout + NO output                            -> still fatal   <- the real hang
#   (3) timeout + an interactive login prompt          -> still fatal   <- the branch's own purpose
#   (4) a probe that EXITS keeps its old verdict, unchanged  <- no regression to GH-375 proper
#
# (2) and (3) are the assertions that matter. "A timeout is unverifiable" is the tempting broader
# rule and it is wrong: silence is exactly the shape a login prompt waiting on stdin produces, so the
# broad rule would swallow the failure this branch was written to catch. Narrow beats tidy here.
set -euo pipefail

source "$(dirname "$0")/_setup.sh" gh375-auth-timeout-verdict
ROOT_REPO="$(cd "$(dirname "$0")/.." && pwd)"
export PYTHONPATH="$ROOT_REPO/utils/py${PYTHONPATH:+:$PYTHONPATH}"

TTY_LINE='CLI error: bubbletea: error opening TTY: bubbletea: could not open TTY: open /dev/tty: device not configured'
LOGIN_LINE='To authenticate, visit https://example.invalid/device and enter code ABCD-1234'

# ── (1)-(4) the verdict function itself ───────────────────────────────────────────────────
mkfix() { printf '%s\n' "$2" > "$WORK/$1"; printf '%s' "$WORK/$1"; }
: > "$WORK/empty.txt"

verdict() {  # <file> -> "<severity>|<detail>"
  python3 -c 'import sys; from rtl import agy_auth_timeout_verdict as v; s,d = v(sys.argv[1]); print(f"{s}|{d}")' "$1"
}

got="$(verdict "$(mkfix tty.txt "$TTY_LINE")")"
[ "${got%%|*}" = "unverifiable" ] \
  && pass "timeout + the TTY diagnostic already printed -> unverifiable (the lane proceeds)" \
  || fail "expected unverifiable for a TTY-diagnosed timeout, got '${got%%|*}'"

got="$(verdict "$WORK/empty.txt")"
[ "${got%%|*}" = "failed" ] \
  && pass "timeout + NO output -> still fatal — silence is the shape of a hang, not evidence of a TTY problem" \
  || fail "a silent timeout must stay fatal, got '${got%%|*}'"

got="$(verdict "$(mkfix login.txt "$LOGIN_LINE")")"
[ "${got%%|*}" = "failed" ] \
  && pass "timeout + an interactive login prompt -> still fatal — the branch keeps its original purpose" \
  || fail "an interactive-login hang must stay fatal, got '${got%%|*}'"

got="$(verdict "$WORK/does-not-exist-$$.txt")"
[ "${got%%|*}" = "failed" ] \
  && pass "timeout + unreadable capture -> fatal, not silently green" \
  || fail "a missing capture must not read as success, got '${got%%|*}'"

# The two functions must not be collapsed into one. agy_auth_output_verdict treats "nothing
# suspicious" as PASS, which is right for a process that exited and catastrophic for one that hung.
got="$(python3 -c 'import sys; from rtl import agy_auth_output_verdict as v; s,d=v(sys.argv[1]); print(s or "PASS")' "$WORK/empty.txt")"
[ "$got" = "PASS" ] \
  && pass "the EXIT-path verdict still passes on empty output (GH-375 proper, unchanged) — which is exactly why the timeout path needs its own function" \
  || fail "agy_auth_output_verdict changed behaviour on empty output — GH-375's own false-failure lesson regressed"

# ── the pre-fix replay: the old unconditional-fatal timeout branch ────────────────────────
# Patched into COPIES so the working tree is never mutated. Both callers had the same shape, so both
# are replayed; a fix in one and not the other is the drift this issue already paid for once.
FIXH="$WORK/prefix"
mkdir -p "$FIXH"
cp -R "$ROOT_REPO/utils" "$FIXH/utils"
# Literal block replacement, restoring each caller's pre-fix source byte-for-byte. NOT index-slicing
# between two anchors: an 8-space-indented anchor also matches INSIDE a 12-space block (the deeper
# line contains the shallower one as a substring), which silently cut consult.py mid-block and left it
# with an IndentationError. A control that fails to compile still "reproduces a block", so that class
# of bug is invisible unless the replay is asserted to be valid Python. Both are compile-checked below.
python3 - "$FIXH/utils/py/agy-turn.py" "$FIXH/utils/py/consult.py" <<'PY'
import pathlib, sys

# GH-492 demoted the unverifiable branch's WARNING to a NOTE and started recording the detail for
# the failure path, so this anchor moved with it. The anchor is what keeps the replay honest — if it
# stops matching, the control below would patch nothing and still report green — so it is updated in
# lockstep rather than loosened into a regex. What is being replayed is UNCHANGED: the pre-fix source
# had no `unverifiable` branch at all and treated every timeout as fatal.
AGY_NEW = '''        t_severity, t_detail = agy_auth_timeout_verdict(out_file)
        if t_severity == "unverifiable":
            _record_auth_unverified(t_detail)
            print(f"agy-turn: NOTE — agy auth is unverifiable headless (expected, via timeout); proceeding. {_AUTH_PROBE_FINDING}",
                  file=sys.stderr)
            print("agy-turn: continuing; the auth probe could not run headless, so it is not a usable "
                  "auth check here. If the turn fails on credentials, run `agy login` in a normal terminal.",
                  file=sys.stderr)
            if os.path.exists(out_file): os.remove(out_file)
            return True
        print(f"agy-turn: agy auth pre-flight timed out after {secs}s; {t_detail}. Run `agy login` in a normal terminal, then retry.", file=sys.stderr)
'''
AGY_OLD = '''        print(f"agy-turn: agy auth pre-flight timed out after {secs}s; likely expired auth opening an interactive login. Run `agy login` in a normal terminal, then retry.", file=sys.stderr)
'''

CONSULT_NEW = '''        t_severity, t_detail = agy_auth_timeout_verdict(tmp)
        if t_severity == "unverifiable":
            with open(log_file, "a") as f:
                if os.path.exists(tmp):
                    with open(tmp) as tf: f.write(tf.read())
                f.write(f"\\nconsult: WARNING — {t_detail}. Proceeding; if agy fails on credentials, "
                        f"run `agy login` in a normal terminal.\\n")
            if os.path.exists(tmp): os.remove(tmp)
            return True
        with open(log_file, "a") as f:
            if os.path.exists(tmp):
                with open(tmp) as tf: f.write(tf.read())
            f.write(f"\\nconsult: agy auth pre-flight timed out after {secs}s; {t_detail}. Run `agy login` in a normal terminal, then retry.\\n")
'''
CONSULT_OLD = '''        with open(log_file, "a") as f:
            if os.path.exists(tmp):
                with open(tmp) as tf: f.write(tf.read())
            f.write(f"\\nconsult: agy auth pre-flight timed out after {secs}s; likely expired auth opening an interactive login. Run `agy login` in a normal terminal, then retry.\\n")
'''

for path, new, old, name in ((sys.argv[1], AGY_NEW, AGY_OLD, "agy-turn.py"),
                             (sys.argv[2], CONSULT_NEW, CONSULT_OLD, "consult.py")):
    p = pathlib.Path(path); s = p.read_text()
    assert new in s, f"{name}: post-fix timeout block not found — the replay would be vacuous"
    p.write_text(s.replace(new, old, 1))
print("PATCHED")
PY
for f in agy-turn consult; do
  python3 -m py_compile "$FIXH/utils/py/$f.py" 2>/dev/null \
    && pass "control: the pre-fix $f.py replay is valid Python (a control that cannot compile proves nothing)" \
    || fail "control: the pre-fix $f.py replay does not compile — the replacement cut a block"
done

# Drive each caller's pre-flight directly with a stub `agy` that prints the TTY line and then hangs
# past the timeout — the exact live shape.
STUB="$WORK/agy-hang"
cat > "$STUB" << STUB_EOF
#!/usr/bin/env bash
printf '%s\n' '$TTY_LINE'
sleep 30
STUB_EOF
chmod +x "$STUB"

run_preflight() {  # <utils-py-dir> <caller> -> prints "True"/"False"
  local pydir="$1" caller="$2"
  if [ "$caller" = agy ]; then
    PYTHONPATH="$pydir" AGY_AUTH_TIMEOUT_S=2 python3 -c '
import importlib.util, sys, os
spec = importlib.util.spec_from_file_location("agyturn", os.path.join(sys.argv[1], "agy-turn.py"))
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
print(m.agy_auth_preflight(sys.argv[2]))' "$pydir" "$STUB" 2>/dev/null
  else
    PYTHONPATH="$pydir" AGY_AUTH_TIMEOUT_S=2 python3 -c '
import importlib.util, sys, os
spec = importlib.util.spec_from_file_location("consultmod", os.path.join(sys.argv[1], "consult.py"))
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
print(m.agy_auth_preflight(sys.argv[2], sys.argv[3]))' "$pydir" "$STUB" "$WORK/consult-pf.log" 2>/dev/null
  fi
}

for caller in agy consult; do
  # `|| true` so a crashing pre-flight is reported by the assertion below rather than aborting the
  # file under `set -e` with no message at all — which is how the consult IndentationError above hid.
  pre="$(run_preflight "$FIXH/utils/py" "$caller" || true)"
  [ "$pre" = "False" ] \
    && pass "control: pre-fix $caller pre-flight BLOCKS a TTY-diagnosed timeout (the defect, observed)" \
    || fail "control: pre-fix $caller did not reproduce the block (got '$pre') — the assertions above prove nothing"
  post="$(run_preflight "$ROOT_REPO/utils/py" "$caller" || true)"
  [ "$post" = "True" ] \
    && pass "post-fix $caller pre-flight proceeds on the same fixture" \
    || fail "post-fix $caller still blocks a TTY-diagnosed timeout (got '$post')"
done

# ── the probe budget must clear the probe's own measured cost, with room for load ───────────
# The flush race is what a too-tight budget looks like from the inside: the probe is killed before it
# can write the diagnostic the reclassification above needs, so a TTY failure degrades into a silent
# one and blocks the lane. Fixing the branch without fixing the margin left that live, and it fired.
#
# Asserted against the MEASURED worst probe cost rather than a number that looks tidy — the #457 rule,
# reused. If `agy whoami` gets slower, or someone trims the default, this fails and says which.
budget="$(python3 -c 'import rtl; print(rtl.AGY_AUTH_TIMEOUT_DEFAULT_S)')"
worst="$(python3 -c 'import rtl; print(rtl.WORST_OBSERVED_WHOAMI_S)')"
ratio="$(python3 -c "print(f'{$budget/$worst:.1f}')")"
python3 -c "import sys; sys.exit(0 if $budget >= 4*$worst else 1)" \
  && pass "the auth-probe budget (${budget}s) clears 4x the worst measured probe cost (${worst}s) — ${ratio}x headroom, where 5s gave under 2x and lost the lane twice" \
  || fail "the auth-probe budget (${budget}s) is under 4x the worst measured cost (${worst}s) — this is the margin whose closure produced the flush race"

# Both callers must read the shared default; a second hardcoded 5 would reintroduce the drift silently.
for f in utils/py/agy-turn.py utils/py/consult.py; do
  if grep -q 'AGY_AUTH_TIMEOUT_S", 5)' "$ROOT_REPO/$f"; then
    fail "$f still hardcodes a 5s probe budget instead of the shared AGY_AUTH_TIMEOUT_DEFAULT_S"
  else
    pass "$(basename "$f") reads the shared AGY_AUTH_TIMEOUT_DEFAULT_S, so the two callers cannot drift"
  fi
done

echo "gh375-auth-timeout-verdict: $PASS pass, $FAIL fail"
