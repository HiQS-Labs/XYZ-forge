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
is "a tracked divergence carries the committer date as staleness" \
   "$(F lens-3 'd["lenses"]["3"]["candidates"][0]["staleness"]')" "1710000000"
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

# B4-again — the C-quoted name. Section 14's "adversarial path" fixture was an ordinary unquoted
# porcelain pathname, so it never entered this branch at all. git C-quotes any name containing a
# quote, backslash, newline or non-ASCII byte; `${line:3}` then yields the ESCAPED DISPLAY STRING,
# and every use of it addresses a file that does not exist — which degraded the lens and cleared
# EVERY candidate already collected. One oddly-named file could blank the whole working-tree lens.
is "a C-quoted porcelain name is decoded to the real filename" \
   "$(F lens-2-cquoted 'd["lenses"]["2"]["candidates"][0]["evidence_payload"]')" \
   'we"ird.md'
is "  so the lens stays ok rather than degrading on one odd filename" \
   "$(F lens-2-cquoted 'd["lenses"]["2"]["status"]')" "ok"
is "  and it still carries its required mtime" \
   "$(F lens-2-cquoted 'd["lenses"]["2"]["candidates"][0]["staleness"]')" "1730000000"

# Renames had the identical parse bug: `R  old -> new` was one field, so the "path" was the literal
# string `old -> new`, unstattable, same blast radius. The CURRENT path is what an operator acts on.
is "a rename record yields the destination path, not 'old -> new'" \
   "$(F lens-2-rename 'd["lenses"]["2"]["candidates"][0]["evidence_payload"]')" "new/name.md"

# S — --fixture must be hermetic for the branch too. Falling through to a live `git rev-parse` let a
# lens-3 candidate take its key and no-upstream close from the reviewer's own checkout.
is "a fixture with no branch.txt degrades lens 3 rather than reading the live branch" \
   "$(F lens-3-no-branch 'd["lenses"]["3"]["degraded_id"]')" "D5"

# S — the published interface: "2 usage or a contract violation". A bare --fixture used to abort on
# an unbound variable under `set -u`, which is exit 1 and a bash error, not the documented contract.
bash "$ROOT_DIR/skills/standup/collect.sh" --fixture >/dev/null 2>&1
is "a bare --fixture is a usage error with the published exit 2" "$?" "2"
bash "$ROOT_DIR/skills/standup/collect.sh" --nope >/dev/null 2>&1
is "  as is an unknown argument" "$?" "2"

echo
# ── 16. Round-5 review: the decoder corrupted the very case it was written to preserve ───────────
# Section 15's C-quoted fixture used only ASCII escapes (\" and \t), which round-trip through
# `unicode_escape` unharmed. The OCTAL escapes do not, and octal is how git quotes every non-ASCII
# filename — the common case, not the exotic one. Third round running where the fixture was shaped
# like the finding rather than like the failure.
is "an octal-escaped UTF-8 filename decodes to the real bytes, not mojibake" \
   "$(F lens-2-utf8 'd["lenses"]["2"]["candidates"][0]["evidence_payload"]')" "é.txt"
is "  so the lens stays ok instead of degrading on an ordinary accented filename" \
   "$(F lens-2-utf8 'd["lenses"]["2"]["status"]')" "ok"
is "  and its stat resolves against the decoded name" \
   "$(F lens-2-utf8 'd["lenses"]["2"]["candidates"][0]["staleness"]')" "1740000000"

# `git rev-list --left-right --count` has a TWO-INTEGER contract. Reading $1 and $2 and ignoring the
# rest let `1 2 trailing-garbage` satisfy both integer checks and emit a confident
# `counts:2/1@tracked`. A bounded read parsed incompletely is still a malformed read.
is "a rev-list result with an extra field degrades rather than becoming a finding" \
   "$(F lens-3-trailing 'd["lenses"]["3"]["degraded_id"]')" "D5"

# The missing-branch.txt case was pinned in section 15; the PRESENT-but-EMPTY case was not, and it
# took the other branch — emitting an ok candidate keyed `branch:` whose close read
# `inspect: branch  (push state unknown, no upstream)`.
is "an empty branch.txt degrades too, not just an absent one" \
   "$(F lens-3-empty-branch 'd["lenses"]["3"]["degraded_id"]')" "D5"

# A legal path beginning with `-` is read by git as an option, so the close command was unusable for
# exactly the file it named. `--` ends option parsing.
has "a leading-dash path is protected by -- in the close command" \
    "$(F lens-2-dash-path 'd["lenses"]["2"]["candidates"][0]["close"]')" "git add -- '-weird.md'"

echo
# ── 17. Round-6: the parse boundary is strict, and its failures are visible ──────────────────────
# The reviewer's round-6 verdict was structural rather than another list of cases: make
# `porcelain_rows` a strict, error-propagating boundary instead of patching one more edge case. Every
# prior round had added a case and left a neighbouring one open. These assertions pin the CONTRACT —
# every row is understood and emitted, or the decoder fails and the lens degrades, with no third
# outcome — rather than pinning three more inputs.

# A row with a status field and no pathname was a successful read that emitted nothing and left the
# lens `ok`: a parse failure wearing the same face as a clean tree.
is "a porcelain row with no pathname degrades rather than reading as a clean tree" \
   "$(F lens-2-no-path 'd["lenses"]["2"]["degraded_id"]')" "D5"
# An undecodable quoted name crashed the decoder, whose exit status process substitution discarded.
is "an undecodable quoted name propagates the decoder's failure as D5" \
   "$(F lens-2-undecodable 'd["lenses"]["2"]["degraded_id"]')" "D5"
is "  and neither one is reported as a successful collection" \
   "$(C lens-2-undecodable >/dev/null; echo $?)" "3"

# A newline in a pathname is LEGAL. Decoding it correctly (round 5) then made it breach the skill's
# one-line output contract: triage.py escapes the em-dash delimiter and nothing else, so one
# candidate would render as several physical lines and could fabricate apparent output lines.
# triage.py is out of scope and should be — the collector is what knows the path is unrenderable.
is "a newline pathname is emitted with an escaped one-line display" \
   "$(F lens-2-newline-path 'd["lenses"]["2"]["candidates"][0]["evidence_payload"]')" 'a\nb.txt'
is "  as an inspect action, not a command built from an unrenderable name" \
   "$(F lens-2-newline-path 'd["lenses"]["2"]["candidates"][0]["close_kind"]')" "inspect"
is "  and it is never dropped — the operator still learns the file is there" \
   "$(F lens-2-newline-path 'len(d["lenses"]["2"]["candidates"])')" "1"
# THE PIN for this section: the rendered screen stays one line per item.
C lens-2-newline-path > "$W/nl.json" 2>/dev/null
is "  so the rendered screen keeps one physical line per item" \
   "$(T "$W/nl.json" --dry-run 2>&1 | wc -l | tr -d ' ')" "5"

# The round-5 trailing-field pin passed for the WRONG REASON: its fixture supplied no date, so the
# malformed count was caught by the later missing-date degradation rather than by the count guard.
# The fixture now carries a valid date, so this measures the primary parse — which was still using
# `awk $1/$2` while only the fallback had the exact-field guard.
is "the PRIMARY rev-list parse rejects an extra field, not just the fallback" \
   "$(F lens-3-trailing 'd["lenses"]["3"]["degraded_id"]')" "D5"

echo
echo "  gh77-standup-triage: $pass pass, $fail fail"
[ "$fail" -eq 0 ]
