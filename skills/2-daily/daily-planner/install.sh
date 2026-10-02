#!/usr/bin/env bash
set -euo pipefail

# Install daily-planner skill by symlinking into ~/.claude/skills/<skill-name>.

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

SKILL_NAME="daily-planner"
DEST_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
LINK="$DEST_DIR/$SKILL_NAME"

if [ -e "$DEST_DIR" ] && [ ! -d "$DEST_DIR" ]; then
  echo "$SKILL_NAME: $DEST_DIR exists and is not a directory — not installing." >&2
  exit 1
fi

mkdir -p "$DEST_DIR"

# Ensure weekly-planner dependency is installed
WEEKLY_INSTALLER="$SELF_DIR/../../3-weekly/weekly-planner/install.sh"
if [ -f "$WEEKLY_INSTALLER" ]; then
  echo "$SKILL_NAME: ensuring required dependency weekly-planner is installed..."
  bash "$WEEKLY_INSTALLER"
elif [ ! -e "$DEST_DIR/weekly-planner" ]; then
  echo "$SKILL_NAME: ERROR - weekly-planner is a required dependency but was not found in $DEST_DIR/weekly-planner or adjacent directory." >&2
  echo "Please install weekly-planner first: bash skills/3-weekly/weekly-planner/install.sh" >&2
  exit 1
fi

if [ -L "$LINK" ]; then
  if [ -e "$LINK" ] && [ "$(cd -P "$LINK" >/dev/null 2>&1 && pwd)" = "$SELF_DIR" ]; then
    echo "$SKILL_NAME: already installed → $LINK -> $SELF_DIR"
    exit 0
  fi
  rm -f "$LINK"
elif [ -e "$LINK" ]; then
  echo "$SKILL_NAME: $LINK exists as a real file or directory — not overwriting." >&2
  exit 1
fi

ln -s "$SELF_DIR" "$LINK"
echo "$SKILL_NAME: installed → $LINK -> $SELF_DIR"
