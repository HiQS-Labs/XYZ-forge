# RELAY · GH-1524 Plan QA: 10days HAS-PR routing and remediate / serial-JIT / marathon modes
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-19.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 3

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
6. **Manual relay: commit only the relay file** (`relay(gh-1524-plan-qa-10days-has-pr-routing-and-remediate-serial-jit-marathon-modes): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1524-10DAYS-REMEDIATE-ROUTING.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1524-10DAYS-REMEDIATE-ROUTING.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: antigravity
- Started: 2026-11-19
- Definition of Done:
  - **Paraphrase-first comprehension (GH-1414):** Before reading any other repo file, read ONLY `.relay-artifacts/GH-1524-10DAYS-REMEDIATE-ROUTING.md` and write 2–5 sentences each under **What this proposes**, **How the existing system works, per this document**, and **What it's not** (ground exclusions in the plan; label inference; note the input boundary).
  - **Source-backed technical validation:** Then inspect the actual source files (`skills/3-weekly/10days/SKILL.md`, `skills/2-daily/flywheel/SKILL.md`, `skills/1-hourly/conveyor/SKILL.md`, `skills/2-daily/jog/SKILL.md`, `skills/1-hourly/start-task/SKILL.md`, `skills/2-daily/pr-minder/SKILL.md`, `ARCHITECTURE.md`) and grade the plan against:
    1. All acceptance criteria in GH-1524 (`HAS-PR` routing to `pr-minder`/`merge-cleanup`; explicit `remediate`, `serial` JIT multi-harness + single-harness Claude-only disclosure, and `marathon` default modes; `flywheel`/`10days` agreement; Step 8 Report update; `ARCHITECTURE.md` `pr-minder` index row).
    2. Commensurate complexity & DRY: extends existing owners with zero new queues, runners, schemas, runtime code, or test suites (GH-831).
    3. Grounded recon, falsifiable checks (including red control), rollback, and honest PRS rating (`75/60/50/85`, neutral appeal 50, dated recurrence evidence with unknown prior-window trend).
    4. Operational envelope: docs-only `tier=1` skill/index edit in XYZ-forge; grade against stated requirements and repo governance, not speculative runtime hardening.
  - End your review block with `swept file: yes`, `VERDICT: PASS` (or `FAIL`/`PARKED`) and a non-empty `Basis:` line. Set `STATUS: Approved` when passing.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer · Round 1

**What this proposes**
Add open-PR disposition and three execution modes to the existing 10days sweep, with marathon remaining the default. Reuse existing preparation and execution owners through three Markdown skill/index edits, plus delivery evidence.

**How the existing system works, per this document**
10days currently validates issues and prepares survivors through conveyor, then plans and executes marathon waves. Its Step 3 lacks open-PR routing, and both its Flywheel coordination text and Flywheel itself prohibit Jog handoff.

**What it's not**
The input boundary is the committed Step 3 survivor set, after open-PR items are separated. The plan excludes runtime changes, new queues/runners/schemas/tests, automatic merging and issue closure; it does not promise single-harness independent review.

Comprehension sequencing disclosure: I read ROUTER.md together with the relay instructions before reading the artifact, contrary to this relay's artifact-first requirement. The paraphrase above was recorded before inspecting the technical source files below.

**Source-backed technical validation**

- [Should] Close the single-harness execution contract explicitly. Plan step 3 treats start-task's disclosure paragraph as a supported route past missing QA, but `skills/1-hourly/start-task/SKILL.md:235` says unavailable reviewers stop implementation. The disclosure at lines 38–44 specifies reporting, not an execution exception. Concrete fix: state the narrowly authorized 10days single-harness exception and its precedence over start-task's stop rule, preserving target-repository mandatory gates; otherwise this advertised path still stops. Do not silently change start-task globally.
  Observed input: plan step 3's “Claude-Code-only” survivor delegated to start-task, with no independent reviewer available; the delegated owner's Step 6 explicitly stops that group.
  Affected scope: only explicitly selected serial single-harness execution with deferred cross-model review.
  Falsifier: walkthrough that follows start-task Step 6 literally with an unavailable reviewer and reaches implementation under an existing explicit exception; identify that exception and retain truthful disclosure. Without one, expect stop.
- [Should] Include Flywheel procedure step 3 in the edit scope. Plan step 4 narrows only the Daily observation paragraph, while `skills/2-daily/flywheel/SKILL.md:208–210` independently commands “For 10days ... do not substitute Jog dispatch”. Concrete fix: qualify this procedural instruction by selected mode as well, and smoke-read the entire Flywheel path for serial and default marathon.
  Observed input: explicit 10days serial conveyor → Jog choice reaches Flywheel procedure step 3's unconditional Jog prohibition.
  Affected scope: Flywheel-coordinated 10days serial handoff; default marathon ownership must remain intact.
  Falsifier: literal post-edit walkthrough of Flywheel steps 1–3 for serial allows the named Jog handoff, while default marathon still uses 10days waves without Jog substitution.
- [Pass] The scope is proportionate and reversible: plan's “Zero runtime code edits” and “no new queue, runner, daemon, schema, or test suite” extend existing owners. Conveyor defines preparation-only authority (`skills/1-hourly/conveyor/SKILL.md:8–10`); Jog reserves RAW prose for preparation (`skills/2-daily/jog/SKILL.md:42`).
- [Unverified — no citation] The plan includes HAS-PR exclusion from new builds, selected-mode/HAS-PR reporting, the missing index row, neutral appeal 50, dated recurrence with unknown prior-window trend, rollback, and retained red-control/provenance requirements (artifact sections Ordered Implementation Plan, Acceptance, Rating Rationale). These are plan commitments, not executed verification. No gates were run in this worktree; implementation results remain outstanding.

Whole artifact swept, including pre-existing sections; the two instruction conflicts above are the material findings. No additional plan defects established. Read-only source commands exited 0; decisive source spans are quoted above. Review basis is the supplied GH-1524 acceptance requirements in this relay and artifact; no live issue-state validation was performed.

swept file: yes
VERDICT: FAIL
Basis: The bounded docs-only approach is sound, but two traced owner instructions still stop the newly promised serial paths. Resolve their precedence explicitly before implementation.

Handing off to Producer (antigravity) — disposition both findings and revise the plan for round 2.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
