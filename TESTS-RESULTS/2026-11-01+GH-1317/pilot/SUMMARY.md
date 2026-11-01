# GH-1317 bounded repair result

**One actor attempt repaired both real defects.** Independent final review Approved
in relay-system/2026-11-01/gh1317-final.md; plan approval in gh1317-plan.md.

| Evaluation | Non-due probe | Changed v2 | Changed v3 | Four positive controls |
|---|---|---|---|---|
| Unchanged base | Fails | Fails | Fails | Pass |
| Actor candidate | Pass | Pass | Pass | Pass |
| Evaluator removes prompt guard | Pass | Fails | Fails | Pass |

Each matrix run used the same frozen v3 protocol: 21 real CLI commands, no nonzero
command exits, actual external fake call counts 7 / 4 / 6. Behavioral predicates
make the defect/mutant outcomes fail despite successful command execution.

Candidate code: b3dd3e43171a2e8b3bd6f4c6ebaf5beaba7b1ba9;
harness blob 721858cd469a8bda4c70fcbe56275d018c8c5f44. One shared strictly
>3600 due predicate; prompt identity enforced before dispatch; normal settlement
releases no-call/refusal reservations. No framework/gate/runner was added.

Elapsed so far: start 22:07:47Z, final approval 22:18:28Z (10m41s). Actor attempt:
22:14:52Z to 22:15:29Z (about 37s), 1 of 2 attempts used. No human intervention
or source patch after the operator's approval. Supervisor corrected fixture/oracle
setup twice, initialized task-local coordination and corrected the PRS selector;
admission occurred after the actor, contrary to required ordering. These process
deviations are preserved in the plan and relay, not rewritten as clean execution.
No budget extension; deadline remains 22:37:47Z. Agent/reviewer used the ChatGPT
subscription; candidate provider calls were external recording fakes, $0 API spend.

Existing focused worker check: 43 pass, 0 fail. Source/manual evidence was separately
reviewed; no full regression gate. No merge-readiness, general autonomy or measured
productivity claim. V3 control calls then idles; no plan-authoring quality claim.

Final reviewer nit: original retention omitted generated tool-output bytes. Those
exact bytes are now in each run's tool-outputs/, independently rehashed against
retained tool_runs/receipt hashes. No semantic expectation or source changed.
Historical v1/v2 protocols remain as superseded setup history; v3 is authoritative.

Publication: current source classifies route=full/tier3. Use documented GH-487 WIP
draft publication with focused evidence and explicit skipped-pre-push disclosure;
full qualification, merge, deployment and checkout retirement remain outstanding.
