#!/usr/bin/env bash
set -u
#
# preflight-docs.sh — GH-78: optional, best-effort, hourly doc PREFLIGHT.
#
# For every active doc in PROJECT/2-WORKING/ and every PROJECT/1-INBOX/GH-*.md capture that is parked in
# ROADMAP.md, this:
#   1. REVIEWS the doc against the PDDA contract — reusing the deterministic pdda.sh checks (for
#      2-WORKING docs) / a lightweight inline frontmatter check (for inbox captures) to learn EXACTLY
#      what is wrong. No guessing.
#   2. Makes SAFE, contract-enforcing EDITS where the fix is unambiguous, delegating the edit judgment to
#      an LLM (PDDA_LLM_BIN — the same convention pdda.sh doc-ready / pdda-catchup.sh already use).
#   3. LOGS every edit/change to an append-only telemetry JSONL beside this telemetry folder
#      (utils/telemetry/preflight-log/YYYY-MM-DD.jsonl).
#   4. Emits a WARN log entry (and makes NO edit) whenever the fix is not safe or there is not enough
#      guidance to edit — the safety valve.
#
# SAFETY POSTURE (inherits PDDA's philosophy — see PROJECT/PDDA.md):
#   * best-effort, ALWAYS exits 0 — never blocks a build (an LLM oracle must be non-deterministic-safe).
#   * OFF BY DEFAULT edit-wise: a no-op unless PDDA_LLM_BIN is set to a model CLI (claude/codex/agy).
#     With it unset the deterministic pass still runs and WARNs on docs that need a manual fix.
#   * NEVER auto-commits or pushes — edits land in the working tree only; a human reviews git diff + log.
#   * deterministic safety valve: a candidate edit is applied only if the deterministic findings do not
#     get worse AND the diff is small (mechanical), else it is reverted from a backup and WARNed.
#
# SCHEDULING ("does it have to be a Claude Desktop scheduled job?" — NO). The script is the deliverable;
# the scheduler is pluggable. Recommended: a macOS launchd hourly agent (matches PDDA.md's "Suggested
# hourly schedule"). Sample ~/Library/LaunchAgents/com.xyz.preflight-docs.plist:
#
#   <?xml version="1.0" encoding="UTF-8"?>
#   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
#   <plist version="1.0"><dict>
#     <key>Label</key><string>com.xyz.preflight-docs</string>
#     <key>ProgramArguments</key><array>
#       <string>/bin/bash</string>
#       <string>/ABSOLUTE/PATH/TO/xyz-3-agents-swarm/utils/telemetry/preflight-docs.sh</string>
#     </array>
#     <key>EnvironmentVariables</key><dict><key>PDDA_LLM_BIN</key><string>claude</string></dict>
#     <key>StartInterval</key><integer>3600</integer>
#     <key>RunAtLoad</key><true/>
#   </dict></plist>
#
# Then: launchctl load ~/Library/LaunchAgents/com.xyz.preflight-docs.plist
# Alternatives: a Claude Code scheduled task (harness-native cron), or a Claude Desktop scheduled job.
#
# Usage: [PDDA_LLM_BIN=claude] utils/telemetry/preflight-docs.sh
# Env knobs:
#   PDDA_LLM_BIN            model CLI to delegate edits to (unset => review+warn only, no edits)
#   PDDA_LLM_ARGS          args passed to the model CLI (default "-p")
#   PDDA_LLM_MODEL         optional --model value
#   PREFLIGHT_LOG_DIR      telemetry log dir (default <this dir>/preflight-log)
#   PREFLIGHT_MAX_EDIT_LINES  reject a candidate edit whose changed-line count exceeds this (default 30)
#   PDDA_REPO_ROOT / PDDA_WORKING_DIR / PDDA_INBOX_DIR  standard PDDA overrides (used for tests)
#   PDDA_ROADMAP           ROADMAP.md path (default <repo root>/ROADMAP.md)

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=utils/pdda/pdda-lib.sh
. "$HERE/../pdda/pdda-lib.sh"

PDDA_SH="$HERE/../pdda/pdda.sh"
PDDA_ROADMAP="${PDDA_ROADMAP:-$PDDA_REPO_ROOT/ROADMAP.md}"
PREFLIGHT_LOG_DIR="${PREFLIGHT_LOG_DIR:-$HERE/preflight-log}"
PREFLIGHT_MAX_EDIT_LINES="${PREFLIGHT_MAX_EDIT_LINES:-30}"
PDDA_LLM_BIN="${PDDA_LLM_BIN:-}"
PDDA_LLM_ARGS="${PDDA_LLM_ARGS:--p}"

RUN_ID="preflight-$(date -u +%Y%m%dT%H%M%SZ)-$$"
MODEL_LABEL="${PDDA_LLM_BIN:-none}"
[ -n "${PDDA_LLM_MODEL:-}" ] && MODEL_LABEL="$PDDA_LLM_BIN:$PDDA_LLM_MODEL"

EDITS=0 WARNS=0 CLEANS=0

# ── telemetry logger ─────────────────────────────────────────────────────────
# One JSON object per line, appended to a daily file — same JSONL spirit as XYZ.json / PDDA-ACTIVITY.
_pf_log() {
  # _pf_log <doc> <action> <safe> <before> <after> <changed> <summary>
  local logf; logf="$PREFLIGHT_LOG_DIR/$(date +%Y-%m-%d).jsonl"
  mkdir -p "$PREFLIGHT_LOG_DIR" 2>/dev/null || true
  python3 - "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$MODEL_LABEL" "$RUN_ID" >>"$logf" <<'PY'
import sys, json, datetime
doc, action, safe, before, after, changed, summary, model, run_id = sys.argv[1:10]
print(json.dumps({
    "timestamp": datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"),
    "run_id": run_id,
    "doc": doc,
    "action": action,           # edit | warn | clean | skip
    "safe": safe == "true",
    "before_errors": int(before),
    "after_errors": int(after),
    "changed_lines": int(changed),
    "model": model,
    "summary": summary,
}))
PY
}

# ── deterministic contract error count ───────────────────────────────────────
# 2-WORKING: authoritative — sum the error totals of the scoped pdda.sh checks (they scan 2-WORKING only,
# so PDDA_ONLY_FILE cleanly isolates the one doc). INBOX: lightweight inline frontmatter check, because
# the pdda.sh checks intentionally do not scan 1-INBOX and inbox captures carry a lighter contract.
_pf_errors() {
  local file="$1" kind="$2" total=0 out sumline n key
  if [ "$kind" = working ]; then
    local check
    for check in frontmatter status-table hardcoded-paths; do
      out="$(PDDA_FORMAT=json PDDA_MODE=observe PDDA_ONLY_FILE="$file" "$PDDA_SH" "$check" 2>/dev/null)"
      sumline="$(printf '%s\n' "$out" | grep '"action":"summary"' | tail -1)"
      n="$(printf '%s' "$sumline" | sed -n 's/.*errors=\([0-9][0-9]*\).*/\1/p')"
      total=$((total + ${n:-0}))
    done
  else
    # inbox capture contract (PDDA.md "GitHub issue intake"): required minimum keys.
    if ! pdda_has_frontmatter "$file"; then
      total=$((total + 1))
    else
      for key in gh_issue source title status created doc_type; do
        if ! pdda_frontmatter_has_key "$file" "$key" \
           || [ -z "$(pdda_trim "$(pdda_frontmatter_value "$file" "$key")")" ]; then
          total=$((total + 1))
        fi
      done
    fi
    # cheap absolute-path scan (mirrors pdda.sh hardcoded-paths intent) outside fenced blocks.
    n="$(grep -nE '/Users/|/private/|/home/[^/]+/|file://|[A-Za-z]:\\\\' "$file" 2>/dev/null | grep -cvE '^\s*[0-9]+:\s*[`>]' || true)"
    total=$((total + ${n:-0}))
  fi
  printf '%s' "$total"
}

# ── LLM edit rubric ──────────────────────────────────────────────────────────
read -r -d '' RUBRIC <<'RUBRIC_EOF' || true
You are a documentation CONTRACT ENFORCER for this repo's PDDA system. You are given ONE markdown doc and
the deterministic contract violations found in it. Make ONLY the minimal, MECHANICAL edits required to
satisfy the contract:
  - add a MISSING required frontmatter key with a correct, faithful value
      (2-WORKING docs need: title, status, created, updated, owner, goal; dates are YYYY-MM-DD)
      (1-INBOX GH captures need: gh_issue, source, title, status, created, doc_type)
  - fix a status-table header to be EXACTLY:  What was just completed | What's next
  - fill a BLANK status-table cell with a faithful, minimal value drawn from the doc
  - repoint an obvious hardcoded absolute path (/Users/..., /home/..., file://...) to a repo-relative one
Do NOT rewrite prose, restructure sections, reorder content, change meaning, or fix anything that needs
judgment or information you do not have. If the safe fix is unclear, DO NOT edit — warn instead.

Respond in EXACTLY this format and NOTHING else:
ACTION: <edit|warn|clean>
REASON: <one short line>
---BEGIN-DOC---
<the FULL corrected document — include this section ONLY when ACTION is edit>
---END-DOC---

ACTION meanings: edit = you made safe mechanical fixes (full corrected doc follows);
clean = already compliant, no change; warn = a fix is needed but is not safe/mechanical for you to make.
RUBRIC_EOF

# ── per-doc preflight ────────────────────────────────────────────────────────
preflight_one() {
  local file="$1" kind="$2" rel before after changed resp action reason newdoc backup findings
  rel="$(pdda_relpath "$file")"
  before="$(_pf_errors "$file" "$kind")"

  if [ "${before:-0}" -eq 0 ]; then
    CLEANS=$((CLEANS + 1))
    printf 'CLEAN  %s (contract satisfied)\n' "$rel"
    _pf_log "$rel" clean true "$before" "$before" 0 "contract already satisfied"
    return
  fi

  # before>0: the doc has contract violations. Without an LLM we can only flag them.
  if [ -z "$PDDA_LLM_BIN" ] || ! command -v "$PDDA_LLM_BIN" >/dev/null 2>&1; then
    WARNS=$((WARNS + 1))
    printf 'WARN   %s — %s contract error(s); set PDDA_LLM_BIN to auto-fix, else fix by hand\n' "$rel" "$before"
    _pf_log "$rel" warn false "$before" "$before" 0 "$before contract error(s); no PDDA_LLM_BIN — manual fix needed"
    return
  fi

  # gather the deterministic findings so the model knows precisely what to fix.
  if [ "$kind" = working ]; then
    findings="$(PDDA_FORMAT=text PDDA_MODE=observe PDDA_ONLY_FILE="$file" "$PDDA_SH" frontmatter 2>/dev/null; \
                PDDA_FORMAT=text PDDA_MODE=observe PDDA_ONLY_FILE="$file" "$PDDA_SH" status-table 2>/dev/null; \
                PDDA_FORMAT=text PDDA_MODE=observe PDDA_ONLY_FILE="$file" "$PDDA_SH" hardcoded-paths 2>/dev/null)"
  else
    findings="(inbox capture) $before missing/empty required frontmatter key(s) or hardcoded path(s)"
  fi

  local -a llm_args
  read -ra llm_args <<<"$PDDA_LLM_ARGS"
  [ -n "${PDDA_LLM_MODEL:-}" ] && llm_args+=(--model "$PDDA_LLM_MODEL")

  local prompt
  prompt="$RUBRIC

=== DETERMINISTIC CONTRACT VIOLATIONS ($rel) ===
$findings

=== DOCUMENT ($rel) ===
$(cat "$file")
"
  # Capture stdout regardless of the CLI's exit code — a model CLI can exit non-zero (a rate-limit
  # notice, a deprecation warning) yet still print a valid envelope; discarding it would waste the turn.
  resp="$(printf '%s' "$prompt" | "$PDDA_LLM_BIN" ${llm_args[@]+"${llm_args[@]}"} 2>/dev/null)" || true

  action="$(printf '%s\n' "$resp" | sed -n 's/^ACTION:[[:space:]]*//p' | head -1 | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"
  reason="$(printf '%s\n' "$resp" | sed -n 's/^REASON:[[:space:]]*//p' | head -1)"
  reason="$(pdda_trim "${reason:-no reason given}")"

  case "$action" in
    edit)
      newdoc="$(printf '%s\n' "$resp" | awk '/^---BEGIN-DOC---[[:space:]]*$/{f=1;next} /^---END-DOC---[[:space:]]*$/{f=0} f')"
      if [ -z "$newdoc" ]; then
        WARNS=$((WARNS + 1))
        printf 'WARN   %s — model said edit but returned no document body\n' "$rel"
        _pf_log "$rel" warn false "$before" "$before" 0 "edit action with empty doc body — no change"
        return
      fi
      backup="$(mktemp)"; cp "$file" "$backup"
      printf '%s\n' "$newdoc" > "$file"
      after="$(_pf_errors "$file" "$kind")"
      changed="$(diff "$backup" "$file" | grep -cE '^[<>]' || true)"
      # SAFETY VALVE: keep only a strictly-improving, small (mechanical) edit; else revert + warn.
      if [ "${after:-99}" -lt "${before}" ] && [ "${changed:-9999}" -le "$PREFLIGHT_MAX_EDIT_LINES" ]; then
        EDITS=$((EDITS + 1))
        printf 'EDIT   %s — %s→%s error(s), %s line(s): %s\n' "$rel" "$before" "$after" "$changed" "$reason"
        _pf_log "$rel" edit true "$before" "$after" "$changed" "$reason"
      else
        cp "$backup" "$file"   # revert from backup (preserves any pre-existing WIP)
        WARNS=$((WARNS + 1))
        printf 'WARN   %s — unsafe edit rejected (%s→%s error(s), %s line(s)); reverted\n' "$rel" "$before" "$after" "$changed"
        _pf_log "$rel" warn false "$before" "$after" "$changed" "unsafe edit reverted: $reason"
      fi
      rm -f "$backup"
      ;;
    warn)
      WARNS=$((WARNS + 1))
      printf 'WARN   %s — model declined to auto-fix: %s\n' "$rel" "$reason"
      _pf_log "$rel" warn false "$before" "$before" 0 "model declined: $reason"
      ;;
    clean)
      # model says clean but the deterministic layer disagrees — trust the deterministic layer, warn.
      WARNS=$((WARNS + 1))
      printf 'WARN   %s — %s deterministic error(s) but model reported clean\n' "$rel" "$before"
      _pf_log "$rel" warn false "$before" "$before" 0 "model reported clean but $before deterministic error(s) remain"
      ;;
    *)
      WARNS=$((WARNS + 1))
      printf 'WARN   %s — unparseable model response; no edit made\n' "$rel"
      _pf_log "$rel" warn false "$before" "$before" 0 "unparseable model response — no change"
      ;;
  esac
}

# ── target resolution ────────────────────────────────────────────────────────
# 2-WORKING active docs + every 1-INBOX/GH-*.md capture whose path appears in ROADMAP.md's queue.
main() {
  printf 'preflight-docs: run %s (model=%s, log=%s)\n' "$RUN_ID" "$MODEL_LABEL" "$(pdda_relpath "$PREFLIGHT_LOG_DIR")"
  if [ -z "$PDDA_LLM_BIN" ] || ! command -v "$PDDA_LLM_BIN" >/dev/null 2>&1; then
    printf 'preflight-docs: PDDA_LLM_BIN unset/absent — REVIEW+WARN only, no edits.\n'
  fi

  local file
  while IFS= read -r file; do
    [ -n "$file" ] || continue
    preflight_one "$file" working
  done < <(pdda_list_working_docs)

  if [ -f "$PDDA_ROADMAP" ]; then
    local rel
    while IFS= read -r rel; do
      [ -n "$rel" ] || continue
      file="$PDDA_REPO_ROOT/$rel"
      [ -f "$file" ] || continue
      preflight_one "$file" inbox
    done < <(grep -oE 'PROJECT/1-INBOX/GH-[A-Za-z0-9._-]+\.md' "$PDDA_ROADMAP" 2>/dev/null | LC_ALL=C sort -u)
  fi

  printf 'preflight-docs: done — %s edit(s), %s warn(s), %s clean.\n' "$EDITS" "$WARNS" "$CLEANS"
  # Best-effort: NEVER blocks (an LLM-driven oracle must be non-deterministic-safe, per PDDA.md).
  exit 0
}

main "$@"
