#!/usr/bin/env bash
# GH-703: roadmap add's synthesized raw_text must satisfy the renderer grammar.
set -euo pipefail
source "$(dirname "$0")/_setup.sh" "GH-703" || { echo "setup failed"; exit 1; }

root="$(cd "$HERE/.." && pwd)"
app="$root/utils/py/releases_app.py"

make_repo() {
  local repo="$1"
  mkdir -p "$repo/PROJECT/1-INBOX"
  git init -q "$repo"
  git -C "$repo" -c user.email=t@t -c user.name=t commit -q --allow-empty -m base
  printf '%s\n' 'ROADMAP_SOURCE=releases' > "$repo/.pdda-mode"
  : > "$repo/PROJECT/1-INBOX/GH-703-test.md"
  python3 "$app" --root "$repo" init --slug test-repo >/dev/null
}

add_without_raw_text() {
  local executable="$1" repo="$2"
  python3 "$executable" --root "$repo" roadmap add \
    --issue-num 703 \
    --issue-url 'https://github.com/org/repo/issues/703' \
    --title 'a/*/b' \
    --created '2026-09-22' \
    --doc-path 'PROJECT/1-INBOX/GH-703-test.md' \
    --dry-run
}

# Red control: remove only the candidate validation call from a disposable copy. The pre-fix
# implementation accepts the title and prints raw_text that roadmap_render() would later drop.
old_app="$WORK/releases_app_pre_gh703.py"
awk '$0 != "            raw_text = validate_raw_text(raw_text, args.issue_num)" { print }' \
  "$app" > "$old_app"
old_repo="$WORK/pre-fix"
make_repo "$old_repo"
old_out="$(add_without_raw_text "$old_app" "$old_repo")" \
  || fail "red control should reproduce pre-fix acceptance"
case "$old_out" in
  *'a/*/b'*) pass "red control reproduced pre-fix acceptance of unrenderable fallback" ;;
  *) fail "red control did not emit the synthesized asterisk title: $old_out" ;;
esac

# Candidate: the same direct add is refused by the shared raw-text validator.
repo="$WORK/candidate"
make_repo "$repo"
rc=0
out="$(add_without_raw_text "$app" "$repo" 2>&1)" || rc=$?
[ "$rc" -ne 0 ] || fail "roadmap add without --raw-text accepted unrenderable title"
case "$out" in
  *'rule=invalid-raw-text'*) pass "direct roadmap add rejects synthesized unrenderable raw_text" ;;
  *) fail "expected invalid-raw-text refusal, got: $out" ;;
esac

echo "== result: $PASS passed, $FAIL failed =="
[ "$FAIL" -eq 0 ]
