#!/usr/bin/env bash
# gh525-unshipped-version-tokens.sh — GH-525: the `unshipped_version_tokens` setting.
#
# A repo whose RELEASES.md writes a literal placeholder for a release that has not shipped a
# version yet ("Release: TBD") could not import more than ONE such block: the importer stored the
# placeholder as a version string, so the second unshipped block collided on UNIQUE(repo_id,
# version). The schema already modelled "no version yet" as SQL NULL and permits any number of
# NULLs — the importer just never mapped a placeholder onto it.
#
# Downstream's only recourse was to FORK this file for two lines (AEGIS-Sleuth #187), which is how
# that fork drifted ~1700 lines behind and independently re-derived an INSERT_RE fix that already
# existed here. This setting is what makes the fork unnecessary.
#
# Negative controls asserted here (each is what fails if the guard is reverted):
#   - WITHOUT the setting, two "Release: TBD" blocks still collide — the default path is unchanged,
#     which is the whole safety claim for existing installs
#   - a real version string is NEVER nulled, even when a placeholder list is configured
#   - a genuinely EMPTY Release: value is still refused, and a trailing comma in the setting
#     cannot turn the empty string into a placeholder

# Sources _setup.sh so the GH-10 fixture-guard adoption happens centrally (gh1-adoption-guard
# requires it) and $WORK is a guarded sandbox root rather than a hand-rolled mktemp.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_setup.sh" gh525-unshipped-version-tokens
APP="$HERE/../utils/py/releases_app.py"

pass=0; fail=0
ok(){ if [ "$2" = "0" ]; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }
is(){ [ "$1" = "$2" ]; }
# capture-then-match, never a pipe into grep -q (gh139-pipe-grep-guard).
has(){ grep -q "$2" <<<"$1"; }

command -v python3 >/dev/null 2>&1 || { echo "python3 required" >&2; exit 1; }
command -v sqlite3 >/dev/null 2>&1 || { echo "sqlite3 required" >&2; exit 1; }

mkrepo(){ # <name> -> echoes the fixture repo path
  local r="$WORK/$1"
  case "$r" in "$WORK"/*) ;; *) echo "REFUSING: $r outside WORK" >&2; exit 2 ;; esac
  mkdir -p "$r"
  git -C "$r" init -q
  git -C "$r" config user.email t@t
  git -C "$r" config user.name t
  printf '%s\n' "$r"
}
R=""
RA(){ RELEASES_APP_LOCK_WAIT=1 python3 "$APP" --root "$R" "$@"; }
rout(){ RA "$@" >/dev/null 2>&1; }
rlog(){ RA "$@" 2>&1; }
sql(){ sqlite3 "$R/releases.db" "$1"; }

# Two unshipped blocks plus one real version — the shape that could not import before.
write_ledger(){ # <repo> <placeholder>
  cat > "$1/RELEASES.md" <<LEDGER
# Major Releases

Release: $2
Codename: "Alpha"
Status: draft
Description: first unshipped release.
Target Date: 2026-12-01

Release: $2
Codename: "Beta"
Status: draft
Description: second unshipped release.
Target Date: 2026-12-02

Release: 1.0.0
Codename: "Shipped"
Status: active
Description: a real version.
Target Date: 2026-01-01
LEDGER
}

# Through the CLI, never sqlite3 directly: a settings row is part of the business-state digest, so
# a hand write leaves the latest receipt disagreeing with the state and `check` fails with
# receipt-chain. Section F pins exactly that.
set_tokens(){ rout settings set unshipped_version_tokens "$1"; }

# ── A. the default path is unchanged (the safety claim for every existing install) ──────────────
echo "-- A: setting absent -> today's behaviour, byte for byte"

R="$(mkrepo default)"
rout init --slug alpha
write_ledger "$R" "TBD"
V="$(rlog import)"
RC=$?
if [ "$RC" != "0" ] || has "$V" "duplicate"; then
  ok "WITHOUT the setting, two placeholder blocks still collide (default path untouched)" 0
else
  ok "WITHOUT the setting, two placeholder blocks still collide" 1
fi

N="$(sql "SELECT COUNT(*) FROM settings WHERE key='unshipped_version_tokens'")"
ok "no setting row is created by init — absent means absent, not empty-string" "$(is "$N" "0"; echo $?)"

# ── B. configured placeholders map to SQL NULL ──────────────────────────────────────────────────
echo "-- B: setting present -> placeholders become NULL, real versions do not"

R="$(mkrepo configured)"
rout init --slug alpha
set_tokens "TBD"
write_ledger "$R" "TBD"
V="$(rlog import)"
ok "import succeeds with two placeholder blocks once the token is configured" "$?"

N="$(sql "SELECT COUNT(*) FROM releases WHERE version IS NULL")"
ok "both unshipped blocks stored as SQL NULL (many NULLs coexist under UNIQUE)" "$(is "$N" "2"; echo $?)"

N="$(sql "SELECT COUNT(*) FROM releases WHERE version='TBD'")"
ok "the literal placeholder is NEVER stored as a version string" "$(is "$N" "0"; echo $?)"

# The control that matters: a configured list must not swallow real versions.
N="$(sql "SELECT COUNT(*) FROM releases WHERE version='1.0.0'")"
ok "a real version is untouched while a placeholder list is configured" "$(is "$N" "1"; echo $?)"

V="$(rlog check)"
if has "$V" "check: clean"; then ok "the resulting ledger checks clean" 0; else ok "ledger checks clean" 1; fi

# ── C. the list accepts more than one placeholder ───────────────────────────────────────────────
echo "-- C: comma-separated list, whitespace-trimmed"

R="$(mkrepo listform)"
rout init --slug alpha
set_tokens "TBD, N/A ,-"
cat > "$R/RELEASES.md" <<'LEDGER'
# Major Releases

Release: TBD
Codename: "One"
Status: draft
Description: placeholder one.
Target Date: 2026-12-01

Release: N/A
Codename: "Two"
Status: draft
Description: placeholder two.
Target Date: 2026-12-02

Release: -
Codename: "Three"
Status: draft
Description: placeholder three.
Target Date: 2026-12-03
LEDGER
rout import
N="$(sql "SELECT COUNT(*) FROM releases WHERE version IS NULL")"
ok "all three list entries map to NULL, surrounding whitespace trimmed" "$(is "$N" "3"; echo $?)"

# ── D. an empty Release: value is still malformed ───────────────────────────────────────────────
echo "-- D: a trailing comma cannot make the empty string a placeholder"

R="$(mkrepo emptyvalue)"
rout init --slug alpha
set_tokens "TBD,"
cat > "$R/RELEASES.md" <<'LEDGER'
# Major Releases

Release:
Codename: "Blank"
Status: draft
Description: no version at all.
Target Date: 2026-12-01
LEDGER
V="$(rlog import)"
if has "$V" "rule=release-value"; then
  ok "an EMPTY Release: value is still refused as a malformed ledger" 0
else
  ok "empty Release: value still refused" 1
fi

# ── E. case sensitivity is deliberate ───────────────────────────────────────────────────────────
echo "-- E: tokens are literal, not normalised"

R="$(mkrepo casing)"
rout init --slug alpha
set_tokens "TBD"
cat > "$R/RELEASES.md" <<'LEDGER'
# Major Releases

Release: tbd
Codename: "Lower"
Status: draft
Description: lower-case placeholder, not configured.
Target Date: 2026-12-01
LEDGER
rout import
N="$(sql "SELECT COUNT(*) FROM releases WHERE version='tbd'")"
ok "a case variant is NOT treated as the configured token (literal match, by design)" "$(is "$N" "1"; echo $?)"


# ââ F. the setting must be writable WITHOUT breaking the ledger âââââââââââââââââââââ
echo "-- F: a configurable ledger needs a configuring verb"

# This is the control that makes the whole feature usable rather than theoretical. Without
# `settings set`, the only way to configure this is a direct sqlite3 INSERT, and a settings row is
# part of the business-state digest -- so the hand write is caught as a receipt-less mutation and
# the ledger stops checking clean. Both halves are asserted: the CLI path stays clean, the hand
# path does not.
R="$(mkrepo receipted)"
rout init --slug alpha
rout settings set unshipped_version_tokens "TBD"
V="$(rlog check)"
if has "$V" "check: clean"; then ok "a setting written through the CLI leaves check CLEAN (receipted)" 0; else ok "CLI-written setting checks clean" 1; fi

R="$(mkrepo handwritten)"
rout init --slug alpha
# One receipted write FIRST: the digest comparison is `latest receipt's after != current state`,
# so a ledger with no receipts at all has nothing to compare against and the hand write would slip
# by unflagged. Measured, not assumed — this assertion failed until the seed write was added.
rout add --version 0.1.0 --status draft --description "seed." --tracking-issue "https://github.com/A/B/issues/1"
sqlite3 "$R/releases.db" "INSERT OR REPLACE INTO settings(key, value) VALUES('unshipped_version_tokens', 'TBD')"
V="$(rlog check)"
if has "$V" "receipt-chain"; then
  ok "a HAND-written setting is caught as a receipt-less mutation (why the verb exists)" 0
else
  ok "hand-written setting caught by the digest chain" 1
fi

R="$(mkrepo guarded)"
rout init --slug alpha
V="$(rlog settings set generation 99)"
if has "$V" "setting-not-configurable"; then
  ok "a non-configurable key is refused (generation belongs to the writer protocol)" 0
else
  ok "non-configurable key refused" 1
fi
V="$(sql "SELECT value FROM settings WHERE key='generation'")"
ok "and the refusal changed nothing" "$(is "$V" "1"; echo $?)"

echo "  ${pass} passed, ${fail} failed"
[ "$fail" = "0" ] || exit 1
