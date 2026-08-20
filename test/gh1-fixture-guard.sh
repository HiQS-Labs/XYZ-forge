#!/usr/bin/env bash
set -uo pipefail
#
# gh1-fixture-guard.sh — GH-1: the shared fixture guard and the clone-identity invariant gate.
#
# Proves the discriminating cases for test/lib/fixture-guard.sh (the GH-564 helper, hardened per
# the GH-567 residual: the lexical prefix test alone accepts `$WORK/../../<real repo>`) and for
# test/lib/clone-identity.sh (a mutation of the clone's identity between capture and assert must
# fail the assert; an untouched clone must pass).
#
# The negative cases intentionally subshell — the guard's contract on refusal is `exit 2`, and the
# suite must survive to report every case rather than die on the first refusal.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GUARD="$HERE/lib/fixture-guard.sh"
IDENTITY="$HERE/lib/clone-identity.sh"

pass=0; fail=0
ok(){ if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }

echo "== test: gh1-fixture-guard =="

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh1-guard.XXXXXX")"
# GH-10: file-scope adoption so the derivation sees the standard shape (the per-case
# subshells below re-source and re-init against the SAME root — idempotent).
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/fixture-guard.sh"
fixture_guard_init "$WORK"
[ -n "$WORK" ] && [ -d "$WORK" ] || { echo "mktemp failed" >&2; exit 1; }
cleanup(){ [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
trap cleanup EXIT

mkdir -p "$WORK/repo"
echo x > "$WORK/file"

# --- fixture-guard: the guard itself ---
g(){ ( . "$GUARD"; fixture_guard_init "$WORK"; require_fixture "$@" ) ; }

ok "empty path is refused (the GH-564 kill)" \
   'g "" "label"; [ $? -eq 2 ]'
ok "a path outside \$WORK is refused" \
   'g /etc "label"; [ $? -eq 2 ]'
ok "TRAVERSAL escape \$WORK/../../etc is refused (lexical check alone would accept it)" \
   'g "$WORK/../../etc" "label"; [ $? -eq 2 ]'
ok "symlink escape (in-bounds lexical path pointing outside) is refused" \
   'ln -sfn /etc "$WORK/out"; g "$WORK/out" "label"; [ $? -eq 2 ]'
ok "the sandbox root itself is refused as a fixture" \
   'g "$WORK" "label"; [ $? -eq 2 ]'
ok "a real in-bounds subdirectory is accepted" \
   'g "$WORK/repo" "label"'
ok "a file is refused by require_fixture (directory expected)" \
   'g "$WORK/file" "label"; [ $? -eq 2 ]'
ok "a file is accepted by require_fixture_file" \
   '( . "$GUARD"; fixture_guard_init "$WORK"; require_fixture_file "$WORK/file" "label" )'
ok "require_fixture refuses everything when fixture_guard_init was not called" \
   '( . "$GUARD"; require_fixture "$WORK/repo" "label" ); [ $? -eq 2 ]'
ok "require_fixture /etc without init is refused — the init check must not depend on statement order" \
   '( . "$GUARD"; require_fixture /etc "label" ); [ $? -eq 2 ]'
ok "a symlink pointing INSIDE \$WORK is accepted (resolved descendant)" \
   'ln -sfn "$WORK/repo" "$WORK/alias"; ( . "$GUARD"; fixture_guard_init "$WORK"; require_fixture "$WORK/alias" "label" )'

# --- clone-identity: the suite-wide invariant bracket ---
IR="$(mktemp -d "$WORK/repo.XXXXXX")"
git -C "$IR" init -q
git -C "$IR" config user.email t@t
git -C "$IR" config user.name t
echo x > "$IR/f"; git -C "$IR" add f; git -C "$IR" commit -qm x

ok "capture then assert with no change passes" \
   '"$IDENTITY" capture "$WORK/id.before" "$IR" && "$IDENTITY" assert "$WORK/id.before" "$IR"'
ok "core.bare flip between capture and assert FAILS the assert" \
   '"$IDENTITY" capture "$WORK/id2.before" "$IR" && git -C "$IR" config core.bare true && ! "$IDENTITY" assert "$WORK/id2.before" "$IR"; rc=$?; git -C "$IR" config --unset core.bare; [ "$rc" -eq 0 ]'
ok "remote rewrite between capture and assert FAILS the assert (the GH-564 incident)" \
   '"$IDENTITY" capture "$WORK/id3.before" "$IR" && git -C "$IR" remote add origin https://example.invalid/x.git && ! "$IDENTITY" assert "$WORK/id3.before" "$IR"; rc=$?; git -C "$IR" remote remove origin; [ "$rc" -eq 0 ]'
ok "local user identity change between capture and assert FAILS the assert" \
   '"$IDENTITY" capture "$WORK/id4.before" "$IR" && git -C "$IR" config --local user.email other@t && ! "$IDENTITY" assert "$WORK/id4.before" "$IR"; rc=$?; git -C "$IR" config --local user.email t@t; [ "$rc" -eq 0 ]'
ok "HEAD move between capture and assert FAILS the assert" \
   '"$IDENTITY" capture "$WORK/id5.before" "$IR" && git -C "$IR" commit --allow-empty -qm y && ! "$IDENTITY" assert "$WORK/id5.before" "$IR"; rc=$?; git -C "$IR" reset -q --hard HEAD~1; [ "$rc" -eq 0 ]'
ok "assert with a missing snapshot file exits 2" \
   '"$IDENTITY" assert "$WORK/nope" "$IR"; [ $? -eq 2 ]'

echo
echo "== gh1-fixture-guard: $pass passed, $fail failed =="
[ "$fail" -eq 0 ]
