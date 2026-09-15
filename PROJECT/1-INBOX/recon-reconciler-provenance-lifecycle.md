# Recon Map — reconciler provenance lifecycle

Commit: cf990598e43f4a406b21d550e4bf10c5a458573d · Mode: graph + exact source fallback · Lanes: A/B/C/D (two independent read-only reviewers plus parent)

## Table of contents
- [Subject and change class](#subject-and-change-class)
- [The seams](#the-seams)
- [Call paths in](#call-paths-in)
- [State and contracts](#state-and-contracts)
- [Build, failure and rollback today](#build-failure-and-rollback-today)
- [Falsification and recommendation](#falsification-and-recommendation)
- [Paths without receipts](#paths-without-receipts)
- [Unknowns](#unknowns)

## Subject and change class

Cross-module producer/consumer contract repair in the existing post-merge reconciler and workflow.
The XYZ-forge graph generation is 2026-09-01T15:54:30Z. Coverage reports changed metadata for
wave_reconcile.py, express.py, pre-push, ci-local.sh and ci.yml, and untracked GH-421/GH-425 tests
and wave workflow. Graph evidence is a stale lead only; all material findings below use current source.

## The seams

| Seam | Location at base commit | Crosses | Breaks if |
|---|---|---|---|
| Push route | `githooks/pre-push:64-93,117-218,254-313` | Git ref -> worktree test | A created file is mistaken for committed evidence |
| Evidence | `utils/py/wave_reconcile.py:415-618` | JSONL -> closeout/premerge | Local receipt identity does not survive squash, or stale evidence is accepted |
| Hosted execution | `.github/workflows/wave-reconcile.yml:3-94` | PR event -> moving development -> bot commit | Test snapshot and attributed merge diverge, or push loses a race |
| Recovery | `utils/py/wave_reconcile.py:922-968` | Closed issue drift -> PRs | One legacy row aborts, or a lost no-issue PR event is never discovered |
| Hotfix | `utils/py/express.py:559-599,663-721,900-907` | Local suite -> direct development push | Bypass gives no retained provenance |
| Other landers | `utils/py/jog_run.py:975-1026`; `scripts/merge_cleanup.py:254-297` | Merge -> local reconciliation | Duplicate ownership races hosted reconciliation |

## Call paths in

- Ordinary pushes -> dispatch hook -> docs PDDA / tier-2 subsystem / full validation. Delete-only
  does no tests; empty stdin takes full validation; unavailable/stale remote base and offline
  ls-remote take full validation; explicit bypass exits 0 without evidence. None writes provenance.
- PR closed -> serialized, non-canceling macOS workflow -> checkout current development -> refuse
  protected development -> `--pr N --gate` -> mutate docs/ledger -> restricted commit/push.
- Schedule/dispatch -> same job -> `--catch-up --gate`. Discovery only considers closed issues in
  manifests, nonterminal roadmap rows and active GH docs. No-issue PRs and open-issue mentions are
  not recovered after lost events or rejected bot pushes. This must be closed within #591.
- Express already invokes `--commit SHA`, including resume, but without `--gate`; it runs only the
  registered hotfix suite then bypasses the full pre-push hook. It is an evidence gap, not an absent
  reconciliation path. Its closeout persistence also bypasses the hook.
- Marathon writes a local gate receipt (`marathon_drive.py:2632-2654`); closeout pushes normally
  (`marathon-closeout.sh:149-189`). A two-pass refusal would interrupt that wrapper.
- Jog invokes offline local reconciliation without gate; manifest omits head/merge SHAs. Cleanup's
  skill promises hosted waiting (`skills/merge-cleanup/SKILL.md:126-129`) but implementation calls
  local reconciliation immediately. Existing #534/#538 own that migration.

## State and contracts

- `ci-local.sh:430-440` -> `utils/gate-record.sh:48-106` writes ignored `.gate-evidence/<SHA>.txt`
  and best-effort `.xyz/receipts/<SHA>.json` (`utils/py/gate_receipt.py:28-84`). Neither is visible to
  TESTS-RESULTS consumers. Gate-status and marathon read these stores; do not fork them into a service.
- Both validation runners emit JSONL through `test/lib/runner-telemetry.sh:65-77,130-175` under
  ignored `.tick/telemetry`: start commit/mode/tier/registered, per-suite exits, final envelope/counts.
  This is the existing raw evidence to retain. The local runner's temporary transcript is deleted.
- GH-430 is the predecessor issue, not current-repo #430 (which is an unrelated PR). It establishes
  committed retention, not a universal schema. `TESTS-RESULTS/README.md:7-26` calls this a permanent
  campaign store. ATE error rows, improve-loop metrics and local gate receipts have distinct schemas.
- `check_provenance_receipts:415-499` checks attribution only: pr/pr_number or SHA (merge, head,
  or any PR commit; prefixes >=7 accepted). It does NOT prove passing tests or committed bytes.
  `validate_pre_merge_receipts:501-618` separately checks committed passing evidence and rejects
  code changes after a matched recent commit. Do not replace either with a green PR smoke check.
- No pruning/rotation of committed campaigns was found in the bounded producer/consumer scan.
  Local JSON replaces a same-SHA receipt; telemetry deletes merged shards; improve-loop initializes
  its run file. These local mechanics do not prune TESTS-RESULTS.

## Build, failure and rollback today

Exact baseline commands and output are retained in
`TESTS-RESULTS/2026-09-13+GH-591/provenance.jsonl`:

1. `python3 utils/py/wave_reconcile.py --pr 590 --gate` -> exit 6, no matching receipt.
2. `python3 utils/py/wave_reconcile.py --catch-up --gate` -> exit 6, closed GH-52 has no attributable PR.

Hosted corroboration: [PR #590 run](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/34733897594),
[scheduled failure](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/34717683882).
Some September 11 runs succeeded: the handoff's "every run since September 10" was too broad.

`RollbackJournal:145-195` snapshots tracked artifacts and removes created files; errors restore
the baseline and check porcelain. Qualification artifacts must join this journal. The workflow
publishes only declared paths and never forces/rebases a generated DB. A rejected fast-forward
push requires recomputing from fresh development. Catch-up currently cannot cover all such PRs.

Prior assumptions, cross-referenced:
- #421 assumed wiring a consumer supplied evidence and every drift row had a closing PR.
  Its plan `GH-421-AUTO-WAVE-RECONCILE.md:99-115` and GH-421 fixtures encode both contracts.
- #425 repaired a vacuous gate but left its producer missing; its own plan lines 64-65 anticipated
  that risk. Both #421/#425 remain administratively open; their docs record PR #495, not completion.
- #546's first wording conflated hook files with Git objects; #584 inherited legacy attribution.
- #543/#545 fallback PRs created new reconciliation obligations. Receipt commits include
  `af1d5ca0`, `18ca7fc7`, `8902e2df`; they repair individual events, not the lifecycle.
- #588/#590 restored hosted runner availability, not full-suite evidence. PR CI only runs vendored
  smoke. Existing macOS suite is main-push-only (`ci.yml:150-197`). Development CI cancels superseded
  runs (`:105-109`): #588 run 34733682612 and #590 run 34733897677 were actually cancelled.

## Falsification and recommendation

The real throwaway Git proof observed a generated local receipt and a pushed tree containing only
the original source file. A pre-push hook cannot change the already selected pushed commit.
The consult synthesis (primary checkout's uncommitted relay-system/2026-09-12/reconciler-umbrella-201512/
SYNTHESIS.md, read directly) is correct about this and about smoke checks being insufficient.

Ranked alternatives: (1) qualify in existing wave job; (2) two-pass local receipt; (3) extend main-only
CI boundary to development and coordinate exact runs; (4) trust PR smoke; (5) exempt chore/docs PRs.
Reject 4/5: they weaken evidence. Reject 3: introduces cross-workflow waiting/cancellation races.
Choose 1: the existing serialized macOS job runs the full sequential suite on a pinned integration
snapshot in a separate disposable full clone, then produces durable per-landing provenance through
the reconciler. Require merge ancestry, passing status and unchanged test identity; keep --gate.
Commit the receipt with reconciliation, never before qualification. No new workflow/service/ledger.

The strongest objection is serial latency. The first candidate's full sequential local gate took
3,121 seconds (52 minutes), exceeding the 13–15 minute historical documentation; one ambient-mode
test failed, so this is runtime evidence, not passing qualification. The hosted duration remains
unmeasured. Bound validation to 90 minutes and the job to 120 minutes. The recovery PR batches all
pending merges into one qualification run; committed receipts make queued repeats cheap. A sustained
queue still blocks closeout and must be measured on the real runner before claiming operational fit.
Current repo is public; standard GitHub-hosted macOS runner minutes are free under
[GitHub billing](https://docs.github.com/en/billing/concepts/product-billing/github-actions).
Private-phase dollar estimates in ci.yml are not current marginal cost. No new artifact service;
retain JSONL in the existing repository store (ongoing Git size cost). Revisit on observed queue growth,
timeouts, visibility/pricing change or suite portability failures.

Two-pass local validation costs the existing 4-6 minute local gate plus a receipt commit/repush on
every run, permanent evidence commits, and special rules for receipt-only children, docs/tier-2,
automation and bypasses. It tests a branch tree before integration. Hosted qualification tests the
integrated tree and works regardless of how a PR was pushed. The local gate remains in force.

## Paths without receipts

Explicit answer: YES, commits can still reach development before a receipt exists. This is a
post-merge control, not branch protection. After this change:

| Landing path | Decision |
|---|---|
| Ordinary, docs-only, tier-2, offline, bypassed, unwired-clone, UI/API or fork PR | Closed by hosted full qualification; no PR class exemption |
| Lost event/rejected bot push, including no-issue PR | Must be closed by receipt-backed catch-up discovery in separate #584 PR; issue-drift-only discovery is insufficient |
| Raw direct push / express | Deliberately outside PR milestone; express already reconciles ungated. Specific follow-up must be filed and linked before umbrella closeout; currently a real gap |
| Reconciler bot commit | Contains its own generated evidence for the tested integration input and runs PDDA on derived outputs; no claim that the full suite tested the later generated ledger commit |
| Direct non-PR issue closure | Existing #492; warn without fabricating PR attribution |
| Jog/cleanup local closeout ownership | Existing #534/#538; hosted PR qualification still applies, but competing local reconciliation remains tracked |

## Unknowns

| Unknown | Why it matters | What settles it |
|---|---|---|
| Full-suite macOS hosted elapsed time and toolchain compatibility | Bounds throughput and required setup | PR 1's own full qualification run |
| Other latent closed-issue drift failures after GH-52 is skipped | May still prevent batch commit | Live catch-up with strict gate after both PRs land |
| Complete receipt-backed recovery start boundary | Must recover all supported PRs without a second ledger or arbitrary window | Trace workflow introduction history and test missing-event fixtures in #584 |
| Express follow-up issue number | Handoff forbids undocumented residual gaps | Prepare concrete issue and obtain outward-action approval at PR review boundary |
| Three consecutive automatic merges and next scheduled success | Final acceptance is external, not a unit-test claim | Run URLs after user-approved merges |

## Current-state radius, one line

Every development PR's evidence, the serialized hosted bot, active PDDA docs, RELEASES ledger/views,
and maintainer landers using local provenance; no coordination kernel or new data store.

### Concurrent express work discovered during implementation

The direct hotfix receipt gap is now owned by [#592](https://github.com/HiQS-Labs/XYZ-forge/issues/592),
with [PR #597](https://github.com/HiQS-Labs/XYZ-forge/pull/597) open. Its stated evidence is the
registered express suite, not a full-suite qualification. It also identifies bounds escape #594.
These are existing umbrella follow-ups; do not file a duplicate or claim them merged.
