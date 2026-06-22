#!/usr/bin/env bash
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=utils/pdda-lib.sh
. "$HERE/pdda-lib.sh"

# Decoration → stdout in text mode, stderr in json mode, so PDDA_FORMAT=json leaves stdout a clean
# JSON-lines stream for downstream parsers (the child checks emit their JSON findings to stdout).
runner_say() { if [ "$PDDA_FORMAT" = "json" ]; then printf '%s\n' "$*" >&2; else printf '%s\n' "$*"; fi; }

CHECKS="
pdda-check-frontmatter.sh
pdda-check-status-table.sh
pdda-check-hardcoded-paths.sh
pdda-check-roadmap.sh
pdda-check-roadmap-coverage.sh
pdda-check-changelog.sh
pdda-stale-working-docs.sh
"
EXIT_CODE=0
FAILED=""

case "$PDDA_MODE" in
  observe) MODE_NOTE="observe (report-only; never blocks)" ;;
  light)   MODE_NOTE="light (reports findings incl. stale flags; does not block)" ;;
  full)    MODE_NOTE="full (on rails; errors block with a non-zero exit)" ;;
  *)       MODE_NOTE="$PDDA_MODE" ;;
esac
runner_say "PDDA run starting — mode: $MODE_NOTE"
pdda_log_activity info "pdda-run" "$PDDA_REPO_ROOT" 0 "starting deterministic PDDA run (mode=$PDDA_MODE)" "start"

for check in $CHECKS; do
  runner_say ""
  runner_say "== $check =="
  if "$HERE/$check"; then
    :
  else
    EXIT_CODE=1
    FAILED="$FAILED $check"
  fi
done

# Step 5: LLM-assisted readiness review — runs ONLY when the deterministic checks (steps 1-4) all
# passed, per PDDA.md "the LLM review should spend time only on docs that passed basic structural
# hygiene" / "deterministic failures should surface first" (Codex review r3). Self-skips too if
# PDDA_LLM_BIN is unset.
runner_say ""
runner_say "== pdda-doc-ready.sh =="
if [ "$EXIT_CODE" -ne 0 ]; then
  runner_say "skipped pdda-doc-ready.sh — fix the deterministic failures above first ($FAILED)"
  pdda_log_activity info "pdda-doc-ready" "$PDDA_REPO_ROOT" 0 "readiness review skipped — deterministic checks failed:$FAILED" "skip"
elif "$HERE/pdda-doc-ready.sh"; then
  :
else
  EXIT_CODE=1
  FAILED="$FAILED pdda-doc-ready.sh"
fi

if [ "$EXIT_CODE" -eq 0 ]; then
  runner_say ""
  runner_say "PDDA run complete: all checks passed"
  pdda_log_activity info "pdda-run" "$PDDA_REPO_ROOT" 0 "PDDA run completed successfully" "finish"
else
  runner_say ""
  runner_say "PDDA run complete: failures:$FAILED"
  pdda_log_activity error "pdda-run" "$PDDA_REPO_ROOT" 0 "PDDA run completed with failures:$FAILED" "finish"
fi

pdda_rotate_activity   # keep PROJECT/PDDA-ACTIVITY.jsonl bounded

# Mode gate: only "full" blocks (non-zero). In observe/light the child checks already exit 0, so
# EXIT_CODE is 0 here regardless; gating the aggregate too makes the contract explicit and robust.
exit "$(pdda_gated_exit "$EXIT_CODE")"
