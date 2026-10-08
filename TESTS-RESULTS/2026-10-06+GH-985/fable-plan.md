---
gh_issue: 985
source: https://github.com/HiQS-Labs/XYZ-forge/issues/985
title: Claude workhorse continuation optimization
status: active
created: 2026-10-06
updated: 2026-10-06
owner: Codex
goal: Align the Claude Stop-hook guidance with the shared verified-outcome contract
---

# Claude workhorse continuation optimization

## Status

| What was just completed | What's next |
|---|---|
| Fable low-effort plan written from direct source reads on the PR #984 stack | Independent plan QA (Fable reviewer); on Approved, exact-row accepted-start, then Agy builds |

## Dependency

Stacked on PR #984 (`fix/...` for GH-983), stack base `3c9bfa8ca452bfddd8ec19d4ac243e02372531bb`; development
integration base `8ec99b6066c997a00c40761c9efb9f9caaff8b8f` (re-verify before publication). The stacked PR must
declare PR #984 as its base and show only this incremental diff. No merge or deployment authorization is granted here.

## Observed input (direct reads, graph not_tracked for workhorse paths, generation 2026-09-01)

- `skills/2-daily/workhorse/stop-hook.sh:7` says: "Loop safety is the harness's 8-consecutive-continuation cap plus the
  `[!]`/`[-]` escape in the checklist." Neither the cap nor the escape is substantiated by anything in this repo
  (repo grep for the cap finds only this line). Official hooks docs document `stop_hook_active` and loop care; no
  numeric cap was verified. The claim is unverified, not disproven.
- `skills/2-daily/workhorse/stop-hook.sh:45-48` emits the block reason: "Continue with the next open item. To hand back
  to the operator instead, mark it [!] (with the exact blocker) or [-] (parked, with its pointer)." This presents
  `[-]` as a parking escape.
- `skills/2-daily/workhorse/SKILL.md:90` says "Parking must not silently reduce authorized scope"; `:105-107` says only
  explicit user deferral removes required work; `:113-117` says stop only for verified completion, explicit user
  pause/cancellation, or a concrete external blocker; `:322` says "`[-]` is not an escape from required scope."
  The hook reason contradicts these four lines.
- `skills/2-daily/workhorse/SKILL.md:17-26` registers the Stop hook via frontmatter. That is syntax-level wiring; it
  proves the hook runs, not that outcomes are evaluated. `SKILL.md:86-88` already discloses this.
- `skills/2-daily/workhorse/SKILL.md:123-124` names the Claude runtime enforcement note but does not describe what
  the hook reason says or that the hook is Claude-only syntax enforcement in one place.
- Decision predicate (`stop-hook.sh:40-43`): block iff the session checklist has a `- [ ]` line. Fail-open paths
  (`stop-hook.sh:9,12,16-22,41-42,49-51`): no python3, bad JSON, bad session id, no checklist, other session. All
  preserved.
- `TESTS-RESULTS/2026-10-06+GH-983/claude-compatibility.json` already records the bounded hook protocol probe
  (unchecked item blocks, checked item allows) for the current bytes.

## Bet (smallest viable)

Change the hook's guidance text, not its behavior. Rewrite the block reason at `stop-hook.sh:45-48` so it states the
shared contract: continue the next open item; stop only for verified completion, explicit user pause/cancellation, or
a concrete external blocker recorded as `[!]` with the exact blocker; `[-]` is for genuinely optional or explicitly
user-deferred work only and does not reduce required scope. Replace the unverified cap sentence at `stop-hook.sh:7`
with a truthful statement: the hook checks checklist syntax only; loop care is the harness's documented Stop-hook
handling and the contract's blocker/pause rules. Add two to three sentences to `SKILL.md` under the "Instructions
versus runtime enforcement" paragraph (`:123-133`) naming what the Claude hook does, what it cannot judge, and that
its reason text now mirrors the contract.

Assumptions: (1) the operator wants text alignment, not new enforcement; (2) the reason string is read by the model as
instruction, so mismatched wording encourages premature parking; (3) no cap number is reinstated because none was
verified. If assumption 1 is wrong, this plan is too small, not wrong.

Simpler alternative considered and rejected: delete the hook reason's second sentence entirely. Rejected because the
hook would then give no stop-path guidance and the model would fall back to memory of the contract rather than the
text in front of it.

Mod rejected: a mod cannot evaluate semantic acceptance either, and GH-831 forbids new gate machinery. PR #966/#967
own the read-only status mod and are gated; nothing here touches them.

Reversibility: Easy. Two text files on a local task branch, no runtime/API change, recoverable from the Git ref.
Rollback: `git revert` the single implementation commit; no installed-link or ledger reversal needed because the
Skills Army deployment is out of this plan's scope.

## Non-goals

No new tests, suites, gates, mods, runners, hooks, loop detectors, or configuration; no trust or permission changes;
no change to the block predicate, fail-open paths, session scoping, or Codex behavior; no change to `install.sh`;
no PR #984 content changes; no merge or deployment.

## Roles

Fable (`--model fable --effort low`): planner and independent plan/final reviewer (separate turns, separate receipts).
Agy: builder, touches production files only after Approved plan QA and exact-row accepted-start. Codex: orchestrator
and final approver. Reviewer writes only the relay receipt. Independent review is required before implementation.

## Ordered execution (one list, verification inline)

1. Commit this doc in `PROJECT/2-WORKING/`, repoint and update the GH-985 ledger row per `SOP.md` Step 1b, then run
   Fable plan QA. -> `utils/pdda/pdda.sh run` zero errors on this doc; Approved receipt under
   `relay-system/2026-10-06/gh985-plan.*.md`. Do not start step 2 without it.
2. Agy edits `skills/2-daily/workhorse/stop-hook.sh:7` (comment) and `:45-48` (reason string) and adds the Claude
   runtime sentences to `skills/2-daily/workhorse/SKILL.md` after line 133. -> `git diff --stat` shows exactly two
   files; `diff` of `stop-hook.sh` lines 9-44 and 49-51 is empty (predicate and fail-open untouched);
   `bash -n stop-hook.sh` and `python3 -c` compile of the heredoc both exit 0.
3. Record bounded manual checks under `TESTS-RESULTS/2026-10-06+GH-985/` with `provenance.jsonl` committed:
   (a) pipe `{"session_id":"gh985","cwd":"<clone>"}` into the hook with a `.workhorse/gh985.md` containing one `- [ ]`
   line -> stdout is `decision: block` and the reason contains the contract wording and no "parked" escape;
   (b) same with `- [x]` only -> no stdout, exit 0; (c) no checklist, malformed JSON, bad session id -> no stdout,
   exit 0 each; (d) red control: temporarily restore the old reason text from the base commit and rerun (a) ->
   the wording assertion fails; restore the new text and rerun -> passes. Also assert the output files are non-empty
   before grading them.
4. Run `./validate.sh --sequential --subsystem small` and `utils/pdda/pdda.sh run` in a separate disposable full
   clone with the identity bracket (`core.bare`, `remote -v`, `user.email`, `HEAD`) captured before and after.
   -> zero errors; warnings inspected and dispositioned in `SUMMARY.md`, no blanket exit-0 claim.
5. Fable final QA on the committed diff and evidence. -> Approved receipt under `relay-system/2026-10-06/gh985-final.*.md`.
6. Push through the pre-push gate from the disposable clone; open a PR based on PR #984's branch, targeting it, with
   the stack dependency and incremental diff stated in the body. -> hosted CI run appears for the exact head SHA;
   update the Status table. Stop here; merge and deployment await operator authorization.

## Acceptance mapping

| Acceptance | Evidence |
|---|---|
| Hook reason no longer advertises parking as an escape | step 3a output and 3d red control |
| Unverified cap claim removed, no replacement number invented | `stop-hook.sh:7` diff and reviewer read |
| Decision predicate and fail-open unchanged | step 2 line-range diff, steps 3b-3c |
| Skill names the Claude hook's limit in one place | `SKILL.md` diff, reviewer read |
| No new tests/gates/mods/config | `git diff --stat` shows two files only |
| Stacked PR exposes dependency | PR base is PR #984's branch; body names it |

## Ratings

pri 65: operator ordered an immediate follow-up and the mismatch can cause premature stops, but no loss or blocked
work is evidenced. sev 45: wording defect in a Claude-only advisory path, hook otherwise correct. appeal 50: neutral.
effort 85: two-file text change on an existing surface. Recurrence: one operator report plus GH-911/GH-983 context;
no measured incident rate, so recurrence is asserted, not counted.

## Validation limits

Manual checks prove the hook emits the new text and still fails open; they do not prove a live Claude session
continues correctly, and nothing here can judge acceptance evidence. Promotion needs the hosted run for the exact
commit.
