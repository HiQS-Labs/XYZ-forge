#!/usr/bin/env bash
# GH-202: wave_reconcile must (1) tolerate marathon-plan exit 5 (items held is normal planning
# state, not a reconcile failure) and (2) keep capture docs ACTIVE when the linked issue is OPEN —
# promotion requires the issue closed. Pre-fix behavior recorded on the issue (2026-08-24).
source "$(dirname "$0")/_setup.sh" gh202-wave-reconcile-issue-state
XYZ_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RECONCILE_PY="$XYZ_ROOT/utils/py/wave_reconcile.py"

PASS=0; FAIL=0
pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "== test: gh202-wave-reconcile-issue-state =="

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh202-reconcile.XXXXXX")"
cleanup() { [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
trap cleanup EXIT
. "$(dirname "$0")/lib/fixture-guard.sh"
TODAY="$(date +%Y-%m-%d)"
fixture_guard_init "$WORK"

REPO="$WORK/fixture-repo"
mkdir -p "$REPO"
git -C "$REPO" init -q -b development
git -C "$REPO" config user.name "Test Agent"
git -C "$REPO" config user.email "test@example.com"
mkdir -p "$REPO/PROJECT/2-WORKING" "$REPO/PROJECT/3-COMPLETED" "$REPO/PROJECT/4-MISC" \
  "$REPO/utils/py" "$REPO/utils/pdda" "$REPO/utils/timeline" "$REPO/TESTS-RESULTS/$TODAY"
cp "$RECONCILE_PY" "$REPO/utils/py/wave_reconcile.py"
require_fixture_file "$REPO/utils/py/wave_reconcile.py" "reconciler-copy"

cat > "$REPO/ROADMAP.md" <<'ROADMAPEOF'
# Test Roadmap

### In progress
- **GH-3001 · Open-issue umbrella** 🚧 **active $TODAY** — phases remain. rated 80/80/80/80. → [GH-3001-OPEN.md](PROJECT/2-WORKING/GH-3001-OPEN.md) · [#3001](https://github.com/HiQS-Labs/XYZ-forge/issues/3001)
- **GH-3002 · Done work** 🚧 **active $TODAY** — complete. rated 80/80/80/80. → [GH-3002-DONE.md](PROJECT/2-WORKING/GH-3002-DONE.md) · [#3002](https://github.com/HiQS-Labs/XYZ-forge/issues/3002)

### Completed
ROADMAPEOF

cat > "$REPO/PROJECT/2-WORKING/GH-3001-OPEN.md" <<'DOCEOF'
---
gh_issue: 3001
title: "GH-3001"
status: In Progress
created: $TODAY
updated: $TODAY
---

# GH-3001

## Lessons Learned (For Future Agents)
- Promote only when the linked issue is actually closed.
DOCEOF

cat > "$REPO/PROJECT/2-WORKING/GH-3002-DONE.md" <<'DOCEOF'
---
gh_issue: 3002
title: "GH-3002"
status: In Progress
created: $TODAY
updated: $TODAY
---

# GH-3002

## Lessons Learned (For Future Agents)
- Promote only when the linked issue is actually closed.
DOCEOF

echo '{"status": "PASS"}' > "$REPO/TESTS-RESULTS/$TODAY/provenance.jsonl"

# Subprocess stubs — marathon-plan deliberately exits 5 (items held): the reconcile must CONTINUE.
printf '#!/usr/bin/env python3\nprint("MOCK: releases_app OK")\n' > "$REPO/utils/py/releases_app.py"
chmod +x "$REPO/utils/py/releases_app.py"
printf '#!/usr/bin/env bash\necho "MOCK: roadmap-dashboard OK"\n' > "$REPO/utils/roadmap-dashboard.sh"
chmod +x "$REPO/utils/roadmap-dashboard.sh"
printf '#!/usr/bin/env python3\nprint("MOCK: timeline OK")\n' > "$REPO/utils/timeline/export_timeline.py"
printf '#!/usr/bin/env bash\necho "MOCK: pdda run OK"\n' > "$REPO/utils/pdda/pdda.sh"
chmod +x "$REPO/utils/timeline/export_timeline.py"
chmod +x "$REPO/utils/pdda/pdda.sh"
printf '#!/usr/bin/env bash\necho "MOCK: marathon-plan reports items held"\nexit 5\n' > "$REPO/utils/marathon-plan.sh"
chmod +x "$REPO/utils/marathon-plan.sh"

# Manifest: ONE merged PR linking BOTH issues; issue 3001 OPEN, 3002 CLOSED.
cat > "$REPO/manifest.json" <<'MANIFESTEOF'
{
  "prs": [
    {"number": 4001, "title": "feat: lands 3001 phase + all of 3002", "state": "MERGED",
     "mergedAt": "2026-08-24T00:00:00Z", "baseRefName": "development", "headRefName": "feat/x",
     "body": "Closes #3002. Advances GH-3001 (phase 1 of 2).", "url": "https://example/pr/4001"}
  ],
  "issues": [
    {"number": 3001, "state": "OPEN"},
    {"number": 3002, "state": "CLOSED"}
  ]
}
MANIFESTEOF

git -C "$REPO" add -A && git -C "$REPO" commit -qm "fixture: docs, stubs, manifest"
require_fixture_file "$REPO/manifest.json" "manifest"

out="$(python3 "$REPO/utils/py/wave_reconcile.py" --root "$REPO" --pr 4001 --offline "$REPO/manifest.json" --skip-pull 2>&1)"; rc=$?

[ "$rc" -eq 0 ] && pass "reconcile exits 0 despite marathon-plan exit 5 (items held tolerated)" \
  || fail "reconcile aborted (rc=$rc): $out"
grep -q "items held" <<<"$out" && pass "exit-5 tolerance is logged, not silent" || fail "no items-held log line"
[ -f "$REPO/PROJECT/2-WORKING/GH-3001-OPEN.md" ] && [ ! -f "$REPO/PROJECT/3-COMPLETED/GH-3001-OPEN.md" ] \
  && pass "OPEN-issue doc stays in 2-WORKING (no promotion)" || fail "OPEN-issue doc was moved/promoted"
grep -q "## Merge evidence" "$REPO/PROJECT/2-WORKING/GH-3001-OPEN.md" \
  && pass "OPEN-issue doc records merge evidence in place" || fail "no merge evidence recorded"
[ -f "$REPO/PROJECT/3-COMPLETED/GH-3002-DONE.md" ] && [ ! -f "$REPO/PROJECT/2-WORKING/GH-3002-DONE.md" ] \
  && pass "CLOSED-issue doc promotes to 3-COMPLETED (existing behavior preserved)" || fail "CLOSED-issue doc not promoted"

# Idempotency: re-running does not duplicate the evidence block
git -C "$REPO" add -A && git -C "$REPO" commit -qm "fixture: post-first-reconcile" 2>/dev/null || true
python3 "$REPO/utils/py/wave_reconcile.py" --root "$REPO" --pr 4001 --offline "$REPO/manifest.json" --skip-pull >/dev/null 2>&1
n="$(grep -c "## Merge evidence" "$REPO/PROJECT/2-WORKING/GH-3001-OPEN.md")"
[ "$n" -eq 1 ] && pass "merge-evidence recording is idempotent" || fail "evidence duplicated ($n blocks)"

# Negative control: manifest WITHOUT issues key (legacy shape) — a CLOSING keyword with
# unknown issue state still promotes (backward compat for the closer path)
cat > "$REPO/manifest2.json" <<'MANIFEST2EOF'
{
  "prs": [
    {"number": 4001, "title": "feat: lands 3001 phase + all of 3002", "state": "MERGED",
     "mergedAt": "2026-08-24T00:00:00Z", "baseRefName": "development", "headRefName": "feat/x",
     "body": "Closes #3002. Closes GH-3001.", "url": "https://example/pr/4001"}
  ]
}
MANIFEST2EOF
cat > "$REPO/PROJECT/2-WORKING/GH-3001-OPEN.md" <<'DOCEOF'
---
gh_issue: 3001
title: "GH-3001"
status: In Progress
created: $TODAY
updated: $TODAY
---

# GH-3001

## Lessons Learned (For Future Agents)
- Legacy manifest compatibility.
DOCEOF
git -C "$REPO" add -A && git -C "$REPO" commit -qm "fixture: restore 3001 for legacy manifest" 2>/dev/null || true
python3 "$REPO/utils/py/wave_reconcile.py" --root "$REPO" --pr 4001 --offline "$REPO/manifest2.json" --skip-pull >/dev/null 2>&1
[ -f "$REPO/PROJECT/3-COMPLETED/GH-3001-OPEN.md" ] \
  && pass "legacy manifest (no issues key): closing keyword + unknown state still promotes — backward compatible" \
  || fail "legacy manifest closer behavior changed (regression)"

# ── GH-271: reference-only mentions are not links ──────────────────────────────
# The pre-fix extractor treated every GH-N/#N mention as a linked issue (PR #185's body
# yielded ten "linked" issues, two of them live lanes). A mention must never promote,
# relocate, or ROADMAP-move anything — only record evidence on an OPEN issue's doc.
cat > "$REPO/PROJECT/2-WORKING/GH-3001-OPEN.md" <<'DOCEOF'
---
gh_issue: 3001
title: "GH-3001"
status: In Progress
created: $TODAY
updated: $TODAY
---

# GH-3001

## Lessons Learned (For Future Agents)
- Mention-only protection fixture.
DOCEOF
rm -f "$REPO/PROJECT/3-COMPLETED/GH-3001-OPEN.md"
cat > "$REPO/manifest3.json" <<'MANIFEST3EOF'
{
  "prs": [
    {"number": 4001, "title": "feat: touches several areas", "state": "MERGED",
     "mergedAt": "2026-08-24T00:00:00Z", "baseRefName": "development", "headRefName": "feat/x",
     "body": "Advances GH-3001; supersedes the approach from GH-2999.", "url": "https://example/pr/4001"}
  ]
}
MANIFEST3EOF
git -C "$REPO" add -A && git -C "$REPO" commit -qm "fixture: mention-only 3001" 2>/dev/null || true
out="$(python3 "$REPO/utils/py/wave_reconcile.py" --root "$REPO" --pr 4001 --offline "$REPO/manifest3.json" --skip-pull 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && pass "mention-only PR reconciles without acting on the mention" || fail "mention-only reconcile failed (rc=$rc): $out"
[ -f "$REPO/PROJECT/2-WORKING/GH-3001-OPEN.md" ] && [ ! -f "$REPO/PROJECT/3-COMPLETED/GH-3001-OPEN.md" ] \
  && pass "GH-271: unknown-state mention does NOT promote (PR #185 class blocked)" \
  || fail "GH-271: mention-only reference still promoted"
grep -q "## Merge evidence" "$REPO/PROJECT/2-WORKING/GH-3001-OPEN.md" \
  && fail "GH-271: unknown-state mention recorded evidence (should be a no-op)" \
  || pass "GH-271: unknown-state mention records nothing"

# Extraction unit checks: closing-keyword semantics, mandatory prefix, fenced code ignored
ext_fail=0
check_ext() { # <label> <want-closers> <want-mentions> <title> <body>
  local label="$1" wc_="$2" wm_="$3" title="$4" body="$5" got
  got="$(FIXTURE_PY_DIR="$REPO/utils/py" python3 - "$wc_" "$wm_" "$title" "$body" <<'PYEOF'
import sys, os, json
sys.path.insert(0, os.environ["FIXTURE_PY_DIR"])
import wave_reconcile as wr
wc_, wm_, title, body = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
closers, mentions = wr.extract_linked_issues({"title": title, "body": body})
want_c = json.loads(wc_); want_m = json.loads(wm_)
print("OK" if (closers, mentions) == (want_c, want_m) else f"BAD closers={closers} mentions={mentions}")
PYEOF
)" || { echo "  FAIL: $label (harness error: $got)"; ext_fail=1; return; }
  [ "$got" = "OK" ] && pass "$label" || { echo "  FAIL: $label -> $got"; ext_fail=1; }
}
check_ext "GH-271: 'Closes #18' links 18" '[18]' '[]' 'feat: x' 'Closes #18.'
check_ext "GH-271: comma list across spellings" '[18,19,20]' '[]' 'feat: x' 'fixes GH-18, GH-19 and resolves #20'
check_ext "GH-271: 'supersedes/unlike' are references, not links" '[]' '[18,141]' 'feat: x' 'supersedes GH-18, unlike GH-141.'
check_ext "GH-271: bare number after keyword is ignored (prefix mandatory)" '[]' '[]' 'feat: x' 'closes 5 issues today'
check_ext "GH-271: past-tense keyword case-insensitive" '[18]' '[]' 'feat: x' 'Fixed #18.'
check_ext "GH-271: trailing title tag links" '[259]' '[]' 'feat: jog Phase 1 (#259)' 'see plan'
check_ext "GH-271: fenced code blocks are ignored" '[]' '[77]' 'feat: x' '```
Closes #99
```
Advances GH-77.'
check_ext "GH-271: keyword at title end cannot capture body ref (same-line rule)" '[]' '[123]' 'fixed' '#123 started'
check_ext "GH-271: closer + mention split (the GH-202 convention)" '[271]' '[260]' 'feat: x' 'Closes GH-271. Advances GH-260 (phase 1 of 2).'
check_ext "GH-271 QA r1: URL fragments/paths are not mentions" '[]' '[]' 'feat: x' 'see https://example.com/#123 and https://example.com/GH-99 and ?#7'
check_ext "GH-271 QA r1: plain refs still count after the lookbehind" '[]' '[123, 124, 125]' 'feat: x' 'see #123 and (GH-124) and —GH-125.'
check_ext "GH-271 QA r3: and-joined refs close together" '[1, 2]' '[]' 'feat: x' 'Fixes #1 and #2.'
check_ext "GH-271 QA r3: query-string equals and amp excluded from mentions" '[]' '[]' 'feat: x' 'see https://x.test/?issue=#123 and ?a=1 and &#77'
check_ext "GH-271 QA r3: inline code in the TITLE is stripped" '[]' '[]' 'feat: `see #123` done' 'nothing here'
[ "$ext_fail" -eq 0 ] || fail "one or more GH-271 extraction unit checks failed"

# ── GH-271 Part B: rollback completeness ───────────────────────────────────────
# A mid-subprocess failure must restore the WHOLE tree: the dashboard the regen step
# rewrote, the dated plan doc marathon-plan dropped, and the docs the reconcile phase
# moved. Pre-fix, "Rolling back..." reported success over regenerated dashboards and a
# stray MARATHON-PLAN-<date>.md (observed 2026-08-23).
git -C "$REPO" add -A && git -C "$REPO" commit -qm "fixture: pre-rollback state" 2>/dev/null || true
printf 'ORIGINAL DASHBOARD\n' > "$REPO/ROADMAP-DASHBOARD.md"
git -C "$REPO" add ROADMAP-DASHBOARD.md && git -C "$REPO" commit -qm "fixture: dashboard original"
printf '#!/usr/bin/env bash\nprintf "REGENERATED DASHBOARD\\n" > "%s/ROADMAP-DASHBOARD.md"\n' "$REPO" > "$REPO/utils/roadmap-dashboard.sh"
printf '#!/usr/bin/env bash\ntouch "%s/PROJECT/2-WORKING/MARATHON-PLAN-1999-01-01.md"\necho "MOCK: marathon-plan hard failure" >&2\nexit 1\n' "$REPO" > "$REPO/utils/marathon-plan.sh"
chmod +x "$REPO/utils/roadmap-dashboard.sh" "$REPO/utils/marathon-plan.sh"
cat > "$REPO/manifest_rollback.json" <<'MANIFESTRBEOF'
{
  "prs": [
    {"number": 4001, "title": "feat: lands 3001 phase + all of 3002", "state": "MERGED",
     "mergedAt": "2026-08-24T00:00:00Z", "baseRefName": "development", "headRefName": "feat/x",
     "body": "Closes #3002. Advances GH-3001 (phase 1 of 2).", "url": "https://example/pr/4001"}
  ],
  "issues": [
    {"number": 3001, "state": "OPEN"},
    {"number": 3002, "state": "CLOSED"}
  ]
}
MANIFESTRBEOF
cat > "$REPO/PROJECT/2-WORKING/GH-3002-DONE.md" <<'DOCEOF'
---
gh_issue: 3002
title: "GH-3002"
status: In Progress
created: $TODAY
updated: $TODAY
---

# GH-3002

## Lessons Learned (For Future Agents)
- Rollback completeness fixture.
DOCEOF
git -C "$REPO" add -A && git -C "$REPO" commit -qm "fixture: rollback scenario"
out="$(python3 "$REPO/utils/py/wave_reconcile.py" --root "$REPO" --pr 4001 --offline "$REPO/manifest_rollback.json" --skip-pull 2>&1)"; rc=$?
[ "$rc" -eq 6 ] && pass "mid-subprocess failure dies with rc=6 (subprocess failure)" || fail "unexpected rc for failed reconcile (rc=$rc): $out"
grep -q "REGENERATED" "$REPO/ROADMAP-DASHBOARD.md" \
  && fail "GH-271: rollback left the regenerated dashboard behind" \
  || pass "GH-271: rollback restored the pre-run dashboard"
[ -f "$REPO/PROJECT/2-WORKING/MARATHON-PLAN-1999-01-01.md" ] \
  && fail "GH-271: rollback left the stray MARATHON-PLAN doc behind" \
  || pass "GH-271: rollback removed the stray MARATHON-PLAN doc"
[ -f "$REPO/PROJECT/2-WORKING/GH-3002-DONE.md" ] \
  && pass "GH-271: rollback restored the promoted doc to 2-WORKING" \
  || fail "GH-271: rollback left the doc promotion in place"
grep -q "Rollback INCOMPLETE" <<<"$out" \
  && fail "GH-271: rollback tripwire fired despite complete restore" \
  || pass "GH-271: rollback tripwire silent on a complete restore"
porcelain="$(git -C "$REPO" status --porcelain)"
[ -z "$porcelain" ] && pass "GH-271: porcelain empty after rollback (tree fully restored)" \
  || fail "GH-271: porcelain dirty after rollback: $porcelain"
# Positive control (Codex consult): a mutation the journal never tracked makes the tripwire
# FIRE and name the leftover — otherwise the silence above proves nothing.
git -C "$REPO" add -A >/dev/null 2>&1 || true
git -C "$REPO" commit -qm "fixture: clean base for tripwire positive control" >/dev/null 2>&1 || true
printf '#!/usr/bin/env bash\ntouch "%s/STRAY-UNTRACKED.md"\necho "MOCK: marathon-plan hard failure" >&2\nexit 1\n' "$REPO" > "$REPO/utils/marathon-plan.sh"
chmod +x "$REPO/utils/marathon-plan.sh"
git -C "$REPO" add utils/marathon-plan.sh && git -C "$REPO" commit -qm "fixture: stray-writing plan stub"
out="$(python3 "$REPO/utils/py/wave_reconcile.py" --root "$REPO" --pr 4001 --offline "$REPO/manifest_rollback.json" --skip-pull 2>&1)"; rc=$?
[ "$rc" -eq 6 ] && pass "tripwire positive-control run still dies rc=6" || fail "tripwire control rc=$rc"
grep -q "Rollback INCOMPLETE" <<<"$out" \
  && pass "GH-271 QA r3: tripwire FIRES when a restore is incomplete" \
  || fail "GH-271 QA r3: tripwire silent over an incomplete rollback"
grep -q "STRAY-UNTRACKED.md" <<<"$out" \
  && pass "  and names the exact stray path" \
  || fail "  leftover path not named: $out"
rm -f "$REPO/STRAY-UNTRACKED.md"
# restore the standard stubs for the live-gh section below
printf '#!/usr/bin/env bash\necho "MOCK: roadmap-dashboard OK"\n' > "$REPO/utils/roadmap-dashboard.sh"
printf '#!/usr/bin/env bash\necho "MOCK: marathon-plan reports items held"\nexit 5\n' > "$REPO/utils/marathon-plan.sh"
chmod +x "$REPO/utils/roadmap-dashboard.sh" "$REPO/utils/marathon-plan.sh"
rm -f "$REPO/ROADMAP-DASHBOARD.md"


# ── LIVE gh path (mock gh on PATH; no --offline) ───────────────────────────────
mkdir -p "$REPO/bin"
cat > "$REPO/bin/gh" <<'GHEOF'
#!/usr/bin/env bash
case "$1" in
  pr)
    # gh pr view 4001 --json ... -> merged PR metadata
    printf '{"number":4001,"title":"feat: lands 3001 phase + all of 3002","state":"MERGED","mergedAt":"%sT00:00:00Z","baseRefName":"development","headRefName":"feat/x","body":"Closes #3002. Advances GH-3001 (phase 1 of 2).","url":"https://example/pr/4001"}\n' "${FAKE_TODAY:-2026-08-24}"
    ;;
  issue)
    if [ "${GH_MOCK_FAIL:-0}" = "1" ]; then echo "gh: API rate limit exceeded" >&2; exit 1; fi
    printf '{"state":"OPEN"}\n'
    ;;
esac
GHEOF
chmod +x "$REPO/bin/gh"

# restore an active 3001 doc for the live tests (and clear the legacy test's promoted copy)
rm -f "$REPO/PROJECT/3-COMPLETED/GH-3001-OPEN.md"
cat > "$REPO/PROJECT/2-WORKING/GH-3001-OPEN.md" <<'DOCEOF'
---
gh_issue: 3001
title: "GH-3001"
status: In Progress
created: $TODAY
updated: $TODAY
---

# GH-3001

## Lessons Learned (For Future Agents)
- Live gh path coverage.
DOCEOF
git -C "$REPO" add -A && git -C "$REPO" commit -qm "fixture: mock gh + restored 3001" 2>/dev/null || true

# Live success: gh answers OPEN -> doc stays active with evidence
out="$(PATH="$REPO/bin:$PATH" python3 "$REPO/utils/py/wave_reconcile.py" --root "$REPO" --pr 4001 --skip-pull 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && grep -q "is OPEN" <<<"$out"   && pass "live gh OPEN answer: reconcile succeeds and keeps the doc active"   || fail "live gh OPEN path broken (rc=$rc): $out"
[ -f "$REPO/PROJECT/2-WORKING/GH-3001-OPEN.md" ] && grep -q "## Merge evidence" "$REPO/PROJECT/2-WORKING/GH-3001-OPEN.md"   && pass "live gh OPEN answer: merge evidence recorded" || fail "live path: no evidence"

# Live failure: gh errors -> reconcile DIES, doc untouched (fail-closed, no blind promotion)
git -C "$REPO" add -A && git -C "$REPO" commit -qm "fixture: post-live-success" 2>/dev/null || true
out="$(GH_MOCK_FAIL=1 PATH="$REPO/bin:$PATH" python3 "$REPO/utils/py/wave_reconcile.py" --root "$REPO" --pr 4001 --skip-pull 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && grep -q "refusing to guess issue state" <<<"$out"   && pass "live gh FAILURE: reconcile dies loudly instead of promoting blindly (fail-closed)"   || fail "live gh failure was swallowed (rc=$rc): $out"
[ -f "$REPO/PROJECT/2-WORKING/GH-3001-OPEN.md" ] && [ ! -f "$REPO/PROJECT/3-COMPLETED/GH-3001-OPEN.md" ]   && pass "live gh FAILURE: no mis-promotion occurred" || fail "live gh failure caused mis-promotion"

echo "  gh202-wave-reconcile-issue-state: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
