---
Goal: Plan QA for GH-505 / GH-509 design v2 — driver-attested approval
Date: 2026-09-08
NEXT: Reviewer
STATUS: Open
ROUND: 1 / 3
---

# Context

Adjudicate the **revised** implementation plan for GH-505 / GH-509 before any code is written.
This is a new design, not a fourth round of the previous thread. The previous thread
(`relay-system/2026-09-08/gh505-reviewer-integrity-plan-qa.md`) blocked at its 3-round cap with
B1 (containment reads the builder-writable directive for permissions) and B2 (merge not bound to
the reviewed head) open, plus F1/F2. Its accepted decisions are carried forward; the plan says how
each open finding is answered.

**Base:** `origin/development` at `a6441b9b`. **Branch:** `fix/gh505-relay-reviewer-integrity`.

Read in full:

- `PROJECT/2-WORKING/GH-505-RELAY-REVIEWER-INTEGRITY.md` — the plan under review (shared by #505, #509, #510)
- `PROJECT/2-WORKING/GH-509-RELAY-TERMINAL-AUTHORIZATION.md` — the #509 pointer
- `PROJECT/1-INBOX/GH-505-RELAY-REVIEWER-INTEGRITY.md`, `PROJECT/1-INBOX/GH-510-JOG-MERGE-FALSE-SUCCESS.md` — evidence and ratings

Source the plan changes:

- `utils/py/relay_drive.py` — args `:30-41`; `terminal_status` `:355`; `token_state` `:361`; loop-top terminal `:571-579`; `RELAY_AGENT` export `:619`; post-turn reads `:820-823`; review-once `:826-846`; post-loop `:866-873`; consult-verify commit `:812-813`
- `relay-automation/relay-turn-lib.sh` — `rtl_is_reviewer_turn` `:63-101`; reviewer `role_note` `:994-998`; shared prompt `:1011`
- `utils/py/marathon_drive.py` — `satisfied_lane_terminal` `:2677-2698`; relay cmd `:3144-3149`; recovery probes `:3218-3222`, `:3294-3298`; caller `:3320-3328`; builder/reviewer env `:1878-1879`, equality refusal `:1940-1942`
- `utils/py/jog_run.py` — override `:1375-1389`; `run_single_phase_drive` `:1279`; caller `:1665`; `handle_landing_boundary` `:1410-1471`; marathon-receipt landing `:426-435`; receipt fields `:137`
- `relay-automation/marathon-agent.sh` — the dispatcher jog will reuse
- `utils/py/codex-turn.py:65-70`, `relay-automation/agy-turn.sh:71-73` — what each turn can write (the trust boundary the plan states)

## The design being reviewed

The driver (`relay_drive.py`) is the only process not run by the party under review. It learns
the reviewer from `--reviewer` (or `--review-once`), exports `RELAY_ROLE` per turn so containment
uses the driver's knowledge instead of the file's, reverts and escalates a terminal STATUS written
in a builder-role turn, and **attests** one written in a reviewer-role turn — appending a block
with reviewer id, reviewed head SHA and a sha256 of the reviewer's appended bytes, and mirroring
it to `<git-common-dir>/relay-attest/<task>.json`. The driver exits 0 only on an approval it
attested in-process. Marathon's post-hoc probes and jog's merge read the attestation, not the word.

## Questions

Answer each with a verdict and cite `file:line` where you disagree.

1. **Does this close B1?** With `RELAY_ROLE` as the first tier of `rtl_is_reviewer_turn`, is
   there any remaining path where a turn's *permissions* (artifact allowlist, reviewer prompt)
   are decided by bytes a builder turn can write? Consider: hand-run turns with no driver,
   `rtl.py` bridging, a stale `RELAY_ROLE` inherited from a parent env.

2. **Does this close B2, and is the trust claim on the mirror file stated honestly?** The plan
   says the driver's exit never depends on the mirror; only marathon's recovery probes and jog's
   merge do, and a same-user host process can forge it (stated non-goal; agy runs unsandboxed).
   Is that the right boundary, or does the mirror reintroduce the round-2 `.tick` problem under
   a different path? Would `receipt["head_sha"]` for the marathon-executor landing be the
   reviewed head, or the head at receipt time?

3. **F1 — precedence.** Builder is never named; a turn is builder-role by not being the reviewer.
   `--review-once` makes the single dispatched actor the reviewer. Neither flag → no terminal
   status can ever be accepted (loud at startup). Is this complete? Is there an existing caller
   this strands that the plan's risk table missed?

4. **Forgery revert.** Reverting the first `STATUS:` line to its pre-turn value and escalating
   `forged-terminal` — is rewriting the relay file from the driver acceptable, given the file is
   committed by the shim's file-scoped commit before the driver sees it? Is a second driver
   commit (attestation or revert) safe with respect to `rtl_enforce`'s commit-bypass guard on the
   *next* turn?

5. **Empty approval.** A reviewer-role turn that writes `STATUS: Approved` without appending
   any bytes is escalated `empty-approval`. Is byte growth a sufficient definition of "the
   reviewer wrote something", or does the attestation need to name what a review must contain?

6. **Falsifiability.** Cases A–J each name a red control at base. Does any of them pass for a
   reason unrelated to the fix? In particular: does case H assert the *process* exit of
   marathon (F2), and does case A's fixture reach the driver's post-turn path rather than a
   helper in isolation?

7. **Scope and DRY.** #510 is folded in because Phase 3 rewrites the same lines. Is that a
   correct fold or scope creep? Is there a second subsystem being built anywhere (the mirror
   directory, `judge_terminal`, `_merge_pr`) that should instead extend something that exists?

8. **Ratings.** #505 `85/85/50/55`, #509 `75/85/50/25`, #510 `70/70/50/90`. Grounded? Appeal
   neutral? Does #509's effort 25 still hold now that the design is ~80 lines rather than a
   subsystem?

Flag anything wrong, missing, incorrectly scoped, or over/under-engineered.

Write your verdict below. Set `STATUS: Approved` only if the plan is sound as written.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
