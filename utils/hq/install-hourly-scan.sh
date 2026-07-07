#!/usr/bin/env bash
# utils/hq/install-hourly-scan.sh — install/uninstall the hourly HQ marathon-scan launchd agent.
#
# Substitutes this checkout's absolute path (and $HOME) into com.xyz-3-agents-swarm.hq-marathon-scan.plist.template,
# copies the result into ~/Library/LaunchAgents/, and loads it — so utils/hq/hourly-global-scan.sh runs
# once an hour, writing PROJECT/2-WORKING/GLOBAL-HQ-MARATHON.md (always overwritten in place — one copy,
# never date-stamped). Idempotent: re-running updates the installed plist to match wherever this
# checkout currently lives.
#
# Usage:
#   utils/hq/install-hourly-scan.sh install     install/refresh + load the launchd agent (default)
#   utils/hq/install-hourly-scan.sh uninstall   unload + remove the launchd agent
#   utils/hq/install-hourly-scan.sh status      show whether the agent is loaded

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
LABEL="com.xyz-3-agents-swarm.hq-marathon-scan"
TEMPLATE="$HERE/$LABEL.plist.template"
DEST="$HOME/Library/LaunchAgents/$LABEL.plist"

cmd_install() {
  [[ -f "$TEMPLATE" ]] || { printf 'install-hourly-scan: template not found: %s\n' "$TEMPLATE" >&2; exit 1; }
  mkdir -p "$HOME/Library/LaunchAgents"
  sed -e "s#__REPO_ROOT__#$ROOT#g" -e "s#__HOME__#$HOME#g" "$TEMPLATE" >"$DEST"
  launchctl unload "$DEST" >/dev/null 2>&1 || true
  launchctl load "$DEST"
  printf 'install-hourly-scan: installed + loaded %s\n' "$DEST"
  printf 'install-hourly-scan: runs hourly (RunAtLoad=true, so it also fires once now); writes %s\n' \
    "$ROOT/PROJECT/2-WORKING/GLOBAL-HQ-MARATHON.md"
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
  install)   cmd_install ;;
  uninstall) cmd_uninstall ;;
  status)    cmd_status ;;
  *) printf 'usage: %s [install|uninstall|status]\n' "$0" >&2; exit 2 ;;
esac
