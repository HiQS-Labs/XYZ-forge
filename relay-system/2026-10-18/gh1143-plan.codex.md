# RELAY · GH1143 plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-18.
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
6. **Commit only the relay file** (`relay(gh1143-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **GH-1143-DEFECT-CAMPAIGN.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: operator
- Started: 2026-10-18

### Artifact — GH-1143-DEFECT-CAMPAIGN.md
```
---
gh_issue: 1143
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1143
title: Radar-to-campaign documentation skill
status: Planning — awaiting plan QA
updated: 2026-10-18
owner: Codex
goal: Connect Radar recommendations to bounded approved discovery using existing assets
created: 2026-10-18
doc_type: feedback
---

# GH-1143 — Defect campaign

Implement a thin instruction skill connecting Radar recommendations to existing campaign,
ATE, fuzz, oracle and minimization assets. Documentation only; no execution or remediation.

## Status

| What was just completed | What's next |
|---|---|
| Source recon and docs-route inspection; intake rated 55/40/50/85 | Independent plan QA before implementation |

## Recon and smallest viable bet

Base: `e93214feb45dc95f32ee2d9080c1d4f6f3b8ab69` (`origin/development`).
PR #946 landed as `e888594fd3e3670a6be2eecdaecc4b20af549c1b`; Radar's existing
verification-asset handoff is the entry seam. ATE's older automatic issue filing is unsafe
for discovery; gen4_campaign's parser defaults to suite mode and synthesis ON. Use explicit
run mode and no-synth only after approval, with model/healing/filing options absent.
`adaptive_ate.generate_pairwise`, `fuzz_engine.fuzz`, `domain_oracles` and
`repro_builder` already provide the building blocks; no new engine is justified.

Outcome: turn selected recommendations into reviewable bounded specifications and accountable
counterexample dispositions. Add `skills/4-occasional/defect-campaign/SKILL.md`, one index row,
and minimal Radar/ATE pointers. Existing Radar alone lacks the approval/evidence contract;
expanding the campaign engine is unnecessary. Revert these docs to roll back.

## Ownership and limits

Live inspection 2026-10-18: primary tick projection has GH1140 final-review handoffs;
its separate clone has dirty merge-cleanup and gh436 files. GH1136 is open and excluded;
GH1133 remains paused. No competing pilot or writes in peer clones. No existing GH1143
intake or open PR found. Fresh standalone full clone and docs task branch follow GH970.
Local claims are clone-local; recheck tracker, claims, locks, processes and peer checkout
state before any future campaign, never infer clearance from an empty new clone.

Proposed rating: 55/40/50/85 (priority/severity/appeal/cheapness), neutral appeal, no override.
This is a missing workflow connection, not an observed runtime defect. #945/#946 are prior
art, not another incident. Recurrence trend unknown: no comprehensive distinct-incident
count for Oct 4–18 versus Sep 20–Oct 4; do not claim growth or zero incidents.

## Ordered plan and acceptance

1. Register/rate this issue via RELEASES CLI, promote this doc per SOP. Classifier inspection:
   Markdown, PROJECT, TESTS-RESULTS, relay-system and releases DB/SQL/generated HTML are
   supported docs surfaces. Inspect the actual final diff including deleted paths; stop if
   any path requires a broader gate. Do not change routing or shared policies.
2. Codex plan QA, cap three rounds; after approval, admit exact owned row via accepted-start.
3. Write the skill and three pointers. Explicit suitability, hypotheses/oracles, known-failing
   and clean controls, concrete budgets/stops, isolated effects, reproducible replay using the
   same predicate, duplicate classes, severity and separately authorized remediation.
   Require individual approval for every new CI test/case/assertion/parametrization.
   Preserve #1131 and prohibit automatic fixes/push/merge/deploy/schedules.
4. Include a source-grounded HELD pilot for #1138 stale batch state: #1140/#1136 excluded;
   structured adapter missing, future separately approved work. No invented argv semantics.
5. Existing skill quick_validate, manual source/link and consumer-path review, deterministic
   PDDA gate, final independent Codex QA (three-round cap). Record evidence under
   TESTS-RESULTS; no new tests, cases, fixtures, scripts, registries or runtime changes.
6. Push through installed docs hook; open DRAFT PR to development and verify remote SHA and
   exact-head hosted statuses. Distinguish smoke/skipped/full qualification. No full suite,
   merge, installation, deployment, campaign execution or clone cleanup.

## Review questions

Check every issue requirement for an equivalent in this plan (omission diff); distinguish
this documentation implementation from future campaign approval. Are tool fit and missing
semantic adapters honest? Are synthesis/healing/autofiling disabled, effects/budgets bounded,
and per-case approval plus ownership boundaries explicit? Are the docs-only gate and existing
writers reused without bypass or speculative machinery? Grade only this local documentation
scope and commensurate complexity. No new tests or enterprise abstractions.
```
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
