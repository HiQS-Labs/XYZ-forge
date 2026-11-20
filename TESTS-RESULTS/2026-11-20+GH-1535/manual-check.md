# Manual Check — GH-1535 (KS-02): Operator Decision Release & U15 Body/Label Holds

- **Issue:** `#1535` (refs `#1541` v5 KS-02 + U15 + KS-11c, `#1518`)
- **Pre-change pinned commit:** `6270a2b5da9964d3f4d99ed4fa1755397d398561` (`build_queue.py` pre-KS-02)
- **Changed candidate commit:** `5bea053cde97ad91b0b40482a7df0ee7290880af`
- **Base inputs:** `TESTS-RESULTS/2026-11-19+GH-1527/inputs/` (`pr_minder.json`, `pr_meta.json`, `issues.json`)
- **No new test suite (GH-831):** Recorded paired manual checks with red/negative controls and `provenance.jsonl`.

## 1. Runnable Verification Procedure (executed verbatim)

```bash
set -euo pipefail
OUT="TESTS-RESULTS/2026-11-20+GH-1535/outputs"
mkdir -p "$OUT"
PRE_SHA="6270a2b5da9964d3f4d99ed4fa1755397d398561"
IN_DIR="TESTS-RESULTS/2026-11-19+GH-1527/inputs"

echo "=== 1. Pin verification & read-only baseline snapshot ==="
git rev-parse "$PRE_SHA"
git rev-parse HEAD
git show "$PRE_SHA:skills/1-hourly/kickstart/scripts/build_queue.py" > /tmp/ks02_pre_build_queue.py
REFS_BEFORE="$(git show-ref)"
FETCH_BEFORE="$(shasum -a 256 .git/FETCH_HEAD 2>/dev/null || echo NONE)"
OBJS_BEFORE="$(git count-objects -v)"

echo "=== 2. Build paired replay fixtures and run pre-change vs changed ==="
python3 - "$IN_DIR" "$OUT" <<'PYEOF'
import copy, json, pathlib, subprocess, sys

in_dir = pathlib.Path(sys.argv[1])
out_dir = pathlib.Path(sys.argv[2])
base_prs = json.loads((in_dir / "pr_minder.json").read_text())
base_meta = json.loads((in_dir / "pr_meta.json").read_text())
base_issues = json.loads((in_dir / "issues.json").read_text())

def assert_true(cond, msg):
    assert cond, f"FAIL: {msg}"

def run_bq(script: str, prs, meta, issues, tag: str) -> str:
    tmp = pathlib.Path(f"/tmp/ks02_fx_{tag}")
    tmp.mkdir(parents=True, exist_ok=True)
    (tmp / "prs.json").write_text(json.dumps(prs))
    (tmp / "meta.json").write_text(json.dumps(meta))
    (tmp / "issues.json").write_text(json.dumps(issues))
    cmd = [
        sys.executable, script,
        "--repo-root", ".",
        "--as-of", "2026-11-19",
        "--owner", "noelsaw1",
        "--other-session", "1400,1418",
        "--needs-operator", "1435,1427",
        "--repo-slug", "HiQS-Labs/XYZ-forge",
        "--prs-json", str(tmp / "prs.json"),
        "--pr-meta-json", str(tmp / "meta.json"),
        "--issues-json", str(tmp / "issues.json"),
    ]
    res = subprocess.run(cmd, capture_output=True, text=True, check=True)
    return res.stdout

def sections(text: str):
    q = text.split("## Queue (execution order)")[1].split("## Needs the operator")[0]
    nd = text.split("## Needs the operator")[1].split("## Not queued")[0]
    nq = text.split("## Not queued")[1]
    return q, nd, nq

def add_comment(issues, num, author, body, ts="2026-11-20T01:43:10Z"):
    for it in issues:
        if it["number"] == num:
            it.setdefault("comments", []).append({
                "author": {"login": author},
                "body": body,
                "createdAt": ts,
            })

def make_issue(num, title, body="", labels=None, created="2026-11-18T12:00:00Z", comments=None):
    return {
        "number": num,
        "title": title,
        "body": body,
        "labels": [{"name": l} for l in (labels or [])],
        "createdAt": created,
        "comments": comments or [],
    }

PRE = "/tmp/ks02_pre_build_queue.py"
CHG = "skills/1-hourly/kickstart/scripts/build_queue.py"
report = ["# KS-02 Paired Pre-Change vs Changed Verification Matrix", ""]

def check_case(name, prs, meta, issues, pre_fn, chg_fn, save_prefix=None):
    pre_out = run_bq(PRE, prs, meta, issues, f"{name}_pre")
    chg_out = run_bq(CHG, prs, meta, issues, f"{name}_chg")
    if save_prefix:
        (out_dir / f"{save_prefix}-pre.md").write_text(pre_out)
        (out_dir / f"{save_prefix}-chg.md").write_text(chg_out)
    pre_fn(*sections(pre_out))
    chg_fn(*sections(chg_out))
    print(f"PASS: {name}")
    report.append(f"- **PASS** `{name}`")

# 1. #1518 Operator decision proceed -> unparks #1526 keeping (closes #1518)
i1 = copy.deepcopy(base_issues)
add_comment(i1, 1518, "noelsaw1", "Operator decision: start-task runs ci-local --fast; pre-push is the single full gate.")
check_case(
    "case1_1518_proceed_unparks_1526",
    base_prs, base_meta, i1,
    lambda q, nd, nq: assert_true("#1518" in nd and "#1526" in nd and "#1526" not in q, "pre should hold #1518 and park #1526"),
    lambda q, nd, nq: assert_true("#1526" in q and "(closes #1518)" in q and "#1518" not in nd and "#1526" not in nd, "chg should queue #1526 with closes #1518"),
    save_prefix="case1-1518-proceed",
)

# 2. #1518 Operator decision proceed standalone (after #1526 already merged) -> must NOT fall into rule 9 unclassified
p2 = [r for r in copy.deepcopy(base_prs) if r["pr"] != 1526]
m2 = [m for m in copy.deepcopy(base_meta) if m["number"] != 1526]
i2 = copy.deepcopy(i1)
check_case(
    "case2_1518_proceed_no_rule9_fallthrough",
    p2, m2, i2,
    lambda q, nd, nq: assert_true("#1518" in nd and "#1518" not in q, "pre keeps #1518 held"),
    lambda q, nd, nq: assert_true("#1518" in q and "operator decision recorded" in q and "#1518" not in nd, "chg queues #1518 without falling into rule 9"),
    save_prefix="case2-1518-no-rule9",
)

# 3. #1518 Operator decision: close -> close bucket (not rule 9, not held)
i3 = copy.deepcopy(base_issues)
add_comment(i3, 1518, "noelsaw1", "Operator decision: close — already landed in d7805a1c3.")
check_case(
    "case3_1518_operator_decision_close_bucket",
    p2, m2, i3,
    lambda q, nd, nq: assert_true("#1518" in nd and "#1518" not in q, "pre keeps #1518 held"),
    lambda q, nd, nq: assert_true("#1518" in q and "operator decision: close" in q and "verify acceptance on development" in q and "#1518" not in nd, "chg puts #1518 in close bucket"),
    save_prefix="case3-1518-close",
)

# 4. KS-11c negative controls: non-owner, wrong first line, superseded by Operator decision: hold
i4a = copy.deepcopy(base_issues)
add_comment(i4a, 1518, "someone-else", "Operator decision: proceed")
check_case(
    "case4a_non_owner_rejected",
    p2, m2, i4a,
    lambda q, nd, nq: assert_true("#1518" in nd, "pre holds"),
    lambda q, nd, nq: assert_true("#1518" in nd and "#1518" not in q, "chg rejects non-owner"),
)

i4b = copy.deepcopy(base_issues)
add_comment(i4b, 1518, "noelsaw1", "Notes first\nOperator decision: proceed")
check_case(
    "case4b_second_line_rejected",
    p2, m2, i4b,
    lambda q, nd, nq: assert_true("#1518" in nd, "pre holds"),
    lambda q, nd, nq: assert_true("#1518" in nd and "#1518" not in q, "chg requires first non-empty line"),
)

i4c = copy.deepcopy(base_issues)
add_comment(i4c, 1518, "noelsaw1", "Operator decision: proceed", ts="2026-11-20T01:00:00Z")
add_comment(i4c, 1518, "noelsaw1", "Operator decision: hold — wait for follow-up", ts="2026-11-20T02:00:00Z")
check_case(
    "case4c_superseded_by_hold",
    p2, m2, i4c,
    lambda q, nd, nq: assert_true("#1518" in nd, "pre holds"),
    lambda q, nd, nq: assert_true("#1518" in nd and "operator decision: hold" in nd and "#1518" not in q, "chg honors latest hold supersession"),
)

# 5. U15 body & label holds across issue types + formatted refs + absent-ref active clause + non-override + false-positive guards + PR propagation
i5 = copy.deepcopy(base_issues)
p5 = copy.deepcopy(base_prs)
m5 = copy.deepcopy(base_meta)

i5.extend([
    make_issue(9001, "bug: OL-10 body HELD marker", "Context\nHELD: owner decision required before dispatch.", labels=["bug"]),
    make_issue(9002, "docs: README.md update", "Simple docs tweak.", labels=["documentation", "status:held"]),
    make_issue(9003, "bug: blocked by ref in body", "Blocked by #1499 until merge completes.", labels=["bug"]),
    make_issue(9004, "bug: open PR after ref in body", "Run after #1467.", labels=["bug"]),
    make_issue(9005, "bug: absent ref active clause", "Only after #9999 lands should this run.", labels=["bug"]),
    make_issue(9006, "bug: formatted ref Blocked by", "Blocked by `#1499` per review.", labels=["bug"]),
    make_issue(9007, "bug: formatted ref Only after lands", "Only after `#1499` lands.", labels=["bug"]),
    make_issue(
        9008, "bug: decide title plus independent status:held",
        "HELD: waiting on external infra.", labels=["bug", "status:held"],
        comments=[{"author": {"login": "noelsaw1"}, "body": "Operator decision: proceed", "createdAt": "2026-11-20T01:00:00Z"}],
    ),
    make_issue(
        9009, "bug: wholly quoted example should NOT hold",
        "Doc note: ignore `HELD: example only` and `Blocked by #1499` and ```\nHELD: fenced\n```.",
        labels=["bug"],
    ),
])
p5.append({"pr": 9106, "title": "fix: GH-9006", "held": None, "inherited_hold": None, "draft": False, "conflicting": False, "failing": False, "behind": False})
m5.append({"number": 9106, "author": {"login": "noelsaw1"}, "title": "fix: GH-9006", "body": "Closes #9006", "mergeable": "MERGEABLE"})

check_case(
    "case5_u15_holds_formatted_refs_nonoverride_and_fp_guards",
    p5, m5, i5,
    lambda q, nd, nq: assert_true(all(f"#{n}" in q for n in (9001, 9002, 9003, 9004, 9005, 9006, 9007, 9009, 9106)), "pre-change queues all body/label held issues and PR #9106"),
    lambda q, nd, nq: (
        assert_true(all(f"#{n}" in nd and f"#{n}" not in q for n in (9001, 9002, 9003, 9004, 9005, 9006, 9007, 9008)), "chg holds 9001..9008 in Needs-operator"),
        assert_true("#9106" in nd and "merging it would close parked #9006" in nd and "#9106" not in q, "chg parks PR #9106 closing formatted-ref held #9006"),
        assert_true("#9009" in q and "#9009" not in nd, "chg does not false-positive on wholly quoted/fenced examples"),
        assert_true("#1412" in q and "#1412" not in nd, "chg does not false-positive on closed past-tense 'after #1403 passed'"),
        assert_true("#1476" in nq and "#1476" not in nd, "chg does not false-positive on inline-quoted `HELD:` in #1476"),
    ),
    save_prefix="case5-u15-holds",
)

# Determinism check
d1 = run_bq(CHG, p5, m5, i5, "det1")
d2 = run_bq(CHG, p5, m5, i5, "det2")
assert d1 == d2, "FAIL: non-deterministic output"
print("PASS: determinism byte-identical")
report.append("- **PASS** `determinism` (two back-to-back runs byte-identical)")
(out_dir / "matrix-summary.md").write_text("\n".join(report) + "\n")
PYEOF

echo "=== 3. Read-only invariance check ==="
REFS_AFTER="$(git show-ref)"
FETCH_AFTER="$(shasum -a 256 .git/FETCH_HEAD 2>/dev/null || echo NONE)"
OBJS_AFTER="$(git count-objects -v)"
[ "$REFS_BEFORE" = "$REFS_AFTER" ] && echo "PASS: git show-ref unchanged"
[ "$FETCH_BEFORE" = "$FETCH_AFTER" ] && echo "PASS: FETCH_HEAD unchanged"
[ "$OBJS_BEFORE" = "$OBJS_AFTER" ] && echo "PASS: git count-objects unchanged"

echo "=== 4. CI route classification & mypy ==="
git diff --name-only "$PRE_SHA"..HEAD | ./utils/ci-route.sh pull_request
mypy --allow-untyped-defs --allow-incomplete-defs skills/1-hourly/kickstart/scripts/build_queue.py
rm -rf /tmp/ks02_pre_build_queue.py /tmp/ks02_fx_*
```

## 2. Summary of Results
- **Paired pre-change vs changed controls (`outputs/matrix-summary.md` & `outputs/check-transcript.log`):**
  - `#1518` `Operator decision` proceed unparks PR `#1526` keeping `(closes #1518)` (red pre-change, green changed).
  - `#1518` `Operator decision` proceed standalone routes to `operator decision recorded` instead of rule 9 `unclassified` (red pre-change, green changed).
  - `#1518` `Operator decision: close` routes to the dedicated close bucket (`verify acceptance on development, then close with a comment citing the commit`) (red pre-change, green changed).
  - KS-11c fail-closed negatives: non-owner comment, second-line marker, and superseding `Operator decision: hold` all stay held.
  - U15 holds across all issue types: `HELD:` body marker, `status:held` label, `Blocked by #1499`, open-PR `after #1467`, absent-ref `Only after #9999 lands`, formatted-reference prose (``Blocked by `#1499` `` and ``Only after `#1499` lands``) + parked-PR propagation (`#9106`), and independent body/label hold surviving owner `Operator decision: proceed` — all red pre-change, green changed.
  - False-positive guards: wholly backtick-quoted/fenced examples (`#9009`, `#1476`) and past-tense `"after #1403 passed"` (`#1412`) do not spuriously hold.
- **Determinism, read-only invariance, route & static check:** byte-identical replay, zero ref/`FETCH_HEAD`/object changes, `route=docs`, `tier=1`, `./utils/pdda/pdda.sh run` exited `0` (`0 errors`), `mypy` exited `0`.
