#!/usr/bin/env bash
# shakedown/scripts/lib.sh — shared helpers, sourced by audit.sh and harness.sh.
#
# Note the pattern this file is sourced WITH (see audit.sh / harness.sh):
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "$SCRIPT_DIR/lib.sh"
# That is the exact self-location idiom shakedown checks for and recommends. The
# scripts eat their own dog food: they never assume the caller's working dir.

# Path token character class (allows $ { } ~ . / _ - and alnum); avoids quoting headaches.
SHK_PATH_RE='[A-Za-z0-9_./~${}()-]+\.sh'

# grade_path <token>
# Classify how robustly a script path written in a SKILL.md invocation will
# resolve when a *different* session runs it from an arbitrary working dir.
# Echoes: "<CLASS>|<severity>|<note>"   severity ∈ pass warn block
grade_path() {
  local p="$1"
  if [[ "$p" == *'$'* || "$p" == *BASH_SOURCE* ]]; then
    echo "SELF|pass|anchored to a variable (e.g. \$SKILL_DIR / BASH_SOURCE) — resolves regardless of CWD"
  elif [[ "$p" == /* ]]; then
    echo "ABSOLUTE|warn|absolute path — survives any CWD, but hardcoded to one machine/layout"
  elif [[ "$p" == '~'* ]]; then
    echo "HOME|block|home-hardcoded (~) — breaks when the skill is installed project-level instead of user-level"
  elif [[ "$p" == ./* || "$p" == ../* ]]; then
    echo "CWD|block|CWD-relative (./ or ../) — resolves against the session's working dir, not the skill"
  elif [[ "$p" == */* ]]; then
    echo "CWD|block|path-relative (dir/script.sh, no anchor) — resolves against CWD; the classic 'works in one session, not another' bug"
  else
    echo "BARE|block|bare name — relies on PATH; almost never on PATH in another session"
  fi
}

# sev_label <severity> — ASCII severity tag, matching the SKILL.md report markers (no emoji,
# so output stays grep/copy-safe and consistent with the repo's plain-ASCII presentation).
sev_label() {
  case "$1" in
    pass)  echo "[ok]"    ;;
    warn)  echo "[warn]"  ;;
    block) echo "[block]" ;;
    *)     echo "[?]"     ;;
  esac
}

# find_script_calls <file>
# Emit one line per .sh path token found in <file>:  lineno<TAB>token<TAB>rawline
find_script_calls() {
  local file="$1"
  grep -nE "$SHK_PATH_RE" "$file" 2>/dev/null | while IFS= read -r hit; do
    local lineno="${hit%%:*}"
    local content="${hit#*:}"
    while IFS= read -r tok; do
      [[ -n "$tok" ]] && printf '%s\t%s\t%s\n' "$lineno" "$tok" "$content"
    done < <(printf '%s\n' "$content" | grep -oE "$SHK_PATH_RE")
  done
}

# invoked_with_sh <rawline> <token-basename>
# True (0) if the line runs the script through `sh` rather than `bash` (bashisms risk).
invoked_with_sh() {
  local raw="$1"
  [[ "$raw" =~ (^|[^[:alnum:]_])sh[[:space:]] ]] && ! [[ "$raw" =~ (^|[^[:alnum:]_])bash[[:space:]] ]]
}

# trim <string> — collapse to a single trimmed line for table cells
trim() {
  local s="$1"
  s="${s//$'\n'/ }"
  s="$(printf '%s' "$s" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
  printf '%s' "$s"
}