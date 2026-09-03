#!/usr/bin/env bash
# GH-128 Phase 4 (remainder): find-hq.sh — device-agnostic locator for utils/hq/hq.sh.
# Hermetic: builds a fake harness (with a stub hq.sh) + a fake FOREIGN git repo, symlinks the
# real find-hq.sh in as it would be installed under ~/.claude/skills/hq, and proves /hq resolves
# from ANY CWD — including standing inside a different repo — with no hardcoded path.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
REAL_LOCATOR="$HERE/../skills/hq/find-hq.sh"
PASS=0; FAIL=0
pass(){ echo "  PASS: $*"; PASS=$((PASS+1)); }
fail(){ echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
echo "== test: hq-locator (GH-128 find-hq.sh) =="

[ -x "$REAL_LOCATOR" ] || { fail "find-hq.sh missing/not executable at $REAL_LOCATOR"; echo "== hq-locator: $PASS passed, $FAIL failed =="; exit 1; }

# Canonicalize: macOS mktemp yields /var/folders/… but the locator returns pwd -P
# (/private/var/folders/…), so compare against the same canonical form.
# GH-177: mktemp -d can fail silently under a sandboxed shell (empty stdout, non-zero rc). The old
# `cd "$(mktemp -d)" && pwd -P` idiom let `cd ""` succeed and silently stay at the CWD (the repo
# root), so the EXIT trap below then rm -rf'd the entire repository — twice (2026-07-07, 2026-07-17).
# Verify mktemp actually succeeded and returned a real directory BEFORE it's wired into a destructive
# trap; canonicalize only as a separate step afterward.
TMP="$(mktemp -d)" || { echo "FAIL: mktemp -d failed" >&2; exit 1; }
[ -n "$TMP" ] && [ -d "$TMP" ] || { echo "FAIL: mktemp -d returned an invalid path" >&2; exit 1; }
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/fixture-guard.sh"   # GH-10: shared fixture containment
fixture_guard_init "$TMP"   # GH-10: pin the sandbox root
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd -P)"

# --- fake harness: utils/hq/hq.sh stub + the real find-hq.sh copied into skills/hq ---
HARN="$TMP/harness"
mkdir -p "$HARN/utils/hq" "$HARN/skills/hq" "$HARN/relay-automation"
cp "$HERE/../relay-automation/harness-paths.sh" "$HARN/relay-automation/"
cat > "$HARN/utils/hq/hq.sh" <<'EOF'
#!/usr/bin/env bash
echo "STUB-HQ ok"
EOF
chmod +x "$HARN/utils/hq/hq.sh"
cp "$REAL_LOCATOR" "$HARN/skills/hq/find-hq.sh"
chmod +x "$HARN/skills/hq/find-hq.sh"

# --- fake FOREIGN repo (a real git root) that ships NO utils/hq ---
FOREIGN="$TMP/foreign"
mkdir -p "$FOREIGN"
( cd "$FOREIGN" && git init -q && git config user.email t@t && git config user.name t \
  && : > f && git add f && git commit -qm init ) || true

# --- simulate the ~/.claude/skills/hq install: a symlink into the harness skill dir ---
USKILLS="$TMP/userskills"
mkdir -p "$USKILLS"
ln -s "$HARN/skills/hq" "$USKILLS/hq"
INSTALLED="$USKILLS/hq/find-hq.sh"   # the path a real session would call

# 1. from the harness repo itself (git-root case)
OUT="$( cd "$HARN" && bash "$HARN/skills/hq/find-hq.sh" --sh )"; rc=$?
{ [ "$rc" = 0 ] && [ "$OUT" = "$HARN/utils/hq/hq.sh" ]; } \
  && pass "resolves hq.sh from the harness repo (git root)" \
  || fail "harness-cwd: rc=$rc out=$OUT"

# 2. THE cross-repo case: standing INSIDE the foreign repo, call the INSTALLED (symlinked)
#    locator with NO override — must follow its own symlink back to the real harness, NOT the
#    foreign git root (which has no utils/hq).
OUT="$( cd "$FOREIGN" && unset XYZ_HARNESS XYZ_REPO_ROOT; bash "$INSTALLED" --sh )"; rc=$?
{ [ "$rc" = 0 ] && [ "$OUT" = "$HARN/utils/hq/hq.sh" ]; } \
  && pass "cross-repo: symlinked locator resolves REAL harness from a foreign CWD" \
  || fail "cross-repo: rc=$rc out=$OUT (expected $HARN/utils/hq/hq.sh)"

# 3. explicit XYZ_HARNESS override wins, even from an unrelated CWD
OUT="$( cd "$TMP" && XYZ_HARNESS="$HARN" bash "$REAL_LOCATOR" --sh )"; rc=$?
{ [ "$rc" = 0 ] && [ "$OUT" = "$HARN/utils/hq/hq.sh" ]; } \
  && pass "\$XYZ_HARNESS override resolves from any CWD" \
  || fail "override: rc=$rc out=$OUT"

# 4. --root prints the repo root that ships utils/hq/
OUT="$( XYZ_HARNESS="$HARN" bash "$REAL_LOCATOR" --root )"
[ "$OUT" = "$HARN" ] && pass "--root prints the harness root" || fail "--root: $OUT"

# 5. --env emits evalable exports that point HQ_SH at the stub
EVOUT="$( XYZ_HARNESS="$HARN" bash "$REAL_LOCATOR" --env )"
( eval "$EVOUT"; [ "$HQ_SH" = "$HARN/utils/hq/hq.sh" ] && [ "$HQ_ROOT" = "$HARN" ] ) \
  && pass "--env exports HQ_SH/HQ_ROOT (evalable)" \
  || fail "--env: $EVOUT"

# 6. and the resolved dispatcher actually runs
RUN="$( eval "$EVOUT"; bash "$HQ_SH" )"
[ "$RUN" = "STUB-HQ ok" ] && pass "resolved hq.sh is executable/runs" || fail "run: $RUN"

# 7. no harness anywhere -> clean error, exit 1 (not a silent empty print). Use an ORPHAN copy
#    of the locator in a subtree with no utils/hq above it, run from a non-git CWD with no
#    override — so none of the three resolution rungs can hit. (The REAL locator would correctly
#    find the real harness via its own location, which is exactly why we copy it out here.)
ORPHAN="$TMP/orphan/skills/hq"
mkdir -p "$ORPHAN"
cp "$REAL_LOCATOR" "$ORPHAN/find-hq.sh"; chmod +x "$ORPHAN/find-hq.sh"
OUT="$( cd "$TMP/orphan" && unset XYZ_HARNESS XYZ_REPO_ROOT; bash "$ORPHAN/find-hq.sh" --sh 2>/dev/null )"; rc=$?
{ [ "$rc" = 1 ] && [ -z "$OUT" ]; } \
  && pass "unresolvable -> exit 1, no stdout" \
  || fail "unresolvable: rc=$rc out=$OUT"

# 8. bad flag -> usage on stderr, exit 2
( XYZ_HARNESS="$HARN" bash "$REAL_LOCATOR" --bogus >/dev/null 2>&1 ); rc=$?
[ "$rc" = 2 ] && pass "unknown flag -> exit 2 (usage)" || fail "bad-flag rc=$rc"

echo "== hq-locator: $PASS passed, $FAIL failed =="
[ "$FAIL" = 0 ]
