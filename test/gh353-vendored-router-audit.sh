#!/usr/bin/env bash
# gh353-vendored-router-audit.sh — GH-353: audit and remediate target ROUTER.md ROADMAP.md frozen status.
#
# Comprehensive regression test matrix:
#   1. Clean releases-mode repo reports `ok` (rc=0).
#   2. Drifted releases-mode repo (legacy ROUTER.md with active ROADMAP.md) reports `ROUTER DRIFT` (rc=1 on --check).
#   3. Releases negative: mention dashboard only in unrelated prose outside Role split / Startup -> fails audit.
#   4. Releases negative: missing ROADMAP.md declaration in Role split -> fails audit.
#   5. Releases negative: Role split says ROADMAP.md active despite mentioning releases.db -> fails audit.
#   6. Releases negative: Startup sequence with bullet list `- Read ROADMAP.md` -> fails audit.
#   7. Releases negative: Startup sequence with unnumbered `Read ROADMAP.md` -> fails audit.
#   8. Releases negative: Missing Startup sequence section -> fails audit.
#   9. Releases --fix: repairs bounded sections, creates missing sections, handles EOF, preserves custom bytes, passes post-fix audit.
#  10. Mode parser: commented `# ROADMAP_SOURCE=releases` in .pdda-mode is legacy mode.
#  11. Mode parser: prefix `NOT_ROADMAP_SOURCE=releases` in .pdda-mode is legacy mode.
#  12. Mode parser: whitespace `  ROADMAP_SOURCE  =  releases  # comment` in .pdda-mode is releases mode.
#  13. Mode parser: unreadable .pdda-mode reports error and exits non-zero on --check.
#  14. Clean legacy-mode repo reports `ok` (rc=0).
#  15. Legacy negative: Role split with false-frozen ROADMAP.md -> fails audit.
#  16. Legacy negative: Startup sequence with false-frozen ROADMAP.md -> fails audit.
#  17. Legacy negative: Missing Role split section -> fails audit.
#  18. Legacy negative: Missing Startup sequence section -> fails audit.
#  19. Legacy negative: Startup sequence missing active ROADMAP.md read step -> fails audit.
#  20. Legacy negative: leftover ROADMAP-DASHBOARD.md file on disk + clean router reports ok (not fooled by file).
#  21. Legacy --fix: creates/repairs missing sections, restores active ROADMAP.md, strips dashboard, passes post-fix audit.
#  22. Unreadable ROUTER.md reports error and exits non-zero on --check.
#  23. `xyz-sync.sh check` surfaces router drift for registered vendored repositories.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$HERE/.." && pwd)"
AUDIT_PY="$ROOT_DIR/utils/py/router_audit.py"
XYZ_SYNC="$ROOT_DIR/relay-automation/xyz-sync.sh"

pass=0; fail=0
ok(){ if [ "$2" = "0" ]; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }
is(){ [ "$1" = "$2" ]; }
has(){ printf '%s' "$1" | grep -Fq "$2"; }

echo "== test: gh353-vendored-router-audit =="

command -v python3 >/dev/null 2>&1 || { echo "python3 required" >&2; exit 1; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh353-audit.XXXXXX")"
[ -n "$WORK" ] && [ -d "$WORK" ] || { echo "mktemp failed" >&2; exit 1; }
. "$HERE/lib/fixture-guard.sh"
fixture_guard_init "$WORK"
cleanup(){ [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
trap cleanup EXIT

mkrepo(){
  local r="$WORK/$1"
  mkdir -p "$r"
  git -C "$r" init -q -b main
  git -C "$r" config user.email test@invalid
  git -C "$r" config user.name test
  printf '%s\n' "$r"
}

# ── 1. Clean releases-mode repo ───────────────────────────────────────────────────
R_REL_CLEAN="$(mkrepo rel_clean)"
require_fixture "$R_REL_CLEAN" "clean releases repo"
touch "$R_REL_CLEAN/releases.db"
cat > "$R_REL_CLEAN/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = the generated, human-readable view of the roadmap ledger (read this; regenerate with `utils/roadmap-dashboard.sh` or `.xyz/utils/roadmap-dashboard.sh`)
- `ROADMAP.md` = LEGACY pointer ledger, frozen since the `ROADMAP_SOURCE=releases` flip — the RELEASES DB (`releases.db` via `releases.sql`) is the source of truth; write via `releases roadmap add`, never by editing this file
- `CHANGELOG.md` = running log of completed work
## Startup sequence
1. Read ROUTER.md
2. Read AGENTS.md
3. Read `ROADMAP-DASHBOARD.md` (or `python3 utils/py/releases_app.py roadmap list`) to find the active effort. (`ROADMAP.md` is the frozen legacy file — do not read it for current state or edit it.)
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_CLEAN" 2>&1)"; rc=$?
ok "clean releases-mode repo reports ok (rc=0)" "$(is "$rc" "0"; echo $?)"
ok "clean releases-mode repo output contains ok" "$(has "$out" "ok"; echo $?)"

# ── 2. Drifted releases-mode repo (legacy active ROADMAP.md text) ───────────────────
R_REL_STALE="$(mkrepo rel_stale)"
require_fixture "$R_REL_STALE" "stale releases repo"
touch "$R_REL_STALE/releases.db"
cat > "$R_REL_STALE/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROUTER.md` = startup order
- `ROADMAP.md` = the pointer ledger of current, completed, attempted, and deferred work
- `CHANGELOG.md` = running log of completed work
## Startup sequence
1. Read ROUTER.md
2. Read AGENTS.md
3. Read `ROADMAP.md` to find the active effort.
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_STALE" 2>&1)"; rc=$?
ok "drifted releases-mode repo reports non-zero exit with --check" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"
ok "drifted releases-mode repo output reports ROUTER DRIFT" "$(has "$out" "ROUTER DRIFT"; echo $?)"

# ── 3. Releases negative: dashboard mentioned outside Role split / Startup ─────────
R_REL_UNSCOPED="$(mkrepo rel_unscoped)"
require_fixture "$R_REL_UNSCOPED" "unscoped releases repo"
touch "$R_REL_UNSCOPED/releases.db"
cat > "$R_REL_UNSCOPED/ROUTER.md" <<'MD'
# ROUTER.md
See ROADMAP-DASHBOARD.md in our notes somewhere.
## Role split
- `ROADMAP.md` = active roadmap ledger
## Startup sequence
1. Read `ROADMAP.md` to find work.
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_UNSCOPED" 2>&1)"; rc=$?
ok "mentioning dashboard outside bounded sections fails audit" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 4. Releases negative: missing ROADMAP.md declaration in Role split ──────────────
R_REL_NO_RMI="$(mkrepo rel_no_rmi)"
require_fixture "$R_REL_NO_RMI" "no rmi releases repo"
touch "$R_REL_NO_RMI/releases.db"
cat > "$R_REL_NO_RMI/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = dashboard view
## Startup sequence
1. Read `ROADMAP-DASHBOARD.md` (ROADMAP.md is frozen legacy).
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_NO_RMI" 2>&1)"; rc=$?
ok "omitted ROADMAP.md role entry reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 5. Releases negative: Role split says ROADMAP.md active despite releases.db ───
R_REL_ACTIVE_WITH_DB="$(mkrepo rel_active_with_db)"
require_fixture "$R_REL_ACTIVE_WITH_DB" "active with db repo"
touch "$R_REL_ACTIVE_WITH_DB/releases.db"
cat > "$R_REL_ACTIVE_WITH_DB/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = generated view
- `ROADMAP.md` = active pointer ledger; releases.db exists alongside it
## Startup sequence
1. Read `ROADMAP-DASHBOARD.md` (ROADMAP.md is frozen legacy).
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_ACTIVE_WITH_DB" 2>&1)"; rc=$?
ok "Role split claiming active despite releases.db reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 6. Releases negative: Startup sequence with bullet format ─────────────────────
R_REL_BULLET_STARTUP="$(mkrepo rel_bullet_startup)"
require_fixture "$R_REL_BULLET_STARTUP" "bullet startup releases repo"
touch "$R_REL_BULLET_STARTUP/releases.db"
cat > "$R_REL_BULLET_STARTUP/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = generated view
- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip
## Startup sequence
- Read ROUTER.md
- Read `ROADMAP.md` to find current tasks.
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_BULLET_STARTUP" 2>&1)"; rc=$?
ok "Startup sequence with bullet - Read ROADMAP.md reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 7. Releases negative: Startup sequence with unnumbered directive ───────────────
R_REL_UNNUM_STARTUP="$(mkrepo rel_unnum_startup)"
require_fixture "$R_REL_UNNUM_STARTUP" "unnum startup releases repo"
touch "$R_REL_UNNUM_STARTUP/releases.db"
cat > "$R_REL_UNNUM_STARTUP/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = generated view
- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip
## Startup sequence
Always read ROADMAP.md before starting any work.
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_UNNUM_STARTUP" 2>&1)"; rc=$?
ok "Startup sequence with unnumbered read ROADMAP.md reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 8. Releases negative: missing Startup sequence section ──────────────────────────
R_REL_NO_START="$(mkrepo rel_no_start)"
require_fixture "$R_REL_NO_START" "no start releases repo"
touch "$R_REL_NO_START/releases.db"
cat > "$R_REL_NO_START/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = generated view
- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_NO_START" 2>&1)"; rc=$?
ok "missing Startup sequence section reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 9. Releases --fix: repairs bounded sections and preserves custom bytes ──────────
CUSTOM_BLOCK='
## Custom Section
Do not destroy this custom block: special chars $VAR, `code`, and exact spacing!

## Another Custom
Line 1
Line 2
'

cat > "$R_REL_STALE/ROUTER.md" <<MD
# ROUTER.md
Intro text here.

## Role split
- \`ROUTER.md\` = startup order
- \`ROADMAP.md\` = the pointer ledger of current work
- \`CHANGELOG.md\` = running log
${CUSTOM_BLOCK}
## Startup sequence
1. Read ROUTER.md
2. Read AGENTS.md
3. Read \`ROADMAP.md\` to find the active effort.
4. Read the linked PROJECT doc.

## Trailing Section
Preserve trailing EOF section.
MD

fix_out="$(python3 "$AUDIT_PY" --fix "$R_REL_STALE" 2>&1)"; rc_fix=$?
ok "router_audit.py --fix returns rc=0" "$(is "$rc_fix" "0"; echo $?)"

after_check_out="$(python3 "$AUDIT_PY" --check "$R_REL_STALE" 2>&1)"; rc_after=$?
ok "after --fix, repo passes audit with rc=0" "$(is "$rc_after" "0"; echo $?)"

content_after="$(cat "$R_REL_STALE/ROUTER.md")"
ok "fixed ROUTER.md contains ROADMAP-DASHBOARD.md in Role split" "$(has "$content_after" "ROADMAP-DASHBOARD.md"; echo $?)"
ok "fixed ROUTER.md notes ROADMAP.md is frozen / legacy" "$(has "$content_after" "LEGACY pointer ledger, frozen"; echo $?)"
ok "fixed ROUTER.md updates startup sequence step 3" "$(has "$content_after" "Read \`ROADMAP-DASHBOARD.md\`"; echo $?)"
ok "fixed ROUTER.md preserves exact Custom Section bytes" "$(has "$content_after" "Do not destroy this custom block: special chars \$VAR, \`code\`, and exact spacing!"; echo $?)"
ok "fixed ROUTER.md preserves Trailing Section" "$(has "$content_after" "Preserve trailing EOF section."; echo $?)"

# ── 10. Mode parser: commented line in .pdda-mode is legacy mode ───────────────────
R_PDDA_COMMENT="$(mkrepo pdda_comment)"
require_fixture "$R_PDDA_COMMENT" "pdda comment repo"
cat > "$R_PDDA_COMMENT/.pdda-mode" <<'MODE'
# ROADMAP_SOURCE=releases
MODE
cat > "$R_PDDA_COMMENT/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP.md` = the pointer ledger of current work
## Startup sequence
1. Read `ROADMAP.md` to find work.
MD

out="$(python3 "$AUDIT_PY" --check "$R_PDDA_COMMENT" 2>&1)"; rc=$?
ok "commented ROADMAP_SOURCE=releases is recognized as legacy mode (rc=0)" "$(is "$rc" "0"; echo $?)"

# ── 11. Mode parser: prefix line in .pdda-mode is legacy mode ───────────────────────
R_PDDA_PREFIX="$(mkrepo pdda_prefix)"
require_fixture "$R_PDDA_PREFIX" "pdda prefix repo"
cat > "$R_PDDA_PREFIX/.pdda-mode" <<'MODE'
NOT_ROADMAP_SOURCE=releases
MODE
cat > "$R_PDDA_PREFIX/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP.md` = the pointer ledger of current work
## Startup sequence
1. Read `ROADMAP.md` to find work.
MD

out="$(python3 "$AUDIT_PY" --check "$R_PDDA_PREFIX" 2>&1)"; rc=$?
ok "prefix NOT_ROADMAP_SOURCE=releases is recognized as legacy mode (rc=0)" "$(is "$rc" "0"; echo $?)"

# ── 12. Mode parser: whitespace in .pdda-mode is releases mode ────────────────────
R_PDDA_WS="$(mkrepo pdda_ws)"
require_fixture "$R_PDDA_WS" "pdda ws repo"
cat > "$R_PDDA_WS/.pdda-mode" <<'MODE'
   ROADMAP_SOURCE   =   releases  # comment
MODE
cat > "$R_PDDA_WS/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = generated view
- `ROADMAP.md` = LEGACY pointer ledger, frozen since the `ROADMAP_SOURCE=releases` flip — releases.db
## Startup sequence
1. Read `ROADMAP-DASHBOARD.md` (ROADMAP.md is frozen legacy).
MD

out="$(python3 "$AUDIT_PY" --check "$R_PDDA_WS" 2>&1)"; rc=$?
ok "whitespace-padded ROADMAP_SOURCE=releases is recognized as releases mode (rc=0)" "$(is "$rc" "0"; echo $?)"

# ── 13. Mode parser: unreadable .pdda-mode reports error ──────────────────────────
R_PDDA_UNREAD="$(mkrepo pdda_unread)"
require_fixture "$R_PDDA_UNREAD" "pdda unread repo"
touch "$R_PDDA_UNREAD/.pdda-mode"
chmod 000 "$R_PDDA_UNREAD/.pdda-mode" 2>/dev/null || true
if [ ! -r "$R_PDDA_UNREAD/.pdda-mode" ]; then
  out="$(python3 "$AUDIT_PY" --check "$R_PDDA_UNREAD" 2>&1)"; rc=$?
  ok "unreadable .pdda-mode reports error on --check" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"
  chmod 644 "$R_PDDA_UNREAD/.pdda-mode"
else
  echo "  SKIP: unreadable .pdda-mode test (running as root or chmod not enforced)"
  pass=$((pass+1))
fi

# ── 14. Clean legacy-mode repo ─────────────────────────────────────────────────────
R_LEG_CLEAN="$(mkrepo leg_clean)"
require_fixture "$R_LEG_CLEAN" "clean legacy repo"
cat > "$R_LEG_CLEAN/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROUTER.md` = startup order
- `ROADMAP.md` = the pointer ledger of current, completed, attempted, and deferred work
- `CHANGELOG.md` = running log of completed work
## Startup sequence
1. Read ROUTER.md
2. Read `ROADMAP.md` to find active effort.
MD

out="$(python3 "$AUDIT_PY" --check "$R_LEG_CLEAN" 2>&1)"; rc=$?
ok "clean legacy-mode repo reports ok (rc=0)" "$(is "$rc" "0"; echo $?)"

# ── 15. Legacy negative: Role split with false-frozen ROADMAP.md ───────────────────
R_LEG_FALSE_FROZEN="$(mkrepo leg_false_frozen)"
require_fixture "$R_LEG_FALSE_FROZEN" "false frozen legacy repo"
cat > "$R_LEG_FALSE_FROZEN/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases flip
## Startup sequence
1. Read ROUTER.md
2. Read `ROADMAP.md` to find active effort.
MD

out="$(python3 "$AUDIT_PY" --check "$R_LEG_FALSE_FROZEN" 2>&1)"; rc=$?
ok "legacy repo with false-frozen ROADMAP.md in Role split reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 16. Legacy negative: Startup sequence with false-frozen ROADMAP.md ────────────
R_LEG_START_FROZEN="$(mkrepo leg_start_frozen)"
require_fixture "$R_LEG_START_FROZEN" "start frozen legacy repo"
cat > "$R_LEG_START_FROZEN/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP.md` = the pointer ledger of current work
## Startup sequence
1. Read ROUTER.md
2. Read `ROADMAP.md` (note: ROADMAP.md is frozen legacy).
MD

out="$(python3 "$AUDIT_PY" --check "$R_LEG_START_FROZEN" 2>&1)"; rc=$?
ok "legacy repo with false-frozen Startup sequence reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 17. Legacy negative: missing Role split section ───────────────────────────────
R_LEG_NO_ROLE="$(mkrepo leg_no_role)"
require_fixture "$R_LEG_NO_ROLE" "no role legacy repo"
cat > "$R_LEG_NO_ROLE/ROUTER.md" <<'MD'
# ROUTER.md
## Startup sequence
1. Read `ROADMAP.md` to find active effort.
MD

out="$(python3 "$AUDIT_PY" --check "$R_LEG_NO_ROLE" 2>&1)"; rc=$?
ok "legacy repo missing Role split reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 18. Legacy negative: missing Startup sequence section ─────────────────────────
R_LEG_NO_START="$(mkrepo leg_no_start)"
require_fixture "$R_LEG_NO_START" "no start legacy repo"
cat > "$R_LEG_NO_START/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP.md` = the pointer ledger of current work
MD

out="$(python3 "$AUDIT_PY" --check "$R_LEG_NO_START" 2>&1)"; rc=$?
ok "legacy repo missing Startup sequence reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 19. Legacy negative: Startup sequence missing active ROADMAP.md read step ─────
R_LEG_NO_RMI_READ="$(mkrepo leg_no_rmi_read)"
require_fixture "$R_LEG_NO_RMI_READ" "no rmi read legacy repo"
cat > "$R_LEG_NO_RMI_READ/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP.md` = the pointer ledger of current work
## Startup sequence
1. Read ROUTER.md
2. Read AGENTS.md
MD

out="$(python3 "$AUDIT_PY" --check "$R_LEG_NO_RMI_READ" 2>&1)"; rc=$?
ok "legacy repo missing active ROADMAP.md read step reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 20. Legacy negative: leftover ROADMAP-DASHBOARD.md file on disk ───────────────
R_LEG_LEFTOVER="$(mkrepo leg_leftover)"
require_fixture "$R_LEG_LEFTOVER" "leftover dashboard file legacy repo"
touch "$R_LEG_LEFTOVER/ROADMAP-DASHBOARD.md"
cat > "$R_LEG_LEFTOVER/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP.md` = the pointer ledger of current, completed, attempted, and deferred work
## Startup sequence
1. Read ROUTER.md
2. Read `ROADMAP.md` to find active effort.
MD

out="$(python3 "$AUDIT_PY" --check "$R_LEG_LEFTOVER" 2>&1)"; rc=$?
ok "legacy repo with leftover dashboard file but clean router reports ok" "$(is "$rc" "0"; echo $?)"

# ── 21. Remediate legacy repo with --fix ──────────────────────────────────────────
R_LEG_DRIFT="$(mkrepo leg_drift)"
require_fixture "$R_LEG_DRIFT" "drifted legacy repo"
cat > "$R_LEG_DRIFT/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = generated view
- `ROADMAP.md` = LEGACY pointer ledger, frozen
## Startup sequence
1. Read ROUTER.md
2. Read `ROADMAP-DASHBOARD.md` to find work.
MD

python3 "$AUDIT_PY" --fix "$R_LEG_DRIFT" >/dev/null
out_remed="$(python3 "$AUDIT_PY" --check "$R_LEG_DRIFT" 2>&1)"; rc_remed=$?
ok "drifted legacy repo remediated with --fix (rc=0)" "$(is "$rc_remed" "0"; echo $?)"
content_leg="$(cat "$R_LEG_DRIFT/ROUTER.md")"
ok "legacy --fix removed ROADMAP-DASHBOARD.md declaration" "$(! has "$content_leg" "ROADMAP-DASHBOARD.md"; echo $?)"
ok "legacy --fix restored active pointer ledger text" "$(has "$content_leg" "pointer ledger of current"; echo $?)"
ok "legacy --fix restored active ROADMAP.md read step" "$(has "$content_leg" "Read \`ROADMAP.md\`"; echo $?)"

# ── 22. Unreadable ROUTER.md handling ─────────────────────────────────────────────
R_UNREADABLE="$(mkrepo unreadable)"
require_fixture "$R_UNREADABLE" "unreadable repo"
touch "$R_UNREADABLE/ROUTER.md"
chmod 000 "$R_UNREADABLE/ROUTER.md" 2>/dev/null || true

if [ ! -r "$R_UNREADABLE/ROUTER.md" ]; then
  out="$(python3 "$AUDIT_PY" --check "$R_UNREADABLE" 2>&1)"; rc=$?
  ok "unreadable ROUTER.md reports non-zero exit on --check" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"
  ok "unreadable output indicates error" "$(has "$out" "ERROR reading ROUTER.md"; echo $?)"
  chmod 644 "$R_UNREADABLE/ROUTER.md"
else
  echo "  SKIP: unreadable test (running as root or chmod 000 not enforced)"
  pass=$((pass+2))
fi

# ── 23. xyz-sync.sh check integration ─────────────────────────────────────────────
REG_FILE="$WORK/registry.tsv"
printf '# XYZ install registry\n' > "$REG_FILE"
printf '%s\t%s\t%s\t%s\t%s\n' "$R_REL_STALE/.xyz" "2026-08-31T00:00:00Z" "0.2.0" "deadbeef" "$R_REL_STALE" >> "$REG_FILE"
mkdir -p "$R_REL_STALE/.xyz"

# Re-introduce drift in R_REL_STALE to test xyz-sync check
cat > "$R_REL_STALE/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP.md` = the pointer ledger
## Startup sequence
1. Read ROADMAP.md
MD

sync_out="$(XYZ_REGISTRY="$REG_FILE" bash "$XYZ_SYNC" check --all 2>&1 || true)"
ok "xyz-sync.sh check surfaces ROUTER DRIFT" "$(has "$sync_out" "ROUTER DRIFT"; echo $?)"

echo "gh353: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
