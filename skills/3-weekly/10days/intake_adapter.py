#!/usr/bin/env python3
"""Locate the harness-owned intake implementation for copied or linked 10days."""
import importlib.util
import os
from pathlib import Path
import subprocess
import sys


def main():
    here = Path(__file__).resolve().parent
    candidates = []
    override = os.environ.get("XYZ_HARNESS") or os.environ.get("XYZ_REPO_ROOT")
    if override:
        candidates.append(Path(override) / "skills/1-hourly/relay-xyz/find-harness.sh")
    candidates.append(here.parent.parent / "1-hourly/relay-xyz/find-harness.sh")
    result = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True)
    if result.returncode == 0:
        root = Path(result.stdout.strip())
        candidates.extend([root / ".xyz/skills/1-hourly/relay-xyz/find-harness.sh",
                           root / "skills/1-hourly/relay-xyz/find-harness.sh"])
    for directory in (".codex/skills", ".agents/skills", ".claude/skills", ".gemini/config/skills",
                      ".gemini/antigravity/skills", ".gemini/antigravity-cli/skills", ".zcode/skills"):
        candidates.append(Path.home() / directory / "relay-xyz/find-harness.sh")
    locator = next((path for path in candidates if path.is_file()), None)
    if locator is None:
        print("10days: harness locator not found; set XYZ_HARNESS to a current harness", file=sys.stderr)
        return 2
    result = subprocess.run(["bash", str(locator), "--root", "--quiet"], capture_output=True, text=True)
    if result.returncode:
        print(result.stderr.strip(), file=sys.stderr)
        return 2
    module = Path(result.stdout.strip()) / "skills/3-weekly/weekly-planner/scripts/issue_intake.py"
    if not module.is_file():
        print("10days: selected harness lacks skills/3-weekly/weekly-planner/scripts/issue_intake.py; update the harness before using this adapter", file=sys.stderr)
        return 2
    spec = importlib.util.spec_from_file_location("issue_intake", module)
    intake = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(intake)
    if sys.argv[1] == "scan":
        return intake.legacy_scan(sys.argv[2:], Path.cwd())
    return intake.legacy_find(sys.argv[2:], Path.cwd())


if __name__ == "__main__":
    sys.exit(main())
