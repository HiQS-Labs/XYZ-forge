# GH1358 checkpoint connection — implementation evidence

Candidate: opt-in `releases jog run --max-tasks 1 --checkpoint-root <publication-clone>`.
Existing supervisor lock covers ledger commit and exact-SHA normal push. A retained journal
recovers publication before new queue dispatch. Default invocation is unchanged.

- Existing gh280 adapter: 227 pass, 0 fail in separate disposable full clone.
- Manual publication controls: two successive ledger mutations, rejected push recovery with
  unchanged commit, unrelated-file refusal, extra publication-clone commit refusal: PASS.
- These controls use a local bare remote and supported ledger CLI, not raw SQL. They are
  component integration evidence, not deployed-autonomy or build-throughput evidence.
- Independent plan QA approved after two concrete implementation corrections; see
  `relay-system/2026-11-08/gh1358-checkpoint-plan.codex.md`.
- Scheduled launchd and final QA/gate evidence pending; no whole-issue qualification.

Retain all disposable control/deployment clones; they contain local-only evidence. No reset,
force push, production primary mutation, exhausted-counter reset or merge occurred.
