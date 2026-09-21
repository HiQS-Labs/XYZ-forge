# RELAY · GH-673 replacement focused completion review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-17.
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
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh673-replacement-focused): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: GH-673 reader candidate at the driver's pinned HEAD `8391d93f`
  (branch `fix/gh673-reader-completion`, rebased 2026-09-20 onto origin/development `41be79e2`;
  every content path is patch-identical to the pre-rebase tip `09ec4faa`, whose runtime is
  `95b3cc24` plus the scoped equal-time identity and simultaneous row/root diagnostic repairs;
  the GH-673 ledger row was replayed through releases_app on the new base, never text-merged).
  Focused evidence on this head, 2026-09-20: pytest test/flightdeck 39/39; work-status selector
  checks pass; real-Chrome checks pass (Node 26); manual harness fixture checks pass;
  gh53-releases-merge-resolve 17/17 (its 2026-09-17 red was the fixture flake fixed by #688).
  Read `PROJECT/2-WORKING/GH-673-FLIGHTDECK-STATUS.md` and the changed runtime files:
  `src/flightdeck/{contract,connectors,aggregate}.py`, `utils/py/releases_cycle.py`,
  `web/flightdeck/{app.js,issue-context.mjs}`, plus focused tests and manual harness.
  In `utils/py/releases_app.py`, sweep `load_work_evidence` and its direct helper/caller
  paths (`_origin_repo_identity`, `_repo_from_issue_url`, `_utc_datetime`, WAL/header
  refusal, lifecycle qualification, settings/schema helpers, `cmd_work_status`).
  The operator explicitly approved this focused changed-function/callers scope;
  no literal unrelated 6500-line whole-file sweep is required for releases_app.py.
  Declare the limited sweep honestly (`swept file: no` for that shared file plus
  `swept changed functions and callers: yes/no`); scope alone is not a defect.
  This fresh replacement cap2 does not reset or conceal the old escalated cap3 review.
- Reviewer: agy (operator-selected substitute; Codex is over its usage limit until 2026-09-19 01:26 UTC+... — see #688 precedent)   ·   Producer: claude-a
- Started: 2026-09-17
- Definition of Done: surgical optional read-only local dashboard; no source task,
  cached/GitHub label or schema writes; normal SQLite coordination files permitted.
  No migration, live connector enablement, merge, deploy or Daily changes. Qualified
  explicit starts plus fresh native state/labels establish work; native closure wins;
  stale/missing/conflicting evidence remains uncertain, never guessed.

### Concrete review questions

1. Does a bad helper-owned row remain a per-issue gap without confirming that issue
   or poisoning good peers, including canonical duplicates under legacy repo IDs?
   Are unresolvable rows counted, per-row errors preserved through finalization,
   and root errors/caps still conservative? Are error-only quiet cards visible?
2. Do bounded subprocess/native SQLite readers preserve data/schema and avoid writer,
   CLI, config dispatch and ledger-root executable loading? Read their cleanup and
   timeout paths plus callers; do not request unrelated machinery.
3. Do healthy unchanged native AND inferred-card drawers stay open while changed
   handoff content/title, vanished current targets, failed reads and expiry invalidate
   copyable stale context? Does recomputation use current cards rather than saved objects?
4. Are positive and negative populated tests meaningful and scope/rollback honest?
   39 Python tests, selector and Chrome checks pass. Original and audit regressions failed
   before repair; selector error-guard mutation fails. These are focused evidence,
   not the qualifying full gate, writer landing or release readiness.

Pre-review advisory audit is retained in TESTS-RESULTS/2026-09-17+GH-673/.
It requested two fixes (equal-time native identity conflicts; preserving simultaneous
root/row errors). Both reproduced, repaired and witnessed red again when deleted.
That one-shot advisory answer is not a driven reviewer turn or final approval;
ROUND remains 1/2 and no actual replacement reviewer turn has yet been dispatched.

Report [Blocker]/[Should]/[Nit]/[Pass] with file:line citations; exact VERDICT PASS,
FAIL or PARKED and Basis. Only real PASS with no unresolved blocker/should may set
STATUS Approved. Read-only reviewer; modify/commit only this relay file. Do not run
validate.sh, test/*.sh, pytest or executable fixtures in the isolated reviewer worktree.
Tests belong in disposable full clones. Narrow non-mutating probes are permitted
under the landed GH-681 reviewer contract, with cited input, command and output.
No push. Time bounded by the driver.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
