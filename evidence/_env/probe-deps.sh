#!/usr/bin/env bash
# Dependency probe for the XYZ-forge marathon/relay stack on Linux.
# Prints one line per tool: NAME<TAB>PATH-or-MISSING<TAB>VERSION
set -u
cd "$(dirname "${BASH_SOURCE[0]}")/../.." || exit 1
# shellcheck disable=SC1091
. evidence/_env/prelude.sh

probe() {
  local name="$1" p v
  p="$(command -v "$name" 2>/dev/null)" || p=""
  if [ -z "$p" ]; then
    printf '%-14s MISSING\n' "$name"
    return 1
  fi
  v="$("$name" --version 2>&1 | head -1)" || v="?"
  printf '%-14s %-52s %s\n' "$name" "$p" "$v"
  return 0
}

echo "--- builders / harness workers (Path A) ---"
probe codex
probe agy
probe claude
probe aider

echo
echo "--- runtime + suite dependencies ---"
probe node
probe npm
probe python3
probe git
probe bash
probe jq
probe yq
probe gh
probe sqlite3
probe timeout
probe flock
probe shellcheck

echo
echo "--- in-repo entrypoints ---"
for f in bin/tick bin/marathon-yaml bin/validate-relay-block validate.sh ci-local.sh utils/pdda/pdda.sh; do
  if [ -e "$f" ]; then
    printf '%-28s present  exec=%s\n' "$f" "$([ -x "$f" ] && echo yes || echo NO)"
  else
    printf '%-28s ABSENT\n' "$f"
  fi
done

echo
echo "--- python module deps (marathon runtime is dual-runtime, XYZ_PYTHON) ---"
python3 - <<'PY' 2>&1
import importlib, sys
print("python:", sys.version.split()[0])
for m in ("yaml", "json", "sqlite3", "tomllib"):
    try:
        importlib.import_module(m)
        print(f"  {m:<10} OK")
    except Exception as e:
        print(f"  {m:<10} MISSING ({e.__class__.__name__})")
PY
