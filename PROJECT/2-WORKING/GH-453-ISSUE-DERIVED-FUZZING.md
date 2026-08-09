---
gh_issue: 453
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/453
title: Design an issue-derived fuzzing evidence pipeline
status: Proposed (2-WORKING)
created: 2026-08-08
updated: 2026-08-08
owner: Codex
goal: Turn recent, human-filed bug reports with known fixes into reproducible candidate regressions without letting untrusted issue text or generated tests modify shared Git state.
doc_type: experiment
effort: 4
complexity: 4
risk: 3
phases: 4
related: GH-191, GH-281, GH-419, PR-450
non_goals: Autonomous repair, automatic PR creation, mining issue comments or attachments, and replacement of ATE variation testing.
---

## Status

| What was just completed | What's next |
|---|---|
| Second-pass design review replaced linked-worktree containment and ambiguous open-issue baselines with credential-free throwaway clones and closed issue/fix-pair oracles | Phase 0: measure whether a bounded 30-day corpus has enough eligible, reproducible issue/fix pairs to justify building a generator |

## Quad Concepts

- Human-filed incidents are valuable seeds, but issue prose is untrusted → normalize title/body and authoritative fix links into inert, versioned records before model use.
- A baseline failure alone can reward broken setup → require the predicted failure before the known fix and a pass after it, with the generator blinded to the fixing diff.
- A linked worktree shares Git state with the source repo → execute generated artifacts only in credential-free throwaway clones with network disabled.
- Generated-test volume is a vanity metric → gate investment on reproduction precision, false-positive rate, novel defect-class yield, and cost per accepted candidate.

## Table of contents

- [Decision and bet](#decision-and-bet)
- [Ground truth and cohort](#ground-truth-and-cohort)
- [Architecture and trust boundaries](#architecture-and-trust-boundaries)
- [Evidence contract and lifecycle](#evidence-contract-and-lifecycle)
- [Phase 0 — corpus feasibility](#phase-0--corpus-feasibility)
- [Phase 1 — blinded candidate generator](#phase-1--blinded-candidate-generator)
- [Phase 2 — isolated repair experiment](#phase-2--isolated-repair-experiment)
- [Phase 3 — operator promotion](#phase-3--operator-promotion)
- [Threat model and stop rules](#threat-model-and-stop-rules)
- [Relationship to ATE and Sentinel](#relationship-to-ate-and-sentinel)
- [Lessons from PR #450](#lessons-from-pr-450)

## Decision and bet

**Viable only if recent closed bugs can supply a trustworthy historical oracle.** The first cohort is
not every issue touched in the last 30 days. It is closed bug reports with an authoritative linked
fixing PR or commit, enough reproduction detail, and a buildable pre-fix revision. That lets an
evaluator ask the useful question: can a generator, given only the report and pre-fix tree, produce a
test that fails for the predicted reason before the fix and passes after the known fix?

The bet is that historical issue/fix pairs contain enough behavioral detail to recover reusable
regressions at lower cost than hand-authored triage. The main failure mode is false confidence: setup
errors, leaked fix knowledge, or tests that encode an implementation detail can look like successful
reproduction. Phase 0 is therefore a go/no-go study, not a commitment to autonomous repair.

Reversibility is **Easy** through Phase 2 because collection is read-only and every generated or
builder-controlled execution happens in an uncredentialed throwaway clone with no remote. Discarding
the clone and run packet removes the experiment without touching shared refs. Promotion is **Costly**
because a misleading regression or repair can enter the normal development queue; it remains an
explicit human-owned issue/PR workflow with ordinary review and rollback.

## Ground truth and cohort

The collector snapshots issues closed in the half-open UTC interval `[run_time - 30 days, run_time)`.
The initial cohort uses title, body, labels, timestamps, and authoritative GitHub links between the
issue and its fixing PR/commit. Comments, reactions, and attachments are excluded in Phase 0 because
they add prompt-injection surface and weak provenance. Collection may use GitHub's API/timeline data;
CI consumes only the redacted snapshot and never calls GitHub.

Each eligible record pins:

- `pre_fix_sha`: the last affected revision selected from the fixing PR/commit ancestry;
- `known_fix_sha`: the revision containing the accepted fix;
- `fix_provenance`: the linked PR/commit and how the two revisions were derived;
- `issue_body_hash`: the immutable identity of the report text shown to the generator;
- `expected_behavior`: a normalized, reviewable claim derived from the report.

The generator sees the issue snapshot and the `pre_fix_sha` source tree, but **not** the fixing diff,
PR discussion, post-fix tests, or `known_fix_sha` tree. A separate evaluator owns that hidden evidence.
This avoids rewarding a generator for copying the answer. Open bugs can become a later discovery
cohort after the historical qualification gate passes; they cannot establish Phase 0 precision
because they lack a known-fix oracle.

Start with 30 days and expand in declared 30-day increments, to a maximum of 90 days, if necessary to
find 20 eligible pairs. If 90 days is insufficient, record a no-go rather than silently weakening the
eligibility rules. Derive revision pairs with an explicit strategy for the PR's merge mode, prove the
expected ancestry/tree relationship, and reject multi-fix or otherwise ambiguous histories. Deduplicate
by repository, issue number, issue-body hash, and fix SHA.

Freeze the cohort and a defect-class-stratified calibration/holdout split before any generator run.
Keep at least ten eligible pairs in each half. Generator outputs on the holdout are sealed before a
human, also blinded to the fixes, authors comparison candidates for those same issues. The evaluator
alone unblinds the known-fix trees. This makes yield, precision, and authoring cost paired rather than
an accidental comparison between easy and hard issues.

## Architecture and trust boundaries

1. **Collector — networked, read-only.** Fetch authoritative issue/fix metadata, redact it, and write
   a content-addressed JSONL snapshot. It has no execution role and never passes credentials onward.
2. **Normalizer — deterministic, offline.** Admit only records with a concrete symptom, affected
   surface, expected behavior, and derivable revision pair. Issue prose remains quoted data, not an
   instruction stream.
3. **Generator — blinded.** A broker sends the normalized report and an exported `pre_fix_sha` source
   tree to the selected model, then writes only the structured result into the worker boundary. The
   generator cannot inspect Git history, remotes, the fixing diff, or the post-fix tree; no provider
   credential enters the clone.
4. **Reproducer/evaluator — separate, offline.** Materialize fresh credential-free clones or source
   copies for `pre_fix_sha` and `known_fix_sha`, run fixed argv templates with wall/resource caps,
   and compare the observed evidence to the prediction. A linked worktree is not sufficient because
   linked worktrees share the object store and most refs with the source repository.
5. **Repair experiment — explicit opt-in, offline.** Give a builder only an accepted candidate,
   normalized contract, and narrow write allowlist in another throwaway clone. Remove its remote,
   withhold `gh` and provider credentials, disable network, and retain only declared artifacts.
6. **Promotion queue — human-owned.** Present the evidence packet for ordinary issue-first review.
   Scheduled mode is report-only; it never pushes, opens a PR, or merges.

## Evidence contract and lifecycle

Every run appends versioned JSONL events and stores content-addressed inputs and logs. A stable
candidate ID is derived from repository, issue number, issue-body hash, and `pre_fix_sha`. Records
include collector/generator versions, both pinned SHAs, fixed argv, timeout, exit code, stdout/stderr
hashes, changed paths, predicted signature, observed signature, and evaluator verdict.

The monotonic success path is:

`collected → normalized → pre_fix_verified → known_fix_verified → repair_eligible`

Terminal results are first-class evidence rather than retried until green:

- `insufficient_contract` — the issue lacks a testable behavioral claim;
- `setup_failure` — dependencies, build, fixture, or invocation failed before the claim was tested;
- `not_reproducible` — the pre-fix revision does not exhibit the predicted failure;
- `unrelated_failure` — it fails, but not for the predicted reason;
- `not_fixed` — it does not pass on the known-fix revision;
- `duplicate` — it adds no distinct failure signature or defect class to the corpus.

Acceptance requires both controls: fail on `pre_fix_sha` for the predicted reason and pass unchanged
on `known_fix_sha`. A timeout, usage error, missing executable, invalid path, unrelated exception, or
test that passes on both revisions is rejected.

## Phase 0 — corpus feasibility

Build the read-only collector, deterministic normalizer, revision-pair resolver, and a checked-in
redacted fixture corpus. Humans author candidates for the calibration half so this phase measures
corpus and oracle quality without confounding it with model quality. Freeze the split before Phase 1;
the human holdout comparator is authored only after generator output is sealed.

**Go/no-go gate:** find at least 20 eligible issue/fix pairs within the declared maximum window, freeze
at least ten calibration and ten holdout pairs, and demonstrate the dual-revision oracle on calibration
candidates. Among candidates admitted for execution, setup/unrelated failures must be at most 10%,
and at least 70% must reproduce the predicted pre-fix/post-fix transition. Below either threshold,
stop and improve collection/normalization rather than building a generator.

Report eligibility yield, attempted-issue coverage, abstention rate, reproduction precision, verified
candidates per eligible issue, rejection reasons, duplicate rate, distinct defect classes, elapsed/cash
cost per verified candidate, and any window expansion. Do not use raw generated test count as a success
metric.

## Phase 1 — blinded candidate generator

Generate hermetic candidate tests against the frozen historical holdout. The generator gets no fixing
diff or post-fix evidence. Seal its results, obtain a likewise-blinded human comparison on the same
issues, and compare precision, verified yield per eligible issue, abstention, defect-class coverage,
and cost. Keep fix evidence blinded until both outputs are frozen.

**QA gate:** every accepted candidate satisfies the dual-revision oracle, has a declared write set,
and adds a distinct signature or is explicitly marked duplicate. Seed malformed cases proving that
setup errors, unrelated exceptions, prompt-like issue prose, invalid filenames, timeouts, and fix
leakage are rejected. Continue only if the generator preserves the Phase 0 precision threshold without
collapsing attempted-issue coverage and reduces cost or increases novel defect-class yield against the
paired human comparator.

## Phase 2 — isolated repair experiment

Run one operator-selected accepted candidate in a fresh throwaway clone, with one builder attempt,
bounded wall/resources, fixed argv, a narrow artifact list, no credentials/network/remote, and no
live push. The evaluator runs outside the builder environment and repeats the candidate plus the
normal targeted gate. Use a blinded historical holdout first: the builder must repair the pre-fix
tree without seeing the historical fix, then compare behavior and patch shape after evaluation.

**QA gate:** prove the worker cannot write shared refs or `development`, widen the declared write set,
force-retry, or access the collector's credentials. Preserve evidence for success, failure, and
timeout. A generated commit alone is never success; the independent candidate and normal gate must
pass, and the patch must not merely encode the fixture.

## Phase 3 — operator promotion

An operator may convert a verified packet into the ordinary issue-first PR workflow. The PR body must
link the human source issue, both revision controls, repair evidence, normal regression gates, and
residual uncertainty. Initial scheduled runs remain report-only. A future explicit `--create-pr`
mode requires separate approval after sustained precision on held-out cohorts; it is not part of this
plan.

**QA gate:** no scheduled or worker code path calls `gh pr create`, pushes, merges, or mutates a source
repo. The promotion record identifies the operator and exact immutable evidence packet used.

## Threat model and stop rules

- Treat issue title/body, generated names/content, model output, and repository fixtures as untrusted.
  Never execute issue code blocks or interpolate issue-derived text into a shell string, path, branch,
  command, or environment variable; use fixed argv templates and sanitized generated identifiers.
- Separate the credentialed collector and model broker from all execution workers. Workers have no
  network, remote, GitHub/model-provider token, or access to the main repo's `.git` directory.
- Before execution, prove the target is the expected ephemeral clone/source copy and the pinned SHA
  matches. Stop on dirty/non-ephemeral targets, ancestry ambiguity, missing evidence, repeated
  signatures, resource caps, or an attempted write-set expansion.
- Snapshot rather than mutate source records. Append a new event when an issue body or authoritative
  fix link changes, preserving the prior body hash and decision.
- Never use `--force` to make a failed candidate continue. Classification is the product of a failed
  experiment; retries require a new versioned candidate or an operator-authored reason.

## Relationship to ATE and Sentinel

Do not build a second generic execution engine. GH-191's ATE generalization is a decision dependency:
if its safe argv-template runner, append-only log, variation grid, supervisor, and scratch-repository
guards can be generalized cleanly, reuse them for candidate execution. Keep the issue collector,
dual-revision oracle, and blinded evaluator as separate issue-derived layers; ATE remains the
variation/adversarial runner rather than the source of ground truth. Sentinel may consume verified
packets through its existing proposal/logging boundary, but it does not bypass human promotion.

## Lessons from PR #450

[PR #450](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/pull/450)
was useful as a negative experiment, not as a merge candidate. It exposed four missing controls:

- fixed scripts were presented as synthesis, so there was no measurable generator;
- there was no blinded pre-fix/post-fix oracle, so passing tests did not prove bug reproduction;
- an invalid generated filename produced a setup failure that could be mistaken for fuzzing evidence;
- broad Python write authority, `--force`, and a `prs_created` counter existed without a safe or real
  PR boundary.

Those failures are reusable lessons because they define falsifiable acceptance criteria here. The
valuable artifact from PR #450 is the review evidence and negative fixtures, not its loop or patches.
