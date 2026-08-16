#!/usr/bin/env bash
set -euo pipefail
# transcript-audit.sh — GH-66 session/transcript-log audit
#
# Four pillars: Attested | Relevant | Fresh | Structured
#
# READ-ONLY: this script never writes to, moves, or deletes any transcript.
#
# Usage:
#   utils/transcript-audit.sh [<transcript-dir>]
#
# Defaults to AUDIT/relay-automation-transcripts/ relative to the repo root
# (resolved from this script's own location).
#
# Output: structured, greppable findings:
#   AUDIT stale-ref <file> <context>
#   AUDIT repeat-explore <dir> count=<n>
#   AUDIT unbounded-stall <transcript>
#
# Exit codes:
#   0  — normal (including when findings are emitted; this is a report, not a gate)
#   1  — bad arguments
#   2  — internal error

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/.." && pwd)"

# ── argument handling ──────────────────────────────────────────────────────────
if [ $# -gt 1 ]; then
  echo "usage: transcript-audit.sh [<transcript-dir>]" >&2
  exit 1
fi

TRANSCRIPT_DIR="${1:-"$REPO_ROOT/AUDIT/relay-automation-transcripts"}"

# Threshold: directory must appear in explore context >= this many times
REPEAT_EXPLORE_THRESHOLD=3

findings_stale=0
findings_repeat=0
findings_stall=0

# ── absent-dir guard ───────────────────────────────────────────────────────────
if [ ! -d "$TRANSCRIPT_DIR" ]; then
  echo "AUDIT summary: no-transcript-dir dir=$TRANSCRIPT_DIR"
  echo "AUDIT total stale-ref=0 repeat-explore=0 unbounded-stall=0"
  exit 0
fi

# Collect transcript files (md, txt, log) — use a temp file for the list
# (bash 3.2 compatible: no mapfile/associative arrays)
TRANSCRIPT_LIST="$(mktemp "${TMPDIR:-/tmp}/ta-list.XXXXXX")"
# Clean up temp list on exit
trap 'rm -f "$TRANSCRIPT_LIST" "$EXPLORE_TMP" 2>/dev/null || true' EXIT
EXPLORE_TMP="$(mktemp "${TMPDIR:-/tmp}/ta-explore.XXXXXX")"

find "$TRANSCRIPT_DIR" -type f \( \
  -name "*.md" -o -name "*.txt" -o -name "*.log" \
\) | sort >"$TRANSCRIPT_LIST"

if [ ! -s "$TRANSCRIPT_LIST" ]; then
  echo "AUDIT summary: no-transcripts-found dir=$TRANSCRIPT_DIR"
  echo "AUDIT total stale-ref=0 repeat-explore=0 unbounded-stall=0"
  exit 0
fi

# ── PILLAR 1 — Attested: stale-ref detection ──────────────────────────────────
# A stale-ref is a reference to a:
#   (a) path with OLD/deprecated/.bak/.backup in the name (pattern-based)
#   (b) repo-relative path appearing after read/cat/source that no longer exists
#
# READ-ONLY: we only grep transcripts; we never write to them.

while IFS= read -r tf; do
  [ -f "$tf" ] || continue

  # (a) deprecated/bak filename patterns anywhere in the file
  while IFS= read -r line; do
    token="$(echo "$line" | grep -oE '[^[:space:]"'"'"'`]*(\.bak|\.backup|OLD[^[:space:]]*|deprecated[^[:space:]]*)[^[:space:]"'"'"'`]*' | head -1 || true)"
    [ -z "$token" ] && continue
    ctx="$(echo "$line" | cut -c1-120)"
    echo "AUDIT stale-ref $tf \"$token\" -- $ctx"
    findings_stale=$((findings_stale + 1))
  done < <(grep -iE '(\.bak|\.backup|OLD[^[:space:]]+|deprecated[^[:space:]]*)' "$tf" 2>/dev/null || true)

  # (b) read/cat/source lines with repo-relative paths that no longer exist
  while IFS= read -r line; do
    # Extract a path-like token after the command keyword
    token="$(echo "$line" | sed -E 's/^[[:space:]]*(read|cat|source|open)[[:space:]]+["\x27]?//i' | grep -oE '[~/][^[:space:]"'"'"'`>|&;]+|[.]{1,2}/[^[:space:]"'"'"'`>|&;]+' | head -1 || true)"
    [ -z "$token" ] && continue
    # Resolve to absolute path
    case "$token" in
      ~/*) local_path="${HOME}/${token#\~/}" ;;
      ./*|../*) local_path="$REPO_ROOT/$token" ;;
      *) local_path="$token" ;;
    esac
    # Only flag if it looks like a repo path and doesn't exist
    case "$local_path" in
      "$REPO_ROOT"/*)
        if [ ! -e "$local_path" ]; then
          ctx="$(echo "$line" | cut -c1-120)"
          echo "AUDIT stale-ref $tf missing:$token -- $ctx"
          findings_stale=$((findings_stale + 1))
        fi
        ;;
    esac
  done < <(grep -iE '^[[:space:]]*(read|cat|source|open)[[:space:]]' "$tf" 2>/dev/null || true)

done <"$TRANSCRIPT_LIST"

# ── PILLAR 2 — Fresh: repeat-explore detection ────────────────────────────────
# Count how many times each directory path appears in ls/find/cd/list/explore
# context across ALL transcripts combined. Use a temp file as a tally (bash 3.2
# has no associative arrays).
#
# Strategy: emit one "dir-token" per matching line, sort, count with uniq -c,
# then filter on the threshold.

while IFS= read -r tf; do
  [ -f "$tf" ] || continue
  grep -iE '^[[:space:]]*(ls|find|cd|list|explore)[[:space:]]' "$tf" 2>/dev/null | \
    grep -oE '(ls|find|cd|list|explore)[[:space:]]+[^[:space:]"'"'"'>|&;]+' | \
    grep -oE '[/~.][^[:space:]"'"'"'>|&;]+' | \
    sed 's|/$||' \
  || true
done <"$TRANSCRIPT_LIST" | sort >"$EXPLORE_TMP"

# Count occurrences and emit findings for those meeting the threshold
if [ -s "$EXPLORE_TMP" ]; then
  uniq -c "$EXPLORE_TMP" | while read -r cnt dir; do
    # uniq -c counts consecutive equal lines; we sorted so this is a full tally
    if [ "$cnt" -ge "$REPEAT_EXPLORE_THRESHOLD" ]; then
      echo "AUDIT repeat-explore $dir count=$cnt"
      # Count externally: we emit one line per qualifying dir, parent counts by
      # scanning our own output (see summary below)
    fi
  done
fi

# ── PILLAR 3 — Relevant: unbounded-stall detection ────────────────────────────
# A stall is a transcript file with NO terminal marker:
#   exit <n>, EXIT=, DECISION:, STATUS:, RESULT:, PASS/FAIL
TERMINAL_RE='exit[[:space:]]+[0-9]|EXIT=[0-9]|DECISION:|STATUS:|RESULT:|[[:space:]]pass[[:space:]]|[[:space:]]fail[[:space:]]|PASS:|FAIL:'

while IFS= read -r tf; do
  [ -f "$tf" ] || continue
  if ! grep -qiE "$TERMINAL_RE" "$tf" 2>/dev/null; then
    echo "AUDIT unbounded-stall $tf"
    findings_stall=$((findings_stall + 1))
  fi
done <"$TRANSCRIPT_LIST"

# ── summary ───────────────────────────────────────────────────────────────────
# Re-count repeat-explore from explore tmp (we lost the count in the subshell above)
if [ -s "$EXPLORE_TMP" ]; then
  findings_repeat="$(uniq -c "$EXPLORE_TMP" | awk -v t="$REPEAT_EXPLORE_THRESHOLD" '$1 >= t' | wc -l | tr -d ' ')"
fi

total=$((findings_stale + findings_repeat + findings_stall))
echo "AUDIT total stale-ref=$findings_stale repeat-explore=$findings_repeat unbounded-stall=$findings_stall total=$total"
exit 0
