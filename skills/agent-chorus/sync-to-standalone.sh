#!/usr/bin/env bash
# Publish the canonical XYZ Forge package into the standalone distribution.
set -euo pipefail
export LC_ALL=C

SKILL_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_REPO="$(git -C "$SKILL_DIR" rev-parse --show-toplevel)"
MANIFEST="$SKILL_DIR/publish-manifest.tsv"
DEFAULT_DEST_REPO="$(dirname "$SOURCE_REPO")/Agent2Agent-Skill"
DEST_REPO="${AGENT2AGENT_STANDALONE_REPO:-$DEFAULT_DEST_REPO}"
MODE=preview

usage() {
  cat <<'EOF'
Usage: sync-to-standalone.sh [--preview | --apply | --check]

  --preview  Show the manifest-defined changes without writing (default).
  --apply    Copy declared files, preserve modes, and record the canonical revision.
  --check    Refuse drift and verify byte parity, modes, and the recorded revision.

Set AGENT2AGENT_STANDALONE_REPO to override the destination repository.
EOF
}

case "${1:---preview}" in
  --preview|--dry-run) MODE=preview ;;
  --apply) MODE=apply ;;
  --check) MODE=check ;;
  -h|--help) usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
esac
[ "$#" -le 1 ] || { usage >&2; exit 2; }

[ -f "$MANIFEST" ] || { echo "Missing publish manifest: $MANIFEST" >&2; exit 1; }
[ -d "$DEST_REPO/.git" ] || {
  echo "Standalone repository not found at: $DEST_REPO" >&2
  echo "Override with AGENT2AGENT_STANDALONE_REPO=/path/to/repo" >&2
  exit 1
}
DEST_REPO="$(cd -P "$DEST_REPO" && pwd)"
[ "$SOURCE_REPO" != "$DEST_REPO" ] || {
  echo "Source and destination repositories are identical; refusing to publish." >&2
  exit 1
}

SOURCE_REVISION="$(git -C "$SOURCE_REPO" rev-parse HEAD)"
if [ "$MODE" = apply ] && [ -n "$(git -C "$SOURCE_REPO" status --porcelain=v1)" ]; then
  echo "Canonical source is dirty; commit it before publishing so the recorded revision is truthful." >&2
  exit 1
fi

allowed_file="$(mktemp "${TMPDIR:-/tmp}/agent-chorus-publish-allowed.XXXXXX")"
trap 'rm -f "$allowed_file"' EXIT
printf '%s\n' .xyz-canonical-revision > "$allowed_file"

manifest_rows() {
  awk -F '\t' 'NF && $1 !~ /^#/ { print }' "$MANIFEST"
}

if ! awk -F '\t' '
  NF && $1 !~ /^#/ {
    if (NF != 3 || seen[$3]++) exit 1
  }
' "$MANIFEST"; then
  echo "Publish manifest has a malformed row or duplicate destination." >&2
  exit 1
fi

file_mode() {
  stat -c '%a' "$1" 2>/dev/null || stat -f '%Lp' "$1"
}

while IFS=$'\t' read -r declared_mode source_rel dest_rel; do
  case "$declared_mode" in 644|755) ;; *) echo "Invalid mode in manifest: $declared_mode" >&2; exit 1 ;; esac
  case "$source_rel:$dest_rel" in /*:*|*:/.*|*:*../*|*:*..|../*:*|*:*//*)
    echo "Unsafe manifest path: $source_rel -> $dest_rel" >&2; exit 1 ;;
  esac
  [ -f "$SOURCE_REPO/$source_rel" ] || { echo "Missing source file: $source_rel" >&2; exit 1; }
  printf '%s\n' "$dest_rel" >> "$allowed_file"
done < <(manifest_rows)

sort -u "$allowed_file" -o "$allowed_file"
unexpected="$(comm -23 <(git -C "$DEST_REPO" ls-files | sort -u) "$allowed_file" || true)"
if [ -n "$unexpected" ]; then
  echo "Refusing unexpected destination-only tracked files:" >&2
  while IFS= read -r path; do printf '  %s\n' "$path" >&2; done <<< "$unexpected"
  echo "Remove them deliberately or add them to publish-manifest.tsv in the canonical repository." >&2
  exit 1
fi

failures=0
while IFS=$'\t' read -r declared_mode source_rel dest_rel; do
  source_file="$SOURCE_REPO/$source_rel"
  dest_file="$DEST_REPO/$dest_rel"
  if [ -L "$dest_file" ]; then
    echo "Refusing symlink destination: $dest_rel" >&2
    exit 1
  fi
  state=UNCHANGED
  [ -f "$dest_file" ] && cmp -s "$source_file" "$dest_file" || state=UPDATE
  [ -f "$dest_file" ] && [ "$(file_mode "$dest_file")" = "$declared_mode" ] || state=UPDATE

  case "$MODE" in
    preview) printf '%-9s %s\n' "$state" "$dest_rel" ;;
    apply)
      mkdir -p "$(dirname "$dest_file")"
      cp "$source_file" "$dest_file"
      chmod "$declared_mode" "$dest_file"
      printf '%-9s %s\n' "$state" "$dest_rel"
      ;;
    check)
      if [ "$state" != UNCHANGED ]; then
        echo "DRIFT     $dest_rel" >&2
        failures=$((failures + 1))
      fi
      ;;
  esac
done < <(manifest_rows)

revision_file="$DEST_REPO/.xyz-canonical-revision"
case "$MODE" in
  preview)
    recorded="$(sed -n '1p' "$revision_file" 2>/dev/null || true)"
    [ "$recorded" = "$SOURCE_REVISION" ] && revision_state=UNCHANGED || revision_state=UPDATE
    printf '%-9s %s\n' "$revision_state" .xyz-canonical-revision
    echo "Preview only; no files copied."
    ;;
  apply)
    printf '%s\n' "$SOURCE_REVISION" > "$revision_file"
    while IFS=$'\t' read -r declared_mode source_rel dest_rel; do
      cmp -s "$SOURCE_REPO/$source_rel" "$DEST_REPO/$dest_rel" || {
        echo "Post-copy byte mismatch: $dest_rel" >&2; exit 1;
      }
      [ "$(file_mode "$DEST_REPO/$dest_rel")" = "$declared_mode" ] || {
        echo "Post-copy mode mismatch: $dest_rel" >&2; exit 1;
      }
    done < <(manifest_rows)
    echo "Published canonical revision $SOURCE_REVISION to $DEST_REPO"
    ;;
  check)
    recorded="$(sed -n '1p' "$revision_file" 2>/dev/null || true)"
    if [ "$recorded" != "$SOURCE_REVISION" ]; then
      echo "DRIFT     .xyz-canonical-revision (recorded ${recorded:-missing}, expected $SOURCE_REVISION)" >&2
      failures=$((failures + 1))
    fi
    [ "$failures" -eq 0 ] || exit 1
    echo "Standalone package matches canonical revision $SOURCE_REVISION"
    ;;
esac
