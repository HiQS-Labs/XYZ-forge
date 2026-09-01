#!/usr/bin/env bash
# gh365-driver-lane-registry.sh — GH-365 step 3: the driver-lock lane is an audited registry, not
# a hand-list trusted by inspection.
#
# THE COUNTEREXAMPLE THIS CLOSES (PR #367): gh346-gateway-allowlists.sh invokes the REAL
# marathon driver (direct `python3 utils/py/marathon_drive.py` — the invocation shape the GH-195
# blind-spot taught this repo to stop missing) but was not in DRIVER_LOCK_LANE. Under the
# parallel pool its three probes burned ~36s retrying the contended lock and then labeled the
# routing assertions SKIP while the suite exited GREEN — a contention-induced coverage skip that
# a campaign would have read as equivalence.
#
# THE CONTRACT: the driver lock is per-clone (.git/relay-driver.lock, GH-42/GH-448) and is taken
# BEFORE argument parsing, so a suite that invokes the SHIPPED driver without pointing
# MARATHON_ROOT at a fixture contends with every other driver caller. validate.sh serializes
# exactly those suites in DRIVER_LOCK_LANE. Membership cannot be verified by reading it (gh322,
# gh391), so this suite audits it BIDIRECTIONALLY, GH-306-style:
#   D1  every lane member exists on disk and is registered in TESTS;
#   D2  every suite that references the shipped drivers outside comments is either in the lane
#       or on the EXEMPT map below, each entry naming WHERE its lock resolves (a fixture root,
#       a copied harness, or text-analysis-only). An unexplained real-driver caller is refused —
#       that is the "cannot silently remain pooled" red control;
#   D3  the fix itself: gh346-gateway-allowlists.sh is in the lane;
#   D4  RED control: a planted suite invoking the shipped driver with no exemption is NAMED by
#       the same scanner this suite runs over the real tree (the detector, not a claim).
source "$(dirname "$0")/_setup.sh" gh365-driver-lane-registry
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"

echo "== test: gh365-driver-lane-registry =="

# The lane registry, parsed out of validate.sh exactly the way ci-local.sh parses TESTS — the
# list cannot drift from its single source of truth.
LANE="$(sed -n '/^DRIVER_LOCK_LANE=/s/^DRIVER_LOCK_LANE="//p' "$REPO/validate.sh" | tr -d '"')"
[ -n "$LANE" ] || fail "could not parse DRIVER_LOCK_LANE from validate.sh"
TESTS_TEXT="$(sed -n '/^TESTS=(/,/^)/p' "$REPO/validate.sh")"

in_lane()   { case " $LANE " in *" $1 "*) return 0 ;; esac; return 1; }
in_tests()  { grep -q "\"$1\"" <<<"$TESTS_TEXT"; }

# D3 — the #367 counterexample is closed.
if in_lane gh346-gateway-allowlists.sh; then
  pass "D3: gh346-gateway-allowlists.sh runs in the serialized driver-lock lane (no contention-SKIP)"
else
  fail "D3: gh346-gateway-allowlists.sh is NOT in DRIVER_LOCK_LANE — its routing assertions can still SKIP green under contention (PR #367 counterexample)"
fi

# D1 — lane hygiene: members exist and are registered.
_l_bad=0
for t in $LANE; do
  [ -f "$REPO/test/$t" ] || { fail "D1: lane member test/$t does not exist"; _l_bad=1; continue; }
  in_tests "$t" || { fail "D1: lane member $t is not registered in validate.sh TESTS"; _l_bad=1; }
done
[ "$_l_bad" -eq 0 ] && pass "D1: all lane members exist and are registered ($(wc -w <<<"$LANE" | tr -d ' ') suites)"

# ── the scanner (D2/D4 share it) ─────────────────────────────────────────────────────────────────
# Fires on EXECUTION shapes and bare ASSIGNMENTS of shipped-driver paths, decided in-process
# (bash case globs — no per-line subprocess fan-out). Mention-only lines (a path inside a grep
# pattern, a pass/fail message, a classifier fixture argument) do not fire; a same-line
# fixture/stub marker ($WORK/$A/$MROOT/$d/$h/$F, STUB, MARATHON_RELAY_DRIVE=) suppresses the
# line. The same-line marker is deliberately coarse: it is the cheap edge, the EXEMPT map below
# is the audit of record (runtime isolation via a LATER MARATHON_ROOT export — e.g. gh115 line
# 148 — is exactly the kind of knowledge that belongs in a cited exemption, not in a regex).
scan_driver_refs() {  # <dir> -> prints "<suite>\t<line>" for each real-driver reference
  local dir="$1" f b n line fire hits
  for f in "$dir"/*.sh; do
    [ -f "$f" ] || continue
    hits=""
    n=0
    while IFS= read -r line; do
      n=$(( n + 1 ))
      case "$line" in '#'*) continue ;; esac
      case "$line" in
        *relay-drive.sh*|*marathon-drive.sh*|*relay_drive.py*|*marathon_drive.py*) ;;
        *) continue ;;
      esac
      fire=0
      case "$line" in
        # exec shapes: interpreter then the shipped path (Bash twin + direct Python — the two
        # shapes GH-195 proved an audit must both recognize)
        bash\ *relay-drive.sh*|bash\ *marathon-drive.sh*|bash\ \"*relay-drive.sh*|bash\ \"*marathon-drive.sh*) fire=1 ;;
        *\ bash\ *relay-drive.sh*|*\ bash\ *marathon-drive.sh*|*\ bash\ \"*relay-drive.sh*|*\ bash\ \"*marathon-drive.sh*) fire=1 ;;
        sh\ *relay-drive.sh*|source\ *relay-drive.sh*) fire=1 ;;
        python3\ *marathon_drive.py*|python3\ *relay_drive.py*|python3\ \"*marathon_drive.py*|python3\ \"*relay_drive.py*) fire=1 ;;
        *\ python3\ *marathon_drive.py*|*\ python3\ *relay_drive.py*|*\ python3\ \"*marathon_drive.py*|*\ python3\ \"*relay_drive.py*) fire=1 ;;
        # bare assignment of a shipped path (quoted, or via a repo-root expansion — \$VARS are
        # backslash-escaped so they match the literal '$ROOT/...' text rather than expanding)
        [A-Za-z_]*=\"*relay-drive.sh|[A-Za-z_]*=\"*marathon-drive.sh|[A-Za-z_]*=\"*marathon_drive.py|[A-Za-z_]*=\"*relay_drive.py) fire=1 ;;
        [A-Za-z_]*=\$ROOT*relay-drive.sh|[A-Za-z_]*=\$ROOT*marathon-drive.sh|[A-Za-z_]*=\$ROOT*marathon_drive.py|[A-Za-z_]*=\$ROOT*relay_drive.py) fire=1 ;;
        [A-Za-z_]*=\$REPO*relay-drive.sh|[A-Za-z_]*=\$REPO*marathon-drive.sh|[A-Za-z_]*=\$REPO*marathon_drive.py|[A-Za-z_]*=\$REPO*relay_drive.py) fire=1 ;;
        [A-Za-z_]*=\$ROOT_DIR*relay-drive.sh|[A-Za-z_]*=\$ROOT_REPO*relay-drive.sh|[A-Za-z_]*=\$ROOT_REPO*marathon-drive.sh|[A-Za-z_]*=\$REPO_ROOT*marathon-drive.sh) fire=1 ;;
      esac
      [ "$fire" = 1 ] || continue
      case "$line" in
        *'$WORK'*|*STUB*|*[Ss]tub*|*'$A'*|*'$MROOT'*|*'$d'*|*'$h'*|*'$F'*|*MARATHON_RELAY_DRIVE=*) continue ;;
      esac
      hits="$hits$n "
    done < "$f"
    [ -n "$hits" ] || continue
    b="$(basename "$f")"
    for n in $hits; do printf '%s\t%s\n' "$b" "$n"; done
  done
}

# The audited EXEMPT map: suite -> where its lock resolves. Every entry was verified against the
# suite's own invocation lines (the exec carries MARATHON_ROOT=<fixture> or drives a copy).
EXEMPT_reason() {
  case "$1" in
    debug-mantra.sh)                        echo "fixture root: MARATHON_ROOT=\$A at the exec (line 27)" ;;
    driver-lock.sh)                         echo "fixture root: MARATHON_ROOT=\$A at the exec (line 25)" ;;
    gh115-round-cap.sh)                     echo "fixture root: MARATHON_ROOT=\$A (line 148, the GH-115 self-fix)" ;;
    gh268-relay-cue-and-target-checks.sh)   echo "fixture root: MARATHON_ROOT=\$MROOT at the execs (lines 166/194)" ;;
    gh273-marathon-root-audit-python-shape.sh) echo "fixture root: MARATHON_ROOT=\$WORK on all 11 real invocations; the two firing lines are a text-analysis heredoc and a \$WT fixture-harness copy" ;;
    gh376-relay-drive-lock-parity.sh)          echo "copied fixture harness: drives \$WT/\$PRE copies, not the shipped tree; shipped twins only parsed (bash -n / ast.parse), never executed" ;;
    lane-attempt-cap.sh)                       echo "parse-only: bash -n syntax checks of the twins; the driver is never executed" ;;
    gh280-jog-marathon-adapter.sh)          echo "stub drivers under \$WORK only; its P-section static tripwire forbids real-driver escapes" ;;
    archive-writers.sh)                     echo "text-analysis only: check_writer() greps the twins' SOURCE for the rtl_transcript_root contract (lines 85-86); never executes them" ;;
    gh284-runlog-heartbeat.sh)              echo "fixture root: MARATHON_ROOT=\$A + MARATHON_RELAY_DRIVE stub at every exec (run_driver, line 51)" ;;
    marathon-drive.sh)                      echo "fixture root: MARATHON_ROOT=\$A at the execs (lines 51/264/380)" ;;
    gh307-gate-env-scrub.sh)                echo "text-analysis only: reads the twins' source via python3 - <file> heredocs; never executes the driver" ;;
    gh314-transcript-writeset.sh)           echo "fixture root: MARATHON_ROOT=\$d (line 78)" ;;
    gh319-gate-path-with-space.sh)          echo "fixture root: MARATHON_ROOT=\$WORK + \$WORK stub driver" ;;
    gh322-runlog-python-lane.sh)            echo "fixture root: MARATHON_ROOT=\$WORK (3 sites) + \$WORK stub" ;;
    gh342-sentinel-debug-log-python.sh)     echo "fixture root: MARATHON_ROOT=\$A (line 325); twins also read as text" ;;
    gh376-relay-drive-lock-parity.sh)       echo "copied fixture harness: invokes relay_drive.py from \$h (a copy), not the shipped tree" ;;
    gh387-gate-not-first-executor.sh)       echo "fixture root: MARATHON_ROOT=\$A + MARATHON_RELAY_DRIVE stub (lines 116/175)" ;;
    gh388-run-log-durability.sh)            echo "fixture root: MARATHON_ROOT=\$A (lines 201/294)" ;;
    gh390-gate-guard.sh)                    echo "fixture root: MARATHON_ROOT=\$WORK + \$WORK stub" ;;
    gh401-dry-run-no-mutation.sh)           echo "fixture root: MARATHON_ROOT=\$MROOT (line 45)" ;;
    gh402-branch-enforcement.sh)            echo "fixture root: MARATHON_ROOT=\$WORK (4 sites)" ;;
    gh407-gate-ran-attribution.sh)          echo "fixture root: MARATHON_ROOT=\$WORK + stubs" ;;
    *)                                      return 1 ;;
  esac
}

# D2 — every real-driver reference is lane-listed or audited.
_unexplained="$(scan_driver_refs "$REPO/test" | cut -f1 | sort -u | while IFS= read -r s; do
  in_lane "$s" && continue
  EXEMPT_reason "$s" >/dev/null && continue
  printf '%s\n' "$s"
done)"
if [ -z "$_unexplained" ]; then
  _n_exempt="$(scan_driver_refs "$REPO/test" | cut -f1 | sort -u | while IFS= read -r s; do
    in_lane "$s" || EXEMPT_reason "$s" >/dev/null || true
  done | wc -l | tr -d ' ')"
  pass "D2: every shipped-driver reference is lane-serialized or carries an audited exemption reason"
else
  while IFS= read -r s; do
    fail "D2: $s references the shipped driver with NO lane membership and NO audited exemption — add it to DRIVER_LOCK_LANE (it contends) or to the EXEMPT map with where its lock resolves"
  done <<<"$_unexplained"
fi

# D4 — RED control: the same scanner names a planted, unexempted, real-driver caller.
PLANT="$WORK/planted"
mkdir -p "$PLANT"
require_fixture "$PLANT" "planted-driver-caller dir"
printf '#!/usr/bin/env bash\npython3 "$ROOT/utils/py/marathon_drive.py" --phase-brief brief.md --dry-run\nbash "$ROOT/relay-automation/relay-drive.sh" --help\n' \
  > "$PLANT/planted-driver-caller.sh"
_caught="$(scan_driver_refs "$PLANT" | cut -f1 | sort -u)"
if grep -qx "planted-driver-caller.sh" <<<"$_caught"; then
  pass "D4 RED: a newly written real-driver caller (both invocation shapes) is NAMED by the scanner — it cannot silently remain pooled"
else
  fail "D4 RED: scanner missed the planted driver caller (got: '${_caught:-none}') — the guard is blind"
fi
# ...and the control's control: the same file WITH a fixture marker is not flagged (no overreach).
printf '#!/usr/bin/env bash\nMARATHON_ROOT="$WORK/m" python3 "$ROOT/utils/py/marathon_drive.py" --phase-brief brief.md --dry-run\n' \
  > "$PLANT/planted-fixture-caller.sh"
if ! grep -qx "planted-fixture-caller.sh" <<<"$(scan_driver_refs "$PLANT" | cut -f1 | sort -u)"; then
  pass "D4 CONTROL: a fixture-rooted caller is NOT flagged (the detector keys on real-clone lock resolution)"
else
  fail "D4 CONTROL: detector overreaches — a MARATHON_ROOT=\$WORK caller was flagged"
fi

echo "== gh365-driver-lane-registry: $PASS passed, $FAIL failed =="
[ "$FAIL" -eq 0 ] || exit 1
exit 0
