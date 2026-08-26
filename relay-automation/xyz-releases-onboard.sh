#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  xyz-releases-onboard.sh [target-repo] [--slug <slug>]
  xyz-releases-onboard.sh -h | --help

Onboard a repository to the Tier 2 SQLite-backed RELEASES ledger (GH-197).
Mechanizes the legacy RELEASES.md -> releases.db onboarding SOP (LTVera-Pandas ad0d816).

Steps performed:
  1. Validates preconditions (refuses if releases.db exists, requires RELEASES.md).
  2. Runs `releases init` + `releases import` from RELEASES.md.
  3. Audits .gitignore and adds `!releases.db` carve-out if a *.db-style rule is present.
  4. Prepends the app-managed banner to RELEASES.md.
  5. Reconciles MIG- temporary refs with GitHub issue URLs, refusing on collision.
  6. Runs `releases check` consistency verification.
  7. Prints the exact git commit command (never commits automatically).
USAGE
}

note() { printf '%s\n' "$*"; }
die() { printf 'xyz-releases-onboard.sh: %s\n' "$*" >&2; exit 1; }

# Resolve this script's real path without readlink -f (bash 3.2 / macOS safe).
_src="${BASH_SOURCE[0]}"
while [ -h "$_src" ]; do
  _dir="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"
  _src="$(readlink "$_src")"
  case "$_src" in /*) ;; *) _src="$_dir/$_src" ;; esac
done
SELF_DIR="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"
HARNESS_ROOT="$(cd "$SELF_DIR/.." >/dev/null 2>&1 && pwd)"

TARGET_REPO=""
SLUG=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --slug)
      [ "$#" -ge 2 ] || die "--slug requires an argument"
      SLUG="$2"
      shift 2
      ;;
    -h|--help) usage; exit 0 ;;
    -*) die "unknown option $1" ;;
    *)
      if [ -z "$TARGET_REPO" ]; then
        TARGET_REPO="$1"
        shift
      else
        die "unexpected argument $1"
      fi
      ;;
  esac
done

TARGET_REPO="${TARGET_REPO:-.}"
[ -d "$TARGET_REPO" ] || die "target repo not found: $TARGET_REPO"
TARGET_REPO="$(cd "$TARGET_REPO" >/dev/null 2>&1 && pwd -P)"

# Precondition 1: Refuse if releases.db already exists at target root.
if [ -f "$TARGET_REPO/releases.db" ]; then
  die "releases.db already exists at $TARGET_REPO (refusing to overwrite existing ledger)"
fi

# Precondition 2: Require legacy RELEASES.md.
if [ ! -f "$TARGET_REPO/RELEASES.md" ]; then
  die "RELEASES.md not found at $TARGET_REPO"
fi

# Resolve releases_app.py location.
RELEASES_APP=""
for cand in \
  "$TARGET_REPO/.xyz/utils/py/releases_app.py" \
  "$HARNESS_ROOT/utils/py/releases_app.py" \
  "$SELF_DIR/../utils/py/releases_app.py"; do
  if [ -f "$cand" ]; then
    RELEASES_APP="$cand"
    break
  fi
done
[ -n "$RELEASES_APP" ] || die "releases_app.py not found in target repo or harness"

STAGE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/xyz-onboard.XXXXXX")"
cleanup_stage() {
  if [ -n "${STAGE_DIR:-}" ] && [ -d "$STAGE_DIR" ]; then
    rm -rf "$STAGE_DIR"
  fi
}
trap cleanup_stage EXIT INT TERM HUP
git init -q "$STAGE_DIR"

note "== Step 1: Initializing ledger and importing legacy RELEASES.md =="
EFFECTIVE_SLUG="${SLUG:-$(basename "$TARGET_REPO")}"
init_args=(--slug "$EFFECTIVE_SLUG")
python3 "$RELEASES_APP" --root "$STAGE_DIR" init "${init_args[@]}" || die "releases init failed"
python3 "$RELEASES_APP" --root "$STAGE_DIR" import "$TARGET_REPO/RELEASES.md" || die "releases import failed"

note "== Step 2: Checking for tracking reference collisions =="
GH_BASE=""
ORIGIN_URL="$(git -C "$TARGET_REPO" config --get remote.origin.url 2>/dev/null || true)"
if [ -n "$ORIGIN_URL" ]; then
  if [[ "$ORIGIN_URL" =~ github\.com[:/]([^/]+)/([^/.]+)(\.git)?$ ]]; then
    GH_BASE="https://github.com/${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
  fi
fi
if [ -z "$GH_BASE" ] && [ -n "$SLUG" ]; then
  case "$SLUG" in
    */*) GH_BASE="https://github.com/$SLUG" ;;
  esac
fi

DB_PATH="$STAGE_DIR/releases.db"
MAP_ENTRIES="$(sqlite3 "$DB_PATH" "SELECT supplied_value, source_value, release_gid FROM grandfather_entries WHERE rule='tracking-issue-missing' AND disposition IS NULL ORDER BY id;" 2>/dev/null || true)"

MAP_ARGS=()
if [ -n "$MAP_ENTRIES" ]; then
  RECON_RESULT="$(python3 - "$DB_PATH" "${GH_BASE:-}" <<'PYEOF'
import sys, sqlite3, re

db_path = sys.argv[1]
gh_base = sys.argv[2] if len(sys.argv) > 2 else ""

conn = sqlite3.connect(db_path)
conn.row_factory = sqlite3.Row
rows = conn.execute("""
    SELECT ge.supplied_value, ge.source_value, ge.release_gid, r.version
    FROM grandfather_entries ge
    LEFT JOIN releases r ON r.global_id = ge.release_gid
    WHERE ge.rule = 'tracking-issue-missing' AND ge.disposition IS NULL
""").fetchall()

existing_urls = {}
for r in conn.execute("SELECT ir.url, rel.version FROM issue_refs ir JOIN releases rel ON rel.tracking_ref_id = ir.id WHERE ir.url IS NOT NULL"):
    existing_urls[r["url"]] = r["version"]

url_to_releases = {}
mig_to_url = {}
unmapped = []

for row in rows:
    mig = row["supplied_value"]
    src = (row["source_value"] or "").strip()
    ver = row["version"] or row["release_gid"]
    
    url = None
    if re.match(r"^https://github\.com/[^/]+/[^/]+/issues/\d+$", src):
        url = src
    elif src and gh_base:
        m = re.search(r"(\d+)", src)
        if m:
            url = f"{gh_base}/issues/{m.group(1)}"
    
    if url:
        mig_to_url[mig] = url
        url_to_releases.setdefault(url, []).append((ver, mig))
    else:
        unmapped.append((ver, mig, src))

collisions = []
for url, releases in url_to_releases.items():
    if len(releases) > 1:
        collisions.append((url, [r[0] for r in releases]))
    elif url in existing_urls:
        collisions.append((url, [existing_urls[url], releases[0][0]]))

if collisions:
    print("COLLISION")
    for url, vers in collisions:
        print(f"Collision on URL {url} shared by releases: {', '.join(vers)}")
    sys.exit(0)

print("OK")
for mig, url in mig_to_url.items():
    print(f"MAP:{mig}={url}")
if unmapped:
    for ver, mig, src in unmapped:
        print(f"UNMAPPED:{ver}:{mig}:{src}")
PYEOF
)"

  STATUS_LINE="$(printf '%s\n' "$RECON_RESULT" | head -1)"
  if [ "$STATUS_LINE" = "COLLISION" ]; then
    printf 'xyz-releases-onboard.sh: STOPPED — shared-tracking-URL collision detected:\n' >&2
    printf '%s\n' "$RECON_RESULT" | tail -n +2 >&2
    printf 'No issues have been filed. Fix duplicate tracking references before onboarding.\n' >&2
    exit 1
  elif [ "$STATUS_LINE" = "OK" ]; then
    while IFS= read -r line; do
      if [[ "$line" =~ ^MAP:(.*)$ ]]; then
        MAP_ARGS+=(--map "${BASH_REMATCH[1]}")
      elif [[ "$line" =~ ^UNMAPPED:(.*)$ ]]; then
        note "Note: unmapped placeholder: ${BASH_REMATCH[1]}"
      fi
    done <<< "$RECON_RESULT"
  fi
fi

note "== Step 3: Reconciling tracking references in staged ledger =="
if [ "${#MAP_ARGS[@]}" -gt 0 ]; then
  python3 "$RELEASES_APP" --root "$STAGE_DIR" reconcile "${MAP_ARGS[@]}" || die "reconcile failed"
fi
python3 "$RELEASES_APP" --root "$STAGE_DIR" check || die "staged releases check failed"

note "== Step 4: Auditing .gitignore for database carve-outs =="
GITIGNORE="$TARGET_REPO/.gitignore"
needs_carveout=0
if git -C "$TARGET_REPO" check-ignore -q releases.db 2>/dev/null; then
  needs_carveout=1
elif [ -f "$GITIGNORE" ] && grep -qE '(\*\.db|releases\.db|\*\.sqlite)' "$GITIGNORE" 2>/dev/null; then
  needs_carveout=1
fi

if [ "$needs_carveout" -eq 1 ]; then
  if [ ! -f "$GITIGNORE" ] || ! grep -Fqx '!releases.db' "$GITIGNORE" 2>/dev/null; then
    if [ -f "$GITIGNORE" ] && [ -s "$GITIGNORE" ]; then
      printf '\n# RELEASES ledger DB (app-managed; committed per-repo)\n!releases.db\n' >> "$GITIGNORE"
    else
      printf '# RELEASES ledger DB (app-managed; committed per-repo)\n!releases.db\n' > "$GITIGNORE"
    fi
    note "Appended !releases.db carve-out to .gitignore"
  else
    note "!releases.db carve-out already present in .gitignore"
  fi
else
  note "No *.db ignore rule detected in .gitignore; carve-out not required"
fi

note "== Step 5: Prepending app-managed banner to RELEASES.md =="
BANNER_TEXT="<!-- This file is app-managed (GH-32). Do not edit directly; use the releases CLI (utils/py/releases_app.py). -->"
if ! grep -Fq "<!-- This file is app-managed" "$TARGET_REPO/RELEASES.md"; then
  TMP_LEDGER="$TARGET_REPO/RELEASES.md.tmp.$$"
  {
    printf '%s\n\n' "$BANNER_TEXT"
    cat "$TARGET_REPO/RELEASES.md"
  } > "$TMP_LEDGER"
  mv "$TMP_LEDGER" "$TARGET_REPO/RELEASES.md"
  note "Prepended app-managed banner to RELEASES.md"
else
  note "App-managed banner already present in RELEASES.md"
fi

note "== Step 6: Materializing ledger into repository =="
cp -p "$STAGE_DIR/releases.db" "$TARGET_REPO/releases.db"
cp -p "$STAGE_DIR/releases.sql" "$TARGET_REPO/releases.sql"

python3 "$RELEASES_APP" --root "$TARGET_REPO" check || die "target releases check failed"

note ""
note "== Onboarding Complete =="
note "The repository has been successfully onboarded to the SQLite RELEASES ledger."
note "Run the following command to commit the new ledger artifacts:"
note ""
note "  git add releases.db releases.sql RELEASES.md .gitignore"
note "  git commit -m \"chore(releases): onboard SQLite ledger (GH-197)\""
note ""
