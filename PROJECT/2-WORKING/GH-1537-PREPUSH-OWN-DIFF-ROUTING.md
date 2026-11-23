---
gh_issue: 1537
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1537
title: "pre-push: a branch that only merged development in is routed by its own diff, not sent to the full gate"
status: In Progress
created: 2026-11-23
updated: 2026-11-23
owner: Claude (start-task sub-agent)
goal: "A refresh push whose only new content is development merged into a branch is classified by the branch's own final-tree diff against the verified integration tip, and takes the documentation route when that diff is docs-only; everything else keeps today's fail-closed routing."
branch: feat/XYZ-forge-gh1537-prepush-own-diff-2026-11-23
doc_type: feature
complexity: 3
risk: 3
effort: 2
phases: 1
non_goals:
  - A new suite, registry entry, classifier or second routing path (AGENTS.md, No new tests; GH-831).
  - Any change to the final landing gate. Merge-cleanup qualification and the kickstart final QA still run the full gate on the landed tip.
  - Reusing a prior full-gate receipt for a code PR's merge-only refresh. A branch whose own diff has code still routes full (that is the issue's own control).
  - Routing by own diff to tier 2 or full. Own-diff classification is accepted only when it yields route=docs.
  - The first push of a new branch (GH-487 already classifies it against the integration branch) and pushes to development or main.
---

## Status

| What was just completed | What's next |
|---|---|
| Intake registered; recon of `githooks/pre-push`, `utils/ci-route.sh` and callers done; plan drafted. | Codex plan QA, then build, red/green manual check, final QA, PR. |

## Problem

`githooks/pre-push` classifies an existing branch's push as `git diff --no-renames --name-only <remote_sha> <local_sha>`
(`githooks/pre-push:209-211`, `:227`). When `development` is merged into the branch, every path
`development` changed since the branch point enters that range, so a docs-only branch is sent to the
full gate (about 14-18 min). Observed: docs PR #1526 paid it twice on 2026-11-19; the PR #1467 and PR #1574 refresh pushes
paid it on 2026-11-22; every serial landing in the kickstart run paid one per re-merge (#1541, KS-12).
(#1537's original text said the hook tests non-linear history at `:91`; that line is a comment. The correction
comment on #1537 names the real mechanism, the update-range diff above.)

Operator decision (2026-11-19, re-ordered 2026-11-22): a PR that only merges `development` in is judged on its own diff;
the final landing still gets a full gate.

## Recon (base `5964566ef`, 2026-11-23)

- Entry: `githooks/pre-push` (installed as a stub by `githooks/install.sh`; GH-1576 / PR #1581 added the `--check`
  guard to the push *callers* and did not touch this file). `resolve_base_pairs` (`:124`) builds one
  `local_sha|base` pair per pushed ref: for an existing remote ref the base is `remote_sha` after
  `cat-file` and `merge-base --is-ancestor` (`:209-211`); for a new branch it is the single best common
  ancestor with the *freshly verified* integration tip (`git ls-remote` equality, `:135-205`, GH-487).
  `classify_push` (`:219`) feeds `git diff --no-renames --name-only base local` to
  `utils/ci-route.sh push`; `route=docs` runs `pdda.sh run`; tier 2 and the full gate read the same pairs.
- Other consumers of the classifier: `validate.sh:845-848` (`--paths-file`/`--auto`), `.github/workflows/ci.yml:300`
  (PR paths, hosted). Neither sees the hook's range; no other caller of the hook's pair arrays exists
  (`git grep _real_ref_pairs` finds only the hook).
- Pinning suites (existing): `test/gh544-pre-push-gate.sh` (drives the real hook against a stub `validate.sh`,
  including the GH-487 first-push rules), `test/gh591-prepush-commit-boundary.sh`, `test/gh35-test-tiers.sh`,
  `test/gh4-ungated-clone-warning.sh`.
- Prior-art scan: no merged PR or open PR changes this routing; 23 merged-PR matches were word overlap
  (`prior_art_recon.py`, 2026-11-23). #1537 is the only tracked ask.
- Untraced: the hosted `ci.yml` PR-level classification, which already uses the PR's own diff and needs no change.

## Plan (the smallest change that carries the rule)

Extend `githooks/pre-push` only; reuse its integration-tip freshness proof and the existing classifier.

1. **Carry the destination ref.** `_real_ref_pairs` entries become `lsha|rsha|rref` (the loop at `:68` already reads `_rref`).
   Two parsers change (`:131`, `:180`). Receipt reuse (`:305-306`, `${_pair%%|*}`) and the length checks (`:127`, `:302`) were
   inspected and need no change. `_base_pairs` stays a two-field `local|base` contract (`:224-227`, `:286-288`).
2. **Extract the live-tip probe.** Move the `ls-remote` block (`:136-177`) into `probe_integration_tips`, so the new path and
   the first-push path share one freshness proof (no second copy). It sets globals (`_adv_dev`, `_adv_main`, a state flag that
   caches success AND failure, and `_base_note`), so it and `own_diff_base` are called directly in the parent shell, never
   inside `$(...)` (a command substitution would lose the cache, Codex plan QA r1).
3. **Add `own_diff_base <local> <remote> <rref>`**, which sets the global `_own_base` and returns 0 only when ALL hold; any doubt
   returns 1 and the pair keeps today's update-range base:
   - destination is `refs/heads/*` and not `development`/`main`;
   - the first local integration tracking ref (`refs/remotes/<remote>/development`, then `main`) has a single best common
     ancestor `mbs` with `local_sha`, `mbs != local_sha`, and `mbs` is NOT already an ancestor of `remote_sha`
     (integration history entered with this push; otherwise there is nothing to narrow and no network round trip is spent);
   - the tracking ref equals the tip the remote advertises right now (shared probe; stale means full);
   - **at least one** merge commit the branch made itself exists (`git rev-list --merges --parents remote..local ^tip` is
     non-empty), and every such merge has ALL its non-first parents as ancestors of that tip. First parents are not constrained:
     the final-tree diff covers them. A fast-forward or linear import of integration history has no such merge and is not
     narrowed ("linear push unchanged"). Commit ancestry cannot say which branch name a merge used: a merge of a side commit
     that is already on the integration tip counts as an integration merge (its content is already on development, and the
     final-tree diff still sees any difference). A merge of a commit NOT on the tip is refused.
4. **Route.** `resolve_base_pairs` also records, per pair, `local|ownbase` (or the update base when not narrowed) and counts the
   narrowed pairs. The top level classifies the own pairs when any pair narrowed:
   - own route is exactly `docs` -> the docs route, and one line names the merge-base;
   - own route is anything else -> **the full gate** (an explicit veto: not tier 2, and NOT the update-range result), because the
     final tree carries code (own commits, a hand-resolved conflict, or an "ours"/evil merge that discards development's code and
     leaves the update range looking docs-only). This is the issue's control (b): a code branch with development merged in routes
     `full`.
   - **Classifier status is a prerequisite for every route** (Codex r1 F3, pre-existing at `:263`): `_cls="$(classify_push 2>/dev/null)"
     || _cls=""`, so a failed diff in a later ref pair cannot leave partial stdout that reads as `route=docs`.
5. **Docs.** Update the hook's header comment. No `CHANGELOG.md` write: `CHANGELOG_WRITES` is off by default
   (`PROJECT/PDDA.md` CHANGELOG section; `.pdda-mode` has no override), so the rationale lives in this plan and the PR.

Soundness argument: the classified range is the final-tree diff `mbs..local_sha`, so a hand-resolved conflict, an evil merge, or any
code the branch carries appears as a path whether or not history looks like a clean merge. The merge-parent rule keeps the operator's
stated scope (an integration merge); it does not prove branch provenance and no provenance subsystem is added.

## Preflight bet check

- *Outcome sought:* a docs-only PR refresh no longer pays a 14-18 minute full gate because development moved.
- *Smallest viable bet:* one function and a two-line routing change inside the existing hook. Not built: receipt reuse for code PRs,
  tier-2 narrowing, any change to landing gates, any new suite.
- *Alternatives rejected:* (a) classify `merge-base..local` for every existing-branch push (also narrows non-merge pushes and
  non-docs routes, a wider bet than approved); (b) treat any merge as safe (misses evil merges and other-branch merges).
- *Rollback:* revert the hook edit; the change is local to one file and every failure path already equals today's route.

## Verification (manual, `TESTS-RESULTS/2026-11-23+GH-1537/`, no new suite)

Fixture repo with a bare origin, the real hook and classifier, a stub `validate.sh`/`pdda.sh` (as `test/gh544-pre-push-gate.sh`
does), real `git push` through the installed stub; `provenance.jsonl` records base and candidate SHAs and exit codes.
- Red (base `5964566ef`): docs branch pushed, development advances with code, development merged in, refresh push routes `full`.
- Green (candidate): the same push routes `docs`, naming the merge-base.
- Controls (candidate; each asserts the route AND that the stub gate or docs gate really ran, with non-empty captures and base/candidate
  hook identity in `provenance.jsonl`): code on the branch plus a merge of development code routes `full`; a merge with a hand-resolved
  code edit (evil merge) routes `full`; an "ours" merge that keeps the old source while development changed it and edits a README routes
  `full` (the update range alone would read docs: Codex r1 F1); a merge of another branch's commit not on the tip routes `full`; a merge
  of a side commit already on the tip narrows (stated policy); a fast-forward/linear import `R -> D -> L` keeps today's route (F2);
  stale tracking ref routes `full`; first push unchanged; a push to `main` routes `full`; a two-ref push with one code ref routes
  `full`; a two-ref push whose second diff fails routes `full` (F3, red on base); a docs-only conflict resolution routes `docs`.
- Existing suites: `gh544`, `gh591`, `gh35`, `gh4`, plus the full gate on the final commit.

## Risks

- A bug in the narrowing under-gates a code push. Mitigations: docs-only acceptance, final-tree diff, fail-closed on every doubt, red controls above.
- Operator-visible limits: a code PR's refresh still routes full by design (the saving is for docs PRs). In the narrow case where
  a code branch merges development whose new content is docs-only, the update range alone would have routed docs and the veto now
  routes full; this follows the issue's own control (b) and costs one gate that the branch's code arguably always owed.

## Task rating (2026-11-23)

Rated 62/40/50/70 (pri/sev/appeal/effort). Severity 40: no data loss, ~14-18 min of wasted gate per refresh. Recurrence: at least four
distinct PR refresh pushes in 5 days (#1526 twice, #1467, #1574; window 2026-11-19..23, prior window unknown). Appeal neutral 50. Effort 70:
one-file hook change on an existing proof.

## Lessons Learned

(to be filled at handoff)
