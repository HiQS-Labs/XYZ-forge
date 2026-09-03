#!/usr/bin/env bash
# NOTE ON THE NUMBER: test/gh358-lock-instrumentation.sh already carries a "GH-358" from the
# pre-rename numbering (nothing by that number is in this repo's ROADMAP.md). This suite is
# HiQS-Labs/XYZ-forge#358. The filenames are distinct; neither is renumbered, because renaming
# a green suite to tidy a comment is churn that costs more history than it buys clarity.
#
# GH-358: wave_reconcile resolved all five HARNESS tools repo-root-relative, so on a vendored
# (Tier 2) install — where they exist only under <repo>/.xyz/ — every one was unreachable and the
# reconciler died on its first downstream step with:
#   python3: can't open file '<repo>/utils/py/releases_app.py': [Errno 2] No such file or directory
# Observed in BinoidCBD/LTVera-Pandas against .xyz source_commit 6d23ac86 (2026-09-01).
#
# The fixture is a VENDORED layout on purpose: the harness lives at $REPO/.xyz and the target repo
# carries none of the five tools. Section 2 is the other half of the fix and matters just as much —
# utils/pdda/pdda.sh is a TARGET-repo tool, so a blanket .xyz/ prefix would have pointed the
# doc-hygiene gate at the harness instead of the repository under reconciliation.
source "$(dirname "$0")/_setup.sh" gh358-wave-reconcile-vendored-paths
XYZ_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

PASS=0; FAIL=0
pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "== test: gh358-wave-reconcile-vendored-paths =="

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh358-reconcile.XXXXXX")"
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

# ── Vendored layout: harness under .xyz/, target repo owns only its OWN tools (pdda).
printf '/.xyz/\n/.tick/\n' >> "$REPO/.gitignore"
mkdir -p "$REPO/PROJECT/2-WORKING" "$REPO/PROJECT/3-COMPLETED" "$REPO/PROJECT/4-MISC" \
  "$REPO/TESTS-RESULTS/$TODAY" "$REPO/utils/pdda" \
  "$REPO/.xyz/utils/py" "$REPO/.xyz/utils/timeline"
cp "$XYZ_ROOT/utils/py/wave_reconcile.py" "$XYZ_ROOT/utils/py/harness_paths.py" "$REPO/.xyz/utils/py/"
require_fixture_file "$REPO/.xyz/utils/py/wave_reconcile.py" "vendored-reconciler-copy"

# The five harness tools exist ONLY under .xyz — this is the whole point of the fixture.
# Each mock drops a marker FILE, not a log line: wave_reconcile captures subprocess stdout and
# does not echo it on success, so asserting on the reconciler's own output would silently pass
# whether or not the tool ever ran. A file on disk is the primitive that cannot be faked.
RAN="$WORK/ran"
mkdir -p "$RAN"
printf '#!/usr/bin/env python3\nimport os\nopen(os.path.join(%s, "releases_app-xyz"), "w").close()\n' \
  "\"$RAN\"" > "$REPO/.xyz/utils/py/releases_app.py"
printf '#!/usr/bin/env bash\ntouch "%s/dashboard-xyz"\n' "$RAN" > "$REPO/.xyz/utils/roadmap-dashboard.sh"
printf '#!/usr/bin/env python3\nimport os\nopen(os.path.join(%s, "timeline-xyz"), "w").close()\n' \
  "\"$RAN\"" > "$REPO/.xyz/utils/timeline/export_timeline.py"
printf '#!/usr/bin/env bash\ntouch "%s/marathon-plan-xyz"\nexit 0\n' "$RAN" > "$REPO/.xyz/utils/marathon-plan.sh"
chmod +x "$REPO/.xyz/utils/py/releases_app.py" "$REPO/.xyz/utils/roadmap-dashboard.sh" \
  "$REPO/.xyz/utils/timeline/export_timeline.py" "$REPO/.xyz/utils/marathon-plan.sh"
for missing in utils/py/releases_app.py utils/roadmap-dashboard.sh \
               utils/timeline/export_timeline.py utils/marathon-plan.sh; do
  [ -e "$REPO/$missing" ] && { echo "FIXTURE BROKEN: $missing must NOT exist at the repo root"; exit 1; }
done

# PDDA is the TARGET repo's own tool. The decoy under .xyz must never be the one that runs.
printf '#!/usr/bin/env bash\ntouch "%s/pdda-repo"\n' "$RAN" > "$REPO/utils/pdda/pdda.sh"
mkdir -p "$REPO/.xyz/utils/pdda"
printf '#!/usr/bin/env bash\ntouch "%s/pdda-xyz-DECOY"\n' "$RAN" > "$REPO/.xyz/utils/pdda/pdda.sh"
chmod +x "$REPO/utils/pdda/pdda.sh" "$REPO/.xyz/utils/pdda/pdda.sh"

cat > "$REPO/ROADMAP.md" <<'ROADMAPEOF'
# Test Roadmap

### In progress
- **GH-3581 · Vendored reconcile** 🚧 **active** — rated 80/80/80/80. → [GH-3581-VENDORED.md](PROJECT/2-WORKING/GH-3581-VENDORED.md) · [#3581](https://github.com/HiQS-Labs/XYZ-forge/issues/3581)

### Completed
ROADMAPEOF

cat > "$REPO/PROJECT/2-WORKING/GH-3581-VENDORED.md" <<DOCEOF
---
gh_issue: 3581
title: "GH-3581"
status: In Progress
created: $TODAY
updated: $TODAY
---

# GH-3581

## Lessons Learned (For Future Agents)
- A harness tool resolves against the harness home; a repo tool resolves against the repo.
DOCEOF

echo '{"status": "PASS"}' > "$REPO/TESTS-RESULTS/$TODAY/provenance.jsonl"

cat > "$REPO/manifest.json" <<'MANIFESTEOF'
{
  "prs": [
    {"number": 4581, "title": "feat: vendored reconcile", "state": "MERGED",
     "mergedAt": "2026-09-01T00:00:00Z", "baseRefName": "development", "headRefName": "feat/v",
     "body": "Closes #3581.", "url": "https://example/pr/4581"}
  ],
  "issues": [{"number": 3581, "state": "CLOSED"}]
}
MANIFESTEOF

git -C "$REPO" add -A && git -C "$REPO" commit -qm "fixture: vendored layout, stubs, manifest"
require_fixture_file "$REPO/manifest.json" "manifest"

out="$(python3 "$REPO/.xyz/utils/py/wave_reconcile.py" --root "$REPO" --pr 4581 \
        --offline "$REPO/manifest.json" --skip-pull 2>&1)"; rc=$?

echo "-- section 1: the five harness tools resolve under .xyz --"
[ "$rc" -eq 0 ] && pass "vendored reconcile exits 0" || fail "vendored reconcile exited $rc: $out"
grep -q "can't open file" <<<"$out" \
  && fail "a tool was still resolved against the repo root: $(grep "can't open file" <<<"$out")" \
  || pass "no 'can't open file' — every harness tool was found"
[ -f "$RAN/releases_app-xyz" ] && pass "releases_app ran from .xyz" || fail "releases_app did not run from .xyz"
[ -f "$RAN/dashboard-xyz" ] && pass "roadmap-dashboard ran from .xyz" || fail "roadmap-dashboard did not run from .xyz"
[ -f "$RAN/timeline-xyz" ] && pass "export_timeline ran from .xyz" || fail "export_timeline did not run from .xyz"
[ -f "$RAN/marathon-plan-xyz" ] && pass "marathon-plan ran from .xyz" || fail "marathon-plan did not run from .xyz"

echo "-- section 2: PDDA is a TARGET-repo tool and must NOT be redirected into .xyz --"
[ -f "$RAN/pdda-repo" ] && pass "pdda gate ran from the repo root" || fail "pdda gate did not run from the repo root"
[ -f "$RAN/pdda-xyz-DECOY" ] && fail "pdda gate was wrongly redirected into .xyz" || pass "harness pdda decoy never ran"

echo "-- section 3: a canonical (non-vendored) checkout still prefers its own tools --"
CANON="$WORK/canonical-repo"
mkdir -p "$CANON/utils/py" "$CANON/utils/timeline" "$CANON/utils/pdda"
cp "$XYZ_ROOT/utils/py/wave_reconcile.py" "$XYZ_ROOT/utils/py/harness_paths.py" "$CANON/utils/py/"
printf '#!/usr/bin/env python3\npass\n' > "$CANON/utils/py/releases_app.py"
chmod +x "$CANON/utils/py/releases_app.py"
canon_out="$(cd "$CANON" && python3 - <<'PY'
import sys, os
sys.path.insert(0, os.path.join(os.getcwd(), "utils", "py"))
import wave_reconcile as wr
print("RESOLVED:", wr.harness_tool(os.getcwd(), "utils/py/releases_app.py"))
PY
)"
grep -q "RESOLVED: utils/py/releases_app.py" <<<"$canon_out" \
  && pass "repo-owned tool stays repo-relative (mock seam + canonical checkout preserved)" \
  || fail "repo-owned tool was not preferred: $canon_out"

echo
echo "  gh358: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
