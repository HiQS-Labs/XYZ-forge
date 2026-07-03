#!/usr/bin/env bash
# test/_scratch-repo.sh — shared hardened scratch-repo helper (GH-44)
#
# Source this file from fixture scripts that need a throwaway git repo that CANNOT
# fall through to an ancestor repo if git init fails or is sandbox-blocked:
#
#   source "$(cd "$(dirname "$0")" && pwd)/../../_scratch-repo.sh"
#   make_scratch_repo "$SC"
#
# What the helper does:
#   1. Exports GIT_CEILING_DIRECTORIES to the scratch dir's PARENT so git never
#      walks up past it when discovering .git.
#   2. Runs `git init -q` inside the scratch dir.
#   3. Hard-asserts that <dir>/.git exists — aborts with a clear message if not,
#      instead of silently letting `git -C <dir>` fall through to the parent repo.
#   4. Sets a local user.name / user.email so commits work without global config.
#
# Requirements: bash 3.2+, POSIX. Idempotent when sourced multiple times.
# (GH-44 — scratch-repo .git fall-through RCA)

# Guard against double-sourcing.
if [ "${_SCRATCH_REPO_LOADED:-0}" = "1" ]; then
  return 0 2>/dev/null || true
fi
_SCRATCH_REPO_LOADED=1

# make_scratch_repo <dir>
#   Creates a hardened throwaway git repo at <dir>.
#   Exits non-zero with a clear error message if the repo cannot be initialised.
make_scratch_repo() {
  local dir="$1"

  if [ -z "$dir" ]; then
    echo "_scratch-repo.sh: make_scratch_repo requires a directory argument" >&2
    return 1
  fi

  # Step 1: cap git's upward .git discovery at the scratch dir's parent so a
  # failed/blocked init can never fall through to a containing repo.
  local parent
  parent="$(dirname "$dir")"
  # Append to any existing ceiling (colon-separated list).
  if [ -z "${GIT_CEILING_DIRECTORIES:-}" ]; then
    export GIT_CEILING_DIRECTORIES="$parent"
  else
    export GIT_CEILING_DIRECTORIES="${GIT_CEILING_DIRECTORIES}:${parent}"
  fi

  # Step 2: create the directory and initialise the git repo.
  mkdir -p "$dir"
  git init -q "$dir" 2>/dev/null

  # Step 3: hard-assert that .git was actually created — abort instead of
  # silently allowing `git -C "$dir"` to discover a parent .git.
  if [ ! -d "$dir/.git" ]; then
    echo "_scratch-repo.sh: FATAL — could not create scratch git repo at $dir/.git" >&2
    echo "  (sandbox may have blocked git init; aborting to prevent fall-through to parent repo)" >&2
    return 1
  fi

  # Step 4: set local identity so commits don't require global git config.
  git -C "$dir" config user.email "scratch@test"
  git -C "$dir" config user.name "scratch"
}
