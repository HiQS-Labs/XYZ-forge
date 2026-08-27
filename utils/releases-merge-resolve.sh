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
#   5. regenerate adopted views   — ROADMAP-DASHBOARD.md / RELEASES-PREVIEW.html /
#                                  LEADERBOARD.html / LEADERBOARD.md are all rendered from
#                                  ledger state, so the resolved dump staled every one of
#                                  them (GH-272; until now each was hand-regenerated after
#                                  every concurrent merge)
#   6. stage the regenerated artifacts
#
# It deliberately does NOT commit. The merge message and whether the merge is right at all remain
# the operator's call; this only guarantees the artifacts are self-consistent before that decision.
#
# Usage:  utils/releases-merge-resolve.sh [--root <repo>]
set -euo pipefail

ROOT=""
ROOT_GIVEN=0
while [ $# -gt 0 ]; do
  case "$1" in
    --root) ROOT="${2:-}"; ROOT_GIVEN=1; shift 2 ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "releases-merge-resolve: unknown argument: $1" >&2; exit 2 ;;
  esac
done

# `--root ""` is NOT the same as no --root. Treating them alike meant a caller whose root variable
# was empty — a test fixture that failed to build, a script with a typo — silently retargeted this
# script at whatever repo the CWD happened to be in, and then REBUILT ITS LEDGER. That is not
# hypothetical: it happened on 2026-08-19 while writing test/gh57-live-merge-resolve.sh, and it
# rewrote this repo's own releases.db/releases.sql (recovered from HEAD; generation had advanced
# 6 -> 12). An explicitly-passed empty root is a caller bug, and the only safe answer is to refuse.
if [ "$ROOT_GIVEN" -eq 1 ] && [ -z "$ROOT" ]; then
  echo "releases-merge-resolve: --root was given but empty. Refusing to fall back to the current" >&2
  echo "  repository — that would operate on a ledger the caller did not name." >&2
  exit 2
fi

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

# The single header must not be LOWER than either merge parent's. Measured 2026-08-19: an operator
# who resolved by keeping the lower side's header got rc=0 here and a `check: clean` afterwards,
# with the ledger's generation counter silently REWOUND below a parent's. The advice to "keep the
# HIGHEST" was written down in the refusal above and nowhere enforced, so the one resolution that
# loses information was also the one nothing complained about. Enforced here, during a merge, where
# both parents are still reachable.
_gen_of() {  # <git-ref-or-empty> -> the dump's generation number at that ref, or nothing
  local ref="$1"
  git -C "$ROOT" show "$ref:releases.sql" 2>/dev/null \
    | sed -n 's/^-- generation: \([0-9][0-9]*\)$/\1/p' | head -1
}
if git -C "$ROOT" rev-parse --verify -q MERGE_HEAD >/dev/null 2>&1; then
  KEPT="$(sed -n 's/^-- generation: \([0-9][0-9]*\)$/\1/p' "$DUMP" | head -1)"
  OURS_GEN="$(_gen_of HEAD)"
  THEIRS_GEN="$(_gen_of MERGE_HEAD)"
  MAX_GEN="${OURS_GEN:-0}"
  [ "${THEIRS_GEN:-0}" -gt "$MAX_GEN" ] 2>/dev/null && MAX_GEN="$THEIRS_GEN"
  if [ -n "$KEPT" ] && [ "$KEPT" -lt "$MAX_GEN" ] 2>/dev/null; then
    die "releases.sql kept '-- generation: $KEPT', but this merge's parents are at
  ${OURS_GEN:-?} (HEAD) and ${THEIRS_GEN:-?} (MERGE_HEAD). Keeping a header BELOW the highest parent
  rewinds the ledger's generation counter, and every later check would still report clean — the
  divergence would be real and invisible. Set the header to $MAX_GEN and re-run."
  fi
fi

# ── 2. take either side of the derived artifacts, but DO NOT resolve them in the index yet ──────
# Staging here is what made the failure message below a lie: `git add` marks the path resolved, so
# a run that then failed the rebuild had already closed half the merge while telling the operator
# nothing was staged. The working-tree copy is replaced (the rebuild needs a sane file underneath),
# and the index stays unmerged until the rebuild AND the verify have both passed.
TOOK_SIDE=""
for f in $DERIVED; do
  if printf '%s\n' "$UNMERGED" | grep -qx "$f"; then
    # --ours is arbitrary and that is the point: both sides are stale the moment the dump merged.
    git -C "$ROOT" checkout --ours -- "$f" 2>/dev/null || true
    TOOK_SIDE="${TOOK_SIDE:+$TOOK_SIDE }$f"
    say "took either side of $f in the working tree (it is regenerated below, so the choice cannot matter)"
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

# ── 5. regenerate the adopted derived views (GH-272) ───────────────────────────────────────────
# Adoption is opt-in by presence, mirroring refresh_preview in releases_app.py: a repo that
# never baked a view (a fixture, a fresh install) is a silent no-op. A view that exists is
# stale the moment the dump merged — regenerate it from the rebuilt ledger, and if the
# generator fails, refuse and leave the merge open rather than warn-and-continue: the
# write path can afford best-effort refreshes, a merge resolver cannot (a stale view is
# exactly the hand-regen tax this step exists to end).
VIEWS="ROADMAP-DASHBOARD.md RELEASES-PREVIEW.html LEADERBOARD.html LEADERBOARD.md"
REGEN=""
for f in $VIEWS; do
  if printf '%s\n' "$UNMERGED" | grep -qx "$f"; then
    # --ours is arbitrary and that is the point: both sides are stale the moment the dump
    # merged. The working-tree copy is replaced because the generators write in place; the
    # index stays unmerged until the regen below has succeeded, same discipline as releases.db.
    git -C "$ROOT" checkout --ours -- "$f" 2>/dev/null || true
    say "took either side of $f in the working tree (it is regenerated below, so the choice cannot matter)"
    REGEN="${REGEN:+$REGEN }$f"
  elif [ -f "$ROOT/$f" ]; then
    REGEN="${REGEN:+$REGEN }$f"
  fi
done

if [ -n "$REGEN" ]; then
  say "regenerating adopted views: $REGEN"
  case " $REGEN " in
    *" ROADMAP-DASHBOARD.md "*)
      say "  -> roadmap-dashboard.sh"
      if ! ROADMAP_DASHBOARD_ROOT="$ROOT" bash "$HERE/roadmap-dashboard.sh"; then
        die "roadmap-dashboard.sh failed. The merge is left open on purpose — staging the
  stale dashboard against a rebuilt ledger would commit exactly the divergence this
  resolver exists to prevent."
      fi
      ;;
  esac
  case " $REGEN " in
    *" RELEASES-PREVIEW.html "*)
      say "  -> export_timeline.py --preview"
      if ! python3 "$HERE/timeline/export_timeline.py" --db "$ROOT/releases.db" --preview "$ROOT/RELEASES-PREVIEW.html"; then
        die "export_timeline.py --preview failed. The merge is left open on purpose; the stale
  RELEASES-PREVIEW.html has not been staged."
      fi
      ;;
  esac
  case " $REGEN " in
    *" LEADERBOARD.html "*)
      say "  -> export_timeline.py --leaderboard"
      if ! python3 "$HERE/timeline/export_timeline.py" --db "$ROOT/releases.db" --leaderboard "$ROOT/LEADERBOARD.html"; then
        die "export_timeline.py --leaderboard failed. The merge is left open on purpose; the stale
  LEADERBOARD.html has not been staged."
      fi
      ;;
  esac
  case " $REGEN " in
    *" LEADERBOARD.md "*)
      say "  -> leaderboard.sh"
      if ! LEADERBOARD_DB="$ROOT/releases.db" LEADERBOARD_OUTPUT="$ROOT/LEADERBOARD.md" bash "$HERE/leaderboard.sh"; then
        die "leaderboard.sh failed. The merge is left open on purpose; the stale LEADERBOARD.md
  has not been staged."
      fi
      ;;
  esac
fi

# ── 6. stage what the rebuild regenerated — the FIRST point at which anything is resolved ───────
for f in $TOOK_SIDE; do
  say "resolving $f in the index now that the rebuild verified clean"
done
# One `git add` for the whole handled set (codex consult: per-path adds could stage a subset
# when a later add fails), gated on existence, then a postcondition: nothing we handled may
# still be unmerged.
ADD_PATHS=""
for f in $DERIVED releases.sql $REGEN; do
  [ -f "$ROOT/$f" ] && ADD_PATHS="${ADD_PATHS:+$ADD_PATHS }$f"
done
[ -n "$ADD_PATHS" ] && git -C "$ROOT" add -- $ADD_PATHS
LEFT_UNMERGED="$(git -C "$ROOT" diff --name-only --diff-filter=U 2>/dev/null || true)"
for f in $ADD_PATHS; do
  if printf '%s\n' "$LEFT_UNMERGED" | grep -qx "$f"; then
    die "$f is still unmerged after staging — refusing to claim success. Inspect the index."
  fi
done

say "artifacts are consistent and staged. Review, then commit the merge yourself —"
say "this script deliberately does not commit."
if [ -f "$ROOT/releases.db.bak" ]; then
  say "note: releases.db.bak holds the DB that was displaced; it is untracked and safe to delete."
fi
exit 0
