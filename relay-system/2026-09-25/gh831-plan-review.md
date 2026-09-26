# RELAY · GH-831 plan review — no new tests; three gate tiers
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-25.
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
6. **Commit only the relay file** (`relay(gh831-plan-review): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-831-THREE-TIER-GATE.md` (the plan). Evidence: `TESTS-RESULTS/2026-09-25+GH-831/suite_map.py`, `TESTS-RESULTS/2026-09-25+GH-831/suite-map.tsv`, `TESTS-RESULTS/2026-09-25+GH-831/merge-projection.tsv`, `TESTS-RESULTS/2026-09-25+GH-831/provenance.jsonl`. Requirements: GitHub issue #831 and the operator decision on #802.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-25
- Definition of Done: the plan is **Approved** when (a) every #831 requirement maps to a plan item or to an explicit, justified operator decision (O1–O6); (b) the recon claims (R1, R5) match the code at the cited `file:line`s; (c) the design extends the existing classifier, registry, `--subsystem` selector and reconcile writer rather than adding a subsystem, writer, lane or **any new test suite**; (d) each phase has a falsifiable check and a rollback; (e) the 4-axis rating is grounded.

## Review packet

**Operational envelope.** A single-repo local developer harness (macOS) with one hosted macOS reconcile per merge and a macOS promotion run. Grade against the stated requirements and commensurate complexity, not enterprise multi-tenant threat models. **The operator has ruled out new tests and new gate machinery**: flag any plan item that adds a `test/` suite, a registry entry, a guard, lane, runner or telemetry stage. Editing an existing suite's expectations where the behaviour it pins changes is allowed.

**Read in full:** the plan; `utils/ci-route.sh`; `validate.sh` lines 1–60, 735–1180 and 1400–1620 (tiers, selectors, telemetry); `githooks/pre-push` 200–310; `utils/py/wave_reconcile.py` 440–650 and 2030–2080; `test/gh306-registry-bidirectional.sh`; `test/gh35-test-tiers.sh` 100–160 and 200–240; `test/gh425-gate-provenance-pr.sh` 280–420; `utils/py/express.py` 530–615. Spot-check `TESTS-RESULTS/2026-09-25+GH-831/suite-map.tsv`.

**Questions** (answer each; cite `file:line`):

1. **Grounding.** Are R1 and R5's claims accurate at the cited lines — tier handling in `validate.sh`, classification in `ci-route.sh`, the push hook's dispatch, `qualification_summary`/`qualification_receipt_matches`, `gh306`'s EXEMPT rule, `gh35` §4?
2. **Requirement coverage.** Map #831's requirements (no new tests via rules; three tiers chosen by one classifier at push, per-merge reconcile and promotion; off suites unregistered with files kept; AGENTS test-freeze note; GH-732 ledger cut) to plan items. Are O1 (push keeps today's cheap checks) and O3 (Medium suites stay registered, so Large ≈ registry minus off) justified deviations, or unmet requirements?
3. **D5 — tier-2 qualification.** Do the proposed tier-2 rules prove the Small run and the area run were complete (exact expected suite set, all green) without loosening the tier-3 rules? Does `validate.sh --sequential --subsystem small` / `--paths-file` actually emit `run.start`/`run.summary` telemetry with `tier` 2 and per-suite events in the form `qualification_summary` would read (cite the telemetry code)? Is computing the expected set with `ci-route.sh` inside the qualification clone sound?
4. **D4 — classifier.** Does routing non-core skill files and ledger/data files to the docs surfaces weaken any fail-closed guarantee? Is the core-skill exclusion list (`relay-xyz`, `relay`, `relay-automation`, `merge-cleanup`, `express`, `jog`) right — is any other skill's code really harness code?
5. **D3 — registry.** Is `gh306`'s EXEMPT list the right single place to record off suites? Does removing the ~12 proposed off suites break `gh141`, `gh379`, the release-manifest suites (`litmus-`, `nightwatch-`, `ballast-`, `meter-release.sh`), `ci-local.sh`, or `express.py`'s registry check?
6. **Mapping.** Spot-check the dispositions in R2. Is any proposed off suite actually core, PDDA or PRS? Is any Small suite something that should not run on every docs merge?
7. **Commensurate complexity.** Is anything over-built, a second subsystem or writer, or a hidden new test? Is anything under-built for a change to what qualifies a merge?
8. **Rollback and blast radius.** Are they sufficient? Do old receipts stay valid under D5's matcher change?
9. **Rating.** Is `rated 85/70/75/40` grounded in the stated evidence? Appeal 75 is labelled as an interpretation of the operator's stated preference; is that acceptable under the start-task rating policy?

Write findings in the Log per the turn rules (grades, `swept file:` line, `Observed input:`/`Affected scope:`/`Falsifier:` for behaviour-change requests). Set `STATUS: Approved` only if the Definition of Done is met.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
