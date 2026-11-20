# GH-1476 OL-09 plan QA — review sub-agent notes

Reviewed plan: `PROJECT/1-INBOX/GH-1476-RAW-TASK-PREPARATION.md` at `b76b62b1e02ce6c398e30a1975e1262015f8e226` (source base cited by plan: `f346d8908a42cd6e7e92f80657f9e7a21208e0ae`; `git diff f346d8908 b76b62b1e` touches only this plan, `releases.db`, `releases.sql`, so skill source is identical at both).

These are the review sub-agent's own notes (orchestrating session). They are NOT independent review; the independent verdict is the Claude reviewer block in `gh1476-plan-qa.md`.

## Paraphrase (written from the plan alone, before supplementary sources)

What this proposes: Make OL-09 real in instructions only. Conveyor gains one canonical "RAW preparation" policy: accept requests that have no row/contract, default each selected unprepared item to one bounded read-only medium-depth research child, deepen only on concrete state/authority/recovery uncertainty or credible high effort, reuse still-valid prepared evidence, keep unknowns as visible holds and treat risk deferral as an explicit per-batch opt-in. 10days Steps 2/3/8 are then edited to consume that policy: a completed-folder doc no longer auto-excludes, HELD is reported separately from EXCLUDE, exclusion needs affirmative evidence, ratings follow start-task policy (neutral appeal, no forced clearing), and only committed execution selection writes the ledger.

How the existing system works (per document): Conveyor (71 lines) already prepares existing issues through recon, capture, contract, PRS pickup and a reviewed docs PR, with held/needs-spike outcomes, but has no research-depth default. 10days scans a GitHub window, buckets by capture-doc folder (3-COMPLETED = immediate exclude), fans out validity subagents that return binary INCLUDE/EXCLUDE and assign rubric ratings (appeal from clarity, forced `ovr` clearing), authors contracts, plans with `marathon-plan.sh --deep` (a preflight refresh, not research depth), preflights and auto-fires. Jog already owns the preparation/admission handoff; Flywheel coordinates without re-enqueueing 10days work.

What it is not: Not OL-10 (runtime admission refusal of stale/held work), not a #1328 amendment, not numeric global research ceilings, not a new queue/state/schema/test suite/runtime, not installed-skill edits, not live backlog execution, and not dependent on PR #1491. The PR refs #1476 rather than closing it, and the manual scenario walk proves prose consistency only.

## Findings (orchestrator, source-backed)

1. [Should] "Daily-goal intake" has no source owner. `git grep -i "daily[- ]goal"` over skills and PROJECT finds only this plan and two marathon-plan mentions of #1474. 10days takes only a `gh issue list` window (`skills/3-weekly/10days/SKILL.md:197-210`); Conveyor takes only existing issue IDs or a selection scope (`skills/1-hourly/conveyor/SKILL.md:14-19`). The plan must either define RAW = an existing GitHub issue lacking row/capture/contract (then "daily-goal intake retained" means "unchanged", and acceptance bullet 6 needs no work), or name the real entry point. Falsifier: a source line where a non-issue daily-goal text enters 10days or Conveyor.
2. [Should] Conveyor's own shortlist ledger write is left in conflict with "no ledger writes on shortlist". `conveyor/SKILL.md:33` says "Selecting an issue for preparation is pickup/selection under decision 6" and `:36-42` runs `roadmap pickup`/`roadmap rate` for every prepared issue; decision D-b (`decisions/2026-11-04-gh1333-closure-appeal-row-at-start.md:8`) defines selection as commitment to an actual execution batch/marathon. #1476's own recon lists this exact contradiction. The plan's step 3 fixes only 10days. Minimal fix: state that 10days consumes only Conveyor's new policy section, never Conveyor Steps 3-6 (capture publication, pickup, label) from a research child; and either leave Conveyor:33 explicitly unchanged with reason (standalone Conveyor run, GH-1401 decision) or reconcile it. Falsifier: show that 10days research children cannot reach Conveyor Step 4.
3. [Should] Live exclusion/drop lines outside the named Step 2/3/8 edits would still turn unknowns into exclusions:
   - `10days/SKILL.md:73-75` Guardrail: "an existing capture doc parked in PROJECT/3-COMPLETED, is evidence" (of already done) — contradicts plan's "a completed folder alone cannot exclude".
   - `10days/SKILL.md:244` sanity-check filter: "low-consequence noise with a clear deferral path, classify it as EXCLUDE" — an implicit risk-based deferral, contradicting "risk deferral requires an explicit batch-scoped request".
   - `10days/SKILL.md:288` "EXCLUDE when ... unreproducible" — plan covers in spirit ("unknown reproduction/access is held") but should cite this line.
   - `10days/SKILL.md:389-391` Step 4 sniff test: "drop that issue back to `needs_contract` and exclude it from this run" — should be HELD with resumption condition, not exclude.
   Plan step 3 should list these lines (or widen scope to "Guardrails + Steps 2-4 + 8") so the implementer cannot leave a contradictory line.
4. [Should] "Selected unprepared work" is undefined inside 10days. Step 3 already spawns one subagent per surviving issue (`:239-241`) for the whole window; ledger selection happens at Step 4/5 (`:338-343`, `:393`). The plan must say whether the Step 3 subagent IS the default medium research child (cheapest, no new fan-out) or a new pass after INCLUDE. Without it an implementer may research the entire window or select before research.
5. [Should] OL-09 checkbox honesty. #1400 OL-09 reads "implemented and verified"; plan step 4 says "Record remaining real-follow-up requirement before ticking OL-09 as operationally verified" — readable as "record, then tick". State plainly: this PR credits instruction text only; #1400 OL-09 stays unchecked until a real bounded run witnesses the behaviours; the PR body and CHANGELOG say so.
6. [Nit] `10days/SKILL.md:232` also invalidates/clears a malformed `ovr` at Step 2; plan names Step 3's forced clear (`:253`) but should say "preserve and hold a malformed operator value for operator decision" covers both lines.
7. [Nit] Step 5 `--deep` (`:398-401`) naming collision: plan correctly notes it is freshness, not research depth; the new text should not reuse "deep" for research depth in 10days without a disambiguating sentence.
8. [Pass] OL-10 separation, no runtime/schema/test-suite, #1328 non-amendment, no numeric global defaults, and Refs-not-Closes are all explicit (plan lines 25, 48-51). Manual walk explicitly says it proves instruction consistency, not behavioural compliance (plan line 40).
9. [Pass] Rating policy target matches start-task and G5 (`decisions/...:7`).

Orchestrator recommendation: FAIL for this round on findings 2-5 (all plan-text fixes, no new machinery); re-review after parent revises.

## Independent review receipt

- Reviewed plan head: `b76b62b1e02ce6c398e30a1975e1262015f8e226`; reviewer worktree HEAD `a16b1d38` (thread scaffold only; plan bytes unchanged).
- Driver: `relay-automation/relay-drive.sh` → `utils/py/relay_drive.py` (XYZ_PYTHON default), `--reviewer claude-review --review-once --round-cap 1` (from thread `ROUND: 1 / 1`), worktree isolation ON, `ALLOW_PATHS=""`.
- Shim/validator: `relay-automation/claude-turn.sh` → `utils/py/claude-turn.py`, `CLAUDE_AUTH_MODE=subscription` (first-party Claude.ai Max login; the shim refuses non-subscription auth before dispatch), `CLAUDE_MODEL=opus`, effort high. CLI result `success`, 18 turns, 195 s; models used claude-opus-5-5 (+ haiku-5-5 helper). Reported cost $1.57 is the CLI's estimate, not a bill.
- Outcome: reviewer turn committed `2ed73826` (file-scoped, no push). Driver exit 4 = STATUS Escalated because round 1/1 ended without approval (by design of a one-round plan review), not a stall.
- Attestation: `relay_attest` writes a record only for an Approved/Closed terminal; a FAIL verdict has none (`.git/relay-attest/` absent). The driver watched the reviewer-role turn it dispatched; no attestation is claimed.
- Reviewer limits: its `gh issue view` was refused in its sandbox; the orchestrator read #1400 directly: OL-09 = "Raw intake and research policy are implemented and verified", which supports S5.

## Reconciliation

Independent reviewer VERDICT FAIL (B1, S1-S6, N1-N3). It independently found every orchestrator finding 1-5 and added: verdict enum lacks HELD (10days:264), preflight exit 4 dropped without delivering evidence (10days:430 vs conveyor:61), Step 3 rating write before selection (10days:254), budget recorded in a packet that does not yet exist (S4), and missing red-control scenarios (S6). Orchestrator concurs with all; none requires new machinery.

## Round 2 receipt (plan review 2 of 3)

- Reviewed plan: `c9168dc77` (`git diff 8293b014 c9168dc77` touches only the plan). Helper fast-forwarded from `8293b014` to `c9168dc77`; it was clean, with no driver lock, extra worktree or attempts record beforehand.
- Thread: a new `gh1476-plan-qa-r2.md`, scaffolded by `relay-automation/new-relay.sh` at `1991a32c` with round-2 questions. The round-1 thread and its FAIL are unedited.
- Driver: `relay-automation/relay-drive.sh` (Python lane) with `--reviewer claude-review --review-once --relay-task RELAY-gh1476-plan-qa-r2`, `--agent-cmd relay-automation/claude-turn.sh`, `RELAY_WORKTREE_ISOLATION=1` and `ALLOW_PATHS=""`.
  - The first invocation refused before any dispatch: `RELAY-gh1476-plan-qa-r2 not found in the resolved tick log`, exit 4.
  - No Claude call was made, so this was not a review attempt.
  - The token was then seeded per relay-automation/README.md: `tick log task.created`, `claim`, `release --to claude-review`. One driven run followed.
- Claude call:
  - Auth: `CLAUDE_AUTH_MODE=subscription`, first-party claude.ai Max (`claude auth status` showed `apiProvider: firstParty`).
  - Settings: `CLAUDE_MODEL=opus`, `CLAUDE_REASONING_EFFORT=high`, `CLAUDE_MAX_TURNS=40`, `CLAUDE_MAX_BUDGET=5`. Claude Code 2.1.321.
  - Result: CLI `subtype: success`, 17 turns, 246 s.
  - Models: claude-opus-5-5, plus the haiku-5-5 helper.
  - Cost: $1.56 is the CLI's list-price estimate, not a bill.
- Outcome:
  - The reviewer turn committed `862fad45` (file-scoped, no push).
  - The driver ended "escalated to human by design (STATUS: Escalated, token open:claude-a)", which is exit 4. That is expected when a one-round review ends without approval.
  - The token is now `open`, handed to `claude-a`.
- Attestation: none. `relay_attest` writes a record only for an Approved/Closed terminal, and `.git/relay-attest/` is absent. The driver watched only the claude-review turn it dispatched.
- Reviewer limits: inside its sandbox, `gh issue view` returned rc=1 and was not retried, so the #1476 and #1400 wording was not rechecked. It did not read this notes file.
- Verdict: FAIL.
  - Resolved: B1, S1 and S5. The re-run exclusion sweep found no live silent-drop route.
  - Partly resolved: S2, S3, S4 and S6.
  - New Should findings:
    - S-A: Conveyor's "before research dispatch" pickup conflicts with its Step 2→3→4 order and `--doc-path CAPTURE_PATH`.
    - S-B: the second pickup instruction at 10days:338-343 (Step 5) is not reconciled with :393 (Step 4).
    - S-C: "daily-goals issue" and linked-candidate selection are undefined and unbounded.
    - S-D: the scenario table lacks the old-line red controls that plan:47 requires. Rows 1 (intake half) and 3 pass on unchanged text, and S6 (j) is missing with (h) and (i) implicit.
  - Nits: N-A to N-E.
- Orchestrator spot-check: confirmed 10days:338-339 `Persist ratings ... at survivor pickup/planning (Step 5)`, conveyor:33-36 pickup with `--doc-path CAPTURE_PATH`, and `--doc-path` optional at `utils/py/releases_app.py:7029`. I concur with S-A to S-D, and all of them are plan-text fixes.
- Budget: 2 of 3 plan-review rounds used. One final round remains, after a Producer revision.

## Round 3 receipt (plan review 3 of 3, final)

- Reviewed plan: `d2ea31935` (`git diff c9168dc77 d2ea31935 -- PROJECT/` touches only the plan). Before the fast-forward from `84bae47d` to `d2ea31935`, the verify clone was clean, with no driver lock, extra worktree or active writer.
- Thread: a new `gh1476-plan-qa-r3.md`, scaffolded by `relay-automation/new-relay.sh` and committed at `06e777cb` with the round-3 questions. The r1 and r2 threads are unedited.
- Token: a fresh `RELAY-gh1476-plan-qa-r3` was seeded before the driver ran (`tick log task.created`, `claim`, `release --to claude-review`). `tick info` showed it as not found before seeding.
- Driver: one invocation of `relay-automation/relay-drive.sh --reviewer claude-review --review-once --relay-task RELAY-gh1476-plan-qa-r3 --agent-cmd relay-automation/claude-turn.sh`, with `RELAY_WORKTREE_ISOLATION=1` and `ALLOW_PATHS=""`.
- Claude call:
  - Auth: `CLAUDE_AUTH_MODE=subscription`. `claude auth status` showed `authMethod: claude.ai` and `apiProvider: firstParty`. There was no API fallback.
  - Settings: `CLAUDE_MODEL=opus`, effort high, max turns 40, max budget 5.
  - Result: CLI `subtype: success`, 19 turns, 186 s. The $1.39 figure is the CLI's estimate, not a bill.
- Outcome:
  - The reviewer turn committed `d62f34bb` (file-scoped, no push).
  - The driver exited 4 with "escalated to human by design (STATUS: Escalated, token open:claude-a)". That is expected when a one-round review ends without approval.
- Attestation: none. `relay_attest` writes a record only for an Approved/Closed terminal, and `.git/relay-attest/` is absent. Because the verdict was not PASS, there is no approval attestation.
- Verdict: FAIL, with one `[Should]` R3-A and one `[Nit]` N-F.
  - Resolved: S-A, S-C, S-D and N-A to N-E. The regression sweep reopens no round-1 item.
- R3-A:
  - What the plan says: plan:39 says "omit optional --doc-path and repoint ... never point to a nonexistent document".
  - What the writer does: when no doc path is given and no `GH-N-*.md` exists, it creates the row with the made-up path `PROJECT/2-WORKING/GH-N.md` (`utils/py/releases_app.py:3864-3877`, inserted at 3960-3963).
  - Consequence: a 10days INCLUDE with `bucket: null` gets a row pointing at a missing file. If the research child then holds the item, nothing ever repoints the row.
  - Fix: one sentence. 10days records the committed selection in the parent note before research and runs the single `pickup` after capture, with the real `--doc-path`, before Step 5.
  - Check: the orchestrator re-read 3843-3848, 3864-3877 and 3960-3963 and confirms the finding. The reviewer's `--dry-run` probe ran on a scratch DB copy.
- N-F: plan:64 expects "exhausted budget prevents launch", but plan:38 does not say so.
- OL-09: no operational credit. #1400 OL-09 stays unchecked.
- Budget: 3 of 3 plan-review rounds are used, with no reset. Any further round needs explicit operator authorization.
