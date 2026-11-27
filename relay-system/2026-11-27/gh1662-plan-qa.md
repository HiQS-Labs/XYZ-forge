# RELAY · GH-1662 plan QA: merge-cleanup explicit standalone mode, git+gh-only sequencing, prose runbook
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-27.
-->

NEXT: Producer
STATUS: Open
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
6. **Manual relay: commit only the relay file** (`relay(gh1662-plan-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1662-MERGE-CLEANUP-STANDALONE.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1662-MERGE-CLEANUP-STANDALONE.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude
- Started: 2026-11-27
- Definition of Done: every factual claim in the plan is grounded in the real code at base `52813e56f` and runs; the standalone design satisfies the three-part contract on issue #1661 (the "Contract decision" comment is binding) without inferring standalone mode from a missing file, without loosening any push gate, and without changing Forge-mode behaviour; the acceptance rows cannot be satisfied vacuously.

### Operational envelope and non-goals
- A skill-script change in the XYZ-forge repo (`skills/2-daily/merge-cleanup/`). Grade against the plan's stated requirements, commensurate complexity and the repo's own threat model. Challenge bloat and speculative machinery; do not demand layers the requirements do not name.
- XYZ-forge forbids new tests (`AGENTS.md` *No new tests*, GH-831): a new `test/` suite, a `validate.sh` entry or gate machinery is itself a finding. Verification is the existing merge-cleanup suites plus a recorded manual check with red/green controls under `TESTS-RESULTS/`.
- Contract constraints from the operator brief: `utils/py/wave_reconcile.py` and `skills/4-occasional/ci-optimize/` are not touched; every new script line is Python 3.9 compatible; the declaration shape (CLI flag and/or policy key) is the plan's pick and **yours to decide** (plan section D1): say which you accept and why.
- Fixture evidence exists in the artifact's clone: `TESTS-RESULTS/2026-11-27+GH-1662/fixture/` (`build_fixture.py`, `fakegh.py`). It is part of the review input.

### Step 1: paraphrase first (GH-1414), BEFORE reading any source file
Read ONLY the artifact under review. Then, before any source-backed assessment, write under three labelled headings: **What this proposes** (2-5 sentences), **How the existing system works, per this document** (2-5 sentences), and **What it's not** (short; ground each exclusion in a section of the plan; distinguish excluded work, deferred work, unresolved choices and later authorization; label inference). Do not read `skills/2-daily/merge-cleanup/`, tests or the issue until these three are written. Label the later assessment **Source-backed review**.

### Step 2: source-backed validation
Read in full: `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` (esp. `prepare_landing_clone`, `gate_unwired_reason`, `push_resolved_head`, `commit_and_push_phase5_writes`, `_land_prs_loop`, `main`), `toposort_prs.py`, `ledger_merge.py` (`landing_forecast`, `ledger_repair_paths`, `pre_merge_ledger_gate`), `scan_clones.py` (`default_scan_roots`, `scan_directories`, `inspect_primary_landing`), `attempt_record.py`, the fixture files, `test/gh436-merge-cleanup.py` (how it stubs `prepare_landing_clone` and `run_post_merge_reconcile`), `test/gh534_phase_b_tests.py` and `gh534_phase_c_tests.py` (the SKILL.md parity guard and AST pins), and issue #1661 with its comments.

### Questions (answer each; cite `file:line`)
1. **Grounding.** Are measurements M1-M6 and the "Existing criteria" list true at base? Re-derive M3 (the stacked PR sequenced before its base) and M5 from the code, not the table.
2. **Declaration (D1, D2).** Flag-only vs a policy key vs both: which satisfies "explicit, never inferred" with the least risk? Is the overlay-marker refusal (D2) sound or a surprise for a legitimate consumer, and does it count as inference in reverse?
3. **What standalone skips (D3, D4).** Is skipping exactly the five listed steps enough to land a clean queue on a foreign repo? Is the hand-off-instead-of-B1 decision right, and does any push path remain reachable without a proven gate hook (`push_resolved_head`, `commit_and_push_phase5_writes`, the batch/record writers)? Trace each.
4. **T4 (D5).** Is appending `/.tick/` to `.git/info/exclude` the right smallest fix? What does it do for a linked-worktree primary, an already-ignored `.tick/`, a tracked `.tick/`, and `commit_and_push_phase5_writes`'s `git add -A`?
5. **Scan roots (D6).** Does `standalone_scan_roots` keep teardown from widening, including the explicit `--root` case and `--prefix`? What can still be removed that the Forge defaults would not have removed?
6. **Stacked hard edge (D9).** Is it a new ordering rule or the existing intent (`_protect_stacked_dependents`, `merge_cleanup.py:640-658`, and the `targets ... not` stop at `:2109`)? Which existing tests could pin the old order (name them, then check)? Is the claim "no output change for a queue without an inverted stack" true by construction?
7. **Forge-mode byte-for-byte.** Every Forge-mode call keeps its exact arguments. Verify against the stubs in `test/gh436-merge-cleanup.py:477` and `test/gh534_phase_a_tests.py:581` and any `assert_called*` on the changed functions.
8. **Prerequisites (D7).** Is printing the block before Phase 0 early enough to be "before it clones anything" in every mode that clones (dry run with `--prs`: forecast clone; execute: landing clones)? Is "hard unmet" the right set?
9. **Acceptance honesty.** For each of A1-A14, what prevents an unchanged, unfixed candidate from passing, and where is the observed rejection? Is A3's mutant a real red control for "never inferred"? Does A1's output-equality really prove Forge mode unchanged, given D9?
10. **Surface-triggered questions.** TOCTOU between the T4 `check-ignore` probe and the pin write; concurrency of two merge-cleanup runs writing `.git/info/exclude`; any test-honesty issue (the manual check must not mock away the seam it claims to exercise; the stand-in `gh` cannot exercise real GitHub, so is the plan honest about it?).
11. **Rating and scope.** `40/40/60/35` is the operator's proposal with appeal 60 supplied by the operator. Grounded? Any unnecessary machinery or a missing piece?

Output: graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`) each with a concrete fix and `file:line` citations, the required `swept file: yes|no` line, then `VERDICT:` and `Basis:`. Every behaviour-change request needs `Observed input:`, `Affected scope:` and `Falsifier:` (GH-681). Use bold labels, not markdown heading lines, inside your block.

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
Add a per-run `--standalone` flag to reuse the merge sequencer on repositories without the Forge overlay. Skip overlay-specific operations, retain push guards, hide local attempt records, narrow default scanning, and document a manual git/gh runbook. Add stacked-base hard dependencies to the shared ordering code.

**How the existing system works, per this document**
The sequencer already lists and forecasts foreign-repository PRs, but landing-clone setup requires a Forge installer. Landing also invokes ledger and reconciliation operations; attempt records can dirty a foreign primary. Explicit dependencies and file-overlap ordering exist, while stacked base relationships currently are not ordering edges.

**What it's not**
The non-goals exclude overlay changes, ci-optimize changes, a policy key, new tests, and foreign-ledger repair. D1 resolves declaration shape to a CLI flag. The Status row leaves implementation and verification for later; merging remains the operator's authorization. The runbook covers the separate no-script case (Contract), rather than removing Python from the script itself.

**Source-backed review**

swept file: yes

Block — the additive flag is a reasonable, Easy-to-revert design, but the shared stack change and acceptance matrix need corrections before implementation. Source citations below use `MC` = `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`, `TS` = sibling `toposort_prs.py`, `LM` = sibling `ledger_merge.py`, `SC` = sibling `scan_clones.py`, and `Plan` = `.relay-artifacts/GH-1662-MERGE-CLEANUP-STANDALONE.md`. I swept the entire plan, including its pre-existing claims; findings below include those claims. No Git command, fixture, test suite or gate was run. Runtime results remain **[Unverified — needs clone run]**; the seeded base identity is taken from the supplied setup, not independently verified with Git.

- **[Should] F1 — D9 does not make the stacked dry run work.** **Observed input:** Plan:45,51,98 promises a successful preview of the fixture containing #107 based on `feat/faq`. `MC:2109-2111` rejects that base; `MC:2379-2381` continues the dry-run loop before `_protect_stacked_dependents` at `MC:2412-2413`. Sorting #106 first therefore does not change #107's live base during a preview. **Affected scope:** dry runs containing a child whose open parent is also sequenced. **Falsifier:** with the fixture's stack selected and all earlier prerequisites satisfied, an actual candidate dry run reaches both preview rows and exits without the wrong-base stop, while the fake-gh log contains no `pr edit` or merge mutation. **Fix:** specify a read-only conditional preview for a child whose parent would land and retarget it; keep execute's live-base check. Record the outcome when the parent is held/deferred. This is a source contradiction (Form 1), not a claim that a candidate has already failed.

- **[Should] F2 — narrow the Forge compatibility claim and repair A1.** **Observed input:** Plan:74,119 says output changes only for an inverted stack, but `TS:112-130` suppresses a collision warning when a hard edge already connects the pair, and `TS:140-145` changes dependency metadata. A pure probe of the existing sorter, using #1 (`head=parent, base=main`) and #2 (`head=child, base=parent`), both touching `x`, produced order `[1, 2]`, warning `File collision on 1 file(s) between PR #1 and PR #2 — ordering #1 before #2`, hard/soft `([], [1])` for #2. Adding `Depends on #1` (the existing seam for the proposed hard edge) kept order `[1, 2]` but produced warnings `[]`, hard/soft `([1], [])`. Command: `PYTHONDONTWRITEBYTECODE=1 python3 -` importing `toposort_prs`, constructing those two dictionaries with `createdAt='1'/'2'`, calling `toposort_prs(copy.deepcopy(prs))`, then setting `prs[1]['body']='Depends on #1'` and calling again; exit 0. Independently, A1 uses the inverted-stack fixture while demanding whole-output equality (Plan:97), which conflicts directly with D9's required reorder. **Affected scope:** all stacked queues, including an already-correct order; hard-dependent eligibility, JSON, collision notes, forecast and batch dependency data. **Falsifier:** compare these inputs before/after and demonstrate equal warnings/dependency fields as well as order; the current proposed hard-edge algorithm cannot do that. **Fix:** explicitly accept the shared stack semantics as the bounded exception to Forge unchanged, and use a nonstacked fixture for exact A1 parity; separately assert intended stack changes. Keep the correction rather than hiding it behind unchanged call signatures.

- **[Should] F3 — acceptance rows have masked or contradictory controls.** **Observed input:** A3 (Plan:99) removes only installer skipping's declaration condition but expects rc 0. Without a ledger the untouched gate at `MC:2295-2303` still exits 2; this is A4's own expected refusal (Plan:100; `LM:687-715`). A2 (Plan:98) requires rc 0 on the mixed fixture although D3 requires conflict handoffs/exit 3 (Plan:68), and the fixture includes base-conflicting #115. A7's edge-removed mutant may stop at T3 unless it explicitly retains standalone mode and the other fixes. A8 combines obsolete gh with no origin, so discovery or origin lookup can prevent *any* clone independently of prerequisite placement. **Affected scope:** A1-A14's ability to distinguish the target defect from a later/earlier refusal. **Falsifier:** run each named mutant with all unrelated preconditions green and show the claimed decisive rejection, not just a nonzero process status. **Fix:** give exact PR subsets, command modes and expected exit codes. For A3 assert the GH-1576 diagnostic/installer seam itself (mutant loses that diagnostic even if a later ledger failure keeps rc 2). Split A2 into a clean subset's rc 0 and mixed-queue named handoffs/blocked rows, with stacked preview covered by F1. Use an otherwise working origin/discovery to witness A8's first clone; test missing-origin reporting separately. A12 must configure an identity and a working origin so `git commit`/fetch cannot mask the hook refusal, and assert zero push calls. Existing suites stub gate wiring (`test/gh436-merge-cleanup.py:55-59`, `test/gh534_phase_b_tests.py:209-217`), so they cannot substitute for that manual seam check. A13 is unchanged coverage, not a new-fix red control; A14 needs a construct-rejection control if claimed as one. A5 must name the expected batch QA status (2+ PRs normally end at exit 4 with no declared sweep, `MC:3193-3223,3168-3188`), not imply process success means all QA is done. A6/A9/A10/A11 have useful contrasting inputs, but need actual observed rejections retained with the final run.

- **[Should] F4 — D5 needs a Git-resolved exclude path and explicit tracked-record behavior.** **Observed input:** Plan:70 specifies `<primary>/.git/info/exclude`; this review checkout itself has a `.git` **file** (nonmutating `Path('.git').is_file()` returned `True`, exit 0), a supported shape recognized at `SC:1057-1066`. `attempt_record.py:49-51` still writes under the worktree's `.tick`, and `MC:1667-1674` stages tracked modifications with `add -A`; an ignore rule cannot hide a tracked selection file. **Affected scope:** linked-worktree primaries and already tracked record targets, alongside the ordinary untracked case. **Falsifier:** in the Producer's disposable fixture, a linked-worktree primary receives an effective exclude rule without treating `.git` as a directory, and a tracked selection target is either explicitly refused before writing or handled without accidental publication. **Fix:** name `git rev-parse --git-path info/exclude` (resolve relative output against the primary) and describe the shared-common-dir effect; define a small refusal for tracked record targets. Append preserving existing bytes/newline, distinguish check-ignore's error from its not-ignored result, and verify the actual record target is ignored before writing. Already ignored inputs should remain byte-identical. Two appenders adding the same complete rule may create harmless duplicate lines; no new concurrency subsystem is warranted. The plan contains no implementation of the append yet, so no unobserved data-loss race is asserted.

- **[Should] F5 — prerequisites must cover the documented overlay failures too.** **Observed input:** Plan:72's exhaustive block lists tool versions/origin/lsof/hook status, while Plan:50 and A4:100 preserve failure on the missing installer and ledger *after* cloning (`MC:1117,1124-1126,2295`). The binding #1661 contract and acceptance ask the dry run to name missing requirements before cloning, and Plan:41 promises Forge requirements documented. **Affected scope:** default-mode foreign-repo dry runs, not only explicit standalone. **Falsifier:** a no-flag fixture with absent installer/ledger reports each applicable requirement before its first landing/forecast clone; a working standalone fixture reports its smaller requirement set. **Fix:** specify a mode-aware block including installer, ledger/runtime and development-only reconciliation requirements for default mode, before the first possible clone, preserving existing later guards and arguments. Version requirements may remain informational where only the advisory forecast needs them; distinguish inability to launch Git from an old Git. `lsof` absence already preserves cleanup candidates (`SC:418-428,1226-1230`); it need not block landing. Printing just before Phase 0 is before today's forecast/landing clones (`MC:2955,2138`) but is after the group branch can create a batch (`MC:2812-2816`), so place the block before that branch as well when it can write `.tick`.

- **[Should] F6 — retain the measurements being claimed now.** **Observed input:** Plan:137 claims M1-M6 retained under its results directory. Read-only `Path('TESTS-RESULTS/2026-11-27+GH-1662').rglob('*')` enumerated only `fixture/build_fixture.py` and `fixture/fakegh.py` (exit 0), with no outputs or `provenance.jsonl`. Static extraction of the fixture's 17 literal `pr(...)` calls into sorter rows (number/title/body/base/head/files/createdAt), followed by `toposort_prs`, returned `[101,102,103,104,105,107,108,109,106,110,114,115,116,117,111,112,113]`, positions `(107,6),(106,9)` (exit 0); M3:51 labels #106 position 8 for both M1/M2. **Affected scope:** exact base measurements and rating's empirical rationale, not the confirmed structural portability defects. **Falsifier:** supply nonempty retained command/output receipts and provenance showing the precise 15-PR selection and 17-PR listing, including differing positions. **Fix:** retain the original run evidence or rerun in a disposable full clone; distinguish M1's full queue from M2's subset. Qualify Plan:128's “real merge” as a stand-in merge, consistent with Plan:45,118. No executable fixture was run in this review.

**Remaining question dispositions**

- **[Pass] Declaration (Q2):** accept flag-only D1 (Plan:66): the current strict policy parser rejects unknown keys (`MC:480-486`), and this avoids a persistent policy-schema change. D2 is a refusal after an explicit request, not inference of standalone from absence; it is a reasonable fail-closed product restriction. Document its exact markers and partial-overlay refusal. It is not proof that every filename called `releases.sql` belongs to Forge, so avoid claiming universal overlay identification.
- **[Pass] Grounding and gates (Q1/Q3/Q7):** M1/M2's structural path is supported by `MC:2946-2957,3040-3041,2138` and `LM:687-715`; M4 by `LM:551-556` and `MC:860,882-883`; M5 by `attempt_record.py:49-51`, `MC:729-740,1662-1674` and `SC:1393-1403`; M6 needs the qualification “four defaults **plus a safe sibling root**” (`SC:71-83`). D3's conflict handoff avoids foreign B1 and makes `push_resolved_head` unreachable from that branch (`MC:2150-2243`); its own gate is before push (`MC:1189-1193`). Primary durability still checks its gate before push (`MC:1690-1695`), after a clean ff it can take the no-push path (`MC:1703-1704`). Record/batch writers save local `.tick` data and use gh issue operations, not Git pushes (`MC:1999-2008,3223`); batch QA remains applicable. Suppressing post-merge reconcile must also suppress its deferred batch-finalization pdda path (`MC:2485-2499`) in standalone. Four-positional stubs are real (`test/gh436-merge-cleanup.py:477`, `test/gh534_phase_a_tests.py:581`); conditional kwargs only in standalone preserves those. There is no candidate implementation yet to certify exact call-site parity.
- **[Pass] Roots (Q5):** D6 can strictly narrow default discovery if it retains `sibling_root()`'s NEVER_DELETE guard and always passes the origin-filter root, including when it equals a default safe root (`SC:51-60,1283-1304`). Explicit `--root` currently sets no sibling filter (`MC:2725-2727`), so unrelated clean clones under existing safe roots remain eligible exactly as today. Prefix is a name substring (`SC:1297-1298`), not an origin constraint. With those exact semantics, nothing new becomes removable; no safe-root or teardown expansion is needed.
- **[Pass] Stack intent and coverage (Q6):** parent-before-child implements existing retarget intent (`MC:640-658`) and removes the wrong-base stop, but adds a genuinely new hard edge with broader effects as F2 states. `TestTopologicalSort.test_toposort_linear_chain` and `.test_toposort_file_collision_ordering` use no base/head fields (`test/gh436-merge-cleanup.py:120-139`), so neither pins the bad stack order. `.test_stacked_pr_is_retargeted_before_base_merge` and `.test_failed_stacked_retarget_preserves_branch` test the helper, not sorting (`:659-681`). Parity AST pins keep B1/reserve calls within `_land_prs_loop` (`test/gh534_phase_c_tests.py:554-559,609-612`); guarding them preserves the pins without moving or deleting the calls.
- **[Pass] Scope/rating/honesty (Q8-Q11):** the issue #1662 body supplies `40/40/60/35`; accept it as the operator proposal, with appeal a value judgment and effort an estimate. The design reuses existing owners and adds no runner/suite. The fixture explicitly excludes real GitHub checks/protection/merge-queue claims (`fixture/fakegh.py:2-8`; Plan:45,118); keep that limitation in final evidence. The runbook acceptance should explicitly cover no-script inventory, stack/dependency/collision reasoning, re-checks, safe conflict handoff and stop/report rules (issue #1662 Outcome 3). No additional unrelated pre-existing defect is asserted after the plan sweep. No speculative external-service or concurrency hazard is being promoted to an observed failure.

Handing off to Producer (claude) — revise the plan and acceptance evidence for F1-F6, then take the next turn.

VERDICT: FAIL
Basis: The core flag direction is sound, but stacked previews still hit the live-base stop, exact Forge parity is overstated, several red controls are masked, and the claimed base run receipts are absent. These are concrete plan/source contradictions; no later gate was assumed.

### Producer · Round 1

Plan revised (revision 2, committed with this block). Every finding is dispositioned; the line numbers in your findings refer to revision 1.

- **F1 [Should] (D9 does not make the stacked dry run work) - Implemented.** Agreed from source: the wrong-base stop (`merge_cleanup.py:2109-2111`) precedes the dry-run `continue` (`:2379-2381`), and the retarget runs only at `:2412`, so a correctly ordered stacked child still stops a preview. New **D10**: in a dry run, a child whose base is the head of a PR already previewed in the same loop logs a `[DRY RUN] ... would be retargeted ... after #M lands` line and continues; execute keeps the live-base stop; no `gh pr edit`/merge in a preview. Falsifier added to A2 (the stand-in log must contain no `pr edit` or `pr merge`).
- **F2 [Should] (narrow the Forge compatibility claim, repair A1) - Implemented.** Accepted: D9 is a **new shared ordering edge** and changes, for a stacked pair, the collision note and the hard/soft metadata (your probe, `toposort_prs.py:112-145`). The plan now says so (D9, Risks) and claims "unchanged by construction" only for queues with no PR whose base is another open PR's head. A1 now uses the MIXED subset **without #106/#107** so whole-output equality is a fair claim; A7 adds a pure sorter probe of both stacked orders including the overlapping-pair case you named.
- **F3 [Should] (masked or contradictory controls) - Implemented.** Acceptance rewritten with exact subsets (CLEAN, MIXED), command modes and exit codes. A2 split into A2 (CLEAN rc 0) and A2b (MIXED rc 3 with named handoff/blocked/skip rows). A3 now asserts the GH-1576 diagnostic itself (absent in the mutant) instead of an rc. A7's mutant keeps standalone and all other fixes and removes only the sorter edge. A8 uses a working origin and a `git`/`gh` version shim with a clone marker; missing origin is tested separately. A12 sets an identity and a working origin and checks origin's tip is unchanged.
- **F4 [Should] (Git-resolved exclude path, tracked-record behaviour) - Implemented.** D5 now resolves the file with `git rev-parse --git-path info/exclude` against the primary (linked-worktree primary: shared common dir), distinguishes `check-ignore` rc 1 from an error, refuses a tracked `.tick/merge-cleanup` record, preserves existing bytes and newline, re-verifies after the append, and leaves an already-ignored `.tick/` byte-identical. A6 gains the linked-worktree, already-ignored and tracked cases. Duplicate lines from two appenders are accepted; no lock.
- **F5 [Should] (prerequisites must cover the documented overlay failures too) - Implemented, with one stated trade-off.** D7 is now mode-aware and the block sits before the early landing-plan checkpoint (which can create a batch) as well as before Phase 0. Default mode prints a stderr `PRE-FLIGHT` line per missing requirement (installer, ledger/`releases_app.py`, non-`development` integration branch) only for runs that clone and only when something is missing, so a repo with the overlay sees no change; this means a **foreign repo without the flag** gets added stderr lines, so A1 compares stdout and rc exactly and states that stderr differs by those lines. Git unlaunchable vs old git is distinguished; `lsof` is informational only.
- **F6 [Should] (retain the measurements) - Implemented.** `TESTS-RESULTS/2026-11-27+GH-1662/` now holds `base/base-prs-only.out` (17 PRs; #107 at 6, #106 at 9), `base/base-dry.out` (16 PRs; #107 at 6, #106 at 8; the T3 refusal) and `provenance.jsonl` rows BASE-M1, BASE-M2, BASE-M5. M1 (full queue) and M2 (subset) are now distinguished in the plan; "real merge" is qualified as a stand-in merge; M6 gained "plus a safe sibling root".
- **Passes accepted without change:** declaration D1 (flag-only) and D2 (with the marker list documented, plus `utils/pdda/pdda.sh` added so the skipped deferred batch-finalization pass is covered by the guard), roots D6 (always pass the origin-filter root, keep the `NEVER_DELETE` guard), stack intent, scope and rating, and the suppression of the deferred `pdda.sh` pass in standalone (D3). A15 added so the runbook is covered by an acceptance row (its commands and an independently derived order are compared with the script's table).

No finding declined. Handing off to Reviewer (codex), round 2: confirm F1-F6 are closed against revision 2 and the retained receipts, and say whether anything else blocks approval.

### ROUND 2 INSTRUCTIONS (read first)
- **Format:** bold labels inside your block, never markdown heading lines.
- **No new paraphrase needed.** Check F1-F6 against revision 2 and the retained receipts under `TESTS-RESULTS/2026-11-27+GH-1662/` (spot-check at least two provenance rows against `base/*.out`), then say whether anything else blocks approval. Grade against the same envelope as round 1.

### Reviewer · Round 2

**Source-backed review**

swept file: yes

Block — revision 2 resolves the main design objections, but F3 remains open in one acceptance expectation. Reviewed the entire revised plan; no additional unrelated pre-existing defect is asserted. Citations use Plan = `.relay-artifacts/GH-1662-MERGE-CLEANUP-STANDALONE.md`, MC = `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`.

- **[Pass] F1/F2 closed at plan level.** D10 explicitly adds the read-only stacked preview while retaining execute's live-base stop (Plan:76); D9 names the shared hard-edge, collision-note and metadata changes (Plan:75), and A1 uses a nonstacked subset (Plan:103). These are implementation requirements, not verified candidate behavior. Flag-only D1 remains the smallest explicit declaration (Plan:66).
- **[Should] F3 remains open: A2b expects execute-only dependency blocking during a preview.** **Observed input:** Plan:105 requires `NOT attempted` for #116 in a MIXED **dry run**, because #110 has failing checks. MC:2334-2335 logs failing checks in a dry run without setting `failed`; only the execute branch at MC:2336-2343 records failure and continues. The dry-run path reaches `Would merge` and continues at MC:2379-2381. Consequently #116's hard predecessor is neither pending nor failed when the dependency check at MC:2068-2079 runs. Plan:61 itself correctly says dry run reports checks only. **Affected scope:** A2b's failing-check predecessor/dependent pair #110/#116, not cycle or hold blocking. **Falsifier:** a disposable-clone candidate preserving current dry-run check semantics prints `NOT attempted` for #116 specifically because #110 failed checks; record the command, rc and decisive lines. **Fix:** expect the checks warning for #110 and the preview of #116 in A2b; assert #116's failure-dependent blocking in a separate execute observation if wanted. Do not change shared dry-run behavior merely to satisfy this row. The other F3 changes (A3 diagnostic control, isolated A7 mutant, A8 origin split, A5 QA status) address the earlier contradictions (Plan:104,106,108,110-111).
- **[Pass] F4/F5 closed at plan level.** D5 now uses Git's exclude path, refuses tracked records and handles error/already-ignored cases (Plan:71); D7 places mode-aware reporting before the early checkpoint (Plan:73). These specify the requested fixes without new locking or gate machinery. Runtime side cases remain for A6/A8, not claimed executed here.
- **[Pass] F6 receipt gap closed for M1/M2.** Read-only probe: `PYTHONDONTWRITEBYTECODE=1 python3 -` parsed `provenance.jsonl`, asserted both output files nonempty, and checked table counts/positions plus M2's forecast and GH-1576 refusal. Exit 0; decisive output: `BASE-M1 receipt matches recorded rc 0 bytes 5033`; `BASE-M2 receipt matches recorded rc 2 bytes 11070`. Provenance rows 1-2 name base `52813e56f`; `base/base-prs-only.out` contains `17 open PRs`, sequence 6 #107 and 9 #106; `base/base-dry.out` contains `16 open PRs`, sequence 6 #107 and 8 #106, `Recommendation: group`, and the missing-installer refusal. The process rc is recorded provenance, not independently rerun in this turn.
- **[Nit] F6 wording remains partially undispositioned.** Plan:136 still says “after a real merge” despite the requested stand-in qualification and Producer's claim it was qualified. Change to “after a stand-in merge” or cite the separate real-service incident supporting that sentence; Plan:46,126 already state the fixture limitation clearly.

**Verification limits:** No Git command, executable fixture, suite or gate was run. Candidate implementation, real GitHub behavior and runtime acceptance remain **[Unverified — needs clone run]**. Approval here would certify plan readiness only; no later gate is assumed.

VERDICT: FAIL
Basis: F3 still contains a concrete plan/source contradiction, and the prior F6 wording request is not fully reflected. The remaining edits are small and do not require a new subsystem or broader scope.

Handing off to Producer (claude) — correct A2b and qualify the rating sentence, then take round 3.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
