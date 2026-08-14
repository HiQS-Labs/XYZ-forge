#!/usr/bin/env bash
# GH-314 — the run's write set is THREE paths, and the transcript was the one nobody checked.
#
# GH-514 built `preflight_write_set_trackable` and wired it to RELAY.md and ESCALATION.md. It cites
# #314 in its own comment, so it reads as if it closed it. It did not: `save_transcript()` performs a
# third `git add -- <transcript>` with check=True, under the transcript root (`relay-system/` by
# default), and that path was never passed to the preflight.
#
# The consequence is worse than the two it does cover, because the transcript is written LATE — the
# builder turn and the reviewer turn are already spent by the time it runs. #314's second reporter
# found this the expensive way: un-ignore RELAY.md, burn a full phase, crash on the next path,
# roughly 1.5h per landmine, serially.
#
# The hostile ignore here is `relay-system/` specifically, NOT `marathon-system/` — that is what
# makes this suite discriminate from gh514. With only `relay-system/` ignored the GH-514 paths are
# all trackable, so the pre-fix tree sails through preflight.
#
# WHAT ACTUALLY DISCRIMINATES, corrected by this file's own negative control — the same way gh514's
# header records its first draft being falsified.
#
# The first draft assumed the pre-fix tree dies in an unhandled `CalledProcessError` from
# `save_transcript`'s `git add`, so "no traceback" would be the discriminating assertion. **The
# control falsified that.** Pre-fix, the run still refuses cleanly, still names `relay-system`, and
# still produces no traceback — it exits 4 rather than 2, because a later layer does catch it.
#
# What actually changes is the COST. Pre-fix:
#
#     FAIL: 2 builder turn(s) were spent before the transcript refusal
#
# Two paid turns bought a refusal the driver could have issued before spending anything. That is
# #314's report almost verbatim — un-ignore one path, burn a full phase, crash on the next, ~1.5h
# per landmine, serially. So the discriminating assertion here is the DISPATCH COUNT, and the
# traceback assertion is demoted to a guard: it does not discriminate today and must not regress.
#
# Usage: bash test/gh314-transcript-writeset.sh
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$HERE/.." && pwd)"
# shellcheck source=/dev/null
source "$HERE/_setup.sh" gh314-transcript-writeset

DRIVE="$ROOT_DIR/relay-automation/marathon-drive.sh"

DISPATCH_LOG="$WORK/dispatched.log"
STUB="$WORK/builder-stub"
cat >"$STUB" <<STUB_EOF
#!/usr/bin/env bash
echo "DISPATCHED" >>"$DISPATCH_LOG"
printf '\n### Round 1 · Builder\nwork\n' >>"\${RELAY_FILE:-/dev/null}" 2>/dev/null || true
exit 0
STUB_EOF
chmod +x "$STUB"

# GH-520: stub the REVIEWER explicitly. test/_setup.sh now supplies a default, but this suite
# asserts on the CONTENT of a refusal, and a run that fail-fasts at the reviewer probe would
# satisfy an absence assertion for entirely the wrong reason.
REVIEWER_STUB="$WORK/reviewer-stub"
printf '#!/usr/bin/env bash\nexit 0\n' >"$REVIEWER_STUB"
chmod +x "$REVIEWER_STUB"
export CODEX_BIN="$REVIEWER_STUB"

mk_target() { # <label> <extra-gitignore-line>
  local label="$1"
  local extra="$2"
  local d="$WORK/$label"
  git init -q "$d"
  git -C "$d" config user.email t@t
  git -C "$d" config user.name t
  { printf '.tick/\n'; [ -n "$extra" ] && printf '%s\n' "$extra"; } >"$d/.gitignore"
  mkdir -p "$d/PROJECT/2-WORKING"
  printf '# brief\n\nDo the thing.\n' >"$d/PROJECT/2-WORKING/brief.md"
  git -C "$d" add -A >/dev/null 2>&1
  git -C "$d" commit -q -m seed
  printf '%s' "$d"
}

run_drive() { # <target-dir> <out-file>
  local d="$1" out="$2"
  ( XYZ_PYTHON=1 MARATHON_ROOT="$d" TICK_REPO_ROOT="$d" TICK_BIN="$TICK" \
      CLAUDE_BIN="$STUB" CLAUDE_TURN_ROOT="$d" RELAY_AGENT=claude-builder \
      bash "$DRIVE" --phase-id lane1 --reviewer codex --builder claude \
        --phase-brief "$d/PROJECT/2-WORKING/brief.md" --round-cap 3 \
        --phases-dir "$d/marathon-system" --pre-advance-cmd true >"$out" 2>&1 )
  printf '%s' $?
}

# ---------------------------------------------------------------------------
# Case 1 — the target ignores ONLY the transcript root
# ---------------------------------------------------------------------------
echo "-- case 1: the target gitignores relay-system/ (the third write-set path)"
HOSTILE="$(mk_target hostile-transcript 'relay-system/')"
: >"$DISPATCH_LOG"
rc="$(run_drive "$HOSTILE" "$WORK/hostile.out")"

[ "$rc" -ne 0 ] \
  && pass "a target that cannot track the transcript is refused (exit $rc)" \
  || fail "GH-314: the run completed against a target that gitignores relay-system/"

# THE discriminating assertion. Pre-fix the preflight never sees this path, so the run proceeds and
# the failure arrives later as an unhandled CalledProcessError from save_transcript's git add.
if /usr/bin/grep -qE "Traceback \(most recent call last\)|CalledProcessError" "$WORK/hostile.out"; then
  fail "GH-314: died with an unhandled traceback instead of refusing — the transcript path is still outside the preflight. Output: $(cat "$WORK/hostile.out")"
else
  pass "refuses cleanly — no unhandled traceback on the transcript path"
fi

/usr/bin/grep -qi "relay-system" "$WORK/hostile.out" \
  && pass "the refusal names the transcript path that cannot be tracked" \
  || fail "GH-314: the refusal does not name relay-system/ — output: $(cat "$WORK/hostile.out")"

# The whole point of moving this earlier: the turns are not spent first.
dispatches="$(/usr/bin/grep -c DISPATCHED "$DISPATCH_LOG" 2>/dev/null | head -1)"; dispatches="${dispatches:-0}"
if [ "$dispatches" -eq 0 ]; then
  pass "no builder turn was spent before the refusal"
else
  fail "GH-314: $dispatches builder turn(s) were spent before the transcript refusal — this is the expensive failure the issue reports"
fi

# ---------------------------------------------------------------------------
# Case 2 — CONTROL: a healthy target must NOT be refused
# ---------------------------------------------------------------------------
# Without this, blocking every run would pass case 1 and the guard would be a blanket.
echo "-- case 2: control — a target with no hostile ignore rule"
HEALTHY="$(mk_target healthy-transcript '')"
: >"$DISPATCH_LOG"
rc="$(run_drive "$HEALTHY" "$WORK/healthy.out")"

/usr/bin/grep -qi "cannot track\|check-ignore\|ignored by" "$WORK/healthy.out" \
  && fail "GH-314: the healthy target was refused by the write-set check — output: $(cat "$WORK/healthy.out")" \
  || pass "CONTROL: a healthy target is not refused by the transcript check"

echo "  gh314-transcript-writeset: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ]
