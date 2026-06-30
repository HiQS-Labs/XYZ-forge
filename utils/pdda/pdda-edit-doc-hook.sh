#!/usr/bin/env bash
# pdda-edit-doc-hook.sh — PostToolUse(Edit|Write|MultiEdit) fast LOCAL single-file doc lint.
#
# Tier 1 of the two-tier doc-health system (tier 2 is the Stop full-scan, pdda-stop-doc-health.sh).
# Reads the hook JSON on stdin, pulls tool_input.file_path, and:
#   - exits 0 INSTANTLY for anything that is not ROADMAP.md or PROJECT/**/*.md (not a PDDA doc),
#   - otherwise runs only the FAST LOCAL checks for that one file — NO network, NO gh, NO LLM:
#       ROADMAP.md       -> `pdda.sh roadmap`
#       PROJECT/**/*.md  -> frontmatter + status-table + hardcoded-paths + roadmap-coverage,
#                           scoped to the single file via PDDA_ONLY_FILE
#
# WARN-ONLY and FAIL-OPEN: it ALWAYS exits 0, so it can NEVER block the edit. Findings print to stderr
# for visibility only. Wire it in .claude/settings.json (PostToolUse, matcher "Edit|Write|MultiEdit").
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=utils/pdda/pdda-lib.sh
. "$HERE/pdda-lib.sh" 2>/dev/null || exit 0   # fail-open: if the lib can't load, never block the edit
PDDA="$HERE/pdda.sh"

payload="$(cat 2>/dev/null || true)"

# Extract tool_input.file_path. An Edit/Write payload's only file_path values all name the edited file,
# so a simple capture is safe; if it yields nothing we just exit 0 (fail-open).
file_path="$(printf '%s' "$payload" \
  | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"
[ -n "$file_path" ] || exit 0

# Normalize to a repo-relative path for the doc-type test.
case "$file_path" in
  "$PDDA_REPO_ROOT"/*) rel="${file_path#"$PDDA_REPO_ROOT"/}" ;;
  /*) exit 0 ;;                # absolute path outside this repo — not ours
  *) rel="$file_path" ;;       # already repo-relative
esac

# Instant no-op unless it is a PDDA-governed doc.
case "$rel" in
  ROADMAP.md|PROJECT/*.md) : ;;
  *) exit 0 ;;
esac

# Local-only, observe mode (warn severities never block); we exit 0 regardless of any check's result.
export PDDA_MODE=observe
printf 'pdda doc-health (edit): %s\n' "$rel" >&2

if [ "$rel" = "ROADMAP.md" ]; then
  PDDA_ROADMAP="$file_path" "$PDDA" roadmap 1>&2 || true
else
  PDDA_ONLY_FILE="$file_path" "$PDDA" frontmatter      1>&2 || true
  PDDA_ONLY_FILE="$file_path" "$PDDA" status-table     1>&2 || true
  PDDA_ONLY_FILE="$file_path" "$PDDA" hardcoded-paths  1>&2 || true
  PDDA_ONLY_FILE="$file_path" "$PDDA" roadmap-coverage 1>&2 || true
fi

exit 0
