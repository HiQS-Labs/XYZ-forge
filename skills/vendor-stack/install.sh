#!/usr/bin/env bash
#
# install.sh — make vendor-stack discoverable to Claude Code from THIS clone.
#
# The repo keeps its skills in top-level skills/, which Claude Code does NOT scan.
# A session only finds vendor-stack if it is symlinked into the user skills dir
# (~/.claude/skills/). This script creates that symlink — idempotently,
# self-locating, with no hardcoded machine path. Same pattern as relay-xyz/install.sh.
#
#   bash skills/vendor-stack/install.sh          # install / repair the symlink
#   CLAUDE_SKILLS_DIR=/path bash …/install.sh    # override the user skills dir
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
SELF_DIR="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"   # …/skills/vendor-stack

DEST_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
LINK="$DEST_DIR/vendor-stack"

mkdir -p "$DEST_DIR"

if [ -L "$LINK" ] && [ "$(readlink "$LINK")" = "$SELF_DIR" ]; then
  echo "vendor-stack: already installed → $LINK -> $SELF_DIR"
elif [ -e "$LINK" ] && [ ! -L "$LINK" ]; then
  echo "vendor-stack: $LINK exists as a real directory — not overwriting." >&2
  echo "  Move it aside and re-run, or set CLAUDE_SKILLS_DIR." >&2
  exit 1
else
  [ -L "$LINK" ] && rm -f "$LINK"   # stale / dangling / wrong-target symlink
  ln -s "$SELF_DIR" "$LINK"
  echo "vendor-stack: installed → $LINK -> $SELF_DIR"
fi

# --- verify the two source repos the skill drives ---
HARNESS="$(cd "$SELF_DIR/../.." >/dev/null 2>&1 && pwd)"
if [ -x "$HARNESS/relay-automation/xyz-vendor.sh" ]; then
  echo "vendor-stack: XYZ harness resolves → $HARNESS"
else
  echo "vendor-stack: WARNING — xyz-vendor.sh not found under $HARNESS" >&2
fi

if [ -x "$SELF_DIR/find-pdda.sh" ]; then
  P="$("$SELF_DIR/find-pdda.sh" --root 2>/dev/null || true)"
  if [ -n "$P" ]; then
    echo "vendor-stack: PDDA repo resolves → $P"
  else
    echo "vendor-stack: note — PDDA repo not resolved (XYZ-only until set)." >&2
    echo "  Set PDDA_REPO=/path/to/your/pdda clone to enable the PDDA step." >&2
  fi
fi
