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

N=""
ROOT_ARG=""
ROOT_SRC=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    # GH-369: check for the value BEFORE shifting. `shift 2` with one argument left shifts
    # nothing and returns non-zero — and this script is deliberately `-e`-exempt, so that
    # failure was silent: $# never decreased, $1 stayed `--root`, and the loop spun forever.
    --root)
      [ "$#" -ge 2 ] || { echo "find-doc.sh: --root requires a directory argument" >&2; exit 2; }
      ROOT_ARG="$2"; ROOT_SRC="--root"; shift 2 ;;
    -h|--help) echo "usage: find-doc.sh [--root DIR] ISSUE_NUMBER" >&2; exit 0 ;;
    -*) echo "find-doc.sh: unknown option: $1" >&2; exit 2 ;;
    *) N="$1"; shift ;;
  esac
done
if [[ ! "$N" =~ ^[0-9]+$ ]]; then
  echo "usage: find-doc.sh [--root DIR] ISSUE_NUMBER" >&2
  exit 2
fi
command -v jq >/dev/null 2>&1 || { echo "find-doc.sh: jq not found on PATH" >&2; exit 2; }

# GH-344: resolve PROJECT/** from the repo being SWEPT, never from this script's own location.
#
# This used to be `dirname "$BASH_SOURCE"/../..`, i.e. the harness repo. The skill is installed
# from a harness clone, so every lookup answered from the harness's own PROJECT/ tree — and both
# repos number issues from 1, so a swept repo's issue number matched an unrelated harness document
# by coincidence. Measured on a real sweep of Hypercart-Dev-Tools/rebalance-OS: 24 of 49 issues got
# a bucket from the wrong repo, 20 of them "3-COMPLETED", which Step 2 of the skill treats as
# "strong already-done signal. Exclude immediately." Correct answer for that repo: zero.
#
# Precedence: --root > $TENDAYS_ROOT > current git toplevel > $PWD. The git toplevel is the right
# default because every other step of the skill is already cwd-bound (`gh` reads the repo from the
# cwd's remote), so this makes find-doc.sh agree with them instead of disagreeing silently.
#
# GH-369: track WHICH of those four supplied the value, so a bad path names its real source. The
# original message hardcoded `--root` and interpolated $ROOT_ARG, so a bad $TENDAYS_ROOT blamed a
# flag the caller never passed and printed an empty path.
ROOT="$ROOT_ARG"
[ -n "$ROOT" ] || { ROOT="${TENDAYS_ROOT:-}"; [ -n "$ROOT" ] && ROOT_SRC='$TENDAYS_ROOT'; }
[ -n "$ROOT" ] || { ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"; ROOT_SRC="git toplevel/\$PWD"; }
# Keep the pre-resolution value: the assignment below overwrites $ROOT with the (empty) result of
# the failed substitution before `||` runs, so reporting "$ROOT" here would print nothing.
ROOT_RAW="$ROOT"
ROOT="$(cd "$ROOT" >/dev/null 2>&1 && pwd)" || {
  echo "find-doc.sh: not a directory (from $ROOT_SRC): $ROOT_RAW" >&2; exit 2; }

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
