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

SKILL_NAME="standup"
DEST_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
LINK="$DEST_DIR/$SKILL_NAME"

CHECK_MODE=0
if [ "${1:-}" = "--check" ]; then
  CHECK_MODE=1
fi

if [ -e "$DEST_DIR" ] && [ ! -d "$DEST_DIR" ]; then
  if [ "$CHECK_MODE" -eq 1 ]; then exit 1; fi
  echo "$SKILL_NAME: $DEST_DIR exists and is not a directory — not installing." >&2
  exit 1
fi

if [ "$CHECK_MODE" -eq 0 ]; then
  mkdir -p "$DEST_DIR"
fi

if [ -L "$LINK" ]; then
  if [ -e "$LINK" ] && [ "$(cd -P "$LINK" >/dev/null 2>&1 && pwd)" = "$SELF_DIR" ]; then
    if [ "$CHECK_MODE" -eq 1 ]; then exit 0; fi
    echo "$SKILL_NAME: already installed → $LINK -> $SELF_DIR"
    exit 0
  fi
  if [ "$CHECK_MODE" -eq 1 ]; then exit 1; fi
  rm -f "$LINK"
elif [ -e "$LINK" ]; then
  if [ "$CHECK_MODE" -eq 1 ]; then exit 1; fi
  echo "$SKILL_NAME: $LINK exists as a real file or directory — not overwriting." >&2
  echo "  Move it aside and re-run, or set CLAUDE_SKILLS_DIR." >&2
  exit 1
fi

if [ "$CHECK_MODE" -eq 1 ]; then
  # Not installed properly
  exit 1
fi

ln -s "$SELF_DIR" "$LINK"
echo "$SKILL_NAME: installed → $LINK -> $SELF_DIR"
