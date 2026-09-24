#!/usr/bin/env bash
# shakedown/scripts/audit.sh — static path audit of a target skill (read-only).
#
# Grades every .sh invocation token in the target's SKILL.md (via lib.sh's grade_path),
# flags sh-vs-bash invocation, then checks each bundled script's shebang / exec bit /
# self-location idiom. Anchors the verdict to the worst finding.
#
#   Usage: audit.sh --target <path-to-target-skill-dir>
#   Exit:  0 clean · 1 warnings · 2 blockers · 3 usage
#
# Self-locates and sources its own lib.sh — the exact idiom this skill recommends, so it
# resolves its helpers no matter the caller's working directory.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

TARGET=""
while (($#)); do case "$1" in
  --target) TARGET="${2:-}"; shift 2 ;;
  -h|--help) echo "usage: audit.sh --target <skill-dir>"; exit 0 ;;
  *) echo "audit: unknown argument: $1" >&2; exit 3 ;;
esac; done
[ -n "$TARGET" ] && [ -d "$TARGET" ] || { echo "audit: --target <existing skill dir> required" >&2; exit 3; }
SKILL="$TARGET/SKILL.md"
[ -f "$SKILL" ] || { echo "audit: no SKILL.md in $TARGET" >&2; exit 3; }

# Worst-severity tracker: 0 pass, 1 warn, 2 block. Verdict anchors to the worst, never an average.
worst=0
bump() { case "$1" in block) ((worst<2)) && worst=2 ;; warn) ((worst<1)) && worst=1 ;; esac; return 0; }

# --- header block ---
head_rev="not a git repo"
if git -C "$TARGET" rev-parse --short HEAD >/dev/null 2>&1; then
  head_rev="$(git -C "$TARGET" log -1 --format='%h %s' 2>/dev/null)"
fi
printf '## Shakedown static audit\n'
printf 'Target: %s (%s)\n' "$(basename "$TARGET")" "$TARGET"
printf 'Target HEAD: %s\n' "$head_rev"
printf 'Env: %s\n\n' "$(uname -srm 2>/dev/null)"

# --- part 1: invocation paths written in SKILL.md ---
printf '### Invocation paths (graded from SKILL.md)\n'
found_any=0
while IFS=$'\t' read -r lineno token raw; do
  [ -n "${token:-}" ] || continue
  found_any=1
  IFS='|' read -r _cls sev note <<<"$(grade_path "$token")"
  bump "$sev"
  printf '%s  L%s  %s  — %s\n' "$(sev_label "$sev")" "$lineno" "$token" "$note"
  if invoked_with_sh "$raw"; then
    bump warn
    printf '%s  L%s  %s  — invoked via `sh`, not `bash`; bashisms may break\n' "$(sev_label warn)" "$lineno" "$token"
  fi
done < <(find_script_calls "$SKILL")
[ "$found_any" = 1 ] || printf '(no .sh invocation tokens in SKILL.md — nothing to grade)\n'
printf '\n'
printf 'Note: this greps every `.sh` token, including illustrative examples in prose — a meta-skill\n'
printf 'that documents bad paths on purpose will show blocks for those examples; read in context.\n\n'

# --- part 2: bundled-script hygiene ---
printf '### Bundled-script hygiene\n'
scripts=()
while IFS= read -r f; do scripts+=("$f"); done < <(find "$TARGET" -type f -name '*.sh' 2>/dev/null | sort)
if ((${#scripts[@]}==0)); then
  printf '(no bundled .sh scripts — pure-prose skill; nothing to harden)\n'
else
  for f in "${scripts[@]}"; do
    rel="${f#"$TARGET"/}"
    if head -1 "$f" 2>/dev/null | grep -q '^#!'; then sb='[ok]'; else sb='[block]'; bump block; fi
    if [ -x "$f" ]; then xb='[ok]'; else xb='[warn]'; bump warn; fi
    # self-location only matters for a script that sources/refs a sibling
    if grep -q 'BASH_SOURCE' "$f"; then
      sl='[ok]'
    elif grep -qE '(^|[^a-zA-Z_])source[[:space:]]|^[[:space:]]*\.[[:space:]]|/[A-Za-z0-9_]+\.sh' "$f"; then
      sl='[block]'; bump block
    else
      sl='[n/a]'
    fi
    printf 'shebang %s  exec-bit %s  self-loc %s  — %s\n' "$sb" "$xb" "$sl" "$rel"
  done
fi
printf '\n'

# --- verdict (anchored to worst) ---
case "$worst" in
  2) printf 'Verdict: [path bug reproduced] — at least one blocker\n'; exit 2 ;;
  1) printf 'Verdict: [warnings only]\n'; exit 1 ;;
  *) printf 'Verdict: [clean]\n'; exit 0 ;;
esac
