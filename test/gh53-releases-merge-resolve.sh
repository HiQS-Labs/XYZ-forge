#!/usr/bin/env bash
# #53 — the derived-artifact attributes, and the one-command merge resolution.
#
# Two things are pinned here, and the second is the one that earns its keep:
#
#   A. .gitattributes marks releases.db and RELEASES-PREVIEW.md as derived (-diff,
#      linguist-generated) and pointedly does NOT give them a merge driver. The measured reason is
#      in .gitattributes; the assertion here is that nobody quietly adds one later, because
#      auto-resolving a derived file lets a merge complete with a DB holding only one side's rows.
#
#   B. utils/releases-merge-resolve.sh finishes a ledger merge correctly, and REFUSES the cases it
#      cannot settle rather than producing a plausible-looking wrong answer.
#
# The refusals are the point of this suite. A resolver that always succeeds is worse than no
# resolver: it would happily rebuild from a dump carrying two generation headers, or from one where
# both branches edited the same release, and hand back an artifact set that looks consistent.
#
# Usage: bash test/gh53-releases-merge-resolve.sh
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$HERE/.." && pwd)"
# shellcheck source=/dev/null
source "$HERE/_setup.sh" gh53-releases-merge-resolve

APP="$ROOT_DIR/utils/py/releases_app.py"
RESOLVE="$ROOT_DIR/utils/releases-merge-resolve.sh"

command -v python3 >/dev/null 2>&1 || { echo "python3 required" >&2; exit 1; }
[ -x "$RESOLVE" ] && pass "releases-merge-resolve.sh is executable" || fail "$RESOLVE missing or not executable"

# ── A. the attribute contract on THIS repo ──────────────────────────────────────────────────────
attr() { git -C "$ROOT_DIR" check-attr "$1" -- "$2" | sed 's/.*: //'; }

for f in releases.db RELEASES-PREVIEW.md; do
  [ "$(attr diff "$f")" = "unset" ] \
    && pass "$f is marked -diff (its diff is generated noise)" \
    || fail "$f is not marked -diff; see .gitattributes"
  [ "$(attr linguist-generated "$f")" = "true" ] \
    && pass "$f is marked linguist-generated (collapsed in PR review)" \
    || fail "$f is not marked linguist-generated"
  [ "$(attr merge "$f")" = "unspecified" ] \
    && pass "$f has NO merge driver — it conflicts on purpose, so the rebuild cannot be skipped silently" \
    || fail "$f has a merge driver set. Auto-resolving a derived file lets a merge complete with a DB holding only one side's rows — the silent divergence #52 exists to catch. Read the rationale in .gitattributes before changing this."
done

# releases.sql must NOT be marked generated: it is the one artifact whose diff a human must read.
[ "$(attr diff releases.sql)" = "unspecified" ] \
  && pass "releases.sql keeps its normal diff (it is the artifact humans actually merge)" \
  || fail "releases.sql was marked -diff; that hides the only ledger diff worth reading"

# ── fixture: two branches that both wrote to the ledger ─────────────────────────────────────────
G=git
mk_diverged() { # <dir> <extra writes on side A> — leaves the repo mid-merge, returns 0
  local R="$1" extra="$2" i=0
  case "$R" in "$WORK"/*) ;; *) echo "REFUSING: $R outside WORK" >&2; exit 2 ;; esac
  mkdir -p "$R"
  $G -C "$R" init -q; $G -C "$R" config user.email t@t; $G -C "$R" config user.name t
  python3 "$APP" --root "$R" init --slug m > /dev/null
  cp "$ROOT_DIR/.gitattributes" "$R/.gitattributes"
  $G -C "$R" add -A; $G -C "$R" commit -qm base
  $G -C "$R" branch s-a; $G -C "$R" branch s-b
  $G -C "$R" checkout -q s-a
  python3 "$APP" --root "$R" add --version 1.0.0 --status draft --tracking-issue TMP-AAAAAA --description "A one." > /dev/null
  while [ "$i" -lt "$extra" ]; do
    python3 "$APP" --root "$R" add --version "1.$i.9" --status draft --tracking-issue "TMP-EXTRA$i" --description "A extra $i." > /dev/null
    i=$((i+1))
  done
  $G -C "$R" commit -qam a
  $G -C "$R" checkout -q s-b
  python3 "$APP" --root "$R" add --version 2.0.0 --status draft --tracking-issue TMP-BBBBBB --description "B one." > /dev/null
  $G -C "$R" commit -qam b
  $G -C "$R" merge s-a -m merge > "$R/../merge.out" 2>&1 || true
}

# union both dumps the way the documented procedure does: ONE header, dedupe the rest
union_dump() { # <repo>
  local R="$1"
  { $G -C "$R" show s-b:releases.sql | grep '^-- generation'
    { $G -C "$R" show s-b:releases.sql; $G -C "$R" show s-a:releases.sql; } \
      | grep -v '^-- generation' | awk '!seen[$0]++'
  } > "$R/releases.sql"
  $G -C "$R" add releases.sql
}

# ── B1. the happy path: disjoint inserts on both sides ──────────────────────────────────────────
R1="$WORK/happy"
mk_diverged "$R1" 0
UNMERGED1="$($G -C "$R1" diff --name-only --diff-filter=U | tr '\n' ' ')"
case "$UNMERGED1" in
  *releases.db*) pass "releases.db conflicted, as designed (the conflict is the signal)" ;;
  *) fail "releases.db did not conflict; the derived-artifact contract changed" ;;
esac

union_dump "$R1"
if bash "$RESOLVE" --root "$R1" > "$WORK/r1.out" 2>&1; then
  pass "resolver completed on disjoint inserts"
else
  sed 's/^/    /' "$WORK/r1.out" >&2
  fail "resolver failed on the ordinary case; see $WORK/r1.out"
fi

python3 "$APP" --root "$R1" check > "$WORK/r1check.out" 2>&1 \
  && pass "after resolution, releases check is clean" \
  || { sed 's/^/    /' "$WORK/r1check.out" >&2; fail "check is not clean after resolution"; }

ROWS="$(sqlite3 "$R1/releases.db" 'SELECT COUNT(*) FROM releases')"
[ "$ROWS" = "2" ] \
  && pass "BOTH sides' releases survived the rebuild (2 rows)" \
  || fail "expected 2 releases after merging one from each side, got $ROWS — a side was dropped"

[ -z "$($G -C "$R1" diff --name-only --diff-filter=U)" ] \
  && pass "no unmerged paths remain — the merge is ready to commit" \
  || fail "unmerged paths remain after the resolver claimed success"

# the resolver must NOT commit: that decision stays with the operator
$G -C "$R1" rev-parse -q --verify MERGE_HEAD > /dev/null 2>&1 \
  && pass "the merge is left UNCOMMITTED — the resolver stages, the operator decides" \
  || fail "the resolver committed the merge; that is the operator's call, not the script's"

# ── B2. NEGATIVE CONTROL: a two-header dump must be refused, not rebuilt ────────────────────────
# This is what a naive `merge=union` leaves behind when the branches made unequal numbers of writes.
# The rebuild reads only the FIRST header, so accepting it would silently understate the generation.
R2="$WORK/twoheader"
mk_diverged "$R2" 2
{ $G -C "$R2" show s-b:releases.sql; $G -C "$R2" show s-a:releases.sql; } \
  | awk '!seen[$0]++' > "$R2/releases.sql"      # deliberately keeps BOTH headers
$G -C "$R2" add releases.sql

HDRS="$(grep -c '^-- generation: ' "$R2/releases.sql")"
[ "$HDRS" -gt 1 ] \
  && pass "fixture reproduces the union artefact: $HDRS generation headers in one dump" \
  || fail "could not reproduce a two-header dump; the control below would be vacuous"

if bash "$RESOLVE" --root "$R2" > "$WORK/r2.out" 2>&1; then
  fail "NEGATIVE CONTROL FAILED: the resolver accepted a dump with $HDRS generation headers"
else
  pass "NEGATIVE CONTROL: a multi-header dump is REFUSED (rc!=0), not silently rebuilt"
fi
grep -q "generation" "$WORK/r2.out" \
  && pass "the refusal names the generation headers, so the operator knows what to fix" \
  || fail "the refusal did not explain itself; see $WORK/r2.out"

# ── B3. NEGATIVE CONTROL: an unresolved releases.sql must be refused ────────────────────────────
R3="$WORK/unresolved"
mk_diverged "$R3" 0
# leave releases.sql exactly as the merge left it, conflicted or not, and force a marker in
printf '<<<<<<< HEAD\n-- junk\n=======\n-- other\n>>>>>>> s-a\n' >> "$R3/releases.sql"
if bash "$RESOLVE" --root "$R3" > "$WORK/r3.out" 2>&1; then
  fail "NEGATIVE CONTROL FAILED: the resolver rebuilt from a dump containing conflict markers"
else
  pass "NEGATIVE CONTROL: a dump with conflict markers is REFUSED"
fi

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
[ "$FAIL" = "0" ] || exit 1
exit 0
