#!/usr/bin/env bash
#
# repro.sh — re-run the probes behind evidence/FINDINGS.md, so no finding rests on trust.
#
# Each probe prints what it expected, what it got, and an explicit PASS/FAIL, where PASS means
# "the finding still reproduces". A finding that stops reproducing is itself news — it means the
# defect was fixed, or the environment differs from the one recorded.
#
# Usage:
#   bash repro.sh                 # run every probe
#   bash repro.sh <name> [...]    # run named probes
#   bash repro.sh --list          # list probe names
#
# Exit: 0 every probe reproduced as recorded · 1 at least one diverged · 2 usage.
#
# Run this from the repo root, un-sandboxed. It writes nothing outside $TMPDIR and never
# modifies the repo.
set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO" || exit 2

PASS=0; FAIL=0

ok()   { printf '  \033[32mPASS\033[0m  %s\n' "$*"; PASS=$((PASS+1)); }
bad()  { printf '  \033[31mFAIL\033[0m  %s\n' "$*"; FAIL=$((FAIL+1)); }
head_() { printf '\n== %s — %s\n' "$1" "$2"; }

# ── F-001 ────────────────────────────────────────────────────────────────────
# The relay-xyz guard's read-exemption inspects only the FIRST WORD of the whole
# command, so a compound `cd X && <read>` is blocked even though the guard's own
# header (line 26) promises "reads are exempt".
probe_guard_read() {
  head_ probe-guard-read "F-001 guard blocks a read inside a compound command"
  local guard="relay-automation/hooks/relay-xyz-guard.sh"
  if [ ! -f "$guard" ]; then bad "guard not found at $guard"; return; fi

  # Drive the guard directly with a synthetic PreToolUse event — same contract the
  # harness uses (stdin JSON, exit 2 = block). Session id is random so no stale
  # proof-of-load marker from a real session can mask the result.
  local sess="repro-$$-$RANDOM"
  local ev_compound ev_bare
  ev_compound=$(printf '{"session_id":"%s","tool_name":"Bash","tool_input":{"command":"cd ~/XYZ-forge && sed -n \\"1,5p\\" relay-automation/marathon.sh"}}' "$sess")
  ev_bare=$(printf '{"session_id":"%s","tool_name":"Bash","tool_input":{"command":"sed -n 1,5p relay-automation/marathon.sh"}}' "$sess")

  printf '%s' "$ev_compound" | bash "$guard" >/dev/null 2>&1
  local rc_compound=$?
  printf '%s' "$ev_bare" | bash "$guard" >/dev/null 2>&1
  local rc_bare=$?

  echo "  expected: compound read blocked (exit 2), bare read allowed (exit 0)"
  echo "  actual  : compound exit=$rc_compound  bare exit=$rc_bare"
  if [ "$rc_compound" -eq 2 ] && [ "$rc_bare" -eq 0 ]; then
    ok "read-exemption misses on a compound command (F-001 reproduces)"
  else
    bad "guard behaviour differs from the recorded finding"
  fi
}

# ── F-002 ────────────────────────────────────────────────────────────────────
# "compute" is not a marathon lifecycle verb anywhere in the repo.
probe_compute_verb() {
  head_ probe-compute-verb "F-002 no marathon 'compute' verb exists"
  local hits
  hits=$(grep -rn -i -E '\bcompute\b' utils/ relay-automation/ skills/ README.md 2>/dev/null \
         | grep -v -i 'does the compute' | grep -c -i -E 'marathon (compute|--compute)' )
  echo "  expected: 0 occurrences of a marathon 'compute' verb"
  echo "  actual  : $hits"
  [ "$hits" -eq 0 ] && ok "no compute verb (F-002 reproduces)" || bad "something now looks like a compute verb"
}

# ── F-003 ────────────────────────────────────────────────────────────────────
# marathon-plan.sh --help advertises its inner Python path as the command name.
probe_plan_help_path() {
  head_ probe-plan-help-path "F-003 marathon-plan.sh --help names the .py, not the .sh"
  local first
  first=$(bash utils/marathon-plan.sh --help 2>&1 | head -1)
  echo "  expected: usage line naming utils/py/marathon_plan.py (the leak)"
  echo "  actual  : $first"
  case "$first" in
    *marathon_plan.py*) ok "help names the Python impl (F-003 reproduces)" ;;
    *marathon-plan.sh*) bad "help now names the shim — F-003 appears FIXED" ;;
    *)                  bad "unrecognized usage line" ;;
  esac
}

# ── F-004 ────────────────────────────────────────────────────────────────────
# Exit 8 is "lane parked", not "relay block invalid".
probe_exit8_meaning() {
  head_ probe-exit8-meaning "F-004 exit 8 == lane parked"
  local line
  line=$(grep -n '8 lane parked' relay-automation/marathon-drive.sh 2>/dev/null | head -1)
  echo "  expected: marathon-drive.sh documents 8 as 'lane parked'"
  echo "  actual  : ${line:-<no match>}"
  [ -n "$line" ] && ok "exit 8 is lane parked (F-004 reproduces)" || bad "exit-8 documentation changed"
}

# ── F-006 ────────────────────────────────────────────────────────────────────
# nvm's node is invisible to a non-interactive login shell because Ubuntu's
# stock ~/.bashrc returns early before the nvm block at the bottom.
probe_node_path() {
  head_ probe-node-path "F-006 nvm node invisible to bash -lc"
  if [ ! -d "$HOME/.nvm/versions/node" ]; then
    echo "  SKIP: no nvm install at ~/.nvm — finding is nvm-specific"
    return
  fi
  local guard_line nvm_line
  guard_line=$(grep -n 'esac' "$HOME/.bashrc" 2>/dev/null | head -1 | cut -d: -f1)
  nvm_line=$(grep -n 'NVM_DIR' "$HOME/.bashrc" 2>/dev/null | head -1 | cut -d: -f1)
  echo "  ~/.bashrc non-interactive early-return ends at line: ${guard_line:-<none>}"
  echo "  ~/.bashrc nvm loader begins at line             : ${nvm_line:-<none>}"

  # The decisive test: a login-but-non-interactive shell, with our prelude NOT sourced.
  local seen
  seen=$(env -u PATH_PRELUDE bash -lc 'command -v node' 2>/dev/null)
  echo "  expected: 'bash -lc command -v node' prints nothing"
  echo "  actual  : '${seen:-<empty>}'"
  if [ -z "$seen" ]; then
    ok "nvm node invisible to non-interactive login shell (F-006 reproduces)"
  else
    bad "node IS visible — dotfiles differ from the recorded environment"
  fi

  # And that the prelude fixes it.
  if [ -f evidence/_env/prelude.sh ]; then
    local fixed
    fixed=$(bash -lc '. evidence/_env/prelude.sh >/dev/null 2>&1; command -v node' 2>/dev/null)
    echo "  with prelude sourced: '${fixed:-<empty>}'"
    case "$fixed" in
      /mnt/c/*) bad "prelude resolved a WINDOWS node" ;;
      "")       bad "prelude did not put node on PATH" ;;
      *)        ok "prelude yields a Linux node" ;;
    esac
  fi
}

# ── F-005 ────────────────────────────────────────────────────────────────────
# Builder presence, and the Windows-claude interop leak.
probe_builders() {
  head_ probe-builders "F-005 builder availability + interop leak"
  local c a cl
  c=$(command -v codex 2>/dev/null); a=$(command -v agy 2>/dev/null); cl=$(command -v claude 2>/dev/null)
  echo "  --- bare PATH (what a non-interactive marathon turn actually sees):"
  echo "  codex : ${c:-<missing>}"
  echo "  agy   : ${a:-<missing>}"
  echo "  claude: ${cl:-<missing>}"

  # F-008: a builder installed with `npm install -g` under nvm lands in the nvm
  # bindir, which is exactly the directory a non-interactive shell cannot see
  # (F-006). So `codex` can be installed and STILL be invisible to marathon.
  if [ -f evidence/_env/prelude.sh ]; then
    local c2
    c2=$( . evidence/_env/prelude.sh >/dev/null 2>&1; command -v codex 2>/dev/null )
    echo "  --- with prelude sourced:"
    echo "  codex : ${c2:-<missing>}"
    if [ -z "$c" ] && [ -n "$c2" ]; then
      ok "codex is installed but invisible without the prelude (F-008 reproduces)"
    fi
  fi
  case "$cl" in
    /mnt/c/*) ok "claude resolves to the WINDOWS binary over interop (F-005 reproduces)" ;;
    "")       echo "  (no claude on PATH — interop leak not present here)" ;;
    *)        echo "  (claude is a Linux binary here — interop leak not present)" ;;
  esac
  if [ -x skills/relay-xyz/find-harness.sh ]; then
    echo "  --- find-harness.sh --check says:"
    bash skills/relay-xyz/find-harness.sh --check 2>&1 | sed 's/^/    /'
  fi
}

# ── plan-location refusal (GH-212) ───────────────────────────────────────────
# marathon.sh refuses a --plan outside PROJECT/2-WORKING/ in the target repo.
probe_plan_location() {
  head_ probe-plan-location "GH-212 plan-location refusal is real"
  local line
  line=$(grep -n 'MARATHON_ALLOW_PLAN_OUTSIDE_WORKING' relay-automation/marathon.sh 2>/dev/null | head -1)
  echo "  expected: marathon.sh gates --plan on PROJECT/2-WORKING/"
  echo "  actual  : ${line:-<no match>}"
  [ -n "$line" ] && ok "plan-location gate present" || bad "plan-location gate not found"
}

ALL="probe-guard-read probe-compute-verb probe-plan-help-path probe-exit8-meaning probe-node-path probe-builders probe-plan-location"

run_one() {
  case "$1" in
    probe-guard-read)     probe_guard_read ;;
    probe-compute-verb)   probe_compute_verb ;;
    probe-plan-help-path) probe_plan_help_path ;;
    probe-exit8-meaning)  probe_exit8_meaning ;;
    probe-node-path)      probe_node_path ;;
    probe-builders)       probe_builders ;;
    probe-plan-location)  probe_plan_location ;;
    *) echo "repro.sh: unknown probe: $1" >&2; return 2 ;;
  esac
}

case "${1:-}" in
  --list) printf '%s\n' $ALL; exit 0 ;;
  -h|--help) sed -n '2,18p' "$0"; exit 0 ;;
esac

if [ "$#" -eq 0 ]; then
  for p in $ALL; do run_one "$p"; done
else
  for p in "$@"; do run_one "$p" || exit 2; done
fi

printf '\n== repro summary: %d reproduced, %d diverged\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
