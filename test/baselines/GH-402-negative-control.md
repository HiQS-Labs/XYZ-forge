# GH-402 — recorded negative control (#419)

Test:     `test/gh402-branch-enforcement.sh` (TEST_SOFT_FAIL=1)
Baseline: `c92dca37bf2368c152a2ab73cd2620ba69df0704` — `utils/py/marathon_drive.py` without the branch guard
Date:     2026-08-11

The pre-fix run is the defect stated as an observation: the marathon runs happily on trunk,
dispatches its turn, and **commits to the shared default branch** — which is the harm, because
a marathon's turns commit continuously, so stopping the run does not un-land them.

The cases that must stay GREEN in both directions are the interesting half: a feature-branch
run, an overridden run, the carve-out, and a repo with no origin all proceed pre-fix and
post-fix. A guard that blocked those would be worse than the defect.

## PRE-FIX — the control is OBSERVED failing

```
== test: gh402-branch-enforcement ==
  workdir: <tmp>
-- case 1: checked out on the shared trunk
  PASS: a run on trunk is refused (exit 4)
  FAIL: GH-402: a turn was dispatched before the refusal
  FAIL: GH-402: the run committed to trunk before refusing — e7820a2 marathon: phase lane1 transcript saved (MARATHON-LANE1-TURN)
3692ade marathon: phase lane1 escalation (cap-or-close-mismatch)
26268bb relay(MARATHON-LANE1-TURN): codex transcript (codex headless; archive; no push)
  FAIL: GH-402: the refusal does not name the branch — got: marathon-drive: relay file committed: <tmp>
marathon-drive: tick token seeded: MARATHON-LANE1-TURN → claude
marathon-drive: phase start: running relay-drive --round-cap 3
claude-turn: worktree isolation ON (<tmp>)
claude-turn: WARNING: workspace '<tmp>' is not trusted; Claude may ignore project permissions. Run Claude Code interactively in this directory and accept the trust dialog, or set projects['<tmp>']["hasTrustDialogAccepted"] to true in ~/.claude.json.
claude-turn: claude turn produced no tracked changes (token-only move?)
claude-turn: handed off token MARATHON-LANE1-TURN → codex (tick release --to)
codex-turn: worktree isolation ON (<tmp>)
codex-turn: codex turn produced no tracked changes (token-only move?)
codex-turn: committed transcript to archive /private<tmp> (marathon-system/lane1/RELAY.md; no push)
claude-turn: worktree isolation ON (<tmp>)
claude-turn: WARNING: workspace '<tmp>' is not trusted; Claude may ignore project permissions. Run Claude Code interactively in this directory and accept the trust dialog, or set projects['<tmp>']["hasTrustDialogAccepted"] to true in ~/.claude.json.
claude-turn: claude turn produced no tracked changes (token-only move?)
claude-turn: handed off token MARATHON-LANE1-TURN → codex (tick release --to)
relay-drive: round cap (3) exceeded (STATUS: Open, token actor: codex) — escalating
marathon-drive: relay escalated: cap/close-mismatch (relay-drive exit 4)
~/Documents/GH Repos/xyz-3-agents-swarm/utils/py/marathon_drive.py:1383: DeprecationWarning: datetime.datetime.utcnow() is deprecated and scheduled for removal in a future version. Use timezone-aware objects to represent datetimes in UTC: datetime.datetime.now(datetime.UTC).
  now = datetime.datetime.utcnow()
marathon-drive: transcript saved: <tmp>
marathon-drive: escalation written: <tmp> (reason: cap-or-close-mismatch)

marathon-drive: end-of-run cost summary (tick analyze) —
--- cost ---
run type: unspecified
tokens: 0 total (0 in / 0 out)
human minutes (self-reported): 0
wall-clock (run window): 32s
per done-task: n/a (0 tasks done)
  FAIL: GH-402: the refusal offers no remedy
  FAIL: GH-402: the refusal does not mention the override flag
-- case 2: the packet's suggested branch appears in the remedy
  FAIL: GH-402: SP_SUGGESTED_BRANCH was ignored — the operator has to invent a name
-- case 3: on a feature branch, the run proceeds
  PASS: a run on a feature branch still dispatches (2 turn(s))
  PASS: a feature-branch run is not reported as blocked
-- case 4: the override flag and the preflight carve-out
  FAIL: GH-402: --allow-trunk-commit did not work — rc=2, output: marathon-drive: unknown argument: --allow-trunk-commit
  PASS: the risk=1/independent-zone carve-out permits a trunk run without the flag
  FAIL: GH-402: --force bypassed the branch guard — a lane retry now grants permission to land on trunk
-- case 5: a repo with no shared trunk is not blocked
  PASS: a repo with no origin is not blocked (nothing is shared; git reset undoes everything)

  gh402-branch-enforcement: 5 passed, 8 failed
```

## POST-FIX — refused on a shared trunk, unchanged everywhere else

```
== test: gh402-branch-enforcement ==
  workdir: <tmp>
-- case 1: checked out on the shared trunk
  PASS: a run on trunk is refused (exit 2)
  PASS: no builder turn was dispatched
  PASS: the receiving repo has no new commits (HEAD is still the seed)
  PASS: the refusal names the branch it is protecting
  PASS: the refusal gives the exact command to cut a branch
  PASS: the refusal names the override
-- case 2: the packet's suggested branch appears in the remedy
  PASS: the refusal uses preflight's own suggested branch name
-- case 3: on a feature branch, the run proceeds
  PASS: a run on a feature branch still dispatches (2 turn(s))
  PASS: a feature-branch run is not reported as blocked
-- case 4: the override flag and the preflight carve-out
  PASS: --allow-trunk-commit permits a trunk run
  PASS: the risk=1/independent-zone carve-out permits a trunk run without the flag
  PASS: --force does NOT bypass the branch guard (it bounds attempts, not branches)
-- case 5: a repo with no shared trunk is not blocked
  PASS: a repo with no origin is not blocked (nothing is shared; git reset undoes everything)

  gh402-branch-enforcement: 13 passed, 0 failed
```
