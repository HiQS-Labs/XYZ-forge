# GH1358 checkpoint implementation plan QA

STATUS: Approved
Reviewer: independent native Codex agent checkpoint_qa
Scope: appended checkpoint plan in PROJECT/1-INBOX/GH-1358-DURABLE-FACTORY-QUALIFICATION.md;
opt-in one-task wake, existing Jog supervisor, separate publication clone, local rehearsal.
Review date: 2026-11-08. Issue-level seven-transition plan was not reopened.

Initial concrete findings:
- Publication clone ahead of checkpoint: ff-only merge of an ancestor succeeds, so pushing
  HEAD could publish unrelated commits. Accepted: compare resulting HEAD with recorded SHA,
  push exact recorded SHA.
- Signal cleanup released lock before publication in initial finally implementation.
  Accepted: handler exits; normal completion publishes; final cleanup releases lock.
- Fresh publication clone must install/check existing hooks. Accepted in deployment setup.

Independent revised plan verdict (verbatim):

> Approved — bounded implementation plan.
> The revised diff fixes the two identified defects: publication verifies and pushes the
> exact checkpoint SHA, and supervisor ownership remains held through normal publication.
> Recovery returns before dispatching another task.
> The plan appropriately reuses Jog’s queue, lock, cold-start recovery and existing push
> hooks. It limits this delivery to the opt-in checkpoint connection and distinguishes
> fixture controls from real scheduled-work evidence.
> Final QA must bind the revised candidate to two-wake publication, rejected-push recovery,
> unrelated-dirt refusal, exact-SHA refusal and focused suite results. This approval is for
> implementation and rehearsal, not whole-issue qualification.

Timing: initial source implementation preceded resumed start-task plan review; this receipt
is not represented as pre-implementation QA. Review preceded scheduled rehearsal deployment.
