#!/usr/bin/env bash
# test/gh422-backfill-source-url.sh — GH-422.
#
# GH-400 criterion 2 made preflight refuse a capture doc that declares a `gh_issue` without citing
# that issue's URL. The gate is correct; its posture was chosen from a blast radius measured on the
# harness repo alone (1 of 48) while the vendoring repos carried 18 between them, and the remediation
# it printed was a `<owner>/<repo>` placeholder the harness could have resolved itself.
#
# Two behaviours are pinned here:
#   1. preflight's NOT-READY message resolves the real owner/repo from the TARGET's origin;
#   2. the backfill tool fixes docs in bulk without ever guessing about provenance it cannot verify.
#
# The conflict case is the one that matters most. When `source:` cites a different issue than
# `gh_issue`, the wrong field may be `gh_issue` — a machine cannot tell which, and rewriting the URL
# to agree would launder bad provenance into provenance that LOOKS verified. That is precisely the
# failure GH-400 exists to prevent, so it must be reported and left alone (case 4), and the tool must
# exit non-zero so a caller cannot read it as a clean sweep (case 4b).
#
# Hermetic: every fixture is a throwaway git repo with a fake origin. No network.

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
TOOL="$ROOT/utils/py/backfill_source_url.py"
PY="$ROOT/utils/py/swarm_preflight.py"
export SP_PY_DIR="$ROOT/utils/py"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh422-backfill.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

PASS=0; FAIL=0
pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }

echo "== test: gh422-backfill-source-url =="
echo "  workdir: $WORK"

[ -f "$TOOL" ] || { fail "missing $TOOL"; echo "  gh422-backfill-source-url: $PASS pass, $FAIL fail"; exit 1; }

SLUG="Acme-Org/consumer-repo"
URL="https://github.com/$SLUG/issues"

mkrepo() { # <dir>
  mkdir -p "$1/PROJECT/2-WORKING"
  git -C "$1" init -q 2>/dev/null
  git -C "$1" remote add origin "https://github.com/$SLUG.git" 2>/dev/null
}

R="$WORK/consumer"; mkrepo "$R"
W="$R/PROJECT/2-WORKING"

# missing source:, with a body that must survive byte-for-byte
printf -- '---\ntitle: missing\ngh_issue: 154\nowner: noel\n---\n\n## Acceptance\n\n- [ ] a criterion.\n\nBody text with `source:` inside it, which must NOT be treated as frontmatter.\n' >"$W/GH-154-missing.md"
cp "$W/GH-154-missing.md" "$WORK/GH-154.before"
# already correct
printf -- '---\ntitle: ok\ngh_issue: 155\nsource: %s/155\n---\n\nbody\n' "$URL" >"$W/GH-155-ok.md"
# unusable non-URL value
printf -- '---\ntitle: bare\ngh_issue: 156\nsource: issue#156\n---\n\nbody\n' >"$W/GH-156-bare.md"
# conflict: cites a different issue
printf -- '---\ntitle: conflict\ngh_issue: 157\nsource: %s/999\n---\n\nbody\n' "$URL" >"$W/GH-157-conflict.md"
# no gh_issue at all
printf -- '---\ntitle: none\n---\n\nbody\n' >"$W/NO-ISSUE.md"

# ── Case 1: dry-run reports but writes NOTHING ────────────────────────────────────────────────────
out="$(python3 "$TOOL" --root "$R" 2>&1)"; rc=$?
grep -q "DRY-RUN: nothing written" <<<"$out" \
  && pass "C1 dry-run is the default and says so" || fail "C1 no dry-run notice: $out"
if /usr/bin/diff -q "$WORK/GH-154.before" "$W/GH-154-missing.md" >/dev/null; then
  pass "C1b dry-run left the file byte-identical"
else
  fail "C1b dry-run MODIFIED a file"
fi
grep -q "$SLUG" <<<"$out" \
  && pass "C1c the derived slug comes from the target's origin, not the harness's" \
  || fail "C1c target origin slug absent: $out"

# ── Case 2: --apply adds the missing line, body untouched ─────────────────────────────────────────
out2="$(python3 "$TOOL" --root "$R" --apply 2>&1)"; rc2=$?
grep -qE "^source: $URL/154$" "$W/GH-154-missing.md" \
  && pass "C2 missing source: is added with the target repo's URL" \
  || fail "C2 source: not added: $(head -5 "$W/GH-154-missing.md")"
if [ "$(grep -c '^source:' "$W/GH-154-missing.md")" = "1" ]; then
  pass "C2b exactly one source: line is written"
else
  fail "C2b duplicate source: lines"
fi
# body must be byte-identical: compare everything after the closing frontmatter delimiter
body_before="$(awk 'f{print} /^---$/{c++; if(c==2) f=1}' "$WORK/GH-154.before")"
body_after="$(awk 'f{print} /^---$/{c++; if(c==2) f=1}' "$W/GH-154-missing.md")"
[ "$body_before" = "$body_after" ] \
  && pass "C2c the document body is byte-identical (a body 'source:' line is not frontmatter)" \
  || fail "C2c body changed"

# ── Case 3: a valid source: is left alone; an unusable one is replaced ────────────────────────────
grep -qE "^source: $URL/155$" "$W/GH-155-ok.md" \
  && pass "C3 an already-correct source: is untouched" || fail "C3 correct doc was altered"
grep -qE "^source: $URL/156$" "$W/GH-156-bare.md" \
  && pass "C3b a bare 'issue#156' is replaced with the real URL" \
  || fail "C3b bare reference not replaced: $(head -4 "$W/GH-156-bare.md")"

# ── Case 4: THE PIN — a mismatch is reported and never rewritten ──────────────────────────────────
grep -qE "^source: $URL/999$" "$W/GH-157-conflict.md" \
  && pass "C4 a conflicting source: is NOT rewritten (gh_issue may be the wrong field)" \
  || fail "C4 conflict was silently rewritten — bad provenance laundered into good-looking provenance"
grep -q "CONFLICT (untouched)" <<<"$out2" \
  && pass "C4b the conflict is reported to the operator" || fail "C4b conflict not reported: $out2"
[ "$rc2" -ne 0 ] \
  && pass "C4c exit is non-zero when a conflict remains, so a script cannot read it as clean" \
  || fail "C4c exited 0 despite an unresolved conflict"

# ── Case 5: a doc with no gh_issue is not dragged in ──────────────────────────────────────────────
grep -q "^source:" "$W/NO-ISSUE.md" \
  && fail "C5 a doc naming no gh_issue was given a source: it never claimed" \
  || pass "C5 a doc with no gh_issue is left alone"

# ── Case 5b: THE SECOND PIN — the tool must cover exactly what the GATE blocks ────────────────────
# A doc named GH-<n>-*.md with NO `gh_issue:` key is still blocked by the gate in bundle mode, because
# preflight resolves it by globbing GH-N-*.md for `--gh-issue N`. A backfill reading only frontmatter
# skips precisely those docs and leaves the operator blocked with no way out — the two-extractors-
# disagree failure from #413. Found by dry-running against `cactus`, whose docs use `issue:` not
# `gh_issue:`; every one of its blocked docs was invisible to the first version of this tool.
printf -- '---\nissue: 9\ntitle: legacy key\n---\n\nbody\n' >"$W/GH-9-legacy-key.md"
python3 "$TOOL" --root "$R" --apply >/dev/null 2>&1
grep -qE "^source: $URL/9$" "$W/GH-9-legacy-key.md" \
  && pass "C5b a GH-<n>- doc with no gh_issue key still gets its source: (gate parity)" \
  || fail "C5b tool skipped a doc the gate blocks: $(head -5 "$W/GH-9-legacy-key.md")"
python3 - "$W/GH-9-legacy-key.md" <<'PYEOF' && pass "C5c and the gate agrees the doc now passes" || fail "C5c gate still refuses the doc the tool claims to have fixed"
import sys, os
sys.path.insert(0, os.environ["SP_PY_DIR"])
from swarm_preflight import check_source_url
sys.exit(0 if check_source_url(sys.argv[1], "9")["status"] == "ok" else 1)
PYEOF

# ── Case 6: idempotent — a second --apply changes nothing ─────────────────────────────────────────
cp "$W/GH-154-missing.md" "$WORK/after-first.md"
python3 "$TOOL" --root "$R" --apply >/dev/null 2>&1
/usr/bin/diff -q "$WORK/after-first.md" "$W/GH-154-missing.md" >/dev/null \
  && pass "C6 re-running --apply is idempotent" || fail "C6 second run changed the file again"

# ── Case 7: no origin remote → refuses rather than guessing the harness's slug ────────────────────
R2="$WORK/no-origin"; mkdir -p "$R2/PROJECT/2-WORKING"; git -C "$R2" init -q 2>/dev/null
printf -- '---\ntitle: x\ngh_issue: 1\n---\n\nbody\n' >"$R2/PROJECT/2-WORKING/GH-1-x.md"
out3="$(python3 "$TOOL" --root "$R2" --apply 2>&1)"; rc3=$?
[ "$rc3" -eq 6 ] && grep -q "BLOCKED" <<<"$out3" \
  && pass "C7 no origin remote → BLOCKED, never falls back to the harness's own slug" \
  || fail "C7 expected exit 6 BLOCKED, got rc=$rc3: $out3"
grep -q "^source:" "$R2/PROJECT/2-WORKING/GH-1-x.md" \
  && fail "C7b wrote a source: despite having no origin to derive it from" \
  || pass "C7b nothing written when the slug cannot be resolved"

# ── Case 8: preflight's remediation resolves the real slug, not a placeholder ─────────────────────
R3="$WORK/pf"; mkrepo "$R3"; mkdir -p "$R3/src"; : >"$R3/src/a.js"
git -C "$R3" symbolic-ref HEAD refs/heads/main 2>/dev/null
{ printf -- '---\ntitle: pf\ngh_issue: 202\n---\n\n## Acceptance\n\n- [ ] a criterion.\n\n## Swarm Preflight Contract\n```json\n%s\n```\n' '{
  "target": { "repo": ".", "ref": "main" },
  "gate": "true",
  "fix_probes": [ { "type": "path_absent", "path": "NEW_FILE.txt" } ],
  "artifacts": [ "src/a.js" ],
  "remediation": { "source": "issue#202", "criteria": "x" }
}'; } >"$R3/PROJECT/2-WORKING/GH-202-pf.md"
git -C "$R3" -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1
git -C "$R3" -c user.email=t@t -c user.name=t commit -qm init >/dev/null 2>&1
mkdir -p "$WORK/bin"; printf '#!/usr/bin/env bash\nexit 1\n' >"$WORK/bin/gh"; chmod +x "$WORK/bin/gh"
export SWARM_PREFLIGHT_NOW="2026-08-04T00:00:00Z" SWARM_PREFLIGHT_TODAY="2026-08-04"
out4="$(PATH="$WORK/bin:$PATH" SWARM_PREFLIGHT_ROOT="$R3" python3 "$PY" --target-root "$R3" \
  --project-doc "$R3/PROJECT/2-WORKING/GH-202-pf.md" --out "$R3/packet" 2>&1)"
grep -q "$URL/202" <<<"$out4" \
  && pass "C8 the NOT-READY message cites the target repo's real issue URL" \
  || fail "C8 remediation still a placeholder: $(grep -i 'source URL' <<<"$out4" | head -1)"
grep -q "<owner>/<repo>" <<<"$out4" \
  && fail "C8b placeholder still emitted when a slug resolves" \
  || pass "C8b no placeholder when the slug resolves"
grep -q "backfill_source_url.py" <<<"$out4" \
  && pass "C8c the message points at the bulk remediation tool" \
  || fail "C8c bulk tool not mentioned"

echo "  gh422-backfill-source-url: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
