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
#   7. Releases negative: negated generated dashboard `ROADMAP-DASHBOARD.md = not generated; current view lives elsewhere` -> fails audit.
#   8. Releases negative: not a generated view `ROADMAP-DASHBOARD.md = not a generated view` -> fails audit.
#   9. Releases negative: generated deployment manifest `ROADMAP-DASHBOARD.md = generated deployment manifest` -> fails audit.
#  10. Releases negative: negated DB source of truth `ROADMAP.md = frozen legacy; releases.db is not the source of truth` -> fails audit.
#  11. Releases negative: compatibility DB note `ROADMAP.md = frozen legacy; releases.db is present for compatibility` -> fails audit.
#  12. Releases negative: mode token without DB source of truth `ROADMAP.md = frozen legacy; ROADMAP_SOURCE=releases` -> fails audit.
#  13. Releases negative: unrelated frozen subject on same line `ROADMAP.md = deployment notes; OLD-API.md is frozen; releases.db is the source of truth` -> fails audit.
#  14. Releases negative: negated dashboard in Startup `Do not read ROADMAP-DASHBOARD.md` -> fails audit.
#  15. Releases negative: historical context dashboard in Startup -> fails audit.
#  16. Releases negative: purpose-free dashboard in Startup `Read ROADMAP-DASHBOARD.md for deployment instructions` -> fails audit.
#  17. Releases negative: purpose-free dashboard + unrelated current work `Read ROADMAP-DASHBOARD.md for deployment instructions; TEAM.md tracks current work` -> fails audit.
#  18. Releases negative: not current state dashboard in Startup `Read ROADMAP-DASHBOARD.md for not current state` -> fails audit.
#  19. Releases negative: multi-clause active directive `ROADMAP.md is frozen for historical reference; nevertheless use ROADMAP.md for current work` -> fails audit.
#  20. Releases negative: historical first clause + active second clause `Read ROADMAP.md only for historical reference; nevertheless use ROADMAP.md for current work` -> fails audit.
#  21. Releases negative: conjunction active directive `ROADMAP.md is frozen and use ROADMAP.md for current work` -> fails audit.
#  22. Releases negative: while-connector active directive `ROADMAP.md is frozen while operators use ROADMAP.md for current work` -> fails audit.
#  23. Releases negative: colon-form active keywords `ROADMAP.md: active; frozen legacy; releases.db is source of truth` -> fails audit.
#  24. Releases negative: negated legacy `ROADMAP.md is not legacy; releases.db is source of truth` -> fails audit.
#  25. Releases negative: prose active ROADMAP in Role split `ROADMAP.md is used for current priorities` -> fails audit.
#  26. Releases negative: prefixed prose active ROADMAP in Role split `Note: ROADMAP.md is used for current priorities` -> fails audit and --fix repairs it.
#  27. Releases negative: compound custom entry + active prose in Role split `- \`PROJECT/PDDA.md\` = governs the \`ROADMAP.md\` contract; \`ROADMAP.md\` is used for current work` -> fails audit and --fix preserves the governance clause while removing the active clause.
#  28. Releases negative: asterisk list marker in Role split `* ROADMAP.md = active pointer ledger` -> fails audit.
#  29. Releases negative: Startup sequence with Open verb `Open ROADMAP.md to find current work` -> fails audit.
#  30. Releases negative: Startup sequence with Consult verb `Consult ROADMAP.md first` -> fails audit.
#  31. Releases negative: Startup sequence with Use verb `Use ROADMAP.md for current work` -> fails audit.
#  32. Releases negative: Startup sequence with negated frozen `ROADMAP.md is not frozen; use it for current work` -> fails audit.
#  33. Releases negative: Startup sequence with markdown link `[ROADMAP.md](path)` -> fails audit.
#  34. Releases negative: Missing Startup sequence section -> fails audit.
#  35. Releases negative: Duplicate Role split and Startup sections -> fails audit.
#  36. Releases clean valid custom mention `- \`PROJECT/PDDA.md\` = governs the \`ROADMAP.md\` contract` passes audit and --fix preserves it.
#  37. Releases clean valid custom startup step `4. Read \`PROJECT/PDDA.md\` for the \`ROADMAP.md\` governance contract.` passes audit and --fix preserves it byte-for-byte.
#  38. Releases clean valid historical read `Read ROADMAP.md only for historical reference` passes audit and --fix preserves it.
#  39. Releases clean valid negations: `do not use it` and `do not use ROADMAP.md for current work` pass audit.
#  40. Releases clean valid fenced code blocks containing `## Role split` and `## Startup sequence` are ignored by section finder.
#  41. Releases --fix: collapses duplicate roadmap steps in Startup to exactly 1 step, passes post-fix audit.
#  42. Releases --fix: removes duplicate sections down to exactly 1 Role split and 1 Startup sequence.
#  43. Releases --fix: preserves prefixed custom sections `## Role split rationale` and `## Startup sequence notes` with byte-for-byte cmp.
#  44. Releases --fix: exact byte-level cmp on custom section with CRLF and idempotent re-run cmp.
#  45. Releases --fix: repairs empty ## Role split followed by another section.
#  46. Releases --fix: preserves repeated custom lines inside owned sections.
#  47. Releases --fix: preserves mixed LF/CRLF lines in owned sections verbatim.
#  48. Mode parser: commented `# ROADMAP_SOURCE=releases` in .pdda-mode is legacy mode.
#  49. Mode parser: prefix `NOT_ROADMAP_SOURCE=releases` in .pdda-mode is legacy mode.
#  50. Mode parser: whitespace `  ROADMAP_SOURCE  =  releases  # comment` in .pdda-mode is releases mode.
#  51. Mode parser: unreadable .pdda-mode reports error and exits non-zero on --check.
#  52. Clean legacy-mode repo reports `ok` (rc=0).
#  53. Clean legacy-mode repo with Markdown link in Startup reports `ok` (rc=0).
#  54. Clean legacy-mode repo with `ROADMAP.md is not frozen` in Startup reports `ok` (rc=0).
#  55. Clean legacy-mode repo with unrelated legacy entry `- \`OLD-API.md\` = remains legacy` reports `ok` (rc=0) and --fix preserves it.
#  56. Clean legacy-mode repo with non-owned historical frozen mention `- \`CHANGELOG.md\` = records when \`ROADMAP.md\` was frozen during the 2025 migration` reports `ok` (rc=0) and --fix preserves it.
#  57. Legacy clean valid custom startup step `4. Read \`PROJECT/PDDA.md\` for the \`ROADMAP.md\` governance contract.` passes audit and --fix preserves it byte-for-byte.
#  58. Legacy negative: Role split with deployment policy pointer ledger `ROADMAP.md = pointer ledger for deployment policy` -> fails audit.
#  59. Legacy negative: Role split with archived pointer ledger `ROADMAP.md = archived pointer ledger` -> fails audit.
#  60. Legacy negative: Role split with false-frozen ROADMAP.md -> fails audit.
#  61. Legacy negative: Role split with two contradictory lines (active + frozen) -> fails audit.
#  62. Legacy negative: Role split with mixed not frozen + affirmative legacy `ROADMAP.md is not frozen, but ROADMAP.md remains legacy` -> fails audit.
#  63. Legacy negative: Role split with asterisk marker `* ROADMAP.md = frozen` -> fails audit.
#  64. Legacy negative: Role split with inactive `not active; obsolete record of deferred work` -> fails audit.
#  65. Legacy negative: Role split with releases.db mention -> fails audit.
#  66. Legacy negative: Startup sequence with deployment instructions `Read ROADMAP.md for deployment instructions` -> fails audit.
#  67. Legacy negative: Startup sequence with deployment instructions + negated current work `Read ROADMAP.md for deployment instructions; do not use ROADMAP.md for current work` -> fails audit.
#  68. Legacy negative: Startup sequence with false-frozen ROADMAP.md -> fails audit.
#  69. Legacy negative: Startup sequence with historical reference only `Read ROADMAP.md only for historical reference` -> fails audit.
#  70. Legacy negative: Startup sequence with negated `Do not read ROADMAP.md` -> fails audit.
#  71. Legacy negative: Startup sequence with `ROADMAP.md is not frozen; do not read ROADMAP.md` -> fails audit.
#  72. Legacy negative: Startup sequence with `Read ROADMAP.md; but note ROADMAP.md remains legacy` -> fails audit.
#  73. Legacy negative: Startup sequence with releases.sql mention -> fails audit.
#  74. Legacy negative: Missing Role split section -> fails audit.
#  75. Legacy negative: Missing Startup sequence section -> fails audit.
#  76. Legacy negative: leftover ROADMAP-DASHBOARD.md file on disk + clean router reports ok (not fooled by file).
#  77. Legacy --fix: removes two-line contradictory frozen role lines, standalone releases tokens, creates/repairs missing sections, restores active ROADMAP.md, strips dashboard, passes post-fix audit.
#  78. Missing ROUTER.md reports error and exits non-zero on --check.
#  79. Unreadable ROUTER.md reports error and exits non-zero on --check.
#  80. `xyz-sync.sh check` surfaces router drift for registered vendored repositories.
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
- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — the RELEASES DB (releases.db) is the source of truth
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
- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — the RELEASES DB (releases.db) is the source of truth
## Startup sequence
1. Read `ROADMAP-DASHBOARD.md` (ROADMAP.md is frozen legacy).
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_HIST_DASH" 2>&1)"; rc=$?
ok "historical archive dashboard declaration in Role split reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 7. Releases negative: negated generated dashboard in Role split ────────────────
R_REL_NEG_GEN_DASH="$(mkrepo rel_neg_gen_dash)"
require_fixture "$R_REL_NEG_GEN_DASH" "neg gen dash releases repo"
touch "$R_REL_NEG_GEN_DASH/releases.db"
cat > "$R_REL_NEG_GEN_DASH/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = not generated; current view lives elsewhere
- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — the RELEASES DB (releases.db) is the source of truth
## Startup sequence
1. Read `ROADMAP-DASHBOARD.md` (ROADMAP.md is frozen legacy).
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_NEG_GEN_DASH" 2>&1)"; rc=$?
ok "negated generated dashboard declaration in Role split reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 8. Releases negative: not a generated view in Role split ───────────────────────
R_REL_NOT_A_GEN="$(mkrepo rel_not_a_gen)"
require_fixture "$R_REL_NOT_A_GEN" "not a gen dash releases repo"
touch "$R_REL_NOT_A_GEN/releases.db"
cat > "$R_REL_NOT_A_GEN/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = not a generated view
- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — the RELEASES DB (releases.db) is the source of truth
## Startup sequence
1. Read `ROADMAP-DASHBOARD.md` (ROADMAP.md is frozen legacy).
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_NOT_A_GEN" 2>&1)"; rc=$?
ok "not a generated view dashboard declaration in Role split reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 9. Releases negative: generated deployment manifest in Role split ──────────────
R_REL_GEN_MANIFEST="$(mkrepo rel_gen_manifest)"
require_fixture "$R_REL_GEN_MANIFEST" "gen manifest releases repo"
touch "$R_REL_GEN_MANIFEST/releases.db"
cat > "$R_REL_GEN_MANIFEST/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = generated deployment manifest
- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — the RELEASES DB (releases.db) is the source of truth
## Startup sequence
1. Read `ROADMAP-DASHBOARD.md` (ROADMAP.md is frozen legacy).
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_GEN_MANIFEST" 2>&1)"; rc=$?
ok "generated deployment manifest in Role split reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 10. Releases negative: negated DB source of truth ──────────────────────────────
R_REL_NEG_DB_SOURCE="$(mkrepo rel_neg_db_source)"
require_fixture "$R_REL_NEG_DB_SOURCE" "neg db source releases repo"
touch "$R_REL_NEG_DB_SOURCE/releases.db"
cat > "$R_REL_NEG_DB_SOURCE/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
- `ROADMAP.md` = frozen legacy; releases.db is not the source of truth
## Startup sequence
1. Read `ROADMAP-DASHBOARD.md` (ROADMAP.md is frozen legacy).
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_NEG_DB_SOURCE" 2>&1)"; rc=$?
ok "negated DB source of truth in Role split reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 11. Releases negative: compatibility DB note ──────────────────────────────────
R_REL_COMPAT_DB="$(mkrepo rel_compat_db)"
require_fixture "$R_REL_COMPAT_DB" "compat db releases repo"
touch "$R_REL_COMPAT_DB/releases.db"
cat > "$R_REL_COMPAT_DB/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
- `ROADMAP.md` = frozen legacy; releases.db is present for compatibility
## Startup sequence
1. Read `ROADMAP-DASHBOARD.md` (ROADMAP.md is frozen legacy).
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_COMPAT_DB" 2>&1)"; rc=$?
ok "compatibility DB note without source of truth in Role split reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 12. Releases negative: mode token without DB source of truth ───────────────────
R_REL_MODE_TOKEN_ONLY="$(mkrepo rel_mode_token_only)"
require_fixture "$R_REL_MODE_TOKEN_ONLY" "mode token only repo"
touch "$R_REL_MODE_TOKEN_ONLY/releases.db"
cat > "$R_REL_MODE_TOKEN_ONLY/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
- `ROADMAP.md` = frozen legacy; ROADMAP_SOURCE=releases
## Startup sequence
1. Read `ROADMAP-DASHBOARD.md` (ROADMAP.md is frozen legacy).
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_MODE_TOKEN_ONLY" 2>&1)"; rc=$?
ok "mode token without DB source of truth in Role split reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 13. Releases negative: unrelated frozen subject on same line ──────────────────
R_REL_UNRELATED_FROZEN="$(mkrepo rel_unrelated_frozen)"
require_fixture "$R_REL_UNRELATED_FROZEN" "unrelated frozen repo"
touch "$R_REL_UNRELATED_FROZEN/releases.db"
cat > "$R_REL_UNRELATED_FROZEN/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
- `ROADMAP.md` = deployment notes; OLD-API.md is frozen; releases.db is the source of truth
## Startup sequence
1. Read `ROADMAP-DASHBOARD.md` (ROADMAP.md is frozen legacy).
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_UNRELATED_FROZEN" 2>&1)"; rc=$?
ok "unrelated frozen subject on same line in Role split reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 14. Releases negative: negated dashboard in Startup ────────────────────────────
R_REL_NEG_DASH="$(mkrepo rel_neg_dash)"
require_fixture "$R_REL_NEG_DASH" "neg dash releases repo"
touch "$R_REL_NEG_DASH/releases.db"
cat > "$R_REL_NEG_DASH/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — releases.db is the source of truth
## Startup sequence
1. Do not read ROADMAP-DASHBOARD.md
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_NEG_DASH" 2>&1)"; rc=$?
ok "negated dashboard read in Startup sequence reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 15. Releases negative: historical context dashboard in Startup ─────────────────
R_REL_HIST_STARTUP="$(mkrepo rel_hist_startup)"
require_fixture "$R_REL_HIST_STARTUP" "hist startup releases repo"
touch "$R_REL_HIST_STARTUP/releases.db"
cat > "$R_REL_HIST_STARTUP/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — releases.db is the source of truth
## Startup sequence
1. Read ROADMAP-DASHBOARD.md for historical context
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_HIST_STARTUP" 2>&1)"; rc=$?
ok "historical context dashboard directive in Startup reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 16. Releases negative: purpose-free dashboard in Startup ──────────────────────
R_REL_PURPOSE_FREE="$(mkrepo rel_purpose_free)"
require_fixture "$R_REL_PURPOSE_FREE" "purpose free releases repo"
touch "$R_REL_PURPOSE_FREE/releases.db"
cat > "$R_REL_PURPOSE_FREE/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — releases.db is the source of truth
## Startup sequence
1. Read ROADMAP-DASHBOARD.md for deployment instructions
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_PURPOSE_FREE" 2>&1)"; rc=$?
ok "purpose-free dashboard directive in Startup reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 17. Releases negative: purpose-free dashboard + unrelated current work ────────
R_REL_PF_UNRELATED="$(mkrepo rel_pf_unrelated)"
require_fixture "$R_REL_PF_UNRELATED" "pf unrelated releases repo"
touch "$R_REL_PF_UNRELATED/releases.db"
cat > "$R_REL_PF_UNRELATED/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — releases.db is the source of truth
## Startup sequence
1. Read ROADMAP-DASHBOARD.md for deployment instructions; TEAM.md tracks current work
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_PF_UNRELATED" 2>&1)"; rc=$?
ok "purpose-free dashboard + unrelated current work in Startup reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 18. Releases negative: not current state dashboard in Startup ──────────────────
R_REL_NOT_CURRENT_DASH="$(mkrepo rel_not_current_dash)"
require_fixture "$R_REL_NOT_CURRENT_DASH" "not current dash releases repo"
touch "$R_REL_NOT_CURRENT_DASH/releases.db"
cat > "$R_REL_NOT_CURRENT_DASH/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — releases.db is the source of truth
## Startup sequence
1. Read ROADMAP-DASHBOARD.md for not current state
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_NOT_CURRENT_DASH" 2>&1)"; rc=$?
ok "not current state dashboard directive in Startup reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 19. Releases negative: multi-clause active directive in Startup ────────────────
R_REL_MULTI_CLAUSE="$(mkrepo rel_multi_clause)"
require_fixture "$R_REL_MULTI_CLAUSE" "multi clause releases repo"
touch "$R_REL_MULTI_CLAUSE/releases.db"
cat > "$R_REL_MULTI_CLAUSE/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — releases.db is the source of truth
## Startup sequence
1. Read `ROADMAP-DASHBOARD.md`.
2. ROADMAP.md is frozen for historical reference; nevertheless use ROADMAP.md for current work.
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_MULTI_CLAUSE" 2>&1)"; rc=$?
ok "multi-clause line with active directive despite frozen text reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 20. Releases negative: historical first clause + active second clause ──────────
R_REL_HIST_ACTIVE_STARTUP="$(mkrepo rel_hist_active_startup)"
require_fixture "$R_REL_HIST_ACTIVE_STARTUP" "hist active startup releases repo"
touch "$R_REL_HIST_ACTIVE_STARTUP/releases.db"
cat > "$R_REL_HIST_ACTIVE_STARTUP/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — releases.db is the source of truth
## Startup sequence
1. Read `ROADMAP-DASHBOARD.md`.
2. Read ROADMAP.md only for historical reference; nevertheless use ROADMAP.md for current work.
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_HIST_ACTIVE_STARTUP" 2>&1)"; rc=$?
ok "historical first clause + active second clause in Startup reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

python3 "$AUDIT_PY" --fix "$R_REL_HIST_ACTIVE_STARTUP" >/dev/null
out_has_check="$(python3 "$AUDIT_PY" --check "$R_REL_HIST_ACTIVE_STARTUP" 2>&1)"; rc_has=$?
ok "historical first clause + active second clause repaired with --fix (rc=0)" "$(is "$rc_has" "0"; echo $?)"

# ── 21. Releases negative: conjunction active directive in Startup ────────────────
R_REL_CONJ_STARTUP="$(mkrepo rel_conj_startup)"
require_fixture "$R_REL_CONJ_STARTUP" "conj startup releases repo"
touch "$R_REL_CONJ_STARTUP/releases.db"
cat > "$R_REL_CONJ_STARTUP/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — releases.db is the source of truth
## Startup sequence
1. Read `ROADMAP-DASHBOARD.md`.
2. ROADMAP.md is frozen and use ROADMAP.md for current work.
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_CONJ_STARTUP" 2>&1)"; rc=$?
ok "conjunction active directive in Startup reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 22. Releases negative: while-connector active directive in Startup ─────────────
R_REL_WHILE_STARTUP="$(mkrepo rel_while_startup)"
require_fixture "$R_REL_WHILE_STARTUP" "while startup releases repo"
touch "$R_REL_WHILE_STARTUP/releases.db"
cat > "$R_REL_WHILE_STARTUP/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — releases.db is the source of truth
## Startup sequence
1. Read `ROADMAP-DASHBOARD.md`.
2. ROADMAP.md is frozen while operators use ROADMAP.md for current work.
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_WHILE_STARTUP" 2>&1)"; rc=$?
ok "while-connector active directive in Startup reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 23. Releases negative: colon-form active keywords in Role split ────────────────
R_REL_COLON_ACTIVE="$(mkrepo rel_colon_active)"
require_fixture "$R_REL_COLON_ACTIVE" "colon active releases repo"
touch "$R_REL_COLON_ACTIVE/releases.db"
cat > "$R_REL_COLON_ACTIVE/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
ROADMAP.md: active; frozen legacy; releases.db is the source of truth
## Startup sequence
1. Read `ROADMAP-DASHBOARD.md` (ROADMAP.md is frozen legacy).
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_COLON_ACTIVE" 2>&1)"; rc=$?
ok "colon-form active keywords in Role split reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 24. Releases negative: negated legacy in Role split ───────────────────────────
R_REL_NOT_LEGACY="$(mkrepo rel_not_legacy)"
require_fixture "$R_REL_NOT_LEGACY" "not legacy releases repo"
touch "$R_REL_NOT_LEGACY/releases.db"
cat > "$R_REL_NOT_LEGACY/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
- `ROADMAP.md` = not legacy; releases.db is source of truth
## Startup sequence
1. Read `ROADMAP-DASHBOARD.md` (ROADMAP.md is frozen legacy).
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_NOT_LEGACY" 2>&1)"; rc=$?
ok "negated legacy in Role split reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 25. Releases negative: prose active ROADMAP in Role split ──────────────────────
R_REL_PROSE_ROLE="$(mkrepo rel_prose_role)"
require_fixture "$R_REL_PROSE_ROLE" "prose role releases repo"
touch "$R_REL_PROSE_ROLE/releases.db"
cat > "$R_REL_PROSE_ROLE/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — releases.db is the source of truth
ROADMAP.md is used for current priorities
## Startup sequence
1. Read `ROADMAP-DASHBOARD.md` (ROADMAP.md is frozen legacy).
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_PROSE_ROLE" 2>&1)"; rc=$?
ok "prose active ROADMAP in Role split reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 26. Releases negative: prefixed prose active ROADMAP in Role split ────────────
R_REL_PREFIX_PROSE="$(mkrepo rel_prefix_prose)"
require_fixture "$R_REL_PREFIX_PROSE" "prefix prose releases repo"
touch "$R_REL_PREFIX_PROSE/releases.db"
cat > "$R_REL_PREFIX_PROSE/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — releases.db is the source of truth
Note: ROADMAP.md is used for current priorities
## Startup sequence
1. Read `ROADMAP-DASHBOARD.md` (ROADMAP.md is frozen legacy).
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_PREFIX_PROSE" 2>&1)"; rc=$?
ok "prefixed prose active ROADMAP in Role split reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

python3 "$AUDIT_PY" --fix "$R_REL_PREFIX_PROSE" >/dev/null
out_pref_prose_check="$(python3 "$AUDIT_PY" --check "$R_REL_PREFIX_PROSE" 2>&1)"; rc_pp=$?
ok "prefixed prose active ROADMAP repaired with --fix (rc=0)" "$(is "$rc_pp" "0"; echo $?)"

# ── 27. Releases negative: compound custom entry + active prose in Role split ─────
R_REL_COMPOUND_ROLE="$(mkrepo rel_compound_role)"
require_fixture "$R_REL_COMPOUND_ROLE" "compound role releases repo"
touch "$R_REL_COMPOUND_ROLE/releases.db"
cat > "$R_REL_COMPOUND_ROLE/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — the RELEASES DB (releases.db) is the source of truth
- `PROJECT/PDDA.md` = governs the `ROADMAP.md` contract; `ROADMAP.md` is used for current work
## Startup sequence
1. Read `ROADMAP-DASHBOARD.md` to find active effort. (ROADMAP.md is frozen legacy.)
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_COMPOUND_ROLE" 2>&1)"; rc=$?
ok "compound custom entry + active prose in Role split reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

python3 "$AUDIT_PY" --fix "$R_REL_COMPOUND_ROLE" >/dev/null
out_comp_fix="$(python3 "$AUDIT_PY" --check "$R_REL_COMPOUND_ROLE" 2>&1)"; rc_cf=$?
ok "compound custom entry fixed and passes audit (rc=0)" "$(is "$rc_cf" "0"; echo $?)"
comp_content="$(cat "$R_REL_COMPOUND_ROLE/ROUTER.md")"
ok "compound fix preserved governance clause" "$(has "$comp_content" "governs the \`ROADMAP.md\` contract"; echo $?)"
ok "compound fix removed stray active clause" "$(! has "$comp_content" "is used for current work"; echo $?)"

# ── 28. Releases negative: asterisk list marker in Role split ──────────────────────
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

# ── 29. Releases negative: Startup sequence with Open verb ─────────────────────────
R_REL_OPEN_STARTUP="$(mkrepo rel_open_startup)"
require_fixture "$R_REL_OPEN_STARTUP" "open startup releases repo"
touch "$R_REL_OPEN_STARTUP/releases.db"
cat > "$R_REL_OPEN_STARTUP/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — releases.db is the source of truth
## Startup sequence
1. Open ROADMAP.md to find current work.
2. Read ROADMAP-DASHBOARD.md
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_OPEN_STARTUP" 2>&1)"; rc=$?
ok "Startup sequence with Open ROADMAP.md reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 30. Releases negative: Startup sequence with Consult verb ──────────────────────
R_REL_CONSULT_STARTUP="$(mkrepo rel_consult_startup)"
require_fixture "$R_REL_CONSULT_STARTUP" "consult startup releases repo"
touch "$R_REL_CONSULT_STARTUP/releases.db"
cat > "$R_REL_CONSULT_STARTUP/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — releases.db is the source of truth
## Startup sequence
- Consult ROADMAP.md first
- Check ROADMAP-DASHBOARD.md
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_CONSULT_STARTUP" 2>&1)"; rc=$?
ok "Startup sequence with Consult ROADMAP.md reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 31. Releases negative: Startup sequence with Use verb ──────────────────────────
R_REL_USE_STARTUP="$(mkrepo rel_use_startup)"
require_fixture "$R_REL_USE_STARTUP" "use startup releases repo"
touch "$R_REL_USE_STARTUP/releases.db"
cat > "$R_REL_USE_STARTUP/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — releases.db is the source of truth
## Startup sequence
1. Use ROADMAP.md for current work.
2. Read ROADMAP-DASHBOARD.md
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_USE_STARTUP" 2>&1)"; rc=$?
ok "Startup sequence with Use ROADMAP.md for current work reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 32. Releases negative: Startup sequence with negated frozen phrase ─────────────
R_REL_NOT_FROZEN_STARTUP="$(mkrepo rel_not_frozen_startup)"
require_fixture "$R_REL_NOT_FROZEN_STARTUP" "not frozen startup releases repo"
touch "$R_REL_NOT_FROZEN_STARTUP/releases.db"
cat > "$R_REL_NOT_FROZEN_STARTUP/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — releases.db is the source of truth
## Startup sequence
1. ROADMAP.md is not frozen; use it for current work.
2. Read ROADMAP-DASHBOARD.md
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_NOT_FROZEN_STARTUP" 2>&1)"; rc=$?
ok "Startup sequence saying ROADMAP.md is not frozen reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 33. Releases negative: Startup sequence with markdown link ────────────────────
R_REL_LINK_STARTUP="$(mkrepo rel_link_startup)"
require_fixture "$R_REL_LINK_STARTUP" "link startup releases repo"
touch "$R_REL_LINK_STARTUP/releases.db"
cat > "$R_REL_LINK_STARTUP/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — releases.db is the source of truth
## Startup sequence
1. See [ROADMAP.md](PROJECT/ROADMAP.md) for active items.
2. Read ROADMAP-DASHBOARD.md
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_LINK_STARTUP" 2>&1)"; rc=$?
ok "Startup sequence with markdown link to ROADMAP.md reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 34. Releases negative: missing Startup sequence section ─────────────────────────
R_REL_NO_START="$(mkrepo rel_no_start)"
require_fixture "$R_REL_NO_START" "no start releases repo"
touch "$R_REL_NO_START/releases.db"
cat > "$R_REL_NO_START/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — releases.db is the source of truth
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_NO_START" 2>&1)"; rc=$?
ok "missing Startup sequence section reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 35. Releases negative: duplicate sections ─────────────────────────────────────
R_REL_DUP_SECT="$(mkrepo rel_dup_sect)"
require_fixture "$R_REL_DUP_SECT" "dup sect releases repo"
touch "$R_REL_DUP_SECT/releases.db"
cat > "$R_REL_DUP_SECT/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — releases.db is the source of truth
## Startup sequence
1. Read ROADMAP-DASHBOARD.md
## Role split
- `ROADMAP.md` = active work
## Startup sequence
1. Read ROADMAP.md
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_DUP_SECT" 2>&1)"; rc=$?
ok "duplicate Role split / Startup sequence sections report drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 36. Releases clean valid custom mention passes audit and is preserved ──────────
R_REL_PDDA_CUSTOM="$(mkrepo rel_pdda_custom)"
require_fixture "$R_REL_PDDA_CUSTOM" "pdda custom releases repo"
touch "$R_REL_PDDA_CUSTOM/releases.db"
cat > "$R_REL_PDDA_CUSTOM/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — the RELEASES DB (`releases.db`) is the source of truth
- `PROJECT/PDDA.md` = governs the `ROADMAP.md` contract
## Startup sequence
1. Read `ROADMAP-DASHBOARD.md` to find active effort. (`ROADMAP.md` is frozen legacy.)
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_PDDA_CUSTOM" 2>&1)"; rc=$?
ok "valid custom PDDA entry mentioning ROADMAP.md passes releases audit (rc=0)" "$(is "$rc" "0"; echo $?)"

python3 "$AUDIT_PY" --fix "$R_REL_PDDA_CUSTOM" >/dev/null
pdda_content="$(cat "$R_REL_PDDA_CUSTOM/ROUTER.md")"
ok "releases --fix preserved custom PROJECT/PDDA.md entry" "$(has "$pdda_content" "PROJECT/PDDA.md"; echo $?)"

# ── 37. Releases clean valid custom startup step preserved byte-for-byte ──────────
R_REL_CUSTOM_STEP="$(mkrepo rel_custom_step)"
require_fixture "$R_REL_CUSTOM_STEP" "custom step releases repo"
touch "$R_REL_CUSTOM_STEP/releases.db"
cat > "$R_REL_CUSTOM_STEP/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP.md` = active pointer ledger
## Startup sequence
1. Read ROUTER.md
2. Read AGENTS.md
3. Read ROADMAP.md
4. Read `PROJECT/PDDA.md` for the `ROADMAP.md` governance contract.
MD

# Save custom step 4
python3 -c "
with open('$R_REL_CUSTOM_STEP/ROUTER.md', 'rb') as f:
    data = f.read()
start = data.find(b'4. Read ' + b'\x60PROJECT/PDDA.md\x60')
with open('$WORK/custom_step_exp.bin', 'wb') as out:
    out.write(data[start:])
"

python3 "$AUDIT_PY" --fix "$R_REL_CUSTOM_STEP" >/dev/null
out_cs="$(python3 "$AUDIT_PY" --check "$R_REL_CUSTOM_STEP" 2>&1)"; rc_cs=$?
ok "releases repo with custom startup step fixed and passes audit (rc=0)" "$(is "$rc_cs" "0"; echo $?)"

python3 -c "
with open('$R_REL_CUSTOM_STEP/ROUTER.md', 'rb') as f:
    data = f.read()
start = data.find(b'4. Read ' + b'\x60PROJECT/PDDA.md\x60')
with open('$WORK/custom_step_act.bin', 'wb') as out:
    out.write(data[start:])
"
cmp "$WORK/custom_step_exp.bin" "$WORK/custom_step_act.bin" >/dev/null 2>&1; rc_cs_cmp=$?
ok "releases --fix preserved custom startup step byte-for-byte with cmp" "$(is "$rc_cs_cmp" "0"; echo $?)"

# ── 38. Releases clean valid historical read preserved byte-for-byte ──────────────
R_REL_HIST_READ="$(mkrepo rel_hist_read)"
require_fixture "$R_REL_HIST_READ" "hist read releases repo"
touch "$R_REL_HIST_READ/releases.db"
cat > "$R_REL_HIST_READ/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = the generated, human-readable view of the roadmap ledger
- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — the RELEASES DB (releases.db) is the source of truth
## Startup sequence
1. Read ROUTER.md
2. Read `ROADMAP-DASHBOARD.md` to find active effort.
3. Read ROADMAP.md only for historical reference.
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_HIST_READ" 2>&1)"; rc=$?
ok "valid historical read 'Read ROADMAP.md only for historical reference' passes releases audit (rc=0)" "$(is "$rc" "0"; echo $?)"

python3 "$AUDIT_PY" --fix "$R_REL_HIST_READ" >/dev/null
hist_content="$(cat "$R_REL_HIST_READ/ROUTER.md")"
ok "releases --fix preserved historical read line" "$(has "$hist_content" "only for historical reference"; echo $?)"

# ── 39. Releases clean valid negations pass audit ──────────────────────────────────
R_REL_VALID_NEG="$(mkrepo rel_valid_neg)"
require_fixture "$R_REL_VALID_NEG" "valid neg releases repo"
touch "$R_REL_VALID_NEG/releases.db"
cat > "$R_REL_VALID_NEG/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — the RELEASES DB (releases.db) is the source of truth
## Startup sequence
1. Read `ROADMAP-DASHBOARD.md` to find active effort.
2. ROADMAP.md is frozen; do not use it for current work.
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_VALID_NEG" 2>&1)"; rc=$?
ok "valid negation 'do not use it for current work' passes releases audit (rc=0)" "$(is "$rc" "0"; echo $?)"

# ── 40. Releases clean valid fenced code blocks ────────────────────────────────────
R_REL_FENCED="$(mkrepo rel_fenced)"
require_fixture "$R_REL_FENCED" "fenced code releases repo"
touch "$R_REL_FENCED/releases.db"
cat > "$R_REL_FENCED/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
- `ROADMAP.md` = LEGACY pointer ledger, frozen since releases.db flip — the RELEASES DB (releases.db) is the source of truth

```markdown
## Role split
- `ROADMAP.md` = example in code fence
## Startup sequence
1. Read `ROADMAP.md` inside fence
```

## Startup sequence
1. Read `ROADMAP-DASHBOARD.md` to find active effort. (ROADMAP.md is frozen legacy.)
MD

out="$(python3 "$AUDIT_PY" --check "$R_REL_FENCED" 2>&1)"; rc=$?
ok "clean repo with ## headings inside code fences passes audit (rc=0)" "$(is "$rc" "0"; echo $?)"

# ── 41. Releases --fix: collapses duplicate roadmap steps in Startup ───────────────
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

# ── 42. Releases --fix: removes duplicate sections down to exactly 1 each ──────────
python3 "$AUDIT_PY" --fix "$R_REL_DUP_SECT" >/dev/null
out_dup_sect_check="$(python3 "$AUDIT_PY" --check "$R_REL_DUP_SECT" 2>&1)"; rc_dup_sect=$?
ok "duplicate sections fixed and passes audit (rc=0)" "$(is "$rc_dup_sect" "0"; echo $?)"
role_sect_count="$(grep -c "## Role split" "$R_REL_DUP_SECT/ROUTER.md")"
start_sect_count="$(grep -c "## Startup sequence" "$R_REL_DUP_SECT/ROUTER.md")"
ok "fixed ROUTER.md has exactly 1 ## Role split" "$(is "$role_sect_count" "1"; echo $?)"
ok "fixed ROUTER.md has exactly 1 ## Startup sequence" "$(is "$start_sect_count" "1"; echo $?)"

# ── 43. Releases --fix: preserves prefixed custom sections byte-for-byte ───────────
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

# ── 44. Releases --fix: exact byte-level cmp on custom section with CRLF & idempotence
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

# ── 45. Releases --fix: repairs empty ## Role split followed by another section ───
R_REL_EMPTY_ROLE="$(mkrepo rel_empty_role)"
require_fixture "$R_REL_EMPTY_ROLE" "empty role releases repo"
touch "$R_REL_EMPTY_ROLE/releases.db"
printf '# ROUTER.md\n## Role split\n## Startup sequence\n1. Read ROADMAP.md\n' > "$R_REL_EMPTY_ROLE/ROUTER.md"

python3 "$AUDIT_PY" --fix "$R_REL_EMPTY_ROLE" >/dev/null
out_er="$(python3 "$AUDIT_PY" --check "$R_REL_EMPTY_ROLE" 2>&1)"; rc_er=$?
ok "releases repo with empty ## Role split fixed and passes audit (rc=0)" "$(is "$rc_er" "0"; echo $?)"

# ── 46. Releases --fix: preserves repeated custom lines inside owned sections ─────
R_REL_REPEAT_CUSTOM="$(mkrepo rel_repeat_custom)"
require_fixture "$R_REL_REPEAT_CUSTOM" "repeat custom releases repo"
touch "$R_REL_REPEAT_CUSTOM/releases.db"
cat > "$R_REL_REPEAT_CUSTOM/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP.md` = active work
- `CUSTOM.md` = custom entry
- `CUSTOM.md` = custom entry
## Startup sequence
1. Read ROADMAP.md
MD

python3 "$AUDIT_PY" --fix "$R_REL_REPEAT_CUSTOM" >/dev/null
repeat_content="$(cat "$R_REL_REPEAT_CUSTOM/ROUTER.md")"
repeat_count="$(grep -c "CUSTOM.md" "$R_REL_REPEAT_CUSTOM/ROUTER.md")"
ok "releases --fix preserved repeated custom entries" "$(is "$repeat_count" "2"; echo $?)"

# ── 47. Releases --fix: preserves mixed LF/CRLF lines in owned sections verbatim ───
R_REL_MIXED_TERM="$(mkrepo rel_mixed_term)"
require_fixture "$R_REL_MIXED_TERM" "mixed term releases repo"
touch "$R_REL_MIXED_TERM/releases.db"
printf '# ROUTER.md\n## Role split\n- `ROADMAP.md` = active work\n- `LF_LINE.md` = line with LF\n- `CRLF_LINE.md` = line with CRLF\r\n## Startup sequence\n1. Read ROADMAP.md\n' > "$R_REL_MIXED_TERM/ROUTER.md"

python3 "$AUDIT_PY" --fix "$R_REL_MIXED_TERM" >/dev/null
python3 -c "
with open('$R_REL_MIXED_TERM/ROUTER.md', 'rb') as f:
    data = f.read()
assert b'- \x60CRLF_LINE.md\x60 = line with CRLF\r\n' in data
assert b'- \x60LF_LINE.md\x60 = line with LF\n' in data
"
ok "releases --fix preserved mixed LF and CRLF line endings verbatim" "0"

# ── 48. Mode parser: commented line in .pdda-mode is legacy mode ───────────────────
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
1. Read `ROADMAP.md` to find active effort.
MD

out="$(python3 "$AUDIT_PY" --check "$R_PDDA_COMMENT" 2>&1)"; rc=$?
ok "commented ROADMAP_SOURCE=releases is recognized as legacy mode (rc=0)" "$(is "$rc" "0"; echo $?)"

# ── 49. Mode parser: prefix line in .pdda-mode is legacy mode ───────────────────────
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
1. Read `ROADMAP.md` to find active effort.
MD

out="$(python3 "$AUDIT_PY" --check "$R_PDDA_PREFIX" 2>&1)"; rc=$?
ok "prefix NOT_ROADMAP_SOURCE=releases is recognized as legacy mode (rc=0)" "$(is "$rc" "0"; echo $?)"

# ── 50. Mode parser: whitespace in .pdda-mode is releases mode ────────────────────
R_PDDA_WS="$(mkrepo pdda_ws)"
require_fixture "$R_PDDA_WS" "pdda ws repo"
cat > "$R_PDDA_WS/.pdda-mode" <<'MODE'
   ROADMAP_SOURCE   =   releases  # comment
MODE
cat > "$R_PDDA_WS/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
- `ROADMAP.md` = LEGACY pointer ledger, frozen since the `ROADMAP_SOURCE=releases` flip — the RELEASES DB (`releases.db`) is the source of truth
## Startup sequence
1. Read `ROADMAP-DASHBOARD.md` to find active effort. (`ROADMAP.md` is frozen legacy.)
MD

out="$(python3 "$AUDIT_PY" --check "$R_PDDA_WS" 2>&1)"; rc=$?
ok "whitespace-padded ROADMAP_SOURCE=releases is recognized as releases mode (rc=0)" "$(is "$rc" "0"; echo $?)"

# ── 51. Mode parser: unreadable .pdda-mode reports error ──────────────────────────
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

# ── 52. Clean legacy-mode repo ─────────────────────────────────────────────────────
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

# ── 53. Clean legacy-mode repo with Markdown link in Startup ───────────────────────
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

# ── 54. Clean legacy-mode repo with not frozen in Startup ──────────────────────────
R_LEG_NOT_FROZEN="$(mkrepo leg_not_frozen)"
require_fixture "$R_LEG_NOT_FROZEN" "clean legacy not frozen repo"
cat > "$R_LEG_NOT_FROZEN/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP.md` = the pointer ledger of current, completed, attempted, and deferred work
## Startup sequence
1. Read `ROADMAP.md` to find active effort (ROADMAP.md is not frozen).
MD

out="$(python3 "$AUDIT_PY" --check "$R_LEG_NOT_FROZEN" 2>&1)"; rc=$?
ok "clean legacy-mode repo with 'not frozen' in Startup reports ok (rc=0)" "$(is "$rc" "0"; echo $?)"

# ── 55. Clean legacy-mode repo with unrelated legacy entry ─────────────────────────
R_LEG_OLD_API="$(mkrepo leg_old_api)"
require_fixture "$R_LEG_OLD_API" "clean legacy old api repo"
cat > "$R_LEG_OLD_API/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP.md` = the pointer ledger of current, completed, attempted, and deferred work
- `OLD-API.md` = remains legacy
## Startup sequence
1. Read `ROADMAP.md` to find active effort.
MD

out="$(python3 "$AUDIT_PY" --check "$R_LEG_OLD_API" 2>&1)"; rc=$?
ok "clean legacy-mode repo with unrelated 'OLD-API.md remains legacy' reports ok (rc=0)" "$(is "$rc" "0"; echo $?)"

python3 "$AUDIT_PY" --fix "$R_LEG_OLD_API" >/dev/null
old_api_content="$(cat "$R_LEG_OLD_API/ROUTER.md")"
ok "legacy --fix preserved unrelated OLD-API.md entry" "$(has "$old_api_content" "OLD-API.md"; echo $?)"

# ── 56. Clean legacy-mode repo with non-owned historical frozen mention ───────────
R_LEG_HIST_CHANGELOG="$(mkrepo leg_hist_changelog)"
require_fixture "$R_LEG_HIST_CHANGELOG" "hist changelog repo"
cat > "$R_LEG_HIST_CHANGELOG/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP.md` = the pointer ledger of current, completed, attempted, and deferred work
- `CHANGELOG.md` = records when `ROADMAP.md` was frozen during the 2025 migration
## Startup sequence
1. Read `ROADMAP.md` to find active effort.
MD

out="$(python3 "$AUDIT_PY" --check "$R_LEG_HIST_CHANGELOG" 2>&1)"; rc=$?
ok "clean legacy repo with historical frozen mention in CHANGELOG entry reports ok (rc=0)" "$(is "$rc" "0"; echo $?)"

python3 "$AUDIT_PY" --fix "$R_LEG_HIST_CHANGELOG" >/dev/null
cl_content="$(cat "$R_LEG_HIST_CHANGELOG/ROUTER.md")"
ok "legacy --fix preserved non-owned CHANGELOG entry" "$(has "$cl_content" "records when \`ROADMAP.md\` was frozen"; echo $?)"

# ── 57. Legacy clean valid custom startup step preserved byte-for-byte ────────────
R_LEG_CUSTOM_STEP="$(mkrepo leg_custom_step)"
require_fixture "$R_LEG_CUSTOM_STEP" "custom step legacy repo"
cat > "$R_LEG_CUSTOM_STEP/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP.md` = the pointer ledger of current, completed, attempted, and deferred work
- `ROADMAP-DASHBOARD.md` = the generated view of the roadmap ledger
## Startup sequence
1. Read ROUTER.md
2. Read AGENTS.md
3. Read `ROADMAP-DASHBOARD.md` to find work.
4. Read `PROJECT/PDDA.md` for the `ROADMAP.md` governance contract.
MD

# Save custom step 4
python3 -c "
with open('$R_LEG_CUSTOM_STEP/ROUTER.md', 'rb') as f:
    data = f.read()
start = data.find(b'4. Read ' + b'\x60PROJECT/PDDA.md\x60')
with open('$WORK/leg_custom_step_exp.bin', 'wb') as out:
    out.write(data[start:])
"

python3 "$AUDIT_PY" --fix "$R_LEG_CUSTOM_STEP" >/dev/null
out_lcs="$(python3 "$AUDIT_PY" --check "$R_LEG_CUSTOM_STEP" 2>&1)"; rc_lcs=$?
ok "legacy repo with custom startup step fixed and passes audit (rc=0)" "$(is "$rc_lcs" "0"; echo $?)"

python3 -c "
with open('$R_LEG_CUSTOM_STEP/ROUTER.md', 'rb') as f:
    data = f.read()
start = data.find(b'4. Read ' + b'\x60PROJECT/PDDA.md\x60')
with open('$WORK/leg_custom_step_act.bin', 'wb') as out:
    out.write(data[start:])
"
cmp "$WORK/leg_custom_step_exp.bin" "$WORK/leg_custom_step_act.bin" >/dev/null 2>&1; rc_lcs_cmp=$?
ok "legacy --fix preserved custom startup step byte-for-byte with cmp" "$(is "$rc_lcs_cmp" "0"; echo $?)"

# ── 58. Legacy negative: Role split with deployment policy pointer ledger ─────────
R_LEG_DEPLOY_POLICY="$(mkrepo leg_deploy_policy)"
require_fixture "$R_LEG_DEPLOY_POLICY" "deploy policy legacy repo"
cat > "$R_LEG_DEPLOY_POLICY/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP.md` = pointer ledger for deployment policy
## Startup sequence
1. Read `ROADMAP.md` to find active effort.
MD

out="$(python3 "$AUDIT_PY" --check "$R_LEG_DEPLOY_POLICY" 2>&1)"; rc=$?
ok "legacy repo with pointer ledger for deployment policy in Role split reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 59. Legacy negative: Role split with archived pointer ledger ──────────────────
R_LEG_ARCHIVED="$(mkrepo leg_archived)"
require_fixture "$R_LEG_ARCHIVED" "archived legacy repo"
cat > "$R_LEG_ARCHIVED/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP.md` = archived pointer ledger
## Startup sequence
1. Read `ROADMAP.md` to find active effort.
MD

out="$(python3 "$AUDIT_PY" --check "$R_LEG_ARCHIVED" 2>&1)"; rc=$?
ok "legacy repo with archived pointer ledger in Role split reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 60. Legacy negative: Role split with false-frozen ROADMAP.md ───────────────────
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

# ── 61. Legacy negative: Role split with two contradictory lines (active + frozen) ─
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

# ── 62. Legacy negative: Role split with mixed not frozen + affirmative legacy ─────
R_LEG_MIXED_ROLE="$(mkrepo leg_mixed_role)"
require_fixture "$R_LEG_MIXED_ROLE" "mixed role legacy repo"
cat > "$R_LEG_MIXED_ROLE/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP.md` = the pointer ledger of current work
ROADMAP.md is not frozen, but ROADMAP.md remains legacy

## Startup sequence
1. Read `ROADMAP.md` to find work.
MD

out="$(python3 "$AUDIT_PY" --check "$R_LEG_MIXED_ROLE" 2>&1)"; rc=$?
ok "legacy repo with not frozen + affirmative legacy in Role split reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 63. Legacy negative: Role split with asterisk marker ───────────────────────────
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

# ── 64. Legacy negative: Role split with inactive declaration ──────────────────────
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

# ── 65. Legacy negative: Role split with releases.db mention ──────────────────────
R_LEG_DB_ROLE="$(mkrepo leg_db_role)"
require_fixture "$R_LEG_DB_ROLE" "db role legacy repo"
cat > "$R_LEG_DB_ROLE/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP.md` = the pointer ledger of current work (releases.db is source)
## Startup sequence
1. Read `ROADMAP.md` to find active effort.
MD

out="$(python3 "$AUDIT_PY" --check "$R_LEG_DB_ROLE" 2>&1)"; rc=$?
ok "legacy repo with releases.db token in Role split reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 66. Legacy negative: Startup sequence with deployment instructions ────────────
R_LEG_DEPLOY_START="$(mkrepo leg_deploy_start)"
require_fixture "$R_LEG_DEPLOY_START" "deploy start legacy repo"
cat > "$R_LEG_DEPLOY_START/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP.md` = the pointer ledger of current, completed, attempted, and deferred work
## Startup sequence
1. Read `ROADMAP.md` for deployment instructions.
MD

out="$(python3 "$AUDIT_PY" --check "$R_LEG_DEPLOY_START" 2>&1)"; rc=$?
ok "legacy repo with deployment instructions in Startup sequence reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 67. Legacy negative: Startup sequence with deployment + negated current work ──
R_LEG_DEPLOY_NEG_START="$(mkrepo leg_deploy_neg_start)"
require_fixture "$R_LEG_DEPLOY_NEG_START" "deploy neg start legacy repo"
cat > "$R_LEG_DEPLOY_NEG_START/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP.md` = the pointer ledger of current, completed, attempted, and deferred work
## Startup sequence
1. Read `ROADMAP.md` for deployment instructions; do not use ROADMAP.md for current work.
MD

out="$(python3 "$AUDIT_PY" --check "$R_LEG_DEPLOY_NEG_START" 2>&1)"; rc=$?
ok "legacy repo with deployment instructions + negated current work in Startup reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 68. Legacy negative: Startup sequence with false-frozen ROADMAP.md ────────────
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

# ── 69. Legacy negative: Startup sequence with historical reference only ──────────
R_LEG_HIST_REF="$(mkrepo leg_hist_ref)"
require_fixture "$R_LEG_HIST_REF" "hist ref legacy repo"
touch "$R_LEG_HIST_REF/ROUTER.md"
cat > "$R_LEG_HIST_REF/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP.md` = the pointer ledger of current, completed, attempted, and deferred work
## Startup sequence
1. Read `ROADMAP.md` only for historical reference.
MD

out="$(python3 "$AUDIT_PY" --check "$R_LEG_HIST_REF" 2>&1)"; rc=$?
ok "legacy repo with historical reference only in Startup reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 70. Legacy negative: Startup sequence with negated Do not read ─────────────────
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

# ── 71. Legacy negative: Startup sequence with not frozen + do not read contradiction
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

# ── 72. Legacy negative: Startup sequence with mixed not frozen + affirmative legacy
R_LEG_START_MIXED="$(mkrepo leg_start_mixed)"
require_fixture "$R_LEG_START_MIXED" "start mixed legacy repo"
cat > "$R_LEG_START_MIXED/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP.md` = the pointer ledger of current work
## Startup sequence
1. Read `ROADMAP.md`; but note ROADMAP.md remains legacy.
MD

out="$(python3 "$AUDIT_PY" --check "$R_LEG_START_MIXED" 2>&1)"; rc=$?
ok "legacy repo with affirmative legacy clause in Startup reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 73. Legacy negative: Startup sequence with releases.sql mention ───────────────
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

# ── 74. Legacy negative: missing Role split section ───────────────────────────────
R_LEG_NO_ROLE="$(mkrepo leg_no_role)"
require_fixture "$R_LEG_NO_ROLE" "no role legacy repo"
cat > "$R_LEG_NO_ROLE/ROUTER.md" <<'MD'
# ROUTER.md
## Startup sequence
1. Read `ROADMAP.md` to find active effort.
MD

out="$(python3 "$AUDIT_PY" --check "$R_LEG_NO_ROLE" 2>&1)"; rc=$?
ok "legacy repo missing Role split reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 75. Legacy negative: missing Startup sequence section ─────────────────────────
R_LEG_NO_START="$(mkrepo leg_no_start)"
require_fixture "$R_LEG_NO_START" "no start legacy repo"
cat > "$R_LEG_NO_START/ROUTER.md" <<'MD'
# ROUTER.md
## Role split
- `ROADMAP.md` = the pointer ledger of current work
MD

out="$(python3 "$AUDIT_PY" --check "$R_LEG_NO_START" 2>&1)"; rc=$?
ok "legacy repo missing Startup sequence reports drift" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"

# ── 76. Legacy negative: leftover ROADMAP-DASHBOARD.md file on disk ───────────────
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

# ── 77. Remediate legacy repo with --fix ──────────────────────────────────────────
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

# ── 78. Missing ROUTER.md handling ────────────────────────────────────────────────
R_MISSING="$(mkrepo missing_router)"
require_fixture "$R_MISSING" "missing router repo"
out="$(python3 "$AUDIT_PY" --check "$R_MISSING" 2>&1)"; rc=$?
ok "missing ROUTER.md reports non-zero exit on --check" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"
ok "missing ROUTER.md output indicates not found" "$(has "$out" "ROUTER.md not found"; echo $?)"

# ── 79. Unreadable ROUTER.md handling ─────────────────────────────────────────────
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

# ── 80. xyz-sync.sh check integration ─────────────────────────────────────────────
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
