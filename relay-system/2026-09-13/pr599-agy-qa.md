# RELAY · PR 599 producer Agy QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-13.
-->

NEXT: codex
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
6. **Commit only the relay file** (`relay(pr599-agy-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh599-agy-qa.md** — the read-only path that
  `relay-drive.sh --artifact-file /private/tmp/gh599-agy-qa.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: agy   ·   Producer: codex
- Started: 2026-09-13
- Definition of Done: Answer all five QA questions in the seeded artifact with cited findings; code approval requires no material correctness blocker, with live acceptance explicitly pending.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### agy QA Review (Round 1)

**swept file: yes**

- **[Blocker]** Hardcoded PR number in permanent campaign store. `GH-591` is hardcoded as the folder name in both `utils/py/wave_reconcile.py:578` (`f"{now:%Y-%m-%d}+GH-591"`) and `.github/workflows/wave-reconcile.yml:39` (`receipt = r'TESTS-RESULTS/.../\+GH-591/...'`). This forces all future qualifications to be logged under this PR's issue number.
  - **Fix:** Change `+GH-591` to a generic campaign name like `+wave` in `utils/py/wave_reconcile.py:578`, `.github/workflows/wave-reconcile.yml:39`, and the corresponding test fixtures in `test/gh421-auto-wave-reconcile.sh:345`.
- **[Pass]** Strict telemetry validation and path confinement. `qualify_landings` checks out the code in an isolated clone (`--no-local`), correctly bounds the run to 90 minutes (`run_bounded`), and reads telemetry directly by matching the launched `validation.pgid`, completely bypassing stale or nested receipts (GH-599 QA1).
- **[Pass]** Failure paths and rollback. `RollbackJournal` accurately reverts created validation receipts on any subprocess failure. Push races are intercepted by the `HEAD` check on `wave_reconcile.py:574` prior to receipt commit, throwing exit 6 to enable later recovery (GH-599 QA2/QA3).
- **[Pass]** Pre-push commit boundary tests. `gh591-prepush-commit-boundary.sh:19-27` successfully asserts that hook-generated files are absent from the pushed tree and require a distinct subsequent push, proving the original missing-receipt defect (GH-599 QA4).
- **[Pass]** Meets producer criteria without breaking older callers. The `--qualify` flag extends the existing job effectively without migrating off the expected `TESTS-RESULTS/` store. Pre-existing defects in `utils/py/wave_reconcile.py` (like unchecked JSON outputs) are non-material (GH-599 QA5).

**VERDICT: FAIL**
**Basis:** Material correctness blocker found in the hardcoded campaign folder name (`GH-591`) which would misroute all future receipts into a PR-specific directory. Pre-existing defects swept and no material blockers found.

handing off to codex — go to the codex window and say 'take your turn'

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
