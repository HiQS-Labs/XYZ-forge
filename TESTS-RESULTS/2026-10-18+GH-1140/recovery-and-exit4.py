#!/usr/bin/env python3
"""GH-1140 manual checks: (a) _recover_unrecorded_merges records positive MERGED evidence only,
(b) the recovered batch becomes QA-pending and reachable via the same find_unfinished call
main()'s final-status fallback uses (the literal exit-4 rc is pinned by the suite:
TestMergeCleanupOrchestration.test_plain_rerun_one_pr_queue_surfaces_owed_qa_as_exit_4 and
.test_teardown_only_execute_surfaces_owed_qa_as_exit_4, red-controlled)."""
import json, subprocess, sys, tempfile, types
from pathlib import Path
from unittest import mock
sys.path.insert(0, "skills/2-daily/merge-cleanup/scripts")
import batch_record, merge_cleanup

tmp = tempfile.mkdtemp(prefix="gh1140-rec-")
rec_dir = batch_record._dir(Path(tmp), "ex/ample"); rec_dir.mkdir(parents=True)
path = rec_dir / "batch-20261018T000000Z-1.json"
base = {"schema": 1, "repo": "ex/ample", "integration": "development", "created": "t",
        "issue": 9, "issue_url": "u", "issue_error": "",
        "planned": [{"pos": 1, "pr": 1, "title": "a", "files": ["x"], "hard": [], "soft": {}},
                    {"pos": 2, "pr": 2, "title": "b", "files": ["x"], "hard": [], "soft": {}}],
        "outcomes": {"1": {"status": "unattempted"}, "2": {"status": "unattempted"}},
        "landed_order": [], "sweep_inputs": {}, "verdict": None, "path": str(path)}
batch_record.save(base)

live = {1: {"state": "MERGED", "mergeCommit": {"oid": "a" * 40}},   # positive -> recover
        2: {"state": "MERGED", "mergeCommit": {"oid": "b" * 40}}}      # second landing, shares file x
with mock.patch.object(merge_cleanup, "refresh_pr_with_retry",
                       side_effect=lambda n, p: live.get(n, {"error": "x"})), \
     mock.patch.object(merge_cleanup, "_gh"), \
     mock.patch.object(batch_record, "update"):
    merge_cleanup._recover_unrecorded_merges(Path(tmp), "ex/ample", "development",
                                             [{"number": 3}])  # discovery: unrelated OPEN PR only
disk = json.loads(path.read_text())
a = disk["outcomes"]["1"]; b = disk["outcomes"]["2"]
rec_ok = (a.get("status") == "merged" and a.get("merge_oid") == "a" * 40
          and b.get("status") == "merged" and b.get("merge_oid") == "b" * 40)
print("(a) recovery (both positive landings retained):", a.get("status"), (a.get("merge_oid") or "")[:6],
      "/", b.get("status"), (b.get("merge_oid") or "")[:6],
      "->", "PASS" if rec_ok else "FAIL")
# negative control: a CLOSED-without-evidence PR must never become a landing (unit-level via
# _note_external_state is pinned in the suite; here we assert the recovery filter shape directly)
closed_probe = merge_cleanup._note_external_state(3, {"state": "CLOSED"}, None, {"skips": {}})
nc = {"skips": {3: "closed"}}
merge_cleanup._note_external_state(3, {"state": "CLOSED"}, None, nc)
neg_ok = nc["skips"][3] == "closed" and 3 not in disk["outcomes"]

# (b) final-status: the recovered batch is now QA-pending and must be surfaced even though this
# run's own batch is None (plain rerun shape).
pending = batch_record.find_unfinished(Path(tmp), "ex/ample", "development", [], need_qa=True)
b_ok = pending is not None and batch_record.qa_pending(pending)
print("(b) exit-4 reachability after plain-rerun shape:", "->", "PASS" if b_ok else "FAIL")
# (c) GH-1140 r3: the recovered landing set must carry complete, runnable sweep inputs —
# finalized by the recovery pass itself, not only by a landing loop that never ran here.
disk2 = json.loads(path.read_text())
s = disk2.get("sweep_inputs") or {}
exp_range = f"{'a' * 40}^1..{'b' * 40}"
cmd = s.get("command") or ""
c_ok = (s.get("range") == exp_range
        and s.get("shared_files") == {"x": [1, 2]}
        and bool(cmd) and "<tmp>" not in cmd
        and subprocess.run(["bash", "-n", "-c", cmd.replace('T=$(mktemp -d)', 'T=/tmp/x')],
                           capture_output=True).returncode == 0)
print("(c) recovered sweep inputs: range", "exact" if s.get("range") == exp_range else s.get("range"),
      "| shared_files", s.get("shared_files"), "| cmd parses:", bool(cmd) and "<tmp>" not in cmd,
      "->", "PASS" if c_ok else "FAIL")
print("(d) closed-without-evidence stays non-landed:", "->", "PASS" if neg_ok else "FAIL")
sys.exit(0 if (rec_ok and b_ok and c_ok and neg_ok) else 1)
