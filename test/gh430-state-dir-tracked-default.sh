#!/usr/bin/env bash
# test/gh430-state-dir-tracked-default.sh — GH-430 regression.
#
# improve-loop.sh's only audit trail is $STATE_DIR/provenance.jsonl. The old default rooted it at
# ${TMPDIR:-/tmp}/improve-loop.$$ — process-scoped, so the evidence evaporates the moment the run
# exits. A full-tree search for provenance*.jsonl turned up zero hits, including the run the
# 2026-06-30 ROADMAP entry and the GH-50 close cited as "provenance logged".
#
# This asserts that running the loop WITHOUT --state-dir puts provenance.jsonl at a path inside this
# repo that git actually tracks (not ignored) — and specifically not under /tmp or $TMPDIR — while an
# explicit --state-dir still overrides the default unchanged.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
IL="$REPO/relay-automation/improve-loop.sh"
PASS=0; FAIL=0
pass(){ echo "  PASS: $*"; PASS=$((PASS+1)); }
fail(){ echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
echo "== test: gh430-state-dir-tracked-default =="
W="${TMPDIR:-/tmp}/gh430-state-dir-test.$$"; rm -rf "$W"; mkdir -p "$W"
CREATED_DIRS=()
cleanup(){ rm -rf "$W"; for d in "${CREATED_DIRS[@]:-}"; do [ -n "$d" ] && rm -rf "$d"; done; }
trap cleanup EXIT

# ---- Scenario A: no --state-dir -> default lands inside the repo, tracked, provenance survives -----
ART="$W/artifact"; echo 50 >"$ART"
OUT="$(cd "$REPO" && bash "$IL" --artifact "$ART" --measure-cmd "cat $ART" --oracle-cmd true \
        --build-cmd true --goal max --max-iterations 1 2>&1)"; RC=$?
[ "$RC" = 0 ] && pass "run without --state-dir completed (exit 0)" || fail "rc=$RC out=$OUT"

SD="$(printf '%s\n' "$OUT" | /usr/bin/grep -o 'provenance: .*/provenance\.jsonl' | sed 's/^provenance: //; s#/provenance\.jsonl$##')"
[ -n "$SD" ] && pass "captured the default STATE_DIR from the run log ($SD)" || fail "could not find a 'provenance:' log line in: $OUT"
[ -n "$SD" ] && CREATED_DIRS+=("$SD")

case "$SD" in
  "$REPO"/*) pass "default STATE_DIR resolves inside this repo" ;;
  *) fail "default STATE_DIR is NOT inside the repo: $SD" ;;
esac

TMPROOT="${TMPDIR:-/tmp}"
if [[ "$REPO" != "$TMPROOT"* && "$REPO" != "/tmp"* && "$REPO" != "/private/tmp"* ]]; then
  case "$SD" in
    "$TMPROOT"/*|/tmp/*|/private/tmp/*) fail "default STATE_DIR is still under a tmp root: $SD" ;;
    *) pass "default STATE_DIR is not under /tmp or \$TMPDIR" ;;
  esac
else
  pass "default STATE_DIR is not under an unparented tmp root"
fi

if [ -n "$SD" ]; then
  REL="${SD#"$REPO"/}"
  if (cd "$REPO" && git check-ignore -q "$REL"); then
    fail "default STATE_DIR path is gitignored (zero containment protection, GH-396): $REL"
  else
    pass "default STATE_DIR path is NOT gitignored -> tracked-eligible: $REL"
  fi
fi

[ -n "$SD" ] && [ -s "$SD/provenance.jsonl" ] && pass "provenance.jsonl exists and is non-empty at the default path" \
  || fail "no provenance.jsonl at default path $SD"

# ---- Scenario B: an explicit --state-dir still overrides the default, unchanged --------------------
B="$W/b"; echo 50 >"$B-art" 2>/dev/null || true
ART2="$W/art2"; echo 50 >"$ART2"
EXPLICIT="$W/explicit-state"
OUT2="$(cd "$REPO" && bash "$IL" --artifact "$ART2" --measure-cmd "cat $ART2" --oracle-cmd true \
         --build-cmd true --goal max --max-iterations 1 --state-dir "$EXPLICIT" 2>&1)"; RC2=$?
[ "$RC2" = 0 ] && pass "run with explicit --state-dir completed (exit 0)" || fail "rc=$RC2 out=$OUT2"
[ -s "$EXPLICIT/provenance.jsonl" ] && pass "explicit --state-dir still wins over the default" \
  || fail "explicit --state-dir was not honored: $EXPLICIT/provenance.jsonl missing"

echo "  gh430-state-dir-tracked-default: $PASS pass, $FAIL fail"
[ "$FAIL" = 0 ]
