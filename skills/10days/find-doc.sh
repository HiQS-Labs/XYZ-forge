#!/usr/bin/env bash
#
# find-doc.sh — deterministic capture-doc lookup for one GH issue number.
#
# Answers, with zero LLM judgment: does GH-<N> already have an in-repo capture doc,
# which PROJECT/** bucket is it in, and does it carry a machine-readable preflight
# contract? A hit in 3-COMPLETED is a strong "already done" signal the skill's
# subagent fan-out should weigh; a doc with no contract is a NEEDS-CONTRACT case.
#
#   bash skills/10days/find-doc.sh ISSUE_NUMBER
#
# Prints one JSON object to stdout. Exit 0 always (a miss is a valid, not an error,
# result) unless the argument itself is malformed (exit 2). Requires jq (already a
# repo dependency — see gh --jq usage throughout utils/) so the JSON output is
# correctly escaped rather than hand-rolled.
set -uo pipefail
# strict-mode: -e exempt — analysis tool; find/grep misses are expected, handled explicitly.

N="${1:-}"
if [[ ! "$N" =~ ^[0-9]+$ ]]; then
  echo "usage: find-doc.sh ISSUE_NUMBER" >&2
  exit 2
fi
command -v jq >/dev/null 2>&1 || { echo "find-doc.sh: jq not found on PATH" >&2; exit 2; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# NOTE: plain `grep`/`ls` are fine here — this runs as a script subprocess, not a Claude
# Code Bash-tool call, so the RTK hook that rewrites interactive `grep` invocations never
# sees it (see the repo's "RTK grep false-negative" gotcha, which is Bash-tool-specific).

DOC=""
BUCKET=""
for d in 1-INBOX 2-WORKING 3-COMPLETED 4-MISC; do
  # `find -type f` (not `ls`) so a same-named directory can never be mistaken for a doc.
  match="$(find "$ROOT/PROJECT/$d" -maxdepth 1 -type f -name "GH-$N-*.md" 2>/dev/null | head -1)"
  if [[ -n "$match" ]]; then
    DOC="$match"
    BUCKET="$d"
    break
  fi
done

if [[ -z "$DOC" ]]; then
  jq -nc --argjson issue "$N" '{issue: $issue, doc: null, bucket: null, has_contract: false}'
  exit 0
fi

HAS_CONTRACT="false"
if grep -qiE '^##.*preflight contract' "$DOC" && grep -q '```json' "$DOC"; then
  HAS_CONTRACT="true"
fi

REL_DOC="${DOC#"$ROOT"/}"
jq -nc --argjson issue "$N" --arg doc "$REL_DOC" --arg bucket "$BUCKET" --argjson has_contract "$HAS_CONTRACT" \
  '{issue: $issue, doc: $doc, bucket: $bucket, has_contract: $has_contract}'
