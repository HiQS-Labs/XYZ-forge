---
gh_issue: 673
source: https://github.com/HiQS-Labs/XYZ-forge/issues/673
title: Flight Deck established-work reader
status: Complete
created: 2026-09-17
updated: 2026-09-21
owner: Codex
goal: Distinguish established work from recent attention without changing source statuses.
doc_type: project
branch: fix/gh673-reader-completion
effort: 3
complexity: 3
risk: 2
phases: 1
---

# Flight Deck established-work reader

## Status

| What was just completed | What's next |
|---|---|
| 2026-09-20: rebased onto development `41be79e2` (content patch-identical to `09ec4faa`; ledger row replayed through the writer). Focused suites green (39/39 pytest, selectors, real Chrome, harness, gh53 17/17). Full `validate.sh` in a disposable clone 407/409 — both reds environment-only (witnessed on unmodified development). Final QA: agy PASS/Approved (`relay-system/2026-09-17/gh673-replacement-focused.md`). Evidence `TESTS-RESULTS/2026-09-20+GH-673/`. | Push, open PR against `development` (draft until the hosted smoke gate is green), then merge is the operator's call. Writer #646 lands second; its rebase after this PR is a no-op for the six shared `cmd_work_status` lines. |
| (2026-09-17) Original final QA remains escalated at cap3. Operator approved reader coordination files and a focused replacement review. Original defects plus two advisory audit gaps repaired; 39 Python tests and expanded real-browser regressions pass. | Finish safe harness preflight, then drive the prepared independent replacement review; #646 landing, final-tip qualifying gate and landed-producer comparison remain release gates. |

## Approved reader safety contract

Operator approval, 2026-09-17, applies to Flight Deck and Rebalance Daily:
normal SQLite coordination files (including WAL/SHM read-lock sidecars) are
allowed. Readers must not change task records, cached source labels, GitHub
labels or database structure, run migrations, repair sources or change journal
mode. Read-only means source data/schema preservation, not zero filesystem
activity. Do not use immutable mode on mutable databases or add a snapshot service
to suppress coordination files. A source that cannot be read safely stays unavailable.

Verify with populated isolated WAL-mode fixtures: compare database bytes and
logical data/schema before and after reading, require nonempty reader output,
and confirm attempted record/schema writes are rejected. Normal coordination
files need not be absent or byte-identical. Existing rollback-mode and unsafe
ledger refusal tests retain their narrower no-sidecar guarantees. This approval
does not grant review approval, merge, migration, connector enablement or deployment.

## Implementation and QA gate

Reuse `src/flightdeck/contract.py`, `connectors.py`, `aggregate.py`, the production
issue selector/cards/drawer, and `utils/py/releases_cycle.py`. Existing #646 recon
traced the qualified `load_work_evidence` contract. Add only schema9 read capability
to that existing helper; no writer/migration copy. Preserve six-position config
callers. Four explicit unique roots maximum; one isolated bounded helper process per
root; 2MiB streamed-output cap, 2000 issue cap, total ledger window2s inside snapshot6s.
Native reads share the remaining deadline, capped busy wait and progress interruption.
No collection, config dispatch, remote calls, source writes, new store or schedule.

Merge qualified evidence additively; preserve native state/title/fetch timestamp.
Native host/type/number and independent repo identity must agree; unproven renames
stay unavailable. Retain established work before unrelated recency/detail/repo caps.
Conflicting roots never silently win by ordering. Keep partial/truncated inventory.
Keep chats/devices separate. Only explicit PR references expand through PR links.

Confirmed status requires supported literal label, genuine unsuperseded start and
fresh matching native open state/label. Default native freshness7200s is configurable;
snapshot freshness is separate. Quiet old starts remain visible with caution, not
completed. Fresh native closure wins; completed versus cancelled stays distinct,
and stale active labels show cleanup pending. NULL is not completion. Missing,
unsupported, unsafe, stale and conflicting sources stay visible. Status reads do
not renew meaningful-progress clocks or assert PR readiness.

Reuse existing focused Python and production-selector/manual checks. Nonempty
fixtures cover agreement, quiet multiday, closure/cancellation, open+mergedPR,
label-only, DB-only, backfill/no start, UTC/future/invalid age, foreign identity,
old schema, unsafe/WAL/intent/timeout/output bounds, reversed duplicate roots,
pre-cap retention and separate sessions. Source data/schema preservation and
no-config/writer sentinels enforce the approved rule above. Witness identity/freshness/closure/reference red
controls in disposable clones, not live data. Synthetic evidence destination:
`TESTS-RESULTS/2026-09-17+GH-673/`; private pilot output remains ignored.

Original independent final QA cap3 is preserved in the original reader clone; it is not reset.
Operator-authorized replacement focused QA has a fresh cap2, then the applicable full gate in a disposable full clone.
Commit/push and separate PR; no bypass, merge or deployment in this lane. A reader
fixture pass is not proof of the unmerged producer. Rebalance reader is #233 in its
own repository. Model interpretation there stays labelled, separate from deterministic
status. Rollback disables optional connector/view without touching sources.

## Ranking rationale

2026-09-17: rated70/45/50/45, no override. Explicit operator priority; incorrect
status costs attention but this reader cannot mutate lifecycle. Neutral appeal;
moderate implementation/verification effort. Existing source gaps, not fabricated
incident-frequency estimates. Real plan QA transcript:
`relay-system/2026-09-17/flightdeck-reader-plan-qa.md` in the preserved original reader clone.

## Approved completion batch — 2026-09-17

Fresh full clone and branch from origin/development `0389dc6e`; selectively replayed
the original reader candidate `f7f760a3` without copying its historical ledger snapshot.
The original clone, capped review and test receipts remain preserved. Review the
changed helper functions and direct callers, not all unrelated releases-app commands.
No schema migration, live status update, merge, deployment or Daily integration here.

Recon: `read_xyz_work` consumes the existing qualified `load_work_evidence` helper,
aggregate merges canonical issue evidence, `issueStatus` grades facts and gaps,
`issueCards` retains quiet work, and `openDetail`/`render` derive copyable handoffs.
An invalid row with helper-owned canonical repo/number is a per-issue gap, never
positive lifecycle evidence. An unresolvable row is counted on its source root;
root errors still invalidate confirmation globally. Preserve error-only issue cards.
Native fresh closure retains precedence. Duplicate canonical issue rows are possible
despite UNIQUE(repo_id, gh_number), because legacy repo aliases have distinct IDs.

1. Reproduce invalid-row poisoning and healthy drawer closure -> both regressions must fail before repairs (witnessed).
2. Apply issue-scoped gaps and root exclusion counts -> populated real-helper duplicate/NULL-URL fixtures, reversed ordering, unchanged source bytes and 37 focused Python checks pass.
3. Share handoff derivation; resolve current inferred/native cards -> unchanged healthy drawers stay open; changed context/status, disappearing targets, read failure and expiry close them (real Chrome checks pass).
4. Independently review the changed functions and callers with cap2 -> only a real Approved verdict advances; retain absolute reviewer logs outside throwaway worktrees.
5. Run qualifying final-candidate checks in a disposable full clone -> push and separate Refs #646 PR only after genuine approval and qualifying evidence. Compare the landed writer and reader on isolated fixtures before release; otherwise record the precise remaining gate.

Workhorse advisory consult was degraded: Codex answered, Agy was killed after
90 seconds of no CPU/transcript progress before its wall cap. No two-model agreement
or final approval is claimed. Codex's inferred-card and explicit health-change
warnings were implemented and tested. Raw advisor logs remain in ignored local scratch;
committed test provenance records commands, outcomes and limits.

Implementation audit (advisory, not a driven approval) found two further gaps.
Equal-time native duplicate signatures now include qualified identity, so a foreign
URL cannot silently win or lose by row order. Per-issue `error` retains the identity
gap while separate `root_error` retains a simultaneous cap/failure. Both new tests
failed before repair, then 39/39 passed; deleting each fix again fails its intended
assertion in memory. Final replacement review remains prepared, not approved.
GH-678/PR680 tracks baseline installer tests escaping into real Gemini directories.
Safe preflight redirects all five existing installer target variables to owned
scratch, HOME unchanged; the isolated installer suite passes 212/212 and real
Gemini links are unchanged. No partial/aborted broad run qualifies a push or release.

## Lessons Learned (For Future Agents)

- A rebase that drops ledger hunks and replays the row through `releases_app` (`roadmap add` / `rate` / `update`) is the only safe way to carry `releases.db` across a moved base; text-merging the dump or the DB is never acceptable. Verify the content paths with `git patch-id --stable` before and after.
- `test/flightdeck/browser-status-checks.mjs` needs Node ≥ 20.11 (`import.meta.dirname`); on this machine the default `node` is 18, `/opt/homebrew/opt/node@26/bin/node` works. A full gate that silently used Node 18 would report this as a reader defect.
- `gh53-releases-merge-resolve` red on 2026-09-17 was the fixture flake fixed by #688, not a reader regression — check the base witness before attributing a red suite to the branch.
- The reader gates on `schema_version >= 9` and reports `status_label_supported: false` otherwise, so it lands independently of the writer (#646); the writer's rebase after this PR is a no-op for the six shared `cmd_work_status` lines.

## Merge evidence

- PR #719 merged 2026-09-21 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
