#!/usr/bin/env bash
# Export BROWSERBASE_API_KEY from a secret file kept OUTSIDE the repo.
# Source it:   source skills/browserbase/env.sh
# Or run it:   skills/browserbase/env.sh --check   (verifies without printing the key)
#
# Resolution order:
#   1. BROWSERBASE_API_KEY already set in the environment -> keep it
#   2. $BROWSERBASE_KEY_FILE (if set)
#   3. $HOME/secrets/browserbase.txt   (repo convention: secrets live by path under ~/secrets/)
#
# The file holds the key on its first line, nothing else. The key is never echoed.

_bb_key_file="${BROWSERBASE_KEY_FILE:-$HOME/secrets/browserbase.txt}"

if [ -z "${BROWSERBASE_API_KEY:-}" ]; then
  if [ -r "$_bb_key_file" ]; then
    BROWSERBASE_API_KEY="$(head -n 1 "$_bb_key_file" | tr -d '[:space:]')"
    export BROWSERBASE_API_KEY
  fi
fi

# Browserbase resolves the project from the key; a PROJECT_ID is not required and
# a stale placeholder makes SDK calls fail, so make sure nothing leaks one in.
unset BROWSERBASE_PROJECT_ID

if [ "${1:-}" = "--check" ]; then
  if [ -z "${BROWSERBASE_API_KEY:-}" ]; then
    echo "browserbase: no key. Put it on line 1 of $_bb_key_file (or set BROWSERBASE_KEY_FILE)." >&2
    exit 1
  fi
  case "$BROWSERBASE_API_KEY" in
    bb_live_*|bb_test_*) echo "browserbase: key loaded from ${_bb_key_file} (prefix ${BROWSERBASE_API_KEY%%_*}_..., ${#BROWSERBASE_API_KEY} chars)" ;;
    *) echo "browserbase: key loaded but does not look like a Browserbase key (expected bb_live_/bb_test_ prefix)" >&2; exit 1 ;;
  esac
  if command -v browse >/dev/null 2>&1; then
    echo "browserbase: browse CLI $(browse --version 2>/dev/null | tail -n 1)"
  else
    echo "browserbase: browse CLI not installed -> npm install -g browse@latest (ask the operator first)" >&2
  fi
fi

unset _bb_key_file
