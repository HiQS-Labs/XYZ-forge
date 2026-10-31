# RELAY · GH-1280 plan QA: outer-loop ATE campaign
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-30.
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
6. **Commit only the relay file** (`relay(gh1280-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-1280-OUTER-LOOP-ATE-CAMPAIGN.md` (the plan).
  Requirements: GitHub issue https://github.com/HiQS-Labs/XYZ-forge/issues/1280 (run
  `gh issue view 1280 --repo HiQS-Labs/XYZ-forge` if reachable; the plan's "Acceptance
  criteria" list is transcribed from it in commit `eec2054d`).
- Source paths to check claims against: `utils/py/harness.py` (parser `:1311-1347`, run-root guard
  `:1302-1308`, `generate-manifest` `:784`, `init --from-prs` `:639-705`, tick tool spawn
  `:1078-1096`), `utils/py/gen4_campaign.py`, `utils/py/fuzz_engine.py`, `utils/py/adaptive_ate.py`,
  `utils/py/domain_oracles.py`, `utils/py/proc_group.py` (`run_bounded`),
  `TESTS-RESULTS/2026-10-28+GH-1248/controls-checkpoint2.jsonl`,
  `skills/4-occasional/ate/SKILL.md`, `skills/4-occasional/defect-campaign/SKILL.md`.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-30
- Operational envelope: one supervised, local, single-host experiment on the operator's Mac Studio,
  using existing ATE/Gen 4 tools against an experimental CLI. Disposable clones only. No production
  code changes, no new tests or suites (GH-831), no new adapters. Grade against the issue's stated
  requirements and commensurate complexity, not enterprise or multi-tenant threat models.
- Definition of Done — answer each question with a `file:line` citation:
  1. Are the plan's recon claims about `harness.py`, `gen4_campaign.py`, `fuzz_engine.py` and
     `domain_oracles.py` correct (guards, refusal messages, clone/reset contract, absent
     no-new-signal stop, replay predicate)?
  2. Does the containment section (sanitized `PATH`/`HOME`, base argv exclusions, `run_bounded` hard
     cap, identity canaries) actually keep a mutant from reaching the network, `validate.sh`,
     `ci-local.sh`, the primary checkout or the production ledger? Name any concrete path it misses.
  3. Is any issue requirement missing from the plan (smoke controls, budgets, stop conditions, the
     review gates, evidence/provenance)?
  4. Are Track B's stateful claims honest — does each of B1–B3 have a real fixture reset, a semantic
     predicate and a cleanup check, or should one be held?
  5. Is the segmented no-new-signal stop for the long window a faithful, minimal way to meet the
     issue's limit given gen4 has no such stop, and is its stated limitation honest?
  6. Does the plan avoid building a duplicate subsystem or new adapter? Flag over- or
     under-engineering.
  7. Is the rating `rated 55/40/50/35` and its rationale grounded (appeal neutral at 50)?

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
