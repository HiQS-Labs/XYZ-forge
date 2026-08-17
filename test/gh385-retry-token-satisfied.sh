#!/usr/bin/env bash
# test/gh385-retry-token-satisfied.sh — GH-385 regression.
# gate-evidence: {"form":"pre-fix-replay","observed":true,"result":"reproducer: bash test/gh385-retry-token-satisfied.sh; pre-fix revisions: (a) marathon_drive.py before acf2d3e, where satisfied_lane_terminal read only the BASE token — case 1 FAILED, an Approved phase completed on a --retry suffix was rebuilt; (b) the first version of that fix, which trusted the builder-written task= directive unconditionally — cases 5,6,7,9 FAILED, a directive naming any unrelated done token satisfied the lane. Post-fix result: 12/0, with case 8 (multi-digit suffix) green in all three revisions as the anti-over-tightening control"}
#
# An Approved phase rebuilt from scratch because its completion was recorded on a --retry SUFFIXED
# token while satisfied_lane_terminal() read only the BASE token:
#
#   1. p1 runs, the builder fails, the phase escalates — MARATHON-P1-TURN is left claimed.
#   2. Operator re-runs with --retry. GH-116 allocates MARATHON-P1-TURN-2, the phase succeeds,
#      -TURN-2 reaches done and RELAY.md records STATUS: Approved.
#   3. A later run without --retry computes the BASE name again, reads the dead attempt's state,
#      and rebuilds a phase that is demonstrably Approved.
#
# Observed on a real 10-phase run: phase 1 rebuilt while phases 2-4 correctly reported satisfied, and
# the only difference was that phase 1 had once been retried. Cost is a full builder + reviewer cycle
# — real money on --builder claude — and the rebuild re-introduced a defect that had been reverted,
# so a phase believed complete silently regressed the tree. Nothing in the log said why.
#
# The driver now reads which task the relay was actually rendered for, from its own marathon-drive
# directive, instead of assuming the base name.
source "$(dirname "$0")/_setup.sh" gh385-retry-token-satisfied
DRIVER="$(cd "$(dirname "$0")/.." && pwd)/utils/py/marathon_drive.py"
export TICK_BIN="$TICK"
tick_a init >/dev/null

printf '.tick/\n' > "$A/.gitignore"
git -C "$A" add .gitignore >/dev/null 2>&1
git -C "$A" commit -q -m init
BRIEF="$WORK/brief.md"; printf '## brief\nbody\n' > "$BRIEF"

STUB_CLAUDE="$WORK/stub-claude"; printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_CLAUDE"; chmod +x "$STUB_CLAUDE"
STUB_AGY="$WORK/stub-agy"; printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_AGY"; chmod +x "$STUB_AGY"

# A relay-drive stub that RECORDS being called. The whole point of the satisfied path is that the
# phase is not driven again, so "was the driver re-entered" is the observable that matters.
RD="$WORK/relay-drive-stub.sh"
cat > "$RD" <<'STUB'
#!/usr/bin/env bash
echo called >> "$RD_CALLS"
exit 0
STUB
chmod +x "$RD"
export RD_CALLS="$WORK/rd-calls"

BASE="MARATHON-P1-TURN"

seed_relay() {  # <recorded-task> — an Approved relay rendered for <recorded-task>
  mkdir -p "$A/phases/p1"
  printf '# Marathon Phase p1\nSTATUS: Approved\nNEXT: agy (Reviewer)\n\n<!-- marathon-drive: task=%s builder=claude reviewer=agy round-cap=5 -->\n\nbody\n' \
    "$1" > "$A/phases/p1/RELAY.md"
}

mk_token() {  # <task> <done|claimed>
  tick_a log task.created "$1" --agent marathon >/dev/null 2>&1 || true
  tick_a claim "$1" --agent claude --paths "phases/p1/RELAY.md" --force >/dev/null 2>&1 || true
  [ "$2" = "done" ] && { tick_a done "$1" --agent claude >/dev/null 2>&1 || true; }
}

run_driver() {  # [extra marathon-drive args...]
  : > "$RD_CALLS"
  MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$RD" TICK_REPO_ROOT="$A" TICK_BIN="$TICK" \
  CLAUDE_BIN="$STUB_CLAUDE" AGY_BIN="$STUB_AGY" \
  python3 "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" \
    --reviewer agy --builder claude --pre-advance-cmd "true" "$@" 2>&1
}

reset_state() { rm -rf "$A/phases" "$A/.tick"; tick_a init >/dev/null 2>&1 || true; : > "$RD_CALLS"; }

# --- (1) THE BUG: completion recorded on -TURN-2, base token left on the failed attempt ----------
reset_state
seed_relay "${BASE}-2"
mk_token "$BASE" claimed      # the dead attempt, exactly as a crashed run leaves it
mk_token "${BASE}-2" done     # where the phase actually completed
out="$(run_driver)"; rc=$?
printf '%s' "$out" | grep -q "already reached a terminal relay" \
  && pass "a phase completed on a --retry token is recognized as satisfied" \
  || fail "GH-385 is back: the Approved phase rebuilt because the BASE token was read: $out"
[ ! -s "$RD_CALLS" ] \
  && pass "relay-drive was NOT re-entered (no builder + reviewer cycle re-run)" \
  || fail "the phase was driven again despite being Approved — the cost this issue is about"
[ "$rc" -eq 0 ] && pass "satisfied phase exits 0" || fail "satisfied phase exit=$rc: $out"

# --- (2) NEGATIVE CONTROL: nothing reached done, so the phase MUST still run ----------------------
# Without this, an implementation that always reported "satisfied" would pass case (1) and silently
# skip every phase in the fleet. The assertion above is only meaningful next to this one.
reset_state
seed_relay "${BASE}-2"
mk_token "$BASE" claimed
mk_token "${BASE}-2" claimed  # recorded task exists but never completed
out="$(run_driver)"
printf '%s' "$out" | grep -q "already reached a terminal relay" \
  && fail "a phase whose recorded token never reached done was skipped — satisfied is now unfalsifiable" \
  || pass "an un-completed recorded token does NOT satisfy the lane (the check can still fail)"

# --- (3) the ordinary no-retry path is unchanged --------------------------------------------------
reset_state
seed_relay "$BASE"
mk_token "$BASE" done
out="$(run_driver)"
printf '%s' "$out" | grep -q "already reached a terminal relay" \
  && pass "the plain base-token satisfied path still works" \
  || fail "regressed the ordinary satisfied path: $out"

# --- (4) a relay with no directive falls back to the base token ------------------------------------
# Relays rendered before the directive existed must keep working rather than being read as unsatisfied.
reset_state
mkdir -p "$A/phases/p1"
printf '# Marathon Phase p1\nSTATUS: Approved\nNEXT: agy\n\nbody\n' > "$A/phases/p1/RELAY.md"
mk_token "$BASE" done
out="$(run_driver)"
printf '%s' "$out" | grep -q "already reached a terminal relay" \
  && pass "a directive-less relay still resolves against the base token" \
  || fail "a pre-directive relay stopped being recognized as satisfied: $out"

# ==================================================================================================
# THE DIRECTIVE IS THE BUILDER'S TO WRITE. Everything below pins that RELAY.md is a hint, not an
# authority. Raised in review of #458 before it merged: the first version of this fix accepted any
# `task=` value, and the builder writes both that line AND `STATUS: Approved` — so the two together
# are a complete forgery of the terminal state. Point the directive at any unrelated already-done
# token and the driver skips render/reseed and reports success after the gate, which is a WIDER hole
# than the one being closed (the pre-GH-385 check read a harness-computed name the builder cannot
# touch). The resolution must never be able to leave this lane's own token family.
# ==================================================================================================

# --- (5) FORGERY: Approved + a directive naming an unrelated done token must NOT satisfy -----------
reset_state
seed_relay "MARATHON-P0-TURN"    # a different lane's token, or any stale/invented name
mk_token "$BASE" claimed         # this lane never completed
mk_token "MARATHON-P0-TURN" done # ...but the named token is legitimately done
out="$(run_driver)"
printf '%s' "$out" | grep -q "already reached a terminal relay" \
  && fail "a builder-written directive naming an unrelated done token satisfied the lane — a builder can now skip its own review: $out" \
  || pass "an out-of-family directive does NOT satisfy the lane"
# ...and it must not report the phase COMPLETE either. Not asserted via RD_CALLS: this fixture leaves
# the base token live-claimed (exactly how a crashed attempt leaves it), so the driver correctly dies
# at reconcile_relay_task before relay-drive is reached. "Did the builder run" is therefore the wrong
# observable here; "did the harness announce success having changed nothing" is the one the issue is
# about, and it is what the pre-fix code did — it exited 0 with the success line.
printf '%s' "$out" | grep -q "complete — " \
  && fail "the harness reported the phase COMPLETE off a forged directive: $out" \
  || pass "the phase is not reported complete — the lane halts honestly instead"

# --- (6) the refusal is VISIBLE ---------------------------------------------------------------------
# A silent fallback is indistinguishable from a directive that was honored, and this repo has shipped
# three checks that could not fail (#333, #348, #351). A lane that rebuilds because its directive was
# refused has to say so, or nobody can tell the guard from a bug.
printf '%s' "$out" | grep -q "not $BASE or a retry derivative" \
  && pass "the ignored directive is named in the log" \
  || fail "the directive was refused silently: $out"

# --- (7) PREFIX-MATCH CONTROL: family membership is not a startswith ---------------------------------
# `MARATHON-P1-TURN-EVIL` and `MARATHON-P1-TURNX` both begin with the base name. A membership test
# written as a prefix check accepts them and the forgery in (5) comes straight back through a name
# chosen to look related.
reset_state
seed_relay "${BASE}X"
mk_token "$BASE" claimed
mk_token "${BASE}X" done
out="$(run_driver)"
printf '%s' "$out" | grep -q "already reached a terminal relay" \
  && fail "'${BASE}X' was accepted as family — the check is a prefix match, not a suffix rule: $out" \
  || pass "a name that merely starts with the base token is not a retry derivative"

# --- (8) POSITIVE CONTROL for the suffix rule: multi-digit retries are still family -----------------
# Without this, a rule of `-\d` (or an over-tight one) would pass every assertion above while
# quietly re-breaking GH-385 for any lane retried more than nine times.
reset_state
seed_relay "${BASE}-11"
mk_token "$BASE" claimed
mk_token "${BASE}-11" done
out="$(run_driver)"
printf '%s' "$out" | grep -q "already reached a terminal relay" \
  && pass "a two-digit retry suffix is still recognized as this lane's token" \
  || fail "the family rule is too tight — GH-385 is back for lanes retried 10+ times: $out"

# --- (9) an explicit --relay-task pins the token; the directive is not consulted --------------------
# This is the --retry path (GH-116 allocates the first unused suffix and passes it through). A retry
# must never be satisfied by the attempt it was invoked to retry, or --retry silently becomes a
# gate-only re-run and the operator's explicit request is discarded.
reset_state
seed_relay "${BASE}-2"
mk_token "${BASE}-2" done        # the previous attempt genuinely completed
out="$(run_driver --relay-task "${BASE}-3")"
printf '%s' "$out" | grep -q "already reached a terminal relay" \
  && fail "--retry was satisfied by the attempt it was retrying — the operator's fresh token was ignored: $out" \
  || pass "an explicit --relay-task overrides the directive (--retry still forces a real re-run)"

# --- (10) GH-385's OTHER ask: the disagreement is logged before the rebuild ------------------------
# The issue asked for this by name — "Log the disagreement ... that single line would have made this
# diagnosable immediately" — because the failure mode is invisible: a phase that is demonstrably
# Approved silently re-runs a full builder + reviewer cycle and the log reads like an ordinary first
# fire. The fix above stops the common cause, but a terminal relay whose token genuinely is not done
# is still reachable (a token reaped after a host crash, a record on a token this run cannot see),
# and in that case the operator gets a rebuild with no explanation unless this line exists.
#
# Asserted, not merely written: an unasserted log line is precisely the "check nobody can see
# working" shape this repo has shipped three times (#333, #348, #351).
reset_state
seed_relay "$BASE"            # directive names the BASE token — no retry involved
mk_token "$BASE" claimed      # terminal relay, but the token is NOT done: the contradiction
out="$(run_driver)"
printf '%s' "$out" | grep -q "already reached a terminal relay" \
  && fail "a not-done token must NOT satisfy the lane: $out" \
  || pass "a terminal relay with a not-done token still rebuilds (unchanged)"
printf '%s' "$out" | grep -q "relay is terminal .* but token .* not done — rebuilding" \
  && pass "GH-385: the token/relay disagreement is logged before the rebuild" \
  || fail "the rebuild is still silent — GH-385's 'log the disagreement' ask is unmet: $out"
printf '%s' "$out" | grep -q "GH-385" \
  && pass "the disagreement line points at GH-385 so the next reader can find the mechanism" \
  || fail "disagreement line does not cite GH-385: $out"

# --- (11) GH-491: --retry on an ALREADY-SATISFIED lane says the cheap path existed ------------------
# Case (9) above establishes that --retry correctly refuses to be satisfied by the attempt it retries.
# The cost of that correctness is that the cheap path becomes invisible exactly when it applies: the
# `already reached a terminal relay` line prints only once the operator has already chosen the right
# invocation, so choosing wrong yields a rebuild and the reasonable conclusion that one was required.
#
# Measured, not hypothetical: three codex builds and three agy reviews across two Nightwatch waves on
# 2026-08-10, both of whose base tokens read `done` afterwards. Every one of those turns was avoidable.
reset_state
seed_relay "$BASE"
mk_token "$BASE" done            # terminal AND done: a plain re-fire would have been gate-only
out="$(run_driver --relay-task "${BASE}-2")"
printf '%s' "$out" | grep -q "already reached a terminal relay" \
  && fail "advisory case regressed into an actual short-circuit — --retry must still rebuild: $out" \
  || pass "GH-491 advisory does not change --retry's behaviour (it still rebuilds)"
printf '%s' "$out" | grep -q "re-firing WITHOUT --retry would have re-run only the pre-advance gate" \
  && pass "GH-491: --retry on a satisfied lane says a plain re-fire would have skipped both turns" \
  || fail "no advisory — the cheaper path stays invisible at the one moment it applies: $out"
printf '%s' "$out" | grep -q "GH-491" \
  && pass "the advisory cites GH-491 so the next reader can find the mechanism" \
  || fail "advisory does not cite GH-491: $out"

# --- (12) NEGATIVE CONTROL for (11): the advisory must NOT fire when it does not apply --------------
# Without this, (11) is indistinguishable from a line that prints on every --retry — which would be
# worse than silence, because an operator would learn to ignore it exactly like #492's TTY warning.
# Same --retry invocation; the ONLY variable is whether the recorded token actually completed.
reset_state
seed_relay "$BASE"
mk_token "$BASE" claimed         # terminal relay, token NOT done: a plain re-fire would ALSO rebuild
out="$(run_driver --relay-task "${BASE}-2")"
printf '%s' "$out" | grep -q "re-firing WITHOUT --retry would have re-run only the pre-advance gate" \
  && fail "control: the advisory fired on a lane a plain re-fire would ALSO have rebuilt — it is unconditional, so it carries no information: $out" \
  || pass "control: no advisory when the recorded token is not done (the cheap path genuinely did not apply)"

exit 0
