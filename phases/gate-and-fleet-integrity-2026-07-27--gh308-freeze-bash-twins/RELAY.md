# Marathon Phase gh308-freeze-bash-twins
STATUS: Approved
NEXT: codex

<!-- marathon-drive: task=MARATHON-GH308-FREEZE-BASH-TWINS-TURN builder=codex reviewer=agy round-cap=7 -->

## Phase Brief

---
title: "Phase brief: GH-308 gh308-freeze-bash-twins (marathon builder input, not a capture doc)"
status: not yet fired
created: 2026-07-27
updated: 2026-07-27
owner: noel
goal: >
  Phase-brief input consumed by relay-automation/marathon-drive.sh for the gh308-freeze-bash-twins phase of
  MARATHON-2026-07-27-GATE-AND-FLEET-INTEGRITY — not itself an active-doc capture; the canonical
  capture doc is GH-308-BASH-TWIN-RETIREMENT.md one level up.
roadmap_exempt: true
---

# Brief — GH-308 **Phase 1 ONLY**: declare Python authoritative, freeze the twins

## Status

| What was just completed | What's next |
|---|---|
| Contract authored and preflighted by the 2026-07-27 /10days sweep — `swarm-preflight --gh-issue` exit 0 (READY). Not yet fired. | Fire as marathon phase 4 of 4, last so no lane edits an already-frozen file. |

**Parent doc:** `PROJECT/2-WORKING/GH-308-BASH-TWIN-RETIREMENT.md`
**Issue:** https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/308
**Runs LAST — after every other lane has finished editing the twins.**

## Scope warning — read before touching anything

The issue title ("Stop maintaining the Bash twins") reads like a large risky migration. **The
contracted work is not that.** Phase 1 is freeze-not-delete:

- **Nothing is deleted.**
- `XYZ_PYTHON`'s default is **unchanged**.
- `marathon-plan` stays a documented **Bash-authoritative exception**.
- `relay-turn-lib.sh` is **not** a twin — it is a shared runtime dependency of the Python lane. Do
  not freeze or delete it.
- Phases 2 (test-matrix collapse) and 3 (opportunistic deletion) are **out of contract**.

If you find yourself deleting a twin or porting a Bash-only script, you have left the contract.

## Why this is the unlocking lane

It closes a recurring correctness class: a fix lands in Bash, Python is the executing default, and
the fix **silently never runs**. Documented recurrences: #296, #215, #223, #174, #148 — five times.
Freezing the twins makes every future fix land in the lane that actually executes.

Verified unstarted: `grep -l FROZEN relay-automation/*.sh` → 0 files; no `bash-final-*` tag exists.

## What to build

1. A short **FROZEN** banner at the top of each of the 11 Tier-A Bash twins, naming Python as
   authoritative, pointing at the corresponding Python file and at issue #308.
2. An enforcement guard that fails (or loudly warns) when a commit touches a frozen twin.
3. The policy recorded in `AGENTS.md` and `UPGRADE.md`, **including** the `marathon-plan` exception.

## Acceptance criteria

- All 11 twins carry the banner.
- **The guard is DEMONSTRATED, not assumed** — prove it blocks/flags with a throwaway commit, per
  the parent doc's own QA checklist.
- The `marathon-plan` exception is written where a future maintainer will actually hit it.
- `git status` shows only banners, docs, the guard, and its test — **nothing deleted**.
- Rollback is a one-line banner removal; confirm no step is hard to undo.
- `test/gh308-frozen-twin-guard.sh` lands and is registered in `validate.sh`'s `TESTS` array.

## Orchestrator-only (do NOT attempt as a lane edit)

- Cutting the annotated `bash-final-2026-07-26` tag.
- Cutting the working branch.

These are listed under the contract's `orchestrator_only` lane for that reason.

## Note on ordering

`relay-automation/relay-drive.sh` is in this phase's write-set **and** in GH-289's. GH-289 runs
before this phase precisely so no lane is asked to edit a file this marathon has already frozen.

## Gate

`bash validate.sh`


---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): relay-automation/agy-turn.sh,relay-automation/aider-turn.sh,relay-automation/claude-turn.sh,relay-automation/codex-turn.sh,relay-automation/pi-turn.sh,relay-automation/poll.sh,relay-automation/relay-loop.sh,relay-automation/relay-drive.sh,relay-automation/consult.sh,relay-automation/marathon-drive.sh,utils/swarm-preflight.sh,AGENTS.md,UPGRADE.md,test/gh308-frozen-twin-guard.sh,validate.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH308-FREEZE-BASH-TWINS-TURN --agent codex --paths "phases/gate-and-fleet-integrity-2026-07-27--gh308-freeze-bash-twins/RELAY.md,relay-automation/agy-turn.sh,relay-automation/aider-turn.sh,relay-automation/claude-turn.sh,relay-automation/codex-turn.sh,relay-automation/pi-turn.sh,relay-automation/poll.sh,relay-automation/relay-loop.sh,relay-automation/relay-drive.sh,relay-automation/consult.sh,relay-automation/marathon-drive.sh,utils/swarm-preflight.sh,AGENTS.md,UPGRADE.md,test/gh308-frozen-twin-guard.sh,validate.sh"
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick ping MARATHON-GH308-FREEZE-BASH-TWINS-TURN --agent codex
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH308-FREEZE-BASH-TWINS-TURN --agent codex --to agy
4. Edit ONLY these paths: phases/gate-and-fleet-integrity-2026-07-27--gh308-freeze-bash-twins/RELAY.md and relay-automation/agy-turn.sh,relay-automation/aider-turn.sh,relay-automation/claude-turn.sh,relay-automation/codex-turn.sh,relay-automation/pi-turn.sh,relay-automation/poll.sh,relay-automation/relay-loop.sh,relay-automation/relay-drive.sh,relay-automation/consult.sh,relay-automation/marathon-drive.sh,utils/swarm-preflight.sh,AGENTS.md,UPGRADE.md,test/gh308-frozen-twin-guard.sh,validate.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: relay-automation/agy-turn.sh,relay-automation/aider-turn.sh,relay-automation/claude-turn.sh,relay-automation/codex-turn.sh,relay-automation/pi-turn.sh,relay-automation/poll.sh,relay-automation/relay-loop.sh,relay-automation/relay-drive.sh,relay-automation/consult.sh,relay-automation/marathon-drive.sh,utils/swarm-preflight.sh,AGENTS.md,UPGRADE.md,test/gh308-frozen-twin-guard.sh,validate.sh.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested` then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH308-FREEZE-BASH-TWINS-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick done MARATHON-GH308-FREEZE-BASH-TWINS-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   Edit ONLY phases/gate-and-fleet-integrity-2026-07-27--gh308-freeze-bash-twins/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.

### Round 1 · Builder · codex

Implemented the Phase-1 freeze only; no twins or Bash-only files were deleted. Added the required
`FROZEN` banner to all eleven Tier-A Bash fallbacks, each pointing to its authoritative Python twin
and issue #308. Added `test/gh308-frozen-twin-guard.sh`, registered it in `validate.sh`, and
demonstrated it blocks a deliberately committed frozen-twin edit inside a throwaway repository while
permitting a docs-only commit. `AGENTS.md` and `UPGRADE.md` now state the Python-only maintenance
policy, the staged/range guard commands, the `marathon-plan` Bash-authoritative exception, and the
`relay-turn-lib.sh` non-twin boundary. Reversibility: Easy — remove the banner/policy/guard commit;
the Bash fallbacks and `XYZ_PYTHON=0` path remain intact. Verified: `bash test/gh308-frozen-twin-guard.sh`
passed (15 pass, 0 fail).

### Round 1 · Reviewer · agy

Reviewed the artifacts and verified the frozen-twin guard passes successfully. The 11 tier-A twins have the required FROZEN banner, the range guard blocks edits to frozen twins, and exceptions for `marathon-plan.sh` and `relay-turn-lib.sh` are correctly preserved. `AGENTS.md` and `UPGRADE.md` were also correctly updated to reflect the new policy.

**Verdict:** Approved
