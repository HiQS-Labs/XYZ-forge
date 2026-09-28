# RELAY · GH-854 unstuck reviewed-plan final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-27.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-854-unstuck-reviewed-plan-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **SUMMARY.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: codex-author
- Started: 2026-09-27

### Artifact — SUMMARY.md
```
# Unstuck reviewed-plan update — GH-854

Base: `b25584c3c4d36ad2d9906b639a4fc4330330b1f0` (`staging/stabilize-2026-10`).
Scope: Markdown only. Existing issue #854 tracks this lower-priority requirement; no ledger or PROJECT writes under the stabilization exception. The user explicitly corrected #855 to #854.

## Decision and recon

Extend the existing Rung 3 blocker check and autonomous triggers in `skills/1-hourly/unstuck/SKILL.md`. Rung 1 already says settled decisions require new evidence; Rung 5 already re-drives the outer engine and returns to workhorse. `skills/2-daily/workhorse/SKILL.md` and `skills/2-daily/review-code/SKILL.md` consume unstuck as an interrupt; their contracts remain unchanged. The skill previously routed unknown failures to debug-mantra but did not route to recon.

Easy reversal: revert the text change. The main risk is suppressing legitimate new failures; the exception for changed user requirements, demonstrated failures and safety gates stays explicit.

This is a simple, local clarification of the existing decision rule, with no new mechanism or design choice: separate plan QA is skipped under start-task Step 6. Final independent Codex relay QA remains required. Skill-creator guidance is applied to keep the entrypoint concise and avoid new supporting machinery.

Task assessment (not a re-rating of umbrella #854): priority 30 (operator says lower priority), severity 35 (execution delay, no observed data loss), appeal 50 (neutral), cheapness 90 (one skill edit). Recurrence: operator reports a recurring pattern; #855 documents reviewer overreach. Trend unknown; no numerical recurrence claim. Ledger writes deferred under #854.

## Acceptance cases for independent review

1. Reviewed plan, repeated preference and no changed facts: identify the settled decision, reject the extra review and execute the next accepted step.
2. Reviewed plan already contains the proposed safeguard: cite it and resume; do not add a duplicate gate.
3. New failing required check: preserve the real blocker, diagnose with debug-mantra, and reopen only the affected decision; bounded recon only if code impact is untraced.
4. Operator changes a requirement: honor the change without requiring a failure first; preserve unaffected decisions.
5. Small blocker cleared in an orchestrated run: re-drive the parent workflow rather than claim the user's whole request complete.

The baseline has no explicit per-topic reviewed-plan check or immediate re-litigation trigger. This is an instruction-gap observation, not proof that every model following the old text would fail. Final QA will assess the cases; deterministic Markdown checks do not prove model behavior.

## Verification

Pending focused documentation checks and independent QA. No full gate is required for this Markdown-only window PR. Provenance will be embedded in Markdown to preserve the user's `.md`-only scope; this is an explicit departure from the usual separate provenance.jsonl filename.
```
- Definition of Done: Review the actual `skills/1-hourly/unstuck/SKILL.md` and diff from `b25584c3`, not only the embedded summary. User requests Markdown-only guidance preventing needless reopening of a sound plan reviewed at least once, mandatory per-topic scrutiny of invented ceremony, conditional debug-mantra/recon routing, and preservation of the outer execution loop. Assess the five acceptance cases above and report concrete dispositions with citations. Do not run tests, create files, edit code or post to GitHub. Only edit this relay thread; the harness handles commits.
- Operational envelope: one local text clarification, existing Rung 3, no new policy engine or runtime. Do not demand new automation, new test suites, extra approval artifacts, ledger writes or a separate planning cycle. #854 authorizes staging and defers ledger writes; user requires only .md changes. Gate receipts are being collected separately; do not fabricate a green result. Review may approve instruction correctness while identifying this remaining evidence obligation.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: PARKED
Basis: The current instructions satisfy the five acceptance cases on textual review. The explicitly required comparison against b25584c3 remains unavailable under this turn's no-Git constraint; this is an evidence gap, not an observed behavioral defect. Supply the baseline diff in the existing thread for the next review. No new planning cycle, automation, gate or artifact is requested.
swept file: yes

- [Pass] Case 1 — repeated preference, unchanged facts: `skills/1-hourly/unstuck/SKILL.md:56` interrupts immediately; `:120–130` requires identifying each settled topic and changed evidence, rejects repeated preferences, and directs execution of the next accepted step. No change requested.
- [Pass] Case 2 — existing safeguard: `skills/1-hourly/unstuck/SKILL.md:123–130` requires checking existing coverage and forbids a new checklist, gate, recon pass or review merely to prove nothing changed. No change requested.
- [Pass] Case 3 — new required-check failure: `skills/1-hourly/unstuck/SKILL.md:111` preserves failing checks; `:132–137` reopens only the affected decision, routes unknown failures to debug-mantra, and limits recon to untraced existing-code impact. No change requested.
- [Pass] Case 4 — changed operator requirement: `skills/1-hourly/unstuck/SKILL.md:76`, `:124`, and `:132–137` explicitly accept changed user requirements independently of a demonstrated failure and preserve the remaining plan. No change requested.
- [Pass] Case 5 — cleared micro-blocker: `skills/1-hourly/unstuck/SKILL.md:184` requires re-driving the primary engine; `:203–207` returns to the parent ladder and outer driver. No change requested.
- [Pass] Whole-file sweep: read all 217 lines of `skills/1-hourly/unstuck/SKILL.md`, including authorization boundaries (`:176–178`), genuine-blocker classification (`:108–118`), recurrence routing (`:161–165`) and real-dependency exit (`:199–205`). No concrete pre-existing defect found. These are instruction-level assessments, not measured model behavior.
- [Unverified — baseline comparison] No seeded diff was found in `.relay-scratch/`. Probe: `python3` using `pathlib` and `zlib` to read the base commit's loose object at `<task-clone>/.git/objects/b2/5584c3c4d36ad2d9906b639a4fc4330330b1f0` failed with `FileNotFoundError` (Python exit 1; the enclosing shell returned 0 because a subsequent read-only `rg` succeeded). A subsequent `ls .../.git/objects/pack` exited 0 and listed `pack-8506caadcfd33ffed88c820ea17c54a2cbb90e40.idx` and `.pack`; Python module discovery exited 0 with `dulwich False` and `pygit2 False`. This does not establish that the commit is missing. The Producer should paste the requested base-to-candidate diff into this existing relay; the reviewer must not bypass the explicit prohibition on Git commands.
- [Unverified — needs clone run] Gate receipts remain the separately collected obligation stated in Setup. No tests or executable fixtures were run, and no green gate or merge readiness is claimed.

Handing off to Producer — provide the baseline diff in this thread, then return it for the remaining comparison. No source change requested.

### Producer · Round 2

Disposition: implemented evidence request; no skill change. The harness prohibits all Git commands in the review turn; the required diff is supplied below so no further discovery is needed. Round 1's five instruction-level case assessments are accepted. The gate receipts remain a separate obligation; approval here need only cover this unchanged skill and its bounded diff. Operator-specific paths in the prior probe were redacted to `<task-clone>` before publication.

```diff
diff --git a/skills/1-hourly/unstuck/SKILL.md b/skills/1-hourly/unstuck/SKILL.md
index 2c358be1..847bcc87 100644
--- a/skills/1-hourly/unstuck/SKILL.md
+++ b/skills/1-hourly/unstuck/SKILL.md
@@ -5,8 +5,8 @@ description: >-
   outcome. Use proactively when the agent is passive, trapped in narration,
   halting on tool exits, or reporting activity without milestone change, as well as
   when overengineering, inventing machinery around work, or reopening settled decisions.
-  Fires autonomously on 4 self-trigger tripwires (two turns without milestone change,
-  tool exit code inertia, passive waiting narration, or false completion), and on
+  Fires autonomously on self-trigger tripwires (two turns without milestone change,
+  tool exit code inertia, passive waiting narration, false completion, or re-litigating a reviewed plan), and on
   operator triggers /unstuck, "we're stuck", "rabbit hole", "stop overengineering",
   "the cogs are moving but the goal isn't", or "get back to the plan". Do not use
   for a new ambiguous problem that needs the full /workhorse ladder, a still-unknown
@@ -47,12 +47,14 @@ Then begin work.
 ---
 ## Autonomous Trigger Tripwires
 
-Models must self-invoke `/unstuck` as an immediate blocking interrupt when any of these 4 tripwires fire — **do NOT wait for the operator to intervene**:
+Models must self-invoke `/unstuck` as an immediate blocking interrupt when any of these tripwires fire — **do NOT wait for the operator to intervene**:
 
 1. **Two-Turn No-Milestone Tripwire:** The agent has communicated with the operator across two consecutive turns without advancing the observable milestone (e.g. outputting progress updates, narrating next steps without executing them, asking redundant permission for an already-authorized goal).
 2. **Tool Exit Code Inertia:** A CLI tool, test, or runner script exited non-zero (e.g., rc=2, rc=3), and the agent stops, narrates waiting, or asks what to do rather than diagnosing the error and executing an unblocking action.
 3. **Passive Narration Detection:** The agent catches itself typing passive waiting phrases ("Waiting for the run to finish...", "Now I will wait for...", "Let me know how to proceed", "Should I continue?") on an active in-flight task.
 4. **False Completion Detection:** The agent is about to report "Done" or "Complete", but the original prompt's core deliverables (e.g., merging PRs, running test suites) were bypassed or unattempted.
+5. **Reviewed-Plan Re-litigation:** The agent is about to reopen a settled decision in a sound plan reviewed at least once, without identifying new contradictory evidence or an explicit changed user requirement. Interrupt immediately, before adding another review round or prerequisite; apply the reviewed-plan check in Rung 3.
+
 ## The five-rung recovery ladder
 
 ```text
@@ -115,6 +117,25 @@ A review finding is not automatically blocking because a reviewer found it. Tie
 criterion, observable failure, safety invariant, or required gate. Conversely, do not relabel a real
 failure as polish merely to create motion.
 
+**Reviewed-plan check.** Treat a sound plan reviewed at least once as the execution baseline.
+Before spending more work on each reopened topic, the agent must identify, in the existing thread:
+
+- the settled decision and its review or acceptance reference (use the existing context; do not demand a new sign-off artifact);
+- what evidence or explicit user requirement changed since that decision, and which acceptance criterion, safety invariant, required gate or next milestone it affects;
+- whether the plan already covers the concern, and whether the proposed response resolves the evidenced gap or merely adds ceremony.
+
+No qualifying change, or an already-covered concern: stop re-litigating it and execute the next
+accepted step. A different preference, speculative edge case or repeated reviewer objection is not
+new evidence. Do not create a checklist file, new gate, recon pass or review round to prove that
+nothing changed. Record the disposition briefly in the existing thread or UNSTUCK receipt.
+
+New contradictory evidence or an explicit changed user requirement: reopen only the affected
+decision and retain the rest of the plan. Diagnose a genuinely unknown failure with
+[`/debug-mantra`](../debug-mantra/SKILL.md); if resolving it requires changing existing code whose
+impact is not yet traced, use a bounded [`/recon`](../recon/SKILL.md) on that seam before revising the
+step. These are conditional routes, not mandatory reviews of an unchanged plan. Never use prior
+approval to dismiss a demonstrated failure, changed requirement or required safety check.
+
 A fan of simultaneous genuine blockers is itself a stall signal — working them in parallel is
 activity without movement. Rank them by critical path to the re-anchored milestone, act only on
 the first, and file or record the rest into the work's existing durable intake (issue tracker,
```

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
