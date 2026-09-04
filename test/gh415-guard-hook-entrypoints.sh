#!/usr/bin/env bash
# GH-415: enumerate the guard surface from its source of truth, never a copied filename list.
source "$(dirname "$0")/_setup.sh" gh415-guard-hook-entrypoints

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GUARD="$ROOT/relay-automation/hooks/relay-xyz-guard.sh"
[ -x "$GUARD" ] || { echo "  FAIL: guard hook not executable: $GUARD" >&2; exit 1; }

export TMPDIR="$WORK/tmp"; mkdir -p "$TMPDIR"

event() {
  python3 - "$1" "$2" <<'PY'
import json, sys
print(json.dumps({"session_id": sys.argv[1], "tool_name": "Bash",
                  "tool_input": {"command": sys.argv[2]}}))
PY
}

run() {
  RC=0
  printf '%s' "$(event "$1" "$2")" | bash "$GUARD" >/dev/null 2>&1 || RC=$?
}

# Discover current Tier-A shims/Python twins from AGENTS.md and every *-turn.sh under
# relay-automation. If a Tier-A addition is not represented in the tree, this test fails instead
# of silently keeping a stale copy of the list.
mapfile_compat() {
  python3 - "$ROOT" <<'PY'
import glob, os, re, sys
root = sys.argv[1]
text = open(os.path.join(root, "AGENTS.md"), encoding="utf-8").read()
m = re.search(r"Tier-A[\s\S]*?entry points\s*\(([^)]+)\)", text)
if not m:
    raise SystemExit("Could not find Tier-A entry points in AGENTS.md")
names = set(re.findall(r"`([^`]+)`", m.group(1)))
paths = set()
for name in names:
    found = False
    for base in ("relay-automation", "utils"):
        path = os.path.join(root, base, name + ".sh")
        if os.path.isfile(path):
            paths.add(os.path.relpath(path, root)); found = True
    path = os.path.join(root, "utils", "py", name.replace("-", "_") + ".py")
    if os.path.isfile(path):
        paths.add(os.path.relpath(path, root)); found = True
    if not found:
        raise SystemExit("Tier-A entry has no executable in the tree: " + name)
for path in glob.glob(os.path.join(root, "relay-automation", "*-turn.sh")):
    paths.add(os.path.relpath(path, root))
for path in sorted(paths):
    print(path)
PY
}

targets="$(mapfile_compat)" || fail "every Tier-A name resolves to an executable in the tree"
[ -n "$targets" ] || fail "entrypoint enumeration is non-empty"

# Anchor set: the enumerated surface must always contain these load-bearing entrypoints, so an
# AGENTS.md edit that SHRINKS the inventory fails here instead of silently narrowing the guard
# (the GH-422 review drift trap: rewording prose once ungated marathon-plan at 24/0 "green").
# New entrypoints may join freely via AGENTS.md or the *-turn.sh glob; these may never leave.
for must in relay-automation/relay-drive.sh relay-automation/marathon-drive.sh \
            utils/marathon-plan.sh relay-automation/consult.sh \
            relay-automation/codex-turn.sh utils/py/relay_drive.py utils/py/marathon_plan.py; do
  grep -Fxq "$must" <<<"$targets" \
    && pass "anchor present: $must" \
    || fail "anchor MISSING from the enumerated guard surface: $must"
done

seen_deepseek=0
seen_consult=0
index=0
while IFS= read -r target; do
  [ -n "$target" ] || continue
  index=$((index + 1))
  case "$target" in
    *.py) command="python3 $target --help" ;;
    *)    command="bash $target --help" ;;
  esac
  run "gh415-cold-$index" "$command"
  [ "$RC" = 2 ] && pass "cold execution of $target is blocked" \
                    || fail "cold execution of $target should block, got $RC"
  [ "$target" = "relay-automation/deepseek-turn.sh" ] && seen_deepseek=1
  [ "$target" = "relay-automation/consult.sh" ] && seen_consult=1
done <<EOF
$targets
EOF

[ "$seen_deepseek" = 1 ] && pass "negative-control deepseek shim is enumerated" \
                           || fail "deepseek-turn.sh escaped the derived surface"
[ "$seen_consult" = 1 ] && pass "negative-control consult shim is enumerated" \
                          || fail "consult.sh escaped the Tier-A surface"

# A path in an argument or quoted text is not a driver invocation.
run gh415-reference 'printf "%s\\n" relay-automation/consult.sh'
[ "$RC" = 0 ] && pass "argument-only consult path is allowed" \
                  || fail "argument-only consult path should allow, got $RC"
run gh415-text 'echo "review relay-automation/deepseek-turn.sh before running it"'
[ "$RC" = 0 ] && pass "text-only deepseek path is allowed" \
                  || fail "text-only deepseek path should allow, got $RC"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
