---
Goal: Plan QA for GH-505 — relay reviewer integrity
Date: 2026-09-08
NEXT: Reviewer
STATUS: Open
ROUND: 1 / 3
---

# Context

Adjudicate the implementation plan for GH-505 before any code is written.

**Base:** `origin/development` at `0b37c36f`. **Branch:** `fix/gh505-relay-reviewer-integrity`.

Read in full:

- `PROJECT/2-WORKING/GH-505-RELAY-REVIEWER-INTEGRITY.md` — the plan under review
- `PROJECT/1-INBOX/GH-505-RELAY-REVIEWER-INTEGRITY.md` — the verified evidence and rating rationale

And the source the plan proposes to change:

- `utils/py/relay_drive.py` — `terminal_status` at `:355-356`; terminal paths at `:571-579` and `:826-846`; `RELAY_AGENT` export at `:619`; `token_state()`
- `relay-automation/relay-turn-lib.sh` — `rtl_is_reviewer_turn` at `:63`; shared per-turn prompt at `:1011`; reviewer `role_note` at `:994-1000`
- `utils/py/jog_run.py` — override at `:1374-1387`; relay seeding at `:1320-1335`; reviewer validation at `:175` and `:190-191`
- `relay-automation/marathon-drive.sh:1039` — the role directive this plan proposes to reuse
- `utils/py/marathon_drive.py:2647-2651` — the prior hardening comment on the same seam

## The defect being fixed

`relay_drive.py` decides a relay is finished by testing the STATUS word alone, never
who wrote it. The shared per-turn prompt tells every agent, builder included, to set
`STATUS: Approved`. `jog_run.py` then overrides a non-zero driver exit when that same
word appears. No merge path, hook, or branch protection requires a review.

## The crux the plan turns on

`rtl_is_reviewer_turn` has two tiers: an **authoritative** one (the
`<!-- marathon-drive: builder=X reviewer=Y -->` directive plus `RELAY_AGENT`, computed,
unguessable) and a **prose fallback** (the first `NEXT:` header line, which the acting
model can write itself). Measured in this clone: **68 of 201 relay files carry the
directive; 133 do not.** Only `marathon-drive.sh:1039` emits it.

## Questions

Answer each with a verdict and cite `file:line` where you disagree.

1. **Fail-closed scope.** Phase 1 escalates `exit 4` (`terminal-role-unprovable`) when
   the role cannot be proven — which today is 133 of 201 relay files. Phase 3 converts
   the jog-seeded slice, but hand-run `/relay` threads keep falling through. Is
   fail-closed the correct call here, or does it break too much to land in one PR?
   If it breaks too much, what is the smallest staging that still closes the hole
   rather than deferring it indefinitely?

2. **Porting the role derivation.** Phase 1 ports `rtl_is_reviewer_turn` into Python as
   a tristate (`True`/`False`/`UNKNOWN`) because the shell version collapses the last
   two, and that collapse is what fails open. Does the tristate faithfully preserve the
   deliberate `builder == reviewer` self-review fall-through? And is a second
   implementation in Python the right move at all, given we would then have two copies
   to keep in sync — or should the driver shell out to the existing function?

3. **Phase 3 ordering and format ownership.** The plan states Phase 1 → 3 as a hard
   dependency (with the override intact, Phase 1's escalation is discarded). Is that
   stated correctly? And does having `jog_run.py` emit a comment marked
   `marathon-drive:` misuse a format another subsystem owns — should it be renamed to a
   neutral marker, and if so what breaks in `rtl_is_reviewer_turn`'s parser?

4. **Merge gate placement.** Phase 4 puts the review requirement in one PreToolUse hook
   rather than at the four `gh pr merge` call sites (`express.py:599`,
   `marathon-closeout.sh:292`, `jog_run.py:1432`,
   `skills/merge-cleanup/scripts/merge_cleanup.py`). The argument is DRY plus a single
   choke point a fifth call site cannot bypass. The counter-argument is that a hook is
   not installed in every clone, so it fails open exactly where the call sites would
   not. Which is right? Does the answer change given `githooks/install.sh --check`
   already exists to verify per-clone installation?

5. **Falsifiability of the acceptance checks.** Each phase claims a red control that
   fails on `0b37c36f`. Are those four controls actually falsifiable as written, or
   does any of them pass for a reason unrelated to the fix? Specifically: does the
   Phase 1 fixture genuinely exercise the driver's terminal path rather than asserting
   on the helper in isolation, and does the Phase 4 fixture test the hook or only the
   `gh` output it reads?

6. **Rating.** The task is rated `85/85/50/55` (pri/sev/appeal/effort, effort scores
   cheapness). Rationale and recurrence evidence are in the intake capture. Is severity
   grounded in the evidence rather than inflated by the companion report's Critical?
   Is appeal correctly left at neutral 50 given the operator expressed no preference?
   Is effort 55 defensible for four files plus four fixtures plus a hook?

Flag anything wrong, missing, incorrectly scoped, or over/under-engineered. If the plan
builds a second subsystem where it should extend an existing one, say so specifically.

Write your verdict below. Set `STATUS: Approved` only if the plan is sound as written.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
