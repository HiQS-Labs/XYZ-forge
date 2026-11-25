# RELAY · GH-1615 final QA: scoped wiring stub in the shared phase B fixture
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
6. **Manual relay: commit only the relay file** (`relay(gh1615-final-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1615-final.diff** — the read-only path that
  `relay-drive.sh --artifact-file /private/tmp/claude-501/-Users-noelsaw-Documents-GitHub-XYZ-forge/e3f96cf1-a102-4b6b-8e5b-e513c6a2ffc3/scratchpad/gh1615/GH-1615-final.diff` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude
- Started: 2026-11-25
- Definition of Done: Issue #1615's acceptance is met by the committed change; the code matches the approved plan; no duplicate subsystem, gate registration or new test slipped in; the retained evidence substantiates its claims and would have rejected an unfixed candidate.

### FORMAT (read first)
Inside your review block use **bold labels** (for example `**Q1**`), NEVER markdown heading lines (`#`, `##`, `####`). The driver counts a block's body only up to the next heading line, so a block that opens with a sub-heading is read as empty and called a stall. Keep the required `swept file: yes|no` line, then `VERDICT:` and `Basis:`.

### What is under review
- The diff against `origin/development` is the artifact above (`test/`, `TESTS-RESULTS/`, `PROJECT/`, `releases.sql`; `releases.db` is binary and omitted; relay threads omitted). The approved plan is `PROJECT/2-WORKING/GH-1615-PHASE-B-FIXTURE-REPAIR.md` (Codex plan QA APPROVED round 2, `relay-system/2026-11-25/gh1615-plan-qa.md`). Evidence: `TESTS-RESULTS/2026-11-25+GH-1615/` (`SUMMARY.md`, `provenance.jsonl` with 20 rows, runners, `failures-at-base.txt`).
- The whole production-code change is 8 added lines in `test/gh534_phase_b_tests.py` (`LedgerFixture.setUp`). Read that file's fixture, `test/gh436-merge-cleanup.py:38-43` and `:1375-1390`, and `test/gh534_phase_c_tests.py:34`.

### Operational envelope and non-goals
- Test-fixture repair, XYZ-forge repo. XYZ-forge forbids new tests and gate registrations (`AGENTS.md` *No new tests*, GH-831): a new `test/` file, a `validate.sh` / `ci-local.sh` / CI entry, or an edit to the gated `gh436` suite in this diff is a finding. Editing an EXISTING suite to keep it truthful is allowed. No production code may change.
- Not yet run, by design: the repository qualification gate for the pushed commit. Do not assume it and do not demand it here.

### Questions (answer each; cite `file:line`)
1. Issue #1615's acceptance: (a) a recorded keep-or-retire decision, (b) fixture brought in line with GH-1576 and the suite shown passing on a clean clone, (c) a recorded run under TESTS-RESULTS with provenance. Is each met by the change and the receipts? Quote the deciding spans.
2. Does the code match the approved plan exactly (scoped `mock.patch.object`, `addCleanup`, placement next to the existing environment patch, the comment's claims true)? Is anything in the diff outside the plan?
3. What prevents an UNCHANGED, unfixed candidate from being reported as delivered, and where is the observed rejection? Cite `BASE-B-red`, `BASE-C-red` and the mutant rows. Could any row pass on empty or absent output? Are the two mutants discriminating (own assertion, differs from the original, green unmutated)?
4. Existing guarantees: try to violate them. The gated entry point now executes the changed fixture (`CAND-GATED-green`); importers (`IMPORTER-DRIVER`); the 24 phase B tests that already passed; scoped-stub stacking over `gh436`'s module-level stub. What did you try and find?
5. Test honesty: does the stub mock away a seam any phase B/C test claims to exercise? Any test asserting a historical invariant GH-1576 changed?
6. Documentation honesty: the plan, `SUMMARY.md` and the provenance correct the issue's "no gate runs it" and the earlier "no gated suite reaches the B1 path" claims. Are those corrections true and proportionate? Is anything overstated or unverified in `SUMMARY.md`, the plan's *Observed* table or the rating re-assessment (`30/35/50/65` to `20/25/50/85`, forced)? Label each remaining gap accepted-and-recorded or a finding.
7. Is any operator decision hiding (gate registration, deleting `gh436`'s now-redundant stub, anything else)?

Output: graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`) each with a concrete fix and `file:line` citations. Every behaviour-change finding needs `Observed input:` / `Affected scope:` / `Falsifier:`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
