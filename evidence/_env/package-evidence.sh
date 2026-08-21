#!/usr/bin/env bash
# Package the whole evidence tree for handover.
set -u
H="$HOME/XYZ-forge"
cd "$H" || exit 1

STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="$HOME/xyz-forge-linux-bringup-evidence-$STAMP.tar.gz"

echo "=== integrity checks before packaging ==="
missing=0
for f in evidence/00-environment.md evidence/01-command-map.md evidence/FINDINGS.md \
         evidence/LINUX-SETUP.md evidence/FIRST-RUN-FRICTION.md evidence/findings-log.md repro.sh; do
  if [ -s "$f" ]; then
    printf '  ok      %-40s %s bytes\n' "$f" "$(stat -c%s "$f")"
  else
    printf '  MISSING %s\n' "$f"; missing=$((missing + 1))
  fi
done

echo
echo "=== marathon runs present ==="
for d in evidence/marathons/run-*/; do
  [ -d "$d" ] || continue
  n=$(find "$d" -type f | wc -l)
  b=$(du -sh "$d" | cut -f1)
  printf '  %-34s %5s files  %s\n' "$(basename "$d")" "$n" "$b"
done

echo
echo "=== transcripts (the primary artefact) ==="
find evidence/marathons -path '*/transcripts/*.md' | sort | sed 's/^/  /'
echo "  total transcripts: $(find evidence/marathons -path '*/transcripts/*.md' | wc -l)"

echo
echo "=== repro.sh probes ==="
bash repro.sh --list | tr '\n' ' '
echo

echo
echo "=== checksums (so nothing can be silently altered later) ==="
find evidence -type f -print0 | sort -z | xargs -0 sha256sum > evidence/SHA256SUMS.txt 2>/dev/null
echo "  wrote evidence/SHA256SUMS.txt ($(wc -l < evidence/SHA256SUMS.txt) files)"

echo
echo "=== tar ==="
tar -czf "$OUT" evidence repro.sh
rc=$?
echo "TAR_RC=$rc"
if [ "$rc" -eq 0 ]; then
  echo "  path : $OUT"
  echo "  size : $(du -h "$OUT" | cut -f1)  ($(stat -c%s "$OUT") bytes)"
  echo "  files: $(tar -tzf "$OUT" | wc -l)"
  echo
  echo "=== verify the archive actually opens ==="
  tar -tzf "$OUT" >/dev/null && echo "  archive is readable" || echo "  ARCHIVE IS CORRUPT"
fi

echo
echo "missing_required=$missing"
exit "$missing"
