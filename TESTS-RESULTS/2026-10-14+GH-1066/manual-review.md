# Manual policy review — GH1066

Input: the nonempty added CI-heavy section in skills/2-daily/merge-cleanup/SKILL.md.
This is prose conformance review, not a claim of automated agent enforcement or a live merge batch.

| Case | Required outcome | Observed instruction and verdict |
|---|---|---|
| Three PRs, one hard dependency and shared runtime | Review whole strategy before first merge | Step2 retains dependency order; Step5 explicitly triggers for three or more, including subdivided batches. PASS. |
| Two ordinary independent PRs | No mandatory extra strategy relay | Step5 final sentence leaves one/two queues without extra review unless risk/policy calls for it. PASS. |
| Same actual model behind different CLI names | Not cross-model approval | Step5 requires different actual model family and records both identities; CLI alone is not proof. PASS. |
| Add a PR or change dependency/order/base content/risk after approval | Refresh affected review | Step4 invalidates affected evidence; Step5 reopens affected review for material changes. Editorial record updates do not. PASS. |
| Repo has no batching mechanism and requires per-PR CI | Preserve mandatory checks and sequential reconcile | Fallback explicitly retains both and disclaims one/two-run guarantee. PASS. |
| Reviewer absent or model identity unknown | Truthful neutral note; no severity escalation | Distinct unavailable-review and unknown-model notes; hold affected batch; no defect severity/new blocker issue. PASS. |
| Another review round after resume | Existing cumulative cap applies | Step5 caps three cumulative rounds per batch including resumes; no new counter. PASS. |

## Witnessed manual red controls

Using the retained source excerpt below, manually substitute the first trigger sentence’s “three or more” with “five or more”. The three-PR case now lacks required review: REJECT. Restore the original (production file never changed for this control).

Delete “different actual model family from the plan author; a different CLI alone is not proof.” from the excerpt. A reviewer using the author’s model under another CLI no longer violates an explicit model-diversity condition: REJECT. Restore the original. These controls demonstrate sensitivity of the manual policy review, not an executable gate.

## Reviewed source

```markdown
### CI-heavy repositories: plan merge groups before qualification (GH-1066)

Prefer a few coherent landing groups over repeatedly repairing, pushing and fully testing
one PR at a time. This is caller-owned planning, not a new driver mode or a gate bypass.
Use the existing batch issue for qualifying queues; smaller queues use the run summary.

1. **Map the cost and constraints.** Read the repo's required checks, push hooks, hosted
   triggers and reconciliation policy. Identify which pushes actually start broad CI and
   which existing path supports batching (merge queue, staging or aggregate landing PR).
   Record the chosen path and intended full-run checkpoints before the first mutation.
2. **Group by dependency and interaction.** Keep hard dependencies in order; group related
   changes sharing runtime/contracts or repeated conflict sites. Shared ledger/CHANGELOG
   files alone do not prove semantic coupling. Separate unrelated work and risky migrations,
   security or containment changes that need independent rollback and qualification.
3. **Prepare before expensive runs.** Resolve the group's known conflicts and combined
   interactions in a disposable full clone, complete independent review, and run the existing
   focused checks as repairs are made. Publish complete reviewed checkpoints rather than
   each mechanical repair. Required per-PR checks still run on their actual final heads.
4. **Freeze the candidate.** Record member PRs and head SHAs, current integration base,
   combined candidate SHA, review receipts and rollback boundary. New members, code repairs
   or base changes invalidate affected evidence; refresh review/checks before landing.
5. **Adversarial sequence review for three or more PRs.** When the authorized batch
   contains three or more PRs, use one bounded [`relay-xyz`](../../1-hourly/relay-xyz/SKILL.md)
   review of the whole grouping, merge strategy and sequence before the first merge, even
   when the batch is divided into smaller groups. Choose an independent reviewer using a
   different actual model family from the plan author; a different CLI alone is not proof.
   Record both model identities, the frozen PR/head/base/candidate SHAs, proposed groups/order,
   required CI checkpoints and rollback boundaries in the existing batch record and relay.
   Ask the reviewer to challenge missing dependencies, semantic interactions, conflict sites,
   unsupported gate deferral, duplicate broad runs and recovery after a partial landing.
   Disposition supported findings before proceeding; advice cannot waive deterministic gates
   or operator authority. Use at most three cumulative review rounds per batch, including
   resumes; do not repeat this strategy review per PR or replace required per-PR QA.
   Material changes to membership, dependency/order, integration content or risk reopen the
   affected plan review; editorial record updates do not. Record unavailable review neutrally
   ("Independent review did not run.") or an unknown identity as "Reviewer model identity
   unverified." Hold the affected batch without assigning defect severity or opening a
   blocking issue. Do not claim cross-model
   approval without evidence. Ordinary one/two-PR queues need no extra strategy relay unless
   risk or repository policy calls for one.
6. **Qualify the complete group.** Where policy permits, reserve the first full gate for
   this frozen combined candidate, after preparation is complete. Keep the existing tier
   classification; grouping docs does not require a full gate. Run the repository's
   qualifying command on its required platform; a parallel publication run is not sequential
   promotion evidence. A failed required check stops landing; diagnose before retrying.
7. **Land through the supported path.** Preserve merge-history policy and PR/issue provenance.
   Never retarget PRs, create a staging branch, alter branch protection/workflows, cancel
   required runs or use a push bypass merely to meet a CI budget. Those changes require
   their own authorization. Historical time-boxed exceptions are not standing permission.
8. **Verify the landed result.** Reserve a second full run for the actual landed integration
   result when policy requires it or candidate evidence no longer qualifies that result.
   Reuse an existing qualifying hosted run only when its SHA/content scope covers the group;
   do not launch a duplicate final sweep. Complete required reconciliation and fresh teardown
   checks, and record actual run SHAs, results and any remaining verification.

**Fallback:** if no supported batch path exists, keep ordinary sequential merges and every
required per-merge reconciliation/check. The current Forge driver reconciles after each merge;
this guidance does not defer that sequence or add a batching flag. Group preparation can reduce
repair/push churn, but cannot promise one or two total CI runs under an unchanged per-PR policy.
Record that limit; use Forge's `docs/CI-CHURN-RECOVERY-SOP.md` for a separately authorized
recovery window when warranted. Never skip qualification or claim unmeasured savings.

```
