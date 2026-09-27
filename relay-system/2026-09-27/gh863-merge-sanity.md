# RELAY · PR #863 merge sanity — #851/#852 into staging/stabilize-2026-10
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-27.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 1

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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(pr-863-merge-sanity-851-852-into-staging-stabilize-2026-10): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: PR #863 as merged into the staging branch — the diff from origin/staging/stabilize-2026-10 (dcc449fb) to HEAD. Key files: `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`, `skills/2-daily/merge-cleanup/scripts/scan_clones.py`, `skills/2-daily/merge-cleanup/SKILL.md`, `test/gh436-merge-cleanup.py`, `test/gh534_phase_a_tests.py`, `test/gh534_phase_b_tests.py`, `CHANGELOG.md`, `TESTS-RESULTS/2026-09-27+GH-851/SUMMARY.md`, `TESTS-RESULTS/2026-09-27+GH-851/PLAN.md`. Read in place; do NOT edit.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-27
- Definition of Done: see *Review packet*. **One round, a sanity check** (operator, 2026-09-27): PASS means safe to squash-merge into the staging branch now.

## Review packet

**The question:** is PR #863 safe to squash-merge into `staging/stabilize-2026-10` now? This is a sanity check, not a second implementation review. The implementation had plan QA (2 rounds) and final QA (1 round, R1 and R2 fixed): `relay-system/2026-09-27/gh851-852-plan-review.md` and `relay-system/2026-09-27/gh851-852-final-qa.md`.

**Since final QA, three things changed.** Review these closely:
1. **Merge commit `9a7b9fb3`.** The task branch is merged onto the staging tip `dcc449fb`. `releases.db`, `releases.sql` and `LEADERBOARD.md` are taken wholesale from the staging side. The plan doc moved to `TESTS-RESULTS/2026-09-27+GH-851/PLAN.md`, because any `PROJECT/` doc without a ledger row fails `pdda-check-roadmap-coverage`, and branch PRs write no ledger rows (#854 per-PR rule).
2. **Commit `6555fc2e`.** `prepare_landing_clone` clears the partial clone directory before each GH-623 retry. It was found on #820's landing: the clone hit its 180 s bound, and the retry failed on `destination path already exists`. Witness `r3_clone_retry_after_stall` is red at `9a7b9fb3` and green at `6555fc2e`.
3. **Commit `fe5f27bd`.** Evidence only.

**Definition of Done (PASS when all hold):**
- (a) **Scope.** The net diff against the staging tip touches only the files in Setup, plus `TESTS-RESULTS/2026-09-27+GH-851/**` and the two `relay-system/2026-09-27/gh851-852-*.md` threads. No `releases.db`/`.sql`/`LEADERBOARD.md` change, no `PROJECT/` change, no new file under `test/`, and no `validate.sh`, registry, workflow or `utils/ci-route.sh` change. Verify with local git: `git diff --name-status dcc449fb..HEAD`.
- (b) **The merge commit dropped nothing from staging.** `CHANGELOG.md` keeps every staging entry and adds exactly one GH-851/852 entry. Staging's entries from #803/#820 era (GH-813, GH-800 M4 Pro and M6) are present.
- (c) **`6555fc2e` is correct and minimal.** `shutil` is imported, the `rmtree` targets only the per-PR clone path under the run's `workdir`, and nothing else in `prepare_landing_clone` changed.
- (d) **The evidence is consistent at head.** `SUMMARY.md` and `provenance.jsonl` name the commits whose code they tested. The latest focused run (`focused-6555fc2e/`) matches the head's code: `fe5f27bd` changed only `TESTS-RESULTS`. No log in `TESTS-RESULTS/2026-09-27+GH-851/` is empty.
- (e) **CI facts.** These are stated by the Producer from GitHub; verify only what you can locally:
  - `ci.yml` has no `pull_request` trigger for this base (`.github/workflows/ci.yml:99-103`), so the PR's only check is CodeRabbit ("reviews are disabled for this base branch").
  - Per #854, the branch is checked by dispatch: run 36355233260 (`workflow_dispatch` on `fe5f27bd`), where `vendored-smoke` must be green and the Ubuntu canary is advisory. The Producer confirms that run's result before merging.
  - No local full gate ran: a D2 bypass, disclosed in the PR body.

**Operating envelope.** A single-operator developer tool. Grade merge-readiness against these checks only. Do not reopen accepted design, ask for new tests or infrastructure, or grade against multi-tenant threat models.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
