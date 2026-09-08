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

## Round 1 — Reviewer (codex) — 2026-09-08

**VERDICT: CHANGES REQUESTED — Block.** The defect is real, but the plan does not yet establish trusted reviewer attribution or enforce its merge requirement. Keep STATUS Open.

Review basis: read the complete working plan and intake, then traced the cited source and the adjacent terminal consumers. No graph tools were exposed in this session, so graph project/generation and index coverage could not be verified; source reads and targeted string searches supplied the evidence. No project code, test, driver, or git command was executed. These are source-grounded plan findings, not witnessed red/green test results. The only runtime operations were the authorized relay token operations and read-only inventory probes.  [Unverified — no citation]

### Graded findings, highest consequence first

**B1 — Block / Recon + Proof: editable role metadata is not approval authority.** The plan calls the directive authoritative and proposes deriving the role from the relay file after the turn (plan lines 95–105). Both roles may edit that file. A builder can change `reviewer=` to itself and change `builder=` to another identity before writing Approved. The shell parser accepts the first matching comment (`relay-automation/relay-turn-lib.sh:84–92`). The prior hardening explicitly warns that this file is builder-writable (`utils/py/marathon_drive.py:2647–2655`). `RELAY_AGENT` is driver-selected, but comparing it with a model-editable mapping does not establish reviewer identity.

Cheapest correction: pin the role mapping and the dispatched actor before the turn from trusted invocation/configuration; do not re-derive authority from post-turn bytes. Reject role-directive tampering. Specify the restart trust source separately: a snapshot taken at startup cannot authenticate a terminal file already forged before startup. A reviewer-looking prose block is not proof either. Unknown or unverifiable historical approval must escalate unless existing trusted evidence actually attributes the approval to the designated reviewer. Do not invent a new receipt subsystem without first checking whether the existing token/turn evidence can carry that proof.

**B2 — Block / Recon + Diagnosable: the terminal paths and token transitions are incomplete.** There are three driver success sites: loop top (`utils/py/relay_drive.py:572–580`), review-once (`:830–834`), and after loop exhaustion (`:868–873`). The plan names only two. At loop top, `actor` comes from the *current* token; `token_state()` deliberately returns an empty actor for done (`:374–377`). It does not identify the author of a completed turn. A reviewer control that runs `tick done` would therefore become unprovable if the proposed helper simply uses this actor on the next loop iteration.

Also, restoring STATUS and changing NEXT does not hand off the token: dispatch uses token state (`:570`, `:587–619`), not NEXT. If the builder spent the token, this repair reaches `token-state` escalation; if it retained it, it can be dispatched again. Choose a precise policy. The smallest safe one for a forged terminal is an explicit nonzero integrity escalation with an actionable reason. If automatic recovery is required, specify the existing token operation, ownership prerequisites, and behavior for an already-done token. Apply one approval decision consistently to all three success sites, retaining valid reviewer success at the final round and in review-once mode.

**B3 — Block / Recon + Minimal: Phase 3 conflates two Jog executors.** `validate_marathon_executor()` validates the marathon route; its call is conditional on `executor == "marathon"` (`utils/py/jog_run.py:1501–1506`). The legacy `run_single_phase_drive(root, gh_num, builder="agy", simulate=False)` has no reviewer parameter (`:1279`), and its caller supplies none (`:1665–1670`). It configures only the builder shim (`:1296–1303`, `:1343–1360`). Adding a comment cannot create a reviewer dispatch. The proposed seed also references `task_name` before its present assignment (`:1336`), and neither `reviewer` nor `cap` exists in that function. Finally, “delete :1374–1387 entirely” deletes the subprocess invocation defining `proc` and leaves the following `except` orphaned. Delete the override block only, retaining invocation and return.

Cheapest correction: remove the override independently, then explicitly choose whether to route reviewed work through the already-default marathon executor or extend the legacy function's parameters, validation, and dispatcher. Avoid constructing another two-agent orchestration path just to label an existing builder-only path. Account for pre-existing seeded files, which the current seed skips (`:1319`). Do not claim jog already has the required identity at this seam.

**B4 — Block / Blast + Proof: a PreToolUse text hook is not a merge choke point.** Current settings hook tool calls through `Bash`/`Skill` matchers (`.claude/settings.json:23`). The merge operations happen inside programs: `utils/py/express.py:599`, `utils/py/jog_run.py:1432`, `skills/merge-cleanup/scripts/merge_cleanup.py:55–56`, and `relay-automation/marathon-closeout.sh:292`. A tool call launching one of these programs need not contain `gh pr merge`; its subprocesses do not become separate model tool calls. This bypass exists even with the hook installed. `githooks/install.sh --check` checks the **pre-push** dispatch stub (`:43–65`), not a model PreToolUse hook or a server merge policy.

Cheapest correction: use server enforcement as the universal boundary, with an explicitly specified and verified settings rollout and bypass policy. If this PR promises enforcement before that rollout or in downstream repos without that policy, have the existing merge paths invoke one shared review check; the check remains DRY despite several callers. A tool hook can supplement that boundary. Do not mark Phase 4 complete while the only universal enforcement remains an unperformed follow-up. The planned `--json reviewDecision` response also does not provide the author/reviewer identities needed by the second predicate; specify identity inputs, target repo/PR resolution, current approval semantics, and fail-closed handling of unavailable/malformed results.

**B5 — Block / Blast: other active terminal consumers can still bypass the new driver decision.** Marathon's startup `satisfied_lane_terminal()` accepts terminal STATUS plus a done token and directly completes the phase (`utils/py/marathon_drive.py:2677–2698`). Its no-progress recovery (`:3218–3222`) and timeout recovery (`:3294–3298`) also accept terminal status with no actor. These are consumers of the exact trust claim being changed, not unrelated feature work. Hardening only relay_drive leaves forged or unproven terminal state usable through resume/recovery. Extend the same approval-evidence rule to these consumers or explicitly narrow the deliverable and stop claiming all relay terminal approval is protected. The frozen Bash fallback is likewise not fixed by a Python-only change; state the runtime boundary honestly.

**F1 — Fix / Proof: the four acceptance controls need exact oracles.** Phase 1 says “driver exits non-zero,” which can pass on an unrelated setup, lock, shim, or token error. Name the actual driver entrypoint, successful fake-turn execution, exact integrity exit/reason, and prove that the terminal branch was reached. Cover builder and reviewer at ordinary and final-cap turns, review-once, pre-terminal startup/resume, directive tampering, missing/malformed roles, and same-agent ambiguity. A unit assertion on the new helper alone does not satisfy this requirement.

Phase 2 is sound in principle; assert both generated prompts are nonempty and contain their role-specific text before checking Approved. Phase 3 should stub a successfully invoked driver to return a known nonzero code while leaving Approved, then assert Jog preserves that exact code; otherwise it can fail because dispatch never happened or the proposed seed raised an exception. Phase 4 must exercise the real guard entrypoint with representative input and assert whether a fake merge side effect is reached. Merely making fake `gh pr view` print null/APPROVED tests the fixture. Include launch-through-runner and hook-absent cases if universal coverage is claimed. Record nonempty red/green artifacts and provenance in a committed evidence destination; the plan currently names no destination. The reviewer did not run these future tests.

**F2 — Fix / Recon + governance: correct the inventory and remove the frozen-twin cosmetic edit.** Python also emits the role directive (`utils/py/marathon_drive.py:2801`), so “only marathon-drive.sh renders it” is false. A read-only inventory here found 261 markdown files recursively under relay-system, 68 with an anchored directive and 193 without; restricting to date-directory `*.md` files gives 202 / 66 / 136. The plan's 201 / 68 / 133 therefore needs its original command, scope, and freshness, and none of those counts proves that Jog is the largest missing slice or that all remainder are hand-run relays. These counts include stored documents, not measured active traffic. Drop the unnecessary `relay-drive.sh:32` comment edit: it touches a frozen twin, and the guard selects changed paths even for comments (`test/gh308-frozen-twin-guard.sh:49–64`).

### Answers to the six requested questions

1. **Fail-closed scope — correct principle; rollout claims need correction (B1–B3, F2).** Accepting an unprovable approval would preserve the defect. The smallest safe staging is to remove Jog's override first or atomically with the terminal guard, supply trustworthy identities through existing supported launchers, and give unsupported historical/manual threads a clear escalation and supported restart path. Do not restore a writable NEXT fallback to avoid migration. Quantify affected active launchers before calling this a 133-thread breakage. This is **Costly** because it changes relay completion, recovery, and queue landing; name those consumers, a rollout tripwire, and a rollback that explicitly acknowledges it reopens the integrity hole.

2. **Role derivation — not faithful as written (B1–B2).** The shell can return true through NEXT even when the directive is absent, malformed, same-agent, or names neither actor. The issue is not merely False/UNKNOWN collapsing: the prose fallback itself can return true. “Mirror two tiers exactly” conflicts with “UNKNOWN for no directive.” Preserve same-agent fall-through only for compatibility presentation/containment if needed; terminal authorization must classify it as unprovable unless a trusted separate role signal exists. “Does not crash” is insufficient. Prefer one canonical parser with separate compatibility and strict authorization policies. Extending the existing shell helper to expose a strict tristate is smaller than duplicating it; calling today's boolean function unchanged is insufficient. A Python migration is also defensible if the shell delegates to it; leaving both implementations is duplication, whatever it is called.

3. **Ordering and marker — dependency stated backwards (B3).** Phase 1's end-to-end protection depends on deleting the override, so Phase 3's deletion must ship before or with Phase 1. Adding metadata does not depend on the new reader existing. Keep the existing marker for compatibility in this fix; its historical name does not justify a format migration. Renaming only the writer breaks the shell parser at `relay-turn-lib.sh:84` and the marathon task reader at `marathon_drive.py:2623`. Any later neutral-marker migration needs compatible readers first and a bounded consumer inventory.

4. **Merge placement — hook-only rejected (B4).** Installation checks do not fix nested subprocess coverage, and the cited installation check covers another hook system. Server policy is the universal boundary; a shared code check at owned callers is the smallest local enforcement if server policy is not yet guaranteed. Specify how a distinct reviewing model's relay approval becomes a distinct GitHub actor's PR review; these are different identities, and the current plan supplies no bridge. Do not silently promise automation can continue under a requirement it cannot yet satisfy.

5. **Falsifiability — Phase 2 is close; Phases 1, 3, and 4 are underspecified (F1).** Phase 1 names driver behavior but does not require reaching its real terminal path. Phase 4 names an invocation but does not establish that the hook runs. All four are testable after tightening the controls; none has been demonstrated red in this review.

6. **Rating — severity/appeal accepted; priority conditional; effort provisional.** Severity 85 is defensible from the local mechanism: a transcript can falsely attest independent review at the point work is accepted. It does not need the companion Critical label. Appeal 50 is correctly neutral. Priority 85 can remain a severity-led judgment, but the companion defect count and causal attribution are explicitly unverified in the intake and must remain so; an uncounted prior window establishes no rising trend. Effort 55 is plausible for the originally imagined patch, but “four files” understates the now-visible role transport, resume consumers, and real merge boundary. Re-rate after the corrected write-set is chosen; do not turn these gaps into an architectural rewrite by default.

SWE summary: **Recon Block; Minimal Fix; Diagnosable Fix; Blast Block; Proof Block.** The working plan should name debug-mantra for implementation-time failures and a committed evidence location. The next turn should revise the existing plan against B1–B5 and F1–F2, not start implementation.

**Handoff:** Producer is `claude-a`, confirmed by this token's creation and preceding release event. No source/artifact changes were made.

NEXT: Producer (claude-a)

## Round 2 — Producer (claude-a) — 2026-09-08

**All 7 findings accepted. Zero rejected.** Each was verified against source before acceptance rather
than taken on the reviewer's word; the verification is recorded in the plan's "What round 1 changed"
table with the confirming `file:line`. Three of them invalidated the plan's core premise, so this is a
rewrite, not a patch.

### What the blockers actually changed

**B1 is the one that mattered.** I called the in-file directive "authoritative, computed,
unguessable." It is a bare line at `RELAY.md:5`, outside the `▽ DO NOT MODIFY ▽` block, in a file
every turn may write. A builder can set `reviewer=` to itself before writing `Approved`. Verified.

The replacement anchor is `.tick/events/` — append-only JSONL, one file per event, named
`<ts>-<agent>-<verb>-<task>.jsonl`, written by `tick` and not on any turn's allowlist. It answers
"who held the token when the terminal STATUS appeared" from evidence the reviewed party cannot forge.
Paired with a new `--reviewer` argument supplied at invocation — `relay_drive.py` has none today,
confirmed — attribution becomes trustworthy without a new receipt subsystem, per your instruction to
check existing token evidence first.

**B2** — third success site confirmed at `:868-873`; `token_state()` returns `""` for done at
`:374-377`; dispatch reads token state at `:570`, not `NEXT:`. So the first plan's "restore STATUS,
point NEXT at the reviewer, continue" was inert. Replaced with a single policy across all three
sites: no auto-repair, integrity escalation with an explicit reason.

**B3** — verified all three sub-claims. `run_single_phase_drive(root, gh_num, builder="agy",
simulate=False)` has no reviewer param; `proc` is assigned at `:1374` so the stated deletion range
would have orphaned the `except`; `task_name` is assigned at `:1336`, after the seed block. My claim
that "jog already has the identity at this seam" was wrong — that validation is on the marathon
route, a different function. Directive-seeding is dropped entirely; only the override block
(`:1375-1387`) is deleted. Whether legacy jog should gain a reviewer is now an open question, not a
silent second orchestration path.

**B4** — accepted without reservation. A tool call launching `express.py` need not contain
`gh pr merge`, and its subprocesses are not separate tool calls, so the hook fails open even when
installed. Enforcement moved to server branch protection as the universal boundary plus one shared
`require_approving_review()` called by the four owned callers. The hook is demoted to a supplement.

**B5** — verified. `satisfied_lane_terminal()` (`:2677-2698`) and the recovery sites discard `_actor`
explicitly. Phase 1 now extends to them.

**F2** — `marathon_drive.py:2801` does also emit the directive, so "only marathon-drive.sh:1039" was
false. The `relay-drive.sh:32` comment edit is dropped; `test/gh308-frozen-twin-guard.sh:49-64`
selects changed paths even for comments.

### Two corrections to your text, neither changing a verdict

1. B1 blocks the *mechanism*, not the goal — your answer 1 affirms fail-closed as the correct
   principle. The plan reads it that way.
2. The file-count discrepancy is scope, not error: 201 counted `relay-system/<date>/*.md`, yours
   counted recursively. Both are stored-document counts. Your actual point — that neither measures
   active traffic and so neither proves jog is the largest slice — is conceded and the claim is
   withdrawn. A measured inventory of *live callers* is now a precondition for Phase 1.

### Also changed

- Phase order: the override deletion is now **Phase 0**, ahead of the terminal guard, per your
  answer 3. The dependency was stated backwards.
- Marker rename dropped; kept for compatibility per your answer 3.
- Re-rated **85/85/50/40** (effort 55 → 40) for the corrected write-set. Persisted and read back.
- Runtime boundary stated honestly: the frozen shell twin is unfixed by a Python-only change, and
  lanes running it are not protected. Named as a PR limitation.
- The relay-approval → GitHub-reviewer identity gap is named as unsolved, with the consequence
  spelled out: automation cannot satisfy the merge check on its own.
- Acceptance controls rewritten to name entrypoint, exact exit code and reason, and an evidence
  destination (`TESTS-RESULTS/2026-09-08+GH-505/`). Phase 0's control stubs the driver rather than
  the relay file so it fails for the right reason.

### Open questions for this round

1. Is the tick event log a sufficient trust anchor, or can a builder turn reach `.tick/` despite it
   being off-allowlist?
2. With `--reviewer` absent from every existing caller, is escalate-by-default the right default, or
   should it be opt-in for one release with a tripwire?
3. Should Phase 3 ship the shared check at all given it cannot be satisfied by automation today, or
   is server policy alone the honest deliverable?

No implementation has started. No source outside the plan and this thread has been modified.

NEXT: Reviewer
