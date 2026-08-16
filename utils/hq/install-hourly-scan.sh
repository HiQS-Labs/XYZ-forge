#!/usr/bin/env bash
# utils/hq/install-hourly-scan.sh — install/uninstall the hourly HQ marathon-scan launchd agent.
#
# Substitutes this checkout's absolute path, $HOME, and the scan's output destination into
# com.xyz-3-agents-swarm.hq-marathon-scan.plist.template, copies the result into
# ~/Library/LaunchAgents/, and loads it — so utils/hq/hourly-global-scan.sh runs once an hour,
# writing ONE fixed-name report (always overwritten in place, never date-stamped). Idempotent:
# re-running updates the installed plist to match wherever this checkout currently lives.
#
# The output destination defaults to an in-repo path (portable, no machine-specific hardcoding);
# --out PATH points it somewhere else instead (e.g. an operator's own Obsidian vault dashboard).
# Either way the path lives only in the generated, gitignored plist — never in checked-in source.
#
# Usage:
#   utils/hq/install-hourly-scan.sh install [--out PATH]   install/refresh + load the agent (default)
#   utils/hq/install-hourly-scan.sh uninstall               unload + remove the launchd agent
#   utils/hq/install-hourly-scan.sh status                  show whether the agent is loaded

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
LABEL="com.xyz-3-agents-swarm.hq-marathon-scan"
TEMPLATE="$HERE/$LABEL.plist.template"
DEST="$HOME/Library/LaunchAgents/$LABEL.plist"
DEFAULT_OUT="$ROOT/PROJECT/2-WORKING/GLOBAL-HQ-MARATHON.md"

cmd_install() {
  local out="$DEFAULT_OUT"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --out) out="${2:?--out requires a PATH argument}"; shift 2 ;;
      *) printf 'install-hourly-scan: unknown install argument: %s\n' "$1" >&2; exit 2 ;;
    esac
  done
  [[ -f "$TEMPLATE" ]] || { printf 'install-hourly-scan: template not found: %s\n' "$TEMPLATE" >&2; exit 1; }
  mkdir -p "$HOME/Library/LaunchAgents"
  sed -e "s#__REPO_ROOT__#$ROOT#g" -e "s#__HOME__#$HOME#g" -e "s#__GLOBAL_SCAN_OUT__#$out#g" \
    "$TEMPLATE" >"$DEST"
  launchctl unload "$DEST" >/dev/null 2>&1 || true
  launchctl load "$DEST"
  printf 'install-hourly-scan: installed + loaded %s\n' "$DEST"
  printf 'install-hourly-scan: runs hourly (RunAtLoad=true, so it also fires once now); writes %s\n' "$out"
  printf 'install-hourly-scan: log: %s/Library/Logs/hq-marathon-scan.log\n' "$HOME"
}

cmd_uninstall() {
  launchctl unload "$DEST" >/dev/null 2>&1 || true
  rm -f "$DEST"
  printf 'install-hourly-scan: unloaded + removed %s\n' "$DEST"
}

cmd_status() {
  if launchctl list "$LABEL" >/dev/null 2>&1; then
    printf 'install-hourly-scan: %s is loaded\n' "$LABEL"
    launchctl list "$LABEL"
  else
    printf 'install-hourly-scan: %s is NOT loaded\n' "$LABEL"
  fi
}

case "${1:-install}" in
  install)   shift || true; cmd_install "$@" ;;
  uninstall) cmd_uninstall ;;
  status)    cmd_status ;;
  *) printf 'usage: %s [install [--out PATH]|uninstall|status]\n' "$0" >&2; exit 2 ;;
esac
