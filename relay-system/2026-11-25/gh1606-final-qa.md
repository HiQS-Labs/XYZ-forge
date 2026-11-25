# RELAY · GH-1606 final QA — gate-toolchain defer before B1 repair slot
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
6. **Manual relay: commit only the relay file** (`relay(gh1606-final-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1606-final.diff** — the read-only path that
  `relay-drive.sh --artifact-file /private/tmp/claude-501/-Users-noelsaw-Documents-GitHub-XYZ-forge/e3f96cf1-a102-4b6b-8e5b-e513c6a2ffc3/scratchpad/GH-1606-final.diff` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude
- Started: 2026-11-25
- Definition of Done: issue #1606's four acceptance items are met by the committed implementation, the code paths match the approved plan, no duplicate subsystem or writer slipped in, and the retained evidence substantiates its claims and would have rejected an unfixed candidate.

### What is under review
- The diff against base `b479f74e0` is the artifact above (`skills/`, `TESTS-RESULTS/`, `releases.sql`; `releases.db` is binary and omitted). The approved plan is `PROJECT/2-WORKING/GH-1606-MERGE-CLEANUP-PUSH-ENVFAULT.md` (Codex plan QA: `relay-system/2026-11-25/gh1606-plan-qa.md`, APPROVED round 3). Evidence: `TESTS-RESULTS/2026-11-25+GH-1606/` (`SUMMARY.md`, `provenance.jsonl`, `run_controls.py`).
- Read in full in the repo worktree: `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`, `skills/2-daily/merge-cleanup/SKILL.md`, the evidence files above, and `validate.sh` lines ~1020–1075.

### Operational envelope and non-goals
- Local operator CLI tooling in the XYZ-forge repo; grade against the stated requirements and commensurate complexity; the repo's own threat model governs. Challenge bloat; do not manufacture scope.
- XYZ-forge forbids new tests (`AGENTS.md` *No new tests*, GH-831): a new `test/` suite, `validate.sh` TESTS entry or gate machinery in the diff is a finding. Verification is an existing suite or a manual check under `TESTS-RESULTS/` with `provenance.jsonl`.
- Plan non-goals (accepted at plan QA): no gate bypass, no repair-budget or `attempt_record` accounting change, no interpreter selection, no change to how a genuine gate RED is surfaced after a push. Phase B's pre-existing breakage and conservative-deferral unmeasured behaviour are recorded limits, not defects of this change.
- Not yet run, by design: the repository's qualification gate for the pushed commit (Step 9). Do not assume it, and do not demand it here.

### Questions (answer each; cite `file:line`)
1. Issue #1606 acceptance: (a) a toolchain-fault refusal names its fault in merge-cleanup's own output; (b) it does not consume one of the 2 repair slots; (c) a recorded red control shows both sides; (d) no bypass, budget unchanged. Is each met by the code and evidence? Quote the deciding spans.
2. Do the actual code paths match the approved plan? Check the helper `gate_toolchain_fault_reason`, its placement relative to the `--resume` skip and to `attempt_record.reserve`, the execute-only guard, the deferral bookkeeping (`failed[...]`, exit 3, hard dependents), and the optional `preflight_warnings(primary_repo)` argument.
3. Did a duplicate subsystem, writer, parallel write path or speculative abstraction slip in? Is the diff free of new `test/` suites and registry entries? Is `run_controls.py` a manual driver under `TESTS-RESULTS/` (the GH-1597 precedent) and not a suite?
4. What prevents an **unchanged, unfixed** candidate from being reported as delivered, and where is the observed rejection? Cite the provenance rows (`AC-2-base-red`, `AC-2-cand-green`, `AC-2-mutant-red`). Are the healthy-path rows non-vacuous (published head captured right after the real push, equal to the recorded repair)? Could any row pass on empty or absent output?
5. Existing guarantees: try to violate the 2-repair cap, the `--resume` parked-skip, dry-run purity (no new writes), consumer repos without `validate.sh`, `--prs`/hard-dependency handling, and callers of `preflight_warnings`. Say what you tried and what you found.
6. Does `SKILL.md` describe the behaviour truthfully and no more (including the conservative-deferral caveat)?
7. The ledger: the diff touches `releases.sql`/`releases.db`. Is that consistent with the writer (CLI) path and the stated rating `55/55/50/70`, with no hand edit evident?
8. Anything unverified or overstated in `SUMMARY.md`? Label each remaining gap as accepted-and-recorded or as a finding.

Output: graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`) each with a concrete fix, `file:line` citations, the required `swept file: yes|no` line, then `VERDICT:` and `Basis:`. Every behaviour-change finding needs `Observed input:` / `Affected scope:` / `Falsifier:`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
