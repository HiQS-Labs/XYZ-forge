# RELAY · GH-1509 plan QA (kickstart observer and recovery)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-17.
-->

NEXT: Reviewer
STATUS: Open
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Manual relay: commit only the relay file** (`relay(gh-1509-plan-qa-kickstart-observer-and-recovery): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/1-INBOX/GH-1509-KICKSTART-OBSERVER-RECOVERY.md` (the plan; no code changed yet).
- Reviewer: codex   ·   Producer: agy
- Started: 2026-11-17
- Operational envelope: an instruction-only Forge skill (`skills/1-hourly/kickstart/SKILL.md`) that codifies the operator's assisted factory pattern (observer parent + one delegated outer-loop child). Commensurate complexity applies: no new daemons, schedulers, queues, schemas, or test suites.

### Step A — paraphrase first (GH-1414), before reading anything except the plan
Read only the plan doc. Then, before opening any source file or the issue, write in your block:
**What this proposes** (2–5 sentences), **How the existing system works, per this document**
(2–5 sentences), and a short **What it's not**. Label inference. Record the input boundary
("plan doc only").

### Step B — source-backed validation
Then read: issue https://github.com/HiQS-Labs/XYZ-forge/issues/1509, `skills/2-daily/flywheel/SKILL.md`, `skills/1-hourly/conveyor/SKILL.md`, and `skills/2-daily/jog/SKILL.md`.

- Definition of Done (the Reviewer grades against these):
  1. Invocation plainly creates parent observer/recovery + one outer-loop child with disjoint responsibilities and no competing writer.
  2. Daily-goal intake routes to existing preparation owners; no readiness claim from raw intake alone.
  3. Normal completion, task-local hold, shared unsafe stop, and parent/child interruption handoffs are specified with concrete evidence and next owner.
  4. Unknown/live/stopped ownership refuses replacement; recovery preserves original limits and uncertain results.
  5. No extra queue/schema/runtime service, new test suite or silent installed-skill update.
  6. Independent plan/final QA, classified checks and recorded main/adjacent instruction walkthrough establish the delivered instruction contract; live unattended qualification remains separate.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer · Round 1

**Step A — input boundary: plan doc only.**

**What this proposes:** Add a source-only kickstart skill that creates an observer and recovery parent and delegates outer-loop execution to one child. It composes existing preparation and execution skills, specifies handoffs and bounded recovery, and adds instruction walkthroughs and independent QA. Inference: the skill is intended to codify an assisted operating pattern rather than automate a new runtime.

**How the existing system works, per this document:** The operator currently uses an observer parent and an outer-loop child, but their boundaries and recovery procedures are ad hoc. Conveyor prepares intake for admission, while Flywheel and Jog supply existing execution and recovery functions. Inference: the current pattern depends on existing records and host delegation rather than a new durable coordinator.

**What it is not:** A new queue, daemon, schema, deployed-skill update, or evidence of unattended qualification.

**Step B — source-backed validation**

swept file: yes

- [Blocker] The lifecycle and recovery instructions omit the concrete evidence and ownership needed to safely resume. The plan says only to check process/lock status and inspect the last accepted result, and does not specify paused builders/writers, unresolved actions, saved-result reconciliation, or a handoff record with the next authorized owner (plan:69–74). Issue #1509 explicitly requires these checks; Jog distinguishes a dead owner from absence of unique work and prescribes `resume`, then `retry-gate`, then `retry-build` (skills/2-daily/jog/SKILL.md:409; skills/2-daily/flywheel/SKILL.md:230–234). Specify those evidence fields, stopped-ownership proof, supported recovery order, and parent-interruption handoff before replacement.
  Observed input: a stopped child session with a still-live builder or a missing result receipt is covered only by the generic process/lock check in plan:74.
  Affected scope: interruption and replacement whenever child, builder, writer or action state is unresolved.
  Falsifier: a walkthrough where a stopped child has a live builder or missing receipt must hold replacement and retain the uncertain outcome; a fully stopped, reconciled run may resume within original limits.
- [Blocker] The stated task-local hold transition is broader than Jog permits: plan:72 says a blocker/question/decision hold continues to the next item, but Jog's wake halts on readiness refusal and other non-receipted failures; only specified outcomes continue (skills/2-daily/jog/SKILL.md:26–34). Require the child to follow the selected owner's exact continuation/stop semantics and record the evidence and next owner.
  Observed input: a readiness refusal during a Jog wake is a task-local blocker under plan:72, yet Jog parks and halts that wake.
  Affected scope: task-local holds during a selected execution owner's wake.
  Falsifier: a readiness-refusal walkthrough should stop the wake; a validated task-local failure receipt may continue only as Jog permits.
- [Blocker] Raw requests are sent directly to Conveyor (plan:65–66), although Conveyor prepares existing issues and directs new issues to idea (skills/1-hourly/conveyor/SKILL.md:3–10). Route raw prose through the existing issue-creation owner where needed, then Conveyor, retaining publication and pickup checks.
  Observed input: a raw request with no existing issue is expressly accepted at plan:65.
  Affected scope: intake that has no existing issue identity.
  Falsifier: an existing issue URL routes directly to Conveyor; a new request first obtains an issue through its authorized owner without claiming readiness.
- [Should] The plan omits the issue's explicit unsupported-host stop and treats a stopped child as sufficient for redispatch (plan:50–52, 74). Specify that missing supported delegation/observation leaves a resumable handoff, without direct execution or a daemon; preserve paused ownership and resolve uncertain actions before replacement. Issue #1509, “Smallest delivery” items 3–4.
  Observed input: a host lacking the required delegation or completion capability has no specified outcome in plan:50–51.
  Affected scope: invocation and recovery on hosts lacking a supported capability.
  Falsifier: a walkthrough with delegation unavailable ends held with the missing capability and next owner, while a supported host starts exactly one child.
- [Should] The verification plan names only `pdda.sh run` as classified verification and does not require provenance for the recorded walkthrough (plan:98–100). Specify classification of the actual final diff, the applicable checks and retained nonempty walkthrough evidence with `provenance.jsonl`; distinguish instruction walkthroughs from live unattended qualification. Repository AGENTS.md, “Verified beats plausible”; skills/2-daily/jog/SKILL.md:123–124.
  Observed input: the planned source skill and architecture edit have only a named docs check and a results directory, with no provenance requirement.
  Affected scope: final verification and review evidence for this delivery.
  Falsifier: a final walkthrough record with nonempty results, provenance, classification and applicable checks supports review without claiming a live unattended run.
- [Pass] The proposed source-only scope excludes a new runtime, queue, schema and deployed-copy changes (plan:29–35), consistent with issue #1509's smallest delivery.
- [Pass] The plan explicitly separates raw intake from preparation, publication and Jog admission (plan:63–67); the routing defect above concerns inputs that do not yet have an issue. Conveyor's publication and pickup boundaries are at skills/1-hourly/conveyor/SKILL.md:63–67.
- [Pass] Independent plan and final QA and main/adjacent walkthroughs are scheduled (plan:87–100); live unattended qualification remains separate (plan:34). The evidence details above remain necessary.

The whole plan was swept; the findings above include pre-existing defects in the reviewed file.

**VERDICT: FAIL**

### Producer · Round 1

All findings from Reviewer Round 1 have been implemented in `PROJECT/1-INBOX/GH-1509-KICKSTART-OBSERVER-RECOVERY.md`:

- **Disposition for Blocker 1 (Lifecycle and recovery evidence/ownership): Implemented.**
  Updated Section "Lifecycle Handoffs and Recovery Protocol" item 4 to define:
  - Concrete evidence fields: child session/thread ID, PID/lock state, target execution root, last recorded milestone, last accepted receipt digest, remaining authorized budgets (deadline, max tasks, attempts), and uncertain action records.
  - Stopped-ownership proof: parent must verify child process and any child-spawned builders/writers are truly stopped (not paused, detached, or running in background); active, paused, or unknown state holds; never replace while an owner or builder is active or unknown.
  - Supported recovery ladder: strictly follow `resume` first → `retry-gate` if approved build had failed gate → `retry-build` only if fresh attempt is needed and budget remains; never retry an unknown outcome.
  - Preserves original deadlines, attempt counters, and authority; redispatches only within remaining budget.

- **Disposition for Blocker 2 (Task-local hold vs Jog semantics): Implemented.**
  Updated Section "Disjoint Parent vs Child Responsibilities" item 2 and "Lifecycle Handoffs and Recovery Protocol" item 2:
  - Child strictly follows the selected execution owner's continuation/stop semantics.
  - For Jog (GH-1400 wake), continuing independent work is permitted only after a newly approved published PR or a validated exit 5 pre-advance-failed receipt whose own gate ran and failed. All other failures (readiness refusal, lock contention, guard-killed gate, crash, missing/mismatched receipt, clone ledger drift) halt the wake.
  - Concrete evidence (task ID, reason, next owner) is recorded for every hold.

- **Disposition for Blocker 3 (Raw intake routing): Implemented.**
  Updated Section "Daily-Goal Intake and Preparation Boundary":
  - Existing issues or issue URLs route directly to Conveyor (GH-1476) for preparation.
  - Raw prose / uncaptured requests first obtain an issue via the authorized issue-creation owner (`idea` / `gh issue create` / repo intake SOP) before routing to Conveyor.
  - Conveyor publication and Jog pickup/admission checks remain required before execution admission; no readiness claim from raw intake or issue creation alone.

- **Disposition for Should 1 (Unsupported-host stop & paused ownership): Implemented.**
  Updated Section "Disjoint Parent vs Child Responsibilities" item 1:
  - If the host environment lacks supported delegation or completion watch capabilities, the parent explicitly reports the missing capability, leaves a resumable handoff with pending state and next owner, and halts. It never pretends, starts a daemon/cron, or falls back to direct unassisted execution.
  - Paused ownership is preserved; uncertain actions must be resolved before replacement.

- **Disposition for Should 2 (Verification classification & walkthrough provenance): Implemented.**
  Updated Section "Ordered Implementation and Verification" items 5 and 6:
  - Classifies final actual diff against integration base `development` via `utils/ci-route.sh` to determine applicable gates.
  - Requires retained nonempty walkthrough evidence and `provenance.jsonl` under `TESTS-RESULTS/2026-11-17+GH-1509/`.
  - Explicitly distinguishes instruction walkthrough evidence from live unattended qualification.

Handing off to Reviewer — ready for Round 2 review.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
