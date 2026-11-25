# RELAY · GH-1615 plan QA: move the GH-1576 wiring stub into the shared phase B fixture
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-25.
-->

NEXT: Producer
STATUS: Approved
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
     change MUST carry `Observed input:`, `Affected scope:` (the input predicate the change would govern),
     and `Falsifier:` (the fixture or data that would show the change unnecessary or wrong, and its expected
     result). `Observed input:` accepts two strict, non-speculative forms:
     (1) **Form 1 (observed failure or artifact contradiction):** a failing probe/gate output, or a concrete
     `fileA:line` vs `fileB:line` contradiction (e.g. IAM SA mismatch, inverted test, sibling guard omission);
     (2) **Form 2 (unrunnable runtime hazard trace):** permitted ONLY when reproduction requires an external
     service, multi-process concurrency, or a browser/container runtime forbidden in the relay worktree —
     must supply a hop-by-hop `file:line` trace plus an exact `Clone probe:` command/script for the Producer's
     disposable full clone. Default severity for an unexecuted Form 2 hazard is `[Should]`.
     A `[Blocker]` must cite an observed failure (Form 1); an unexecuted Form 2 hazard stays `[Should]`
     until a probe reproduces it, and remains pending probe verification until the Producer runs
     `Clone probe:` in a disposable full clone.
     A finding from an earlier round stays open, and the verdict stays failing, until new evidence closes it.
     This includes earlier [Nit] findings; only a newly raised [Nit] with VERDICT: PASS on STATUS: Approved remains optional.
     This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking Form 1 evidence and lacking a complete Form 2 trace + `Clone probe:` as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request lacking Form 1 evidence and
     lacking a complete Form 2 trace + `Observed input:` / `Affected scope:` / `Falsifier:` / `Clone probe:`).
     For every Form 2 `Clone probe:` finding, read the probe before running it — refuse any probe that reaches
     the network, credentials, or paths outside the disposable clone and record the refusal as
     `[Unverified — clone probe failed/unavailable]` — then execute safe probes in a disposable full clone and
     record one of three outcomes: (a) Reproduced → fix and paste failing-before / passing-after probe output;
     (b) Falsified → `Declined — falsified by clone probe: <cmd → exit + output>`; (c) Errored, refused, or
     environment unavailable → keep the finding OPEN (`[Unverified — clone probe failed/unavailable]`, blocking
     `STATUS: Approved` until re-run cleanly or escalated/parked). Make approved changes, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Manual relay: commit only the relay file** (`relay(gh1615-plan-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1615-PHASE-B-FIXTURE-REPAIR.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1615-PHASE-B-FIXTURE-REPAIR.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude
- Started: 2026-11-25
- Definition of Done: every factual claim in the plan is grounded in the real code and runs; the root cause, the smallest change and the acceptance controls are sound and cannot be satisfied vacuously; the plan's correction of the issue's premise is true.

### Operational envelope and non-goals
- Test-fixture repair in the XYZ-forge repo; grade against the plan's stated requirements and commensurate complexity; the repo's own threat model governs. Challenge bloat and speculative machinery; do not manufacture scope.
- XYZ-forge forbids new tests (`AGENTS.md` *No new tests*, GH-831): a new `test/` suite, a `validate.sh` entry or gate machinery is itself a finding. Editing an EXISTING suite to keep it truthful is allowed. Verification is an existing suite or a manual check under `TESTS-RESULTS/` with `provenance.jsonl`.
- The plan's non-goals (frontmatter `non_goals`) are the author's; say which you accept and which you contest, with evidence.

### ROUND 2 INSTRUCTIONS (read first)
- **Format:** inside your review block use **bold labels** (for example `**Q1**`), NEVER markdown heading lines (`#`, `##`, `####`). The driver counts a block's body only up to the next heading line; round 1's `####` sub-headings made it read your block as empty.
- **No new paraphrase needed.** Focus on: (a) is R1-1 closed? Spot-check at least three rows of `TESTS-RESULTS/2026-11-25+GH-1615/provenance.jsonl` against the plan's claims and the revision `d3b238ed5` (the receipts are in the repo, readable in your worktree); (b) the AC-5 tightening in the plan; (c) anything new that blocks approval. Keep the required `swept file: yes|no` line and `VERDICT:` / `Basis:`.

### Step 1: paraphrase first (GH-1414), BEFORE reading any source file
Read ONLY the artifact under review. Then, before any source-backed assessment, write under three labelled headings: **What this proposes** (2-5 sentences), **How the existing system works, per this document** (2-5 sentences), **What it's not** (short; ground each exclusion in a plan section; separate excluded work, deferred work, unresolved choices and later authorization; label inference and missing boundaries rather than inventing non-goals). State the input boundary: "paraphrase written from the artifact only." Only afterwards read the code and label the rest **source-backed**.

### Step 2: source-backed validation
Read in full: `test/gh534_phase_b_tests.py` (esp. `LedgerFixture.setUp`, `TestPhase5EndToEnd`, `TestE6Gate`), `test/gh436-merge-cleanup.py` (esp. lines 38-43 and 1375-1390), `test/gh534_phase_c_tests.py` (imports at line 34, `TestCScript`, `TestGh623Resilience`), `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` (`gate_unwired_reason`, `prepare_landing_clone`, `push_resolved_head`), `validate.sh` around line 96, and `skills/2-daily/merge-cleanup/SKILL.md` lines 615-640. The plan's line numbers are at base `d3b238ed5`; check them.

### Questions (answer each; cite `file:line`)
1. **Premise.** The plan overturns the issue's "no gate runs it": `gh436` does `from gh534_phase_b_tests import *` and is registered at `validate.sh:96`. Is that true and sufficient? Is there any way the gated run does NOT execute all 39 phase B tests (a name collision, a `load_tests` hook, a skip)?
2. **Root cause and class.** Is the stated origin right (the shim lives in the aggregator, not the shared fixture)? Does moving it to `LedgerFixture.setUp` remove that class for B, C and the importers, and is the plan honest about what it does not remove?
3. **Correctness of the scoped patch.** `mock.patch.object(merge_cleanup, "gate_unwired_reason", ...)` started in `setUp` with `addCleanup(stop)`: does it stack and unwind correctly over `gh436`'s module-level lambda? Any test that patches `gate_unwired_reason` itself, calls `main()` twice, or runs in a subclass `setUp` order that would break it? Does any class derived from `LedgerFixture` override `setUp` without calling `super().setUp()`?
4. **Test honesty (surface-triggered).** Does the stub mock away the very seam any test claims to exercise? Does any test assert a historical invariant that GH-1576 changed (a test inversion check)? Is the plan's claim "neither suite asserts on wiring" true?
5. **Non-vacuity.** AC-5 plans two production mutants (anchors: `deferred_set = deferred_closure(all_ordered, eligible)`; the `live.get("headRefOid") != pr["headRefOid"]` refusal in `push_resolved_head`). Would each really turn its named pinned test red, and is each anchor unique? What prevents an unfixed candidate from being reported as delivered, and where is the observed rejection (AC-1 is the red control; is it enough)?
6. **Guarantees.** AC-4 runs the real gated entry point on the candidate. Is that the right guarantee check, and what else does the changed fixture execute inside the gate (list the gated suites that import phase B/C)?
7. **Rating and decisions.** The plan re-rates the task from the issue's proposed `30/35/50/65` to `20/25/50/85` (pri/sev/appeal/effort, effort = cheapness). Is the re-rate grounded in the evidence? Is "no operator decision required" justified, or is a decision hiding?
8. **Surgical and DRY.** Is the plan the smallest honest repair? Any unneeded machinery, or a missing piece (for example, a stale statement in docs that the plan should correct)?

Output: graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`) each with a concrete fix and `file:line` citations, the required `swept file: yes|no` line, then `VERDICT:` and `Basis:`. Every behaviour-change finding needs `Observed input:` / `Affected scope:` / `Falsifier:`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer · Round 1

#### What this proposes
Repair standalone phase B and C runs by scoping the existing GH-1576 wiring stub to the shared LedgerFixture setup. Keep production and the aggregator unchanged, and prove the repaired suite still detects two production regressions.

#### How the existing system works, per this document
The registered gh436 aggregator imports all phase B tests and already supplies a process-wide wiring stub. Standalone entry points lack that stub, so synthetic landing repositories fail the production wiring refusal before reaching their intended subjects.

#### What it's not
Accepted exclusions, subject to source validation: no new registration, retirement, production change, aggregator edit or new tests (frontmatter non_goals). Deferred optional work: deleting the aggregator stub (Operator decisions left open). Other aggregator-only shims are explicitly untraced (Risks); no later authorization is requested. Paraphrase written from the artifact only.

#### Source-backed review
swept file: yes

Reviewed the whole plan, including its pre-existing claims, alternatives, exclusions, risks and acceptance table. No additional pre-existing defect identified in the artifact. Source checks below are static; no suite, executable fixture or git command ran here. Runtime outcomes remain [Unverified — needs clone run] unless the Producer supplies retained receipts. Reversibility: Easy — a fixture-local patch with normal unittest cleanup.

- [Should] R1-1 — Retain the evidence already cited as observed, before signing off the plan's factual run claims. The artifact at lines 38–46 asserts exact baseline failures, timings, green stub experiments and a green aggregator run; line 89 calls AC-1 “recorded,” while line 85 only promises future evidence. No receipt for these runs is supplied with the review input. Probe: `rg --files TESTS-RESULTS/2026-11-25+GH-1615 .relay-artifacts` → exit 2, decisive output `rg: TESTS-RESULTS/2026-11-25+GH-1615: No such file or directory (os error 2)`. The available GH-1606 provenance addresses different checks, not these exact runs. Fix: retain the cited baseline/stub-run commands, revisions, exit statuses and decisive nonempty output in provenance.jsonl and reference the retained artifact; supply it as a review input. If those runs cannot be recovered, label them unverified and reproduce in a disposable full clone. This requests evidence/doc correction, not production behavior.
  Observed input: artifact lines 38–46 and 89 claim completed measurements, versus the missing evidence path above.
  Affected scope: completed run claims used to establish the root cause and red control, not future candidate acceptance runs.
  Falsifier: a supplied retained receipt for each cited baseline/stub experiment, with matching revision, command, exit status and nonempty summary, closes this finding.

- [Pass] Q1 — The issue's “ungated” premise is contradicted by `validate.sh:96`, the wrapper's `exec python3 "$HERE/gh436-merge-cleanup.py"`, and `test/gh436-merge-cleanup.py:1382-1384`. A non-executing AST namespace reconstruction (Python heredoc reading the four modules with ast.parse; replaying top-level class definitions and phase imports) exited 0: `a tests 46 phase B 0; b tests 39 phase B 39; c tests 111 phase B 27; g tests 227 phase B 39`. No collection hook, skip decorator or __all__ exclusion was found in the phase B/C or aggregator collection path. Phase C reimports the same two B classes, rather than replacing them with different classes. Keep the premise correction. Static collection is not proof that a particular historical run passed.

- [Pass] Q2–3 — The origin and proposed scope are sound: `test/gh436-merge-cleanup.py:39-43` supplies the process-wide stub, while `test/gh534_phase_b_tests.py:175-204` seeds repositories without githooks. The real refusal is `merge_cleanup.py:1057-1059,1124-1126`. Starting patch.object in setUp and registering stop with addCleanup follows the existing environment patch at B:202-204; cleanup restores the preceding aggregator lambda. B's fixture-derived classes have no setup override; C's TestCScript calls super at C:249-250, and TestGh623Resilience (C:621) inherits setup. Repeated run_main calls remain within the fixture patch lifetime (B:251-271). No direct competing wiring patch appears in B/C. Keep the scoped patch and the explicit limit on untraced shims.

- [Pass] Q4 — The wiring seam is distinct from the asserted ledger gate: `TestE6Gate.test_gate_red_prevents_the_merge` patches pre_merge_ledger_gate, not gate_unwired_reason (B:719-729). B:467-483 pins allowlisting; B:603-627 pins the moved-head refusal. Neither suite asserts the wiring refusal. No historical wiring-invariant inversion was identified. Keep production unchanged and keep the comment identifying GH-1576's separate wiring evidence.

- [Pass] Q5 — Both mutant anchors occur once in merge_cleanup.py (read-only Python str.count probe → exit 0, counts `1` and `1`). Setting eligible=None at the assignment before `merge_cleanup.py:2970` skips filtering and the “not sequenced” diagnostic required at B:483; disabling the comparison at production:1183 removes the “remote head moved” diagnostic required at B:623, even if the subsequent ordinary push is rejected. These are sound predicted red controls, not executed results. Run the named tests green before mutation and require the intended assertion failure, not an import/syntax/environment error. AC-1 plus AC-2 reject an unchanged candidate if the reported baseline is substantiated; AC-5 checks sensitivity rather than replacing that baseline. No extra test or machinery is needed.

- [Pass] Q6 — AC-4 is the correct candidate guarantee: the actual registered wrapper executes the aggregator. The importer search found only the gh436 registered entry importing B/C (`test/gh436-merge-cleanup.py:1383-1384`); it also collects phase A at 1382. The fixture change reaches B's TestB1Classify, TestPhase5EndToEnd and TestE6Gate, plus C's TestCScript and TestGh623Resilience (B:285,384,690; C:245,621). Other C record/parity tests still execute in that entry point. Keep AC-3/4/6; gh1606's driver explicitly calls d.doCleanups in finally (`TESTS-RESULTS/2026-11-25+GH-1606/run_controls.py`, quoted `finally: d.doCleanups()`), so scoped cleanup fits that importer too.

- [Pass] Q7–8 — The lower priority/severity and higher cheapness are reasonable judgments given existing gated collection and a fixture-local repair (artifact:116); the exact numbers are prioritization judgments, not measurements. No hidden production/registration/retirement decision is needed. Accept all frontmatter exclusions, including leaving the aggregator lambda. The existing fixture plus unittest.mock is the smallest adequate mechanism; no new suite, registry or production change is justified. The historical GH-1606 statements should remain history with an explicit correction, as artifact:51-53 proposes. The wrapper's A-only descriptive aside is incomplete but does not assert that B is ungated or require expanding this repair.

VERDICT: FAIL
Basis: The scoped repair, corrected gating premise and proposed acceptance controls are supported by static source inspection. R1-1 remains open because the Definition of Done requires factual run claims to be grounded in runs, and the cited baseline/experiment receipts were not supplied. Candidate runtime verification is intentionally future work; this verdict does not demand executing implementation acceptance before implementation. No later gate is assumed.

Handing off to Producer — retain/supply the cited baseline and experiment receipts, disposition R1-1, and return the plan for review.

### Producer · Round 1

- **R1-1 [Should] (retain the receipts for the cited baseline and experiment runs) - Implemented.** Agreed: the plan cited completed runs whose logs lived only in a scratch folder, and the plan's `TESTS-RESULTS/2026-11-25+GH-1615/` path did not yet exist. It now does, committed at `20d139204`: `provenance.jsonl` has 11 rows, each with command, revision (`d3b238ed5`), exit status and decisive output: `BASE-B-red` (39 run, 14 failures, 1 error), `EXP-1-B` (one-line stub only: 39 run, 0/0), `BASE-C-red` (111 run, 32 failures, 1 error), `EXP-1-C` (111 run, 0/0), `BASE-A-green` (46 OK), `GATED-BASE-green` (`gh436` 227 OK), `COLLECTION` (227 = 95 + 46 + 39 + 47), `REPORT-VISIBILITY` (4 of 15 blocks print the wiring refusal), `IMPORTERS`, `SKILL-PINS`, `SETUP-OVERRIDES`. Beside it: the two experiment runners, `collect_count.py`, and `failures-at-base.txt` (15 B names and 33 C names, each reconciled to its run summary). The raw 400 KB logs were not kept (they carry absolute temp paths). The plan now cites the receipts directly.
- **Q5 advice taken:** AC-5 now requires each mutant to fail on the pinned test's **own assertion**, not an import, syntax or environment error, with the same test green on the unmutated candidate; the mutation script already runs that control.
- **All Q1-Q8 `[Pass]` findings accepted** without change. One additional fact is now in the plan from my own pre-check: every `LedgerFixture` subclass inherits `setUp` or calls `super().setUp()` first (row `SETUP-OVERRIDES`).
- **Process note, for the record:** the driver classified your round-1 block as `zero-output-stall` even though it holds a full review. Cause, verified in `utils/py/relay_drive.py:146-162` (`review_blocks_added`): a block's body is counted only up to the next heading line of ANY level, and your block began with a `#### What this proposes` sub-heading, so the body read as empty. That was my packet's fault ("three labelled headings"). The round is counted as round 1 (the file holds a real verdict and `ROUND: 1 / 3`). For round 2 please use bold labels, not heading lines, inside your block.

No finding declined. No implementation yet; this relay is plan QA only.

Handing off to Reviewer (codex), round 2: confirm R1-1 is closed against the retained receipts, and say whether anything else blocks approval.

### Reviewer · Round 2

**Source-backed review — approve the plan.**
swept file: yes

Read the entire revised artifact, retained receipts, experiment runners, collection script and failure lists; spot-checked the source seams from round 1. No additional pre-existing defect in the plan blocks approval. The round-2 instruction waives a new paraphrase. Reversibility remains Easy: fixture-local patch and unittest cleanup. All stated non-goals remain accepted; Q1–Q8 dispositions from round 1 stand.

- [Pass] **R1-1 closed — the missing retained evidence is supplied.** Spot-checked five rows against the plan and its stated base: provenance.jsonl:1 reports BASE-B-red at d3b238ed5, exit 1, “Ran 39 tests in 78.097s ; FAILED (failures=14, errors=1)”; :2 reports EXP-1-B at that revision, exit 0, “RESULT run=39 failures=0 errors=0 ok=True”; :3–4 report C's 111 tests red (32 failures/1 error) then green with the one-line stub; :6 reports the same-base gated run, exit 0, “Ran 227 tests in 252.499s ; OK”. These match artifact:38–46. The retained runners apply only the stated wiring stub before unittest collection/run (run_stubbed_phase_b.py:4–6; run_stubbed_phase_c.py:4–6). Keep the receipts and their explicit raw-log retention limitation at artifact:50. These are Producer-retained historical receipts, not independently rerun results.

- [Pass] **Receipt consistency probe.** Command: Python heredoc using json.loads over TESTS-RESULTS/2026-11-25+GH-1615/provenance.jsonl, asserting exactly 11 rows, each with revision == 'd3b238ed5' and nonempty command/output_snippet; printing the five rows above; counting FAIL/ERROR lines in failures-at-base.txt; ast.parse on the three retained runner/counter scripts without executing them. Exit 0; decisive output: “listed=15”, “listed=33”, “11 nonempty revision-pinned receipts; retained runners parse without executing”. The failure lists reconcile with provenance.jsonl:1,3. No suite, executable fixture or git command ran here.

- [Pass] **AC-5 is now discriminating.** Artifact:96 explicitly requires each mutant to differ, the same pinned test to be green on the unmutated candidate, and failure on the test's own assertion rather than an import/syntax/environment error. This resolves the round-1 advice. The allowlist assertion at test/gh534_phase_b_tests.py:483 and remote-head diagnostic assertion at :623 remain distinct from hook wiring; the production anchors remain the eligibility filter at merge_cleanup.py:2970 and moved-head refusal at :1183. Keep these controls as planned; their runtime sensitivity remains to be demonstrated during implementation, not claimed by this approval.

- [Pass] **Scope and guarantee check retained.** Artifact:71–73 keeps the patch in shared fixture setup with addCleanup; test/gh436-merge-cleanup.py:43 supplies the previous process-wide stub, and :1382–1384 imports A/B/C into the entry registered at validate.sh:96. Artifact:92–99 retains base red, candidate B/C, actual gated wrapper, importer and scope checks. Keep the candidate acceptance sequence and the correction of historical gating claims at artifact:54–56. No new suite, production change or operator decision is needed for this plan.

VERDICT: PASS
Basis: R1-1 is closed by revision-pinned, nonempty retained receipts consistent with the plan and supporting files. AC-5 now excludes accidental mutant failure. No new blocking issue was found in the whole-plan sweep. This approves the plan only: candidate acceptance and mutant execution are future implementation evidence, and no later relay gate is assumed.

Relay closed (Approved), no further turn needed. Producer may implement the reviewed scope and execute the planned acceptance controls in disposable full clones.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
