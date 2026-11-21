# Manual Check — GH-1545 (KS-03): Launch Authority Defaults

- **Issue:** `#1545` (refs `#1541` v5 KS-03 + U5, `#1536`)
- **Pre-change pinned commit:** `6270a2b5da9964d3f4d99ed4fa1755397d398561` (`build_queue.py` pre-KS-03)
- **Changed candidate commit:** `8631a7187b6591d084f93ed386ac49960513b04c`
- **Retained run-1 amendment baseline:** `TESTS-RESULTS/2026-11-20+GH-1545/inputs/run1-run-record-92ff5ce.md` (retrieved verbatim from PR `#1542` commit `92ff5cebefec586d2f5e4009d042eb9709f05ec7`, GitHub blob `264978fe46ed792debcab41f38d1a6bdf0b68055`)
- **No new test suite (GH-831):** Recorded paired manual check with red controls and `provenance.jsonl`.
- **Scope honesty:** Live run-2 target ("zero PARENT amendments for KS-03 classes") remains uncredited until run 2 (`KS-17`). Runtime enforcement of `KS-02`, `KS-05`, `KS-10`, and `KS-11` remains uncredited until their respective milestones land.

## 1. Runnable Verification Procedure (executed verbatim)

```bash
set -euo pipefail
OUT="TESTS-RESULTS/2026-11-20+GH-1545/outputs"
mkdir -p "$OUT"
PRE_SHA="6270a2b5da9964d3f4d99ed4fa1755397d398561"
IN_DIR="TESTS-RESULTS/2026-11-19+GH-1527/inputs"
RUN1="TESTS-RESULTS/2026-11-20+GH-1545/inputs/run1-run-record-92ff5ce.md"

echo "=== 1. Pin verification & read-only baseline snapshot ==="
git rev-parse "$PRE_SHA"
git rev-parse HEAD
git show "$PRE_SHA:skills/1-hourly/kickstart/scripts/build_queue.py" > /tmp/ks03_pre_build_queue.py
REFS_BEFORE="$(git show-ref)"
FETCH_BEFORE="$(shasum -a 256 .git/FETCH_HEAD 2>/dev/null || echo NONE)"
OBJS_BEFORE="$(git count-objects -v)"

echo "=== 2. Paired queue-generation replay (pre-change vs changed) ==="
FLAGS=(
  --repo-root .
  --as-of 2026-11-19
  --owner noelsaw1
  --other-session 1400,1418
  --needs-operator 1508
  --repo-slug HiQS-Labs/XYZ-forge
  --prs-json "$IN_DIR/pr_minder.json"
  --pr-meta-json "$IN_DIR/pr_meta.json"
  --issues-json "$IN_DIR/issues.json"
)
python3 /tmp/ks03_pre_build_queue.py "${FLAGS[@]}" --out "$OUT/pre-change-authority.md"
python3 skills/1-hourly/kickstart/scripts/build_queue.py "${FLAGS[@]}" --out "$OUT/changed-authority.md"
python3 skills/1-hourly/kickstart/scripts/build_queue.py "${FLAGS[@]}" --out /tmp/ks03_changed_run2.md

echo "=== 3. Determinism & Queue/Needs-operator/Not-queued byte-invariance ==="
cmp -s "$OUT/changed-authority.md" /tmp/ks03_changed_run2.md && echo "PASS: determinism cmp=0"
python3 - "$OUT/pre-change-authority.md" "$OUT/changed-authority.md" "$RUN1" "$OUT/decision-replay.txt" <<'PYEOF'
import pathlib, re, sys

pre_txt = pathlib.Path(sys.argv[1]).read_text()
chg_txt = pathlib.Path(sys.argv[2]).read_text()
run1_txt = pathlib.Path(sys.argv[3]).read_text()
out_path = pathlib.Path(sys.argv[4])

def split_sections(text: str):
    idx = text.index("## Queue (execution order)")
    return text[:idx], text[idx:]

pre_auth, pre_tail = split_sections(pre_txt)
chg_auth, chg_tail = split_sections(chg_txt)

assert pre_tail == chg_tail, "FAIL: Queue/Needs-operator/Not-queued sections drifted"
assert "Status: NOT YET GRANTED." in pre_auth and "Status: NOT YET GRANTED." in chg_auth
print("PASS: Queue / Needs-operator / Not-queued byte-identical; Status: NOT YET GRANTED preserved")

checks = {
    "cr_30min_current_head": re.compile(r"30 min\s+have passed since a \"@coderabbitai review\" request on the current head", re.S),
    "cr_reread_pre_merge": re.compile(r"Re-read\s+reviews immediately before the merge", re.S),
    "cr_waiver_wording": re.compile(r"advisory not received;\s+predeclared waiver used", re.S),
    "cr_major_blocks": re.compile(r"Any Major that CodeRabbit posted blocks\s+until it is fixed or answered", re.S),
    "ks11a_round_cap": re.compile(r"Round cap \(KS-11a\): land only with an independent reviewer's explicit approval covering the final\s+head", re.S),
    "ks11a_protected_surfaces": re.compile(r"Never auto-accept on\s+gate, hook, containment, schema, kernel, or Costly surfaces", re.S),
    "ks11b_conflict_hubs": re.compile(r"Conflict hubs \(KS-11b\): conflict hubs reported by the merge-cleanup forecast route to a separate\s+recorded batch", re.S),
    "ks11c_ks02_decisions": re.compile(r"Operator decisions \(KS-11c / KS-02\): release holds only when authored by noelsaw1, applicable,\s+and not superseded", re.S),
    "quota_fallback_verbatim": re.compile(r"stop reason verbatim states quota, switch that\s+turn's reviewer to agy and record the actual model name; if both providers are capped, park", re.S),
    "flywheel_per_pr_approval": re.compile(r"satisfies Flywheel's per-PR merge\s+approval step \(skills/2-daily/flywheel/SKILL\.md:109-120\) for noelsaw1 PRs", re.S),
    "flywheel_full_sha_pin": re.compile(r"exact full-SHA --prs N@<approved-full-sha> pin verification before --execute still applies", re.S),
}

for name, rx in checks.items():
    pre_hit = bool(rx.search(pre_auth))
    chg_hit = bool(rx.search(chg_auth))
    print(f"CLAUSE {name}: pre_change={pre_hit} changed={chg_hit}")
    assert not pre_hit, f"FAIL: expected red pre-change on {name}"
    assert chg_hit, f"FAIL: expected green changed on {name}"

# Verify pinned run-1 evidence anchors exist verbatim in retained run1-run-record-92ff5ce.md
anchors = [
    ("OA-3 03:12Z CodeRabbit advisory", "OPERATOR_AMENDMENT: OA-3 2026-11-20T03:12Z CodeRabbit advisory, 30-min max wait"),
    ("#1495/#1496 02:50Z rate-limited", "item 5a (#1495, #1496): READY except CodeRabbit — heads 239183bf7 / 48e0f6b09"),
    ("#1526 2 CodeRabbit Majors", "item 0a (#1526): IN REVIEW — merged development in (CHANGELOG both kept), fixed 2 CodeRabbit Majors"),
    ("#1519/#1532 3-round cap", "item 7 (#1519): DRAFT PR https://github.com/HiQS-Labs/XYZ-forge/pull/1532 head eea4c81a0"),
    ("S-2 02:02Z false agy switch", "SUPERVISION: S-2 2026-11-20T02:02Z parent instructed an agy QA switch (round cap misread as quota)"),
    ("02:06Z withdrawal", "PARENT 2026-11-20T02:06Z: CORRECTION to the 02:02Z note: the \"cap\" on #1519 was the 3-round relay cap, not Codex usage."),
]
for label, needle in anchors:
    assert needle in run1_txt, f"FAIL: missing run-1 anchor {label}"
    print(f"RUN1_ANCHOR OK: {label}")

# Bounded decision replay evaluating pre-change vs changed AUTHORITY clauses
def eval_authority(auth_text: str, case: dict) -> str:
    has_cr_waiver = bool(checks["cr_30min_current_head"].search(auth_text) and checks["cr_waiver_wording"].search(auth_text))
    has_ks11a = bool(checks["ks11a_round_cap"].search(auth_text) and checks["ks11a_protected_surfaces"].search(auth_text))
    has_quota = bool(checks["quota_fallback_verbatim"].search(auth_text))
    has_flywheel = bool(checks["flywheel_per_pr_approval"].search(auth_text))

    kind = case["kind"]
    if kind == "cr_merge":
        if case["open_major"]:
            return "BLOCK: open CodeRabbit Major must be fixed or answered"
        if case["cr_reviewed_current_head"]:
            return "MERGE: CodeRabbit reviewed current head with 0 open Major"
        if not has_cr_waiver:
            return "HOLD / MANUAL_AMENDMENT_REQUIRED: pre-change authority has no 30-min advisory waiver"
        if case["request_head"] != case["current_head"]:
            return "WAIT: U5 stale-head request does not start the 30-min clock on current head"
        if case["elapsed_min_on_current_head"] < 30:
            return "WAIT: <30 min elapsed on current head"
        if case["late_major_on_reread"]:
            return "BLOCK: immediate pre-merge re-read found a posted Major"
        return "MERGE_AUTONOMOUS: advisory not received; predeclared waiver used (current head verified)"
    if kind == "round_cap":
        if not has_ks11a:
            return "HOLD / OPERATOR_ESCALATION: pre-change authority lacks KS-11a round-cap and quota rules"
        if case["stop_reason"] == "provider-quota":
            if case["agy_capped"]:
                return "PARK: both reviewer providers quota-capped"
            return "SWITCH_REVIEWER_AGY: verbatim quota stop reason; record actual agy model"
        if case["explicit_final_head_approval"] and case["minor_nit_accepted"] and not case["protected_surface"]:
            return "LAND_WITH_DISCLOSURE: explicit final-head approval with reviewer-accepted Minor/nit deferral"
        return "PARK_FAIL_CLOSED: no explicit final-head approval or protected surface; refuse agy switch on non-quota cap"
    if kind == "quota":
        if not has_quota:
            return "HOLD / PARENT_INTERVENTION: pre-change authority has no quota fallback rule"
        if not case["verbatim_quota"]:
            return "NO_SWITCH: stop reason is not verbatim quota"
        if case["agy_capped"]:
            return "PARK: both reviewer providers quota-capped"
        return "SWITCH_REVIEWER_AGY: verbatim quota stop reason; record actual agy model"
    if kind == "flywheel_approval":
        if case["author"] != "noelsaw1":
            return "STOP_AND_ASK: non-owner PR out of scope"
        if not case["full_sha_pin_verified"]:
            return "HOLD: full-SHA --prs pin not verified"
        if not has_flywheel:
            return "MANUAL_PER_PR_APPROVAL_REQUIRED: pre-change authority does not state Flywheel per-PR satisfaction"
        return "APPROVED_UNDER_LAUNCH_GRANT: Flywheel per-PR approval satisfied for noelsaw1 with verified full-SHA pin"
    raise ValueError(kind)

cases = [
    {
        "id": "Case A (Observed run-1: #1495/#1496 02:50Z->03:20Z+)",
        "provenance": "OBSERVED run-1 history (run1-run-record-92ff5ce.md lines 91, 96, 100, 112)",
        "kind": "cr_merge",
        "open_major": False, "cr_reviewed_current_head": False,
        "request_head": "239183bf7", "current_head": "239183bf7",
        "elapsed_min_on_current_head": 31, "late_major_on_reread": False,
    },
    {
        "id": "Case B (Synthetic U5 control: stale-head request timer)",
        "provenance": "SYNTHETIC negative control (head pushed after request)",
        "kind": "cr_merge",
        "open_major": False, "cr_reviewed_current_head": False,
        "request_head": "239183bf7", "current_head": "999999999",
        "elapsed_min_on_current_head": 35, "late_major_on_reread": False,
    },
    {
        "id": "Case C1 (Observed run-1: #1526 posted CodeRabbit Majors)",
        "provenance": "OBSERVED run-1 history (run1-run-record-92ff5ce.md line 73)",
        "kind": "cr_merge",
        "open_major": True, "cr_reviewed_current_head": True,
        "request_head": "5c5557936", "current_head": "5c5557936",
        "elapsed_min_on_current_head": 45, "late_major_on_reread": False,
    },
    {
        "id": "Case C2 (Synthetic U5 control: late Major found on pre-merge re-read)",
        "provenance": "SYNTHETIC negative control (late Major before merge)",
        "kind": "cr_merge",
        "open_major": False, "cr_reviewed_current_head": False,
        "request_head": "239183bf7", "current_head": "239183bf7",
        "elapsed_min_on_current_head": 32, "late_major_on_reread": True,
    },
    {
        "id": "Case D (Observed run-1: #1519/#1532 cap-stalled on gate surface)",
        "provenance": "OBSERVED run-1 history (run1-run-record-92ff5ce.md lines 85-87, 94, 111, 115)",
        "kind": "round_cap",
        "stop_reason": "cap-stalled", "agy_capped": False,
        "explicit_final_head_approval": False, "minor_nit_accepted": False, "protected_surface": True,
    },
    {
        "id": "Case E1 (Synthetic quota control: verbatim quota -> agy)",
        "provenance": "SYNTHETIC positive control",
        "kind": "quota",
        "verbatim_quota": True, "agy_capped": False,
    },
    {
        "id": "Case E2 (Synthetic quota control: both providers capped -> park)",
        "provenance": "SYNTHETIC negative control",
        "kind": "quota",
        "verbatim_quota": True, "agy_capped": True,
    },
    {
        "id": "Case F (Synthetic KS-11a control: explicit approval + accepted Minor/nit deferral on docs)",
        "provenance": "SYNTHETIC positive control (non-protected surface)",
        "kind": "round_cap",
        "stop_reason": "approved-with-minor", "agy_capped": False,
        "explicit_final_head_approval": True, "minor_nit_accepted": True, "protected_surface": False,
    },
    {
        "id": "Case G1 (Observed run-1: noelsaw1 PR with verified full-SHA pin)",
        "provenance": "OBSERVED run-1 class (#1525/#1529/#1495/#1496)",
        "kind": "flywheel_approval",
        "author": "noelsaw1", "full_sha_pin_verified": True,
    },
    {
        "id": "Case G2 (Synthetic boundary control: non-owner PR)",
        "provenance": "SYNTHETIC negative control",
        "kind": "flywheel_approval",
        "author": "other-author", "full_sha_pin_verified": True,
    },
]

lines = ["# KS-03 Paired Authority Decision Replay (pre-change 6270a2b5 vs changed 8631a718)", ""]
for c in cases:
    pre_d = eval_authority(pre_auth, c)
    chg_d = eval_authority(chg_auth, c)
    lines.append(f"## {c['id']}")
    lines.append(f"- Source: {c['provenance']}")
    lines.append(f"- Pre-change (`6270a2b5`): {pre_d}")
    lines.append(f"- Changed    (`8631a718`): {chg_d}")
    lines.append("")
    print(f"REPLAY {c['id']}\n  PRE: {pre_d}\n  CHG: {chg_d}")

assert "MANUAL_AMENDMENT_REQUIRED" in eval_authority(pre_auth, cases[0])
assert "advisory not received; predeclared waiver used" in eval_authority(chg_auth, cases[0])
assert "WAIT: U5 stale-head" in eval_authority(chg_auth, cases[1])
assert "BLOCK: open CodeRabbit Major" in eval_authority(chg_auth, cases[2])
assert "BLOCK: immediate pre-merge re-read" in eval_authority(chg_auth, cases[3])
assert "OPERATOR_ESCALATION" in eval_authority(pre_auth, cases[4])
assert "PARK_FAIL_CLOSED" in eval_authority(chg_auth, cases[4])
assert "SWITCH_REVIEWER_AGY" in eval_authority(chg_auth, cases[5])
assert "PARK: both reviewer providers" in eval_authority(chg_auth, cases[6])
assert "LAND_WITH_DISCLOSURE" in eval_authority(chg_auth, cases[7])
assert "MANUAL_PER_PR_APPROVAL_REQUIRED" in eval_authority(pre_auth, cases[8])
assert "APPROVED_UNDER_LAUNCH_GRANT" in eval_authority(chg_auth, cases[8])
assert "STOP_AND_ASK" in eval_authority(chg_auth, cases[9])

out_path.write_text("\n".join(lines))
print("PASS: all 10 paired decision-replay assertions passed")
PYEOF

echo "=== 4. Read-only invariance check ==="
REFS_AFTER="$(git show-ref)"
FETCH_AFTER="$(shasum -a 256 .git/FETCH_HEAD 2>/dev/null || echo NONE)"
OBJS_AFTER="$(git count-objects -v)"
[ "$REFS_BEFORE" = "$REFS_AFTER" ] && echo "PASS: git show-ref unchanged"
[ "$FETCH_BEFORE" = "$FETCH_AFTER" ] && echo "PASS: FETCH_HEAD unchanged"
[ "$OBJS_BEFORE" = "$OBJS_AFTER" ] && echo "PASS: git count-objects unchanged"

echo "=== 5. CI route classification & mypy ==="
git diff --name-only "$PRE_SHA"..HEAD | ./utils/ci-route.sh pull_request
mypy --allow-untyped-defs --allow-incomplete-defs skills/1-hourly/kickstart/scripts/build_queue.py
rm -f /tmp/ks03_pre_build_queue.py /tmp/ks03_changed_run2.md
```

## 2. Summary of Results
- **Paired queue-generation replay:** All 11 clause assertions failed on pinned pre-change `6270a2b5da9964d3f4d99ed4fa1755397d398561` (`pre_change=False`) and passed on candidate `8631a7187b6591d084f93ed386ac49960513b04c` (`changed=True`). Queue / Needs-operator / Not-queued sections remained byte-identical and `Status: NOT YET GRANTED.` remained intact.
- **Paired decision replay (`outputs/decision-replay.txt`):** All 10 cases passed, distinguishing observed run-1 history (`Cases A, C1, D, G1`, anchored verbatim in `inputs/run1-run-record-92ff5ce.md`) from synthetic negative/positive controls (`Cases B, C2, E1, E2, F, G2`).
- **Determinism & read-only invariance:** Two back-to-back runs matched byte-for-byte (`cmp=0`), and `git show-ref`, `FETCH_HEAD`, and `git count-objects -v` were unchanged.
- **Classified gate:** `utils/ci-route.sh pull_request` → `route=docs`, `tier=1`; `./utils/pdda/pdda.sh run` exited `0` with `0 errors` (`pdda-run.log`).
- **Static check:** `mypy --allow-untyped-defs --allow-incomplete-defs` (1.14.1; allowing pre-existing untyped functions outside this template-only diff) reported `Success: no issues found in 1 source file`.
