#!/usr/bin/env bash
# #131 — --target-root with a separate harness repo was a catch-22: relay-drive's containment
# guard (GH-289) demands the relay file live UNDER the target root, but marathon-drive hardwired
# its `git add` to `git -C <harness root>`, which dies "outside repository" (exit 128) for a relay
# file under the target. No configuration survived both checks. The fix routes the PHASE
# write-set (phase_dir / RELAY.md / ESCALATION.md) commits to the repo CONTAINING phase_dir
# (commit_root), leaving in-repo runs byte-identical and transcripts with the harness root.
#
# Fixture shape mirrors the issue's repro: a scratch harness repo H (MARATHON_ROOT — tick state,
# transcripts, driver lock all live there; the real clone is only READ for its scripts) and a
# separate target repo T driven with --target-root T --phases-dir T/marathon-system.
#
# Discriminating assertions: pre-fix, the driver dies at the render with an unhandled
# CalledProcessError ("outside repository"); post-fix the render AND escalation commits land in T,
# and the in-repo control still commits to its own root exactly as before.
#
# Usage: bash test/synthetic/gh131-marathon-target-root.sh
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$HERE/../.." && pwd)"
TICK="$ROOT_DIR/bin/tick"
DRIVE="$ROOT_DIR/relay-automation/marathon-drive.sh"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh131-target-root.XXXXXX")"
trap '[ -n "$WORK" ] && [ -d "$WORK" ] && rm -rf "$WORK"' EXIT

PASS=0; FAIL=0
pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); [ "${TEST_SOFT_FAIL:-0}" = "1" ] || { echo "gh131: $PASS passed, $FAIL failed"; exit 1; }; }

# GH-567: validate a fixture at the USE boundary — non-empty, inside $WORK, no "..", a directory.
require_fixture() {
  local p="${1:-}"
  case "$p" in
    ""|"$WORK"|"$WORK"..*|*..*) fail "invalid fixture path '$p'"; return 1 ;;
    "$WORK"/*) [ -d "$p" ] || { fail "fixture is not a directory: $p"; return 1; } ;;
    *) fail "fixture escaped the sandbox root $WORK: $p"; return 1 ;;
  esac
}

mk_repo() { # <name> <gitignore-line-or-empty>
  local d="$WORK/$1"
  git init -q "$d"
  git -C "$d" config user.email t@t
  git -C "$d" config user.name t
  [ -n "${2:-}" ] && printf '%s\n' "$2" >"$d/.gitignore"
  mkdir -p "$d/PROJECT/2-WORKING"
  printf '# brief\n\nDo the thing.\n' >"$d/PROJECT/2-WORKING/brief.md"
  git -C "$d" add -A >/dev/null 2>&1
  git -C "$d" commit -q -m seed
  printf '%s' "$d"
}

# Builder stub: records the dispatch, does a round's work in the relay file (the gh514 recipe).
DISPATCH_LOG="$WORK/dispatched.log"
BUILDER_STUB="$WORK/builder-stub"
cat >"$BUILDER_STUB" <<'EOF'
#!/usr/bin/env bash
echo "DISPATCHED" >>"${DISPATCH_LOG:-/dev/null}"
printf '\n### Round 1 · Builder\nwork\n' >>"${RELAY_FILE:-/dev/null}" 2>/dev/null || true
exit 0
EOF
chmod +x "$BUILDER_STUB"

# Reviewer stub: exits 0, never approves — the phase deterministically escalates, which is the
# path that must commit ESCALATION.md to the right repo.
REVIEWER_STUB="$WORK/reviewer-stub"
printf '#!/usr/bin/env bash\nexit 0\n' >"$REVIEWER_STUB"
chmod +x "$REVIEWER_STUB"

# drive <harness-repo> <turn-root> <out> [cross args...] — run marathon-drive with the harness
# scripts (read from the real clone) rooted at a scratch repo.
drive() {
  local hx="$1" turnroot="$2" out="$3"; shift 3
  ( cd "$ROOT_DIR" && XYZ_PYTHON=1 \
      MARATHON_ROOT="$hx" TICK_REPO_ROOT="$hx" TICK_BIN="$TICK" \
      CLAUDE_BIN="$BUILDER_STUB" CODEX_BIN="$REVIEWER_STUB" \
      CLAUDE_TURN_ROOT="$turnroot" RELAY_AGENT=claude-builder \
      DISPATCH_LOG="$DISPATCH_LOG" \
      bash "$DRIVE" --phase-id "gh131-$$" --reviewer codex --builder claude \
        --phase-brief "$turnroot/PROJECT/2-WORKING/brief.md" --round-cap 2 \
        --pre-advance-cmd true --force "$@" ) >"$out" 2>&1
  return $?
}

echo "=== 1. cross-repo: --target-root T + --phases-dir T/marathon-system ==="
HX="$(mk_repo hx)";      require_fixture "$HX" || exit 1   # scratch harness repo: tick/transcript/lock
T="$(mk_repo target)";   require_fixture "$T" || exit 1    # the code repo under relay-drive's guard
: >"$DISPATCH_LOG"
drive "$HX" "$T" "$WORK/cross.out" --target-root "$T" --phases-dir "$T/marathon-system"
rc=$?

if ! grep -q "Traceback (most recent call last)" "$WORK/cross.out"; then
  pass "no unhandled traceback (pre-fix: CalledProcessError at the render git add)"
else
  fail "driver crashed: $(grep -A3 'Traceback' "$WORK/cross.out" | head -5)"
fi
if ! grep -qi "outside repository" "$WORK/cross.out"; then
  pass "no 'outside repository' git failure"
else
  fail "git still routed a target path at the harness root: $(grep -i 'outside repository' "$WORK/cross.out" | head -2)"
fi
# NOTE: no `git log | grep -q` pipelines anywhere in this suite. Under `set -o pipefail`, grep -q
# exiting on a first-match closes the pipe while git is still writing, git dies on SIGPIPE, and
# the pipeline reports failure for a match that succeeded — observed live as a flaky red on the
# escalation assertion while the fail-time dump showed the commit present. Capture, then match.
t_log="$(git -C "$T" log --format=%s)"
case "$t_log" in *"render phase"*)
  pass "relay-file render commit landed in the TARGET repo" ;;
*) fail "no render commit in T (log: $t_log)" ;; esac
case "$t_log" in *"escalation"*)
  pass "escalation record commit landed in the TARGET repo" ;;
*) fail "no escalation commit in T — escalate() still routes to the wrong root" ;; esac
t_files="$(git -C "$T" ls-files)"
case "$t_files" in *marathon-system/*RELAY.md*)
  pass "RELAY.md is tracked in the TARGET repo" ;;
*) fail "RELAY.md not tracked in T (files: $t_files)" ;; esac
case "$t_files" in *marathon-system/*ESCALATION.md*)
  pass "ESCALATION.md is tracked in the TARGET repo" ;;
*) fail "ESCALATION.md not tracked in T" ;; esac
[ "$rc" -ne 1 ] && pass "driver exit $rc is a documented outcome, not a crash/lock code" \
  || fail "driver exited 1 (crash or lock contention): see $WORK/cross.out"

echo "=== 2. in-repo control: no --target-root, default phases-dir, commits stay at root ==="
T2="$(mk_repo t2)"; require_fixture "$T2" || exit 1
: >"$DISPATCH_LOG"
drive "$T2" "$T2" "$WORK/inrepo.out"
rc2=$?
t2_log="$(git -C "$T2" log --format=%s)"
case "$t2_log" in *"render phase"*)
  pass "in-repo run still commits the render to its own root (unchanged)" ;;
*) fail "in-repo run lost its render commit (regression): $t2_log" ;; esac
case "$t2_log" in *"escalation"*)
  pass "in-repo run still commits the escalation record to its own root" ;;
*) fail "in-repo run lost its escalation commit: $t2_log" ;; esac
if ! grep -q "Traceback (most recent call last)" "$WORK/inrepo.out"; then
  pass "in-repo run: no traceback"
else
  fail "in-repo run crashed: $(grep -A3 'Traceback' "$WORK/inrepo.out" | head -5)"
fi
[ "$rc2" -ne 1 ] && pass "in-repo driver exit $rc (documented outcome)" || fail "in-repo driver exited 1"

echo "=== 3. commit-root resolution unit: phase_commit_root picks the containing repo ==="
UNIT="$WORK/unit.py"
mkdir -p "$WORK/nonrepo"   # inside $WORK, deliberately NOT a git repo
cat >"$UNIT" <<EOF
import os, sys
sys.path.insert(0, os.path.join(sys.argv[1], "utils", "py"))
import importlib.util
spec = importlib.util.spec_from_file_location(
    "md", os.path.join(sys.argv[1], "utils", "py", "marathon_drive.py"))
md = importlib.util.module_from_spec(spec)
spec.loader.exec_module(md)

hx, t, nonrepo = sys.argv[2], sys.argv[3], sys.argv[4]
checks = [
    # in-repo (default phases dir under root): root itself, byte-identical target
    (md.phase_commit_root(hx, os.path.join(hx, "marathon-system", "lane1"), None) == hx,
     "in-repo phase_dir -> root"),
    # cross-repo: phase_dir under the target -> the target's toplevel
    (md.phase_commit_root(hx, os.path.join(t, "marathon-system", "lane1"), t) ==
     os.path.realpath(t), "cross-repo phase_dir -> target toplevel"),
    # phases-dir in no git repo at all -> the args.target_root-or-root fallback idiom
    (md.phase_commit_root(hx, os.path.join(nonrepo, "p"), t) == t,
     "non-repo phase_dir -> target_root-or-root fallback"),
    # phase_dir does not exist yet (resolved before makedirs) — walks up to the target
    (md.phase_commit_root(hx, os.path.join(t, "marathon-system", "not-created-yet"), t) ==
     os.path.realpath(t), "nonexistent phase_dir still resolves via its parents"),
]
bad = [label for ok, label in checks if not ok]
for label in bad:
    print("MISMATCH: " + label)
sys.exit(1 if bad else 0)
EOF
if python3 "$UNIT" "$ROOT_DIR" "$HX" "$T" "$WORK/nonrepo" >"$WORK/unit.out" 2>&1; then
  pass "phase_commit_root: in-repo -> root, cross-repo -> containing repo, fallback idiom intact"
else
  fail "phase_commit_root regression: $(cat "$WORK/unit.out")"
fi

echo "gh131: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
