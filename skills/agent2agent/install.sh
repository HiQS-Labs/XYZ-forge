#!/usr/bin/env bash
# Install this repo-backed skill for Claude Code and Codex without copying it.
set -euo pipefail

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
SKILL_NAME="agent2agent"

install_one() {
  _label="$1"
  _dest="$2"
  _link="$_dest/$SKILL_NAME"

  if [ -e "$_dest" ] && [ ! -d "$_dest" ]; then
    echo "$SKILL_NAME: $_dest exists and is not a directory — not installing for $_label." >&2
    return 1
  fi
  mkdir -p "$_dest"

  if [ -L "$_link" ]; then
    if [ -e "$_link" ] && [ "$(cd -P "$_link" >/dev/null 2>&1 && pwd)" = "$SELF_DIR" ]; then
      echo "$SKILL_NAME: already installed for $_label → $_link -> $SELF_DIR"
      return 0
    fi
    rm -f "$_link"
  elif [ -e "$_link" ]; then
    echo "$SKILL_NAME: $_link exists as a real file or directory — not overwriting." >&2
    return 1
  fi

  ln -s "$SELF_DIR" "$_link"
  echo "$SKILL_NAME: installed for $_label → $_link -> $SELF_DIR"
}

install_one "Claude Code" "${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
install_one "Codex" "${CODEX_SKILLS_DIR:-$HOME/.codex/skills}"
