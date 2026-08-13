#!/usr/bin/env bash
# relay-turn-trace.sh — GH-161: rtl_trace / rtl_log_always / rtl_default_log instrumentation.
#   (1) rtl_trace  — no-op unless RTL_TRACE=1 AND RTL_LOG is set
#   (2) rtl_log_always — fires whenever RTL_LOG is set, regardless of RTL_TRACE (mirrors an existing
#       unconditional diagnostic; no new gating)
#   (3) rtl_default_log — persistent path under rtl_transcript_root(...)/logs/<date>/, falling back to
#       today's PID-keyed tmp path (byte-identical to the pre-GH-161 default) on any resolver failure
#   (4) end-to-end via codex-turn.sh: RTL_TRACE=1 with no CODEX_LOG set lands trace lines in the
#       persistent transcript, which stays gitignored (never shows up in git status, never committed);
#       RTL_TRACE unset still gets the unconditional rtl_log_always lines but not the fine-grained ones
source "$(dirname "$0")/_setup.sh" relay-turn-trace

LIB="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/relay-turn-lib.sh"
[ -f "$LIB" ] || fail "relay-turn-lib.sh not found at $LIB"
# shellcheck disable=SC1090
source "$LIB"

LOGFILE="$WORK/trace.log"

# --- (1) rtl_trace: no-op with RTL_TRACE unset, even with RTL_LOG set ----------------------------
rm -f "$LOGFILE"; unset RTL_TRACE; RTL_LOG="$LOGFILE"
rtl_trace "should not appear"
[ ! -s "$LOGFILE" ] && pass "rtl_trace: no-op when RTL_TRACE is unset (RTL_LOG set)" || fail "rtl_trace wrote output with RTL_TRACE unset"

# --- (1b) rtl_trace: no-op with RTL_TRACE=1 but RTL_LOG unset -------------------------------------
rm -f "$LOGFILE"; RTL_TRACE=1; unset RTL_LOG
rtl_trace "should not appear either"
[ ! -e "$LOGFILE" ] && pass "rtl_trace: no-op when RTL_LOG is unset (RTL_TRACE=1)" || fail "rtl_trace wrote output with RTL_LOG unset"

# --- (1c) rtl_trace: fires only when BOTH RTL_TRACE=1 and RTL_LOG are set -------------------------
rm -f "$LOGFILE"; RTL_TRACE=1; RTL_LOG="$LOGFILE"
rtl_trace "hello trace"
grep -qF '[trace] hello trace' "$LOGFILE" 2>/dev/null && pass "rtl_trace: fires with RTL_TRACE=1 + RTL_LOG set" || fail "rtl_trace did not write the expected line"

# --- (2) rtl_log_always: fires whenever RTL_LOG is set, REGARDLESS of RTL_TRACE -------------------
rm -f "$LOGFILE"; unset RTL_TRACE; RTL_LOG="$LOGFILE"
rtl_log_always "hello always"
grep -qF '[trace] hello always' "$LOGFILE" 2>/dev/null && pass "rtl_log_always: fires with RTL_TRACE unset (only needs RTL_LOG)" || fail "rtl_log_always did not write with RTL_TRACE unset"

# --- (2b) rtl_log_always: no-op when RTL_LOG is unset ---------------------------------------------
rm -f "$LOGFILE"; unset RTL_LOG
rtl_log_always "should not appear"
[ ! -e "$LOGFILE" ] && pass "rtl_log_always: no-op when RTL_LOG is unset" || fail "rtl_log_always wrote output with RTL_LOG unset"

# --- (2c) neither helper ever fails the turn, even if the log path is unwritable ------------------
RTL_TRACE=1; RTL_LOG="/nonexistent-dir-$$/nope.log"
rtl_trace "unwritable"; rc1=$?
rtl_log_always "unwritable"; rc2=$?
[ "$rc1" -eq 0 ] && [ "$rc2" -eq 0 ] && pass "rtl_trace/rtl_log_always never fail on an unwritable RTL_LOG" || fail "helper returned non-zero on unwritable path (rc1=$rc1 rc2=$rc2)"
unset RTL_TRACE RTL_LOG

# --- (3) rtl_default_log: persistent path under rtl_transcript_root(root)/logs/<date>/ ------------
unset XYZ_ARCHIVE_ROOT
day="$(date +%Y-%m-%d)"
out="$(rtl_default_log "$A" codex-turn RELAY-TURN-1)"
case "$out" in
  "$A/relay-system/logs/$day/codex-turn-RELAY-TURN-1-"*.log) pass "rtl_default_log: persistent path under relay-system/logs/<date>/" ;;
  *) fail "rtl_default_log: unexpected path shape: $out" ;;
esac
[ -d "$(dirname "$out")" ] && pass "rtl_default_log: creates the log directory" || fail "rtl_default_log: log directory was not created"

# --- (3b) rtl_default_log: task name sanitized to a single safe filename segment ------------------
out="$(rtl_default_log "$A" codex-turn "weird task/name with spaces")"
case "$out" in
  *"/"*"weird_task_name_with_spaces-"*.log) pass "rtl_default_log: sanitizes task name for the filename" ;;
  *) fail "rtl_default_log: task name not sanitized: $out" ;;
esac

# --- (3c) rtl_default_log: REFUSES on a resolver failure; it no longer falls back to tmp ----------
#
# INVERTED DELIBERATELY BY GH-388. This case previously asserted the opposite — that a resolver
# failure silently produced `${TMPDIR}/codex-turn-$$.log` and "never propagated the failure to the
# caller". That behaviour was the defect, not a feature: a misconfigured XYZ_ARCHIVE_ROOT relocated
# every turn transcript into the one directory a reboot erases, and said nothing, so the evidence was
# already gone by the time anyone had reason to look for it. A marathon on a 32 GB host panicked
# mid-phase and its only account was written to exactly such a path.
#
# The trade was reversed knowingly: refusing costs a turn that has NOT started, whereas the fallback
# cost the record of a turn that HAD. Adding a warning while still writing to volatile storage was
# considered in the issue's own review and rejected — the logs would still be destroyed, and the
# message would only mean someone could have known.
#
# A relative XYZ_ARCHIVE_ROOT makes rtl_transcript_root hard-error (see archive-root.sh).
out="$(XYZ_ARCHIVE_ROOT="relative/dir" rtl_default_log "$A" codex-turn RELAY-TURN-2 2>"$WORK/dl.err")"
rc=$?
[ "$rc" -ne 0 ] \
  && pass "rtl_default_log: refuses (exit $rc) rather than silently relocating to tmp (GH-388)" \
  || fail "rtl_default_log: returned '$out' on an unresolvable archive root — the tmp fallback is back"
[ -z "$out" ] \
  && pass "rtl_default_log: emits no path at all when it cannot resolve a durable one" \
  || fail "rtl_default_log: emitted a path while refusing: '$out'"
/usr/bin/grep -q "XYZ_ARCHIVE_ROOT" "$WORK/dl.err" \
  && pass "rtl_default_log: the refusal names the cause (the resolver's stderr is no longer swallowed)" \
  || fail "rtl_default_log: refused without explaining why — stderr was: $(cat "$WORK/dl.err")"
unset XYZ_ARCHIVE_ROOT

# ============================================================================================
# (4) end-to-end via codex-turn.sh — real shim, stub codex, no CODEX_LOG override
# ============================================================================================
export TICK_BIN="$TICK"
SHIM="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/codex-turn.sh"
tick_a init >/dev/null

mkdir -p "$A/bin"; ln -sf "$TICK" "$A/bin/tick"
printf 'STATUS: Open\n# relay body\n' >"$A/relay.md"
# Mirror the real repo's GH-161 gitignore entry — the persistent log default MUST stay ignored or it
# would be swept as "off-lane" / re-appear as untracked noise after the turn (see relay-turn-lib.sh's
# rtl_default_log comment and the final RTL_LOG_REL sweep in rtl_enforce).
printf '.tick/\nbin/\nrelay-system/logs/\n' >"$A/.gitignore"
git -C "$A" add relay.md .gitignore >/dev/null 2>&1; git -C "$A" commit -q -m "seed relay" >/dev/null 2>&1

STUB="$WORK/codex"
cat >"$STUB" <<'STUB_EOF'
#!/usr/bin/env bash
set -u
export TICK_REPO_ROOT="$A"
"$TICK" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths "z/**" >/dev/null 2>&1
"$TICK" ping  "$RELAY_TASK" --agent "$RELAY_AGENT" >/dev/null 2>&1
printf '\n### Round 1 · Reviewer · %s (codex-stub)\n**Verdict:** Changes requested\n' "$RELAY_AGENT" >>"$RELAY_FILE"
"$TICK" release "$RELAY_TASK" --agent "$RELAY_AGENT" --to claude-a >/dev/null 2>&1
exit 0
STUB_EOF
chmod +x "$STUB"

seed_token(){ tick_a log task.created "$1" --agent claude-a >/dev/null; tick_a claim "$1" --agent claude-a --paths "z/**" >/dev/null; tick_a release "$1" --agent claude-a --to codex >/dev/null; }

# --- (4a) RTL_TRACE=1, no CODEX_LOG override: fine-grained trace lands in the persistent path ------
seed_token RELAY-TURN-trace-on
before_untracked="$(git -C "$A" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
e2e_out="$(env RELAY_AGENT=codex RELAY_FILE="$A/relay.md" RELAY_TASK=RELAY-TURN-trace-on CODEX_AGENT=codex \
  CODEX_BIN="$STUB" CODEX_TURN_ROOT="$A" RTL_TRACE=1 \
  bash "$SHIM" 2>&1)"; rc=$?
if [ "$rc" -ne 0 ]; then echo "DEBUG e2e shim output (rc=$rc):" >&2; printf '%s\n' "$e2e_out" >&2; fi
[ "$rc" -eq 0 ] && pass "e2e: RTL_TRACE=1 turn (no CODEX_LOG override) exits 0" || fail "e2e turn rc=$rc"

day="$(date +%Y-%m-%d)"
found_log="$(find "$A/relay-system/logs/$day" -name 'codex-turn-RELAY-TURN-trace-on-*.log' 2>/dev/null | head -1)"
if [ -z "$found_log" ]; then
  echo "DEBUG: find $A/relay-system:" >&2; find "$A/relay-system" 2>/dev/null >&2
fi
[ -n "$found_log" ] && [ -f "$found_log" ] && pass "e2e: persistent transcript created under relay-system/logs/$day/" || fail "e2e: no persistent transcript found under relay-system/logs/$day/"
if [ -n "$found_log" ]; then
  if ! grep -q '\[trace\] rtl_init:' "$found_log"; then echo "DEBUG contents of $found_log:" >&2; cat "$found_log" >&2; fi
  grep -q '\[trace\] rtl_init:' "$found_log" && pass "e2e: RTL_TRACE=1 — rtl_init fine-grained trace line present" || fail "e2e: rtl_init trace line missing"
  grep -q '\[trace\] rtl_enforce: COMMIT' "$found_log" && pass "e2e: unconditional rtl_log_always COMMIT line present" || fail "e2e: COMMIT log_always line missing"
fi
after_untracked="$(git -C "$A" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
[ "$after_untracked" -eq "$before_untracked" ] && pass "e2e: persistent log never appears in git status (gitignored)" || fail "e2e: git status changed — log leaked into tracked/untracked view ($before_untracked -> $after_untracked)"

# --- (4b) RTL_TRACE unset: unconditional lines present, fine-grained lines absent ------------------
seed_token RELAY-TURN-trace-off
env RELAY_AGENT=codex RELAY_FILE="$A/relay.md" RELAY_TASK=RELAY-TURN-trace-off CODEX_AGENT=codex \
  CODEX_BIN="$STUB" CODEX_TURN_ROOT="$A" \
  bash "$SHIM" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "e2e: default (RTL_TRACE unset) turn exits 0" || fail "e2e default turn rc=$rc"
found_log2="$(find "$A/relay-system/logs/$day" -name 'codex-turn-RELAY-TURN-trace-off-*.log' 2>/dev/null | head -1)"
if [ -n "$found_log2" ]; then
  grep -q '\[trace\] rtl_enforce: COMMIT' "$found_log2" && pass "e2e: default still gets the unconditional COMMIT line" || fail "e2e: default missing unconditional COMMIT line"
  grep -q '\[trace\] rtl_init:' "$found_log2" && fail "e2e: default should NOT have fine-grained rtl_init trace" || pass "e2e: default has no fine-grained rtl_init trace (opt-in only)"
else
  fail "e2e: no persistent transcript found for the default-posture turn"
fi

# --- (4c) CODEX_LOG explicitly set inside the tracked tree still gets swept (no regression) -------
seed_token RELAY-TURN-intree
env RELAY_AGENT=codex RELAY_FILE="$A/relay.md" RELAY_TASK=RELAY-TURN-intree CODEX_AGENT=codex \
  CODEX_BIN="$STUB" CODEX_TURN_ROOT="$A" CODEX_LOG="$A/intree.log" RTL_TRACE=1 \
  bash "$SHIM" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "e2e: in-tree CODEX_LOG turn exits 0" || fail "e2e in-tree turn rc=$rc"
[ ! -f "$A/intree.log" ] && pass "e2e: in-tree CODEX_LOG swept even with new trace instrumentation writing to it" || fail "e2e: in-tree CODEX_LOG resurrected by rtl_trace/rtl_log_always (GH-161 regression)"

echo "== relay-turn-trace: $PASS passed, $FAIL failed =="
[ "$FAIL" = 0 ]
