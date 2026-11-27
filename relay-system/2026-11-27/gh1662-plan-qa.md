# RELAY · GH-1662 plan QA: merge-cleanup explicit standalone mode, git+gh-only sequencing, prose runbook
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-27.
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

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
