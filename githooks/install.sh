#!/usr/bin/env bash
# install.sh — wire this clone's push gate. (GH-544, corrected by GH-549)
#
# `.git/hooks/` is NOT version-controlled and does not travel with a clone, so the gate has to be
# wired up per clone. The FIRST design did that with `core.hooksPath=githooks`, pointing git at the
# in-tree directory. That was wrong in a way that produced exactly the failure the gate exists to
# prevent:
#
#   `core.hooksPath` is REPO-scoped, not BRANCH-scoped. On any checkout without a `githooks/`
#   directory — a branch cut before the gate landed, an old feature branch, a bisect checkout — git
#   finds no hook file and runs NO HOOK AT ALL, with no warning. The push goes out ungated, silently.
#   And the hook is precisely the thing that does not run, so nothing inside `githooks/pre-push` can
#   detect its own absence.
#
# So the ENTRYPOINT moves out of the working tree. This installs a small delegator stub into the
# resolved git hooks directory (`git rev-parse --git-path hooks`, which from a linked worktree
# resolves to the PARENT clone's `.git/hooks` — so one install covers every worktree). Living in git
# metadata makes it branch-independent. The stub keeps no logic of its own beyond dispatch:
#
#   1. exec the in-tree `githooks/pre-push` when present  — all real logic stays reviewable in-tree
#   2. else run `validate.sh` directly, announced         — branches predating the hook still gate
#   3. else REFUSE the push                               — never silently ungated
#
# THE LIMIT, STATED UP FRONT: this is still PER CLONE. A fresh clone or a second machine that has
# never run this has NO gate. `--check` exists so that absence is detectable instead of silent. That
# gap, and `git push --no-verify`, are not fixable client-side.
#
# Usage:
#   bash githooks/install.sh            # install (idempotent)
#   bash githooks/install.sh --check    # report whether this clone is wired; exit 1 if not
#   bash githooks/install.sh --uninstall
set -uo pipefail

REPO="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "githooks/install.sh: not inside a git repository" >&2; exit 3; }
cd "$REPO" || exit 3

REL="githooks"
MODE="${1:-install}"

# The marker is how --check recognizes OUR stub and how --uninstall knows it is safe to delete the
# file. Without it, uninstall could remove a pre-push hook some other tool installed.
MARKER="XYZ-GH549-PREPUSH-STUB"

# Resolve the DEFAULT hooks directory — deliberately NOT `git rev-parse --git-path hooks`, which
# obeys core.hooksPath and so, with the legacy value still set, resolves to the in-tree `githooks/`
# and would have this installer overwrite the very hook it delegates to. The common dir is also what
# makes one install cover every linked worktree: from a worktree, --git-common-dir points at the
# PARENT clone, and that is where git looks for hooks.
COMMON="$(git rev-parse --git-common-dir 2>/dev/null)" || {
  echo "githooks/install.sh: cannot resolve the git directory" >&2; exit 3; }
[ -n "$COMMON" ] || { echo "githooks/install.sh: cannot resolve the git directory" >&2; exit 3; }
case "$COMMON" in /*) ;; *) COMMON="$REPO/$COMMON" ;; esac
HOOK_DIR="$COMMON/hooks"
STUB="$HOOK_DIR/pre-push"

current="$(git config --get core.hooksPath 2>/dev/null || true)"

_stub_is_ours() { [ -f "$STUB" ] && grep -q "$MARKER" "$STUB" 2>/dev/null; }

case "$MODE" in
  --check|check)
    _ok=0
    if _stub_is_ours && [ -x "$STUB" ]; then
      echo "githooks: INSTALLED — $STUB is the gate stub (executable)"
    else
      echo "githooks: NOT INSTALLED in this clone." >&2
      if [ -f "$STUB" ] && ! _stub_is_ours; then
        echo "  $STUB exists but is NOT this installer's stub — refusing to claim it." >&2
      elif [ -f "$STUB" ]; then
        echo "  $STUB exists but is not executable." >&2
      else
        echo "  $STUB does not exist." >&2
      fi
      echo "  This clone will push WITHOUT running the gate. Fix: bash githooks/install.sh" >&2
      _ok=1
    fi
    # A leftover core.hooksPath is reported even when the stub is fine: it OVERRIDES the default
    # hooks directory, so a stale one silently disables the stub we just verified.
    if [ -n "$current" ]; then
      echo "  WARNING: core.hooksPath='$current' is set and overrides $HOOK_DIR." >&2
      echo "  The stub above will NOT run while it is set. Fix: bash githooks/install.sh" >&2
      _ok=1
    fi
    exit "$_ok"
    ;;
  --uninstall|uninstall)
    if _stub_is_ours; then
      rm -f "$STUB"
      echo "githooks: uninstalled — removed $STUB."
    elif [ -f "$STUB" ]; then
      echo "githooks: $STUB is not this installer's stub — left it alone." >&2
    else
      echo "githooks: nothing to uninstall."
    fi
    if [ "$current" = "$REL" ]; then
      git config --unset core.hooksPath 2>/dev/null || true
      echo "githooks: also cleared the legacy core.hooksPath=$REL."
    fi
    echo "githooks: this clone no longer gates pushes."
    exit 0
    ;;
  install) ;;
  *) echo "usage: bash githooks/install.sh [--check | --uninstall]" >&2; exit 2 ;;
esac

[ -f "$REPO/$REL/pre-push" ] || { echo "githooks/install.sh: $REL/pre-push not found" >&2; exit 3; }
chmod +x "$REPO/$REL/pre-push" 2>/dev/null || true

# `core.hooksPath` must be UNSET for the stub to be reached — it overrides the default hooks
# directory entirely. Clear our own legacy value; refuse to touch anyone else's.
if [ -n "$current" ]; then
  if [ "$current" = "$REL" ]; then
    git config --unset core.hooksPath 2>/dev/null || true
    echo "githooks: cleared the legacy core.hooksPath=$REL (GH-549 — it skipped the gate on any"
    echo "          branch without a $REL/ directory, silently)."
  else
    echo "githooks/install.sh: core.hooksPath is set to '$current'." >&2
    echo "  It overrides $HOOK_DIR, so the gate stub would never run — and unsetting it would" >&2
    echo "  disable whatever it points at. Refusing to decide that for you." >&2
    echo "  Resolve it deliberately, then re-run: git config --unset core.hooksPath" >&2
    exit 4
  fi
fi

mkdir -p "$HOOK_DIR" || { echo "githooks/install.sh: cannot create $HOOK_DIR" >&2; exit 3; }

if [ -f "$STUB" ] && ! _stub_is_ours; then
  echo "githooks/install.sh: $STUB already exists and is not this installer's stub." >&2
  echo "  Refusing to overwrite it — that would disable whatever it does." >&2
  echo "  Move it aside and re-run if you want the gate here." >&2
  exit 4
fi

cat >"$STUB" <<'STUB_EOF'
#!/usr/bin/env bash
# pre-push — GATE DISPATCH STUB. XYZ-GH549-PREPUSH-STUB
#
# Installed by githooks/install.sh. This file lives in git metadata, NOT in the working tree, and is
# therefore BRANCH-INDEPENDENT — which is the entire point (GH-549). An in-tree hook wired through
# core.hooksPath vanished on any branch that predated it, and git skips a missing hook silently.
#
# Keep this file dumb. All real gate logic lives in the tree at githooks/pre-push, where it is
# reviewed and versioned; this only decides WHICH gate to run, so the two cannot drift.
set -uo pipefail

if ! REPO="$(git rev-parse --show-toplevel 2>/dev/null)" || [ -z "$REPO" ]; then
  echo "pre-push: cannot resolve the repository root — REFUSING the push rather than skipping the gate." >&2
  echo "pre-push:   Override with 'git push --no-verify' if you know why this happened." >&2
  exit 1
fi

# 1. The normal path: hand off to the in-tree hook, stdin and all.
if [ -x "$REPO/githooks/pre-push" ]; then
  exec "$REPO/githooks/pre-push" "$@"
fi

# 2. This branch predates the in-tree hook. Do NOT skip — run the gate directly. Announced, because
#    a fallback that looks identical to the normal path teaches nobody that the branch is old.
echo "pre-push: this branch has no githooks/pre-push — falling back to running validate.sh directly." >&2

if [ ! -x "$REPO/validate.sh" ]; then
  echo "pre-push: and $REPO/validate.sh is missing or not executable — REFUSING the push." >&2
  echo "pre-push:   Neither gate exists on this branch. A gate that cannot run is not one that passed." >&2
  echo "pre-push:   Override with 'git push --no-verify' if this branch is genuinely ungatable." >&2
  exit 1
fi

# Same two short-circuits the in-tree hook honors — they have to live on BOTH paths, or an old
# branch would block `git push --delete` and ignore the automation bypass.
_all_deletes=1
_saw_line=0
while read -r _lref _lsha _rref _rsha; do
  [ -n "${_lsha:-}" ] || continue
  _saw_line=1
  case "$_lsha" in
    *[!0]*) _all_deletes=0 ;;
  esac
done
if [ "$_saw_line" -eq 1 ] && [ "$_all_deletes" -eq 1 ]; then
  echo "pre-push: delete-only push — no gate to run."
  exit 0
fi

if [ "${XYZ_SKIP_PREPUSH:-0}" != "0" ]; then
  echo "pre-push: SKIPPED by XYZ_SKIP_PREPUSH — nothing was verified before this push." >&2
  exit 0
fi

if "$REPO/validate.sh"; then
  echo "pre-push: gate GREEN — pushing."
  exit 0
fi
_rc=$?
echo "pre-push: GATE RED (exit $_rc) — push REFUSED. Override: git push --no-verify" >&2
exit 1
STUB_EOF

chmod +x "$STUB" || { echo "githooks/install.sh: cannot make $STUB executable" >&2; exit 3; }

echo "githooks: installed — $STUB"
echo "  It runs the gate before any push, on EVERY branch in this clone (and its worktrees),"
echo "  including branches with no githooks/ directory (GH-549)."
echo "  Bypass: git push --no-verify   or   XYZ_SKIP_PREPUSH=1 git push"
echo "  Verify: bash githooks/install.sh --check"
