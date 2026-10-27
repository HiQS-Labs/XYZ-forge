#!/usr/bin/env bash
# GH-1234 manual smoke (GH-1088). Usage: bash smoke.sh <clone-root> [<marathon_drive.py> <jog_run.py>]
# Drives the lane-PR body builder open_lane_pr uses, renders it through marathon-closeout.sh
# --dry-run (prints the exact `gh pr create --body` it would run), and checks Jog's argv builder.
set -u
R="$1"; MD="${2:-$R/utils/py/marathon_drive.py}"; JR="${3:-$R/utils/py/jog_run.py}"
cd "$R"
python3 - "$R" "$MD" "$JR" <<'PY'
import importlib.util, subprocess, sys
root, md_path, jr_path = sys.argv[1:4]
sys.path.insert(0, f"{root}/utils/py")
def load(name, path):
    spec = importlib.util.spec_from_file_location(name, path); m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m); return m
md = load("md_under_test", md_path)
jr = load("jr_under_test", jr_path)
helper = getattr(md, "lane_pr_notes", None)
cases = [("main: Jog lane (flag), issue 416", "gh-416-doc-trues-up-batch", "416", True),
         ("adjacent: wave lane (no flag), issue 648", "gh-648-lane3", "648", False),
         ("adjacent: no derivable issue", "p1", None, True)]
for label, phase, issue, closes in cases:
    if helper is None:
        notes = f"Automated marathon closeout for phase `{phase}` (GH-561)."   # base: inline literal
    else:
        notes = helper(phase, issue, closes)
    out = subprocess.run(["bash", "relay-automation/marathon-closeout.sh", "--dry-run", "--open-only",
                          "--no-commit", "--head", f"marathon/{phase}", "--title", f"Marathon lane {phase}",
                          "--notes", notes], capture_output=True, text=True)
    line = next((l for l in (out.stdout + out.stderr).splitlines() if "gh pr create" in l), "(no gh pr create line)")
    tail = notes.splitlines()[-1]
    print(f"{label}\n  closeout rc={out.returncode}; body last line: {tail!r}\n  {line[:220]}")
inv = {"argv": ["/x/marathon-drive.sh", "--phase-id", "gh-416"], "target_root": "/t", "phase": "gh-416"}
for issue in ("416", None):
    argv = jr._marathon_argv_from_invocation(dict(inv, issue=issue), "agy", "codex")
    print(f"jog argv issue={issue!r}: --lane-closes-issue count = {argv.count('--lane-closes-issue')}")
argv2 = jr._marathon_argv_from_invocation(dict(inv, issue="416", argv=inv["argv"] + ["--lane-closes-issue"]), "agy", "codex")
print(f"jog argv already flagged: count = {argv2.count('--lane-closes-issue')}")
PY
