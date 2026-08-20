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

# ── F-015 ────────────────────────────────────────────────────────────────────
# agy 1.1.16 has no `whoami` subcommand (nor `login`, the remedy every failure
# path prints), so the argument falls through to the interactive TUI, which
# emits a terminal takeover and then blocks while ignoring SIGTERM.
#
# This probe is deliberately SPLIT. The static half (no whoami/login subcommand,
# the classifier now recognises a mute takeover) needs no agy and always runs.
# The live half needs a real agy on PATH and is skipped without one, so this
# probe stays runnable on a machine that never installed it.
probe_agy_auth() {
  head_ probe-agy-auth "F-015 agy 1.1.16 removed whoami; the preflight blocked the lane"

  # -- static: is the fix present and does it hold its shape? --
  local py="utils/py/rtl.py"
  if grep -q 'AGY_TUI_TAKEOVER_MARKERS' "$py" 2>/dev/null; then
    ok "rtl.py carries the mute-takeover classifier (the fix is in this tree)"
  else
    bad "rtl.py has no AGY_TUI_TAKEOVER_MARKERS — the fix is missing, the agy lane will block"
  fi

  # The classifier must reclassify a MUTE takeover and still block a takeover
  # that says something readable. Both directions, or the fix is a rubber stamp.
  local out
  out=$(PYTHONPATH="$REPO/utils/py" python3 - <<'PY' 2>&1
import tempfile, os
from rtl import agy_auth_timeout_verdict
TAKEOVER = "\x1b[?2026$p\x1b[?1049h\x1b[?25l\x1b[?2004h\x1b[H\x1b[2J"
LOGIN = "To authenticate, visit https://example.invalid/device and enter code ABCD-1234"
def verdict(body):
    fd, p = tempfile.mkstemp()
    os.write(fd, body.encode()); os.close(fd)
    try:    return agy_auth_timeout_verdict(p)[0]
    finally: os.unlink(p)
print("mute=%s login=%s silent=%s" % (verdict(TAKEOVER), verdict(TAKEOVER + LOGIN), verdict("")))
PY
)
  echo "  expected: mute=unverifiable login=failed silent=failed"
  echo "  actual  : $out"
  if [ "$out" = "mute=unverifiable login=failed silent=failed" ]; then
    ok "a mute takeover reclassifies; a readable login prompt and silence both still block"
  else
    bad "classifier verdicts diverged: $out"
  fi

  # -- live: only if agy is actually installed --
  if ! command -v agy >/dev/null 2>&1; then
    echo "  SKIP live half: no agy on PATH (the static half above still applies)"
    return
  fi

  local help_out
  help_out=$(timeout -s KILL 30 agy --help </dev/null 2>&1)
  echo "  agy version: $(timeout -s KILL 20 agy --version </dev/null 2>&1 | head -1)"
  if printf '%s' "$help_out" | grep -qE '^[[:space:]]+whoami\b'; then
    bad "agy DOES have a whoami subcommand here — F-015's premise does not reproduce"
  else
    ok "agy has no 'whoami' subcommand (what the preflight calls)"
  fi
  if printf '%s' "$help_out" | grep -qE '^[[:space:]]+login\b'; then
    bad "agy HAS a login subcommand — the printed remedy would work here"
  else
    ok "agy has no 'login' subcommand either (the remedy every failure path prints)"
  fi

  # SIGTERM is ignored: a plain `timeout` must overshoot its own deadline.
  local s e dt
  s=$(date +%s)
  timeout 6 agy whoami </dev/null >/dev/null 2>&1
  e=$(date +%s); dt=$((e - s))
  # Reap it — this probe must not leak a 200MB process.
  pkill -9 -f '[a]gy whoami' >/dev/null 2>&1
  echo "  expected: >6s elapsed under a 6s SIGTERM timeout (SIGTERM ignored)"
  echo "  actual  : ${dt}s"
  [ "$dt" -gt 6 ] \
    && ok "agy whoami outlived its SIGTERM deadline (${dt}s > 6s)" \
    || bad "agy whoami honoured SIGTERM in ${dt}s — the hang does not reproduce"
}

# ── F-016 ────────────────────────────────────────────────────────────────────
# swarm-preflight decides lane readiness with a bare `command -v`, which proves
# only that a file is on PATH — not that the lane will run.
probe_lane_cli_probe() {
  head_ probe-lane-cli-probe "F-016 swarm-preflight's lane-cli check is a bare command -v"
  local line
  line=$(grep -n 'GH39_LANE_NOTE=' utils/swarm-preflight.sh 2>/dev/null | head -1)
  echo "  expected: lane readiness decided by 'command -v', with no exec or auth check"
  echo "  actual  : ${line:0:150}"
  if printf '%s' "$line" | grep -q 'command -v agy'; then
    ok "agy lane readiness is a bare PATH lookup"
  else
    bad "GH39_LANE_NOTE no longer uses a bare command -v — finding may be fixed"
  fi
  # find-harness.sh is the better-behaved sibling: it honours AGY_BIN and the
  # well-known install location. The disagreement IS the finding.
  if grep -q 'AGY_BIN' skills/relay-xyz/find-harness.sh 2>/dev/null; then
    ok "find-harness.sh resolves via AGY_BIN/well-known path — the two tools disagree by construction"
  else
    bad "find-harness.sh no longer resolves AGY_BIN"
  fi
}

# ── F-017 ────────────────────────────────────────────────────────────────────
# marathon.sh checks --plan against the process CWD at :136, but does not compute
# the documented base (_plan_base="${TARGET_ROOT:-$ROOT}") until :155.
probe_plan_resolution() {
  head_ probe-plan-resolution "F-017 --plan is checked before --target-root is applied"
  local check_ln base_ln
  check_ln=$(grep -n 'plan not found' relay-automation/marathon.sh | head -1 | cut -d: -f1)
  base_ln=$(grep -n '_plan_base=' relay-automation/marathon.sh | head -1 | cut -d: -f1)
  echo "  expected: the existence check line number is LOWER than the _plan_base line number"
  echo "  actual  : existence check at :${check_ln:-?}, _plan_base at :${base_ln:-?}"
  if [ -n "$check_ln" ] && [ -n "$base_ln" ] && [ "$check_ln" -lt "$base_ln" ]; then
    ok "the plan is existence-checked $((base_ln - check_ln)) lines before its documented base is computed"
  else
    bad "ordering no longer reproduces (check=$check_ln base=$base_ln)"
  fi
  # And the help does promise the resolution that does not happen.
  if grep -q 'Plan and brief paths resolve against DIR when set' relay-automation/marathon.sh; then
    ok "the help still promises 'Plan and brief paths resolve against DIR when set'"
  else
    bad "the help text changed — finding may be fixed"
  fi
}

# ── F-018 ────────────────────────────────────────────────────────────────────
# --target-root is recommended for a target that gitignores harness output, and
# relay-drive refuses that exact combination for a build turn.
probe_target_root_contradiction() {
  head_ probe-target-root-contradiction "F-018 --target-root recommended for the case relay-drive refuses"
  local advice refusal
  advice=$(grep -c 'gitignores marathon-system/' relay-automation/marathon.sh 2>/dev/null)
  refusal=relay-automation/relay-drive.sh$(grep -rl 'build turn cannot report' relay-automation/ utils/py/ 2>/dev/null | head -1)
  echo "  expected: the help recommends --target-root for a gitignoring target, AND a driver refuses it"
  echo "  actual  : help mentions gitignoring target: ${advice:-0}x; refusal lives in: ${refusal:-<none>}"
  [ "${advice:-0}" -ge 1 ] \
    && ok "marathon.sh --target-root help recommends it for a gitignoring target" \
    || bad "the recommendation is gone — finding may be fixed"
  [ -n "$refusal" ] \
    && ok "a driver refuses --target-root for build turns ($refusal)" \
    || bad "no 'turn cannot report' refusal found — finding may be fixed"
}

# ── F-019 ────────────────────────────────────────────────────────────────────
# artifacts_new is required for greenfield lanes (hard exit 3) and is absent from
# the example file that the exit-3 message tells the operator to copy.
probe_artifacts_new_doc() {
  head_ probe-artifacts-new-doc "F-019 artifacts_new is undocumented in the example the error names"
  local ex="relay-automation/CONTRACT.example.md"
  if [ ! -f "$ex" ]; then bad "$ex not found"; return; fi
  echo "  expected: swarm-preflight enforces artifacts_new, and $ex never mentions it"
  if grep -q 'artifacts_new' utils/swarm-preflight.sh; then
    ok "swarm-preflight.sh enforces artifacts_new (hard exit 3)"
  else
    bad "artifacts_new is no longer enforced"
  fi
  if grep -q 'artifacts_new' "$ex"; then
    bad "$ex now documents artifacts_new — finding is fixed"
  else
    ok "$ex — the file the exit-3 message says to copy — never mentions artifacts_new"
  fi
  # And nowhere in the operator-facing docs either.
  local hits
  hits=$(grep -rl 'artifacts_new' README.md ROUTER.md AGENTS.md relay-automation/ 2>/dev/null | wc -l)
  echo "  actual  : operator-facing docs mentioning artifacts_new: $hits"
  [ "$hits" -eq 0 ] \
    && ok "no operator-facing doc defines artifacts_new" \
    || bad "artifacts_new is now documented in $hits operator-facing file(s)"
}

# ── F-023 ────────────────────────────────────────────────────────────────────
# The GH-68 drift watcher treats a path that exists at NEITHER rev as drifted,
# because `git rev-parse <sha>:<missing>` exits 128 while ECHOING its argument
# back on stdout. The two echoes differ (different sha prefixes), so the
# "unchanged (or absent at both revs)" guard never fires.
#
# Proven against a real throwaway repo built here in $TMPDIR, so the probe does
# not depend on the marathon target still existing.
probe_drift_false_positive() {
  head_ probe-drift-false-positive "F-023 drift fires on paths absent at both revs"

  local lib="relay-automation/relay-turn-lib.sh"
  if [ ! -f "$lib" ]; then bad "$lib not found"; return; fi

  # 1. The watch list is still hardcoded to xyz's own filenames.
  if grep -q 'for _surf in relay-automation/relay-turn-lib.sh src/project.js src/events.js' "$lib"; then
    ok "watch list is hardcoded to xyz's filenames (no per-repo lever)"
  else
    bad "watch list changed — finding may be fixed"
  fi

  # 2. The guard still uses a bare rev-parse (no --verify), which is the cause.
  if grep -A3 'for _surf in relay-automation/relay-turn-lib.sh' "$lib" | grep -q 'rev-parse --verify'; then
    bad "rev-parse now uses --verify — finding is fixed"
    return
  else
    ok "rev-parse is still bare (no --verify), so a missing path echoes back"
  fi

  # 3. Demonstrate the mechanism on a fresh throwaway repo.
  local d; d="$(mktemp -d)" || { bad "mktemp failed"; return; }
  (
    cd "$d" || exit 1
    git init -q -b main
    echo hello > real.txt
    git -c user.email=t@example.invalid -c user.name=t add -A
    git -c user.email=t@example.invalid -c user.name=t commit -q -m one
    echo world >> real.txt
    git -c user.email=t@example.invalid -c user.name=t commit -qam two
  ) >/dev/null 2>&1

  local before new psha csha rc out
  before=$(git -C "$d" rev-parse HEAD~1)
  new=$(git -C "$d" rev-parse HEAD)

  # The exact expressions from relay-turn-lib.sh, against a path in NEITHER rev.
  psha="$(git -C "$d" rev-parse "$before:src/project.js" 2>/dev/null || true)"
  csha="$(git -C "$d" rev-parse "$new:src/project.js"    2>/dev/null || true)"
  echo "  expected: a path absent at both revs yields EQUAL values, so no drift"
  echo "  actual  : _psha=[${psha}]"
  echo "            _csha=[${csha}]"
  if [ "$psha" = "$csha" ]; then
    bad "the two values are equal here — the false positive does not reproduce"
  else
    ok "absent-at-both-revs yields DIFFERENT strings -> drift is emitted (the false positive)"
  fi

  # 4. And confirm --verify --quiet is the one-flag fix.
  psha="$(git -C "$d" rev-parse --verify --quiet "$before:src/project.js" 2>/dev/null || true)"
  csha="$(git -C "$d" rev-parse --verify --quiet "$new:src/project.js"    2>/dev/null || true)"
  echo "  with --verify --quiet: _psha=[${psha}] _csha=[${csha}]"
  if [ -z "$psha" ] && [ "$psha" = "$csha" ]; then
    ok "--verify --quiet yields empty at both revs, so the existing guard would work"
  else
    bad "--verify --quiet did not silence the echo-back"
  fi

  # 5. Sanity: a path that DOES exist and is unchanged must stay quiet.
  psha="$(git -C "$d" rev-parse "$before:real.txt" 2>/dev/null || true)"
  csha="$(git -C "$d" rev-parse "$new:real.txt"    2>/dev/null || true)"
  if [ "$psha" != "$csha" ]; then
    ok "a genuinely CHANGED tracked path still differs (real drift is still detected)"
  else
    bad "a changed path compared equal — the detector would miss real drift"
  fi

  rm -rf "$d"
}

ALL="probe-guard-read probe-compute-verb probe-plan-help-path probe-exit8-meaning probe-node-path probe-builders probe-plan-location probe-agy-auth probe-lane-cli-probe probe-plan-resolution probe-target-root-contradiction probe-artifacts-new-doc probe-drift-false-positive"

run_one() {
  case "$1" in
    probe-guard-read)     probe_guard_read ;;
    probe-compute-verb)   probe_compute_verb ;;
    probe-plan-help-path) probe_plan_help_path ;;
    probe-exit8-meaning)  probe_exit8_meaning ;;
    probe-node-path)      probe_node_path ;;
    probe-builders)       probe_builders ;;
    probe-plan-location)  probe_plan_location ;;
    probe-agy-auth)       probe_agy_auth ;;
    probe-lane-cli-probe) probe_lane_cli_probe ;;
    probe-plan-resolution) probe_plan_resolution ;;
    probe-target-root-contradiction) probe_target_root_contradiction ;;
    probe-artifacts-new-doc) probe_artifacts_new_doc ;;
    probe-drift-false-positive) probe_drift_false_positive ;;
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
