#!/usr/bin/env bash
#
# install.sh — make the /hq skill discoverable to Claude Code from THIS clone (GH-128, Phase 4).
#
# THE problem this fixes: the repo keeps its skills in top-level skills/, a directory Claude Code
# does NOT scan. A session only finds /hq if it is symlinked into the user skills dir
# (~/.claude/skills/). A fresh clone / other machine has no such symlink, so /hq is invisible in
# every session there. This script creates that symlink — idempotently, self-locating, no hardcoded
# machine path — so any clone can make /hq available in one command. Combined with find-hq.sh (which
# resolves hq.sh from any CWD), this is what lets /hq run "user-level": from a session in any repo.
#
#   bash skills/hq/install.sh                 # install / repair the symlink
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
SELF_DIR="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"   # …/skills/hq

DEST_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
LINK="$DEST_DIR/hq"

mkdir -p "$DEST_DIR"

if [ -L "$LINK" ] && [ "$(readlink "$LINK")" = "$SELF_DIR" ]; then
  echo "hq: already installed → $LINK -> $SELF_DIR"
elif [ -e "$LINK" ] && [ ! -L "$LINK" ]; then
  echo "hq: $LINK exists as a real directory — not overwriting." >&2
  echo "  Move it aside and re-run, or set CLAUDE_SKILLS_DIR." >&2
  exit 1
else
  [ -L "$LINK" ] && rm -f "$LINK"   # stale / dangling / wrong-target symlink
  ln -s "$SELF_DIR" "$LINK"
  echo "hq: installed → $LINK -> $SELF_DIR"
fi

# --- verify the chain the skill actually depends on ---
if [ -x "$SELF_DIR/find-hq.sh" ]; then
  H="$("$SELF_DIR/find-hq.sh" --sh 2>/dev/null || true)"
  if [ -n "$H" ]; then
    echo "hq: dispatcher resolves → $H"
  else
    echo "hq: WARNING — find-hq.sh could not resolve utils/hq/hq.sh." >&2
    echo "  Set XYZ_HARNESS=/path/to/your/xyz-3-agents-swarm clone." >&2
  fi
fi
