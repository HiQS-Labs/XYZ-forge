import json
from unittest.mock import mock_open, patch
import gate_receipt as g, jog_run as j, rtl

sha, key = "a" * 40, "GH-1653-jog-publish"
old, new = "marathon/old", "marathon/new"
row = {"schema": rtl.ATTEMPT_SCHEMA, "task": key, "kind": "manual",
       "state": "active", "id": "c" * 32, "target_root": "/exec",
       "origin": "d" * 64, "branch": new, "start_sha": sha,
       "started": "2026-11-27T00:00:00+00:00"}
def metadata(_root, verb, *_):
    return {"branch": new, "rev-parse": sha, "merge-base": ""}[verb]

with patch("builtins.open", mock_open(read_data=json.dumps(row) + "\n")), \
     patch.object(g.os.path, "isfile", return_value=True), \
     patch.multiple(g, attempt_git=metadata, attempt_origin=lambda _: row["origin"]), \
     patch.multiple(j, _git=lambda *_: sha.encode(),
                    _jog_remote_ref=lambda _, branch: sha if branch == old else None), \
     patch.object(g, "lane_attempt_finish", return_value=dict(row, state="completed")) as finish:
    j.jog_settle_publication_attempt("/exec", "/coord", 1653, old, True,
                                     need_published=False)
    print(f"proved={old}; checked out/reserved={new}; finish called={finish.called}; "
          f"archive={finish.call_args.kwargs.get('archive') if finish.called else False}")
    assert not finish.called
