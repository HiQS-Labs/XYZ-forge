---
gh_issue: 646
source: https://github.com/HiQS-Labs/XYZ-forge/issues/646
title: Shared in-progress task label
status: In progress — writer refresh and independent final review
created: 2026-09-16
updated: 2026-09-17
owner: Codex
goal: Make explicit task starts and confirmed issue endings visible through the same in-progress label in the existing XYZ ledger and GitHub connector.
branch: feat/gh646-writer-refresh
doc_type: implementation
effort: 3
complexity: 3
risk: 3
phases: 4
---

# GH-646 — Shared in-progress task label

## Status

| What was just completed | What's next |
|---|---|
| The replacement reviewer approved the focused writer source after it fixed a wave closeout path that could terminalize a still-open or unknown-state issue. 41 focused tests pass and three restored-bypass mutants fail as intended. The first full gate was safely aborted. | Land/verify GH-678 / PR #680 installer safety, or use the already validated per-target installer isolation that redirects every managed skill target to owned scratch without changing `HOME`; then run one new disposable-clone full gate before a PR is opened. |
| 2026-09-20: rebased onto development `41be79e2` (ledger row replayed through the writer; `releases migrate` → schema 009). Four reconciler suites red on the rebased head were root-caused to `_may_terminalize_issue` gating MERGED closers; repaired in `c544629f` (merged closers keep GH-202 authority; declined PRs still need a confirmed CLOSED issue) plus three fixture edits that model the writer's identity reads. Fresh agy QA `relay-system/2026-09-20/gh646-rebase-repair-qa.md`: PASS/Approved; two Nits applied in `d59c0d86`. Evidence `TESTS-RESULTS/2026-09-20+GH-646/`. | Full `validate.sh` once in a disposable clone on the final head → push (`XYZ_SKIP_PREPUSH=1`, disclosed) → draft PR after reader PR #719; rebase once more after #719 lands (the six shared `cmd_work_status` lines become a no-op); merge is the operator's call. |

## Goal and scope

An explicit accepted start sets the literal `in-progress` value on the existing `roadmap_items` row and, only when explicitly configured, projects the same GitHub issue label. A confirmed completed or cancelled issue clears it through the existing reconciliation path. The ledger is authoritative; readers only display evidence.

The implementation extends the current roadmap writer, migration/dump path, existing connector registry, Express admission, and wave reconciliation. It does not add a service, a second database, a scheduler, a generic label system, natural-language start inference, or a bidirectional GitHub sync.

## Reversibility and blast radius

This is **Costly** because schema 009 changes the ledger dump and writer contract. Existing schema-008 data remains readable with `status_label` unavailable; rollback is disabling the opt-in connector and retaining a pre-migration backup, never restoring an old database over newer work. The affected surfaces are roadmap writes, dump/rebuild, Express admissions, reconciliation, connector payloads, and readers of work evidence. No production migration, connector enablement, label write, or live closure pilot is authorized by this work.

Reader safety is settled separately: normal SQLite coordination sidecars are allowed for passive readers, while task records, database structure, and GitHub labels remain immutable to readers. This writer plan neither relies on nor changes that reader behavior.

## Ordered delivery plan

1. Reconcile the retained writer commits against current `origin/development`, preserving only the writer, migration, qualified identity, Express, reconciliation, connector, and focused regression changes. -> Expect no Flight Deck, Daily, generated view, or unrelated harness changes in the diff.
2. Verify the nonempty focused fixtures for explicit starts, duplicate starts, schema migration/dump compatibility, same-number foreign identities, native issue-versus-PR checks, outage/replay, closure/reopen, Express dry runs, and exact-row reconciliation. -> Expect each protection to be covered by an existing red control and the refreshed source revision recorded.
3. Run a new bounded independent final relay review of the refreshed source and the complete acceptance map. -> Expect an explicit Approved verdict, or a named blocker; do not reuse or extend the historical capped review.
4. After approval, run the applicable final qualifying gate exactly once in a separate disposable full clone, inspect the final diff, and publish a PR against `development` only if the gate and review are green. -> Expect a verified PR head, accurate limitations, and no merge, deployment, live migration, connector enablement, or pilot claim.

## Acceptance checks

- An accepted explicit start persists one owned `in-progress` label; metadata, capture, rating, imports, and CLIO mentions do not start work.
- Exact repository identity prevents same-number, foreign, malformed, or pull-request records from borrowing authority.
- GitHub projection is opt-in, writes only this label, preserves other labels, and leaves durable local state and replay evidence intact when remote work fails.
- Confirmed terminal state clears only this label; merged PR plus open issue, quiet activity, and a reopened issue without a fresh start do not imply completion or active work.
- Old schemas remain readable, new dumps preserve the field, and existing consumers keep their marker/event compatibility.
- Final review and qualification describe any unresolved environment or baseline failure precisely rather than treating it as a pass.

## Current evidence and stop rules

The refreshed branch contains a selective replay of the original writer implementation and late identity fixes. The reviewer found that ordinary legacy active appearance could establish the new label without qualified admission; the repair limits establishment to `accepted_start=True`. The reopened review also found that direct terminal cleanup did not prove the returned native issue identity; the repair reuses the native issue guard before a closure reason can queue the exact-row terminal mutation. The replacement focused reviewer then found that wave reconciliation could terminalize a declined PR's linked issue when its state was open, absent, or invalid; the repair requires a confirmed CLOSED state unless the existing explicit `--force-promote` override is used. The focused suite now passes 41 Python tests; deliberate appearance, closure-identity, and wave-terminal mutants all fail. The Python driver attested the replacement review. The one attempted full gate failed its missing-shellcheck prerequisite at launch and was then safely aborted before an unsafe baseline installer could touch managed Gemini links; it is not qualification. See `TESTS-RESULTS/2026-09-17+GH-646/writer-qualification-aborted.md`.

Stop and report rather than expand scope if qualified identity cannot reach the existing connector, a migration/dump contract is ambiguous, the bounded reviewer finds a correctness gap, or the final gate fails after one scoped repair/retest. Do not resolve hosted reconciliation debt, merge-cleanup race conditions, Flight Deck rendering, or Daily integration in this producer lane.

## Review authorization record

On 2026-09-17, the operator authorized one replacement final-review lane after the first real headless reviewer failed before producing a verdict. The replacement is deliberately limited to every changed writer/runtime function and relevant direct callers in the 23-file GH-646 candidate, plus its schema/dump, focused-test, and receipt boundaries. This is a review-scope waiver only: it does not permit a live migration, connector enablement, label write, deployment, merge, or a skipped final qualification gate.

## QA dispositions — 2026-09-20 (agy, Approved)

- [Nit] no-active-doc log said "the PR was not merged" for a merged PR whose issue is OPEN — **Applied** (`d59c0d86`): the message now branches on `is_merged`.
- [Nit] `--mutant wave_terminal` lambda took two arguments against the four-argument predicate, so the mutation runner raised `TypeError` instead of asserting — **Applied** (`d59c0d86`): `lambda *args, **kwargs: True`; witnessed `FAILED (failures=3)`.
- [Nit] pin both predicate branches in the writer's unit suite — **Applied**: `test_may_terminalize_issue_pins_both_branches` (table-driven, seven tuples).
- Consult (agy) proposed `(is_merged and issue_state is None)`; **Rejected** in favour of `(is_merged and not is_open)` because `is_open` also covers an unknown-state multiphase umbrella, which the approved writer must keep preserving.

## Lessons Learned (For Future Agents)

- A predicate that "requires confirmed state" must be checked against every landed contract that feeds it: `fetch_issue_state` documents None ⇒ promote for offline manifests, and three suites plus gh202 pin it. Run the neighbouring reconciler suites, not only the writer's own, before calling a tightening safe.
- When a branch makes the writer qualify rows against `repos`, every hand-built fixture ledger must carry that MIGRATION_001 table; grep `CREATE TABLE.*roadmap_items` in `test/` for fixtures without `repos` (five existed; only gh496 reached the new path).
- A stubbed `gh` must answer every verb the code path calls: adding a REST `gh api repos/…/issues/N` identity read silently breaks stubs that only answer `gh issue view`. Keep the stub's shape next to the reader's validation (`number`, `html_url`, lower-case `state`, `labels`, no `pull_request`).
- Mutation runners are code too: a signature change to the mutated function must update the mutant lambda, or the red control degrades to a crash that looks like a failure. Run `--mutant` after every signature change.
- Ledger across a rebase: drop the ledger hunks, replay through `releases_app` (`roadmap add`/`rate`/`update`, `releases migrate`), never text-merge `releases.sql`/`releases.db`.
