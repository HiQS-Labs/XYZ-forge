#!/usr/bin/env bash
# gh353-vendored-router-audit.sh — GH-353: audit and remediate target ROUTER.md ROADMAP.md frozen status.
#
# Comprehensive regression test matrix:
#   1. Clean releases-mode repo reports `ok` (rc=0).
#   2. Drifted releases-mode repo (legacy ROUTER.md with active ROADMAP.md) reports `ROUTER DRIFT` (rc=1 on --check).
#   3. Releases negative: mention dashboard only in unrelated prose outside Role split / Startup -> fails audit.
#   4. Releases negative: missing ROADMAP.md declaration in Role split -> fails audit.
#   5. Releases negative: obsolete dashboard in Role split `ROADMAP-DASHBOARD.md = obsolete; do not read` -> fails audit.
#   6. Releases negative: historical archive only dashboard in Role split -> fails audit.
#   7. Releases negative: negated dashboard in Startup `Do not read ROADMAP-DASHBOARD.md` -> fails audit.
#   8. Releases negative: historical context dashboard in Startup -> fails audit.
#   9. Releases negative: multi-clause active directive `ROADMAP.md is frozen for historical reference; nevertheless use ROADMAP.md for current work` -> fails audit.
#  10. Releases negative: contradictory keywords `ROADMAP.md = current priorities pointer; frozen legacy; releases.db is source of truth` -> fails audit.
#  11. Releases negative: prose active ROADMAP in Role split `ROADMAP.md is used for current priorities` -> fails audit.
#  12. Releases negative: asterisk list marker in Role split `* ROADMAP.md = active pointer ledger` -> fails audit.
#  13. Releases negative: Startup sequence with Open verb `Open ROADMAP.md to find current work` -> fails audit.
#  14. Releases negative: Startup sequence with Consult verb `Consult ROADMAP.md first` -> fails audit.
#  15. Releases negative: Startup sequence with Use verb `Use ROADMAP.md for current work` -> fails audit.
#  16. Releases negative: Startup sequence with negated frozen `ROADMAP.md is not frozen; use it for current work` -> fails audit.
#  17. Releases negative: Startup sequence with markdown link `[ROADMAP.md](path)` -> fails audit.
#  18. Releases negative: Missing Startup sequence section -> fails audit.
#  19. Releases negative: Duplicate Role split and Startup sections -> fails audit.
#  20. Releases clean valid negations: `do not use it` and `do not use ROADMAP.md for current work` pass audit.
#  21. Releases --fix: collapses duplicate roadmap steps in Startup to exactly 1 step, passes post-fix audit.
#  22. Releases --fix: removes duplicate sections down to exactly 1 Role split and 1 Startup sequence.
#  23. Releases --fix: preserves prefixed custom sections `## Role split rationale` and `## Startup sequence notes` with byte-for-byte cmp.
#  24. Releases --fix: exact byte-level cmp on custom section with CRLF and idempotent re-run cmp.
#  25. Mode parser: commented `# ROADMAP_SOURCE=releases` in .pdda-mode is legacy mode.
#  26. Mode parser: prefix `NOT_ROADMAP_SOURCE=releases` in .pdda-mode is legacy mode.
#  27. Mode parser: whitespace `  ROADMAP_SOURCE  =  releases  # comment` in .pdda-mode is releases mode.
#  28. Mode parser: unreadable .pdda-mode reports error and exits non-zero on --check.
#  29. Clean legacy-mode repo reports `ok` (rc=0).
#  30. Clean legacy-mode repo with Markdown link in Startup reports `ok` (rc=0).
#  31. Clean legacy-mode repo with `ROADMAP.md is not frozen` in Startup reports `ok` (rc=0).
#  32. Legacy negative: Role split with false-frozen ROADMAP.md -> fails audit.
#  33. Legacy negative: Role split with two contradictory lines (active + frozen) -> fails audit.
#  34. Legacy negative: Role split with asterisk marker `* ROADMAP.md = frozen` -> fails audit.
#  35. Legacy negative: Role split with inactive `not active; obsolete record of deferred work` -> fails audit.
#  36. Legacy negative: Role split with releases.db mention -> fails audit.
#  37. Legacy negative: Startup sequence with false-frozen ROADMAP.md -> fails audit.
#  38. Legacy negative: Startup sequence with negated `Do not read ROADMAP.md` -> fails audit.
#  39. Legacy negative: Startup sequence with `ROADMAP.md is not frozen; do not read ROADMAP.md` -> fails audit.
#  40. Legacy negative: Startup sequence with releases.sql mention -> fails audit.
#  41. Legacy negative: Missing Role split section -> fails audit.
#  42. Legacy negative: Missing Startup sequence section -> fails audit.
#  43. Legacy negative: leftover ROADMAP-DASHBOARD.md file on disk + clean router reports ok (not fooled by file).
#  44. Legacy --fix: removes two-line contradictory frozen role lines, standalone releases tokens, creates/repairs missing sections, restores active ROADMAP.md, strips dashboard, passes post-fix audit.
#  45. Missing ROUTER.md reports error and exits non-zero on --check.
#  46. Unreadable ROUTER.md reports error and exits non-zero on --check.
#  47. `xyz-sync.sh check` surfaces router drift for registered vendored repositories.
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
- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
## Startup sequence
1. Read `ROADMAP-DASHBOARD.md` (ROADMAP.md is frozen legacy).
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_NO_RMI" 2>&1)"; rc=$?
ok "omitted ROADMAP.md role entry reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 5. Releases negative: obsolete dashboard in Role split ─────────────────────────
R_REL_OBSOLETE_DASH="$(mkrepo rel_obsolete_dash)"
require_fixture "$R_REL_OBSOLETE_DASH" "obsolete dash releases repo"
touch "$R_REL_OBSOLETE_DASH/releases.db"
cat > "$R_REL_OBSOLETE_DASH/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = obsolete; do not read
- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip
## Startup sequence
1. Read `ROADMAP-DASHBOARD.md` (ROADMAP.md is frozen legacy).
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_OBSOLETE_DASH" 2>&1)"; rc=$?
ok "obsolete dashboard declaration in Role split reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 6. Releases negative: historical archive dashboard in Role split ───────────────
R_REL_HIST_DASH="$(mkrepo rel_hist_dash)"
require_fixture "$R_REL_HIST_DASH" "hist dash releases repo"
touch "$R_REL_HIST_DASH/releases.db"
cat > "$R_REL_HIST_DASH/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = historical archive
- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip
## Startup sequence
1. Read `ROADMAP-DASHBOARD.md` (ROADMAP.md is frozen legacy).
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_HIST_DASH" 2>&1)"; rc=$?
ok "historical archive dashboard declaration in Role split reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 7. Releases negative: negated dashboard in Startup ─────────────────────────────
R_REL_NEG_DASH="$(mkrepo rel_neg_dash)"
require_fixture "$R_REL_NEG_DASH" "neg dash releases repo"
touch "$R_REL_NEG_DASH/releases.db"
cat > "$R_REL_NEG_DASH/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip
## Startup sequence
1. Do not read ROADMAP-DASHBOARD.md
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_NEG_DASH" 2>&1)"; rc=$?
ok "negated dashboard read in Startup sequence reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 8. Releases negative: historical context dashboard in Startup ──────────────────
R_REL_HIST_STARTUP="$(mkrepo rel_hist_startup)"
require_fixture "$R_REL_HIST_STARTUP" "hist startup releases repo"
touch "$R_REL_HIST_STARTUP/releases.db"
cat > "$R_REL_HIST_STARTUP/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip
## Startup sequence
1. Read ROADMAP-DASHBOARD.md for historical context
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_HIST_STARTUP" 2>&1)"; rc=$?
ok "historical context dashboard directive in Startup reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 9. Releases negative: multi-clause active directive in Startup ─────────────────
R_REL_MULTI_CLAUSE="$(mkrepo rel_multi_clause)"
require_fixture "$R_REL_MULTI_CLAUSE" "multi clause releases repo"
touch "$R_REL_MULTI_CLAUSE/releases.db"
cat > "$R_REL_MULTI_CLAUSE/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip
## Startup sequence
1. Read `ROADMAP-DASHBOARD.md`.
2. ROADMAP.md is frozen for historical reference; nevertheless use ROADMAP.md for current work.
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_MULTI_CLAUSE" 2>&1)"; rc=$?
ok "multi-clause line with active directive despite frozen text reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 10. Releases negative: contradictory keywords in Role split ────────────────────
R_REL_CONTRADICT="$(mkrepo rel_contradict)"
require_fixture "$R_REL_CONTRADICT" "contradictory releases repo"
touch "$R_REL_CONTRADICT/releases.db"
cat > "$R_REL_CONTRADICT/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
- `ROADMAP.md` = current priorities pointer; frozen legacy; releases.db is source of truth
## Startup sequence
1. Read `ROADMAP-DASHBOARD.md` (ROADMAP.md is frozen legacy).
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_CONTRADICT" 2>&1)"; rc=$?
ok "contradictory current priorities pointer + frozen in Role split reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 11. Releases negative: prose active ROADMAP in Role split ──────────────────────
R_REL_PROSE_ROLE="$(mkrepo rel_prose_role)"
require_fixture "$R_REL_PROSE_ROLE" "prose role releases repo"
touch "$R_REL_PROSE_ROLE/releases.db"
cat > "$R_REL_PROSE_ROLE/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip
ROADMAP.md is used for current priorities
## Startup sequence
1. Read `ROADMAP-DASHBOARD.md` (ROADMAP.md is frozen legacy).
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_PROSE_ROLE" 2>&1)"; rc=$?
ok "prose active ROADMAP in Role split reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 12. Releases negative: asterisk list marker in Role split ──────────────────────
R_REL_ASTERISK="$(mkrepo rel_asterisk)"
require_fixture "$R_REL_ASTERISK" "asterisk releases repo"
touch "$R_REL_ASTERISK/releases.db"
cat > "$R_REL_ASTERISK/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
* `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
* `ROADMAP.md` = active pointer ledger
## Startup sequence
1. Read `ROADMAP-DASHBOARD.md` (ROADMAP.md is frozen legacy).
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_ASTERISK" 2>&1)"; rc=$?
ok "asterisk-marker active ROADMAP.md declaration in Role split reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 13. Releases negative: Startup sequence with Open verb ─────────────────────────
R_REL_OPEN_STARTUP="$(mkrepo rel_open_startup)"
require_fixture "$R_REL_OPEN_STARTUP" "open startup releases repo"
touch "$R_REL_OPEN_STARTUP/releases.db"
cat > "$R_REL_OPEN_STARTUP/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip
## Startup sequence
1. Open ROADMAP.md to find current work.
2. Read ROADMAP-DASHBOARD.md
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_OPEN_STARTUP" 2>&1)"; rc=$?
ok "Startup sequence with Open ROADMAP.md reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 14. Releases negative: Startup sequence with Consult verb ──────────────────────
R_REL_CONSULT_STARTUP="$(mkrepo rel_consult_startup)"
require_fixture "$R_REL_CONSULT_STARTUP" "consult startup releases repo"
touch "$R_REL_CONSULT_STARTUP/releases.db"
cat > "$R_REL_CONSULT_STARTUP/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip
## Startup sequence
- Consult ROADMAP.md first
- Check ROADMAP-DASHBOARD.md
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_CONSULT_STARTUP" 2>&1)"; rc=$?
ok "Startup sequence with Consult ROADMAP.md reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 15. Releases negative: Startup sequence with Use verb ──────────────────────────
R_REL_USE_STARTUP="$(mkrepo rel_use_startup)"
require_fixture "$R_REL_USE_STARTUP" "use startup releases repo"
touch "$R_REL_USE_STARTUP/releases.db"
cat > "$R_REL_USE_STARTUP/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip
## Startup sequence
1. Use ROADMAP.md for current work.
2. Read ROADMAP-DASHBOARD.md
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_USE_STARTUP" 2>&1)"; rc=$?
ok "Startup sequence with Use ROADMAP.md for current work reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 16. Releases negative: Startup sequence with negated frozen phrase ─────────────
R_REL_NOT_FROZEN_STARTUP="$(mkrepo rel_not_frozen_startup)"
require_fixture "$R_REL_NOT_FROZEN_STARTUP" "not frozen startup releases repo"
touch "$R_REL_NOT_FROZEN_STARTUP/releases.db"
cat > "$R_REL_NOT_FROZEN_STARTUP/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip
## Startup sequence
1. ROADMAP.md is not frozen; use it for current work.
2. Read ROADMAP-DASHBOARD.md
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_NOT_FROZEN_STARTUP" 2>&1)"; rc=$?
ok "Startup sequence saying ROADMAP.md is not frozen reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 17. Releases negative: Startup sequence with markdown link ────────────────────
R_REL_LINK_STARTUP="$(mkrepo rel_link_startup)"
require_fixture "$R_REL_LINK_STARTUP" "link startup releases repo"
touch "$R_REL_LINK_STARTUP/releases.db"
cat > "$R_REL_LINK_STARTUP/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip
## Startup sequence
1. See [ROADMAP.md](PROJECT/ROADMAP.md) for active items.
2. Read ROADMAP-DASHBOARD.md
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_LINK_STARTUP" 2>&1)"; rc=$?
ok "Startup sequence with markdown link to ROADMAP.md reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 18. Releases negative: missing Startup sequence section ─────────────────────────
R_REL_NO_START="$(mkrepo rel_no_start)"
require_fixture "$R_REL_NO_START" "no start releases repo"
touch "$R_REL_NO_START/releases.db"
cat > "$R_REL_NO_START/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_NO_START" 2>&1)"; rc=$?
ok "missing Startup sequence section reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 19. Releases negative: duplicate sections ─────────────────────────────────────
R_REL_DUP_SECT="$(mkrepo rel_dup_sect)"
require_fixture "$R_REL_DUP_SECT" "dup sect releases repo"
touch "$R_REL_DUP_SECT/releases.db"
cat > "$R_REL_DUP_SECT/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip
## Startup sequence
1. Read ROADMAP-DASHBOARD.md
## Role split
- `ROADMAP.md` = active work
## Startup sequence
1. Read ROADMAP.md
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_DUP_SECT" 2>&1)"; rc=$?
ok "duplicate Role split / Startup sequence sections report drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 20. Releases clean valid negations pass audit ──────────────────────────────────
R_REL_VALID_NEG="$(mkrepo rel_valid_neg)"
require_fixture "$R_REL_VALID_NEG" "valid neg releases repo"
touch "$R_REL_VALID_NEG/releases.db"
cat > "$R_REL_VALID_NEG/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip
## Startup sequence
1. Read `ROADMAP-DASHBOARD.md`.
2. ROADMAP.md is frozen; do not use it for current work.
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_VALID_NEG" 2>&1)"; rc=$?
ok "valid negation 'do not use it for current work' passes releases audit (rc=0)" "$(is "$rc" "0"; echo $?)"

# ── 21. Releases --fix: collapses duplicate roadmap steps in Startup ───────────────
R_REL_DUP="$(mkrepo rel_dup)"
require_fixture "$R_REL_DUP" "dup releases repo"
touch "$R_REL_DUP/releases.db"
cat > "$R_REL_DUP/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP.md` = active work
## Startup sequence
1. Read ROUTER.md
2. Open ROADMAP.md to find current work.
3. Consult [ROADMAP.md](ROADMAP.md) for items.
4. Read ROADMAP-DASHBOARD.md
MD

python3 "$AUDIT_PY" --fix "$R_REL_DUP" >/dev/null
out_dup_check="$(python3 "$AUDIT_PY" --check "$R_REL_DUP" 2>&1)"; rc_dup=$?
ok "dup roadmap steps fixed and passes audit (rc=0)" "$(is "$rc_dup" "0"; echo $?)"
dup_count="$(grep -c "ROADMAP-DASHBOARD.md" "$R_REL_DUP/ROUTER.md")"
ok "Startup sequence collapsed duplicate directives to 1 canonical step" "$(is "$dup_count" "2"; echo $?)"

# ── 22. Releases --fix: removes duplicate sections down to exactly 1 each ──────────
python3 "$AUDIT_PY" --fix "$R_REL_DUP_SECT" >/dev/null
out_dup_sect_check="$(python3 "$AUDIT_PY" --check "$R_REL_DUP_SECT" 2>&1)"; rc_dup_sect=$?
ok "duplicate sections fixed and passes audit (rc=0)" "$(is "$rc_dup_sect" "0"; echo $?)"
role_sect_count="$(grep -c "## Role split" "$R_REL_DUP_SECT/ROUTER.md")"
start_sect_count="$(grep -c "## Startup sequence" "$R_REL_DUP_SECT/ROUTER.md")"
ok "fixed ROUTER.md has exactly 1 ## Role split" "$(is "$role_sect_count" "1"; echo $?)"
ok "fixed ROUTER.md has exactly 1 ## Startup sequence" "$(is "$start_sect_count" "1"; echo $?)"

# ── 23. Releases --fix: preserves prefixed custom sections byte-for-byte ───────────
R_REL_PREFIXED_CUSTOM="$(mkrepo rel_prefixed_custom)"
require_fixture "$R_REL_PREFIXED_CUSTOM" "prefixed custom repo"
touch "$R_REL_PREFIXED_CUSTOM/releases.db"
cat > "$R_REL_PREFIXED_CUSTOM/ROUTER.md" <<'MD'
# ROUTER.md
## Role split rationale
Rationale notes here: $CUSTOM_PARAM = 100!
## Role split
- `ROADMAP.md` = active work
## Startup sequence notes
Special notes about startup sequence: DO NOT DELETE!
## Startup sequence
1. Read ROADMAP.md
MD

# Save custom section slices before fix
python3 -c "
with open('$R_REL_PREFIXED_CUSTOM/ROUTER.md', 'rb') as f:
    data = f.read()
s1_start = data.find(b'## Role split rationale')
s1_end = data.find(b'## Role split\n')
s2_start = data.find(b'## Startup sequence notes')
s2_end = data.find(b'## Startup sequence\n')
with open('$WORK/custom_s1_exp.bin', 'wb') as out:
    out.write(data[s1_start:s1_end])
with open('$WORK/custom_s2_exp.bin', 'wb') as out:
    out.write(data[s2_start:s2_end])
"

python3 "$AUDIT_PY" --fix "$R_REL_PREFIXED_CUSTOM" >/dev/null
out_pref_check="$(python3 "$AUDIT_PY" --check "$R_REL_PREFIXED_CUSTOM" 2>&1)"; rc_pref=$?
ok "prefixed custom sections repo fixed and passes audit (rc=0)" "$(is "$rc_pref" "0"; echo $?)"

python3 -c "
with open('$R_REL_PREFIXED_CUSTOM/ROUTER.md', 'rb') as f:
    data = f.read()
s1_start = data.find(b'## Role split rationale')
s1_end = data.find(b'## Role split\n')
s2_start = data.find(b'## Startup sequence notes')
s2_end = data.find(b'## Startup sequence\n')
with open('$WORK/custom_s1_act.bin', 'wb') as out:
    out.write(data[s1_start:s1_end])
with open('$WORK/custom_s2_act.bin', 'wb') as out:
    out.write(data[s2_start:s2_end])
"

cmp "$WORK/custom_s1_exp.bin" "$WORK/custom_s1_act.bin" >/dev/null 2>&1; rc_s1=$?
cmp "$WORK/custom_s2_exp.bin" "$WORK/custom_s2_act.bin" >/dev/null 2>&1; rc_s2=$?
ok "prefixed '## Role split rationale' preserved byte-for-byte with cmp" "$(is "$rc_s1" "0"; echo $?)"
ok "prefixed '## Startup sequence notes' preserved byte-for-byte with cmp" "$(is "$rc_s2" "0"; echo $?)"

# ── 24. Releases --fix: exact byte-level cmp on custom section with CRLF & idempotence
R_REL_CRLF="$(mkrepo rel_crlf)"
require_fixture "$R_REL_CRLF" "crlf releases repo"
touch "$R_REL_CRLF/releases.db"

CUSTOM_CRLF_TEXT="## Custom Section\r\nExact custom text with CRLF line endings: \$SPECIAL \`code\`!\r\n"

printf "# ROUTER.md\r\n\r\n## Role split\r\n- \`ROADMAP.md\` = active pointer ledger\r\n\r\n%b\r\n## Startup sequence\r\n1. Consult ROADMAP.md to find current tasks.\r\n" "$CUSTOM_CRLF_TEXT" > "$R_REL_CRLF/ROUTER.md"

# Save custom section slice before fix
python3 -c "
with open('$R_REL_CRLF/ROUTER.md', 'rb') as f:
    data = f.read()
start = data.find(b'## Custom Section')
end = data.find(b'## Startup sequence')
with open('$WORK/custom_expected.bin', 'wb') as out:
    out.write(data[start:end])
"

fix_out="$(python3 "$AUDIT_PY" --fix "$R_REL_CRLF" 2>&1)"; rc_fix=$?
ok "router_audit.py --fix returns rc=0 on CRLF fixture" "$(is "$rc_fix" "0"; echo $?)"

after_check_out="$(python3 "$AUDIT_PY" --check "$R_REL_CRLF" 2>&1)"; rc_after=$?
ok "after --fix, CRLF repo passes audit with rc=0" "$(is "$rc_after" "0"; echo $?)"

# Extract custom section slice after fix
python3 -c "
with open('$R_REL_CRLF/ROUTER.md', 'rb') as f:
    data = f.read()
start = data.find(b'## Custom Section')
end = data.find(b'## Startup sequence')
with open('$WORK/custom_actual.bin', 'wb') as out:
    out.write(data[start:end])
"
cmp "$WORK/custom_expected.bin" "$WORK/custom_actual.bin" >/dev/null 2>&1; rc_cmp=$?
ok "custom section bytes match exactly with cmp (CRLF intact)" "$(is "$rc_cmp" "0"; echo $?)"

# Idempotence
cp "$R_REL_CRLF/ROUTER.md" "$WORK/router_pass1.bin"
python3 "$AUDIT_PY" --fix "$R_REL_CRLF" >/dev/null
cmp "$WORK/router_pass1.bin" "$R_REL_CRLF/ROUTER.md" >/dev/null 2>&1; rc_idemp=$?
ok "--fix is byte-level idempotent on second run" "$(is "$rc_idemp" "0"; echo $?)"

# ── 25. Mode parser: commented line in .pdda-mode is legacy mode ───────────────────
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

# ── 26. Mode parser: prefix line in .pdda-mode is legacy mode ───────────────────────
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

# ── 27. Mode parser: whitespace in .pdda-mode is releases mode ────────────────────
R_PDDA_WS="$(mkrepo pdda_ws)"
require_fixture "$R_PDDA_WS" "pdda ws repo"
cat > "$R_PDDA_WS/.pdda-mode" <<'MODE'
   ROADMAP_SOURCE   =   releases  # comment
MODE
cat > "$R_PDDA_WS/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
- `ROADMAP.md` = LEGACY pointer ledger, frozen since the `ROADMAP_SOURCE=releases` flip — releases.db
## Startup sequence
1. Read `ROADMAP-DASHBOARD.md` (ROADMAP.md is frozen legacy).
MD

out="$(python3 "$AUDIT_PY" --check "$R_PDDA_WS" 2>&1)"; rc=$?
ok "whitespace-padded ROADMAP_SOURCE=releases is recognized as releases mode (rc=0)" "$(is "$rc" "0"; echo $?)"

# ── 28. Mode parser: unreadable .pdda-mode reports error ──────────────────────────
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

# ── 29. Clean legacy-mode repo ─────────────────────────────────────────────────────
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

# ── 30. Clean legacy-mode repo with Markdown link in Startup ───────────────────────
R_LEG_MD_LINK="$(mkrepo leg_md_link)"
require_fixture "$R_LEG_MD_LINK" "clean legacy md link repo"
cat > "$R_LEG_MD_LINK/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP.md` = the pointer ledger of current, completed, attempted, and deferred work
## Startup sequence
1. Read [the roadmap](ROADMAP.md) to find active effort.
MD

out="$(python3 "$AUDIT_PY" --check "$R_LEG_MD_LINK" 2>&1)"; rc=$?
ok "clean legacy-mode repo with Markdown link in Startup reports ok (rc=0)" "$(is "$rc" "0"; echo $?)"

# ── 31. Clean legacy-mode repo with not frozen in Startup ──────────────────────────
R_LEG_NOT_FROZEN="$(mkrepo leg_not_frozen)"
require_fixture "$R_LEG_NOT_FROZEN" "clean legacy not frozen repo"
cat > "$R_LEG_NOT_FROZEN/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP.md` = the pointer ledger of current work
## Startup sequence
1. Read `ROADMAP.md` to find active effort (ROADMAP.md is not frozen).
MD

out="$(python3 "$AUDIT_PY" --check "$R_LEG_NOT_FROZEN" 2>&1)"; rc=$?
ok "clean legacy-mode repo with 'not frozen' in Startup reports ok (rc=0)" "$(is "$rc" "0"; echo $?)"

# ── 32. Legacy negative: Role split with false-frozen ROADMAP.md ───────────────────
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

# ── 33. Legacy negative: Role split with two contradictory lines (active + frozen) ─
R_LEG_TWO_LINE="$(mkrepo leg_two_line)"
require_fixture "$R_LEG_TWO_LINE" "two line contradictory legacy repo"
cat > "$R_LEG_TWO_LINE/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP.md` = the pointer ledger of current work
ROADMAP.md is frozen legacy

## Startup sequence
1. Read `ROADMAP.md` to find work.
MD

out="$(python3 "$AUDIT_PY" --check "$R_LEG_TWO_LINE" 2>&1)"; rc=$?
ok "legacy repo with two contradictory lines in Role split reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 34. Legacy negative: Role split with asterisk marker ───────────────────────────
R_LEG_ASTERISK="$(mkrepo leg_asterisk)"
require_fixture "$R_LEG_ASTERISK" "asterisk legacy repo"
cat > "$R_LEG_ASTERISK/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
* `ROADMAP.md` = LEGACY pointer ledger, frozen
## Startup sequence
1. Read `ROADMAP.md` to find active effort.
MD

out="$(python3 "$AUDIT_PY" --check "$R_LEG_ASTERISK" 2>&1)"; rc=$?
ok "legacy repo with asterisk false-frozen role reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 35. Legacy negative: Role split with inactive declaration ──────────────────────
R_LEG_INACTIVE_ROLE="$(mkrepo leg_inactive_role)"
require_fixture "$R_LEG_INACTIVE_ROLE" "inactive role legacy repo"
cat > "$R_LEG_INACTIVE_ROLE/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP.md` = not active; obsolete record of deferred work
## Startup sequence
1. Read ROUTER.md
2. Read `ROADMAP.md` to find active effort.
MD

out="$(python3 "$AUDIT_PY" --check "$R_LEG_INACTIVE_ROLE" 2>&1)"; rc=$?
ok "legacy repo with not active; obsolete record in Role split reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 36. Legacy negative: Role split with releases.db mention ──────────────────────
R_LEG_DB_ROLE="$(mkrepo leg_db_role)"
require_fixture "$R_LEG_DB_ROLE" "db role legacy repo"
cat > "$R_LEG_DB_ROLE/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP.md` = the pointer ledger of current work (releases.db is source)
## Startup sequence
1. Read `ROADMAP.md` to find work.
MD

out="$(python3 "$AUDIT_PY" --check "$R_LEG_DB_ROLE" 2>&1)"; rc=$?
ok "legacy repo with releases.db token in Role split reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 37. Legacy negative: Startup sequence with false-frozen ROADMAP.md ────────────
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

# ── 38. Legacy negative: Startup sequence with negated Do not read ─────────────────
R_LEG_NEG_READ="$(mkrepo leg_neg_read)"
require_fixture "$R_LEG_NEG_READ" "neg read legacy repo"
cat > "$R_LEG_NEG_READ/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP.md` = the pointer ledger of current work
## Startup sequence
1. Read ROUTER.md
2. Do not read ROADMAP.md.
MD

out="$(python3 "$AUDIT_PY" --check "$R_LEG_NEG_READ" 2>&1)"; rc=$?
ok "legacy repo with Do not read ROADMAP.md reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 39. Legacy negative: Startup sequence with not frozen + do not read contradiction
R_LEG_START_CONTRADICT="$(mkrepo leg_start_contradict)"
require_fixture "$R_LEG_START_CONTRADICT" "start contradict legacy repo"
cat > "$R_LEG_START_CONTRADICT/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP.md` = the pointer ledger of current work
## Startup sequence
1. ROADMAP.md is not frozen; do not read ROADMAP.md.
MD

out="$(python3 "$AUDIT_PY" --check "$R_LEG_START_CONTRADICT" 2>&1)"; rc=$?
ok "legacy repo with not frozen + do not read contradiction in Startup reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 40. Legacy negative: Startup sequence with releases.sql mention ───────────────
R_LEG_SQL_START="$(mkrepo leg_sql_start)"
require_fixture "$R_LEG_SQL_START" "sql start legacy repo"
cat > "$R_LEG_SQL_START/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP.md` = the pointer ledger of current work
## Startup sequence
1. Read `ROADMAP.md` via releases.sql.
MD

out="$(python3 "$AUDIT_PY" --check "$R_LEG_SQL_START" 2>&1)"; rc=$?
ok "legacy repo with releases.sql in Startup sequence reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 41. Legacy negative: missing Role split section ───────────────────────────────
R_LEG_NO_ROLE="$(mkrepo leg_no_role)"
require_fixture "$R_LEG_NO_ROLE" "no role legacy repo"
cat > "$R_LEG_NO_ROLE/ROUTER.md" <<'MD'
# ROUTER.md
## Startup sequence
1. Read `ROADMAP.md` to find active effort.
MD

out="$(python3 "$AUDIT_PY" --check "$R_LEG_NO_ROLE" 2>&1)"; rc=$?
ok "legacy repo missing Role split reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 42. Legacy negative: missing Startup sequence section ─────────────────────────
R_LEG_NO_START="$(mkrepo leg_no_start)"
require_fixture "$R_LEG_NO_START" "no start legacy repo"
cat > "$R_LEG_NO_START/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP.md` = the pointer ledger of current work
MD

out="$(python3 "$AUDIT_PY" --check "$R_LEG_NO_START" 2>&1)"; rc=$?
ok "legacy repo missing Startup sequence reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 43. Legacy negative: leftover ROADMAP-DASHBOARD.md file on disk ───────────────
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

# ── 44. Remediate legacy repo with --fix ──────────────────────────────────────────
R_LEG_DRIFT="$(mkrepo leg_drift)"
require_fixture "$R_LEG_DRIFT" "drifted legacy repo"
cat > "$R_LEG_DRIFT/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
* `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
* `ROADMAP.md` = LEGACY pointer ledger, frozen
releases.db is the source of truth
ROADMAP.md is frozen legacy

## Startup sequence
1. Read ROUTER.md
2. Read `ROADMAP-DASHBOARD.md` to find work.
MD

python3 "$AUDIT_PY" --fix "$R_LEG_DRIFT" >/dev/null
out_remed="$(python3 "$AUDIT_PY" --check "$R_LEG_DRIFT" 2>&1)"; rc_remed=$?
ok "drifted legacy repo remediated with --fix (rc=0)" "$(is "$rc_remed" "0"; echo $?)"
content_leg="$(cat "$R_LEG_DRIFT/ROUTER.md")"
ok "legacy --fix removed ROADMAP-DASHBOARD.md declaration" "$(! has "$content_leg" "ROADMAP-DASHBOARD.md"; echo $?)"
ok "legacy --fix stripped standalone releases.db line" "$(! has "$content_leg" "releases.db is the source"; echo $?)"
ok "legacy --fix stripped contradictory frozen line" "$(! has "$content_leg" "ROADMAP.md is frozen legacy"; echo $?)"
ok "legacy --fix restored active pointer ledger text" "$(has "$content_leg" "pointer ledger of current"; echo $?)"
ok "legacy --fix restored active ROADMAP.md read step" "$(has "$content_leg" "Read \`ROADMAP.md\`"; echo $?)"

# ── 45. Missing ROUTER.md handling ────────────────────────────────────────────────
R_MISSING="$(mkrepo missing_router)"
require_fixture "$R_MISSING" "missing router repo"
out="$(python3 "$AUDIT_PY" --check "$R_MISSING" 2>&1)"; rc=$?
ok "missing ROUTER.md reports non-zero exit on --check" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"
ok "missing ROUTER.md output indicates not found" "$(has "$out" "ROUTER.md not found"; echo $?)"

# ── 46. Unreadable ROUTER.md handling ─────────────────────────────────────────────
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

# ── 47. xyz-sync.sh check integration ─────────────────────────────────────────────
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
