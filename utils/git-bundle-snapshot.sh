#!/usr/bin/env bash
#
# git-bundle-snapshot.sh — write a rotated full-repo git bundle snapshot, so a
# repo-wipe recovery (GH-177 happened twice) is one command instead of an evening:
#   git clone ~/Backups/xyz-3-agents-swarm/<newest>.bundle recovered/
#
# A bundle is a single file containing every ref + object (`git bundle create
# --all`); unlike the working tree or reflog it survives `.git` being shredded,
# and unlike a remote it also captures local-only branches.
#
# Usage:
#   utils/git-bundle-snapshot.sh            # snapshot this repo, keep newest 14
#   KEEP=30 utils/git-bundle-snapshot.sh    # override rotation depth
#   BUNDLE_DIR=/path utils/git-bundle-snapshot.sh
#
# Intended cron wiring (daily, 09:00):
#   0 9 * * * /usr/bin/env bash "/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/utils/git-bundle-snapshot.sh" >> "$HOME/Backups/xyz-3-agents-swarm/snapshot.log" 2>&1
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
repo_name="$(basename -- "$repo_root")"
keep="${KEEP:-14}"
bundle_dir="${BUNDLE_DIR:-$HOME/Backups/$repo_name}"

git -C "$repo_root" rev-parse --git-dir >/dev/null || {
  echo "git-bundle-snapshot: $repo_root is not a git repo" >&2
  exit 1
}

mkdir -p "$bundle_dir"
stamp="$(date +%Y%m%d-%H%M%S)"
bundle_path="$bundle_dir/$repo_name-$stamp.bundle"
tmp_path="$bundle_path.tmp"

# Write to a .tmp path and only promote it to the real name AFTER verify passes,
# so a create/verify killed mid-run (OOM, disk full) can't leave a corrupt
# .bundle that the rotation logic later counts as a good backup (GH-233 review).
trap 'rm -f -- "$tmp_path"' EXIT
git -C "$repo_root" bundle create "$tmp_path" --all
git -C "$repo_root" bundle verify "$tmp_path" >/dev/null
mv -f -- "$tmp_path" "$bundle_path"
trap - EXIT
echo "git-bundle-snapshot: wrote $bundle_path ($(du -h "$bundle_path" | cut -f1 | tr -d ' '))"

# Rotate: keep the newest $keep bundles, delete strictly older ones.
count=0
while IFS= read -r old; do
  count=$((count + 1))
  if [ "$count" -gt "$keep" ]; then
    rm -f -- "$old"
    echo "git-bundle-snapshot: rotated out $old"
  fi
done < <(ls -1t "$bundle_dir"/"$repo_name"-*.bundle 2>/dev/null)
