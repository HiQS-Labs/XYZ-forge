# RELAY · GH854 gate disposition plan QA round2
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-01.
-->

NEXT: Producer
STATUS: Approved
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
6. **Commit only the relay file** (`relay(gh854-gate-disposition-plan-qa-round2): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **plan-review-packet.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-01

### Artifact — plan-review-packet.md
```
Review the bounded implementation plan below. Do not run tests or mutate source. This is independent plan QA, not implementation. Evaluate minimality, preserved runtime coverage, exact registry/canary/subsystem contract, falsifiable acceptance, operator deferral triggers, reversibility and ratings. Exact historical causes remain unknown and are intentionally deferred. The user explicitly approved these dispositions. No broad audit, invented new checks, or speculative runtime fixes. Reviewer must report Approved or concrete actionable findings; final QA and full task-branch push gate remain separate.

---
gh_issue: 854
source: https://github.com/HiQS-Labs/XYZ-forge/issues/854
title: "GH-854: execute approved gate dispositions"
status: "Proposed (1-INBOX — plan review)"
created: 2026-10-01
updated: 2026-10-01
owner: "XYZ Forge maintainers"
goal: "Apply the operator-approved check dispositions without changing runtime behavior."
doc_type: bugfix
---
# GH-854 — execute approved gate dispositions

The [canonical ordered stabilization list](https://github.com/HiQS-Labs/XYZ-forge/issues/854#issuecomment-5915099783) owns overall progress. This bounded execution document owns only the approved registry change; it does not duplicate the full stabilization plan or October 8 audit.

## Decision and evidence
Operator requested each unresolved item be tracked and deferred until a true blocker, then authorized executing the triangulated dispositions. #916 tracks unexplained live relay exit6, #917 the installation registry15/16 diagnostic, and #918 the Gen4 shared-root oracle16/1 failure. #909 stays closed: #910 repaired witnessed completion-record loss, and its existing regression coverage stays. Deferral accepts reduced automatic coverage for unrelated changes; it is not proof of harmlessness or root-cause resolution. See each issue for exact resume triggers.

Base development: `1b40d57c36c70eb045341ec95403de93ba056b92`. The [bounded source recon](../../TESTS-RESULTS/2026-10-01+GH-854/dispositions/recon.md) records consumers, preserved runtime contracts, observed failures and unknowns. Registry410 before change. Every affected suite is outside Small; domain-oracle additionally appears in the ATE selection list. Ubuntu names the registry suite in --skip; unregistered skips are rejected, requiring a companion workflow edit. No gate runs in this valuable task clone.

## Preservation, reversibility and scope
Easy to reverse: restore the two TESTS entries, remove their EXEMPT entries, restore the ATE member and corresponding Ubuntu skip together. Keep both suite files and all runtime modules byte-for-byte. Keep Small, containment, token ownership, commit-bound attestation, resume, escalation and completion regression coverage. Do not add tests, guards, runners, lanes, telemetry stages or runtime fixes. No module deletion, data migration, fixture repair, automatic audit, merge, deploy or clone cleanup is part of this change. Existing #836 D2 RELAY_SELF_SUFFICIENCY_SKIP=1 applies to subsequent local qualification; direct validate defaults stay unchanged.

## Ordered execution and acceptance
1. Cross-model consult and independent Codex plan QA -> disposition scope and companion selections reviewed; three-round QA cap.
2. Admit the exact roadmap row; remove registry-lock-concurrency.sh and gh-gen4-phase1-domain-oracles.sh from TESTS; add explicit gh306 exemptions; remove oracle from ATE subset and registry from Ubuntu skip; correct obsolete ci-local/ci-workflow assertions/comments -> registry408, no runtime change.
3. In a separate disposable full clone, run existing gh306, gh35 tier coverage, gh379 and ci-workflow checks; witness gh306 red by omitting exemptions, then restore saved bytes -> red names missing entries, green with explicit exemptions; record provenance and identity.
4. Independent final Codex QA of final diff and focused evidence -> Approved within three rounds; then one full task-branch push gate under caffeinate, serial on host, intact identity, zero retry activity in telemetry and transcript, not merely exit0 -> committed full evidence and exact-head hosted result.
5. Ready PR to development and #854 update -> operator landing decision remains required by #854. After approved landing, two clean development4-wide runs in fresh clones; stop on failure/drift. Task-branch gate never increments development count.

## Deferred follow-ups and unchanged counters
[#916](../1-INBOX/GH-916-LIVE-RELAY-DEFERRED.md), [#917](../1-INBOX/GH-917-INSTALL-REGISTRY-DEFERRED.md), [#918](../1-INBOX/GH-918-GEN4-ORACLE-DEFERRED.md) remain deferred/open. Live compatibility can be run deliberately with existing opt-in; retained installer/oracle suites can be run directly when their actual contracts change. No independent expected October8 registry count is invented. #854 local1/3, hostedPR-closed3/3; #853 quiet interval remains unmet. Automation stays paused.

## Rating
70/50/50/85: current operator-selected CI unblock, bounded coverage tradeoff, neutral appeal, small selection change. No override. This row covers disposition implementation, not closing all umbrella acceptance criteria.


## Source recon
# Recon Map — existence and gate scope of four failed checks

Source: frozen development landing 9ecb344f126c613d7fcc8a0f5d22145a954c6d31. GitHub refreshed in this assessment: development 1b40d57c36c70eb045341ec95403de93ba056b92; compare shows one reconciliation commit, no examined runtime/test changes. This is a bounded operator-requested value assessment, not the October 8 full-suite audit. No tests or gates launched, no source changes made.

## Triangulate card
SUBJECT: whether four failed checks justify blocking relay, consult, and marathon work.
CELL: reversible x crossing -> recon-lite + falsify. Registry removal is reversible; it reduces coverage across landings and must remain explicit. No authority or runtime-state migration proposed.
GROUND: main lane traced completion telemetry and ATE oracles; two read-only lanes traced live relay and installation registry consumers. Graph Verify project Users-noelsaw-Documents-GH-Repos-XYZ-forge generation2026-09-30T07:57:23Z; graph was a lead, frozen source confirmed material claims. Coverage no recorded gaps for main paths; vendor line285 parse gap read by registry lane. Graph omissions for nested Python emitters required source fallback.
FALSIFY: 'all four are core workflow correctness checks' disproved by real consumers. 'All are useless invented tests' also disproved: one real model compatibility exercise, a demonstrated completion lost-update, real registry consumers, and a real optional Gen4 campaign consumer exist.
SMALLEST: retain valuable scoped coverage; stop equating full-registry membership with product severity. No replacement framework or new tests.
UNKNOWNS: exact historical relay exit6, missing registry writer outcome, and zero-state changed path/holder remain unknown. No claim they are harmless; unknown attribution does not establish critical-path importance.

## 1. relay-self-sufficiency.sh
- Source test/relay-self-sufficiency.sh:4-18,95-156; test/fixtures/minimal-relay.md:8-38.
- One real agy/Codex leaf-shim turn on a fixed tiny fixture, RELAY_WORKTREE_ISOLATION=0. Not the generated scaffold, relay supervisor, consult orchestration, or marathon sequencing/recovery.
- Unique value: real installed CLI/model follows the turn prompt. Deterministic stub suites cannot substitute completely for this live compatibility observation.
- Weakness: assertion A seeds release away from claude-a at106-108, then tests claimer !=claude-a at146-149. This does not independently prove a correct claim/release cycle. No mutation experiment was run here; direct logic finding.
- Existing behavioral coverage: test/agy-turn.sh:111-156 (good turn, containment, committed off-lane edits, spaces, empty output); test/codex-turn.sh:84-126 (token commands, peer handoff, ownership refusal, containment); test/consult.sh:50-95 (WIP preservation, advisor containment, cleanup, partial/all failures).
- Policy: relay-automation/README.md:45-71 and source header: four normal wrappers default-skip; changed shims/shared prompt/fixture owe recorded live evidence. Direct validate does not inherit the wrapper default.
- Verdict: existence justified as targeted live compatibility check. Universal blocker not justified. Preserve meaningful containment and attestation checks; do not call exit6 an off-lane edit without its guard evidence.

## 2. xyz-completion.sh
- test/xyz-completion.sh:1-12,146-197 tests real completion writer concurrent atomic record preservation. Sixteen successful writers/15 records led to controlled stale-lock successor deletion repro and repair #909/#910.
- Real callers: utils/py/relay_drive.py:489-504 and utils/py/marathon_drive.py:1323-1335. Emitters invoke subprocess and do not use its return code to decide approval/advancement. Relay successful terminal status is bound to attestation before emit at734-754; marathon bind_candidate and durable approval fields precede emit at2710-2738.
- relay-automation/README.md:146-186 defines XYZ.json as human-facing completion telemetry. Tick events/attestation/gate receipts are separate state. Consult source has no direct writer reference in the examined entry point.
- Harm: missing completion history/status reporting, not demonstrated source-code loss or lost approval state. Important data-integrity defect, not a proven execution-critical outage. Fixed already.
- Existing related suite gh358-lock-instrumentation tests instrumentation/budgets; it is not a replacement for this actual concurrent writer assertion.
- Verdict: keep regression coverage; strong existence justification. Prioritize it for telemetry/shared writer changes. No basis to delete a useful deterministic check merely because it exposed a real defect.

## 3. registry-lock-concurrency.sh
- test/registry-lock-concurrency.sh:20-55 launches16 concurrent install.sh calls twice, not relay turns. Stdout/stderr discarded; waits ignored. Missing row alone cannot distinguish process failure, permitted lock timeout, or lost update.
- install.sh:192-208,297-333: registry best effort, --no-register supported, lock timeout may skip registration while install remains usable.
- Consumers: relay-automation/xyz-sync.sh:167-204 bulk update selection; marathon-ls.sh:174-200 cross-repo listing; utils/collect-relay-system.sh:49-86 aggregation; utils/hq/hq-lib.sh:243-263 lookup plus filesystem fallback.
- Runtime location: skills/1-hourly/relay-xyz/find-harness.sh:120-181 resolves explicit/local/self paths; start-marathon skill135-153 uses it; consult skill46-65 uses git root/local .xyz. These paths do not require a registry row.
- Loss can hide an install from future updates, an operational risk. It does not directly corrupt or halt an in-flight marathon.
- Modern xyz-vendor.sh:396-419 is a separate writer, not exercised by this test. test/xyz-vendor.sh:98,277-282,341 has registration/idempotence/no-register/removal but not concurrent coverage.
- Verdict: legitimate installer stress check, low routine workflow priority. Retain targeted/manual coverage; recommend removing universal blocker role under existing non-Small policy. Reduced concurrency coverage must be disclosed.
- Historical GH72 citation belongs to migrated numbering; current public #72 is unrelated. Original red receipt not recovered; do not fabricate a current issue link.

## 4. gh-gen4-phase1-domain-oracles.sh
- test/gh-gen4-phase1-domain-oracles.sh:30-40 invokes embedded module self-tests,53-131 repeats positive/negative CLI controls,152-156 checks validate --print-mode against shared ROOT while discarding stdout/stderr.
- Crash recovery uses test-written holder.py/recover_good.py/recover_naive.py (105-129), not marathon recovery. Passing this proves an oracle distinguishes synthetic examples, not that a marathon recovers correctly.
- utils/py/domain_oracles.py:203-232 before/after tree digest + handle scan does not attribute concurrent activity. Its body run_suite446-531 separately repeats toy +/- examples. The last real-root assertion can be affected by other suites; exact historical failure remains unknown.
- Real consumer utils/py/gen4_campaign.py:46 imports host_identity;72 fuzzes the oracle CLI. This is Gen4 tooling, not relay/consult/marathon entry-point enforcement. Main ATE skill invokes run_variations.py; #909 evidence uses ate_variations, not this oracle as acceptance.
- The shared Python module must not be deleted just to retire the gate suite: campaign depends on it.
- Verdict: optional ATE-tooling self-test earns targeted coverage, not a universal release block. Recommend unregister/exempt this non-Small flaky suite while retaining its file/module. Loss of CLI self-test coverage on unrelated changes is explicit, not a claim other tests are identical.

## Measured cost and priority limits
Accepted local development run at57bd97af had durations: completion7.134s, registry2.892s, live relay57.030s, domain oracle7.862s (existing committed provenance5b4c6e2a). These are overlapping worker durations, not additive wall-time savings or current benchmarks. Main problem is false/opaque blocking and repeated full-run investigations, not these four suites monopolizing execution time.
All four absent from SUBSYSTEM_TESTS_small at utils/ci-route.sh:38. Telemetry and ATE suites are separately in focused subsystem lists at27-28. Small membership is policy classification, not itself proof of importance. Medium/Large hosted qualification still runs full registry; this assessment does not silently change that contract or reinterpret old failures as clean.

## Recommendation and boundary
One directly samples live core behavior, one protects supporting completion telemetry, two protect secondary installation/ATE tooling. None of the four observations establishes an unresolved current corruption of code, approval, or marathon resume state. The evidence does not rule such defects out; the priority burden is unmet.
Preserve core worktree/allowlist safety, token ownership, attestation-to-commit binding, pause/resume and failure escalation coverage. Use existing scoped suites and representative skill-driven work. No wholesale rewrite, new gate machinery, or broad automatic audit. Narrow registry changes need their normal review/evidence; no test registration changed in this assessment.

## Consult disposition and retry context
Both Codex and agy answered. Include a narrow AGENTS.md:413-414 correction to remove the stale claim that registry concurrency runs locally; no macOS/Ubuntu policy change. Correct the validate.sh --skip usage example to a still-registered suite (acorn-extract.sh). Codex requested gh35 focused check, zero-retry transcript/telemetry acceptance, and adjacent workflow prose; all in plan. Initial QA substantive verdict PASS was rejected because the producer changed plan text during the turn. That text was backed up/restored; inputs are now frozen. Review this final plan for concrete omissions. Do not run mutation-heavy tests. Do not change source or the plan.
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

### Reviewer · Round 1
VERDICT: PASS
Basis: Approved for bounded implementation. Reviewed the entire embedded plan, source recon, consult disposition and deferred follow-ups against the Setup review criteria. No actionable omission or pre-existing defect found in the reviewed artifact. This approves the plan only; final implementation QA, clone-run evidence, push gate and operator landing decision remain separate.
swept file: yes

- [Pass] Minimality and preservation: “Keep both suite files and all runtime modules byte-for-byte” and “Do not add tests, guards, runners, lanes, telemetry stages or runtime fixes” bound the change to selection and truthful companion text. Existing completion regression coverage remains explicitly retained. No speculative historical root-cause fix is authorized.
- [Pass] Exact selection contract: execution step 2 names both TESTS removals, explicit gh306 exemptions, the ATE removal and Ubuntu skip removal. Source reads support the companion edits: utils/ci-route.sh:28, validate.sh:647,680,820, .github/workflows/ci.yml:493-495, and test/ci-workflow.sh:429-432. The consult paragraph additionally identifies the AGENTS coverage claim and skip usage example.
- [Pass] Static count probe: command below exited 0; decisive output was `current=410 planned=408 targets=['gh-gen4-phase1-domain-oracles.sh', 'registry-lock-concurrency.sh']` and `small_contains_targets=False`. This measures current selection text, not execution success.
  ```sh
  export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
  python3 - <<'PYPROBE'
  import pathlib, re
  s=pathlib.Path('validate.sh').read_text()
  m=re.search(r'^TESTS=\(\n(.*?)^\)',s,re.M|re.S)
  assert m and m.group(1).strip()
  names=re.findall(r'^\s*"([^"]+)"',m.group(1),re.M)
  targets={'registry-lock-concurrency.sh','gh-gen4-phase1-domain-oracles.sh'}
  assert targets.issubset(names)
  print(f'current={len(names)} planned={len([n for n in names if n not in targets])} targets={sorted(targets)}')
  print('small_contains_targets=' + str(any(t in re.search(r'^SUBSYSTEM_TESTS_small="([^"]+)"',pathlib.Path('utils/ci-route.sh').read_text(),re.M).group(1).split() for t in targets)))
  PYPROBE
  ```
- [Unverified — no citation] Falsifiable acceptance: steps 3–5 require the existing focused suites, a witnessed missing-exemption red control, saved-byte restoration, committed provenance, intact clone identity, final independent QA and “zero retry activity in telemetry and transcript, not merely exit0”. They keep task-branch evidence separate from the two remaining development runs and require stopping on failure/drift.
- [Pass] Coverage tradeoff, reversibility and deferral: “restore the two TESTS entries ... restore the ATE member and corresponding Ubuntu skip together” gives a complete Easy rollback. “Reduced automatic coverage for unrelated changes” is explicitly accepted without claiming harmlessness. Each embedded recon section retains unknown attribution; the linked local #916/#917/#918 docs state concrete user-impact resume triggers. The 70/50/50/85 rating has a bounded rationale and no override.
- [Unverified — needs clone run] Focused-suite green, actual gh306 red control, final runtime byte preservation, zero-retry full gate and exact-head hosted result are future acceptance work, not results obtained in this turn. No validate, test suite, pytest or executable fixture was run.

Evidence scope: graph Verify metadata for the canonical XYZ project reports generation 2026-09-30T07:57:23Z and no recorded coverage issue for the seven selection/companion paths checked; that does not attest this worktree. Material selection assertions above use direct local source reads. No broad runtime audit or external issue-state verification is claimed.

Done — relay closed (Approved), no further review turn needed. Token handoff to Producer / claude-a for the harness and authorized implementation.

### Producer · protocol correction before final allowed plan turn
Both prior substantive reviews found no plan defect. The first turn was rejected for a producer edit during QA (preserved/restored); the second reviewer released the token to claude-a before the shim could close it, causing close-mismatch. No production changes have occurred.
For this final allowed plan turn, confirm the existing plan and report your verdict in this relay file. **Do not call tick release, tick done, or any other token mutation. Leave ownership with codex. The codex-turn shim owns terminal tick done and the supervisor validates the close. Do not claim the token was handed back.** Only edit this relay file. No source changes or tests. The goal is a valid independent plan receipt so the already-approved scope can execute. This is a bounded protocol correction, not permission to expand review scope or reset the three-turn cap.

### Reviewer · Round 3
VERDICT: PASS
Basis: Approved for bounded implementation. Reviewed the entire embedded plan, source recon, consult disposition and prior turns against the Setup criteria using the SWE rubric. No actionable omission or pre-existing defect found in the reviewed artifact. This approves plan readiness only.
swept file: yes

- [Pass] Minimality and preservation: “Keep both suite files and all runtime modules byte-for-byte” and “Keep Small, containment, token ownership, commit-bound attestation, resume, escalation and completion regression coverage” explicitly preserve the required contracts. “Do not add tests, guards, runners, lanes, telemetry stages or runtime fixes” excludes speculative repairs.
- [Pass] Exact selection contract: step 2 specifies both TESTS removals, gh306 exemptions, ATE removal and Ubuntu skip removal. Local source reads locate the targets at validate.sh:647,680, ATE at utils/ci-route.sh:28, Ubuntu skip at .github/workflows/ci.yml:494, obsolete assertion at test/ci-workflow.sh:429-432, and stale prose at ci-local.sh:26,261 and AGENTS.md:414. The consult paragraph explicitly includes the AGENTS correction and skip example at validate.sh:771. No missing companion selection found in this bounded review.
- [Pass] Static selection measurement: the command below exited 0; decisive output was `current=410 planned=408 small_contains_targets=False`. This measures text, not gate success or a witnessed red control.
  ```sh
  export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
  python3 - <<'PYPROBE'
  import pathlib,re
  s=pathlib.Path("validate.sh").read_text()
  m=re.search(r"^TESTS=\(\n(.*?)^\)",s,re.M|re.S)
  assert m and m.group(1).strip()
  names=re.findall(r'^\s*"([^"]+)"',m.group(1),re.M)
  targets={"registry-lock-concurrency.sh","gh-gen4-phase1-domain-oracles.sh"}
  assert targets.issubset(names)
  r=pathlib.Path("utils/ci-route.sh").read_text()
  small=re.search(r'^SUBSYSTEM_TESTS_small="([^"]+)"',r,re.M).group(1).split()
  print(f"current={len(names)} planned={len([n for n in names if n not in targets])} small_contains_targets={bool(targets.intersection(small))}")
  PYPROBE
  ```
- [Unverified — no citation] Falsifiable acceptance: step 3 requires “witness gh306 red by omitting exemptions, then restore saved bytes” and records provenance/identity in a disposable full clone. Step 4 requires independent final QA, committed full evidence, “zero retry activity in telemetry and transcript, not merely exit0” and an exact-head hosted result. Step 5 separates task-branch evidence from development runs and says “stop on failure/drift”. These remain future obligations.
- [Pass] Coverage tradeoff and rollback: “restore the two TESTS entries, remove their EXEMPT entries, restore the ATE member and corresponding Ubuntu skip together” gives a complete Easy rollback. “Deferral accepts reduced automatic coverage for unrelated changes” makes the risk explicit. Local #916/#917/#918 documents each name concrete “Resume only when” predicates. Historical attribution remains unknown. The stated 70/50/50/85 rating is bounded to implementation and has no override.
- [Unverified — needs clone run] Focused suites, actual gh306 red control, final byte preservation, full zero-retry qualification and exact-head hosted success require subsequent disposable-clone work. No validate.sh, test suite, pytest or executable fixture ran here.

Evidence scope: graph Verify metadata for the canonical XYZ project reports generation 2026-09-30T07:57:23Z and no recorded coverage issue for the seven selection/companion paths checked. This best-effort metadata does not attest the worktree; local source text supplied selection evidence. No broad runtime audit or fresh external issue-state verification is claimed.

Protocol: the current user explicitly assigned this Reviewer turn despite the stale NEXT header and requested terminal done on approval; that instruction governs over the earlier embedded correction. NEXT remains Producer for authorized implementation after this plan receipt. No git command or source/artifact edit was made.

Done — relay closed (Approved), no further review turn needed.


### Attestation · relay-drive — 2026-10-02T05:21:32Z
task: gh854-dispositions-plan2
reviewer: codex
status: Approved
reviewed-head: ffe982b5739a6cadd8897006eab19f9579dba8fa
added-range: 25285+4224
added-sha256: 07b1173de864e25fa4814117abcae4acf763186632701edf22d036e5bcad6d5c
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
