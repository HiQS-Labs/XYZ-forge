#!/usr/bin/env bash
# health-lib.sh — shared STATUS/VERDICT → health (green|orange|red) mapping.
#
# Factored out of extract-relay-telemetry.sh (GH-24) so the on-demand batch extractor AND the live
# per-session XYZ.json completion hook (GH-75) derive relay health from the SAME logic instead of
# forking it. This file is meant to be sourced, not executed:
#
#   . "$(dirname "$0")/health-lib.sh"
#   health="$(xyz_health_from_status "$status" "$log_content" "$verdict")"
#
# xyz_health_from_status <status> <log_content> <verdict>
#   status       relay thread STATUS: header value ("" if none)
#   log_content  1 if the ## Log section has any non-blank content, else 0
#   verdict      last VERDICT: in the log ("" if none)
# Echoes exactly one of: green | orange | red
#
# Mapping (unchanged from GH-24):
#   green  — STATUS Approved or Closed
#   orange — STATUS Escalated | Changes requested; or In Progress/empty WITH a verdict
#   red    — In Progress/empty with no log content or no verdict; or VERDICT: FAIL under non-terminal
#            STATUS.

xyz_health_from_status() {
  local status="${1:-}" log_content="${2:-0}" verdict="${3:-}" health
  case "$status" in
    Approved|Closed)
      health="green"
      ;;
    Escalated|"Changes requested")
      health="orange"
      ;;
    "In Progress"|"")
      if [[ "$log_content" -eq 0 || -z "$verdict" ]]; then
        health="red"
      else
        health="orange"
      fi
      ;;
    *)
      health="orange"
      ;;
  esac
  # VERDICT: FAIL under a non-terminal STATUS overrides to red
  if [[ "$health" != "green" && "$verdict" == "FAIL" ]]; then
    health="red"
  fi
  printf '%s\n' "$health"
}
