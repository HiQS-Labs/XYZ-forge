"""GH-1344 witnesses for Acceptance 1 (moved/renamed doc readers) and 5 (partial delivery).

Usage: python3 -I witness_1344.py <head_clone> <base_worktree>
Runs each reader from the base tree (3a563a9f) and from HEAD against the same scratch copy of
HEAD's PROJECT/ + releases.db, so red/green differs only by code.
"""
import importlib.util, json, os, shutil, subprocess, sys, tempfile
from unittest import mock

head, base = sys.argv[1], sys.argv[2]


def load(tree, name):
    sys.path.insert(0, os.path.join(tree, "utils", "py"))
    try:
        for m in [k for k in list(sys.modules) if k in ("jog_run", "wave_reconcile", "releases_app")]:
            del sys.modules[m]
        spec = importlib.util.spec_from_file_location(name, os.path.join(tree, "utils", "py", name + ".py"))
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        return mod
    finally:
        sys.path.pop(0)


def fixture():
    d = tempfile.mkdtemp(prefix="w1344-")
    shutil.copytree(os.path.join(head, "PROJECT"), os.path.join(d, "PROJECT"))
    shutil.copy(os.path.join(head, "releases.db"), d)
    subprocess.run(["git", "init", "-q", d], check=True)
    # Acceptance 1 move: rename a doc whose identity lives only in frontmatter.
    src = os.path.join(d, "PROJECT/1-INBOX/GH-1292-HARNESS-RECAP-HOOKS.md")
    dst = os.path.join(d, "PROJECT/2-WORKING/harness-recap-hooks.md")
    os.replace(src, dst)
    return d


out = {"acceptance_1": {}, "acceptance_5": {}}
for label, tree in (("base_3a563a9f", base), ("head", head)):
    d = fixture()
    row = {}
    jr = load(tree, "jog_run")
    try:
        row["jog_run.find_issue_doc(1292)"] = jr.find_issue_doc(d, 1292)
    except Exception as e:
        row["jog_run.find_issue_doc(1292)"] = f"{type(e).__name__}: {e}"
    wr = load(tree, "wave_reconcile")
    try:
        row["wave_reconcile.find_active_doc_for_issue(1292)"] = wr.find_active_doc_for_issue(d, 1292)
    except Exception as e:
        row["wave_reconcile.find_active_doc_for_issue(1292)"] = f"{type(e).__name__}: {e}"
    # Bash resolver: see pdda_fn.sh / pdda-resolver-1292.txt (sourcing pdda.sh whole runs its CLI).
    out["acceptance_1"][label] = row
    shutil.rmtree(d)

# Acceptance 5: partial delivery stays open with one comment; proof closes.
jr = load(head, "jog_run")
cases = {
    "partial_no_proof": ({"state": "OPEN", "body": "## Acceptance\n- [x] a\n- [ ] b\n", "comments": []}, {}),
    "checklist_complete": ({"state": "OPEN", "body": "## Acceptance\n- [x] a\n- [x] b\n", "comments": []}, {}),
    "partial_with_coverage_proof": ({"state": "OPEN", "body": "## Acceptance\n- [x] a\n- [ ] b\n", "comments": []},
                                    {"head_sha": "abc", "builder": "codex",
                                     "whole_issue_coverage": {"issue": 1344, "head_sha": "abc", "covers_whole_issue": True,
                                                              "reviewer": "claude", "evidence_path": "x"}}),
    "partial_marker_already_present": ({"state": "OPEN", "body": "## Acceptance\n- [ ] b\n",
                                        "comments": [{"body": "<!-- jog-delivered-open:1344 -->\nreason"}]}, {}),
}
for name, (issue, receipt) in cases.items():
    calls = []

    def fake_run(cmd, *a, **k):
        calls.append(cmd[1:3] if cmd[0] == "gh" else cmd[:2])
        return subprocess.CompletedProcess(cmd, 0, json.dumps(issue) if cmd[:3] == ["gh", "issue", "view"] else "", "")

    with mock.patch.object(jr, "github_slug_from_origin", return_value="HiQS-Labs/XYZ-forge"), \
         mock.patch.object(jr.subprocess, "run", side_effect=fake_run):
        try:
            res = jr._close_delivered_issue(head, 1344, 9999, "abc", receipt)
        except Exception as e:
            res = f"{type(e).__name__}: {e}"
    out["acceptance_5"][name] = {"closed": res, "gh_calls": [" ".join(c) for c in calls]}

base_closes = subprocess.run(["grep", "-n", "lane-closes-issue", f"{base}/utils/py/jog_run.py"], capture_output=True, text=True).stdout
out["acceptance_5"]["base_3a563a9f_lane_closes_issue"] = base_closes.strip().splitlines()
print(json.dumps(out, indent=2, default=str))
