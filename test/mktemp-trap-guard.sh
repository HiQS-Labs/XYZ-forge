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

# Real code directories, PLUS root-level .sh files themselves (validate.sh, install.sh,
# run-tests.sh) — excludes relay-system/ (transcripts), AUDIT/ (transcripts), and anything
# gitignored (node_modules, .tick, etc.) by construction (find only walks what's listed).
# GH-177 review (Codex, round 1): the original version scanned only a fixed subdirectory
# allowlist and silently missed root-level scripts and tools/ — fixed by adding both.
SCAN_DIRS=(test utils relay-automation skills bin tools)
FILES=()
while IFS= read -r _f; do
  [ -n "$_f" ] && FILES+=("$_f")
done < <(
  { for d in "${SCAN_DIRS[@]}"; do
      [ -d "$REPO/$d" ] || continue
      find "$REPO/$d" -type f -name '*.sh' -not -path '*/node_modules/*'
    done
    find "$REPO" -maxdepth 1 -type f -name '*.sh'
  } | sort -u
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

    # --- Tier 2: a var assigned from mktemp, later `cd`'d into without a real guard first ------------
    # A `cd "$VAR"` inside an unrelated subshell/command-substitution opened EARLIER ON THE SAME LINE
    # (e.g. `( cd "$FR" && bash something )`, `out="$( cd "$FR" && bash "$FH" )"`) is NOT the danger:
    # it can't leak a wrong cwd out past that subshell. Two shapes ARE the danger, and both are checked
    # below, only once a real validation guard (an explicit `-n`/`-z`/`-d` test naming $VAR, or an
    # exit-status check chained directly onto the mktemp assignment itself) has NOT already appeared:
    #   (a) RE-CAPTURE: an outer assignment that captures `cd "$VAR" && pwd` — `pwd` is what turns a
    #       swallowed mktemp failure into a persisted, valid-looking PATH string (the split-line twin
    #       of Tier 1's inline `cd "$(mktemp ...)" && pwd`).
    #   (b) BARE cd: `cd "$VAR"` NOT opened inside a subshell/command-substitution on that same line —
    #       this changes the CALLING SCRIPT's own cwd for everything after it, unconditionally, the
    #       moment $VAR is empty and `cd ""` silently no-ops-in-place — dangerous regardless of what
    #       (if anything) reads the cwd back out afterward. (GH-177 review, Codex round 1, Blocker 2:
    #       the original version only caught the same-line re-capture form and missed this.)
    # GH-177 review (Codex round 1, Blocker 2): the guard check itself used to accept ANY `||` anywhere
    # on a line merely mentioning $VAR as proof of validation (e.g. a decoy `echo "$VAR" || true` would
    # have silently suppressed real findings after it) — round 1's "fix" narrowed that to a same-line
    # `||` on the assignment itself, but that's STILL too loose: `TMP="$(mktemp -d)" || true` doesn't
    # abort anything and leaves $TMP just as unvalidated (Codex round 2, Blocker). Removed the same-line
    # shortcut entirely: the ONLY thing that counts as a guard now is an explicit `-n`/`-z`/`-d` test
    # naming $VAR on some later line — a real `X="$(mktemp -d)" || { ...; exit 1; }` still passes fine
    # because the very next validation line (`[ -n "$X" ] && [ -d "$X" ] || ...`) always follows it in
    # a correct fix; there's no legitimate guard shape this drops.
    if [[ "$line" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)=.*mktemp ]]; then
      local var="${BASH_REMATCH[1]}"
      local guarded=0

      local j
      for ((j = idx + 1; j < n && guarded == 0; j++)); do
        is_comment_line "${lines[$j]}" && continue
        local L="${lines[$j]}"

        if [[ "$L" == *"\$$var"* || "$L" == *"\${$var}"* ]] \
           && [[ "$L" =~ \[[[:space:]]+-[nzd][[:space:]] ]]; then
          guarded=1
          break
        fi

        local recapture_re="=.*\\\$\\(.*cd[[:space:]]+\"?\\\$\\{?${var}\\}?\"?.*&&[[:space:]]*pwd"
        if [[ "$L" =~ $recapture_re ]]; then
          fail "$rel:$((idx + 1)) \$$var assigned from mktemp, then RE-CAPTURED via '\$(cd \"\$$var\" && ...)' at line $((j + 1)) with no non-empty/is-directory guard in between — same shape as the historical repo-wipe (GH-177), just split across lines"
          break
        fi

        if [[ "$L" =~ cd[[:space:]]+\"?\$\{?$var\}?\"? ]]; then
          local before_cd="${L%%cd*}"
          if [[ "$before_cd" != *'('* ]]; then
            fail "$rel:$((idx + 1)) \$$var assigned from mktemp, then BARE 'cd \"\$$var\"' at line $((j + 1)) (not scoped inside a subshell) with no non-empty/is-directory guard first — changes the script's own cwd unconditionally if mktemp failed, same failure class as GH-177"
            break
          fi
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
