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

DRY_RUN=0
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

  print_command git add -A
  print_command git commit -m "$COMMIT_MESSAGE"
  print_command git push -u "$REMOTE" "$HEAD_BRANCH"
  print_capture PR_URL gh pr create --base "$BASE_BRANCH" --head "$HEAD_BRANCH" --title "$PR_TITLE" --body "$PR_NOTES"
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

run_closeout() {
  local label="$1"
  shift
  if ! "$@"; then
    printf 'marathon-closeout.sh: %s failed\n' "$label" >&2
    exit 3
  fi
}

run_closeout "stage all changes" git add -A
run_closeout "commit" git commit -m "$COMMIT_MESSAGE"
run_closeout "push" git push -u "$REMOTE" "$HEAD_BRANCH"

if ! PR_URL="$(gh pr create --base "$BASE_BRANCH" --head "$HEAD_BRANCH" --title "$PR_TITLE" --body "$PR_NOTES")"; then
  printf 'marathon-closeout.sh: pull-request creation failed\n' >&2
  exit 3
fi
[[ -n "$PR_URL" ]] || { printf 'marathon-closeout.sh: pull-request creation returned no URL\n' >&2; exit 3; }

if ! gh pr checks "$PR_URL"; then
  printf 'marathon-closeout.sh: PR checks are not green; refusing to merge\n' >&2
  exit 4
fi

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
