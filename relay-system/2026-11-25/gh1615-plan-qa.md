# RELAY · GH-1615 plan QA: move the GH-1576 wiring stub into the shared phase B fixture
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-25.
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
7. **Rating and decisions.** The plan re-rates `30/35/50/85`? No: `20/25/50/85` from the issue's `30/35/50/65`. Is the re-rate grounded? Is "no operator decision required" justified, or is a decision hiding?
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

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
