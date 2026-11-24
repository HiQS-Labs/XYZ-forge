<!-- build_queue.py (GH-1527) as of 2026-11-20; window 14 days; daily-goals #1568; inputs: pr_minder.py --json, gh pr list, gh issue list -->

## Authority granted (one grant, covers the whole run)
- Merge PRs authored by noelsaw1 when ALL hold: development is merged in where needed; the classified
  gate is green on that exact SHA; independent cross-model QA has approved the final head; hosted
  checks are green; and EITHER CodeRabbit has reviewed the current head with no open Major OR 30 min
  have passed since a "@coderabbitai review" request on the current head with no review. Re-read
  reviews immediately before the merge. Record the timeout path as "advisory not received;
  predeclared waiver used", never as reviewed or approved. Any Major that CodeRabbit posted blocks
  until it is fixed or answered.
- Close issues whose acceptance criteria are verified on development, with a comment that cites
  the commit.
- Post status comments on PRs and issues.
- Decision defaults (KS-11, fail-closed):
  - Round cap (KS-11a): land only with an independent reviewer's explicit approval covering the final
    head. Minor/nit findings may be deferred ONLY when ALL hold: (1) the reviewer explicitly tagged
    them Minor/nit and accepted the deferral on the current head, AND (2) direct inspection of the
    actual changed files and reversibility confirms NO gate, hook (such as githooks/*), containment,
    schema, kernel, or Costly/irreversible surface is touched, AND (3) utils/ci-route.sh does NOT
    report full_required=true (full_required=false never waives a named protected surface; unknown
    classification -> park). Never defer on any protected/Costly/irreversible surface or when
    full_required=true; otherwise park and continue independent work. A PR landed with accepted
    Minor/nit deferrals states so explicitly and never claims Approved beyond what the reviewer
    stated.
  - Conflict hubs (KS-11b): conflict hubs reported by the merge-cleanup forecast route to a separate
    recorded batch.
  - Operator decisions (KS-11c / KS-02): release holds only when authored by noelsaw1, applicable,
    and not superseded.
- Provider quota fallback: when the reviewer seat's stop reason verbatim states quota, switch that
  turn's reviewer to agy and record the actual model name; if both providers are capped, park. Never
  infer quota from a round cap or generic failure.
- Flywheel per-PR approval: once granted below, this launch grant satisfies Flywheel's per-PR merge
  approval step (skills/2-daily/flywheel/SKILL.md:109-120) for noelsaw1 PRs within these bounds;
  exact full-SHA --prs N@<approved-full-sha> pin verification before --execute still applies.
- Out of scope, so the run stops and asks: merging anyone else's PR, deploys, installed-skill updates,
  ledger rewrites outside the reconcile, anything owned by another session (#1400, #1418).
- Status: NOT YET GRANTED. The parent records the operator's grant here before dispatch.

## Queue (execution order)
1. #1417 synthetic issue 1417: small bug fix through start-task or jog.
2. #1467 synthetic issue 1467: small bug fix through start-task or jog.
3. #1471 synthetic issue 1471: small bug fix through start-task or jog.
4. #1480 synthetic issue 1480: small bug fix through start-task or jog.
5. #1483 synthetic issue 1483: small bug fix through start-task or jog.
6. #1497 synthetic issue 1497: small bug fix through start-task or jog.
7. #1500 synthetic issue 1500: small bug fix through start-task or jog.
8. #1501 synthetic issue 1501: small bug fix through start-task or jog.
9. #1507 synthetic issue 1507: small bug fix through start-task or jog.
10. #1526 synthetic issue 1526: small bug fix through start-task or jog.
11. #1530 synthetic issue 1530: small bug fix through start-task or jog.
12. #1541 Arc: kickstart factory outer loop: small bug fix through start-task or jog.
13. #1551 synthetic issue 1551: small bug fix through start-task or jog.
14. Final QA pass on development: tier 1, plus the full gate in a disposable clone.

## Needs the operator (the run parks these and keeps going)
- #1400 synthetic issue 1400: owned by another session; remind only
- #1418 synthetic issue 1418: owned by another session; remind only
- #1537 synthetic issue 1537 (KS-12): unclassified; operator picks scope

## Not queued (arcs, plans, research, spikes, umbrellas, radar, daily goals)
- (none)
