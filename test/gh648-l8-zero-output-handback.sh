#!/usr/bin/env bash
# GH-648 L8 / GH-397: a zero-output reviewer turn (header flips, token moves) is
# NOT review coverage — only an appended `### Round N · Reviewer` block is.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export REPO_ROOT="$ROOT"
export PYTHONPATH="$ROOT/utils/py:${PYTHONPATH:-}"

python3 -B - <<'PY'
import importlib.util
import os
import sys
import unittest

sys_path = os.path.join(os.environ['REPO_ROOT'], 'utils', 'py')
if sys_path not in sys.path:
    sys.path.insert(0, sys_path)
spec = importlib.util.spec_from_file_location(
    'relay_drive', os.path.join(sys_path, 'relay_drive.py'))
rd = importlib.util.module_from_spec(spec)
spec.loader.exec_module(rd)

BLOCK = "### Round 1 · Reviewer · agy\nswept file: yes\n**Verdict:** Approved\n"
HEADER_FLIP = "---\nNEXT: agy (Reviewer)\nSTATUS: Open\n---\nbody\n"


class ReviewBlocksAdded(unittest.TestCase):
    def test_appended_block_is_counted(self):
        self.assertEqual(rd.review_blocks_added("body\n", "body\n" + BLOCK), 1)

    def test_header_flip_without_block_counts_zero(self):
        self.assertEqual(
            rd.review_blocks_added(HEADER_FLIP, HEADER_FLIP + "\n(no findings)\n"), 0)

    def test_no_change_counts_zero(self):
        self.assertEqual(rd.review_blocks_added(BLOCK, BLOCK), 0)

    def test_empty_before_text_is_safe(self):
        self.assertEqual(rd.review_blocks_added("", BLOCK), 1)


if __name__ == "__main__":
    unittest.main()
PY
