#!/usr/bin/env bash
# GH-153: regression lock for the RELEASES dashboard sidebar + full-cycle rollup spike.
#
# Pins three surfaces, all additive by design:
#   (1) utils/py/releases_cycle.py — the shared module: JSON contract, markdown sections,
#       exit 2 on missing/corrupt DB (rollup.sh degrades per repo on that code);
#   (2) utils/timeline/export_timeline.py — ships the additive payload keys (projects, cycle,
#       meta.repoUrl) and bakes the sidebar chrome into BOTH artifacts from the one template;
#   (3) utils/timeline/RELEASES.html — the three nav states (expanded/rail/hidden), the
#       non-link placeholders, and the boot()-side __snCycle hook that fills the panel.
# The rollup.sh embed path (verbatim + demoted + failure-visible) is pinned by
# test/hq-rollup.sh Cases A/F/G — deliberately not duplicated here.
#
# Negative controls: pre-GH-153 the exporter payload had no cycle/projects keys, the template
# had no #sidenav, and releases_cycle.py did not exist — every "MISS" below was the old state.

set -uo pipefail
# strict-mode: -e exempt — assertion-style test with expected-nonzero probes handled explicitly.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
CYCLE="$ROOT/utils/py/releases_cycle.py"
EXPORTER="$ROOT/utils/timeline/export_timeline.py"
TEMPLATE="$ROOT/utils/timeline/RELEASES.html"

# shellcheck source=test/lib/fixture-guard.sh
. "$ROOT/test/lib/fixture-guard.sh"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh153.XXXXXX")"
fixture_guard_init "$WORK"
trap 'rm -rf "$WORK"' EXIT

PASS=0
FAIL=0
pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }

echo "== test: gh153-releases-sidebar-rollup =="
echo "  workdir: $WORK"

# The repo's own committed ledger is the fixture — copied into the sandbox, never touched in place.
DB="$WORK/releases.db"
cp "$ROOT/releases.db" "$DB"
require_fixture_file "$DB" "ledger fixture"

echo "-- module: JSON contract against a real ledger copy --"
JSON_OUT="$("$CYCLE" --db "$DB" --json)"
rc=$?
[ "$rc" -eq 0 ] && pass "cycle module exits 0 on a real ledger (invoked via exec bit, as rollup.sh does)" \
  || fail "cycle module rc=$rc on a real ledger"
if python3 - "$JSON_OUT" <<'PY'
import json, sys
s = json.loads(sys.argv[1])
assert {"repo", "generatedAt", "db", "releases", "roadmap", "marathons", "items",
        "recentEvents"} <= set(s), sorted(s)
assert {"total", "open", "overdue", "byStatus", "openList", "recentShipped"} <= set(s["releases"])
assert {"wip", "queued", "done", "paused", "total"} <= set(s["roadmap"])
assert {"dialedIn", "shipped", "cut", "open"} <= set(s["items"])
assert isinstance(s["db"]["generation"], int) and s["db"]["receipts"] >= 0
assert s["releases"]["total"] == sum(s["releases"]["byStatus"].values()), "total != sum(byStatus)"
assert s["marathons"]["total"] == sum(s["marathons"]["byStatus"].values())
PY
then pass "JSON shape: all sections present, counts internally consistent"
else fail "JSON shape mismatch (see python traceback above)"
fi

echo "-- module: markdown render + repo-label override --"
MD_OUT="$("$CYCLE" --db "$DB" --repo-label SPIKE-REPO)"
rc=$?
[ "$rc" -eq 0 ] && pass "markdown render exits 0" || fail "markdown render rc=$rc"
for heading in "# RELEASES cycle — SPIKE-REPO" \
               "## Releases — " "## Roadmap shadow — " "## Marathons — " \
               "## Manifest outcomes" "## Latest state events"; do
  grep -q "$heading" <<<"$MD_OUT" \
    && pass "markdown section present: $heading" \
    || fail "markdown section missing: $heading"
done

echo "-- module: exit 2 on missing / corrupt DB (rollup.sh degrades on this code) --"
"$CYCLE" --db "$WORK/no-such.db" >/dev/null 2>"$WORK/missing.err"
rc=$?
[ "$rc" -eq 2 ] && pass "missing DB -> exit 2" || fail "missing DB -> rc=$rc (want 2)"
grep -q "no releases DB" "$WORK/missing.err" \
  && pass "missing DB names the path on stderr" || fail "missing DB stderr silent"

printf 'definitely not a sqlite database\n' > "$WORK/corrupt.db"
"$CYCLE" --db "$WORK/corrupt.db" >/dev/null 2>"$WORK/corrupt.err"
rc=$?
[ "$rc" -eq 2 ] && pass "corrupt DB -> exit 2" || fail "corrupt DB -> rc=$rc (want 2)"
grep -q "releases_cycle:" "$WORK/corrupt.err" \
  && pass "corrupt DB explains itself on stderr" || fail "corrupt DB stderr silent"
rm -f "$WORK/corrupt.db"

echo "-- exporter: additive payload keys --"
EXPORT_JSON="$(python3 "$EXPORTER" --db "$DB" --json)"
rc=$?
[ "$rc" -eq 0 ] && pass "exporter --json exits 0 with the cycle import in place" \
  || fail "exporter --json rc=$rc"
if python3 - "$EXPORT_JSON" <<'PY'
import json, sys
d = json.loads(sys.argv[1])
assert "cycle" in d and "projects" in d, sorted(d)
assert d["meta"]["repoUrl"] and d["meta"]["repoUrl"].startswith("https://github.com/")
assert any(p["slug"] == "XYZ-forge" and p["active"] for p in d["projects"]), d["projects"]
assert d["cycle"]["releases"]["total"] >= 1
PY
then pass "payload carries projects + cycle + meta.repoUrl, values sane"
else fail "payload keys missing/wrong (see python traceback above)"
fi

echo "-- exporter: sidebar chrome baked into BOTH artifacts from the one template --"
PREVIEW="$WORK/RELEASES-PREVIEW.html"
LEADER="$WORK/LEADERBOARD.html"
python3 "$EXPORTER" --db "$DB" --preview "$PREVIEW" >/dev/null \
  && pass "preview bake exits 0" || fail "preview bake failed"
python3 "$EXPORTER" --db "$DB" --leaderboard "$LEADER" >/dev/null \
  && pass "leaderboard bake exits 0" || fail "leaderboard bake failed"
require_fixture_file "$PREVIEW" "baked preview"
require_fixture_file "$LEADER" "baked leaderboard"

MARKERS=('id="sidenav-toggle"'      # hamburger — the slideout control
         'id="sidenav"'             # the nav itself
         'id="sn-project"'          # project switcher
         'id="sn-min"'              # minimize-to-rail chevron
         'data-snfocus="rel"'       # focus items wired to the #fbar buttons
         'class="sn-item sn-ph"'    # NON-LINK placeholders (no fake hrefs)
         '__snCycle'                # boot()-side hook filling the panel
         'data-sn="expanded"'       # default ON
         'id="ledger-data"')        # the pre-existing inline payload survives the injection
for f in "$PREVIEW" "$LEADER"; do
  fname="$(basename "$f")"
  for m in "${MARKERS[@]}"; do
    grep -q "$m" "$f" \
      && pass "$fname: $m" \
      || fail "$fname: MISSING $m"
  done
done

echo "-- template: states + placeholders are source-level facts --"
for pat in 'body\[data-sn="rail"\]' 'body\[data-sn="hidden"\]' 'placeholder — no destination yet' \
           'localStorage.setItem(KEY,state)' 'window.__snCycle=function(data)'; do
  grep -q "$pat" "$TEMPLATE" \
    && pass "template carries: $pat" \
    || fail "template missing: $pat"
done

echo "== gh153-releases-sidebar-rollup: $PASS passed, $FAIL failed =="
[ "$FAIL" -eq 0 ]
