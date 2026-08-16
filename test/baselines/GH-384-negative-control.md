# GH-384 — recorded negative control (#419), by mutation

Test:     `test/gh384-crash-recovery.sh`
Revision: `a75cafd24eebcc5225c5f868dc6b1a339b6b24d3`
Date:     2026-08-11

`marathon-recover.sh` already shipped (Nightwatch wave 3, PR #501) — what was missing was the
fixture the issue's own litmus test demands, not the tool. So there is no pre-fix revision to
replay. The control is instead a pair of MUTATIONS of the behaviour the criterion names,
chosen to fail in OPPOSITE directions: a suite that catches only the first would still pass a
tool that shouts UNGATED at every phase, which the issue calls out explicitly.

## Baseline — unmutated

```
== test: gh384-crash-recovery ==
  workdir: <tmp>
-- read-only
  PASS: HEAD is unchanged (no commit was made)
  PASS: git status is byte-identical before and after
  PASS: no file was created or removed anywhere in the tree
-- detection: gated vs ungated
  PASS: the report contains a block for the gated phase
  PASS: the report contains a block for the ungated phase
  PASS: the two phases produce DIFFERENT output (the issue's core litmus test)
  PASS: the ungated phase is labelled with its ungated commit
  PASS: the label names the actual landed commit's task
  PASS: the finding is stated as UNVERIFIED, not merely reported
  PASS: the gated phase is NOT flagged (no false positive)
  PASS: the gated phase's approval event is recognised
-- inverse control: remove the approval event, the verdict must flip
  PASS: with the event removed, the same phase now reports its approval missing
-- driver lock state
  PASS: no lock present reports IDLE
  PASS: a lock held by a dead pid reports STALE
  PASS: a lock held by a live pid reports LIVE
-- documented recovery procedure
  PASS: README names the tool to run after an interruption
  PASS: README explains the ungated-commit finding
  PASS: README says what to DO about one (re-run the gate, or revert)
  PASS: README notes that a stale driver lock self-heals

  gh384-crash-recovery: 19 passed, 0 failed
```

## M1 — detection removed (`reachable_phase_commit` never finds a commit)

The "existence is not detection" substitution: the report still runs, still prints a block
per phase, still exits 0 — and finds nothing.

```
== test: gh384-crash-recovery ==
  workdir: <tmp>
-- read-only
  PASS: HEAD is unchanged (no commit was made)
  PASS: git status is byte-identical before and after
  PASS: no file was created or removed anywhere in the tree
-- detection: gated vs ungated
  PASS: the report contains a block for the gated phase
  PASS: the report contains a block for the ungated phase
  PASS: the two phases produce DIFFERENT output (the issue's core litmus test)
  FAIL: GH-384: the ungated phase was not labelled — its block was:
PHASE: ungated
STATUS: Open
RELAY: /var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/tick-gh384-crash-recovery.XXXXXX.2sDHLkhsPA/target/marathon-system/ungated/RELAY.md
TASK: MARATHON-UNGATED-TURN
APPROVAL: missing (no marathon.phase.approved event)
RECOVERY: no reachable phase commit found
  PASS: the label names the actual landed commit's task
  FAIL: GH-384: the ungated commit is not marked unverified — an operator could read it as fine
  PASS: the gated phase is NOT flagged (no false positive)
  PASS: the gated phase's approval event is recognised
-- inverse control: remove the approval event, the verdict must flip
  PASS: with the event removed, the same phase now reports its approval missing
-- driver lock state
  PASS: no lock present reports IDLE
  PASS: a lock held by a dead pid reports STALE
  PASS: a lock held by a live pid reports LIVE
-- documented recovery procedure
  PASS: README names the tool to run after an interruption
  PASS: README explains the ungated-commit finding
  PASS: README says what to DO about one (re-run the gate, or revert)
  PASS: README notes that a stale driver lock self-heals

  gh384-crash-recovery: 17 passed, 2 failed
```

## M2 — the verdict stops depending on the approval event (everything flagged)

The opposite failure: a tool that reports UNGATED for a phase that was properly gated. An
operator cannot act on a report that flags everything, and a whole-output `grep UNGATED`
would call this a pass.

```
== test: gh384-crash-recovery ==
  workdir: <tmp>
-- read-only
  PASS: HEAD is unchanged (no commit was made)
  PASS: git status is byte-identical before and after
  PASS: no file was created or removed anywhere in the tree
-- detection: gated vs ungated
  PASS: the report contains a block for the gated phase
  PASS: the report contains a block for the ungated phase
  PASS: the two phases produce DIFFERENT output (the issue's core litmus test)
  PASS: the ungated phase is labelled with its ungated commit
  PASS: the label names the actual landed commit's task
  PASS: the finding is stated as UNVERIFIED, not merely reported
  PASS: the gated phase is NOT flagged (no false positive)
  FAIL: GH-384: the approval event was not detected — block was:
PHASE: gated
STATUS: Approved
RELAY: /var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/tick-gh384-crash-recovery.XXXXXX.R2zuaekdUE/target/marathon-system/gated/RELAY.md
TASK: MARATHON-GATED-TURN
APPROVAL: missing (no marathon.phase.approved event)
RECOVERY: no reachable phase commit found
-- inverse control: remove the approval event, the verdict must flip
  PASS: with the event removed, the same phase now reports its approval missing
-- driver lock state
  PASS: no lock present reports IDLE
  PASS: a lock held by a dead pid reports STALE
  PASS: a lock held by a live pid reports LIVE
-- documented recovery procedure
  PASS: README names the tool to run after an interruption
  PASS: README explains the ungated-commit finding
  PASS: README says what to DO about one (re-run the gate, or revert)
  PASS: README notes that a stale driver lock self-heals

  gh384-crash-recovery: 18 passed, 1 failed
```

## Restored — the tool is back to its committed content

```
== test: gh384-crash-recovery ==
  workdir: <tmp>
-- read-only
  PASS: HEAD is unchanged (no commit was made)
  PASS: git status is byte-identical before and after
  PASS: no file was created or removed anywhere in the tree
-- detection: gated vs ungated
  PASS: the report contains a block for the gated phase
  PASS: the report contains a block for the ungated phase
  PASS: the two phases produce DIFFERENT output (the issue's core litmus test)
  PASS: the ungated phase is labelled with its ungated commit
  PASS: the label names the actual landed commit's task
  PASS: the finding is stated as UNVERIFIED, not merely reported
  PASS: the gated phase is NOT flagged (no false positive)
  PASS: the gated phase's approval event is recognised
-- inverse control: remove the approval event, the verdict must flip
  PASS: with the event removed, the same phase now reports its approval missing
-- driver lock state
  PASS: no lock present reports IDLE
  PASS: a lock held by a dead pid reports STALE
  PASS: a lock held by a live pid reports LIVE
-- documented recovery procedure
  PASS: README names the tool to run after an interruption
  PASS: README explains the ungated-commit finding
  PASS: README says what to DO about one (re-run the gate, or revert)
  PASS: README notes that a stale driver lock self-heals

  gh384-crash-recovery: 19 passed, 0 failed
```
