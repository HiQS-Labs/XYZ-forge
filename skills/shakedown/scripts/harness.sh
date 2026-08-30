#!/usr/bin/env bash
# shakedown/scripts/harness.sh — live discovery harness (sandboxed; read-only against target).
#
# Run A executes the as-documented command across a CWD/install matrix to reproduce a discovery
# bug; Run B re-runs the {SKILL}-anchored proposed command to confirm the fix survives all of it.
# Every scenario gets a fresh throwaway copy of the target under mktemp, deleted on exit.
#
#   Usage: harness.sh --target <dir> --as-documented '<cmd>' [--proposed '<cmd with {SKILL}>'] [--keep]
#   Exit:  0 no discovery bug · 1 bug reproduced · 3 usage
#
# Self-locates and sources its own lib.sh (the idiom this skill recommends).
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

TARGET="" ; AS_DOC="" ; PROPOSED="" ; KEEP=0
while (($#)); do case "$1" in
  --target)        TARGET="${2:-}"; shift 2 ;;
  --as-documented) AS_DOC="${2:-}"; shift 2 ;;
  --proposed)      PROPOSED="${2:-}"; shift 2 ;;
  --keep)          KEEP=1; shift ;;
  -h|--help) echo "usage: harness.sh --target <dir> --as-documented '<cmd>' [--proposed '<cmd with {SKILL}>'] [--keep]"; exit 0 ;;
  *) echo "harness: unknown argument: $1" >&2; exit 3 ;;
esac; done
[ -n "$TARGET" ] && [ -d "$TARGET" ] || { echo "harness: --target <existing skill dir> required" >&2; exit 3; }
[ -n "$AS_DOC" ] || { echo "harness: --as-documented '<command>' required" >&2; exit 3; }

name="$(basename "$TARGET")"
BASE="$(mktemp -d "${TMPDIR:-/tmp}/shakedown.XXXXXX")"
ERR="$BASE/.stderr"
trap '[ "$KEEP" = 1 ] || rm -rf "$BASE"' EXIT
[ "$KEEP" = 1 ] && printf 'sandbox kept at: %s\n\n' "$BASE"

stage() { local d="$1"; mkdir -p "$d"; cp -R "$TARGET/." "$d/"; ( cd "$d" && pwd ); }
sub()   { printf '%s' "${1//\{SKILL\}/$2}"; }   # {SKILL} -> install dir

BUG=0
row() { # <label> <cwd> <install-dir> <home> <cmd-template>
  local label="$1" cwd="$2" inst="$3" home="$4" tmpl="$5" cmd rc verd err
  cmd="$(sub "$tmpl" "$inst")"
  ( cd "$cwd" && HOME="$home" bash -c "$cmd" ) >/dev/null 2>"$ERR"; rc=$?
  if [ "$rc" -eq 127 ] || grep -qiE 'no such file|not found' "$ERR"; then verd='NOT-FOUND'; BUG=1
  elif [ "$rc" -ne 0 ]; then verd='found/err'      # located but errored (e.g. missing arg) — discovery still passed
  else verd='found'; fi
  err="$(tr '\n' ' ' <"$ERR" 2>/dev/null | sed -E 's/  +/ /g' | cut -c1-72)"
  printf '  %-20s %-10s exit %-3s %s\n' "$label" "$verd" "$rc" "$err"
}

matrix() { # <cmd-template>
  local tmpl="$1" inst
  inst="$(stage "$BASE/control/$name")";                 row "control(CWD=skill)" "$inst"            "$inst" "$HOME"          "$tmpl"
  inst="$(stage "$BASE/foreign/$name")";  mkdir -p "$BASE/fcwd";  row "foreign CWD"  "$BASE/fcwd"     "$inst" "$HOME"          "$tmpl"
  inst="$(stage "$BASE/nested/$name")";   mkdir -p "$BASE/nested/a/b/c"; row "nested CWD" "$BASE/nested/a/b/c" "$inst" "$HOME" "$tmpl"
  inst="$(stage "$BASE/has space/$name")";mkdir -p "$BASE/scwd";  row "spaces in path" "$BASE/scwd"   "$inst" "$HOME"          "$tmpl"
  inst="$(stage "$BASE/proj/.claude/skills/$name")";            row "project install" "$BASE/proj"    "$inst" "$HOME"          "$tmpl"
  mkdir -p "$BASE/fakehome"; inst="$(stage "$BASE/fakehome/.claude/skills/$name")"; mkdir -p "$BASE/ucwd"
                                                        row "user install"      "$BASE/ucwd"          "$inst" "$BASE/fakehome" "$tmpl"
  # symlinked install: the skill dir referenced by the command is a SYMLINK to the real copy
  # (e.g. ~/.claude/skills/shakedown -> repo/skills/shakedown). A locator using `find` without -L,
  # or self-location that breaks across a symlink, fails exactly here — the gap that let shakedown
  # pass its own audit. ln -sfn so the symlink is fresh on both Run A and Run B passes.
  inst="$(stage "$BASE/symreal/$name")"; ln -sfn "$inst" "$BASE/sym-$name"; mkdir -p "$BASE/symcwd"
                                                        row "symlinked install" "$BASE/symcwd"        "$BASE/sym-$name" "$HOME" "$tmpl"
  inst="$(stage "$BASE/noexec/$name")"; chmod -x "$inst"/scripts/*.sh 2>/dev/null || true
                                                        row "stripped exec bit" "$inst"               "$inst" "$HOME"          "$tmpl"
}

printf '## Shakedown live harness — %s\n\n' "$name"
printf '### Run A — as documented: %s\n' "$AS_DOC"
BUG=0; matrix "$AS_DOC"; A_BUG=$BUG
printf '  -> Run A: %s\n\n' "$([ "$A_BUG" = 1 ] && echo 'DISCOVERY BUG reproduced (script not found under some condition)' || echo 'no discovery bug under these scenarios')"

if [ -n "$PROPOSED" ]; then
  printf '### Run B — proposed (anchored): %s\n' "$PROPOSED"
  BUG=0; matrix "$PROPOSED"; B_BUG=$BUG
  printf '  -> Run B: %s\n\n' "$([ "$B_BUG" = 1 ] && echo 'STILL FAILS — the proposed fix is not CWD-robust' || echo 'survives every scenario')"
fi

if [ "$A_BUG" = 1 ]; then
  printf 'Verdict: [path bug reproduced] — the as-documented command is not CWD-robust\n'; exit 1
fi
printf 'Verdict: [clean] — no discovery bug reproduced under these scenarios (not proof of universality)\n'; exit 0
