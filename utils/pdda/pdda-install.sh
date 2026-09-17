#!/usr/bin/env bash
set -euo pipefail

# PDDA installer — drop the Project-Driven Doc Automation surface into ANOTHER repo in a clean,
# ready-to-use "zero state". Run it from a clone of XYZ Forge:
#
#   ./utils/pdda/pdda-install.sh /path/to/your-repo
#
# It copies the shipped runtime — exactly the set declared in utils/pdda/pdda-sync-manifest.conf and
# expanded by utils/pdda/pdda-manifest.sh (the SAME manifest pdda-sync.sh pushes, so the install set
# and the steady-state push set can never drift) — creates the PROJECT/** lifecycle tree, and
# SYNTHESISES blank seed ledger/changelog/activity/mode files. It never copies this repo's own
# ROADMAP/CHANGELOG/activity content, so the target starts empty but immediately valid. Existing
# target files are never clobbered unless you pass --force.
#
# Re-running it upgrades in place. If the target predates the utils/pdda/ subfolder (runtime kept
# FLAT under utils/), it auto-migrates to the canonical layout: removes the duplicate PDDA-owned flat
# files and repoints old-path references. Disable with --no-migrate.
#
# This is the executable form of utils/pdda/PDDA-INSTALL.md; keep the two in lockstep.

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Shared manifest expander — the synced runtime set is declared ONCE in
# utils/pdda/pdda-sync-manifest.conf and consumed by both this installer and pdda-sync.sh (push), so
# the two never drift (GUIDING-PRINCIPLES #4). New runtime files under utils/pdda/ ship automatically.
# shellcheck source=utils/pdda/pdda-manifest.sh
. "$SOURCE_DIR/utils/pdda/pdda-manifest.sh"

FORCE=0
WITH_STARTUP_DOCS=0
MIGRATE=1
REGISTER=1
MODE="observe"
QUAD="off"
TARGET=""

# Per-user, per-device install registry — records WHERE each copy was installed and on which source
# commit. Lives in $HOME (never in the repo, so it can't leak into the eventually-public repo). Not
# portable by design. A future sync layer reads this to find targets that are behind. Override the
# path with PDDA_REGISTRY; skip writing it with --no-register.
PDDA_REGISTRY="${PDDA_REGISTRY:-${XDG_CONFIG_HOME:-$HOME/.config}/pdda/registry.tsv}"

# Optional multi-device rollup: if git-pulse (a separate, GitHub-backed activity-sync tool) is present, the
# installer also drops a PATH-NORMALIZED projection of the registry (repo name + date + source commit +
# mode; never absolute paths) into git-pulse's repo under pdda/, and git-pulse's own sync carries it across
# devices — no new sync infrastructure. Best-effort and fail-open: absent git-pulse → silently skipped, the
# install is unaffected. The LOCAL registry above stays the source of truth. The git-pulse checkout is
# auto-detected (see publish_registry_projection): explicit PDDA_GITPULSE_DIR wins, else git-pulse's own
# config.sh `sync_repo_dir`, else a small candidate list. Set PDDA_GITPULSE_DIR to a nonexistent path to
# disable, or use --no-register (same gate). Empty default = "auto-detect" (resolution lives in the fn).
PDDA_GITPULSE_DIR="${PDDA_GITPULSE_DIR:-}"

usage() {
  cat <<'USAGE'
PDDA installer — install Project-Driven Doc Automation into a target repo.

Usage:
  ./utils/pdda/pdda-install.sh [options] <target-repo-dir>

Options:
  --force                Overwrite existing seed files (ROADMAP.md, CHANGELOG.md, .pdda-mode,
                         blank.md placeholders) and startup-doc scaffolds. Runtime scripts +
                         PROJECT/PDDA.md are always refreshed. Never touches your real PROJECT/** docs.
  --with-startup-docs    Also install the operator read-order scaffold: ROUTER.md (written from
                         utils/pdda/templates/ROUTER.target.md — the canonical repo's own ROUTER.md is NOT
                         copied), AGENTS.md, GUIDING-PRINCIPLES.md, and the /pdda re-orient skill.
                         The three docs are create-only: an existing file is kept, not overwritten
                         (use --force). The /pdda skill is runtime and always refreshed.
                         When ROUTER.md is written, a post-install self-check asserts that every
                         *.sh it names exists in the target; a failure exits non-zero (a PDDA
                         template bug). A ROUTER.md that was kept is never validated.
  --no-migrate           Skip auto-migration of a pre-utils/pdda/ (flat) layout. By default, when the
                         target keeps the runtime flat under utils/, install removes the duplicate
                         PDDA-owned flat files and repoints old-path references to utils/pdda/.
  --no-register          Skip recording this install in the per-user registry
                         (default: $XDG_CONFIG_HOME/pdda/registry.tsv or ~/.config/pdda/registry.tsv;
                         override with PDDA_REGISTRY). The registry is machine-local and never committed.
                         Also skips the multi-device git-pulse projection (see below).
  --mode <m>             Initial .pdda-mode: observe (default) | light | full.
  --quad                 Enable the opt-in Quad Concepts layer (seeds .pdda-quad=on). Off by default;
                         orthogonal to --mode. Requires a "## Quad Concepts" section (1-4 bullets) on
                         plan docs; see PROJECT/PDDA.md. Opt a doc out with quad_exempt: true.
  -h, --help             This message.

What gets installed (zero state):
  utils/pdda/{pdda.sh,pdda-lib.sh,pdda-doc-ready.sh,pdda-catchup.sh,pdda-gh-refresh.sh}   (runtime, refreshed)
  PROJECT/PDDA.md                                            (the contract, refreshed)
  PROJECT/{1-INBOX,2-WORKING,3-COMPLETED,4-MISC}/blank.md    (lifecycle buckets)
  ROADMAP.md CHANGELOG.md RELEASES.md PROJECT/PDDA-ACTIVITY.jsonl .pdda-mode .pdda-quad   (blank seeds, create-only)
  .gitignore += PROJECT/PDDA-ACTIVITY.jsonl .pdda-gh-state.tsv  (churning runtime state)

It also records the install in a per-user, machine-local registry (~/.config/pdda/registry.tsv) so
pdda-sync.sh knows where every copy lives. The registry is never committed. --no-register skips it.

If git-pulse (a GitHub-backed activity-sync tool) is present, the installer additionally drops a
path-normalized projection of the registry (repo name + date + source commit + mode; never absolute
paths) into git-pulse's repo under pdda/, and git-pulse's own sync carries that status across your
devices. Best-effort and fail-open — absent git-pulse it is silently skipped. The git-pulse checkout is
auto-detected (git-pulse's config.sh sync_repo_dir, then common locations); set PDDA_GITPULSE_DIR to
override or to a nonexistent path to disable. The local registry remains the source of truth. If the
resolved checkout has uncommitted changes under pdda/, or is behind its own upstream as of its last
fetch, a one-line warning names the path — the write to disk still always succeeds either way.

After install it runs `utils/pdda/pdda.sh run` in the target so you see it working immediately.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --force) FORCE=1; shift ;;
    --with-startup-docs) WITH_STARTUP_DOCS=1; shift ;;
    --no-migrate) MIGRATE=0; shift ;;
    --no-register) REGISTER=0; shift ;;
    --mode) MODE="${2:-}"; shift 2 ;;
    --quad) QUAD="on"; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) printf 'install.sh: unknown option %q\n\n' "$1" >&2; usage >&2; exit 2 ;;
    *) if [ -z "$TARGET" ]; then TARGET="$1"; shift; else printf 'install.sh: unexpected argument %q\n' "$1" >&2; exit 2; fi ;;
  esac
done

case "$MODE" in observe|light|full) ;; *) printf 'install.sh: --mode must be observe|light|full (got %q)\n' "$MODE" >&2; exit 2 ;; esac

if [ -z "$TARGET" ]; then
  printf 'install.sh: missing target repo directory.\n\n' >&2
  usage >&2
  exit 2
fi

# Resolve the target (must exist as a directory).
if [ ! -d "$TARGET" ]; then
  printf 'install.sh: target %q is not a directory. Create it (and `git init`) first.\n' "$TARGET" >&2
  exit 1
fi
TARGET="$(cd "$TARGET" && pwd)"

if [ "$TARGET" = "$SOURCE_DIR" ]; then
  printf 'install.sh: refusing to install into the pdda source repo itself.\n' >&2
  exit 1
fi

# True if TARGET is inside a git work tree. Uses `git rev-parse`, not a literal `.git` directory test,
# so it also handles worktrees and submodules (where `.git` is a FILE) and an external GIT_DIR.
is_git_repo() { git -C "$TARGET" rev-parse --is-inside-work-tree >/dev/null 2>&1; }

if ! is_git_repo; then
  printf 'install.sh: note — %q is not a git repo. PDDA works best under version control (changelog\n' "$TARGET" >&2
  printf '            freshness uses git history). Consider `git init` there.\n' >&2
fi

say() { printf '%s\n' "$*"; }

HELD_LOCKS=""
cleanup_advisory_locks() {
  local entry owner
  while IFS= read -r entry; do
    [ -n "$entry" ] || continue
    owner="$(cat "$entry/pid" 2>/dev/null || true)"
    if [ -z "$owner" ] || [ "$owner" = "$$" ]; then
      rm -rf "$entry" 2>/dev/null || true
    fi
  done <<EOF
$HELD_LOCKS
EOF
}
trap cleanup_advisory_locks EXIT INT TERM HUP

remember_lock() {
  HELD_LOCKS="${HELD_LOCKS}${HELD_LOCKS:+
}$1"
}

forget_lock() {
  local needle="$1" kept="" entry
  while IFS= read -r entry; do
    [ -n "$entry" ] || continue
    [ "$entry" = "$needle" ] && continue
    kept="${kept}${kept:+
}$entry"
  done <<EOF
$HELD_LOCKS
EOF
  HELD_LOCKS="$kept"
}

advisory_lock_path() {
  local target="$1" dir stem
  dir="$(dirname "$target")"
  stem="$(basename "$target")"
  case "$stem" in *.*) stem="${stem%.*}" ;; esac
  printf '%s/%s.lock' "$dir" "$stem"
}

acquire_advisory_lock() {
  local target="$1" label="$2" lockdir holder deadline empty_streak
  lockdir="$(advisory_lock_path "$target")"
  deadline=$(( $(date +%s) + 30 ))
  empty_streak=0
  while :; do
    if mkdir -p "$(dirname "$lockdir")" 2>/dev/null && mkdir "$lockdir" 2>/dev/null; then
      printf '%s\n' "$$" > "$lockdir/pid" 2>/dev/null || true
      remember_lock "$lockdir"
      ADVISORY_LOCK_DIR="$lockdir"
      return 0
    fi
    if [ "$(date +%s)" -ge "$deadline" ]; then
      say "$label: lock $lockdir held too long; proceeding without lock"
      ADVISORY_LOCK_DIR=""
      return 1
    fi
    holder="$(cat "$lockdir/pid" 2>/dev/null || true)"
    if [ -z "$holder" ]; then
      empty_streak=$((empty_streak + 1))
      if [ "$empty_streak" -ge 20 ]; then
        rm -rf "$lockdir" 2>/dev/null || true
        empty_streak=0
      fi
      sleep 0.1 2>/dev/null || sleep 1
      continue
    fi
    empty_streak=0
    if kill -0 "$holder" 2>/dev/null; then
      sleep 0.1 2>/dev/null || sleep 1
      continue
    fi
    rm -rf "$lockdir" 2>/dev/null || true
  done
}

release_advisory_lock() {
  local lockdir="${1:-}" owner
  [ -n "$lockdir" ] || return 0
  owner="$(cat "$lockdir/pid" 2>/dev/null || true)"
  if [ -z "$owner" ] || [ "$owner" = "$$" ]; then
    rm -rf "$lockdir" 2>/dev/null || true
  fi
  forget_lock "$lockdir"
}

run_with_advisory_lock() {
  local target="$1" label="$2"
  shift 2
  if ! acquire_advisory_lock "$target" "$label"; then
    return 0
  fi
  local lockdir="$ADVISORY_LOCK_DIR" rc
  "$@"
  rc=$?
  release_advisory_lock "$lockdir"
  return "$rc"
}
# Copy a runtime file verbatim, always (runtime is the shipped surface, safe to refresh).
copy_runtime() {  # <relpath>
  local rel="$1" src="$SOURCE_DIR/$1" dst="$TARGET/$1"
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  say "  runtime   $rel"
}

# Portable in-place edit (BSD/GNU `sed -i` differ; avoid both via temp + mv). The temp lives BESIDE
# the target — no $TMPDIR dependency and the mv stays on one filesystem (atomic, no cross-device copy).
sed_inplace() {  # <file> <sed-args...>
  local f="$1"; shift
  local tmp="$f.pdda-mig.$$"
  sed "$@" "$f" > "$tmp" && mv "$tmp" "$f"
}

# Collapse a pre-utils/pdda/ FLAT install into the canonical subfolder layout. The runtime is already
# refreshed under utils/pdda/ by the time this runs, so here we (1) delete the now-duplicate PDDA-owned
# flat files and (2) repoint old flat-path references — never touching the repo's own utils/ files,
# the dated CHANGELOG, or the activity log. Idempotent: a no-op once there is no flat utils/pdda.sh.
migrate_flat_layout() {
  [ "$MIGRATE" -eq 1 ] || return 0
  [ -f "$TARGET/utils/pdda.sh" ] || return 0   # no flat entry point => nothing to migrate

  say ""
  say "Migrating pre-utils/pdda/ flat layout:"

  local f
  for f in utils/pdda.sh utils/pdda-lib.sh utils/pdda-doc-ready.sh utils/pdda-catchup.sh \
           utils/PDDA-INSTALL.md PDDA-INSTALL.md; do
    if [ -f "$TARGET/$f" ]; then
      rm -f "$TARGET/$f"
      say "  remove    $f (now in utils/pdda/)"
    fi
  done
  if [ -d "$TARGET/utils/pdda-phase-out" ]; then
    rm -rf "$TARGET/utils/pdda-phase-out"
    say "  remove    utils/pdda-phase-out/ (legacy)"
  fi

  # Repoint old flat-path references. Candidate files come from `git ls-files` (tracked only — skips
  # node_modules/.venv and other untracked trees, and keeps the scan bounded); a non-git target falls
  # back to a pruned `find`. Either way we skip the target's own utils/ tree (never our files to edit),
  # the dated CHANGELOG, and machine logs — and only rewrite a file that actually contains an old path.
  local rel repointed=0
  while IFS= read -r -d '' rel; do
    rel="${rel#./}"
    case "$rel" in
      utils/*|node_modules/*|.venv/*|vendor/*|CHANGELOG.md|*.jsonl) continue ;;
    esac
    grep -Iq -e 'utils/pdda\.sh' -e 'utils/pdda-lib\.sh' -e 'utils/pdda-doc-ready\.sh' \
      -e 'utils/pdda-catchup\.sh' -e 'utils/PDDA-INSTALL\.md' "$TARGET/$rel" 2>/dev/null || continue
    sed_inplace "$TARGET/$rel" \
      -e 's|utils/pdda\.sh|utils/pdda/pdda.sh|g' \
      -e 's|utils/pdda-lib\.sh|utils/pdda/pdda-lib.sh|g' \
      -e 's|utils/pdda-doc-ready\.sh|utils/pdda/pdda-doc-ready.sh|g' \
      -e 's|utils/pdda-catchup\.sh|utils/pdda/pdda-catchup.sh|g' \
      -e 's|utils/PDDA-INSTALL\.md|utils/pdda/PDDA-INSTALL.md|g'
    say "  repoint   $rel"
    repointed=$((repointed + 1))
  done < <(
    if is_git_repo; then
      git -C "$TARGET" ls-files -z
    else
      ( cd "$TARGET" && find . \( -name .git -o -name node_modules -o -name .venv -o -path './utils' \) -prune \
          -o -type f -print0 )
    fi
  )
  [ "$repointed" -eq 0 ] && say "  (no old-path references found)"
  say "  migration done — review with: git -C \"$TARGET\" diff"
}

# Install a startup-doc scaffold: copy <src-relpath> to <dst-relpath>, but only if the destination is
# absent (or when --force). This is deliberately NOT copy_runtime. copy_runtime's "safe to refresh"
# premise holds for utils/pdda/** — files PDDA owns and a target never edits. It does not hold for the
# startup docs, which `--help` itself calls a scaffold: the target owns them after the first install,
# and refreshing them verbatim silently destroys the operator's work (GH-25).
# Set by seed_from_source: 1 if it wrote the destination, 0 if it kept an existing file. The
# post-install self-check reads this — it must only validate a file the installer actually WROTE.
SEEDED_LAST=0

seed_from_source() {  # <src-relpath> [<dst-relpath>]
  local src_rel="$1" dst_rel="${2:-$1}"
  local src="$SOURCE_DIR/$src_rel" dst="$TARGET/$dst_rel"
  SEEDED_LAST=0
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] && [ "$FORCE" -ne 1 ]; then
    say "  keep      $dst_rel (exists; --force to overwrite)"
    return
  fi
  cp "$src" "$dst"
  SEEDED_LAST=1
  say "  scaffold  $dst_rel"
}

# ------------------------------------------------------------------------------------------------
# Post-install self-check (GH-23 P2)
#
# Assert that every `*.sh` path named in the ROUTER.md we just WROTE resolves to a file that exists in
# the target. This single assertion would have caught the whole of GH-23 at install time: for months
# `--with-startup-docs` copied the canonical repo's own router into every target, telling agents to run
# `install.sh` and `utils/pdda/pdda-sync.sh` — neither of which a target has. No check saw it, because
# `pdda-check-governance` only scans `.md` references (that gap is GH-23 P3).
#
# Two boundaries, both learned the hard way:
#
#   1. Only validate a file we WROTE. If --with-startup-docs kept the operator's existing ROUTER.md,
#      that file is theirs; failing their install over their own scripts would be indefensible.
#   2. Run it against the written artifact, not the source template. P1's first draft of
#      utils/pdda/templates/ROUTER.target.md reintroduced the exact bug it exists to fix (it told targets a local
#      edit "is overwritten on the next `pdda-sync.sh push`"), and only an assertion on the OUTPUT
#      caught it. Checking the input would have passed.
#
# Bare filenames (no directory component) fall back to a repo-wide basename search, mirroring
# `_pdda_gov_resolve_ref` in pdda.sh — a doc may legitimately say `pdda.sh` meaning `utils/pdda/pdda.sh`.
SELFCHECK_FAILED=0

# Scoped to the docs this installer WROTE this run — never to a doc it kept. A repo's own ROUTER.md or
# AGENTS.md may name any script it likes (a private deploy helper, a script added after install); that
# is the operator's business, not ours to validate. We assert only over output we are responsible for.
#
# GH-23 P3: originally this checked ROUTER.md alone, and so sailed straight past a dead `install.sh` in
# the GUIDING-PRINCIPLES.md we scaffold into every target. The router was never special — any doc we
# write can name a script we do not ship.
assert_written_doc_refs() {  # <dst-relpath>
  local doc_rel="$1" doc="$TARGET/$doc_rel" ref missing=0 found p
  [ -f "$doc" ] || return 0

  say "  self-check  every *.sh named in the written $doc_rel exists in the target"
  while IFS= read -r ref; do
    [ -n "$ref" ] || continue
    case "$ref" in
      */*) [ -e "$TARGET/$ref" ] && continue ;;
      # literal basename match, not `find -name "$ref"` (which globs): today the extractor below emits
      # no glob metachars, but matching literally removes the reliance on that and keeps this in step
      # with _pdda_gov_resolve_ref. Process substitution (not a pipe) so `break` cannot leave `find` in
      # a pipefail pipeline under `set -euo pipefail`. First match wins. GH-34.
      *)   found=""
           while IFS= read -r -d '' p; do
             if [ "${p##*/}" = "$ref" ]; then found="$p"; break; fi
           done < <(find "$TARGET" -not -path '*/.git/*' -print0 2>/dev/null)
           [ -n "$found" ] && continue ;;
    esac
    printf '  ERROR  %s names "%s" but no such file exists in %s\n' "$doc_rel" "$ref" "$TARGET" >&2
    missing=$((missing + 1))
    # `\b` after the suffix, or `foo.shtml` is harvested as `foo.sh` and the installer fails a target
    # over a script nobody ever mentioned.
  done < <(grep -oE '[A-Za-z0-9_./-]+\.sh\b' "$doc" | LC_ALL=C sort -u)

  if [ "$missing" -gt 0 ]; then
    {
      printf '\n  %s dead script reference(s) in the %s this installer just wrote.\n' "$missing" "$doc_rel"
      printf '  This is a bug in PDDA'"'"'s source doc for %s, not in your repo.\n' "$doc_rel"
      printf '  The target is installed and usable; its startup docs are misleading. Please report it.\n\n'
    } >&2
    return 1
  fi
  say "  self-check  ok"
  return 0
}

# Create a seed file only if absent (or when --force). Reads content from stdin.
seed_file() {  # <relpath>  (content on stdin)
  local rel="$1" dst="$TARGET/$1"
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] && [ "$FORCE" -ne 1 ]; then
    say "  keep      $rel (exists; --force to overwrite)"
    cat >/dev/null   # drain stdin
    return
  fi
  cat > "$dst"
  say "  seed      $rel"
}

# Ensure PDDA's churning runtime state is gitignored in the target (the activity log and the gh-issue
# -state cache are regenerated output, not source — tracking them makes every run a dirty diff).
# Idempotent, so installs AND upgrades converge: adds each entry if missing, and untracks any that a
# pre-gitignore install already committed (a no-op for entries that were never tracked).
ensure_runtime_ignored() {
  local gi="$TARGET/.gitignore" entry
  for entry in "PROJECT/PDDA-ACTIVITY.jsonl" ".pdda-gh-state.tsv"; do
    if [ -f "$gi" ] && grep -qxF "$entry" "$gi"; then
      say "  keep      .gitignore ($entry already ignored)"
    else
      # Guarantee a trailing newline before appending so we never glue onto the prior last line.
      if [ -f "$gi" ] && [ -n "$(tail -c1 "$gi" 2>/dev/null)" ]; then printf '\n' >> "$gi"; fi
      printf '%s\n' "$entry" >> "$gi"
      say "  ignore    .gitignore += $entry"
    fi
    if is_git_repo && git -C "$TARGET" ls-files --error-unmatch "$entry" >/dev/null 2>&1; then
      if git -C "$TARGET" rm --cached --quiet "$entry" >/dev/null 2>&1; then
        say "  untrack   $entry (was tracked; git rm --cached)"
      fi
    fi
  done
}

write_registry_projection() {
  local out="$1"
  local tmp="$out.tmp.$$"
  if {
       printf '# PDDA install status (normalized to repo name; absolute paths intentionally omitted).\n'
       printf '# Maintainer LLM on another machine: a clone usually keeps the origin repo name as its folder,\n'
       printf '# so locate it by exact name first:\n'
       printf '#   find ~ -type d -name "<repo>" -exec test -d "{}/.git" \\; -print 2>/dev/null\n'
       printf '# If that returns nothing (repo cloned into a renamed folder), fall back to a fuzzy search:\n'
       printf '#   find ~ -type d -iname "*<repo>*" -exec test -d "{}/.git" \\; -print 2>/dev/null\n'
       printf '# repo\tlast_install_utc\tmode\tsource_commit\tstartup_docs\n'
       awk -F'\t' 'BEGIN{OFS="\t"} /^#/{next} NF==0{next} {n=split($1,a,"/"); $1=a[n]; print}' "$PDDA_REGISTRY"
     } > "$tmp" 2>/dev/null && mv "$tmp" "$out"; then
    say "  publish   pdda/registry-$dev.tsv (normalized; git-pulse carries it)"
  else
    rm -f "$tmp" 2>/dev/null
    say "  (git-pulse publish failed — projection unchanged)"
  fi
}

# Publish a path-normalized projection of the registry into git-pulse's sync repo when git-pulse is present,
# so PDDA install status rolls up across devices with NO new sync infrastructure (git-pulse's own sync
# carries the file). Normalized = col 1 absolute path -> bare repo name; the projection never contains a
# filesystem path. Best-effort / fail-open (GUIDING-PRINCIPLES #6: never break an install); the local
# registry stays the source of truth (#4) and keeps absolute paths because pdda-sync.sh cd's into them.
# Rewritten in full every run, so the projection can't drift from the registry. A maintainer-LLM on another
# machine locates a repo by name (the file header carries the exact find command), not by a path we ship.
publish_registry_projection() {
  local gp="$PDDA_GITPULSE_DIR" dev cfg out tmp cand
  cfg="${XDG_CONFIG_HOME:-$HOME/.config}/git-pulse/config.sh"
  # Resolve the git-pulse checkout when no explicit override was given: ask git-pulse's own config where
  # its sync repo lives (sync_repo_dir), then fall back to a small candidate list. Keeps PDDA in step with
  # git-pulse's actual layout instead of assuming the old hardcoded ~/.config/git-pulse/repo default.
  if [ -z "$gp" ]; then
    gp="$( ( . "$cfg" 2>/dev/null; printf '%s' "${sync_repo_dir:-}" ) )"
    if [ -z "$gp" ] || [ ! -d "$gp/.git" ]; then
      for cand in "${XDG_CONFIG_HOME:-$HOME/.config}/git-pulse/repo" "$HOME/git-pulse-sync"; do
        [ -d "$cand/.git" ] && { gp="$cand"; break; }
      done
    fi
  fi
  [ -d "$gp/.git" ] || return 0   # no git-pulse checkout found -> nothing to roll up
  # Reuse git-pulse's own device id so PDDA and pulse files key on the same device; else fall back to host.
  dev="$( ( . "$cfg" 2>/dev/null; printf '%s' "${device_id:-}" ) )"
  [ -n "$dev" ] || dev="$(hostname -s 2>/dev/null || printf 'unknown-device')"
  mkdir -p "$gp/pdda" 2>/dev/null || { say "  (git-pulse pdda/ not writable — publish skipped)"; return 0; }
  out="$gp/pdda/registry-$dev.tsv"
  run_with_advisory_lock "$out" "git-pulse projection" write_registry_projection "$out"
  warn_stale_projection_destination "$gp"
  return 0
}

# Best-effort: the projection write above can succeed on disk while never reaching origin, if the
# git-pulse checkout itself isn't being committed/pushed by whatever job owns that (GH-28 — a real
# device was found with 5 rows sitting uncommitted for over a week because its git-pulse sync job had
# stalled, and publish_registry_projection reported success the whole time). This never fetches (no
# network call on every install) — "behind" is only as fresh as the checkout's own last fetch/pull —
# and never fails the install; it just makes the drift visible instead of silent.
warn_stale_projection_destination() {
  local gp="$1" dirty upstream counts behind
  git -C "$gp" rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0
  dirty="$(git -C "$gp" status --porcelain -- pdda 2>/dev/null || true)"
  if [ -n "$dirty" ]; then
    say "  (warn: git-pulse projection at $gp/pdda is uncommitted — it won't reach origin, or your other devices, until something commits + pushes that checkout)"
  fi
  upstream="$(git -C "$gp" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)" || return 0
  [ -n "$upstream" ] || return 0
  counts="$(git -C "$gp" rev-list --left-right --count "HEAD...$upstream" 2>/dev/null)" || return 0
  behind="${counts#*$'\t'}"
  case "$behind" in
    ''|*[!0-9]*) return 0 ;;
  esac
  if [ "$behind" -gt 0 ]; then
    say "  (warn: git-pulse checkout at $gp is $behind commit(s) behind $upstream as of its last fetch — the pdda projection there may be stale until it's pulled/pushed)"
  fi
}

write_install_registry_row() {
  local reg="$1" target="$2" row="$3"
  local tmp="$reg.tmp.$$"
  if awk -F'\t' -v t="$target" '$1 != t' "$reg" > "$tmp" 2>/dev/null; then
    if printf '%s\n' "$row" >> "$tmp" && mv "$tmp" "$reg"; then
      say "  register  $target -> $reg"
      publish_registry_projection   # best-effort multi-device rollup; never fails the install
    fi
  else
    rm -f "$tmp"
    say "  (registry write failed — skipped)"
  fi
}

# Record this install in the per-user, per-device registry (one row per target, latest wins). This is
# the data pdda-sync.sh reads to find copies that are behind — recording source_commit means that layer
# needs no schema change. Machine-local; never committed. Best-effort: a failure here never fails the
# install. On success it also publishes the multi-device projection (publish_registry_projection).
register_install() {
  [ "$REGISTER" -eq 1 ] || return 0
  local reg="$PDDA_REGISTRY" dir
  dir="$(dirname "$reg")"
  mkdir -p "$dir" 2>/dev/null || { say "  (registry dir $dir not writable — skipped)"; return 0; }

  local ts src_commit sdocs row tmp
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  src_commit="$(git -C "$SOURCE_DIR" rev-parse --short HEAD 2>/dev/null || printf 'unknown')"
  sdocs=$([ "$WITH_STARTUP_DOCS" -eq 1 ] && printf 'yes' || printf 'no')

  if [ ! -f "$reg" ]; then
    {
      printf '# PDDA install registry — per-user, per-device. Machine-local; do NOT commit.\n'
      printf '# target\tlast_install_utc\tmode\tsource_commit\tstartup_docs\n'
    } > "$reg"
  fi

  # One row per target: drop any prior row for this exact path (tab-delimited col 1), then append fresh.
  # awk keeps comment lines (their col 1 never equals an absolute target path).
  row="$(printf '%s\t%s\t%s\t%s\t%s' "$TARGET" "$ts" "$MODE" "$src_commit" "$sdocs")"
  run_with_advisory_lock "$reg" "registry" write_install_registry_row "$reg" "$TARGET" "$row"
}

say "Installing PDDA into: $TARGET"
say ""
say "Runtime + contract:"
INSTALL_MANIFEST="$(pdda_manifest_expand "$SOURCE_DIR")" || exit 1
[ -n "$INSTALL_MANIFEST" ] || { say "FAILED: empty PDDA manifest"; exit 1; }
# Copy exactly the shared manifest set (DRY with pdda-sync.sh), restoring the exec bit on scripts.
while IFS= read -r rel; do
  [ -n "$rel" ] || continue
  copy_runtime "$rel"
  case "$rel" in *.sh) chmod +x "$TARGET/$rel" ;; esac
done <<EOF
$INSTALL_MANIFEST
EOF

if [ "$WITH_STARTUP_DOCS" -eq 1 ]; then
  # Three distinct semantics, deliberately not one call. Conflating them is GH-25 (a verbatim refresh
  # ate a repo-authored AGENTS.md) and GH-23 P1 (the canonical repo's own router shipped into targets,
  # naming install.sh and pdda-sync.sh — neither of which a target has).
  #
  #   templated  ROUTER.md   <- utils/pdda/templates/ROUTER.target.md, NOT this repo's ROUTER.md
  #   scaffold   AGENTS.md, GUIDING-PRINCIPLES.md   create-only; the target owns them after install
  #   runtime    .claude/skills/pdda/SKILL.md       PDDA owns it; safe to refresh verbatim
  written_docs="" kept_docs=""
  seed_from_source "utils/pdda/templates/ROUTER.target.md" "ROUTER.md"
  if [ "$SEEDED_LAST" -eq 1 ]; then written_docs="$written_docs ROUTER.md"; else kept_docs="$kept_docs ROUTER.md"; fi
  seed_from_source "utils/pdda/templates/AGENTS.target.md" "AGENTS.md"
  if [ "$SEEDED_LAST" -eq 1 ]; then written_docs="$written_docs AGENTS.md"; else kept_docs="$kept_docs AGENTS.md"; fi
  seed_from_source "utils/pdda/templates/GUIDING-PRINCIPLES.target.md" "GUIDING-PRINCIPLES.md"
  if [ "$SEEDED_LAST" -eq 1 ]; then written_docs="$written_docs GUIDING-PRINCIPLES.md"; else kept_docs="$kept_docs GUIDING-PRINCIPLES.md"; fi
  mkdir -p "$TARGET/.claude/skills/pdda"
  cp "$SOURCE_DIR/utils/pdda/templates/pdda/SKILL.md" "$TARGET/.claude/skills/pdda/SKILL.md"

  # GH-23 P2 — post-install self-check. One assertion would have caught the whole GH-23 bug at install
  # time: a startup doc that names a script the repo does not contain. P3 widened it from ROUTER.md to
  # every doc we wrote, after the .sh dead-ref scan found the same defect sitting in GUIDING-PRINCIPLES.md.
  #
  # Written and kept are decided per doc, so the skip notice must be too: a run that scaffolds AGENTS.md
  # beside a kept ROUTER.md validates the first and stays silent about the second — but must still SAY
  # it is staying silent, or the operator cannot tell an unvalidated doc from a validated one.
  for doc_rel in $written_docs; do
    assert_written_doc_refs "$doc_rel" || SELFCHECK_FAILED=1
  done
  for doc_rel in $kept_docs; do
    say "  self-check skipped — $doc_rel was kept, not written (it is yours, not ours to validate)"
  done
fi

migrate_flat_layout

say ""
say "Lifecycle buckets:"
for bucket in 1-INBOX 2-WORKING 3-COMPLETED 4-MISC; do
  seed_file "PROJECT/$bucket/blank.md" <<'BLANK'
<!-- placeholder so this lifecycle bucket exists in version control; PDDA checks ignore blank.md -->
BLANK
done

say ""
say "Zero-state seeds:"
TODAY="$(date +%Y-%m-%d)"

seed_file "ROADMAP.md" <<ROADMAP
<!-- PDDA ROADMAP CONTRACT — this file is a POINTER/LEDGER, not a plan body.
     Allowed: queued intake / projects in progress / completed / attempted / deferred + links to PROJECT/** docs.
     NOT allowed: phase checklists, build steps, deep execution notes — put those in the project doc.
     Carve-out: a SHORT exception note is OK only when omitting it would hide an operationally critical fact.
     Coverage rule: every PROJECT/2-WORKING doc must be reflected here by a pointer (or opt out with roadmap_exempt: true).
     Enforced by \`pdda.sh roadmap\` + \`pdda.sh roadmap-coverage\` (deterministic) + utils/pdda/pdda-doc-ready.sh ROADMAP rubric (LLM). -->

# Roadmap

> **Pointer/ledger only — not a plan body.** Execution detail (phase checklists, build steps, QA
> gates, deep notes) lives in the linked \`PROJECT/**\` docs; keep it there. See the contract banner above.

## Status

| What was just completed | What's next |
|---|---|
| Installed PDDA ($TODAY). | Open a \`PROJECT/**\` doc for the first tracked effort and add its pointer here. |

## Ledger

### Queue / parked intake

- No parked intake docs.

### In progress

- No active \`PROJECT/2-WORKING\` docs.

### Completed

- No completed docs.

### Deferred

- No deferred docs.

---

*Add new work here only when a real \`PROJECT/**\` doc exists to own the execution detail.*
ROADMAP

seed_file "CHANGELOG.md" <<CHANGELOG
# CHANGELOG.md

Newest-first, dated end-of-iteration record. One entry per substantive iteration: what changed,
why, and the verification. See \`PROJECT/PDDA.md\` for the full contract.

## $TODAY

### PDDA installed

- Installed the PDDA document-automation surface (\`utils/pdda/pdda.sh\` + helpers, \`PROJECT/PDDA.md\`)
  and the \`PROJECT/**\` lifecycle tree in \`observe\` mode.
- Next: replace this entry as real iterations land.

Verification: \`./utils/pdda/pdda.sh run\`
CHANGELOG

seed_file "RELEASES.md" <<'RELEASES'
# Major Releases

Forward-looking planning ledger for major releases — one block per release, minimal fields, blank
line between blocks. Marathon plans and other forward planning cross-reference this doc for
target release names/dates; it is not a history of what shipped (that's CHANGELOG.md — lessons
learned belong there at ship time, not duplicated here). Contract lives in PROJECT/PDDA.md ->
"RELEASES.md — release ledger". Add new fields only when a real need shows up.

Release: 0.1.0
Status: Draft
Target Date:
Codename: n/a
Description: EXAMPLE — replace this with your first real release, or delete this block once real entries exist below.
GH_URL:
Front-door reviewed:
Shakedown reviewed:
License file:
RELEASES

# Empty activity log (never copy the source repo's log).
seed_file "PROJECT/PDDA-ACTIVITY.jsonl" </dev/null

ensure_runtime_ignored

seed_file ".pdda-mode" <<MODE
$MODE
MODE

# Quad Concepts opt-in lever (orthogonal to .pdda-mode). Off unless --quad was passed.
seed_file ".pdda-quad" <<QUAD
# Quad Concepts opt-in lever (orthogonal to .pdda-mode). Set to 'on' to require a
# '## Quad Concepts' section (1-4 pain->fix bullets) on plan docs. See PROJECT/PDDA.md.
# Per-doc opt-out: quad_exempt: true. Env override: PDDA_QUAD=1.
$QUAD
QUAD

say ""
say "Registry:"
register_install

say ""
say "Verifying install (utils/pdda/pdda.sh run):"
say ""
case "$MODE" in
  observe) MODE_BLURB="report-only; graduate to light → full as you clear doc debt" ;;
  light)   MODE_BLURB="reports findings but never blocks; graduate to full when ready" ;;
  full)    MODE_BLURB="on rails — errors block with a non-zero exit" ;;
esac
VERIFY_RC=0
if ( cd "$TARGET" && PDDA_MODE="$MODE" ./utils/pdda/pdda.sh run ); then
  say ""
  say "PDDA installed. Mode: $MODE ($MODE_BLURB)."
  [ "$QUAD" = "on" ] && say "Quad Concepts: ON — plan docs need a '## Quad Concepts' section (1-4 bullets); opt out with quad_exempt: true."
  say "Next: read PROJECT/PDDA.md, then start a doc in PROJECT/2-WORKING and point ROADMAP.md at it."
else
  VERIFY_RC=$?
  say ""
  say "PDDA installed, but the first run reported findings or failed — see output above."
  case "$MODE" in
    observe|light) say "Normal $MODE findings are report-only; verification failed to complete. Re-run ./utils/pdda/pdda.sh run." ;;
    full)          say "In full mode errors block (non-zero exit); review the findings and re-run ./utils/pdda/pdda.sh run." ;;
  esac
fi

# The self-check validates PDDA's OWN output, not the target's content — so unlike the doc-hygiene run
# above (which is warn-only in observe/light), a failure here is always a hard, mode-independent error.
# It means PDDA shipped a router naming scripts the target does not have. The install itself completed;
# exiting non-zero is what stops `pdda-sync.sh register` from propagating a broken router any further.
if [ "$SELFCHECK_FAILED" -eq 1 ]; then
  say ""
  say "FAILED: post-install self-check — the ROUTER.md written into this target names scripts it does not have."
  say "The target is installed and usable, but its router misdirects agents. This is a PDDA template bug."
  exit 1
fi

[ "$VERIFY_RC" -eq 0 ] || exit "$VERIFY_RC"
exit 0
