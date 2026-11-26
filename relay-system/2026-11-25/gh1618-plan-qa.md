# RELAY · GH-1618 plan QA: correct the 'ungated' claim in the GH-1606 documents
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
6. **Manual relay: commit only the relay file** (`relay(gh1618-plan-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1618-UNGATED-CLAIM-CORRECTION.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1618-UNGATED-CLAIM-CORRECTION.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude
- Started: 2026-11-25
- Definition of Done: every factual claim in the plan (and in the correction note it proposes) is grounded in the real code at base `086b657ea` and does not overclaim; the plan keeps what was measured and only supersedes the wrong inference; the acceptance checks can detect an uncorrected or over-corrected document; nothing but documentation text changes.

### Operational envelope and non-goals
- Documentation-only correction of two already-merged files in the XYZ-forge repo. Grade against the plan's stated requirements and commensurate complexity; the repo's own threat model governs. Challenge bloat; do not manufacture scope.
- XYZ-forge forbids new tests (`AGENTS.md` *No new tests*, GH-831): a new `test/` suite, `validate.sh` entry or gate machinery is itself a finding. The probe script under `TESTS-RESULTS/2026-11-25+GH-1618/` is a manual check with `provenance.jsonl`, not a suite.
- The plan's non-goals (frontmatter `non_goals`) are the author's; say which you accept and which you contest, with evidence. Operator-set constraints: `provenance.jsonl` row `FINDING-phaseB-pre-existing` stays unchanged; no code, tests or gate registration; no absolute home paths.

### Step 1: paraphrase first (GH-1414), BEFORE reading any source file
Read ONLY the artifact under review. Then, before any source-backed assessment, write under three labelled headings: **What this proposes** (2-5 sentences), **How the existing system works, per this document** (2-5 sentences), **What it's not** (short; ground each exclusion in a plan section; separate excluded work, deferred work, unresolved choices and later authorization; label inference and missing boundaries rather than inventing non-goals). State the input boundary: "paraphrase written from the artifact only." Only afterwards read the code and label the rest **source-backed**. Use **bold labels**, never markdown heading lines, inside your review block (the driver counts a block's body only up to the next heading line).

### Step 2: source-backed validation
Read: `test/gh436-merge-cleanup.py` (lines 36-45 and 1375-1390), `validate.sh` around line 96, `test/gh534_phase_b_tests.py` (`LedgerFixture`, `TestPhase5EndToEnd`), `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` around lines 2160-2215 (`gate_toolchain_fault_reason`, `attempt_record.reserve`), the receipts `TESTS-RESULTS/2026-11-25+GH-1618/` and `TESTS-RESULTS/2026-11-25+GH-1615/`, and the two target files (`PROJECT/3-COMPLETED/GH-1606-MERGE-CLEANUP-PUSH-ENVFAULT.md`, `TESTS-RESULTS/2026-11-25+GH-1606/SUMMARY.md`, `provenance.jsonl`) in your worktree.

### Questions (answer each; cite `file:line`)
1. **Premise.** Is it true that the gate reaches the phase B/C tests through `gh436` (`import *`, `validate.sh:96`)? Is there any way the gated run does NOT execute them (name collision, skip, `load_tests`)? Is the plan right that the original measurement (standalone red at `b479f74e0`: 39 tests, 14 failures, 1 error, cause GH-1576) is a separate true fact?
2. **No overclaim.** The proposed correction note says a gated-collected phase B test reaches `attempt_record.reserve` on the healthy path, and that no gated test drives the toolchain-fault ordering. Do the retained probe and `git grep` actually support exactly that, and is the wording no broader than the evidence? Is anything in the note unverified (the plan says the probe ran at `086b657ea`, not at the GH-1606 base)?
3. **Complete list of wrong sentences.** Grep the two target files (and `provenance.jsonl`) for the same claim in other wording ("not referenced", "never saw", "withdrawn as a witness", "red at base", "no suite drives"). Does the plan's edit list cover every site? Is any claim the plan proposes to strike actually true and worth keeping?
4. **Does not rewrite history.** Does the plan keep the original observation and wording (struck through) and add a dated note, and leave `provenance.jsonl` byte-identical while the SUMMARY note supersedes its title word?
5. **What prevents an unfixed candidate being reported as delivered.** AC-1 to AC-5: would each reject an uncorrected or over-corrected document, and where is the observed rejection (the plan says AC-1's red control is the same grep at `origin/development`)? Are admission probes distinguished from final acceptance?
6. **PDDA and governance.** The doc stays in `PROJECT/3-COMPLETED/`; the plan doc `PROJECT/2-WORKING/GH-1618-...md` and its roadmap pointer row were created through `releases_app.py roadmap pickup`. Anything in the plan that would break PDDA front matter, the status table, or the hardcoded-path rule?
7. **Rating.** `15/10/40/90` (pri/sev/appeal/effort, effort = cheapness; appeal 40 is the operator's supplied value). Grounded?
8. **Surgical and DRY.** Smallest honest correction? Anything missing, or any unneeded machinery?

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

**What this proposes**
Correct two GH-1606 documents in place with a dated note and strikes around incorrect gate-coverage inferences. Preserve the standalone failure measurement and the original evidence receipt, and verify the resulting text before delivery.

**How the existing system works, per this document**
The gate registers gh436, which imports the phase A/B/C unittest classes and stubs the wiring check process-wide. A retained single-test probe reports a healthy-path reserve call; standalone phase B previously failed the wiring check.

**What it's not**
I accept the frontmatter exclusions: no runtime, suite or gate changes, no receipt rewrite, no revision of the original measurement, no reopening #1615 or editing the other PRs, and no redundant-stub removal. Status defers edits, docs validation and final QA until after plan QA; merge remains later operator authorization. No unresolved implementation choice is identified. Input boundary: paraphrase written from the artifact only.

**Source-backed — Block pending the bounded wording correction below.** Reversibility: Easy; only documentation wording changes. No runtime change is requested.

- [Should] R1 — Keep the negative coverage statement within what was measured. Artifact lines 42 and 65 turn a no-match search into “No gated test drives a toolchain fault” / “What no gated test drives is the toolchain-fault ordering.” The retained receipt only searches a helper identifier (`TESTS-RESULTS/2026-11-25+GH-1618/provenance.jsonl:3`); the single healthy-path probe explicitly “says nothing about a toolchain fault” (same file, line 2). A helper need not be named by a test to be reached indirectly: the reported healthy test at `test/gh534_phase_b_tests.py:429-435` calls `run_main()`, which reaches the helper and reserve at `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:2177-2201`. **Observed input:** the above concrete evidence/claim mismatch; reviewer command `rg -n gate_toolchain_fault_reason test` → exit 1, no output. **Affected scope:** the plan's Observed table, proposed note and shorter SUMMARY note; this is a request to bound a factual statement, not expand test coverage. **Falsifier:** a retained audit tracing all gated test inputs and seams, showing none supplies a fault on this path, would support the universal negative. **Fix:** say “The search found no direct test reference to the helper; fault ordering is demonstrated by GH-1606's manual driver, and gated fault-ordering coverage was not established by these checks.” Alternatively retain a sufficient source audit. No new suite or runtime probe is needed.
- [Pass] Q1 — The gate chain is real: `validate.sh:96` registers the shell wrapper; `test/gh436-merge-cleanup.sh:11-12` invokes the Python entry point; `test/gh436-merge-cleanup.py:1382-1384,1593` imports the classes and invokes unittest. A read-only AST scan of the four Python modules (exit 0) found no top-level `load_tests` and no duplicate locally defined Test-class names; source search found no skip decorators. The wrapper intentionally skips non-Forge/vendored contexts through `require_forge_root` at line 11; registry selection also determines whether gh436 runs. In this Forge gate context the retained collection/pass receipts support the premise. Original standalone red remains a separate recorded fact: `TESTS-RESULTS/2026-11-25+GH-1606/provenance.jsonl:23` records b479f74e0, 39/14/1 and GH-1576.
- [Pass] Q2 — The positive reserve statement is correctly narrow: `TESTS-RESULTS/2026-11-25+GH-1618/probe_gate_reserve.py:16-29` counts the actual calls for exactly one named test, and its receipt at `provenance.jsonl:2` records one call each, OK, revision 086b657ea. This is retained producer evidence, not a reviewer rerun. The historical limitation is explicit at `TESTS-RESULTS/2026-11-25+GH-1618/SUMMARY.md:21-26`; keep that revision/limit explicit when incorporating the note. No claim of a new run at b479f74e0 is supported.
- [Pass] Q3/Q4 — The edit inventory covers the incorrect sites found by the scoped source search: target doc lines 30, 47, 131-134, 180, 214, 240 and target SUMMARY lines 38-39. The unqualified “no suite drives B1 reservation” in the whole table row at line 47 must be included in its strike, not only its first cell. Keep the true standalone measurement at lines 48 and 128-130, and the true withdrawal of standalone phase B as an unchanged-green witness at lines 135-137, 180 and 214. Artifact lines 54-60 and 74 preserve the receipt and use dated notes/strikes rather than silently deleting that evidence; supersede both the title's “ungated” and the inference in receipt notes via the SUMMARY, without changing receipt bytes.
- [Nit] Q5 — Make AC-3's required added fact explicit in step 2: target SUMMARY has “39 tests” and “14 failures” at line 38 but no “GH-1576” anywhere. Read-only Python substring check → exit 0, decisive output `SUMMARY.md {'39 tests': True, '14 failures': True, 'GH-1576': False}`. Artifact line 86 says all three must survive in each file. State that the new shorter note adds the GH-1576 cause, or change AC-3 to require preservation where originally present plus the cause in the correction.
- [Pass] Q5 — AC-1 is a manual contextual review of search hits, not a grep-exit predicate: uncorrected target lines 30/47/131-134 and SUMMARY line 38 currently exhibit the disallowed unqualified hits; a corrected file still legitimately matches the grep. AC-2 inspects scope and receipt preservation; AC-3 guards measurement loss; AC-4 checks structure/paths; AC-5 compares output and claim scope (`artifact:84-90`). These are planned final acceptance, distinct from the existing admission receipts. The claimed origin/development red control was not independently rerun here because git is forbidden; retain the producer's final acceptance receipts rather than treating this plan review as delivery. I ran no gate, executable fixture or test.
- [Pass] Q6/Q7/Q8 — The plan preserves completed-doc location/frontmatter/status shape (`artifact:54-55`), matches the active-doc frontmatter/status requirements at `PROJECT/PDDA.md:56-77`, and introduces no absolute home path. Pickup and external issue/PR state are supplied context, not independently queried here. The low priority/severity, operator appeal 40 and high cheapness are proportionate to the documentation-only scope (`artifact:46-48`). The chosen in-place correction and existing receipt locations are surgical; accept all stated non-goals, with no additional machinery requested (`artifact:12-17,50-78`). No additional pre-existing defect in the reviewed plan beyond the findings above was identified.

swept file: yes

VERDICT: FAIL
Basis: The central correction is supported, but its universal negative about gated fault coverage exceeds the recorded search/probe evidence. Bound that wording; clarify the small AC-3 mismatch while updating the plan. This is plan QA only, not approval of implementation or merge.

Handing off to Producer (claude) — disposition R1 and the AC-3 nit, update the plan and evidence wording, then return for review.

### Producer · Round 1

- **R1 [Should] (bound the negative coverage statement) - Implemented.** Agreed: a no-match search for the helper's name does not show that no gated test reaches the fault path, and my own probe shows a test reaches the helper indirectly through `run_main()`. The plan's Observed row, the proposed correction note and the evidence `SUMMARY.md` / `provenance.jsonl` (row `NO-FAULT-TEST`) now say: the search found no direct test reference to the helper; the fault ordering is demonstrated by the GH-1606 manual driver; gated fault-ordering coverage was not established by these checks. No audit and no new probe were added (your fix option 1).
- **Q5 nit - Implemented.** AC-3 now says `39 tests` and `14 failures` must remain in both files (present before) and `GH-1576` must be present in both after the edit, with the SUMMARY note adding the cause it did not name before; plan step 2 states this.
- **Q3/Q4 advice taken:** plan step 1 now strikes the whole AC-table row at line 47 (all three cells, including "no suite drives B1 reservation or a toolchain fault"). The true standalone measurement (lines 48, 128-130) and the true withdrawal of standalone phase B as a witness (135-137, 180, 214) stay.
- **All Q1/Q2/Q6/Q7/Q8 `[Pass]` findings accepted** without change. The probe's revision and limit stay explicit in the note.

Handing off to Reviewer (codex), round 2: confirm R1 and the AC-3 nit are closed and say whether anything else blocks approval. Use bold labels, not heading lines.

### Reviewer · Round 2

**What this proposes**
Correct two merged GH-1606 documents in place, preserving the standalone failure measurement while superseding the incorrect gate-coverage inference. Add dated notes, retain struck original inferences, and leave the original provenance receipt unchanged.

**How the existing system works, per this document**
The registered gh436 entry point imports phase A/B/C test classes and stubs the wiring check process-wide. A retained probe at `086b657ea` ran one collected phase B test and counted one healthy-path reserve call. A helper-name search establishes only the absence of direct references, not absence of indirect fault coverage.

**What it's not**
Accepted exclusions: runtime/test/gate changes, rewriting receipts or measurements, reopening #1615 or editing #1614/#1617, and removing the redundant stub (artifact frontmatter lines 12-17). Implementation, docs checks and final QA remain subsequent work; merge requires later operator action (Status table). No unresolved choice is stated. Input boundary: paraphrase written from the artifact only.

**Source-backed**
- [Pass] R1 closed. Artifact lines 42 and 65 now explicitly say the search does not establish absence of gated fault coverage. This matches `TESTS-RESULTS/2026-11-25+GH-1618/provenance.jsonl:2-3` and `SUMMARY.md:15,19-26`. The positive claim remains one healthy-path test at the recorded revision, supported by the counter wrappers and selected test at `probe_gate_reserve.py:16-29`; no historical rerun is claimed. Concrete fix: none remaining.
- [Pass] Q5 nit closed. Artifact lines 60 and 86 explicitly require adding the GH-1576 cause to SUMMARY, while retaining the pre-existing counts in both documents. The existing SUMMARY's measurement is at `TESTS-RESULTS/2026-11-25+GH-1606/SUMMARY.md:38-39`. Concrete fix: none remaining.
- [Pass] Q1/Q2 premise and limits remain sound. `validate.sh:96`, `test/gh436-merge-cleanup.sh:11-12`, and `test/gh436-merge-cleanup.py:43,1382-1384,1593` establish registration, process stub, import and unittest execution. The wrapper's Forge-root check and registry selection qualify when that entry runs. The retained 227-test collection receipt (`GH-1618/provenance.jsonl:1`) and GH-1615 SUMMARY's base/candidate gated rows support actual collection/execution; no new name-collision/skip/load_tests issue was identified. Reviewer command `rg -n 'load_tests|@unittest.skip|@pytest.mark.skip' test/gh436-merge-cleanup.py test/gh534_phase_a_tests.py test/gh534_phase_b_tests.py test/gh534_phase_c_tests.py` returned exit 1, no matches. The fixture's missing-hook seed and scoped patch are visible at `test/gh534_phase_b_tests.py:181-210`; the end-to-end input calls `run_main()` at lines 429-435, and production probes before reserving at `merge_cleanup.py:2177-2193`. The separate original standalone 39/14/1 observation and GH-1576 cause remain recorded at `GH-1606/provenance.jsonl:23`. Concrete fix: none.
- [Pass] Q3/Q4 inventory and preservation remain adequate. Artifact lines 54-60 cover target doc lines 30, 47, 131-134, 180, 214, 240 and SUMMARY lines 38-39, including the whole incorrect table row. The standalone measurement and withdrawal as an unchanged-green witness remain true historical facts; artifact lines 58-60 preserve and qualify them. Artifact lines 65 and 74 retain struck inferences and supersede the receipt wording through SUMMARY rather than rewriting it. Concrete fix: execute this bounded edit list.
- [Pass] Q5 acceptance is appropriately manual and contextual. Artifact lines 84-90 distinguish final checks from retained admission measurements. The unedited target doc lines 30, 47, 131-134 and SUMMARY line 38 visibly supply AC-1's red input; grep success alone is not a pass. AC-2 checks scope/receipt preservation, AC-3 prevents measurement loss, AC-4 covers document structure/paths, and AC-5 checks factual scope against output. No git command, executable fixture, suite or gate was run this turn; the claimed origin/development red control was not independently rerun because git is forbidden. Final acceptance and its receipts remain implementation obligations, not assumed later results. Concrete fix: retain those results during delivery.
- [Pass] Q6/Q7/Q8: artifact frontmatter and Status comply with `PROJECT/PDDA.md:56-77`; lines 54 and 78 preserve completed-doc location and bound ledger changes. No absolute home path or new suite/gate is proposed. Pickup and external issue/PR state remain supplied context rather than independently queried facts. The documentation-only `15/10/40/90` rationale at artifact line 48 is proportionate, with appeal explicitly operator-supplied. The existing documents and evidence directory suffice; no additional machinery is warranted. No additional pre-existing defect was identified in the whole reviewed plan. Concrete fix: none.

swept file: yes

VERDICT: PASS
Basis: Both prior findings are closed by the revised wording. The full plan now keeps the measured facts, bounds the inference to its evidence, and provides proportionate final acceptance. Approval is for the plan, not completed implementation, qualification or merge.

Relay closed (Approved), no further turn needed.


### Attestation · relay-drive — 2026-11-26T02:40:23Z
task: RELAY-gh1618-plan-qa-r2
reviewer: codex
status: Approved
reviewed-head: 8a4bcf595c2c2ef1e6390d2cd0316f51ca827ff5
added-range: 21806+5222
added-sha256: 81fcb92ca27344d5696ee98f5e94a6487bb0d186cf85d2d07cc65d4a0ba484ee
gate-run: undeclared
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
