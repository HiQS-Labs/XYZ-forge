# RELAY · GH-1606 plan QA — gate-toolchain fault must not burn a B1 repair slot
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-25.
-->

NEXT: Producer
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

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
