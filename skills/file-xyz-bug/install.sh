#!/usr/bin/env bash
#
# install.sh — make file-xyz-bug discoverable to Claude Code from THIS clone.
#
# The repo keeps its skills in top-level skills/, a directory Claude Code does NOT scan.
# A session finds file-xyz-bug only if it is symlinked into the user skills dir
# (~/.claude/skills/). That matters more here than for most skills: the whole point of
# file-xyz-bug is to be invoked from OTHER repos, so a user-level install is not a
# convenience — it is the only install that works.
#
#   bash skills/file-xyz-bug/install.sh          # install / repair the symlink
#   CLAUDE_SKILLS_DIR=/path bash …/install.sh    # override the user skills dir
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
SELF_DIR="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"   # …/skills/file-xyz-bug

DEST_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
LINK="$DEST_DIR/file-xyz-bug"

mkdir -p "$DEST_DIR"

if [ -L "$LINK" ] && [ "$(readlink "$LINK")" = "$SELF_DIR" ]; then
  echo "file-xyz-bug: already installed → $LINK -> $SELF_DIR"
elif [ -e "$LINK" ] && [ ! -L "$LINK" ]; then
  echo "file-xyz-bug: $LINK exists as a real directory — not overwriting." >&2
  echo "  Move it aside and re-run, or set CLAUDE_SKILLS_DIR." >&2
  exit 1
else
  [ -L "$LINK" ] && rm -f "$LINK"   # stale / dangling / wrong-target symlink
  # Check the ln: it fails for reasons that are NOT the operator's fault (a sandboxed shell
  # denies writes under ~/.claude), and an unchecked `ln` reports success while leaving the
  # skill uninstalled — a lie that costs a whole session to notice.
  if ! ln -s "$SELF_DIR" "$LINK" 2>/dev/null; then
    echo "file-xyz-bug: FAILED to create $LINK" >&2
    echo "  If you are running inside a sandboxed shell, ~/.claude/skills is write-denied —" >&2
    echo "  re-run this installer with the sandbox disabled." >&2
    exit 1
  fi
  echo "file-xyz-bug: installed → $LINK -> $SELF_DIR"
fi

chmod +x "$SELF_DIR/find-xyz.sh" 2>/dev/null || true

# --- verify the chain the skill actually depends on ---
# Resolve THROUGH the installed symlink, not $SELF_DIR: that is the path a foreign session
# will use, and it is the leg that actually breaks (a stripped exec bit or a symlink into
# a moved clone both pass a $SELF_DIR check and fail the real one).
if [ -x "$LINK/find-xyz.sh" ]; then
  R="$("$LINK/find-xyz.sh" --root 2>/dev/null || true)"
  if [ -n "$R" ]; then
    echo "file-xyz-bug: intake repo resolves → $R"
  else
    echo "file-xyz-bug: WARNING — find-xyz.sh could not resolve the intake repo." >&2
    echo "  Set XYZ_REPO=/path/to/your/xyz-3-agents-swarm clone." >&2
  fi
else
  echo "file-xyz-bug: WARNING — $LINK/find-xyz.sh is missing or not executable." >&2
fi
