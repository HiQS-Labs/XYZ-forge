#!/usr/bin/env bash
# test/gh438-removal-is-progress.sh — GH-438, PARTIAL.
#
# SCOPE, STATED UP FRONT. GH-438 reports two compounding defects. This file covers ONE:
#
#   COVERED — path_has_nonempty_phase_delta() tested `os.path.isfile(p) and getsize(p) > 0` FIRST and
#   unconditionally, so a lane whose deliverable is REMOVING a path could never register progress.
#   The artifact is gone, which is the entire point, and the function read that as "no delta".
#
#   NOT COVERED — nothing re-evaluates the lane's fix_probes after the build, which is what turns
#   "impossible" into "silently reported as done". The issue's own framing: the contract carried a
#   perfect detector, it read `unfixed` before the run and STILL read `unfixed` after, while the
#   phase reported `STATUS: Approved, gate passed` and exited 0. That half needs the driver to know
#   about acceptance criteria, which it currently does not at all, and is a design decision rather
#   than a bug fix. GH-438 stays OPEN. Do not read this file as closing it.
#
# The distinction matters because the uncovered half is the dangerous one: a runner that reports
# success while having changed nothing.
source "$(dirname "$0")/_setup.sh" gh438-removal-is-progress
DRIVER="$(cd "$(dirname "$0")/.." && pwd)/utils/py/marathon_drive.py"
export TICK_BIN="$TICK"
tick_a init >/dev/null

printf '.tick/\n' > "$A/.gitignore"
mkdir -p "$A/src"
printf 'doomed contents\n' > "$A/src/doomed.js"
printf 'kept contents\n'   > "$A/src/kept.js"
git -C "$A" add -A >/dev/null 2>&1
git -C "$A" commit -q -m "seed tracked artifacts"

BRIEF="$WORK/brief.md"; printf '## brief\nbody\n' > "$BRIEF"
STUB_CLAUDE="$WORK/stub-claude"; printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_CLAUDE"; chmod +x "$STUB_CLAUDE"
STUB_AGY="$WORK/stub-agy"; printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_AGY"; chmod +x "$STUB_AGY"

# Builder stalls (exit 3) having performed the lane's real deliverable; the reviewer pass then
# approves. This is the GH-207 already-satisfied recovery shape, which is where
# path_has_nonempty_phase_delta is consulted via artifacts_exist().
mk_stub() {  # <shell-fragment run on the builder call>
  cat > "$WORK/rd.sh" <<STUB
#!/usr/bin/env bash
set -eu
relay=""; task=""; review_once=0
while ((\$#)); do
  case "\$1" in
    --relay-file) relay="\$2"; shift 2 ;;
    --relay-task) task="\$2"; shift 2 ;;
    --review-once) review_once=1; shift ;;
    *) shift ;;
  esac
done
if [ "\$review_once" -eq 0 ]; then
  $1
  exit 3
fi
sed -i.bak 's/^STATUS:[[:space:]]*.*/STATUS: Approved/' "\$relay"; rm -f "\$relay.bak"
printf '\n### Round 1 · Reviewer · agy\n**Verdict:** Approved\n' >> "\$relay"
TICK_REPO_ROOT="$A" "$TICK" claim "\$task" --agent agy --paths "phases/p1/RELAY.md" >/dev/null 2>&1 || true
TICK_REPO_ROOT="$A" "$TICK" done "\$task" --agent agy >/dev/null 2>&1 || true
exit 0
STUB
  chmod +x "$WORK/rd.sh"
}

run_driver() {  # <artifact-path>
  rm -rf "$A/phases" "$A/.tick"; tick_a init >/dev/null 2>&1 || true
  MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$WORK/rd.sh" TICK_REPO_ROOT="$A" TICK_BIN="$TICK" \
  CLAUDE_BIN="$STUB_CLAUDE" AGY_BIN="$STUB_AGY" \
  python3 "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" --reviewer agy --builder claude \
    --artifact "$1" --pre-advance-cmd "true" 2>&1
}

# --- (1) THE FIX: a removal is progress ------------------------------------------------------------
mk_stub 'rm -f "'"$A"'/src/doomed.js"'
out="$(run_driver src/doomed.js)"; rc=$?
[ "$rc" -eq 0 ] \
  && pass "a lane whose deliverable is a removal can complete (exit 0)" \
  || fail "GH-438 is back: removing the artifact read as no progress, exit=$rc: $out"
printf '%s' "$out" | grep -q "lane_already_satisfied" \
  && pass "the removal is recognized as a real phase delta" \
  || fail "removal did not register as a delta: $out"
[ ! -e "$A/src/doomed.js" ] && pass "the artifact really is gone" || fail "fixture did not delete the artifact"
git -C "$A" checkout -- src/doomed.js 2>/dev/null || git -C "$A" reset -q --hard >/dev/null 2>&1

# --- (2) NEGATIVE CONTROL: touching nothing is still not progress ---------------------------------
# Without this, "always return True" passes case (1) and every stalled lane in the fleet would be
# waved through as satisfied — a strictly worse bug than the one being fixed.
mk_stub 'true'
out="$(run_driver src/kept.js)"; rc=$?
printf '%s' "$out" | grep -q "lane_already_satisfied" \
  && fail "an untouched artifact was reported as satisfied — the delta check is now unfalsifiable" \
  || pass "an untouched artifact is still NOT progress (the check can fail)"
[ "$rc" -ne 0 ] && pass "a lane that did nothing does not exit 0 (rc=$rc)" \
  || fail "a lane that changed nothing exited 0"

# --- (3) the emptiness rule that earns its keep is preserved ---------------------------------------
# A newly created but completely empty file is not a deliverable. This is the ONLY thing the original
# existence test was protecting, and narrowing it must not have dropped it.
mk_stub ': > "'"$A"'/src/hollow.js"'
out="$(run_driver src/hollow.js)"
printf '%s' "$out" | grep -q "lane_already_satisfied" \
  && fail "a newly created EMPTY artifact counted as a deliverable" \
  || pass "a newly created empty artifact is still rejected"
rm -f "$A/src/hollow.js"

exit 0
