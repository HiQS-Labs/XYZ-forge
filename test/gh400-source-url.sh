#!/usr/bin/env bash
# test/gh400-source-url.sh — GH-400, criterion 2: "Every generated capture doc contains the source
# issue URL."
#
# This criterion shipped in b026737 as PROSE ONLY — `skills/10days/SKILL.md` told the model to put
# the issue URL in `source:`, and no gate ever read the field. `source: issue#400`, or no `source`
# at all, passed everything. That is the same "trust the model's output as though it were verified"
# shape GH-400 exists to close, reproduced inside GH-400's own fix, which is why the criterion was
# left unchecked on the issue rather than claimed.
#
# Cases 1-4 are the pin (missing / bare reference / wrong issue / body-only). Cases 5-7 are the half
# that keeps it honest: a correct doc must still pass, a doc with no gh_issue must not be dragged in,
# and the verdict must be auditable afterwards. This repo has documented instances of a check that
# could not distinguish the bug from the fix (#348, #351, #342, #362, #369) — the pass-direction
# cases exist so this is not another (see #419).
#
# Hermetic: `gh` is stubbed to fail, so the acceptance-fidelity check degrades to `unknown` (never
# blocking) and cannot mask or manufacture the verdict under test. No network, no auth.

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
PY="$ROOT/utils/py/swarm_preflight.py"
export SP_PY_DIR="$ROOT/utils/py"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh400-srcurl.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

PASS=0; FAIL=0
pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }

echo "== test: gh400-source-url =="
echo "  workdir: $WORK"

[ -f "$PY" ] || { fail "missing $PY"; echo "  gh400-source-url: $PASS pass, $FAIL fail"; exit 1; }

# `gh` stubbed to always fail: isolates this gate from the acceptance-fidelity one.
mkdir -p "$WORK/bin"
printf '#!/usr/bin/env bash\necho "gh: unavailable" >&2\nexit 1\n' >"$WORK/bin/gh"
chmod +x "$WORK/bin/gh"

URL_BASE="https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues"

# unit <doc-file> <issue-or-empty> → "<status>"
unit() {
  python3 - "$1" "${2-}" <<'PYEOF'
import sys, os
sys.path.insert(0, os.environ["SP_PY_DIR"])
from swarm_preflight import check_source_url
r = check_source_url(sys.argv[1], sys.argv[2] or None)
print(r["status"])
PYEOF
}

mkdoc() { # <file> <frontmatter-extra> [body]
  { printf -- '---\ntitle: t\ngh_issue: 202\n%s---\n\n## Acceptance\n\n- [ ] a criterion.\n\n%s' "$2" "${3-}"
  } >"$1"
}

# ── Case 1: gh_issue but no source: at all ────────────────────────────────────────────────────────
mkdoc "$WORK/c1.md" ""
[ "$(unit "$WORK/c1.md" 202)" = "missing" ] \
  && pass "C1 gh_issue with no source: is refused" \
  || fail "C1 expected missing, got '$(unit "$WORK/c1.md" 202)'"

# ── Case 2: a bare reference is not a URL ─────────────────────────────────────────────────────────
mkdoc "$WORK/c2.md" "source: issue#202
"
[ "$(unit "$WORK/c2.md" 202)" = "missing" ] \
  && pass "C2 'source: issue#202' is not diffable and is refused" \
  || fail "C2 expected missing, got '$(unit "$WORK/c2.md" 202)'"

# ── Case 3: URL present but pointing at a DIFFERENT issue ─────────────────────────────────────────
mkdoc "$WORK/c3.md" "source: $URL_BASE/999
"
[ "$(unit "$WORK/c3.md" 202)" = "mismatch" ] \
  && pass "C3 a URL citing issue #999 under gh_issue: 202 is refused" \
  || fail "C3 expected mismatch, got '$(unit "$WORK/c3.md" 202)'"

# ── Case 4: a source: line in the BODY must not satisfy the frontmatter requirement ───────────────
mkdoc "$WORK/c4.md" "" "Example of what to write:

\`\`\`yaml
source: $URL_BASE/202
\`\`\`
"
[ "$(unit "$WORK/c4.md" 202)" = "missing" ] \
  && pass "C4 a fenced example in the body does not count as provenance" \
  || fail "C4 body-only source: was accepted — got '$(unit "$WORK/c4.md" 202)'"

# ── Case 5: a correct doc must PASS (anti-noise) ──────────────────────────────────────────────────
mkdoc "$WORK/c5.md" "source: $URL_BASE/202
"
[ "$(unit "$WORK/c5.md" 202)" = "ok" ] \
  && pass "C5 a correct source URL passes" \
  || fail "C5 correct doc rejected — the gate is unusable: got '$(unit "$WORK/c5.md" 202)'"

# ── Case 6: quoted value, and a doc with no gh_issue is not dragged in ────────────────────────────
mkdoc "$WORK/c6.md" "source: \"$URL_BASE/202\"
"
[ "$(unit "$WORK/c6.md" 202)" = "ok" ] && pass "C6 a quoted URL passes" \
  || fail "C6 quoted URL rejected: got '$(unit "$WORK/c6.md" 202)'"
printf -- '---\ntitle: no-issue\n---\n\nbody\n' >"$WORK/c6b.md"
[ "$(unit "$WORK/c6b.md" "")" = "not-applicable" ] \
  && pass "C6b a doc naming no gh_issue is not-applicable, not a failure" \
  || fail "C6b expected not-applicable, got '$(unit "$WORK/c6b.md" "")'"

# ── Case 7: end-to-end — preflight refuses to emit a packet, and records the verdict ──────────────
R="$WORK/repo"; mkdir -p "$R/PROJECT/2-WORKING" "$R/src"; : >"$R/src/a.js"
git -C "$R" init -q -b main 2>/dev/null || { git -C "$R" init -q; git -C "$R" symbolic-ref HEAD refs/heads/main; }
CONTRACT='{
  "target": { "repo": ".", "ref": "main" },
  "gate": "true",
  "fix_probes": [ { "type": "path_absent", "path": "NEW_FILE.txt" } ],
  "artifacts": [ "src/a.js" ],
  "remediation": { "source": "issue#202", "criteria": "x" }
}'
mkcapture() { # <file> <source-line>
  { printf -- '---\ntitle: e2e\ngh_issue: 202\n%s---\n\n## Acceptance\n\n- [ ] a criterion.\n\n## Swarm Preflight Contract\n```json\n%s\n```\n' \
      "$2" "$CONTRACT"; } >"$1"
}
mkcapture "$R/PROJECT/2-WORKING/GH-202-bad.md" ""
git -C "$R" -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1
git -C "$R" -c user.email=t@t -c user.name=t commit -qm init >/dev/null 2>&1

export SWARM_PREFLIGHT_NOW="2026-08-03T00:00:00Z" SWARM_PREFLIGHT_TODAY="2026-08-03"
out="$(PATH="$WORK/bin:$PATH" SWARM_PREFLIGHT_ROOT="$R" python3 "$PY" --target-root "$R" \
  --project-doc "$R/PROJECT/2-WORKING/GH-202-bad.md" --out "$R/packet" 2>&1)"; rc=$?
[ "$rc" -eq 5 ] && grep -q "NOT-READY" <<<"$out" \
  && pass "C7 preflight exits 5 NOT-READY when the doc cites no issue URL" \
  || fail "C7 expected exit 5 NOT-READY, got rc=$rc: $out"
grep -q "source URL missing" <<<"$out" \
  && pass "C7b the verdict says which check failed and why" \
  || fail "C7b unhelpful NOT-READY message: $out"
[ ! -f "$R/packet/packet.md" ] \
  && pass "C7c no packet is written when provenance is missing" \
  || fail "C7c a packet was emitted despite a missing source URL"

# ── Case 8: end-to-end — a correct doc still emits, and the verdict is auditable ──────────────────
R2="$WORK/repo-ok"; mkdir -p "$R2/PROJECT/2-WORKING" "$R2/src"; : >"$R2/src/a.js"
git -C "$R2" init -q -b main 2>/dev/null || { git -C "$R2" init -q; git -C "$R2" symbolic-ref HEAD refs/heads/main; }
{ printf -- '---\ntitle: e2e-ok\ngh_issue: 202\nsource: %s/202\n---\n\n## Acceptance\n\n- [ ] a criterion.\n\n## Swarm Preflight Contract\n```json\n%s\n```\n' \
    "$URL_BASE" "$CONTRACT"; } >"$R2/PROJECT/2-WORKING/GH-202-ok.md"
git -C "$R2" -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1
git -C "$R2" -c user.email=t@t -c user.name=t commit -qm init >/dev/null 2>&1

out2="$(PATH="$WORK/bin:$PATH" SWARM_PREFLIGHT_ROOT="$R2" python3 "$PY" --target-root "$R2" \
  --project-doc "$R2/PROJECT/2-WORKING/GH-202-ok.md" --out "$R2/packet" 2>&1)"; rc2=$?
[ "$rc2" -eq 0 ] \
  && pass "C8 a doc citing its issue URL still emits a packet (exit 0)" \
  || fail "C8 correct doc blocked — the gate is unusable: rc=$rc2: $out2"
[ -f "$R2/packet/packet.md" ] && pass "C8b the packet is written" || fail "C8b no packet for the correct case"
if [ -f "$R2/packet/run-candidate.json" ]; then
  python3 - "$R2/packet/run-candidate.json" <<'PYEOF' && pass "C8c run-candidate.json records readiness.source_url" || fail "C8c source_url missing from run-candidate.json"
import json, sys
d = json.load(open(sys.argv[1]))
s = d.get("readiness", {}).get("source_url", {})
sys.exit(0 if s.get("status") == "ok" else 1)
PYEOF
else
  fail "C8c no run-candidate.json to audit"
fi

echo "  gh400-source-url: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
