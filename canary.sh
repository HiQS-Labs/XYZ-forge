#!/usr/bin/env bash
# canary.sh — the FIRST rung of the gate: a clean-room, network-free, sub-minute smoke tier over
# the surfaces that carry this repo's value. It answers one question before anything else is paid
# for: do the core XYZ surfaces still start, parse, and coordinate?
#
#   tick kernel   bin/tick            init → claim → contended claim LOSES → release --to → take
#                                     (handoff) → done → project → analyze, in a throwaway repo
#   relay         relay-drive.sh      --help in BOTH runtimes; poll.sh --help in BOTH runtimes;
#                 relay-xyz skill     find-harness.sh --check resolves this harness + tick
#   consult       consult.sh          --help in BOTH runtimes
#   marathon      marathon.sh         --dry-run on a canary-owned one-phase plan in BOTH runtimes;
#                                     marathon-drive.sh --help; marathon-yaml parses the plan
#   jog           utils/py/jog_run.py the serial (lanes-off) supervisor: --help, and --dry-run against
#                                     a COPY of the committed releases ledger in the sandbox
#   static floor  bash -n on every top-level shell entry point, node --check on bin/ + src/,
#                 py_compile + import of every utils/py module
#
# What it is NOT: a replacement for ./validate.sh (the gate) or ci-local.sh (the qualifying run).
# It never calls a model, never touches the network, and never writes inside the repo tree — the
# last check proves the working tree and the clone's .git state (config, remotes, HEAD) are
# exactly as they were before the run.
#
# Usage:
#   ./canary.sh                      # both runtimes (Python default + XYZ_PYTHON=0 Bash twin)
#   ./canary.sh --runtime python     # Python default only
#   ./canary.sh --runtime bash       # Bash twin only
#   ./canary.sh --list               # print the check names and exit
#   ./canary.sh --keep               # keep the sandbox for inspection (path printed at the end)
#
# Environment:
#   XYZ_CANARY_SANDBOX   — sandbox dir (default: mktemp under $TMPDIR; removed unless --keep).
#                          Use-boundary guarded (GH-567): it must resolve outside the harness
#                          tree, must not be / or the home directory, and only a directory
#                          carrying this run's logs/ marker is ever removed at teardown.
#   XYZ_CANARY_TIMEOUT_S — per-check wall-clock cap in seconds (default 60)
#
# Exit: 0 every check passed · 1 one or more checks failed · 2 usage.
#
# Porting to hosted CI: .github/workflows/canary.yml already runs this file; it is
# `workflow_dispatch`-only until the tier is accepted. Arm it by adding
# `push:` / `pull_request:` triggers there — nothing in this file needs to change.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNTIMES="1 0"
KEEP=0
LIST=0
TIMEOUT_S="${XYZ_CANARY_TIMEOUT_S:-60}"

usage() {
  sed -n '2,42p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --runtime)
      shift
      case "${1:-}" in
        python) RUNTIMES="1" ;;
        bash)   RUNTIMES="0" ;;
        both)   RUNTIMES="1 0" ;;
        *) echo "canary: --runtime expects python|bash|both" >&2; exit 2 ;;
      esac ;;
    --keep) KEEP=1 ;;
    --list) LIST=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "canary: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

# ---------------------------------------------------------------------------------------------
# harness
# ---------------------------------------------------------------------------------------------
PASS=0
FAIL=0
FAILED_NAMES=""
LOG_DIR=""

now_ms() {
  if [ -n "${EPOCHREALTIME:-}" ]; then
    local s="${EPOCHREALTIME%%.*}" f="${EPOCHREALTIME##*.}"
    echo "$(( 10#$s * 1000 + 10#${f:0:3} ))"
  else
    echo "$(( $(date +%s) * 1000 ))"
  fi
}

rt_label() { [ "$1" = "1" ] && echo python || echo bash; }

# sandbox_resolve <path> — print the resolved path, or fail. This is the use-boundary guard
# (GH-567): a derivation-site check never covers a path passed in from elsewhere, so every
# dangerous use of the sandbox re-proves it here instead of trusting the setup line. Refuses an
# empty path, a path that does not resolve to a directory, and anything inside the harness tree.
# The in-check `rm -rf`s at tick-repo/jog-target/marathon-target are descendants of a SANDBOX
# that passed this guard and the setup refusals below (never /, never home), and SANDBOX is a
# shell variable an external process cannot mutate mid-run — so one guard here plus the setup
# refusals covers every delete target in this file.
sandbox_resolve() {
  local p="${1:-}" rp
  [ -n "$p" ] || return 1
  rp="$(cd -- "$p" 2>/dev/null && pwd -P)" || return 1
  case "$rp" in "$ROOT"|"$ROOT"/*) return 1 ;; esac
  printf '%s\n' "$rp"
}

# sandbox_deletable — the teardown guard. This run may only remove a directory that (a) still
# passes sandbox_resolve, (b) is not the filesystem root or the resolved home, and (c) carries
# this run's logs/ ownership marker. On any doubt the sandbox is KEPT, never deleted.
sandbox_deletable() {
  local rp hp
  rp="$(sandbox_resolve "$SANDBOX")" || return 1
  hp="$(sandbox_resolve "${HOME:-}" 2>/dev/null)" || hp=""
  if [ "$rp" = "/" ]; then return 1; fi
  if [ -n "$hp" ] && [ "$rp" = "$hp" ]; then return 1; fi
  [ -d "$rp/logs" ] || return 1
  printf '%s\n' "$rp"
}

# GH-564: `git status` cannot see .git/config or refs — the exact contamination class behind the
# separate-full-clone rail (core.bare flipped, origin repointed, identity appended, HEAD reset).
# The containment check snapshots the FULL local config plus HEAD before the run and diffs it
# after, so ANY local config write fires, not just the four telltales. Hook FILES planted under
# .git/hooks remain out of scope; a changed hooksPath (a config key) does not.
git_state_fingerprint() {
  printf 'head=%s\n' "$(git -C "$ROOT" rev-parse HEAD 2>/dev/null)"
  git -C "$ROOT" config --local --list 2>/dev/null
}

# run_check <name> <command...>
# The command runs in a subshell with the sandbox as CWD. Pass when it exits 0.
run_check() {
  local name="$1"; shift
  if [ "$LIST" = "1" ]; then echo "$name"; return 0; fi
  local log="$LOG_DIR/$name.log" t0 t1 rc
  t0="$(now_ms)"
  # Checks are shell functions, so `timeout(1)` cannot wrap them; a background watchdog does.
  # The resolve before the cd is the per-check use boundary: `cd ""` is a silent no-op, so a
  # sandbox that went missing or invalid mid-run must FAIL the check, not run it in-tree.
  local pid wd
  ( sandbox_resolve "$SANDBOX" >/dev/null && cd "$SANDBOX" && "$@" ) >"$log" 2>&1 &
  pid=$!
  # The watchdog owns no stdio and takes its sleep down with it, so a finished check never leaves
  # an orphan holding a caller's pipe open (`./canary.sh | tee` would otherwise block for TIMEOUT_S).
  ( trap 'kill $s 2>/dev/null; wait $s 2>/dev/null; exit 0' TERM; sleep "$TIMEOUT_S" & s=$!; wait $s; kill "$pid" 2>/dev/null ) </dev/null >/dev/null 2>&1 &
  wd=$!
  wait "$pid"; rc=$?
  kill "$wd" 2>/dev/null; wait "$wd" 2>/dev/null
  t1="$(now_ms)"
  if [ $rc -eq 0 ]; then
    PASS=$((PASS + 1))
    printf '  ok    %-34s %6d ms\n' "$name" "$((t1 - t0))"
  else
    FAIL=$((FAIL + 1))
    FAILED_NAMES="$FAILED_NAMES $name"
    printf '  FAIL  %-34s %6d ms  (exit %d)\n' "$name" "$((t1 - t0))" "$rc"
    sed 's/^/        | /' "$log" | tail -n 25
  fi
}

# expect_help <pattern> <command...> — exit 0 AND stdout+stderr contains <pattern>.
expect_help() {
  local pattern="$1"; shift
  local out
  out="$("$@" 2>&1)" || { echo "exit $? from: $*"; printf '%s\n' "$out"; return 1; }
  printf '%s\n' "$out" | grep -q -- "$pattern" || { echo "output lacks '$pattern'"; printf '%s\n' "$out"; return 1; }
}

# help_in_runtime <XYZ_PYTHON value> <pattern> <command...> — expect_help under one runtime twin.
help_in_runtime() {
  local rt="$1"; shift
  XYZ_PYTHON="$rt" expect_help "$@"
}

# ---------------------------------------------------------------------------------------------
# checks
# ---------------------------------------------------------------------------------------------
check_shell_syntax() {
  local f bad=0
  for f in "$ROOT"/relay-automation/*.sh "$ROOT"/utils/*.sh "$ROOT"/skills/*/*.sh "$ROOT"/skills/*/*/*.sh \
           "$ROOT"/githooks/*.sh "$ROOT"/validate.sh "$ROOT"/ci-local.sh "$ROOT"/canary.sh \
           "$ROOT"/bin/validate-relay-block; do
    [ -f "$f" ] || continue
    bash -n "$f" || { echo "syntax: $f"; bad=1; }
  done
  return $bad
}

check_node_syntax() {
  local f bad=0
  for f in "$ROOT"/bin/tick "$ROOT"/bin/marathon-yaml "$ROOT"/src/*.js; do
    node --check "$f" || { echo "syntax: $f"; bad=1; }
  done
  return $bad
}

check_python_ports() {
  # compileall writes .pyc next to source, so it compiles a COPY in the sandbox, and the import
  # probe sets PYTHONDONTWRITEBYTECODE=1 for the same reason — "never writes inside the repo
  # tree" stays literally true instead of merely gitignored.
  rm -rf "$SANDBOX/py-floor"
  cp -R "$ROOT/utils/py" "$SANDBOX/py-floor" || return 1
  python3 -m compileall -q "$SANDBOX/py-floor" || return 1
  ( cd "$ROOT/utils/py" && PYTHONDONTWRITEBYTECODE=1 python3 - <<'PY'
import importlib, pathlib, sys
bad = 0
for p in sorted(pathlib.Path(".").glob("*.py")):
    if "-" in p.stem or p.stem.startswith("_"):
        continue  # hyphenated shims are exec-only; private helpers are imported by their owners
    try:
        importlib.import_module(p.stem)
    except Exception as e:  # noqa: BLE001 — any import-time failure is the finding
        print(f"import {p.stem}: {type(e).__name__}: {e}")
        bad = 1
sys.exit(bad)
PY
  )
}

# The coordination kernel, end to end, in a repo that is not this one. TICK_REPO_ROOT pins the
# root so the kernel's wrong-CWD guard cannot route events into the real clone.
check_tick_lifecycle() {
  local repo="$SANDBOX/tick-repo" tick="$ROOT/bin/tick" out
  rm -rf "$repo"; mkdir -p "$repo"
  git -C "$repo" init -q
  git -C "$repo" -c user.email=canary@xyz -c user.name=canary commit -q --allow-empty -m init
  export TICK_REPO_ROOT="$repo"
  "$tick" init || return 1
  "$tick" claim CANARY --agent alpha --paths 'docs/**' || { echo "first claim must win"; return 1; }
  if "$tick" claim CANARY --agent beta --paths 'docs/**'; then
    echo "contended claim must LOSE (exit 1) — two agents hold one token"; return 1
  fi
  out="$("$tick" info CANARY)" || return 1
  printf '%s\n' "$out" | grep -q '^claimer: *alpha$' || { echo "info lacks claimer alpha"; printf '%s\n' "$out"; return 1; }
  "$tick" release CANARY --agent alpha --to beta || return 1
  out="$("$tick" take --agent beta)" || return 1
  printf '%s\n' "$out" | grep -q 'won: CANARY' || { echo "handoff take did not win CANARY"; printf '%s\n' "$out"; return 1; }
  "$tick" done CANARY --agent beta --note canary || return 1
  "$tick" project || return 1
  [ -s "$repo/.tick/STATE.md" ] || { echo ".tick/STATE.md not projected"; return 1; }
  out="$("$tick" analyze --format json)" || return 1
  printf '%s\n' "$out" | python3 -c '
import json, sys
d = json.load(sys.stdin)
n = d["window"]["total_events"]
sys.exit(0 if n >= 4 else (print(f"analyze saw {n} events, expected >= 4") or 1))
' || return 1
  unset TICK_REPO_ROOT
}

# The relay-block structural validator: both deterministic refusals must still fire.
check_relay_block_validator() {
  local v="$ROOT/bin/validate-relay-block" rc
  "$v" "$SANDBOX/does-not-exist.md" >/dev/null 2>&1; rc=$?
  [ $rc -eq 1 ] || { echo "missing file: expected exit 1, got $rc"; return 1; }
  printf 'no header here\n' > "$SANDBOX/no-status.md"
  "$v" "$SANDBOX/no-status.md" >/dev/null 2>&1; rc=$?
  [ $rc -eq 8 ] || { echo "missing STATUS: expected exit 8, got $rc"; return 1; }
}

check_relay_locator() {
  local f
  for f in "$ROOT"/skills/relay-xyz/find-harness.sh "$ROOT"/skills/*/relay-xyz/find-harness.sh; do
    [ -f "$f" ] && { expect_help 'ok  tick CLI' "$f" --check; return $?; }
  done
  echo "relay-xyz skill not found under skills/ (find-harness.sh)"; return 1
}

# Jog is the serial supervisor (lanes off): one task at a time from the jog queue. --dry-run
# simulates the queue against the ledger at --root without a lease, lock, or worktree mutation,
# so it runs against a COPY of the committed releases ledger inside the sandbox.
check_jog_dry_run() {
  local target="$SANDBOX/jog-target" out
  rm -rf "$target"; mkdir -p "$target"
  cp "$ROOT/releases.db" "$ROOT/releases.sql" "$target/"
  git -C "$target" init -q
  git -C "$target" add -A
  git -C "$target" -c user.email=canary@xyz -c user.name=canary commit -q -m ledger
  out="$(python3 "$ROOT/utils/py/jog_run.py" --root "$target" --dry-run --executor marathon --builder agy --reviewer codex 2>&1)" \
    || { echo "exit $? from jog_run.py --dry-run"; printf '%s\n' "$out"; return 1; }
  printf '%s\n' "$out" | grep -q 'jog: \[dry-run\] simulating queue execution' \
    || { echo "jog did not enter dry-run simulation"; printf '%s\n' "$out"; return 1; }
  [ "$(git -C "$target" status --porcelain)" = "" ] \
    || { echo "jog --dry-run mutated the sandbox ledger:"; git -C "$target" status --porcelain; return 1; }
}

check_marathon_yaml() {
  local out
  out="$("$ROOT/bin/marathon-yaml" "$ROOT/canary/fixtures/MARATHON.canary.yaml" --format json)" || return 1
  printf '%s\n' "$out" | python3 -c '
import json, sys
d = json.load(sys.stdin)
ids = [p["id"] for p in d["phases"]]
sys.exit(0 if ids == ["p1"] else (print(f"phases {ids}, expected [p1]") or 1))
'
}

# marathon.sh --dry-run renders the relay file and prints the tick seed, then exits WITHOUT
# driving a turn. The plan lives under this harness (GH-212 exempt); the brief is copied into the
# sandbox target repo; the builder/reviewer binaries are inert stubs on PATH so the preflight
# passes without any real model CLI installed. The stubs shadow PATH-name lookups only — an
# absolute-path builder invocation would bypass them, which is part of why this check asserts the
# orchestrator's dry-run completion rather than any builder output.
check_marathon_dry_run() {  # <XYZ_PYTHON value>
  local rt="$1" target="$SANDBOX/marathon-target-$rt" stub="$SANDBOX/stub-bin" out
  rm -rf "$target"; mkdir -p "$target/canary-briefs" "$stub"
  printf '#!/bin/sh\nexit 0\n' > "$stub/agy"; printf '#!/bin/sh\nexit 0\n' > "$stub/codex"
  chmod +x "$stub/agy" "$stub/codex"
  cp "$ROOT/canary/fixtures/briefs/p1.md" "$target/canary-briefs/p1.md"
  git -C "$target" init -q
  git -C "$target" add -A
  git -C "$target" -c user.email=canary@xyz -c user.name=canary commit -q -m briefs
  out="$(cd "$target" && PATH="$stub:$PATH" XYZ_PYTHON="$rt" MARATHON_ROOT="$target" TICK_REPO_ROOT="$target" \
        "$ROOT/relay-automation/marathon.sh" --plan "$ROOT/canary/fixtures/MARATHON.canary.yaml" \
        --builder agy --pre-advance-cmd true --dry-run 2>&1)" \
    || { echo "exit $? from marathon.sh --dry-run"; printf '%s\n' "$out"; return 1; }
  printf '%s\n' "$out" | grep -q 'tick seed: log task.created MARATHON-P1-TURN' \
    || { echo "dry-run did not print the tick seed"; printf '%s\n' "$out"; return 1; }
  # The twins differ on WHERE the rendered relay goes (Bash writes RELAY.md, Python prints it);
  # the orchestrator's completion line is the parity-neutral proof that every phase rendered.
  printf '%s\n' "$out" | grep -q 'marathon: dry-run complete: 1 phase(s)' \
    || { echo "orchestrator did not report dry-run complete"; printf '%s\n' "$out"; return 1; }
}

check_tree_clean() {
  local after gafter
  after="$(git -C "$ROOT" status --porcelain --untracked-files=all 2>/dev/null)"
  if [ "$after" != "$TREE_BEFORE" ]; then
    echo "the canary changed the repo tree — it must never write inside the harness:"
    diff <(printf '%s\n' "$TREE_BEFORE") <(printf '%s\n' "$after") | sed -n '1,40p'
    return 1
  fi
  gafter="$(git_state_fingerprint)"
  if [ "$gafter" != "$GITSTATE_BEFORE" ]; then
    echo "the canary changed the clone's .git state (config/refs) — the GH-564 class git status cannot see:"
    diff <(printf '%s\n' "$GITSTATE_BEFORE") <(printf '%s\n' "$gafter") | sed -n '1,40p'
    return 1
  fi
  return 0
}

# ---------------------------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------------------------
if [ "$LIST" = "0" ]; then
  for tool in bash git node python3; do
    command -v "$tool" >/dev/null 2>&1 || { echo "canary: missing required tool: $tool" >&2; exit 2; }
  done
  # Snapshot BEFORE anything else, so even a setup misconfiguration that wrote in-tree is caught
  # by the closing containment check instead of being invisible inside the "before" state.
  TREE_BEFORE="$(git -C "$ROOT" status --porcelain --untracked-files=all 2>/dev/null)"
  GITSTATE_BEFORE="$(git_state_fingerprint)"
  SANDBOX="${XYZ_CANARY_SANDBOX:-$(mktemp -d "${TMPDIR:-/tmp}/xyz-canary.XXXXXX")}"
  mkdir -p "$SANDBOX" 2>/dev/null || true
  RP="$(sandbox_resolve "$SANDBOX")" || { echo "canary: sandbox unusable: $SANDBOX" >&2; exit 2; }
  SANDBOX="$RP"
  HP="$(sandbox_resolve "${HOME:-}" 2>/dev/null)" || HP=""
  if [ "$RP" = "/" ] || { [ -n "$HP" ] && [ "$RP" = "$HP" ]; }; then
    echo "canary: sandbox must not be / or the home directory ($RP)" >&2
    exit 2
  fi
  SANDBOX="$RP"
  LOG_DIR="$SANDBOX/logs"; mkdir -p "$LOG_DIR"  # also the ownership marker the teardown guard requires
  T_START="$(now_ms)"
  echo "canary: harness $ROOT"
  echo "canary: sandbox $SANDBOX"
  echo "canary: runtimes $(for r in $RUNTIMES; do rt_label "$r"; done | tr '\n' ' ')"
  echo
else
  SANDBOX="/dev/null"
fi

echo "-- static floor"
run_check shell-syntax          check_shell_syntax
run_check node-syntax           check_node_syntax
run_check python-ports          check_python_ports

echo "-- tick kernel"
run_check tick-lifecycle        check_tick_lifecycle
run_check relay-block-validator check_relay_block_validator

echo "-- relay"
run_check relay-xyz-locator     check_relay_locator
for rt in $RUNTIMES; do
  l="$(rt_label "$rt")"
  run_check "relay-drive-help[$l]"    help_in_runtime "$rt" 'Usage:' "$ROOT/relay-automation/relay-drive.sh" --help
  run_check "poll-help[$l]"           help_in_runtime "$rt" 'Usage:' "$ROOT/relay-automation/poll.sh" --help
done

echo "-- consult"
for rt in $RUNTIMES; do
  l="$(rt_label "$rt")"
  run_check "consult-help[$l]"        help_in_runtime "$rt" 'consult' "$ROOT/relay-automation/consult.sh" --help
done

echo "-- marathon"
run_check marathon-yaml         check_marathon_yaml
run_check marathon-help         expect_help 'Usage:' "$ROOT/relay-automation/marathon.sh" --help
for rt in $RUNTIMES; do
  l="$(rt_label "$rt")"
  run_check "marathon-drive-help[$l]" help_in_runtime "$rt" 'Usage:' "$ROOT/relay-automation/marathon-drive.sh" --help
  run_check "marathon-dry-run[$l]"    check_marathon_dry_run "$rt"
done

echo "-- jog"
run_check jog-help              expect_help 'Jog serial execution runner' python3 "$ROOT/utils/py/jog_run.py" --help
run_check jog-dry-run           check_jog_dry_run

echo "-- containment"
run_check tree-clean            check_tree_clean

[ "$LIST" = "1" ] && exit 0

echo
T_END="$(now_ms)"
printf 'canary: %d passed, %d failed in %d ms\n' "$PASS" "$FAIL" "$((T_END - T_START))"
if [ $FAIL -gt 0 ]; then
  echo "canary: FAILED:$FAILED_NAMES"
  echo "canary: logs in $LOG_DIR"
  KEEP=1
fi
if [ "$KEEP" = "1" ]; then
  echo "canary: sandbox kept at $SANDBOX"
elif DEL_RP="$(sandbox_deletable)"; then
  rm -rf "$DEL_RP"
else
  echo "canary: sandbox NOT deleted — failed the ownership guard, kept at $SANDBOX"
fi
[ $FAIL -eq 0 ]
