# RELAY · GH-1587 Plan QA: Close 6 High-Severity Review Blind Spots
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-23.
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

### Round 1 · Producer · claude-a · 2026-11-23

**Decisions on proposals:**
- **[Blocker] 1 (Focused tests & push gate clone location):** Implemented (`PROJECT/2-WORKING/GH-1587-QA-REVIEW-BLIND-SPOTS.md` Phase 1 step 7 & Phase 2 Clone safety boundary / steps 1–4). Removed all `test/*.sh` runs from Phase 1 in the task clone; moved all 16 focused `test/*.sh` runs, red-on-base pin checks, live GH-836 self-sufficiency, and smoke tests into the separate disposable full clone `../XYZ-forge-gh1587-qa-review-blind-spots-2026-11-23-verify` with canonical origin URL and before/after identity checks. Clarified that the task clone itself is a fresh standalone disposable full clone (not primary, not a linked worktree), so running the single pre-push `./validate.sh` gate on `git push` satisfies both `AGENTS.md` (disposable full clone) and `start-task/SKILL.md:291` (GH-1518: do not run `./validate.sh` twice on the same commit).
- **[Blocker] 2 (Observed Rejection table & admission pins vs behavioral detection):** Implemented (`PROJECT/2-WORKING/GH-1587-QA-REVIEW-BLIND-SPOTS.md` Acceptance Map, Target Seams #10, and Phase 2 steps 2 & 4). Split the Acceptance Map cleanly into Layer A (Deterministic Admission Pins: extended existing `test/gh681-reviewer-probe-rules.sh`, `test/gh778-review-code-skill.sh`, and `test/gh616-start-task-commensurate-envelope.sh` in-place under GH-831 with negative-control mutations, verified RED on unchanged `14cb8a60d` files and GREEN on candidate) and Layer B (Behavioral Evidence: live GH-836 self-sufficiency + `new-relay.sh`-scaffolded Codex review on a reconstructed defective Python fixture covering TOCTOU race, missing sibling auth guard, and mocked-out test body).
- **[Should] 3 (Form 2 severity, pending status, and Producer clone-probe closure including errored/unavailable probes):** Implemented (`PROJECT/2-WORKING/GH-1587-QA-REVIEW-BLIND-SPOTS.md` new section "Form 1 vs Form 2 Severity & Closure Rules (GH-681 + GH-564)" + Phase 2 step 4). Defined default `[Should]` severity for unexecuted Form 2 traces, allowed `[Blocker]` via Form 2 only when the static `file:line` trace proves an unconditional invariant breach, marked all Form 2 findings pending verification until the Producer executes `Clone probe:` in a disposable clone, specified all three closure outcomes (Reproduced → fix + before/after output; Falsified → `Declined — falsified by clone probe: <cmd → exit + output>`; Errored/Unavailable → stays OPEN as `[Unverified — clone probe failed/unavailable]` and blocks `STATUS: Approved`), and added both Producer execution and errored/unavailable-probe verification to Phase 2 step 4.
- **[Should] 4 (Record persisted roadmap rating & admission check):** Implemented (`PROJECT/2-WORKING/GH-1587-QA-REVIEW-BLIND-SPOTS.md` Status table, "Persisted Roadmap Registration & Rating" section, and Phase 1 preamble). Recorded `rmi-01M859AVNYRXE06BH6A6QH6F5E` (`pri=85 / sev=80 / appeal=50 [neutral] / effort=70`, `ovr=null`, `doc_path: PROJECT/2-WORKING/GH-1587-QA-REVIEW-BLIND-SPOTS.md`) and explicit pre-write readback + `--accepted-start` check.
- **[Nit] Rollback merge-commit parent flag (from footer):** Implemented (`PROJECT/2-WORKING/GH-1587-QA-REVIEW-BLIND-SPOTS.md` Rollback section: added `git revert -m 1 <merge-sha>` for merge commits).

**Did:** Revised `PROJECT/2-WORKING/GH-1587-QA-REVIEW-BLIND-SPOTS.md` in commit `880b529b3` to resolve all 4 findings plus the rollback merge-parent note.

**Re-review this:** Re-read `.relay-artifacts/GH-1587-QA-REVIEW-BLIND-SPOTS.md` in full and confirm all Round 1 findings are closed cleanly before Round 2 verdict.

**Commit:** `880b529b3`

Handing off to Reviewer (codex) — take your Round 2 turn.

### Reviewer · Round 2

**What this proposes** (input boundary: plan artifact only)
The plan extends the review ladder and relay instructions for six defect classes and a clone-probe handoff. It proposes existing pin updates and live review evidence in disposable clones.

**How the existing system works, per this document** (input boundary: plan artifact only)
The code-review skill owns the shared ladder and PR review delegates to it. Relay findings require concrete evidence, and unsafe probes run in disposable clones.

**What it's not** (input boundary: plan artifact only)
It does not create a new suite, modify frozen twins, or change finding tags. It does not authorize executing unsafe suites inside the relay worktree.

**Source-backed technical validation**

- [Blocker] Round 1's behavioral rejection finding remains open: the proposed live fixture covers only three classes and exercises the final packet without a defective-input rejection for the other classes or start-task routing. Text pins are explicitly admission evidence, not evidence that a reviewer detects a defect. Specify concrete defective inputs and expected review/routing outcomes for the remaining test inversion, native-framework reinvention, resume-key instability, and start-task routing, with baseline rejection and corrected controls; retain the distinction between pins and behavior.
  Observed input: artifact lines 35–36 and 142–148 list six classes but the live fixture names only TOCTOU, sibling guard and mocked test body; `test/gh778-review-code-skill.sh:32-36,72-76` checks text presence.
  Affected scope: acceptance of all six promised defect classes and surface-triggered QA routing.
  Falsifier: recorded behavioral red/green evidence for each omitted class and routing would close the gap. Suite and live outcomes are [Unverified — needs clone run].
- [Blocker] The execution order changes the plan and potentially lessons after final QA, although the gate requires approval on the final head. Move all intended tracked edits and commits before final QA, then rerun appropriate checks and QA if anything changes afterward.
  Observed input: artifact lines 187–189 and 195: final QA precedes updating plan status and potentially appending lessons; `skills/1-hourly/start-task/SKILL.md:328-330` requires fresh review for changes after approval.
  Affected scope: final reviewed and pushed commit when step 7 modifies tracked files.
  Falsifier: a sequence with all tracked edits committed before QA, or explicit fresh QA and checks after subsequent edits, yields the same reviewed final SHA.
- [Should] The clone identity checklist names only HEAD and origin and omits `core.bare` and local user identity, so it cannot detect all required fixture escapes. Record and compare all four identity values before and after each mutation-heavy run, invalidating evidence on drift; apply the same check to the full-gate clone.
  Observed input: artifact lines 174–178; `WORKTREE-SAFETY.md:504-505` names `core.bare`, origin, local user identity and HEAD.
  Affected scope: verification runs and pre-push full gate in disposable clones.
  Falsifier: explicit before/after comparison of all four values with invalidation on drift would make this change unnecessary.
- [Should] The smoke says to execute the probe and verify a disposition, but does not require an actual Producer turn; a manual operator execution cannot establish that the Producer receives and follows the handoff. Require a scaffolded Producer turn and captured dispositions for reproduced/falsified and unavailable probes.
  Observed input: artifact lines 184–186 specify a live reviewer turn followed by executing a probe, with no Producer turn specified.
  Affected scope: Form 2 handoff and closure behavior.
  Falsifier: a receipt showing the actual Producer turn executing each probe and recording the expected disposition would resolve this gap.
- [Unverified — no citation] The plan now records the requested rating and pre-admission readback (artifact lines 70–76), and specifies merge-parent rollback (line 206). Actual persisted row and clone runs remain unverified in this turn.

swept file: yes
The outstanding findings above include pre-existing and revised-plan defects; no other pre-existing defect was established. The full base-SHA and source-seam audit remains unverified; no suites or live relay probes were run here.

VERDICT: FAIL
Basis: Acceptance coverage, final-head review, clone identity, and the Producer handoff need executable evidence and ordering before approval.
Handing off to Producer — take your turn and disposition each finding.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
