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
  # GH-362: marathon-plan was GH-308's ONE documented exception — its Bash body stayed authoritative
  # and dual-maintained because the "port" delegated to a copied, drifted node engine. GH-340 removed
  # that reason: `utils/py/_marathon_plan.py` is a native stdlib engine, the copied JS is deleted, and
  # the Python lane needs no Node. The exception outlived its rationale, so it is retired here and
  # marathon-plan becomes the 12th frozen twin.
  utils/marathon-plan.sh:utils/py/marathon_plan.py
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

# ── GH-551: no NEW Bash either ────────────────────────────────────────────────────────────────────
# The freeze above stops behavior landing in the twelve legacy twins, but said nothing about a brand-
# new .sh appearing beside them — which is how the class regrows. New executables are Python in
# utils/py/; a NEW .sh added under utils/ or relay-automation/ is blocked unless a trailer names it:
#
#   New-bash-exception: relay-automation/some-shim.sh — <reason>
#
# Same per-file philosophy as GH-321: every added file must be named, a typo'd trailer covers nothing
# and the unnamed file still fails by name. test/, git hooks, and existing shims are out of scope —
# only ADDED (--diff-filter=A) files under the two guarded trees.
check_new_bash() {
  local added
  if (( staged )); then
    added="$(git -C "$ROOT" diff --cached --name-only --diff-filter=A -- 'utils/*.sh' 'relay-automation/*.sh')"
  else
    added="$(git -C "$ROOT" diff --name-only --diff-filter=A "${base}..HEAD" -- 'utils/*.sh' 'relay-automation/*.sh')"
  fi
  if [[ -z "$added" ]]; then
    echo 'gh308 guard: no new Bash under utils/ or relay-automation/'
    return 0
  fi
  local declared=""
  if (( allow_exceptions )); then
    # ponytail: path-named-in-trailer is the whole check — no reason-text validation like GH-321's;
    # add it if the hatch gets abused with bare paths.
    declared="$(git -C "$ROOT" log --format='%B' "${base}..HEAD" | sed -n 's/^New-bash-exception:[[:space:]]*//p')"
  fi
  local f bad=0
  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    if [[ -n "$declared" ]] && printf '%s\n' "$declared" | grep -F -- "$f" >/dev/null; then
      printf 'gh308 guard: new Bash %s — covered by a declared New-bash-exception\n' "$f"
    else
      printf 'gh308 guard: NEW Bash file blocked: %s — new executables are Python in utils/py/ (GH-551)\n' "$f" >&2
      bad=1
    fi
  done <<EOF
$added
EOF
  if (( bad )); then
    printf 'gh308 guard: write it in utils/py/, or declare: New-bash-exception: <path> — <reason>\n' >&2
    return 1
  fi
  return 0
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

# ── GH-362: the freeze itself is not a violation of the freeze ───────────────────────────────────
# A range whose base predates the freeze contains the commit that ADDED the FROZEN banners, and that
# commit necessarily touches every frozen twin. The guard was structurally unable to pass there: it
# blocked the release PR that first merged `development` into `main` (#361), naming all 11 twins,
# with nothing wrong in the diff.
#
# The predicate is narrow on purpose. A commit that *introduces* a path's FROZEN banner establishes
# the freeze for that path; edits to that path AFTER that commit are ordinary violations and are
# still caught. So this exempts the establishing edit, not the file.
#
# Not self-limiting, despite appearances: once `main` contains the freeze, later `main..development`
# ranges are clean — but a bisect run, a long-lived branch, a fork comparing against an old base, or
# a release branch cut from before the freeze all reach back past it again.
freeze_commit_for() {  # <base> <path> → stdout: the commit in base..HEAD that introduced FROZEN, or ""
  local base="$1" path="$2" out
  # Deliberately NOT `| head -1`: head closing the pipe early makes git's write fail, and under
  # `set -euo pipefail` that surfaced as `printf: write error: Interrupted system call` on every call.
  # Take the first line in-shell instead.
  out="$(git -C "$ROOT" log --format=%H --reverse -S 'FROZEN' "${base}..HEAD" -- "$path" 2>/dev/null || true)"
  [[ -n "$out" ]] || return 0
  printf '%s\n' "${out%%$'\n'*}"
}

# Is every edit to <path> in this range at-or-before the commit that froze it?
path_edits_are_only_the_freeze() {  # <base> <path>
  local base="$1" path="$2" fc after
  fc="$(freeze_commit_for "$base" "$path")"
  [[ -n "$fc" ]] || return 1                     # the freeze is not in this range; nothing to exempt
  # Any commit touching the path strictly after the freeze commit is a real post-freeze edit.
  after="$(git -C "$ROOT" log --format=%H "${fc}..HEAD" -- "$path" 2>/dev/null)"
  [[ -z "$after" ]]
}

# The set of commits in the range that establish a freeze for at least one twin. Their commit
# messages predate the GH-321 per-file trailer format, so their trailers must not hard-fail parsing.
freeze_establishing_commits() {  # <base> → stdout: one SHA per line
  local base="$1" pair p fc
  for pair in "${TWINS[@]}"; do
    p="${pair%%:*}"
    fc="$(freeze_commit_for "$base" "$p")"
    [[ -n "$fc" ]] && printf '%s\n' "$fc"
  done | sort -u
}

collect_declared() {  # <base> → stdout: covered paths, one per line. rc 1 if ANY trailer is malformed.
  local base="$1" rc=0 line rest paths_part reason token found
  local -a skip_commits=()
  # GH-362(B): a malformed trailer used to hard-fail the WHOLE run, even when it sat in a commit whose
  # edits need no coverage at all. `07ae1e7` is exactly that case — its trailer is the pre-GH-321 bare
  # form (`Frozen-twin-exception: <reason>`, no path), which was correct when written, and it is the
  # freeze-establishing commit whose edits (A) already exempts. Git history cannot be rewritten, so
  # the format change shipped in GH-321 needs this back-compat or it permanently rejects its own past.
  #
  # Scoped deliberately: ONLY freeze-establishing commits are skipped. Every other commit still gets
  # the full GH-321 treatment, so a new pathless trailer is still rejected — which is what GH-321 was
  # actually for.
  # Portable collect: `mapfile` is a bash 4+ builtin and macOS ships bash 3.2, which this repo's
  # scripts must keep working under.
  local _sc
  while IFS= read -r _sc; do
    [[ -n "$_sc" ]] && skip_commits+=("$_sc")
  done < <(freeze_establishing_commits "$base")
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
  done < <(eligible_trailer_lines "$base" "${skip_commits[@]+"${skip_commits[@]}"}")
  return "$rc"
}

# Emit trailer candidate lines from every commit in base..HEAD EXCEPT the given skip commits, with
# git-standard indented continuation lines folded onto their trailer.
#
# Folding is limited to INDENTED continuations, which is the form `git interpret-trailers` recognises.
# A trailer wrapped flush-left (as `07ae1e7`'s is) is indistinguishable from the start of the next
# paragraph, and guessing would let arbitrary prose become part of a coverage claim. Such a trailer is
# therefore still read as its first line only — correct, and harmless now that (A)/(B) stop that
# commit from failing the run. Wrap new trailers with indentation, or keep them on one line.
eligible_trailer_lines() {  # <base> [skip-sha...]
  local base="$1"; shift
  local -a skip=("$@")
  local sha body line pending="" s skipthis
  while IFS= read -r sha; do
    [[ -n "$sha" ]] || continue
    skipthis=0
    for s in ${skip[@]+"${skip[@]}"}; do [[ "$s" == "$sha" ]] && { skipthis=1; break; }; done
    (( skipthis )) && continue
    pending=""
    while IFS= read -r line; do
      if [[ -n "$pending" && "$line" =~ ^[[:space:]]+[^[:space:]] ]]; then
        # indented continuation of the trailer we are holding
        pending="$pending ${line#"${line%%[![:space:]]*}"}"
        continue
      fi
      [[ -n "$pending" ]] && { printf '%s\n' "$pending"; pending=""; }
      case "$line" in
        Frozen-twin-exception:*) pending="$line" ;;
        *) printf '%s\n' "$line" ;;
      esac
    done < <(git -C "$ROOT" log -1 --format='%B' "$sha")
    [[ -n "$pending" ]] && printf '%s\n' "$pending"
  done < <(git -C "$ROOT" log --format=%H "${base}..HEAD")
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
    # GH-362(A): the commit that established this path's freeze is not a violation of it. Only exempt
    # when the freeze is the LAST thing that touched the path in this range — a later edit is real.
    if path_edits_are_only_the_freeze "$base" "$f"; then
      printf 'gh308 guard: %s — the only edit in this range IS the commit that froze it (%s)\n' \
        "$f" "$(freeze_commit_for "$base" "$f" | cut -c1-8)"
    elif printf '%s\n' "$declared" | grep -Fx -- "$f" >/dev/null; then
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
  (( rc == 2 )) && exit 2
  nb=0
  check_new_bash || nb=1   # GH-551: handles its own trailer coverage under --allow-exceptions
  (( rc == 0 )) && exit "$nb"
  (( allow_exceptions )) || exit "$rc"
  echo "---"
  if check_exception_coverage "$base"; then
    # Wording matters: an edit can be permitted for two different reasons and conflating them would
    # let a reader believe a declaration exists where none does (GH-362).
    echo 'gh308 guard: every frozen-twin edit in this range is accounted for — declared, or the freeze itself'
    exit "$nb"
  fi
  exit 1
fi

# CI supplies the merge-base explicitly; local validation intentionally stays structural so the
# bootstrap commit that adds these banners can establish the frozen baseline.
if [[ -n "${GH308_FROZEN_TWIN_BASE:-}" ]]; then
  base="$GH308_FROZEN_TWIN_BASE"
  check_changes
  check_new_bash
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

# GH-362: this assertion is INVERTED from what it pinned before. marathon-plan was GH-308's one
# Bash-authoritative exception; GH-340 deleted the copied node engine that was its entire rationale,
# so the exception is retired and the file is the 12th frozen twin. Kept as an explicit assertion
# rather than deleted, so a future revert of the freeze fails loudly instead of silently restoring an
# exception whose reason no longer exists.
if grep -Fq 'FROZEN (GH-308)' "$ROOT/utils/marathon-plan.sh"; then
  ok 'marathon-plan is frozen — the GH-308 exception is retired (GH-362)'
else
  bad 'marathon-plan lost its FROZEN banner: the GH-362 retirement was reverted without a decision'
fi

if ! grep -Fq 'FROZEN (GH-308)' "$ROOT/relay-automation/relay-turn-lib.sh"; then
  ok 'relay-turn-lib remains the shared Bash dependency, not a twin'
else
  bad 'relay-turn-lib must not be frozen: Python invokes it at runtime'
fi

# Demonstrate the range guard against an actual throwaway commit, not merely a staged diff.
tmp="$(mktemp -d "${TMPDIR:-/tmp}/gh308-frozen-twin.XXXXXX")"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/fixture-guard.sh"   # GH-10: shared fixture containment
fixture_guard_init "$tmp"   # GH-10: pin the sandbox root
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
exc="$(mktemp -d "$tmp/gh308-exceptions.XXXXXX")"
require_fixture "$exc" "exceptions fixture"  # GH-10
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
if printf '%s' "$out" | grep -F 'relay-automation/relay-drive.sh was edited with NO Frozen-twin-exception' >/dev/null; then
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
if (( rc != 0 )) && printf '%s' "$out" | grep -F 'not a frozen twin: relay-automation/codex-turnn.sh' >/dev/null; then
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

# ── GH-362: the freeze itself, and the trailer format that predates the freeze ───────────────────
# These four reproduce what blocked release PR #361 — the first time `development`..`main` was ever
# put through CI. The guard named all 11 twins with nothing wrong in the diff, because the range
# contained `07ae1e7`, the commit that ADDED the banners.
#
# The fixture mirrors that shape: a base where a twin has NO banner, then a commit that introduces it.
exc_unfreeze_commit() {  # <file> — remove the banner and commit; echoes the resulting SHA
  local f="$1"
  printf '#!/usr/bin/env bash\n# not yet frozen\n' >"$exc/relay-automation/$f"
  git -C "$exc" add "relay-automation/$f"
  git -C "$exc" commit -qm "pre-freeze state for $f"
  git -C "$exc" rev-parse HEAD
}
exc_freeze_commit() {  # <file> <commit-message> — (re)introduce the banner + an edit, in one commit
  printf '#!/usr/bin/env bash\n# FROZEN (GH-308): Python is authoritative\n# edit landed with the freeze\n' \
    >"$exc/relay-automation/$1"
  git -C "$exc" add "relay-automation/$1"
  git -C "$exc" commit -qm "$2"
}
exc_guard_from() {  # <base> — same invocation as exc_guard, against an arbitrary base
  GH308_GUARD_ROOT="$exc" bash "$exc/test/gh308-frozen-twin-guard.sh" \
    --check --base "$1" --allow-exceptions 2>&1
}

# 11. A range whose only edit to a twin IS the commit that froze it must PASS. Pre-fix this was
#     structurally impossible — the freeze necessarily touches every twin it freezes.
exc_reset
pre_freeze="$(exc_unfreeze_commit codex-turn.sh)"
exc_freeze_commit codex-turn.sh 'freeze the codex twin'
out="$(exc_guard_from "$pre_freeze")" && rc=0 || rc=$?
if (( rc == 0 )) && printf '%s' "$out" | grep -F 'the only edit in this range IS the commit that froze it' >/dev/null; then
  ok 'the commit that establishes a freeze is not itself a freeze violation [GH-362]'
else
  bad "freeze-establishing commit was blocked (rc=$rc): $out"
fi

# 12. The exemption is for the establishing EDIT, not the file. An edit landing after the freeze in
#     the same range is an ordinary violation and must still fail — otherwise case 11 is a hole.
exc_reset
pre_freeze="$(exc_unfreeze_commit codex-turn.sh)"
exc_freeze_commit codex-turn.sh 'freeze the codex twin'
exc_commit codex-turn.sh 'sneak a real change in after the freeze, declaring nothing'
out="$(exc_guard_from "$pre_freeze")" && rc=0 || rc=$?
if (( rc != 0 )) && printf '%s' "$out" | grep -F 'relay-automation/codex-turn.sh was edited with NO Frozen-twin-exception' >/dev/null; then
  ok 'a post-freeze edit in the same range is still blocked [GH-362]'
else
  bad "post-freeze edit slipped through the freeze exemption (rc=$rc): $out"
fi

# 13. The pre-GH-321 pathless trailer lives permanently in `07ae1e7`'s message. It was correct when
#     written, history cannot be rewritten, and it must not hard-fail the run — but ONLY in a
#     freeze-establishing commit. Case 5 above still rejects it anywhere else.
exc_reset
pre_freeze="$(exc_unfreeze_commit codex-turn.sh)"
exc_freeze_commit codex-turn.sh "$(printf 'freeze the codex twin\n\nFrozen-twin-exception: a legacy bare reason with no path, as GH-319 wrote it')"
out="$(exc_guard_from "$pre_freeze")" && rc=0 || rc=$?
if (( rc == 0 )) && ! printf '%s' "$out" | grep -F 'malformed Frozen-twin-exception' >/dev/null; then
  ok "a legacy path-less trailer in the freeze commit does not fail the run [GH-362]"
else
  bad "legacy trailer in the freeze commit still hard-failed (rc=$rc): $out"
fi

# 14. An indented continuation line is folded onto its trailer, so a wrapped declaration still
#     covers what it names. (Flush-left wrapping is deliberately NOT folded — indistinguishable from
#     the next paragraph — so this pins the form that IS supported.)
exc_reset
exc_commit codex-turn.sh "$(printf 'wrapped trailer\n\nFrozen-twin-exception: relay-automation/codex-turn.sh —\n  the reason continues on an indented line, which git treats as part of the trailer')"
out="$(exc_guard)" && rc=0 || rc=$?
if (( rc == 0 )); then
  ok 'an indented continuation line is folded onto its trailer [GH-362]'
else
  bad "a wrapped (indented) trailer was not folded: $out"
fi

# ── GH-551: no new Bash under utils/ or relay-automation/ ────────────────────────────────────────
exc_add_commit() {  # <path> <commit-message> — add a brand-new file
  mkdir -p "$exc/$(dirname "$1")"
  printf '#!/usr/bin/env bash\necho new\n' >"$exc/$1"
  git -C "$exc" add "$1"
  git -C "$exc" commit -qm "$2"
}

# 15. A brand-new .sh under a guarded tree is blocked and named.
exc_reset
exc_add_commit utils/new-helper.sh 'adds a new bash helper, declaring nothing'
out="$(exc_guard)" && rc=0 || rc=$?
if (( rc != 0 )) && printf '%s' "$out" | grep -F 'NEW Bash file blocked: utils/new-helper.sh' >/dev/null; then
  ok 'a new .sh under utils/ is blocked and named [GH-551]'
else
  bad "new .sh under utils/ was not blocked (rc=$rc): $out"
fi

# 16. A New-bash-exception trailer naming the file lets it pass under --allow-exceptions.
exc_reset
exc_add_commit relay-automation/new-shim.sh "$(printf 'adds a declared shim\n\nNew-bash-exception: relay-automation/new-shim.sh — declared reason')"
if exc_guard >/dev/null; then
  ok 'a declared New-bash-exception covers the added file [GH-551]'
else
  bad "a declared new-bash addition was rejected: $(exc_guard)"
fi

# 17. The trailer is per-file: it must not excuse a second, unnamed addition riding along.
exc_reset
exc_add_commit relay-automation/new-shim.sh "$(printf 'adds a declared shim\n\nNew-bash-exception: relay-automation/new-shim.sh — declared reason')"
exc_add_commit utils/rider.sh 'second addition, declares nothing'
out="$(exc_guard)" && rc=0 || rc=$?
if (( rc != 0 )) && printf '%s' "$out" | grep -F 'NEW Bash file blocked: utils/rider.sh' >/dev/null; then
  ok 'a declared exception does not excuse an unnamed second addition [GH-551]'
else
  bad "an unnamed new .sh rode along on another file's trailer (rc=$rc): $out"
fi

# 18. Outside the guarded trees (test/, docs, hooks) new Bash is untouched.
exc_reset
exc_add_commit test/new-test.sh 'adds a test script, no trailer needed'
if exc_guard >/dev/null; then
  ok 'a new .sh outside the guarded trees passes without a trailer [GH-551]'
else
  bad "a new test/*.sh was wrongly blocked: $(exc_guard)"
fi

# 19. Strict mode (no --allow-exceptions) blocks a new .sh even when declared — same shape as case 8.
exc_reset
exc_add_commit utils/declared-anyway.sh "$(printf 'declared\n\nNew-bash-exception: utils/declared-anyway.sh — declared reason')"
if GH308_GUARD_ROOT="$exc" bash "$exc/test/gh308-frozen-twin-guard.sh" --check --base "$EXC_BASE" >/dev/null 2>&1; then
  bad 'strict mode honored a New-bash-exception trailer it should ignore'
else
  ok 'strict mode blocks a new .sh, declared or not [GH-551]'
fi

# 20. Editing an EXISTING non-twin .sh in a guarded tree is not an "addition" and still passes.
exc_reset
exc_add_commit relay-automation/existing-lib.sh 'baseline gains a lib (declared so it lands)
New-bash-exception: relay-automation/existing-lib.sh — fixture baseline'
NEW_BASE="$(git -C "$exc" rev-parse HEAD)"
printf '# edit to an existing non-twin file\n' >>"$exc/relay-automation/existing-lib.sh"
git -C "$exc" add relay-automation/existing-lib.sh
git -C "$exc" commit -qm 'edit the existing lib'
if exc_guard_from "$NEW_BASE" >/dev/null; then
  ok 'editing an existing non-twin .sh is not treated as an addition [GH-551]'
else
  bad "an edit to an existing non-twin .sh was blocked as new: $(exc_guard_from "$NEW_BASE")"
fi

echo "  gh308-frozen-twin-guard: $pass pass, $fail fail"
[[ "$fail" -eq 0 ]]
