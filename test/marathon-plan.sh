#!/usr/bin/env bash
# test/marathon-plan.sh — regression lock for utils/marathon-plan.sh.
#
# Standalone (no tick/relay harness). Builds throwaway repos with a synthetic ROADMAP.md ledger +
# rated capture docs + preflight contracts, and stubs git/gh via the planner's hermetic env seam
# (QUEUE_PLAN_GH_STATE_FILE / QUEUE_PLAN_BRANCHES_FILE). Asserts the deterministic sequencing
# (scores, waves, collision-safety), every validation signal (already-closed / already-landed /
# partial / drift / unrated / note-only), the policy flip, gh degradation, and --check determinism.

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
QP="$ROOT/utils/marathon-plan.sh"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/marathon-plan.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

PASS=0; FAIL=0; SKIP=0
pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
# GH-348: a skip must be LOUD and counted. The bug this file used to carry was a cross-lane assertion
# that silently compared one lane to itself; a silent skip would recreate it in a new shape.
skip() { echo "  SKIP: $*" >&2; SKIP=$((SKIP+1)); }

DAY="2026-06-28"
NOWT="2026-06-28T00:00:00Z"

echo "== test: marathon-plan =="
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

# run_qp_py <root> [args...] — explicitly the Python lane.
run_qp_py() {
  local root="$1"; shift
  QUEUE_PLAN_ROOT="$root" QUEUE_PLAN_TODAY="$DAY" QUEUE_PLAN_NOW="$NOWT" \
    QUEUE_PLAN_GH_STATE_FILE="$root/.gh-state.json" QUEUE_PLAN_BRANCHES_FILE="$root/.branches" \
    XYZ_PYTHON=1 bash "$QP" "$@"
}

# run_qp_sh <root> [args...] — explicitly the BASH/node engine.
#
# GH-348, and the reason this exists: `run_qp` above sets no XYZ_PYTHON, and utils/marathon-plan.sh:6
# reads `${XYZ_PYTHON-1}` — defaulting to 1. So run_qp is the PYTHON lane, and Scenario T's
# "matches between shell and XYZ_PYTHON=1" was comparing Python to Python. Mutating the Bash engine's
# rendered output left the whole file at 60/0, both T assertions green, for as long as that was true.
#
# marathon-plan is the ONE entry point GH-308 deliberately exempted from Python authority — the Bash
# twin stays dual-maintained — so cross-lane drift here is expected, not theoretical. It has already
# happened twice: GH-154 (missing GH-48 zone model) and GH-255 (two more gaps, papered over with
# pre/post-processing shims). Scenario T was added by GH-154 to stop the third instance, and until
# this helper landed it could not.
#
# The other 58 cases keep using run_qp on purpose: unset XYZ_PYTHON is what production runs.
run_qp_sh() {
  local root="$1"; shift
  QUEUE_PLAN_ROOT="$root" QUEUE_PLAN_TODAY="$DAY" QUEUE_PLAN_NOW="$NOWT" \
    QUEUE_PLAN_GH_STATE_FILE="$root/.gh-state.json" QUEUE_PLAN_BRANCHES_FILE="$root/.branches" \
    XYZ_PYTHON=0 bash "$QP" "$@"
}

# wave_of <queue-doc> <issue-number> → wave number containing #N (empty if not waved)
wave_of() {
  grep -E '^\*\*Wave ' "$1" | grep -E "#$2([^0-9]|\$)" | sed -E 's/^\*\*Wave ([0-9]+).*/\1/' | head -1
}
# row_index <queue-doc> <issue-number> → line number of its per-item scoring row (sequence order)
row_index() { grep -nE "\[#$2\]" "$1" | head -1 | cut -d: -f1; }
zone_cell() { grep -E "\[#$2\]" "$1" | head -1 | awk -F'|' '{gsub(/^ +| +$/, "", $6); print $6}'; }

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
mk_doc "$A" GH-100-kernela.md 2 2 2 "$(contract_for MISS_A bin/tick)"
mk_doc "$A" GH-101-kernelb.md 2 2 2 "$(contract_for MISS_B relay-automation/relay-drive.sh)"
mk_doc "$A" GH-102-indepa.md  2 2 2 "$(contract_for MISS_C src/indepa.js)"
mk_doc "$A" GH-103-indepb.md  2 2 2 "$(contract_for MISS_D src/indepb.js)"
mk_doc "$A" GH-104-shimdep.md 2 2 2 "$(contract_for MISS_E relay-automation/consult.sh)"
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
doc="$A/PROJECT/2-WORKING/MARATHON-PLAN-$DAY.md"
[[ $rc -eq 0 ]] && pass "A: clean plan → exit 0" || fail "A: expected exit 0, got $rc"
[[ -f "$doc" ]] && pass "A: MARATHON-PLAN doc written" || fail "A: MARATHON-PLAN doc not written"
grep -q "active lanes : 5 across 2 wave(s)" <<<"$out" && pass "A: 5 active across 2 waves" || fail "A: wrong active/wave count — $(grep 'active lanes' <<<"$out")"
[[ "$(wave_of "$doc" 102)" == "1" && "$(wave_of "$doc" 103)" == "1" ]] && pass "A: two disjoint independents share Wave 1" || fail "A: indeps not both Wave 1 (102=$(wave_of "$doc" 102) 103=$(wave_of "$doc" 103))"
ka="$(wave_of "$doc" 100)"; kb="$(wave_of "$doc" 101)"
[[ -n "$ka" && -n "$kb" && "$ka" != "$kb" ]] && pass "A: two kernel items never share a wave (100=$ka 101=$kb)" || fail "A: kernel items shared a wave (100=$ka 101=$kb)"
sd="$(wave_of "$doc" 104)"
[[ -n "$sd" && -n "$ka" && "$sd" -gt "$ka" ]] && pass "A: shim dep-on-kernel sequenced strictly later (shim=$sd kernel=$ka)" || fail "A: shim not after its kernel dep (shim=$sd kernel=$ka)"

# GH-69: deterministic suggested_branch per active lane, from slug + run date — no git writes.
grep -qF 'suggested_branch: `marathon/gh-100-kernela-'"$DAY"'`' "$doc" \
  && pass "A: #100 gets a deterministic suggested_branch" \
  || fail "A: #100 missing suggested_branch line"
[[ "$(grep -cF 'suggested_branch: `marathon/' "$doc")" -eq 5 ]] \
  && pass "A: all 5 active lanes carry a suggested_branch" \
  || fail "A: expected 5 suggested_branch lines, got $(grep -cF 'suggested_branch: `marathon/' "$doc")"
# Same-day re-run is deterministic (byte-identical slug+date ⇒ same branch name).
run_qp "$A" >/dev/null 2>&1
grep -qF 'suggested_branch: `marathon/gh-100-kernela-'"$DAY"'`' "$doc" \
  && pass "A: suggested_branch is stable across a same-day re-run" \
  || fail "A: suggested_branch drifted on re-run"

# ─────────────────────────────────────────────────────────────────────────────
# Scenario B — validation signals (drift present, exit 4)
# ─────────────────────────────────────────────────────────────────────────────
B="$WORK/B"; mkdir -p "$B"; echo "gh-220-partial" >"$B/.branches"
echo '{"200":"CLOSED","221":"OPEN"}' >"$B/.gh-state.json"
touch "$B/LANDED_FILE"                                   # makes the already-landed probe report "landed"
printf 'changelog mentions gh-220-partial here\n' >"$B/CHANGELOG.md"
mk_doc "$B" GH-200-closed.md   2 2 2 "$(contract_for MISS_X src/x.js)"
mk_doc "$B" GH-210-landed.md   2 2 2 "$(contract_for LANDED_FILE src/y.js)"
mk_doc "$B" GH-220-partial.md  2 2 2 "$(contract_for MISS_P src/p.js)"
mk_doc "$B" GH-221-onesig.md   2 2 2 "$(contract_for MISS_O src/o.js)"
mk_doc "$B" GH-230-unrated.md  2 -   2 "$(contract_for MISS_U src/u.js)"
mk_doc "$B" GH-250-gated.md    2 2 2 "$(contract_for MISS_G src/g.js)"
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
doc="$B/PROJECT/2-WORKING/MARATHON-PLAN-$DAY.md"
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
mk_doc "$C" GH-300-low.md  2 2  2 "$(contract_for MISS_L src/low.js)"
mk_doc "$C" GH-301-high.md 2 4 2 "$(contract_for MISS_H src/high.js)"
cat >"$C/ROADMAP.md" <<EOF
# Roadmap
## Ledger
### In progress
- **GH-300 · low risk** 🆕 — → [d](PROJECT/2-WORKING/GH-300-low.md) · [#300](https://github.com/o/r/issues/300)
- **GH-301 · high risk** 🆕 — → [d](PROJECT/2-WORKING/GH-301-high.md) · [#301](https://github.com/o/r/issues/301)
EOF
run_qp "$C" >/dev/null 2>&1; doc="$C/PROJECT/2-WORKING/MARATHON-PLAN-$DAY.md"
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
run_qp "$C" >/dev/null 2>&1                       # write today's MARATHON-PLAN doc
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
grep -q '"check":"marathon-plan/summary"' <<<"$json" && pass "F: json includes a summary record" || fail "F: json summary missing"

# ─────────────────────────────────────────────────────────────────────────────
# Scenario G — agy QA [Blocker]: a dep on a HELD (not-built) item must defer the dependent
# ─────────────────────────────────────────────────────────────────────────────
G="$WORK/G"; mkdir -p "$G"; echo '{}' >"$G/.gh-state.json"; : >"$G/.branches"
mk_doc "$G" GH-700-free.md   2 2 2 "$(contract_for MISS_F  src/free.js)"
mk_doc "$G" GH-701-dephld.md 2 2 2 "$(contract_for MISS_DH src/dephld.js)"
mk_doc "$G" GH-710-held.md   2 -   2 "$(contract_for MISS_HE src/held.js)"   # unrated ⇒ held
cat >"$G/ROADMAP.md" <<EOF
# Roadmap
## Ledger
### In progress
- **GH-700 · free** 🆕 — → [d](PROJECT/2-WORKING/GH-700-free.md) · [#700](https://github.com/o/r/issues/700)
- **GH-701 · dep on held** 🆕 — depends on GH-710 → [d](PROJECT/2-WORKING/GH-701-dephld.md) · [#701](https://github.com/o/r/issues/701)
- **GH-710 · held (unrated)** 🆕 — → [d](PROJECT/2-WORKING/GH-710-held.md) · [#710](https://github.com/o/r/issues/710)
EOF
out="$(run_qp "$G" 2>/dev/null)"; doc="$G/PROJECT/2-WORKING/MARATHON-PLAN-$DAY.md"
w700="$(wave_of "$doc" 700)"; w701="$(wave_of "$doc" 701)"
{ [[ "$w700" == "1" && -z "$w701" ]] && grep -q "blocked-dep]  GH-701" <<<"$out"; } && pass "G: dep on a HELD item EXCLUDES the dependent (700=wave$w700; 701 blocked-dep, not waved) [agy Blocker r1+r3]" || fail "G: dependent-on-held not excluded (700=$w700 701=$w701)"

# ─────────────────────────────────────────────────────────────────────────────
# Scenario H — agy QA [Should]: comma-separated deps must ALL be parsed
# ─────────────────────────────────────────────────────────────────────────────
H="$WORK/H"; mkdir -p "$H"; echo '{}' >"$H/.gh-state.json"; : >"$H/.branches"
mk_doc "$H" GH-800-k1.md    2 2 2 "$(contract_for MISS_K1 bin/tick)"
mk_doc "$H" GH-801-k2.md    2 2 2 "$(contract_for MISS_K2 relay-automation/relay-drive.sh)"
mk_doc "$H" GH-803-k3.md    2 2 2 "$(contract_for MISS_K3 relay-automation/relay-turn-lib.sh)"
mk_doc "$H" GH-802-multi.md 2 2 2 "$(contract_for MISS_M  src/multi.js)"
cat >"$H/ROADMAP.md" <<EOF
# Roadmap
## Ledger
### In progress
- **GH-800 · kernel1** 🆕 — → [d](PROJECT/2-WORKING/GH-800-k1.md) · [#800](https://github.com/o/r/issues/800)
- **GH-801 · kernel2** 🆕 — → [d](PROJECT/2-WORKING/GH-801-k2.md) · [#801](https://github.com/o/r/issues/801)
- **GH-803 · kernel3** 🆕 — → [d](PROJECT/2-WORKING/GH-803-k3.md) · [#803](https://github.com/o/r/issues/803)
- **GH-802 · multi-dep** 🆕 — depends on GH-800, GH-801, and GH-803 → [d](PROJECT/2-WORKING/GH-802-multi.md) · [#802](https://github.com/o/r/issues/802)
EOF
run_qp "$H" >/dev/null 2>&1; doc="$H/PROJECT/2-WORKING/MARATHON-PLAN-$DAY.md"
w800="$(wave_of "$doc" 800)"; w801="$(wave_of "$doc" 801)"; w803="$(wave_of "$doc" 803)"; w802="$(wave_of "$doc" 802)"
# Oxford-comma "GH-800, GH-801, and GH-803" — all three must parse, so the dependent follows the LAST (803).
[[ -n "$w802" && "$w802" -gt "$w800" && "$w802" -gt "$w801" && "$w802" -gt "$w803" ]] && pass "H: oxford-comma deps all parsed — multi-dep follows ALL kernels (800=$w800 801=$w801 803=$w803 802=$w802) [agy Blocker r2]" || fail "H: oxford-comma deps not all honored (800=$w800 801=$w801 803=$w803 802=$w802)"

# ─────────────────────────────────────────────────────────────────────────────
# Scenario I — agy QA [Blocker r4]: title GH-NN is canonical, beats an in-prose issue link
# ─────────────────────────────────────────────────────────────────────────────
I="$WORK/I"; mkdir -p "$I"; : >"$I/.branches"
echo '{"910":"OPEN","911":"CLOSED"}' >"$I/.gh-state.json"
mk_doc "$I" GH-910-epic.md 2 2 2 "$(contract_for MISS_E2 src/epic.js)"
cat >"$I/ROADMAP.md" <<EOF
# Roadmap
## Ledger
### In progress
- **GH-910 · epic umbrella** 🆕 — sequences the sub-issue [#911](https://github.com/o/r/issues/911) → [d](PROJECT/2-WORKING/GH-910-epic.md) · [#910](https://github.com/o/r/issues/910)
EOF
out="$(run_qp "$I" 2>/dev/null)"; doc="$I/PROJECT/2-WORKING/MARATHON-PLAN-$DAY.md"
{ [[ "$(wave_of "$doc" 910)" == "1" ]] && ! grep -q "already-closed" <<<"$out"; } && pass "I: title GH-910 wins over the in-prose closed #911 (item stays active, not already-closed) [agy Blocker r4]" || fail "I: ghIssueOf precedence wrong — $(grep -E 'already-closed' <<<"$out" | head -1)"

# ─────────────────────────────────────────────────────────────────────────────
# Scenario J — GH-85 regression cases for undocumented-partial-completion false-positives
# ─────────────────────────────────────────────────────────────────────────────
J="$WORK/J"; mkdir -p "$J"; : >"$J/.branches"
echo '{}' >"$J/.gh-state.json"

# (a) A rated+contracted lane whose artifacts all pre-exist AND whose #n is in CHANGELOG is classified READY / active (not partial).
printf 'changelog mentions gh-950-existing here (#950)\n' >"$J/CHANGELOG.md"
mkdir -p "$J/src"
touch "$J/src/existing_art.js"
echo "src/existing_art.js" >"$J/.base-files"
mk_doc "$J" GH-950-existing.md 2 2 2 "$(contract_for MISS_EXP src/existing_art.js)"

# (b) A lane with genuine partial signals (branch-matches-slug + tests-reference-slug) is STILL partial.
echo "gh-951-genuine" >"$J/.branches"
mkdir -p "$J/test"
touch "$J/test/gh-951-genuine-test.sh"
mk_doc "$J" GH-951-genuine.md 2 2 2 "$(contract_for MISS_GEN src/genuine_art.js)"

cat >"$J/ROADMAP.md" <<EOF
# Roadmap
## Ledger
### In progress
- **GH-950 · existing artifact** 🆕 — all artifacts pre-exist → [d](PROJECT/2-WORKING/GH-950-existing.md) · [#950](https://github.com/o/r/issues/950)
- **GH-951 · genuine partial** 🆕 — genuine partial signals → [d](PROJECT/2-WORKING/GH-951-genuine.md) · [#951](https://github.com/o/r/issues/951)
EOF

out="$(QUEUE_PLAN_BASE_FILES_FILE="$J/.base-files" run_qp "$J" 2>/dev/null)"
doc="$J/PROJECT/2-WORKING/MARATHON-PLAN-$DAY.md"

if ! grep -q "undocumented-partial-completion.*GH-950" <<<"$out" && [[ "$(wave_of "$doc" 950)" == "1" ]]; then
  pass "J: (a) edit-existing-file lane in CHANGELOG is READY / active (not partial) [GH-85]"
else
  fail "J: (a) edit-existing-file lane was wrongly flagged partial or excluded from waves"
fi

if grep -q "undocumented-partial-completion.*GH-951" <<<"$out" && [[ -z "$(wave_of "$doc" 951)" ]]; then
  pass "J: (b) lane with genuine partial signals is STILL partial [GH-85]"
else
  fail "J: (b) lane with genuine partial signals was not flagged partial or got sequenced in waves"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Scenario K — GH-5: contract-seam detection (coupled same-wave lanes)
# ─────────────────────────────────────────────────────────────────────────────
K="$WORK/K"; mkdir -p "$K"; echo '{}' >"$K/.gh-state.json"; : >"$K/.branches"
# 920 + 921 are write-disjoint (producer.js vs consumer.js) but share the src/schema/ spine → coupled.
# 922 lives in a different subtree (utils/report.js) → NOT coupled with either.
mk_doc "$K" GH-920-producer.md 2 2 2 "$(contract_for MISS_SP src/schema/producer.js)"
mk_doc "$K" GH-921-consumer.md 2 2 2 "$(contract_for MISS_SC src/schema/consumer.js)"
mk_doc "$K" GH-922-report.md   2 2 2 "$(contract_for MISS_RP utils/report.js)"
cat >"$K/ROADMAP.md" <<EOF
# Roadmap
## Ledger
### In progress
- **GH-920 · producer** 🆕 — independent → [d](PROJECT/2-WORKING/GH-920-producer.md) · [#920](https://github.com/o/r/issues/920)
- **GH-921 · consumer** 🆕 — independent → [d](PROJECT/2-WORKING/GH-921-consumer.md) · [#921](https://github.com/o/r/issues/921)
- **GH-922 · report** 🆕 — independent → [d](PROJECT/2-WORKING/GH-922-report.md) · [#922](https://github.com/o/r/issues/922)
EOF
run_qp "$K" >/dev/null 2>&1
doc="$K/PROJECT/2-WORKING/MARATHON-PLAN-$DAY.md"
# all three write-disjoint → same wave; the seam detector must flag ONLY 920‖921 on src/schema.
seamline="$(grep -E '^\- \*\*Wave .*share ' "$doc" | grep 'src/schema')"
if [[ -n "$seamline" ]] && grep -q "#920" <<<"$seamline" && grep -q "#921" <<<"$seamline"; then
  pass "K: contract seam flagged — #920 ‖ #921 share src/schema/ (pin a contract)"
else
  fail "K: expected a src/schema seam warning for #920‖#921, got: $(grep -A3 'Contract seams' "$doc" | head -6)"
fi
# 922 shares no deep dir with 920/921 → must NOT appear in any seam line.
if grep -q "#922" <<<"$(grep -E '^\- \*\*Wave .*share ' "$doc")"; then
  fail "K: #922 (utils/report.js) wrongly flagged as a contract seam"
else
  pass "K: #922 in a disjoint subtree is NOT flagged as coupled (no false seam)"
fi
# the section names the fix (pin a CONTRACT.md) — the 'pin the contract' step made explicit (fix 1).
grep -qi "pin a .*CONTRACT" "$doc" && pass "K: plan states the 'pin a contract' step for the seam" || fail "K: no pin-a-contract guidance in the seam section"

# ── Scenario L — GH-5 (PR #103 review): trailing-slash DIRECTORY artifact still yields a seam.
# 930's write-set is a bare dir `src/api/`; only the trailing-slash fix keeps `src/api` in its
# prefix tree (the old dirPrefixes popped `api`), so the seam vs 931's `src/api/handler.js` fires.
L="$WORK/L"; mkdir -p "$L"; echo '{}' >"$L/.gh-state.json"; : >"$L/.branches"
mk_doc "$L" GH-930-dir.md  2 2 2 "$(contract_for MISS_DIR src/api/)"
mk_doc "$L" GH-931-file.md 2 2 2 "$(contract_for MISS_FILE src/api/handler.js)"
cat >"$L/ROADMAP.md" <<EOF
# Roadmap
## Ledger
### In progress
- **GH-930 · dir** 🆕 — independent → [d](PROJECT/2-WORKING/GH-930-dir.md) · [#930](https://github.com/o/r/issues/930)
- **GH-931 · file** 🆕 — independent → [d](PROJECT/2-WORKING/GH-931-file.md) · [#931](https://github.com/o/r/issues/931)
EOF
run_qp "$L" >/dev/null 2>&1
doc="$L/PROJECT/2-WORKING/MARATHON-PLAN-$DAY.md"
grep -q "src/api" <<<"$(grep -E '^\- \*\*Wave .*share ' "$doc")" \
  && pass "L: trailing-slash directory artifact (src/api/) still produces a seam on src/api" \
  || fail "L: trailing-slash dir artifact dropped the seam: $(grep -A3 'Contract seams' "$doc" | head -6)"

# ── Scenario M — GH-5 (PR #103 review): "deepest" = most SEGMENTS, not longest string.
# 940‖941 share `src/loooongname` (depth 2, long name) AND `x/a/b/c` (depth 4, short). The deepest
# by segment count is x/a/b/c; the old string-length proxy would have wrongly chosen src/loooongname.
M="$WORK/M"; mkdir -p "$M"; echo '{}' >"$M/.gh-state.json"; : >"$M/.branches"
mk_doc "$M" GH-940-a.md 2 2 2 "$(contract_for MISS_MA src/loooongname/a.js x/a/b/c/p.js)"
mk_doc "$M" GH-941-b.md 2 2 2 "$(contract_for MISS_MB src/loooongname/b.js x/a/b/c/q.js)"
cat >"$M/ROADMAP.md" <<EOF
# Roadmap
## Ledger
### In progress
- **GH-940 · a** 🆕 — independent → [d](PROJECT/2-WORKING/GH-940-a.md) · [#940](https://github.com/o/r/issues/940)
- **GH-941 · b** 🆕 — independent → [d](PROJECT/2-WORKING/GH-941-b.md) · [#941](https://github.com/o/r/issues/941)
EOF
run_qp "$M" >/dev/null 2>&1
doc="$M/PROJECT/2-WORKING/MARATHON-PLAN-$DAY.md"
seam="$(grep -E '^\- \*\*Wave .*share ' "$doc")"
if grep -q 'x/a/b/c' <<<"$seam" && ! grep -q 'loooongname' <<<"$seam"; then
  pass "M: deepest seam chosen by SEGMENT COUNT (x/a/b/c), not string length (src/loooongname)"
else
  fail "M: wrong deepest spine — expected x/a/b/c, got: $seam"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Scenario N — GH-86: surface the manual PR-review-lane overlay (Level 1 only)
# ─────────────────────────────────────────────────────────────────────────────
N="$WORK/N"; mkdir -p "$N"; echo '{}' >"$N/.gh-state.json"; : >"$N/.branches"
mk_doc "$N" GH-960-solo.md 2 2 2 "$(contract_for MISS_SOLO src/solo.js)"
cat >"$N/ROADMAP.md" <<EOF
# Roadmap
## Ledger
### In progress
- **GH-960 · solo item** 🆕 — → [d](PROJECT/2-WORKING/GH-960-solo.md) · [#960](https://github.com/o/r/issues/960)
EOF
doc="$N/PROJECT/2-WORKING/MARATHON-PLAN-$DAY.md"

# (a) no PR-REVIEW-QUEUE-<today>.md overlay -> no new section at all (zero-output-diff no-op).
run_qp "$N" >/dev/null 2>&1
! grep -q "## Review lanes" "$doc" \
  && pass "N: (a) no PR-REVIEW-QUEUE doc -> no Review lanes section [GH-86]" \
  || fail "N: (a) Review lanes section appeared with no overlay doc present"

# (b) a PR-REVIEW-QUEUE-<today>.md WITH 2 lanes in its ## Lanes table -> section appears, lists both.
cat >"$N/PROJECT/2-WORKING/PR-REVIEW-QUEUE-$DAY.md" <<EOF
---
title: PR review queue — $DAY
status: Active (2-WORKING)
roadmap_exempt: true
---

# PR review queue — $DAY

## Lanes

| Lane | PR | Reviewer | Artifact (read-only) | Fire (preflight → review) |
|---|---|---|---|---|
| R1 | #79 GH-77 aider lane | codex (harness/shim code) | \`gh pr diff 79\` | prep thread w/ \`--artifact-file\` → \`relay-drive --review-once\` |
| R2 | #81 GH-78 doc-preflight | agy (script + telemetry) | \`gh pr diff 81\` | prep thread w/ \`--artifact-file\` → \`relay-drive --review-once\` |
EOF
run_qp "$N" >/dev/null 2>&1
grep -qF "## Review lanes (manual overlay — run via relay-xyz)" "$doc" \
  && pass "N: (b) overlay present -> Review lanes section appears [GH-86]" \
  || fail "N: (b) Review lanes section missing with overlay doc present"
grep -q '| R1 | #79 GH-77 aider lane | codex (harness/shim code) |' "$doc" \
  && pass "N: (b) lane R1 listed with PR + reviewer [GH-86]" \
  || fail "N: (b) lane R1 not listed correctly"
grep -q '| R2 | #81 GH-78 doc-preflight | agy (script + telemetry) |' "$doc" \
  && pass "N: (b) lane R2 listed with PR + reviewer [GH-86]" \
  || fail "N: (b) lane R2 not listed correctly"
grep -qF "[PR-REVIEW-QUEUE-$DAY.md](PR-REVIEW-QUEUE-$DAY.md)" "$doc" \
  && pass "N: (b) section links the overlay doc [GH-86]" \
  || fail "N: (b) overlay doc link missing"
grep -q 'filesystem-touching `test/\*\.sh`' "$doc" \
  && pass "N: (c) How-to-fire guidance warns that fs-touching tests are read-only specs in-turn [GH-54]" \
  || fail "N: (c) missing fs-touching-test warning in the generated plan"

# ─────────────────────────────────────────────────────────────────────────────
# Scenario O — GH-48: explicit default zones config is byte-identical to the built-in default
# ─────────────────────────────────────────────────────────────────────────────
O="$WORK/O"; mkdir -p "$O"; echo '{}' >"$O/.gh-state.json"; : >"$O/.branches"
mk_doc "$O" GH-990-kernel.md 2 2 2 "$(contract_for MISS_OK bin/tick)"
mk_doc "$O" GH-991-shim.md   2 2 2 "$(contract_for MISS_OS relay-automation/consult.sh)"
mk_doc "$O" GH-992-indep.md  2 2 2 "$(contract_for MISS_OI src/indep.js)"
cat >"$O/ROADMAP.md" <<EOF
# Roadmap
## Ledger
### In progress
- **GH-990 · kernel** 🆕 — → [d](PROJECT/2-WORKING/GH-990-kernel.md) · [#990](https://github.com/o/r/issues/990)
- **GH-991 · shim** 🆕 — → [d](PROJECT/2-WORKING/GH-991-shim.md) · [#991](https://github.com/o/r/issues/991)
- **GH-992 · indep** 🆕 — → [d](PROJECT/2-WORKING/GH-992-indep.md) · [#992](https://github.com/o/r/issues/992)
EOF
run_qp "$O" >/dev/null 2>&1
cp "$O/PROJECT/2-WORKING/MARATHON-PLAN-$DAY.md" "$O/default.md"
run_qp "$O" --zones-config "$ROOT/utils/marathon-plan-zones.default.json" >/dev/null 2>&1
cmp -s "$O/default.md" "$O/PROJECT/2-WORKING/MARATHON-PLAN-$DAY.md" \
  && pass "O: explicit default zones config is byte-identical to the built-in default [GH-48]" \
  || fail "O: explicit default config changed planner output"

# ─────────────────────────────────────────────────────────────────────────────
# Scenario P — GH-48: foreign zone names, case-insensitive regex, and orchestrator_only escalation
# ─────────────────────────────────────────────────────────────────────────────
P="$WORK/P"; mkdir -p "$P"; echo '{}' >"$P/.gh-state.json"; : >"$P/.branches"
mk_doc "$P" GH-970-helpera.md 2 2 2 "$(contract_for MISS_PA scripts/apple_reminders_helper_app.swift)"
mk_doc "$P" GH-971-helperb.md 2 2 2 "$(contract_for MISS_PB scripts/apple_reminders_helper_app.swift/entitlements.plist)"
mk_doc "$P" GH-972-turn.md    2 2 2 "$(contract_for MISS_PT relay-automation/agy-turn.sh)"
mk_doc "$P" GH-973-orch.md    2 2 2 '{"target":{"repo":".","ref":"main"},"gate":"true","fix_probes":[{"type":"path_absent","path":"MISS_PO"}],"artifacts":["src/worker.js"],"lanes":{"orchestrator_only":["src/"]}}'
cat >"$P/ROADMAP.md" <<EOF
# Roadmap
## Ledger
### In progress
- **GH-970 · helper a** 🆕 — → [d](PROJECT/2-WORKING/GH-970-helpera.md) · [#970](https://github.com/o/r/issues/970)
- **GH-971 · helper b** 🆕 — → [d](PROJECT/2-WORKING/GH-971-helperb.md) · [#971](https://github.com/o/r/issues/971)
- **GH-972 · turn shim** 🆕 — → [d](PROJECT/2-WORKING/GH-972-turn.md) · [#972](https://github.com/o/r/issues/972)
- **GH-973 · orch escalation** 🆕 — → [d](PROJECT/2-WORKING/GH-973-orch.md) · [#973](https://github.com/o/r/issues/973)
EOF
cat >"$P/foreign-zones.json" <<'EOF'
{
  "zones": [
    {
      "name": "review-gate",
      "pathPrefixes": ["bin/review"],
      "maxPerWave": 1,
      "penalty": 2,
      "escalateOrchestratorOnly": true
    },
    {
      "name": "signed-helper",
      "pathPrefixes": ["scripts/apple_reminders_helper_app.swift"],
      "maxPerWave": 1,
      "penalty": 2
    },
    {
      "name": "turn-shim",
      "pathRegex": "RELAY-AUTOMATION/AGY-TURN\\.SH$",
      "pathRegexCaseInsensitive": true,
      "inferKeywordRegex": "agy-turn\\.sh",
      "conservativeWhenInferred": true,
      "penalty": 1
    }
  ],
  "defaultZone": { "name": "independent", "penalty": 0 }
}
EOF
run_qp "$P" --zones-config "$P/foreign-zones.json" >/dev/null 2>&1
doc="$P/PROJECT/2-WORKING/MARATHON-PLAN-$DAY.md"
[[ "$(zone_cell "$doc" 972)" == "turn-shim" ]] \
  && pass "P: case-insensitive pathRegex classifies relay-automation/agy-turn.sh into a foreign zone name [GH-48]" \
  || fail "P: expected #972 zone=turn-shim, got $(zone_cell "$doc" 972)"
[[ "$(zone_cell "$doc" 973)" == "review-gate" ]] \
  && pass "P: escalateOrchestratorOnly reclassifies an artifact under lanes.orchestrator_only [GH-48]" \
  || fail "P: expected #973 zone=review-gate, got $(zone_cell "$doc" 973)"
[[ -n "$(wave_of "$doc" 970)" && -n "$(wave_of "$doc" 971)" && "$(wave_of "$doc" 970)" != "$(wave_of "$doc" 971)" ]] \
  && pass "P: foreign maxPerWave=1 zone serializes helper lanes without exact write-set collision [GH-48]" \
  || fail "P: expected helper lanes in different waves (970=$(wave_of "$doc" 970) 971=$(wave_of "$doc" 971))"
grep -q '| signed-helper | ❌ serialize — one at a time |' "$doc" \
  && pass "P: collision map renders a foreign capped zone row [GH-48]" \
  || fail "P: signed-helper collision-map row missing"

# ─────────────────────────────────────────────────────────────────────────────
# Scenario Q — GH-48: precedence --zones-config > QUEUE_PLAN_ZONES_FILE > root-local file
# ─────────────────────────────────────────────────────────────────────────────
Q="$WORK/Q"; mkdir -p "$Q"; echo '{}' >"$Q/.gh-state.json"; : >"$Q/.branches"
mk_doc "$Q" GH-980-zonepick.md 2 2 2 "$(contract_for MISS_Q src/zonepick.js)"
cat >"$Q/ROADMAP.md" <<EOF
# Roadmap
## Ledger
### In progress
- **GH-980 · zone pick** 🆕 — → [d](PROJECT/2-WORKING/GH-980-zonepick.md) · [#980](https://github.com/o/r/issues/980)
EOF
cat >"$Q/.marathon-plan-zones.json" <<'EOF'
{ "zones": [ { "name": "root-zone", "pathPrefixes": ["src/zonepick.js"], "penalty": 1 } ], "defaultZone": { "name": "independent", "penalty": 0 } }
EOF
cat >"$Q/env-zones.json" <<'EOF'
{ "zones": [ { "name": "env-zone", "pathPrefixes": ["src/zonepick.js"], "penalty": 1 } ], "defaultZone": { "name": "independent", "penalty": 0 } }
EOF
cat >"$Q/cli-zones.json" <<'EOF'
{ "zones": [ { "name": "cli-zone", "pathPrefixes": ["src/zonepick.js"], "penalty": 1 } ], "defaultZone": { "name": "independent", "penalty": 0 } }
EOF
run_qp "$Q" >/dev/null 2>&1
doc="$Q/PROJECT/2-WORKING/MARATHON-PLAN-$DAY.md"
[[ "$(zone_cell "$doc" 980)" == "root-zone" ]] \
  && pass "Q: root-local .marathon-plan-zones.json applies when no higher tier is set [GH-48]" \
  || fail "Q: expected root-zone, got $(zone_cell "$doc" 980)"
QUEUE_PLAN_ZONES_FILE="$Q/env-zones.json" run_qp "$Q" >/dev/null 2>&1
[[ "$(zone_cell "$doc" 980)" == "env-zone" ]] \
  && pass "Q: QUEUE_PLAN_ZONES_FILE overrides the root-local file [GH-48]" \
  || fail "Q: expected env-zone, got $(zone_cell "$doc" 980)"
QUEUE_PLAN_ZONES_FILE="$Q/env-zones.json" run_qp "$Q" --zones-config "$Q/cli-zones.json" >/dev/null 2>&1
[[ "$(zone_cell "$doc" 980)" == "cli-zone" ]] \
  && pass "Q: --zones-config overrides QUEUE_PLAN_ZONES_FILE [GH-48]" \
  || fail "Q: expected cli-zone, got $(zone_cell "$doc" 980)"

# ─────────────────────────────────────────────────────────────────────────────
# Scenario R — GH-48: malformed zone config fails loud, no silent fallback
# ─────────────────────────────────────────────────────────────────────────────
printf '{ bad json\n' >"$Q/bad-zones.json"
run_qp "$Q" --zones-config "$Q/bad-zones.json" >/dev/null 2>&1; rc=$?
[[ $rc -eq 3 ]] \
  && pass "R: malformed --zones-config fails loud (exit 3), no silent fallback [GH-48]" \
  || fail "R: expected exit 3 from malformed --zones-config, got $rc"
QUEUE_PLAN_ZONES_FILE="$Q/bad-zones.json" run_qp "$Q" >/dev/null 2>&1; rc=$?
[[ $rc -eq 3 ]] \
  && pass "R: malformed QUEUE_PLAN_ZONES_FILE also fails loud (exit 3) [GH-48]" \
  || fail "R: expected exit 3 from malformed QUEUE_PLAN_ZONES_FILE, got $rc"

# ─────────────────────────────────────────────────────────────────────────────
# Scenario S — GH-150: docOf prefers the lane's own GH-<n> pointer over an earlier PROJECT doc link
# ─────────────────────────────────────────────────────────────────────────────
S="$WORK/S"; mkdir -p "$S/PROJECT/1-INBOX" "$S/PROJECT/3-COMPLETED"; echo '{}' >"$S/.gh-state.json"; : >"$S/.branches"
cat >"$S/PROJECT/1-INBOX/GH-111-right-doc.md" <<EOF
---
title: GH-111 right doc
complexity: 2
risk: 1
effort: 2
---

# GH-111 right doc

## Swarm Preflight Contract
\`\`\`json
$(contract_for MISS_S src/right.js)
\`\`\`
EOF
cat >"$S/PROJECT/3-COMPLETED/MARATHON-PLAN-$DAY.md" <<EOF
---
title: Distractor marathon plan
---

# Distractor marathon plan
EOF
cat >"$S/ROADMAP.md" <<EOF
# Roadmap
## Ledger
### Queue / parked intake
- **GH-111 · right doc outside 2-WORKING** 🆕 — referenced by [plan](PROJECT/3-COMPLETED/MARATHON-PLAN-$DAY.md) before the real pointer → [d](PROJECT/1-INBOX/GH-111-right-doc.md) · [#111](https://github.com/o/r/issues/111)
EOF
out="$(run_qp "$S" 2>/dev/null)"; doc="$S/PROJECT/2-WORKING/MARATHON-PLAN-$DAY.md"
if ! grep -q "unrated.*GH-111" <<<"$out" && [[ "$(wave_of "$doc" 111)" == "1" ]]; then
  pass "S: docOf prefers the lane's own GH-111 pointer over an earlier PROJECT doc link [GH-150]"
else
  fail "S: docOf chose the distractor PROJECT doc (out=$(grep -E 'unrated.*GH-111|needs-contract.*GH-111' <<<\"$out\" | head -1) wave=$(wave_of \"$doc\" 111))"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Scenario T — GH-154: XYZ_PYTHON=1 matches the shell path for an explicit zones config
# ─────────────────────────────────────────────────────────────────────────────
T="$WORK/T"; mkdir -p "$T"; echo '{}' >"$T/.gh-state.json"; : >"$T/.branches"
mk_doc "$T" GH-1200-helpera.md 2 2 2 "$(contract_for MISS_TA scripts/apple_reminders_helper_app.swift)"
mk_doc "$T" GH-1201-helperb.md 2 2 2 "$(contract_for MISS_TB scripts/apple_reminders_helper_app.swift/entitlements.plist)"
mk_doc "$T" GH-1202-turn.md    2 2 2 "$(contract_for MISS_TT relay-automation/agy-turn.sh)"
mk_doc "$T" GH-1203-orch.md    2 2 2 '{"target":{"repo":".","ref":"main"},"gate":"true","fix_probes":[{"type":"path_absent","path":"MISS_TO"}],"artifacts":["src/worker.js"],"lanes":{"orchestrator_only":["src/"]}}'
cat >"$T/ROADMAP.md" <<EOF
# Roadmap
## Ledger
### In progress
- **GH-1200 · helper a** 🆕 — → [d](PROJECT/2-WORKING/GH-1200-helpera.md) · [#1200](https://github.com/o/r/issues/1200)
- **GH-1201 · helper b** 🆕 — → [d](PROJECT/2-WORKING/GH-1201-helperb.md) · [#1201](https://github.com/o/r/issues/1201)
- **GH-1202 · turn shim** 🆕 — → [d](PROJECT/2-WORKING/GH-1202-turn.md) · [#1202](https://github.com/o/r/issues/1202)
- **GH-1203 · orch escalation** 🆕 — → [d](PROJECT/2-WORKING/GH-1203-orch.md) · [#1203](https://github.com/o/r/issues/1203)
EOF
cat >"$T/foreign-zones.json" <<'EOF'
{
  "zones": [
    {
      "name": "review-gate",
      "pathPrefixes": ["bin/review"],
      "maxPerWave": 1,
      "penalty": 2,
      "escalateOrchestratorOnly": true
    },
    {
      "name": "signed-helper",
      "pathPrefixes": ["scripts/apple_reminders_helper_app.swift"],
      "maxPerWave": 1,
      "penalty": 2
    },
    {
      "name": "turn-shim",
      "pathRegex": "RELAY-AUTOMATION/AGY-TURN\\.SH$",
      "pathRegexCaseInsensitive": true,
      "inferKeywordRegex": "agy-turn\\.sh",
      "conservativeWhenInferred": true,
      "penalty": 1
    }
  ],
  "defaultZone": { "name": "independent", "penalty": 0 }
}
EOF
# GH-348: the LEFT side is now run_qp_sh (XYZ_PYTHON=0), not run_qp. The Bash engine needs `node`
# (utils/marathon-plan.sh:146 hard-requires it) — if that is absent, SKIP loudly. Falling back to
# run_qp here would restore the exact tautology this fix removes, and it would look like a pass.
if ! command -v node >/dev/null 2>&1; then
  skip "T: cross-lane parity needs node for the XYZ_PYTHON=0 engine — parity UNVERIFIED this run [GH-348]"
  skip "T: rendered-doc cross-lane parity likewise unverified (no node)"
else
  shell_out="$(run_qp_sh "$T" --dry-run --zones-config "$T/foreign-zones.json" 2>/dev/null)"; rc_shell=$?
  py_out="$(run_qp_py "$T" --dry-run --zones-config "$T/foreign-zones.json" 2>/dev/null)"; rc_py=$?
  [[ $rc_shell -eq 0 && $rc_py -eq 0 && "$shell_out" == "$py_out" ]] \
    && pass "T: explicit zones dry-run output matches between the BASH engine and XYZ_PYTHON=1 [GH-154/GH-348]" \
    || fail "T: explicit zones dry-run mismatch (bash=$rc_shell py=$rc_py)"
  run_qp_sh "$T" --zones-config "$T/foreign-zones.json" >/dev/null 2>&1
  cp "$T/PROJECT/2-WORKING/MARATHON-PLAN-$DAY.md" "$T/shell.md"
  run_qp_py "$T" --zones-config "$T/foreign-zones.json" >/dev/null 2>&1
  cmp -s "$T/shell.md" "$T/PROJECT/2-WORKING/MARATHON-PLAN-$DAY.md" \
    && pass "T: rendered MARATHON-PLAN doc matches between the BASH engine and XYZ_PYTHON=1 [GH-154/GH-348]" \
    || fail "T: rendered MARATHON-PLAN doc drifted between the BASH engine and XYZ_PYTHON=1"

  # GH-348 self-check: prove the comparison above is actually cross-lane, in the run itself.
  # A mutated copy of the Bash engine MUST be detected. Without this, a future refactor could quietly
  # point both sides at one lane again and every assertion here would keep passing.
  MUT="$T/mutated-marathon-plan.sh"
  sed 's/GENERATED by utils\/marathon-plan\.sh/MUTATED-BASH by utils\/marathon-plan.sh/' "$QP" >"$MUT"
  if cmp -s "$QP" "$MUT"; then
    # Either the banner literal moved/changed, or the working tree already carries the mutation
    # (someone is mid-experiment). Both mean this self-check proved nothing — say which, don't guess.
    fail "T: mutation self-check is inert — the 'GENERATED by' banner literal is not in $QP as expected, or the tree already carries the mutation [GH-348]"
  else
    mut_out="$(QUEUE_PLAN_ROOT="$T" QUEUE_PLAN_TODAY="$DAY" QUEUE_PLAN_NOW="$NOWT" \
      QUEUE_PLAN_GH_STATE_FILE="$T/.gh-state.json" QUEUE_PLAN_BRANCHES_FILE="$T/.branches" \
      XYZ_PYTHON=0 bash "$MUT" --dry-run --zones-config "$T/foreign-zones.json" 2>/dev/null)"
    # The dry-run report does not carry the banner, so compare the RENDERED doc, which does.
    QUEUE_PLAN_ROOT="$T" QUEUE_PLAN_TODAY="$DAY" QUEUE_PLAN_NOW="$NOWT" \
      QUEUE_PLAN_GH_STATE_FILE="$T/.gh-state.json" QUEUE_PLAN_BRANCHES_FILE="$T/.branches" \
      XYZ_PYTHON=0 bash "$MUT" --zones-config "$T/foreign-zones.json" >/dev/null 2>&1
    if cmp -s "$T/shell.md" "$T/PROJECT/2-WORKING/MARATHON-PLAN-$DAY.md"; then
      fail "T: mutating the Bash engine changed NOTHING — the parity comparison is not cross-lane [GH-348]"
    else
      pass "T: mutating the Bash engine IS detected — the parity comparison is genuinely cross-lane [GH-348]"
    fi
    # Leave the fixture as the unmutated Bash render, so nothing downstream inherits mutated output.
    run_qp_sh "$T" --zones-config "$T/foreign-zones.json" >/dev/null 2>&1
  fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# Scenario U — GH-349: an unknown flag must be a USAGE ERROR on the lane that runs
# ─────────────────────────────────────────────────────────────────────────────
# marathon_plan.py's usage() used to end in an unconditional sys.exit(0), making the die() on the next
# line unreachable — so `marathon-plan.sh --bogus` exited 0 on the DEFAULT lane while Bash exited 2.
# A scripted `--check --typo` printed usage, compared nothing, and reported success.
U="$WORK/U"; mkdir -p "$U/PROJECT/2-WORKING"; echo '{}' >"$U/.gh-state.json"; : >"$U/.branches"
printf '# Roadmap\n## Ledger\n### In progress\n' >"$U/ROADMAP.md"

u_out="$(run_qp "$U" --bogus 2>"$WORK/u.err")"; u_rc=$?
[[ $u_rc -eq 2 ]] \
  && pass "U: unknown flag exits 2 on the DEFAULT lane (XYZ_PYTHON unset) [GH-349]" \
  || fail "U: unknown flag exited $u_rc on the default lane (expected 2)"
grep -q 'unknown argument: --bogus' "$WORK/u.err" \
  && pass "U: the error names the offending flag, on stderr [GH-349]" \
  || fail "U: no 'unknown argument' on stderr: $(head -1 "$WORK/u.err")"
grep -q '^Usage:' <<<"$(printf '%s\n' "$u_out")" \
  && pass "U: usage still goes to stdout (Bash parity: usage stdout, error stderr)" \
  || fail "U: usage block missing from stdout"
# The failure this pins is specifically that a NON-ZERO exit is reachable. --help must stay 0.
run_qp "$U" --help >/dev/null 2>&1 \
  && pass "U: --help still exits 0" || fail "U: --help no longer exits 0"
# Cross-lane: both twins must agree on the code, or a caller's `|| alert` fires on one lane only.
if command -v node >/dev/null 2>&1; then
  run_qp_sh "$U" --bogus >/dev/null 2>&1; ub_rc=$?
  [[ $ub_rc -eq 2 ]] && pass "U: the Bash lane also exits 2 (codes agree across lanes) [GH-349]" \
    || fail "U: Bash lane exited $ub_rc (expected 2)"
else
  skip "U: cross-lane exit-code agreement needs node"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Scenario V — GH-346: `branch:` front-matter is DERIVED, not the literal "main"
# ─────────────────────────────────────────────────────────────────────────────
# Every generated plan asserted `branch: main` regardless of the target repo's trunk. Reported against
# rebalance-OS, whose trunk is `development`. It is the repo's TRUNK, deliberately not the current
# branch — deriving HEAD would make `--check` report drift just because someone cut a feature branch.
#
# #346 claimed "the Python lane contains no branch: string of its own, so fixing :945 covers both".
# That was true when marathon_plan.py shelled out to the copied JS; GH-340/PR #341 replaced it with a
# native Python engine that has its own renderer. Both engines are fixed, and asserted here.
grep -q 'o.push("branch: main")' "$QP" \
  && fail "V: utils/marathon-plan.sh still hardcodes 'branch: main' [GH-346]" \
  || pass "V: the Bash engine no longer hardcodes 'branch: main' [GH-346]"
grep -q 'o.append("branch: main")' "$ROOT/utils/py/_marathon_plan.py" \
  && fail "V: the native Python engine still hardcodes 'branch: main' [GH-346]" \
  || pass "V: the native Python engine no longer hardcodes 'branch: main' [GH-346]"

# The fixture root is a plain directory, not a git repo, so nothing resolves → the honest fallback.
# Needs at least one ledger item: an empty ledger exits 3 ("no ledger items parsed") and renders
# nothing, so an assertion against a missing file would be measuring the wrong failure.
V="$WORK/V"; mkdir -p "$V"; echo '{}' >"$V/.gh-state.json"; : >"$V/.branches"
mk_doc "$V" GH-1300-branchfield.md 2 2 2 "$(contract_for MISS_VB src/branchfield.js)"
cat >"$V/ROADMAP.md" <<EOF
# Roadmap
## Ledger
### In progress
- **GH-1300 · branch field** 🆕 — → [d](PROJECT/2-WORKING/GH-1300-branchfield.md) · [#1300](https://github.com/o/r/issues/1300)
EOF
run_qp "$V" >/dev/null 2>&1
vdoc="$V/PROJECT/2-WORKING/MARATHON-PLAN-$DAY.md"
if [[ -f "$vdoc" ]]; then
  grep -qx 'branch: unknown' "$vdoc" \
    && pass "V: a non-git root renders 'branch: unknown', not a false 'main' [GH-346]" \
    || fail "V: expected 'branch: unknown', got '$(grep -m1 '^branch:' "$vdoc")'"
else
  fail "V: no plan rendered at $vdoc"
fi

# QUEUE_PLAN_BRANCH is the override + hermetic seam. Both lanes must honor it identically.
rm -f "$vdoc"
QUEUE_PLAN_BRANCH="release/9.9" run_qp "$V" >/dev/null 2>&1
grep -qx 'branch: release/9.9' "$vdoc" \
  && pass "V: QUEUE_PLAN_BRANCH overrides the derived value (Python lane) [GH-346]" \
  || fail "V: QUEUE_PLAN_BRANCH ignored on the Python lane: '$(grep -m1 '^branch:' "$vdoc")'"
if command -v node >/dev/null 2>&1; then
  cp "$vdoc" "$V/py-branch.md"; rm -f "$vdoc"
  QUEUE_PLAN_BRANCH="release/9.9" run_qp_sh "$V" >/dev/null 2>&1
  grep -qx 'branch: release/9.9' "$vdoc" \
    && pass "V: QUEUE_PLAN_BRANCH overrides the derived value (Bash lane) [GH-346]" \
    || fail "V: QUEUE_PLAN_BRANCH ignored on the Bash lane: '$(grep -m1 '^branch:' "$vdoc")'"
  # The whole doc, not just the field: a derived value computed differently in the two engines is the
  # drift class GH-348 exists to catch, and this is the change most likely to introduce it.
  cmp -s "$V/py-branch.md" "$vdoc" \
    && pass "V: both engines render byte-identical docs with a derived branch [GH-346/GH-348]" \
    || fail "V: engines diverge with a derived branch: $(diff "$V/py-branch.md" "$vdoc" | head -4)"
else
  skip "V: cross-lane branch-derivation parity needs node"
fi

echo
_skip_note=""; [[ "$SKIP" -gt 0 ]] && _skip_note=", $SKIP skipped"
echo "  marathon-plan: $PASS passed, $FAIL failed$_skip_note"
[[ "$FAIL" -eq 0 ]]
