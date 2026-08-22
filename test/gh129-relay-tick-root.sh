#!/usr/bin/env bash
# test/gh129-relay-tick-root.sh — #129: relay-drive TICK_REPO_ROOT self-resolution, not-found
# diagnostic, escalate-exits-4 pins (#136 attempts-location pin rides in the same suite).
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec bash "$HERE/test/synthetic/gh129-relay-tick-root.sh"
