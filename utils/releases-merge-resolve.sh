#!/usr/bin/env bash
# releases-merge-resolve.sh — finish a merge that touched the RELEASES ledger (GH-32 / #53).
#
# The derived artifact (releases.db) conflicts on every concurrent ledger
# write, ON PURPOSE — see .gitattributes for why we did not paper over that with a merge driver.
# But resolving it correctly is several remembered steps, and the step people skip is the one that
# matters: regenerating the DB from the merged dump. Skip it and you commit a DB that disagrees with
# releases.sql, silently, and the DB is what every reader trusts at runtime.
#
# This script is that resolution, as one command:
#
#   1. refuse unless releases.sql is genuinely resolved (that file is the ONLY one needing judgment)
#   2. take either side of the derived artifacts — they are about to be regenerated anyway
#   3. `releases check --rebuild`  — dump -> DB, atomic, .bak of the displaced DB
#   4. `releases check`           — must come back clean, or we refuse and leave the merge open
#   5. stage the regenerated artifacts
#
# It deliberately does NOT commit. The merge message and whether the merge is right at all remain
# the operator's call; this only guarantees the artifacts are self-consistent before that decision.
#
# Usage:  utils/releases-merge-resolve.sh [--root <repo>]
set -euo pipefail

ROOT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --root) ROOT="${2:-}"; shift 2 ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "releases-merge-resolve: unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [ -z "$ROOT" ]; then
  ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
fi
[ -n "$ROOT" ] && [ -d "$ROOT" ] || {
  echo "releases-merge-resolve: not inside a git checkout (and no --root given)" >&2; exit 3; }

# The app is resolved from THIS SCRIPT's location, not from $ROOT: the script ships alongside the
# app, and it operates on a target repo through `--root`. Resolving it from $ROOT would break every
# use against a fixture or a sibling checkout.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP="$HERE/py/releases_app.py"
[ -f "$APP" ] || { echo "releases-merge-resolve: $APP not found — this script must ship beside utils/py/releases_app.py" >&2; exit 3; }

DUMP="$ROOT/releases.sql"
DERIVED="releases.db"

say() { printf 'releases-merge-resolve: %s\n' "$*"; }
die() { printf 'releases-merge-resolve: %s\n' "$*" >&2; exit 1; }

# ── 1. releases.sql must be resolved first — it is the only file carrying real content ──────────
UNMERGED="$(git -C "$ROOT" diff --name-only --diff-filter=U 2>/dev/null || true)"

if printf '%s\n' "$UNMERGED" | grep -qx 'releases.sql'; then
  die "releases.sql is still unresolved. That is the one file here that needs judgment — the
  derived artifacts do not. Resolve it first (union both sides' rows, keeping ONE '-- generation:'
  header), then re-run this script. See RELEASES-DB-FAQS.md."
fi

if [ -f "$DUMP" ] && grep -q '^<<<<<<< ' "$DUMP"; then
  die "releases.sql still contains conflict markers. Resolve them before rebuilding — a dump with
  markers is not a canonical dump and --rebuild would refuse or produce nonsense."
fi

[ -f "$DUMP" ] || die "no releases.sql at $DUMP — nothing to rebuild from"

# A merged dump can be syntactically fine and still carry two '-- generation:' headers, which is
# what a naive union merge produces when the two sides made a different number of writes. The
# rebuild reads only the FIRST one, so this is worth naming rather than letting it through.
GEN_HEADERS="$(grep -c '^-- generation: ' "$DUMP" || true)"
if [ "${GEN_HEADERS:-0}" -gt 1 ]; then
  die "releases.sql carries $GEN_HEADERS '-- generation:' headers; a canonical dump has exactly one.
  This is what a plain union merge leaves behind when the two branches made a different number of
  writes. Keep the HIGHEST one, delete the rest, and re-run. (The rebuild would otherwise read only
  the first and silently understate the generation.)"
fi
[ "${GEN_HEADERS:-0}" -eq 1 ] || die "releases.sql carries no '-- generation:' header — not a canonical dump"

# ── 2. take either side of the derived artifacts ────────────────────────────────────────────────
for f in $DERIVED; do
  if printf '%s\n' "$UNMERGED" | grep -qx "$f"; then
    # --ours is arbitrary and that is the point: both sides are stale the moment the dump merged.
    git -C "$ROOT" checkout --ours -- "$f" 2>/dev/null || true
    git -C "$ROOT" add -- "$f"
    say "took either side of $f (it is regenerated below, so the choice cannot matter)"
  fi
done

# ── 3. rebuild the DB from the merged dump ──────────────────────────────────────────────────────
say "rebuilding releases.db from the merged releases.sql"
if ! python3 "$APP" --root "$ROOT" check --rebuild; then
  die "check --rebuild failed. The merge is left open on purpose — nothing was staged over it.
  Read the error above: a UNIQUE constraint failure usually means the merged dump contains the same
  row twice (both sides edited one release), which is a real content conflict a union cannot settle."
fi

# ── 4. the rebuilt state must actually be clean ─────────────────────────────────────────────────
say "verifying"
if ! python3 "$APP" --root "$ROOT" check; then
  die "the rebuilt artifacts still do not check clean. Not staging them. The displaced DB is at
  releases.db.bak if you need to compare."
fi

# ── 5. stage what the rebuild regenerated ───────────────────────────────────────────────────────
for f in $DERIVED releases.sql; do
  [ -f "$ROOT/$f" ] && git -C "$ROOT" add -- "$f"
done

say "artifacts are consistent and staged. Review, then commit the merge yourself —"
say "this script deliberately does not commit."
if [ -f "$ROOT/releases.db.bak" ]; then
  say "note: releases.db.bak holds the DB that was displaced; it is untracked and safe to delete."
fi
exit 0
