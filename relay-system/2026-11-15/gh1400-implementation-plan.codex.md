# RELAY · GH1400 implementation plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-15.
-->

NEXT: Producer
STATUS: Approved
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
     A `[Blocker]` must cite an observed failure. This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1400-implementation-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Review packet — read in this order

First read only `PROJECT/2-WORKING/GH-1400-SUPERVISION-COMPOSITION.md`, especially the new
Implementation slice. Before source or supplementary requirements, write 2–5 sentences each
under **What this proposes** and **How the existing system works, per this document** and a
short **What it's not**. Record this input boundary, distinguish inference and missing boundaries.
Then perform source-backed validation against `utils/py/jog_run.py`, `utils/py/releases_app.py`,
`utils/py/proc_group.py`, Jog/Flywheel skills, AGENTS and GUIDING-PRINCIPLES.

Requirements: user explicitly authorized BUILD a thin deterministic supervisor around existing
owners, through reviewed verified PR; no new queue/ledger/schema or framework, no scheduler  [Unverified — no citation]
activation/live LTVera/API spend/merge. RAW intake belongs to preparation, fresh readiness at
execution. Preserve old PR1403 instruction-only evidence/caps as history. New review cap3.
Current plan is proposed implementation; challenge concrete safety or requirement gaps before code.

Questions (source-backed assessment after initial paraphrase):
1. Does this extend the actual owner and remove the observed receipt/clone handoff intervention?
2. Are deadline/cancel and lock/owner semantics implementable with the named existing primitives?
3. Are pending selection, approved adoption, uncertain holds and attempt preservation sufficient?
4. Does preservation retain all unique commits/logs without branch-state corruption?
5. What prevents unchanged code from counting as delivered, and where are its planned red controls?
6. Is the scope commensurate with a local operator CLI, without promising simulator guarantees?
7. Is rating75/60/50/45 justified (prior75/60/50/80 was docs-only; override null)?

Do not run suites or modify source. Only this relay file is writable. Grade the bounded local
operational envelope; no enterprise fault model, new framework or speculative tests. Source-backed
findings must name concrete failing input/scope/falsifier. Approval is plan approval, not runtime proof.

## Setup
- Artifact under review: _<fill in the repo-relative path(s) the turn reviews>_
- Reviewer: codex   ·   Producer: producer
- Started: 2026-11-15
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

#### What this proposes

The implementation slice adds an opt-in, finite Jog wake that recovers an approved execution receipt, safely aligns its execution clone, and selects eligible pending work through existing owners. It keeps native attempt limits and requires fresh execution readiness, with an absolute dispatch deadline and explicit holds on uncertainty. This review treats approval as permission to implement the plan, not evidence that its runtime behavior works.

#### How the existing system works, per this document

The document says Jog owns selection and execution records, while Marathon owns build attempts and the target execution lock. Interrupted wake recovery currently projects cold state, and publishing an approved receipt requires a separate resume command; development alignment also needs manual intervention. These are document claims awaiting source validation; the exact subprocess timeout API, lock lifetime across recovery, and historical-state validation are not established by the document alone.

#### What it's not

No new queue, ledger, scheduler, model dispatch, merge authority, or simulator guarantee is proposed. Input boundary: only the complete GH-1400 project document was read before this paraphrase; historical instruction-only evidence and exhausted repair caps remain historical.

#### Source-backed assessment

swept file: yes

Reviewed the entire project document, including historical instruction-only delivery, integration repairs and the implementation slice. Source fallback used because this session exposes no graph tools; no current graph generation or coverage result is independently claimed. Read the relevant Jog run/recovery/publication/checkpoint paths, Releases queue writers/parser, proc_group, Jog/Flywheel instructions, AGENTS and GUIDING-PRINCIPLES. No suites, executable fixtures, Git commands, model calls or remote mutations were run.

- [Pass] **Existing owner and intervention:** the plan extends the actual CLI owner, not a parallel supervisor. Releases delegates directly to `jog_run_main` (`utils/py/releases_app.py:5198`); interrupted checkpoint recovery currently projects and returns (`utils/py/jog_run.py:2195`), while separate resume publishes (`:790`). Existing alignment only switches branches (`:2645`). The proposed recovery-before-selection and preservation/alignment path addresses both demonstrated intervention classes (project document:198–215). Implementation must still demonstrate this through the planned CLI smoke.
- [Pass] **Deadline/cancel and locks are implementable:** `proc_group.run_bounded` creates a process group, accepts a timeout and cleans it up on exceptions (`utils/py/proc_group.py:108`, `:124`, `:139`); Jog currently uses unbounded calls at `utils/py/jog_run.py:637` and `:694`. The planned bounded calls and retained dispatch record are concrete work, not existing guarantees. Primary exclusion, target alignment exclusion and Marathon execution ownership are separated in the contract (project document:193–211). Publication/cleanup overrun is disclosed rather than hidden.
- [Pass] **Selection, adoption and uncertainty:** latest matching issue/execution evidence, publication before projection, no inferred retry, and selected-item accounting including preflight holds are explicit (project document:196–215). The existing run writes the result path before worker dispatch (`utils/py/jog_run.py:675`); publication validates approved/green evidence, branch identity and candidate gate (`:1124`). Retaining those owners while strengthening identity checks is sufficient at plan level.
- [Pass] **Preservation:** the contract preserves unique development commits under a branch name, holds tracked dirt and dependent worktrees, retains untracked files/logs, and refuses overwrite rather than resetting (project document:202–207). That directly fills the clean-local-switch gap at `utils/py/jog_run.py:2645`. Preservation-name collisions must consequently hold rather than replace a ref; this follows the existing “preserve every branch” requirement.
- [Pass] **Discriminating acceptance:** real CLI adoption of A plus selection of B, an adjacent unchanged-attempt/receipt rerun, pre-change intervention controls, and a nonempty complete required-check list are explicit (project document:230–240). Unchanged baseline behavior cannot satisfy that full acceptance. Final exact-revision QA and a disposable-clone gate remain separate requirements (`:241`). These are planned checks, not executed results.
- [Pass] **Bounded scope and history:** the new slice expressly preserves old PR #1403 caps and evidence (project document:146–148), excludes scheduler/spend/merges and strong crash guarantees (`:176–180`, `:216–219`), and supplies a Costly rollback retaining native history (`:221–224`). This fits GUIDING-PRINCIPLES' “extend” North Star and Flywheel's “Flywheel selects and resumes existing skills; it does not reimplement their commands, state, locks, limits or evidence.” No simulator or new framework is needed.
- [Pass] **Rating rationale:** 75/60/50/45 with null override distinguishes runtime recovery work from historical docs-only cheapness 80; one assisted run and synthetic evidence are not inflated into a recurrence trend (project document:247–251). This is a coherent qualitative rationale. The primary writer read-back itself was not independently queried in this review.
- [Nit] **Current-state wording overstates attempt ownership:** project document:165–166 says queue attempt_count is “never a second retry budget,” but `utils/py/releases_app.py:5177` currently parks dead-owner running rows when `attempt_count >= 3`, with “orphan lease: max attempts exceeded.” Correct the recon sentence to identify this legacy recovery threshold and distinguish it from the intended supervised contract. This does not block the plan: its no-reset/no-second-budget requirement and native-attempt controls already state the intended behavior. Include the existing threshold in implementation analysis; do not quietly remove unrelated legacy behavior.

Pre-existing issues in the relevant source were considered: malformed execution JSON silently becomes fresh state (`utils/py/jog_run.py:317`); unknown lock owners are reclaimed (`:1513–1544`); cold receipt projection lacks publication (`:467`); result shape validation alone does not bind expected issue/execution (`:146`). The plan explicitly addresses these through refusal, owner exclusion and exact-result recovery (project document:198–211). No additional unaddressed blocking defect was identified in the artifact sweep. This is not an exhaustive audit of all runtime modules.

VERDICT: PASS
Basis: Approve the bounded implementation plan. It names the actual owner, concrete intervention seams, preservation rules, refusal behavior and discriminating clone verification without adding a second system. The recon wording nit is nonblocking. Runtime correctness, long-horizon qualification, hosted results and primary rating persistence remain unverified; no implementation or gate approval is implied.

Relay closed (Approved), no further turn needed.


### Attestation · relay-drive — 2026-11-15T15:56:22Z
task: RELAY-gh1400-implementation-plan
reviewer: codex
status: Approved
reviewed-head: 592f6c6457a3d59e66ee2fb7391b9d660a01b831
added-range: 7767+7202
added-sha256: 946a64e1667aa90ef53e6a3422678ea8a6ea49f5e3ed27479cc275d71d0ad91c
gate-run: undeclared
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
