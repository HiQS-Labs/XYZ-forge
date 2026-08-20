#!/usr/bin/env bash
#
# install.sh — make relay-xyz discoverable to Claude Code, Codex, and Gemini / Antigravity from THIS clone.
#
# THE problem this fixes: the repo keeps its skills in top-level skills/, a directory
# agent runtimes do NOT scan by default. A session only finds relay-xyz if it is symlinked
# into the environment skills dir (~/.claude/skills/, ~/.codex/skills/, ~/.gemini/config/skills/,
# ~/.gemini/antigravity/skills/, etc.). A fresh clone / other machine has no such symlink,
# so the skill is invisible in EVERY session there. This script creates those symlinks —
# idempotently, self-locating, with no hardcoded machine path — so any clone can make itself
# discoverable in one command.
#
#   bash skills/relay-xyz/install.sh          # install / repair symlinks
#
# Each destination has its own override: CLAUDE_SKILLS_DIR, CODEX_SKILLS_DIR,
# GEMINI_CONFIG_SKILLS_DIR, ANTIGRAVITY_SKILLS_DIR, ANTIGRAVITY_CLI_SKILLS_DIR.
#
# Safe to re-run. Replaces stale/dangling symlinks and backs up existing real directories before linking.
set -u

# --- resolve this script's real directory (symlink-safe; bash 3.2 / macOS) ---
_src="${BASH_SOURCE[0]}"
while [ -h "$_src" ]; do
  _dir="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"
  _src="$(readlink "$_src")"
  case "$_src" in /*) ;; *) _src="$_dir/$_src" ;; esac
done
SELF_DIR="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"   # …/skills/relay-xyz
SKILL_NAME="relay-xyz"

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

install_one "Claude Code" "${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
install_one "Codex" "${CODEX_SKILLS_DIR:-$HOME/.codex/skills}"
install_one "Gemini (Config)" "${GEMINI_CONFIG_SKILLS_DIR:-$HOME/.gemini/config/skills}"
install_one "Gemini (Antigravity)" "${ANTIGRAVITY_SKILLS_DIR:-$HOME/.gemini/antigravity/skills}"
install_one "Gemini (Antigravity CLI)" "${ANTIGRAVITY_CLI_SKILLS_DIR:-$HOME/.gemini/antigravity-cli/skills}"

# --- verify the chain the skill actually depends on ---
if [ -x "$SELF_DIR/find-harness.sh" ]; then
  H="$("$SELF_DIR/find-harness.sh" --root 2>/dev/null || true)"
  if [ -n "$H" ]; then
    echo "relay-xyz: harness resolves → $H"
  else
    echo "relay-xyz: WARNING — find-harness.sh could not resolve the harness root." >&2
    echo "  Set XYZ_HARNESS=/path/to/your/xyz-3-agents-swarm clone." >&2
  fi
fi
