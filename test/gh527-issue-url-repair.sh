#!/usr/bin/env bash
# gh527-issue-url-repair.sh — roadmap_items.issue_url must be repairable, and one row whose
# issue_url disagrees with its gh_number must not disable `reconcile-state` for every other row.
#
# WHY: GH-61's row was imported with the issue_url of #62 — the legacy ROADMAP.md importer took
# the FIRST issue link in a line that mentioned four child issues before its own `→ [#61]`
# pointer. Nothing could then repair it: `roadmap add` writes issue_url only at intake, `roadmap
# sync` is a hard no-op in a releases-mode repo, and `update`/`repoint`/`move` cannot set the
# column. A direct sqlite3 write is caught by both `dump-divergence` and `receipt-chain`. So a
# single bad cell refused `reconcile-state` outright, stranding 152 healthy rows (#527).
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
APP="$ROOT/utils/py/releases_app.py"

PASS=0
FAIL=0
ok()   { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }
check(){ if [ "$1" = "$2" ]; then ok "$3"; else bad "$3 (expected [$2], got [$1])"; fi; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh527.XXXXXX")"
# GH-177: prove the fixture root exists BEFORE the trap that deletes it and before any cd. A
# sandbox-broken mktemp returns empty, and an unguarded `rm -rf "$WORK"` / `cd "$WORK"` then acts
# on the wrong directory — that is what wiped this repo twice.
[ -n "$WORK" ] || { echo "gh527: mktemp -d returned empty; refusing to continue" >&2 && exit 1; }
[ -d "$WORK" ] || { echo "gh527: mktemp -d root is not a directory; refusing" >&2 && exit 1; }
trap 'rm -rf "$WORK"' EXIT
. "$HERE/lib/fixture-guard.sh"   # GH-10: shared fixture containment
fixture_guard_init "$WORK"       # GH-10: pin the sandbox root

# releases_app refuses to run outside a git checkout (GH-448), so the fixture is a real repo.
# Everything below addresses the fixture by absolute path — `git -C`, `--root` — and this script
# never changes its own cwd. GH-177: a bare `cd "$WORK"` is unsafe no matter how well guarded,
# because `cd ""` silently no-ops in place, so the whole shape is avoided rather than defended.
git init -q "$WORK"
git -C "$WORK" config user.email t@example.com
git -C "$WORK" config user.name t
python3 "$APP" --root "$WORK" init >/dev/null
# GH-10: every path this suite writes must be provably inside the pinned sandbox, never a real repo.
require_fixture "$WORK/.git" "gh527 fixture git dir"
require_fixture_file "$WORK/releases.db" "gh527 fixture ledger DB"

park() { # park <issue-num> <title>
  python3 "$APP" --root "$WORK" roadmap add \
    --issue-num "$1" --issue-url "https://github.com/o/r/issues/$1" \
    --title "$2" --created 2026-01-01 --doc-path "PROJECT/1-INBOX/GH-$1.md" \
    --raw-text "- **GH-$1 · $2** 🆕 rated 50/50/50/50" >/dev/null
}
park 900 "healthy row"
park 901 "row that will be corrupted"

# --- 0. intake must not be able to CREATE the defect --------------------------------------------
# The legacy importer that created GH-61's row is retired, but before #527 `roadmap add` accepted
# a mismatched issue_url with no complaint and wrote a receipted, wrong row that `check` called
# clean. A repair verb alone would patch a hole that was still open.
set +e
out="$(python3 "$APP" --root "$WORK" roadmap add --issue-num 903 \
        --issue-url "https://github.com/o/r/issues/904" --title "mismatch at intake" \
        --created 2026-01-01 --doc-path "PROJECT/1-INBOX/GH-903.md" \
        --raw-text "- **GH-903 · mismatch at intake** 🆕 rated 50/50/50/50" 2>&1)"; rc=$?
set -e
check "$rc" "3" "intake refuses an issue_url that names a different issue"

# Corrupt 901 the way the legacy importer did: a real URL naming a DIFFERENT issue. By hand,
# because intake now refuses it and no other verb could write the column before #527. The rebuild
# re-baselines the dump and receipt chain so the WRONG-BUT-CONSISTENT row is the starting state —
# which is exactly the shape GH-61 was in: bad data, valid chain, clean check.
# `check --rebuild` is dump -> DB, so the corruption is written into releases.sql and rebuilt in.
# Corrupting the DB directly would be undone by the very rebuild that re-baselines the chain.
corrupt_901() {
  python3 - "$WORK" <<'PY'
import re, sys
p = sys.argv[1] + "/releases.sql"
s = open(p, encoding="utf-8").read()
new = re.sub(r"(VALUES\([^)]*?'901',[^)]*?)https://github\.com/o/r/issues/901",
             r"\1https://github.com/o/r/issues/902", s)
assert new != s, "fixture: failed to corrupt GH-901's issue_url in the dump"
open(p, "w", encoding="utf-8").write(new)
PY
  python3 "$APP" --root "$WORK" check --rebuild >/dev/null 2>&1 || true
  rm -f "$WORK"/releases.db.bak
}
corrupt_901
set +e
python3 "$APP" --root "$WORK" check >/dev/null 2>&1; rc=$?
set -e
check "$rc" "0" "fixture baseline is consistent (bad data, valid chain) like GH-61 was"

# --- 1. the repair verb exists and is validated -------------------------------------------------
set +e
out="$(python3 "$APP" --root "$WORK" roadmap update --issue-num 901 \
        --issue-url "https://github.com/o/r/issues/902" 2>&1)"; rc=$?
set -e
check "$rc" "3" "a URL naming a different issue than gh_number is refused"
case "$out" in *"must agree"*) ok "refusal names the invariant" ;;
               *) bad "refusal should explain the gh_number/issue_url invariant: $out" ;; esac

set +e
out="$(python3 "$APP" --root "$WORK" roadmap update --issue-num 901 --issue-url "not-a-url" 2>&1)"
rc=$?
set -e
check "$rc" "3" "a non-issue URL is refused"

set +e
out="$(python3 "$APP" --root "$WORK" roadmap update --issue-num 901 2>&1)"; rc=$?
set -e
check "$rc" "3" "update with no field to change is still refused"

# --- 2. the repair works, and leaves the ledger consistent --------------------------------------
python3 "$APP" --root "$WORK" roadmap update --issue-num 901 \
  --issue-url "https://github.com/o/r/issues/901" >/dev/null
got="$(python3 - "$WORK" <<'PY'
import sqlite3, sys
c = sqlite3.connect(sys.argv[1] + "/releases.db")
print(c.execute("select issue_url from roadmap_items where gh_number=901").fetchone()[0])
PY
)"
check "$got" "https://github.com/o/r/issues/901" "issue_url is corrected"

# The repair must be receipted like every other write — a receipt-less mutation is what the
# receipt-chain guard exists to catch, and it is the reason direct SQL was never the answer.
recs="$(python3 - "$WORK" <<'PY'
import sqlite3, sys
c = sqlite3.connect(sys.argv[1] + "/releases.db")
print(c.execute("select count(*) from op_receipts where op='roadmap-update'").fetchone()[0])
PY
)"
if [ "$recs" -ge 1 ]; then ok "the repair wrote an op_receipt"; else bad "repair left no receipt"; fi

set +e
python3 "$APP" --root "$WORK" check >/dev/null 2>&1; rc=$?
set -e
check "$rc" "0" "check is clean after a CLI repair (no dump-divergence, no receipt-chain break)"

# --- 3. one unresolvable row must not disable the whole sweep -----------------------------------
# Re-corrupt 901, then prove 900 is still reconcilable. `gh` is stubbed so the test never touches
# the network: every issue reads CLOSED, so a reconcilable row MUST move.
corrupt_901

cat > "$WORK/fake-gh" <<'SH'
#!/usr/bin/env bash
echo '{"state":"CLOSED","stateReason":"COMPLETED"}'
SH
chmod +x "$WORK/fake-gh"

set +e
out="$(RELEASES_GH_BIN="$WORK/fake-gh" python3 "$APP" --root "$WORK" \
       roadmap reconcile-state --dry-run 2>&1)"; rc=$?
set -e
check "$rc" "0" "reconcile-state no longer refuses the whole run over one bad row"
case "$out" in *"GH-900"*) ok "the healthy row is still reconciled" ;;
               *) bad "healthy row GH-900 was stranded: $out" ;; esac
case "$out" in *"GH-901"*) ok "the unresolvable row is named, not silently dropped" ;;
               *) bad "unresolvable row GH-901 was not reported: $out" ;; esac
case "$out" in *"roadmap update --issue-num 901"*) ok "the warning names the repair command" ;;
               *) bad "warning should point at the repair verb: $out" ;; esac

# The skip must never be mistaken for a verdict: 901 stays put.
set +e
RELEASES_GH_BIN="$WORK/fake-gh" python3 "$APP" --root "$WORK" \
  roadmap reconcile-state --apply >"$WORK/apply.out" 2>&1
rc=$?
set -e
check "$rc" "0" "mixed-row apply succeeds"
[ "$rc" -eq 0 ] || cat "$WORK/apply.out"
sec="$(python3 - "$WORK" <<'PY'
import sqlite3, sys
c = sqlite3.connect(sys.argv[1] + "/releases.db")
print(c.execute("select section from roadmap_items where gh_number=901").fetchone()[0])
PY
)"
check "$sec" "Queue / parked intake" "the skipped row's state was never guessed"
python3 - "$WORK" <<'PYVERIFY'
import sqlite3, sys
with sqlite3.connect(sys.argv[1] + "/releases.db") as c:
    assert c.execute("select section from roadmap_items where gh_number=900").fetchone()[0] == "Completed"
    assert c.execute("select count(*) from op_receipts where op='roadmap-reconcile-state'").fetchone()[0] == 1
PYVERIFY
ok "mixed-row apply moves the healthy row and records one receipt"
python3 "$APP" --root "$WORK" check >/dev/null
ok "ledger remains consistent after mixed-row apply"


printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
