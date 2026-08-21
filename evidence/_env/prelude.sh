#!/usr/bin/env bash
# XYZ-forge linux-bringup — environment prelude.
#
# Source this at the top of every bring-up command:
#     . evidence/_env/prelude.sh
#
# WHY THIS EXISTS
# ---------------
# `nvm install` appends its loader to the BOTTOM of ~/.bashrc (~line 119).
# Ubuntu's stock ~/.bashrc returns early when the shell is not interactive:
#
#     case $- in
#         *i*) ;;
#           *) return;;
#     esac                      # <- ~line 8
#
# So under `bash -lc '...'` (login BUT non-interactive) the nvm block never
# runs. Symptom: `command -v node` is empty, while `command -v npm` succeeds and
# points at "/mnt/c/Program Files/nodejs/npm" — the WINDOWS npm, leaking into
# the WSL PATH through Windows interop. That combination is actively dangerous:
# a Windows npm resolving platform-gated deps against a Linux filesystem
# produces a node_modules tree that fails later in ways that look like repo bugs.
#
# This prelude puts the LINUX node first on PATH, explicitly, with no dependence
# on dotfile load order.

# Resolve the nvm node bindir without relying on nvm.sh being loadable.
_xyz_node_bin=""
if [ -d "$HOME/.nvm/versions/node" ]; then
  # Highest installed version wins; -V sorts v10 after v9 correctly.
  _xyz_node_bin="$(ls -1 "$HOME/.nvm/versions/node" 2>/dev/null | sort -V | tail -1)"
  if [ -n "$_xyz_node_bin" ]; then
    _xyz_node_bin="$HOME/.nvm/versions/node/$_xyz_node_bin/bin"
  fi
fi

if [ -n "$_xyz_node_bin" ] && [ -x "$_xyz_node_bin/node" ]; then
  PATH="$_xyz_node_bin:$PATH"
  export PATH
fi
unset _xyz_node_bin

# Strip Windows interop paths so a stray .exe can never shadow a Linux tool
# during a run. Keep this OFF by default; enable with XYZ_STRIP_WINPATH=1.
if [ "${XYZ_STRIP_WINPATH:-0}" = "1" ]; then
  PATH="$(printf '%s' "$PATH" | tr ':' '\n' | grep -v '^/mnt/c/' | paste -sd: -)"
  export PATH
fi

# Assert we got a Linux node, not a Windows one.
xyz_assert_linux_node() {
  local n
  n="$(command -v node 2>/dev/null)" || true
  if [ -z "$n" ]; then
    echo "PRELUDE FAIL: no node on PATH" >&2
    return 1
  fi
  case "$n" in
    /mnt/c/*) echo "PRELUDE FAIL: node is the WINDOWS binary: $n" >&2; return 1 ;;
  esac
  local m
  m="$(command -v npm 2>/dev/null)" || true
  case "$m" in
    /mnt/c/*) echo "PRELUDE FAIL: npm is the WINDOWS binary: $m" >&2; return 1 ;;
    "")       echo "PRELUDE FAIL: no npm on PATH" >&2; return 1 ;;
  esac
  echo "PRELUDE OK: node=$n ($(node --version))  npm=$m ($(npm --version))"
  return 0
}
