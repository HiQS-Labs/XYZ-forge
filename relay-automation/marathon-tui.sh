#!/usr/bin/env bash
# marathon-tui.sh — interactive cross-repo marathon monitor (fzf TUI).
#
# Pipes marathon-ls.sh into fzf with a ~2s auto-refresh and a preview pane
# powered by marathon-detail.sh. Field 1 of each row is the repo path.
#
# Requires: fzf (brew install fzf)
# Writes NO state anywhere.
set -euo pipefail

# Resolve sibling script paths relative to this script's directory.
_src="${BASH_SOURCE[0]}"
while [ -h "$_src" ]; do
  _dir="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"
  _src="$(readlink "$_src")"
  case "$_src" in /*) ;; *) _src="$_dir/$_src" ;; esac
done
SELF_DIR="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"

LS_SCRIPT="$SELF_DIR/marathon-ls.sh"
DETAIL_SCRIPT="$SELF_DIR/marathon-detail.sh"

# Guard: fzf must be installed.
if ! command -v fzf >/dev/null 2>&1; then
  printf 'marathon-tui.sh: fzf is not installed.\n' >&2
  printf 'Install it with:  brew install fzf\n' >&2
  exit 1
fi

[ -f "$LS_SCRIPT" ]     || { printf 'marathon-tui.sh: missing %s\n' "$LS_SCRIPT" >&2; exit 1; }
[ -f "$DETAIL_SCRIPT" ] || { printf 'marathon-tui.sh: missing %s\n' "$DETAIL_SCRIPT" >&2; exit 1; }

# Run fzf:
#   --header-lines=1          treat the TSV header row as a sticky header
#   --delimiter='\t'          split on tabs so {1} is the REPO column
#   --reload-sync / load      auto-reload every ~2 s (fzf 0.35+ bind syntax)
#   --preview                 marathon-detail.sh on the selected repo (field 1)
bash "$LS_SCRIPT" | fzf \
  --header-lines=1 \
  --delimiter=$'\t' \
  --with-nth='1,2,3,4,5' \
  --bind "load:reload-sync(sleep 2; bash '$LS_SCRIPT')" \
  --bind "change:reload-sync(bash '$LS_SCRIPT')" \
  --preview "bash '$DETAIL_SCRIPT' {1}" \
  --preview-window='right:50%:wrap' \
  --prompt='marathon> ' \
  --info=inline \
  --ansi
