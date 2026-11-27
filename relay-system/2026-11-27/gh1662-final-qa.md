# RELAY · GH-1662 final QA: merge-cleanup standalone mode, stacked ordering, runbook
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-27.
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
6. **Manual relay: commit only the relay file** (`relay(gh1662-final-qa): <role> r<N>`); no push.
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
- Definition of Done: the implemented change satisfies issue #1662 (the contract on #1661) and the approved plan (`PROJECT/2-WORKING/GH-1662-MERGE-CLEANUP-STANDALONE.md`, plan QA approved round 3 in `relay-system/2026-11-27/gh1662-plan-qa.md`): sequencing works with only git and gh; landing works in an explicit standalone mode that is never inferred and keeps every push gated; a prose runbook (`skills/2-daily/merge-cleanup/STANDALONE.md`) lets an agent do the same by hand; Forge mode is unchanged except the accepted shared stacked-base semantics (D9, D10); the evidence substantiates each claim.

### Operational envelope and non-goals
- A skill-script change in XYZ-forge. Grade against the plan's requirements, commensurate complexity and the repo's own threat model; reject speculative machinery. XYZ-forge forbids new tests (`AGENTS.md` *No new tests*, GH-831): a new `test/` file, `validate.sh` entry or registry entry in the diff is a finding. The manual-check drivers under `TESTS-RESULTS/2026-11-27+GH-1662/` are recorded evidence, not a suite.
- Non-goals (plan frontmatter): no `wave_reconcile.py` or other overlay change, no `skills/4-occasional/ci-optimize/` change, no policy key, no inference from a missing file, no Forge-mode default change.
- **The change under review** is committed; the implementation diff is `relay-system/2026-11-27/gh1662-final-qa-scripts.diff` (scripts, SKILL.md, STANDALONE.md versus the base `52813e56f`). Read the changed files in full, not only the diff. You cannot run git; the Producer runs any probe you name in a disposable full clone.
- Evidence: `TESTS-RESULTS/2026-11-27+GH-1662/provenance.jsonl` (rows BASE-*, A1-A15 with revisions, commands and decisive output), `runs/` (normalised outputs), `run_controls.py`, `runbook_walk.py`, `fixture/`. Existing suites ran green in a disposable clone (rows A13-*).

### Step 1: paraphrase first (GH-1414), BEFORE reading any source file
Read ONLY this thread and the plan. Then write under three labelled headings **What this proposes**, **How the existing system works, per this document**, **What it's not** (2-5 sentences each; label inference). Do not read the diff, scripts or evidence until written. Label the rest **Source-backed review**. Use bold labels, not markdown heading lines, inside your block.

### Questions (answer each; cite `file:line`)
1. **Acceptance.** Is each of the plan's acceptance rows A1-A15 satisfied by a row in `provenance.jsonl`, and does the row's observed output actually establish it (not merely successful execution)? Pick three rows and check the retained `runs/` output against the claimed snippet. Is any red control vacuous (A3, A2-mut, A6, A7)?
2. **Never inferred; pushes gated.** Trace every path in the diff where `standalone` changes behaviour. Can any run reach a push from a clone or the primary without a proven gate hook, or skip the installer wiring without the flag? Does the overlay-marker refusal hold?
3. **Forge mode unchanged.** Every Forge-mode call keeps its exact arguments (`prepare_landing_clone`, `run_post_merge_reconcile`, `build_landing_forecast`, `landing_forecast`); the Forge forecast dict gains no key. Check against the suites' stubs (`test/gh436-merge-cleanup.py:477`, `test/gh534_phase_a_tests.py:581`). Is the D9/D10 shared change the only Forge-visible difference besides the stderr `PRE-FLIGHT` lines?
4. **Correctness and Python 3.9.** Read `ensure_tick_ignored`, `standalone_prerequisites`, `default_mode_preflight`, the `_land_prs_loop` branches, `standalone_scan_roots`, the toposort edge. Any 3.10+ construct, wrong return, TOCTOU or missed case? Is hand-off-instead-of-B1 consistent (keep_workdir, `failed`, exit 3)?
5. **Runbook.** Is `STANDALONE.md` consistent with the script's semantics (edges, order, skips, checks, mergeable polling, forecast and hubs, stop conditions), safe (no force-push, no branch deletion, no `--no-verify`, no hand teardown), and honest about what only the scripts do? Cite any statement the code contradicts.
6. **SKILL.md.** Is the new section accurate and compact; does the capability-table row and `--standalone` option keep the parity guard satisfied (`test/gh534_phase_c_tests.py` parity guard)?
7. **Scope, rating, duplicates.** Is `40/40/60/35` still right against the evidence? Is any duplicate subsystem or second writer present? Any accidental or out-of-scope file in the diff (run `git diff --name-only` is the Producer's: list what you see in the diff file)?
8. **Honesty.** Are the stated limits (stand-in `gh`, real GitHub not exercised, Python below 3.9, A15 shares an author) complete?

Output: graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`) with `file:line`, the required `swept file: yes|no` line, `VERDICT:` and `Basis:`. Behaviour-change requests need `Observed input:`, `Affected scope:`, `Falsifier:` (GH-681).

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
An explicit per-run standalone flag permits foreign-repository landing without Forge ledger/reconcile steps, retaining push gates. Shared stacked-base ordering and dry-run preview fix parent/child sequencing; a runbook supplies the manual alternative.

**How the existing system works, per this document**
The plan says git/gh already sequence and forecast foreign queues, but landing requires Forge installer and ledger machinery. It describes hard declared dependencies, soft file collisions, isolated landing clones and guarded pushes; stacked bases currently lack ordering edges.

**What it's not**
This does not infer mode from missing files, introduce a policy key, implement foreign ledger repair or alter overlays. Real GitHub behavior is explicitly outside the recorded verification; inference: fixture evidence alone cannot establish GitHub squash-stack behavior.

**Source-backed review**

swept file: no

The artifact and runbook were read in full, as were the sorter and changed branches. The full 7,275-line sweep of all six implementation/doc files is **not complete**; no whole-file clearance is claimed. No additional pre-existing defect was established in the portions examined. Full sweep remains required before approval.

- [Should] **F1 — branch-name equality invents stacked dependencies for fork PRs.** `skills/2-daily/merge-cleanup/scripts/toposort_prs.py:115-121` indexes every head by its short branch name, without repository identity. Two independent fork contributions from their respective `main` branches into upstream `main` therefore give #1 a hard dependency on #2. Selecting only #1 removes it altogether through `merge_cleanup.py:783-803`; holding #2 also blocks #1 through `merge_cleanup.py:2186-2197`. This is a Forge-visible difference outside genuine stacks. The runbook repeats the same false equivalence at `STANDALONE.md:92`.
  **Observed input:** Form 1, narrow pure-Python probe, exit 0, with decisive output `fork-main order/deps: [(2, []), (1, [2])]` and `listed={1}, effective sequence: []`:
  ```bash
  PYTHONDONTWRITEBYTECODE=1 python3 - <<'PROBE'
  import sys
  sys.path.insert(0, 'skills/2-daily/merge-cleanup/scripts')
  import toposort_prs as ts
  import merge_cleanup as mc
  prs = [dict(number=n, title='Fork contribution', body='',
              headRefName='main', baseRefName='main', files=[],
              createdAt='2026-11-27') for n in (1, 2)]
  ordered, _, _ = ts.toposort_prs(prs)
  print('fork-main order/deps:', [(p['number'], p['_hard_deps']) for p in ordered])
  print('listed={1}, effective sequence:', [p['number'] for p in mc.effective_sequence(prs, {1})])
  PROBE
  ```
  This uses the exact fields discovery currently supplies (`toposort_prs.py:33-35`); it cannot distinguish two fork heads from an upstream branch. No GitHub service, fixture execution or git command was used.
  **Affected scope:** automatic stacked edges when head/base names coincide across different repositories, especially the common fork-default-branch case; both modes, selection closure, forecast and dependent eligibility.
  **Falsifier:** two independent fork `main -> upstream/main` PRs must have no automatic hard edge, and selecting only #1 must retain `[1]`; an actual upstream `feat/parent` head with a child targeting that same upstream branch must still order parent first and block the child when the parent is unlisted. Current output fails the first predicate.
  **Concrete fix:** qualify stacked-parent matching with repository identity (obtain the necessary discovery metadata; do not guess from the short branch name), preserve real same-repository stacks, and update the prose rule. Check the related short-name matching at `merge_cleanup.py:645-647` and dry-run preview at `:2226-2233` for the same identity assumption. Retain a manual before/after probe with both fork and genuine-stack cases; no new suite.

**Answers to the requested questions**

1. **Acceptance/evidence.** Every A1-A15 ID has a passing receipt in `TESTS-RESULTS/2026-11-27+GH-1662/provenance.jsonl:4-26` (A13 split across five rows). These establish the recorded fixture cases, not all queues. Three retained-output spot checks match: `runs/A2-cand-standalone-clean-dry-py39.out:105-121` has four Would-merge lines plus the stacked preview, rc file `0`; `runs/A5-exec.out:89-120` has four MERGED witnesses and four clean-primary confirmations, `:150` says QA pending, rc file `4`; `runs/A10-overlay-guard.out:4` refuses the ledger marker, rc file `2`. The red-control definitions are non-vacuous: A3 checks the diagnostic rather than rc (`run_controls.py:217-220`), A2-mut checks the stacked stop (`:167-169`), A6 checks second-run NOT READY versus candidate readiness (`:340-346`), A7 retains the changed order/dependency fields (`runs/A7-sorter-probe.json`). They miss F1's cross-repository input.
2. **Declaration/pushes.** The wiring exception requires the flag and an absent installer (`merge_cleanup.py:1134-1140`); overlay refusal precedes the run (`:2887-2893`). Both push owners retain the gate check (`:1204-1208`, `:1805-1811`); A12's retained JSON reports refusal. The flag reaches roots, prerequisites/ignore, forecast repair classification, clone preparation, handoff, ledger gate and post-merge reconcile. No ungated push was established in these paths. This is source inspection plus retained evidence, not a fresh clone gate run.
3. **Forge behavior.** Conditional empty kwargs preserve the four-positional clone stubs (`merge_cleanup.py:2161-2162`, `:2258`; `test/gh436-merge-cleanup.py:477`, `test/gh534_phase_a_tests.py:581`). Forecast adds its key only when standalone (`ledger_merge.py:980-981`). F1 defeats the claim that only genuine stacks change behavior; otherwise the inspected diff preserves the default call arguments, including reconcile at `merge_cleanup.py:2578-2581`.
4. **Correctness/3.9.** A read-only `ast.parse(..., feature_version=(3,9))` over all skill scripts exited 0: `Python 3.9 grammar: all script files parsed`. This is syntax evidence, not runtime evidence. Retained dual-runtime results are at provenance `:5-6`. Handoff sets `failed` and `keep_workdir` (`merge_cleanup.py:2273-2282`), feeding exit 3 (`:2644-2668`). `ensure_tick_ignored` checks tracked records before ignoring, resolves the Git exclude path and rechecks (`:1562-1588`); retained linked-worktree/already-ignored/tracked cases are in `runs/A6-side-cases.json`. No concurrency guarantee beyond the plan's accepted duplicate-line behavior was established.
5. **Runbook.** It covers ordering, skips, polling, forecast, hubs, pin checks, remote merge witnessing and clean fast-forward (`STANDALONE.md:74-154`), and prohibits force-push, branch deletion, ungated pushing and manual teardown (`:67`, `:141-154`). Correct the stacked identity rule with F1. Minor existing prose discrepancy to reconcile while editing: `:130` says skip a wrong base while `:146` says stop; the script stops (`merge_cleanup.py:2233-2234`). No external-service hazard is being asserted from that wording.
6. **SKILL/parity.** The new mode section names the guarded skips (`SKILL.md:49-55`), the new row and option are at `:648`, `:656`. The parity guard checks its required capability set, rather than rejecting extra rows (`test/gh534_phase_c_tests.py:584-605`); the receipt for phase C reports 111 green (`provenance.jsonl:23`). This turn did not execute that suite.
7. **Scope/rating/duplicates.** The supplied diff lists exactly SKILL.md, STANDALONE.md and scripts ledger_merge.py, merge_cleanup.py, scan_clones.py, toposort_prs.py (diff headers at lines 1, 56, 216, 275, 654, 677). It contains no new test, overlay or ci-optimize path. Existing owners are extended rather than a second landing writer added. `40/40/60/35` remains a reasonable bounded assessment, but readiness is failing on F1; the evidence does not justify increasing confidence in fork queues.
8. **Honesty/limits.** The artifact's **Not verified** paragraph correctly discloses stand-in gh, real GitHub, below-3.9 runtime and shared authorship of A15. Add the uncovered fork-branch identity case until fixed. This review adds no claim of fresh suite execution, full qualification, exhaustive pre-existing-defect clearance or a later configured gate.  [Unverified — no citation]

VERDICT: FAIL
Basis: F1 is an observed selection/ordering defect in the shared D9 path, beyond the accepted genuine-stack behavior. Recorded acceptance cases pass but do not cover it; the full source sweep also remains outstanding, so approval would be premature.

Handing off to Producer (claude) — address F1, retain both fork and genuine-stack manual receipts, reconcile the noted stop/skip wording, and return for the remaining whole-file QA.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
