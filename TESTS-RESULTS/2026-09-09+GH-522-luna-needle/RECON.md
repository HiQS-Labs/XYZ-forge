# Bounded recon — common Luna decision surface

Needle main0700238abbf5efa04af02efabaa4d5f5089d5e42; issue13 snapshot710c32dcfcfff020d34427fdbc6ba4defdc4304e; XYZ harness9135d2f7a8a68c0603790090649a8cf438718d7b. Graph generation and coverage are recorded in input/sources.json; graph was a lead, material files were read directly. Parent performed review; Luna supplied advisory answers later.

## Read/state/contract seams
- Needle main: Stop hook context_from_transcript -> extract iter_steps -> taxonomy.label_call -> serialize_query -> data/hook-log.jsonl; no inference (`input/needle-main-oracle_stop_hook.py:43-87`).
- Serializerq1: preceding action labels + current request, bounded12 steps/600 characters; training shares serializer (`input/needle-main-serialize.py:74-116`). Published label description/empty-answer semantics differ from proposed issue13 abstention policy.
- Needle710c: Stop hook -> pending session file -> detached oracle_infer -> session-keyed last result + hook log. Atomic replace protects file shape but has no current-generation comparison; separate timing/claim tests needed (`input/needle-710c-oracle_infer.py:18-65`).
- XYZ: releases CLI -> cmd_jog_add -> perform_write; current duplicate and terminal-reset semantics read directly (`utils/py/releases_app.py:3876-3935`). Machine contracts split admission suggestion from execution ownership, and Jog projection from Marathon result producer.
- Source snapshots came from public main/local tracked files matching main and git show of the public issue's pinned revision. No training data or data/ read.

## Failure, operations and rollback
This experiment uses existing consult.py main -> read-only Codex CLI in disposable worktree -> transcript + model attestation, in a separate full harness clone. No running surfaces or production writers change. Disable/no-launch is the rollback. No full validation suite or Needle native suite was run because this is an advisory question trial, not a runtime/finetune/code change. This is not a green harness qualification claim.

## Unknowns
Actual predicate quality on real plans; prospective next-action accuracy; trained Needle numerical/retrieval root cause; real worker/admission race behavior; direct API entitlement/latency/cost and private data controls. Each requires its owning issue's proposed experimental path; none can be inferred from synthetic case answers.

## Scope
Bounded Oracle hook/serializer + XYZ admission boundary review. Not a full repository audit. No new architecture, state authority or published contract has been adopted.
