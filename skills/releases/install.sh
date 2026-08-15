#!/usr/bin/env bash
set -euo pipefail

# Install the consolidated releases skill into Claude Code and retire legacy aliases.

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

SKILL_NAME="releases"
DEST_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
LINK="$DEST_DIR/$SKILL_NAME"
LEGACY_NAMES="release release-plan"

if [ -e "$DEST_DIR" ] && [ ! -d "$DEST_DIR" ]; then
  echo "$SKILL_NAME: $DEST_DIR exists and is not a directory — not installing." >&2
  exit 1
fi

mkdir -p "$DEST_DIR"

# Consolidation is deliberate: refuse before changing anything if a legacy name is a real file or
# directory. Symlinks are replaceable install pointers and are removed only after the new skill is
# installed and verified.
for legacy_name in $LEGACY_NAMES; do
  legacy_link="$DEST_DIR/$legacy_name"
  if [ -e "$legacy_link" ] && [ ! -L "$legacy_link" ]; then
    echo "$SKILL_NAME: legacy path $legacy_link is a real file or directory — not overwriting." >&2
    echo "  Preserve or move it yourself, then re-run this installer." >&2
    exit 1
  fi
done

installed=0
if [ -L "$LINK" ]; then
  if [ -e "$LINK" ] && [ "$(cd -P "$LINK" >/dev/null 2>&1 && pwd)" = "$SELF_DIR" ]; then
    echo "$SKILL_NAME: already installed → $LINK -> $SELF_DIR"
    installed=1
  else
    rm -f "$LINK"
  fi
elif [ -e "$LINK" ]; then
  echo "$SKILL_NAME: $LINK exists as a real file or directory — not overwriting." >&2
  echo "  Move it aside and re-run, or set CLAUDE_SKILLS_DIR." >&2
  exit 1
fi

if [ "$installed" -eq 0 ]; then
  ln -s "$SELF_DIR" "$LINK"
  echo "$SKILL_NAME: installed → $LINK -> $SELF_DIR"
fi

[ -f "$LINK/SKILL.md" ] || {
  echo "$SKILL_NAME: installed link does not expose SKILL.md" >&2
  exit 1
}

for legacy_name in $LEGACY_NAMES; do
  legacy_link="$DEST_DIR/$legacy_name"
  if [ -L "$legacy_link" ]; then
    rm -f "$legacy_link"
    echo "$SKILL_NAME: retired legacy Claude Code alias → $legacy_link"
  fi
done
