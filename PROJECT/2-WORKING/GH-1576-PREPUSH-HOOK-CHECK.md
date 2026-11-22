---
gh_issue: 1576
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1576
title: "start-task: refuse to push from a clone with no pre-push hook installed, so no push skips the gate"
status: Working — plan drafted; awaiting Codex plan QA
created: 2026-11-21
updated: 2026-11-21
owner: Claude (start-task sub-agent)
goal: "No start-task-family push leaves a clone whose pre-push stub is not installed; the check is `githooks/install.sh --check`, run immediately before the push."
branch: fix/XYZ-forge-gh1576-prepush-hook-check-2026-11-21
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
phases: 1
---

## Status

| What was just completed | What's next |
|---|---|
| Intake registered (row rated 62/58/50/72), recon of every push step done, plan drafted. | Codex plan QA, then build, red/green manual check, final QA, PR. |

## Problem

`githooks/pre-push` is the push gate, but hooks live in `.git/hooks/` and do not travel with a clone.
A fresh clone that never ran `bash githooks/install.sh` pushes with no gate and nothing fails.
`start-task/SKILL.md:290` and `AGENTS.md:194-196` state that `--check` must pass; nothing enforces it.
Evidence (issue #1576): kickstart run-2 clones `t1530` and `landing` pushed unwired during the PR #1574
refresh. Same class as GH-4 (warn-only in `validate.sh`) and GH-549 (stub design): the detector
(`install.sh --check`, exit 1 when unwired) exists; no push step consumes it as a refusal.

## Recon (base `3dc703600`, 2026-11-21)

Existing authority: `githooks/install.sh` (install, `--check` exit 0/1, stderr says the clone pushes
ungated). Existing consumers: `validate.sh:825` (warn only), `utils/py/express.py:551 gate_check` and
its refusal `gate-unwired` at `:704` (preflight) and `:1109` (after the suite, right before the landing
push at `:1143`). `utils/py/xyz_init_clone.py:108` already installs hooks, but only for the vendored
Tier-2 harness clones; it is not the start-task lane.

Every push step in the lane family (`git push` call sites; none calls `--check` today except express):

| Lane | Site | Pushes from | Hook today |
|---|---|---|---|
| start-task | `SKILL.md` Step 3 (provision) and Steps 7/9 (push) | task clone | prose only; line 290 states `--check` |
| kickstart | `skills/1-hourly/kickstart/scripts/run_record.py:590` (`checkpoint --push`) | child clone | unchecked |
| jog | `utils/py/jog_run.py:1209` (`publish_jog_receipt`), `:2320` (`_push`, publication clone) | execution clone / publication clone | unchecked |
| merge-cleanup | `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:1048` (`push_resolved_head`, throwaway landing clone made at `:964 prepare_landing_clone`, never wired), `:1534` (post-merge writes, `--primary` landing clone) | landing clone / primary | unchecked |
| express | `utils/py/express.py:1143` landing push (bypasses the hook by lane design, `XYZ_SKIP_PREPUSH=1`), `:1284` closeout push | task clone | `:1143` covered by `:1109`; `:1284` unchecked |
| others | `hosted_lane_publish.py`, `xyz_mini_sync.py`, `wave_reconcile`, `marathon-closeout.sh`, `fuzz-*.sh`, `pop-and-run-agy.sh`, `ci-doctor/benchmark-runners.sh` | not start-task lanes | out of scope (see non-goals) |

Untraced / uncertain: whether existing fixtures for jog/merge-cleanup/kickstart push from clones that
copy this repo (installer present, stub absent). Those suites will be run in step 4 and any red is a
finding, not a reason to add a bypass.

## Plan (the smallest change that enforces the rule)

Authority stays `bash githooks/install.sh --check`. No new script, no new subsystem, no new suite.

1. **start-task `SKILL.md`**: Step 3 provisioning says to run `bash githooks/install.sh` then
   `--check` in the new clone before any work; Steps 7/9 push text says to run `--check` immediately
   before every push (first and later), to stop without pushing on nonzero, and never to use
   `--no-verify` or `XYZ_SKIP_PREPUSH`. The line-290 sentence is rewritten to refer to this rule.
   Kickstart children, jog and merge-cleanup repair clones reuse this step; add a one-line pointer to
   `kickstart/SKILL.md` and `express/SKILL.md` (express already refuses; its text records `:1284`).
2. **Python push sites** each run the clone's own `bash githooks/install.sh --check` immediately before
   the push and refuse (raise the file's existing error type; no push) on nonzero:
   `run_record.py:590`, `jog_run.py:1209`, `jog_run.py:2320` (pub clone), `merge_cleanup.py:1048` and
   `:1534`, and `express.py:1284` (reuse its `gate_check`). `jog_run.py` imports `gate_check`'s
   logic only if `express` imports cleanly; otherwise it carries the same 5-line call (no shared
   module is created for it).
   Rule when `githooks/install.sh` is absent from the clone (vendored host with no Forge installer):
   the check is not applicable, so the push proceeds with one stderr line saying so (express keeps
   its own vendored rule).
3. **merge-cleanup provisioning**: `prepare_landing_clone` runs `bash githooks/install.sh` after the
   clone (it creates this clone, so it owns wiring it); without it every repair push would now refuse.
   The repair push then runs the stub's gate, so `:1048` uses `PUSH_GATE_TIMEOUT_S` like `:1534`
   (today `NET_TIMEOUT_S` 180 s would kill a gate run). The `--primary` clone is never installed into
   by the tool; unwired means refuse.
4. **Verification** (existing suites only, GH-831): run the suites that touch the changed files
   (`gh436-merge-cleanup`, `gh280-jog-marathon-adapter`, the express suite `gh267`, `gh544`,
   `gh4`) plus the route's full gate.
5. **Manual red/green** under `TESTS-RESULTS/2026-11-21+GH-1576/` with `provenance.jsonl`, in a
   disposable full clone with a local bare origin:
   - Red (unchanged code, base `3dc703600`): unwired clone pushes via kickstart `checkpoint --push`
     and via a plain `git push`; no gate receipt appears; push succeeds.
   - Green (changed code), main path: same sequence refuses before the push (remote unchanged), `rc`
     nonzero, message names `bash githooks/install.sh`.
   - Green, adjacent path: after `bash githooks/install.sh` the same push runs the stub (the hook's
     output appears; with `XYZ_SKIP_PREPUSH`-free env the gate runs or classifies docs). Also a
     rerun of an already-pushed head (up-to-date) is unaffected, and the empty/absent-installer case
     proceeds with the stderr note.

## Preflight bet check

- *Outcome sought:* no push by this lane family can reach the remote from an unwired clone.
- *Smallest viable bet:* one `--check` call at each existing push site plus provisioning text; reuse the
  existing detector and refusal pattern.
- *Not built:* a shared guard module, a wrapper `git push`, a server-side check, a new test, any
  `--no-verify` fallback, enforcement for `git push` typed by a human or for non-lane scripts.
- *Alternatives rejected:* (a) a global `core.hooksPath` or git template dir: machine-wide state outside
  the repo, breaks other repos, contradicts GH-549 reasoning; (b) a shared Python module imported by all
  lanes: skills are vendored and installed apart from `utils/py`, so an import would add a coupling the
  call site does not need; the check is 5 lines against the existing authority.
- *Rollback:* revert the PR; behaviour returns to unchecked pushes. Each site is independent.

## Non-goals

No change to `githooks/install.sh` or `githooks/pre-push`; no change to what the hook gates; no new tests,
suites or registry entries; no enforcement against `git push --no-verify` typed by hand (not fixable
client-side, per `install.sh`'s own header); non-lane scripts listed above are not touched.

## Risks

- A fixture that pushes from an unwired copy turns red: fix the fixture's wiring or record it; never add
  a skip flag.
- merge-cleanup repair pushes now run the gate: longer, bounded by `PUSH_GATE_TIMEOUT_S`; a red gate
  there refuses the repair push (the intended fail-closed outcome).
- This touches gate/hook surfaces: no finding is deferred; no landing by the sub-agent.

## Task rating (2026-11-21)

`rated 62/58/50/72` (pri/sev/appeal/effort). Severity 58: an ungated push is silent and recurring in
class (GH-4, GH-549, run 2 of kickstart) but hosted CI still covers pushes to `development`/`main`, so
no data loss. Priority 62: it let a whole run's pushes skip the gate. Appeal 50: neutral, no operator
value given. Effort 72: about six small call sites plus prose. Recurrence: 1 observed incident in the
last 14 days (run 2, #1541/#1574), 0 found in the prior 14 (history search limited to issue titles);
trend unknown beyond that.
