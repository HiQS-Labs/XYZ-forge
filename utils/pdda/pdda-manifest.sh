#!/usr/bin/env bash
# Shared PDDA distribution-manifest expander. SOURCED by both install.sh (initial copy) and
# pdda-sync.sh (steady-state push) so the synced file set has exactly ONE definition — the
# declaration in pdda-sync-manifest.conf beside this file (GUIDING-PRINCIPLES #4).
#
# No side effects on source: pure read + stdout. Safe to source under `set -euo pipefail`.

# pdda_manifest_conf_path <hq_root> — resolve the manifest .conf (override with PDDA_MANIFEST_CONF).
pdda_manifest_conf_path() {
  printf '%s\n' "${PDDA_MANIFEST_CONF:-$1/utils/pdda/pdda-sync-manifest.conf}"
}

# pdda_manifest_expand <hq_root>
#   Print the repo-relative file set the manifest resolves to, one per line, sorted + unique.
#   `dir` roots are expanded with `git ls-files` (fallback: pruned `find`); `exclude` globs are
#   applied last. Returns non-zero only on a missing/empty conf so callers can guard.
pdda_manifest_expand() {
  local root="$1"
  local conf; conf="$(pdda_manifest_conf_path "$root")"
  [ -f "$conf" ] || { printf 'pdda-manifest: conf not found: %s\n' "$conf" >&2; return 1; }

  local -a includes=() excludes=()
  local kind arg line
  while IFS= read -r line || [ -n "$line" ]; do
    # strip leading/trailing whitespace; skip blank + comment lines
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [ -z "$line" ] && continue
    case "$line" in \#*) continue ;; esac
    kind="${line%%[[:space:]]*}"
    arg="${line#"$kind"}"
    arg="${arg#"${arg%%[![:space:]]*}"}"   # ltrim the value
    arg="${arg%/}"                          # normalize trailing slash on dir paths
    case "$kind" in
      dir)
        # git-tracked files under this dir; fall back to a pruned find for a non-git canonical repo.
        local f
        if git -C "$root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
          while IFS= read -r f; do includes+=("$f"); done < <(git -C "$root" ls-files -- "$arg")
        else
          while IFS= read -r f; do
            f="${f#./}"; includes+=("$f")
          done < <( cd "$root" && find "$arg" \( -name .git -o -name node_modules \) -prune -o -type f -print )
        fi
        ;;
      file)  includes+=("$arg") ;;
      exclude) excludes+=("$arg") ;;
      *) printf 'pdda-manifest: ignoring unknown directive %q in %s\n' "$kind" "$conf" >&2 ;;
    esac
  done < "$conf"

  # Emit, applying excludes (glob) last; sort -u for a stable, dedup'd set.
  local p ex skip
  for p in "${includes[@]}"; do
    skip=0
    for ex in "${excludes[@]}"; do
      # shellcheck disable=SC2254  # intentional glob match against the exclude pattern
      case "$p" in $ex) skip=1; break ;; esac
    done
    [ "$skip" -eq 0 ] && printf '%s\n' "$p"
  done | LC_ALL=C sort -u
}
