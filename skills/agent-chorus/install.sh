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
SKILL_NAME="agent-chorus"
LEGACY_SKILL_NAME="agent2agent"

# Phase 0 rename (#193): machines that installed the old skill hold a
# ~/.claude/skills/agent2agent symlink whose target directory no longer exists after
# this rename lands — a dangling link that silently drops the skill with no pointer
# to the new name. During the one-release deprecation window, repoint that legacy
# link at the renamed skill dir so `/agent2agent` still resolves; remove this block
# together with scripts/agent2agent.py.
migrate_legacy_link() {
  _label="$1"
  _dest="$2"
  _legacy="$_dest/$LEGACY_SKILL_NAME"
  [ -L "$_legacy" ] || return 0    # only ever touch a symlink, never a real dir/file
  _target="$(readlink "$_legacy")"
  case "$_target" in
    *"/skills/$LEGACY_SKILL_NAME"|*"/skills/$SKILL_NAME")
      ln -sfn "$SELF_DIR" "$_legacy"
      echo "$SKILL_NAME: repointed legacy $_legacy -> $SELF_DIR for $_label (deprecation window)"
      ;;
    *)
      if [ ! -e "$_legacy" ]; then
        rm -f "$_legacy"
        echo "$SKILL_NAME: removed dangling legacy link $_legacy for $_label"
      fi
      ;;
  esac
}

install_one() {
  _label="$1"
  _dest="$2"
  _link="$_dest/$SKILL_NAME"

  if [ -e "$_dest" ] && [ ! -d "$_dest" ]; then
    echo "$SKILL_NAME: $_dest exists and is not a directory — not installing for $_label." >&2
    return 1
  fi
  mkdir -p "$_dest"
  migrate_legacy_link "$_label" "$_dest"

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
