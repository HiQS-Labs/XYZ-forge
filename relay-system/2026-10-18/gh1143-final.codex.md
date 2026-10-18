# RELAY · GH1143 final implementation QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-18.
-->

NEXT: Producer
STATUS: Approved
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
6. **Commit only the relay file** (`relay(gh1143-final-implementation-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **SKILL.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: operator
- Started: 2026-10-18

### Artifact — SKILL.md
```
---
name: defect-campaign
description: Turn a selected Radar defect cluster into a bounded discovery specification using existing ATE, fuzz, oracle and replay assets, then triage evidence for separately approved remediation. Use for Radar-to-campaign planning or explicitly approved discovery; not for strategy-only findings or automatic repair.
---

# Defect campaign

Start with one selected Radar report/cluster and produce a reviewable experiment contract.
Radar recommends; it neither proves a bug nor authorizes execution. Reuse its
[verification-asset handoff](https://github.com/HiQS-Labs/XYZ-forge/blob/development/skills/3-weekly/radar/SKILL.md#sibling-recommend-the-repos-own-verification-assets),
landed in [PR #946](https://github.com/HiQS-Labs/XYZ-forge/pull/946).
This skill adds instructions, not another engine, scheduler or repair loop.

## Suitability and ownership

Pin the target repository, source SHA, report/cluster signature, prior counterexamples and
results. Record live issue/PR reads with UTC observation time separately from source revision.
Read current repo guidance and inspect existing issues, PRs and local owners before proposing
work. In XYZ, use the existing prior_art_recon utility and read-only `tick claims --json` in
relevant maintained/active clones; inspect driver locks, processes and task checkout state.
An empty fresh clone's claim log is not global clearance. Unknown or overlapping ownership
means hold and report the owner/dependency; never steal claims or modify peer work.

Choose by problem class, with a concrete target, falsifiable invariant, safe fixture and useful
oracle. If one is missing, return a held specification naming the gap rather than run anyway.

| Problem | Existing asset to inspect | Limit |
|---|---|---|
| CLI grammar/input boundaries | [fuzz_engine.py](https://github.com/HiQS-Labs/XYZ-forge/blob/development/utils/py/fuzz_engine.py): seeded argv mutation/replay | Error text or exit status alone may be expected refusal |
| Configuration/environment interactions | [adaptive_ate.py](https://github.com/HiQS-Labs/XYZ-forge/blob/development/utils/py/adaptive_ate.py): constrained pairwise grid | Pairwise coverage does not establish higher-order sequence coverage |
| State transitions, resume, concurrency | Structured operation sequences with a domain adapter and semantic predicate; inspect [domain_oracles.py](https://github.com/HiQS-Labs/XYZ-forge/blob/development/utils/py/domain_oracles.py) | Containment, idempotence and crash-recovery checks do not prove business semantics; generic argv mutation supplies no stateful adapter |
| Documentary drift, prioritization, strategy | Analysis and existing review workflow | Do not force a fuzz campaign |

Reuse [gen4_campaign.py](https://github.com/HiQS-Labs/XYZ-forge/blob/development/utils/py/gen4_campaign.py)
when its argv/clone contract fits; use [repro_builder.py](https://github.com/HiQS-Labs/XYZ-forge/blob/development/utils/py/repro_builder.py)
for compatible argv/environment minimization. Its default reproduction predicate is return
code plus optional output substring, not an arbitrary semantic oracle. Missing adapters or
predicate integration are future separately scoped work, never an implied implementation task.
[ATE](https://github.com/HiQS-Labs/XYZ-forge/blob/development/skills/4-occasional/ate/SKILL.md)
and [#435](https://github.com/HiQS-Labs/XYZ-forge/issues/435) provide existing variation/offline-clone
precedent; [#460](https://github.com/HiQS-Labs/XYZ-forge/issues/460) provides disposition context.

## Specify before requesting execution approval

Keep one contract in the existing task/results record, with:

- Target SHA, owner, report link, hypothesis and a precise semantic oracle/falsifier; distinguish
  expected refusals from defects. Specify known-failing and clean controls and their expected
  observations. Identify retained source evidence for each; do not claim unrun controls passed.
- Allowed input mutations/operation sequences, fixture reset boundary, sanitized environment,
  offline dependency stubs, seed and immutable corpus snapshot; exclude production/shared state.
- Exact commands, dependencies and permitted effects. Set finite wall-time, total case/mutation,
  per-command timeout, batch/corpus and no-new-signal limits, reserving replay/minimization and
  cleanup time inside the total budget. Never inherit a multi-hour default without approval.
- Disposable standalone full clones (not primary or linked worktrees), host/sandbox identity
  baselines, owned process groups and verified descendant cleanup. Reuse existing process-group  [Unverified — no citation]
  facilities such as [proc_group.py](https://github.com/HiQS-Labs/XYZ-forge/blob/development/utils/py/proc_group.py).
  Check actual nested process behavior: an outer process group alone does not contain a child
  that starts its own session. If existing controls cannot meet the contract, hold; build no adapter.
- Stop on containment/identity violation, surviving processes, invalid observations or oracle,
  missing dependency, exhausted budget or the declared repeated no-new-signal limit. Preserve
  evidence and clean only owned disposable state; do not retry by increasing budgets.

Obtain explicit operator approval for this bounded execution and permitted effects before
running discovery. Planning or invoking this skill is not campaign approval. Every individual
new CI test, case, assertion or parametrization requires its own explicit operator approval;
approving discovery does not approve synthesis or turning discovery inputs into CI cases.
No new suites, fixtures or registry entries by default. Preserve [#1131](https://github.com/HiQS-Labs/XYZ-forge/issues/1131):
no full development-suite preflight or repeated full gate; follow current qualification policy.
Older SOP/ATE instructions for auto-filing, new regression tests, full preflight or fixes do
not supersede these boundaries. No automatic fix, push, merge, deployment, issue closure or
schedule activation. Any external filing or publishing needs separate explicit authorization.

## Verify current CLI safety before an approved run

Read the exact pinned source and `--help` first, without invoking a default mode. Currently
`gen4_campaign.py` defaults to `--mode suite`, and synthesis defaults ON. Discovery must use
explicit `--mode run --no-synth`, with all approved numeric/target bounds supplied; omit
`--tier2-cmd` and `--heal-generator-cmd`. Verify those omissions still disable model/healing
paths at the inspected revision. Keep automatic filing off: omit ATE `--gh-repo` and do not
invoke `compile_issue.py`, filing helpers or auto-filing wrappers. If safety flags/semantics
have drifted or cannot be established, stop and revise the contract before execution.

Inspect the exact target allowlist; do not blindly accept defaults or include `validate.sh`:
mutated arguments can launch a full gate. The campaign's duration is checked between batches
and replay/cleanup can extend it; host violations are recorded, not necessarily immediate
abort conditions. Do not present telemetry as enforcement. Use existing supervision and
verified timeouts/cleanup that satisfy the approved stops, or hold execution as unsupported.  [Unverified — no citation]
Recheck live/local ownership immediately before launch. No campaign is authorized by this doc.

## Replay, classify and hand off

Replay each candidate on the pinned revision, then minimize using the **same semantic
predicate**, not a weaker error hash/exit code. Verify clean controls still pass and failing
controls still fail. If the existing minimizer cannot preserve the predicate, retain the
unminimized observation and name that limitation; do not invent semantic coverage.
Retain exact argv/operation sequence, input/corpus snapshot, source/tool versions, sanitized
environment/dependency versions, outputs and relevant timing/interleaving plus before/after
state. A seed alone is insufficient for stateful or concurrent replay. Report flakiness honestly.

Dedupe by target + violated invariant + root cause against live issues, PRs, prior results and
active local owners; hashes are candidate grouping only. For **every** counterexample record
an accountable owner, evidence link, replay result, severity/real-world impact and disposition:
new defect, known rediscovery, expected refusal, flaky/inconclusive observation, or faulty oracle.
Promptly surface critical/high impact for review; defer lower severity unless selected. Link
back to the Radar tracking context or existing results issue within authorized destinations;
otherwise return the proposed backlink/update for approval. Do not silently file duplicates.

A report may contain zero defects. State exercised, excluded and unresolved coverage and
budgets actually used; a clean bounded run never proves an entire bug class eradicated.
Remediation is separately approved through existing start-task/review ownership. Preserve
before/after reproduction evidence if a later authorized fix is made. This skill never
implicitly authorizes that fix, a CI addition or consequential follow-up.

## Held pilot specification: merge-batch stale captured state

Source: [Radar #1138](https://github.com/HiQS-Labs/XYZ-forge/issues/1138) and
[#1143](https://github.com/HiQS-Labs/XYZ-forge/issues/1143); source inspected at
`e93214feb45dc95f32ee2d9080c1d4f6f3b8ab69`. Relevant existing seam:
`skills/2-daily/merge-cleanup/scripts/batch_record.py` (`extend`, `landed`, `qa_pending`,
`continuable`) and `merge_cleanup.py` batch selection/sweep inputs.

**HELD, not executable:** #1140 batch persistence/orchestration and #1136 accepted-start work
are active/excluded at the 2026-10-18 intake inspection. #1133 stays paused. Refresh tracker and
local ownership before reconsidering; first reuse #1140's eventual counterexamples and landed
revision. No competing pilot, adapter, fixture or bug repair is part of this skill delivery.

Proposed hypothesis: refresh of an unlanded PR updates overlap inputs without rewriting landed
history; a fresh execution cannot hide matching pending QA. Oracle compares refreshed planned
file sets to the observed PR snapshot, preserves landed order/merge identity and requires QA
coverage for all landed identities before continuation. A failed post-merge refresh must
retain verified merge identity; repeated equivalent reads/recomputations preserve semantics.  [Unverified — no citation]

Controls specified, **not run**: reuse #1073's stale-overlap counterexample (changed unlanded
file set) and #1084's QA-bypass/merge-identity-loss evidence as known-failing historical controls,
after resolving their exact pre-fix revisions/artifacts. Clean controls: unchanged unlanded file
set and fully QA-covered landed set with no pending PR changes; expected stable semantics and
no pending QA. Reuse existing gh436/gh534 assets only; no permission to add CI cases/assertions.

Proposed budget for later approval: at most 12 declared operation sequences, 30 seconds per
sequence and 10 minutes total, with the last 4 minutes reserved for replay/minimization/cleanup;
stop after 3 consecutive sequences with no new signal or any safety/observation failure.
Use sanitized offline tracker snapshots in an owned standalone clone, no live merge/push/API
writes. Preserve each snapshot and operation/interleaving trace; seed-only replay is rejected.
A structured-state adapter and predicate-preserving replay/minimization integration are missing:
generic campaign argv mutation cannot provide them. These are future separately reviewed work;
until suitable existing assets are identified, the pilot stays held even if ownership clears.
```
- Definition of Done: Every issue requirement in the supplied source snapshot is implemented within the docs-only scope, with accurate existing checks and no executable changes.

## Final review context and questions

Read the complete committed diff from e93214feb45dc95f32ee2d9080c1d4f6f3b8ab69, the full skill,
its Radar/ATE/index pointers, PROJECT/2-WORKING/GH-1143-DEFECT-CAMPAIGN.md and
TESTS-RESULTS/2026-10-18+GH-1143/manual-review.md, pdda.txt, route.txt, provenance.jsonl.
The source snapshot below is supplied for offline review; do not require network retrieval.
Read existing source functions referenced by the skill to check limitations, not just prose.

Operational envelope: a thin documentation-only skill. No scripts, adapters, schedulers,
registries, workflows, tests, fixtures, campaign execution or bug fixes. No installation,
merge, deployment or clone cleanup. Publication is authorized as DRAFT to development after
normal docs gates/review. Be surgical and commensurate; no enterprise machinery or new tests.

1. Omission-diff: does each issue requirement have an equivalent, including suitability,
   explicit hypotheses/oracles and controls, budgets/stops/isolation, precise disablement,
   same-predicate replay evidence, ownership/root-cause dedupe and accountable dispositions,
   null-result coverage limits and separate remediation/per-individual-CI-case approval?
2. Are gen4/ATE defaults/flags, domain_oracles/repro_builder limits and missing stateful adapter
   represented honestly? Is the HELD pilot concrete without competing with #1140/#1136 or #1133?
3. Do both consumer paths preserve Radar recommendation-only and no reciprocal asset-to-Radar
   pointer semantics? Does the diff avoid duplicate runtime machinery or incidental changes?
4. Do the actual docs route, existing validator, PDDA result and manual walkthrough substantiate
   the claims, clearly separated from behavioral campaign safety and full/promotion qualification?

Plan review originally used 3/3 rounds; final reviewer recommendation PASS at d555b12f was
mechanically rejected exit4 review-body-rewritten. Operator then explicitly approved "Yes
override procedural stop." That failure remains retained. No plan cap reset or success claim.
This is the separate normal FINAL implementation review, cap three rounds. Review only; writes
limited to this relay file, never run tests/campaigns. Report concrete findings with citations;
otherwise Approve as a non-executable artifact. Preserve ALL prior body bytes, append the new
review block immediately before the final next-turn marker and keep that marker last.

## Issue #1143 source snapshot (fetched 2026-10-18)

## Status: proposal only
User requested thoughts, light–medium reconnaissance and an issue. This does **not** authorize implementation, campaign execution, test additions, remediation or activation.

## Recommendation
A thin skill (working name: **defect-campaign**) could turn a selected Radar finding into a bounded, approved experiment and then a remediation handoff. Reuse the existing engines and workflow. Do not build another scheduler or autonomous repair system.

The valuable connection is: **Radar cluster → suitability check → explicit hypothesis/oracle → bounded discovery → reproducible counterexample → severity/ownership decision → separately authorized fix**. Radar alone cannot establish a bug or permission to fix it.

## Recon / prior art
- [#945](https://github.com/HiQS-Labs/XYZ-forge/issues/945) already proposes the verification-asset handoff; [PR #946](https://github.com/HiQS-Labs/XYZ-forge/pull/946) merged that into development as e888594fd3e3670a6be2eecdaecc4b20af549c1b. Extend this recommendation-only seam, do not duplicate it. The issue remaining open does not mean its PR never landed.
- [ATE](https://github.com/HiQS-Labs/XYZ-forge/blob/development/skills/4-occasional/ate/SKILL.md) means Automated Testing Environment. Existing [adaptive_ate.py](https://github.com/HiQS-Labs/XYZ-forge/blob/development/utils/py/adaptive_ate.py) supplies constraint-aware pairwise grids; [fuzz_engine.py](https://github.com/HiQS-Labs/XYZ-forge/blob/development/utils/py/fuzz_engine.py) supplies seeded argv mutation/replay.
- [domain_oracles.py](https://github.com/HiQS-Labs/XYZ-forge/blob/development/utils/py/domain_oracles.py) covers containment/state/idempotence/crash-recovery predicates; [repro_builder.py](https://github.com/HiQS-Labs/XYZ-forge/blob/development/utils/py/repro_builder.py) supplies argv/environment minimization.
- [gen4_campaign.py](https://github.com/HiQS-Labs/XYZ-forge/blob/development/utils/py/gen4_campaign.py) already orchestrates disposable clones, targets, seeds, bounds, telemetry, clustering and optional healing. **Synthesis defaults on.** Discovery must explicitly disable synthesis and healing/model-command options; omit automatic filing options. Inspect exact current CLI safety before any future execution. Its default targets exclude validate.sh because mutated arguments previously launched a full gate.
- [#435](https://github.com/HiQS-Labs/XYZ-forge/issues/435) provides a campaign precedent using offline stubs and independent clones. [#460](https://github.com/HiQS-Labs/XYZ-forge/issues/460) already describes counterexample-to-disposition flow.
- Older SOP/campaign instructions for automatic new regression tests, full preflight or fixes must not override the current per-case approval moratorium or #1131.

## Matching rule: select the tool by problem class
- CLI grammar/input boundaries: bounded seeded argv fuzzing
- Configuration/environment interactions: constrained ATE/pairwise scenarios
- State transitions, resume and concurrency: structured operation sequences with explicit semantic predicates
- Documentary drift, prioritization or strategy: analysis; do not force these into fuzzing

A report match needs a specific target, falsifiable invariant, safe fixture and useful oracle. Generic containment checks cannot prove correct business behavior. Pairwise coverage does not prove higher-order sequence coverage.

## Proposed campaign contract
1. Capture Radar report/cluster, exact code SHA, live issue/PR ownership, prior results and known counterexamples. Distinguish source revision from tracker timestamps.
2. Specify hypotheses, allowed mutations, expected refusals, semantic oracle/falsifier, known-failing and clean controls, fixture, seed/corpus, commands, dependencies and wall-time/case limits.
3. Obtain approval for that bounded execution and its permitted effects. Use disposable standalone full clones, sanitized environment, offline stubs and owned process-group cleanup. A discovery phase may mutate disposable fixture state only where declared; no production/shared checkout effects.
4. Reuse existing campaign facilities with synthesis/healing and automatic issue filing off. Stop on containment/identity violations, surviving processes, invalid observations, missing dependencies, exhausted budgets or repeated no-new-signal results. Reserve time for replay/minimization/cleanup.
5. Replay and minimize using the **same semantic predicate**. Retain exact inputs, corpus snapshot, code/tool versions, environment, outputs and timing where relevant. A seed alone is insufficient for stateful/concurrent behavior.
6. Dedupe by target + invariant + root cause against issues, PRs and active local owners, not only error-text hashes. Separate new defects, known rediscoveries, expected refusals, flaky/inconclusive observations and faulty oracles.
7. Report severity and real-world impact before remediation. Critical/high findings get prompt review; lower-severity findings remain deferred unless selected. Use existing start-task/review ownership for an explicitly authorized fix.
8. Preserve before/after reproduction evidence and link the disposition back to the Radar tracking context or existing results issue. A clean bounded run does not prove an entire bug class eradicated.

## Pilot candidate and current overlap
[Radars #1138](https://github.com/HiQS-Labs/XYZ-forge/issues/1138) identify merge-batch stale captured state. Relevant seams are batch_record.py extend/landed/qa_pending/continuable and driver selection/sweep-input construction. Known controls include [#1073](https://github.com/HiQS-Labs/XYZ-forge/issues/1073) stale file overlap and [#1084](https://github.com/HiQS-Labs/XYZ-forge/issues/1084) QA bypass/merge-identity loss.

**Do not launch a competing pilot now:** active [#1140](https://github.com/HiQS-Labs/XYZ-forge/issues/1140) work on Mac mini is changing batch persistence/orchestration. First reuse its eventual counterexamples and final implementation, or select another unowned class. [#1136](https://github.com/HiQS-Labs/XYZ-forge/issues/1136) accepted-start repair is also active and excluded.

Candidate hypotheses, after ownership clearance:
- Refreshing an unlanded PR must update overlap inputs without rewriting landed history
- A fresh execution cannot hide matching pending QA
- A failed post-merge refresh cannot discard a verified merge identity  [Unverified — no citation]
- Repeated equivalent read/recompute operations preserve semantics

Existing gh436/gh534 checks are assets to reuse, not permission to add cases. This pilot likely needs a small structured-state adapter/oracle: name and review that gap instead of claiming argv mutation already covers it.

## Guardrails / anti-goals
- No automatic new CI suites, cases, assertions or parametrizations; each requires explicit operator approval
- No repeated full development suite under #1131; preserve current promotion policy
- No automatic fix, push, merge, deployment, issue closure or schedule activation
- No ledger transport redesign: [#923 results](https://github.com/HiQS-Labs/XYZ-forge/issues/923#issuecomment-6252388515) rejected the proposed ordering change on measured benefit/safety
- No new general engine, registry, gate, daemon or model dependency
- No silent adoption of stale SOP permissions
- This issue does not change any existing holds or authorize work on #1133

## Initial design acceptance
- [ ] One source-grounded pilot specification with ownership/duplicate check
- [ ] Tool fit and missing domain oracle/adapter identified
- [ ] Known-failing and clean controls specified before execution
- [ ] Explicit budgets, stop conditions, isolation and reproducibility contract
- [ ] Every counterexample has an accountable disposition and evidence link
- [ ] Honest null result accepted; exercised/excluded/unresolved coverage stated
- [ ] Existing machinery reused with no new CI policy or automatic remediation

The main cost is trustworthy domain predicates, not launching a fuzzer. This is worthwhile if it reduces repeated manual triage and preserves findings; it is not worthwhile if it adds another orchestration layer without better evidence.

— dot


## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: PASS
Basis: Ship the non-executable documentation artifact within the authorized DRAFT-to-development scope. The full skill and supplied issue snapshot have equivalent requirements; no blocking omission or additional pre-existing defect was found in the artifact sweep. Referenced implementation seams and consumer pointers support the stated limitations. Reversibility: Easy (remove/revert these instructions and pointers). This approval is not campaign authorization, runtime-safety proof, merge readiness or promotion qualification.
swept file: yes

- [Pass] Suitability and ownership precede execution: `skills/4-occasional/defect-campaign/SKILL.md:16` pins source/report/prior evidence separately from tracker observation time, checks active ownership and holds unknown/overlapping work. Lines 24–37 select tools by problem class and explicitly reject generic containment/argv mutation as stateful business-semantic coverage. No new engine, adapter, scheduler, registry, workflow, test or fixture is introduced; the committed path delta contains only 15 documentation/evidence/ledger paths. Read-only probe: `python3 .relay-scratch/tmp/read_diff.py` → exit 0, decisive output includes only ARCHITECTURE/CHANGELOG, GH1143 PROJECT/results/relay documents, releases.db/sql and the three skill documents; `diff lines 1299`. This scratch-only object reader inspected base e93214fe through seeded HEAD fa215ee3 without invoking git.
- [Pass] Execution contract and disablement are explicit at skill lines 47–89: hypotheses/oracles, failing/clean controls, declared mutations, sanitized fixtures, finite budgets, replay/cleanup reserve, standalone clones, descendant cleanup, stop conditions and fresh approval. `utils/py/gen4_campaign.py:365` defaults to suite; `:376` and `:399` implement no-synth/inversion; `:229` gates healing on its optional command. ATE filing is conditional on `args.gh_repo` at `utils/ate/scripts/run_variations.py:588`. Skill lines 76–88 require explicit run/no-synth, omitted model/healing/filing commands and holding unsupported supervision. Its warning that duration is batch-checked and host violations are recorded matches `gen4_campaign.py:152` and `:188`; its nested-session warning matches `proc_group.py:124` and `fuzz_engine.py:245`. These are static source checks, not exercised safety guarantees.
- [Pass] Replay/results preserve the source requirements at skill lines 93–113: same semantic predicate, retained complete inputs/corpus/environment/state/timing, root-cause/ownership dedupe, accountable evidence-linked dispositions, severity triage, authorized backlink, honest bounded null results and separately approved remediation. `utils/py/repro_builder.py:120` and `:123` check return code and optional substring; skill lines 34–37 and 95–96 accurately decline to treat that as arbitrary semantic minimization. Per-individual CI-case approval and prohibition on inherited older permissions are explicit at lines 64–72; no ledger transport redesign is proposed.
- [Pass] The held pilot is concrete without implying execution: skill lines 119–147 name the pinned source, batch_record/selection seams, hypotheses, unrun historical and clean controls, 12 sequences/30 seconds each/10 minutes total with four minutes reserved, ownership exclusions and missing predicate integration. `batch_record.py:79`, `:95`, `:105`, `:110` and `merge_cleanup.py:1746` are the actual existing seams. Lines 123–126 retain #1140/#1136 exclusions and #1133's pause; line 147 keeps the pilot held even after ownership clears. Historical control revisions/artifacts still need resolution, as line 136 explicitly states.
- [Pass] Consumer handoff stays recommendation-only: `skills/3-weekly/radar/SKILL.md:802` retains "Radar recommends and never executes" and the no-reciprocal-pointer rule; its addition at :808 recommends optional specification. `skills/4-occasional/ate/SKILL.md:20` points to defect-campaign and overrides its older filing flow for this mode, without redirecting the asset into a Radar rerun. `ARCHITECTURE.md:132` indexes the new skill. A separate read-only Python equality assertion exited 0: the embedded skill exactly equals the on-disk skill. A read-only SQLite query (`select gh_number,section,doc_path,rating_pri,rating_sev,rating_appeal,rating_effort from roadmap_items where gh_number=1143`) returned one In progress row, the correct working-doc pointer and 55/40/50/85; integrity_check returned ok. Base/candidate database comparison showed only generation, one GH1143 roadmap row, five operation receipts and four work events changed.
- [Pass] Retained verification is appropriately scoped: `TESTS-RESULTS/2026-10-18+GH-1143/manual-review.md:5` records the existing validator and textual consumer/negative-completeness walkthrough; its closing paragraphs distinguish docs consistency from campaign safety. `pdda.txt` ends "PDDA run complete: no errors, 57 warning(s)" and records the LLM readiness skip; `route.txt` records docs_only=true, route=docs, tier=1, full_required=false, consistent with `utils/ci-route.sh:65`. `provenance.jsonl` retains the procedural review rejection and f135518a documentation checks. `PROJECT/2-WORKING/GH-1143-DEFECT-CAMPAIGN.md`, sections "Blocked handoff" and "Operator override", preserve the failed plan attestation and explicit override rather than relabeling that failure as successful QA.
- [Unverified — needs clone run] No validate.sh, test/*.sh, pytest, executable fixture or campaign ran during this review. Recorded producer docs checks were inspected, not rerun here; no full-suite, behavioral campaign, hosted exact-head or publication result is claimed. Future campaign ownership/control evidence must be refreshed before any separately approved execution. The harness owns final post-turn attestation and the file-scoped commit.

Relay closed (Approved), no further review turn needed. Returning the completed token to operator; proceed only within the authorized documentation/DRAFT publication scope.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
