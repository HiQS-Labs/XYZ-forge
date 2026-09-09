#!/usr/bin/env bash
# GH-518 adapter-level containment for muse-turn, covering the two findings from PR #520 review.
#
# test/gh518-muse-model-policy.sh unit-tests resolve_model() in isolation. That is necessary and
# not sufficient: both findings here are WIRING defects, invisible to a function called directly
# with one argument. These cases drive the real shim end to end behind a stub `muse` and a stub
# `gh`, and assert on what the adapter actually dispatched and actually cleaned up.
#
# [P1] Classify the execution repository, not the overridable coordination repository.
#   claim_task_or_exit() returns resolve_tick_repo_root(root), which honors TICK_REPO_ROOT whenever
#   that path merely EXISTS -- it never requires it to equal the turn root. The CLI, meanwhile, is
#   launched with cwd=root. So a private turn root paired with a public TICK_REPO_ROOT could select
#   the discounted data-clause tier from the public coordination repo and then execute against the
#   private checkout. Both roots must be public; either one private or unknown vetoes.
#
# [P1] Reap the child PROCESS GROUP before enforcing or removing the worktree.
#   subprocess.run(timeout=...) kills and waits for the direct child only. Muse spawns shells and
#   test children, so on timeout that tree can outlive the turn and keep writing into a worktree
#   being torn down. rtl_run_bounded() starts a new session and SIGKILLs the group. The stub here
#   spawns a grandchild that writes AFTER the timeout; the write must never land.
#
# No network and no paid model call: `muse` and `gh` are both stubs.
source "$(dirname "$0")/_setup.sh" gh518-muse-adapter-containment
export TICK_BIN="$TICK"
SHIM="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/muse-turn.sh"

SAFE="muse-spark-1.3"
CONTRIB="muse-spark-1.3-contributor"

tick_b() { tick_in "$B" "$@"; }
tick_a init >/dev/null 2>&1
tick_b init >/dev/null 2>&1

for R in "$A" "$B"; do
  printf 'STATUS: Open\n# relay body\n' >"$R/relay.md"
  printf '.tick/\nbin/\n' >"$R/.gitignore"
  git -C "$R" add relay.md .gitignore >/dev/null 2>&1
  git -C "$R" commit -q -m "seed relay" >/dev/null 2>&1
done

# ── stub gh: answers by the directory it is invoked in ────────────────────────
# muse-turn calls `gh repo view` with cwd=<repo root>, so $PWD identifies which repo is being
# classified. VIS_A / VIS_B drive the answers per case.
mkdir -p "$WORK/bin"
cat >"$WORK/bin/gh" <<'GH_EOF'
#!/usr/bin/env bash
here="$(cd "$(pwd)" && pwd -P)"
a="$(cd "$A" && pwd -P)"; b="$(cd "$B" && pwd -P)"
case "$here" in
  "$a") echo "${VIS_A:-PRIVATE}" ;;
  "$b") echo "${VIS_B:-PRIVATE}" ;;
  *)    echo "PRIVATE" ;;
esac
GH_EOF
chmod +x "$WORK/bin/gh"

# ── stub muse: records argv, satisfies the relay protocol, optional slow grandchild ──
STUB="$WORK/muse"
cat >"$STUB" <<'STUB_EOF'
#!/usr/bin/env bash
set -u
printf '%s\n' "$*" > "$WORK/muse-args"
if [ "${STUB_MODE:-good}" = spawnchild ]; then
  # A grandchild that outlives the direct child and writes after the turn's cap. If only the
  # direct process is killed, this write lands and the assertion below catches it.
  ( sleep "${STUB_CHILD_DELAY_S:-8}"; printf 'late\n' >"$WORK/late-write" ) &
  printf '%s\n' "$!" >"$WORK/child-pid"
  sleep 60
  exit 0
fi
"$TICK" claim   "$RELAY_TASK" --agent "$RELAY_AGENT" --paths "z/**" >/dev/null 2>&1
"$TICK" ping    "$RELAY_TASK" --agent "$RELAY_AGENT" >/dev/null 2>&1
printf 'muse output for %s\n' "$RELAY_AGENT"
printf '\n### Round 1 · Reviewer · %s (muse-stub)\n**Verdict:** Changes requested\n' "$RELAY_AGENT" >>"$RELAY_FILE"
"$TICK" release "$RELAY_TASK" --agent "$RELAY_AGENT" --to claude-a >/dev/null 2>&1
exit 0
STUB_EOF
chmod +x "$STUB"

seed_token_in(){ # <repo> <task>
  tick_in "$1" log task.created "$2" --agent claude-a >/dev/null 2>&1
  tick_in "$1" claim   "$2" --agent claude-a --paths "z/**" >/dev/null 2>&1
  tick_in "$1" release "$2" --agent claude-a --to muse >/dev/null 2>&1
}

run_shim(){ # <task> <turn-root> <tick-root> <stub-mode> [extra env...]
  local task="$1" turn_root="$2" tick_root="$3" mode="$4"; shift 4
  local log="$WORK/muse-log-$task.log"; : >"$log"
  rm -f "$WORK/muse-args"
  env PATH="$WORK/bin:$PATH" \
      RELAY_AGENT=muse RELAY_FILE="$turn_root/relay.md" RELAY_TASK="$task" MUSE_AGENT=muse \
      MUSE_BIN="$STUB" MUSE_TURN_ROOT="$turn_root" TICK_REPO_ROOT="$tick_root" \
      MUSE_LOG="$log" STUB_MODE="$mode" "$@" \
      bash "$SHIM" >/dev/null 2>&1
  return $?
}

dispatched_model(){ sed -n 's/.*--model \([^ ]*\).*/\1/p' "$WORK/muse-args" 2>/dev/null | head -1; }

# ── (1) private execution root + PUBLIC coordination root -> safe tier ────────
# THE inversion from review, and the case that must be wired exactly right to bite: the turn root
# ($A) is private and is where the CLI runs, while TICK_REPO_ROOT ($B) is public. Pre-fix, the
# adapter classified only the tick root, saw PUBLIC, and dispatched the data-clause tier while
# executing against the private checkout.
#
# An earlier draft of this case passed "$A" "$A" and so never created the mismatch at all -- it
# went green against the unfixed adapter. The two roots below must genuinely differ or this
# assertion proves nothing.
seed_token_in "$B" RELAY-MUSE-mixed1
VIS_A=PRIVATE VIS_B=PUBLIC run_shim RELAY-MUSE-mixed1 "$A" "$B" good
got="$(dispatched_model)"
[ "$got" = "$SAFE" ] \
  && pass "private execution root -> safe tier dispatched (got $got)" \
  || fail "private execution root dispatched '$got', expected $SAFE"

# ── (2) PUBLIC execution root + private coordination root -> safe tier ────────
# The mirror case. Classifying only the execution repo would pass this by asserting no private
# content crosses over; requiring unanimity removes the need to assert it.
seed_token_in "$B" RELAY-MUSE-mixed2
VIS_A=PUBLIC VIS_B=PRIVATE run_shim RELAY-MUSE-mixed2 "$A" "$B" good
got="$(dispatched_model)"
[ "$got" = "$SAFE" ] \
  && pass "private coordination root -> safe tier dispatched (got $got)" \
  || fail "private coordination root dispatched '$got', expected $SAFE"

# ── (3) control: every root public -> contributor tier is reachable ───────────
# Without this the suite could pass by always returning the safe model.
seed_token_in "$A" RELAY-MUSE-allpublic
VIS_A=PUBLIC VIS_B=PUBLIC run_shim RELAY-MUSE-allpublic "$A" "$A" good
got="$(dispatched_model)"
[ "$got" = "$CONTRIB" ] \
  && pass "control: all-public roots DO reach the contributor tier (got $got)" \
  || fail "all-public roots dispatched '$got', expected $CONTRIB — the guard may be stuck safe"

# ── (4) timeout reaps the whole process group ────────────────────────────────
seed_token_in "$A" RELAY-MUSE-timeout
rm -f "$WORK/late-write" "$WORK/child-pid"
VIS_A=PRIVATE VIS_B=PRIVATE run_shim RELAY-MUSE-timeout "$A" "$A" spawnchild \
  RELAY_TURN_TIMEOUT_S=3 STUB_CHILD_DELAY_S=8
rc=$?
[ "$rc" -eq 7 ] && pass "timeout surfaces as exit 7" || fail "timeout exit was $rc, expected 7"

child="$(cat "$WORK/child-pid" 2>/dev/null || echo)"
if [ -n "$child" ] && kill -0 "$child" 2>/dev/null; then
  fail "grandchild $child survived the timeout kill (process group not reaped)"
  kill -9 "$child" 2>/dev/null || true
else
  pass "grandchild was reaped with the process group"
fi

# Wait past the grandchild's write deadline: a survivor would land its write here.
sleep 8
[ ! -f "$WORK/late-write" ] \
  && pass "no post-timeout write landed (nothing outlived the turn to touch the worktree)" \
  || fail "a delayed write landed AFTER the turn was declared killed — cleanup/enforcement raced a live child"
