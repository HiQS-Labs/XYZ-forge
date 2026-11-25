# RELAY · GH-1606 plan QA — gate-toolchain fault must not burn a B1 repair slot
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-25.
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
6. **Manual relay: commit only the relay file** (`relay(gh1606-plan-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1606-MERGE-CLEANUP-PUSH-ENVFAULT.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1606-MERGE-CLEANUP-PUSH-ENVFAULT.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude
- Started: 2026-11-25
- Definition of Done: the plan is approved only if its requirements, root-cause claim, smallest change and falsifiable acceptance checks are each grounded in the real code and cannot be satisfied vacuously (see Questions).

### Operational envelope and non-goals
- Local developer/operator CLI tooling (`skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`) in the XYZ-forge repo. Grade against the plan's stated requirements and commensurate complexity; the repo's own stated threat model governs. Challenge speculative abstraction, parallel subsystems and bloat — act as a filter against scope creep, not an engine of it.
- XYZ-forge forbids new tests (`AGENTS.md` *No new tests*, GH-831): a request for a new `test/` suite, `validate.sh` TESTS entry or gate machinery is itself a finding. Verification is an existing suite or a manual check recorded under `TESTS-RESULTS/` with `provenance.jsonl`.
- The plan's stated non-goals (frontmatter `non_goals`) are the author's; state which you accept and which you would contest, with evidence.

### Step 1 — paraphrase first (GH-1414), BEFORE reading any source file
Read ONLY the artifact under review. Then, in your review block and before any source-backed assessment, write under three labelled headings:
- **What this proposes** (2–5 sentences)
- **How the existing system works, per this document** (2–5 sentences)
- **What it's not** (short; ground each exclusion in a plan section; separate excluded work, deferred work, unresolved choices and later authorization; label inference and missing boundaries rather than inventing non-goals)
State the input boundary: "paraphrase written from the artifact only." Only afterwards read the code below and label the rest of the review **source-backed**. A mismatch between your paraphrase and the source is a signal to report, not hide.

### Step 2 — source-backed technical validation
Read in full: `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` (focus: `gate_unwired_reason`, `prepare_landing_clone`, `push_resolved_head`, the B1 branch around `attempt_record.reserve`, `preflight_warnings` and its call site), `skills/2-daily/merge-cleanup/scripts/attempt_record.py`, and `validate.sh` lines ~1020–1075 (the `ENVIRONMENT FAULT` block and `--print-mode`). The existing suites `test/gh534_phase_b_tests.py` and `test/gh436-merge-cleanup.py` may be read, not run. Line numbers in the plan are at base `b479f74e0`; check them.

### Questions (answer each; cite `file:line`)
1. Root cause: does the plan name the origin (slot reserved before the gate's runnability is known) and does the fix site remove the failure *class*, or only this instance? Is the claim "hook wiring is already checked pre-reserve (`merge_cleanup.py:1094`)" true?
2. Is `bash validate.sh --print-mode` a faithful, side-effect-free probe of exactly what the pre-push hook will hit? Does the hook run `validate.sh` under the same PATH/env the probe inherits? Can `--print-mode` produce a false pass or a false fault?
3. Deferring (exit 3, queue continues) vs stopping (exit 2): is deferral correct given hard-dependent blocking, `--resume`, and the batch record? Is any PR state left inconsistent (landing clone, attempt record, batch row)?
4. Does the pre-reserve placement preserve existing guarantees — the 2-repair cap, the `--resume` parked-skip, dry-run purity (no writes), consumer repos without `validate.sh`, and the existing fixtures in `test/gh534_phase_b_tests.py` / `test/gh436-merge-cleanup.py`? Try to violate each.
5. What prevents an **unchanged, unfixed** candidate from being reported as delivered — and where is the observed rejection? Is AC-2's "base-commit run is red, candidate green" plan actually runnable on the existing fixture, and is each acceptance check non-vacuous (would an empty/absent probe pass it)?
6. Open questions in the plan: (a) defer vs stop, (b) leave the `[-400:]` truncation out of scope, (c) is the run-start PRE-FLIGHT warning scope creep? Give your position on each with evidence.
7. Is the plan surgical and DRY — does it extend `gate_unwired_reason`/`preflight_warnings`/`validate.sh --print-mode` instead of building a second system? Flag any unneeded machinery or any missing piece.
8. Rating: the plan rates `55/55/50/70` (`effort` = cheapness). Is that grounded in the recon, and is the `effort 25 → 70` correction right?

Output: graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`) each with a concrete fix, `file:line` citations, the required `swept file: yes|no` line, then `VERDICT:` and `Basis:`. Every behaviour-change finding needs `Observed input:` / `Affected scope:` / `Falsifier:`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer · Round 1

**What this proposes**

Paraphrase written from the artifact only. Add a bounded gate-toolchain probe before a B1 repair reservation and defer a conflicted PR when it reports a fault. Reuse that probe for a run-start warning and document the behavior, without changing the repair budget.

**How the existing system works, per this document**

Landing-clone preparation checks hook wiring before reservation. B1 then reserves a durable slot, repairs the conflict and pushes; an environment refusal at push time can spend the slot while the stderr tail hides the cause. The document says validate's print-mode already checks toolchain readiness without running suites.

**What it's not**

Excluded by frontmatter: gate bypasses, budget/accounting changes, interpreter selection and genuine failing-suite diagnostics. Alternatives defer widening the push-output slice; defer versus stop and the warning's scope remain reviewer questions. No additional authorization phase is specified.

**Source-backed assessment — Block pending plan corrections**

- **[Blocker] R1 — AC-2 cannot produce its promised red control as written.** Observed input: artifact:117 promises a PATH-only base/candidate run of the existing B1 fixture; `test/gh534_phase_b_tests.py:175-192` seeds releases tools and a README, not validate or hooks, and `test/gh436-merge-cleanup.py:40-43` disables the wiring check. Running phase B alone instead encounters the real missing-installer refusal at `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:1056-1058` before reservation. Affected scope: AC-2/AC-3's claimed environment-fault scenario. Falsifier: an explicit fixture setup that demonstrably reaches the real environment diagnostic, shows base exit 2 with one attempt, candidate exit 3 with zero attempts, and a healthy candidate repair that actually pushes. Fix: specify the disposable-clone manual driver/setup, including gate files/hook or a clearly declared controlled push-refusal seam, the wiring setup, and the exact base/candidate command. Do not add a suite. Require nonempty named fault output, actual entry into B1, an unchanged published PR head on defer, and an existing/absent attempt record handled explicitly; never accept missing output as zero attempts. No such observed unchanged-candidate rejection is currently supplied; AC-1's stub only tests the helper oracle, not reservation ordering.

- **[Should] R2 — “whole class” overstates the chosen probe contract.** Observed input: artifact:62-64 includes broken PHP, but `validate.sh:1028-1033` prints that fault without exiting; with healthy Python it reaches exit 0 at `validate.sh:1060`. Artifact:77 discards every rc-0 diagnostic. Also `bash validate.sh` can read a non-executable file that the hook explicitly rejects at `githooks/pre-push:52-55`; timeout/spawn failure deliberately returns empty (artifact:78-79). Affected scope: the claim that every gate-runnability fault is prevented before reservation. Falsifier: show each included fault produces a nonempty helper reason before reserve, including PHP-only output with rc 0; otherwise the universal claim is false. Fix: bound the requirement/root-cause claim to the detected blocking Python/toolchain diagnostics and explicitly document fail-open/unmeasured cases, or define how named diagnostics are handled independently of rc. Keep PHP's actual advisory semantics intact; do not invent a new policy merely to match the prose.

- **[Should] R3 — acknowledge that this probe is conservative, not the exact push precondition.** Observed input: artifact:75-76 describes the eventual push's check, but `githooks/pre-push:390-395` selects `run_docs_gate` (`:337-345`) without validate; the proposed unconditional probe requires mypy/pytest/requests at `validate.sh:1037-1044`. Full-receipt reuse also exits before validate (`githooks/pre-push:421-440`). Affected scope: B1 repairs whose push would select docs or reuse a receipt; a Python missing only mypy is a concrete input to the stricter probe. Falsifier: demonstrate the repaired push's real route always requires the same toolchain for every supported B1 shape, or explicitly accept conservative deferral. Fix: record that scoped tradeoff and its false-deferral consequence, or reuse an existing route owner if exact equivalence is required; do not copy the hook's classifier. Same PATH is supported by `merge_cleanup.py:1155-1163` (copied environment plus attempt context), but identical PATH does not establish identical route. No runtime route reproduction was executed here.

- **[Pass] Q1/Q3/Q4 — ordering and deferral fit the existing owners.** The cited wiring check really is pre-reserve (`merge_cleanup.py:1094`); reservation durably appends before B1 finishes and pushes (`:2148,2188,2197`). Put the new check inside the execute path after the resume skip (`:2121-2136`). Hard dependents consult failed/pending (`:2032-2043`), batch outcomes persist the failure reason (`:1953-1955`), and the incomplete queue returns 3 (`:2471-2482`). A deferred landing clone remains inspectable (`:2485-2498`); no remote repair or attempt record should have changed. The two-attempt cap stays owned by `attempt_record.py:reserve` (MAX_REPAIRS and append under RecordLock). Concrete action: retain these mechanisms and include their outcomes in the manual check, rather than add accounting/refund logic. Missing validate is silent only for the new helper; it does not waive the existing missing-installer refusal. These are source-based compatibility conclusions, not executed regressions.

- **[Pass] Q2/Q4/Q6 — print-mode is useful read-only introspection, with limits.** It exits before gate accounting/suites (`validate.sh:1049-1066`), but the linked-worktree guard precedes it (`validate.sh:58-94`), so a warning from a linked primary can describe that primary rather than the disposable landing clone. Concrete action: label run-start output advisory and clone-specific rather than proof of push readiness. Preserve the no-write warning helper convention (`merge_cleanup.py:1409-1439`). “Dry run no writes” should mean no new writes from this change: the existing dry run publishes its selection before warnings (`:2910-2916`). A scoped warning meets the issue's advance-warning requirement and is not scope creep.

- **[Pass] Q6/Q7/Q8 — keep the small design and most non-goals.** Defer rather than stop is appropriate for independent PRs under the existing exit-3/dependency contract above. Keep genuine suite-RED truncation outside this fix (`merge_cleanup.py:1165`), but qualify the claim that preflight eliminates all hidden environment causes because the helper intentionally fails open. Accept no bypass, no interpreter switching, and no accounting changes. One helper reused by B1 and preflight extends existing owners; no parallel gate, new suite or runner is justified. The effort-axis correction is right (`RELEASES-DB-FAQS.md:156`: higher means cheaper); 70 is a reasonable estimate for the code, with manual evidence setup additional work. The other scores are defensible judgment from the reported incident (artifact:148), not independently measured recurrence.

swept file: yes

The artifact was reviewed in full and merge_cleanup.py was swept beyond the proposed insertion sites; no additional independently established pre-existing defect is asserted in this turn. Source inspection only: no validate, test suite, pytest, executable fixture, git command, or external runtime probe was run. Runtime acceptance remains [Unverified — needs clone run]; no later gate is assumed.

VERDICT: FAIL
Basis: R1 leaves the central falsifiable acceptance scenario unexecutable as specified; R2/R3 require a truthful probe boundary and explicit conservative-deferral decision. The pre-reserve direction is sound, but these gaps prevent plan approval.

Handing off to Producer (claude) — revise the plan and supply a concrete disposable-clone verification procedure, then return for Round 2.

### Producer · Round 1

Revised `PROJECT/2-WORKING/GH-1606-MERGE-CLEANUP-PUSH-ENVFAULT.md` (sections *Root cause*, *Plan* step 3, *Acceptance and red controls*, *Smoke*, *Risks and accepted tradeoffs*, *Decisions after plan QA round 1*, *Recon ledger*). Dispositions:

- **R1 [Blocker] — Implemented.** Verified before accepting, not on trust: in a disposable full clone at base `b479f74e0`, `test.gh534_phase_b_tests.TestPhase5EndToEnd.test_unknown_mergeable_settles_and_the_pr_lands` → `FAIL: landing clone gate wiring failed: githooks/install.sh is missing … (GH-1576)`; the whole file → `Ran 39 tests … FAILED (failures=14, errors=1)`. `validate.sh`, `ci-local.sh` and `test/*.sh` never reference it (grep: no match), while the gated suites are `gh436-merge-cleanup.sh`, `gh645-…`, `gh674-…`, and `gh436` mocks `prepare_landing_clone` (`:458`). So: phase B is withdrawn as a "stays green" witness (AC-5 now names the gated suites), and AC-2 is rewritten as a concrete manual driver (`TESTS-RESULTS/2026-11-25+GH-1606/run_controls.py`, not a suite) with two declared seams (hook installer stub, `validate.sh` toolchain shim), a counting push stub, base-vs-candidate by script directory, and per-scenario assertions that reject missing output and treat an absent attempt record as `absent`, never `0`. Phase B's breakage itself is a separate pre-existing defect: out of scope, recorded for triage.
- **R2 [Should] — Implemented.** Class bounded to blocking toolchain faults (`validate.sh:1042-1045`, exit 3); PHP stays advisory (`:1028-1033`, rc 0) and is not deferred on; fail-open on timeout/spawn failure and the non-executable-file divergence (`githooks/pre-push:52-55`) are stated as unmeasured. Requirement and root-cause prose no longer claims "the whole class" or "all hidden causes".
- **R3 [Should] — Implemented.** Conservative deferral recorded as an accepted tradeoff with its false-deferral consequence (exit 3, named fix, no slot spent) and its source (`githooks/pre-push:390-395`, `:421-440`); hook classifier deliberately not copied. Not measured on a real docs-route push — stated as such.
- **[Pass] items — accepted, with the refinements taken:** pre-reserve warning labelled advisory and primary-specific (linked-worktree guard `validate.sh:58-94` precedes `--print-mode`); "dry run writes nothing" reworded to "no new writes from this change" (existing selection pin, `merge_cleanup.py:2910-2916`); defer over stop kept; `[-400:]` truncation stays out of scope; effort `25 → 70` correction stands.

No finding declined. No code written yet; this relay is plan QA only.

Handing off to Reviewer (codex) — round 2: check the revised AC-2 driver design (can it reach `routing to B1` and the push seam on the existing `LedgerFixture`?), the bounded class claim, and the recorded tradeoff.

### Reviewer · Round 2

**What this proposes**

Paraphrase written from the artifact only. Add a bounded print-mode toolchain probe immediately before a B1 reservation, defer on its reported fault, and reuse it for an advisory primary-checkout warning. Keep repair accounting and push enforcement unchanged.

**How the existing system works, per this document**

Hook installation is checked before reservation, but toolchain readiness is discovered only after repair at push. The existing phase B fixture lacks that installer and is already broken at base, so the revised manual controls introduce explicit installer/toolchain seams and a counting push stub.

**What it's not**

Accept the frontmatter exclusions: no bypass, interpreter selection, accounting change or genuine suite-failure output change. Phase B repair is deferred outside this task (Measured prerequisite); real docs-route equivalence is unmeasured and conservative deferral accepted (Risks). Implementation and runtime evidence follow plan approval; approval here cannot establish delivery.

**Source-backed assessment — Block pending one control-design correction**

- **[Blocker] R1 remains open: the healthy push seam cannot satisfy AC-3.** **Observed input:** the artifact explicitly replaces the healthy push with a counting stub returning `(True, "pushed")` (`.relay-artifacts/GH-1606-MERGE-CLEANUP-PUSH-ENVFAULT.md:151-157`) yet requires S3/S4 to land (`:163`). In the reused fixture, live `headRefOid` comes from the origin PR branch (`test/gh534_phase_b_tests.py:74-79`), not the push function's return. Immediately after that return, `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:2213-2226` refreshes that head, waits for B1's commit and stops with exit 2 when they differ. This is a Form 1 artifact/source contradiction, not an inferred external-service hazard. **Affected scope:** S3 healthy, S4 repaired resume and any S5 healthy B1 control; the revised installer seam can clear the earlier wiring refusal, but success without publication cannot clear the next head check. **Falsifier:** run the proposed return-only healthy stub unchanged and show the origin PR head actually equals B1's commit and the fixture reports MERGED; otherwise expect the explicit head-mismatch refusal. **Fix:** keep the counting refusal stub for S1/S2, but make the healthy wrapper count and delegate to the real `push_resolved_head` against the fixture's local bare origin (the declared installer seam installs no actual hook), or explicitly publish the repaired SHA to that local branch. Assert the nonempty published head equals the repaired SHA before accepting MERGED, and capture stdout as well as stderr: `routing to B1`/`B1:` use `log` on stdout (`merge_cleanup.py:444-445,2117,2167`), whereas `LedgerFixture.run_main` only captures stderr (`test/gh534_phase_b_tests.py:262-269`). No new suite or production change is requested. Runtime execution remains **[Unverified — needs clone run]**; the source contradiction itself is established.

- **[Pass] R2 / Q1-Q2 — the bounded fault claim now matches the chosen oracle.** `validate.sh:1035-1045` checks Python version/imports and exits 3; PHP is advisory at `:1028-1033`. The plan now excludes PHP, timeout/spawn failures and executable-bit divergence. Hook wiring really precedes B1 reservation (`merge_cleanup.py:1094,2148`). Action: implement the scoped helper as proposed; retain these explicit limits. Print-mode exits before receipt admission/suites (`validate.sh:1049-1066`), so this is useful introspection, not gate evidence.

- **[Pass] R3 / Q2,Q6-Q7 — conservative deferral is now an explicit design decision.** Push inherits PATH via the copied environment (`merge_cleanup.py:1155-1163`), but the docs route and full-receipt reuse skip validate (`githooks/pre-push:390-395,421-440`). Accept the small conservative probe rather than duplicating that classifier. This may delay a push that would succeed today; the benefit is avoiding a spent slot for detected blocking faults. Action: retain the stated false-deferral boundary and avoid describing it as exact hook equivalence.

- **[Pass] Q3-Q4,Q6 — placement and failure vocabulary fit existing state owners.** Hard dependents consult failed/pending (`merge_cleanup.py:2032-2043`); batch rows retain the reason (`:1953-1955`); incomplete queues return 3 and retain deferred clones (`:2471-2498`). Resume's ceiling skip precedes reserve (`:2121-2148`), and the locked two-repair authority remains `attempt_record.py:reserve` (`MAX_REPAIRS = 2`, append under `RecordLock`). Action: keep the helper inside execute after that skip. Missing validate must skip only the new helper, preserving the existing installer requirement (`merge_cleanup.py:1055-1058`). Defaulted preflight argument preserves callers; label its warning primary-specific because `validate.sh:58-94` precedes print-mode. No new dry-run writes: the pre-existing selection publication remains at `merge_cleanup.py:2910-2916`. The warning serves the stated advance-warning requirement; truncation at `:1165` can stay out of scope.

- **[Pass] Q5 — non-vacuity is substantially improved, subject to R1.** Artifact `:162,168-169` now requires actual B1 routing, named nonempty fault output, zero push calls, unchanged remote head, and explicit absent/loaded-empty attempt records. Those distinguish pre-reserve deferral from early refusal and spent-slot behavior. Action: retain the paired base/candidate S1/S2 assertions and repair the healthy seam above. No unchanged-candidate rejection has been witnessed in this review; these are prospective acceptance checks, not delivered evidence. A summary naming a deferred PR establishes the failure-map outcome, not an independently exercised hard-dependent scenario; source coverage for that unchanged mechanism is sufficient for this plan.

- **[Pass] Q7-Q8 — the surgical design and rating correction stand.** The plan extends the existing warning owner (`merge_cleanup.py:1409-1439`) and validate oracle (`validate.sh:1049-1060`), with no accounting rewrite or new gate machinery. Effort means cheapness (`RELEASES-DB-FAQS.md:156`), so 25→70 is directionally correct for this small change; the other scores remain incident-based judgment, not measured recurrence. Action: keep this scope; repair only the manual control's publication semantics.

swept file: yes

Reviewed the full artifact and swept merge_cleanup.py beyond the proposed insertion sites, plus attempt_record.py and the specified validate block. No additional independently established pre-existing defect is asserted. Read-only source inspection only; no git command, validate, suite, pytest, executable fixture, external service or runtime acceptance probe was run. Source-read commands exited 0; decisive code spans are quoted/cited above. No later gate is assumed.

VERDICT: FAIL
Basis: the production fix direction, bounded guarantee and conservative tradeoff are acceptable. R1 remains open because the revised healthy return-only push stub contradicts the existing remote-head confirmation and cannot prove the promised healthy/resume landing. Correct that narrow manual-driver design, then return for plan approval; implementation evidence remains a subsequent obligation.

Handing off to Producer (claude) — correct the healthy publication seam and stdout capture in the plan, then return for Round 3.

### Producer · Round 2

Revised the plan again (*Manual driver* push seam, AC-3 row, *Decisions after plan QA round 1*, *Open questions*, *Recon ledger*). Disposition of the one open item:

- **R1 [Blocker] (healthy push seam) — Implemented.** Verified before accepting: the fixture's `gh` stub reads the PR head from the origin branch (`test/gh534_phase_b_tests.py:74-79`), and after the push `merge_cleanup.py:2213-2226` waits for it to equal B1's commit and returns exit 2 otherwise, so a return-only `(True, "pushed")` stub cannot land — the reviewer's Form 1 contradiction is correct. Fix as proposed: S1 keeps the counting **refusal** stub (the incident shape); every **healthy** run (S3/S4/S5) uses a counting wrapper that **delegates to the real `push_resolved_head`** against the fixture's bare origin, and the driver asserts the origin branch SHA is non-empty and equals the repaired commit in the attempt record, and that the PR reads `MERGED`, before accepting a landing. The driver captures **stdout and stderr** (`routing to B1` / `B1:` are `log` → stdout, `merge_cleanup.py:444-445`; `LedgerFixture.run_main` captures only stderr, `:262-269`). The driver's PR setup is now named: it derives from `TestPhase5EndToEnd.test_two_prs_second_conflicts_after_first_lands_and_b1_resolves_it` (`:421`).
- **Measured, not just argued.** In a disposable clone at base `b479f74e0`, with only the wiring seam applied (the same stub `test/gh436-merge-cleanup.py:43` uses), that existing scenario passes end to end: `attempt 1/2 reserved … B1 rc=0 … pushed d55922402c to feat/b … PR #2 is MERGED`, `Ran 1 test … OK`. So the healthy real-push path is runnable on `LedgerFixture`; no production change is needed to support it.
- **[Unverified — no citation] items — kept unchanged** (bounded class claim, conservative deferral, placement/failure vocabulary, non-vacuity rules, surgical scope, rating correction).

No finding declined. No code written; this relay is plan QA only.

Handing off to Reviewer (codex) — round 3 (last of the cap): confirm the corrected healthy seam closes R1, and say whether any path remains where an unchanged candidate would be reported as delivered.

### Reviewer · Round 3

**What this proposes**

Paraphrase written from the artifact only. Probe validate's blocking toolchain diagnostics before reserving a B1 repair, defer the affected PR, and reuse the helper for an advisory primary-checkout warning. Preserve the budget and hook enforcement.

**How the existing system works, per this document**

Wiring is checked before reservation, but toolchain failure is currently discovered after repair when pushing. The revised manual driver uses a refusal stub for the incident and a counting real-push wrapper for healthy controls, checking the published branch against the recorded repair and capturing both output streams.

**What it's not**

Accept frontmatter exclusions: no bypass, accounting change, interpreter switching or genuine suite-RED output work. Phase B's existing wiring-fixture breakage is deferred (Measured prerequisite). Exact hook-route equivalence is explicitly unmeasured and conservative deferral accepted (Risks); implementation and delivery evidence remain later obligations (Status and Acceptance).

**Source-backed assessment — approve the plan**

- **[Pass] R1 closed / Q5.** The corrected healthy wrapper delegates to the actual publication owner (artifact:155–172; `merge_cleanup.py:1142–1166`), which pushes the repaired SHA to the fixture origin. The subsequent live-head comparison (`merge_cleanup.py:2210–2227`) now has a real published value to observe. AC-2 independently rejects an unchanged candidate through exit 3, named fault, no reservation and zero push calls (artifact:177,183–184); AC-1 rejects a missing or always-empty helper (artifact:176). These are falsifiable prospective checks, not an observed candidate rejection in this turn. Implementation detail for the driver: capture/assert the nonempty remote head immediately after the real push inside the wrapper, retain that observation, then assert MERGED after main returns. The fixture deletes the source branch on merge (`test/gh534_phase_b_tests.py:155–157`); a fresh post-merge ls-remote cannot supply that head. This fits the proposed counting wrapper without another production mechanism. No remaining return-only success seam is specified.

- **[Pass] Q1–Q2.** Wiring is already checked before reservation (`merge_cleanup.py:1094,2148`); the added check addresses the detected blocking-toolchain class at its origin. Validate's Python fault exits 3 (`validate.sh:1035–1045`) before print-mode returns and before receipt admission (`:1049–1066`). PHP remains advisory (`:1028–1033`). Push copies the environment (`merge_cleanup.py:1155–1163`), but identical PATH does not mean identical route: docs and receipt reuse can skip validate (`githooks/pre-push:390–395,421–440`). Accept the expressly bounded, conservative probe and its documented fail-open/executable-bit limits; do not claim exact hook equivalence or delivery proof.

- **[Pass] Q3–Q4.** Execute-only placement after the resume skip preserves the existing ceiling authority (`merge_cleanup.py:2121–2148`; `attempt_record.py:31,125–146`). Deferring through failed fits hard-dependent blocking (`merge_cleanup.py:2032–2043`), durable batch outcome reporting (`:1953–1955`) and incomplete-run exit 3 (`:2471–2482`). No refund/accounting rewrite is needed. Missing validate skips only this helper, preserving the installer requirement (`:1055–1058`); defaulted preflight arguments preserve existing callers (`:1409–1439`). Dry-run acceptance correctly excludes the pre-existing selection write (`:2910–2916`). S3/S4/S5/S7 attack healthy publication, resume budget, missing validate and the parked skip (artifact:178); no further source-established obstacle to those controls is identified. Runtime execution remains unverified here.

- **[Pass] Q6–Q8.** Choose defer over stop to continue independent work using the failure-map contract above. Leave the push stderr truncation (`merge_cleanup.py:1165`) outside this bounded fix. Reusing the existing advisory warning owner (`:1409–1439`) serves advance warning; it is not scope creep when labelled primary-specific. The helper reuses validate's oracle rather than copying its imports or the hook classifier (artifact:84–106,204–213). Accept the stated non-goals and the small reversible scope. The 55/55/50 scores remain incident-based judgment (artifact, Per-issue rating); effort 25→70 correctly reflects higher cheapness (`RELEASES-DB-FAQS.md:156`), with evidence setup additional work.

swept file: yes

Reviewed the entire seeded plan and swept the source beyond the insertion sites, including attempt-record ownership and the specified fixture/validate paths. No additional independently established pre-existing production defect is asserted. Source-read commands exited 0; decisive spans are cited above. No git command, validate, suite, pytest, executable fixture or runtime acceptance probe was run. The Producer's reported clone run is supporting context, not independently reproduced evidence. No later gate is assumed.

VERDICT: PASS
Basis: the last open contradiction is resolved by real publication plus published-head observation. Requirements, bounded root cause, smallest change and non-vacuous acceptance controls are sufficiently grounded for plan approval. This approves implementation of the plan; it does not certify implementation or delivery. Retain the planned base-red/candidate-green outputs and provenance during implementation.

Relay closed (Approved), no further turn needed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
