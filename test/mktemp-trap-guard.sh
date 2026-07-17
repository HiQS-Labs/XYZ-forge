#!/usr/bin/env bash
# test/mktemp-trap-guard.sh — GH-177 regression guard: static audit for the pattern that rm -rf'd
# this repo TWICE (2026-07-07, 2026-07-17).
#
# Root cause (see PROJECT/2-WORKING/GH-177-MKTEMP-TRAP-REPO-WIPE.md): `mktemp -d` can fail silently
# under a sandboxed shell (empty stdout, non-zero rc). Empirically confirmed (2026-07-17): `cd ""`
# SUCCEEDS (rc=0) and silently stays at the current directory rather than erroring — so
# `cd "$(mktemp -d)" && pwd -P` converts a failed mktemp into a valid-looking, NON-EMPTY path: the
# repo root itself. Wiring that into `trap 'rm -rf "$VAR"' EXIT` then deletes the repo on exit.
# NOTE this is NOT the same risk as a bare `VAR="$(mktemp -d)"` with no `cd`-wrap: if mktemp fails
# there, VAR is simply empty, and `rm -rf ""` is a confirmed-safe no-op (verified empirically — it
# does not delete cwd contents) — so that far more common idiom is intentionally NOT flagged here.
#
# This test scans every .sh file under the real code directories (not relay-system/ transcripts, not
# node_modules) for the shape that is actually dangerous, whether inline or split across lines:
#   (1) the exact historical idiom `cd "$(mktemp` / `cd $(mktemp` on one line — unsafe regardless of
#       what follows, because `cd` swallows mktemp's failure silently and can turn it into a hit.
#   (2) a variable assigned from `mktemp` that is later `cd`'d into (`cd "$VAR"`) — one or more lines
#       later — without an intervening check that it's non-empty and a real directory first. Same
#       shape as (1), just split across lines instead of nested inline.
# Comment-only lines are skipped so this test doesn't flag documentation ABOUT the bug (like the
# paragraph above, or this repo's own fixed files' explanatory comments) as if it were live code.
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
PASS=0; FAIL=0
pass(){ echo "  PASS: $*"; PASS=$((PASS+1)); }
fail(){ echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
echo "== test: mktemp-trap-guard (GH-177) =="

# Real code directories only — excludes relay-system/ (transcripts), AUDIT/ (transcripts), and
# anything gitignored (node_modules, .tick, etc.) by construction (find only walks what's listed).
SCAN_DIRS=(test utils relay-automation skills bin)
FILES=()
while IFS= read -r _f; do
  [ -n "$_f" ] && FILES+=("$_f")
done < <(
  for d in "${SCAN_DIRS[@]}"; do
    [ -d "$REPO/$d" ] || continue
    find "$REPO/$d" -type f -name '*.sh' -not -path '*/node_modules/*'
  done | sort -u
)

is_comment_line() {  # trimmed line's first non-space char is '#'
  local line="$1" trimmed
  trimmed="${line#"${line%%[![:space:]]*}"}"
  [[ "$trimmed" == \#* ]]
}

audit_file() {
  local file="$1" rel
  rel="${file#$REPO/}"
  # Never flag THIS file for quoting the pattern in its own header comment / for the word "mktemp"
  # appearing in prose — only real code lines matter, and this file has no mktemp assignment of its
  # own, so it naturally produces zero matches below.

  local -a lines=()
  local line
  while IFS= read -r line || [ -n "$line" ]; do lines+=("$line"); done < "$file"

  local idx n="${#lines[@]}"
  for ((idx = 0; idx < n; idx++)); do
    line="${lines[$idx]}"
    is_comment_line "$line" && continue

    # --- Tier 1: the exact historical footgun shape, unsafe regardless of context ---
    if [[ "$line" =~ cd[[:space:]]+\"?\$\(.*mktemp ]]; then
      fail "$rel:$((idx + 1)) unsafe 'cd \$(mktemp ...)' idiom — cd \"\" silently succeeds and stays at cwd if mktemp fails, instead of erroring: ${line#"${line%%[![:space:]]*}"}"
    fi

    # --- Tier 2: a var assigned from mktemp, later RE-CAPTURED via `X="$(cd "$VAR" && pwd ...)"` ---
    # A bare `cd "$VAR"` inside an unrelated subshell/command-substitution (used only to scope a side
    # effect, e.g. `( cd "$FR" && bash something )`) is NOT the danger: it can't leak a wrong cwd out,
    # and its captured output (a program's stdout/logs) can never be mistaken for a path later. The
    # danger is specifically an outer assignment that captures `cd "$VAR" && pwd` — `pwd` is what turns
    # a swallowed mktemp failure into a persisted, valid-looking PATH string (the split-line twin of
    # Tier 1's inline `cd "$(mktemp ...)" && pwd`) — chaining to any other command (e.g. running a
    # program and capturing its output) can't produce that same failure mode.
    if [[ "$line" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)=.*mktemp ]]; then
      local var="${BASH_REMATCH[1]}"
      local guarded=0

      local j
      for ((j = idx + 1; j < n; j++)); do
        is_comment_line "${lines[$j]}" && continue
        local L="${lines[$j]}"

        if [[ "$L" == *"\$$var"* || "$L" == *"\${$var}"* ]]; then
          if [[ "$L" =~ \[[[:space:]]+-[nzd][[:space:]] ]] || [[ "$L" == *'||'* ]]; then
            guarded=1
          fi
        fi

        local recapture_re="=.*\\\$\\(.*cd[[:space:]]+\"?\\\$\\{?${var}\\}?\"?.*&&[[:space:]]*pwd"
        if [ "$guarded" -eq 0 ] && [[ "$L" =~ $recapture_re ]]; then
          fail "$rel:$((idx + 1)) \$$var assigned from mktemp, then RE-CAPTURED via '\$(cd \"\$$var\" && ...)' at line $((j + 1)) with no non-empty/is-directory guard in between — same shape as the historical repo-wipe (GH-177), just split across lines"
          break
        fi
      done
    fi
  done
}

if [ "${#FILES[@]}" -eq 0 ]; then
  echo "FAIL: no .sh files found to audit under ${SCAN_DIRS[*]}" >&2
  exit 1
fi

for f in "${FILES[@]}"; do
  audit_file "$f"
done

if [ "$FAIL" -gt 0 ]; then
  echo "  mktemp-trap-guard: $PASS passed, $FAIL failed"
  exit 1
fi

pass "audited ${#FILES[@]} .sh files under ${SCAN_DIRS[*]} — no unguarded mktemp-into-destructive-rm-rf pattern found"
echo "  mktemp-trap-guard: $PASS passed, $FAIL failed"
exit 0
