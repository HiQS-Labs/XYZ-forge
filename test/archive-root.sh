#!/usr/bin/env bash
# archive-root.sh — GH-30 Phase 1: the single transcript-root resolver in relay-turn-lib.sh.
# Covers rtl_transcript_root / rtl_repo_slug in isolation (no writer wiring — that's Phase 2):
#   - XYZ_ARCHIVE_ROOT unset  → "$target/relay-system" (byte-for-byte today's path; regression guard)
#   - set to a valid git repo → "$archive/relay-system/<slug>" (slug from origin remote basename)
#   - set relative            → HARD ERROR (never a silent fallback into the foreign tree)
#   - set-but-missing         → HARD ERROR
#   - set to a NON-git dir     → HARD ERROR (Model A: the archive is a committed git repo)
#   - slug fallback           → target with no origin remote uses its dir basename
source "$(dirname "$0")/_setup.sh" archive-root

LIB="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/relay-turn-lib.sh"
[ -f "$LIB" ] || fail "relay-turn-lib.sh not found at $LIB"
# shellcheck disable=SC1090
source "$LIB"

# $A is a git clone whose origin remote is the bare "$REMOTE" (…/remote.git) → slug "remote".
SLUG_A="remote"

# --- (1) unset → byte-for-byte today's path -----------------------------------------------------
unset XYZ_ARCHIVE_ROOT
out="$(rtl_transcript_root "$A")"; rc=$?
[ "$rc" = 0 ] || fail "unset: expected rc 0, got $rc"
[ "$out" = "$A/relay-system" ] || fail "unset: expected '$A/relay-system', got '$out'"
pass "unset XYZ_ARCHIVE_ROOT → \$target/relay-system (regression-safe)"

# --- (2) set to a valid git repo → namespaced by slug -------------------------------------------
ARCHIVE="$WORK/archive"; git init -q "$ARCHIVE"
out="$(XYZ_ARCHIVE_ROOT="$ARCHIVE" rtl_transcript_root "$A")"; rc=$?
[ "$rc" = 0 ] || fail "set-valid: expected rc 0, got $rc"
[ "$out" = "$ARCHIVE/relay-system/$SLUG_A" ] || fail "set-valid: expected '$ARCHIVE/relay-system/$SLUG_A', got '$out'"
pass "set to git repo → \$archive/relay-system/<slug> (namespaced per source repo)"

# --- (2b) trailing-slash target → no double slash (regression-safe normalization) ---------------
out="$(rtl_transcript_root "$A/")"; rc=$?
[ "$rc" = 0 ] || fail "trailing-slash: expected rc 0, got $rc"
[ "$out" = "$A/relay-system" ] || fail "trailing-slash: expected '$A/relay-system' (no '//'), got '$out'"
pass "trailing-slash target → single-slash base (no // prefix surprise)"

# --- (3) set relative → hard error (no silent fallback), and stderr explains why -----------------
err="$(XYZ_ARCHIVE_ROOT="relative/dir" rtl_transcript_root "$A" 2>&1 1>/dev/null)"; rc=$?
out="$(XYZ_ARCHIVE_ROOT="relative/dir" rtl_transcript_root "$A" 2>/dev/null)"; rc=$?
[ "$rc" != 0 ] || fail "set-relative: expected non-zero rc, got 0 (output '$out')"
[ -z "$out" ] || fail "set-relative: expected no stdout path, got '$out'"
[ -n "$err" ] || fail "set-relative: expected a stderr diagnostic, got none"
pass "set relative path → hard error, no fallback, stderr explains"

# --- (4) set-but-missing → hard error -----------------------------------------------------------
out="$(XYZ_ARCHIVE_ROOT="$WORK/does-not-exist" rtl_transcript_root "$A" 2>/dev/null)"; rc=$?
[ "$rc" != 0 ] || fail "set-missing: expected non-zero rc, got 0 (output '$out')"
[ -z "$out" ] || fail "set-missing: expected no stdout path, got '$out'"
pass "set to a missing dir → hard error"

# --- (5) set to a non-git dir → hard error (Model A) --------------------------------------------
PLAINDIR="$WORK/plain"; mkdir -p "$PLAINDIR"
out="$(XYZ_ARCHIVE_ROOT="$PLAINDIR" rtl_transcript_root "$A" 2>/dev/null)"; rc=$?
[ "$rc" != 0 ] || fail "set-nongit: expected non-zero rc, got 0 (output '$out')"
[ -z "$out" ] || fail "set-nongit: expected no stdout path, got '$out'"
pass "set to a non-git dir → hard error (Model A requires a committed archive)"

# --- (6) slug fallback: target with no origin remote → dir basename -----------------------------
NOREMOTE="$WORK/lonerepo"; git init -q "$NOREMOTE"   # git repo, but no origin remote
out="$(XYZ_ARCHIVE_ROOT="$ARCHIVE" rtl_transcript_root "$NOREMOTE")"; rc=$?
[ "$rc" = 0 ] || fail "slug-fallback: expected rc 0, got $rc"
[ "$out" = "$ARCHIVE/relay-system/lonerepo" ] || fail "slug-fallback: expected '…/relay-system/lonerepo', got '$out'"
pass "no origin remote → slug falls back to target dir basename"

# --- (7) rtl_repo_slug sanitizes to a single safe path segment ----------------------------------
slug="$(rtl_repo_slug "$A")"
[ "$slug" = "$SLUG_A" ] || fail "slug: expected '$SLUG_A', got '$slug'"
case "$slug" in */*) fail "slug contains a path separator: '$slug'";; esac
pass "rtl_repo_slug returns a single sanitized segment ('$slug')"

# --- (8) scp-style origin remote → basename, .git stripped, host: prefix dropped -----------------
SCP="$WORK/scp"; git init -q "$SCP"; git -C "$SCP" remote add origin "git@github.com:org/foo.git"
[ "$(rtl_repo_slug "$SCP")" = "foo" ] || fail "scp-remote: expected 'foo', got '$(rtl_repo_slug "$SCP")'"
pass "scp-style remote git@host:org/foo.git → slug 'foo'"

# --- (9) trailing-slash origin URL → basename still resolves (not an empty fallback) -------------
TSL="$WORK/tslash"; git init -q "$TSL"; git -C "$TSL" remote add origin "https://github.com/org/bar.git/"
[ "$(rtl_repo_slug "$TSL")" = "bar" ] || fail "trailing-slash-remote: expected 'bar', got '$(rtl_repo_slug "$TSL")'"
pass "trailing-slash remote …/bar.git/ → slug 'bar' (no empty-basename fallback)"

# --- (10) path-traversal basenames ('..' / '.') never survive as a slug -------------------------
# These target roots have no origin remote → slug falls back to the dir basename; the sanitizer must
# NOT let a traversal segment through, or a writer could escape $XYZ_ARCHIVE_ROOT/relay-system/.
[ "$(rtl_repo_slug "/no/such/path/..")" = "repo" ] || fail "traversal '..': expected 'repo', got '$(rtl_repo_slug "/no/such/path/..")'"
[ "$(rtl_repo_slug "/no/such/path/.")"  = "repo" ] || fail "traversal '.': expected 'repo', got '$(rtl_repo_slug "/no/such/path/.")'"
pass "'..' / '.' basenames collapse to 'repo' (no path-traversal escape)"

# --- (11) leading-dash basename → never option-shaped for a later cd/git -C consumer -------------
ds="$(rtl_repo_slug "/no/such/path/-rf")"
case "$ds" in -*) fail "leading-dash: slug still option-shaped: '$ds'";; esac
[ "$ds" = "rf" ] || fail "leading-dash: expected 'rf', got '$ds'"
pass "leading-dash basename '-rf' → 'rf' (not option-shaped)"

# --- (12) space in basename → sanitized to a single safe segment --------------------------------
sp="$(rtl_repo_slug "/no/such/my repo")"
[ "$sp" = "my_repo" ] || fail "space: expected 'my_repo', got '$sp'"
case "$sp" in *" "*) fail "space survived in slug: '$sp'";; esac
pass "space in basename 'my repo' → 'my_repo'"

echo "== archive-root: $PASS passed, $FAIL failed =="
[ "$FAIL" = 0 ]
