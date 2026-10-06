# QA relay — the GH-976 plan doc
STATUS: Open
NEXT: codex (Reviewer)

## Your role

You are the **reviewer**. This is a **review-only** turn: `ALLOW_PATHS` is empty, so the only file
you may write is this relay file. Do not edit the plan or any source. Report findings here.

## What to review

`PROJECT/2-WORKING/GH-976-RELAY-RECEIPT-ONLY-PROGRESS.md` — a one-step bugfix plan, not yet built.

Operational envelope: a local CLI relay supervisor used by one developer's headless agent loops.
Tests and machinery must be commensurate; this repo forbids new test suites and new `validate.sh`
registry entries (AGENTS.md "No new tests", GH-831), so do not ask for one.

Read rather than take on trust:

- `utils/py/relay_drive.py:579-590` (`get_head_commit`), `:790-796` (before-turn snapshot),
  `:1094-1108` (the progress oracle and extension), `:737-738` (hard cap), `:399` + `:756` + `:1044`
  (`STATUS: Escalated` handling).
- `relay-automation/relay-turn-lib.sh:1498` and `utils/py/relay_drive.py:643` — the two commits a
  turn produces even when no artifact changed.
- `test/gh115-round-cap.sh` — the existing suite and how its stub simulates "progress".
- GitHub issue #976 and the consumer incident it cites (david-nguyen-chaoticdomain/user-sage-backend#75).

## Definition of Done

This is a plan review: will building this plan fix the defect, and can a cold agent build it from the
doc alone? Answer each with evidence from the repo.

1. **Are the factual claims true?** The plan says HEAD always moves on a relay turn because of the
   two commit sites above, so the `head_after != head_before` arm is always satisfied. Confirm or
   refute with file:line.
2. **Is the receipt-path list right and complete?** `relay-system/`, `marathon-system/`, `.tick/`,
   `.relay-scratch/`, `TESTS-RESULTS/`, plus the relay file's own path. Name any path a receipt
   commit touches that is missing, or any listed path that a real repair legitimately touches.
3. **Does the fix preserve GH-115?** A builder commit of real files at the cap must still extend.
   Would the existing suite's Test 2/3 (which signal progress through `[x]` lines, not commits)
   still pass, and does the suite still pin anything meaningful about the HEAD arm?
4. **Is the red control credible?** The plan records a manual check under `TESTS-RESULTS/` rather
   than adding a suite. Say whether that check, as described, would actually go red on the pre-fix
   code and green after, or whether it is unfalsifiable as written.
5. **Is the non-goal on adjudication right?** The plan declines to parse prose like "adjudication
   requested" because `STATUS: Escalated` already exists as the terminal handoff. Argue against that
   if the harness gives agents no way to set it.
6. **Is it the right size?** One helper, one call-site change, failing closed to "no extension" on
   git error. Flag anything over- or under-built.

Rate each finding `[Blocker]`, `[Must]`, `[Should]`, or `[Note]`. A `[Blocker]` or `[Should]` that
asks for a behaviour change must carry `Observed input:`, `Affected scope:` and `Falsifier:` lines.

Set `STATUS: Approved` only if the plan is buildable as written. Otherwise `STATUS: Changes requested`.

## Round log

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
