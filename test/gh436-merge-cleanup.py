#!/usr/bin/env python3
"""test/gh436-merge-cleanup.py — Unit tests for /merge-cleanup skill.

Tests:
1. Deletable path containment & NEVER_DELETE boundary guards.
2. PR dependency parsing and topological sorting.
3. Git checkout inspection & disposition classification.
"""

import os
import sys
import tempfile
import subprocess
import shutil
import unittest
from pathlib import Path

# Add skill scripts to sys.path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "skills" / "merge-cleanup" / "scripts"))

from scan_clones import (
    _within,
    is_safe_deletable_path,
    inspect_checkout,
    inspect_driver_lock,
    DEFAULT_SAFE_ROOTS,
    DEFAULT_NEVER_DELETE
)
from toposort_prs import (
    parse_pr_dependencies,
    extract_touched_files,
    toposort_prs
)


class TestMergeCleanupSafety(unittest.TestCase):
    def test_within_logic(self):
        parent = Path("/a/b")
        child = Path("/a/b/c")
        self.assertTrue(_within(child, parent))
        self.assertFalse(_within(parent, parent))  # child == parent rejected
        self.assertFalse(_within(Path("/a/b_other"), parent))
        self.assertFalse(_within(Path("/a"), parent))

    def test_safe_deletable_path_boundaries(self):
        safe_root = Path("/tmp/test_safe_root")
        safe_root.mkdir(parents=True, exist_ok=True)
        never_delete = {Path("/tmp/test_safe_root"), Path.home(), Path("/")}

        child = safe_root / "repo_clone"
        child.mkdir(parents=True, exist_ok=True)

        # Child inside safe root
        ok, msg = is_safe_deletable_path(child, safe_roots=[safe_root], never_delete=never_delete)
        self.assertTrue(ok)

        # Safe root itself is rejected
        ok, msg = is_safe_deletable_path(safe_root, safe_roots=[safe_root], never_delete=never_delete)
        self.assertFalse(ok)
        self.assertIn("NEVER_DELETE", msg)

        # Protected system root
        ok, msg = is_safe_deletable_path(Path("/"), safe_roots=[safe_root], never_delete=never_delete)
        self.assertFalse(ok)

        # Path outside safe roots
        outside = Path("/tmp/outside_repo")
        outside.mkdir(parents=True, exist_ok=True)
        ok, msg = is_safe_deletable_path(outside, safe_roots=[safe_root], never_delete=never_delete)
        self.assertFalse(ok)
        self.assertIn("SAFE_ROOTS", msg)


class TestTopologicalSort(unittest.TestCase):
    def test_parse_dependencies(self):
        body1 = "This fix depends on #123 and is blocked by https://github.com/HiQS-Labs/XYZ-forge/pull/456."
        deps = parse_pr_dependencies(body1, "feat: implement X")
        self.assertEqual(deps, {123, 456})

        body2 = "No dependencies here."
        deps2 = parse_pr_dependencies(body2, "fix: bug Y")
        self.assertEqual(deps2, set())

    def test_toposort_linear_chain(self):
        prs = [
            {"number": 3, "title": "PR 3", "body": "Depends on #2", "createdAt": "2026-09-01T03:00:00Z"},
            {"number": 1, "title": "PR 1", "body": "Initial base", "createdAt": "2026-09-01T01:00:00Z"},
            {"number": 2, "title": "PR 2", "body": "Depends on #1", "createdAt": "2026-09-01T02:00:00Z"},
        ]
        ordered, _, _ = toposort_prs(prs)
        ordered_nums = [p["number"] for p in ordered]
        self.assertEqual(ordered_nums, [1, 2, 3])

    def test_toposort_file_collision_ordering(self):
        prs = [
            {"number": 20, "title": "PR 20", "body": "", "createdAt": "2026-09-01T02:00:00Z", "files": [{"path": "shared.py"}]},
            {"number": 10, "title": "PR 10", "body": "", "createdAt": "2026-09-01T01:00:00Z", "files": [{"path": "shared.py"}]},
        ]
        ordered, _, warnings = toposort_prs(prs)
        ordered_nums = [p["number"] for p in ordered]
        # PR 10 is older, so it should merge before PR 20
        self.assertEqual(ordered_nums, [10, 20])
        self.assertTrue(any("File collision" in w for w in warnings))


class TestCheckoutInspection(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.mkdtemp()
        self.repo_dir = Path(self.temp_dir) / "test_repo"
        self.repo_dir.mkdir()
        subprocess.run(["git", "init"], cwd=self.repo_dir, capture_output=True, check=True)
        subprocess.run(["git", "config", "user.name", "Test User"], cwd=self.repo_dir, check=True)
        subprocess.run(["git", "config", "user.email", "test@example.com"], cwd=self.repo_dir, check=True)

        # Initial commit
        (self.repo_dir / "README.md").write_text("Hello")
        subprocess.run(["git", "add", "README.md"], cwd=self.repo_dir, check=True)
        subprocess.run(["git", "commit", "-m", "initial commit"], cwd=self.repo_dir, check=True)

    def tearDown(self):
        shutil.rmtree(self.temp_dir, ignore_errors=True)

    def test_clean_repo_inspection(self):
        info = inspect_checkout(self.repo_dir)
        self.assertTrue(info["is_git"])
        self.assertEqual(info["checkout_type"], "standalone_clone")
        self.assertTrue(info["is_clean"])
        self.assertEqual(info["stash_count"], 0)

    def test_dirty_repo_disposition(self):
        (self.repo_dir / "dirty.txt").write_text("uncommitted")
        info = inspect_checkout(self.repo_dir)
        self.assertFalse(info["is_clean"])
        self.assertEqual(info["disposition"], "PRESERVE_DIRTY")

    def test_driver_lock_inspection(self):
        lock_file = self.repo_dir / ".git" / "relay-driver.lock"
        lock_file.write_text(f"pid={os.getpid()}\nholder=test\n")
        lock_info = inspect_driver_lock(self.repo_dir)
        self.assertTrue(lock_info["locked"])
        self.assertTrue(lock_info["alive"])
        self.assertEqual(lock_info["pid"], os.getpid())


if __name__ == "__main__":
    unittest.main()
