#!/usr/bin/env bash
# archive-telemetry.sh — GH-30 Phase 4: extract-relay-telemetry.sh honors the transcript-root resolver,
# so it produces a feed from ARCHIVED (off-tree) transcripts and aggregates across source repos without
# colliding on <date>/<slug>. Also asserts the unset path still yields valid JSON (regression).
source "$(dirname "$0")/_setup.sh" archive-telemetry

EXTRACT="$(cd "$(dirname "$0")/.." && pwd)/utils/telemetry/extract-relay-telemetry.sh"
[ -f "$EXTRACT" ] || fail "extract-relay-telemetry.sh not found at $EXTRACT"
TODAY="$(date +%F)"

# Build an archive git repo holding TWO source repos' transcripts under the namespaced layout
# $ARCHIVE/relay-system/<repo-slug>/<date>/<thread>.md — the exact shape rtl_transcript_root writes.
ARCHIVE="$WORK/archive"; git init -q "$ARCHIVE"
mk_thread() { # <slug> <thread-name> <title> <status>
  local d="$ARCHIVE/relay-system/$1/$TODAY"; mkdir -p "$d"
  printf 'NEXT: Reviewer\nSTATUS: %s\n# %s\n\n## Log\nVERDICT: PASS approved\n' "$4" "$3" >"$d/$2.md"
}
mk_thread repo-alpha thread-a "Alpha review" Approved
mk_thread repo-beta  thread-b "Beta review"  Approved
# A same-named thread in a DIFFERENT repo — must NOT collide (namespaced by slug dir → distinct files).
mk_thread repo-alpha shared-name "Alpha shared" Approved
mk_thread repo-beta  shared-name "Beta shared"  Approved

OUT="$WORK/feed.json"
XYZ_ARCHIVE_ROOT="$ARCHIVE" bash "$EXTRACT" --from "$TODAY" --to "$TODAY" --out "$OUT" >/dev/null 2>&1 \
  || fail "extractor (archive mode) exited non-zero"
[ -f "$OUT" ] || fail "archive mode: no feed written"

python3 - "$OUT" <<'PY' || fail "archive feed did not contain both repos' threads without collision"
import json, sys
recs = json.load(open(sys.argv[1]))
titles = [r.get("title") for r in recs]
assert isinstance(recs, list) and len(recs) >= 4, f"expected >=4 records, got {len(recs)}: {titles}"
for want in ("Alpha review", "Beta review", "Alpha shared", "Beta shared"):
    assert want in titles, f"missing record from an archived repo: {want} (got {titles})"
# both same-named-but-different-repo threads survive as distinct records (no <date>/<slug> collision)
assert titles.count("Alpha shared") == 1 and titles.count("Beta shared") == 1, f"collision: {titles}"
for r in recs:
    assert r.get("health") == "green", f"expected green health for an Approved thread, got {r}"
PY
pass "archive mode: feed aggregates BOTH source repos' transcripts"
pass "archive mode: same-named threads in different repos do not collide (namespaced by slug)"

# Unset regression: a date range with NO local files → valid empty array, exit 0 (byte-for-byte path).
OUT2="$WORK/feed-empty.json"
unset XYZ_ARCHIVE_ROOT
bash "$EXTRACT" --from 1999-01-01 --to 1999-01-02 --out "$OUT2" >/dev/null 2>&1 \
  || fail "extractor (unset, empty range) exited non-zero"
python3 - "$OUT2" <<'PY' || fail "unset empty-range feed was not a valid empty JSON array"
import json, sys
recs = json.load(open(sys.argv[1]))
assert recs == [], f"expected [], got {recs}"
PY
pass "unset mode: empty date range → valid [] (default path intact)"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
