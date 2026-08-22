#!/usr/bin/env bash
# GH-32 / #52 — the committed RELEASES artifacts must agree with each other.
#
# `gh32-releases-app.sh` proves the CLI behaves, in fixtures. It says nothing about the
# releases.db / releases.sql pair actually committed in THIS repo. That gap is the one this suite
# closes, and it exists because the documented merge procedure has a human step: resolve
# releases.sql as text, then `releases check --rebuild` to regenerate the DB from it. Skip the
# rebuild and you commit a DB that disagrees with the dump — silently, because the DB is what every
# reader trusts at runtime (list, show, next and `project sync` all read the DB, never the dump).
#
# TWO RULES THIS SUITE OBEYS, both deliberate:
#
#   1. READ-ONLY, NEVER --rebuild. A gate that silently repairs destroys the evidence that a merge
#      was mis-resolved. Reporting divergence is the job; repair stays a human decision.
#
#   2. It never runs the app against the real clone. Plain `check` is *almost* read-only — but when
#      an intent journal is live it calls recover_from_journal(), which WRITES. A gate must not
#      mutate the repo it is checking, so the artifacts are copied into a fixture and checked there.
#      The clone's own bytes are hashed before and after to prove nothing moved (GH-564 shape: a
#      suite that touches the caller's clone is the class this repo has already been bitten by).
#
# Negative control is asserted here, not assumed: the same check must go RED on a deliberately
# divergent dump. Without that half, this suite passes forever on a healthy repo and proves nothing.
# Recorded in test/baselines/GH-52-negative-control.md.
#
# Usage: bash test/gh32-releases-artifacts.sh
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$HERE/.." && pwd)"
# shellcheck source=/dev/null
source "$HERE/_setup.sh" gh32-releases-artifacts

APP="$ROOT_DIR/utils/py/releases_app.py"

command -v python3 >/dev/null 2>&1 || { echo "python3 required" >&2; exit 1; }
[ -f "$APP" ] || fail "releases_app.py not found at $APP"

# The artifacts under test. RELEASES.generated.md is deliberately NOT copied: it is gitignored, so
# it is not part of what a merge can break, and depending on an untracked file would make this
# suite's verdict differ between clones — the exact defect GH-37 was.
ARTIFACTS="releases.db releases.sql"

digest_live() { # hash the clone's artifacts so we can prove we did not touch them
  local f out=""
  for f in $ARTIFACTS; do
    [ -f "$ROOT_DIR/$f" ] && out="$out$(file_hash "$ROOT_DIR/$f") $f
"
  done
  printf '%s' "$out"
}

file_hash() { # portable: sha256sum -> shasum -a 256 -> md5 (GH-65)
  local f="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$f" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$f" | awk '{print $1}'
  else
    md5 -q "$f"
  fi
}

seed_fixture() { # <dir> — copy the clone's artifacts into an isolated fixture
  local d="$1" f
  case "$d" in "$WORK"/*) ;; *) echo "REFUSING: $d outside WORK" >&2; exit 2 ;; esac
  mkdir -p "$d"
  # The app resolves its writer lock and journal through the git common-dir (GH-448), so the
  # fixture must be a git checkout or every command refuses with rule=not-a-git-repo. `git init`
  # here also guarantees the lock lands in the FIXTURE's .git, never this clone's.
  git -C "$d" init -q
  git -C "$d" config user.email t@t
  git -C "$d" config user.name t
  for f in $ARTIFACTS; do
    [ -f "$ROOT_DIR/$f" ] && cp "$ROOT_DIR/$f" "$d/$f"
  done
}

BEFORE="$(digest_live)"

# ── 1. the committed pair agrees ────────────────────────────────────────────────────────────────
LIVE="$WORK/live"
seed_fixture "$LIVE"

[ -f "$LIVE/releases.db" ] \
  && pass "releases.db is present in this clone" \
  || fail "releases.db is missing — the ledger's runtime truth is not committed"
[ -f "$LIVE/releases.sql" ] \
  && pass "releases.sql is present in this clone" \
  || fail "releases.sql is missing — nothing to merge or rebuild from"

CHECK_OUT="$WORK/check.out"
python3 "$APP" --root "$LIVE" check > "$CHECK_OUT" 2>&1
CHECK_RC=$?

if [ "$CHECK_RC" = "0" ]; then
  pass "releases check is clean against the committed artifacts (rc=0)"
else
  echo "  ---- releases check output ----" >&2
  sed 's/^/  /' "$CHECK_OUT" >&2
  echo "  -------------------------------" >&2
  fail "releases check FAILED (rc=$CHECK_RC) against the committed artifacts — the DB and the dump disagree. If this followed a merge, the resolution skipped 'releases check --rebuild'; see RELEASES-DB-FAQS.md"
fi

grep -q "generation trio consistent" "$CHECK_OUT" \
  && pass "the generation trio is consistent (DB <-> dump)" \
  || fail "check did not report a consistent generation trio; see $CHECK_OUT"

grep -q "receipt chain intact" "$CHECK_OUT" \
  && pass "the op_receipt digest chain is intact" \
  || fail "check did not report an intact receipt chain; see $CHECK_OUT"

# ── 2. containment: the clone's own artifacts were not touched ──────────────────────────────────
AFTER="$(digest_live)"
[ "$BEFORE" = "$AFTER" ] \
  && pass "the clone's artifacts are byte-identical after the check (the gate did not write to the repo it checks)" \
  || fail "the clone's artifacts CHANGED during this suite — a read-only gate wrote to the caller's clone"

[ ! -f "$ROOT_DIR/releases.db.bak" ] \
  && pass "no releases.db.bak was produced (this suite never runs --rebuild)" \
  || fail "a releases.db.bak exists in the clone — something ran --rebuild; a gate must never repair"

# ── 3. NEGATIVE CONTROL: the same check must go red on a divergent dump ─────────────────────────
# Without this, every assertion above is satisfiable by a check that can never fail.
BROKEN="$WORK/broken"
seed_fixture "$BROKEN"

if [ -f "$BROKEN/releases.sql" ]; then
  # Perturb the dump so it no longer equals the canonical dump of the DB. Appending a comment is
  # enough: dump_text() is byte-compared, and a comment cannot be mistaken for a real edit.
  printf '\n-- deliberate divergence introduced by test/gh32-releases-artifacts.sh\n' >> "$BROKEN/releases.sql"

  python3 "$APP" --root "$BROKEN" check > "$WORK/broken.out" 2>&1
  BROKEN_RC=$?

  [ "$BROKEN_RC" != "0" ] \
    && pass "NEGATIVE CONTROL: a divergent dump makes check fail (rc=$BROKEN_RC) — the assertion above is falsifiable" \
    || fail "NEGATIVE CONTROL FAILED: check returned 0 on a deliberately divergent dump; this suite proves nothing"

  grep -q "dump-divergence" "$WORK/broken.out" \
    && pass "NEGATIVE CONTROL: the failure names rule=dump-divergence (the operator is told which rule broke)" \
    || fail "the divergence failure did not name dump-divergence; see $WORK/broken.out"

  # and the real clone is STILL untouched after the negative control
  [ "$(digest_live)" = "$BEFORE" ] \
    && pass "the clone is still byte-identical after the negative control" \
    || fail "the negative control mutated the caller's clone"
else
  fail "could not seed the negative control — releases.sql missing"
fi

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
[ "$FAIL" = "0" ] || exit 1
exit 0
