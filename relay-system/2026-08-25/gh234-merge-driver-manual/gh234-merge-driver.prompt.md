# Question: Should GH-234 be built, or is it superseded by the GH-32/#53 design?

GitHub issue #234 ("Scaffold a dedicated SQLite Git merge driver for releases.db") asks for:

1. A new `releases merge-db %O %A %B` verb in `utils/py/releases_app.py` conforming to Git's custom merge driver spec.
2. Schema-aware merging: logically merge INSERTs into `roadmap_items` / `manifest_items` from both branches into the ancestor.
3. Setup script to wire `.git/config` + `.gitattributes` to route `releases.db` conflicts to the driver.
4. Graceful failure on same-row conflicting edits.

Its stated premise: releases.db is the canonical source of truth (per #169's transition away from ROADMAP.md), SQLite is binary, so Git merges fail and operators cannot hand-edit a .db.

However, the repo appears to have already decided AGAINST a merge driver, by design:

- `.gitattributes` (lines 3-36) says `releases.db` is GENERATED from `releases.sql` — a canonical GID-keyed text dump — rebuilt via `releases check --rebuild`, marked `-diff linguist-generated=true`, and that it "conflicts on every concurrent ledger write, ON PURPOSE — see .gitattributes for why we did not paper over that with a merge driver."
- `utils/releases-merge-resolve.sh` (GH-32 / #53) is the sanctioned one-command resolution: merge the text `releases.sql`, regenerate the DB from the merged dump, verify `releases check` comes back clean.

Please read for yourself before answering:
- The issue text is reproduced above (issue #234 in HiQS-Labs/XYZ-forge; you may not have network — the summary above is faithful).
- `.gitattributes`
- `utils/releases-merge-resolve.sh`
- `utils/py/releases_app.py` (skim the merge/check/rebuild-related verbs; it is ~3700 lines)
- `releases.sql` (skim structure: how mergeable is the text dump really — INSERT ordering, autoincrement ids, position-UNIQUE tables like doc_lines/legacy_lines, append-only trigger tables like op_receipts)

## What "good" looks like

An advisory answer (no writes) that makes a clear call among:
(a) Build #234 as specified (binary three-way merge driver on the .db);
(b) Close #234 as superseded — the GH-32/#53 releases.sql text-dump path already solves it, possibly with small hardening;
(c) A middle path — e.g. a merge driver on `releases.sql` (text) rather than the .db, or wiring releases-merge-resolve.sh in as the driver.

Address specifically:
- Does the #234 premise ("operators cannot resolve the conflict") still hold given releases-merge-resolve.sh exists?
- Are there failure modes the text-dump merge path does NOT cover that a schema-aware driver would (e.g. both branches INSERT rows that textually conflict in releases.sql, autoincrement id collisions, position-UNIQUE collisions)?
- What is the smallest change that makes concurrent-branch ledger writes safe and low-friction?

Advisory only. Do not modify any files.

## Inline evidence (read these instead of the repo — you have no repo access)

### .gitattributes (releases section)
# Derived RELEASES artifacts (GH-32 / #53).
#
# `releases.db` is GENERATED from `releases.sql` — the canonical GID-keyed dump — by
# `releases check --rebuild`. It is not hand-editable and carries no information the dump does not.
# (RELEASES-PREVIEW.md was a second such artifact; it was removed 2026-08-19.)
#
# -diff                  its diff is noise — it is a SQLite binary.
# linguist-generated     collapses it by default in GitHub PR review, so a one-line ledger change
#                        does not bury the actual diff under a regenerated file.
#
# WHAT IS DELIBERATELY *NOT* SET HERE: a merge driver.
#
# It is tempting to add `merge=<keep-ours>` so these stop conflicting. Measured 2026-08-19, that
# works only if the driver is DEFINED in `.git/config` (`driver = true`) — `merge=ours` alone does
# nothing, because `ours` is a merge *strategy*, not a built-in merge *driver*; the attribute is set,
# git finds no such driver, and the file conflicts anyway. Verified with `git check-attr` plus a real
# two-branch merge.
#
# We are not adding that driver, and the reason is not inertia:
#
#   1. `.git/config` is not committed, so the driver would be absent on every fresh clone — the same
#      problem already tracked as #4 for the pre-push hook. A merge that silently behaves differently
#      depending on whether someone ran an install script is worse than one that always conflicts.
#   2. More importantly, auto-resolving is the WRONG outcome. Taking either side of a derived file
#      lets the merge complete cleanly while the DB still holds only one side's rows. The rebuild is
#      then easy to forget, and the result is a DB that disagrees with the dump — precisely the
#      silent divergence #52 exists to catch. The conflict is a feature: it stops you at the moment
#      the decision has to be made.
#
# So it conflicts on purpose. The resolution is one command, not a manual merge:
#
#     utils/releases-merge-resolve.sh
#
# It takes either side of the derived file (it is about to be regenerated anyway), rebuilds from
# the merged `releases.sql`, and verifies `releases check` comes back clean. See RELEASES-DB-FAQS.md.
releases.db           -diff linguist-generated=true
harnesses.db          -diff linguist-generated=true

### utils/releases-merge-resolve.sh (full)
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

# ── 5. stage what the rebuild regenerated — the FIRST point at which anything is resolved ───────
for f in $TOOK_SIDE; do
  say "resolving $f in the index now that the rebuild verified clean"
done
for f in $DERIVED releases.sql; do
  [ -f "$ROOT/$f" ] && git -C "$ROOT" add -- "$f"
done

say "artifacts are consistent and staged. Review, then commit the merge yourself —"
say "this script deliberately does not commit."
if [ -f "$ROOT/releases.db.bak" ]; then
  say "note: releases.db.bak holds the DB that was displaced; it is untracked and safe to delete."
fi
exit 0

### releases.sql (first 80 lines, for dump structure)
-- releases-app canonical dump (GH-32 grammar: GID-keyed rows, natural keys elsewhere,
-- no integer PKs/FKs as values; rebuild renumbers deterministically)
-- generation: 161
-- table: schema_migrations
INSERT INTO schema_migrations(version, applied_at) VALUES('1', '2026-08-19T01:32:22Z');
INSERT INTO schema_migrations(version, applied_at) VALUES('2', '2026-08-19T18:55:40Z');
INSERT INTO schema_migrations(version, applied_at) VALUES('3', '2026-08-21T04:21:29Z');
INSERT INTO schema_migrations(version, applied_at) VALUES('4', '2026-08-21T04:21:29Z');
INSERT INTO schema_migrations(version, applied_at) VALUES('5', '2026-08-21T05:37:00Z');
-- table: settings
INSERT INTO settings(key, value) VALUES('enforcement', 'lenient');
INSERT INTO settings(key, value) VALUES('generation', '161');
INSERT INTO settings(key, value) VALUES('repo_slug', 'XYZ-forge');
-- table: repos
INSERT INTO repos(global_id, slug) VALUES('repo-01M0BTBRJ0PZF51EK6PCRJ20FS', 'XYZ-forge');
-- table: issue_refs
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0BTBRMJKGF9H80N3ZMF92DS', NULL, 'MIG-F1CCB6', '2026-08-19T01:32:22Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0BTBRMJJT3BG3V8F58X2NYZ', NULL, 'MIG-D7D2C4', '2026-08-19T01:32:22Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0BTBRMJS3ZFBVSD21PBVSRG', NULL, 'MIG-D248B2', '2026-08-19T01:32:22Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0BTBRMKMJ8FDX4CNF6GS6HW', NULL, 'MIG-79F036', '2026-08-19T01:32:22Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0BTBRMK2QY9TREZSEDWFB3D', NULL, 'MIG-A993B3', '2026-08-19T01:32:22Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0BTBRMKBKXK8TVCE1A4VK01', NULL, 'MIG-751A4C', '2026-08-19T01:32:22Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0BTBRMKKR87FV1G7NT6P7HT', NULL, 'MIG-7AFFE1', '2026-08-19T01:32:22Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0BTBRMKX96AHAJ56H6J14MD', NULL, 'MIG-AC68FA', '2026-08-19T01:32:22Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0DEBCZR0XW31V7WX2Q97ZBM', 'https://github.com/HiQS-Suite/XYZ-forge/issues/32', NULL, '2026-08-19T16:40:56Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0DEBJFW421C08QWT3YQNK1B', 'https://github.com/HiQS-Suite/XYZ-forge/issues/52', NULL, '2026-08-19T16:41:02Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0DEBJJNBDMZTZAQTRDC5S16', 'https://github.com/HiQS-Suite/XYZ-forge/issues/53', NULL, '2026-08-19T16:41:02Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0DEBJPEZ1Y4JR592ZQ1EYYG', 'https://github.com/HiQS-Suite/XYZ-forge/issues/54', NULL, '2026-08-19T16:41:02Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0EC2ZXN2SS1XD2N3E56GT18', 'https://github.com/HiQS-Suite/XYZ-forge/issues/77', NULL, '2026-08-20T01:20:38Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0EC52J0R1NK9DP6G8W7TZSR', 'https://github.com/HiQS-Suite/XYZ-forge/issues/79', NULL, '2026-08-20T01:21:46Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0EC53GHPRFE3DXDX66FD6BJ', 'https://github.com/HiQS-Suite/XYZ-forge/issues/80', NULL, '2026-08-20T01:21:47Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0EC54J16G48NH1808XKXPBC', 'https://github.com/HiQS-Suite/XYZ-forge/issues/81', NULL, '2026-08-20T01:21:48Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0EC55RA3XQXE1N1W2FT5A8H', 'https://github.com/HiQS-Suite/XYZ-forge/issues/82', NULL, '2026-08-20T01:21:49Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0EC56V5EAP7Y2G1PTNGVSVD', 'https://github.com/HiQS-Suite/XYZ-forge/issues/83', NULL, '2026-08-20T01:21:50Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0EC57TKJG99RDSS3JTCPDEX', 'https://github.com/HiQS-Suite/XYZ-forge/issues/84', NULL, '2026-08-20T01:21:51Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0EC58TGT6MX5XATS3QXVRRP', 'https://github.com/HiQS-Suite/XYZ-forge/issues/85', NULL, '2026-08-20T01:21:52Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0EC59Z94WCSGW269SHJW7XS', 'https://github.com/HiQS-Suite/XYZ-forge/issues/86', NULL, '2026-08-20T01:21:54Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0EC5TSKTTCWHT85VARPQ79H', 'https://github.com/HiQS-Suite/XYZ-forge/issues/87', NULL, '2026-08-20T01:22:11Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0GKP4YK2HZHWG6VZ95WGZ1G', 'https://github.com/HiQS-Suite/XYZ-forge/issues/105', NULL, '2026-08-20T22:11:54Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0GRR1QGQ1GSY9E2ZMNZRBKY', 'https://github.com/HiQS-Suite/XYZ-forge/issues/107', NULL, '2026-08-20T23:40:20Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0GT694W4DAYT0PEEAGFV4E4', 'https://github.com/HiQS-Suite/XYZ-forge/issues/108', NULL, '2026-08-21T00:05:35Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0PJK2PCN7XP266QRPJH4HGD', 'https://github.com/HiQS-Suite/XYZ-forge/issues/179', NULL, '2026-08-23T05:48:12Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0PJK8TETEJE0SBGBHCNB32M', 'https://github.com/HiQS-Suite/XYZ-forge/issues/113', NULL, '2026-08-23T05:48:18Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0PJK9866MTPW5XAFYKGTDS2', 'https://github.com/HiQS-Suite/XYZ-forge/issues/114', NULL, '2026-08-23T05:48:19Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0PJK9M9EQMJ0BE7781AQJKQ', 'https://github.com/HiQS-Suite/XYZ-forge/issues/115', NULL, '2026-08-23T05:48:19Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0PJK9ZXB0ZQTRM1YN2BRBST', 'https://github.com/HiQS-Suite/XYZ-forge/issues/168', NULL, '2026-08-23T05:48:19Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0PJKACNVA4F9Y0SV0NF8A5B', 'https://github.com/HiQS-Suite/XYZ-forge/issues/8', NULL, '2026-08-23T05:48:20Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0PJKAT3XXXFESZFY2JYDA5R', 'https://github.com/HiQS-Suite/XYZ-forge/issues/2', NULL, '2026-08-23T05:48:20Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0PJKB5WBS67QBPYQE3KY0RR', 'https://github.com/HiQS-Suite/XYZ-forge/issues/50', NULL, '2026-08-23T05:48:21Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0QMD2Y0HYJ5BZ9QD4N1CZSQ', 'https://github.com/HiQS-Labs/XYZ-forge/issues/180', NULL, '2026-08-23T15:39:07Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0QMD39GRV9ENTPQ48SAV0ZC', 'https://github.com/HiQS-Labs/XYZ-forge/issues/181', NULL, '2026-08-23T15:39:07Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0QMD3MK4JKVEVDPKTN8TYFQ', 'https://github.com/HiQS-Labs/XYZ-forge/issues/182', NULL, '2026-08-23T15:39:08Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0QMD3ZDRJJZ6J62WHZ99KDG', 'https://github.com/HiQS-Labs/XYZ-forge/issues/183', NULL, '2026-08-23T15:39:08Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0QMD4BHKF6QBGHM6NK4JM6J', 'https://github.com/HiQS-Labs/XYZ-forge/issues/184', NULL, '2026-08-23T15:39:09Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0RWZR8JVB8485B5VD3YYD4Z', 'https://github.com/HiQS-Suite/XYZ-forge/issues/174', NULL, '2026-08-24T03:28:22Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0RX41NJJ1FWP5QH3W2JB1R4', 'https://github.com/HiQS-Labs/XYZ-forge/issues/193', NULL, '2026-08-24T03:30:42Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0S1Y11H7T1XDNYTR2Z0ZYZ0', 'https://github.com/HiQS-Labs/XYZ-forge/issues/201', NULL, '2026-08-24T04:54:48Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0T6MY9VK19VW4S8YV2VV5XR', 'https://github.com/HiQS-Labs/XYZ-forge/issues/202', NULL, '2026-08-24T15:36:28Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0V21JW6D4RC7V16TJM7MHCX', 'https://github.com/HiQS-Labs/XYZ-forge/issues/222', NULL, '2026-08-24T23:35:14Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0V4GMTP63EP30G7DBNDJ81X', 'https://github.com/HiQS-Labs/XYZ-forge/issues/223', NULL, '2026-08-25T00:18:24Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0V6GTR6D53TC85FSN41ZJNY', 'https://github.com/HiQS-Labs/XYZ-forge/issues/224', NULL, '2026-08-25T00:53:27Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0V6HC4YNYHS8290SJKR5KGY', 'https://github.com/HiQS-Labs/XYZ-forge/issues/204', NULL, '2026-08-25T00:53:45Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0V6HCJ1CK7GPBT77WG45MY4', 'https://github.com/HiQS-Labs/XYZ-forge/issues/205', NULL, '2026-08-25T00:53:46Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0V6HCYHM528FAHP3NKYP4FQ', 'https://github.com/HiQS-Labs/XYZ-forge/issues/123', NULL, '2026-08-25T00:53:46Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0VAWN2HR3J7B4VYYFX33N5B', 'https://github.com/HiQS-Labs/XYZ-forge/issues/226', NULL, '2026-08-25T02:09:49Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0VAWNTVXQAVQX28EPJKTSVM', 'https://github.com/HiQS-Labs/XYZ-forge/issues/228', NULL, '2026-08-25T02:09:50Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0X6J84SYBN5TBCZFCR99FCD', 'https://github.com/HiQS-Labs/XYZ-forge/issues/232', NULL, '2026-08-25T19:32:43Z');
INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M0X6J8GQ09BVJQJBESG9METY', 'https://github.com/HiQS-Labs/XYZ-forge/issues/233', NULL, '2026-08-25T19:32:43Z');
-- table: marathons
INSERT INTO marathons(global_id, repo_gid, tracking_ref_gid, status, created_at) VALUES('mar-01M0EC2ZXJCCJ88KASQPDBTBJ9', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', 'ref-01M0EC2ZXN2SS1XD2N3E56GT18', 'planned', '2026-08-20T01:20:38Z');
-- table: releases
INSERT INTO releases(global_id, repo_gid, version, codename, status, target_date, shipped_date, description, exit_criterion, tracking_ref_gid, marathon_gid, gh_release_url, milestone, front_door_reviewed, shakedown_reviewed, license_file, baseline_count, baseline_at, baseline_source) VALUES('rel-01M0BTBRMJJHRS147J73WWGGEJ', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '0.1.0', 'Quicksilver', 'shipped', '2026-08-01', NULL, 'Python-authoritative Tier-A twins. Licensed AGPL-3.0-only (`LICENSE`) with a commercial option (`LICENSE-COMMERCIAL.md`), adopted 2026-07-29 post-ship; the pre-existing conflicting `LICENSE.md` was removed 2026-07-30 (#372).', NULL, 'ref-01M0BTBRMJKGF9H80N3ZMF92DS', NULL, 'https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/308', 'Quicksilver', 'No', 'No', 'Yes', NULL, NULL, NULL);
INSERT INTO releases(global_id, repo_gid, version, codename, status, target_date, shipped_date, description, exit_criterion, tracking_ref_gid, marathon_gid, gh_release_url, milestone, front_door_reviewed, shakedown_reviewed, license_file, baseline_count, baseline_at, baseline_source) VALUES('rel-01M0BTBRMJW4B6HWAHKW82GFGS', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '0.2.0', 'Litmus', 'shipped', '2026-09-05', '2026-08-14', 'Make the checks capable of failing. Every gate in the Litmus manifest is shown to report red against a real defect, or is explicitly downgraded to advisory — a check never observed failing is not evidence (#419). Ordered first because it is the release that makes the next one measurable. It is also what the self-improvement chain (#431) is blocked on: a Reviewer is a gate, so #419 applies to it, and its qualification gate is currently un-runnable (#428) and has only ever been measured once (#429).', '`bash test/litmus-release.sh --release-gate` exits 0. Red today by design; turning it green is what "done" means. Its own negative control is `--mutate-evidence`, which must detect a stripped declaration and an unregistered gate. NOTE the honest limit, stated in that file: the audit proves registration, declaration shape and the absence of false completion claims. It does NOT prove a control was truly observed, because `gate_inventory.py` reads a declaration authored by the same person who wrote the gate. Recorded execution of each control is deliberately out of scope for this release.', 'ref-01M0BTBRMJJT3BG3V8F58X2NYZ', NULL, NULL, 'Litmus', 'No', 'No', 'Yes', NULL, NULL, NULL);
INSERT INTO releases(global_id, repo_gid, version, codename, status, target_date, shipped_date, description, exit_criterion, tracking_ref_gid, marathon_gid, gh_release_url, milestone, front_door_reviewed, shakedown_reviewed, license_file, baseline_count, baseline_at, baseline_source) VALUES('rel-01M0BTBRMJNQM0474RQEYWKJKV', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '0.3.0', 'Nightwatch', 'shipped', '2026-10-10', '2026-08-14', 'An unattended marathon against a real target repo survives, records, and recovers. Before dispatching work, it proves the target can accept the harness write-set and preserves the local-state contract, so hostile ignore rules or linked worktrees fail clearly rather than silently splitting, leaking, or losing the run. GH-354 Phase 1 is an early Nightwatch containment prerequisite: restore clone-wide driver exclusion for linked worktrees and prove all driver pairs fail closed. A run interrupted, killed at its cap, or panicking the host leaves a durable record and recovery path instead of a clean tree full of ungated commits. Depends on Litmus. The same durability work is what makes a reflection corpus trustworthy (#431): a run with no record is invisible to any later pass over it, and the loop''s own evidence has never survived a reboot (#430).', '`bash test/nightwatch-release.sh --release-gate` exits 0. **BUILT 2026-08-11 and red by design**, exactly as Litmus''s was; turning it green is what "done" means. It has two halves because a metadata audit cannot answer this release''s question. Half A audits the frozen manifest — each entry''s gate EXISTS, is REGISTERED in `validate.sh` (a gate absent from TESTS is indistinguishable from one that passes — the #461 defect), and has a RECORDED control under `test/baselines/`; it also cross-checks that this list and the `Manifest:` line below agree, since a boundary that disagrees with itself is not frozen. Half B **executes** the lifecycle cases rather than auditing them, delegating to the suites that already drive real children and kill them rather than growing a second driver fixture here. Status on 2026-08-11: **manifest 8/8 complete; lifecycle 5 passing, 0 NOT COVERED — GOALPOST MET.** The last gap was the hostile-target write-set case, closed by #514, which was filed while executing this release and deliberately NOT admitted to the manifest (discovery is not admission); it belongs to the lifecycle list because the exit criterion always named that case — what was missing was a suite driving it. That lane also corrected its own premise: the pre-fix tree does not dispatch a turn first, it dies at the render''s `git add` with an unhandled `CalledProcessError` traceback, so the discriminating assertion is the absence of that traceback rather than the absence of a dispatch. Its own negative control is `--mutate-evidence` (34/0), which unregisters a gate and deletes a recorded control in a fixture copy, requires both to be detected, and re-checks the unmutated inputs green in the same run so an always-red detector cannot pass for one. Honest limit, inherited from Litmus: Half A reads a declaration and a filename and cannot know a recorded control was honestly recorded; Half B is what narrows that, and is why this criterion is a command that kills children rather than a checklist.', 'ref-01M0BTBRMJS3ZFBVSD21PBVSRG', NULL, NULL, 'Nightwatch', 'No', 'No', 'Yes', NULL, NULL, NULL);
INSERT INTO releases(global_id, repo_gid, version, codename, status, target_date, shipped_date, description, exit_criterion, tracking_ref_gid, marathon_gid, gh_release_url, milestone, front_door_reviewed, shakedown_reviewed, license_file, baseline_count, baseline_at, baseline_source) VALUES('rel-01M0BTBRMJ4GE194HWHJJS2AV2', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '0.4.0', 'Plumbline', 'draft', '2026-11-14', NULL, 'Assisted reflection and a bounded self-improvement loop, measured before either is trusted. The reflection pipeline turns durable Nightwatch records into proposals (`proposals-sink.sh` gains its first production caller) and is graded against external ground truth — the 49 human-filed findings from the two rebalance-OS marathons (#405/#406) — for recall and precision. Ships a committed benchmark and a recorded go/no-go; "not worth automating yet" is a passing result, per #431''s own Phase 2 exit criterion. Operator sign-off stays manual. Depends on Nightwatch.', NULL, 'ref-01M0BTBRMKMJ8FDX4CNF6GS6HW', NULL, 'https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/431', 'Plumbline', 'No', 'No', 'Yes', NULL, NULL, NULL);
INSERT INTO releases(global_id, repo_gid, version, codename, status, target_date, shipped_date, description, exit_criterion, tracking_ref_gid, marathon_gid, gh_release_url, milestone, front_door_reviewed, shakedown_reviewed, license_file, baseline_count, baseline_at, baseline_source) VALUES('rel-01M0BTBRMKEYXGKWR47HX3S72J', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '0.5.0', 'Lantern', 'draft', '2026-12-12', NULL, 'When the harness fails, the information needed to act already exists inside it — make it say so. Not "add checks": every case was already detected, and some were then described wrongly (a stack trace, a fabricated path, a success exit code, silence). Scope is one epic, deliberately narrow, and deliberately NOT Nightwatch: that milestone owns run lifecycle "even when lifecycle code emits a misleading message" (see the scope boundary above), and none of Lantern''s cases violates a lifecycle invariant — they violate the legibility of a failure whose lifecycle handling was already correct. All four members were found in one afternoon during Nightwatch wave 3, which halted three times at zero paid-turn cost; each halt was avoidable from information the system already held. Depends on nothing; independent of Plumbline.', '`bash test/lantern-release.sh --release-gate` exits 0. **NOT BUILT.** Writing it precedes fixing any member, which is the Litmus and Nightwatch ordering and the reason both releases could tell a finished entry from a claimed one. Two halves, the established shape: Half A audits the frozen manifest — each entry''s gate EXISTS, is REGISTERED in `validate.sh`, has a RECORDED control under `test/baselines/`, and the list agrees with the `Manifest:` line below. Half B **executes** #499''s four phases rather than auditing them, since every one of them is a message an operator either receives or does not: a `relay-drive` launch preflight that refuses before spending, a gate refusal that states its real reason, a launcher exit code that survives its wrapper, and a change-impact report. **#358 Phase 2 is the one member with no executable half, and the criterion is written around that rather than pretending otherwise:** it is satisfied by a RECORDED transcript of a real CI failure under `test/baselines/`, and it must NOT be satisfiable by a disposition written in advance — that issue''s own capture doc forbids pre-committing one, and an exit criterion that accepted a pre-written verdict would launder exactly the thing #419 exists to prevent. Its own negative control is `--mutate-evidence`, which must unregister a gate, delete a recorded control, and substitute a pre-dated disposition for a real transcript — detecting all three, and re-checking the unmutated inputs green in the same run so an always-red detector cannot pass for one.', 'ref-01M0BTBRMK2QY9TREZSEDWFB3D', NULL, 'https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/499', 'not created yet. The original reason — "#499 is unmilestoned by design while Nightwatch is the active goalpost" — expired when Nightwatch reached RC on 2026-08-11, and is kept here only so a reader does not act on it as if current. Creating it is a live decision, not a formality: **neither member would be enumerable by it as things stand** (#499 is unmilestoned, and #358 keeps its Nightwatch milestone deliberately), so the milestone would join nothing until #499 is assigned. The `Manifest:` line below is this release''s authoritative scope either way.', 'No', 'No', 'Yes', NULL, NULL, NULL);
INSERT INTO releases(global_id, repo_gid, version, codename, status, target_date, shipped_date, description, exit_criterion, tracking_ref_gid, marathon_gid, gh_release_url, milestone, front_door_reviewed, shakedown_reviewed, license_file, baseline_count, baseline_at, baseline_source) VALUES('rel-01M0BTBRMKX17AQN7Q11A0YCD7', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '0.6.0', 'Meter', 'draft', '2026-09-26', NULL, 'XYZ can be handed to a stranger: an unauthenticated clone reaches a documented entry path and exercises a supported happy path with no private context, from a sanitized, secret-scanned tree. RE-SCOPED 2026-08-15 by explicit operator decision — originally the metering release; that work moved intact to Sundown (0.8.0). Deliverable is a sanitized fresh-history clone pushed to https://github.com/HiQS-Suite/XYZ-forge. Compacted 2026-08-20 with the RELEASES.md block; full prose in that file''s git history.', 'bash test/meter-release.sh --release-gate exits 0. NOT BUILT — written first, before any sanitization (the Litmus/Nightwatch ordering). Half A AUDITS the launch artifact: single-commit sanitized clone at the declared path; CHANGELOG.md byte-identical; .tick/, relay-system/, temp/ absent; PROJECT/ = PDDA scaffold + retained Meter example only; both LICENSE files present and consistent; secret-scan result names tool version and exact commit. Half B EXECUTES the stranger''s path: a credential-less clone of the published commit completes one supported happy path with nothing author-machine-local. Negative control --mutate-evidence: plant a private path, remove CHANGELOG.md, leave a relay-system/ behind — detect all three, re-check unmutated inputs green in the same run. RED on arrival.', 'ref-01M0BTBRMKBKXK8TVCE1A4VK01', NULL, 'https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/563', 'Meter', 'Yes', 'Yes', 'Yes', NULL, NULL, NULL);
INSERT INTO releases(global_id, repo_gid, version, codename, status, target_date, shipped_date, description, exit_criterion, tracking_ref_gid, marathon_gid, gh_release_url, milestone, front_door_reviewed, shakedown_reviewed, license_file, baseline_count, baseline_at, baseline_source) VALUES('rel-01M0BTBRMKKDB5TCEXT75BTFJY', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '0.7.0', 'Ballast', 'shipped', '2026-09-12', '2026-08-18', 'Post-launch hardening: **the launched repository holds up under a stranger''s first run and an outside contributor''s first push.** Every member was found the same way — by pointing the launch machinery at its own published output: the first fresh-clone runs of the public repository produced a different failing set each time (#15), a push gate that does not travel with clones got worse the moment the repo went public (#4), and the kernel''s own event log can drop events on the concurrent path the kernel exists to coordinate (#14). Ballast exists because publication moved the failure surface from "our machines" to "everyone else''s", and nothing in the shipped tree tests that surface. Builds on Meter''s publication; depends on nothing unshipped.', '`bash test/ballast-release.sh --release-gate` exits 0. **NOT BUILT — writing it is Ballast''s first task, before any member is fixed** (the Litmus/Nightwatch/Meter ordering; a release whose exit criterion is authored after its members cannot tell a finished entry from a claimed one). Two halves, the established shape. **Half A audits the frozen manifest:** each entry''s gate EXISTS, is REGISTERED in `validate.sh` (a gate absent from TESTS is indistinguishable from one that passes — the #461 defect), has a RECORDED control under `test/baselines/`, and the list agrees with the `Manifest-Members:` line below in both directions. **Half B EXECUTES the stranger''s path rather than auditing it:** (1) a fresh unauthenticated clone from the published commit runs the documented entry path ten consecutive times in parallel with zero failing runs — a contention warning is allowed only where it names the contended suite per #15''s contract; (2) a fresh clone with no gate installed is surfaced as ungated, in-band, on the documented first-run path, naming the one-command install (#4) — and with the gate installed, a would-be-red push is refused (a push cannot be locally refused with no hook at all; that mechanical limit is stated here rather than papered over, and #4''s fix makes the ungated state loud instead of invisible); (3) a writer killed mid-`appendEvent` loses no event, and no reader ever observes a partial `.jsonl` (#14). RED on arrival by design. Its own negative control is `--mutate-evidence`: in a fixture copy it must unregister a gate, delete a recorded control, and forge a passing stranger-run record; detect all three; and re-check the unmutated inputs green in the same run so an always-red detector cannot pass for one. **SHIPPED 2026-08-18.** `XYZ_BALLAST_STRANGER_RUNS=10 test/ballast-release.sh --release-gate` executed for real against a fresh disposable clone (`~/xyz-disposable/xyz-stranger-clone`): exit 0. Half A: 4 of 4 manifest members complete (#14, #15, #4, #3 — gate/registration/control/CLOSED-issue all confirmed). Half B: 4 of 4 passing (B1: 10/10 consecutive parallel runs with zero failures; B2a: ungated clone warning in-band; B2b: forced-red push refusal; B3: atomic-append cross-process stress case clean) — **GOALPOST MET**.', 'ref-01M0BTBRMKKR87FV1G7NT6P7HT', NULL, NULL, 'Ballast', 'No', 'No', 'Yes', NULL, NULL, NULL);
INSERT INTO releases(global_id, repo_gid, version, codename, status, target_date, shipped_date, description, exit_criterion, tracking_ref_gid, marathon_gid, gh_release_url, milestone, front_door_reviewed, shakedown_reviewed, license_file, baseline_count, baseline_at, baseline_source) VALUES('rel-01M0BTBRMKFFDNYP04S68XWAPF', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '0.8.0', 'Sundown', 'draft', '2026-10-17', NULL, 'Retire the twelve frozen Bash twins. Three steps, in order: (1) sweep for real `XYZ_PYTHON=0` usage — if nothing sets it, the fallback is already dead in practice; (2) re-vendor every fleet `.xyz/` copy onto the Python lane (`xyz-sync.sh list` is the worklist); (3) delete the twins and retire the GH-308 edit-guard, keeping only its no-new-Bash half (GH-551). Not before steps 1-2: the vendored fleet still runs the Bash path, and `XYZ_PYTHON=0` is the documented rollback. Depends on nothing in Meter.', '**NOT WRITTEN.** Required before this release starts, per the ordering Litmus and Nightwatch both used and Meter is repeating — the gate is built first and arrives RED, because a release whose exit criterion is authored after its members cannot tell a finished entry from a claimed one.', 'ref-01M0BTBRMKX96AHAJ56H6J14MD', NULL, NULL, 'Sundown', 'No', 'No', 'Yes', NULL, NULL, NULL);
INSERT INTO releases(global_id, repo_gid, version, codename, status, target_date, shipped_date, description, exit_criterion, tracking_ref_gid, marathon_gid, gh_release_url, milestone, front_door_reviewed, shakedown_reviewed, license_file, baseline_count, baseline_at, baseline_source) VALUES('rel-01M0DEBCZP752VYW4A3N2Q3YS9', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '0.7.1', 'Bulwark', 'shipped', '2026-08-20', '2026-08-19', 'Patch release on Ballast: the RELEASES ledger survives a git merge. A SQLite DB cannot be merged by git, so releases.sql is the canonical GID-keyed dump and the only artifact that crosses a merge boundary. Three gaps closed — clone artifacts are no longer mutated by a read-only check (#52), the .gitattributes contract and a one-command resolver pin how a conflicted dump is settled (#53), and check --rebuild now REFUSES a merge-mangled dump by name instead of throwing a traceback (#54). RELEASES-PREVIEW.md was removed: a Mac DB viewer and GitHub Projects cover the whole-ledger read.', 'test/gh32-releases-artifacts.sh, test/gh53-releases-merge-resolve.sh, test/gh54-merged-dump-refusals.sh and releases_app.py check all exit 0, AND this release''s own merge into development resolves releases.sql without a hand-edit.', 'ref-01M0DEBCZR0XW31V7WX2Q97ZBM', NULL, NULL, 'Bulwark', 'No', 'No', 'Yes', NULL, NULL, NULL);
