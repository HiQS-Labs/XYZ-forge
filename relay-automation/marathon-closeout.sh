#!/usr/bin/env bash
# marathon-closeout.sh — deterministic git/GitHub ceremony after a marathon.
#
# Exit codes:
#   0  closeout completed, or dry-run rendered successfully
#   2  invalid arguments or unsafe repository/branch precondition
#   3  a git/gh closeout command failed
#   4  PR checks are not green or GitHub reports the PR is not mergeable
#
# Dry-run deliberately requires --head so it can render the complete command
# sequence without invoking git or gh, including read-only discovery commands.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRY_RUN=0
OPEN_ONLY=0
NO_COMMIT=0
AUTO_PR=0
SKIP_GATE_CHECK=0
REPO="."
BASE_BRANCH="development"
HEAD_BRANCH=""
REMOTE="origin"
COMMIT_MESSAGE="chore: close out marathon"
PR_TITLE="Marathon closeout"
PR_NOTES="Automated marathon closeout."

usage() {
  cat >&2 <<'EOF'
usage: marathon-closeout.sh [options]

Options:
  --dry-run            Print the exact closeout sequence; execute no git/gh command.
  --auto-pr            One-shot automated PR creation: sets --open-only and --no-commit.
  --open-only          Stop once the pull request is open; do not check, merge, switch, or pull.
  --no-commit          Push and PR only; do not commit first (GH-561). Required for
                       automated calls: the driver has already committed the phase's own work.
  --skip-gate-check    Bypass checking for on-disk local gate receipt in .xyz/receipts/ or .gate-evidence/.
  --repo DIR           Repository to close out (default: current directory).
  --head BRANCH        Feature branch (required for --dry-run; auto-detected live).
  --base BRANCH        Merge target and final local branch (default: development).
  --remote NAME        Git remote (default: origin).
  --message TEXT       Commit message (default: chore: close out marathon).
  --title TEXT         Pull-request title (default: Marathon closeout).
  --notes TEXT         Pull-request body/notes.
  -h, --help           Show this help.
EOF
}

die_usage() {
  printf 'marathon-closeout.sh: %s\n' "$1" >&2
  usage
  exit 2
}

while (($#)); do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --auto-pr) AUTO_PR=1; OPEN_ONLY=1; NO_COMMIT=1; shift ;;
    --open-only) OPEN_ONLY=1; shift ;;
    --no-commit) NO_COMMIT=1; shift ;;
    --skip-gate-check) SKIP_GATE_CHECK=1; shift ;;
    --repo|--head|--base|--remote|--message|--title|--notes)
      (($# >= 2)) || die_usage "$1 requires a value"
      case "$1" in
        --repo) REPO="$2" ;;
        --head) HEAD_BRANCH="$2" ;;
        --base) BASE_BRANCH="$2" ;;
        --remote) REMOTE="$2" ;;
        --message) COMMIT_MESSAGE="$2" ;;
        --title) PR_TITLE="$2" ;;
        --notes) PR_NOTES="$2" ;;
      esac
      shift 2
      ;;
    -h|--help) usage; exit 0 ;;
    *) die_usage "unknown argument: $1" ;;
  esac
done

[[ -d "$REPO" ]] || die_usage "repository directory not found: $REPO"
cd -- "$REPO"

if [[ "${XYZ_SKIP_GATE_CHECK:-0}" == "1" ]]; then
  SKIP_GATE_CHECK=1
fi

# GH-124 QW2: Hard-lock base branch against main
if [[ "$BASE_BRANCH" == "main" ]]; then
  die_usage "refusing to target 'main' directly — 'development' is the required WIP base branch"
fi

print_command() {
  printf 'DRY-RUN:'
  printf ' %q' "$@"
  printf '\n'
}

print_capture() {
  local variable="$1"
  shift
  printf 'DRY-RUN: %s=$(' "$variable"
  printf '%q ' "$@"
  printf ')\n'
}

if ((DRY_RUN)); then
  [[ -n "$HEAD_BRANCH" ]] || die_usage "--head is required with --dry-run"
  [[ "$HEAD_BRANCH" != "$BASE_BRANCH" ]] || die_usage "head branch must differ from base branch"

  if ((NO_COMMIT)); then
    printf 'DRY-RUN: (--no-commit: skipping commit step)\n'
  else
    print_command git diff --cached --quiet
    print_command git commit -m "$COMMIT_MESSAGE"
  fi
  print_command git push -u "$REMOTE" "$HEAD_BRANCH"
  print_capture EXISTING_PR gh pr list --head "$HEAD_BRANCH" --base "$BASE_BRANCH" --state open --json url --jq '.[0].url'
  print_capture PR_URL gh pr create --base "$BASE_BRANCH" --head "$HEAD_BRANCH" --title "$PR_TITLE" --body "$PR_NOTES"
  if ((OPEN_ONLY)); then
    exit 0
  fi
  print_command gh pr checks '\$PR_URL'
  print_capture MERGEABLE gh pr view '\$PR_URL' --json mergeable --jq .mergeable
  print_command test '\$MERGEABLE' = MERGEABLE
  print_command gh pr merge '\$PR_URL' --merge
  print_command git switch "$BASE_BRANCH"
  print_command git pull --ff-only "$REMOTE" "$BASE_BRANCH"
  exit 0
fi

command -v git >/dev/null 2>&1 || die_usage "git not found on PATH"
command -v gh >/dev/null 2>&1 || die_usage "gh not found on PATH"

inside=""
if ! inside="$(git rev-parse --is-inside-work-tree 2>/dev/null)" || [[ "$inside" != "true" ]]; then
  die_usage "not inside a git worktree: $REPO"
fi

if [[ -z "$HEAD_BRANCH" ]]; then
  if ! HEAD_BRANCH="$(git branch --show-current)"; then
    printf 'marathon-closeout.sh: could not determine current branch\n' >&2
    exit 3
  fi
fi
[[ -n "$HEAD_BRANCH" ]] || die_usage "detached HEAD is not supported; pass --head"
[[ "$HEAD_BRANCH" != "$BASE_BRANCH" ]] || die_usage "refusing to close out the base branch itself"

verify_gate_receipt() {
  local sha="$1"
  if ((SKIP_GATE_CHECK)); then
    return 0
  fi
  local receipt_tool="$SCRIPT_DIR/utils/py/gate_receipt.py"
  if [[ -f "$receipt_tool" ]]; then
    if ! python3 "$receipt_tool" check --repo "$REPO" --sha "$sha" >/dev/null 2>&1; then
      printf 'marathon-closeout.sh: REFUSED — commit %s has no passing local gate receipt in .xyz/receipts/ or .gate-evidence/\n' "${sha:0:8}" >&2
      printf 'Run validate.sh or ci-local.sh first, or pass --skip-gate-check to bypass.\n' >&2
      exit 2
    fi
  fi
}

run_closeout() {
  local label="$1"
  shift
  if ! "$@"; then
    printf 'marathon-closeout.sh: %s failed\n' "$label" >&2
    exit 3
  fi
}

if ((NO_COMMIT)); then
  printf 'marathon-closeout.sh: --no-commit; pushing the branch as committed\n'
  verify_gate_receipt "$(git rev-parse HEAD)"
else
  # GH-124 QW2: Purge indiscriminate git add -A
  if git diff --cached --quiet; then
    if [[ -n "$(git status --porcelain)" ]]; then
      die_usage "uncommitted changes exist in working tree. Commit your changes first (blanket git add -A is purged per GH-124)."
    else
      printf 'marathon-closeout.sh: no staged changes; skipping commit\n'
    fi
  else
    run_closeout "commit" git commit -m "$COMMIT_MESSAGE"
  fi
  verify_gate_receipt "$(git rev-parse HEAD)"
fi
run_closeout "push" git push -u "$REMOTE" "$HEAD_BRANCH"

if ! PR_URL="$(gh pr list --head "$HEAD_BRANCH" --base "$BASE_BRANCH" --state open --json url --jq '.[0].url')"; then
  printf 'marathon-closeout.sh: could not query existing pull requests\n' >&2
  exit 3
fi
if [[ -n "$PR_URL" ]]; then
  printf 'marathon-closeout.sh: reusing open PR %s\n' "$PR_URL"
else
  if ! PR_URL="$(gh pr create --base "$BASE_BRANCH" --head "$HEAD_BRANCH" --title "$PR_TITLE" --body "$PR_NOTES")"; then
    printf 'marathon-closeout.sh: pull-request creation failed\n' >&2
    exit 3
  fi
  [[ -n "$PR_URL" ]] || { printf 'marathon-closeout.sh: pull-request creation returned no URL\n' >&2; exit 3; }
fi

if ((OPEN_ONLY)); then
  printf 'marathon-closeout.sh: open PR ready at %s\n' "$PR_URL"
  exit 0
fi

# GH-544: "no checks configured" and "checks failed" are DIFFERENT states, and this used to conflate
# them. With hosted CI off for the private phase (#544), every PR has zero checks — `gh pr checks`
# then exits non-zero and the old code took the `exit 4` refusal path, so an automated closeout could
# never merge anything again.
#
# The fix must not be "ignore check failures": that would silently discard a real gate the moment CI
# returns, which is strictly worse than the bug it replaces. So the two states are separated by
# reading gh's OUTPUT, not just its exit code — gh says "no checks reported" when none are configured.
#
# A closeout with no checks is not unverified: `githooks/pre-push` gated the push that created this
# branch. It is stated out loud anyway, because "merged with no CI" should never be invisible.
#
# THE CAPTURE MUST SIT INSIDE THE `if`. This script runs under `set -euo pipefail` (line 12), and a
# bare `_checks_out="$(gh pr checks ...)"` whose command fails exits the script IMMEDIATELY — the
# following `_checks_rc=$?` is never reached and the whole no-checks branch below is dead code. That
# is exactly what the first version of this fix did, and its test passed anyway because the test
# eval'd the block without `set -e`. Both are fixed; the test now runs the block under the production
# shell options.
#
# TWO SIGNALS, and MEASUREMENT DECIDED WHICH ONE ACTUALLY CARRIES THIS.
#
# A cross-model review recommended preferring `--json bucket` over matching gh's human prose, on the
# sound general principle that wording is not an API. So it is tried first. But observed against a
# REAL check-less PR (#545, gh 2.96.0), `--json bucket` does NOT return `[]` — it prints the same
# prose and exits 1:
#
#     $ gh pr checks 545 --json bucket
#     no checks reported on the 'fix/gh544-parallel-default' branch     [exit 1]
#
# So the PROSE match is what actually recognises this state today; the `[]` branch below is
# forward-looking and currently never fires. Both are kept: if gh starts returning an empty list, the
# structured signal takes over and the prose match becomes the redundant one. Saying which is load-
# bearing matters — the previous version of this comment claimed --json was primary, which was a
# guess, and the guess was wrong.
#
# Anything that is neither an empty bucket nor the no-checks prose is a REFUSAL.
# >>> GH-544 checks-gate BEGIN (extracted verbatim by test/gh544-pre-push-gate.sh — keep the
# sentinels; a line-range extract broke when this block grew a second `fi`.)
_checks_out=""
_checks_rc=0
if _checks_out="$(gh pr checks "$PR_URL" 2>&1)"; then
  _checks_rc=0
else
  _checks_rc=$?
fi
_checks_json=""
if _checks_json="$(gh pr checks "$PR_URL" --json bucket 2>/dev/null)"; then :; else _checks_json=""; fi
if [ "$_checks_rc" -ne 0 ]; then
  case "${_checks_json:-}" in
    "[]")
      printf 'marathon-closeout.sh: no CI checks are configured for this PR (empty --json bucket) — proceeding.\n'
      printf 'marathon-closeout.sh:   Hosted CI is off for the private phase (GH-544); the local\n'
      printf 'marathon-closeout.sh:   pre-push gate is what verified this branch. Merging WITHOUT CI.\n'
      _checks_rc=0
      ;;
  esac
fi
if [ "$_checks_rc" -ne 0 ]; then
  case "$_checks_out" in
    *"no checks reported"*|*"No checks reported"*)
      printf 'marathon-closeout.sh: no CI checks are configured for this PR — proceeding.\n'
      printf 'marathon-closeout.sh:   Hosted CI is off for the private phase (GH-544); the local\n'
      printf 'marathon-closeout.sh:   pre-push gate is what verified this branch. Merging WITHOUT CI.\n'
      ;;
    *)
      printf '%s\n' "$_checks_out" >&2
      printf 'marathon-closeout.sh: PR checks are not green; refusing to merge\n' >&2
      exit 4
      ;;
  esac
fi
# <<< GH-544 checks-gate END

if ! MERGEABLE="$(gh pr view "$PR_URL" --json mergeable --jq .mergeable)"; then
  printf 'marathon-closeout.sh: could not read PR mergeability\n' >&2
  exit 3
fi
if [[ "$MERGEABLE" != "MERGEABLE" ]]; then
  printf 'marathon-closeout.sh: PR is not mergeable (%s); refusing to merge\n' "$MERGEABLE" >&2
  exit 4
fi

run_closeout "merge" gh pr merge "$PR_URL" --merge
run_closeout "switch to $BASE_BRANCH" git switch "$BASE_BRANCH"
run_closeout "pull $BASE_BRANCH" git pull --ff-only "$REMOTE" "$BASE_BRANCH"

printf 'marathon-closeout.sh: merged %s and updated %s\n' "$PR_URL" "$BASE_BRANCH"
