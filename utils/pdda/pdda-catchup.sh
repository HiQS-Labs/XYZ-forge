#!/usr/bin/env bash
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=utils/pdda/pdda-lib.sh
. "$HERE/pdda-lib.sh"

CHECK_NAME="pdda-catchup"
EXIT_CODE=0

PDDA_LLM_BIN="${PDDA_LLM_BIN:-}"
PDDA_LLM_ARGS="${PDDA_LLM_ARGS:--p}"

if [ -z "$PDDA_LLM_BIN" ] || ! command -v "$PDDA_LLM_BIN" >/dev/null 2>&1; then
  pdda_record_finding info "$CHECK_NAME" "$PDDA_REPO_ROOT" 0 \
    "LLM catchup triage skipped (set PDDA_LLM_BIN to a model CLI such as agy/codex/claude to enable)" "skip"
  pdda_emit_summary "$CHECK_NAME" 0
  exit 0
fi

read -ra _llm_args <<<"$PDDA_LLM_ARGS"
[ -n "${PDDA_LLM_MODEL:-}" ] && _llm_args+=(--model "$PDDA_LLM_MODEL")

read -r -d '' RUBRIC <<'RUBRIC_EOF' || true
You are an expert repository manager and technical lead. 
Your task is to review recent activity in this repository (CHANGELOG entries, recent Git commits, recently added Inbox issues, and active working docs) and compare it against the current contents of ROUTER.md.
ROUTER.md serves as the canonical startup file and routing guide for this repository.

Based on the recent activity, please provide specific, actionable recommendations on what to:
1. MOVE in ROUTER.md (e.g. reordering or updating routing hints)
2. DELETE from ROUTER.md (e.g. stale rules or outdated pointers)
3. ADD to ROUTER.md (e.g. new canonical files, new command rails, or new overarching rules)

Do NOT rewrite the entire file. Provide concise recommendations explaining your rationale.
Output your recommendations in plain Markdown.
RUBRIC_EOF

# Gather context
# 1. ROUTER.md
ROUTER_CONTENT=""
if [ -f "$PDDA_REPO_ROOT/ROUTER.md" ]; then
  ROUTER_CONTENT="$(cat "$PDDA_REPO_ROOT/ROUTER.md")"
fi

# 2. CHANGELOG.md (Top 50 lines)
CHANGELOG_CONTENT=""
if [ -f "$PDDA_REPO_ROOT/CHANGELOG.md" ]; then
  CHANGELOG_CONTENT="$(head -n 50 "$PDDA_REPO_ROOT/CHANGELOG.md")"
fi

# 3. Recent Git Commits
COMMITS_CONTENT=""
if git -C "$PDDA_REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  COMMITS_CONTENT="$(git -C "$PDDA_REPO_ROOT" log -n 10 --oneline 2>/dev/null)"
fi

# 4. Recent Inbox Issues (filename + first heading, so the model gets real signal)
INBOX_CONTENT=""
if [ -d "$PDDA_INBOX_DIR" ]; then
  INBOX_CONTENT="$(
    find "$PDDA_INBOX_DIR" -maxdepth 1 -type f -name 'GH-*.md' | LC_ALL=C sort | head -n 10 |
      while IFS= read -r f; do
        title="$(grep -m1 '^#[[:space:]]' "$f" 2>/dev/null | sed -E 's/^#+[[:space:]]*//')"
        printf '%s — %s\n' "$(basename "$f")" "${title:-(no title)}"
      done
  )"
fi

# 5. Active Working Docs (filename + title + status)
WORKING_CONTENT=""
if [ -d "$PDDA_WORKING_DIR" ]; then
  WORKING_CONTENT="$(
    pdda_list_working_docs |
      while IFS= read -r f; do
        title="$(pdda_frontmatter_value "$f" "title" 2>/dev/null || grep -m1 '^#[[:space:]]' "$f" 2>/dev/null | sed -E 's/^#+[[:space:]]*//')"
        status="$(pdda_frontmatter_value "$f" "status" 2>/dev/null || echo "unknown")"
        printf '%s — %s (Status: %s)\n' "$(basename "$f")" "${title:-(no title)}" "$status"
      done
  )"
fi

# Assemble the full prompt once, then feed it on stdin (portable across model CLIs and immune to
# ARG_MAX limits when ROUTER.md is large).
PROMPT="$RUBRIC

=== CURRENT ROUTER.md ===
$ROUTER_CONTENT

=== RECENT CHANGELOG ENTRIES (TOP 50 LINES) ===
$CHANGELOG_CONTENT

=== RECENT GIT COMMITS (LAST 10) ===
$COMMITS_CONTENT

=== RECENT INBOX ISSUES (TOP 10) ===
$INBOX_CONTENT

=== ACTIVE WORKING DOCS ===
$WORKING_CONTENT
"

# Run LLM. Let stderr flow to the terminal (so auth/rate-limit/arg errors are visible, not swallowed)
# and capture stdout so we can both reprint it and persist it. rc is the model CLI's exit code (last
# stage of the pipe).
printf "Gathering recent repository activity and passing to %s...\n\n" "$PDDA_LLM_BIN"

RESPONSE="$(printf '%s' "$PROMPT" | "$PDDA_LLM_BIN" ${_llm_args[@]+"${_llm_args[@]}"})"
rc=$?

if [ "$rc" -ne 0 ]; then
  pdda_record_finding warn "$CHECK_NAME" "$PDDA_REPO_ROOT" 0 \
    "LLM catchup invocation failed (rc=$rc from $PDDA_LLM_BIN)" "error"
  EXIT_CODE=1
fi

printf '%s\n' "$RESPONSE"

# Persist recommendations so they survive terminal scrollback (other checks all leave a trail).
if [ -n "$RESPONSE" ]; then
  mkdir -p "$PDDA_MISC_DIR"
  OUT_FILE="$PDDA_MISC_DIR/pdda-catchup-$(pdda_today).md"
  printf '%s\n' "$RESPONSE" > "$OUT_FILE"
  pdda_record_finding info "$CHECK_NAME" "$OUT_FILE" 0 \
    "Catchup recommendations written" "report"
fi

echo ""
pdda_emit_summary "$CHECK_NAME" "$EXIT_CODE"
exit "$(pdda_gated_exit "$EXIT_CODE")"
