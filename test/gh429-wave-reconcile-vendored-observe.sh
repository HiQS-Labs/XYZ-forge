#!/usr/bin/env bash
# GH-429 (HiQS-Labs/XYZ-forge#429): three residual gaps that kept wave_reconcile from completing a
# LIVE run on a vendored, observe-mode consumer (BinoidCBD/LTVera-Pandas, 2026-09-03, at head bc49850):
#   1. roadmap-dashboard.sh derives ROOT one level too shallow when vendored (lands on <repo>/.xyz)
#      → the reconciler now passes ROADMAP_DASHBOARD_ROOT=<repo> to every downstream step.
#   2. run_validation_gate died on `"ERROR" in stdout` even when pdda.sh exited 0 — pdda-lib.sh makes
#      observe/light exit 0 BY DESIGN, so the grep overrode the repo's declared mode → block on the
#      exit status only; warn on the reported count.
#   3. `Closes https://github.com/<org>/<repo>/issues/N` (honoured by GitHub) was not a closing ref
#      → accepted for the ORIGIN slug only; a foreign repo's URL stays a mention.
# Fixture is a vendored layout (copied from gh358): the reconciler and its tools live under $REPO/.xyz,
# pdda.sh is the TARGET repo's own tool at $REPO/utils/pdda/pdda.sh. Stubs drop marker FILES.
source "$(dirname "$0")/_setup.sh" gh429-wave-reconcile-vendored-observe
XYZ_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0; FAIL=0
pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }
echo "== test: gh429-wave-reconcile-vendored-observe =="
WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh429-reconcile.XXXXXX")"
cleanup() { [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
trap cleanup EXIT
. "$(dirname "$0")/lib/fixture-guard.sh"
TODAY="$(date +%Y-%m-%d)"
fixture_guard_init "$WORK"

# build_fixture <dir> <pr-body> <pdda-exit> — a vendored consumer repo with one active doc GH-4291.
build_fixture() {
  local REPO="$1" BODY="$2" PDDA_EXIT="$3" RAN="$1.ran"
  mkdir -p "$REPO" "$RAN"
  git -C "$REPO" init -q -b development
  git -C "$REPO" config user.email t@t; git -C "$REPO" config user.name t
  git -C "$REPO" remote add origin https://github.com/HiQS-Labs/XYZ-forge.git
  printf '/.xyz/\n/.tick/\n' >> "$REPO/.gitignore"
  mkdir -p "$REPO/PROJECT/2-WORKING" "$REPO/PROJECT/3-COMPLETED" "$REPO/PROJECT/4-MISC" \
    "$REPO/TESTS-RESULTS/$TODAY" "$REPO/utils/pdda" "$REPO/.xyz/utils/py" "$REPO/.xyz/utils/timeline"
  cp "$XYZ_ROOT/utils/py/wave_reconcile.py" "$XYZ_ROOT/utils/py/harness_paths.py" "$REPO/.xyz/utils/py/"
  printf '#!/usr/bin/env python3\npass\n' > "$REPO/.xyz/utils/py/releases_app.py"
  # The dashboard stub records the root it was HANDED — the primitive section 1 asserts on.
  printf '#!/usr/bin/env bash\nprintf "%%s" "${ROADMAP_DASHBOARD_ROOT:-UNSET}" > "%s/dashboard-root"\n' "$RAN" \
    > "$REPO/.xyz/utils/roadmap-dashboard.sh"
  printf '#!/usr/bin/env python3\npass\n' > "$REPO/.xyz/utils/timeline/export_timeline.py"
  printf '#!/usr/bin/env bash\nexit 0\n' > "$REPO/.xyz/utils/marathon-plan.sh"
  # An observe-mode pdda: findings on stdout, exit status per the repo's mode.
  printf '#!/usr/bin/env bash\necho "ERROR [pdda-check-frontmatter] PROJECT/x.md:1 missing field"\necho "PDDA run complete: 3 error(s) found, not blocking in observe mode"\nexit %s\n' "$PDDA_EXIT" \
    > "$REPO/utils/pdda/pdda.sh"
  chmod +x "$REPO"/.xyz/utils/py/*.py "$REPO"/.xyz/utils/*.sh "$REPO/.xyz/utils/timeline/export_timeline.py" "$REPO/utils/pdda/pdda.sh"
  cat > "$REPO/ROADMAP.md" <<'ROADMAPEOF'
# Test Roadmap

### In progress
- **GH-4291 · Observe-mode reconcile** 🚧 **active** — rated 80/80/80/80. → [GH-4291-OBSERVE.md](PROJECT/2-WORKING/GH-4291-OBSERVE.md) · [#4291](https://github.com/HiQS-Labs/XYZ-forge/issues/4291)

### Completed
ROADMAPEOF
  cat > "$REPO/PROJECT/2-WORKING/GH-4291-OBSERVE.md" <<DOCEOF
---
gh_issue: 4291
title: "GH-4291"
status: In Progress
created: $TODAY
updated: $TODAY
---

# GH-4291

## Lessons Learned (For Future Agents)
- The exit status is the mode; the stdout is the report.
DOCEOF
  echo '{"status": "PASS"}' > "$REPO/TESTS-RESULTS/$TODAY/provenance.jsonl"
  python3 - "$REPO/manifest.json" "$BODY" <<'PY'
import json, sys
json.dump({"prs": [{"number": 5291, "title": "feat: observe-mode reconcile", "state": "MERGED",
                    "mergedAt": "2026-09-03T00:00:00Z", "baseRefName": "development",
                    "headRefName": "feat/o", "body": sys.argv[2], "url": "https://example/pr/5291"}],
           "issues": [{"number": 4291, "state": "CLOSED"}]}, open(sys.argv[1], "w"))
PY
  git -C "$REPO" add -A && git -C "$REPO" commit -qm "fixture" 
  require_fixture_file "$REPO/manifest.json" "manifest"
}

run_reconcile() { python3 "$1/.xyz/utils/py/wave_reconcile.py" --root "$1" --pr 5291 --offline "$1/manifest.json" --skip-pull 2>&1; }

echo "-- section 1+2: observe-mode pdda (findings, exit 0) no longer kills a live run; dashboard gets the repo root --"
R1="$WORK/repo-observe"; build_fixture "$R1" "Closes #4291." 0
out="$(run_reconcile "$R1")"; rc=$?
[ "$rc" -eq 0 ] && pass "live reconcile exits 0 with an observe-mode backlog" || fail "live reconcile exited $rc: $out"
grep -q "WARNING — pdda reported 3 finding(s) but exited 0" <<<"$out" \
  && pass "the findings are surfaced as a warning with their count" || fail "no warning with the count: $out"
grep -q "PDDA validation gate failed" <<<"$out" && fail "gate still died on stdout" || pass "gate did not die on stdout"
[ -f "$R1/PROJECT/3-COMPLETED/GH-4291-OBSERVE.md" ] && pass "doc promoted to 3-COMPLETED" || fail "doc not promoted"
# Compare normalised paths: $TMPDIR may carry a trailing slash, and the reconciler abspath()s --root.
want="$(python3 -c 'import os,sys; print(os.path.abspath(sys.argv[1]))' "$R1")"
[ "$(cat "$R1.ran/dashboard-root" 2>/dev/null)" = "$want" ] \
  && pass "roadmap-dashboard.sh received ROADMAP_DASHBOARD_ROOT=<repo root>" \
  || fail "dashboard root was '$(cat "$R1.ran/dashboard-root" 2>/dev/null)', expected '$want'"

echo "-- section 2 negative control: a FULL-mode pdda (exit 1) still blocks and rolls back --"
R2="$WORK/repo-full"; build_fixture "$R2" "Closes #4291." 1
out="$(run_reconcile "$R2")"; rc=$?
[ "$rc" -eq 7 ] && pass "non-zero pdda exit → reconciler exit 7" || fail "expected exit 7, got $rc: $out"
grep -q "PDDA validation gate failed" <<<"$out" && pass "gate names the failure" || fail "no gate failure message"
[ -f "$R2/PROJECT/2-WORKING/GH-4291-OBSERVE.md" ] && pass "doc move rolled back" || fail "doc move was not rolled back"

echo "-- section 3: a closing keyword + the ORIGIN repo's issue URL is a closer --"
R3="$WORK/repo-url"; build_fixture "$R3" "Closes https://github.com/HiQS-Labs/XYZ-forge/issues/4291 — the mock harness." 0
out="$(run_reconcile "$R3")"; rc=$?
[ "$rc" -eq 0 ] && pass "URL-form reconcile exits 0" || fail "exit $rc: $out"
grep -q "closes \[4291\]" <<<"$out" && pass "PR body URL form parsed as closes [4291]" || fail "URL form not a closer: $(grep 'closes' <<<"$out")"
[ -f "$R3/PROJECT/3-COMPLETED/GH-4291-OBSERVE.md" ] && pass "doc promoted from the URL form" || fail "doc not promoted from URL form"

echo "-- section 3 negative control: a FOREIGN repo's issue URL stays a mention --"
R4="$WORK/repo-foreign"; build_fixture "$R4" "Closes https://github.com/other-org/other-repo/issues/4291." 0
out="$(run_reconcile "$R4")"; rc=$?
grep -q "closes \[\]" <<<"$out" && pass "foreign URL is not a closer" || fail "foreign URL treated as closer: $(grep 'closes' <<<"$out")"
[ -f "$R4/PROJECT/2-WORKING/GH-4291-OBSERVE.md" ] && pass "doc stays active on a foreign URL" || fail "doc wrongly promoted on a foreign URL"

echo "-- unit: slug helper and the extractor --"
unit="$(cd "$R3" && python3 - <<'PY'
import sys, os
sys.path.insert(0, os.path.join(os.getcwd(), ".xyz", "utils", "py"))
import wave_reconcile as wr, harness_paths as hp
print("SLUG:", hp.github_slug_from_origin(os.getcwd()))
c, m = wr.extract_linked_issues({"title": "t", "body": "Fixes: https://github.com/HiQS-Labs/XYZ-forge/issues/12 and closes #13"}, repo_slug="hiqs-labs/xyz-forge")
print("CLOSERS:", c, "MENTIONS:", m)
c2, m2 = wr.extract_linked_issues({"title": "t", "body": "Closes https://github.com/HiQS-Labs/XYZ-forge/issues/12"})
print("NOSLUG:", c2, m2)
PY
)"
grep -q "SLUG: HiQS-Labs/XYZ-forge" <<<"$unit" && pass "github_slug_from_origin reads the origin slug" || fail "slug: $unit"
grep -q "CLOSERS: \[12, 13\]" <<<"$unit" && pass "URL form (case-insensitive slug) and #N combine" || fail "extractor: $unit"
grep -q "NOSLUG: \[\] \[\]" <<<"$unit" && pass "without a slug the URL form is neither closer nor mention (unchanged contract)" || fail "noslug: $unit"

echo
echo "gh429-wave-reconcile-vendored-observe: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
