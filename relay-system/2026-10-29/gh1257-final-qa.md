# RELAY · GH-1257 final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-29.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1257-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `utils/py/harness.py`
- Also review: utils/py/_marathon_plan.py (the compute/render split, _pack_waves, _contract_seams, releases_db cfg); the diff `git diff 89e1af53..HEAD -- utils/`; the approved plan PROJECT/2-WORKING/GH-1257-BACKLOG-WAVE-PILOT.md (plan QA: relay-system/2026-10-29/gh1257-plan-qa.md, Approved round 3); the evidence TESTS-RESULTS/2026-10-29+GH-1257/ (SUMMARY.md, provenance.jsonl, controls.txt, suites.txt, pilot-1/, the two control scripts); issue #1257.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-29
- Operational envelope: a local, single-operator, read-only experiment on an unmerged spike branch. Grade against the approved plan and its acceptance criteria with commensurate complexity; do not demand multi-tenant or enterprise machinery. XYZ-forge forbids new test suites (AGENTS.md, GH-831): a new `test/` suite or validate.sh entry would itself be a finding; verification is existing suites plus recorded manual controls.
- Definition of Done: each plan step 1–5 and acceptance criterion 1–6 is implemented as approved and substantiated by the evidence; the planner split is behaviour-preserving; no second planner, writer or suite slipped in; the tool stays read-only and offline; the ambiguity handling matches the plan; the evidence is honest about what it shows (including the #216 under-count); the 60/35/50/45 rating still fits.
- Questions:
  1. Does the code match plan steps 1–5 (including the F1–F6 dispositions)? Cite any divergence with file:line.
  2. Is the `Engine` split truly behaviour-preserving, including `_pack_waves(force_tail=True)` and `_contract_seams` (wave numbering), and is the recorded parity check adequate?
  3. Are there correctness bugs in `plan_draft`, `_build_proposal`, `_verify_plan_draft`, `init_from_prs`, the new `run_tick` branch, `_accepted_briefs` or `status`? Consider copied-vs-shared records, request consumption, reconciliation of a crashed plan-draft tick, and the synthetic tools' unchanged behaviour.
  4. Does the evidence substantiate every acceptance criterion, and is anything claimed that the evidence does not show?
  5. Anything over- or under-built for this pilot?
- Note: the full repository gate (`validate.sh`, route=full per `utils/ci-route.sh`) has not run yet; it runs once on the final approved commit in a disposable clone. Grade it `[Unverified — needs clone run]`, not as a code finding.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
