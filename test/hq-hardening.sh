#!/usr/bin/env bash
# GH-132: HQ resolution/dispatch hardening — regression tests for the 4 findings from the GH-128
# Codex review. Each group first proves the OLD failure mode is closed. Hermetic: temp registries,
# temp git repos (for owner/repo slugs), and stub gh/pdda binaries.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
HQ="$HERE/../utils/hq/hq.sh"
LIB="$HERE/../utils/hq/hq-lib.sh"
PASS=0; FAIL=0
pass(){ echo "  PASS: $*"; PASS=$((PASS+1)); }
fail(){ echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
echo "== test: hq-hardening (GH-132) =="

command -v git >/dev/null 2>&1 || { echo "  SKIP: git absent"; echo "== hq-hardening: 0 passed, 0 failed =="; exit 0; }
# GH-177: mktemp -d can fail silently under a sandboxed shell (empty stdout, non-zero rc). The old
# `cd "$(mktemp -d)" && pwd -P` idiom let `cd ""` succeed and silently stay at the CWD (the repo
# root), so the EXIT trap below then rm -rf'd the entire repository — twice (2026-07-07, 2026-07-17).
# Verify mktemp actually succeeded and returned a real directory BEFORE it's wired into a destructive
# trap; canonicalize (macOS /tmp -> /private/tmp) only as a separate step afterward.
TMP="$(mktemp -d)" || { echo "FAIL: mktemp -d failed" >&2; exit 1; }
[ -n "$TMP" ] && [ -d "$TMP" ] || { echo "FAIL: mktemp -d returned an invalid path" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd -P)"
newrepo(){ mkdir -p "$1" && ( cd "$1" && git init -q && git config user.email t@t && git config user.name t && git remote add origin "$2" ); }
xyzrow(){ printf '%s\t2026-07-04T00:00:00Z\t0.2.0\tzz\t%s\n' "$1/.xyz" "$1"; }   # install<TAB>ts<TAB>tick<TAB>commit<TAB>coord

# ============================================================================================
# Blocker 1 — owner/repo identity: a basename collision must NOT silently pick the wrong repo.
# ============================================================================================
G1="$TMP/g1"; mkdir -p "$G1/empty"
newrepo "$G1/orgA/api" "git@github.com:FooOrg/api.git"
newrepo "$G1/orgB/api" "git@github.com:BarOrg/api.git"
REG1="$G1/xyz.tsv"; { xyzrow "$G1/orgA/api"; xyzrow "$G1/orgB/api"; } > "$REG1"
r1(){ env HQ_XYZ_REGISTRY="$REG1" HQ_REBALANCE_DB="$G1/none.db" HQ_PDDA_REGISTRY_DIR="$G1/nopdda" \
        HQ_SEARCH_ROOTS="$G1/empty" bash "$HQ" resolve "$1"; }

OUT="$(r1 'FooOrg/api')"; rc=$?
{ [ "$rc" = 0 ] && printf '%s\n' "$OUT" | grep -q "REPO_PATH=$G1/orgA/api"; } \
  && pass "owner slug 'FooOrg/api' resolves to the RIGHT install (orgA)" \
  || fail "FooOrg/api rc=$rc -> $(printf '%s\n' "$OUT" | grep REPO_PATH)"

OUT="$(r1 'BarOrg/api')"; rc=$?
{ [ "$rc" = 0 ] && printf '%s\n' "$OUT" | grep -q "REPO_PATH=$G1/orgB/api"; } \
  && pass "owner slug 'BarOrg/api' resolves to the RIGHT install (orgB)" \
  || fail "BarOrg/api rc=$rc -> $(printf '%s\n' "$OUT" | grep REPO_PATH)"

OUT="$(r1 'api')"; rc=$?
{ [ "$rc" = 2 ] && printf '%s\n' "$OUT" | grep -q 'RESOLVED_VIA=ambiguous'; } \
  && pass "bare 'api' collision -> AMBIGUOUS (rc=2), not a silent wrong-repo guess" \
  || fail "bare api rc=$rc -> $OUT"

OUT="$(r1 'WrongOrg/api')"; rc=$?
[ "$rc" = 2 ] \
  && pass "unknown owner 'WrongOrg/api' -> AMBIGUOUS (rc=2), never guesses" \
  || fail "WrongOrg/api rc=$rc (expected 2)"

# ============================================================================================
# Blocker 2 — a stale XYZ path (registry points at a deleted dir) must not arm Tier A / fire.
# ============================================================================================
G2="$TMP/g2"; mkdir -p "$G2/empty" "$G2/pdda"
REG2="$G2/xyz.tsv"; xyzrow "$G2/ghost/deleted-app" > "$REG2"      # coord does NOT exist on disk
printf 'deleted-app\t2026-07-04T00:00:00Z\tobserve\tabc\tyes\n' > "$G2/pdda/registry-dev.tsv"
e2(){ env HQ_XYZ_REGISTRY="$REG2" HQ_REBALANCE_DB="$G2/none.db" HQ_PDDA_REGISTRY_DIR="$G2/pdda" \
        HQ_SEARCH_ROOTS="$G2/empty" bash "$HQ" "$@"; }

OUT="$(e2 resolve deleted-app)"; rc=$?
{ [ "$rc" = 1 ] && ! printf '%s\n' "$OUT" | grep -q '^XYZ_PATH='; } \
  && pass "stale XYZ path -> UNRESOLVED (rc=1), no XYZ_PATH emitted" \
  || fail "stale resolve rc=$rc -> $(printf '%s\n' "$OUT" | grep -E 'XYZ_PATH|REPO_PATH')"

OUT="$(e2 fire --gh-issue 9 --risk 2 deleted-app 2>&1)"; rc=$?
{ [ "$rc" != 0 ] && ! printf '%s\n' "$OUT" | grep -q 'GATES PASS'; } \
  && pass "fire at a stale target -> refuses (no GATES PASS)" \
  || fail "fire stale rc=$rc -> $OUT"

# ============================================================================================
# Blocker 3 — park --title must produce VALID YAML and never report success on an invalid doc.
# ============================================================================================
# 3a (unit): the rendered capture's title line is a well-formed double-quoted scalar.
valid_dq(){ # $1 = a `title: "..."` line -> 0 if no UNescaped interior quote remains
  local v="${1#title: \"}"; v="${v%\"}"
  local clean; clean="$(printf '%s' "$v" | sed 's/\\\\//g; s/\\"//g')"
  case "$clean" in *\"*) return 1;; *) return 0;; esac
}
# shellcheck source=/dev/null
( . "$LIB"
  OUT="$(hq_render_capture 5 'http://x/issues/5' 'bad "q" and a \back' 2026-07-04 feedback proj repo body)"
  TLINE="$(printf '%s\n' "$OUT" | grep -m1 '^title:')"
  valid_dq "$TLINE" && echo "___DQ_OK___" || echo "___DQ_BAD___ $TLINE"
) | grep -q '___DQ_OK___' \
  && pass "hq_render_capture escapes a quoted/backslash title into valid YAML" \
  || fail "render_capture produced invalid YAML title"

# 3b: build a Tier-A target with a stub pdda.sh (validates the title) + a stub gh.
G3="$TMP/g3"; TGT="$G3/repos/beta-app"
newrepo "$TGT" "git@github.com:Me/beta-app.git"
mkdir -p "$TGT/utils/pdda" "$TGT/PROJECT/1-INBOX" "$TGT/.xyz"
printf '# ROADMAP\n\n## Ledger\n### Queue\n' > "$TGT/ROADMAP.md"
cat > "$TGT/utils/pdda/pdda.sh" <<'PS'
#!/usr/bin/env bash
[ "$1" = frontmatter ] || exit 0
[ -n "${PDDA_STUB_FORCE_FAIL:-}" ] && exit 1
f="$PDDA_ONLY_FILE"; [ -f "$f" ] || exit 1
line="$(grep -m1 '^title:' "$f")"; v="${line#title: \"}"; v="${v%\"}"
clean="$(printf '%s' "$v" | sed 's/\\\\//g; s/\\"//g')"
case "$clean" in *\"*) exit 1;; *) exit 0;; esac
PS
chmod +x "$TGT/utils/pdda/pdda.sh"
REG3="$G3/xyz.tsv"; xyzrow "$TGT" > "$REG3"
printf 'beta-app\t2026-07-04T00:00:00Z\tobserve\tabc\tyes\n' > "$G3/pdda-registry-dev.tsv"
mkdir -p "$G3/pdda"; cp "$G3/pdda-registry-dev.tsv" "$G3/pdda/registry-dev.tsv"
GH="$G3/gh"; cat > "$GH" <<'GHS'
#!/usr/bin/env bash
if [ "$1" = issue ] && [ "$2" = list ]; then printf '[]\n'; exit 0; fi
if [ "$1" = issue ] && [ "$2" = create ]; then printf 'https://github.com/Me/beta-app/issues/77\n'; exit 0; fi
exit 0
GHS
chmod +x "$GH"
# PDDA_STUB_FORCE_FAIL (when set by the caller) propagates through the environment into the stub.
p3(){ env HQ_XYZ_REGISTRY="$REG3" HQ_REBALANCE_DB="$G3/none.db" HQ_PDDA_REGISTRY_DIR="$G3/pdda" \
        HQ_SEARCH_ROOTS="$G3/repos" HQ_GH_BIN="$GH" bash "$HQ" \
        park --create --title "$T3" beta-app 'the request body'; }

T3='bad "quoted" title'
OUT="$(p3 2>&1)"; rc=$?
DOC="$(ls "$TGT"/PROJECT/1-INBOX/GH-77-*.md 2>/dev/null | head -1)"
{ [ "$rc" = 0 ] && [ -n "$DOC" ] && valid_dq "$(grep -m1 '^title:' "$DOC")"; } \
  && pass "park --create with a quoted --title writes VALID YAML and succeeds" \
  || fail "park quoted-title rc=$rc doc=$DOC title=$(grep -m1 '^title:' "$DOC" 2>/dev/null)"

rm -f "$TGT"/PROJECT/1-INBOX/GH-77-*.md
T3='x'
OUT="$(PDDA_STUB_FORCE_FAIL=1 p3 2>&1)"; rc=$?
{ [ "$rc" != 0 ] && printf '%s\n' "$OUT" | grep -q 'not PDDA-valid'; } \
  && pass "park --create fails hard (rc!=0) when the frontmatter check fails" \
  || fail "park fail-hard rc=$rc -> $OUT"

# ============================================================================================
# Blocker 4 — a glob-metachar token must not resolve via the find fallback.
# ============================================================================================
G4="$TMP/g4"; mkdir -p "$G4/repos/only-app/.git" "$G4/nopdda"
e4(){ env HQ_XYZ_REGISTRY="$G4/none.tsv" HQ_REBALANCE_DB="$G4/none.db" HQ_PDDA_REGISTRY_DIR="$G4/nopdda" \
        HQ_SEARCH_ROOTS="$G4/repos" bash "$HQ" resolve "$1"; }

OUT="$(e4 '*')"; rc=$?
{ [ "$rc" = 1 ] && ! printf '%s\n' "$OUT" | grep -q "REPO_PATH=$G4/repos/only-app"; } \
  && pass "glob token '*' does NOT resolve via find (rc=1, UNRESOLVED)" \
  || fail "glob resolve rc=$rc -> $(printf '%s\n' "$OUT" | grep REPO_PATH)"

OUT="$(e4 'only-app')"; rc=$?
{ [ "$rc" = 0 ] && printf '%s\n' "$OUT" | grep -q "REPO_PATH=$G4/repos/only-app"; } \
  && pass "control: a literal name still resolves via find (rc=0)" \
  || fail "literal resolve rc=$rc -> $(printf '%s\n' "$OUT" | grep REPO_PATH)"

# ============================================================================================
# GH-132 follow-on — same-repo collapse: two registry rows pointing at the SAME coord (e.g. a
# legacy xyz-tick install alongside the current vendored .xyz) must resolve cleanly, not ambiguous.
# ============================================================================================
G5="$TMP/g5"; mkdir -p "$G5/empty"
newrepo "$G5/dup-app" "git@github.com:Me/dup-app.git"
REG5="$G5/xyz.tsv"
{ printf '%s\t2026-07-04T00:00:00Z\t0.1.0\told1\t%s\n' "$G5/dup-app/xyz-tick" "$G5/dup-app"   # legacy install
  xyzrow "$G5/dup-app"                                                                          # current .xyz
} > "$REG5"
r5(){ env HQ_XYZ_REGISTRY="$REG5" HQ_REBALANCE_DB="$G5/none.db" HQ_PDDA_REGISTRY_DIR="$G5/nopdda" \
        HQ_SEARCH_ROOTS="$G5/empty" bash "$HQ" resolve "$1"; }

OUT="$(r5 'dup-app')"; rc=$?
{ [ "$rc" = 0 ] && ! printf '%s\n' "$OUT" | grep -q 'RESOLVED_VIA=ambiguous' \
    && printf '%s\n' "$OUT" | grep -q "REPO_PATH=$G5/dup-app"; } \
  && pass "same-repo duplicate registry rows collapse, not ambiguous (rc=0)" \
  || fail "dup-app rc=$rc -> $(printf '%s\n' "$OUT" | grep -E 'RESOLVED_VIA|REPO_PATH')"

{ [ "$rc" = 0 ] && printf '%s\n' "$OUT" | grep -q "XYZ_INSTALL=$G5/dup-app/.xyz\$"; } \
  && pass "same-repo collapse prefers the vendored .xyz install over the legacy one" \
  || fail "dup-app XYZ_INSTALL -> $(printf '%s\n' "$OUT" | grep XYZ_INSTALL)"

# Control: two DIFFERENT repos sharing a basename must still be ambiguous (the collapse must not
# weaken Blocker 1's cross-repo disambiguation — re-asserted here alongside its own fixture).
OUT="$(r1 'api')"; rc=$?
{ [ "$rc" = 2 ] && printf '%s\n' "$OUT" | grep -q 'RESOLVED_VIA=ambiguous'; } \
  && pass "control: cross-repo basename collision still ambiguous after the same-repo collapse fix" \
  || fail "control cross-repo rc=$rc -> $OUT"

echo "== hq-hardening: $PASS passed, $FAIL failed =="
[ "$FAIL" = 0 ]
