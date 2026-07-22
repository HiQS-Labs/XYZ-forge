#!/usr/bin/env bash
set -euo pipefail

# Install this skill by symlinking its directory into ~/.claude/skills/<skill-name>.

_src="${BASH_SOURCE[0]}"
while [ -h "$_src" ]; do
  _dir="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"
  _src="$(readlink "$_src")"
  case "$_src" in
    /*) ;;
    *) _src="$_dir/$_src" ;;
  esac
done
SELF_DIR="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"

SKILL_NAME="release"
DEST_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
LINK="$DEST_DIR/$SKILL_NAME"

if [ -e "$DEST_DIR" ] && [ ! -d "$DEST_DIR" ]; then
  echo "$SKILL_NAME: $DEST_DIR exists and is not a directory — not installing." >&2
  exit 1
fi

mkdir -p "$DEST_DIR"

if [ -L "$LINK" ]; then
  if [ -e "$LINK" ] && [ "$(cd -P "$LINK" >/dev/null 2>&1 && pwd)" = "$SELF_DIR" ]; then
    echo "$SKILL_NAME: already installed → $LINK -> $SELF_DIR"
    exit 0
  fi
  rm -f "$LINK"
elif [ -e "$LINK" ]; then
  echo "$SKILL_NAME: $LINK exists as a real file or directory — not overwriting." >&2
  echo "  Move it aside and re-run, or set CLAUDE_SKILLS_DIR." >&2
  exit 1
fi

ln -s "$SELF_DIR" "$LINK"
echo "$SKILL_NAME: installed → $LINK -> $SELF_DIR"
