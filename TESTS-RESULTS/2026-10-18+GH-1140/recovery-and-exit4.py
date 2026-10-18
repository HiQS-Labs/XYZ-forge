#!/usr/bin/env python3
"""GH-1140 manual checks: (a) _recover_unrecorded_merges records positive MERGED evidence only,
(b) the recovered batch becomes QA-pending and reachable via the same find_unfinished call
main()'s final-status fallback uses (the literal exit-4 rc is pinned by the suite:
TestMergeCleanupOrchestration.test_plain_rerun_one_pr_queue_surfaces_owed_qa_as_exit_4 and
.test_teardown_only_execute_surfaces_owed_qa_as_exit_4, red-controlled)."""
import json, sys, tempfile, types
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
        2: {"state": "CLOSED"}}                                       # closed, no merge evidence -> untouched
with mock.patch.object(merge_cleanup, "refresh_pr_with_retry",
                       side_effect=lambda n, p: live.get(n, {"error": "x"})), \
     mock.patch.object(merge_cleanup, "_gh"), \
     mock.patch.object(batch_record, "update"):
    merge_cleanup._recover_unrecorded_merges(Path(tmp), "ex/ample", "development",
                                             [{"number": 3}])  # discovery: unrelated OPEN PR only
disk = json.loads(path.read_text())
a = disk["outcomes"]["1"]; b = disk["outcomes"]["2"]
rec_ok = (a.get("status") == "merged" and a.get("merge_oid") == "a" * 40
          and b.get("status") == "unattempted" and not b.get("merge_oid"))
print("(a) recovery:", a.get("status"), (a.get("merge_oid") or "")[:6], "/", b.get("status"),
      "->", "PASS" if rec_ok else "FAIL")

# (b) final-status: the recovered batch is now QA-pending and must be surfaced even though this
# run's own batch is None (plain rerun shape).
pending = batch_record.find_unfinished(Path(tmp), "ex/ample", "development", [], need_qa=True)
b_ok = pending is not None and batch_record.qa_pending(pending)
print("(b) exit-4 reachability after plain-rerun shape:", "->", "PASS" if b_ok else "FAIL")
# (c) GH-1140 r3: the recovered landing set must carry complete, runnable sweep inputs —
# finalized by the recovery pass itself, not only by a landing loop that never ran here.
disk2 = json.loads(path.read_text())
s = disk2.get("sweep_inputs") or {}
c_ok = bool(s.get("range")) and "shared_files" in s and "command" in s and "<tmp>" not in s.get("command", "<tmp>")
print("(c) recovered sweep inputs:", {k: s.get(k) for k in ("range", "shared_files")}, "cmd-safe:", "<tmp>" not in s.get("command", "<tmp>"),
      "->", "PASS" if c_ok else "FAIL")
sys.exit(0 if (rec_ok and b_ok and c_ok) else 1)
