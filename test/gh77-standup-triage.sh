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


# ── 11. Lenses 2, 3, 7 asserts ──────────────────────────────────────────────────────────────────
"$ROOT_DIR/skills/standup/collect.sh" --fixture "$ROOT_DIR/skills/standup/fixtures/lens-2" > "$W/l2.json"
out="$(T "$W/l2.json" --dry-run 2>&1)"
has "Lens 2 classifies to expected tier (1)" "$out" "1 · commit or stash releases.db"
has "Lens 2 degrades loudly with its D id when read is unavailable" "$out" "D5"

"$ROOT_DIR/skills/standup/collect.sh" --fixture "$ROOT_DIR/skills/standup/fixtures/lens-3" > "$W/l3.json"
out="$(T "$W/l3.json" --dry-run 2>&1)"
has "Lens 3 classifies to expected tier (4)" "$out" "4 · push or rebase branch"
has "Lens 3 degrades loudly with its D id when read is unavailable" "$out" "D5"

"$ROOT_DIR/skills/standup/collect.sh" --fixture "$ROOT_DIR/skills/standup/fixtures/lens-7" > "$W/l7.json"
out="$(T "$W/l7.json" --dry-run 2>&1)"
has "Lens 7 classifies to expected tier (5)" "$out" "5 · sync roadmap items"

"$ROOT_DIR/skills/standup/collect.sh" --fixture "$W/empty-fixture" > "$W/l7_empty.json"
out="$(T "$W/l7_empty.json" --dry-run 2>&1)"
has "Lens 7 degrades loudly with its D id when read is unavailable" "$out" "D4"

echo
echo "  gh77-standup-triage: $pass pass, $fail fail"
[ "$fail" -eq 0 ]
