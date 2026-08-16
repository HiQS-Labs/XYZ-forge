#!/usr/bin/env bash
#
# install.sh — make relay-xyz discoverable to Claude Code from THIS clone.
#
# THE problem this fixes: the repo keeps its skills in top-level skills/, a directory
# Claude Code does NOT scan. A session only finds relay-xyz if it is symlinked into the
# user skills dir (~/.claude/skills/). A fresh clone / other machine has no such symlink,
# so the skill is invisible in EVERY session there ("other VS Code sessions not finding
# the files"). This script creates that symlink — idempotently, self-locating, with no
# hardcoded machine path — so any clone can make itself discoverable in one command.
#
#   bash skills/relay-xyz/install.sh          # install / repair the symlink
#   CLAUDE_SKILLS_DIR=/path bash …/install.sh # override the user skills dir
#
# Safe to re-run. Refuses to clobber a real directory; replaces a stale/dangling symlink.
set -u

# --- resolve this script's real directory (symlink-safe; bash 3.2 / macOS) ---
_src="${BASH_SOURCE[0]}"
while [ -h "$_src" ]; do
  _dir="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"
  _src="$(readlink "$_src")"
  case "$_src" in /*) ;; *) _src="$_dir/$_src" ;; esac
done
SELF_DIR="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"   # …/skills/relay-xyz

DEST_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
LINK="$DEST_DIR/relay-xyz"

mkdir -p "$DEST_DIR"

if [ -L "$LINK" ] && [ "$(readlink "$LINK")" = "$SELF_DIR" ]; then
  echo "relay-xyz: already installed → $LINK -> $SELF_DIR"
elif [ -e "$LINK" ] && [ ! -L "$LINK" ]; then
  echo "relay-xyz: $LINK exists as a real directory — not overwriting." >&2
  echo "  Move it aside and re-run, or set CLAUDE_SKILLS_DIR." >&2
  exit 1
else
  [ -L "$LINK" ] && rm -f "$LINK"   # stale / dangling / wrong-target symlink
  ln -s "$SELF_DIR" "$LINK"
  echo "relay-xyz: installed → $LINK -> $SELF_DIR"
fi

# --- verify the chain the skill actually depends on ---
if [ -x "$SELF_DIR/find-harness.sh" ]; then
  H="$("$SELF_DIR/find-harness.sh" --root 2>/dev/null || true)"
  if [ -n "$H" ]; then
    echo "relay-xyz: harness resolves → $H"
  else
    echo "relay-xyz: WARNING — find-harness.sh could not resolve the harness root." >&2
    echo "  Set XYZ_HARNESS=/path/to/your/xyz-3-agents-swarm clone." >&2
  fi
fi
