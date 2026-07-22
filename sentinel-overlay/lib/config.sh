#!/usr/bin/env bash
# config.sh — the ACTIVATION GATE for the Sentinel Tier-2 overlay.
#
# Inert by default: with no runtime.env (or SENTINEL_ENABLE != 1) the whole overlay is a clean no-op —
# no network, no LLM, no GitHub. This file is the ONE place activation is decided. Source it and call
# sentinel_active / sentinel_require_active before ANY egress. Never bypass it.
set -u

_SENTINEL_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SENTINEL_OVERLAY_ROOT="$(cd "$_SENTINEL_LIB/.." && pwd)"
# The runtime config is gitignored (sentinel-overlay/config/runtime.env). Absent = inert.
SENTINEL_CONFIG="${SENTINEL_CONFIG:-$SENTINEL_OVERLAY_ROOT/config/runtime.env}"

# sentinel_load_config — load the gitignored runtime.env if present. Returns 1 if absent (=> inert).
sentinel_load_config() {
  [ -f "$SENTINEL_CONFIG" ] || return 1
  # shellcheck disable=SC1090
  set -a; . "$SENTINEL_CONFIG"; set +a
  return 0
}

# sentinel_active — TRUE only when the runtime config exists AND explicitly enables egress.
# This is the call-home switch: default (no file / not enabled) is OFF.
sentinel_active() {
  sentinel_load_config || return 1
  [ "${SENTINEL_ENABLE:-0}" = "1" ] || return 1
  return 0
}

# sentinel_require_active <what> — gate for egress functions. When inert, prints one line to stderr
# and returns 1 so the caller no-ops. When active, returns 0.
sentinel_require_active() {
  if ! sentinel_active; then
    printf 'sentinel: inert (no runtime.env or SENTINEL_ENABLE!=1) — %s skipped (call-home off)\n' "${1:-egress}" >&2
    return 1
  fi
  return 0
}
