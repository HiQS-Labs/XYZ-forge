#!/usr/bin/env bash
# GH-693 — "## Lessons Learned (For Future Agents)" is highly recommended, never a promotion gate.
#
# From GH-165 (2026-08-22) to GH-693 the reconciler refused a merged doc without the section: the
# explicit landing died exit 5, --pre-merge counted it as a doc-contract failure (GH-496), and the
# hosted catch-up path skipped the backlog item and re-reported it every run (GH-684 → #691). The
# operator demoted it: say it loudly, promote anyway. This suite pins every one of those paths —
# and its negative control keeps the frontmatter schema mandatory, so "advisory" cannot leak.
#
# Red-before: on the parent of the GH-693 commit, Test A exits 5 and Test C exits 5.
source "$(dirname "$0")/_setup.sh" gh693-lessons-learned-advisory
XYZ_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RECONCILE_PY="$XYZ_ROOT/utils/py/wave_reconcile.py"

mkfixture() {  # <dir> <doc body after frontmatter>  -> a minimal reconcilable repo with one merged landing
  local d="$1" body="$2"
  mkdir -p "$d/PROJECT/2-WORKING" "$d/PROJECT/3-COMPLETED" "$d/PROJECT/4-MISC" "$d/utils/py" "$d/utils/pdda" "$d/utils/timeline" "$d/TESTS-RESULTS/2026-09-18"
  git -C "$d" init -q -b development
  git -C "$d" config user.name t; git -C "$d" config user.email t@t
  cp "$RECONCILE_PY" "$XYZ_ROOT/utils/py/harness_paths.py" "$d/utils/py/"
  cat > "$d/ROADMAP.md" <<'R'
# Roadmap

### In progress
- **GH-999 · Test Feature** 🚧 **active 2026-09-18** — fixture. rated 80/80/80/80. → [GH-999-TEST.md](PROJECT/2-WORKING/GH-999-TEST.md) · [#999](https://github.com/HiQS-Labs/XYZ-forge/issues/999)

### Completed
R
  printf -- '---\ngh_issue: 999\ntitle: "GH-999: Test Feature"\nstatus: In Progress\ncreated: 2026-09-18\nupdated: 2026-09-18\nowner: fixture\ngoal: fixture\n---\n# GH-999: Test Feature\n%s\n' "$body" > "$d/PROJECT/2-WORKING/GH-999-TEST.md"
  echo '{"pr": 1001, "status": "PASS", "trials": 1}' > "$d/TESTS-RESULTS/2026-09-18/provenance.jsonl"
  cat > "$d/manifest.json" <<'M'
{"prs": [{"number": 1001, "title": "feat: GH-999", "state": "MERGED", "mergedAt": "2026-09-18T00:00:00Z",
          "baseRefName": "development", "headRefName": "feat/gh999", "body": "Closes #999"}]}
M
  # Downstream mocks (same shape as test/wave-reconcile.sh): the suite pins the doc gate, not the ledger.
  local m
  for m in utils/py/releases_app.py utils/timeline/export_timeline.py; do
    printf '#!/usr/bin/env python3\nprint("MOCK OK")\n' > "$d/$m"; chmod +x "$d/$m"
  done
  for m in utils/roadmap-dashboard.sh utils/marathon-plan.sh utils/leaderboard.sh utils/pdda/pdda.sh; do
    printf '#!/usr/bin/env bash\necho "MOCK OK"\nexit 0\n' > "$d/$m"; chmod +x "$d/$m"
  done
  git -C "$d" add -A && git -C "$d" commit -q -m fixture
}

reconcile() {  # <dir> <args...>
  local d="$1"; shift
  python3 "$d/utils/py/wave_reconcile.py" --root "$d" --offline "$d/manifest.json" --skip-pull "$@" 2>&1
}

# --- A: explicit landing, no section at all -> WARN, promoted, exit 0 (was die exit 5) -------------
A="$WORK/a"; mkfixture "$A" "No lessons section here."
set +e; out="$(reconcile "$A" --pr 1001)"; rc=$?; set -e
[ "$rc" = 0 ] && pass "A: explicit landing without the section exits 0" || fail "A: exit $rc — $out"
grep -q "wave-reconcile: WARN — Doc GH-999-TEST.md has no '## Lessons Learned (For Future Agents)' section" <<<"$out" \
  && pass "A: WARN names the doc and the missing section" || fail "A: no WARN line — $out"
grep -q "Highly recommended, not required (GH-693) — promotion proceeds" <<<"$out" \
  && pass "A: WARN says the section is recommended, not required" || fail "A: WARN wording missing — $out"
[ -f "$A/PROJECT/3-COMPLETED/GH-999-TEST.md" ] && [ ! -f "$A/PROJECT/2-WORKING/GH-999-TEST.md" ] \
  && pass "A: doc promoted to 3-COMPLETED without the section" || fail "A: doc was not promoted"
grep -q "status: Complete" "$A/PROJECT/3-COMPLETED/GH-999-TEST.md" \
  && pass "A: promoted doc's status is Complete" || fail "A: status not updated"

# --- B: explicit landing, placeholder body -> WARN (placeholder), promoted -------------------------
B="$WORK/b"; mkfixture "$B" $'## Lessons Learned (For Future Agents)\n- TODO\n<!-- none yet -->'
set +e; out="$(reconcile "$B" --pr 1001)"; rc=$?; set -e
[ "$rc" = 0 ] && pass "B: placeholder section exits 0" || fail "B: exit $rc — $out"
grep -q "WARN — Doc GH-999-TEST.md has empty/placeholder '## Lessons Learned' section" <<<"$out" \
  && pass "B: WARN cites the placeholder body" || fail "B: no placeholder WARN — $out"
[ -f "$B/PROJECT/3-COMPLETED/GH-999-TEST.md" ] && pass "B: doc promoted" || fail "B: doc not promoted"

# --- C: --pre-merge, no section -> WARN, not a doc-contract failure (was exit 5) --------------------
C="$WORK/c"; mkfixture "$C" "No lessons section here."
# --pre-merge reads the doc contract for docs in the PR and the committed receipt at HEAD; mirror the
# GH-496 fixture shape (receipt committed for HEAD) so the only variable is the section.
sha="$(git -C "$C" rev-parse HEAD)"
printf '{"commit": "%s", "status": "PASS"}\n' "$sha" >> "$C/TESTS-RESULTS/2026-09-18/provenance.jsonl"
git -C "$C" add -A && git -C "$C" commit -q -m "fix: closes #999 (receipt)" >/dev/null 2>&1 || true
set +e; out="$(python3 "$C/utils/py/wave_reconcile.py" --root "$C" --pre-merge 2>&1)"; rc=$?; set -e
[ "$rc" != 5 ] && pass "C: --pre-merge does not fail the doc contract over the section (exit $rc, not 5)" \
  || fail "C: --pre-merge still exits 5 — $out"
grep -q "WARN — Doc GH-999-TEST.md has no '## Lessons Learned" <<<"$out" \
  && pass "C: --pre-merge prints the WARN" || fail "C: no WARN in --pre-merge — $out"
! grep -q "missing mandatory" <<<"$out" && pass "C: the word 'mandatory' is gone from the reconciler's output" \
  || fail "C: output still calls the section mandatory"

# --- D: catch-up path -> no SKIPPED line, promoted (was SKIPPED + re-reported every run, GH-684) ----
# Exercised in-process by test/gh421-auto-wave-reconcile.sh (test_catch_up_promotes_a_lessons_less_backlog_doc_with_a_warning);
# here the CLI-level pin: the SKIP marker never appears for a lessons-less doc on an explicit run either.
! grep -q "SKIPPED" <<<"$(reconcile "$WORK/a" --pr 1001 --dry-run 2>&1 || true)" \
  && pass "D: no SKIPPED marker for a lessons-less doc" || fail "D: SKIPPED marker emitted"

# --- E: negative control — frontmatter stays mandatory on --pre-merge (exit 5) ----------------------
E="$WORK/e"; mkfixture "$E" $'## Lessons Learned (For Future Agents)\n- real reflection'
python3 - "$E/PROJECT/2-WORKING/GH-999-TEST.md" <<'PY'
import sys,re; p=sys.argv[1]; s=open(p).read(); open(p,'w').write(re.sub(r'^goal: .*\n','',s,flags=re.M))
PY
git -C "$E" add -A && git -C "$E" commit -q -m "fix: closes #999 (goal dropped)"
set +e; out="$(python3 "$E/utils/py/wave_reconcile.py" --root "$E" --pre-merge 2>&1)"; rc=$?; set -e
[ "$rc" = 5 ] && pass "E: control — missing frontmatter 'goal' still fails the doc contract (exit 5)" \
  || fail "E: control broke — frontmatter no longer mandatory (exit $rc) — $out"
grep -q "frontmatter missing required field(s): goal" <<<"$out" \
  && pass "E: control — the error names the missing field" || fail "E: control — error text missing — $out"

# --- F: the detector still detects (the WARN is not a no-op) ----------------------------------------
python3 - "$RECONCILE_PY" <<'PY'
import importlib.util, os, sys
sys.path.insert(0, os.path.dirname(sys.argv[1]))   # harness_paths sits beside the reconciler
spec = importlib.util.spec_from_file_location("wr", sys.argv[1]); wr = importlib.util.module_from_spec(spec); spec.loader.exec_module(wr)
assert wr.validate_lessons_learned("# x\n", "d.md").startswith("Doc d.md has no '## Lessons Learned")
assert wr.validate_lessons_learned("# x\n## Lessons Learned\n- TODO\n", "d.md").startswith("Doc d.md has empty/placeholder")
assert wr.validate_lessons_learned("# x\n## Lessons Learned\n- a real one\n", "d.md") is None
assert wr.WARN_MARKER == "WARN — "
print("ok")
PY
[ $? = 0 ] && pass "F: detector distinguishes missing / placeholder / substantive; WARN_MARKER pinned" || fail "F: detector regression"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
