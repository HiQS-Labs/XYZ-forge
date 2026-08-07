---
gh_issue: 432
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/432
title: "GH-432 — a failed builder turn skips rtl_enforce entirely, so its work is never committed and its token is never handed off"
status: "Active (2-WORKING) — captured 2026-08-06, implementing directly (not a marathon lane)."
created: 2026-08-06
updated: 2026-08-06
owner: noel
doc_type: project
release: "0.3.0 Nightwatch"
complexity: 2
risk: 2
effort: 2
phases: 2
ratings_provisional: true
related:
  - "#409 — a failed builder turn leaks its tick claim. Same root cause, observed from the token side."
  - "#408 — _run_tick_loud discards stderr then exits on it. Adjacent failure surface, NOT fixed here."
  - "#390 / PR #393 — exit-7 timeout attribution and persistent claude-turn transcripts. Merged 2026-08-07. Improves diagnosis of a failed turn; does NOT change whether enforce runs."
  - "#67 — the authoritative token handoff this defect skips (rtl_enforce step 4)."
non_goals:
  - "Making a crashed builder's work correct. The turn failed; persisting its partial output is about not losing evidence, not about trusting it."
  - "Changing the exit-code contract. A failed turn still exits 5; only the side effects before that exit change."
  - "Fixing #408 or #409 in this branch, though #409 is largely subsumed. Separate issues, separate acceptance."
  - "Touching the frozen Bash twins (GH-308). The fix lands in utils/py/*-turn.py."
goal: >
  A builder turn whose agent subprocess exits non-zero calls sys.exit(5) BEFORE rtl.enforce(), so it
  skips the file-scoped commit, the allowlist containment check, the transcript archive, and the
  authoritative token handoff in one step. The timeout path (exit 7) two lines above does the exact
  opposite — it falls through to enforce and only then exits. The result is the reported stall: the
  relay-file edit stays uncommitted, the tick token stays claimed by the dead agent, and the relay
  has no path to a terminal state without manual `tick done` + hand-editing STATUS.
---

# GH-432 · a failed turn takes the one exit that skips persistence

## Status

Active. Root cause identified and reproduced by reading the two adjacent branches; fix is a
control-flow correction in five files, plus a regression test that asserts the side effects rather
than the exit code.

## The defect

All five Python turn shims share this shape (line numbers from `utils/py/claude-turn.py` at
`9cb779e`):

```python
if bounded_rc == 7:
    print(f"... exceeded {turn_timeout}s wall-clock cap — killed", file=sys.stderr)
elif bounded_rc != 0:
    print(f"... failed (exit {bounded_rc})", file=sys.stderr)
    sys.exit(5)                      # <-- returns here, never reaching enforce

rc = rtl.enforce(t, me, claude_log, "claude")   # commit + containment + archive + handoff
if bounded_rc == 7:
    sys.exit(7)
```

The timeout branch deliberately falls through to `enforce`. The generic-failure branch does not.
Nothing in the code or its comments explains the asymmetry, and every consequence of it is a
regression from the timeout path's behavior:

| `rtl_enforce` step | timeout (exit 7) | agent failure (exit 5) |
|---|---|---|
| (1) allowlist containment on tracked changes | runs | **skipped** |
| (3) file-scoped commit of the turn's work | runs | **skipped** |
| (3b) transcript commit to the archive repo | runs | **skipped** |
| (4) authoritative token handoff (GH-67) | runs | **skipped** |
| (5) dependency-drift signal | runs | **skipped** |

Worktree isolation makes the loss precise rather than partial: `rtl.worktree_end(wt)` has already
run by this point, so the agent's allowlisted edits have ALREADY been copied back into the real
tree. They are sitting there, correct and uncommitted, when `sys.exit(5)` discards the only code
path that would have committed them. The reporter confirms this from the other end — Round 3's
proposed patch "was substantively correct and closely matched the fix I ended up applying by hand."

Affected files, all with the identical `sys.exit(5)`-before-`enforce` shape:

- `utils/py/claude-turn.py:143`
- `utils/py/codex-turn.py:116`
- `utils/py/agy-turn.py:253`
- `utils/py/pi-turn.py:146`
- `utils/py/aider-turn.py:196`

## Why it matters

A crashed turn is the case where persistence matters MOST, and it is the only case where the
harness throws the work away. The failure is also silent in the way that costs the most time: the
relay file on disk looks like the turn happened (the agent's edit is there), `git status` shows it
dirty, and `tick info` shows the token still claimed by an agent that no longer exists. Nothing
says "this turn failed" except a line on stdout that scrolls past in an unattended run.

This is #409 observed from the builder side rather than the token side.

## Acceptance

The issue does not carry an acceptance-criteria block — it is a field report ending in a "Suggested
fix direction" section. Criteria below are derived from that section and from the observed
behavior, per the GH-400 contract for a capture doc whose issue has no acceptance block.

1. A builder turn whose agent exits non-zero (not a timeout) still runs `rtl_enforce`: its
   allowlisted changes are committed file-scoped, and the tick token is released to `RELAY_PEER`
   or closed, exactly as the timeout path already does.
2. The turn still exits 5. No caller sees a changed exit code for a failed turn.
3. Containment is not weakened: a failed turn that ALSO made off-lane edits still has them
   reverted and still fails — the failure path gains `enforce`'s guarantees, it does not bypass them.
4. A failed turn is distinguishable from a successful one in the relay record, not only on stdout.
5. All five turn shims behave identically on this path. Fixing only `claude-turn` would leave the
   same report reachable through four other builders.
6. The regression test asserts the SIDE EFFECTS (commit exists, token handed off) rather than the
   exit code, because the exit code was already correct while the defect was live.

## Acceptance — deviations from the issue

- **Derived, not copied.** The issue has no acceptance block; criteria 1-4 restate its "Suggested
  fix direction" and "Impact" sections, criteria 5-6 are mine and are recorded as additions.
- **Criterion 5 widens the write-set beyond the reported file.** The report names
  `claude-turn.sh`; the defect is in all five Python shims. Narrowing to the reported file would
  leave the issue reproducible via codex, agy, pi, and aider.
- **The issue's second suggestion is partly declined.** It asks to "double-check whether the
  `RELAY_PEER`-not-set path has any interaction with turn completion/crash handling." Checked: it
  does not. `RELAY_PEER` unset only reaches the `warn-stuck` branch of the handoff at
  `relay-turn-lib.sh:1174`, which is a WARN and cannot fail or crash a turn. It is a real usability
  gap — with no peer set there is no auto-handoff even on the success path — but it is a separate
  concern from this crash and is NOT fixed here.

## Phases

- **Phase 1** — route the generic-failure branch through `rtl_enforce` in all five shims, preserving
  exit 5. Regression test asserting commit + handoff on a failed turn.
- **Phase 2** — make the failure legible in the relay record (criterion 4), so an unattended run
  leaves evidence a later pass can read.

## Litmus tests

Per GH-419: each check below must be observed FAILING against the pre-fix tree before it is trusted.

1. Failed builder turn → the allowlisted edit is committed. Negative control: revert the fix, the
   same test must report the tree dirty and no commit.
2. Failed builder turn → the token is released to the peer. Negative control: pre-fix, `tick info`
   must still show it claimed by the failed agent.
3. Off-lane edit during a FAILED turn → still reverted, still exits 6-or-5 (containment intact).
4. Successful turn → byte-identical behavior to pre-fix. This one is the guard against the fix
   changing the happy path.

## Provenance

Field report from a vendored `.xyz/` install into a private repo, harness commit `791db7d`.
No public repro link; the reporter offered the relay thread on request. Root cause did not need it —
the two adjacent branches in the shim are sufficient.
