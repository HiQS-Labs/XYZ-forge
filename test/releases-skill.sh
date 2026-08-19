#!/usr/bin/env bash
# Consolidated /releases skill: one repo source, one Claude Code symlink, no Codex install surface.
set -u
set -o pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILL="$ROOT/skills/releases/SKILL.md"
INSTALLER="$ROOT/skills/releases/install.sh"
PASS=0
FAIL=0

pass() { echo "  PASS: $*"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL + 1)); }
contains() {
  label="$1"
  file="$2"
  needle="$3"
  if grep -Fq -- "$needle" "$file"; then pass "$label"; else fail "$label"; fi
}

echo "== test: releases-skill =="

[ -f "$SKILL" ] && pass "plural skill exists" || fail "missing $SKILL"
[ ! -e "$ROOT/skills/release" ] && pass "singular repo folder is retired" \
  || fail "legacy skills/release still exists"
contains "frontmatter name is plural" "$SKILL" "name: releases"
contains "default route is read-only" "$SKILL" "Default to read-only synthesis."
contains "cleanup route is documented" "$SKILL" "/releases clean"
contains "planning route is documented" "$SKILL" "/releases plan"
contains "publication route is documented" "$SKILL" "/releases publish"
contains "Radar handoff is conditional" "$SKILL" 'Offer `/radar`'
contains "Finish Line handoff is conditional" "$SKILL" 'Offer `/finish-line`'
contains "closed-only PRs are rejected as shipment evidence" "$SKILL" "closed-but-unmerged PR"
contains "closed-unmerged PRs are still inspected" "$SKILL" "merged and closed-unmerged PRs"
contains "description warning caps at four sentences" "$SKILL" "exceeds four sentences"
contains "manifest count triggers review rather than rejection" "$SKILL" "more than seven issues"
contains "Codex mutation is forbidden" "$SKILL" "Never create, edit, install, or synchronize a Codex skill"

# ── GH-32 route migration: app-managed repos delegate every write to the releases CLI ────────────
contains "backend detection is a preflight step" "$SKILL" "releases.db"
contains "app-managed mutations name the CLI implementation" "$SKILL" "utils/py/releases_app.py"
contains "direct edits are refused in app-managed repos" "$SKILL" "never edit \`RELEASES.md\` directly there"
contains "clean route delegates via releases update" "$SKILL" "releases update --gid"
contains "plan route delegates via releases add" "$SKILL" "releases add"
contains "publish write-back delegates via releases ship" "$SKILL" "releases ship --gid"
contains "anchor route delegates as a command pair" "$SKILL" '`releases add ... ` + `releases ship ...`'
contains "legacy repos keep the direct-edit path" "$SKILL" "legacy-managed"
contains "app-managed preflight runs the consistency check" "$SKILL" "releases check"
# The delegation must preserve the confirm UX, not bypass it:
contains "command preview replaces the patch preview, confirmation unchanged" "$SKILL" "Preview the exact command set instead of a patch"
contains "router doc names the plural front door" "$ROOT/ROUTER.md" 'invoke `/releases`'
contains "PDDA contract names one consolidated skill" "$ROOT/PROJECT/PDDA.md" 'One repo-owned skill operates on this file: `/releases`'
if grep -Eq '/release-plan|/release([^s[:alnum:]-]|$)' "$ROOT/ROUTER.md" "$ROOT/PROJECT/PDDA.md"; then
  fail "canonical routing docs still name a legacy release skill"
else
  pass "canonical routing docs contain no legacy release skill"
fi

if bash -n "$INSTALLER"; then pass "installer parses"; else fail "installer has a syntax error"; fi
if grep -Eq 'CODEX_SKILLS_DIR|/\.codex/|~/\.codex' "$INSTALLER"; then
  fail "installer contains a Codex install path"
else
  pass "installer is Claude-only"
fi

TMP="$(mktemp -d -t releases-skill.XXXXXX)" || {
  echo "  FAIL: mktemp failed" >&2
  exit 1
}
[ -n "$TMP" ] && [ -d "$TMP" ] || {
  echo "  FAIL: mktemp returned an invalid path" >&2
  exit 1
}
trap '[ -n "$TMP" ] && [ -d "$TMP" ] && rm -rf "$TMP"' EXIT

CLAUDE_DIR="$TMP/claude-skills"
mkdir -p "$CLAUDE_DIR" "$TMP/legacy-release" "$TMP/legacy-release-plan"
ln -s "$TMP/legacy-release" "$CLAUDE_DIR/release"
ln -s "$TMP/legacy-release-plan" "$CLAUDE_DIR/release-plan"

out="$(CLAUDE_SKILLS_DIR="$CLAUDE_DIR" bash "$INSTALLER" 2>&1)"
rc=$?
[ "$rc" -eq 0 ] && pass "installer succeeds with legacy symlinks" \
  || fail "installer failed with legacy symlinks: $out"
[ -L "$CLAUDE_DIR/releases" ] && pass "installer creates plural Claude symlink" \
  || fail "plural Claude symlink missing"
[ "$(readlink "$CLAUDE_DIR/releases" 2>/dev/null)" = "$ROOT/skills/releases" ] \
  && pass "plural symlink targets the repo-owned skill" \
  || fail "plural symlink points at the wrong target"
[ ! -L "$CLAUDE_DIR/release" ] && [ ! -L "$CLAUDE_DIR/release-plan" ] \
  && pass "installer retires both legacy aliases" \
  || fail "one or more legacy aliases survived migration"

# Pin the idempotent branch: an already-correct new link must not exit before retiring a legacy
# alias that another sync recreated.
ln -s "$TMP/legacy-release-plan" "$CLAUDE_DIR/release-plan"
out="$(CLAUDE_SKILLS_DIR="$CLAUDE_DIR" bash "$INSTALLER" 2>&1)"
rc=$?
[ "$rc" -eq 0 ] && [ ! -L "$CLAUDE_DIR/release-plan" ] \
  && pass "idempotent rerun still retires a resurrected legacy alias" \
  || fail "idempotent rerun left the legacy alias: rc=$rc out=$out"

# A real legacy directory may contain unique operator work. Consolidation refuses before creating
# or deleting anything in that destination.
CLAUDE_REAL="$TMP/claude-real-legacy"
mkdir -p "$CLAUDE_REAL/release-plan"
out="$(CLAUDE_SKILLS_DIR="$CLAUDE_REAL" bash "$INSTALLER" 2>&1)"
rc=$?
[ "$rc" -eq 1 ] && pass "real legacy directory is refused" \
  || fail "real legacy directory should refuse with exit 1: rc=$rc out=$out"
[ -d "$CLAUDE_REAL/release-plan" ] && [ ! -e "$CLAUDE_REAL/releases" ] \
  && pass "refusal leaves the destination untouched" \
  || fail "refusal mutated the destination"

echo "  releases-skill: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ]
