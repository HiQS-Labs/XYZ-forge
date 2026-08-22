#!/usr/bin/env bash
# test/gh130-agy-auth-whoami.sh — #130/#135: agy auth preflight three-state verdict (usage errors
# unverifiable, credentials fatal) across agy-turn.py AND consult.py.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec bash "$HERE/test/synthetic/gh130-agy-auth-whoami.sh"
