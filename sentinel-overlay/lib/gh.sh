#!/usr/bin/env bash
# gh.sh — gated GitHub wrapper. The ONLY place `gh` (and any git push) is invoked in the overlay.
# Inert unless sentinel_active. Every call-home to GitHub routes through here so the static guard
# and the inert-by-default test have a single choke point to verify.
set -u
_GH_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "$_GH_LIB/config.sh"

# sentinel_gh <args...> — passthrough to `gh`, only when active. Returns 1 (no-op) when inert.
sentinel_gh() {
  sentinel_require_active "gh ${1:-}" || return 1
  gh "$@"
}

# sentinel_git_push <args...> — the only sanctioned network push. Gated.
sentinel_git_push() {
  sentinel_require_active "git push" || return 1
  git push "$@"
}
