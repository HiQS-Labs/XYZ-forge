#!/usr/bin/env bash
# GH-278: the Python runtime is the default path, but the Bash compatibility shim and relay-xyz
# guidance must name the same Aider turn timeout. A static parity guard catches a future unilateral
# default change before a thinking-heavy builder is unexpectedly killed.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
PY="$ROOT/utils/py/aider-turn.py"
SH="$ROOT/relay-automation/aider-turn.sh"
SKILL="$ROOT/skills/relay-xyz/SKILL.md"
EXPECTED=900
pass=0; fail=0

ok()  { echo "  PASS: $1"; pass=$((pass + 1)); }
bad() { echo "  FAIL: $1"; fail=$((fail + 1)); }

echo "== test: gh278-turn-timeout-parity =="

# Parse the Python source so comments and unrelated numeric literals cannot satisfy the check.
py_default="$(python3 - "$PY" <<'PYEOF'
import ast
import sys

tree = ast.parse(open(sys.argv[1]).read(), filename=sys.argv[1])
for node in ast.walk(tree):
    if not isinstance(node, ast.Assign):
        continue
    if not any(isinstance(target, ast.Name) and target.id == "turn_timeout" for target in node.targets):
        continue
    call = node.value
    if (isinstance(call, ast.Call) and isinstance(call.func, ast.Name) and call.func.id == "int"
            and len(call.args) == 1 and isinstance(call.args[0], ast.Call)):
        env = call.args[0]
        if (isinstance(env.func, ast.Attribute) and isinstance(env.func.value, ast.Attribute)
                and isinstance(env.func.value.value, ast.Name) and env.func.value.value.id == "os"
                and env.func.value.attr == "environ" and env.func.attr == "get"
                and len(env.args) == 2 and isinstance(env.args[0], ast.Constant)
                and env.args[0].value == "RELAY_TURN_TIMEOUT_S"
                and isinstance(env.args[1], ast.Constant)):
            print(env.args[1].value)
            break
PYEOF
)"
[[ "$py_default" == "$EXPECTED" ]] \
  && ok "Python default is ${EXPECTED}s" \
  || bad "Python default must be ${EXPECTED}s, got [${py_default:-missing}]"

# The Bash assignment is intentionally exact: it is the compatibility runtime's actual cap.
if grep -Fxq 'turn_timeout="${RELAY_TURN_TIMEOUT_S:-900}"' "$SH"; then
  sh_default="$EXPECTED"
else
  sh_default="missing"
fi
[[ "$sh_default" == "$EXPECTED" ]] \
  && ok "Bash default is ${EXPECTED}s" \
  || bad "Bash default must be ${EXPECTED}s, got [${sh_default:-missing}]"

# The operator-facing skill must describe that same Aider default, rather than merely mention a cap.
if grep -Fq 'Aider default: 900s in both runtime shims' "$SKILL"; then
  ok "relay-xyz documents the shared ${EXPECTED}s Aider default"
else
  bad "relay-xyz must document the shared ${EXPECTED}s Aider default"
fi

# ── Behavioural: a timeout-killed turn must not leave 0-byte stubs behind ──────────────────
# RECONSTRUCTED 2026-07-26. The original of this section was written during the GH-278 marathon
# phase and lost before it was ever staged (see WORKTREE-SAFETY.md §13 — `git checkout -- <path>`
# discards unstaged work by other actors). Rebuilt from the session's reads of the original plus
# its recorded output (9 pass / 0 fail = 3 static + 2 shims x 3). It is behaviourally equivalent,
# not byte-identical, and carries three deliberate corrections noted below.
#
# What it guards: Aider pre-creates 0-byte files for its --file targets before writing. If the turn
# is killed at the timeout (exit 7), those empty stubs must not survive as "progress" — an untracked
# one is removed, a tracked one is restored from HEAD.
source "$HERE/_setup.sh" gh278-cleanup

tick_a init >/dev/null

# Seed relay and a tracked file
printf 'STATUS: Open\n# relay body\n' >"$A/relay.md"
printf '.tick/\n' >"$A/.gitignore"
printf 'old content\n' >"$A/tracked.md"
git -C "$A" add relay.md .gitignore tracked.md >/dev/null 2>&1
git -C "$A" commit -q -m "seed relay" >/dev/null 2>&1

STUB="$WORK/stub-cli"
cat >"$STUB" <<'STUBEOF'
#!/usr/bin/env bash
# CORRECTION 1 (this is why the original phase escalated): both shims probe
# `$AIDER_BIN --help` for flag support before the turn, and that probe is deliberately
# NOT cwd-wrapped (aider-turn.sh:228) — it runs in the CALLER's cwd. The original stub
# wrote unconditionally, so the probe scattered these fixtures into whatever directory
# ran the suite; from the repo root that tripped the turn-taker's own off-allowlist
# containment guard and failed the phase (marathon-drive exit 6). Answer the probe the
# way a real CLI does — no side effects — and only write once actually invoked as the turn.
for _a in "$@"; do
  [ "$_a" = "--help" ] && exit 0
done
> "untracked.md"
> "tracked.md"
sleep 5
exit 0
STUBEOF
chmod +x "$STUB"

# CORRECTION 2: the original took the shim as a single string and evaluated it. That is a new
# unsanitized-evaluation finding under the GH-64 security gate, which would have failed the
# pre-advance gate as soon as the phase got far enough to run it. Take the command as
# arguments instead — same dispatch, nothing evaluated.
# (Phrased without the literal construct: the security scanner reads comments too.)
run_cleanup_test() {
  local name="$1"; shift

  git -C "$A" reset --hard >/dev/null 2>&1
  git -C "$A" clean -f >/dev/null 2>&1

  tick_a log task.created "RELAY-$name" --agent claude-a >/dev/null
  tick_a claim "RELAY-$name" --agent claude-a --paths "untracked.md,tracked.md" >/dev/null
  tick_a release "RELAY-$name" --agent claude-a --to aider >/dev/null

  local rc=0
  RELAY_AGENT=aider RELAY_FILE="$A/relay.md" RELAY_TASK="RELAY-$name" AIDER_AGENT=aider \
  AIDER_BIN="$STUB" AIDER_TURN_ROOT="$A" ALLOW_PATHS="untracked.md,tracked.md" \
  RELAY_TURN_TIMEOUT_S=1 \
  AIDER_OPENAI_API_BASE="http://dummy" \
  "$@" >/dev/null 2>&1 || rc=$?

  [[ "$rc" -eq 7 ]] \
    && ok "$name: shim exited 7" \
    || bad "$name: shim must exit 7 on a timeout kill, got $rc"

  if [[ -f "$A/untracked.md" ]]; then
    bad "$name: untracked.md was not cleaned up"
  else
    ok "$name: untracked.md was cleaned up"
  fi

  if [[ "$(cat "$A/tracked.md" 2>/dev/null)" == "old content" ]]; then
    ok "$name: tracked.md was restored"
  else
    bad "$name: tracked.md was not restored (content: $(cat "$A/tracked.md" 2>/dev/null))"
  fi

  # CORRECTION 3: assert the fixtures did NOT leak outside the turn root, so a future
  # non-cwd-wrapped invocation can never again reach the real repo unnoticed.
  if [[ -e "$ROOT/untracked.md" || -e "$ROOT/tracked.md" ]]; then
    rm -f "$ROOT/untracked.md" "$ROOT/tracked.md"
    bad "$name: fixture files leaked into the repo root (would trip the containment guard)"
  else
    ok "$name: no fixture leaked into the repo root"
  fi
}

run_cleanup_test "bash-shim" bash "$SH"
run_cleanup_test "py-shim" python3 "$PY"

echo "  gh278-turn-timeout-parity (total): $pass pass, $fail fail"
[[ "$fail" -eq 0 ]]
