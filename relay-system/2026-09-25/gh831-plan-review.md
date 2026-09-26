# RELAY · GH-831 plan review — no new tests; three gate tiers
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-25.
-->

NEXT: Producer
STATUS: Escalated
ROUND: 3 / 3

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

### Reviewer · Round 1

VERDICT: FAIL
Basis: The design reuses the existing machinery, but the off-list contradicts its own scope, D5 does not specify complete two-run qualification/replay, and the stated rollback cannot preserve new receipts. Correct these before implementation.
swept file: yes

Read the entire plan and suite-map generator; swept the requested source sections and gh306 in full. Pre-existing behavior relevant to this change is called out below; this is not a claim of an exhaustive audit of every runtime file. No suites, fixtures, validator, pytest, or git commands were executed. Execution claims below are source traces, not green gate evidence.

- **[Blocker] F1 — R2's off list removes actual harness/PRS coverage (Q5–6).** Plan `PROJECT/2-WORKING/GH-831-THREE-TIER-GATE.md:143-145` calls these skill-text/feature tests, but `test/debug-mantra.sh:24-36,57-95` invokes the marathon driver's real dry-run renderer and checks prior-attempt behavior and root-path containment. `test/gh777-start-task-prior-art.sh:8-31` executes `utils/py/prior_art_recon.py` and asserts roadmap/query results. `test/gh132-review-xyz-skill.sh:29-31,51-81,84-100` exercises engine selection, verdict exit codes and worktree isolation through `utils/py/review_xyz.py`, not just skill prose. This is an observed classification error, not an assertion that a suite currently fails. Cheapest fix: retain debug-mantra as Core, disposition prior-art against PRS/core, and explicitly disposition the review engine against the actual harness boundary rather than its filename. Produce exact final names (including the ambiguous `gh527` Small entry) before removing registrations.
  Observed input: The three executable call sites above are included in the plan's off list.
  Affected scope: Proposed off suites that execute harness/PRS behavior, not pure skill-text assertions.
  Falsifier: Show these paths are outside the operator's retained core/PDDA/PRS definition, or that the cited calls no longer exercise that behavior; pure prose-only suites should remain eligible for off.

- **[Should] F2 — D5 needs a landing-level proof contract for BOTH Medium runs (Q3,7).** Plan `:304-318` says two runs and “each run's receipt entry,” but current `utils/py/wave_reconcile.py:553-555,2054-2061` suppresses qualification when **any** entry matches. Its writer stores one `validation.jsonl` (`:620-635`), and its parser requires exactly one start/summary (`:466-469`). Merely admitting the two gate strings makes a Small-only entry sufficient to suppress a Medium landing. Specify the smallest extension to this existing writer/matcher that binds both required runs, hashes, process identities, classification inputs and expected sets to one landing decision; retain atomic no-receipt-on-second-run-failure behavior. State how expected sets are recovered for old tier-2 receipts after lists evolve, rather than recomputing against current HEAD. Add recorded manual checks for missing area evidence, failed second run, and replay after list changes; no new suite is needed.
  Observed input: D5's per-run entries plus the existing `any(qualification_receipt_matches(...))` call sites above.
  Affected scope: Medium qualification and every receipt consumer, including `--only-receipted` recovery.
  Falsifier: A retained Medium proof with only the Small component must fail lookup/replay; complete Small+area proof must pass, including after unrelated registry evolution.

- **[Should] F3 — Make the tier-2 completeness equation precise (Q3).** D5 `:311-315` compares “suite event names” to shell suite names, but `validate.sh:1142,1174,1454-1457` also emits `event=suite,lane=non-suite` for PDDA/static/Python. Literal all-event equality would reject every Small run. Restrict exact membership and uniqueness to sequential shell events and explicitly require selected non-suite events and the expected denominator. Presence+rc=0 alone is insufficient for Python: `:1450-1454` emits a zero-rc Python event when pytest is unavailable, and `:1514-1520` excludes skipped Python from total. The qualifier currently preflights pytest (`wave_reconcile.py:598`), which mitigates the live path but does not make the proposed receipt rules prove completeness. For Small, require shell count + identity + PDDA + actually-run Python; define the corresponding area-run extras. Preserve existing SHA/run/runner identity checks and all tier-3 rules.
  Observed input: The real `python:test_python_layer.py` skip event at `validate.sh:1454` and PDDA suite event at `:1142`.
  Affected scope: New tier-2 acceptance only.
  Falsifier: Real complete Small/area telemetry passes; remove PDDA or Python, duplicate a shell event, or substitute the skipped-Python shape and acceptance must fail.

- **[Should] F4 — Rollback claim is false as written (Q8).** Plan `:429-430` says reverting Phase 2 keeps its receipts valid “because the matcher keeps accepting them.” Reverting that PR restores `wave_reconcile.py:501` (only `validate.sh --sequential`) and `:473` (only tier 3). The new receipt shapes are then rejected. Choose and document either restoring full-run production while retaining backward-compatible readers, or a full revert with explicit requalification of affected landings. Add a concrete trigger and recovery check; Phase 3 should point to the same rollback.
  Observed input: New tier-2 gate strings in D5 `:316-318` versus the pre-change matcher at `:501`.
  Affected scope: Rollback after at least one Small/Medium receipt has been published.
  Falsifier: Under the selected rollback, an already-published tier-2 receipt is either accepted intentionally or requalified by the documented full-run recovery; no claim that a reverted old matcher accepts it.

- **[Should] F5 — Projection does not simulate D4 (Q4,9).** `TESTS-RESULTS/2026-09-25+GH-831/suite_map.py:124-130` treats all skill-only changes except relay/relay-xyz as Small, including mapped subsystems and merge-cleanup; D4 `:288-289` explicitly excludes those. Concrete output: `merge-projection.tsv:11` classifies merge-cleanup fix `068d2994` as `small(skill code)`, and `:54` classifies the skills-army-hq sync change `24b387d6` likewise. It also labels PDDA/releases implementation Small where D5 would select tier 2. Recompute against the final classifier policy, or clearly separate the counterfactual from the design's expected savings. Resolve the obsolete 54-minute Large claim at plan `:161-162` against O3's 60 minutes at `:350-352`. Retain the explicit caveat that stripping all test edits also strips existing-test repairs, not only hypothetical new suites.
  Observed input: The cited projection rows and source branch, compared with D4's exclusion list.
  Affected scope: The 47% Small/40-minute-average forecast and its rating rationale, not the routing runtime.
  Falsifier: Applying final D4 to the retained path sets reproduces each tier and the aggregate forecast; merge-cleanup code cannot remain Small under the stated exclusions.

- **[Should] F6 — Correct R1's unconditional test-edit statement (Q1).** Plan `:89-90` says any test edit gives tier 3, but the GH-487 dedicated-test co-touch exception at `utils/ci-route.sh:335-347,418-424` remains active. Read-only probe: `printf '%s\n' utils/py/releases_app.py test/gh549-work-events.sh | bash utils/ci-route.sh push` exited **0**, decisive output `route=fast`, `tier=2`, `tier2_subsystems=releases`. Update R1 and D4's “test edits” language to preserve and name the existing exception; no runtime behavior change requested.

- **[Pass] Q1/Q3 — Runner reuse is grounded.** `validate.sh:934-940` selects subsystem tier 2; `:1113-1117` starts telemetry before tier-2 work; `:1420-1437` emits sequential shell events; `:1552-1554` writes the summary. `test/lib/runner-telemetry.sh:65-77,164-175` supplies numeric tier/start and summary events in the existing format. `githooks/pre-push:258-295` supports R1's three dispatch arms. `gh306:41-52,88-94` and `gh35:144-153,215-224` support R5's exemption, membership and no-suite tier-1 claims. Computing expected lists in the exact tested clone is sound at production time; F2 covers replay durability. Actual new commands: **[Unverified — needs clone run]**.

- **[Pass] Q5/Q7 — No second subsystem or test machinery is necessary.** D2/D3/D7 (`plan:266-283,327-338`) reuse list data, selector, EXEMPT and existing rules. EXEMPT's existence/disjointness checks (`test/gh306-registry-bidirectional.sh:120-138`) suit retained-but-disabled files. The proposed off names do not intersect gh141's synthetic inventory (`test/gh141-synthetic-registry.sh:34-48`), gh379's canary skip contract (`:275-285`), or the four release-manifest gate lists. Keeping Medium registered preserves gh35 and full-run consumers. `express.py:536-546` accepts an existing registered suite; a hotfix whose sole suite is deliberately off would remain ineligible, consistent with O5. Small's expensive PRS suites are a deliberate O2 tradeoff, not an obvious mapping error. F1 concerns what should be off, not registry plumbing.

- **[Unverified — source unavailable] Q2 — Requirement coverage and operator deviations.** Against the review packet: no-new-tests/rules and AGENTS freeze map to D7/Phase 1; retained files/unregistration map to D3/Phase 2; classifier and hosted tiers map to D1/D4/D5; GH-732 cut maps to Phase 1 step 2. O1 and O3 are justified proposals (push cost; preserving promotion coverage), but `plan:342` labels them defaults, not recorded operator decisions. Promotion is always Large in D6, despite the goal `:23-24` saying the classifier chooses at promotion; explicitly map this exception too. Direct verification failed: `gh issue view 831 --repo HiQS-Labs/XYZ-forge --json body` and `gh api repos/HiQS-Labs/XYZ-forge/issues/comments/5841529958 --jq .body` each exited **1**, `error connecting to api.github.com`. Supply the authoritative requirement/decision spans or a retained accessible copy before claiming DoD(a); do not represent proposed defaults as operator acceptance.

- **[Pass] Q4/Q9 — Bounded policy and rating judgment.** D4 intentionally weakens the gate for named skill/data paths; core exclusions and unmapped fallback must take precedence. The inspected additional skill executable `skills/2-daily/relay-to-issue/relay-to-issue.sh:3-36` handles issue publication, not driver execution/containment; no additional mandatory core exclusion established in this sweep. Appeal 75 is allowed as a labelled interpretation of an explicit desirability preference by `skills/1-hourly/start-task/SKILL.md:245`; plan `:63-64` supplies that label. Priority/severity/effort have stated rationales (`:59-67`), but the empirical forecast needs F5 and the remote recurrence counts were not independently verified. Read-only CSV probe exited **0**: `suite rows: 419 unique: 419`, `small: 61`; these support inventory size, not every disposition.

Root cause of the plan gaps: the existing one-run/full-registry qualification contract is being generalized without spelling out its multi-run replay and rollback invariants; suite names and a different projection policy also substitute for executable scope. Fix the plan and its evidence at those boundaries, without adding new tests or machinery.

Handing off to Producer (claude-a) — disposition F1–F6, resolve the requirement evidence gap, and request the next review turn.

### Producer · Round 1 · claude-a

Every finding is implemented in the plan (`PROJECT/2-WORKING/GH-831-THREE-TIER-GATE.md`) and in the evidence
(`TESTS-RESULTS/2026-09-25+GH-831/`). The dispositions follow.

- **F1 [Blocker] — Implemented.**
  - Re-read every proposed off suite for what it executes. You were right on all three:
    - `debug-mantra.sh` runs the marathon driver's dry-run (`test/debug-mantra.sh:24-36`).
    - `gh777-start-task-prior-art.sh` runs `utils/py/prior_art_recon.py` (`:8-31`).
    - `gh132-review-xyz-skill.sh` runs `utils/py/review_xyz.py` (`:29-31`).
  - All three are now **Core**. New rule (plan R2): *a suite that executes harness, PDDA or PRS code is never
    off.*
  - The off list is now 8 exact names:
    - six execute nothing and only read skill text: `gh578`, `gh615`, `gh616`, `gh617`, `gh779`, `gh781`;
    - two read skill text and run only their own skill's `install.sh` (`test/gh778-review-code-skill.sh:8`,
      `test/gh798-status-skill.sh:8`): `gh778`, `gh798`.
  - Every one of the 63 unsettled suites now has an exact final disposition. See the `OVERRIDES` table in
    `suite_map.py` and the `disposition` column in `suite-map.tsv`.
  - `gh527` is two suites. `gh527-issue-url-repair.sh` is Small; `gh527-destructive-git-guard.sh` is Core.
- **F2 [Should] — Implemented, by removing the two-run case.**
  - The hosted reconcile now qualifies Medium merges with the full registry run (new O7; D1, D5). Medium was
    1–4 of 146 merges.
  - So every landing still has exactly one run and one receipt entry, and the any-match suppression at
    `wave_reconcile.py:553-555, 2054-2061` and `--only-receipted` stay correct.
  - Durable replay: the tier-2 entry records its expected list, and the matcher checks that list against the
    `SUBSYSTEM_TESTS_small` line at the **tested commit** (`git show <tested>:utils/ci-route.sh`), not at
    HEAD (D5.3).
  - Recorded manual checks are added to Phase 2 step 4: replay after a later list change, a missing suite,
    and a failed run.
- **F3 [Should] — Implemented** (D5.2).
  - Exact membership and uniqueness apply only to `lane == sequential` shell events, which must equal the
    expected list.
  - It requires `tier2:pdda`, `python:test_python_layer.py` and `clone-identity-invariant`, each with rc 0.
  - It requires `total == len(expected) + 3`, correcting my own first draft of `+2`. The identity check is
    always counted (`validate.sh:1514`), and a skipped Python layer is excluded from `total`
    (`:1515-1519`), so the zero-rc skip event at `:1454` cannot pass.
  - The identity, run and runner checks, and all tier-3 rules, are unchanged.
  - Falsifier cases, each recorded as a manual check in Phase 2 step 4: missing PDDA, missing or skipped
    Python, a duplicated shell event, a missing suite.
- **F4 [Should] — Implemented.**
  - The rollback is now a forward fix that reverts only D5's selection and keeps the new receipt reader, so
    published Small receipts still match.
  - A full revert of Phase 2 is explicitly not the rollback. It is allowed only after every Small-qualified
    landing is re-qualified with a full run, because the old matcher (`:473, 501`) rejects them.
  - Trigger, action and check are stated, and Phase 3 points to the rollback.
- **F5 [Should] — Implemented.**
  - The projection now routes with D4 exactly: core-skill exclusions and subsystem claims take precedence. It
    prices with D5 (tier 1 runs the Small run; anything else runs the full run).
  - It reports two variants: as merged, 32% Small; with test edits removed, 42% Small. Each variant's bias is
    stated, including that stripping test edits also strips repairs to existing suites.
  - The obsolete 54-minute Large claim is gone. Large is the registry minus off, about 61 minutes.
  - Expected average: about 44–47 minutes per merge, against 61.
- **F6 [Should] — Implemented.** R1 now states the GH-487 dedicated-test co-touch exception, and cites your
  probe (`releases_app.py` + `gh549` gives tier 2, releases). D4 keeps it unchanged.
- **Q2 [Unverified] — Resolved.**
  - Retained copies are committed: `TESTS-RESULTS/2026-09-25+GH-831/requirements-issue-831.md` (the #831
    body) and `decision-802-comment-5841529958.md` (the operator decision).
  - The plan now labels O1–O7 as **proposed defaults, not yet confirmed**, and states that Phase 2 starts only  [Unverified — no citation]
    after the operator confirms O1–O4 and O7.
  - The goal no longer says the classifier chooses at promotion; D1 and D6 state that promotion always runs
    Large.

Handing off to Reviewer (codex) — take your turn: round 2 review of the revised plan against F1–F6 and Q2.

### Reviewer · Round 2 · codex

VERDICT: FAIL
Basis: The single-run design resolves the multi-run receipt problem, but the Small acceptance rule names a nonexistent telemetry event, ledger routing has contradictory precedence, and promotion remains an undispositioned requirement deviation.
swept file: yes

Swept the entire revised plan and suite-map generator, the retained requirements and decision, and the requested runtime/test source sections. Reviewed using SWE and debug-mantra's plan lens. No additional pre-existing defect is asserted from this bounded source sweep; the findings below concern the proposed contracts against existing behavior. No git commands, suites, fixtures, pytest, or validator were executed. All runtime acceptance remains [Unverified — needs clone run].

- **[Should] F7 — D5 requires an event the runner never emits (Q1/Q3).** Plan `PROJECT/2-WORKING/GH-831-THREE-TIER-GATE.md:333-334` requires a non-suite event named `clone-identity-invariant`. At `validate.sh:1480` the identity result is instead `event=stage,lane=non-suite,name=envelope-assert`; `:1483` adds `clone-identity-invariant` only to the shell's PASSED array. Requiring the proposed name rejects a complete Small run. Change D5 to consume the existing `envelope-assert` stage with rc 0 and retain the summary envelope check; keep `total == len(expected) + 3`. Do not add telemetry to satisfy the mistaken name. Also spell the summary's existing `envelope_rc` as string `"0"` (`test/lib/runner-telemetry.sh:174-175`), or explicitly normalize it.
  Observed input: `validate.sh:1480`: `rt_emit stage non-suite "envelope-assert" "$_s" "$(rt_now_ms)" "$_re_rc"`; no emitter for `clone-identity-invariant`.
  Affected scope: D5's new Small/tier-2 qualification rule only; existing tier-3 acceptance stays unchanged.
  Falsifier: In the disposable-clone manual check, complete real Small telemetry must qualify; deleting or failing its envelope-assert stage must reject it without creating a new event type.
  Probe: read-only Python over `Path('validate.sh').read_text().splitlines()`, selecting the envelope emitter and counting lines containing both `rt_emit` and `clone-identity-invariant`; exit **0**, decisive output `validate.sh:1480: rt_emit stage non-suite "envelope-assert" ...` and `clone-identity-invariant rt_emit occurrences 0`.

- **[Should] F8 — Resolve ledger precedence before calling the projection D4-exact (Q4/Q9).** D4 `plan:310` promises `releases.db`/`releases.sql` route docs, but `:313` says subsystem claims take precedence, and `utils/ci-route.sh:36` already claims both for releases. Following that precedence gives tier 2 and therefore the full hosted run under D5. The projection unconditionally discards these paths before checking claims (`TESTS-RESULTS/2026-09-25+GH-831/suite_map.py:153-154`), so it implements a different policy. Cheapest fix: explicitly give these named ledger data files the intended docs exception while retaining subsystem precedence for skill/code paths; align the projection and record a ledger-only routing check alongside the existing exclusion check.
  Observed input: the single changed path `releases.db`, claimed by `subsystem_of()`, matches both contradictory D4 rules.
  Affected scope: the named ledger data paths; releases implementation and its dedicated-test co-touch behavior must retain their existing mapping.
  Falsifier: `releases.db` alone must produce `route=docs,tier=1` under the intended policy, while `utils/py/releases_app.py` stays tier 2 and mixed ledger+core changes stay tier 3. If ledger is intentionally Medium instead, state that deviation and reprice the projection.
  Probe: `printf '%s\n' releases.db | bash utils/ci-route.sh push`; exit **0**, decisive output `route=fast`, `tier=2`, `tier2_subsystems=releases`. This establishes the current claim; it does not execute the proposed classifier.

- **[Should] F9 — Promotion needs an explicit requirement disposition (Q2).** The retained #831 Decision 2 and #802 Decisions 2 both say the classifier chooses at promotion. D1/D6 (`plan:271-275,352-356`) instead always run Large, but O1–O7 contains no promotion exception and the confirmation prerequisite (`:373-374`) cannot settle it. Add a named, justified promotion decision to that prerequisite, or implement the stated promotion requirement. O1, O3 and O7 are reasonable engineering proposals, but `:373` explicitly says they are unconfirmed; they must not be presented as settled operator decisions or an unconditional requirements pass. No need to reopen the sound one-run implementation choice while documenting this.
  Observed input: retained requirement: “`utils/ci-route.sh` picks the tier ... for promotion to `main`”; proposed D1: “the classifier is not consulted”.
  Affected scope: promotion policy and the plan's requirement-to-decision mapping, not a request to add machinery.
  Falsifier: A cited operator decision explicitly accepting always-Large promotion, or a plan item that routes promotion as required, resolves this gap. A list of unconfirmed defaults alone does not establish that decision.

- **[Pass] F1/F2/F4/F6 — Main round-1 corrections are sound (Q1/Q3/Q5/Q6/Q8).** R2 `plan:155-163` retains the three executable harness suites and distinguishes both gh527 files. D5 `:321-349` uses one qualifying run and stores the expected Small list tied to the tested commit, resolving the any-match problem at `wave_reconcile.py:553-555,2054-2061`; computing membership in that tested clone and replaying that commit's list is the correct boundary. The selection-only forward rollback `plan:475-487` keeps readers compatible with published receipts. R1 `:99-103` now names GH-487 accurately. F7 is the remaining completeness correction; F8 limits the revised forecast claim.

- **[Pass] Q1/Q3/Q5/Q7 — Existing machinery supports the proposal.** `validate.sh:934-940,1113-1117,1420-1437,1552-1554` and `test/lib/runner-telemetry.sh:65-77` provide subsystem selection, numeric tier-2 start, sequential shell events and summary. `githooks/pre-push:258-295` preserves the stated dispatch; `gh306:41-52,87-94,120-138` supports explicit off exemptions; `gh35:144-153,215-224` pins retained membership and the unchanged cheap tier-1 path. The eight off names do not intersect the inspected gh141/gh379/release-manifest consumers. `express.py:536-546` still accepts existing registered coverage. D2/D3/D7 add list data and edit existing contracts, with no new suite, writer, runner or telemetry stage. Register `small` in the existing `SUBSYSTEMS` enumeration as well as defining its list: the listing loop at `ci-route.sh:52-67` ignores variables whose names are absent from that enumeration.

- **[Pass] Q2/Q6 — Inventory and remaining requirement mapping are explicit.** D7 and Phase 1 map the freeze/rules; D3 maps off-with-files-kept; Phase 1 step 2 maps the GH-732 ledger cut; D1/D4/D5 map push and reconcile. Read-only Python CSV aggregation (`csv.DictReader(..., delimiter='\t')`, nonempty rows asserted) exited **0**: `suite rows 419 unique 419`, `CORE 300, SMALL 73, OFF 8, MEDIUM 38`; projection `146`, as-merged `{3:98,1:47,2:1}`, no-test-edits `{1:62,3:80,2:4}`. These reproduce table counts, not historical routing correctness. The retained suites/Small PRS cost tradeoff is explicit in R2 and O2; no further mandatory core-skill exclusion was established by this sweep.

- **[Nit] Q9 — Tighten rating prose.** Appeal 75 remains an acceptable labelled interpretation under `skills/1-hourly/start-task/SKILL.md:245`. The plan's Severity 70 rationale calls the problem “work-blocking,” while the same policy's Severity row (`:243`) places work-blocking defects at 80–100. Either distinguish queue delay from that category or adjust the score. The effort paragraph still lists a pre-push-hook edit although D1 leaves it untouched. Recurrence figures were not independently re-fetched; the projection is a forecast subject to F8, not a measured future saving.

Root cause of the remaining plan gaps: the proposed acceptance names were not matched to emitted telemetry, and the policy exceptions are not consistently expressed across requirements, prose and projection. Fix those descriptions at their existing boundaries; no new tests or gate machinery are needed.

Handing off to Producer (claude-a) — disposition F7–F9, correct the plan, and request round 3 review. STATUS remains Open; no implementation approval is implied.

### Producer · Round 2 · claude-a

Every finding is implemented in `PROJECT/2-WORKING/GH-831-THREE-TIER-GATE.md`. The dispositions follow.

- **F7 [Should] — Implemented.** Confirmed with a read: the identity result is
  `rt_emit stage non-suite "envelope-assert"` (`validate.sh:1480`), and nothing emits
  `clone-identity-invariant`.
  - D5.2 now requires the existing `event == stage`, `name == envelope-assert` event with rc 0.
  - It lists `tier2:pdda` (`:1142`) and `python:test_python_layer.py` (`:1454-1461`) as the `lane ==
    non-suite` suite events.
  - It keeps `total == len(expected) + 3`, and spells `envelope_rc == "0"` and `suite_events_match == "yes"`
    as the strings written by `test/lib/runner-telemetry.sh:174-175`.
  - No telemetry is added. Phase 2 step 4 gains the check "deleting or failing `envelope-assert` is rejected".
- **F8 [Should] — Implemented.** D4 now states the precedence:
  - The named ledger, data and view files (`releases.db`/`.sql`, `harnesses.db`/`.sql`, `LEADERBOARD.html`,
    `RELEASES-PREVIEW.html`) are an explicit exception. They join the docs-surface patterns, which
    `ci-route.sh` checks before `subsystem_of()`, so they are docs despite releases' claim at
    `utils/ci-route.sh:36`.
  - Core exclusions and subsystem claims still take precedence for skill paths.
  - Releases implementation and its GH-487 co-touch behaviour keep their mapping.
  - This is the policy the projection already applied (`suite_map.py`'s `D4_DATA`), so the projection is
    unchanged and now matches D4.
  - Phase 2 step 1 gains your routing check: `releases.db` alone gives docs/tier 1, `releases_app.py` gives
    tier 2, and ledger + core gives tier 3.
- **F9 [Should] — Implemented as an explicit operator decision.**
  - New **O8**: promotion always runs Large, a named deviation from #831's Decision 2. Its reasons: the
    promotion range always touches core (1,803 commits on 2026-09-25); classifying it in `ci.yml` would add
    machinery to reach the same answer; and it is the GH-509 last full check.
  - The smallest literal alternative is stated.
  - O8 is added to the Phase 2 confirmation prerequisite (O1–O4, O7, O8). O1–O8 stay labelled unconfirmed
    defaults. The plan claims no operator acceptance for them, only for the four answers recorded in
    "Decision and rating".
- **Nit [Q9] — Implemented.** Severity 70 is now described as queue delay, explicitly outside the policy's
  80–100 work-blocking band. The effort paragraph drops the push-hook edit, which D1 leaves untouched. The
  projection is described as a forecast.
- **Pass note — Implemented.** D2 adds `small` to the `SUBSYSTEMS` enumeration (`utils/ci-route.sh:24`) as well
  as defining its list.

Handing off to Reviewer (codex) — take your turn: round 3 (final) review of F7–F9, the nit and the pass note.

### Reviewer · Round 3 · codex

VERDICT: PARKED
Basis: The technical corrections address F7/F8 and the rating nit. F9 now has an explicit proposed disposition, but the operator has not accepted it or the other requirement deviations. Definition of Done (a) requires an operator decision, not merely a proposed default. At round 3/3 this is escalated for that decision; no further technical revision loop is requested.
swept file: yes

Read the entire current plan and relay, retained requirements/decision, suite-map generator and provenance, and the requested classifier, validator, hook, qualification, registry and express source sections. Applied SWE and debug-mantra's plan lens. No additional pre-existing defect was established by this bounded source sweep. No git command, validator, test suite, pytest or executable fixture was run. Runtime acceptance remains [Unverified — needs clone run].

- **[Should] F9 remains an operator-decision dependency (Q2).** `PROJECT/2-WORKING/GH-831-THREE-TIER-GATE.md:387-388,437` explicitly says O1–O4, O7 and O8 are unconfirmed and gate Phase 2. O8 at `:406-413` now explains always-Large promotion, resolving the missing-disposition prose; it does not establish acceptance. O1 changes the requested push coverage, O3 retains Medium in Large, and O7 replaces Small-plus-area with a full hosted run. These are reasonable engineering proposals, but the retained #831 Decision 2 and #802 Decisions 2 still specify different behavior. Cheapest resolution: Producer obtains and cites the operator's choices, then incorporates any resulting changes. No new machinery is requested.
  Observed input: plan `:387`: "Proposed defaults, not yet confirmed"; retained requirement: "utils/ci-route.sh picks the tier ... for promotion to main"; D1 `:275`: "the classifier is not consulted, O8".
  Affected scope: requirements acceptance for O1–O4, O7 and O8, especially the push, Medium reconcile and promotion policies; not the technical validity of the one-run design.
  Falsifier: A cited operator response accepting those defaults (or plan changes satisfying the original requirements) removes this dependency. The Producer's heading "Implemented as an explicit operator decision" is not that response; its own disposition says the defaults remain unconfirmed.

- **[Pass] F7 and Q1/Q3 — Small completeness now matches emitted telemetry.** D5 at `plan:336-351` requires unique exact sequential membership, PDDA and actually-run Python, the existing `envelope-assert` stage and `total == len(expected) + 3`. `validate.sh:1142,1428,1450-1461,1480,1514-1520,1552-1554` supplies those events and denominator; `test/lib/runner-telemetry.sh:174-175` writes the string envelope field. The skipped-Python denominator cannot satisfy the specified rule. D2 `plan:286-294` now includes both the Small list and its enumeration, matching `ci-route.sh:24,52-67` and `validate.sh:934-940`. Medium uses one full run, so the old two-run question is superseded by O7 rather than incompletely implemented. Phase 2 `plan:459-468` specifies falsifiers against real telemetry; their execution is still owed.

- **[Pass] F8 and Q4 — Ledger precedence is explicit at the right boundary.** D4 `plan:318-326` gives the named data/view files the docs exception while retaining core/subsystem precedence for skill code and GH-487 for test co-touch. This corresponds to the existing docs-first membership case at `ci-route.sh:353-365`; `suite_map.py:142-159` applies the same named-data exception. Phase 2 `plan:445-448` includes ledger-only, releases-code and ledger-plus-core routing checks. This intentionally reduces coverage on named non-core skill/data changes; it is not a claim that those paths retain their previous full-run coverage. No additional mandatory core-skill exclusion was established in this sweep.

- **[Pass] Q2/Q5/Q6/Q7 — Remaining mapping and reuse are explicit.** D7/Phase 1 (`plan:372-380,424-429`) cover the freeze, rule rewrites, AGENTS note and GH-732 cut. D3 (`:298-306`) removes eight registrations while retaining files and extending the existing EXEMPT reason. `test/gh306-registry-bidirectional.sh:41-52,87-94,120-138` and `test/gh35-test-tiers.sh:144-153,215-224` support that design without changing tier 1 or removing Medium coverage. `express.py:536-546` accepts an existing registered suite. The one classifier/list/selector/writer design in D1–D5 adds no runner, lane, telemetry stage or test suite. The retained executable harness suites and the Small PRS cost choice are explicit at `plan:155-163,393-395`; no new off-list defect was established.

- **[Pass] Q8 — Replay and rollback preserve the intended boundary.** D5 `plan:352-362` validates the recorded Small list against the tested commit and leaves old full-run receipt acceptance unchanged. This fits the current single-entry matcher and both any-match consumers at `wave_reconcile.py:493-526,553-555,2054-2061`. The selection-only forward rollback at `plan:503-515` retains the new reader; a full revert requires requalification. Phases 1–3 name observable checks (`:426-433,441-481,485-491`), with Phase 1 text reversal and Phase 3 using the same rollback. This is a plan-level adequacy judgment, not an executed compatibility claim.

- **[Pass] Q9 — Rating prose is now consistent with the policy.** `plan:69-79` separates queue delay from work-blocking defects, labels Appeal 75 as interpretation, and removes the hook edit from effort. `skills/1-hourly/start-task/SKILL.md:243-246` permits that interpretation and defines the four axes. The 32–42% Small share and 44–47-minute average are forecasts (`plan:168-179,415-418`), not measured future performance; remote recurrence counts and the 1,803-commit promotion-range claim were not independently re-fetched.

- **[Pass] Evidence spot-check.** Read-only `python3 -` using `csv.DictReader(..., delimiter='\t')`, nonempty-row assertions, `Counter`, and `hashlib.sha256(Path.read_bytes())`, with `PYTHONDONTWRITEBYTECODE=1` and scratch TMPDIR, exited **0**. Decisive output: `suite rows 419 unique 419`; `CORE 300, SMALL 73, OFF 8, MEDIUM 38`; as-merged tiers `{3:98,1:47,2:1}`; no-test-edits `{1:62,3:80,2:4}`. All four latest-provenance hashes matched (suite map, projection, retained issue and decision), and all eight off files existed. A source-line probe printed `1480:rt_emit stage non-suite "envelope-assert" ...`. These verify the retained inventory/bytes and emitter, not every historical routing decision or future runtime behavior.

Root cause of the remaining hold: engineering proposals differ from the recorded operator requirements; naming and justifying them does not authorize them. Fix site: the existing Decisions for the operator section with an attributable response. No downstream gate or extra review machinery can substitute for that choice.

Handing off to Producer (claude-a) — present O1–O4, O7 and O8 for the operator's decision and record the answer. STATUS is Escalated at the round cap; do not restart the loop or implement Phase 2 on an implied approval.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
