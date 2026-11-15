# RELAY · GH-1475 Phase 1 plan QA (Codex)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-14.
-->

NEXT: Reviewer
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
6. **Commit only the relay file** (`relay(gh1475-plan-codex): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-1475-MERGE-CLEANUP-REMEDIATION.md` (the Phase 1 plan; read it in full).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-14
- Definition of Done: the plan is approvable when its claims are grounded in the cited paths, every
  Phase 1 requirement (P1.1–P1.6 of https://github.com/HiQS-Labs/XYZ-forge/issues/1475) is covered with
  the smallest surface, it extends the existing writers (no duplicate subsystem or write path), each
  acceptance check observes the actual failure with a red control, and blast radius, rollback and the
  PRS rating are sound.

## Review packet (Producer: claude-a, 2026-11-14)

**Operational envelope.** `/merge-cleanup` is a local operator CLI run by one person or agent on one
laptop. Grade against commensurate complexity; do not ask for distributed locks, daemons or enterprise
fail-safes. XYZ-forge forbids new tests (AGENTS.md *No new tests*, GH-831): a new suite, a `validate.sh`
entry or gate machinery would itself be a finding; verification is existing suites plus manual checks
under `TESTS-RESULTS/`. Review-only turn: write only this relay file.

### Step 1 — paraphrase first
Read ONLY the plan doc above (no issue, no source yet). Write under your review heading:
**What this proposes** (2–5 sentences), **How the existing system works, per this document** (2–5
sentences), and a short **What it's not** (excluded vs deferred vs unresolved; label inference). State
the input boundary ("plan doc only").

### Step 2 — source-backed assessment
Then read: issue #1475 body (the approved three-phase plan; `gh issue view 1475 -R HiQS-Labs/XYZ-forge`
if reachable, else the Phase 1 list in the plan doc stands), and the sources the plan cites:
`utils/py/wave_reconcile.py`, `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`,
`skills/2-daily/merge-cleanup/scripts/batch_record.py`, `skills/2-daily/merge-cleanup/SKILL.md`,
`test/gh436-merge-cleanup.py`, `test/gh534_phase_c_tests.py`. Label this part **Source-backed assessment**.
Recorded decisions: `merge-check-*` stays retained (pinned tests); flock is out (P3.6); no new gh call.

### Questions
1. Are the plan's line/symbol claims accurate at this revision? Cite any that are wrong.
2. For each of P1.1–P1.6: what prevents an unchanged, unfixed tree from being reported as delivered —
   and where is the intended observed rejection (the red control)? Is any check only an admission probe
   (proves it runs, not that the defect is fixed)?
3. P1.3 uses `shutil.rmtree` on this run's own `mkdtemp` workdir with containment checks, not Trash.
   Is that safe and consistent with repo rules (AGENTS.md danger list, GH-567)? Any path where `clean`
   is true but the workdir holds something an operator needs?
4. P1.4: is the recovery write correct and minimal (dry-run guard, batch lookup by `[N]`, `_sync_batch`
   extraction), and is the `record_sweep` hint logic right without a gh query?
5. P1.6: do the probes risk breaking existing `main()`-level tests that mock `subprocess`/`_gh`? Any
   probe not worth its code?
6. Is anything missing, duplicated, or over-built? Is the rating 60/65/50/75 grounded?

Grade each finding `[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`, then VERDICT.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
