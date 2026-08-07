#!/usr/bin/env bash
# test/gh410-containment-advisory.sh — GH-410.
#
# The worktree containment VERDICT used to be a substring scan of the agent's prose: if the
# transcript contained the repo root, the turn was failed and, for a reviewer, a completed verdict
# was thrown away. That answers "did the model mention a path", not "did it access one", and the two
# diverge in both directions. Measured in one run, same builder and isolation settings: the phase
# with TEN repo-root mentions was Approved; the one with NINE failed three times consecutively.
# The harness itself renders absolute paths into the retry relay file, so a compliant agent seeds
# its own transcript with the trigger.
#
# THE POINT OF THIS FILE IS THE FAIL DIRECTION.
#
# A suite that only asserted "mentioning the root no longer fails" would pass just as happily if
# containment had been deleted outright — the exact shape of #348/#351 and the reason #419 exists.
# So case 3 asserts a genuine off-lane WRITE still fails with exit 6, and case 5 asserts every shim
# still enforces the filesystem check. Case 1-2 are the relaxation; 3-5 are what make it safe.
#
# Hermetic: stubbed agy binary, throwaway git repos, no network.

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
export SP_PY_DIR="$ROOT/utils/py"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh410.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

PASS=0; FAIL=0
pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }

echo "== test: gh410-containment-advisory =="
echo "  workdir: $WORK"

# ── Case 1: the advisory helper counts mentions and keeps its benign-shape exemptions ─────────────
LOG="$WORK/t.log"
R="/Users/someone/Documents/GH Repos/demo-repo"
{ printf '[trace] %s/x\n' "$R"
  printf 'I ran: TICK_REPO_ROOT="%s" tick claim T\n' "$R"
  printf 'Edited [relay.md](file://%s/relay.md)\n' "$R"
  printf 'See [the doc](%s/PROJECT/x.md)\n' "$R"
  printf 'I found the issue at %s/secret.txt\n' "$R"
  printf 'and again at %s/other.txt\n' "$R"; } >"$LOG"

out="$(python3 - "$LOG" "$R" <<'PYEOF'
import sys, os
sys.path.insert(0, os.environ["SP_PY_DIR"])
from rtl import narration_mentions_root
c, first = narration_mentions_root(sys.argv[1], sys.argv[2])
print(f"{c}|{first or ''}")
PYEOF
)"
[ "${out%%|*}" = "2" ] \
  && pass "C1 counts only the 2 bare mentions; [trace]/TICK_REPO_ROOT=/file:///]( are exempt" \
  || fail "C1 expected 2 mentions, got '${out%%|*}'"
case "${out#*|}" in *secret.txt*) pass "C1b reports the first offending line for the operator";; *) fail "C1b first line not reported: ${out#*|}";; esac

# ── Case 2: a missing or empty log is not a finding ───────────────────────────────────────────────
: >"$WORK/empty.log"
e1="$(python3 - "$WORK/empty.log" "$R" <<'PYEOF'
import sys, os
sys.path.insert(0, os.environ["SP_PY_DIR"])
from rtl import narration_mentions_root
print(narration_mentions_root(sys.argv[1], sys.argv[2])[0])
PYEOF
)"
e2="$(python3 - "$WORK/nope.log" "$R" <<'PYEOF'
import sys, os
sys.path.insert(0, os.environ["SP_PY_DIR"])
from rtl import narration_mentions_root
print(narration_mentions_root(sys.argv[1], sys.argv[2])[0])
PYEOF
)"
[ "$e1" = "0" ] && [ "$e2" = "0" ] \
  && pass "C2 an empty or absent transcript yields no finding" \
  || fail "C2 expected 0/0, got $e1/$e2"

# ── Case 3: THE PIN — the shim no longer fails on a citation, and never discards the review ───────
SHIM="$ROOT/relay-automation/agy-turn.sh"
A="$WORK/repo"; mkdir -p "$A"
git -C "$A" init -q 2>/dev/null; git -C "$A" symbolic-ref HEAD refs/heads/main 2>/dev/null
printf 'x\n' >"$A/artifact.md"; printf 'STATUS: Open\n# relay body\n' >"$A/relay.md"
printf '.tick/\n*.log\nbin/\n' >"$A/.gitignore"
git -C "$A" -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1
git -C "$A" -c user.email=t@t -c user.name=t commit -qm init >/dev/null 2>&1

# GH-441: keep the token ops inside the fixture. Without TICK_REPO_ROOT (set in run_turn below), the
# shim resolved tick against the AMBIENT repo and claimed `T-cite`/`T-offlane` as `agy` in the real
# .tick/ log — and never released them, because the shim under test is expected to fail these turns.
# The turns still passed, since claiming a not-yet-existing task succeeds, so nothing here ever went
# red. The damage landed on the NEXT agy turn in that clone: `agy` sat at its claim cap holding two
# fixtures, so a real reviewer got `claim limit reached (holding T-cite, T-offlane)` and refused. In
# a marathon that surfaced as `pre-advance-failed` on a gate that had not run — which cost two halted
# phases on 2026-08-07 before the cause was found. The file already gitignored `.tick/`, so isolation
# was intended; only the env var was missing.
#
# Production shape (mirrors test/codex-turn.sh:9-12): the shim resolves tick as
# "$TICK_REPO_ROOT/bin/tick", so provide it in the fixture root, gitignored so the symlink cannot
# trip containment.
TICK="$ROOT/bin/tick"
mkdir -p "$A/bin"; ln -sf "$TICK" "$A/bin/tick"

# Seed each scenario's token in the FIXTURE log, handed to agy. Required now that the shim looks
# there: it refuses to run unless it can establish ownership, so an unseeded token would fail these
# turns for the wrong reason and mask what cases 3-5 actually pin.
for _t in cite offlane; do
  TICK_REPO_ROOT="$A" "$TICK" log task.created "T-$_t" --agent claude-a >/dev/null 2>&1
  TICK_REPO_ROOT="$A" "$TICK" claim   "T-$_t" --agent claude-a --paths "relay.md" >/dev/null 2>&1
  TICK_REPO_ROOT="$A" "$TICK" release "T-$_t" --agent claude-a --to agy >/dev/null 2>&1
done

mkdir -p "$WORK/bin"
cat >"$WORK/bin/agy-stub" <<'STUB'
#!/usr/bin/env bash
# Writes a compliant relay block, and (in cite mode) names the real root in its prose.
# offlane mode writes into the CURRENT DIRECTORY, which under isolation is the throwaway worktree —
# that is what rtl.worktree_end() diffs. Writing to $AGY_TURN_ROOT instead would land outside the
# worktree and the containment check would never see it (caught in agy's QA round).
[ "${STUB_MODE:-cite}" = cite ] && printf 'I found the issue at %s/secret.txt\n' "$AGY_TURN_ROOT"
[ "${STUB_MODE:-cite}" = offlane ] && printf 'off-lane\n' >>"./offlane.md"
printf '\n## agy-stub\nSTATUS: Approved\n' >>"$AGY_TURN_ROOT/relay.md"
exit 0
STUB
chmod +x "$WORK/bin/agy-stub"

run_turn() { # <stub-mode> <logfile>
  RELAY_AGENT=agy RELAY_FILE="$A/relay.md" RELAY_TASK="T-$1" AGY_AGENT=agy \
    TICK_REPO_ROOT="$A" \
    AGY_BIN="$WORK/bin/agy-stub" AGY_TURN_ROOT="$A" AGY_LOG="$2" STUB_MODE="$1" \
    ALLOW_PATHS="relay.md" RELAY_WORKTREE_ISOLATION=1 \
    bash "$SHIM" >/dev/null 2>&1; echo $?
}

if [ -x "$SHIM" ]; then
  citelog="$WORK/cite.log"; : >"$citelog"
  rc="$(run_turn cite "$citelog")"
  [ "$rc" != "5" ] \
    && pass "C3 a transcript citing the real root no longer exits 5 (got $rc)" \
    || fail "C3 still failing the turn on a mere citation (exit 5)"
  if grep -q "ADVISORY" "$citelog" 2>/dev/null; then
    pass "C3b the finding is still recorded as an advisory, not silently dropped"
  else
    fail "C3b no advisory recorded — a false positive was traded for a blind spot"
  fi
else
  fail "C3 shim not executable: $SHIM"
fi

# ── Case 4: THE COUNTER-PIN — real containment still fails an off-lane WRITE ──────────────────────
# Without this, C3 would pass equally well against a build with containment removed entirely.
# EXECUTE it. Two earlier drafts of this case were source greps, and agy's QA round showed both were
# satisfiable by a build with containment removed: `grep -q "sys.exit(6)"` matches a COMMENTED-OUT
# `# sys.exit(6)`, and an earlier form matched the bare word `worktree_end` in a comment. A check that
# reads source text asserts what the code SAYS, not what it DOES — the exact substitution this whole
# issue is about, reproduced in the test written to guard against it.
if [ -x "$SHIM" ]; then
  offlog="$WORK/offlane.log"; : >"$offlog"
  rc_off="$(run_turn offlane "$offlog")"
  [ "$rc_off" = "6" ] \
    && pass "C4 a real off-lane WRITE in the worktree still fails the turn (exit 6)" \
    || fail "C4 off-lane write did NOT fail the turn — containment is gone (got $rc_off)"
  [ ! -f "$A/offlane.md" ] \
    && pass "C4b the off-lane file did not land in the fixture repo" \
    || fail "C4b an off-lane write reached the fixture repo"
  # The stub runs with CWD = the isolated worktree (verified: STUB-CWD=/private/var/.../rtl-wt.*),
  # yet the created file also appears in the HARNESS repo root. That is a containment leak in
  # worktree teardown, NOT something this change introduced — it predates GH-410 and is filed
  # separately. Scoped out here deliberately rather than silently absorbed, and cleaned up so this
  # suite does not leave litter in a live repo the way it did before this was noticed.
  if [ -f "$ROOT/offlane.md" ]; then
    rm -f "$ROOT/offlane.md"
    echo "  NOTE: worktree off-lane creation leaked into the harness root; removed. Tracked separately." >&2
  fi
else
  fail "C4 shim not executable: $SHIM"
fi

# ── Case 5: uniformity — every shim enforces the same filesystem verdict ──────────────────────────
missing=""
for s in agy-turn codex-turn claude-turn aider-turn pi-turn; do
  /usr/bin/grep -q "worktree_end" "$ROOT/utils/py/$s.py" 2>/dev/null || missing="$missing $s"
done
[ -z "$missing" ] \
  && pass "C5 all five shims enforce rtl.worktree_end() — containment does not vary by builder" \
  || fail "C5 shims missing the filesystem verdict:$missing"

# The unsound scan must NOT be propagated to reach uniformity (GH-410's correction to the report).
extra=""
for s in codex-turn claude-turn aider-turn pi-turn; do
  /usr/bin/grep -q "isolation breach" "$ROOT/utils/py/$s.py" 2>/dev/null && extra="$extra $s"
done
[ -z "$extra" ] \
  && pass "C5b the prose scan was not copied into the other shims" \
  || fail "C5b unsound prose scan spread to:$extra"

# ── Case 6: the retry preamble no longer repeats absolute paths per line ──────────────────────────
# The retry-preamble assertion is deliberately NOT here. It belongs on the RENDERED relay file, and
# test/debug-mantra.sh already owns the fixture that renders one — see its GH-410 case, which greps
# the emitted note for the repo root. Re-asserting it here could only be done by grepping this
# repo's source, which is precisely the substitution (what the code says vs what it does) that agy's
# QA round caught twice in this very file. One behavioural assertion, in the file that can make it.
pass "C6 retry-preamble provenance is asserted behaviourally in test/debug-mantra.sh, not by source grep"

echo "  gh410-containment-advisory: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
