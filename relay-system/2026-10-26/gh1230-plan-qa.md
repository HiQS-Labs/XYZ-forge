# RELAY · GH-1230 plan QA: task-sync Desktop titles go stale
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-24.
-->

NEXT: Closed
STATUS: Approved
ROUND: 2 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
     **A finding that asks for a behaviour change is a generalization unless you can paste the concrete
     input — a row, a value, a `file:line` — that fails under the current code** (GH-681: the gh673
     final QA relay generalized one late-error observation into "or a later invalid identity", the
     Producer implemented it, the same seat `[Pass]`ed it next round, and one historical NULL-URL
     ledger row then blanked every issue). Every `[Blocker]` or `[Should]` requesting a behaviour
     change MUST carry three lines: `Observed input:` (the failing input you saw), `Affected scope:`
     (the input predicate the change would govern), `Falsifier:` (the fixture or data that would show
     the change unnecessary or wrong, and its expected result).
     A `[Blocker]` must cite an observed failure. This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1230-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/1-INBOX/GH-1230-TASK-SYNC-DESKTOP-STALE-TITLES.md` (the PLAN; no code yet). Requirements are its Scope table, from https://github.com/HiQS-Labs/XYZ-forge/issues/1230.
- Source it changes (read in full): skills/3-weekly/task-sync/scripts/adapters/claude.py (ClaudeDesktopAdapter), skills/3-weekly/task-sync/SKILL.md ("Claude Desktop (GH-1191)" section), skills/3-weekly/task-sync/scripts/task_sync.py. Prior work: PROJECT/2-WORKING/GH-1191-TASK-SYNC-CLAUDE-DESKTOP.md, PROJECT/3-COMPLETED/GH-1196-TASK-SYNC-DESKTOP-PINS.md, TESTS-RESULTS/2026-10-24+GH-1191/, TESTS-RESULTS/2026-10-24+GH-1196/.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-26
- Operational envelope: a local single-operator read-only planner; the Desktop app's `set_session_title` is the only title writer, driven by an agent following SKILL.md from a scheduled task. Grade against the Scope table and commensurate complexity. No new `test/` suites or gate machinery (AGENTS.md, GH-831); manual probes + a live check under TESTS-RESULTS/.
- Operator constraint: zero manual steps and no approval queue (operator, 2026-10-26).
- Native facts (observed on one device, recorded in the plan's Evidence table): scheduled-task runs decline overwriting a user-set title even in bypass mode; an open interactive bypass session's timer wake renamed one; renaming a running session persisted. Whether a scheduled run can hand a rename to an open session is unproven, which is the plan's step 0.
- Definition of Done:
  1. R1–R5 each map to a plan step with a falsifiable check.
  2. Changes stay within the existing loop, procedure and scheduler; no second planner or writer; archiving is limited to the task's own runs.
  3. Removing the window and the running skip is sound: the fail-closed rules are kept, and the GH-1191 probe deltas are stated.
  4. The step 0 gate and the 3a/3b fork are well-defined, and a failed probe stops for the operator.
  5. Rating `rated 70/40/45/60` is grounded.

Questions:
1. Is dropping the title window and the running skip correct and complete (planner + recheck)? What breaks?
2. Is the step 0 probe the right decider for R1, and is 3a's forwarding contract specified enough (sweeper identity, recheck, failure reporting)?
3. Is step 4 (archiving the task's own old runs) safe and necessary for R4, or is the limit bump enough?
4. Are the probes and live checks enough, and not too many?
5. Anything over-engineered, under-specified or out of scope? Cite file:line.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

swept file: yes

- [Blocker] Step 3a requires an operator to create, pin, and give a standing instruction to the sweeper (`GH-1230…md:96`), contradicting R5's no-operator-step acceptance criterion (`GH-1230…md:51`) and the stated zero-manual-step constraint. Make provision/discovery of the pinned sweeper and its instruction part of the scheduled-task procedure, or state that no new-device rollout can claim R5 until it is automatically provisioned.
  Observed input: A device with the scheduled task but no pre-existing named, pinned interactive sweeper session reaches a declined `titleSource: user` row; step 3a then has no recipient and line 96 calls for an operator setup action.
  Affected scope: Every device/new installation lacking the preconfigured sweeper session.
  Falsifier: A documented unattended bootstrap/recovery path creates or deterministically discovers the sweeper, pins it, and installs its standing instruction without an operator action; then the same declined row is forwarded and renamed.

- [Should] R4 requires a complete non-archived inventory (`GH-1230…md:50`), but step 2 permits an exactly-500-row response merely to be reported as “possibly truncated” (`GH-1230…md:89`). Define that boundary as a fail-closed/retry-or-page condition, and add a probe/live assertion that the successful snapshot is demonstrably complete before accepting R4.
  Observed input: `list_sessions(limit=500)` returns exactly 500 rows while a 501st non-archived session exists; the proposed procedure continues with an incomplete snapshot.
  Affected scope: Devices whose non-archived session count meets or exceeds the selected limit.
  Falsifier: Native `list_sessions` proves it has no pagination/truncation signal and a documented hard maximum below 500; then an exactly-500 response is complete by contract.

- [Should] The forwarding contract is not yet executable enough for its safety claim. Step 3a says only that the scheduled run forwards IDs and old/new titles and the sweeper “re-runs the recheck” (`GH-1230…md:95–98`), but it does not name the stable sweeper identity/lookup, the required current-title/activity/date predicates, the post-write confirmation, or which failures increment `forward_failed`. Specify these as a single per-target contract and test a stale forwarded proposal so a manual rename or changed activity is skipped, not overwritten.
  Observed input: A declined proposal for `{id, old="10-23 A", new="10-24 A"}` is forwarded; before delivery the user renames the same session to `"Investigating B"` or its activity date changes. The listed payload alone cannot distinguish a safe retry from an overwrite without an explicit recheck contract.
  Affected scope: Every forwarded decline during concurrent user activity or delayed/unavailable sweeper delivery.
  Falsifier: The receiving native tool atomically compares the old title and activity date as part of `set_session_title`; then the explicit client-side recheck is redundant.

- [Should] The rating's appeal component is ungrounded: `appeal 45` has no rationale while pri/sev/effort do (`GH-1230…md:140–144`). Add its evidence or mark it operator-neutral/assumed, so `rated 70/40/45/60` meets DoD 5.

- [Pass] The plan correctly confines direct title mutation to the existing planner/native `set_session_title` path: the current adapter is plan-only and fail-closed on non-literal archive/running fields (`skills/3-weekly/task-sync/scripts/adapters/claude.py:377–443`); the CLI refuses plan-only apply/set-title modes (`skills/3-weekly/task-sync/scripts/task_sync.py:227–239`); and the existing Desktop procedure already supplies the native write/re-read pattern (`skills/3-weekly/task-sync/SKILL.md:225–256`). No additional pre-existing defect was found in the three source files swept for this plan.

VERDICT: FAIL

Basis: The plan has the right single-planner/single-writer shape and retains the fail-closed planner rules, but its manual sweeper setup violates R5 and the remaining two operational contracts cannot yet prove R1/R4 under their stated boundary inputs.

Handing off to Producer — go to the Producer window and say “take your turn”.

### Producer · Round 1

- [Blocker] manual sweeper setup vs R5: **Implemented.** The sweeper is now provisioned by the same agent-run per-device setup that already creates the scheduled task. It uses `start_session` in bypass mode, pins the session and seeds its instruction, so there's no operator action. It is discovered by exact title on every run (0 or more than 1 match = no sweeper). New probe 0c tests whether a scheduled run can recreate a missing sweeper unattended; if not, every run reports `sweeper=missing` until the next setup run. R5's acceptance check is updated to match.
- [Should] exactly-500 inventory: **Implemented.** Fail closed: retry with `limit=2000`, and abort with `error: inventory truncated` if that is also full. No renames on a possibly incomplete inventory. The live R4 check compares the snapshot count with a separate `limit=2000` count.
- [Should] forwarding contract: **Implemented.** It now has a payload `{session_id, old, new, activity_date}`, sweeper identity and lookup, and a per-target contract: recheck exact `old` title and activity date (skip, never overwrite), write, re-read, receipt with `via: sweeper`. Counts are `forwarded`/`forward_failed` with defined causes. Two live checks cover a stale forward (manual rename) and a moved activity date. Probe 0b covers an app restart.
- [Should] appeal rationale: **Implemented**, marked assumed and operator-neutral.

Round 2: please re-review R5, plan steps 0, 2, 3, 5 and 6, and the rating.

### Reviewer · Round 2

swept file: yes

- [Pass] R1/R5 now have a bounded route decision and an unattended sweeper lifecycle: both candidate send routes are probed first, failed routing stops for the operator, and the exact-title singleton sweeper is provisioned/discovered or reported missing without an approval queue (`PROJECT/1-INBOX/GH-1230-TASK-SYNC-DESKTOP-STALE-TITLES.md:76-81`, `:95-105`). The documented fallback is correctly not presented as automatic (`:107`).

- [Pass] The planner/recheck change is complete for busy and old rows: the plan retains literal archived/running and activity fail-closed handling while removing only title age/running exclusions (`PROJECT/1-INBOX/GH-1230-TASK-SYNC-DESKTOP-STALE-TITLES.md:83-87`); its native recheck compares the current local activity date rather than an impossible fixed timestamp (`:89-93`). This fits the current loop, whose only title exclusions are `running` and the `cutoff` (`skills/3-weekly/task-sync/scripts/adapters/claude.py:417-443`).

- [Pass] R4 now fails closed rather than treating a full page as complete, with a 500→2000 retry and no rename after either ambiguous boundary (`PROJECT/1-INBOX/GH-1230-TASK-SYNC-DESKTOP-STALE-TITLES.md:89-90`). Its archiver is bounded to non-running, >24-hour sessions whose `get_session` has this task's `scheduledTaskId`, and is reversible (`:109-112`); the live check separately checks the complete count (`:127-131`).

- [Pass] The forwarded writer is sufficiently specified: payload identity, fresh title/activity/archival/self predicates, post-write reread, durable receipt, and defined transport/missing-sweeper failure accounting are all present (`PROJECT/1-INBOX/GH-1230-TASK-SYNC-DESKTOP-STALE-TITLES.md:99-106`). The two live stale-proposal checks directly exercise the overwrite boundary (`:121-123`).

- [Pass] The prior rating gap is resolved: appeal is explicitly labelled assumed and operator-neutral, alongside evidence for the other three components (`PROJECT/1-INBOX/GH-1230-TASK-SYNC-DESKTOP-STALE-TITLES.md:151-157`). No additional pre-existing defect was found in the full swept source files `skills/3-weekly/task-sync/scripts/adapters/claude.py`, `skills/3-weekly/task-sync/SKILL.md`, and `skills/3-weekly/task-sync/scripts/task_sync.py`.

- [Pass] Narrow static probe: `python3 - <<'PY' ...` (the six-plan-term check recorded in `.relay-scratch/tmp/gh1230-plan-static-check.txt`) exited 0 and printed `step0_both_routes=True`, `inventory_fail_closed=True`, `sweeper_recheck=True`, `receipt_confirmation=True`, `self_run_archive_only=True`, and `rating_appeal_grounded=True`.

VERDICT: PASS

Basis: All five requirements map to falsifiable probe/live checks. The revised plan keeps one planner, native title writer, procedure, and scheduler; preserves fail-closed planner behaviour; makes forwarding and inventory boundaries explicit; and scopes archiving to the task's own old runs. The live native checks and existing-battery deltas are proportionate; no new test/gate machinery is proposed.

Relay closed (Approved), no further turn needed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
