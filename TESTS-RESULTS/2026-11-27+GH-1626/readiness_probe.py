#!/usr/bin/env python3
"""GH-1626 readiness probe (retained manual check, not a suite; GH-831).

Exit 0 only when the FIXED behavior is observed, with a one-PR queue (as main() requires):
  0. both landing calls return the expected code and refresh the fixture PR exactly once, AND
  1. a landing dry run (`land_prs(..., dry_run=True)`) leaves an old, tool-shaped
     `merge-cleanup-*` folder in place, AND
  2. the same call with dry_run=False still prunes it (positive control: the fix must not
     simply disable pruning).
Any other outcome, including a crash, exits nonzero, so the preflight contract
(`expect_nonzero: true`) reads it as unfixed.

Isolation: everything happens under a fresh fixture temp root (tempfile.tempdir is
redirected there before merge_cleanup is imported). Network and process-table lookups that
are not the seam under test are stubbed: the merge policy, origin URL, the
"another merge_cleanup.py is running" check, and lsof. No git remote, gh, or repo state is
touched.
"""
import os
import sys
import tempfile
import time
import types
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCRIPTS = ROOT / "skills/2-daily/merge-cleanup/scripts"
sys.dont_write_bytecode = True

fixture = Path(tempfile.mkdtemp(prefix="gh1626-probe-")).resolve()
tmp_root = fixture / "tmp"
tmp_root.mkdir()
primary = fixture / "primary"
primary.mkdir()
os.environ["TMPDIR"] = str(tmp_root)
tempfile.tempdir = str(tmp_root)
os.environ.pop("MERGE_CLEANUP_KEEP_WORKDIRS", None)

sys.path.insert(0, str(SCRIPTS))
import merge_cleanup as mc  # noqa: E402

POLICY = {"strategy": "merge", "preserve_commit_history": True, "source": "probe", "qualification": None}
mc.resolve_merge_policy = lambda *a, **k: dict(POLICY)
mc.check_merge_capability = lambda *a, **k: None
mc.origin_url = lambda *a, **k: "https://example.invalid/probe/repo.git"
mc._other_merge_cleanup_running = lambda: False
mc.scan_clones.inspect_open_handles = lambda path: {"verified": True, "active": False, "details": "probe"}


class Args(types.SimpleNamespace):
    def __getattr__(self, name):  # any flag the code path reads but the probe did not set
        return None


def plant():
    """Old tool-shaped folder + 3 newer ones (default keep=3), all owned by this user."""
    old = tmp_root / "merge-cleanup-oldprobe"
    (old / "pr-9-deadbeef-abcdefgh").mkdir(parents=True)
    past = time.time() - 3 * 3600
    for p in (old / "pr-9-deadbeef-abcdefgh", old):
        os.utime(p, (past, past))
    for i in range(3):
        newer = tmp_root / f"merge-cleanup-newer00{i}"
        newer.mkdir()
    return old


# Review round 1 (F1): main() only calls land_prs with a NONEMPTY queue, so the probe uses one
# fixture PR. Its live refresh is stubbed to a draft: the loop skips it (no landing clone, no
# merge, no gh call) and reaches the same end-of-loop cleanup a real dry-run landing reaches.
FIXTURE_PR = {"number": 9, "title": "gh1626 probe fixture", "_hard_deps": [], "_soft_deps": []}
refreshed = []


def _refresh(num, *a, **k):
    refreshed.append(num)
    return {"number": num, "state": "OPEN", "isDraft": True, "baseRefName": "development",
            "labels": [], "headRefOid": "0" * 40}


mc.refresh_pr_with_retry = _refresh
# A draft skip is an expected skip: the loop finishes cleanly and returns 0 (observed on base).
EXPECTED_RC = 0


def run(dry_run):
    for d in tmp_root.iterdir():
        mc.shutil.rmtree(d, ignore_errors=True)
    old = plant()
    args = Args(integration_branch="development", strategy=None, resume=False,
                execute=not dry_run, teardown_only=False, prs=[9])
    del refreshed[:]
    rc = mc.land_prs([dict(FIXTURE_PR)], primary, args, dry_run, batch=None)
    return rc, old.exists(), list(refreshed)


def main():
    rc_dry, kept_dry, ref_dry = run(True)
    rc_exec, kept_exec, ref_exec = run(False)
    print(f"dry-run:  land_prs rc={rc_dry} refreshed={ref_dry} old-folder-kept={kept_dry}")
    print(f"execute:  land_prs rc={rc_exec} refreshed={ref_exec} old-folder-kept={kept_exec}")
    if (rc_dry, rc_exec) != (EXPECTED_RC, EXPECTED_RC) or ref_dry != [9] or ref_exec != [9]:
        print(f"INVALID: landing loop did not complete as expected (want rc={EXPECTED_RC} and "
              "one refresh of the fixture PR in both arms); folder state not credited")
        return 3
    if not kept_dry:
        print("UNFIXED: a landing dry run pruned a retained scratch folder (GH-1626)")
        return 1
    if kept_exec:
        print("UNFIXED/INVALID: execute run no longer prunes; the positive control failed")
        return 2
    print("FIXED: dry run keeps retained scratch; execute still prunes")
    return 0


if __name__ == "__main__":
    try:
        code = main()
    finally:
        mc.shutil.rmtree(fixture, ignore_errors=True)
    sys.exit(code)
