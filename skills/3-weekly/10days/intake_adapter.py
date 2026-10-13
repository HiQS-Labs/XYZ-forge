#!/usr/bin/env python3
"""Locate the harness-owned intake implementation for copied or linked 10days."""
import importlib.util
import os
from pathlib import Path
import subprocess
import sys


def main():
    if len(sys.argv) < 2 or sys.argv[1] not in ("scan", "find"):
        print("usage: intake_adapter.py {scan|find} [arguments...]", file=sys.stderr)
        return 2
    override = os.environ.get("XYZ_HARNESS") or os.environ.get("XYZ_REPO_ROOT")
    if override and not (Path(override) / "relay-automation/relay-drive.sh").is_file():
        print("10days: explicit harness is unavailable or incomplete", file=sys.stderr)
        return 2
    here = Path(__file__).resolve().parent
    bundled = here.parents[2]
    module = bundled / "skills/3-weekly/weekly-planner/scripts/issue_intake.py"
    # A complete source/vendor bundle is one reviewed runtime. Separately copied
    # skills still resolve the shared harness; they do not import sibling skills.
    if not all(path.is_file() for path in (module, bundled / "utils/py/releases_app.py",
                                           bundled / "utils/hq/hq-lib.sh",
                                           bundled / "relay-automation/relay-drive.sh")):
        candidates = []
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
    exec(compile(module.read_bytes(), str(module), "exec"), intake.__dict__)
    if sys.argv[1] == "scan":
        return intake.legacy_scan(sys.argv[2:], Path.cwd())
    return intake.legacy_find(sys.argv[2:], Path.cwd())


if __name__ == "__main__":
    sys.exit(main())
