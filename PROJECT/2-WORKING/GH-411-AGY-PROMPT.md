---
title: Agy dispatch prompt for GH-411 — tick log foreign-cwd guard
status: Active (2-WORKING)
created: 2026-09-03
updated: 2026-09-03
owner: noelsaw1
gh_issue: 411
source: https://github.com/HiQS-Labs/XYZ-forge/issues/411
doc_type: project
roadmap_exempt: true
goal: >
  Carry the dispatch prompt for GH-411's single-lane marathon. Execution detail and acceptance
  live on the issue and in PROJECT/1-INBOX/GH-411-TICK-LOG-FOREIGN-CWD-GUARD.md; this file is the
  operator's copy-paste surface only, exempt from the ledger for the same reason a marathon plan is.
---

# Agy prompt — GH-411, in a fresh full clone

## Status

| What was just completed | What's next |
|---|---|
| Dispatch prompt written and verified against post-merge HEAD; GH-396's resolver landed on `development`, so #411 is unblocked | Hand the block below to agy; it clones `~/marathon-clones/marathon-gh-411-tick-log-guard`, fixes, proves red+green, opens a PR, then tears the clone down |

Copy the block below to agy. It is self-contained: clone, fix, prove, PR, tear down.

---

```
Work GitHub issue #411 in HiQS-Labs/XYZ-forge, end to end, in a fresh full clone.

SETUP — full clone, deterministically named (repo SOP marathon-triage §0c):
  CLONE="$HOME/marathon-clones/marathon-gh-411-tick-log-guard"
  git clone https://github.com/HiQS-Labs/XYZ-forge.git "$CLONE"
  cd "$CLONE" && git switch -c fix/gh411-tick-log-foreign-cwd-guard
Work ONLY inside $CLONE. Never touch the operator's primary checkout.
Read AGENTS.md, GUIDING-PRINCIPLES.md and ROUTER.md before editing.

THE DEFECT
bin/tick's MUTATING_GUARD_VERBS (:37) covers claim/take/scope/release/break/done/ping/reap.
assertResolvedRoot (:41) returns early for any verb outside that set. `log` is outside it, so
`tick log task.created` from a foreign cwd with TICK_REPO_ROOT unset exits 0 and creates
.tick/events/ in whatever directory resolved — and that call is how every run gets seeded.

Reproduce it first, from an empty scratch dir (no git, no .tick, TICK_REPO_ROOT unset):
  tick claim T1 --agent s --paths 'x/**'        -> refused rc 1   (guard works)
  tick log task.created T9 --agent s --paths 'x/**'  -> rc 0, creates ./.tick/events/*.jsonl
Do not proceed until you have seen both.

THE FIX
Move the guard decision from verb to verb + event-type prefix. Guard EVERY `tick log` type
EXCEPT `cost.*`. Do not guard only `task.*` — `marathon.*` is written through `tick log` too
(marathon-drive.sh :874 :927 :1155, marathon.sh :356) and a task-only rule leaves that hole open.

SCOPE — three hard limits:
  1. `cost.*` must still succeed unpinned. That is the property the exemption exists to protect
     (see the comment at bin/tick:35).
  2. Do NOT change the `drift` VERB (bin/tick:293-297). It is a separate verb with its own
     documented warn-only invariant citing decisions/2026-07-01-cross-agent-dep-conflict.md.
     It is not a log type and is out of scope.
  3. Do NOT edit any frozen Bash twin (GH-308) — relay-automation/marathon-drive.sh and
     marathon.sh are frozen. The whole fix belongs in bin/tick.

PROOF — required, per AGENTS.md §13. A green gate with no witnessed red is not evidence.
  New suite test/gh411-tick-log-foreign-cwd.sh, registered in validate.sh's TESTS array.
  REDS (must fail against pre-fix bin/tick):
    - `tick log task.created` from an unpinned foreign cwd is refused
    - `tick log marathon.complete` from an unpinned foreign cwd is refused
  GREENS (must pass both before and after):
    - `tick log cost.*` from an unpinned foreign cwd still succeeds
    - a pinned TICK_REPO_ROOT still writes to the intended root only
  Record the observed pre-fix run in test/baselines/GH-411-negative-control.md — the real
  transcript, not a sentence asserting a control happened.
  Then run: bash validate.sh   (must be green)

DELIVER
  git add -A && git commit   # conventional message, reference GH-411
  git push -u origin fix/gh411-tick-log-foreign-cwd-guard
  gh pr create --base development --title "fix(GH-411): guard tick log for every event type except cost.*" \
    --body "<what changed, the reds you witnessed with their output, the greens, validate.sh result. Closes #411.>"

TEAR DOWN — only after the PR URL exists:
  cd ~ && rm -rf "$HOME/marathon-clones/marathon-gh-411-tick-log-guard"
  Report the PR URL and confirm the clone is gone.

STOP AND REPORT instead of guessing if: the repro does not reproduce, validate.sh fails for a
reason unrelated to your change, or the fix would require touching a frozen twin.
```

---

## Why these guardrails

- **The clone name** follows marathon-triage §0c (`marathon-gh-<n>-<slug>`); #411 is this
  single-lane marathon's own tracking issue.
- **A full clone, not a worktree** — a linked worktree shares the parent's
  `.git/relay-driver.lock` (`driver-lock-lib.sh:20-35`) and `validate.sh:16-53` refuses to gate
  from one.
- **`drift` is the trap.** It reads like a sibling of `cost`/`log` in the same comment but is a
  distinct verb with an ADR behind its exemption. An agent optimizing "guard everything not
  cost" would break the warn-only invariant.
- **Reds before greens.** Four of the eight findings in the GH-406 arc exist because a check was
  written and never proven capable of failing.
