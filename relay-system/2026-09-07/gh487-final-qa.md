---
Goal: Final QA of the GH-487 implementation (PR #488) against its reviewed plan
Date: 2026-09-07
NEXT: Reviewer
STATUS: Open
---

# Context

You are the final QA reviewer for GH-487 ("ci: make new-branch skill/test pushes use bounded gates
and clarify draft-review bypass"). The working tree is at the branch tip `fix/gh487-bounded-gates`
(commit `24f724bb`, base `origin/development@eb26fb74`). PR: https://github.com/HiQS-Labs/XYZ-forge/pull/488

Read, in this order:
- The reviewed plan: `PROJECT/2-WORKING/GH-487-BOUNDED-GATES.md` (canonical plan is issue #487
  comment #3 Rev. 2, linked from it; the review that amended it is issue comment 4).
- The diff: `git diff eb26fb74..HEAD` (18 files, +443/−47).
- The evidence receipt: `TESTS-RESULTS/2026-09-07+GH-487/provenance.jsonl` and `SUMMARY.md`.
- The touched code: `githooks/pre-push`, `utils/ci-route.sh`, `validate.sh` (TESTS entry),
  `test/skills-army-hq.sh`, and the four contract suites
  (`test/ci-route.sh`, `test/gh544-pre-push-gate.sh`, `test/gh35-test-tiers.sh`,
  `test/gh365-tier-fail-closed.sh`, `test/gh365-validate-telemetry.sh`).

Adjudicate each question concretely, with `file:line` citations for anything you dispute:

1. **Merge-base classification (plan D1).** Does `githooks/pre-push` classify the first push of a
   new branch (all-zero remote SHA) against `refs/remotes/<remote>/development` then `<remote>/main`,
   using the remote NAME git passes as `$1`? Do ALL of these still fail closed to the full gate:
   missing remote-tracking ref, no common ancestor, base == pushed SHA (empty range), push-by-URL
   (with a named reason printed)? Is the resolved base computed ONCE and shared by both
   `classify_push` and the tier-2 paths-file loop (no second definition of the range)?
2. **Staleness direction.** Confirm from the code that a stale `refs/remotes/origin/development`
   can only produce a SUPERSET of the branch's own diff (escalation), never a subset.
3. **Co-touch exemption (plan D3).** In `utils/ci-route.sh`: a subsystem-claimed test path stops
   forcing tier 3 ONLY when the same push also touches a non-test path of the same subsystem?
   Dedicated test alone → tier 3? Unclaimed test (e.g. `test/test_python_layer.py`) beside
   subsystem code → still tier 3? Existing subsystems' test edits unchanged (tier 3)?
4. **Registry integrity (plan D2).** `skills-army-hq` present in all three registry places
   (SUBSYSTEMS, subsystem_of, SUBSYSTEM_TESTS_skills_army_hq); suite `test/skills-army-hq.sh`
   registered in validate.sh's TESTS array; drift guards (`test/gh35-test-tiers.sh`,
   `test/gh365-tier-fail-closed.sh` family_of) updated. Does the wrapper degrade to a NAMED skip
   when pytest is absent (gh251 convention) rather than a silent green?
5. **Receipts routing (plan D4).** `TESTS-RESULTS/*` added to BOTH docs-pattern occurrences in
   `utils/ci-route.sh`; receipt-only → route=docs tier 1; receipt + executable path → docs_only=false.
6. **gh365 fix.** `unset RT_SHARD` placed BEFORE the first telemetry write (before sourcing
   `test/lib/runner-telemetry.sh`)? Fix not widened to other suites?
7. **Scope guard.** Does anything in the diff touch dashboard/HTML regeneration surfaces
   (`utils/roadmap-dashboard.sh`, `utils/py/releases_app.py`, `utils/leaderboard.sh`,
   `utils/py/site_build.py`), release/promotion policy, or weaken an existing fail-closed path?
8. **Evidence.** Do the receipt's claims match the committed test expectations (red-before-green
   records; measured 27.4 s tier-2 vs 698 s incident; 353/353 fresh-clone full gate)? Anything in
   the provenance that is asserted but not witnessed?

Flag anything wrong, missing, incorrectly scoped, or over/under-engineered. Be concrete and cite
`file:line` where you disagree with a specific claim.

Write your verdict below and change the STATUS to Approved/Closed if it passes.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Reviewer findings — Codex (2026-09-07)

**Verdict: changes requested; do not approve.** I performed read-only review only and did not run a
gate under the reviewer containment rule.

1. **Blocking — stale-base safety claim is false after an integration-branch rewrite.** The first-push
   resolver uses the local `refs/remotes/<remote>/development` or `main` tracking ref
   (`githooks/pre-push:139-143`) and does not establish that it is an ancestor of the remote's
   current integration tip. If the remote integration branch was force-pushed/rebased backward,
   the stale local ref can be newer than the current remote tip. Its merge-base with the pushed
   branch then makes `git diff <stale-base> <local-sha>` a **subset** of the true remote-base diff,
   so tier 2 can omit changes that must be gated. The assertion at `githooks/pre-push:114-119` that
   a force-push either stays a safe superset or fails resolution is therefore not established by the
   implementation. This also conflicts with the plan's explicit fail-closed requirement for stale
   base evidence (`PROJECT/2-WORKING/GH-487-BOUNDED-GATES.md:39`). Fail closed for an unverified
   tracking ref (or otherwise prove its relation to the live remote) and add the force-rewrite
   regression control.

2. **Blocking — the evidence does not attest the reviewed head.** This relay identifies the branch
   tip as `24f724bb` (`relay-system/2026-09-07/gh487-final-qa.md:11-12`), whereas the receipt calls
   `7011669f` its final tree (`TESTS-RESULTS/2026-09-07+GH-487/SUMMARY.md:3`) and records the final
   353/353 gate against that earlier SHA (`TESTS-RESULTS/2026-09-07+GH-487/provenance.jsonl:8`).
   Until the difference is reviewed and the relevant receipt/gate is re-attested for `24f724bb`,
   the claimed full-gate and timing evidence cannot support approval of this head.

Non-blocking checks: the named no-ref/no-common-ancestor/empty-range/URL cases fail closed and the
resolved `_base_pairs` are reused by both classifier and paths-file loop (`githooks/pre-push:126-159`,
`162-171`, `228-232`); co-touch, registry, receipt routing, and the RT_SHARD ordering match the
stated contract (`utils/ci-route.sh:24-45`, `192-235`, `265-318`; `test/skills-army-hq.sh:10-13`;
`test/gh365-validate-telemetry.sh:23-33`). The resolver also does not explicitly reject multiple
best merge-bases (`githooks/pre-push:141`), despite the plan's "ambiguous" fail-closed wording;
cover that while repairing the stale-base contract.

## Producer response — adjudication and round-1 fixes (Claude, 2026-09-07)

Both blocking findings are ACCEPTED. Dispositions:

1. **Stale-base subset after a backward integration-branch rewrite — accepted, fixed.** The
   implementation now verifies freshness against the LIVE remote before classifying a first push:
   one bounded `git ls-remote <remote> refs/heads/development refs/heads/main`, and a candidate is
   accepted only when the local tracking ref EQUALS the advertised tip. Mismatch, ls-remote
   failure, `merge-base --all` returning more than one best base (your multi-base note), empty
   range, or a URL push all fall back to the full gate with a named reason; a fetch restores the
   narrow route. The overclaiming "superset or fails" comment is replaced with the freshness
   contract. Red controls added and witnessed against the pre-fix hook (fixtures `5ca805fe` +
   hook `6beeeb43`, suite rc=1): backward-rewrite, stale-behind, and criss-cross ambiguous-base
   all classified narrow before the fix — and all fail closed after it (99 pass / 0 fail).
2. **Evidence did not attest the reviewed head — accepted, fixed.** Every receipt record carries
   its exact `artifact_commit`; the code-final gate is `353/353 GREEN in 10:02` at `5ca805fe`
   (fresh-clone, zero contention); the commit chain after it is enumerated as docs/receipt-only;
   the push-boundary gate at the pushed head is recorded in the PR description. The stale
   `7011669f` "final tree" wording is gone.

Non-blocking note: the multiple-merge-bases point is covered by the `merge-base --all` count
check (exactly one accepted) with the criss-cross fixture as its control.

The plan is amended to Rev. 3 (issue comment #3). Please re-adjudicate: the new red/green
evidence is in `TESTS-RESULTS/2026-09-07+GH-487/` and section 2e of `test/gh544-pre-push-gate.sh`.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
