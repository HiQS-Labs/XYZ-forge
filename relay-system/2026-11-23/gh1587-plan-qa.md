# RELAY · GH-1587 Plan QA: Close 6 High-Severity Review Blind Spots
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-23.
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
     change MUST carry three lines: `Observed input:` (the failing input you saw), `Affected scope:`
     (the input predicate the change would govern), `Falsifier:` (the fixture or data that would show
     the change unnecessary or wrong, and its expected result).
     A `[Blocker]` must cite an observed failure.
     A finding from an earlier round stays open, and the verdict stays failing, until new evidence closes it.
     This includes earlier [Nit] findings; only a newly raised [Nit] with VERDICT: PASS on STATUS: Approved remains optional.
     This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Manual relay: commit only the relay file** (`relay(gh1587-plan-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1587-QA-REVIEW-BLIND-SPOTS.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1587-QA-REVIEW-BLIND-SPOTS.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-23
- Definition of Done: The surgical plan in `PROJECT/2-WORKING/GH-1587-QA-REVIEW-BLIND-SPOTS.md` faithfully covers all 6 recurring High-severity review blind spots and the GH-681/GH-564 Catch-22 from HiQS-Labs/XYZ-forge#1587, pins accurate source seams at `14cb8a60d`, obeys GH-831 (no new tests), GH-308 (frozen Bash twins), GH-836 (live self-sufficiency + scaffold review), and single-source-of-truth skill boundaries (`review-code-xyz` vs `review-pr-xyz`), and specifies falsifiable rejection criteria and rollback without over-engineering.
- Operational Envelope: Local XYZ-forge skill docs, relay turn prompts, marathon reviewer brief, packaged tarball (`relay-pkg.tar.gz`), and in-place pin test (`test/gh681-reviewer-probe-rules.sh`). Grade against stated requirements, commensurate complexity, and XYZ-forge rails (`AGENTS.md`, GH-681, GH-831, GH-308, GH-564).
- Paraphrase-First Step (GH-1414): Before reading repo source files, read ONLY `.relay-artifacts/GH-1587-QA-REVIEW-BLIND-SPOTS.md` and write 2–5 sentences each under `**What this proposes**`, `**How the existing system works, per this document**`, and `**What it's not**` (marking input boundary = plan artifact only). Then read the target repo files below and label the remaining findings as `**Source-backed technical validation**`.
- Source paths to validate after paraphrase: `skills/2-daily/review-code-xyz/SKILL.md`, `skills/2-daily/review-pr-xyz/SKILL.md`, `relay-automation/relay-turn-lib.sh`, `relay-automation/new-relay.sh`, `utils/py/marathon_drive.py`, `skills/1-hourly/relay/SKILL.md`, `skills/1-hourly/relay-xyz/SKILL.md`, `skills/1-hourly/start-task/SKILL.md`, `relay-automation/README.md`, `test/gh681-reviewer-probe-rules.sh`, `utils/py/review_xyz.py`.
- Plan QA Questions:
  1. Are all target file paths, line references, and confirmed non-edits (`utils/py/rtl.py`, `relay-automation/marathon-drive.sh`, `utils/py/review_xyz.py`) grounded in the repo at `14cb8a60d`?
  2. Is any requirement from GH-1587 (6 blind spots + 2-form `Observed input:` / `Clone probe:` + `make-pkg.sh` + GH-836 live check) missing, contradictory, or unsynchronized across the 10 target files?
  3. What prevents an unchanged, unfixed candidate from being reported as delivered — and where is the observed rejection? Do the acceptance checks distinguish admission/pin checks from actual defect detection?
  4. Does the plan keep `review-code-xyz` as single source of truth (no duplication into `review-pr-xyz`), keep canonical `[Blocker]`/`[Should]` tags intact, obey GH-831 (no new test files), and obey GH-308 (no frozen twin edits)?
  5. Are the persisted roadmap rating (`85/80/50/70`, appeal neutral=50), rollback boundary, and Phase 1/2 QA gates sufficient and commensurate?

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer · Round 1

**What this proposes** (input boundary: plan artifact only)
The plan adds targeted review checks for six recurring defect classes and a bounded clone-probe handoff for hazards a relay reviewer cannot execute locally. It synchronizes the prompts, skills, package and existing pin checks, then calls for clone verification and independent QA.

**How the existing system works, per this document** (input boundary: plan artifact only)
The code-review skill owns the canonical review ladder, while PR review delegates to it. Relay reviewers currently need concrete evidence for behavior-change findings, and disposable clones contain mutation-heavy verification.

**What it's not** (input boundary: plan artifact only)
This is not a new review skill or test suite, and it does not propose changing canonical finding tags or frozen Bash twins. It does not permit running unsafe tests inside the relay worktree.

**Source-backed technical validation**

- [Blocker] Phase 1 schedules the focused `test/*.sh` runs before the disposable clone exists, and Phase 2 schedules the full pre-push gate from the task clone. This conflicts with the full-clone-only safety rule and leaves the intended verification location unsafe. Fix the ordered steps so every `test/*.sh` and `validate.sh` invocation, including the push gate, runs in a disposable full clone of the final candidate; preserve identity checks and receipts.
  Observed input: plan lines 153–157 and 165–171; `AGENTS.md` “Run mutation-heavy suites only in a separate disposable FULL CLONE”.
  Affected scope: all planned focused and full test executions.
  Falsifier: an explicit earlier disposable full clone and an explicit final push-gate execution there, with matching candidate SHA and identity checks, would remove this conflict.
- [Blocker] The “Observed Rejection” table does not establish that the six defect classes or start-task behavior are detected: it cites diff inspection and existing unrelated pins, while the only new red control removes the literal `Clone probe:` string. An unchanged skill can pass these existing checks. Specify concrete defective examples and expected findings for each class and the start-task routing, with baseline rejection and corrected-candidate evidence; distinguish text admission pins from behavioral evidence.
  Observed input: plan lines 102–103, 134–139; `test/gh778-review-code-skill.sh:33,72-76` pins existing wording and a recital, not the six proposed checks; `test/gh616-start-task-commensurate-envelope.sh:45-47` mutates existing envelope wording.
  Affected scope: acceptance of the six review checks and surface-triggered QA handoff.
  Falsifier: a recorded run showing the specified existing checks reject an unchanged candidate for each missing behavior, or a concrete behavioral red/green review fixture for each, would disprove the gap. These suite outcomes are [Unverified — needs clone run].
- [Should] Form 2 permits an unexecuted hazard trace while retaining the categorical requirement that a `[Blocker]` cite an observed failure, and the smoke checks only reviewer output, not whether the Producer executes the probe or whether a failed/unavailable probe keeps the finding open. Specify severity and pending status before observation, exact evidence needed to close each outcome, and a producer-side smoke including failed/unavailable probes.
  Observed input: plan lines 88–91 and 168; `relay-automation/new-relay.sh:92-104` requires a failing input and observed failure for a blocker.
  Affected scope: runtime hazards whose clone probe has not yet yielded a result.
  Falsifier: a concrete documented disposition that prevents approval until an actual probe result, and a smoke exercising both producer execution and unavailable/failing probe outcomes, would resolve the ambiguity.
- [Should] The plan never records the requested persisted roadmap rating or a check against it; its status says registration/rating remains next. Add the four values `85/80/50/70`, including neutral appeal 50, and verify the persisted row before accepted-start.
  Observed input: plan status table and lines 146–147 contain no rating; the relay Setup question 5 requires the persisted rating.
  Affected scope: GH-1587 roadmap admission.
  Falsifier: a cited persisted row with those values and an explicit admission check would make this request unnecessary.
- [Pass] The non-edit boundary for parser tags and Python delegation is grounded: `utils/py/review_xyz.py:62-63` matches literal tags and `utils/py/rtl.py:1118-1119` delegates to `rtl_turn_prompt`; `review-pr-xyz/SKILL.md:21-24` delegates the canonical ladder.

swept file: yes
Pre-existing defects in the artifact are the findings above; no other pre-existing defect was established. The complete source-path and base-SHA audit, live smoke, and suite outcomes remain unverified in this contained turn. Rollback's `git revert <merge-sha>` also needs the appropriate merge-parent choice if the landing is a merge commit.

VERDICT: FAIL
Basis: The execution location, rejection evidence, and unresolved clone-probe closure must be made concrete before this plan is executable or approvable.
Handing off to Producer — take your turn and disposition each finding.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
