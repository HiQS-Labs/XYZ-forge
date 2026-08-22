#!/usr/bin/env bash
#
# install.sh — make review-xyz discoverable to Claude Code, Codex, and Gemini / Antigravity from THIS clone.
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
SKILL_NAME="review-xyz"

install_one() {
  _label="$1"
  _dest="$2"
  _link="$_dest/$SKILL_NAME"

  if [ -e "$_dest" ] && [ ! -d "$_dest" ]; then
    echo "$SKILL_NAME: $_dest exists and is not a directory — skipping $_label." >&2
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
    _backup="${_link}.bak-$(date +%Y%m%d%H%M%S)"
    echo "$SKILL_NAME: $_link exists as a real directory/file — backing up to $_backup before linking."
    mv "$_link" "$_backup"
  fi

  ln -s "$SELF_DIR" "$_link"
  echo "$SKILL_NAME: installed for $_label → $_link -> $SELF_DIR"
}

rc=0
install_one "Claude Code" "${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}" || rc=1
install_one "Codex" "${CODEX_SKILLS_DIR:-$HOME/.codex/skills}" || rc=1
install_one "Gemini (Config)" "${GEMINI_CONFIG_SKILLS_DIR:-$HOME/.gemini/config/skills}" || rc=1
install_one "Gemini (Antigravity)" "${ANTIGRAVITY_SKILLS_DIR:-$HOME/.gemini/antigravity/skills}" || rc=1
install_one "Gemini (Antigravity CLI)" "${ANTIGRAVITY_CLI_SKILLS_DIR:-$HOME/.gemini/antigravity-cli/skills}" || rc=1
exit "$rc"
