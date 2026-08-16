#!/usr/bin/env bash
# test/gh400-acceptance-fidelity.sh — GH-400.
#
# A capture doc is a MODEL'S SUMMARY of a GitHub issue, and preflight inlines it into the packet as
# the definition of done. Neither the builder nor the reviewer ever sees the issue, so a summary that
# reframes a requirement becomes the contract and no downstream role can compare it to anything.
#
# The case this pins is real, not hypothetical. rebalance-OS #202 required a malformed row be
# "proven to be either reconciled or surfaced, never silently dropped"; the /10days capture doc
# (commit b941299) instead required asserting "the exporter's actual current behavior (drop the
# row...)"; and two independent marathon runs (3673257f, 7525d047) delivered a test function named
# `malformed_source_row_is_dropped`. Every gate was green and the phase closed.
#
# Case 1 is the pin. Cases 2-4 are what keep it honest: a checker that flags the inversion but ALSO
# flags a faithful copy is not a fidelity gate, it is noise that gets switched off. This repo has
# five documented instances of an assertion that could not distinguish the bug from the fix (#348,
# #342, #351, #362B, #369) — cases 2-4 exist so this is not the sixth.
#
# Hermetic: `gh` is stubbed on PATH, so no network and no auth.

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
PY="$ROOT/utils/py/swarm_preflight.py"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh400-acceptance.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

PASS=0; FAIL=0
pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }

echo "== test: gh400-acceptance-fidelity =="
echo "  workdir: $WORK"

[ -f "$PY" ] || { fail "missing $PY"; echo "  gh400-acceptance-fidelity: $PASS pass, $FAIL fail"; exit 1; }

# ── gh stub: serves $WORK/issues/<n>.md as the issue body, exit 1 for anything unknown ────────────
mkdir -p "$WORK/bin" "$WORK/issues"
cat >"$WORK/bin/gh" <<'STUB'
#!/usr/bin/env bash
# Minimal `gh issue view <n> --json body -q .body` stand-in.
[ "${GH_STUB_BROKEN:-0}" = "1" ] && { echo "gh: could not authenticate" >&2; exit 1; }
n=""
for a in "$@"; do case "$a" in ''|*[!0-9]*) ;; *) n="$a"; break ;; esac; done
[ -n "$n" ] && [ -f "$GH_STUB_DIR/$n.md" ] || { echo "gh: no such issue" >&2; exit 1; }
cat "$GH_STUB_DIR/$n.md"
STUB
chmod +x "$WORK/bin/gh"
export GH_STUB_DIR="$WORK/issues"

# check <doc-file> <issue-number> → prints "<status>|<detail>"
check() {
  PATH="$WORK/bin:$PATH" python3 - "$1" "$2" <<'PYEOF'
import sys, os
sys.path.insert(0, os.environ["SP_PY_DIR"])
from swarm_preflight import check_acceptance_fidelity
r = check_acceptance_fidelity(sys.argv[1], sys.argv[2], ".")
print(f"{r['status']}|{r['detail']}")
PYEOF
}
export SP_PY_DIR="$ROOT/utils/py"

# ── Case 1: THE PIN — the real GH-202 inversion must be refused ───────────────────────────────────
cat >"$WORK/issues/202.md" <<'EOF'
## Summary

GH-156 shipped its CLIO projection reconciliation. One acceptance criterion was not met.

## Acceptance

- [ ] A fixture representing at least one malformed source row is added to the CLIO projection test harness.
- [ ] The test asserts the *intended* behaviour explicitly — whether that is quarantine, repair, or a loud failure — rather than just asserting "no crash."
- [ ] The malformed row is proven to be either reconciled or surfaced, never silently dropped from the projection.
- [ ] Passes on both `bash` and `/bin/bash`, matching the existing harness contract.

## Context

- Parent: #156
EOF

cat >"$WORK/gh202-doc.md" <<'EOF'
---
gh_issue: 202
title: "GH-202 — CLIO malformed row test"
---

## Acceptance

- [ ] `test/clio-exporter.sh` gains a fixture exercising a malformed/truncated
      source row (e.g. invalid JSON, missing required field, unparseable timestamp).
- [ ] The fixture asserts the exporter's actual current behavior (drop the row,
      continue processing the rest) rather than crashing or silently corrupting output.
- [ ] `bash test/clio-exporter.sh` green.

## Swarm Preflight Contract
EOF

res="$(check "$WORK/gh202-doc.md" 202)"
if [ "${res%%|*}" = "diverged" ]; then
  pass "C1 the real GH-202 inversion is refused (${res#*|})"
else
  fail "C1 GH-202 inversion NOT caught — got '$res'. This is the exact case the issue was filed for."
fi

# The inverted criterion must be named in the report, not just counted — an operator has to be able
# to see WHICH requirement was rewritten without re-reading the issue.
det="$(PATH="$WORK/bin:$PATH" python3 - "$WORK/gh202-doc.md" <<'PYEOF'
import sys, os
sys.path.insert(0, os.environ["SP_PY_DIR"])
from swarm_preflight import check_acceptance_fidelity, acceptance_fidelity_report
r = check_acceptance_fidelity(sys.argv[1], "202", ".")
print("\n".join(acceptance_fidelity_report(r)))
PYEOF
)"
grep -q "never silently dropped from the projection" <<<"$det" \
  && pass "C1b the report names the inverted requirement verbatim" \
  || fail "C1b report does not quote the dropped criterion: $det"
grep -q "drop the row, continue processing the rest" <<<"$det" \
  && pass "C1c the report shows the doc's substituted wording, continuation line included" \
  || fail "C1c report lost the doc's hard-wrapped continuation: $det"

# ── Case 2: a verbatim copy must PASS (the anti-noise half of the pin) ────────────────────────────
cat >"$WORK/issues/300.md" <<'EOF'
## Acceptance

- [ ] The parser rejects a negative timeout instead of coercing it to zero.
- [ ] A regression test covers the rejection path.
EOF
cat >"$WORK/verbatim-doc.md" <<'EOF'
---
gh_issue: 300
---
## Acceptance

- [ ] The parser rejects a negative timeout instead of coercing it to zero.
- [ ] A regression test covers the rejection path.
EOF
res="$(check "$WORK/verbatim-doc.md" 300)"
[ "${res%%|*}" = "match" ] && pass "C2 a verbatim copy passes" || fail "C2 false positive on a verbatim copy: $res"

# ── Case 3: hard-wrapped copy must PASS — capture docs wrap at ~80, issues do not ─────────────────
# Without continuation folding this reads as two truncated criteria and every honest doc fails.
cat >"$WORK/wrapped-doc.md" <<'EOF'
---
gh_issue: 300
---
## Acceptance

- [ ] The parser rejects a negative timeout instead of coercing it to
      zero.
- [ ] A regression test covers the
      rejection path.
EOF
res="$(check "$WORK/wrapped-doc.md" 300)"
[ "${res%%|*}" = "match" ] && pass "C3 a hard-wrapped copy passes (continuations folded)" \
  || fail "C3 hard-wrap treated as divergence: $res"

# ── Case 4: a trailing rule + footer must not be folded into the last criterion ───────────────────
# Found while dogfooding this check against issue #400 itself: GitHub bodies commonly end with
# `---` and an italic sign-off, which a naive folder appends to the final criterion, making a
# byte-perfect copy report as diverged.
cat >"$WORK/issues/301.md" <<'EOF'
## Acceptance

- [ ] Only one criterion here.

---

*Analysis by Claude Code, from two 10-lane marathon runs.*
EOF
cat >"$WORK/footer-doc.md" <<'EOF'
---
gh_issue: 301
---
## Acceptance

- [ ] Only one criterion here.
EOF
res="$(check "$WORK/footer-doc.md" 301)"
[ "${res%%|*}" = "match" ] && pass "C4 a trailing '---' + footer is not folded into the criterion" \
  || fail "C4 issue footer leaked into the last criterion: $res"

# ── Case 5: a silently dropped criterion is refused ───────────────────────────────────────────────
cat >"$WORK/dropped-doc.md" <<'EOF'
---
gh_issue: 300
---
## Acceptance

- [ ] The parser rejects a negative timeout instead of coercing it to zero.
EOF
res="$(check "$WORK/dropped-doc.md" 300)"
[ "${res%%|*}" = "diverged" ] && pass "C5 a silently dropped criterion is refused" \
  || fail "C5 dropped criterion not caught: $res"

# ── Case 6: the SAME drop, properly declared, is allowed ──────────────────────────────────────────
# The escape hatch is deliberately a reviewable in-repo section, not an env flag: a deviation should
# survive in the doc where the next reader finds it, not in a shell history nobody sees.
cat >"$WORK/declared-doc.md" <<'EOF'
---
gh_issue: 300
---
## Acceptance

- [ ] The parser rejects a negative timeout instead of coercing it to zero.

## Acceptance — deviations from the issue

- [dropped] A regression test covers the rejection path. — reason: split to lane B; this lane is parser-only.
EOF
res="$(check "$WORK/declared-doc.md" 300)"
[ "${res%%|*}" = "match" ] && pass "C6 the same drop passes once declared with a reason" \
  || fail "C6 a properly declared deviation was still refused: $res"

# ── Case 7: a declaration with no reason does not count ───────────────────────────────────────────
cat >"$WORK/noreason-doc.md" <<'EOF'
---
gh_issue: 300
---
## Acceptance

- [ ] The parser rejects a negative timeout instead of coercing it to zero.

## Acceptance — deviations from the issue

- [dropped] A regression test covers the rejection path.
EOF
res="$(check "$WORK/noreason-doc.md" 300)"
[ "${res%%|*}" = "diverged" ] && pass "C7 a deviation with no '— reason:' is refused" \
  || fail "C7 reasonless deviation accepted: $res"

# ── Case 8: a declaration that does not match the actual diff does not count ──────────────────────
# Otherwise the section becomes a rubber stamp: any text under the heading would excuse any drift.
cat >"$WORK/bogus-doc.md" <<'EOF'
---
gh_issue: 300
---
## Acceptance

- [ ] The parser rejects a negative timeout instead of coercing it to zero.

## Acceptance — deviations from the issue

- [dropped] Something the issue never asked for. — reason: hand-waving.
EOF
res="$(check "$WORK/bogus-doc.md" 300)"
[ "${res%%|*}" = "diverged" ] && pass "C8 a deviation naming the wrong criterion is refused" \
  || fail "C8 rubber-stamp deviation accepted: $res"

# ── Case 8b: a deviation declared when the lists actually agree is refused ────────────────────────
# Found by dogfooding: GH-399's own capture doc declared a [changed] deviation while its acceptance
# list was still verbatim, and the check passed vacuously because reconciliation only ran when the
# lists differed. A reader would have believed criterion 4 was narrowed; the list said otherwise.
cat >"$WORK/stale-dev-doc.md" <<'EOF'
---
gh_issue: 300
---
## Acceptance

- [ ] The parser rejects a negative timeout instead of coercing it to zero.
- [ ] A regression test covers the rejection path.

## Acceptance — deviations from the issue

- [changed] A regression test covers the rejection path. -> A regression test covers both paths. — reason: broader.
EOF
res="$(check "$WORK/stale-dev-doc.md" 300)"
[ "${res%%|*}" = "diverged" ] && pass "C8b a deviation declared while the lists agree is refused" \
  || fail "C8b a misleading deviation passed vacuously: $res"

# ── Case 9: a doc with NO acceptance section cannot dodge an issue that has one ───────────────────
cat >"$WORK/nosection-doc.md" <<'EOF'
---
gh_issue: 300
---
# Some capture doc

## Phase 1
- [ ] do the thing
EOF
res="$(check "$WORK/nosection-doc.md" 300)"
[ "${res%%|*}" = "diverged" ] && pass "C9 omitting the acceptance section entirely is refused" \
  || fail "C9 a doc dodged the gate by having no acceptance section: $res"

# ── Case 10: undeterminable ≠ diverged — unreachable gh must report unknown, never block ──────────
res="$(GH_STUB_BROKEN=1 check "$WORK/verbatim-doc.md" 300)"
[ "${res%%|*}" = "unknown" ] && pass "C10 an unauthenticated/offline gh reports unknown, not divergence" \
  || fail "C10 offline gh must not be read as drift: $res"

res="$(check "$WORK/verbatim-doc.md" "")"
[ "${res%%|*}" = "unknown" ] && pass "C11 a doc with no gh_issue reports unknown" \
  || fail "C11 missing gh_issue mishandled: $res"

cat >"$WORK/issues/302.md" <<'EOF'
## Summary
An issue with no acceptance section at all — the shape of 32 of this repo's 33 active capture docs.
EOF
cat >"$WORK/noissueacc-doc.md" <<'EOF'
---
gh_issue: 302
---
## Acceptance

- [ ] Something the doc author decided on their own.
EOF
res="$(check "$WORK/noissueacc-doc.md" 302)"
[ "${res%%|*}" = "unknown" ] && pass "C12 an issue with no acceptance section reports unknown" \
  || fail "C12 issue without an acceptance section must not be read as drift: $res"

# ── Case 13: end-to-end — preflight refuses to emit a packet on unexplained drift ─────────────────
R="$WORK/repo"
mkdir -p "$R/PROJECT/2-WORKING" "$R/src"
: >"$R/src/a.js"
git -C "$R" init -q -b main 2>/dev/null || { git -C "$R" init -q; git -C "$R" symbolic-ref HEAD refs/heads/main; }
mkcapture() { # <file> <acceptance-block>
  # `source:` is required of any doc naming a gh_issue (GH-400 criterion 2, test/gh400-source-url.sh).
  # Carried here so these fixtures exercise THIS file's subject and not that gate.
  { printf -- '---\ngh_issue: 202\ntitle: e2e\nsource: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/202\n---\n\n## Acceptance\n\n%s\n\n## Swarm Preflight Contract\n```json\n%s\n```\n' \
      "$2" '{
  "target": { "repo": ".", "ref": "main" },
  "gate": "true",
  "fix_probes": [ { "type": "path_absent", "path": "NEW_FILE.txt" } ],
  "artifacts": [ "src/a.js" ],
  "remediation": { "source": "issue#202", "criteria": "malformed row" }
}'; } >"$1"
}
mkcapture "$R/PROJECT/2-WORKING/GH-202-e2e.md" '- [ ] The fixture asserts the exporter'"'"'s actual current behavior (drop the row).'
git -C "$R" -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1
git -C "$R" -c user.email=t@t -c user.name=t commit -qm init >/dev/null 2>&1

export SWARM_PREFLIGHT_NOW="2026-08-03T00:00:00Z" SWARM_PREFLIGHT_TODAY="2026-08-03"
out="$(PATH="$WORK/bin:$PATH" SWARM_PREFLIGHT_ROOT="$R" python3 "$PY" --target-root "$R" \
  --project-doc "$R/PROJECT/2-WORKING/GH-202-e2e.md" --out "$R/packet" 2>&1)"; rc=$?
if [ "$rc" -eq 5 ] && grep -q "NOT-READY" <<<"$out"; then
  pass "C13 preflight exits 5 NOT-READY on unexplained acceptance drift"
else
  fail "C13 expected exit 5 NOT-READY, got rc=$rc: $out"
fi
grep -q "acceptance criteria diverge from issue #202" <<<"$out" \
  && pass "C13b the verdict names the issue and the reason" \
  || fail "C13b unhelpful NOT-READY message: $out"
[ ! -f "$R/packet/packet.md" ] && pass "C13c no packet is written when fidelity fails" \
  || fail "C13c a packet was emitted despite unexplained drift"

# ── Case 14: end-to-end — a faithful doc still emits, and the packet says it was verified ─────────
# HONESTY NOTE (agy review): C14 alone also passes pre-fix, where every doc emitted a packet. It is
# the cry-wolf control — it fails only if the gate starts over-blocking — not evidence of the fix.
# C14b is the falsifiable half: the provenance line does not exist in the pre-fix packet.
R2="$WORK/repo-ok"
mkdir -p "$R2/PROJECT/2-WORKING" "$R2/src"
: >"$R2/src/a.js"
git -C "$R2" init -q -b main 2>/dev/null || { git -C "$R2" init -q; git -C "$R2" symbolic-ref HEAD refs/heads/main; }
{ printf -- '---\ngh_issue: 202\ntitle: e2e-ok\nsource: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/202\n---\n\n## Acceptance\n\n'
  printf -- '- [ ] A fixture representing at least one malformed source row is added to the CLIO projection test harness.\n'
  printf -- '- [ ] The test asserts the *intended* behaviour explicitly — whether that is quarantine, repair, or a loud\n      failure — rather than just asserting "no crash."\n'
  printf -- '- [ ] The malformed row is proven to be either reconciled or surfaced, never silently dropped from the\n      projection.\n'
  printf -- '- [ ] Passes on both `bash` and `/bin/bash`, matching the existing harness contract.\n'
  printf -- '\n## Swarm Preflight Contract\n```json\n%s\n```\n' '{
  "target": { "repo": ".", "ref": "main" },
  "gate": "true",
  "fix_probes": [ { "type": "path_absent", "path": "NEW_FILE.txt" } ],
  "artifacts": [ "src/a.js" ],
  "remediation": { "source": "issue#202", "criteria": "malformed row" }
}'; } >"$R2/PROJECT/2-WORKING/GH-202-ok.md"
git -C "$R2" init -q 2>/dev/null
git -C "$R2" -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1
git -C "$R2" -c user.email=t@t -c user.name=t commit -qm init >/dev/null 2>&1

out2="$(PATH="$WORK/bin:$PATH" SWARM_PREFLIGHT_ROOT="$R2" python3 "$PY" --target-root "$R2" \
  --project-doc "$R2/PROJECT/2-WORKING/GH-202-ok.md" --out "$R2/packet" 2>&1)"; rc2=$?
if [ "$rc2" -eq 0 ]; then
  pass "C14 a faithful, hard-wrapped copy of the SAME issue still emits a packet (exit 0)"
else
  fail "C14 faithful copy blocked — the gate is unusable: rc=$rc2: $out2"
fi
if [ -f "$R2/packet/packet.md" ]; then
  grep -q "Verified against" "$R2/packet/packet.md" \
    && pass "C14b the packet records that acceptance was verified against the issue" \
    || fail "C14b packet lacks the verification provenance line"
else
  fail "C14b no packet written for the faithful case"
fi

# ── Case 15: the check records its verdict in run-candidate.json for post-hoc audit ───────────────
if [ -f "$R2/packet/run-candidate.json" ]; then
  python3 -c "
import json,sys
d=json.load(open('$R2/packet/run-candidate.json'))
f=d.get('readiness',{}).get('acceptance_fidelity')
sys.exit(0 if f and f.get('status')=='match' else 1)
" && pass "C15 readiness.acceptance_fidelity is recorded in run-candidate.json" \
    || fail "C15 acceptance_fidelity missing or wrong in run-candidate.json"
else
  fail "C15 no run-candidate.json to audit"
fi

# ── Cases 16-19: findings from agy's QA review (2026-08-03), each verified before being fixed ─────
# All four were live. Three let a doc reach `match` or `unknown` while genuinely diverging, which is
# the failure mode that matters most here — a gate that silently abstains reads exactly like one that
# passed.

# C16: an issue whose ## Acceptance section EXISTS but lists nothing is not "no section". Collapsing
# the two let a capture doc invent arbitrary criteria under its own heading and still read `unknown`.
cat >"$WORK/issues/303.md" <<'EOF'
## Acceptance

To be decided in the design review.
EOF
cat >"$WORK/invented-doc.md" <<'EOF'
---
gh_issue: 303
---
## Acceptance

- [ ] Whatever the doc author felt like requiring.
EOF
res="$(check "$WORK/invented-doc.md" 303)"
[ "${res%%|*}" = "diverged" ] && pass "C16 an empty issue acceptance section does not license invented criteria" \
  || fail "C16 doc invented criteria against an empty issue section and passed: $res"

# C17: prose between criteria must not truncate extraction. Before the fix this returned early, so
# the fidelity check compared 2 criteria while the packet inlined 3 — the two disagreed silently.
cat >"$WORK/issues/304.md" <<'EOF'
## Acceptance

- [ ] one.
- [ ] two.

A clarifying paragraph that is not a criterion.

- [ ] three.
EOF
cat >"$WORK/prose-doc.md" <<'EOF'
---
gh_issue: 304
---
## Acceptance

- [ ] one.
- [ ] two.
- [ ] three.
EOF
res="$(check "$WORK/prose-doc.md" 304)"
[ "${res%%|*}" = "match" ] && pass "C17 prose between criteria does not truncate the list" \
  || fail "C17 a criterion after an explanatory paragraph was dropped: $res"

# C18: heading variants. `## Acceptance:` previously read as "no section" -> unknown -> bypass.
cat >"$WORK/issues/305.md" <<'EOF'
## Acceptance:

- [ ] the only criterion.
EOF
cat >"$WORK/variant-doc.md" <<'EOF'
---
gh_issue: 305
---
## Acceptance Criteria (draft)

- [ ] something else entirely.
EOF
res="$(check "$WORK/variant-doc.md" 305)"
[ "${res%%|*}" = "diverged" ] && pass "C18 heading variants are recognized on both sides, not bypassed" \
  || fail "C18 a heading variant produced a silent bypass: $res"

# C18b: the relaxation must not swallow a prose heading that merely starts with the word.
cat >"$WORK/issues/307.md" <<'EOF'
## Acceptance is not required here

- [ ] not a criteria list.
EOF
cat >"$WORK/prose-heading-doc.md" <<'EOF'
---
gh_issue: 307
---
## Acceptance

- [ ] the doc's own criterion.
EOF
res="$(check "$WORK/prose-heading-doc.md" 307)"
[ "${res%%|*}" = "unknown" ] && pass "C18b a prose heading is still not an acceptance section" \
  || fail "C18b the heading relaxation is too broad: $res"

# C19: a [changed] declaration whose ISSUE-side text contains its own ' -> ' must still parse.
cat >"$WORK/issues/306.md" <<'EOF'
## Acceptance

- [ ] Map A -> B during import.
EOF
cat >"$WORK/arrow-doc.md" <<'EOF'
---
gh_issue: 306
---
## Acceptance

- [ ] Map A -> B during export.

## Acceptance — deviations from the issue

- [changed] Map A -> B during import. -> Map A -> B during export. — reason: import is out of scope for this lane.
EOF
res="$(check "$WORK/arrow-doc.md" 306)"
[ "${res%%|*}" = "match" ] && pass "C19 a [changed] entry survives an arrow inside the criterion text" \
  || fail "C19 arrow inside criterion text broke the declaration: $res"

echo "  gh400-acceptance-fidelity: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
