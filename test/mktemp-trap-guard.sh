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
# GH-177 review (Codex round 4, Blocker 2): a `*.sh`-suffix glob misses extensionless bash
# entrypoints like `bin/validate-relay-block` (real `#!/usr/bin/env bash`, no `.sh` suffix) — a
# reintroduced footgun there would never be scanned. `is_bash_script` below catches those too.
is_bash_script() {  # <path> — true if executable and its shebang names bash
  local p="$1"
  [ -x "$p" ] || return 1
  IFS= read -r _shebang < "$p" 2>/dev/null
  [[ "$_shebang" == '#!'*bash* ]]
}

SCAN_DIRS=(test utils relay-automation skills bin tools)
FILES=()
while IFS= read -r _f; do
  [ -n "$_f" ] && FILES+=("$_f")
done < <(
  { for d in "${SCAN_DIRS[@]}"; do
      [ -d "$REPO/$d" ] || continue
      find "$REPO/$d" -type f -not -path '*/node_modules/*' -not -name '*.sh' -print | while IFS= read -r _cand; do
        is_bash_script "$_cand" && printf '%s\n' "$_cand"
      done
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

  # GH-177 review (Codex round 3, Blocker 1): scanning whole physical lines missed a same-line
  # multi-statement chain — `TMP="$(mktemp -d)"; cd "$TMP"` (or `; TMP="$(cd "$TMP" && pwd)"`) all on
  # ONE line is the identical failure shape, just never split across lines at all. Flatten each
  # non-comment physical line into `;`-separated segments and scan those instead, so a same-line chain
  # is checked exactly like the same statements on separate lines would be. Naive split — doesn't
  # respect quoting/heredocs — an accepted limitation of this heuristic audit, same tradeoff already
  # made by its other checks (comment-skip, no real parser). A comment line contributes NO segments
  # (splitting `# TMP=...; stuff` would wrongly treat "stuff" as live code).
  local -a seg=() seg_ln=()
  local rest s
  for ((idx = 0; idx < ${#lines[@]}; idx++)); do
    line="${lines[$idx]}"
    is_comment_line "$line" && continue
    rest="$line"
    while [[ "$rest" == *';'* ]]; do
      s="${rest%%;*}"; rest="${rest#*;}"
      seg+=("$s"); seg_ln+=("$((idx + 1))")
    done
    seg+=("$rest"); seg_ln+=("$((idx + 1))")
  done

  local n="${#seg[@]}"
  for ((idx = 0; idx < n; idx++)); do
    line="${seg[$idx]}"

    # --- Tier 1: the exact historical footgun shape, unsafe regardless of context ---
    if [[ "$line" =~ cd[[:space:]]+\"?\$\(.*mktemp ]]; then
      fail "$rel:${seg_ln[$idx]} unsafe 'cd \$(mktemp ...)' idiom — cd \"\" silently succeeds and stays at cwd if mktemp fails, instead of erroring: ${line#"${line%%[![:space:]]*}"}"
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
    # GH-177 review (Codex round 3, Blocker 2): the entry regex required the var name to start the
    # segment, so a declaration-prefixed assignment (`local TMP="$(mktemp -d)"`, `declare TMP=...`,
    # `export TMP=...`) was invisible to Tier 2 entirely. Optional keyword+space prefix now allowed;
    # the var name is always capture group 2 (group 1 is the optional keyword clause, empty if absent).
    local decl_re='^[[:space:]]*(local[[:space:]]+|declare[[:space:]]+|export[[:space:]]+|typeset[[:space:]]+)?([A-Za-z_][A-Za-z0-9_]*)=.*mktemp'
    if [[ "$line" =~ $decl_re ]]; then
      local var="${BASH_REMATCH[2]}"
      local guarded=0
      # GH-177 review (Codex round 5, final Blocker): a lone `-n` OR `-z` OR `-d` test was accepted as
      # a conclusive guard even when it doesn't actually gate anything — `[ -n "$TMP" ] || true` or a
      # bare `[ -d "$TMP" ] || echo miss` both mention the var with a real test, but neither ABORTS on
      # failure, so mktemp failure still flows straight through to the dangerous path. Fail-closed now:
      # require BOTH a non-empty (`-n`) test AND an is-directory (`-d`) test for this var, each provably
      # gating (chained to `|| exit`, `|| return`, or a `{ ...; exit|return; }` block) — same line or
      # accumulated across separate lines. A decoy that mentions the var without actually aborting sets
      # neither flag, so it can never silently satisfy the guard.
      local seen_n_abort=0 seen_d_abort=0
      local n_re="-n[[:space:]]+\"?\\\$\\{?${var}\\}?\"?"
      local d_re="-d[[:space:]]+\"?\\\$\\{?${var}\\}?\"?"
      local abort_re='\|\|[[:space:]]*(exit|return|\{[^}]*(exit|return))'

      # GH-177 review (Codex round 4, Blocker 1): `;`-splitting alone missed same-SEGMENT `&&`/`||`
      # chains (`TMP="$(mktemp -d)" && cd "$TMP"`, `... || TMP="$(cd "$TMP" && pwd)"`) — the chained
      # continuation lives in the SAME segment as the assignment, never split further. Fixed by
      # starting this scan at the assignment's OWN segment (j = idx, not idx + 1): `seg[idx]` already
      # contains any `&&`/`||`-chained tail as plain text, so the existing recapture/bare-cd checks
      # below catch it without needing a 4th delimiter to split on.
      local j
      for ((j = idx; j < n && guarded == 0; j++)); do
        local L="${seg[$j]}"

        if [[ ("$L" == *"\$$var"* || "$L" == *"\${$var}"*) && "$L" =~ $abort_re ]]; then
          [[ "$L" =~ $n_re ]] && seen_n_abort=1
          [[ "$L" =~ $d_re ]] && seen_d_abort=1
        fi
        if [ "$seen_n_abort" -eq 1 ] && [ "$seen_d_abort" -eq 1 ]; then
          guarded=1
          break
        fi

        local recapture_re="=.*\\\$\\(.*cd[[:space:]]+\"?\\\$\\{?${var}\\}?\"?.*&&[[:space:]]*pwd"
        if [[ "$L" =~ $recapture_re ]]; then
          fail "$rel:${seg_ln[$idx]} \$$var assigned from mktemp, then RE-CAPTURED via '\$(cd \"\$$var\" && ...)' at ${rel}:${seg_ln[$j]} with no non-empty/is-directory guard in between — same shape as the historical repo-wipe (GH-177), just split across lines/statements"
          break
        fi

        if [[ "$L" =~ cd[[:space:]]+\"?\$\{?$var\}?\"? ]]; then
          # GH-177 review (Codex round 4): a naive "does the text before 'cd' contain ANY '('" check
          # is fooled by the mktemp call's OWN parens on the same segment (`TMP="$(mktemp -d)" && cd
          # "$TMP"` has a `(` before "cd" from "$(mktemp", but it's already CLOSED — not wrapping the
          # cd at all). Count UNCLOSED parens instead: only a net-positive count means "cd" is still
          # nested inside an open subshell/command-substitution at that point in the segment.
          local before_cd="${L%%cd*}"
          local opens="${before_cd//[^(]/}" closes="${before_cd//[^)]/}"
          if (( ${#opens} <= ${#closes} )); then
            fail "$rel:${seg_ln[$idx]} \$$var assigned from mktemp, then BARE 'cd \"\$$var\"' at ${rel}:${seg_ln[$j]} (not scoped inside a subshell) with no non-empty/is-directory guard first — changes the script's own cwd unconditionally if mktemp failed, same failure class as GH-177"
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

pass "audited ${#FILES[@]} shell scripts under ${SCAN_DIRS[*]} (*.sh + extensionless bash-shebang executables) — no unguarded mktemp-into-destructive-rm-rf pattern found"
echo "  mktemp-trap-guard: $PASS passed, $FAIL failed"
exit 0
