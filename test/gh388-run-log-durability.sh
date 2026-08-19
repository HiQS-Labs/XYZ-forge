#!/usr/bin/env bash
# GH-388 — the phase that fails must not be the one phase with no record.
#
# THE FAILURE MODE GUARANTEES THE ABSENCE OF THE RECORD, which is why a green suite proves nothing
# here: everything already works on the success path. Per-phase transcripts are written when a phase
# COMPLETES, so the phase that dies is the one with no transcript, and the chain-level narrative
# existed only on the operator's terminal. In the run that produced this issue, phases 1-4 each have
# a transcript, phase 5 killed the host, and the only surviving account of it was a terminal stream
# redirected to a path the platform clears at boot. After the reboot it was gone.
#
# So this file KILLS a phase and asserts on what is left behind. Three properties, and the second is
# the one a naive fix misses:
#   1. a chain-level run log exists, is durable, and was announced at chain start
#   2. the killed phase left a CONTENT-BEARING record — created after that phase started, naming the
#      phase id, the relay state at interruption, and the reason. An empty or pre-created file was a
#      real hole in the first draft of these criteria and is asserted against directly.
#   3. `rtl_default_log` no longer silently relocates a transcript to storage a reboot erases
#
# Usage: bash test/gh388-run-log-durability.sh
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$HERE/.." && pwd)"
# shellcheck source=/dev/null
source "$HERE/_setup.sh" gh388-run-log-durability
PY="${PYTHON:-python3}"

# ---------------------------------------------------------------------------
# Part A — the non-durable registry is ONE file, read by BOTH lanes
# ---------------------------------------------------------------------------
echo "-- A: one registry, two readers, same verdict"

CONF="$ROOT_DIR/relay-automation/non-durable-log-roots.conf"
[ -f "$CONF" ] && pass "the registry file exists ($(basename "$CONF"))" \
               || fail "GH-388 criterion 5: no single place states the non-durable locations"

# shellcheck source=/dev/null
source "$ROOT_DIR/relay-automation/durable-log-lib.sh"

# Both readers must agree. Two hardcoded lists would satisfy "stated in one place" on paper and drift
# in practice — this is what keeps the claim true, and it is the assertion that fails first if
# someone later inlines a copy into either lane.
disagreed=""
for p in /tmp/x.log /private/tmp/x /var/tmp/y /dev/shm/z "$ROOT_DIR/relay-system/logs/a.log" /usr/local/share/keepme; do
  bash_reason="$(xyz_non_durable_reason "$p")"
  py_reason="$("$PY" -c "
import sys; sys.path.insert(0, '$ROOT_DIR/utils/py'); import rtl
print(rtl.non_durable_reason('$p'))")"
  bash_verdict=$([ -n "$bash_reason" ] && echo NON-DURABLE || echo DURABLE)
  py_verdict=$([ -n "$py_reason" ] && echo NON-DURABLE || echo DURABLE)
  [ "$bash_verdict" = "$py_verdict" ] || disagreed="$disagreed $p(bash=$bash_verdict,py=$py_verdict)"
done
[ -z "$disagreed" ] \
  && pass "the Bash and Python readers agree on every probe path" \
  || fail "GH-388: the two lanes disagree about durability —$disagreed"

# The over-match guard: ordinary durable storage must classify DURABLE, or the registry would be
# condemning everything and the /tmp assertion below would pass for the wrong reason.
#
# GH-37: the probe is a FIXED absolute path, derived from no environment variable at all. A clone's
# location is not a property of the harness — cloning into $TMPDIR is a legitimate throwaway pattern
# (an agent validating a PR did exactly that), and the classifier calling that clone ephemeral is the
# CORRECT answer, not a defect. Asserting on $ROOT_DIR made a green suite depend on where someone
# happened to clone, turning a right answer into a red gate that blocked unrelated work at the push
# boundary.
#
# $HOME is NOT the fix and was rejected during this change: a container or CI runner with
# HOME=/tmp/runner reproduces the identical spurious failure, having moved the environment-dependence
# rather than removed it. Only a literal path outside every registry prefix tests the registry itself.
# This is the same durable representative the two-reader agreement loop above already probes.
DURABLE_PROBE=/usr/local/share/keepme
xyz_path_is_durable "$DURABLE_PROBE/relay-system/logs/a.log" \
  && pass "a fixed path on durable storage is classified durable (the registry does not over-match)" \
  || fail "$DURABLE_PROBE was classified non-durable — the registry condemns ordinary storage"
xyz_path_is_durable /tmp/whatever \
  && fail "/tmp was classified DURABLE — the registry is not being read" \
  || pass "/tmp is classified non-durable"

# This clone's own root is REPORTED, never asserted. Both outcomes are correct classifications, and
# the ephemeral one is precisely the warning GH-388 exists to surface: evidence written into a
# throwaway clone does not survive the reboot that makes you want to read it.
if xyz_path_is_durable "$ROOT_DIR/relay-system/logs/a.log"; then
  pass "this clone's transcript root is on durable storage"
else
  pass "this clone is on EPHEMERAL storage ($(xyz_non_durable_reason "$ROOT_DIR")) — correctly classified; evidence written here will not survive a reboot"
fi

# The registry is data, not code: adding a line must change the verdict. Without this the conf file
# could be a decorative artifact while the real list lives in the readers.
TMPCONF="$WORK/conf-probe"
mkdir -p "$TMPCONF/relay-automation"
cp "$ROOT_DIR/relay-automation/durable-log-lib.sh" "$TMPCONF/relay-automation/"
printf '/an-invented-volatile-root\n' >"$TMPCONF/relay-automation/non-durable-log-roots.conf"
probe="$(cd "$TMPCONF" && bash -c 'source relay-automation/durable-log-lib.sh; xyz_non_durable_reason /an-invented-volatile-root/x')"
[ "$probe" = "/an-invented-volatile-root" ] \
  && pass "the registry is genuinely read at runtime (an invented entry changes the verdict)" \
  || fail "adding an entry to the registry changed nothing — the real list is hardcoded somewhere (got: '$probe')"

# ---------------------------------------------------------------------------
# Part B — rtl_default_log refuses instead of silently relocating
# ---------------------------------------------------------------------------
echo "-- B: a misconfigured archive root refuses, rather than quietly writing to volatile storage"

# XYZ_ARCHIVE_ROOT that is not a git repo → rtl_transcript_root returns nothing. Pre-fix, BOTH lanes
# answered with a $TMPDIR path and said nothing at all.
BADARCH="$WORK/not-a-git-repo"
mkdir -p "$BADARCH"

set +e
py_out="$(XYZ_ARCHIVE_ROOT="$BADARCH" "$PY" -c "
import sys; sys.path.insert(0, '$ROOT_DIR/utils/py'); import rtl
print(rtl.rtl_default_log('$A', 'agy-turn', 'T-1'))" 2>&1)"
py_rc=$?
set -e
if [ "$py_rc" -ne 0 ]; then
  pass "python lane REFUSES on an unusable archive root (exit $py_rc)"
else
  fail "GH-388: python lane returned a path instead of refusing — got: $py_out"
fi
case "$py_out" in
  *"$WORK"*|*TMPDIR*|*/tmp/*|*/var/folders/*)
    # Only a failure if it was RETURNED as the transcript path; in the refusing case the temp path
    # must not appear as an answer at all.
    [ "$py_rc" -eq 0 ] && fail "GH-388: the returned transcript path is in volatile storage: $py_out" ;;
esac
case "$py_out" in
  *"not a git repo"*|*"XYZ_ARCHIVE_ROOT"*)
    pass "the refusal names WHY the root did not resolve (the resolver's stderr is no longer swallowed)" ;;
  *) fail "the refusal did not explain the cause — got: $py_out" ;;
esac

set +e
bash_out="$(XYZ_ARCHIVE_ROOT="$BADARCH" bash -c "
source '$ROOT_DIR/relay-automation/relay-turn-lib.sh' >/dev/null 2>&1
rtl_default_log '$A' agy-turn T-1" 2>&1)"
bash_rc=$?
set -e
[ "$bash_rc" -ne 0 ] \
  && pass "bash lane REFUSES on the same input (exit $bash_rc)" \
  || fail "GH-388: bash lane returned '$bash_out' instead of refusing — the lanes disagree"

# The other direction, and it is load-bearing: a WORKING configuration must still return a path.
# A "fix" that refuses everything passes every assertion above and breaks every turn in the fleet.
set +e
ok_out="$("$PY" -c "
import sys; sys.path.insert(0, '$ROOT_DIR/utils/py'); import rtl
print(rtl.rtl_default_log('$A', 'agy-turn', 'T-1'))" 2>/dev/null)"
ok_rc=$?
set -e
if [ "$ok_rc" -eq 0 ] && [ -n "$ok_out" ]; then
  pass "a healthy default (no XYZ_ARCHIVE_ROOT) still resolves: ${ok_out#"$A"/}"
else
  fail "the durability guard broke the normal path — rc=$ok_rc out=$ok_out"
fi
case "$ok_out" in
  "$A"/relay-system/*) pass "and it resolves under the repo's own relay-system, unchanged" ;;
  *) fail "the healthy path moved: $ok_out" ;;
esac

# ---------------------------------------------------------------------------
# Part C — a KILLED phase leaves a content-bearing record
# ---------------------------------------------------------------------------
echo "-- C: kill a phase mid-run; assert what survives"

# A phase that never finishes. The stub blocks, the driver is signalled, and the question is whether
# anything durable is left behind naming what was happening.
DRIVE="$ROOT_DIR/relay-automation/marathon-drive.sh"
printf 'STATUS: Open\n# relay body\n' >"$A/relay.md"
printf '.tick/\n' >"$A/.gitignore"
git -C "$A" add relay.md .gitignore >/dev/null 2>&1
git -C "$A" commit -q -m "seed" >/dev/null 2>&1
mkdir -p "$A/PROJECT/2-WORKING"
printf '# brief\n\nDo the thing.\n' >"$A/PROJECT/2-WORKING/brief.md"

HANG="$WORK/hang-agent"
cat >"$HANG" <<'HANG_EOF'
#!/usr/bin/env bash
# A builder that starts, writes a round into the relay file, and then never returns.
printf '\n### Round 1 · Builder · %s\npartial work, interrupted\n' "${RELAY_AGENT:-builder}" >>"$RELAY_FILE"
sleep 300
HANG_EOF
chmod +x "$HANG"

# GH-232, walked into again. `marathon_drive.py` probes the REVIEWER binary (CODEX_BIN, default
# `codex`) before anything else runs, so with no `codex` on PATH the driver fail-fasts, the phase
# never reaches dispatch, and part C reports "did not reproduce" — which is true, but about the
# probe rather than about the interruption under test. This file stubbed the builder and not the
# reviewer, so it passed on a developer machine (a real `codex` is installed there) and went red on
# ubuntu CI: the exact failure mode ci.yml already documents.
REVIEWER_STUB="$WORK/reviewer-stub"
printf '#!/usr/bin/env bash\nexit 0\n' >"$REVIEWER_STUB"
chmod +x "$REVIEWER_STUB"
export CODEX_BIN="$REVIEWER_STUB"

PHASES="$A/marathon-system"

# Launch the driver in its OWN SESSION, and this is not incidental tidiness. The first version
# backgrounded it normally and the test itself exited 143: the driver's teardown signals its process
# GROUP, and a plain `&` leaves it sharing this script's group, so killing the phase killed the
# thing doing the killing. `setsid` is not on macOS, so os.setsid() via python is the portable form.
# It also means the `sleep 300` builder cannot outlive the case and wedge the suite.
set +e
XYZ_PYTHON=1 MARATHON_ROOT="$A" TICK_REPO_ROOT="$A" TICK_BIN="$TICK" \
  CLAUDE_BIN="$HANG" CLAUDE_TURN_ROOT="$A" RELAY_AGENT=claude-builder \
  "$PY" -c 'import os,sys; os.setsid(); os.execvp(sys.argv[1], sys.argv[1:])' \
    bash "$DRIVE" --phase-id killme --reviewer codex --builder claude \
    --phase-brief "$A/PROJECT/2-WORKING/brief.md" --round-cap 3 --phases-dir "$PHASES" \
    --pre-advance-cmd true >"$WORK/drive.out" 2>&1 &
drive_pid=$!
# NOT `set -e` here. An earlier draft restored it and the whole file exited 143 at the `wait` below —
# a killed child returns 128+SIGTERM, which under `set -e` terminates the waiter with that status.
# The test read as "something killed the test", which is the wrong story about the right number.
set +e

# Wait for the phase to be genuinely under way — never a fixed sleep, which would race on a loaded
# machine and silently turn this whole section into a no-op.
started=0
for _ in $(seq 1 120); do
  if /usr/bin/grep -q "phase start" "$WORK/drive.out" 2>/dev/null; then
    started=1; break
  fi
  sleep 0.5
done

if [ "$started" -eq 1 ]; then
  pass "the phase reached dispatch, so the kill below lands mid-run"
  # Stamped at the moment dispatch is confirmed, so "written after the phase started" is measured
  # against the phase actually starting rather than against some input file that happens to be old.
  # The first draft compared against the brief and failed on a filesystem with coarse mtimes; this
  # compares against a marker created in the same run, seconds before the kill.
  touch "$WORK/phase-started.marker"
  # macOS ships bash 3.2, whose `-nt` compares WHOLE SECONDS. Without this pause the marker and the
  # interrupted-phase record land in the same second, `-nt` reports false, and the test accuses a
  # correct fix of pre-creating the file. The pause is the difference between the assertion meaning
  # "written after the phase started" and meaning "written in a later second than the marker".
  sleep 1.5
  kill -TERM "$drive_pid" 2>/dev/null || true
  wait "$drive_pid" 2>/dev/null; kill_rc=$?
  # The driver is a session leader (see the launch above), so its whole tree — relay-drive, the turn
  # shim, the sleeping stub — is reachable by negating the pid. Without this the `sleep 300` outlives
  # the case. Errors ignored: a clean shutdown leaves nothing to signal.
  kill -TERM -"$drive_pid" 2>/dev/null || true

  rec="$PHASES/killme/PHASE-INTERRUPTED.md"
  if [ -f "$rec" ]; then
    pass "the killed phase left a record ($(basename "$rec"))"
    # CONTENT, not existence. An empty or pre-created file satisfied the first draft of the criteria.
    /usr/bin/grep -q "^phase: killme" "$rec" \
      && pass "the record names the phase id" \
      || fail "GH-388: the record does not name the phase — $(cat "$rec")"
    /usr/bin/grep -q "^relay-status:" "$rec" \
      && pass "the record carries the relay state at interruption" \
      || fail "GH-388: the record does not carry the relay state — $(cat "$rec")"
    /usr/bin/grep -qE "^reason: .+" "$rec" \
      && pass "the record names a reason" \
      || fail "GH-388: the record has no reason — $(cat "$rec")"
    [ -s "$rec" ] \
      && pass "the record is non-empty" \
      || fail "GH-388: the record is empty, which is the loophole this criterion was rewritten to close"
    # Created AFTER the phase started, not pre-seeded. An empty or pre-created file satisfied the
    # criterion's first wording, which is why this is asserted rather than assumed.
    if [ "$rec" -nt "$WORK/phase-started.marker" ]; then
      pass "the record was written after the phase began (not pre-created)"
    else
      fail "GH-388: the record is not newer than a marker stamped after dispatch — it may be a pre-created stub"
    fi
  else
    fail "GH-388: a phase killed mid-run left NO record in $PHASES/killme (dir: $(ls -1 "$PHASES/killme" 2>/dev/null | tr '\n' ' '))"
  fi
else
  fail "part C did not reproduce: the phase never reached dispatch, so nothing was killed mid-run.
--- driver output ---
$(cat "$WORK/drive.out")
--- phases tree ---
$(find "$PHASES" -maxdepth 2 2>/dev/null)"
  kill -TERM "$drive_pid" 2>/dev/null || true
  wait "$drive_pid" 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# Part D — the CHAIN run log (marathon.sh), which is what the issue is named for
# ---------------------------------------------------------------------------
echo "-- D: the chain run log survives a chain that never finishes"

MARATHON="$ROOT_DIR/relay-automation/marathon.sh"
cat >"$A/PROJECT/2-WORKING/PLAN.yaml" <<'PLAN_EOF'
name: gh388-probe
phases:
  - id: neverends
    reviewer: codex
    brief: PROJECT/2-WORKING/brief.md
    max_review_rounds: 1
PLAN_EOF

set +e
XYZ_PYTHON=1 MARATHON_ROOT="$A" TICK_REPO_ROOT="$A" TICK_BIN="$TICK" \
  CLAUDE_BIN="$HANG" CLAUDE_TURN_ROOT="$A" \
  "$PY" -c 'import os,sys; os.setsid(); os.execvp(sys.argv[1], sys.argv[1:])' \
    bash "$MARATHON" --plan "$A/PROJECT/2-WORKING/PLAN.yaml" --builder claude \
    --pre-advance-cmd true >"$WORK/chain.out" 2>&1 &
chain_pid=$!
set +e

chain_started=0
for _ in $(seq 1 120); do
  /usr/bin/grep -q "run log:" "$WORK/chain.out" 2>/dev/null && { chain_started=1; break; }
  sleep 0.5
done

if [ "$chain_started" -eq 1 ]; then
  pass "the chain announced its run log at start (acceptance: the operator must know where to look)"
  run_log="$(sed -n 's/^marathon: run log: //p' "$WORK/chain.out" | head -n1)"
  [ -n "$run_log" ] && pass "the announced path is parseable: ${run_log#"$A"/}" \
                    || fail "the run-log announcement carried no path"

  case "$run_log" in
    "$A"/relay-system/run-logs/*)
      pass "the run log lives under the same transcript root as the per-phase transcripts" ;;
    *)
      fail "GH-388: the run log is not under the transcript root — got: $run_log" ;;
  esac

  # Wait for the chain to have written something real, then kill it WITHOUT a clean shutdown. The
  # whole claim is "captured as it is produced", and the only way to test that is to take the process
  # away mid-run and see what is on disk.
  for _ in $(seq 1 60); do
    [ -s "$run_log" ] && /usr/bin/grep -q "phase 1/1" "$run_log" 2>/dev/null && break
    sleep 0.5
  done
  kill -TERM "$chain_pid" 2>/dev/null || true
  wait "$chain_pid" 2>/dev/null
  kill -TERM -"$chain_pid" 2>/dev/null || true

  [ -f "$run_log" ] && pass "the run log still exists after the chain was killed" \
                    || fail "GH-388: the run log vanished with the run"
  [ -s "$run_log" ] && pass "the run log is non-empty" \
                    || fail "GH-388: the run log survived but is empty — nothing was captured as produced"
  if /usr/bin/grep -q "phase 1/1: neverends" "$run_log" 2>/dev/null; then
    pass "the run log carries the chain narrative (the phase heading), not just a header"
  else
    fail "GH-388: the run log does not contain the chain's own narrative — content was: $(head -5 "$run_log")"
  fi
else
  fail "part D did not reproduce: the chain never announced a run log.
--- chain output ---
$(cat "$WORK/chain.out")"
  kill -TERM "$chain_pid" 2>/dev/null || true
  wait "$chain_pid" 2>/dev/null
  kill -TERM -"$chain_pid" 2>/dev/null || true
fi

# --dry-run must NOT leave a run log: there is no run to narrate, and an empty log implying one
# happened is its own small lie. This is the guard against "arm the log as early as possible".
rm -rf "$A/relay-system/run-logs"
XYZ_PYTHON=1 MARATHON_ROOT="$A" TICK_REPO_ROOT="$A" TICK_BIN="$TICK" \
  bash "$MARATHON" --plan "$A/PROJECT/2-WORKING/PLAN.yaml" --dry-run >"$WORK/dry.out" 2>&1
if [ -d "$A/relay-system/run-logs" ]; then
  fail "GH-388: --dry-run created a run log — an empty record implying a run that never happened"
else
  pass "--dry-run leaves no run log (nothing ran, so nothing is narrated)"
fi

echo
echo "  $TEST_NAME: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
