#!/usr/bin/env bash
# pdda-stop-doc-health.sh — Stop-hook tier 2 of the doc-health system: ONE consolidated, system-wide
# doc-health scan per turn. It runs the deterministic suite — which already includes `issue-doc-sync`,
# read from the CACHED gh-state file (PDDA_ISSUE_SYNC_SOURCE=cache) so there is NO network call — and
# prints a single consolidated report of the warn/error findings.
#
# NEVER blocks: it ALWAYS exits 0, so it can never prevent a stop. The report is surfaced for
# visibility only. Wire it in .claude/settings.json as a `Stop` hook. Pairs with tier 1,
# pdda-edit-doc-hook.sh (the per-edit single-file lint).
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=utils/pdda/pdda-lib.sh
. "$HERE/pdda-lib.sh" 2>/dev/null || exit 0   # fail-open: if the lib can't load, never block the stop
PDDA="$HERE/pdda.sh"

# One deterministic, offline, non-blocking pass: cached gh-state + observe mode + no LLM (doc-ready
# self-skips when PDDA_LLM_BIN is unset). `|| true` keeps a non-zero check from ever surfacing here.
report="$(PDDA_ISSUE_SYNC_SOURCE=cache PDDA_MODE=observe PDDA_FORMAT=text PDDA_LLM_BIN="" \
  "$PDDA" run 2>&1 || true)"

findings="$(printf '%s\n' "$report" | grep -E '^(ERROR|WARN) ' || true)"
nerr="$(printf '%s\n' "$findings" | grep -c '^ERROR ' 2>/dev/null || true)"
nwarn="$(printf '%s\n' "$findings" | grep -c '^WARN ' 2>/dev/null || true)"

# Reconciliation drift is the one finding class that ends a unit of work rather than describing one:
# a doc reached 3-COMPLETED with its issue still open, or a doc declares itself ready to close. A
# script must never close an issue on its own — that is a human judgment (PDDA is recommend-never-act).
# So the hook does the one thing a script legitimately can: name the wrap that asks. Without this the
# operator sees a warn, has no prompt to act, and the drift survives to the next session.
reconcile="$(printf '%s\n' "$findings" | grep -E 'pdda-check-issue-doc-sync' || true)"
nrec="$(printf '%s\n' "$reconcile" | grep -c 'pdda-check-issue-doc-sync' 2>/dev/null || true)"

{
  printf '── PDDA doc-health (stop scan) ──\n'
  if [ "${nerr:-0}" -eq 0 ] && [ "${nwarn:-0}" -eq 0 ]; then
    printf 'all clear: no error/warn doc-health findings across the working set (issue-doc-sync from cached gh-state)\n'
  else
    printf '%s error(s), %s warn(s) — incl. issue-doc-sync against the cached gh-state file:\n' "$nerr" "$nwarn"
    printf '%s\n' "$findings"
    if [ "${nrec:-0}" -gt 0 ]; then
      printf '\n%s doc/issue reconciliation finding(s): a unit of work looks finished but is not wrapped.\n' "$nrec"
      printf 'Run /pdda-eod to reconcile the docs and close the issues (propose-then-confirm; nothing closes without your yes).\n'
    fi
  fi
} >&2

exit 0
