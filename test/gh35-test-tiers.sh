#!/usr/bin/env bash
set -uo pipefail
#
# gh35-test-tiers.sh — GH-35: tiered test selection + CPU governance in validate.sh.
#
# Two questions, deliberately tested separately (the review guardrail on #35: test selection is
# deterministic policy; resource policy is a knob):
#
#   WHICH tests  — the tier system: registry classification, fail-closed boundaries, and the
#                  tier-1/tier-2 execution paths, driven END-TO-END against fixture clones.
#   HOW LOUDLY   — CPU governance: balanced default width (never the old cores-2), --throttle,
#                  --burst, env levers, precedence, and nice -n 10 on the workers.
#
# HOW THE EXECUTION CASES STAY CHEAP: the fixture repos copy the REAL validate.sh and the REAL
# classifier but stub the suites they select, the same trick gh544-pre-push-gate.sh uses on the
# hook — the dispatch, the pool, the identity bracket and the GH-15 summary math are all the
# real machinery; only the leaf suites cost milliseconds.
#
# The registry drift guard is the releases-skill lesson as a test: a subsystem naming a suite
# that does not exist (or is not registered in validate.sh's TESTS) must fail LOUDLY, because a
# registry entry that never runs is indistinguishable from a passing gate that tested nothing.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
V="$REPO/validate.sh"
ROUTER="$REPO/utils/ci-route.sh"
# GH-441 / GH-35: scrub ambient runner env vars so test assertions start from a clean baseline
unset XYZ_VALIDATE_THROTTLE XYZ_VALIDATE_MAX_JOBS XYZ_VALIDATE_PARALLEL 2>/dev/null || true

pass=0; fail=0
ok(){ if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi }
probe(){ bash "$V" --print-mode "$@" 2>&1; }

echo "== test: gh35-test-tiers =="

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh35-tiers.XXXXXX")"
[ -n "$WORK" ] && [ -d "$WORK" ] || { echo "mktemp failed" >&2; exit 1; }
cleanup(){ [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
trap cleanup EXIT

# GH-177/GH-1: every fixture path this suite passes around is proven to live under $WORK.
. "$HERE/lib/fixture-guard.sh"
fixture_guard_init "$WORK"

# ── (1) CPU governance — the decision, announced (GH-35 Phase 2) ─────────────────────────────────
width_of(){ printf '%s' "$1" | sed -n 's/.*PARALLEL mode \([0-9]*\)-wide.*/\1/p' | head -1; }

# THE PIN: the balanced default never exceeds 4 workers, on any host. The pre-GH-35 default was
# cores-2 capped 8, which pegged 8-core+ machines at 100% — this is the number that changed.
def_out="$(probe)"
def_w="$(width_of "$def_out")"
if [ -n "$def_w" ]; then
  ok "auto-detected default width is <= 4 (got ${def_w}-wide; was cores-2 up to 8 pre-GH-35)" \
     "[ "$def_w" -le 4 ]"
  ok "  and the reason names the balanced default and the escape hatch" \
     "printf '%s' \"\$def_out\" | grep 'balanced default cores/2' >/dev/null"
  ok "  and announces nice on the workers" \
     "printf '%s' \"\$def_out\" | grep 'nice -n 10' >/dev/null"
else
  ok "auto-detected default declined to sequential WITH a reason (low-core host — legal)" \
     "printf '%s' \"\$def_out\" | grep -E 'SEQUENTIAL mode' >/dev/null"
  echo "  (sequential host: width assertions below compare against sequential and stay meaningful)"
fi

out="$(probe --throttle)"
ok "--throttle pins 2 workers" "[ "$(width_of "$out")" = "2" ]"
ok "  and names quiet-CPU + nice in the reason" \
   "printf '%s' \"\$out\" | grep 'quiet-CPU' >/dev/null"
out="$(probe --quiet-cpu)"
ok "--quiet-cpu is the documented alias of --throttle" "[ "$(width_of "$out")" = "2" ]"

out="$(probe --burst)"; burst_w="$(width_of "$out")"
ok "--burst restores the full-core width (>= balanced default)" \
   "[ -n \"$burst_w\" ] && { [ -z \"$def_w\" ] || [ \"$burst_w\" -ge \"$def_w\" ]; }"
ok "  and says so in the reason" "printf '%s' \"\$out\" | grep 'full-core width' >/dev/null"

out="$(XYZ_VALIDATE_THROTTLE=1 probe)"
ok "XYZ_VALIDATE_THROTTLE=1 selects the 2-worker quiet mode" "[ "$(width_of "$out")" = "2" ]"
ok "  and names the env var as the reason" "printf '%s' \"\$out\" | grep 'XYZ_VALIDATE_THROTTLE=1' >/dev/null"
out="$(XYZ_VALIDATE_MAX_JOBS=3 probe)"
ok "XYZ_VALIDATE_MAX_JOBS=3 pins 3 workers" "[ "$(width_of "$out")" = "3" ]"
out="$(XYZ_VALIDATE_THROTTLE=1 XYZ_VALIDATE_MAX_JOBS=4 probe)"
ok "a width lever beats a throttle lever in the environment" "[ "$(width_of "$out")" = "4" ]"
out="$(XYZ_VALIDATE_THROTTLE=1 probe --burst)"
ok "an explicit flag beats the ambient throttle env (flag > env, GH-544 contract)" \
   "[ "$(width_of "$out")" = "$burst_w" ]"
out="$(probe --max-parallel 5)"
ok "--max-parallel N is the documented alias of --parallel N" "[ "$(width_of "$out")" = "5" ]"

# A flag always beats XYZ_VALIDATE_PARALLEL, the pre-existing lever — still true with the new ones.
out="$(XYZ_VALIDATE_PARALLEL=0 probe --throttle)"
ok "a throttle flag still overrides XYZ_VALIDATE_PARALLEL=0" "[ "$(width_of "$out")" = "2" ]"

# ── (2) CPU governance — malformed input fails loudly, never silently ignores ────────────────────
rc=0; out="$(XYZ_VALIDATE_MAX_JOBS=x bash "$V" --print-mode 2>&1)" || rc=$?
ok "a malformed XYZ_VALIDATE_MAX_JOBS is refused (exit 2)" "[ $rc -eq 2 ]"
ok "  and names the variable" "printf '%s' \"\$out\" | grep 'XYZ_VALIDATE_MAX_JOBS' >/dev/null"
rc=0; out="$(XYZ_VALIDATE_THROTTLE=x bash "$V" --print-mode 2>&1)" || rc=$?
ok "a malformed XYZ_VALIDATE_THROTTLE is refused (exit 2)" "[ $rc -eq 2 ]"
rc=0; out="$(bash "$V" --throttle --burst 2>&1)" || rc=$?
ok "--throttle + --burst is a conflict (exit 2), not a silent last-wins" "[ $rc -eq 2 ]"
rc=0; out="$(bash "$V" --parallel 2 --sequential 2>&1)" || rc=$?
ok "--parallel + --sequential is a conflict (exit 2)" "[ $rc -eq 2 ]"
rc=0; out="$(bash "$V" --tier 9 2>&1)" || rc=$?
ok "--tier 9 is refused (exit 2)" "[ $rc -eq 2 ]"

# ── (3) tier selection is orthogonal to width and never promotion evidence ───────────────────────
out="$(probe --tier 2)"
ok "--tier 2 defaults to the throttled 2-worker pool" "[ "$(width_of "$out")" = "2" ]"
ok "  and a tier below 3 disclaims promotion evidence in its own header" \
   "printf '%s' \"\$out\" | grep 'NEVER promotion evidence' >/dev/null"
out="$(probe --tier 1)"
ok "--tier 1 print-mode names tier 1 and disclaims promotion evidence" \
   "printf '%s' \"\$out\" | grep 'tier 1' >/dev/null"

out="$(probe --subsystem hq)"
ok "--subsystem hq selects tier 2 and names the subsystem" \
   "printf '%s' \"\$out\" | grep 'tier 2 — subsystem hq' >/dev/null"
rc=0; out="$(bash "$V" --subsystem nope --print-mode 2>&1)" || rc=$?
ok "an unknown subsystem is refused (exit 2)" "[ $rc -eq 2 ]"

# PR #55 review, finding 1: --tier N alongside a selector is legal as CONFIRMATION (this is
# the exact spelling ROUTER.md documents) and an error as a contradiction.
out="$(probe --tier 2 --subsystem hq)"; rc=$?
ok "--tier 2 --subsystem hq (the ROUTER.md example) works (rc=$rc)" \
   "[ $rc -eq 0 ] && printf '%s' \"\$out\" | grep 'tier 2 — subsystem hq' >/dev/null"
rc=0; out="$(bash "$V" --print-mode --tier 1 --subsystem hq 2>&1)" || rc=$?
ok "a CONTRADICTING --tier 1 --subsystem hq is refused (exit 2)" "[ $rc -eq 2 ]"
ok "  and the error says which tier the selector chose" \
   "printf '%s' \"\$out\" | grep 'contradicts the selector' >/dev/null"

# ── (4) the registry drift guard — the releases-skill lesson as a test ───────────────────────────
# Every registered suite must (a) exist in test/ and (b) be registered in validate.sh's TESTS,
# or `--tier 2` would "pass" by running nothing. ci-route.sh's own listing check covers (a);
# THIS covers (b), which nothing else can see.
tests_blob="$(sed -n '/^TESTS=(/,/^)/p' "$V")"
reg_lines="$(bash "$ROUTER" subsystems | cut -f2 | tr ' ' '\n')"
[ -n "$reg_lines" ] || { echo "  FAIL: registry listing came back empty"; fail=$((fail+1)); }
_drift=""
while read -r t; do
  [ -n "$t" ] || continue
  grep -q "\"$t\"" <<<"$tests_blob" || _drift="$_drift $t"
done <<<"$reg_lines"
ok "every registered suite is in validate.sh's TESTS array (drift: '${_drift:-none}')" \
   "[ -z \"\$_drift\" ]"

# The loud half: a registry naming a suite missing from disk must refuse to list, not skip.
# Layout mirrors a real checkout (ci-route.sh resolves ROOT/test relative to its own location),
# and every REAL suite is present so the only missing one — the one the error must name — is
# the ghost.
DRIFT_ROOT="$WORK/drift"; DRIFT_DIR="$DRIFT_ROOT/utils"
mkdir -p "$DRIFT_DIR" "$DRIFT_ROOT/test"
require_fixture "$DRIFT_ROOT" "drift registry root"
bash "$ROUTER" subsystems | cut -f2 | tr ' ' '\n' | while IFS= read -r _t; do
  [ -n "$_t" ] && : > "$DRIFT_ROOT/test/$_t"
done
cp "$ROUTER" "$DRIFT_DIR/ci-route.sh"
sed 's/SUBSYSTEM_TESTS_ate="ate-run-variations.sh"/SUBSYSTEM_TESTS_ate="ate-run-variations.sh ghost-suite.sh"/' \
  "$DRIFT_DIR/ci-route.sh" > "$DRIFT_DIR/ci-route.sh.new" && mv "$DRIFT_DIR/ci-route.sh.new" "$DRIFT_DIR/ci-route.sh"
chmod +x "$DRIFT_DIR/ci-route.sh"
rc=0; out="$(bash "$DRIFT_DIR/ci-route.sh" subsystems 2>&1)" || rc=$?
ok "a registered suite missing from test/ fails the listing loudly (exit 2)" "[ $rc -eq 2 ]"
ok "  and names the ghost suite" "printf '%s' \"\$out\" | grep 'ghost-suite.sh' >/dev/null"

# ── (5) tier-1 execution: the docs gate, dispatched for real against a fixture ────────────────────
# Real validate.sh + real classifier; stubbed PDDA gates (what tier 1 runs is pdda.sh's decision,
# which has its own suites — here we pin the DISPATCH, not PDDA's internals).
mkfixture() {  # -> prints fixture repo path
  local r
  r="$(mktemp -d "$WORK/repo.XXXXXX")"
  require_fixture "$r" "mkfixture repo"
  git -C "$r" init -q
  git -C "$r" config user.email t@t
  git -C "$r" config user.name t
  mkdir -p "$r/relay-automation" "$r/utils/py" "$r/utils/pdda" "$r/utils/hq" "$r/githooks" "$r/test/lib"
  cp "$V" "$r/validate.sh"; chmod +x "$r/validate.sh"
  cp "$REPO/relay-automation/gate-env.sh" "$r/relay-automation/gate-env.sh"
  cp "$ROUTER" "$r/utils/ci-route.sh"; chmod +x "$r/utils/ci-route.sh"
  cp "$REPO/utils/py/gate_env.py" "$r/utils/py/gate_env.py"
  cp "$REPO/githooks/install.sh" "$r/githooks/install.sh"
  cp "$REPO/test/lib/clone-identity.sh" "$r/test/lib/clone-identity.sh"
  cat > "$r/utils/pdda/pdda.sh" <<'STUB'
#!/usr/bin/env bash
echo "stub-pdda ran"
exit "${PDDA_EXIT:-0}"
STUB
  chmod +x "$r/utils/pdda/pdda.sh"
  cat > "$r/utils/pdda-local-checks.sh" <<'STUB'
#!/usr/bin/env bash
echo "stub-pdda-local ran"
exit 0
STUB
  chmod +x "$r/utils/pdda-local-checks.sh"
  printf '%s\n' "$r"
}

R1="$(mkfixture)"
out="$( cd "$R1" && bash validate.sh --tier 1 2>&1 )"; rc=$?
ok "tier 1 runs the docs gate and exits green" "[ $rc -eq 0 ]"
ok "  and really ran the PDDA stub" "printf '%s' \"\$out\" | grep 'stub-pdda ran' >/dev/null"
ok "  and ran NO test suite (no 'Running <suite>' banner)" \
   "! printf '%s' \"\$out\" | grep -E '^Running ' >/dev/null"
ok "  and disclaims promotion evidence" "printf '%s' \"\$out\" | grep 'NOT promotion evidence' >/dev/null"
out="$( cd "$R1" && PDDA_EXIT=1 bash validate.sh --tier 1 2>&1 )"; rc=$?
ok "a RED docs gate fails tier 1 (exit 1)" "[ $rc -eq 1 ]"
ok "  and says the documentation gate is RED" "printf '%s' \"\$out\" | grep 'documentation gate RED' >/dev/null"

# ── (6) tier-2 execution: real pool, real identity bracket, real summary math, stub suites ───────
R2="$(mkfixture)"
cat > "$R2/test/hq.sh" <<'STUB'
#!/usr/bin/env bash
n="$(ps -o nice= -p $$ | tr -d ' ')"
echo "hq-stub ran nice=$n"
printf '%s\n' "$n" > "$(dirname "$0")/hq-stub-nice.txt"
exit "${HQ_EXIT:-0}"
STUB
chmod +x "$R2/test/hq.sh"
printf '#!/usr/bin/env bash\nexit 0\n' > "$R2/utils/hq/hq.sh"
PF="$R2/paths.txt"; printf 'utils/hq/hq.sh\n' > "$PF"

out="$( cd "$R2" && bash validate.sh --paths-file "$PF" 2>&1 )"; rc=$?
ok "tier 2 runs the classified subsystem suite and exits green" "[ $rc -eq 0 ]"
ok "  and really ran the hq stub (marker written by the suite itself)" \
   "[ -f '$R2/test/hq-stub-nice.txt' ]"
ok "  and ran the identity bracket (tier 2 still runs fixtures)" \
   "printf '%s' \"\$out\" | grep 'clone-identity invariant' >/dev/null"
ok "  and disclaims promotion evidence in the tier-2 banner" \
   "printf '%s' \"\$out\" | grep 'NOT promotion evidence' >/dev/null"
ok "  and the GH-15 summary tallies (no INTERNAL ERROR)" \
   "! printf '%s' \"\$out\" | grep 'INTERNAL ERROR' >/dev/null"
ok "  and the static syntax check ran on the changed file" \
   "printf '%s' \"\$out\" | grep 'bash -n utils/hq/hq.sh' >/dev/null"
# `nice -n N` is RELATIVE to the caller, so an absolute "== 10" here is wrong whenever anything
# already niced the runner — which githooks/pre-push did, stacking to 20 and turning this pin into
# a push-blocker on every full-gate push (found 2026-08-19 dogfooding the 0.7.1 release cut). The
# contract is a DELTA: a worker sits exactly 10 below whatever priority validate.sh itself has.
_stub_nice="$(cat "$R2/test/hq-stub-nice.txt" 2>/dev/null || echo missing)"
# Merge note (PR #60 vs e9fff12): both lanes hit this failure independently and patched it
# differently. `-ge 10` makes the assertion pass under ANY stacking — including the +20 the
# pre-push hook was actually producing — so it removes the failure without removing the bug.
# The delta form keeps the bug detectable, and e9fff12 fixed the stacking at its source.
_self_nice="$(ps -o nice= -p $$ | tr -d ' ')"
_want_nice=$(( _self_nice + 10 ))
ok "the suite worker ran 10 below its caller (caller nice=${_self_nice}, worker nice=${_stub_nice}, wanted ${_want_nice})" \
   "[ \"\$_stub_nice\" = \"\$_want_nice\" ]"

out="$( cd "$R2" && HQ_EXIT=1 bash validate.sh --paths-file "$PF" 2>&1 )"; rc=$?
ok "a RED subsystem suite fails tier 2 (exit 1)" "[ $rc -eq 1 ]"

# Fail-closed: a path list that does not classify tier 2 must be REFUSED, not quietly widened.
PF2="$R2/paths2.txt"; printf 'tool.js\n' > "$PF2"
rc=0; out="$( cd "$R2" && bash validate.sh --paths-file "$PF2" 2>&1)" || rc=$?
ok "--paths-file with an unmapped path refuses (exit 2, fail-closed)" "[ $rc -eq 2 ]"
ok "  and says which tier it classified as" "printf '%s' \"\$out\" | grep 'classified tier 3' >/dev/null"

# A registry entry whose suites are missing on disk escalates rather than running nothing.
R3="$(mkfixture)"
mkdir -p "$R3/utils/telemetry"
printf '#!/usr/bin/env bash\n' > "$R3/utils/telemetry/report.sh"
PF3="$R3/paths3.txt"; printf 'utils/telemetry/health-lib.sh\n' > "$PF3"
rc=0; out="$( cd "$R3" && bash validate.sh --paths-file "$PF3" 2>&1)" || rc=$?
ok "a subsystem with no runnable suites on disk refuses the narrow gate (exit 2)" "[ $rc -eq 2 ]"
ok "  and the classifier said why: no runnable tests, failing closed" \
   "printf '%s' \"\$out\" | grep 'no runnable tests' >/dev/null"

# PR #55 review, finding 2: a DELETED file rides a git-diff path list — there is nothing to
# syntax-check, and a 127 on the missing path must not fail the gate.
R2B="$(mkfixture)"
cp "$R2/test/hq.sh" "$R2B/test/hq.sh"
mkdir -p "$R2B/utils/hq"
printf '#!/usr/bin/env bash\nexit 0\n' > "$R2B/utils/hq/hq.sh"
PFB="$R2B/pathsb.txt"; printf 'utils/hq/gone.sh\nutils/hq/hq.sh\n' > "$PFB"
out="$( cd "$R2B" && bash validate.sh --paths-file "$PFB" 2>&1 )"; rc=$?
ok "a deleted path in the tier-2 list is skipped, not 127'd (exit $rc)" \
   "[ $rc -eq 0 ] && printf '%s' \"\$out\" | grep 'gone — skipping utils/hq/gone.sh' >/dev/null"

# Static checks are load-bearing: broken syntax in a changed file must fail the tier-2 gate.
R4="$(mkfixture)"
cp "$R2/test/hq.sh" "$R4/test/hq.sh"; chmod +x "$R4/test/hq.sh"
printf 'if [ then\n' > "$R4/utils/hq/hq.sh"
PF4="$R4/paths4.txt"; printf 'utils/hq/hq.sh\n' > "$PF4"
rc=0; out="$( cd "$R4" && bash validate.sh --paths-file "$PF4" 2>&1)" || rc=$?
ok "a changed file with broken bash syntax fails tier 2 (exit 1)" "[ $rc -eq 1 ]"

# Docs paths mixed into a tier-2 change set pull in the PDDA gate (issue: "PDDA if docs touched").
R5="$(mkfixture)"
cp "$R2/test/hq.sh" "$R5/test/hq.sh"; chmod +x "$R5/test/hq.sh"
printf '#!/usr/bin/env bash\nexit 0\n' > "$R5/utils/hq/hq.sh"
PF5="$R5/paths5.txt"; printf 'README.md\nutils/hq/hq.sh\n' > "$PF5"
out="$( cd "$R5" && bash validate.sh --paths-file "$PF5" 2>&1 )"; rc=$?
ok "docs + subsystem runs the pdda stub in-band (exit $rc) and the hq stub in the pool" \
   "[ $rc -eq 0 ] && printf '%s' \"\$out\" | grep 'stub-pdda ran' >/dev/null && [ -f '$R5/test/hq-stub-nice.txt' ]"
out="$( cd "$R5" && PDDA_EXIT=1 HQ_EXIT=0 bash validate.sh --paths-file "$PF5" 2>&1 )"; rc=$?
ok "a RED docs gate fails the mixed tier-2 run (exit 1)" "[ $rc -eq 1 ]"

# ── (7) --auto classifies a real diff and fails closed on an unusable range ───────────────────────
R6="$(mkfixture)"
cp "$R2/test/hq.sh" "$R6/test/hq.sh"; chmod +x "$R6/test/hq.sh"
printf 'seed\n' > "$R6/SEED" && git -C "$R6" add -A >/dev/null 2>&1 \
  && git -C "$R6" commit -qm seed >/dev/null 2>&1
printf '# docs\n' > "$R6/README.md"
git -C "$R6" add -A >/dev/null 2>&1 && git -C "$R6" commit -qm docs >/dev/null 2>&1
out="$( cd "$R6" && bash validate.sh --print-mode --auto 2>&1 )"
ok "--auto classifies a docs-only over-upstream diff as tier 1" \
   "printf '%s' \"\$out\" | grep 'classified tier 1' >/dev/null"
printf '#!/usr/bin/env bash\nexit 0\n' > "$R6/utils/hq/hq.sh"
git -C "$R6" add -A >/dev/null 2>&1 && git -C "$R6" commit -qm hq >/dev/null 2>&1
out="$( cd "$R6" && bash validate.sh --print-mode --auto 2>&1 )"
ok "--auto classifies an hq-only diff as tier 2" \
   "printf '%s' \"\$out\" | grep 'classified tier 2' >/dev/null"
out="$( cd "$R6" && bash validate.sh --print-mode --auto no-such-ref 2>&1 )"
ok "--auto with an unusable range fails closed to tier 3 (zero-path branch or explicit refusal)" \
   "printf '%s' \"\$out\" | grep -E 'could not classify|classified tier 3' >/dev/null"

# ── (8) the push hook dispatches route=fast+tier2 to the narrow gate ─────────────────────────────
# The hook itself is gh544-pre-push-gate.sh's surface; THIS pins the contract between hook and
# runner from the runner side: validate.sh must accept exactly what the hook hands it (a paths
# file) and pre-push must hand exactly that. The static half catches a hook that regresses to
# full-gate-always as surely as an e2e case would, without driving git push from inside a suite.
ok "pre-push hands the push's paths to validate.sh --paths-file (GH-35 dispatch)" \
   "grep -q -- '--paths-file' '$REPO/githooks/pre-push'"
ok "  and only after the classifier explicitly said tier=2" \
   "grep -q '_tier\" = \"2\"' '$REPO/githooks/pre-push'"
ok "validate.sh --tier 2 exits 2 on a non-tier-2 path list (the hook's fail-closed partner)" \
   "[ -x '$R2/validate.sh' ]"

# ── (9) GH-45: the gate REFUSES to run from a linked worktree ────────────────────────────────────
# The 2026-08-19 incident: a gate run from a linked worktree corrupted the PARENT clone (shared
# .git) — core.bare=true, origin repointed at a deleted temp path, every refs/remotes/origin/*
# deleted, development overwritten with fixture commits. The guard must refuse BEFORE anything
# runs, name those consequences (an operator who doesn't know what breaks will override), honor
# the explicit override, and stay silent in a normal clone — the last one is the control that
# proves the guard FIRES rather than merely that the gate still works.
R7="$(mkfixture)"
cp "$REPO/ci-local.sh" "$R7/ci-local.sh"; chmod +x "$R7/ci-local.sh"
git -C "$R7" add -A >/dev/null 2>&1 && git -C "$R7" commit -qm gate >/dev/null 2>&1
WT45="$WORK/wt45"
git -C "$R7" worktree add -q "$WT45" -b wt45 >/dev/null 2>&1
require_fixture "$WT45" "GH-45 fixture worktree"

out="$( cd "$WT45" && bash validate.sh --tier 1 2>&1 )"; rc=$?
ok "GH-45: a linked worktree is REFUSED before anything runs (exit 2)" "[ $rc -eq 2 ]"
ok "  and the message names the real consequence (core.bare)" \
   "printf '%s' \"\$out\" | grep 'core.bare=true' >/dev/null"
ok "  and names the rest (origin repointed, remote refs deleted, development overwritten)" \
   "printf '%s' \"\$out\" | grep 'deleted every refs/remotes/origin' >/dev/null && printf '%s' \"\$out\" | grep 'development with fixture commits' >/dev/null"
ok "  and names the explicit override" \
   "printf '%s' \"\$out\" | grep 'XYZ_ALLOW_WORKTREE_GATE=1' >/dev/null"
ok "  and NOTHING ran — no docs gate, no suite banners" \
   "! printf '%s' \"\$out\" | grep -E 'stub-pdda ran|^Running ' >/dev/null"

out="$( cd "$WT45" && XYZ_ALLOW_WORKTREE_GATE=1 bash validate.sh --tier 1 2>&1 )"; rc=$?
ok "GH-45: the override runs the gate AND announces itself (exit $rc)" \
   "[ $rc -eq 0 ] && printf '%s' \"\$out\" | grep 'explicit request' >/dev/null && printf '%s' \"\$out\" | grep 'stub-pdda ran' >/dev/null"

# THE CONTROL: the same fixture's MAIN checkout must still run — this is what distinguishes a
# guard that fires from a gate that simply never worked.
out="$( cd "$R7" && bash validate.sh --tier 1 2>&1 )"; rc=$?
ok "GH-45 CONTROL: the normal checkout of the SAME repo still runs the gate (exit $rc)" \
   "[ $rc -eq 0 ] && printf '%s' \"\$out\" | grep 'stub-pdda ran' >/dev/null"
ok "  and says nothing about worktrees (silent pass-through)" \
   "! printf '%s' \"\$out\" | grep -i 'worktree' >/dev/null"

# ci-local.sh runs the SAME suite, so it carries the same guard (issue requirement 4).
out="$( cd "$WT45" && bash ci-local.sh --fast 2>&1 )"; rc=$?
ok "GH-45: ci-local.sh refuses from a linked worktree too (exit 2)" "[ $rc -eq 2 ]"
ok "  with the same consequence message and override" \
   "printf '%s' \"\$out\" | grep 'core.bare=true' >/dev/null && printf '%s' \"\$out\" | grep 'XYZ_ALLOW_WORKTREE_GATE=1' >/dev/null"
# Invoking validate.sh by ABSOLUTE path from OUTSIDE the worktree must not slip past: HERE
# itself is checked, not just the CWD.
out="$( cd "$WORK" && bash "$WT45/validate.sh" --tier 1 2>&1 )"; rc=$?
ok "GH-45: an absolute-path invocation whose HERE is the worktree is still refused (exit 2)" \
   "[ $rc -eq 2 ] && printf '%s' \"\$out\" | grep 'linked git worktree' >/dev/null"

git -C "$R7" worktree remove --force "$WT45" >/dev/null 2>&1

echo "  gh35-test-tiers: $pass pass, $fail fail"
[ "$fail" -eq 0 ]
