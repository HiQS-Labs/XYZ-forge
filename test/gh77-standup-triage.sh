#!/usr/bin/env bash
# GH-77 — skills/standup/triage.py: the deterministic half of /standup.
#
# The GH-77 PRD escalated at its 4-round review cap with a flat finding rate (11 -> 13 -> 10 -> 10).
# The defects were not subtle; they were a state machine specified in prose, where a gap needs a
# human reader to notice it. This suite is the answer to that: the properties four review rounds
# argued about are pinned here as executable assertions, so the fifth reviewer is a test run.
#
# The four that cost the most rounds, each with a falsifiable pin below:
#   * a tier-1..3 item is NEVER silent — rendered, or counted in K with a paging escape hatch;
#   * a corruption finding reaches tier 1 through BOTH emission shapes (`FAIL: rule=` and
#     `warn: rule=`) — matching only `warn:` made the founding incident class invisible;
#   * suppression hashes a canonical lens-sorted live-state map, so a deduped multi-lens item has
#     one defined fingerprint and an escalation re-raises;
#   * writes stay inside the frozen PARKED/ authority, and a second run over unchanged state is a
#     byte no-op.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$HERE/.." && pwd)"
TRIAGE="$ROOT_DIR/skills/standup/triage.py"

pass=0; fail=0
pass_() { echo "  PASS: $1"; pass=$((pass+1)); }
fail_() { echo "  FAIL: $1" >&2; fail=$((fail+1)); }
# Deliberately no dynamic evaluation: the helper other suites share needs a security-scan baseline
# entry per suite, and nothing below needs that indirection.
is()   { if [ "$2" = "$3" ]; then pass_ "$1"; else fail_ "$1 (got '$2', want '$3')"; fi; }
has()  { if printf '%s' "$2" | grep -Fq -- "$3"; then pass_ "$1"; else fail_ "$1 (missing '$3')"; fi; }
hasnt(){ if printf '%s' "$2" | grep -Fq -- "$3"; then fail_ "$1 (found '$3')"; else pass_ "$1"; fi; }

echo "== test: gh77-standup-triage =="
command -v python3 >/dev/null 2>&1 || { echo "python3 required" >&2; exit 1; }
[ -f "$TRIAGE" ] || { echo "missing $TRIAGE" >&2; exit 1; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh77-standup.XXXXXX")"
. "$HERE/lib/fixture-guard.sh"
fixture_guard_init "$WORK"
cleanup() {
  case "${WORK:-}" in
    "${TMPDIR:-/tmp}"/gh77-standup.*) [ -d "$WORK" ] && rm -rf "$WORK" ;;
    *) echo "gh77-standup: REFUSING cleanup outside the workspace: ${WORK:-<empty>}" >&2 ;;
  esac
}
trap cleanup EXIT

W="$WORK/w"
mkdir -p "$W/PARKED"
require_fixture "$W" "standup fixture"

export STANDUP_BRANCH=development
export STANDUP_STAMP=2026-08-19-1200

# lens_json <file> <candidate-json...>  — wrap candidates into the collector's document shape
mk() { python3 - "$@" <<'PY'
import json, sys
out, lenses = sys.argv[1], {}
for spec in sys.argv[2:]:
    c = json.loads(spec)
    lid = str(c.pop("lens"))
    lenses.setdefault(lid, {"status": "ok", "degraded_id": None, "candidates": []})
    lenses[lid]["candidates"].append(c)
json.dump({"repo": {"branch": "development"}, "lenses": lenses}, open(out, "w"))
PY
}
T() { python3 "$TRIAGE" --lenses "$1" --parked-dir "$W/PARKED" "${@:2}"; }

# ── 1. a corruption finding reaches tier 1 through BOTH emission shapes ─────────────────────────
# The escalating finding: check() prints corruption via fail() as `FAIL: rule=...` while advisories
# go through warn(). A predicate matching only `warn:` produced no candidate at all.
mk "$W/corrupt.json" \
  '{"lens":6,"key":"rule:dump-divergence:db","kind":"rule","what":"resolve dump divergence","evidence_type":"rule","evidence_payload":"dump-divergence@db","rule_name":"dump-divergence","staleness":null,"live_state":"FAIL: rule=dump-divergence","close":"python3 utils/py/releases_app.py check --rebuild","close_kind":"command"}'
out="$(T "$W/corrupt.json" --dry-run 2>&1)"
has "corruption from a FAIL: line classifies tier 1" "$out" "1 · resolve dump divergence"
has "  and the opening line counts it as critical" "$out" "1 critical."
hasnt "  and it is not silently dropped as a degraded lens" "$out" "D5"

# ── 2. THE PIN: a tier-1 item beyond the cap is counted, never silent ───────────────────────────
# Eight tier-1 items. Exempt from parking AND suppression, so an earlier design left the eighth in
# neither count — not rendered, not parked, not suppressed, invisible on every subsequent run.
args=(); for n in 1 2 3 4 5 6 7 8; do
  args+=("{\"lens\":6,\"key\":\"rule:receipt-chain:r$n\",\"kind\":\"rule\",\"what\":\"fix chain $n\",\"evidence_type\":\"rule\",\"evidence_payload\":\"receipt-chain@r$n\",\"rule_name\":\"receipt-chain\",\"staleness\":$((1000+n)),\"live_state\":\"FAIL r$n\",\"close\":\"python3 utils/py/releases_app.py check\",\"close_kind\":\"command\"}")
done
mk "$W/eight.json" "${args[@]}"
out="$(T "$W/eight.json" --dry-run 2>&1)"
is "8 tier-1 items: exactly 7 rendered" "$(printf '%s' "$out" | grep -c '^1 · fix chain')" "7"
has "  and the 8th is counted, not silenced" "$out" "1 critical beyond cap"
has "  and the notices line names the escape hatch" "$out" "--page 2"
out2="$(T "$W/eight.json" --dry-run --page 2 2>&1)"
has "  and page 2 renders the 8th" "$out2" "fix chain 8"
is "  and the render is exactly 12 lines, inside the 15-line cap" "$(printf '%s\n' "$out" | wc -l | tr -d ' ')" "12"

# ── 3. tier-1..3 are never suppressed, even with a matching prior fingerprint ───────────────────
T "$W/corrupt.json" --apply --session-state "$W/sess.json" >/dev/null 2>&1
out="$(T "$W/corrupt.json" --dry-run --session-state "$W/sess.json" 2>&1)"
has "a tier-1 item re-renders on the second run (never suppressed)" "$out" "resolve dump divergence"
hasnt "  and is not counted as suppressed" "$out" "1 suppressed"

# ── 4. a tier-5 item IS suppressed when its fingerprint is unchanged, and re-raises when it moves ─
mk "$W/rot.json" \
  '{"lens":4,"key":"pr:51","kind":"pr","what":"review PR 51","evidence_type":"pr","evidence_payload":"51+BLOCKED","staleness":900,"stale_days":30,"live_state":"BLOCKED/false/2026-07-01","close":"gh pr review 51","close_kind":"command"}'
rm -f "$W/sess2.json"
T "$W/rot.json" --apply --session-state "$W/sess2.json" >/dev/null 2>&1
out="$(T "$W/rot.json" --dry-run --session-state "$W/sess2.json" 2>&1)"
has "an unchanged tier-5 item is suppressed on rerun" "$out" "1 suppressed"
hasnt "  and does not re-render" "$out" "review PR 51"
mk "$W/rot2.json" \
  '{"lens":4,"key":"pr:51","kind":"pr","what":"review PR 51","evidence_type":"pr","evidence_payload":"51+CLEAN","staleness":900,"merge_state":"CLEAN","live_state":"CLEAN/false/2026-08-19","close":"gh pr merge 51","close_kind":"command"}'
out="$(T "$W/rot2.json" --dry-run --session-state "$W/sess2.json" 2>&1)"
has "  but a changed live state re-raises it (fingerprint, not display string)" "$out" "review PR 51"
has "  and the escalation to tier 4 is visible" "$out" "4 · review PR 51"

# ── 5. ranking is a total order: unknown staleness sorts after known, within tier ───────────────
mk "$W/rank.json" \
  '{"lens":5,"key":"issue:200","kind":"issue","what":"unknown age item","evidence_type":"issue","evidence_payload":"200+OPEN@none","staleness":null,"live_state":"OPEN","close":"gh issue view 200","close_kind":"command"}' \
  '{"lens":5,"key":"issue:100","kind":"issue","what":"known age item","evidence_type":"issue","evidence_payload":"100+OPEN@none","staleness":500,"live_state":"OPEN","close":"gh issue view 100","close_kind":"command"}'
out="$(T "$W/rank.json" --dry-run 2>&1)"
first="$(printf '%s\n' "$out" | grep -n 'age item' | head -1)"
has "an unmeasured item never jumps a known-age peer" "$first" "known age item"

# ── 6. dedup across lenses yields one item with one defined fingerprint ─────────────────────────
mk "$W/dup.json" \
  '{"lens":5,"key":"issue:77","kind":"issue","what":"re-file 77","evidence_type":"issue","evidence_payload":"77+CLOSED@roadmap","staleness":700,"live_state":"CLOSED@roadmap","close":"python3 utils/py/releases_app.py roadmap sync","close_kind":"command"}' \
  '{"lens":1,"key":"issue:77","kind":"issue","what":"re-file 77","evidence_type":"quote","evidence_payload":"we should re-file 77","staleness":0,"live_state":"session-mention","close":"python3 utils/py/releases_app.py roadmap sync","close_kind":"command"}'
out="$(T "$W/dup.json" --dry-run 2>&1)"
is "two lenses reporting one entity collapse to one item" "$(printf '%s' "$out" | grep -c 're-file 77')" "1"

# ── 7. writes stay inside PARKED/, and an unchanged rerun is a byte no-op ───────────────────────
args=(); for n in $(seq 1 9); do
  args+=("{\"lens\":5,\"key\":\"issue:$((300+n))\",\"kind\":\"issue\",\"what\":\"triage issue $n\",\"evidence_type\":\"issue\",\"evidence_payload\":\"$((300+n))+OPEN@none\",\"staleness\":$((2000+n)),\"live_state\":\"OPEN\",\"close\":\"gh issue view $((300+n))\",\"close_kind\":\"command\",\"check\":{\"kind\":\"gh-issue-state\",\"args\":[\"$((300+n))\"]}}")
done
mk "$W/many.json" "${args[@]}"
BEFORE="$(cd "$W" && find . -path ./PARKED -prune -o -type f -print | sort | xargs shasum -a 256 2>/dev/null | shasum -a 256)"
T "$W/many.json" --apply --session-state "$W/sess3.json" >/dev/null 2>&1
parkfile="$W/PARKED/2026-08-19-1200-standup.md"
if [ -f "$parkfile" ]; then pass_ "overflow parks into the frozen PARKED/ schema"; else fail_ "overflow parks into the frozen PARKED/ schema"; fi
has "  and the record carries a fingerprint" "$(cat "$parkfile" 2>/dev/null)" "fingerprint:"
has "  and carries a read-only check probe" "$(cat "$parkfile" 2>/dev/null)" "check:"
H1="$(shasum -a 256 "$parkfile" | awk '{print $1}')"
T "$W/many.json" --apply --session-state "$W/sess3.json" >/dev/null 2>&1
H2="$(shasum -a 256 "$parkfile" | awk '{print $1}')"
is "  and a rerun over unchanged state writes nothing (byte no-op)" "$H1" "$H2"

# ── 8. degradation aggregates losslessly inside the cap ────────────────────────────────────────
python3 - "$W/deg.json" <<'PY'
import json, sys
lenses = {str(i): {"status": "degraded", "degraded_id": d, "candidates": []}
          for i, d in ((1, "D6"), (4, "D2"), (5, "D5"), (6, "D4"), (7, "D5"))}
json.dump({"repo": {"branch": "development"}, "lenses": lenses}, open(sys.argv[1], "w"))
PY
out="$(T "$W/deg.json" --dry-run 2>&1)"; rc=$?
is "a fully degraded run exits 3 (degraded, not clean)" "$rc" "3"
is "  and still fits the 15-line cap" "$([ "$(printf '%s\n' "$out" | wc -l | tr -d ' ')" -le 15 ] && echo ok)" "ok"
has "  and names every degradation id (lossless collapse)" "$out" "D2"
has "  and names D6 too" "$out" "D6"
has "  and reports an empty list honestly" "$out" "Nothing open."

# ── 9. the verdict vocabulary is finite and the clause is bounded ───────────────────────────────
out="$(T "$W/rank.json" --dry-run --verdict bogus-code 2>&1)"; rc=$?
is "an unknown verdict code is refused" "$rc" "2"
long="$(python3 -c 'print("x"*200)')"
out="$(T "$W/rank.json" --dry-run --verdict-clause "$long" 2>&1)"; rc=$?
is "an over-long verdict clause is refused (no wall of text via the clause)" "$rc" "2"

# ── 10. the em-dash delimiter inside a payload cannot break the item line ───────────────────────
mk "$W/delim.json" \
  '{"lens":1,"key":"conv:abc123","kind":"conv","what":"fix the thing","evidence_type":"quote","evidence_payload":"we said A — then B","staleness":0,"live_state":"q","close":"git status","close_kind":"command"}'
out="$(T "$W/delim.json" --dry-run 2>&1)"
line="$(printf '%s\n' "$out" | grep 'fix the thing')"
is "an embedded delimiter is escaped, so the line keeps exactly 2 top-level separators" \
   "$(printf '%s' "$line" | grep -o ' — ' | wc -l | tr -d ' ')" "2"
has "  and the payload text survives the escape (lossless)" "$line" "then B"

echo
# ── 11. Lens 2, 3, 7 classification and degradation ──────────────────────────────────────────
bash "$ROOT_DIR/skills/standup/collect.sh" --fixture "$ROOT_DIR/skills/standup/fixtures/lens-2" > "$W/lens2.json"
out="$(T "$W/lens2.json" --dry-run 2>&1)"
has "lens 2 artifact classifies to tier 1" "$out" "1 · commit or discard releases.db"

bash "$ROOT_DIR/skills/standup/collect.sh" --fixture "$ROOT_DIR/skills/standup/fixtures/lens-2-fail" > "$W/deg2.json"
out="$(T "$W/deg2.json" --dry-run 2>&1)" || true
has "lens 2 degrades loudly with D5" "$out" "D5"

bash "$ROOT_DIR/skills/standup/collect.sh" --fixture "$ROOT_DIR/skills/standup/fixtures/lens-3" > "$W/lens3.json"
out="$(T "$W/lens3.json" --dry-run 2>&1)"
has "lens 3 behind classifies to tier 5" "$out" "5 · sync branch"

bash "$ROOT_DIR/skills/standup/collect.sh" --fixture "$ROOT_DIR/skills/standup/fixtures/lens-3-fail" > "$W/deg3.json"
out="$(T "$W/deg3.json" --dry-run 2>&1)" || true
has "lens 3 degrades loudly with D5" "$out" "D5"

bash "$ROOT_DIR/skills/standup/collect.sh" --fixture "$ROOT_DIR/skills/standup/fixtures/lens-7" > "$W/lens7.json"
out="$(T "$W/lens7.json" --dry-run 2>&1)"
has "lens 7 diverged classifies to tier 5" "$out" "5 · sync ROADMAP ledger"

bash "$ROOT_DIR/skills/standup/collect.sh" --fixture "$ROOT_DIR/skills/standup/fixtures/lens-7-fail" > "$W/deg7.json"
bash "$ROOT_DIR/skills/standup/collect.sh" --fixture "$ROOT_DIR/skills/standup/fixtures/lens-1" > "$W/lens1.json"
bash "$ROOT_DIR/skills/standup/collect.sh" --fixture "$ROOT_DIR/skills/standup/fixtures/lens-1-fail" > "$W/deg1.json"
bash "$ROOT_DIR/skills/standup/collect.sh" --fixture "$ROOT_DIR/skills/standup/fixtures/lens-6" > "$W/lens6.json"
bash "$ROOT_DIR/skills/standup/collect.sh" --fixture "$ROOT_DIR/skills/standup/fixtures/lens-6-fail" > "$W/deg6.json"
bash "$ROOT_DIR/skills/standup/collect.sh" --fixture "$ROOT_DIR/skills/standup/fixtures/lens-8" > "$W/lens8.json"
bash "$ROOT_DIR/skills/standup/collect.sh" --fixture "$ROOT_DIR/skills/standup/fixtures/lens-8-fail" > "$W/deg8.json"

bash "$ROOT_DIR/skills/standup/collect.sh" --fixture "$ROOT_DIR/skills/standup/fixtures/lens-4" > "$W/lens4.json"
bash "$ROOT_DIR/skills/standup/collect.sh" --fixture "$ROOT_DIR/skills/standup/fixtures/lens-4-fail" > "$W/deg4.json"
bash "$ROOT_DIR/skills/standup/collect.sh" --fixture "$ROOT_DIR/skills/standup/fixtures/lens-4-truncated" > "$W/lens4_trunc.json"

bash "$ROOT_DIR/skills/standup/collect.sh" --fixture "$ROOT_DIR/skills/standup/fixtures/lens-5" > "$W/lens5.json"
bash "$ROOT_DIR/skills/standup/collect.sh" --fixture "$ROOT_DIR/skills/standup/fixtures/lens-5-fail" > "$W/deg5.json"
bash "$ROOT_DIR/skills/standup/collect.sh" --fixture "$ROOT_DIR/skills/standup/fixtures/lens-5-manifest" > "$W/lens5_manifest.json"

out="$(T "$W/lens4.json" --dry-run 2>&1)" || true
has "lens 4 finds open PR 51" "$out" "review PR 51"
has "lens 4 pin classification for CLEAN" "$out" "4 · review PR 51"
has "lens 4 pin classification for non-CLEAN (BLOCKED goes to 6)" "$out" "6 · review PR 52"
is "lens 4 structured candidate emits merge_state" "$(python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(d["lenses"]["4"]["candidates"][0]["merge_state"])' "$W/lens4.json")" "CLEAN"

out="$(T "$W/deg4.json" --dry-run 2>&1)" || true
has "lens 4 degrades loudly with D1" "$out" "D1"
out="$(T "$W/lens4_trunc.json" --dry-run 2>&1)" || true
has "lens 4 truncates at 50 and degrades with D2" "$out" "D2"
is "lens 4 D2 case still emits its 50 candidates" "$(python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(len(d["lenses"]["4"]["candidates"]))' "$W/lens4_trunc.json")" "50"
is "lens 4 D2 case expected first candidate remains present" "$(python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(d["lenses"]["4"]["candidates"][0]["what"])' "$W/lens4_trunc.json")" "review PR 1"

out="$(T "$W/lens5.json" --dry-run 2>&1)" || true
has "lens 5 finds triage issue" "$out" "triage issue 200"
is "lens 5 structured candidate emits live_state with updatedAt" "$(python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(d["lenses"]["5"]["candidates"][0]["live_state"])' "$W/lens5.json")" "OPEN/2026-08-19"
out="$(T "$W/deg5.json" --dry-run 2>&1)" || true
has "lens 5 degrades loudly with D1" "$out" "D1"

out="$(T "$W/lens5_manifest.json" --dry-run 2>&1)" || true
has "lens 5 manifest source contributes exactly its issue number" "$out" "triage issue 999"

# Rerun/fingerprint regression test for Lens 5
rm -f "$W/sess_lens5.json"
T "$W/lens5.json" --apply --session-state "$W/sess_lens5.json" >/dev/null 2>&1
out="$(T "$W/lens5.json" --dry-run --session-state "$W/sess_lens5.json" 2>&1)" || true
has "unchanged lens 5 item is suppressed on rerun" "$out" "1 suppressed"
hasnt "  and does not re-render" "$out" "triage issue 200"

cp -r "$ROOT_DIR/skills/standup/fixtures/lens-5" "$W/lens-5-copy"
python3 -c 'import json; print(json.dumps({"number": 200, "state": "OPEN", "title": "An Issue", "updatedAt": "2026-08-20T14:00:00Z"}))' > "$W/lens-5-copy/lens5_gh_issue_200.txt"
bash "$ROOT_DIR/skills/standup/collect.sh" --fixture "$W/lens-5-copy" > "$W/lens5_updated.json"

out="$(T "$W/lens5_updated.json" --dry-run --session-state "$W/sess_lens5.json" 2>&1)" || true
has "  but a changed live state (updatedAt) re-raises it" "$out" "triage issue 200"

out="$(T "$W/lens1.json" --dry-run 2>&1)" || true
has "lens 1 finds session mention" "$out" "re-file 77"
out="$(T "$W/deg1.json" --dry-run 2>&1)" || true
has "lens 1 degrades loudly with D6" "$out" "D6"

out="$(T "$W/lens6.json" --dry-run 2>&1)" || true
has "lens 6 finds overdue release" "$out" "ship 0.7.2"
out="$(T "$W/deg6.json" --dry-run 2>&1)" || true
has "lens 6 degrades loudly with D5" "$out" "D5"

out="$(T "$W/lens8.json" --dry-run 2>&1)" || true
has "lens 8 finds done work" "$out" "close parked item issue:301"
out="$(T "$W/deg8.json" --dry-run 2>&1)" || true
has "lens 8 degrades loudly with D3" "$out" "no PARKED/"

out="$(T "$W/deg7.json" --dry-run 2>&1)" || true
has "lens 7 degrades loudly with D4" "$out" "D4"

echo
# ── 12. Blocker 3 and Blocker 4 assertions ──────────────────────────────────────────────
bash "$ROOT_DIR/skills/standup/collect.sh" --fixture "$ROOT_DIR/skills/standup/fixtures/lens-2-missing-fixture" > "$W/deg_missing.json" 2>/dev/null
out="$(T "$W/deg_missing.json" --dry-run 2>&1)" || true
has "lens degrades loudly when fixture is missing" "$out" "D5"

bash "$ROOT_DIR/skills/standup/collect.sh" --fixture "$ROOT_DIR/skills/standup/fixtures/lens-3-bad-rev-list" > "$W/deg_bad_rev.json"
out="$(T "$W/deg_bad_rev.json" --dry-run 2>&1)" || true
has "lens 3 degrades loudly on non-integer rev-list" "$out" "D5"

bash "$ROOT_DIR/skills/standup/collect.sh" --fixture "$ROOT_DIR/skills/standup/fixtures/lens-3-bad-status" > "$W/deg_bad_status.json"
out="$(T "$W/deg_bad_status.json" --dry-run 2>&1)" || true
has "lens 3 degrades loudly on failed dirty-tree check" "$out" "D5"

bash "$ROOT_DIR/skills/standup/collect.sh" --fixture "$ROOT_DIR/skills/standup/fixtures/lens-2-quote-branch" > "$W/quote_branch.json"
out="$(T "$W/quote_branch.json" --dry-run 2>&1)" || true
has "JSON encoding handles branch name with double quotes" "$out" "commit or discard releases.db"

bash "$ROOT_DIR/skills/standup/collect.sh" --fixture "$ROOT_DIR/skills/standup/fixtures/lens-1-bad-schema" > "$W/deg_lens1_schema.json" 2>/dev/null
out="$(T "$W/deg_lens1_schema.json" --dry-run 2>&1)" || true
has "lens 1 degrades loudly on malformed session schema" "$out" "D6"

bash "$ROOT_DIR/skills/standup/collect.sh" --fixture "$ROOT_DIR/skills/standup/fixtures/lens-1-empty-session" > "$W/deg_lens1_empty.json" 2>/dev/null
out="$(T "$W/deg_lens1_empty.json" --dry-run 2>&1)" || true
has "lens 1 degrades loudly on empty session" "$out" "D6"

bash "$ROOT_DIR/skills/standup/collect.sh" --fixture "$ROOT_DIR/skills/standup/fixtures/lens-8-bad-check" > "$W/deg_lens8_schema.json" 2>/dev/null
out="$(T "$W/deg_lens8_schema.json" --dry-run 2>&1)" || true
has "lens 8 degrades loudly on malformed check object" "$out" "no PARKED/"

echo
# ── 13. The collector's own dependency is not allowed to fail silently ───────────────────
# Blocker 4's fix made `jq` load-bearing: every candidate and the branch name are encoded through it,
# which is what stops a quote in a path or ref from producing invalid JSON at exit 0. But jq is a NEW
# dependency — nothing else under skills/, utils/ or relay-automation/ uses it, and the repo's
# quickstart asks only for Node and git. On a clone without it the collector died at the first `jq -n`
# with exit 127 and printed NOTHING, and an empty stdin is indistinguishable to the consumer from
# "the session is clean" — the exact silent-ok class this suite exists to close, arriving by a new
# route. Pin the loud path: valid JSON, every lens D5, and a non-zero exit.
NOJQ="$W/nojq-bin"; mkdir -p "$NOJQ"
for _b in bash git python3 sed grep cat date wc printf sort head tail mkdir rm ls tr awk stat; do
  _p="$(command -v "$_b" 2>/dev/null)" && ln -sf "$_p" "$NOJQ/$_b"
done
set +e
PATH="$NOJQ" bash "$ROOT_DIR/skills/standup/collect.sh" \
  --fixture "$ROOT_DIR/skills/standup/fixtures/lens-2" > "$W/nojq.json" 2>/dev/null
nojq_rc=$?
# NOT `set -e`: this file runs under `set -uo pipefail` (line 17) and deliberately calls the collector
# in states where a non-zero exit is the expected result. Restoring -e here silently truncated the
# suite at the first such call — it printed PASS lines and exited 3 with everything after section 13
# never running, which reads exactly like a green run to anything checking only the tail.
set +e
if [ "$nojq_rc" -ne 0 ]; then
  pass=$((pass+1)); echo "  PASS: collector exits non-zero when jq is unavailable (got $nojq_rc)"
else
  fail=$((fail+1)); echo "  FAIL: collector exited 0 with jq unavailable — the caller cannot tell" >&2
fi
if python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$W/nojq.json" 2>/dev/null; then
  pass=$((pass+1)); echo "  PASS: it still emits VALID JSON with jq unavailable — never an empty stdin"
else
  fail=$((fail+1)); echo "  FAIL: jq-unavailable output is not valid JSON — consumer sees silence" >&2
fi
if python3 -c '
import json, sys
try:
    d = json.load(open(sys.argv[1]))
    expected_keys = {"1", "2", "3", "4", "5", "6", "7", "8"}
    keys = set(d.get("lenses", {}).keys())
    if keys != expected_keys: sys.exit(1)
    if any(l.get("degraded_id") != "D5" for l in d["lenses"].values()): sys.exit(2)
except Exception:
    sys.exit(3)
' "$W/nojq.json"; then
  pass=$((pass+1)); echo "  PASS: fallback document contains exactly lenses 1-8 all as D5"
else
  fail=$((fail+1)); echo "  FAIL: fallback document keys or degraded_id mismatch" >&2
fi
out="$(T "$W/nojq.json" --dry-run 2>&1)" || true
has "every lens degrades loudly with D5 when jq is unavailable" "$out" "D5"

echo
# ── 14. Round-3 review: what the collector must not fabricate, hide, or hand you to run ──────────
# Every case below is a finding from the codex round-3 review of this branch. They share one shape:
# the collector produced something that LOOKED like a valid result. A fabricated count, a degraded
# lens reported through a success exit code, a required measure quietly absent, and a recommendation
# that executes shell substitution when followed. A green suite is not evidence against any of them,
# which is why each gets a direct assertion rather than being inferred from a rendered line.
C() { bash "$ROOT_DIR/skills/standup/collect.sh" --fixture "$ROOT_DIR/skills/standup/fixtures/$1" 2>/dev/null; }
# <fixture> <python expr over `d` (the parsed document)>
F() { C "$1" | python3 -c "import json,sys
d=json.load(sys.stdin)
print($2)"; }

# B1 — unparseable `roadmap sync` output is D4, never a confident divergence of size zero.
# The old code accepted any nonempty stdout lacking 'already in sync', then let each count extraction
# fall back to 0, emitting `counts:+0~0-0`: a finding asserting there is nothing to find.
is "an unparseable roadmap-sync summary degrades to D4" \
   "$(F lens-7-malformed 'd["lenses"]["7"]["degraded_id"]')" "D4"
is "  and fabricates no candidate from it" \
   "$(F lens-7-malformed 'len(d["lenses"]["7"]["candidates"])')" "0"
is "a real diverged summary yields the canonical counts payload" \
   "$(F lens-7 'd["lenses"]["7"]["candidates"][0]["evidence_payload"]')" "+2~1-0"

# B2 — a degraded lens must be visible in the EXIT CODE, not only in the document. SKILL.md publishes
# "3 one or more lenses degraded"; only the jq preflight honoured it, so a caller checking $? was told
# a failed bounded read had succeeded.
C lens-7-fail >/dev/null; is "an ordinary degraded lens exits 3, as SKILL.md publishes" "$?" "3"
C lens-2      >/dev/null; is "  and a fully clean collection still exits 0" "$?" "0"

# B3 — the lens table requires FILE MTIME for a lens-2 candidate. Absent, it is not an item with
# unknown staleness; it is a lens that cannot supply all six fields. Under --fixture the read must
# also be hermetic: reading the real CWD made the result depend on the reviewer's checkout.
is "a fixture that supplies no mtime degrades D5 rather than emitting a null-staleness item" \
   "$(F lens-2-no-stat 'd["lenses"]["2"]["degraded_id"]')" "D5"
is "  and a supplied mtime is carried as the candidate's staleness" \
   "$(F lens-2 'd["lenses"]["2"]["candidates"][0]["staleness"]')" "1700000000"

# B4 — THE SECURITY PIN. `close` is never executed by collection, but it is a recommendation a human
# or an agent may run verbatim. A path containing $(...) must be inert when they do.
adv="$(F lens-2-adversarial-path 'd["lenses"]["2"]["candidates"][0]["close"]')"
has "an adversarial path is single-quoted in the close command" "$adv" "'\$(touch /tmp/pwned).txt'"
# A grep for an unquoted `$(` cannot decide this — inside `'updated $(touch …)'` the character before
# `$(` is a space, which any "not a quote" pattern matches, so the naive check fails a correct string.
# Ask the real question instead: does a shell-word splitter recover the path as ONE literal token,
# byte-for-byte? It does exactly when the quoting is sound, and cannot when it is not.
if python3 -c '
import shlex, sys
want = sys.argv[1]
print("YES" if want in shlex.split(sys.argv[2]) else "NO")' '$(touch /tmp/pwned).txt' "$adv" | grep -q YES; then
  pass_ "  the path survives shell word-splitting as one literal token (substitution is inert)"
else
  fail_ "the adversarial path does not survive as a literal token — it would expand if followed"
fi

# S1 — the no-upstream contract, which was the original lens-3 regression. Divergence from the trunk
# does not establish push state, so: unknown staleness, and an inspect action rather than `git push`.
is "no upstream (exit 128) falls back to the trunk and says so" \
   "$(F lens-3-no-upstream 'd["lenses"]["3"]["candidates"][0]["evidence_payload"]')" "3/0@no-upstream"
is "  its staleness is unknown, never a fabricated date" \
   "$(F lens-3-no-upstream 'd["lenses"]["3"]["candidates"][0]["staleness"]')" "None"
is "  and its close is an inspect action, never a bare git push" \
   "$(F lens-3-no-upstream 'd["lenses"]["3"]["candidates"][0]["close_kind"]')" "inspect"

# S2 — a TRACKED lens-3 candidate does have an honest date available, so null is not acceptable there.
is "a tracked divergence carries a committer date as staleness" \
   "$(F lens-3 'd["lenses"]["3"]["candidates"][0]["staleness"]')" "1712000000"
is "  and an unreadable date degrades rather than emitting a dateless item" \
   "$(F lens-3-no-date 'd["lenses"]["3"]["degraded_id"]')" "D5"
is "lens 7 carries the ROADMAP.md mtime as staleness" \
   "$(F lens-7 'd["lenses"]["7"]["candidates"][0]["staleness"]')" "1750000000"

# S3 — the lens table's close for lens 7 is sync THEN the dashboard refresh. Half of it leaves the
# committed dashboard stale, which is the exact drift GH-27's --check gate exists to catch.
has "lens 7's close refreshes the dashboard after syncing" \
    "$(F lens-7 'd["lenses"]["7"]["candidates"][0]["close"]')" "roadmap-dashboard.sh"

echo
# ── 15. Round-4 review: the two round-3 fixes that MOVED the bug instead of closing it ───────────
# Both are the same lesson twice: a fix that satisfies the assertion written for it, while the
# defect walks around the assertion. Section 14 pinned each finding at the exact shape codex
# described, so both survived a green suite.

# B1-again — the anchor. Section 14's `roadmap_diverged` fixture is a single token, so a form that
# merely *found the counts somewhere in the text* passed it. This fixture is the counterexample: a
# well-formed count fragment embedded in a line that is NOT the producer's summary, naming the wrong
# file. Finding a convenient substring is not validating a summary.
is "a count-shaped fragment inside a non-summary line degrades to D4" \
   "$(F lens-7-decoy 'd["lenses"]["7"]["degraded_id"]')" "D4"
is "  and yields no candidate from the decoy counts" \
   "$(F lens-7-decoy 'len(d["lenses"]["7"]["candidates"])')" "0"

# ROUND 8 — the C-quote grammar is GONE, not fixed. The collector reads `--porcelain -z`, which git
# provides precisely so tools do not parse that grammar. Three separate rounds (4, 5, 7) were each
# spent on a different bug in hand-parsing it, and round 8 found two more; the reviewer recommended a
# machine-safe format in round 4 and again in round 8. The assertions below are for the boundary that
# replaced it, and the ones written against escape sequences are deleted rather than kept passing —
# a test for a code path that no longer exists is worse than no test, because it reads as coverage.

# The two rename shapes the text format could not express unambiguously. In -z a rename is two
# NUL-terminated fields, destination first, and the status field is read POSITIONALLY.
is "a staged rename yields the destination path" \
   "$(F lens-2-rename 'd["lenses"]["2"]["candidates"][0]["evidence_payload"]')" "new/name.md"
# An UNSTAGED rename puts R in the SECOND position. Testing xy[0] alone missed this shape entirely,
# so a perfectly ordinary record fell through and falsely degraded the lens.
is "an UNSTAGED rename (\" R\") is handled by the same path as a staged one" \
   "$(F lens-2-rename-unstaged 'd["lenses"]["2"]["candidates"][0]["evidence_payload"]')" "new/name.md"
# " -> " is LEGAL INSIDE a pathname, so the text format was ambiguous and no splitter could fix it.
# Here the source is its own field and simply gets consumed.
is "a rename whose SOURCE contains \" -> \" is still parsed correctly" \
   "$(F lens-2-rename-arrow-src 'd["lenses"]["2"]["candidates"][0]["evidence_payload"]')" "dest.md"
is "  and a rename entry with no source field degrades rather than misreading the next entry" \
   "$(F lens-2-rename-no-source 'd["lenses"]["2"]["degraded_id"]')" "D5"

# Bytes are raw in -z, so the cases that needed an escape grammar are now simply data.
is "a UTF-8 pathname needs no decoding and arrives intact" \
   "$(F lens-2-utf8 'd["lenses"]["2"]["candidates"][0]["evidence_payload"]')" "é.txt"
is "  as does a pathname containing a double quote" \
   "$(F lens-2-quote-in-name 'd["lenses"]["2"]["candidates"][0]["evidence_payload"]')" 'we"ird.md'

# Malformed entries must degrade, never read as a clean tree. A whitespace-only record was silently
# skipped by a `strip()` guard, which contradicted the boundary's own promise.
is "an entry with a status and no pathname degrades" \
   "$(F lens-2-no-path 'd["lenses"]["2"]["degraded_id"]')" "D5"
is "a whitespace-only entry degrades rather than being skipped as blank" \
   "$(F lens-2-whitespace-entry 'd["lenses"]["2"]["degraded_id"]')" "D5"
is "an unrecognised status field degrades" \
   "$(F lens-2-bad-status 'd["lenses"]["2"]["degraded_id"]')" "D5"
is "  and none of them is reported as a successful collection" \
   "$(C lens-2-whitespace-entry >/dev/null; echo $?)" "3"

# A newline in a pathname is legal and survives -z intact — which makes it the collector's problem to
# render, not triage.py's. Escaped display, inspect close, never dropped.
is "a newline pathname is emitted with an escaped one-line display" \
   "$(F lens-2-newline-path 'd["lenses"]["2"]["candidates"][0]["evidence_payload"]')" 'a\nb.txt'
is "  as an inspect action, not a command built from an unrenderable name" \
   "$(F lens-2-newline-path 'd["lenses"]["2"]["candidates"][0]["close_kind"]')" "inspect"
is "  and it is never dropped — the operator still learns the file is there" \
   "$(F lens-2-newline-path 'len(d["lenses"]["2"]["candidates"])')" "1"
C lens-2-newline-path > "$W/nl.json" 2>/dev/null
is "  so the rendered screen keeps one physical line per item" \
   "$(T "$W/nl.json" --dry-run 2>&1 | wc -l | tr -d ' ')" "8"

# The required mtime is validated BEFORE jq sees it. A non-integer made jq's `tonumber` fail; with
# `set +e` active the candidate silently became EMPTY while the lens stayed `ok`, and the final
# heredoc emitted INVALID JSON at exit 0 — malformed input leaking past the boundary as broken output.
is "a non-integer mtime degrades instead of producing invalid JSON at exit 0" \
   "$(F lens-2-bad-mtime 'd["lenses"]["2"]["degraded_id"]')" "D5"

# The lens-2 predicate excludes only UNTRACKED paths under PARKED/ — the settled decision.
is "an untracked PARKED/ path is excluded without degrading the lens" \
   "$(F lens-2-parked 'd["lenses"]["2"]["status"] + ":" + str(len(d["lenses"]["2"]["candidates"]))')" "ok:0"

# Lens 3 validates its COMPLETE date stream. Filtering with grep and taking an end silently discarded
# malformed lines, so a truncated or partly-garbage `git log` yielded a confident staleness for a
# branch whose history was never fully read.
is "a date stream with a malformed line degrades rather than filtering it away" \
   "$(F lens-3-bad-dates 'd["lenses"]["3"]["degraded_id"]')" "D5"
is "a date stream shorter than the divergence count degrades" \
   "$(F lens-3-short-dates 'd["lenses"]["3"]["degraded_id"]')" "D5"

# ── 18b. Round-9: the -z boundary rejects truncation and impossible status pairs ─────────────────
# -z TERMINATES each entry with NUL rather than separating them, so a stream whose last entry has no
# terminator is a TRUNCATED read — and a truncated bounded read is a failed one, not a shorter list
# of findings. The final partial entry used to be accepted whole.
is "an unterminated final entry is a truncated read, not a finding" \
   "$(F lens-2-unterminated 'd["lenses"]["2"]["degraded_id"]')" "D5"
# A rename's source field is required. Consuming it without looking let `R  dest\0\0` through as a
# confident candidate whose required source was absent.
is "a rename with an empty source field degrades" \
   "$(F lens-2-empty-rename-src 'd["lenses"]["2"]["degraded_id"]')" "D5"
# `?` and `!` occur ONLY as the doubled pairs. Treating XY as two independently permissive characters
# accepted pairs git cannot emit (`?M`, `M?`, `?!`), which reached the candidate builder and produced
# an ok lens with a fabricated live_state.
is "a status pair git cannot emit degrades" \
   "$(F lens-2-impossible-status 'd["lenses"]["2"]["degraded_id"]')" "D5"
# THE CONTROLS, and the reason this section is not just three more rejections: tightening a validator
# until it rejects valid input is a regression in the other direction, and a false D5 on a real
# working tree is worse than the over-acceptance it replaced. Both pairs below are legal porcelain.
is "  but the ignored pair (!!) is legal and still yields a candidate" \
   "$(F lens-2-ignored 'd["lenses"]["2"]["candidates"][0]["evidence_payload"]')" "build/out.o"
is "  and the unmerged pair (UU) is legal too" \
   "$(F lens-2-unmerged 'd["lenses"]["2"]["candidates"][0]["evidence_payload"]')" "conflict.md"

# ── 18c. Round-10: the validator must not reject valid input, and the bytes must survive Bash ────
# Both findings are the SAME regression direction — the one I said I cared most about while adding
# the round-9 validator, and then introduced anyway. A false D5 on a real working tree is worse than
# the over-acceptance it replaced, because it makes the collector wrong about a repo that is fine.

# `T` (type changed — a file replaced by a symlink, say) is ordinary porcelain v1. Omitting it from
# the code set degraded a legitimate record. The round-9 `!!` and `UU` controls did not cover it,
# which is the argument for controls that span the grammar rather than one example of it.
is "a staged type-change (T) is valid porcelain, not a degradation" \
   "$(F lens-2-typechange 'd["lenses"]["2"]["candidates"][0]["evidence_payload"]')" "swapped.md"
is "  as is an unstaged one" \
   "$(F lens-2-typechange-wt 'd["lenses"]["2"]["candidates"][0]["evidence_payload"]')" "swapped.md"

# THE BASH HANDOFF. Command substitution strips ALL trailing newlines from its output, so a legal
# pathname ending in LF lost it at the very last step — undoing the raw-byte boundary that the whole
# -z rewrite exists to provide, and addressing a DIFFERENT (possibly existing) file. The interior-
# newline fixture could not exercise this: only a TRAILING newline is stripped.
is "a pathname ending in LF keeps its trailing byte through the shell handoff" \
   "$(F lens-2-trailing-lf 'd["lenses"]["2"]["candidates"][0]["evidence_payload"]')" 'name\n'
# The mtime is keyed on the exact bytes, so resolving it proves the trailing byte reached the stat
# lookup — not just the display string.
is "  and its stat resolves on the exact bytes, not the stripped name" \
   "$(F lens-2-trailing-lf 'd["lenses"]["2"]["candidates"][0]["staleness"]')" "1800000002"

# ── 18d. Round-11: a legal pathname is BYTES, not text ───────────────────────────────────────────
# The last finding, and the fifth appearance of one pattern worth naming: every remaining safety bug
# in this file has lived at a BYTE-TO-TEXT CROSSING. The C-quote decoder, the base64 handoff, the
# trailing-LF strip, and now the JSON boundary — each was a sound parser undone where bytes became a
# string. A git pathname is a byte string and need not be valid UTF-8.
#
# Classifying on control bytes alone let `name\xff` take the ordinary COMMAND path, so the raw byte
# reached `jq --arg` in the key, the evidence and the close — producing a normalised or invalid JSON
# string and a runnable command addressing a DIFFERENT pathname. A name that cannot be rendered as
# text is unrenderable for exactly the reason a newline is.
is "a non-UTF-8 pathname is escaped unambiguously, not normalised away" \
   "$(F lens-2-non-utf8 'd["lenses"]["2"]["candidates"][0]["evidence_payload"]')" 'name\xff'
is "  and gets an inspect close, never a runnable command built from it" \
   "$(F lens-2-non-utf8 'd["lenses"]["2"]["candidates"][0]["close_kind"]')" "inspect"
is "  while the lens stays ok — the item is escaped, not dropped or degraded" \
   "$(F lens-2-non-utf8 'd["lenses"]["2"]["status"]')" "ok"
# Keyed on the exact bytes, so this proves the byte identity survived to the stat lookup. Note the
# display uses backslashreplace, not replace: U+FFFD would render two different paths identically,
# which is fine for a glyph and useless for naming a file the operator has to go and find.
is "  and its stat resolves on the exact bytes" \
   "$(F lens-2-non-utf8 'd["lenses"]["2"]["candidates"][0]["staleness"]')" "1810000000"

# ── 19. THE GENERIC GUARD: no input makes the collector emit nothing ─────────────────────────────
# Written after the round-7 staleness fix silently reintroduced the founding failure. A no-match
# `grep` exits 1, `set -e` is active in collect.sh, and the script aborted MID-DOCUMENT — emitting no
# JSON at all for one fixture. The consumer reads empty stdin as a clean session, so that is the
# silent-ok failure in its purest form, arriving through a one-word change in an unrelated fix.
#
# Every assertion above names a specific input. This one names the INVARIANT, over every fixture that
# exists now or is added later: whatever the input, the collector emits a parseable document. It cost
# nothing to write and it would have caught that regression on the first run.
bad_json=""
for fx in "$ROOT_DIR"/skills/standup/fixtures/*/; do
  # Capture, THEN validate. Piping the collector straight into python fails the whole pipeline under
  # `pipefail` on the collector's own deliberate exit 3 (a degraded lens), which is not what this
  # asserts — the claim is about the DOCUMENT, not the exit code, and those are checked separately.
  doc="$(bash "$ROOT_DIR/skills/standup/collect.sh" --fixture "$fx" 2>/dev/null)"
  if ! printf '%s' "$doc" | python3 -c 'import json,sys; json.load(sys.stdin)' 2>/dev/null; then
    bad_json="$bad_json $(basename "$fx")"
  fi
done
if [ -z "$bad_json" ]; then
  pass_ "every fixture yields a parseable document — no input silences the collector"
else
  fail_ "these fixtures produced no/invalid JSON (the consumer would read them as a clean session):$bad_json"
fi

echo
# ── 20. Round-5 Reviewer: Lens 1 canonical identity, Lens 6 show parse, Lens 8 controls ─────────

bash "$ROOT_DIR/skills/standup/collect.sh" --fixture "$ROOT_DIR/skills/standup/fixtures/lens-1-malformed-actionable" > "$W/deg_lens1_malformed.json" 2>/dev/null
out="$(T "$W/deg_lens1_malformed.json" --dry-run 2>&1)" || true
has "lens 1 degrades loudly (D6) if actionable item has missing/malformed quote/what/close" "$out" "D6"

export RELEASES_APP_NOW="2026-08-20T12:00:00Z"
bash "$ROOT_DIR/skills/standup/collect.sh" --fixture "$ROOT_DIR/skills/standup/fixtures/lens-6-overdue-show" > "$W/lens6_overdue.json" 2>/dev/null
out="$(T "$W/lens6_overdue.json" --dry-run 2>&1)" || true
has "lens 6 extracts overdue candidate from show output even without check warning" "$out" "ship 0.9.0"

bash "$ROOT_DIR/skills/standup/collect.sh" --fixture "$ROOT_DIR/skills/standup/fixtures/lens-8-controls" > "$W/lens8_controls.json" 2>/dev/null
out="$(T "$W/lens8_controls.json" --dry-run 2>&1)" || true
has "lens 8 success control for test-e yields candidate" "$out" "close parked item issue:1"
has "lens 8 success control for git-log yields candidate" "$out" "close parked item issue:2"
has "lens 8 success control for releases-check yields candidate" "$out" "close parked item issue:3"
is "lens 8 explicit state is preserved in live_state for test-e" "$(F lens-8-controls 'next((c["live_state"] for c in d["lenses"]["8"]["candidates"] if c["evidence_payload"]=="issue:1"), None)')" "exit 0"

bash "$ROOT_DIR/skills/standup/collect.sh" --fixture "$ROOT_DIR/skills/standup/fixtures/lens-8-fail-controls" > "$W/lens8_fail_controls.json" 2>/dev/null
is "lens 8 failure controls yield zero candidates" "$(F lens-8-fail-controls 'len(d["lenses"]["8"]["candidates"])')" "0"

bash "$ROOT_DIR/skills/standup/collect.sh" --fixture "$ROOT_DIR/skills/standup/fixtures/lens-8-bad-read" > "$W/lens8_bad_read.json" 2>/dev/null
out="$(T "$W/lens8_bad_read.json" --dry-run 2>&1)" || true
has "lens 8 degrades loudly with D3 on unreadable PARKED record" "$out" "no PARKED/"

bash "$ROOT_DIR/skills/standup/collect.sh" --fixture "$ROOT_DIR/skills/standup/fixtures/lens-6-bad-read" > "$W/lens6_bad_read.json" 2>/dev/null
out="$(T "$W/lens6_bad_read.json" --dry-run 2>&1)" || true
has "lens 6 degrades loudly with D5 on unreadable fixture" "$out" "D5"

echo
# ── 21. Lens 1 non-fixture control ─────────────────────────────────────────────────────────────
echo '[{"quote":"test quote","what":"test what","close":"inspect: test"}]' > "$W/.standup-transcript.json"
(cd "$W" && bash "$ROOT_DIR/skills/standup/collect.sh") > "$W/live_lens1_nonfixture.json" 2>/dev/null
rm -f "$W/.standup-transcript.json"
out="$(T "$W/live_lens1_nonfixture.json" --dry-run 2>&1)" || true
has "Lens 1 works outside fixture mode when .standup-transcript.json is present at repo root" "$out" "test what"

echo


echo
# ── 22. Daybreak Wave 3: Lens 4 & 5 validation and bounds regression ──────────────────────────────
export STANDUP_STAMP=2026-08-19-1200

# Lens 4: malformed/missing fields (D5)
bash "$ROOT_DIR/skills/standup/collect.sh" --fixture "$ROOT_DIR/skills/standup/fixtures/lens-4-missing-fields" > "$W/lens4_missing.json" 2>/dev/null
out="$(T "$W/lens4_missing.json" --dry-run 2>&1)" || true
has "lens 4 degrades loudly with D5 on missing/malformed API fields" "$out" "D5"

# Lens 5: malformed/missing fields (D5)
bash "$ROOT_DIR/skills/standup/collect.sh" --fixture "$ROOT_DIR/skills/standup/fixtures/lens-5-missing-fields" > "$W/lens5_missing.json" 2>/dev/null
out="$(T "$W/lens5_missing.json" --dry-run 2>&1)" || true
has "lens 5 degrades loudly with D5 on missing/malformed API fields" "$out" "D5"

# Lens 5: wrong issue number from API (D5)
bash "$ROOT_DIR/skills/standup/collect.sh" --fixture "$ROOT_DIR/skills/standup/fixtures/lens-5-wrong-number" > "$W/lens5_wrong_num.json" 2>/dev/null
out="$(T "$W/lens5_wrong_num.json" --dry-run 2>&1)" || true
has "lens 5 degrades loudly with D5 on mismatched issue number" "$out" "D5"

# Lens 4 & 5: gh unavailable degrades loudly to D1
NOGH="$W/nogh-bin"
mkdir -p "$NOGH"
for _b in bash git python3 sed grep cat date wc printf sort head tail mkdir rm ls tr awk stat jq base64; do
  _p="$(command -v "$_b" 2>/dev/null)"
  if [ -n "$_p" ]; then
    ln -sf "$_p" "$NOGH/$_b"
  fi
done
echo '[]' > "$W/dummy_session.json"
PATH="$NOGH" bash "$ROOT_DIR/skills/standup/collect.sh" --session "$W/dummy_session.json" > "$W/nogh.json" 2>/dev/null
if python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$W/nogh.json" 2>/dev/null; then
  pass_ "collector still emits valid JSON when gh is missing"
else
  fail_ "collector emitted invalid JSON when gh is missing"
fi
out="$(T "$W/nogh.json" --dry-run 2>&1)" || true
has "lens 4 degrades loudly with D1 when gh is missing" "$out" "D1"
has "lens 5 degrades loudly with D1 when gh is missing" "$out" "D1"


# Lens 5: non-root invocation control (must find ROADMAP and DB at REPO_ROOT)
# We test this by creating a mock repository inside $W
MOCK_REPO="$W/mock-repo"
mkdir -p "$MOCK_REPO/subdir"
cp -r "$ROOT_DIR/skills/standup/fixtures/lens-5" "$MOCK_REPO/lens-5"
# Make it look like a repo
(cd "$MOCK_REPO" && git init >/dev/null && git config user.email "a@b.com" && git config user.name "A B" && touch dummy && git add dummy && git commit -m "init" >/dev/null)
# Provide bounded sources at repo root
cp "$MOCK_REPO/lens-5/ROADMAP.md" "$MOCK_REPO/"
cp "$MOCK_REPO/lens-5/releases.db" "$MOCK_REPO/"
echo "[{\"what\": \"GH-200\"}]" > "$MOCK_REPO/.standup-transcript.json"

# We run collect.sh WITHOUT --fixture, from the subdirectory, maskinggh with a mock on PATH
MOCK_BIN="$W/mock_bin"
mkdir -p "$MOCK_BIN"
cat << 'MOCK' > "$MOCK_BIN/gh"
#!/usr/bin/env bash
if [[ "$1" == "--version" ]]; then exit 0; fi
if [[ "$1" == "issue" && "$2" == "view" ]]; then
  # Just return the same static payload for any issue
  echo '{"number":'"$3"',"state":"OPEN","title":"An Issue","updatedAt":"2026-08-20T14:00:00Z"}'
  exit 0
fi
if [[ "$1" == "pr" && "$2" == "list" ]]; then
  echo '[]'
  exit 0
fi
exit 1
MOCK
chmod +x "$MOCK_BIN/gh"

# We need to mock jq too, wait jq is required by collect.sh
ln -s "$(command -v jq)" "$MOCK_BIN/jq"
ln -s "$(command -v git)" "$MOCK_BIN/git"
ln -s "$(command -v python3)" "$MOCK_BIN/python3"
ln -s "$(command -v base64)" "$MOCK_BIN/base64"

(cd "$MOCK_REPO/subdir" && PATH="$MOCK_BIN:$PATH" bash "$ROOT_DIR/skills/standup/collect.sh") > "$W/lens5_subdir.json" 2>/dev/null
out="$(T "$W/lens5_subdir.json" --dry-run 2>&1)" || true
has "lens 5 non-root invocation finds repo root ROADMAP and DB bounded inputs" "$out" "triage issue 200"

# Lens 5: missing ROADMAP degrades to D5
bash "$ROOT_DIR/skills/standup/collect.sh" --fixture "$ROOT_DIR/skills/standup/fixtures/lens-5-missing-roadmap" > "$W/lens5_missing_roadmap.json" 2>/dev/null
out="$(T "$W/lens5_missing_roadmap.json" --dry-run 2>&1)" || true
has "lens 5 degrades loudly with D5 on missing/unreadable ROADMAP" "$out" "D5"

# Lens 5: missing releases.db degrades to D5
bash "$ROOT_DIR/skills/standup/collect.sh" --fixture "$ROOT_DIR/skills/standup/fixtures/lens-5-missing-db" > "$W/lens5_missing_db.json" 2>/dev/null
out="$(T "$W/lens5_missing_db.json" --dry-run 2>&1)" || true
has "lens 5 degrades loudly with D5 on missing/unreadable releases.db" "$out" "D5"
echo "  gh77-standup-triage: $pass pass, $fail fail"
[ "$fail" -eq 0 ]
