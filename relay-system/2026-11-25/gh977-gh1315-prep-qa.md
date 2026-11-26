# RELAY · Preparation QA: #977 and #1315 Conveyor packets (Day 2 candidates)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-25.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 2

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
6. **Manual relay: commit only the relay file** (`relay(gh977-gh1315-prep-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-25
- Reviewer sandbox is read-only on the artifact: set no edits. Read-only probes only (see `swept file` rule); do NOT run `validate.sh`, `test/*.sh` or pytest.

### What is under review (PREPARATION only, not an implementation)
Conveyor preparation packets for GitHub issues #977 and #1315 (HiQS-Labs/XYZ-forge), candidates for Day 2 of the Flywheel proving arc (ledger #1610, ranking #1616). Skill: `skills/1-hourly/conveyor/SKILL.md` (read it, esp. Preparation flow steps 3-5 and "Probe polarity").
Files (all committed at HEAD of this worktree, base `origin/development` 086b657ea):
- `PROJECT/1-INBOX/GH-977-ROADMAP-UPDATE-KEEPS-RATING.md` (new capture + Swarm Preflight Contract)
- `PROJECT/1-INBOX/GH-1315-LEGACY-PREVIEW-PARITY.md` (existing 2026-11-11 capture, refreshed)
- `TESTS-RESULTS/2026-11-25+GH-977/` and `TESTS-RESULTS/2026-11-25+GH-1315/` (`readiness_probe.py`, `SUMMARY.md`, `provenance.jsonl`, `probe-proof/`, `existing-suites/`)
- `releases.sql` diff (one new roadmap row for #977 via `roadmap pickup`; #1315 row untouched)
Source defects to read: `utils/py/releases_app.py:4108-4240` (`cmd_roadmap_update`), `skills/3-weekly/skills-army-hq/scripts/sync.py:242-300` and `intake.py:565-575`.
Issue text (read via the capture docs' quoted acceptance): #977 criteria are its `## Ask` bullets; #1315 criteria are its `## Expected` text. Neither issue body has an `## Acceptance` heading, so Preflight reports acceptance fidelity `unknown/no-issue-section` (advisory).

### Operational envelope and non-goals
Local developer tooling in a docs/ledger-only PR. No implementation, no queue enqueue, no labels, no issue edits, no new test suites (GH-831). Grade commensurate complexity; challenge bloat. Do not ask for new suites.

### Facts already measured (verify, do not take on faith)
- Preflight `--dry-run` + Jog promotion lint (`contract_probes_from_doc`, `promotion_probes`) both exit 0 for both docs on the prepared commit; probe verdict `unfixed`. After a simulated real fix (disposable clone) Preflight exits 4 STALE with probe `landed`; after a comment-only edit exit 0 `unfixed` (see `probe-proof/*/` and the patches there).
- The probes are `command` probes with `expect_nonzero: true`: the script exits 0 only when the fixed behavior is positively observed, so a crash reads as unfixed. Preflight `eval_probes` is `utils/py/swarm_preflight.py:250-305`.
- #1315 already had a row (In progress, accepted-start) and a `pending/0` Jog queue row from the 2026-11-11 trial; both preserved. #977 has no queue row.

### Definition of Done (grade against these; cite file:line)
1. Each capture's acceptance is copied verbatim from the issue and any deviation is declared in the form `extract_declared_deviations` parses (`utils/py/swarm_preflight.py:637-700`).
2. Each contract uses only supported probe shapes, has correct polarity (reads unfixed today, fixed after a real fix, unfixed after a comment-only edit), the gate is made only of existing suites, and artifacts are bounded (no new test suite).
3. The attempt/retry history recorded in each doc is accurate and nothing was reset (check `releases.sql`, `git diff origin/development -- releases.sql`).
4. Ratings: #977 written only through `roadmap pickup`; #1315 preserved. Rationale consistent with start-task's rating policy.
5. Nothing implements either fix, adds a label, enqueues into Jog, or edits the issues.

### Questions (answer each with file:line)
1. Does each probe (`readiness_probe.py`) actually discriminate the defect described in its issue, and could it read "fixed" for a wrong reason (e.g. a preview that merely errors for another cause, a text-only update refused for an unrelated reason)? Name the falsifier.
2. Is the `expect_nonzero: true` + fail-closed design sound given `eval_probes` treats any nonzero exit as landed when `expect_nonzero` is false and zero as landed when true? Any crash path that reads "landed"?
3. Is each gate command made only of existing suites, and will the contract's `artifacts` allow the real fix (e.g. #977 must edit `test/gh257-roadmap-ledger-fixes.sh` Case 8; does anything else pin the clearing behavior)?
4. Are the deviation declarations and acceptance lists faithful to the issue text and the 2026-11-25 triage notes (comments on #977 and #1315)?
5. Is the #1315 history accurate (queue row, work_events, trial #1386) and is anything about the preserved In-progress/accepted-start state a hazard for the Day 2 launch that the doc fails to state?
6. Is anything over-built or out of scope for a preparation-only PR? Does the diff touch anything it should not (`git diff --stat origin/development`)?

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
