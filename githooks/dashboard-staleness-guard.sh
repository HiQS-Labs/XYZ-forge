#!/usr/bin/env bash
# dashboard-staleness-guard.sh — refuse a push whose range writes the roadmap ledger but not the
# dashboard (GH-243, the enforcement half of GH-169 item 3).
#
# WHY: since the ROADMAP_SOURCE=releases flip, ROADMAP-DASHBOARD.md is the ONLY human-readable
# view of the roadmap ledger — the DB is what every tool trusts, and nothing else re-renders the
# view. A ledger write (releases.sql / releases.db) that ships without a dashboard regeneration
# publishes a web/agent view that silently disagrees with the data under it.
#
# WHERE IT RUNS: called by githooks/pre-push with the same "<local_sha> <remote_sha>" ref pairs
# the gate already parses — the push boundary is this repo's one wired, branch-independent
# enforcement point (GH-549); a pre-commit hook would need a second stub wiring that does not
# exist. Local commits stay free and ungated on purpose.
#
# SCOPE: applies only when the repo being pushed declares ROADMAP_SOURCE=releases in .pdda-mode.
# Legacy-mode repos and branches predating the flip are untouched. A new branch (all-zero remote
# sha) has no computable range; it falls through to the full gate like every other unclassifiable
# push — this guard only ever ADDS a refusal, never replaces the gate.
#
# Usage: dashboard-staleness-guard.sh <repo_root> <local_sha> <remote_sha> [<local_sha> <remote_sha>...]
# Exit:  0 ok (guard passed or not applicable) · 1 refuse the push · 2 usage.
set -uo pipefail

REPO="${1:-}"; shift || true
[ -n "$REPO" ] && [ -d "$REPO" ] || { echo "dashboard-staleness-guard: usage: <repo_root> <local_sha> <remote_sha>..." >&2; exit 2; }

grep -q "ROADMAP_SOURCE=releases" "$REPO/.pdda-mode" 2>/dev/null || exit 0

touched_ledger=0
touched_dashboard=0
while [ "$#" -ge 2 ]; do
  local_sha="$1"; remote_sha="$2"; shift 2
  case "$remote_sha" in
    ''|0000000000000000000000000000000000000000) continue ;;   # new branch: no range to inspect
  esac
  git -C "$REPO" cat-file -e "${remote_sha}^{commit}" 2>/dev/null || continue
  while IFS= read -r path; do
    case "$path" in
      releases.sql|releases.db) touched_ledger=1 ;;
      ROADMAP-DASHBOARD.md)     touched_dashboard=1 ;;
    esac
  done < <(git -C "$REPO" diff --no-renames --name-only "$remote_sha" "$local_sha" 2>/dev/null)
done

if [ "$touched_ledger" -eq 1 ] && [ "$touched_dashboard" -eq 0 ]; then
  # GH-257 Task 4: check whether regenerating ROADMAP-DASHBOARD.md currently produces drift or no diff
  drift_detected=0
  if [ -f "$REPO/utils/roadmap-dashboard.sh" ]; then
    if ! bash "$REPO/utils/roadmap-dashboard.sh" --check >/dev/null 2>&1; then
      drift_detected=1
    fi
  else
    drift_detected=1
  fi

  if [ "$drift_detected" -eq 1 ]; then
    cat >&2 <<'EOF'
dashboard-staleness-guard: REFUSING the push — this range writes the roadmap ledger
(releases.sql / releases.db) without regenerating ROADMAP-DASHBOARD.md, so the human-readable
view would ship stale against the data under it (GH-243 / GH-169 item 3).

Fix (one command, then commit the result into the same push):
    bash utils/roadmap-dashboard.sh && git add ROADMAP-DASHBOARD.md && git commit -m "docs: regenerate roadmap dashboard"

Bypass (deliberately loud, e.g. a WIP branch): git push --no-verify
EOF
  else
    cat >&2 <<'EOF'
dashboard-staleness-guard: REFUSING the push — this range writes the roadmap ledger
(releases.sql / releases.db) without modifying ROADMAP-DASHBOARD.md, but regenerating the
dashboard produces NO diff (GH-243 / GH-257).

This happens when a parked row was dropped by the renderer (e.g. malformed raw_text).
To diagnose:
    bash utils/roadmap-dashboard.sh
and inspect stderr for warnings on dropped rows. Correct the row with:
    releases roadmap update --issue-num <N> --raw-text "- **GH-<N> · <title>** ..."
then regenerate and commit:
    bash utils/roadmap-dashboard.sh && git add releases.db releases.sql ROADMAP-DASHBOARD.md && git commit -m "docs: fix roadmap row and regenerate dashboard"

Bypass (deliberately loud, e.g. a WIP branch): git push --no-verify
EOF
  fi
  exit 1
fi
exit 0
