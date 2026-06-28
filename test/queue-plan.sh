#!/usr/bin/env bash
# test/queue-plan.sh — regression lock for utils/queue-plan.sh.
#
# Standalone (no tick/relay harness). Builds throwaway repos with a synthetic ROADMAP.md ledger +
# rated capture docs + preflight contracts, and stubs git/gh via the planner's hermetic env seam
# (QUEUE_PLAN_GH_STATE_FILE / QUEUE_PLAN_BRANCHES_FILE). Asserts the deterministic sequencing
# (scores, waves, collision-safety), every validation signal (already-closed / already-landed /
# partial / drift / unrated / note-only), the policy flip, gh degradation, and --check determinism.

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
QP="$ROOT/utils/queue-plan.sh"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/queue-plan.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

PASS=0; FAIL=0
pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }

DAY="2026-06-28"
NOWT="2026-06-28T00:00:00Z"

echo "== test: queue-plan =="
echo "  workdir: $WORK"

# mk_doc <root> <filename> <cx> <risk> <eff> <contract-json>   ("-" for a rating ⇒ omit that key;
#                                                                "" contract ⇒ no preflight contract)
mk_doc() {
  local root="$1" fn="$2" cx="$3" rk="$4" ef="$5" contract="$6"
  mkdir -p "$root/PROJECT/2-WORKING"
  {
    printf -- '---\n'
    printf 'title: %s\n' "$fn"
    [ "$cx" != "-" ] && printf 'complexity: %s\n' "$cx"
    [ "$rk" != "-" ] && printf 'risk: %s\n' "$rk"
    [ "$ef" != "-" ] && printf 'effort: %s\n' "$ef"
    printf -- '---\n\n# %s\n\n' "$fn"
    [ -n "$contract" ] && printf '## Swarm Preflight Contract\n```json\n%s\n```\n' "$contract"
  } >"$root/PROJECT/2-WORKING/$fn"
}

# run_qp <root> [args...]
run_qp() {
  local root="$1"; shift
  QUEUE_PLAN_ROOT="$root" QUEUE_PLAN_TODAY="$DAY" QUEUE_PLAN_NOW="$NOWT" \
    QUEUE_PLAN_GH_STATE_FILE="$root/.gh-state.json" QUEUE_PLAN_BRANCHES_FILE="$root/.branches" \
    bash "$QP" "$@"
}

# wave_of <queue-doc> <issue-number> → wave number containing #N (empty if not waved)
wave_of() {
  grep -E '^\*\*Wave ' "$1" | grep -E "#$2([^0-9]|\$)" | sed -E 's/^\*\*Wave ([0-9]+).*/\1/' | head -1
}
# row_index <queue-doc> <issue-number> → line number of its per-item scoring row (sequence order)
row_index() { grep -nE "\[#$2\]" "$1" | head -1 | cut -d: -f1; }

contract_for() { # contract_for <missing-or-present-path> <artifact1> [artifact2]
  local probe="$1"; shift
  local arts="" a
  for a in "$@"; do arts="$arts${arts:+,}\"$a\""; done
  printf '{"target":{"repo":".","ref":"main"},"gate":"true","fix_probes":[{"type":"path_absent","path":"%s"}],"artifacts":[%s],"lanes":{"orchestrator_only":[]}}' "$probe" "$arts"
}

# ─────────────────────────────────────────────────────────────────────────────
# Scenario A — sequencing & collision-safe wave packing (clean, exit 0)
# ─────────────────────────────────────────────────────────────────────────────
A="$WORK/A"; mkdir -p "$A"; echo '{}' >"$A/.gh-state.json"; : >"$A/.branches"
mk_doc "$A" GH-100-kernela.md low low low "$(contract_for MISS_A bin/tick)"
mk_doc "$A" GH-101-kernelb.md low low low "$(contract_for MISS_B relay-automation/relay-drive.sh)"
mk_doc "$A" GH-102-indepa.md  low low low "$(contract_for MISS_C src/indepa.js)"
mk_doc "$A" GH-103-indepb.md  low low low "$(contract_for MISS_D src/indepb.js)"
mk_doc "$A" GH-104-shimdep.md low low low "$(contract_for MISS_E relay-automation/consult.sh)"
cat >"$A/ROADMAP.md" <<EOF
# Roadmap
## Ledger
### In progress
- **GH-100 · kernelA** 🆕 — kernel lane → [d](PROJECT/2-WORKING/GH-100-kernela.md) · [#100](https://github.com/o/r/issues/100)
- **GH-101 · kernelB** 🆕 — kernel lane → [d](PROJECT/2-WORKING/GH-101-kernelb.md) · [#101](https://github.com/o/r/issues/101)
- **GH-102 · indepA** 🆕 — independent → [d](PROJECT/2-WORKING/GH-102-indepa.md) · [#102](https://github.com/o/r/issues/102)
- **GH-103 · indepB** 🆕 — independent → [d](PROJECT/2-WORKING/GH-103-indepb.md) · [#103](https://github.com/o/r/issues/103)
- **GH-104 · shimDep** 🆕 — shim, scheduled after GH-100 → [d](PROJECT/2-WORKING/GH-104-shimdep.md) · [#104](https://github.com/o/r/issues/104)
EOF
out="$(run_qp "$A" 2>/dev/null)"; rc=$?
doc="$A/PROJECT/2-WORKING/QUEUE-$DAY.md"
[[ $rc -eq 0 ]] && pass "A: clean plan → exit 0" || fail "A: expected exit 0, got $rc"
[[ -f "$doc" ]] && pass "A: QUEUE doc written" || fail "A: QUEUE doc not written"
grep -q "active lanes : 5 across 2 wave(s)" <<<"$out" && pass "A: 5 active across 2 waves" || fail "A: wrong active/wave count — $(grep 'active lanes' <<<"$out")"
[[ "$(wave_of "$doc" 102)" == "1" && "$(wave_of "$doc" 103)" == "1" ]] && pass "A: two disjoint independents share Wave 1" || fail "A: indeps not both Wave 1 (102=$(wave_of "$doc" 102) 103=$(wave_of "$doc" 103))"
ka="$(wave_of "$doc" 100)"; kb="$(wave_of "$doc" 101)"
[[ -n "$ka" && -n "$kb" && "$ka" != "$kb" ]] && pass "A: two kernel items never share a wave (100=$ka 101=$kb)" || fail "A: kernel items shared a wave (100=$ka 101=$kb)"
sd="$(wave_of "$doc" 104)"
[[ -n "$sd" && -n "$ka" && "$sd" -gt "$ka" ]] && pass "A: shim dep-on-kernel sequenced strictly later (shim=$sd kernel=$ka)" || fail "A: shim not after its kernel dep (shim=$sd kernel=$ka)"

# ─────────────────────────────────────────────────────────────────────────────
# Scenario B — validation signals (drift present, exit 4)
# ─────────────────────────────────────────────────────────────────────────────
B="$WORK/B"; mkdir -p "$B"; : >"$B/.branches"
echo '{"200":"CLOSED","221":"OPEN"}' >"$B/.gh-state.json"
touch "$B/LANDED_FILE"                                   # makes the already-landed probe report "landed"
printf 'changelog mentions gh-220-partial here\n' >"$B/CHANGELOG.md"
mk_doc "$B" GH-200-closed.md   low low low "$(contract_for MISS_X src/x.js)"
mk_doc "$B" GH-210-landed.md   low low low "$(contract_for LANDED_FILE src/y.js)"
mk_doc "$B" GH-220-partial.md  low low low "$(contract_for MISS_P src/p.js)"
mk_doc "$B" GH-221-onesig.md   low low low "$(contract_for MISS_O src/o.js)"
mk_doc "$B" GH-230-unrated.md  low -   low "$(contract_for MISS_U src/u.js)"
mk_doc "$B" GH-250-gated.md    low low low "$(contract_for MISS_G src/g.js)"
cat >"$B/ROADMAP.md" <<EOF
# Roadmap
## Ledger
### In progress
- **GH-200 · closed item** 🟡 — listed but closed → [d](PROJECT/2-WORKING/GH-200-closed.md) · [#200](https://github.com/o/r/issues/200)
- **GH-210 · landed item** 🟢 — built → [d](PROJECT/2-WORKING/GH-210-landed.md) · [#210](https://github.com/o/r/issues/210)
- **GH-220 · partial item** 🟢 — partly built → [d](PROJECT/2-WORKING/GH-220-partial.md) · [#220](https://github.com/o/r/issues/220)
- **GH-221 · onesig item** 🟢 — only the emoji signal → [d](PROJECT/2-WORKING/GH-221-onesig.md) · [#221](https://github.com/o/r/issues/221)
- **GH-250 · gated item** 🟡 — gated on operator GO → [d](PROJECT/2-WORKING/GH-250-gated.md) · [#250](https://github.com/o/r/issues/250)
### Queue / parked intake
- **GH-230 · unrated item** 🆕 — missing a rating → [d](PROJECT/2-WORKING/GH-230-unrated.md) · [#230](https://github.com/o/r/issues/230)
- **GH-240 · dead pointer** 🆕 — doc link is broken → [d](PROJECT/2-WORKING/GH-240-missing.md) · [#240](https://github.com/o/r/issues/240)
- **Just a field note** 🐞 — a finding with no issue and no doc, nothing to build.
EOF
out="$(run_qp "$B" 2>/dev/null)"; rc=$?
doc="$B/PROJECT/2-WORKING/QUEUE-$DAY.md"
[[ $rc -eq 4 ]] && pass "B: drift present → exit 4" || fail "B: expected exit 4, got $rc"
grep -q "already-closed.*closed item\|already-closed]  GH-200" <<<"$out" && pass "B: #200 flagged already-closed" || fail "B: #200 not flagged already-closed"
[[ -z "$(wave_of "$doc" 200)" ]] && pass "B: closed item excluded from waves" || fail "B: closed item appeared in a wave"
grep -q "already-landed]  GH-210" <<<"$out" && pass "B: #210 flagged already-landed (fix_probes landed)" || fail "B: #210 not flagged already-landed"
[[ -z "$(wave_of "$doc" 210)" ]] && pass "B: landed item excluded from waves" || fail "B: landed item appeared in a wave"
grep -q "undocumented-partial-completion]  GH-220" <<<"$out" && pass "B: #220 flagged partial (2 signals)" || fail "B: #220 not flagged partial"
! grep -q "undocumented-partial-completion]  GH-221" <<<"$out" && pass "B: #221 NOT flagged partial (1 signal < threshold)" || fail "B: #221 wrongly flagged partial"
[[ -n "$(wave_of "$doc" 221)" ]] && pass "B: one-signal item still active (in a wave)" || fail "B: one-signal item not active"
grep -q "unrated]  GH-230" <<<"$out" && pass "B: #230 flagged unrated" || fail "B: #230 not flagged unrated"
grep -qE "drift].*(dead pointer|GH-240|missing)" <<<"$out" && pass "B: dead doc pointer flagged drift" || fail "B: dead pointer not flagged"
grep -q "note-only]" <<<"$out" && pass "B: note-only bullet flagged" || fail "B: note-only not flagged"
grep -q "Gated on operator GO" "$doc" && grep -q "#250" "$doc" && pass "B: gated item parked in Held/Gated bucket" || fail "B: gated item not in gated bucket"
[[ -z "$(wave_of "$doc" 250)" ]] && pass "B: gated item excluded from active waves" || fail "B: gated item appeared in a wave"

# ─────────────────────────────────────────────────────────────────────────────
# Scenario C — policy flip (quick-wins vs derisk-first reverse a high-risk item)
# ─────────────────────────────────────────────────────────────────────────────
C="$WORK/C"; mkdir -p "$C"; echo '{}' >"$C/.gh-state.json"; : >"$C/.branches"
mk_doc "$C" GH-300-low.md  low low  low "$(contract_for MISS_L src/low.js)"
mk_doc "$C" GH-301-high.md low high low "$(contract_for MISS_H src/high.js)"
cat >"$C/ROADMAP.md" <<EOF
# Roadmap
## Ledger
### In progress
- **GH-300 · low risk** 🆕 — → [d](PROJECT/2-WORKING/GH-300-low.md) · [#300](https://github.com/o/r/issues/300)
- **GH-301 · high risk** 🆕 — → [d](PROJECT/2-WORKING/GH-301-high.md) · [#301](https://github.com/o/r/issues/301)
EOF
run_qp "$C" >/dev/null 2>&1; doc="$C/PROJECT/2-WORKING/QUEUE-$DAY.md"
[[ "$(row_index "$doc" 300)" -lt "$(row_index "$doc" 301)" ]] && pass "C: quick-wins ranks low-risk first" || fail "C: quick-wins order wrong"
run_qp "$C" --policy derisk-first >/dev/null 2>&1
[[ "$(row_index "$doc" 301)" -lt "$(row_index "$doc" 300)" ]] && pass "C: derisk-first ranks high-risk first (order flipped)" || fail "C: derisk-first did not flip order"

# ─────────────────────────────────────────────────────────────────────────────
# Scenario D — gh degradation
# ─────────────────────────────────────────────────────────────────────────────
QUEUE_PLAN_ROOT="$C" QUEUE_PLAN_TODAY="$DAY" QUEUE_PLAN_NOW="$NOWT" QUEUE_PLAN_GH=off \
  bash "$QP" --dry-run >"$WORK/qp_d.out" 2>/dev/null; rc=$?
[[ $rc -eq 0 ]] && pass "D: gh disabled → still emits a plan, exit 0" || fail "D: gh-off expected exit 0, got $rc"
grep -q "gh=off" "$WORK/qp_d.out" && pass "D: report announces gh=off" || fail "D: gh=off not announced"
QUEUE_PLAN_ROOT="$C" QUEUE_PLAN_TODAY="$DAY" QUEUE_PLAN_NOW="$NOWT" QUEUE_PLAN_GH=off \
  bash "$QP" --dry-run --require-gh >/dev/null 2>&1; rc=$?
[[ $rc -eq 6 ]] && pass "D: --require-gh + gh-off → exit 6" || fail "D: expected exit 6, got $rc"

# ─────────────────────────────────────────────────────────────────────────────
# Scenario E — --check determinism / drift guard
# ─────────────────────────────────────────────────────────────────────────────
run_qp "$C" >/dev/null 2>&1                       # write today's QUEUE doc
run_qp "$C" --check >/dev/null 2>&1; rc=$?
[[ $rc -eq 0 ]] && pass "E: --check in sync → exit 0" || fail "E: --check expected exit 0, got $rc"
printf '\n- **Drifted note** 🐞 — a new ledger note, no issue, no doc.\n' >>"$C/ROADMAP.md"
run_qp "$C" --check >/dev/null 2>&1; rc=$?
[[ $rc -eq 1 ]] && pass "E: ledger change → --check detects drift (exit 1)" || fail "E: --check did not detect drift, got $rc"

# ─────────────────────────────────────────────────────────────────────────────
# Scenario F — JSON output shape
# ─────────────────────────────────────────────────────────────────────────────
json="$(run_qp "$A" --dry-run --format json 2>/dev/null)"
echo "$json" | while IFS= read -r line; do [ -n "$line" ] && printf '%s' "$line" | node -e 'JSON.parse(require("fs").readFileSync(0,"utf8"))' || exit 1; done \
  && pass "F: --format json emits one valid JSON object per line" || fail "F: json lines not all valid"
grep -q '"check":"queue-plan/summary"' <<<"$json" && pass "F: json includes a summary record" || fail "F: json summary missing"

echo
echo "  queue-plan: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]]
