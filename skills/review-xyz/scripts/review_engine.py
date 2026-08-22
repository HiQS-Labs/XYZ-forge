#!/usr/bin/env python3
"""Convenience runner for review_xyz within skills/review-xyz."""
import os
import sys

# Locate root repository and invoke utils/py/review_xyz.py
HERE = os.path.dirname(os.path.realpath(__file__))
SKILL_DIR = os.path.dirname(HERE)
XYZ_ROOT = os.path.dirname(os.path.dirname(SKILL_DIR))
REVIEW_PY = os.path.join(XYZ_ROOT, "utils", "py", "review_xyz.py")

if __name__ == "__main__":
    if not os.path.isfile(REVIEW_PY):
        print(f"review_engine: cannot locate review_xyz.py at {REVIEW_PY}", file=sys.stderr)
        sys.exit(2)
    os.execv(sys.executable, [sys.executable, REVIEW_PY] + sys.argv[1:])
