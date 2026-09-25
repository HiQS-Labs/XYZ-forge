#!/usr/bin/env bash
# Install this repo-owned skill into Claude's user skill directory by symlink.
set -eu

_src="${BASH_SOURCE[0]}"
while [ -h "$_src" ]; do
  _dir="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"
  _src="$(readlink "$_src")"
  case "$_src" in /*) ;; *) _src="$_dir/$_src" ;; esac
done
SELF_DIR="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"

SKILL_NAME="start-marathon"
DEST_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
LINK="$DEST_DIR/$SKILL_NAME"

mkdir -p "$DEST_DIR"

if [ -L "$LINK" ] && [ "$(readlink "$LINK")" = "$SELF_DIR" ]; then
  echo "$SKILL_NAME: already installed -> $LINK -> $SELF_DIR"
elif [ -e "$LINK" ] && [ ! -L "$LINK" ]; then
  echo "$SKILL_NAME: $LINK exists as a real directory; refusing to overwrite it." >&2
  echo "Move it aside after preserving any unique files, then re-run this installer." >&2
  exit 1
else
  if [ -L "$LINK" ] && [ -e "$LINK" ]; then
    # GH-678: a live link that is not ours belongs to another installer or to a managed
    # Skills Army collection. Only a dangling link is stale enough to replace.
    echo "$SKILL_NAME: $LINK already points at $(readlink "$LINK") — not replacing a live link." >&2
    echo "  Remove it yourself if that is intended." >&2
    exit 1
  fi
  [ ! -L "$LINK" ] || rm -f "$LINK"
  ln -s "$SELF_DIR" "$LINK"
  echo "$SKILL_NAME: installed -> $LINK -> $SELF_DIR"
fi

[ -f "$LINK/SKILL.md" ] || {
  echo "$SKILL_NAME: installed link does not expose SKILL.md" >&2
  exit 1
}

# Preserve the established invocation without duplicating the skill source.
LEGACY_LINK="$DEST_DIR/marathon-triage"
if [ -L "$LEGACY_LINK" ] && [ "$(readlink "$LEGACY_LINK")" = "$SELF_DIR" ]; then
  : # Already points to this skill.
elif [ -L "$LEGACY_LINK" ] && [ ! -e "$LEGACY_LINK" ]; then
  rm -f "$LEGACY_LINK"
  ln -s "$SELF_DIR" "$LEGACY_LINK"
elif [ ! -e "$LEGACY_LINK" ]; then
  ln -s "$SELF_DIR" "$LEGACY_LINK"
else
  echo "marathon-triage: existing installation preserved at $LEGACY_LINK" >&2
fi
