#!/usr/bin/env bash
# GH-308 — Freeze the Bash compatibility twins while keeping XYZ_PYTHON=0 reversible.
#
# Guard usage for a real change:
#   bash test/gh308-frozen-twin-guard.sh --check --staged
#   GH308_FROZEN_TWIN_BASE=<merge-base> bash test/gh308-frozen-twin-guard.sh --check
# The normal test validates the banners and demonstrates committed-range blocking in a throwaway repo.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${GH308_GUARD_ROOT:-$(cd "$HERE/.." && pwd)}"
TWINS=(
  relay-automation/agy-turn.sh:utils/py/agy-turn.py
  relay-automation/aider-turn.sh:utils/py/aider-turn.py
  relay-automation/claude-turn.sh:utils/py/claude-turn.py
  relay-automation/codex-turn.sh:utils/py/codex-turn.py
  relay-automation/pi-turn.sh:utils/py/pi-turn.py
  relay-automation/poll.sh:utils/py/poll.py
  relay-automation/relay-loop.sh:utils/py/relay_loop.py
  relay-automation/relay-drive.sh:utils/py/relay_drive.py
  relay-automation/consult.sh:utils/py/consult.py
  relay-automation/marathon-drive.sh:utils/py/marathon_drive.py
  utils/swarm-preflight.sh:utils/py/swarm_preflight.py
)

mode=test staged=0 base=""
while (($#)); do
  case "$1" in
    --check) mode=check ;;
    --staged) staged=1 ;;
    --base) base="${2:?--base needs a revision}"; shift ;;
    --help)
      sed -n '2,8p' "$0"
      exit 0
      ;;
    *) printf 'usage: %s [--check [--staged | --base REV]]\n' "$0" >&2; exit 2 ;;
  esac
  shift
done

frozen_paths() {
  local pair
  for pair in "${TWINS[@]}"; do printf '%s\n' "${pair%%:*}"; done
}

check_changes() {
  local -a paths=()
  local pair
  for pair in "${TWINS[@]}"; do paths+=("${pair%%:*}"); done
  local changed
  if (( staged )); then
    changed="$(git -C "$ROOT" diff --cached --name-only -- "${paths[@]}")"
  else
    [[ -n "$base" ]] || { echo 'gh308 guard: --check needs --staged or --base REV' >&2; return 2; }
    git -C "$ROOT" rev-parse --verify "${base}^{commit}" >/dev/null
    changed="$(git -C "$ROOT" diff --name-only "${base}..HEAD" -- "${paths[@]}")"
  fi
  if [[ -n "$changed" ]]; then
    printf 'gh308 guard: FROZEN Bash twin edit blocked; change its Python twin instead:\n%s\n' "$changed" >&2
    return 1
  fi
  echo 'gh308 guard: no frozen Bash twin changed'
}

if [[ "$mode" == check ]]; then
  check_changes
  exit $?
fi

# CI supplies the merge-base explicitly; local validation intentionally stays structural so the
# bootstrap commit that adds these banners can establish the frozen baseline.
if [[ -n "${GH308_FROZEN_TWIN_BASE:-}" ]]; then
  base="$GH308_FROZEN_TWIN_BASE"
  check_changes
fi

pass=0 fail=0
ok() { echo "  PASS: $1"; pass=$((pass + 1)); }
bad() { echo "  FAIL: $1"; fail=$((fail + 1)); }
echo '== test: gh308-frozen-twin-guard =='

for pair in "${TWINS[@]}"; do
  sh_path="${pair%%:*}"; py_path="${pair#*:}"
  if [[ -f "$ROOT/$py_path" ]] && grep -Fq '# FROZEN (GH-308): Python is authoritative' "$ROOT/$sh_path" \
      && grep -Fq "$py_path" "$ROOT/$sh_path" && grep -Fq 'issue #308' "$ROOT/$sh_path"; then
    ok "$sh_path is frozen in favor of $py_path"
  else
    bad "$sh_path needs its GH-308 FROZEN banner and Python pointer ($py_path)"
  fi
done

if ! grep -Fq 'FROZEN (GH-308)' "$ROOT/utils/marathon-plan.sh"; then
  ok 'marathon-plan remains the Bash-authoritative exception'
else
  bad 'marathon-plan must not be frozen: Bash is still authoritative'
fi

if ! grep -Fq 'FROZEN (GH-308)' "$ROOT/relay-automation/relay-turn-lib.sh"; then
  ok 'relay-turn-lib remains the shared Bash dependency, not a twin'
else
  bad 'relay-turn-lib must not be frozen: Python invokes it at runtime'
fi

# Demonstrate the range guard against an actual throwaway commit, not merely a staged diff.
tmp="$(mktemp -d "${TMPDIR:-/tmp}/gh308-frozen-twin.XXXXXX")"
cleanup() { rm -rf "$tmp"; }
trap cleanup EXIT
mkdir -p "$tmp/relay-automation" "$tmp/test"
cp "$0" "$tmp/test/gh308-frozen-twin-guard.sh"
printf '#!/usr/bin/env bash\n# FROZEN (GH-308): Python is authoritative\n' >"$tmp/relay-automation/codex-turn.sh"
git -C "$tmp" init -q
git -C "$tmp" config user.email gh308-test@example.invalid
git -C "$tmp" config user.name gh308-test
git -C "$tmp" add .
git -C "$tmp" commit -qm baseline
printf '# deliberate forbidden edit\n' >>"$tmp/relay-automation/codex-turn.sh"
git -C "$tmp" add relay-automation/codex-turn.sh
git -C "$tmp" commit -qm forbidden-edit
if GH308_GUARD_ROOT="$tmp" bash "$tmp/test/gh308-frozen-twin-guard.sh" --check --base HEAD~1 >/dev/null 2>&1; then
  bad 'range guard accepted a committed frozen-twin edit'
else
  ok 'range guard blocks a committed frozen-twin edit in a throwaway repo'
fi

printf 'note\n' >"$tmp/README.md"
git -C "$tmp" add README.md
git -C "$tmp" commit -qm docs-only
if GH308_GUARD_ROOT="$tmp" bash "$tmp/test/gh308-frozen-twin-guard.sh" --check --base HEAD~1 >/dev/null; then
  ok 'range guard permits a commit that does not touch a frozen twin'
else
  bad 'range guard rejected a commit outside the frozen twins'
fi

echo "  gh308-frozen-twin-guard: $pass pass, $fail fail"
[[ "$fail" -eq 0 ]]
