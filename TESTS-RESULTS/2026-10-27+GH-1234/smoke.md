# GH-1234 manual smoke (GH-1088)

- Date: 2026-10-27, operator Mac.
- Disposable full clone: `XYZ-forge-gh1234-closeout-closes-keyword-2026-10-27-verify`, at task branch `9bb3cb49`; `git status --porcelain` was empty after the runs.
- Script: [smoke.sh](smoke.sh).
  - It builds the lane PR body with `marathon_drive.lane_pr_notes`, the helper `open_lane_pr` calls.
  - It renders the body through `relay-automation/marathon-closeout.sh --dry-run --open-only --no-commit`, which prints the exact `gh pr create --body` it would run.
  - It calls Jog's `_marathon_argv_from_invocation` directly.
- Red control: the same script run against `marathon_drive.py` and `jog_run.py` from base `5cab70c8`, which have the inline literal and no flag.
- No suite was added (GH-831).

## Fix (9bb3cb49)

```
main: Jog lane (flag), issue 416
  closeout rc=0; body last line: 'Closes #416'
  DRY-RUN: PR_URL=$(gh pr create --base development --head marathon/gh-416-doc-trues-up-batch --title Marathon\ lane\ gh-416-doc-trues-up-batch --body $'Automated marathon closeout for phase `gh-416-doc-trues-up-batch` (GH
adjacent: wave lane (no flag), issue 648
  closeout rc=0; body last line: 'Refs #648'
  DRY-RUN: PR_URL=$(gh pr create --base development --head marathon/gh-648-lane3 --title Marathon\ lane\ gh-648-lane3 --body $'Automated marathon closeout for phase `gh-648-lane3` (GH-561).\n\nRefs #648' )
adjacent: no derivable issue
  closeout rc=0; body last line: 'Automated marathon closeout for phase `p1` (GH-561).'
  DRY-RUN: PR_URL=$(gh pr create --base development --head marathon/p1 --title Marathon\ lane\ p1 --body Automated\ marathon\ closeout\ for\ phase\ \`p1\`\ \(GH-561\). )
jog argv issue='416': --lane-closes-issue count = 1
jog argv issue=None: --lane-closes-issue count = 0
jog argv already flagged: count = 1
```

## Base 5cab70c8 (red control)

```
main: Jog lane (flag), issue 416
  closeout rc=0; body last line: 'Automated marathon closeout for phase `gh-416-doc-trues-up-batch` (GH-561).'
  DRY-RUN: PR_URL=$(gh pr create --base development --head marathon/gh-416-doc-trues-up-batch --title Marathon\ lane\ gh-416-doc-trues-up-batch --body Automated\ marathon\ closeout\ for\ phase\ \`gh-416-doc-trues-up-batch\
adjacent: wave lane (no flag), issue 648
  closeout rc=0; body last line: 'Automated marathon closeout for phase `gh-648-lane3` (GH-561).'
  DRY-RUN: PR_URL=$(gh pr create --base development --head marathon/gh-648-lane3 --title Marathon\ lane\ gh-648-lane3 --body Automated\ marathon\ closeout\ for\ phase\ \`gh-648-lane3\`\ \(GH-561\). )
adjacent: no derivable issue
  closeout rc=0; body last line: 'Automated marathon closeout for phase `p1` (GH-561).'
  DRY-RUN: PR_URL=$(gh pr create --base development --head marathon/p1 --title Marathon\ lane\ p1 --body Automated\ marathon\ closeout\ for\ phase\ \`p1\`\ \(GH-561\). )
jog argv issue='416': --lane-closes-issue count = 0
jog argv issue=None: --lane-closes-issue count = 0
jog argv already flagged: count = 1
```

## Verdict

PASS.
- **Main path:** a Jog-flagged lane renders `--body` ending `Closes #416`; at base it has no keyword.
- **Adjacent paths:**
  - an unflagged wave lane renders `Refs #648` and closes nothing;
  - with no derivable issue the body is byte-identical to base;
  - Jog adds `--lane-closes-issue` exactly once for `issue='416'`, never for `issue=None`, and does not duplicate it.
