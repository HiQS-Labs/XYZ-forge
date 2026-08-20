#!/usr/bin/env bash
# Copy every artefact a marathon run wrote, RAW and unedited, into
# evidence/marathons/run-<N>/artefacts/.
#
#   evidence/_env/archive-run.sh <run-number> <phase-dir-prefix> <transcript-glob>
#   e.g. evidence/_env/archive-run.sh 1 run1-ledger-exports 'marathon-r1p*'
#
# Nothing here reformats, filters or truncates. `cp -a` preserves mtimes so the
# ordering of the run is recoverable from the filesystem alone.
set -u
H="$HOME/XYZ-forge"; T="$HOME/marathon-target"
N="${1:?run number}"; PFX="${2:?phase dir prefix}"; TGLOB="${3:?transcript glob}"
DEST="$H/evidence/marathons/run-$N/artefacts"

mkdir -p "$DEST"/{relay-threads,transcripts,run-logs,preflight,events,plan}

echo "=== 1. live relay threads + escalations + state files ==="
for d in "$T/marathon-system/$PFX"*/; do
  [ -d "$d" ] || continue
  id="$(basename "$d")"
  mkdir -p "$DEST/relay-threads/$id"
  cp -a "$d"/. "$DEST/relay-threads/$id/" 2>/dev/null
  echo "  $id -> $(ls -1 "$DEST/relay-threads/$id" | tr '\n' ' ')"
done

echo
echo "=== 2. saved transcripts (raw) ==="
find "$T/relay-system" -name "$TGLOB.md" -type f -print0 2>/dev/null \
  | xargs -0 -I{} cp -a {} "$DEST/transcripts/" 2>/dev/null
ls -1 "$DEST/transcripts/" 2>/dev/null | sed 's/^/  /'

echo
echo "=== 3. per-turn shim logs (agy/codex transcripts, GH-161 persistent path) ==="
if [ -d "$T/relay-system/logs" ]; then
  cp -a "$T/relay-system/logs/." "$DEST/run-logs/" 2>/dev/null
fi
find "$T/relay-system/run-logs" "$H/relay-system/run-logs" -type f -print0 2>/dev/null \
  | xargs -0 -I{} cp -a {} "$DEST/run-logs/" 2>/dev/null
echo "  files: $(find "$DEST/run-logs" -type f | wc -l)"

echo
echo "=== 4. preflight packet ==="
# Run 1 preflighted from the HARNESS (pre-vendoring); runs 2+ from the target.
_slug="$(echo "$PFX" | grep -oE '^run[0-9]+')"
for _root in "$T" "$H"; do
  find "$_root/relay-system/preflight" -type d -name "*${_slug}*" -print0 2>/dev/null \
    | xargs -0 -I{} cp -a {} "$DEST/preflight/" 2>/dev/null
done
find "$DEST/preflight" -type f 2>/dev/null | sed "s|$DEST/preflight|  |"

echo
echo "=== 5. tick events for this run ==="
UP="$(echo "$PFX" | grep -oE '^run[0-9]+' | sed 's/^run/R/' | tr 'a-z' 'A-Z')"
echo "  event token: MARATHON-${UP}P*"
find "$T/.tick/events" -name "*MARATHON-${UP}P*" -type f -print0 2>/dev/null \
  | xargs -0 -I{} cp -a {} "$DEST/events/" 2>/dev/null
find "$T/.tick/events" -name "*marathon.complete*" -type f -print0 2>/dev/null \
  | xargs -0 -I{} cp -a {} "$DEST/events/" 2>/dev/null
echo "  event files: $(find "$DEST/events" -type f | wc -l)"

echo
echo "=== 6. the plan, briefs and capture doc that drove the run ==="
find "$T/PROJECT/2-WORKING" -path "*$(echo "$PFX" | tr 'a-z' 'A-Z' | cut -d- -f1)*" -type f -print0 2>/dev/null \
  | xargs -0 -I{} cp -a --parents {} "$DEST/plan/" 2>/dev/null
find "$DEST/plan" -type f 2>/dev/null | sed 's|.*PROJECT|  PROJECT|'

echo
echo "=== 7. the built artefacts, as they stand after this run ==="
mkdir -p "$DEST/built"
cp -a "$T/src" "$DEST/built/" 2>/dev/null
cp -a "$T/test" "$DEST/built/" 2>/dev/null
echo "  src:  $(ls -1 "$DEST/built/src" 2>/dev/null | wc -l) files"
echo "  test: $(ls -1 "$DEST/built/test" 2>/dev/null | wc -l) files"

echo
echo "=== 8. git history of the run (target repo) ==="
git -C "$T" log --format='%H%x09%ad%x09%an%x09%s' --date=iso > "$DEST/git-log.tsv" 2>/dev/null
git -C "$T" log --name-only --format='COMMIT %H %ad %s' --date=iso > "$DEST/git-log-with-files.txt" 2>/dev/null
echo "  git-log.tsv: $(wc -l < "$DEST/git-log.tsv") commits"

echo
echo "=== TOTAL ==="
echo "  files: $(find "$DEST" -type f | wc -l)"
echo "  bytes: $(du -sb "$DEST" | cut -f1)"
du -sh "$DEST"
