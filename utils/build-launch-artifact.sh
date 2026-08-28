#!/usr/bin/env bash
# Build the PUBLIC LAUNCH ARTIFACT — the sanitized, fresh-history tree that becomes XYZ's public
# repository. See RELEASES.md's Meter block and #563.
#
# The published thing is NOT this repository. It is a clone-shaped directory containing only tracked,
# committed files, minus runtime state and internal working material, committed as ONE initial commit
# with no inherited git objects.
#
# WHY `git archive` AND NOT A CLONE (decided 2026-08-15 by cross-model consult):
#   - `git clone` + orphan branch leaves the ENTIRE original object database in .git until a gc. The
#     history is severed by reference but still physically present, so one `tar` of the directory
#     ships 2,147 commits worth of objects that were supposed to be gone.
#   - `cp`/`rsync` of the working tree relies on hand-maintained exclusions and can drag in .git,
#     .tick/, node_modules, or any untracked local junk sitting in the tree at that moment.
#   - `git archive HEAD` emits exactly the tracked files at exactly one commit. No object database, no
#     untracked files, no ignored files, nothing that was ever deleted. The isolation is structural
#     rather than maintained.
#
# THIS SCRIPT IS THE BUILD, NOT A ONE-OFF SANITIZATION PASS. It is meant to be re-run freely: the
# artifact is a build output, so /front-door and /shakedown can review a real artifact early instead
# of waiting for a hand-sanitized folder to exist at the end. Re-running always yields exactly one
# commit — history is recreated, never appended to.
#
# Usage:
#   utils/build-launch-artifact.sh <dest> [--remote <url>] [--no-commit]
#
#   <dest>        absolute path to build into. Created if absent. If it already exists it must be
#                 SAFE TO REBUILD (see the marker rule below) or the script refuses.
#   --remote URL  origin to set on the artifact. Default: the launch destination in RELEASES.md.
#   --no-commit   extract and prune but leave the tree uncommitted, for inspecting a diff.
#
# SAFETY. This script deletes files. It refuses unless <dest> is one of:
#   - absent (it creates it),
#   - empty,
#   - a git repository with ZERO commits (an empty clone of the destination repo), or
#   - a previous artifact, proven by the marker file this script writes.
# Anything else — including any path inside this repository — is refused. #564's lesson applies
# directly: an empty or wrong path fed to a recursive delete is the whole failure mode, so the path
# is validated at the point of USE, not merely where it is derived.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

MARKER=".xyz-launch-artifact"
DEFAULT_REMOTE="https://github.com/HiQS-Labs/XYZ-forge.git"

DEST=""; REMOTE="$DEFAULT_REMOTE"; DO_COMMIT=1
while [ $# -gt 0 ]; do
  case "$1" in
    --remote)    REMOTE="${2:-}"; shift 2 ;;
    --no-commit) DO_COMMIT=0; shift ;;
    --help|-h)   sed -n '2,40p' "$0"; exit 0 ;;
    -*)          printf 'unknown option: %s\n' "$1" >&2; exit 2 ;;
    *)           DEST="$1"; shift ;;
  esac
done

die() { printf 'build-launch-artifact: %s\n' "$*" >&2; exit 2; }

# ── Paths that never reach the public artifact ────────────────────────────────────────────────────
# Runtime state, relay transcripts, scratch space, and the parked-findings ledger. These are tracked
# in this repository, so `git archive` emits them and they must be pruned explicitly.
DROP_PATHS=(
  "relay-system"      # 375 tracked consult/relay transcripts
  "temp"              # scratch
  "PARKED"            # parked-findings ledger, internal
  ".tick"             # runtime event log (untracked here, listed for belt-and-braces)
  "AUDIT"             # internal audit workspace
  "phases"            # internal phase logs (operator decision 2026-08-15)
  "decisions"         # internal ADR workspace (operator decision 2026-08-15) — see KEEP_FILES:
                      # one decision doc is a documented INPUT to a shipped test, not internal
                      # scratch, and is restored after the drop.
  ".consult-gh79-out" # tracked consult transcripts — dot-prefixed, so the top-level sweep for
                      # internal working material missed it entirely. Found by TruffleHog, which
                      # flagged content inside it; the secret was a false positive but the
                      # DIRECTORY was the real finding. Hidden directories need naming explicitly.
)
# `marathon-system` is deliberately KEPT: the operator's call is that a public reader benefits from
# seeing how the sausage is made. Checked for PII before keeping — its only private content was
# machine-generated absolute home paths in RELAY.md files, which the redaction pass below rewrites.

# Individual files rescued from a dropped directory. A path lands here when a SHIPPED test reads it:
# `gh378-gate-requires-green-suite.sh` asserts on the baseline-strategy decision doc by name, so
# dropping it wholesale turns a green suite red for every newcomer. Restored after the drop pass
# rather than by exempting the whole directory, so the exception stays visible and countable.
KEEP_FILES=(
  "decisions/2026-08-10-marathon-gate-baseline-strategy.md"
)

# Build artifacts that are tracked in this repository but must never ship.
DROP_GLOBS=(
  "__pycache__"
  "*.pyc"
  # The secret-scan record names the artifact commit it covered. If it shipped, writing it would
  # change the very commit it names — an unresolvable fixed point. It is the project's evidence,
  # not part of the product, so it stays in the source repository and out of the artifact.
  "GH-563-secret-scan.md"
)

# ── Redaction ─────────────────────────────────────────────────────────────────────────────────────
# The author's home directory appears in machine-generated relay threads, test baselines and a few
# governance docs. Rewriting it to `~/` removes the username while preserving every sentence's
# meaning — the same substitution already applied to CHANGELOG.md, and the style the docs mostly use
# already. Done HERE rather than by hand so it is reproducible and cannot be forgotten on a rebuild.
# Assembled at runtime rather than written as a literal: this script would otherwise contain the
# very string it strips, and ship into the artifact as a self-inflicted match.
REDACT_HOME="$(printf '/%s/%s/' Users noelsaw)"
REDACT_WITH="~/"
# GH-204: derive the bare username from REDACT_HOME for the residual sweep below. Hardcoding it
# there re-introduced exactly the self-inflicted match the assembly above exists to avoid.
REDACT_USER="$(printf '%s' "$REDACT_HOME" | awk -F/ '{print $3}')"

# ── PROJECT retention ─────────────────────────────────────────────────────────────────────────────
# PROJECT/ ships as the PDDA scaffold plus the capture docs for THIS RELEASE, so the tree reflects
# the repository's actual state rather than an empty shell (operator decision, 2026-08-15). These are
# the launch's own working docs: its exit criterion, its checklist, and the two open items #563 names
# as covered-by-waiver rather than admitted.
# Format: <bucket>/<filename>. The bucket is preserved rather than everything being forced into
# 2-WORKING — an inbox item is not active work, and flattening the distinction would misrepresent
# the method in the one place a newcomer goes looking for how it is used.
PROJECT_KEEP=(
  "2-WORKING/GH-544-LOCAL-GATE-BEFORE-PUSH.md"
  "2-WORKING/GH-555-METER-EXIT-CRITERION.md"
  "2-WORKING/GH-563-PUBLIC-LAUNCH.md"
  "2-WORKING/GH-564-FIXTURE-CONTAINMENT.md"
  "1-INBOX/GLM-5.3-audit.txt"
)
# Scaffold files kept at PROJECT/ root — the method itself, which is what makes the retained docs
# legible as a worked example.
PROJECT_SCAFFOLD=(
  "PDDA.md"
  "PDDA-MODE-GUIDE.md"
  "PDDA-SYNC-POLICY.md"
  "CONSTITUTION.md"
  "DO-NOT-BUILD.md"
)

# ── Validate the destination ──────────────────────────────────────────────────────────────────────
[ -n "$DEST" ] || die "no destination given. Usage: $0 <dest> [--remote <url>]"
case "$DEST" in
  /*) ;;
  *)  die "destination '$DEST' is not absolute — refusing to resolve it against the caller's cwd" ;;
esac

# Never build into this repository, or anywhere inside it.
DEST_NORM="${DEST%/}"
[ "$DEST_NORM" = "$ROOT" ] && die "destination is this repository itself"
case "$DEST_NORM/" in
  "$ROOT"/*) die "destination '$DEST' is INSIDE this repository — the artifact must be built outside it" ;;
esac

if [ -e "$DEST_NORM" ]; then
  [ -d "$DEST_NORM" ] || die "destination '$DEST' exists and is not a directory"
  if [ -f "$DEST_NORM/$MARKER" ]; then
    :   # a previous artifact — safe to rebuild
  elif [ -z "$(ls -A "$DEST_NORM" 2>/dev/null)" ]; then
    :   # empty
  elif [ -d "$DEST_NORM/.git" ] \
       && [ "$(git -C "$DEST_NORM" rev-list --count --all 2>/dev/null || echo x)" = "0" ] \
       && [ -z "$(git -C "$DEST_NORM" ls-files 2>/dev/null)" ]; then
    :   # an empty clone of the destination repo — exactly what `gh repo clone` of a new repo gives
  else
    die "destination '$DEST' is not empty, carries no $MARKER marker, and is not an empty clone.
    Refusing to delete files this script did not create. Remove it by hand, or point at a fresh path."
  fi
fi

# ── Source must be committed: git archive reads HEAD, not the working tree ────────────────────────
if ! git -C "$ROOT" diff --quiet HEAD 2>/dev/null; then
  die "this repository has uncommitted tracked changes. git archive reads HEAD, so those changes
    would be SILENTLY ABSENT from the artifact. Commit or stash first."
fi
SRC_SHA="$(git -C "$ROOT" rev-parse HEAD)"
SRC_REF="$(git -C "$ROOT" rev-parse --abbrev-ref HEAD)"

printf '== build-launch-artifact ==\n'
printf '  source : %s @ %s (%s)\n' "$ROOT" "${SRC_SHA:0:8}" "$SRC_REF"
printf '  dest   : %s\n' "$DEST_NORM"
printf '  remote : %s\n\n' "$REMOTE"

# ── Preserve an existing origin, so a clone of the destination repo keeps its own remote ──────────
EXISTING_REMOTE=""
if [ -d "$DEST_NORM/.git" ]; then
  EXISTING_REMOTE="$(git -C "$DEST_NORM" remote get-url origin 2>/dev/null || true)"
  [ -n "$EXISTING_REMOTE" ] && REMOTE="$EXISTING_REMOTE"
fi

# ── Clear and extract ─────────────────────────────────────────────────────────────────────────────
mkdir -p "$DEST_NORM" || die "could not create '$DEST_NORM'"
# Guarded above; delete contents including dotfiles, but never the directory itself.
find "$DEST_NORM" -mindepth 1 -maxdepth 1 -exec rm -rf {} + || die "could not clear '$DEST_NORM'"

git -C "$ROOT" archive "$SRC_SHA" | tar -x -C "$DEST_NORM" \
  || die "git archive/extract failed"
extracted="$(find "$DEST_NORM" -type f | wc -l | tr -d ' ')"
printf '  extracted %s tracked file(s) from %s\n' "$extracted" "${SRC_SHA:0:8}"

# ── Stash the rescued files before the drop pass removes their directories ───────────────────────
RESCUE="$DEST_NORM/.rescue.$$"
for kf in "${KEEP_FILES[@]}"; do
  if [ -f "$DEST_NORM/$kf" ]; then
    mkdir -p "$RESCUE/$(dirname "$kf")"
    cp "$DEST_NORM/$kf" "$RESCUE/$kf"
  else
    printf '  NOTE: rescue file not found in source: %s\n' "$kf"
  fi
done

# ── Prune the drop set ────────────────────────────────────────────────────────────────────────────
for p in "${DROP_PATHS[@]}"; do
  if [ -e "$DEST_NORM/$p" ]; then
    n="$(find "$DEST_NORM/$p" -type f | wc -l | tr -d ' ')"
    rm -rf "${DEST_NORM:?}/$p"
    printf '  dropped %-14s (%s file(s))\n' "$p" "$n"
  fi
done

for g in "${DROP_GLOBS[@]}"; do
  n="$(find "$DEST_NORM" -name "$g" 2>/dev/null | wc -l | tr -d ' ')"
  if [ "$n" != "0" ]; then
    find "$DEST_NORM" -name "$g" -exec rm -rf {} + 2>/dev/null
    printf '  dropped %-14s (%s match(es), tracked build artifact)\n' "$g" "$n"
  fi
done

if [ -d "$RESCUE" ]; then
  rescued=0
  for kf in "${KEEP_FILES[@]}"; do
    if [ -f "$RESCUE/$kf" ]; then
      mkdir -p "$DEST_NORM/$(dirname "$kf")"
      mv "$RESCUE/$kf" "$DEST_NORM/$kf"
      rescued=$((rescued+1))
    fi
  done
  rm -rf "$RESCUE"
  printf '  restored %s file(s) a shipped test depends on\n' "$rescued"
fi

# ── Reduce PROJECT to scaffold + this release's capture docs ─────────────────────────────────────
if [ -d "$DEST_NORM/PROJECT" ]; then
  kept=0 removed=0
  # Stash the keepers, wipe the buckets, restore the keepers into 2-WORKING.
  STAGE="$DEST_NORM/.project-keep.$$"
  mkdir -p "$STAGE"
  for spec in "${PROJECT_KEEP[@]}"; do
    name="${spec##*/}"
    found="$(find "$DEST_NORM/PROJECT" -type f -name "$name" -print -quit 2>/dev/null)"
    if [ -n "$found" ]; then
      mkdir -p "$STAGE/$(dirname "$spec")"
      cp "$found" "$STAGE/$spec"
      kept=$((kept+1))
    else
      printf '  NOTE: retained doc not found in source: %s\n' "$spec"
    fi
  done
  for bucket in 1-INBOX 2-WORKING 3-COMPLETED 4-MISC; do
    if [ -d "$DEST_NORM/PROJECT/$bucket" ]; then
      removed=$((removed + $(find "$DEST_NORM/PROJECT/$bucket" -type f | wc -l | tr -d ' ')))
      rm -rf "${DEST_NORM:?}/PROJECT/$bucket"
    fi
    mkdir -p "$DEST_NORM/PROJECT/$bucket"
  done
  # Anything at PROJECT/ root that is not declared scaffold goes too (activity logs, etc).
  while IFS= read -r f; do
    base="${f##*/}"
    keep=0
    for s in "${PROJECT_SCAFFOLD[@]}"; do [ "$base" = "$s" ] && keep=1 && break; done
    [ "$keep" -eq 0 ] && { rm -f "$f"; removed=$((removed+1)); }
  done < <(find "$DEST_NORM/PROJECT" -maxdepth 1 -type f 2>/dev/null)

  for spec in "${PROJECT_KEEP[@]}"; do
    if [ -f "$STAGE/$spec" ]; then
      mkdir -p "$DEST_NORM/PROJECT/$(dirname "$spec")"
      mv "$STAGE/$spec" "$DEST_NORM/PROJECT/$spec"
    fi
  done
  rm -rf "$STAGE"
  printf '  PROJECT reduced — %s retained, %s removed\n' "$kept" "$removed"
fi

# ── Redact the author's home path from every text file ───────────────────────────────────────────
redacted=0
redact_failed=0
while IFS= read -r f; do
  if LC_ALL=C grep -qF "$REDACT_HOME" "$f" 2>/dev/null; then
    # GH-204: portable in-place edit (GNU + BSD). The counter reflects a real CONTENT change, not
    # sed's exit code -- the BSD-only `sed -i ''` form rewrote the file unchanged under GNU sed and
    # still read as success, shipping the author's home path into the artifact.
    if LC_ALL=C sed -i.bak "s|${REDACT_HOME}|${REDACT_WITH}|g" "$f" 2>/dev/null \
       && ! LC_ALL=C grep -qF "$REDACT_HOME" "$f" 2>/dev/null; then
      redacted=$((redacted+1))
    else
      redact_failed=$((redact_failed+1))
      printf '  REDACTION FAILED (home path still present): %s\n' "${f#"$DEST_NORM"/}" >&2
    fi
    rm -f "$f.bak"
  fi
done < <(find "$DEST_NORM" -type f ! -path "*/.git/*" 2>/dev/null)
printf '  redacted home path in %s file(s)\n' "$redacted"
if [ "$redact_failed" != "0" ]; then
  die "redaction FAILED for $redact_failed file(s) — the artifact still carries the author home path ($redacted file(s) were redacted successfully). A failure is NOT the same as 'nothing to redact', which reports 0 redactions and no failures."
fi

# Report anything the substitution could not reach, rather than assuming it is clean.
residual="$(LC_ALL=C grep -rlF "$REDACT_USER" "$DEST_NORM" --exclude-dir=.git 2>/dev/null | wc -l | tr -d ' ')"
if [ "$residual" != "0" ]; then
  printf '  NOTE: %s file(s) still contain the username in some other form:\n' "$residual"
  LC_ALL=C grep -rlF "$REDACT_USER" "$DEST_NORM" --exclude-dir=.git 2>/dev/null \
    | sed "s|^$DEST_NORM/|    |" | head -20
fi

# ── Marker, so a rebuild can prove it owns this directory ─────────────────────────────────────────
{
  printf 'This directory is a generated XYZ public launch artifact.\n'
  printf 'Built by utils/build-launch-artifact.sh from source commit %s.\n' "$SRC_SHA"
  printf 'Do not edit by hand: rebuild instead. The presence of this file authorises the build\n'
  printf 'script to clear this directory on the next run.\n'
} > "$DEST_NORM/$MARKER"

# ── Fresh history: exactly one commit, no inherited objects ──────────────────────────────────────
if [ "$DO_COMMIT" -eq 1 ]; then
  rm -rf "${DEST_NORM:?}/.git"
  git -C "$DEST_NORM" init -q -b main            || die "git init failed"
  git -C "$DEST_NORM" add -A                     || die "git add failed"
  # Pin the commit date to the SOURCE commit's, so the same source produces the same artifact SHA.
  # Without this the timestamp varies per run and the artifact hash changes on every rebuild — which
  # would make the recorded secret-scan commit stale the moment anyone rebuilt, and make "scan the
  # exact published commit" unverifiable in practice.
  SRC_DATE="$(git -C "$ROOT" show -s --format=%cI "$SRC_SHA")"
  GIT_AUTHOR_DATE="$SRC_DATE" GIT_COMMITTER_DATE="$SRC_DATE" \
  git -C "$DEST_NORM" -c user.email="noreply@users.noreply.github.com" \
                      -c user.name="XYZ" \
                      commit -q -m "XYZ: initial public release

Fresh history. This repository's development history is recorded in CHANGELOG.md,
which is carried forward verbatim from the project's private development." \
    || die "git commit failed"
  git -C "$DEST_NORM" remote add origin "$REMOTE" 2>/dev/null \
    || git -C "$DEST_NORM" remote set-url origin "$REMOTE"

  n_commits="$(git -C "$DEST_NORM" rev-list --count HEAD)"
  n_files="$(git -C "$DEST_NORM" ls-files | wc -l | tr -d ' ')"
  printf '\n  committed: %s commit, %s tracked file(s)\n' "$n_commits" "$n_files"
  printf '  origin   : %s\n' "$(git -C "$DEST_NORM" remote get-url origin)"
  [ "$n_commits" = "1" ] || die "expected exactly 1 commit, got $n_commits"
else
  printf '\n  --no-commit: tree left uncommitted for inspection\n'
fi

printf '\n  artifact ready: %s\n' "$DEST_NORM"
printf '  next: XYZ_LAUNCH_ARTIFACT=%s bash test/meter-release.sh --release-gate\n' "$DEST_NORM"
