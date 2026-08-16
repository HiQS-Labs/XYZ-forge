#!/usr/bin/env bash
# GH-384 — after an interrupted marathon, does the tool actually DISTINGUISH a gated phase from an
# ungated one?
#
# The issue's own litmus test, quoted: "Existence is not detection. `marathon-detail.sh` already
# prints STATUS:/NEXT: lines and recent tick events — a script that does the same thing under a new
# name satisfies nothing here." A fixture with two phases, one Approved-with-a-phase.approved-event
# and one Open-with-a-landed-commit-and-no-event, must produce VISIBLY DIFFERENT output. Same output
# for both is a fail even if the tool runs cleanly.
#
# So every assertion here is comparative or on a specific label. Nothing asserts "the tool exited 0",
# because it exits 0 whether or not it detected anything — which is exactly why the lane shipped
# without this file and the criterion stayed unmet.
#
# The third property is the one an operator's safety depends on: the tool is documented read-only, so
# running it against a repo must leave that repo byte-identical. That is directly testable, and this
# file tests it rather than trusting the docstring.
#
# Usage: bash test/gh384-crash-recovery.sh
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$HERE/.." && pwd)"
# shellcheck source=/dev/null
source "$HERE/_setup.sh" gh384-crash-recovery

RECOVER="$ROOT_DIR/relay-automation/marathon-recover.sh"
[ -x "$RECOVER" ] || [ -f "$RECOVER" ] \
  || { fail "marathon-recover.sh is missing — GH-384's deliverable does not exist"; exit 1; }

# ---------------------------------------------------------------------------
# The fixture: one gated phase, one ungated phase, in ONE repo
# ---------------------------------------------------------------------------
# Both phases must live in the same repo and the same run, or the comparison is between two
# invocations rather than between two phases — and a tool that simply echoes its input would pass
# that weaker form.
R="$WORK/target"
git init -q "$R"
git -C "$R" config user.email r@t
git -C "$R" config user.name r
printf '.tick/\n' >"$R/.gitignore"
git -C "$R" add .gitignore >/dev/null 2>&1
git -C "$R" commit -q -m "seed"

mk_phase() {  # <phase-id> <task> <status>
  local id="$1" task="$2" status="$3"
  mkdir -p "$R/marathon-system/$id"
  cat >"$R/marathon-system/$id/RELAY.md" <<EOF
STATUS: $status

<!-- marathon-drive: phase=$id task=$task -->

# Relay for $id
EOF
}

# Phase 1 — GATED: Approved, and a marathon.phase.approved event exists for its task.
mk_phase gated MARATHON-GATED-TURN Approved
# Phase 2 — UNGATED: still Open, no approval event, and a commit for its task IS on the branch.
#           This is the crash window: the turn's work was committed before the gate ever ran.
mk_phase ungated MARATHON-UNGATED-TURN Open

git -C "$R" add marathon-system >/dev/null 2>&1
git -C "$R" commit -q -m "marathon: render phases"
# The landed, never-gated commit. Subject matches the harness's real shape (relay-turn-lib.sh:1144).
printf 'work the builder committed before the gate ran\n' >"$R/ungated-artifact.md"
git -C "$R" add ungated-artifact.md >/dev/null 2>&1
git -C "$R" commit -q -m "relay(MARATHON-UNGATED-TURN): codex turn (codex headless)"

# The approval event for the GATED phase only. Written in tick's own compact shape.
mkdir -p "$R/.tick/events"
printf '{"type":"marathon.phase.approved","task":"MARATHON-GATED-TURN","agent":"marathon"}\n' \
  >"$R/.tick/events/approved.jsonl"

# ---------------------------------------------------------------------------
# Read-only, asserted BEFORE reading the output — a tool that mutates the repo it is diagnosing
# after a crash is worse than no tool, so this is checked first.
# ---------------------------------------------------------------------------
echo "-- read-only"
before_head="$(git -C "$R" rev-parse HEAD)"
before_status="$(git -C "$R" status --porcelain | LC_ALL=C sort)"
before_tree="$(cd "$R" && find . -path ./.git -prune -o -print | LC_ALL=C sort)"

out="$(bash "$RECOVER" "$R" 2>&1)"

after_head="$(git -C "$R" rev-parse HEAD)"
after_status="$(git -C "$R" status --porcelain | LC_ALL=C sort)"
after_tree="$(cd "$R" && find . -path ./.git -prune -o -print | LC_ALL=C sort)"

[ "$before_head" = "$after_head" ] \
  && pass "HEAD is unchanged (no commit was made)" \
  || fail "GH-384: the read-only tool moved HEAD: $before_head -> $after_head"
[ "$before_status" = "$after_status" ] \
  && pass "git status is byte-identical before and after" \
  || fail "GH-384: the tool changed the working tree — status diff:
$(diff <(printf '%s\n' "$before_status") <(printf '%s\n' "$after_status"))"
[ "$before_tree" = "$after_tree" ] \
  && pass "no file was created or removed anywhere in the tree" \
  || fail "GH-384: the tool wrote to the repo — tree diff:
$(diff <(printf '%s\n' "$before_tree") <(printf '%s\n' "$after_tree"))"

# ---------------------------------------------------------------------------
# Detection — the two phases must READ DIFFERENTLY
# ---------------------------------------------------------------------------
echo "-- detection: gated vs ungated"

# Slice the report per phase, so "the word UNGATED appears somewhere" cannot pass for "the ungated
# phase was labelled". A tool that printed the label under both phases would satisfy a whole-output
# grep and fail here, which is the substitution the issue warns about.
gated_block="$(printf '%s\n' "$out" | awk '/^PHASE: gated$/{f=1} /^PHASE: ungated$/{f=0} f')"
ungated_block="$(printf '%s\n' "$out" | awk '/^PHASE: ungated$/{f=1} f')"

[ -n "$gated_block" ] && pass "the report contains a block for the gated phase" \
                      || fail "no block for the gated phase — report was:
$out"
[ -n "$ungated_block" ] && pass "the report contains a block for the ungated phase" \
                        || fail "no block for the ungated phase — report was:
$out"

[ "$gated_block" != "$ungated_block" ] \
  && pass "the two phases produce DIFFERENT output (the issue's core litmus test)" \
  || fail "GH-384: both phases produced identical output — the tool is not distinguishing them"

case "$ungated_block" in
  *"UNGATED COMMIT:"*)
    pass "the ungated phase is labelled with its ungated commit" ;;
  *)
    fail "GH-384: the ungated phase was not labelled — its block was:
$ungated_block" ;;
esac
case "$ungated_block" in
  *"MARATHON-UNGATED-TURN"*) pass "the label names the actual landed commit's task" ;;
  *) fail "GH-384: the ungated finding does not name the commit it found" ;;
esac
case "$ungated_block" in
  *UNVERIFIED*) pass "the finding is stated as UNVERIFIED, not merely reported" ;;
  *) fail "GH-384: the ungated commit is not marked unverified — an operator could read it as fine" ;;
esac

case "$gated_block" in
  *"UNGATED COMMIT:"*)
    fail "GH-384: the GATED phase was also flagged ungated — a false positive makes the report useless" ;;
  *)
    pass "the gated phase is NOT flagged (no false positive)" ;;
esac
case "$gated_block" in
  *"APPROVAL: recorded"*) pass "the gated phase's approval event is recognised" ;;
  *) fail "GH-384: the approval event was not detected — block was:
$gated_block" ;;
esac

# The inverse control. If the approval event is removed, the SAME repo must now flag the same phase —
# proving the verdict is driven by the event and not by the phase's name or its STATUS line alone.
echo "-- inverse control: remove the approval event, the verdict must flip"
mv "$R/.tick/events/approved.jsonl" "$WORK/approved.jsonl.bak"
mk_phase gated MARATHON-GATED-TURN Open      # a crashed run would leave it non-terminal too
out2="$(bash "$RECOVER" "$R" 2>&1)"
gated_block2="$(printf '%s\n' "$out2" | awk '/^PHASE: gated$/{f=1} /^PHASE: ungated$/{f=0} f')"
case "$gated_block2" in
  *"APPROVAL: missing"*)
    pass "with the event removed, the same phase now reports its approval missing" ;;
  *)
    fail "GH-384: removing the approval event changed nothing — the verdict is not reading the events:
$gated_block2" ;;
esac
mv "$WORK/approved.jsonl.bak" "$R/.tick/events/approved.jsonl"
mk_phase gated MARATHON-GATED-TURN Approved

# ---------------------------------------------------------------------------
# Driver-lock state — reported, and reported from the SHARED resolver
# ---------------------------------------------------------------------------
echo "-- driver lock state"
case "$out" in
  *"DRIVER LOCK: IDLE"*) pass "no lock present reports IDLE" ;;
  *) fail "GH-384: driver-lock state was not reported — report was:
$out" ;;
esac

# A lock naming a pid that cannot exist must read STALE, not LIVE. The distinction is the whole
# reason the criterion names it: a stale lock self-heals, a LIVE one means something is still running.
# shellcheck source=/dev/null
source "$ROOT_DIR/relay-automation/driver-lock-lib.sh"
lockdir="$(driver_lock_path_for_repo "$R")"
mkdir -p "$lockdir"
printf '999999\n' >"$lockdir/pid"
out3="$(bash "$RECOVER" "$R" 2>&1)"
case "$out3" in
  *"DRIVER LOCK: STALE"*) pass "a lock held by a dead pid reports STALE" ;;
  *) fail "GH-384: a dead-pid lock was not reported STALE — got: $(printf '%s\n' "$out3" | /usr/bin/grep 'DRIVER LOCK')" ;;
esac
printf '%s\n' "$$" >"$lockdir/pid"
out4="$(bash "$RECOVER" "$R" 2>&1)"
case "$out4" in
  *"DRIVER LOCK: LIVE"*) pass "a lock held by a live pid reports LIVE" ;;
  *) fail "GH-384: a live lock was not reported LIVE — got: $(printf '%s\n' "$out4" | /usr/bin/grep 'DRIVER LOCK')" ;;
esac
rm -rf "$lockdir"

# ---------------------------------------------------------------------------
# The documented procedure exists and is findable
# ---------------------------------------------------------------------------
echo "-- documented recovery procedure"
# Asserted on SUBSTANCE, not on one phrase. The criterion names three things the procedure must tell
# an operator, and a doc can contain the words "ungated commit" while saying none of them. (The first
# draft grepped case-sensitively for that phrase and failed against a README that documents all three
# — the wrong test, not the wrong doc.)
readme="$ROOT_DIR/README.md"
/usr/bin/grep -qi "marathon-recover.sh" "$readme" \
  && pass "README names the tool to run after an interruption" \
  || fail "GH-384: README does not name marathon-recover.sh"
/usr/bin/grep -qi "ungated commit" "$readme" \
  && pass "README explains the ungated-commit finding" \
  || fail "GH-384: README does not explain the ungated-commit finding"
if /usr/bin/grep -qiE "re-run .*gate|revert" "$readme"; then
  pass "README says what to DO about one (re-run the gate, or revert)"
else
  fail "GH-384: README reports the finding without giving the remedy"
fi
if /usr/bin/grep -qiE "stale lock self-heals|self-heals on the next" "$readme"; then
  pass "README notes that a stale driver lock self-heals"
else
  fail "GH-384: README does not cover the stale-lock case"
fi

echo
echo "  $TEST_NAME: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
