#!/usr/bin/env bash
#
# install.sh — make relay-to-issue discoverable to Claude Code from THIS clone.
#
# The repo keeps skills in top-level skills/, which Claude Code does NOT scan. A
# session only finds /relay-to-issue if it is symlinked into the user skills dir
# (~/.claude/skills/). This script creates that symlink — idempotently,
# self-locating, no hardcoded machine path — so any clone can register the skill
# in one command.
#
#   bash skills/relay-to-issue/install.sh             # install / repair the symlink
#   CLAUDE_SKILLS_DIR=/path bash …/install.sh         # override the user skills dir
#
# Safe to re-run. Refuses to clobber a real directory; replaces a stale symlink.
set -u

# --- resolve this script's real directory (symlink-safe; bash 3.2 / macOS) ---
_src="${BASH_SOURCE[0]}"
while [ -h "$_src" ]; do
  _dir="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"
  _src="$(readlink "$_src")"
  case "$_src" in /*) ;; *) _src="$_dir/$_src" ;; esac
done
SELF_DIR="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"   # …/skills/relay-to-issue

DEST_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
LINK="$DEST_DIR/relay-to-issue"

mkdir -p "$DEST_DIR"

if [ -L "$LINK" ] && [ "$(readlink "$LINK")" = "$SELF_DIR" ]; then
  echo "relay-to-issue: already installed → $LINK -> $SELF_DIR"
elif [ -e "$LINK" ] && [ ! -L "$LINK" ]; then
  echo "relay-to-issue: $LINK exists as a real directory — not overwriting." >&2
  echo "  Move it aside and re-run, or set CLAUDE_SKILLS_DIR." >&2
  exit 1
else
  [ -L "$LINK" ] && rm -f "$LINK"   # stale / dangling / wrong-target symlink
  ln -s "$SELF_DIR" "$LINK"
  echo "relay-to-issue: installed → $LINK -> $SELF_DIR"
fi

# --- verify the dependency the skill actually needs ---
if command -v gh >/dev/null 2>&1; then
  if gh auth status >/dev/null 2>&1; then
    echo "relay-to-issue: gh authenticated ✓"
  else
    echo "relay-to-issue: WARNING — gh is installed but not authenticated (run: gh auth login)." >&2
  fi
else
  echo "relay-to-issue: WARNING — gh CLI not found on PATH; the skill needs it to file issues." >&2
fi
