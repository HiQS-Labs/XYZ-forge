#!/usr/bin/env bash
# GH-308 — Freeze the Bash compatibility twins while keeping XYZ_PYTHON=0 reversible.
#
# Guard usage for a real change:
#   bash test/gh308-frozen-twin-guard.sh --check --staged
#   GH308_FROZEN_TWIN_BASE=<merge-base> bash test/gh308-frozen-twin-guard.sh --check
#   bash test/gh308-frozen-twin-guard.sh --check --base REV --allow-exceptions   # what CI runs
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

mode=test staged=0 base="" allow_exceptions=0
while (($#)); do
  case "$1" in
    --check) mode=check ;;
    --staged) staged=1 ;;
    --base) base="${2:?--base needs a revision}"; shift ;;
    --allow-exceptions) allow_exceptions=1 ;;
    --help)
      sed -n '2,9p' "$0"
      exit 0
      ;;
    *) printf 'usage: %s [--check [--staged | --base REV] [--allow-exceptions]]\n' "$0" >&2; exit 2 ;;
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

# ── GH-321: per-file exception coverage ─────────────────────────────────────────────────────────
# The escape hatch shipped in PR #318 was RANGE-scoped: one `Frozen-twin-exception:` trailer anywhere
# in BASE..HEAD excused EVERY frozen-twin edit in the PR, including files nobody reasoned about, in
# commits that declared nothing. CI then printed "1 commit(s) declare Frozen-twin-exception —
# allowing:" and listed the declaring commit, so the log read like a narrow reviewed exception when
# it was a blanket one — the undeclared edit was never named. Marathon PRs are the common case and
# the worst shape for it: 4+ autonomous lanes on one branch make an undeclared twin edit riding
# behind someone else's declared exception the expected accident, not an exotic one.
#
# A trailer must now name the twin(s) it covers, and every changed twin must be named by some trailer
# in the range:
#
#   Frozen-twin-exception: relay-automation/marathon-drive.sh — silently-fake pre-advance gate (GH-319)
#
# Per-file coverage across the range, deliberately NOT "the trailer must be on the same commit as the
# edit": a later fixup commit correcting an earlier one is ordinary and should not need its own
# re-declaration. What the looseness actually cost was attribution, and naming the file recovers it.
#
# The reason text is separated by an em dash (or ` -- `) and is NOT scanned for paths, so a reason may
# freely mention `validate.sh` or any other file without being read as a coverage claim.
is_frozen_path() {  # <path>
  local pair
  for pair in "${TWINS[@]}"; do [[ "${pair%%:*}" == "$1" ]] && return 0; done
  return 1
}

collect_declared() {  # <base> → stdout: covered paths, one per line. rc 1 if ANY trailer is malformed.
  local base="$1" rc=0 line rest paths_part reason token found
  while IFS= read -r line; do
    case "$line" in
      Frozen-twin-exception:*) ;;
      *) continue ;;
    esac
    rest="${line#Frozen-twin-exception:}"
    if [[ "$rest" == *"—"* ]]; then
      paths_part="${rest%%—*}"; reason="${rest#*—}"
    elif [[ "$rest" == *" -- "* ]]; then
      paths_part="${rest%% -- *}"; reason="${rest#* -- }"
    else
      # Includes the legacy bare form (`Frozen-twin-exception: <reason>`), which named no file and is
      # exactly what made the hatch blanket-scoped. Failing loudly beats covering nothing in silence.
      printf 'gh308 guard: malformed Frozen-twin-exception trailer — no path/reason separator:\n  %s\n' "$line" >&2
      printf '  expected: Frozen-twin-exception: <path>[, <path>...] — <reason>\n' >&2
      rc=1; continue
    fi
    if [[ ! "$reason" =~ [^[:space:]] ]]; then
      printf 'gh308 guard: Frozen-twin-exception trailer has no reason text:\n  %s\n' "$line" >&2
      rc=1; continue
    fi
    found=0
    paths_part="${paths_part//,/ }"
    for token in $paths_part; do   # deliberate word splitting: the path list is space/comma separated
      if is_frozen_path "$token"; then
        printf '%s\n' "$token"
        found=1
      else
        printf 'gh308 guard: Frozen-twin-exception names a path that is not a frozen twin: %s\n' "$token" >&2
        printf '  A typo here would silently cover nothing, so it fails instead. Frozen twins:\n' >&2
        frozen_paths | sed 's/^/    /' >&2
        rc=1
      fi
    done
    if (( found == 0 )); then
      printf 'gh308 guard: Frozen-twin-exception trailer names no frozen twin:\n  %s\n' "$line" >&2
      rc=1
    fi
  done < <(git -C "$ROOT" log --format='%B' "${base}..HEAD")
  return "$rc"
}

check_exception_coverage() {  # <base> — called only after check_changes has already failed
  local base="$1" changed declared f uncovered=0
  local -a paths=()
  local pair
  for pair in "${TWINS[@]}"; do paths+=("${pair%%:*}"); done
  changed="$(git -C "$ROOT" diff --name-only "${base}..HEAD" -- "${paths[@]}")"
  declared="$(collect_declared "$base")" || return 1
  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    if printf '%s\n' "$declared" | grep -Fxq -- "$f"; then
      printf 'gh308 guard: %s — covered by a declared Frozen-twin-exception\n' "$f"
    else
      # Name the file. The whole defect in the range-scoped version was that it never did.
      printf 'gh308 guard: %s was edited with NO Frozen-twin-exception trailer naming it\n' "$f" >&2
      uncovered=1
    fi
  done <<EOF
$changed
EOF
  if (( uncovered )); then
    printf 'gh308 guard: put the fix in the Python twin, or declare the exception per file:\n' >&2
    printf '  Frozen-twin-exception: <path> — <reason>\n' >&2
    return 1
  fi
  return 0
}

if [[ "$mode" == check ]]; then
  if (( allow_exceptions )) && (( staged )); then
    echo 'gh308 guard: --allow-exceptions needs --base REV (staged changes have no commit trailers yet)' >&2
    exit 2
  fi
  rc=0
  check_changes || rc=$?
  (( rc == 0 )) && exit 0
  (( rc == 2 )) && exit 2
  (( allow_exceptions )) || exit "$rc"
  echo "---"
  if check_exception_coverage "$base"; then
    echo 'gh308 guard: every frozen-twin edit in this range is covered by a declared exception'
    exit 0
  fi
  exit 1
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

# ── GH-321: the exception hatch must be per-FILE, not per-range ─────────────────────────────────
# Every case below is driven through the real guard in a throwaway repo with TWO frozen twins,
# because the defect only exists when a PR touches more than one: with a single twin, range scoping
# and file scoping are indistinguishable, which is how it shipped.
exc="$(mktemp -d "${TMPDIR:-/tmp}/gh308-exceptions.XXXXXX")"
cleanup_exc() { rm -rf "$exc"; }
trap 'cleanup; cleanup_exc' EXIT
mkdir -p "$exc/relay-automation" "$exc/test"
cp "$0" "$exc/test/gh308-frozen-twin-guard.sh"
for f in codex-turn.sh relay-drive.sh; do
  printf '#!/usr/bin/env bash\n# FROZEN (GH-308): Python is authoritative\n' >"$exc/relay-automation/$f"
done
git -C "$exc" init -q
git -C "$exc" config user.email gh308-test@example.invalid
git -C "$exc" config user.name gh308-test
git -C "$exc" add .
git -C "$exc" commit -qm baseline
EXC_BASE="$(git -C "$exc" rev-parse HEAD)"

exc_guard() { GH308_GUARD_ROOT="$exc" bash "$exc/test/gh308-frozen-twin-guard.sh" \
  --check --base "$EXC_BASE" --allow-exceptions 2>&1; }
exc_commit() { # <file> <commit-message>
  printf '# edit\n' >>"$exc/relay-automation/$1"
  git -C "$exc" add "relay-automation/$1"
  git -C "$exc" commit -qm "$2"
}
exc_reset() { git -C "$exc" reset -q --hard "$EXC_BASE"; }

# 1. THE DEFECT: a declared exception for one twin must not excuse an undeclared edit to another.
exc_reset
exc_commit codex-turn.sh "$(printf 'fix codex twin\n\nFrozen-twin-exception: relay-automation/codex-turn.sh — declared reason')"
exc_commit relay-drive.sh 'unrelated edit riding along, declares nothing'
out="$(exc_guard)" && rc=0 || rc=$?
if (( rc != 0 )); then
  ok 'a declared exception for one twin does NOT excuse an undeclared edit to another'
else
  bad "range-scoped hatch still in force: an undeclared twin edit passed. Output: $out"
fi
# Naming the uncovered file is the point — the old version printed only the DECLARING commit, so the
# log read like a narrow exception while the undeclared edit stayed invisible.
if printf '%s' "$out" | grep -Fq 'relay-automation/relay-drive.sh was edited with NO Frozen-twin-exception'; then
  ok 'the failure names the uncovered file explicitly'
else
  bad "failure output did not name the uncovered file: $out"
fi
# Reproduce the shipped defect on this exact fixture rather than only asserting its absence. This is
# verbatim the predicate PR #318 put in .github/workflows/ci.yml. If it does NOT allow, the fixture
# has stopped exercising the bug (e.g. someone dropped the declaring trailer) and case 1 above would
# be passing for the wrong reason.
old_rule="$(git -C "$exc" log --format='%H %s%n%b' "${EXC_BASE}..HEAD" | grep -c '^Frozen-twin-exception:' || true)"
if (( old_rule > 0 )); then
  ok 'fixture reproduces the defect: the old range-scoped rule would have allowed this PR'
else
  bad 'fixture no longer exercises the range-scoped defect (no trailer present in the range)'
fi

# 2. Declaring every twin it edits passes — the hatch still works when used honestly.
exc_reset
exc_commit codex-turn.sh "$(printf 'fix codex twin\n\nFrozen-twin-exception: relay-automation/codex-turn.sh — reason A')"
exc_commit relay-drive.sh "$(printf 'fix relay-drive twin\n\nFrozen-twin-exception: relay-automation/relay-drive.sh — reason B')"
if exc_guard >/dev/null; then
  ok 'exceptions covering every edited twin still pass'
else
  bad "a fully declared PR was rejected: $(exc_guard)"
fi

# 3. One trailer may cover several twins at once.
exc_reset
exc_commit codex-turn.sh 'edit one'
exc_commit relay-drive.sh "$(printf 'edit two\n\nFrozen-twin-exception: relay-automation/codex-turn.sh, relay-automation/relay-drive.sh — one reason for both')"
if exc_guard >/dev/null; then
  ok 'a single trailer may name several twins'
else
  bad "multi-path trailer was not honored: $(exc_guard)"
fi

# 4. A typo'd path must fail loudly. Silently covering nothing is the worst outcome: the author
#    believes it is declared, and the guard would either wave the edit through or blame a file the
#    author never mentioned.
exc_reset
exc_commit codex-turn.sh "$(printf 'typo\n\nFrozen-twin-exception: relay-automation/codex-turnn.sh — typo in the path')"
out="$(exc_guard)" && rc=0 || rc=$?
if (( rc != 0 )) && printf '%s' "$out" | grep -Fq 'not a frozen twin: relay-automation/codex-turnn.sh'; then
  ok 'a trailer naming a non-twin path fails and names the bad token'
else
  bad "typo'd path was not rejected (rc=$rc): $out"
fi

# 5. The legacy bare trailer named no file at all — that IS the looseness. It must not keep working.
exc_reset
exc_commit codex-turn.sh "$(printf 'legacy\n\nFrozen-twin-exception: a reason with no path named')"
out="$(exc_guard)" && rc=0 || rc=$?
if (( rc != 0 )); then
  ok 'the legacy path-less trailer no longer excuses anything'
else
  bad "a path-less trailer still passed: $out"
fi

# 6. A trailer that names a path but no reason is malformed too — the trailer exists to record WHY.
exc_reset
exc_commit codex-turn.sh "$(printf 'no reason\n\nFrozen-twin-exception: relay-automation/codex-turn.sh —   ')"
if exc_guard >/dev/null 2>&1; then
  bad 'a trailer with an empty reason was accepted'
else
  ok 'a trailer with no reason text is rejected'
fi

# 7. A reason mentioning another .sh file must not be misread as a coverage claim, and must not be
#    validated as a path — reasons routinely cite files (`see validate.sh`).
exc_reset
exc_commit codex-turn.sh "$(printf 'cite\n\nFrozen-twin-exception: relay-automation/codex-turn.sh — gate is fake, see validate.sh and utils/nope.sh')"
if exc_guard >/dev/null 2>&1; then
  ok 'file names inside the reason text are not parsed as coverage claims'
else
  bad "a reason citing another file was misparsed: $(exc_guard)"
fi

# 8. Without --allow-exceptions the guard keeps its original meaning: ANY frozen-twin edit fails,
#    trailer or not. That is the mode validate.sh and --staged use locally.
exc_reset
exc_commit codex-turn.sh "$(printf 'declared\n\nFrozen-twin-exception: relay-automation/codex-turn.sh — declared reason')"
if GH308_GUARD_ROOT="$exc" bash "$exc/test/gh308-frozen-twin-guard.sh" --check --base "$EXC_BASE" >/dev/null 2>&1; then
  bad 'the strict (no --allow-exceptions) mode honored a trailer it should ignore'
else
  ok 'strict mode still blocks every frozen-twin edit, declared or not'
fi

# 9. --allow-exceptions with --staged is a usage error, not a silent pass: staged changes have no
#    commit trailers to read, so evaluating coverage against them could only ever say "uncovered".
GH308_GUARD_ROOT="$exc" bash "$exc/test/gh308-frozen-twin-guard.sh" --check --staged --allow-exceptions >/dev/null 2>&1 && rc=0 || rc=$?
if (( rc == 2 )); then
  ok '--allow-exceptions --staged is rejected as a usage error (exit 2)'
else
  bad "--allow-exceptions --staged returned $rc, expected the usage exit 2"
fi

# 10. A clean range still passes through the exception path untouched.
exc_reset
printf 'note\n' >"$exc/README.md"
git -C "$exc" add README.md
git -C "$exc" commit -qm docs-only
if exc_guard >/dev/null; then
  ok 'a range touching no frozen twin passes under --allow-exceptions'
else
  bad "a clean range failed under --allow-exceptions: $(exc_guard)"
fi

echo "  gh308-frozen-twin-guard: $pass pass, $fail fail"
[[ "$fail" -eq 0 ]]
