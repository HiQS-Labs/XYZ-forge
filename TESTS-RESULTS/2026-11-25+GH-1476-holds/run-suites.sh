#!/usr/bin/env bash
# GH-1476 (holds only): run the EXISTING suites that cover the touched files, on committed state,
# in one disposable full clone. usage: bash run-suites.sh <label> <disposable-clone-root>
# Logs and exit codes land in ./suites-<label>/. No suite is added.
set -u
label="${1:?label}"; clone="${2:?clone root}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
out="$here/suites-$label"; mkdir -p "$out"
cd "$clone" || exit 2
unset XYZ_HARNESS TICK_REPO_ROOT
for s in jog-queue.sh gh280-jog-marathon-adapter.sh gh291-contract-goldens.sh gh505-relay-attest.sh gh202-wave-reconcile-issue-state.sh gh454-reconciler-defects.sh gh232-wave-reconcile-multiphase.sh gh168-wave-reconcile-scope.sh; do
  start="$(date -u +%FT%TZ)"
  bash "test/$s" > "$out/$s.log" 2>&1 < /dev/null; rc=$?
  [ -s "$out/$s.log" ] || { echo "EMPTY LOG $s" >&2; rc=99; }
  printf '%s rc=%s head=%s started=%s\n' "$s" "$rc" "$(git rev-parse --short HEAD)" "$start" | tee -a "$out/summary.txt"
done
