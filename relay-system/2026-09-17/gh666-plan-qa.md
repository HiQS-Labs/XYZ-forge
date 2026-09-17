# RELAY · GH-666 narrow probe plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-16.
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
- Artifact under review: **.relay-artifacts/GH-666-AGY-MODEL-PROBE.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-666-AGY-MODEL-PROBE.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: producer
- Started: 2026-09-16
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

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

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
