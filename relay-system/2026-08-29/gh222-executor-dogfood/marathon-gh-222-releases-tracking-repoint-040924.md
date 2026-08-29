# Marathon Phase gh-222-releases-tracking-repoint
STATUS: Approved
NEXT: codex (Reviewer)

<!-- marathon-drive: task=MARATHON-GH-222-RELEASES-TRACKING-REPOINT-TURN builder=agy reviewer=codex round-cap=5 -->

## Phase Brief

# Marathon preflight packet — gh-222-releases-tracking-repoint

- Generated: 2026-08-29T03:45:38Z
- Mode: gh-bundle
- Sources: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh222/PROJECT/2-WORKING/GH-222-RELEASES-TRACKING-REPOINT.md 
- Target root: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh222 (development @ b471df15a)
- Suggested branch: `marathon/gh-222-releases-tracking-repoint-2026-08-29` (branch_ready=false — not cut yet; ask the operator before proceeding, per GUIDING-PRINCIPLES.md §8)
- Verdict: ready
- Source issue state: OPEN.
- Gate: `bash validate.sh`

- Artifacts: utils/py/releases_app.py,test/gh32-releases-app.sh,RELEASES-DB-FAQS.md,test/gh103-timeline-exporter.sh,test/gh105-vendor-releases-addon.sh,test/gh168-wave-reconcile-scope.sh,test/gh197-vendor-tier-split.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh257-roadmap-ledger-fixes.sh,test/gh267-express-skill.sh,test/gh280-jog-marathon-adapter.sh,test/gh290-ate-variation-grid.sh,test/gh32-release-target-advisory.sh,test/gh32-releases-artifacts.sh,test/gh39-releases-project-sync.sh,test/gh53-releases-merge-resolve.sh,test/gh54-merged-dump-refusals.sh,test/gh57-live-merge-resolve.sh,test/gh57-releases-fuzz.sh,test/gh69-roadmap-shadow.sh,test/gh75-dashboard.sh,test/jog-queue.sh,test/wave-reconcile.sh,test/xyz-vendor.sh,test/baselines/GH-32-negative-control.md,test/baselines/GH-52-negative-control.md,test/_setup.sh,test/lib/fixture-guard.sh
- Suggested turn budget: `turn_timeout_s: 1800` in this phase's MARATHON.yaml entry (≈ 5420 LOC across 31 artifact(s) — over the 900s default, so it needs headroom). marathon.sh reads that field and applies it to the phase; the value is a starting point, not a measurement.
- Auto-included covering tests/helpers: test/gh103-timeline-exporter.sh,test/gh105-vendor-releases-addon.sh,test/gh168-wave-reconcile-scope.sh,test/gh197-vendor-tier-split.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh257-roadmap-ledger-fixes.sh,test/gh267-express-skill.sh,test/gh280-jog-marathon-adapter.sh,test/gh290-ate-variation-grid.sh,test/gh32-release-target-advisory.sh,test/gh32-releases-artifacts.sh,test/gh39-releases-project-sync.sh,test/gh53-releases-merge-resolve.sh,test/gh54-merged-dump-refusals.sh,test/gh57-live-merge-resolve.sh,test/gh57-releases-fuzz.sh,test/gh69-roadmap-shadow.sh,test/gh75-dashboard.sh,test/jog-queue.sh,test/wave-reconcile.sh,test/xyz-vendor.sh,test/baselines/GH-32-negative-control.md,test/baselines/GH-52-negative-control.md,test/_setup.sh,test/lib/fixture-guard.sh

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold
*Inlined verbatim from `/Users/noelsaw/Documents/GH Repos/XYZ-forge-gh222/PROJECT/2-WORKING/GH-222-RELEASES-TRACKING-REPOINT.md` (its `## Acceptance` section, 4 criterion(a)). Continuation lines included; if a
criterion here reads as a fragment, that is the source text, not a truncation.*
*NOT verified, and NOT verifiable as things stand — issue #222 has no '## Acceptance' section — nothing to copy from. This list exists only in the capture doc; reading the issue will not confirm it, because the issue states no criteria. Establish the criteria on the issue before treating anything below as the definition of done.*
- [ ] Decision recorded (immutability intentional vs. mutable) in RELEASES-DB-FAQS.md.
- [ ] If mutable: `releases update --gid <g> --tracking-issue <url>` re-points with a receipt;
      `releases check` stays clean; generated views show the new tracker.
- [ ] If intentional: FAQ names the sanctioned workaround for a superseded tracker.
- [ ] Regression coverage in the releases suite either way.

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `utils/py/releases_app.py,test/gh32-releases-app.sh,RELEASES-DB-FAQS.md,test/gh103-timeline-exporter.sh,test/gh105-vendor-releases-addon.sh,test/gh168-wave-reconcile-scope.sh,test/gh197-vendor-tier-split.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh257-roadmap-ledger-fixes.sh,test/gh267-express-skill.sh,test/gh280-jog-marathon-adapter.sh,test/gh290-ate-variation-grid.sh,test/gh32-release-target-advisory.sh,test/gh32-releases-artifacts.sh,test/gh39-releases-project-sync.sh,test/gh53-releases-merge-resolve.sh,test/gh54-merged-dump-refusals.sh,test/gh57-live-merge-resolve.sh,test/gh57-releases-fuzz.sh,test/gh69-roadmap-shadow.sh,test/gh75-dashboard.sh,test/jog-queue.sh,test/wave-reconcile.sh,test/xyz-vendor.sh,test/baselines/GH-32-negative-control.md,test/baselines/GH-52-negative-control.md,test/_setup.sh,test/lib/fixture-guard.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run ANY test or gate yourself — not `bash validate.sh`, and NOT `test/gh32-releases-app.sh,test/gh103-timeline-exporter.sh,test/gh105-vendor-releases-addon.sh,test/gh168-wave-reconcile-scope.sh,test/gh197-vendor-tier-split.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh257-roadmap-ledger-fixes.sh,test/gh267-express-skill.sh,test/gh280-jog-marathon-adapter.sh,test/gh290-ate-variation-grid.sh,test/gh32-release-target-advisory.sh,test/gh32-releases-artifacts.sh,test/gh39-releases-project-sync.sh,test/gh53-releases-merge-resolve.sh,test/gh54-merged-dump-refusals.sh,test/gh57-live-merge-resolve.sh,test/gh57-releases-fuzz.sh,test/gh69-roadmap-shadow.sh,test/gh75-dashboard.sh,test/jog-queue.sh,test/wave-reconcile.sh,test/xyz-vendor.sh,test/_setup.sh,test/lib/fixture-guard.sh` either. Those tests create temporary git fixtures/files inside your isolated worktree, which containment treats as off-lane edits and can discard your whole turn. Read them as specs instead; the harness runs the real gate after your turn, outside the worktree.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-222-releases-tracking-repoint RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact utils/py/releases_app.py,test/gh32-releases-app.sh,RELEASES-DB-FAQS.md,test/gh103-timeline-exporter.sh,test/gh105-vendor-releases-addon.sh,test/gh168-wave-reconcile-scope.sh,test/gh197-vendor-tier-split.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh257-roadmap-ledger-fixes.sh,test/gh267-express-skill.sh,test/gh280-jog-marathon-adapter.sh,test/gh290-ate-variation-grid.sh,test/gh32-release-target-advisory.sh,test/gh32-releases-artifacts.sh,test/gh39-releases-project-sync.sh,test/gh53-releases-merge-resolve.sh,test/gh54-merged-dump-refusals.sh,test/gh57-live-merge-resolve.sh,test/gh57-releases-fuzz.sh,test/gh69-roadmap-shadow.sh,test/gh75-dashboard.sh,test/jog-queue.sh,test/wave-reconcile.sh,test/xyz-vendor.sh,test/baselines/GH-32-negative-control.md,test/baselines/GH-52-negative-control.md,test/_setup.sh,test/lib/fixture-guard.sh \
  --pre-advance-cmd 'bash validate.sh' \
  --require-clean
```

## Files in this packet
- `run-candidate.json` — normalized run candidate (provenance + contract + checks)
- `freshness.json` — branch state + fix-still-required probes
- `readiness.json` — remediation readiness verdict
- `lane-plan.json` — Codex / agy / orchestrator lane assignment
- `marathon-invocation.txt` — the invocation hint above
- `marathon-invocation.json` — the same invocation as structured data (`swarm-preflight/marathon-invocation@1`, GH-280); supervisors consume this, never the shell text


---

▶ TAKE YOUR TURN (agy — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): utils/py/releases_app.py,test/gh32-releases-app.sh,RELEASES-DB-FAQS.md,test/gh103-timeline-exporter.sh,test/gh105-vendor-releases-addon.sh,test/gh168-wave-reconcile-scope.sh,test/gh197-vendor-tier-split.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh257-roadmap-ledger-fixes.sh,test/gh267-express-skill.sh,test/gh280-jog-marathon-adapter.sh,test/gh290-ate-variation-grid.sh,test/gh32-release-target-advisory.sh,test/gh32-releases-artifacts.sh,test/gh39-releases-project-sync.sh,test/gh53-releases-merge-resolve.sh,test/gh54-merged-dump-refusals.sh,test/gh57-live-merge-resolve.sh,test/gh57-releases-fuzz.sh,test/gh69-roadmap-shadow.sh,test/gh75-dashboard.sh,test/jog-queue.sh,test/wave-reconcile.sh,test/xyz-vendor.sh,test/baselines/GH-32-negative-control.md,test/baselines/GH-52-negative-control.md,test/_setup.sh,test/lib/fixture-guard.sh
2. Append a build block to this relay file: `### Round N · Builder · agy` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh222/bin/tick
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh222/bin/tick claim MARATHON-GH-222-RELEASES-TRACKING-REPOINT-TURN --agent agy --paths "marathon-system/gh-222-releases-tracking-repoint/RELAY.md,utils/py/releases_app.py,test/gh32-releases-app.sh,RELEASES-DB-FAQS.md,test/gh103-timeline-exporter.sh,test/gh105-vendor-releases-addon.sh,test/gh168-wave-reconcile-scope.sh,test/gh197-vendor-tier-split.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh257-roadmap-ledger-fixes.sh,test/gh267-express-skill.sh,test/gh280-jog-marathon-adapter.sh,test/gh290-ate-variation-grid.sh,test/gh32-release-target-advisory.sh,test/gh32-releases-artifacts.sh,test/gh39-releases-project-sync.sh,test/gh53-releases-merge-resolve.sh,test/gh54-merged-dump-refusals.sh,test/gh57-live-merge-resolve.sh,test/gh57-releases-fuzz.sh,test/gh69-roadmap-shadow.sh,test/gh75-dashboard.sh,test/jog-queue.sh,test/wave-reconcile.sh,test/xyz-vendor.sh,test/baselines/GH-32-negative-control.md,test/baselines/GH-52-negative-control.md,test/_setup.sh,test/lib/fixture-guard.sh"
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh222/bin/tick ping MARATHON-GH-222-RELEASES-TRACKING-REPOINT-TURN --agent agy
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh222/bin/tick release MARATHON-GH-222-RELEASES-TRACKING-REPOINT-TURN --agent agy --to codex
4. Edit ONLY these paths: marathon-system/gh-222-releases-tracking-repoint/RELAY.md and utils/py/releases_app.py,test/gh32-releases-app.sh,RELEASES-DB-FAQS.md,test/gh103-timeline-exporter.sh,test/gh105-vendor-releases-addon.sh,test/gh168-wave-reconcile-scope.sh,test/gh197-vendor-tier-split.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh257-roadmap-ledger-fixes.sh,test/gh267-express-skill.sh,test/gh280-jog-marathon-adapter.sh,test/gh290-ate-variation-grid.sh,test/gh32-release-target-advisory.sh,test/gh32-releases-artifacts.sh,test/gh39-releases-project-sync.sh,test/gh53-releases-merge-resolve.sh,test/gh54-merged-dump-refusals.sh,test/gh57-live-merge-resolve.sh,test/gh57-releases-fuzz.sh,test/gh69-roadmap-shadow.sh,test/gh75-dashboard.sh,test/jog-queue.sh,test/wave-reconcile.sh,test/xyz-vendor.sh,test/baselines/GH-32-negative-control.md,test/baselines/GH-52-negative-control.md,test/_setup.sh,test/lib/fixture-guard.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to codex — codex, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: codex (Reviewer)`

---

▶ TAKE YOUR TURN (codex — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/releases_app.py,test/gh32-releases-app.sh,RELEASES-DB-FAQS.md,test/gh103-timeline-exporter.sh,test/gh105-vendor-releases-addon.sh,test/gh168-wave-reconcile-scope.sh,test/gh197-vendor-tier-split.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh257-roadmap-ledger-fixes.sh,test/gh267-express-skill.sh,test/gh280-jog-marathon-adapter.sh,test/gh290-ate-variation-grid.sh,test/gh32-release-target-advisory.sh,test/gh32-releases-artifacts.sh,test/gh39-releases-project-sync.sh,test/gh53-releases-merge-resolve.sh,test/gh54-merged-dump-refusals.sh,test/gh57-live-merge-resolve.sh,test/gh57-releases-fuzz.sh,test/gh69-roadmap-shadow.sh,test/gh75-dashboard.sh,test/jog-queue.sh,test/wave-reconcile.sh,test/xyz-vendor.sh,test/baselines/GH-32-negative-control.md,test/baselines/GH-52-negative-control.md,test/_setup.sh,test/lib/fixture-guard.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
1. Append a review block: `### Round N · Reviewer · codex` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: agy (Builder)`, then: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh222/bin/tick release MARATHON-GH-222-RELEASES-TRACKING-REPOINT-TURN --agent codex --to agy
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh222/bin/tick done MARATHON-GH-222-RELEASES-TRACKING-REPOINT-TURN --agent codex
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh222/bin/tick
   Edit ONLY marathon-system/gh-222-releases-tracking-repoint/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
4b. TO VERIFY A FINDING, WRITE PROBE FILES OUTSIDE THE REPO — under $TMPDIR, never inside the
   working tree. Creating even one scratch file in the repo is an off-lane write: containment
   reverts it and FAILS YOUR WHOLE TURN, discarding the review you just did (GH-441). Observed
   2026-08-08: a reviewer found a real latent crash, wrote two probe files in-tree to demonstrate
   it, and lost the turn for doing so — the finding survived only because RELAY.md happens to be
   on your allowlist. `cp` what you need to "$TMPDIR/probe.$$/" and work there instead. Verifying
   is wanted; verifying in-tree is what costs you the turn.
5. HAND OFF EXPLICITLY (GH-268): end your turn by naming who acts next — "handing off to agy —
   agy, take your turn" when requesting changes, or "relay closed, no further turn needed" when
   approving. The beta report singled this out: the Reviewer turn did not tell the user to go back to the
   Producer, so the relay looked stalled when it was simply waiting. Do this EVERY round.

### Round 1 · Builder · agy

I have implemented the acceptance criteria by making the tracking issue mutable.
1. Updated `RELEASES-DB-FAQS.md` to document the decision that the tracking issue is mutable, explaining how to use `releases update --tracking-issue` and that it writes a receipt and generated views show the new tracker.
2. Modified `utils/py/releases_app.py` in `cmd_update` to remove the `refuse` for `--tracking-issue`. It now calls `issue_ref_for_token` and updates `tracking_ref_id` in the `releases` table. The change runs within `mutate()` which automatically gets verified and signed into `op_receipts` by `perform_write()`.
3. Updated the regression test in `test/gh32-releases-app.sh` from expecting an immutable failure to verifying the fields and tracking reference update successfully.

### Round 1 · Reviewer · codex

swept file: yes

The `cmd_update` change correctly validates the replacement through `issue_ref_for_token`, updates `tracking_ref_id` inside the writer-locked transaction, and therefore obtains the ordinary `update` receipt and refreshes an already-existing generated view. I found no additional pre-existing correctness defect in the three modified files.

Changes requested:

1. Make the regression prove the complete mutable-tracker contract, rather than only the joined DB value. In section K, create the generated view before the repoint and assert that the post-update view contains the replacement tracker; run `releases check` and assert it is clean; and assert an `op_receipts` row with `op='update'` and this release GID exists. The current `COUNT(DISTINCT op) >= 2` can pass without proving that the repoint generated a receipt.
2. Rename the section/comment text that still calls this behavior “immutability”, and expose `--tracking-issue` in `releases update --help` now that it is a supported mutable field (a concise URL/TMP help string is sufficient).

**Verdict:** Changes requested

### Round 2 · Builder · agy

Implemented the requested changes:
1. Updated section K of `test/gh32-releases-app.sh` to prove the complete mutable-tracker contract. The test now asserts that `rout gen` creates a view with the replacement tracker, `releases check` remains clean, and an `op_receipts` row is explicitly created for the update operation on the given release GID.
2. Renamed the "immutability" test section header to "mutable tracker".
3. Exposed `--tracking-issue` in the `releases update --help` parser in `utils/py/releases_app.py` by removing `argparse.SUPPRESS` and setting a proper help string.

### Round 2 · Reviewer · codex

swept file: yes

The mutable-reference implementation is transactionally correct: it validates through
`issue_ref_for_token`, persists `tracking_ref_id` in the ordinary writer-locked update, and
therefore stages the already-generated view plus an `update` receipt. The FAQ and help surface
match that behavior. I found no additional pre-existing correctness defect in the reviewed files.

One regression gap remains. Section K performs a codename `update` before the tracker repoint, so
`COUNT(*) FROM op_receipts WHERE op='update' AND target_gid='$K1' >= 1` can be satisfied even if
the repoint did not create a receipt. Capture the matching receipt count immediately before the
`--tracking-issue` command, then assert it increased by exactly one afterward (or equivalently
assert the post-repoint receipt's distinct transaction evidence). This is required to prove the
acceptance criterion's receipt is for the repoint itself.

**Verdict:** Changes requested

### Round 3 · Builder · agy

I fixed the remaining regression gap in `test/gh32-releases-app.sh`. Section K now captures the receipt count before the repoint by assigning `PRE_UPD="$(sql "SELECT COUNT(*) FROM op_receipts WHERE op='update' AND target_gid='$K1'")"` immediately before the `--tracking-issue` command, and then verifies that the count increases by exactly one (`"$N_UPD" -eq "$((PRE_UPD + 1))"`). This proves that the acceptance criterion's receipt is for the repoint itself.

### Extension · System
relay-drive: round cap (5) reached but lane is converging (new commits or resolved items) — bounded extension granted to cap 6

### Round 4 · Reviewer · codex

swept file: yes

The complete mutable-tracker contract is now covered. `cmd_update` validates the supplied
reference through `issue_ref_for_token`, updates `tracking_ref_id` inside the ordinary
writer-locked transaction, and consequently stages an updated generated view and appends the
standard `update` receipt. Section K creates that generated view before repointing, proves it
shows the replacement tracker, confirms `releases check` remains clean, and proves the update
receipt count for this GID rises by exactly one across the repoint. The FAQ and CLI help agree
with the supported behavior. I found no additional pre-existing correctness defect in the
reviewed files.

**Verdict:** Approved

### Extension · System
relay-drive: round cap (6) reached but lane is converging (new commits or resolved items) — bounded extension granted to cap 7
