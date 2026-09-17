# RELAY · GH-666 narrow probe plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-16.
-->

NEXT: Producer
STATUS: Approved
ROUND: 3 / 3

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
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-666-narrow-probe-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: PROJECT/2-WORKING/GH-666-AGY-MODEL-PROBE.md, its recon and utils/py/agy-turn.py; committed canonical paths, read only.
- Reviewer: codex   ·   Producer: producer
- Started: 2026-09-16
- Definition of Done: Phase 1 ordered plan and QA checklist are grounded, bounded, surgical and falsifiable; no implementation or gate approval inferred from plan QA.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Producer — producer — Round 1

VERDICT: PARKED
Basis: Independent plan review pending.
swept file: yes

Operational envelope: local developer CLI, one model-validation probe, accidental
relative writes. Commensurate stdlib fix only; no distributed/OS-sandbox/process
framework. Read the actual repo plan (not the external placeholder), its recon,
utils/py/agy-turn.py (662 lines; bounded reads through EOF), relevant existing
test/agy-turn.sh model cases and RELEASES rating read-back. No full historical
changelog audit is required for this prospective local-probe plan; that is not
the code being changed. No tests/programs or source edits in the valued clone.

Questions:
1. Does the traced unsafe call before RTL/snapshot and existing auth-probe pattern
   justify a temporary model-probe cwd without changing validation semantics?
2. Are refusal/cleanup and baseline/ablation caller-preservation checks sufficient
   and commensurate, with explicit limitations for absolute writes/detached children?
3. Are blast radius, rollback, rating 90/85/50/85 and distinct observed versus
   unknown recurrence grounded, and is the plan free of duplicate systems/writers?
4. Do the gate/QA/PR steps preserve unrelated GH-661 work and refuse readiness
   on existing base failures, without claiming skipped gates or promotion?

Only append a cited verdict here. Claim the env-pinned token; on PASS set STATUS
Approved and tick DONE while owned (do not release Producer). Otherwise hand back
findings within cap3. No source edits, Git commands or heavy tests.
Handing off to Reviewer — review the narrow plan and give the cited verdict.

### Reviewer — codex — Round 1

VERDICT: FAIL
Basis: The narrow stdlib design is justified, but executable-resolution compatibility and the caller-preservation oracle need explicit decisions before implementation. Graded against the Producer's four questions and the plan's Phase 1 QA checklist; Setup's Definition of Done remains a placeholder.
swept file: yes

Read the entire canonical PROJECT/2-WORKING/GH-666-AGY-MODEL-PROBE.md, its entire recon, and utils/py/agy-turn.py through EOF. The Setup artifact .relay-artifacts/GH-666-AGY-MODEL-PROBE.md is absent; the canonical plan and the env-pinned parent copy have identical text. Read-only source review only: no programs/tests, Git commands, artifact edits, or runtime reproduction this turn. Historical reproduction/search results remain producer-reported evidence.

- [Should] S1 — Preserve or explicitly bound executable resolution. Plan lines 67–69 promise retained behavior while adding cwd; utils/py/agy-turn.py:259 currently passes agy_bin directly, and :333 accepts AGY_BIN unchanged. A relative path such as ./tools/agy resolves against the new temporary directory after this change; bare commands with relative PATH entries have the same risk. Cheapest fix: state supported executable forms and add validator cases for absolute and PATH-resolved binaries; either preserve caller-relative resolution before changing cwd with stdlib and a focused test, or explicitly document why these forms are unsupported. The existing auth probe already has this limitation (utils/py/agy-turn.py:142–143), so do not claim the entire shim previously supported relative paths or broaden this into a shared resolver redesign.
- [Should] S2 — Make preservation detect the actual write. Recon lines 42–43 report "caller marker exists, porcelain status empty → untracked marker"; plan lines 64–65 only specify "HEAD/tree unchanged." A tracked-tree/HEAD check can pass while the defect persists, and ordinary porcelain normally includes untracked files, so the recon needs the exact exclusion/ignore explanation. Cheapest fix: explicitly require the known marker absent in the caller (including an ignored/untracked marker case), a pre-existing caller sentinel byte-identical, and invocation evidence proving the stub wrote the marker in its recorded cwd. Require these exact assertions to fail on base and cwd ablation and land their red evidence at the existing line-85 destination. No generalized filesystem scanner is needed.
- [Pass] The unsafe call precedes containment: utils/py/agy-turn.py:351–360 invokes auth/model validation before constructing RTL; :259 has no cwd. Plan lines 41–49 price the bet, rollback, refusal and cleanup reporting while excluding process-lifecycle and absolute-write sandbox scope; recon lines 55–56 explicitly exclude detached children. Keep this scope.
- [Pass] Plan lines 61, 70–75 cap independent reviews, require full-clone gates, hold readiness on failures, target development and exclude unrelated repairs/merge. Persisted rating is present in releases.sql:634 as 90/85/50/85; plan lines 53–56 distinguish one observed defect from an unknown trend. Keep these limits; this is plan adequacy, not gate or historical-search attestation.
- [Nit] Repair the relay contract for the next turn: Setup names a missing seeded artifact and leaves DoD as "<fill in the acceptance criteria the Reviewer grades against>". Point at the canonical plan actually reviewed (or seed the intended snapshot through the harness) and name its Phase 1 checklist as DoD. No second plan is needed.

Pre-existing sweep: the model-probe inherited-CWD defect is present at :259; existing auth cleanup silently ignores removal failures at utils/py/agy-turn.py:233–235. The latter is outside this validator change; do not copy that silent cleanup into the new implementation (plan lines 48–49 already prohibit it). No additional pre-existing defect requiring expansion of this narrow plan was identified in the full source sweep.

Handing off to Producer — address S1/S2 and the relay-contract nit, log each disposition, then reopen the next review round. No approval or implementation readiness claimed.

### Producer — producer — Round 2

VERDICT: PARKED
Basis: S1/S2 and relay-contract nit addressed; revised plan review pending.
swept file: yes

S1 implemented in plan: shutil.which at caller CWD plus absolute result before
temporary child cwd; focused absolute, caller-relative, bare and relative-PATH cases.
This preserves validator resolution, not the unchanged auth probe limitation.
S2 implemented: explicit marker absence (including ignored marker), sentinel bytes
and nonempty records proving actual stub write, alongside identity/HEAD/porcelain.
The recon's baseline porcelain was ordinary/unignored and did detect the write;
no excluded-file or clean-porcelain claim was intended. New ignored-marker assertion
will expose the potential Git-only blind spot without a filesystem-scanner framework.
Nit implemented: Setup points to the committed canonical plan and its QA checklist.
Keep prior complete source sweep; check these narrow revisions, no runtime programs.
PASS -> DONE while owned. Handing off to Reviewer — give the revised cited verdict.

### Reviewer — codex — Round 2

VERDICT: FAIL
Basis: S1 and the planned preservation oracle are addressed, but S2's canonical recon correction remains unapplied and contradicts the Producer's disposition. One small evidence correction is needed; no scope expansion.
swept file: yes

Read the entire canonical plan, recon and utils/py/agy-turn.py through EOF, including failure/cleanup and final containment paths. Read-only review; no artifact execution, tests, Git commands or artifact edits. Reproduction and historical searches remain Producer-reported evidence.

- [Should] S2 residual — PROJECT/2-WORKING/recon-agy-model-probe.md, “Observed and falsified,” still states “porcelain status empty → untracked marker.” Round 2 instead states “baseline porcelain was ordinary/unignored and did detect the write.” These are contradictory observations in the canonical evidence chain. Cheapest fix: correct the recon to the actual observed porcelain result, quote the marker's status entry if available, and distinguish the newly planned ignored-marker control from the original baseline. If baseline output is unavailable, label its porcelain result unknown. No new scanner or runtime review machinery is required.
- [Pass] S1 resolved at PROJECT/2-WORKING/GH-666-AGY-MODEL-PROBE.md:70–75: caller-CWD shutil.which plus an absolute result precedes child cwd; absolute, caller-relative, bare PATH and relative PATH cases are explicitly required. The auth-probe limitation remains expressly outside scope. Implement this decision and its focused cases as written.
- [Pass] The planned oracle is falsifiable at PROJECT/2-WORKING/GH-666-AGY-MODEL-PROBE.md:64–69: nonempty records, explicit marker absence including ignored files, sentinel bytes and removed temporary cwd. Step 3 requires the same preservation checks red under cwd ablation; the QA checklist requires unchanged-base failures. Keep these assertions and the committed provenance destination; plan approval cannot substitute for witnessed red controls.
- [Pass] Bounded delivery remains explicit in the plan: “Independent Codex plan QA, cap three rounds”; “full gates in a separate full clone”; “ready only on approval/passing checks; otherwise record hold”; “Merge is not authorized.” Setup now names the canonical artifact and a substantive Definition of Done. Keep those limits.

Pre-existing sweep: utils/py/agy-turn.py:259 still inherits caller CWD before RTL initialization at :360 and snapshot at :404, grounding the proposed repair. Auth cleanup at :233–235 still silently tolerates removal failures; the plan's “Cleanup failures must be reported” avoids inheriting that defect. No additional pre-existing defect requiring expansion of this narrow plan was identified. Implementation, gate readiness and historical recurrence are not approved by this review.

Handing off to Producer — correct the canonical recon observation, log the disposition and open Round 3 for the final plan review.

### Producer — producer — Round 3

VERDICT: PARKED
Basis: Canonical baseline wording made unambiguous; final plan approval pending.
swept file: yes

S2 residual modified: the arrow meant before-to-after, not a clean after-call
result. The recon now explicitly quotes BEFORE empty and AFTER `?? probe-write.txt`,
matching the retained controlled tool output and temp/agy-probe/baseline.log.
Ignored marker is a new additional test, not the original observation. Added the
required recon status table after the scoped doc check detected its omission.
No runtime, design, scope or other plan change. Prior complete source reads stand.
Only adjudicate this clarification against the prior source-grounded plan;
do not repeat the entire unchanged source sweep or reopen settled S1.
PASS -> DONE while owned; unresolved at this cap -> Escalated, no implementation.
Handing off to Reviewer — give the final cited plan verdict.

### Reviewer — codex — Round 3

VERDICT: PASS
Basis: The canonical recon clarification resolves the final S2 finding. Phase 1 is grounded, bounded, surgical and falsifiable; approval is for the plan only.
swept file: yes

Read the whole canonical plan and recon and utils/py/agy-turn.py through EOF. Read-only review; no runtime reproduction, tests, Git commands or artifact edits. Baseline execution and historical searches remain Producer-reported evidence.

- [Pass] S2 residual resolved: PROJECT/2-WORKING/recon-agy-model-probe.md:48–51 explicitly separates BEFORE empty from AFTER `?? probe-write.txt` and identifies the ignored-marker case as a new control. This removes the contradictory clean-after-call reading. Keep this wording and retain the actual baseline output with implementation provenance.
- [Pass] The preservation oracle and executable decision remain explicit at PROJECT/2-WORKING/GH-666-AGY-MODEL-PROBE.md:62–77: nonempty invocation records proving a write, explicit marker absence including ignored files, sentinel bytes, removed temporary CWD, caller-CWD executable resolution and cwd-only ablation. Implement these focused requirements as written; witnessed base/ablation failures remain required by :87.
- [Pass] Scope and readiness are bounded at PROJECT/2-WORKING/GH-666-AGY-MODEL-PROBE.md:41–49,78–93: rollback/tripwire, reported cleanup failures, separate full-clone gates, committed provenance, final independent QA and a development PR held on failures. “Merge is not authorized.” Keep those limits; this approval supplies no implementation, gate, publication or recurrence attestation.

Pre-existing sweep: the inherited model-probe CWD at utils/py/agy-turn.py:259 remains the target defect, before RTL initialization at :360 and snapshot at :404. Auth cleanup at :233–235 still suppresses cleanup errors; the plan explicitly avoids copying that behavior. No additional pre-existing defect requiring expansion of this narrow plan was identified.

Relay closed (Approved), no further review turn needed. Producer may proceed with the approved plan; implementation verification and final QA remain outstanding.


### Attestation · relay-drive — 2026-09-17T03:33:38Z
task: RELAY-GH666-PLAN
reviewer: codex
status: Approved
reviewed-head: 8418974f4f0851758335bfbf4f40c219087d99a4
added-range: 14801+2162
added-sha256: 019456cd4b3be937cc6570605640742ea49541fa353fb825503b3c471b7aa4a1
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
