#!/usr/bin/env bash
#
# find-doc.sh — deterministic capture-doc lookup for one GH issue number.
#
# Answers, with zero LLM judgment: does GH-<N> already have an in-repo capture doc,
# which PROJECT/** bucket is it in, and does it carry a machine-readable preflight
# contract? A hit in 3-COMPLETED is a strong "already done" signal the skill's
# subagent fan-out should weigh; a doc with no contract is a NEEDS-CONTRACT case.
#
#   bash skills/3-weekly/10days/find-doc.sh ISSUE_NUMBER
#
# Prints one JSON object to stdout. Exit 0 always (a miss is a valid, not an error,
# result) unless the argument itself is malformed (exit 2). Requires jq (already a
# repo dependency — see gh --jq usage throughout utils/) so the JSON output is
# correctly escaped rather than hand-rolled.
set -uo pipefail
# strict-mode: -e exempt — adapter propagates the Python/gh exit status.
command -v python3 >/dev/null 2>&1 || { echo "10days: python3 not found on PATH" >&2; exit 2; }
SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit 2
exec python3 "$SCRIPT_DIR/intake_adapter.py" find "$@"
