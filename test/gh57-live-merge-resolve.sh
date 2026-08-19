#!/usr/bin/env bash
# GH-57 — the RELEASES merge contract, driven by an ACTUAL `git merge`.
#
# WHY THIS EXISTS, when gh53/gh54/gh57-releases-fuzz already cover merges.
#
# Every one of those suites builds its merged dump by hand — `awk '!seen[$0]++'` over two
# `git show` outputs — and then calls the app. That proves what the app does with a mangled dump.
# It does NOT prove what git actually leaves on disk, and it never puts the resolver in front of a
# real conflicted index. Concretely, until this suite the following were all unexercised:
#
#   * that a real merge conflicts BOTH releases.sql and releases.db (the resolver branches on that)
#   * the resolver's two refusals, against a genuinely unmerged tree rather than a simulated one
#   * the full operator path: conflict -> hand-resolve the dump -> resolver -> `git merge --continue`
#   * what the index looks like after the resolver FAILS
#
# The gap was noted on 2026-08-19 as "no PR has touched releases.sql concurrently with development",
# which is true and is exactly why the live path had no coverage: the repo's own traffic never
# produced one. A suite is the only way this path gets exercised before an operator meets it.
#
# Three of the scenarios below found real defects on first run; all three were fixed in the same
# change and are pinned here. See RELEASES-DB-FAQS.md ("What a real merge actually looks like").
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$HERE/.." && pwd)"
APP="$ROOT_DIR/utils/py/releases_app.py"
RESOLVER="$ROOT_DIR/utils/releases-merge-resolve.sh"

pass=0; fail=0
ok()   { if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1" >&2; fail=$((fail+1)); fi }
has()  { printf '%s' "$1" | grep -Fq -- "$2"; }

echo "== test: gh57-live-merge-resolve =="
command -v python3 >/dev/null 2>&1 || { echo "python3 required" >&2; exit 1; }
command -v sqlite3 >/dev/null 2>&1 || { echo "sqlite3 required" >&2; exit 1; }
[ -f "$APP" ]     || { echo "missing app: $APP" >&2; exit 1; }
[ -x "$RESOLVER" ] || { echo "missing resolver: $RESOLVER" >&2; exit 1; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh57-live.XXXXXX")"
. "$HERE/lib/fixture-guard.sh"
fixture_guard_init "$WORK"
cleanup() {
  case "${WORK:-}" in
    "${TMPDIR:-/tmp}"/gh57-live.*) [ -d "$WORK" ] && rm -rf "$WORK" ;;
    *) echo "gh57-live: REFUSING cleanup outside the workspace: ${WORK:-<empty>}" >&2 ;;
  esac
}
trap cleanup EXIT

ra() { local r="$1"; shift; require_fixture "$r" "releases fixture"; python3 "$APP" --root "$r" "$@"; }

# Every path below that reaches a real tool goes through this first. Writing this suite escaped its
# fixture exactly once — `conflicted()` aborted mid-build (see the `local` note there), returned an
# empty string, and `--root ""` sent utils/releases-merge-resolve.sh at THIS repo, which rebuilt the
# production ledger. The resolver now refuses an empty --root, and this guard makes the suite refuse
# to get that far. Two independent stops, because one was already shown to be zero.
fx() {  # <candidate-root> — die unless it is a real fixture under $WORK
  local r="${1:-}"
  [ -n "$r" ] || { echo "gh57-live: ABORT — empty fixture root; a fixture failed to build" >&2; exit 2; }
  require_fixture "$r" "fixture root"
  printf '%s\n' "$r"
}
resolver() { local r; r="$(fx "${1:-}")"; bash "$RESOLVER" --root "$r" 2>&1; }

# Leave a repo sitting in a REAL, unresolved merge conflict on the ledger.
# <name> <extra writes on the side branch> -> repo path
conflicted() {
  # NOTE: one name per `local`. macOS ships bash 3.2, where `local a=$1 b=$WORK/$a` does NOT see
  # `a` — every name in the statement is localized (unset) before any assignment runs, so `$a`
  # tripped `set -u`, aborted this function, and returned an empty path. That is what escaped the
  # fixture and rebuilt the production ledger while this suite was being written.
  local name="$1"
  local extra="${2:-0}"
  local r="$WORK/$name"
  local i=0
  mkdir -p "$r"; require_fixture "$r" "merge fixture"
  git -C "$r" init -q -b main
  git -C "$r" config user.email gh57live@test.invalid
  git -C "$r" config user.name gh57live
  ra "$r" init --slug "$name" >/dev/null
  git -C "$r" add -A; git -C "$r" commit -qm base
  git -C "$r" branch side
  git -C "$r" checkout -q side
  ra "$r" add --version 1.0.0 --status draft --description 'side one.' --tracking-issue TMP-SIDE01 >/dev/null
  while [ "$i" -lt "$extra" ]; do
    ra "$r" add --version "1.$((i+1)).0" --status draft --description 'side extra.' \
      --tracking-issue "TMP-SIDE1$i" >/dev/null
    i=$((i+1))
  done
  git -C "$r" commit -qam side
  git -C "$r" checkout -q main
  ra "$r" add --version 2.0.0 --status draft --description 'main one.' --tracking-issue TMP-MAIN01 >/dev/null
  git -C "$r" commit -qam main
  git -C "$r" merge side -m merge >"$r.merge.log" 2>&1 || true
  printf '%s\n' "$r"
}

# Hand-resolve the dump the way RELEASES-DB-FAQS.md tells an operator to: union both sides' rows,
# keep exactly ONE settings block, and keep the HIGHEST generation header.
resolve_dump() {  # <repo> [override-header-number]
  local r; r="$(fx "${1:-}")"          # same bash 3.2 rule: one name per `local`
  local override="${2:-}"
  local hi lo keep
  hi="$(git -C "$r" show MERGE_HEAD:releases.sql | sed -n 's/^-- generation: \([0-9]*\)$/\1/p' | head -1)"
  lo="$(git -C "$r" show HEAD:releases.sql       | sed -n 's/^-- generation: \([0-9]*\)$/\1/p' | head -1)"
  [ "${lo:-0}" -gt "${hi:-0}" ] && hi="$lo"
  keep="${override:-$hi}"
  { printf -- '-- generation: %s\n' "$keep"
    { git -C "$r" show HEAD:releases.sql; git -C "$r" show MERGE_HEAD:releases.sql; } \
      | grep -v -E '^-- generation: |^INSERT INTO settings\(' | awk '!seen[$0]++'
    git -C "$r" show MERGE_HEAD:releases.sql | grep '^INSERT INTO settings('
  } > "$r/releases.sql"
  git -C "$r" add releases.sql
}

# ── 1. what a real merge actually leaves behind ─────────────────────────────────────────────────
echo "-- 1: the shape of a real conflict"
R1="$(conflicted c1 1)"
U="$(git -C "$R1" diff --name-only --diff-filter=U)"
ok "a concurrent ledger write conflicts BOTH artifacts, not just the dump" \
   "has \"\$U\" 'releases.sql' && has \"\$U\" 'releases.db'"
ok "  and git wrote conflict markers into releases.sql" \
   "[ \"\$(grep -c '^<<<<<<< ' '$R1/releases.sql')\" -ge 1 ]"
ok "  and the conflicted dump carries both sides' generation headers" \
   "[ \"\$(grep -c '^-- generation: ' '$R1/releases.sql')\" -eq 2 ]"

# ── 2. the resolver refuses an unresolved dump, and refuses markers ─────────────────────────────
echo "-- 2: refusals against a genuinely conflicted index"
out="$(resolver "$R1")"; rc=$?
ok "resolver refuses while releases.sql is unmerged (rc=$rc)" "[ $rc -ne 0 ]"
ok "  and says which file needs judgment" "has \"\$out\" 'releases.sql is still unresolved'"
# NOTE: `git diff --cached --name-only` lists BOTH conflicted paths during any in-progress merge —
# that is how git reports unmerged index entries, not evidence of a write. Measure the file instead.
R1_DB_HASH="$(shasum -a 256 "$R1/releases.db" | awk '{print $1}')"
ok "  and did NOT touch the live DB (byte-identical after the refusal)" \
   "[ \"\$(shasum -a 256 '$R1/releases.db' | awk '{print \$1}')\" = \"$R1_DB_HASH\" ]"

# Marker check: stage the file WITH its markers still in it. The unmerged test above no longer
# fires, so this is the only thing standing between markers and a rebuild.
git -C "$R1" add releases.sql
out="$(resolver "$R1")"; rc=$?
ok "resolver refuses a staged dump that still contains conflict markers (rc=$rc)" "[ $rc -ne 0 ]"
ok "  and names the markers as the reason" "has \"\$out\" 'still contains conflict markers'"

# ── 3. the full operator path, end to end, through `git merge --continue` ───────────────────────
echo "-- 3: conflict -> resolve dump -> resolver -> commit"
R3="$(conflicted c3 1)"
resolve_dump "$R3"
out="$(resolver "$R3")"; rc=$?
ok "resolver completes a real hand-resolved merge (rc=$rc)" "[ $rc -eq 0 ]"
ok "  and says it deliberately did not commit" "has \"\$out\" 'does not commit'"
ok "  and left no unmerged paths" "[ -z \"\$(git -C '$R3' diff --name-only --diff-filter=U)\" ]"
out2="$(ra "$R3" check 2>&1)"; rc2=$?
ok "  and the ledger checks clean afterwards" "[ $rc2 -eq 0 ] && has \"\$out2\" 'check: clean'"
ok "  and BOTH sides' releases survived the merge" \
   "[ \"\$(sqlite3 '$R3/releases.db' 'SELECT COUNT(*) FROM releases')\" -eq 3 ]"
git -C "$R3" commit -q --no-edit >/dev/null 2>&1
ok "  and \`git commit\` closes the merge" \
   "[ -z \"\$(git -C '$R3' rev-parse --verify -q MERGE_HEAD 2>/dev/null)\" ]"
ok "  and the committed tree carries both artifacts" \
   "git -C '$R3' show --stat HEAD | grep -q releases.sql && git -C '$R3' show --stat HEAD | grep -q releases.db"

# ── 4. EDGE CASE: a failed resolver must leave the merge genuinely open ─────────────────────────
# Found broken 2026-08-19: the resolver staged releases.db BEFORE attempting the rebuild, so a
# failing run had already marked half the merge resolved while its own error text said "nothing was
# staged over it". An operator who trusted that line and ran `git commit` would have committed the
# stale --ours DB against a dump it does not match — the silent divergence #52/#53 exist to stop.
echo "-- 4: the failure path leaves the merge open (regression: it did not)"
R4="$(conflicted c4 0)"
resolve_dump "$R4"
# Append a second, DIFFERING row for a GID the resolved dump already contains: a content conflict
# no union can settle. Derive it from the merged dump itself — reading the GID out of the worktree
# releases.db gives you the OURS side's release, which by construction is absent from MERGE_HEAD's
# dump, so the duplicate never got appended and this scenario silently tested nothing.
R4_ROW="$(grep -m1 '^INSERT INTO releases(' "$R4/releases.sql")"
ok "fixture has a release row to duplicate" "[ -n \"\$R4_ROW\" ]"
printf '%s\n' "$R4_ROW" | sed "s/one\./one EDITED ON THE OTHER BRANCH./" >> "$R4/releases.sql"
R4_GID="$(printf '%s' "$R4_ROW" | grep -o 'rel-[A-Z0-9]*' | head -1)"
ok "  and that GID now appears twice in the dump" \
   "[ \"\$(grep -c \"\$R4_GID\" '$R4/releases.sql')\" -gt 1 ]"
git -C "$R4" add releases.sql
out="$(resolver "$R4")"; rc=$?
ok "resolver fails on an unsettleable content conflict (rc=$rc)" "[ $rc -ne 0 ]"
ok "  and releases.db is STILL unmerged — the merge is open, as the message claims" \
   "git -C '$R4' diff --name-only --diff-filter=U | grep -qx releases.db"

# ── 5. EDGE CASE: keeping the LOWER generation header must be refused ───────────────────────────
# Found broken 2026-08-19: this returned rc=0 and then `check: clean`, with the ledger's generation
# counter rewound below a merge parent's. The advice to keep the highest header existed only inside
# another refusal's prose; nothing enforced it, so the one resolution that loses information was
# also the one nothing complained about.
echo "-- 5: a rewound generation header is refused (regression: it was accepted)"
R5="$(conflicted c5 2)"
LOW="$(git -C "$R5" show HEAD:releases.sql | sed -n 's/^-- generation: \([0-9]*\)$/\1/p' | head -1)"
HIGH="$(git -C "$R5" show MERGE_HEAD:releases.sql | sed -n 's/^-- generation: \([0-9]*\)$/\1/p' | head -1)"
ok "fixture really has unequal parent generations (HEAD=$LOW MERGE_HEAD=$HIGH)" "[ \"$LOW\" -lt \"$HIGH\" ]"
resolve_dump "$R5" "$LOW"
out="$(resolver "$R5")"; rc=$?
ok "resolver refuses a header below the highest parent (rc=$rc)" "[ $rc -ne 0 ]"
ok "  and names both parents' generations" "has \"\$out\" \"$LOW (HEAD)\" && has \"\$out\" \"$HIGH (MERGE_HEAD)\""
ok "  and says what to set it to" "has \"\$out\" 'Set the header to $HIGH'"
# POSITIVE CONTROL: the same fixture with the correct header must succeed, or the check above is
# just refusing everything.
resolve_dump "$R5"
out="$(resolver "$R5")"; rc=$?
ok "POSITIVE CONTROL: the SAME merge with the highest header resolves cleanly (rc=$rc)" "[ $rc -eq 0 ]"
ok "  and the ledger's generation did not go backwards" \
   "[ \"\$(sqlite3 '$R5/releases.db' \"SELECT value FROM settings WHERE key='generation'\")\" -gt \"$HIGH\" ]"

# ── 6. EDGE CASE: the displaced DB backup must never be committable ─────────────────────────────
# The resolver tells the operator releases.db.bak is "untracked and safe to delete". It was not
# ignored, so a `git add -A` before `git merge --continue` would have committed a stale binary copy
# of the ledger — the one artifact guaranteed to disagree with the dump.
echo "-- 6: releases.db.bak is ignored, not merely unmentioned"
ok "the rebuild really produced a .bak to worry about" "[ -f '$R3/releases.db.bak' ]"
ok "this repo's .gitignore covers releases.db.bak" \
   "git -C '$ROOT_DIR' check-ignore -q releases.db.bak"

# ── 7. EDGE CASE: an explicitly empty --root must be refused, not silently retargeted ──────────
# This is here because it actually happened. While writing this suite, `conflicted()` aborted on a
# bash 3.2 `local` quirk and returned "", the call became `--root ""`, the resolver fell back to
# `git rev-parse --show-toplevel`, and it REBUILT THIS REPO'S PRODUCTION LEDGER (generation 6 -> 12;
# recovered from HEAD). "No --root" and "--root with an empty value" are different statements and
# must not share a code path.
echo "-- 7: --root '' is a caller bug, not a request for the current repo"
out="$(bash "$RESOLVER" --root "" 2>&1)"; rc=$?
ok "resolver refuses an explicitly empty --root (rc=$rc)" "[ $rc -ne 0 ]"
ok "  and says it will not fall back to the current repository" \
   "has \"\$out\" 'Refusing to fall back'"
ok "  and this repo's ledger was not touched by that call" \
   "[ -z \"\$(git -C '$ROOT_DIR' status --porcelain releases.db releases.sql)\" ]"

echo
echo "  gh57-live-merge-resolve: $pass pass, $fail fail"
[ "$fail" -eq 0 ]
