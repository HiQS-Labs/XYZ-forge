#!/usr/bin/env bash
# XYZ-forge linux-bringup — logged command runner.
#
#   evidence/_env/run.sh <logfile> <command...>
#
# Runs <command...> with the bring-up prelude sourced, streams combined
# stdout+stderr to both the terminal and <logfile>, and appends a machine-
# readable trailer carrying the REAL exit code of the command (not tee's).
#
# Nothing in this bring-up is allowed to count as evidence unless it went
# through here, per the brief: "If it is not in a log with an exit code, it did
# not happen."
set -u

if [ "$#" -lt 2 ]; then
  echo "usage: run.sh <logfile> <command...>" >&2
  exit 64
fi

LOG="$1"; shift
mkdir -p "$(dirname "$LOG")"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck disable=SC1091
. "$REPO_ROOT/evidence/_env/prelude.sh"

START_EPOCH="$(date +%s)"
START_ISO="$(date -Is)"

{
  echo "=== XYZ-FORGE BRINGUP RUN ==="
  echo "cmd      : $*"
  echo "cwd      : $(pwd)"
  echo "start    : $START_ISO"
  echo "node     : $(command -v node 2>/dev/null || echo NONE) $(node --version 2>/dev/null || true)"
  echo "npm      : $(command -v npm 2>/dev/null || echo NONE) $(npm --version 2>/dev/null || true)"
  echo "=== BEGIN OUTPUT ==="
} | tee "$LOG"

# PIPESTATUS captures the command's status, not tee's.
set +e
"$@" 2>&1 | tee -a "$LOG"
RC="${PIPESTATUS[0]}"
set -e

END_EPOCH="$(date +%s)"
{
  echo "=== END OUTPUT ==="
  echo "end      : $(date -Is)"
  echo "duration : $((END_EPOCH - START_EPOCH))s"
  echo "EXIT_CODE: $RC"
} | tee -a "$LOG"

exit "$RC"
