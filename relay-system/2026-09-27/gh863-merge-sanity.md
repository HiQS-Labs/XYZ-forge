# RELAY · PR #863 merge sanity — #851/#852 into staging/stabilize-2026-10
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-27.
-->

NEXT: Producer
STATUS: Approved
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

### Reviewer · Round 1 · codex

VERDICT: PASS
Basis: The locally measurable merge-sanity criteria hold for the seeded head `606ef435` (PR code at `6555fc2e`, evidence at `fe5f27bd`). Approve the staging squash under the packet's #854 D2 route; Producer still owns confirming run 36355233260's blocking job before merging. This is not a full-gate or promotion attestation.

swept file: no

Review scope: read the relay, the merge-cleanup orchestrator and surrounding control flow, the complete net implementation/test diff, the retry-only diff, prior QA dispositions, and evidence. Compared whole committed file contents for staging preservation and code freshness. Did not repeat the prior implementation review's whole-file audit of every unchanged scanner/test/changelog line: the packet explicitly scopes this turn to a merge sanity check. No additional pre-existing defect was established in the reviewed scope; no broader absence-of-defects claim is made.

- **[Pass] Scope and staging preservation.** Read-only object inspection (including SHA-1 verification of decoded objects) found the PR range `dcc449fb..fe5f27bd` confined to the packet's allowlist. No added test file, PROJECT change, gate/registry/workflow change, or ledger/view change. The seeded `606ef435` adds only this `gh863-merge-sanity.md` thread, an expected review-scaffold exception to (a), not a product change. `releases.db`, `releases.sql`, and `LEADERBOARD.md` have identical staging/head blobs. The complete CHANGELOG comparison is one insertion of 27 lines after `# Changelog`; every staging line remains, including GH-813 and GH-800 M4 Pro/M6 at `CHANGELOG.md:178,182,186`. No fix needed.

- **[Pass] Retry cleanup is minimal and contained in this operating envelope.** `merge_cleanup.py:19` imports `shutil`; `:295` creates a fresh per-PR directory with `mkdtemp(..., dir=str(workdir))`; `:298-302` clears only that directory before each clone attempt. `land_prs` owns the freshly allocated workdir at `:840`. Comparing `9a7b9fb3` to `6555fc2e` shows only the lambda-to-`_clone_once` replacement in production code; its companion change is the manual witness. The recorded input/result at `witness/r3-before.jsonl:1` is `clone_retry_failed_on_leftover_dir: true`; `witness/r3-after.jsonl:1` is `clone_succeeded_on_retry: true` (the later fixture fetch failure is intentional). No fix needed.

- **[Pass] Evidence matches the code, and logs are populated.** The only `6555fc2e..fe5f27bd` changes are in `TESTS-RESULTS/2026-09-27+GH-851/`; the only subsequent seed change is this relay. `SUMMARY.md:50-56`, `provenance.jsonl:12`, and `focused-6555fc2e/identity.txt:1-2` identify `6555fc2e`. The logs report 180 tests OK (`focused-6555fc2e/gh436-merge-cleanup.log:2050-2052`), 6 OK (`gh674-merge-cleanup-hosted-lookup.log:5-7`), and 8 OK (`gh645-merge-cleanup-xyz-tools.log:3-5`). `red-control.log:9` records `AssertionError: 0 != 2`; `red-control-restore.log:5` records `OK`. All 47 `.log` files are non-empty. These are inspected committed receipts, not suites rerun in this turn. No fix needed.

- **[Pass] Local CI configuration agrees with the packet.** `.github/workflows/ci.yml:99-104` limits pull requests to main/development and permits dispatch; `:245-252` permits the advisory Ubuntu canary on dispatch with `continue-on-error: true`; `:519-522` declares blocking vendored-smoke. **[Unverified — external result]** No local artifact establishes the live conclusion of run 36355233260, CodeRabbit's current result, or the current PR-body disclosure. Producer must confirm those as assigned by (e). The disclosed absence of a local full gate is preserved (`SUMMARY.md:35`); none was run here.

- **[Nit] Moved-plan pointer.** `SUMMARY.md:3` still points to `PROJECT/2-WORKING/GH-851-MERGE-CLEANUP-LANDING-RESILIENCE.md`, which is absent after the move. Update this pointer to `TESTS-RESULTS/2026-09-27+GH-851/PLAN.md` when touching the evidence next. This does not invalidate the named commits or receipts and need not hold the squash.

Probe receipt: command `PYTHONDONTWRITEBYTECODE=1 python3 "$TMPDIR/object_probe.py"` (scratch-only read-only decoder of loose/packed commit/tree/blob objects, no Git invocation), exit **0**. Decisive output:

```text
STAGING_IDENTICAL releases.db True
STAGING_IDENTICAL releases.sql True
STAGING_IDENTICAL LEADERBOARD.md True
RETRY_COMMIT ['TESTS-RESULTS/2026-09-27+GH-851/witness.py.txt', 'skills/2-daily/merge-cleanup/scripts/merge_cleanup.py']
RELAY_SEED_COMMIT ['relay-system/2026-09-27/gh863-merge-sanity.md']
WORKTREE_MISMATCHES []
LOGS 47 EMPTY []
```

The same command printed the full changed-path list and complete retry/CHANGELOG diffs summarized above. A separate `rg -n 'Ran [0-9]+ tests|^OK$|FAILED' TESTS-RESULTS/2026-09-27+GH-851/focused-6555fc2e/*.log` (exit **0**) produced the cited 180/6/8 totals, expected failing red control, and passing restore. No Git command, suite, fixture, or source mutation was performed.

Relay closed (Approved), no further review turn needed. Producer (claude-a) owns the already-required live CI confirmation and squash into staging; the harness owns committing this relay file.


### Attestation · relay-drive — 2026-09-27T22:29:49Z
task: RELAY-gh863-merge-sanity
reviewer: codex
status: Approved
reviewed-head: 606ef435749e72aabdc0b464ab6de8ae90f31ad2
added-range: 8948+5160
added-sha256: da9552d933604508b6207b326ae189057eb31f296f97388da3fda6586297662c
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
