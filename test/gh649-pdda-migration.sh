#!/usr/bin/env bash
# GH-649: source ownership, isolated consumer upgrade, and retained sync-state cutover.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BOX="$(mktemp -d "${TMPDIR:-/tmp}/gh649.XXXXXX")"
[ -n "$BOX" ] && [ -d "$BOX" ] || exit 1
trap 'rm -rf "$BOX"' EXIT
export PDDA_REGISTRY="$BOX/registry.tsv" PDDA_GITPULSE_DIR="$BOX/no-git-pulse"
export PDDA_SYNC_TMP="$BOX/old-state"
unset PDDA_REPO PDDA_HOME PDDA_MANIFEST_CONF
ok() { printf 'ok - %s\n' "$*"; }
fail() { printf 'FAIL - %s\n' "$*" >&2; exit 1; }
[ "$(cd "$BOX" && bash "$ROOT/skills/vendor-stack/find-pdda.sh")" = "$ROOT" ] || fail resolver
if PDDA_REPO="$BOX" bash "$ROOT/skills/vendor-stack/find-pdda.sh" >"$BOX/invalid.log" 2>&1; then fail 'missing installer accepted'; fi
grep -q 'lacks utils/pdda/pdda-install.sh' "$BOX/invalid.log"
ok 'Forge resolves without sibling PDDA; invalid override fails'
T="$BOX/target"; mkdir "$T"; git -C "$T" init -q
bash "$ROOT/utils/pdda/pdda-install.sh" "$T" --with-startup-docs --no-register >"$BOX/install.log" 2>&1
[ -x "$T/utils/pdda/pdda.sh" ] && [ -s "$T/utils/py/pdda_gov_scan.py" ]
for p in pdda-install.sh pdda-sync.sh pdda-manifest.sh pdda-sync-manifest.conf templates; do
  [ ! -e "$T/utils/pdda/$p" ] || fail "source-only payload: $p"
done
if grep -Eq 'standalone.*source-of-truth|RELEASES.md is retired|GH-568' "$T/AGENTS.md" "$T/PROJECT/PDDA.md"; then fail 'source-only contract'; fi
grep -q 'git rev-parse --show-toplevel' "$T/.claude/skills/pdda/SKILL.md"
for p in AGENTS.md ROUTER.md GUIDING-PRINCIPLES.md ROADMAP.md CHANGELOG.md PROJECT/PDDA-ACTIVITY.jsonl PROJECT/1-INBOX/user.md; do
  printf '\nUSER-OWNED %s\n' "$p" >> "$T/$p"
done
cp -R "$T" "$BOX/before-upgrade"
bash "$ROOT/utils/pdda/pdda-install.sh" "$T" --with-startup-docs --no-register >"$BOX/upgrade.log" 2>&1
for p in AGENTS.md ROUTER.md GUIDING-PRINCIPLES.md ROADMAP.md CHANGELOG.md PROJECT/PDDA-ACTIVITY.jsonl PROJECT/1-INBOX/user.md; do
  if [ "$p" = PROJECT/PDDA-ACTIVITY.jsonl ]; then
    head -c "$(wc -c < "$BOX/before-upgrade/$p" | tr -d ' ')" "$T/$p" | cmp - "$BOX/before-upgrade/$p"
  else
    cmp "$T/$p" "$BOX/before-upgrade/$p"
  fi
done
ok 'fresh payload is complete; upgrades preserve target-owned files'
printf '# Invalid active project\n' > "$T/PROJECT/2-WORKING/invalid.md"
for mode in observe light; do
  (cd "$T" && PDDA_MODE="$mode" bash utils/pdda/pdda.sh frontmatter) >"$BOX/$mode.log" 2>&1
done
if (cd "$T" && PDDA_MODE=full bash utils/pdda/pdda.sh frontmatter) >"$BOX/full.log" 2>&1; then fail 'invalid full-mode document accepted'; fi
grep -qi 'error' "$BOX/full.log"
ok 'observe/light report; full rejects invalid document'
if PDDA_MANIFEST_CONF="$BOX/missing.conf" bash "$ROOT/utils/pdda/pdda-install.sh" "$T" --no-register >"$BOX/manifest.log" 2>&1; then fail 'missing manifest accepted'; fi
grep -q 'conf not found' "$BOX/manifest.log"
: > "$BOX/empty.conf"
if PDDA_MANIFEST_CONF="$BOX/empty.conf" bash "$ROOT/utils/pdda/pdda-install.sh" "$T" --no-register >"$BOX/empty.log" 2>&1; then fail 'empty manifest accepted'; fi
ok 'missing and empty manifests fail'
# A tiny source fixture exercises the real engine with inherited state from the old distributor.
S="$BOX/source"; U="$BOX/sync-target"; mkdir -p "$S/utils/pdda" "$S/payload" "$U/payload"
cp "$ROOT/utils/pdda/pdda-sync.sh" "$ROOT/utils/pdda/pdda-manifest.sh" "$S/utils/pdda/"
printf 'file payload/managed.txt\nfile payload/unbaselined.txt\n' > "$S/utils/pdda/pdda-sync-manifest.conf"
printf 'new upstream\n' > "$S/payload/managed.txt"
printf 'upstream other\n' > "$S/payload/unbaselined.txt"
printf 'local adaptation\n' > "$U/payload/managed.txt"
printf 'no stamp local\n' > "$U/payload/unbaselined.txt"
printf 'old removed payload\n' > "$U/payload/retired.txt"
printf '%s\t2026-09-16\tobserve\told\t0\n' "$U" > "$PDDA_REGISTRY"
slug="$(printf '%s' "$U" | tr '/ ' '__' | tr -cd 'A-Za-z0-9_.-')"
mkdir -p "$PDDA_SYNC_TMP/pdda-sync-state" "$PDDA_SYNC_TMP/pdda-sync-manifest"
printf 'payload/managed.txt\told-source-hash\n' > "$PDDA_SYNC_TMP/pdda-sync-state/$slug.tsv"
printf 'payload/managed.txt\npayload/retired.txt\n' > "$PDDA_SYNC_TMP/pdda-sync-manifest/$slug.tsv"
cp -R "$U" "$BOX/saved-payload"; cp -R "$PDDA_SYNC_TMP" "$BOX/saved-state"; cp "$PDDA_REGISTRY" "$BOX/saved-registry"
bash "$S/utils/pdda/pdda-sync.sh" push --dry-run --no-delete --allow-dirty >"$BOX/preview.log" 2>&1
diff -r "$U" "$BOX/saved-payload"
for d in pdda-sync-state pdda-sync-manifest; do diff -r "$PDDA_SYNC_TMP/$d" "$BOX/saved-state/$d"; done
cmp "$PDDA_REGISTRY" "$BOX/saved-registry"
grep -q 'diverged=2' "$BOX/preview.log"
bash "$S/utils/pdda/pdda-sync.sh" push --no-delete --allow-dirty >"$BOX/preserve.log" 2>&1
diff -r "$U" "$BOX/saved-payload"
grep -q 'payload/retired.txt' "$PDDA_SYNC_TMP/pdda-sync-manifest/$slug.tsv"
grep -q 'old-source-hash' "$PDDA_SYNC_TMP/pdda-sync-state/$slug.tsv"
if grep -q 'unbaselined' "$PDDA_SYNC_TMP/pdda-sync-state/$slug.tsv"; then fail 'invented baseline'; fi
ok 'dry-run preserves payload/state/registry; live default preserves divergence and deferred deletion'
bash "$S/utils/pdda/pdda-sync.sh" push --force-resync --no-delete --allow-dirty >"$BOX/adopt.log" 2>&1
cmp "$S/payload/managed.txt" "$U/payload/managed.txt"
backup="$(find "$PDDA_SYNC_TMP/pdda-sync-backups" -name managed.txt -type f)"
[ -n "$backup" ]; cmp "$backup" "$BOX/saved-payload/payload/managed.txt"
backup="$(find "$PDDA_SYNC_TMP/pdda-sync-backups" -name unbaselined.txt -type f)"
[ -n "$backup" ]; cmp "$backup" "$BOX/saved-payload/payload/unbaselined.txt"
# Known baseline follows an ordinary source advancement.
printf 'next upstream\n' > "$S/payload/managed.txt"
bash "$S/utils/pdda/pdda-sync.sh" push --no-delete --allow-dirty >"$BOX/advance.log" 2>&1
cmp "$S/payload/managed.txt" "$U/payload/managed.txt"
# Restore all three saved surfaces, not just payload bytes. Only fixture paths are removed.
rm -rf "$U" "$PDDA_SYNC_TMP"
cp -R "$BOX/saved-payload" "$U"; cp -R "$BOX/saved-state" "$PDDA_SYNC_TMP"; cp "$BOX/saved-registry" "$PDDA_REGISTRY"
diff -r "$U" "$BOX/saved-payload"; diff -r "$PDDA_SYNC_TMP" "$BOX/saved-state"; cmp "$PDDA_REGISTRY" "$BOX/saved-registry"
ok 'explicit adoption backs up both divergent files; normal advances work; full restore verified'
echo 'GH-649 migration checks passed'
