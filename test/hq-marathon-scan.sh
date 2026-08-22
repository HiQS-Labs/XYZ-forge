#!/usr/bin/env bash
# GH-158: hermetic regression lock for utils/hq/marathon-scan.sh.
#
# Builds fixture registries + fixture repos, stubs each target repo's own swarm-preflight.sh, and
# asserts the scanner classifies all five lane verdicts plus Held-not-counted without writing inside
# any target repo.

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
SCAN="$ROOT/utils/hq/marathon-scan.sh"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/hq-marathon-scan.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

PASS=0
FAIL=0
pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }

echo "== test: hq-marathon-scan =="
echo "  workdir: $WORK"

make_repo() {
  local name="$1"
  local repo="$WORK/repos/$name"
  mkdir -p "$repo/.git" "$repo/PROJECT/2-WORKING" "$repo/PROJECT/1-INBOX" "$repo/PROJECT/3-COMPLETED" "$repo/utils"
  cat >"$repo/utils/swarm-preflight.sh" <<'EOF'
#!/usr/bin/env bash
set -uo pipefail
MODE="" ISSUE="" DOC=""
while (($# > 0)); do
  case "$1" in
    --gh-issue) ISSUE="${2:-}"; shift 2 ;;
    --project-doc) DOC="${2:-}"; shift 2 ;;
    --target-root|--format|--dry-run) shift ;;
    *) shift ;;
  esac
done
if [[ -n "$ISSUE" ]]; then
  case "$ISSUE" in
    101) echo '{"readiness":{"ready":true}}'; exit 0 ;;
    201) echo '{"readiness":{"ready":false}}'; exit 6 ;;
    301) echo '{"readiness":{"ready":false}}'; exit 6 ;;
    501) echo '{"readiness":{"ready":false}}'; exit 7 ;;
  esac
fi
case "$DOC" in
  PROJECT/3-COMPLETED/RELAY-TO-ISSUE-SKILL.md) echo '{"readiness":{"ready":false}}'; exit 4 ;;
  *) echo '{"readiness":{"ready":false}}'; exit 6 ;;
esac
EOF
  chmod +x "$repo/utils/swarm-preflight.sh"
  cat >"$repo/ROADMAP.md" <<'EOF'
# Roadmap
## Ledger
### In progress
- **relay-to-issue-skill** 🟡 — stale pointer → [d](PROJECT/2-WORKING/RELAY-TO-ISSUE-SKILL.md)
EOF
  printf '%s' "$repo"
}

mk_doc() {
  local path="$1" title="$2" status="$3"
  cat >"$path" <<EOF
---
title: $title
status: $status
---

# $title

## Swarm Preflight Contract
\`\`\`json
{"target":{"repo":".","ref":"main"},"gate":"true","fix_probes":[{"type":"path_absent","path":"missing.txt"}],"artifacts":["src/a.js"]}
\`\`\`
EOF
}

mk_marathon() {
  local path="$1" title="$2" status="$3" lanes="$4"
  cat >"$path" <<EOF
---
title: $title
status: $status
---

# $title

## Recommended waves

**Wave 1:** $lanes
EOF
}

READY_REPO="$(make_repo ready-repo)"
PROMOTE_REPO="$(make_repo promote-repo)"
BLOCKED_REPO="$(make_repo blocked-repo)"
STALE_REPO="$(make_repo stale-repo)"
AMBIG_REPO="$(make_repo ambiguous-repo)"
HELD_REPO="$(make_repo held-repo)"

mk_doc "$READY_REPO/PROJECT/2-WORKING/GH-101-READY.md" GH-101-ready "Active"
mk_doc "$PROMOTE_REPO/PROJECT/1-INBOX/GH-201-PROMOTE.md" GH-201-promote "Open"
mk_doc "$BLOCKED_REPO/PROJECT/2-WORKING/GH-301-BLOCKED.md" GH-301-blocked "Active"
mk_doc "$AMBIG_REPO/PROJECT/2-WORKING/GH-501-AMBIG.md" GH-501-ambig "Active"
mk_doc "$STALE_REPO/PROJECT/3-COMPLETED/RELAY-TO-ISSUE-SKILL.md" relay-to-issue-skill "Shipped"

mk_marathon "$READY_REPO/PROJECT/2-WORKING/MARATHON-PLAN-2026-07-06.md" ready-marathon "Active" "#101"
mk_marathon "$PROMOTE_REPO/PROJECT/2-WORKING/MARATHON-PLAN-2026-07-06.md" promote-marathon "Active" "#201"
mk_marathon "$BLOCKED_REPO/PROJECT/2-WORKING/MARATHON-PLAN-2026-07-06.md" blocked-marathon "Active" "#301"
mk_marathon "$STALE_REPO/PROJECT/2-WORKING/MARATHON-PLAN-2026-07-06.md" stale-marathon "Active" "relay-to-issue-skill"
mk_marathon "$AMBIG_REPO/PROJECT/2-WORKING/MARATHON-PLAN-2026-07-06.md" ambiguous-marathon "Active" "#501"
mk_marathon "$HELD_REPO/PROJECT/2-WORKING/MARATHON-2026-07-06-B.md" held-marathon "Held (operator go)" "#601"

PDDA_DIR="$WORK/pdda"
mkdir -p "$PDDA_DIR"
cat >"$PDDA_DIR/registry-test.tsv" <<EOF
ready-repo	2026-07-06T00:00:00Z	observe	abc	yes
promote-repo	2026-07-06T00:00:00Z	observe	abc	yes
blocked-repo	2026-07-06T00:00:00Z	observe	abc	yes
stale-repo	2026-07-06T00:00:00Z	observe	abc	yes
ambiguous-repo	2026-07-06T00:00:00Z	observe	abc	yes
held-repo	2026-07-06T00:00:00Z	observe	abc	yes
EOF

XYZ_REG="$WORK/xyz.tsv"
cat >"$XYZ_REG" <<EOF
$READY_REPO/.xyz	2026-07-06T00:00:00Z	0.2.0	a1	$READY_REPO
$PROMOTE_REPO/.xyz	2026-07-06T00:00:00Z	0.2.0	a1	$PROMOTE_REPO
$BLOCKED_REPO/.xyz	2026-07-06T00:00:00Z	0.2.0	a1	$BLOCKED_REPO
$STALE_REPO/.xyz	2026-07-06T00:00:00Z	0.2.0	a1	$STALE_REPO
$AMBIG_REPO/.xyz	2026-07-06T00:00:00Z	0.2.0	a1	$AMBIG_REPO
$HELD_REPO/.xyz	2026-07-06T00:00:00Z	0.2.0	a1	$HELD_REPO
EOF

OUT="$WORK/HQ-MARATHON-2026-07-06.md"
HQ_PDDA_REGISTRY_DIR="$PDDA_DIR" \
HQ_XYZ_REGISTRY="$XYZ_REG" \
HQ_SEARCH_ROOTS="$WORK/repos" \
HQ_MARATHON_SCAN_TODAY="2026-07-06" \
HQ_MARATHON_SCAN_NOW="2026-07-06T12:00:00Z" \
bash "$SCAN" --out "$OUT" >/dev/null 2>&1
rc=$?
[[ $rc -eq 0 ]] && pass "scan exits 0" || fail "scan rc=$rc"
[[ -f "$OUT" ]] && pass "report written" || fail "report missing"

grep -q '| ready-repo | `PROJECT/2-WORKING/MARATHON-PLAN-2026-07-06.md` | Active | ✅ active |' "$OUT" \
  && pass "ready repo surfaced in source table" || fail "ready repo missing from source table"
grep -q '| #101 | `PROJECT/2-WORKING/MARATHON-PLAN-2026-07-06.md` | `gh-issue #101` | ✅ ready (exit 0) |' "$OUT" \
  && pass "ready lane classified" || fail "ready lane not classified"
grep -q '| #201 | `PROJECT/2-WORKING/MARATHON-PLAN-2026-07-06.md` | `gh-issue #201` | ⚠️ blocked-not-promoted (exit 6) |' "$OUT" \
  && pass "blocked-not-promoted lane classified" || fail "blocked-not-promoted missing"
grep -q '| #301 | `PROJECT/2-WORKING/MARATHON-PLAN-2026-07-06.md` | `gh-issue #301` | ⛔ blocked-other (exit 6) |' "$OUT" \
  && pass "blocked-other lane classified" || fail "blocked-other missing"
grep -q '| relay-to-issue-skill | `PROJECT/2-WORKING/MARATHON-PLAN-2026-07-06.md` | `PROJECT/3-COMPLETED/RELAY-TO-ISSUE-SKILL.md` | ⚠️ stale-already-landed (exit 4) |' "$OUT" \
  && pass "named ghost lane resolves to completed doc and classifies stale" || fail "stale ghost lane missing"
grep -q '| #501 | `PROJECT/2-WORKING/MARATHON-PLAN-2026-07-06.md` | `gh-issue #501` | ❓ ambiguous (exit 7) |' "$OUT" \
  && pass "ambiguous lane classified" || fail "ambiguous missing"
grep -q '| held-repo | `PROJECT/2-WORKING/MARATHON-2026-07-06-B.md` | Held (operator go) | 🟡 held, not counted |' "$OUT" \
  && pass "held marathon surfaced but marked not counted" || fail "held marathon missing"

grep -q -- '- Ready: 1' "$OUT" \
  && grep -q -- '- Blocked-not-promoted: 1' "$OUT" \
  && grep -q -- '- Blocked-other: 1' "$OUT" \
  && grep -q -- '- Stale-already-landed: 1' "$OUT" \
  && grep -q -- '- Ambiguous: 1' "$OUT" \
  && grep -q -- '- Held marathons surfaced, not counted: 1' "$OUT" \
  && pass "net counts match fixture matrix" \
  || fail "net counts wrong: $(grep -E '^- (Ready|Blocked|Stale|Ambiguous|Held)' "$OUT")"

if grep -q . <<<"$(find "$WORK/repos" -path '*/PROJECT/2-WORKING/HQ-MARATHON-*' -o -path '*/packet/*')"; then
  fail "scanner wrote inside a target repo"
else
  pass "scanner stayed read-only over target repos"
fi

echo "== hq-marathon-scan: $PASS passed, $FAIL failed =="
[ "$FAIL" -eq 0 ]
