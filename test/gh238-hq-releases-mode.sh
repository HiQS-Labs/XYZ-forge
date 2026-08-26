#!/bin/bash
set -eu
source test/_setup.sh "GH-238" || { echo "setup failed"; exit 1; }

root="$(cd "$HERE/.." && pwd)"

echo "== test: GH-238 releases roadmap add CLI =="

# Setup a releases DB
mkdir -p "$WORK/target"
cd "$WORK/target"
git init >/dev/null 2>&1
python3 "$root/utils/py/releases_app.py" init >/dev/null

# 1. CLI dry-run
out="$(python3 "$root/utils/py/releases_app.py" roadmap add --issue-num 101 --issue-url "https://gh/101" --title "Test 1" --created 2026-08-25 --doc-path "PROJECT/1-INBOX/GH-101-test.md" --dry-run)"
grep -q "ROADMAP line: " <<<"$out" || fail "dry-run missing line output"

# 2. CLI happy path
python3 "$root/utils/py/releases_app.py" roadmap add --issue-num 101 --issue-url "https://gh/101" --title "Test 1" --created 2026-08-25 --doc-path "PROJECT/1-INBOX/GH-101-test.md" >/dev/null || fail "happy path failed"

# 3. CLI dup-guard
! python3 "$root/utils/py/releases_app.py" roadmap add --issue-num 101 --issue-url "https://gh/101" --title "Test 1" --created 2026-08-25 --doc-path "PROJECT/1-INBOX/GH-101-test.md" 2>err || fail "dup guard allowed second write"
grep -q "roadmap-duplicate" err || fail "missing dup error rule"

# 4. Receipt row present
grep -q "roadmap-add" <<<"$(sqlite3 releases.db "SELECT op FROM op_receipts ORDER BY id DESC LIMIT 1")" || fail "missing op_receipts entry"

# 5. Dump regenerated
grep -q "Test 1" releases.sql || fail "releases.sql dump missing written row"

# 6. roadmap sync is a clean no-op in releases-mode (it mirrors ROADMAP.md and would DELETE
#    rows parked by `roadmap add`; wave_reconcile.py calls it unconditionally post-merge)
echo "ROADMAP_SOURCE=releases" > .pdda-mode
out="$(python3 "$root/utils/py/releases_app.py" roadmap sync)"
grep -q "skipped — releases-mode" <<<"$out" || fail "sync did not skip in releases-mode"
[ "$(sqlite3 releases.db "SELECT COUNT(*) FROM roadmap_items")" = "1" ] || fail "sync deleted the add-parked row"
rm .pdda-mode

echo "  PASS: CLI tests"

echo "== test: GH-238 hq.sh releases-mode =="

export XYZ_PATH="$root" # mock xyz installed
export HQ_SEARCH_ROOTS="$WORK"

cat << 'MOCK' > "$WORK/mock-gh.sh"
#!/bin/bash
if [ "$1" = "issue" ] && [ "$2" = "list" ]; then echo "[]"; exit 0; fi
if [ "$1" = "issue" ] && [ "$2" = "create" ]; then echo "https://github.com/HiQS-Labs/XYZ-forge/issues/102"; exit 0; fi
exit 1
MOCK
chmod +x "$WORK/mock-gh.sh"
export HQ_GH_BIN="$WORK/mock-gh.sh"

# 1. hq.sh without releases-mode (baseline)
mkdir -p "$WORK/repo-baseline"
cd "$WORK/repo-baseline"
git init >/dev/null 2>&1
touch .pdda-mode ROADMAP.md
mkdir -p PROJECT/1-INBOX
cd "$root"
out="$(bash utils/hq/hq.sh park "repo-baseline" "test req")"
grep -q "ROADMAP line:" <<<"$out" || fail "baseline preview sink wrong"

out="$(bash utils/hq/hq.sh park "repo-baseline" "test req" --create)"
grep -q "ROADMAP: pointer added" <<<"$out" || fail "baseline write failed"
grep -q "test req" "$WORK/repo-baseline/ROADMAP.md" || fail "ROADMAP.md was not written"

# 2. hq.sh WITH releases-mode
mkdir -p "$WORK/repo-releases/utils/py"
cp "$root/utils/py/releases_app.py" "$WORK/repo-releases/utils/py/"
cd "$WORK/repo-releases"
git init >/dev/null 2>&1
echo "ROADMAP_SOURCE=releases" > .pdda-mode
python3 utils/py/releases_app.py init >/dev/null
cd "$root"

out="$(bash utils/hq/hq.sh park "repo-releases" "test req releases")"
grep -q "ROADMAP sink: releases roadmap add" <<<"$out" || fail "releases-mode preview sink wrong"

out="$(bash utils/hq/hq.sh park "repo-releases" "test req releases" --create)"
grep -q "DB: pointer added via releases CLI" <<<"$out" || fail "releases write failed"

# Check DB was written
grep -q "test req releases" <<<"$(sqlite3 "$WORK/repo-releases/releases.db" "SELECT title FROM roadmap_items")" || fail "releases DB was not written"

# 3. Vendored .xyz/ layout — hq_releases_bin's fallback must find the CLI there
mkdir -p "$WORK/repo-vendored/.xyz/utils/py"
cp "$root/utils/py/releases_app.py" "$WORK/repo-vendored/.xyz/utils/py/"
cd "$WORK/repo-vendored"
git init >/dev/null 2>&1
echo "ROADMAP_SOURCE=releases" > .pdda-mode
python3 .xyz/utils/py/releases_app.py init >/dev/null
cd "$root"
out="$(bash utils/hq/hq.sh park "repo-vendored" "test req vendored" --create)"
grep -q "DB: pointer added via releases CLI" <<<"$out" || fail "vendored .xyz/ layout write failed"
grep -q "test req vendored" <<<"$(sqlite3 "$WORK/repo-vendored/releases.db" "SELECT title FROM roadmap_items")" || fail "vendored releases DB was not written"

# 4. Failure mode (no DB) — scratch stays in $WORK, never the repo root (AGENTS.md)
rm "$WORK/repo-releases/releases.db"
! bash utils/hq/hq.sh park "repo-releases" "test req fails" --create >"$WORK/out" 2>"$WORK/err" || fail "failure mode did not abort"
grep -q "releases roadmap add failed" "$WORK/err" || fail "did not print failure error"
! grep -q "ROADMAP: pointer added" "$WORK/out" || fail "failure mode fell back to ROADMAP.md text append"

echo "  PASS: hq.sh tests"
echo "== GH-238 ALL PASSED =="
