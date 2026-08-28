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

SYS_TMP="$(cd -P "${TMPDIR:-/tmp}" 2>/dev/null && pwd -P)" || SYS_TMP="/tmp"
GUARD_ROOT=""
GUARD_ROOT_PHYS=""
GUARD_INODE=""
GUARD_DEV=""

get_dev_inode() {
  local target="$1"
  # GNU coreutils spells --format as -c and uses -f for --file-system; BSD spells --format as -f.
  # Probing BSD-first therefore SUCCEEDS on Linux for the wrong reason: `-f` is accepted, "%d %i"
  # is read as a filename, and stdout gets a multi-line filesystem block instead of "<dev> <inode>".
  # The caller's "${x%% *}" then yields an empty device and the guard reports an identity mismatch
  # between two identical inodes. `-c` is not a BSD flag, so probing GNU-first fails cleanly there.
  stat -c "%d %i" "$target" 2>/dev/null || stat -f "%d %i" "$target" 2>/dev/null || true
}

cleanup_guard() {
  local exit_code=$?
  [ -n "$GUARD_ROOT" ] || return "$exit_code"
  [ -e "$GUARD_ROOT" ] || return "$exit_code"
  if [ -L "$GUARD_ROOT" ]; then
    echo "dashboard-staleness-guard: refusing cleanup — guard root is a symlink" >&2
    exit 1
  fi
  local cur_phys
  cur_phys="$(cd -P "$GUARD_ROOT" 2>/dev/null && pwd -P)" || {
    echo "dashboard-staleness-guard: failed to resolve guard root physical path" >&2
    exit 1
  }
  if [ -n "$GUARD_ROOT_PHYS" ] && [ "$cur_phys" != "$GUARD_ROOT_PHYS" ]; then
    echo "dashboard-staleness-guard: refusing cleanup — guard root path drifted ($cur_phys != $GUARD_ROOT_PHYS)" >&2
    exit 1
  fi
  local cur_dev_inode
  cur_dev_inode="$(get_dev_inode "$cur_phys")"
  local cur_dev="${cur_dev_inode%% *}"
  local cur_inode="${cur_dev_inode##* }"
  if [ -z "$GUARD_DEV" ] || [ -z "$GUARD_INODE" ] || [ -z "$cur_dev" ] || [ -z "$cur_inode" ] || \
     [ "$cur_dev" != "$GUARD_DEV" ] || [ "$cur_inode" != "$GUARD_INODE" ]; then
    echo "dashboard-staleness-guard: refusing cleanup — guard root identity mismatch ($cur_dev:$cur_inode != $GUARD_DEV:$GUARD_INODE)" >&2
    exit 1
  fi
  case "$cur_phys" in
    "$SYS_TMP"/*) rm -rf "$cur_phys" || exit 1 ;;
    *) echo "dashboard-staleness-guard: refusing cleanup of non-descendant $cur_phys" >&2; exit 1 ;;
  esac
  return "$exit_code"
}
trap cleanup_guard EXIT INT TERM

GUARD_ROOT="$(mktemp -d "$SYS_TMP/staleness-guard.XXXXXX")"
[ -n "$GUARD_ROOT" ] || { echo "dashboard-staleness-guard: mktemp failed" >&2; exit 1; }

GUARD_ROOT_PHYS="$(cd -P "$GUARD_ROOT" 2>/dev/null && pwd -P)" || GUARD_ROOT_PHYS=""
[ -n "$GUARD_ROOT_PHYS" ] && [ -d "$GUARD_ROOT_PHYS" ] || { echo "dashboard-staleness-guard: failed to resolve guard root" >&2; exit 1; }
case "$GUARD_ROOT_PHYS" in
  "$SYS_TMP"/*) ;;
  *) echo "dashboard-staleness-guard: guard root $GUARD_ROOT_PHYS is not a resolved descendant of $SYS_TMP" >&2; exit 1 ;;
esac

init_dev_inode="$(get_dev_inode "$GUARD_ROOT_PHYS")"
GUARD_DEV="${init_dev_inode%% *}"
GUARD_INODE="${init_dev_inode##* }"
if [ -z "$GUARD_DEV" ] || [ -z "$GUARD_INODE" ]; then
  echo "dashboard-staleness-guard: failed to establish guard root device/inode identity" >&2
  exit 1
fi

while [ "$#" -ge 2 ]; do
  local_sha="$1"; remote_sha="$2"; shift 2
  case "$remote_sha" in
    ''|0000000000000000000000000000000000000000) continue ;;   # new branch: no range to inspect
  esac
  git -C "$REPO" cat-file -e "${remote_sha}^{commit}" 2>/dev/null || continue

  touched_ledger=0
  touched_dashboard=0
  while IFS= read -r path; do
    case "$path" in
      releases.sql|releases.db) touched_ledger=1 ;;
      ROADMAP-DASHBOARD.md)     touched_dashboard=1 ;;
    esac
  done < <(git -C "$REPO" diff --no-renames --name-only "$remote_sha" "$local_sha" 2>/dev/null)

  if [ "$touched_ledger" -eq 1 ] && [ "$touched_dashboard" -eq 0 ]; then
    # GH-257 Task 4: check whether regenerating ROADMAP-DASHBOARD.md produces drift or no diff.
    # Run the diagnosis against a commit-pinned temporary projection of local_sha inside the
    # private GUARD_ROOT_PHYS so uncommitted working-tree modifications do not skew the classification.
    TMP_PROJ="$GUARD_ROOT_PHYS/proj-$local_sha"
    mkdir -p "$TMP_PROJ"

    drift_detected=1
    if git -C "$REPO" archive "$local_sha" 2>/dev/null | tar -x -C "$TMP_PROJ" 2>/dev/null \
       && [ -f "$TMP_PROJ/utils/roadmap-dashboard.sh" ]; then
      if bash "$TMP_PROJ/utils/roadmap-dashboard.sh" --check >/dev/null 2>&1; then
        drift_detected=0
      else
        drift_detected=1
      fi
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
done

exit 0
