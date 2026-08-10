#!/usr/bin/env bash
# test/gh331-cost-summary.sh — GH-331 / GH-308: the end-of-run `tick analyze` cost summary was
# implemented only in the Bash twins (relay-drive.sh GH-152, marathon-drive.sh GH-222), so on the
# DEFAULT lane (XYZ_PYTHON unset → Python, since GH-264) a driven run emitted NO cost visibility.
# marathon was worse: it tells its nested relay-drive child RELAY_COST_SUMMARY=0, so with the parent's
# own summary also absent a driven phase showed ZERO cost.
#
# Every invocation here drives the DEFAULT (Python) lane — that is the whole point of GH-308. Pins:
#   (1) a driven relay-drive turn prints the cost block on the default lane;
#   (2) RELAY_COST_SUMMARY=0 silences it;
#   (3) the summary is ADDITIVE — it never changes the driven run's exit code (checked on a NON-zero
#       exit path, and when `tick analyze` itself fails);
#   (4) the same three properties for marathon-drive with MARATHON_COST_SUMMARY.
#
# gate-evidence: {"form":"pre-fix-replay","observed":true,"result":"reproducer: hold the clone's .git/relay-driver.lock with a LIVE pid, then run this suite (that is the in-marathon condition; a linked worktree does NOT reproduce it because relay-drive takes a per-worktree lock there, GH-376). pre-fix revision: this file with RELAY_DRIVER_LOCKED unset but the relay-drive invocations unscoped. pre-fix result: FAIL rc=1 'another driver is active in this repo (pid 2436, lock: .git/relay-driver.lock)' — the same failure that halted Litmus wave-2 phase 1 on 2026-08-08 at 893s. post-fix result: 8 pass / 0 fail with the SAME lock still held, and 8 pass / 0 fail with no lock, so the fix is verified in both directions rather than only the one under investigation"}
source "$(dirname "$0")/_setup.sh" gh331-cost-summary

# GH-441 — hermetic against an ambient driver, same reason as test/driver-lock.sh:11. Every
# assertion here drives relay-drive/marathon-drive against this suite's own throwaway repo ($A) and
# reads the driven run's OWN output. Inheriting RELAY_DRIVER_LOCKED=1 from a live marathon gate makes
# those nested drivers take the already-locked path and skip the end-of-run cost summary, so the
# suite measures the parent rather than itself. Measured 2026-08-07: inherited → 5 pass / 3 fail;
# unset → clean.
unset RELAY_DRIVER_LOCKED

export TICK_BIN="$TICK"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TICK_PATH="$TICK"

# ...BUT unsetting it is only half the fix, and the missing half halted a live marathon.
#
# The first version of this file's comment claimed "$A is isolated, so unsetting cannot collide with
# a real lock." That was reasoned, not observed, and it is FALSE. $A is where the relay FILE lives;
# it is not the nested driver's ROOT. relay-drive.sh:48 sets
#     ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# from its OWN script location, and there is no env override for it (--target-root moves the build,
# not the lock; MARATHON_ROOT is honoured by marathon-drive only — which is why the sibling
# test/gh284-runlog-heartbeat.sh, scoped with MARATHON_ROOT="$A", was never affected).
#
# So with RELAY_DRIVER_LOCKED unset, the nested relay-drive reached for the REAL clone's
# .git/relay-driver.lock — held by the marathon driver that was running this very gate — and refused:
#
#   FAIL: relay-drive default lane: expected exit 0 + cost summary; got rc=1
#     relay-drive: another driver is active in this repo (pid 35784, lock: .git/relay-driver.lock).
#
# Observed 2026-08-08, Litmus wave-2 phase 1: relay Approved, gate exit 1 after 893s, marathon HALT
# (exit 5). Green standalone, red inside a marathon — GH-441's own defect, reintroduced by GH-441's
# own fix, in the one direction the standalone run cannot see.
#
# THE FIX: give relay-drive a script path INSIDE $A so its script-relative ROOT_DIR resolves to $A,
# and the lock it takes is $A's. Symlinking DIRECTORIES (not individual scripts) is what makes this
# work — the driver resolves its siblings relative to itself, and those resolve through the symlinked
# directory. Same technique as the gitignored `$A/bin/tick` symlink in
# test/gh410-containment-advisory.sh, for the same reason.
#
# The set below is not guessed: it is every path relay-drive.sh dereferences under $ROOT_DIR
#     grep -ohE '\$\{?ROOT_DIR\}?/[A-Za-z0-9._/-]+' relay-automation/relay-drive.sh
# minus the three it creates or owns itself (.git, .relay-driver.lock, relay-system). Getting this
# wrong fails LOUDLY rather than silently — the first attempt symlinked only relay-automation/ and
# the nested run died with
#     can't open file '<A>/utils/py/relay_drive.py': [Errno 2] No such file or directory
# because relay-drive.sh dispatches to the Python lane under $ROOT_DIR/utils (GH-264 default).
mkdir -p "$A"
for _ge_dir in relay-automation utils bin; do
  ln -sfn "$ROOT/$_ge_dir" "$A/$_ge_dir"
done
unset _ge_dir
DRIVE="$A/relay-automation/relay-drive.sh"

# marathon-drive needs NO such treatment and deliberately keeps the real path: every assertion below
# passes MARATHON_ROOT="$A" (line ~141), which marathon-drive honours for lock resolution, and
# --pre-advance-cmd true so no real gate runs. Routing it through $A too would only add a way for a
# nested marathon to find the REAL validate.sh and re-enter the full gate recursively.
MDRIVE="$ROOT/relay-automation/marathon-drive.sh"

tick_a init >/dev/null

COST_LINE='relay-drive: end-of-run cost summary (tick analyze)'

# ── relay-drive ─────────────────────────────────────────────────────────────────────────
seed() {  # <task> <relayfile-basename>
  printf 'STATUS: In progress\n# body\n' >"$A/$2"
  tick_a log task.created "$1" --agent producer --paths "$2" >/dev/null 2>&1
  tick_a claim   "$1" --agent producer --paths "$2" >/dev/null 2>&1
  tick_a release "$1" --agent producer --to reviewer >/dev/null 2>&1
  tick_a cost    "$1" --agent reviewer --tokens-in 1200 --tokens-out 340 --tool codex >/dev/null 2>&1
}

approve_stub() {  # <task> <relayfile> → path
  local task="$1"
  local rf="$2"
  local p="$WORK/approve-$task.sh"
  cat >"$p" <<EOF
#!/usr/bin/env bash
export TICK_REPO_ROOT="$A"
"$TICK_PATH" claim $task --agent reviewer >/dev/null 2>&1
tmp="\$(mktemp)"; sed 's/^STATUS:.*/STATUS: Approved/' "$rf" > "\$tmp" && mv "\$tmp" "$rf"
"$TICK_PATH" done $task --agent reviewer >/dev/null 2>&1
exit 0
EOF
  chmod +x "$p"; printf '%s' "$p"
}

# (1) default lane, cost summary ON → the block appears, run still exits 0.
seed RELAY-A relayA.md
STUB_A="$(approve_stub RELAY-A "$A/relayA.md")"
outA="$(bash "$DRIVE" --relay-file "$A/relayA.md" --relay-task RELAY-A --agent-cmd "$STUB_A" --review-once 2>&1)"; rcA=$?
[ "$rcA" -eq 0 ] && printf '%s' "$outA" | grep -qF "$COST_LINE" \
  && pass "relay-drive default lane: driven turn prints the cost summary (exit 0)" \
  || fail "relay-drive default lane: expected exit 0 + cost summary; got rc=$rcA (out: $outA)"
printf '%s' "$outA" | grep -qF -- '--- cost ---' \
  && pass "relay-drive: the summary carries the real tick analyze cost block" \
  || fail "relay-drive: cost block missing from summary: $outA"

# (2) RELAY_COST_SUMMARY=0 silences it (still exit 0).
seed RELAY-B relayB.md
STUB_B="$(approve_stub RELAY-B "$A/relayB.md")"
outB="$(RELAY_COST_SUMMARY=0 bash "$DRIVE" --relay-file "$A/relayB.md" --relay-task RELAY-B --agent-cmd "$STUB_B" --review-once 2>&1)"; rcB=$?
[ "$rcB" -eq 0 ] && ! printf '%s' "$outB" | grep -qF "$COST_LINE" \
  && pass "relay-drive: RELAY_COST_SUMMARY=0 opts out of the summary" \
  || fail "relay-drive: RELAY_COST_SUMMARY=0 did not silence the summary (rc=$rcB): $outB"

# (3a) NON-zero exit path: a genuine stall exits 3. The summary must be additive — exit STAYS 3.
seed RELAY-C relayC.md
NOOP="$WORK/noop.sh"; printf '#!/usr/bin/env bash\nexit 0\n' >"$NOOP"; chmod +x "$NOOP"
outC="$(bash "$DRIVE" --relay-file "$A/relayC.md" --relay-task RELAY-C --agent-cmd "$NOOP" --review-once 2>&1)"; rcC=$?
[ "$rcC" -eq 3 ] \
  && pass "relay-drive: the summary never changes the run's exit code (stall still exits 3)" \
  || fail "relay-drive: exit code changed by the summary — expected 3, got $rcC (out: $outC)"

# (3b) `tick analyze` itself failing must degrade gracefully and NOT change the exit code.
seed RELAY-D relayD.md
STUB_D="$(approve_stub RELAY-D "$A/relayD.md")"
BROKEN_TICK="$WORK/broken-tick.sh"
printf '#!/usr/bin/env bash\ncase "$1" in analyze) exit 9 ;; esac\nexec "%s" "$@"\n' "$TICK" >"$BROKEN_TICK"
chmod +x "$BROKEN_TICK"
outD="$(TICK_BIN="$BROKEN_TICK" bash "$DRIVE" --relay-file "$A/relayD.md" --relay-task RELAY-D --agent-cmd "$STUB_D" --review-once 2>&1)"; rcD=$?
[ "$rcD" -eq 0 ] \
  && pass "relay-drive: a failed tick analyze does not change the exit code (still 0)" \
  || fail "relay-drive: failed tick analyze changed exit code — expected 0, got $rcD (out: $outD)"
printf '%s' "$outD" | grep -qF 'tick analyze failed — end-of-run cost summary unavailable' \
  && pass "relay-drive: a failed tick analyze degrades with a note, not a crash" \
  || fail "relay-drive: expected the analyze-failed degradation note: $outD"

# ── marathon-drive ──────────────────────────────────────────────────────────────────────
MCOST_LINE='marathon-drive: end-of-run cost summary (tick analyze)'
printf '.tick/\n' > "$A/.gitignore"
git -C "$A" add .gitignore >/dev/null 2>&1 && git -C "$A" commit -qm init >/dev/null 2>&1
BRIEF="$WORK/GH-331-brief.md"; printf 'GH-331 cost brief\n' > "$BRIEF"
# Stub relay-drive that exits 3 (a stall): marathon still arms drive_started before invoking it, so the
# cost summary must fire at marathon's own exit, and marathon must still exit 3.
STUB_RD="$WORK/relay-drive-stub.sh"; printf '#!/usr/bin/env bash\nexit 3\n' >"$STUB_RD"; chmod +x "$STUB_RD"
STUB_CLAUDE="$WORK/claude"; printf '#!/usr/bin/env bash\nexit 0\n' >"$STUB_CLAUDE"; chmod +x "$STUB_CLAUDE"
STUB_AGY="$WORK/agy"; printf '#!/usr/bin/env bash\nexit 0\n' >"$STUB_AGY"; chmod +x "$STUB_AGY"
tick_a cost MARATHON-GH331 --agent codex --tokens-in 2000 --tokens-out 700 --tool codex >/dev/null 2>&1

run_marathon() { # <phase-id> [extra-env-assignments passed via `env`]
  local pid="$1"; shift
  env "$@" MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$STUB_RD" TICK_REPO_ROOT="$A" TICK_BIN="$TICK" \
    CLAUDE_BIN="$STUB_CLAUDE" AGY_BIN="$STUB_AGY" \
    bash "$MDRIVE" --phases-dir "$A/phases" --phase-brief "$BRIEF" --phase-id "$pid" \
      --relay-task "MARATHON-GH331-$pid" --builder claude --reviewer agy --pre-advance-cmd true 2>&1
}

# (4a) default lane, cost summary ON → marathon prints its own block, still exits 3.
mOut="$(run_marathon m1)"; mRc=$?
[ "$mRc" -eq 3 ] && printf '%s' "$mOut" | grep -qF "$MCOST_LINE" \
  && pass "marathon-drive default lane: driven phase prints the cost summary (exit preserved: 3)" \
  || fail "marathon-drive default lane: expected exit 3 + cost summary; got rc=$mRc (out: $(printf '%s' "$mOut" | tail -5))"

# (4b) MARATHON_COST_SUMMARY=0 silences it (still exits 3).
mOut0="$(run_marathon m2 MARATHON_COST_SUMMARY=0)"; mRc0=$?
[ "$mRc0" -eq 3 ] && ! printf '%s' "$mOut0" | grep -qF "$MCOST_LINE" \
  && pass "marathon-drive: MARATHON_COST_SUMMARY=0 opts out of the summary" \
  || fail "marathon-drive: MARATHON_COST_SUMMARY=0 did not silence the summary (rc=$mRc0): $(printf '%s' "$mOut0" | tail -5)"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
