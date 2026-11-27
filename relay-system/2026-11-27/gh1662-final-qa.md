# RELAY · GH-1662 final QA: merge-cleanup standalone mode, stacked ordering, runbook
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

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
