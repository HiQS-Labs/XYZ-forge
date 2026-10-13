#!/usr/bin/env python3
"""GH-789 red controls for manual_matrix.py (evidence script, NOT a registered suite — GH-831).

Run ONLY from a disposable full clone (it edits merge-cleanup scripts in place, then restores them):
    python3 TESTS-RESULTS/2026-10-05+GH-789/red_controls.py
For each control: apply one exact mutation, run the matrix, record exit code, cases collected and the
failing case names, restore the original bytes. Writes red-controls-<id>.log files and
red-controls.jsonl next to this script. Exit 0 only if the candidate is green and every control is red
on its expected case.
"""
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
S = REPO / "skills" / "2-daily" / "merge-cleanup" / "scripts"
MATRIX = HERE / "manual_matrix.py"
REBASE_DELETE = re.compile(r'\["update-ref", "-d", "REBASE_HEAD", [^\]]+\]')


def sub(old, new):
    def apply(text):
        assert old in text, f"mutation anchor not found: {old[:60]!r}"
        return text.replace(old, new, 1)
    return apply


def regex(pattern, new):
    def apply(text):
        out, n = pattern.subn(new, text, count=1)
        assert n == 1, f"mutation pattern not found: {pattern.pattern}"
        return out
    return apply


def second_post_poll_skip(text):
    marker = 'log(f"PR #{p_num}: SKIPPED (draft)")'
    sites = [m.start() for m in re.finditer(re.escape(marker), text)]
    assert len(sites) == 2, f"expected 2 initial/post-poll skip sites, found {len(sites)}"
    j = text.rfind('if info.get("isDraft"):', 0, sites[1])
    return text[:j] + "if False:" + text[j + len('if info.get("isDraft"):'):]


# id, file, mutation, expected failing case(s), description
CONTROLS = [
    ("R0", None, None, None, "all four scripts restored to development 442ea913 (unported)"),
    ("R1", "merge_cleanup.py", sub('if live.get("isDraft"):\n                log(f"PR #{p_num}: SKIPPED (draft before merge)")',
                                   'if False:\n                log(f"PR #{p_num}: SKIPPED (draft before merge)")'),
     ["test_draft_appearing_after_gate_never_reaches_merge_api"], "pre-merge draft recheck disabled"),
    ("R1b", "merge_cleanup.py", second_post_poll_skip,
     ["test_draft_appearing_during_poll_never_reaches_repair"], "post-UNKNOWN-poll draft skip disabled"),
    ("R2", "merge_cleanup.py", sub("if not ok and why == DRAFT_REFUSAL:", "if False:"),
     ["test_draft_at_repaired_push_is_skipped_and_independent_lands", "test_draft_at_repaired_push_blocks_its_hard_dependent"],
     "push-boundary DRAFT_REFUSAL skip disabled (falls to the fail-closed stop)"),
    ("R2b", "merge_cleanup.py", sub('B1 result kept at {clone})")\n                    failed[p_num] = "draft"\n                    keep_workdir = True\n                    continue',
                                    'B1 result kept at {clone})")\n                    failed[p_num] = "draft"\n                    keep_workdir = True\n                    return 0'),
     ["test_draft_at_repaired_push_is_skipped_and_independent_lands", "test_draft_at_repaired_push_blocks_its_hard_dependent"],
     "push-boundary skip returns early instead of continuing the queue"),
    ("R3", "ledger_merge.py", sub('raise ValueError("changelog preamble or existing history changed")', "pass  # RED CONTROL"),
     ["test_reordered_base_sections_are_rejected"], "union_changelog history-changed check removed"),
    ("R4", "merge_cleanup.py", regex(REBASE_DELETE, '["update-ref", "-d", "REBASE_HEAD"]'),
     ["test_rebase_head_moved_after_inspection_is_not_deleted"], "REBASE_HEAD deleted without the observed oid"),
]


def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()[:16]


def run(tag):
    r = subprocess.run([sys.executable, str(MATRIX)], cwd=REPO, capture_output=True, text=True)
    log = r.stdout + r.stderr
    (HERE / f"red-controls-{tag}.log").write_text(log.replace(str(Path.home()), "~"))
    ran = re.findall(r"Ran (\d+) tests?", log)
    failing = sorted(set(re.findall(r"^(?:FAIL|ERROR): (test_\w+)", log, re.M)))
    return r.returncode, (int(ran[-1]) if ran else 0), failing


def main():
    head = subprocess.run(["git", "rev-parse", "--short=8", "HEAD"], cwd=REPO, capture_output=True, text=True).stdout.strip()
    originals = {p.name: p.read_bytes() for p in S.glob("*.py")}
    base = {"sha": head, "matrix_sha256": sha(MATRIX), "command": f"python3 {MATRIX.relative_to(REPO)}"}
    rows, ok = [], True
    rc, n, failing = run("candidate")
    rows.append(dict(base, kind="manual_matrix", id="candidate", exit_code=rc, collected=n, failing=failing,
                     log="red-controls-candidate.log"))
    ok &= rc == 0 and n > 0 and not failing
    try:
        for cid, fname, mutate, expect, desc in CONTROLS:
            if cid == "R0":
                for f in ("merge_cleanup", "ledger_merge", "scan_clones", "toposort_prs"):
                    blob = subprocess.run(["git", "show", f"442ea913:skills/2-daily/merge-cleanup/scripts/{f}.py"],
                                          cwd=REPO, capture_output=True, check=True).stdout
                    (S / f"{f}.py").write_bytes(blob)
                mutated = "4 files @ 442ea913"
            else:
                target = S / fname
                target.write_text(mutate(target.read_text()))
                mutated = f"{fname} sha256 {sha(target)}"
            rc, n, failing = run(cid)
            hit = rc != 0 and (expect is None or all(e in failing for e in expect))
            ok &= hit
            rows.append(dict(base, kind="red_control", id=cid, mutation=desc, mutated=mutated, expected_failing=expect,
                             exit_code=rc, collected=n, failing=failing, red_as_expected=hit,
                             log=f"red-controls-{cid}.log"))
            for name, data in originals.items():
                (S / name).write_bytes(data)
    finally:
        for name, data in originals.items():
            (S / name).write_bytes(data)
    (HERE / "red-controls.jsonl").write_text("".join(json.dumps(r) + "\n" for r in rows))
    for r in rows:
        print(r["id"], r["exit_code"], r["collected"], "OK" if r.get("red_as_expected", r["exit_code"] == 0) else "UNEXPECTED",
              ",".join(r["failing"])[:160])
    print("RESULT:", "ALL CONTROLS AS EXPECTED" if ok else "UNEXPECTED")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
