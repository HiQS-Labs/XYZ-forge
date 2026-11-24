# Kickstart run 3 — GH-1592 and GH-1541

RUN-RECORD-VERSION: 1
LANDING_CLONE: ~/kickstart-clones-run3/landing

Status: AUTHORIZED FOR DISPATCH 2026-11-24T19:12:57Z. Starting base 305ebc303d7cee1553570200963b5aac39fd4195. Wall deadline 2026-11-25T07:12:57Z. Reserve final QA from 2026-11-25T05:42:57Z. Owner noelsaw1. Child Claude Sonnet 5.5 high, parent Codex observer and recovery. Use Terra medium on compatible established build lanes. Preserve this deadline and the original attempt budgets on every resume.

Canonical dev is live origin/development. Preserve the stale dirty primary and existing #1528 task clone. Start tasks only in isolated fresh clones. A landing must use the pinned LANDING_CLONE. Restrict merge-cleanup temporaries to a run-owned TMPDIR and set MERGE_CLEANUP_KEEP_WORKDIRS sufficiently high to prevent the retained-clone pruning reported in #1578. Preserve evidence and no broad cleanup. Record actual route, candidate SHA and gate receipt. Any repair in the run is counted as assisted as required by #1328. No parent implementation during the trial.

Queue generated without hand-editing by build_queue.py --daily-goals 1592 --other-session 1528. Its #1575 route suggestion is subject to the live diff classifier and skill invocation requirements. Use start-task if express is ineligible. Before dispatching held items, use Conveyor/intake against the exact issue and rerun admission against the unchanged goals issue. Respect existing task ownership and dependencies. Do not dispatch directly from prose.

KS-19 resets the baseline. For each completed gate append one canonical record, with an accompanying BASELINE event that names durable attempt ID, kind, exact SHA, start/end UTC, measured seconds, route and outcome. Do not repeat a gate line on resume. Track infrastructure stops separately with actual diagnostics. Keep final development QA separate from route means. Disclose missing route samples and denominators.

KS-15 checkpoint after the first independently verified milestone and before controlled recovery. Use run_record.py checkpoint into a dedicated non-integration clone and publish the redacted branch. KS-16 is scheduled for the first completed long operation, after durable effect identification; if host support for safe duplicate or stale delivery is absent, report it as unexercised. KS-20 is scheduled after the first published checkpoint and before dispatch of the next lane; inform the parent at the safe boundary and keep owner/attempt budget intact. Deliberate parent interruption requires a genuinely fresh recovery session, and only verifiable events earn credit.

<!-- build_queue.py (GH-1527) as of 2026-11-24; window 14 days; daily-goals #1592; inputs: pr_minder.py --json, gh pr list, gh issue list -->

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
  ledger rewrites outside the reconcile, anything owned by another session (#1528).
- Status: GRANTED for the bounded #1592 run under the recorded standing owner-PR rules. The operator authorized run 3 after #1593 landed in the November 24 chat turn. The grant applies only to the run's admitted in-scope noelsaw1 PRs.

## Queue (execution order)
1. #1575 Follow-up to PR #1574: express SKILL.md manual-entry wording and the 🆕 marker in the GH-1530 ledger row: docs fix through express.
2. Final QA pass on development: tier 1, plus the full gate in a disposable clone.

## Needs the operator (the run parks these and keeps going)
- #1528 connect-the-dots: tighten evidence discipline and dry-run safety: owned by another session; remind only
- #1583 marathon planner and frozen twins read a gone path_present probe as blocked, not landed (parity with swarm_preflight, GH-1580): unclassified; operator picks scope
- #1590 build_queue --daily-goals: a backticked foreign lead (`owner/repo#N`) on a checklist line lets a later #N become the item: unclassified; operator picks scope

## Not queued (arcs, plans, research, spikes, umbrellas, radar, daily goals)
- (none)

## Progress log
BASELINE: The Terra CLI returned gpt-6.1-terra, medium. The Claude Sonnet 5.5 high relay route produced an attested Approved verdict on the GH-1580 retained-scope seed 99f48b73d. These are route probes, not Run 3 evidence.
BASELINE: The Terra read-only clone inventory held all 94 candidates. Two exact merged heads (#1589 and #1584) still have per-clone attempt history and other ignored evidence. About 22 GiB available; no prior clones altered.
BASELINE: GH-1575 pre-launch scan on development 895cec0f2 found the GH-1530 ledger raw_text already has the completed marker and no new marker. The express manual-entry sentence is still ambiguous. Re-check both on the actual intake base. Remaining skill-only patch routes docs by ci-route; use the invocation rails in the record.
BASELINE: GH-1590 read-only parser probe at 895cec0f2 reproduced the admission bug: a bare foreign lead followed by #10 yields [], a backticked foreign lead followed by #10 yields [10], and a backticked local #10 followed by #11 yields [10]. Candidate still requires normal preparation/admission.
BASELINE: PR #1593 head ec4a644d2ea4d42c05819f1d9d01512e909e11bd passed required hosted smoke and local full gate. CodeRabbit withdrew its Major on the previous head. Both threads are resolved. Current-head advisory requested in PR comment 7139056962 (use its UTC timestamp and 30-minute window); review-cap notice applies. Run 3 remains prepared pending landing.
BASELINE: PR #1593 merged as 80ebadaf41. Advisory not received on ec4a644d after the 30-minute window; predeclared waiver used. GitHub required smoke, independent QA and exact-head local gate passed. Reconciliation, RELEASES check and issue-doc-sync passed; origin/development is 305ebc303d7cee1553570200963b5aac39fd4195. This is preparation and is excluded from run 3 metrics.
GATE: GH-1575 head 13f3c1289fc6be4ddafc52ed8a8024546d6b9d0f docs 107s green
BASELINE: attempt GA-1575-1 kind=docs-gate-pre-push-candidate sha=13f3c1289fc6be4ddafc52ed8a8024546d6b9d0f start=2026-11-24T19:18:53Z end=2026-11-24T19:20:40Z seconds=107 route=docs outcome=green cmd=utils/pdda/pdda.sh run (33 warnings, 0 errors). #1575 builder codex gpt-6.1-terra reasoning medium observed in CODEX log (CODEX_FLAGS -m gpt-6.1-terra -c model_reasoning_effort=medium); reviewer claude-sonnet-5-5 modelUsage observed, effort high requested via CLAUDE_REASONING_EFFORT (not echoed by CLI); relay attested Approved reviewed 79916c3c77d5, relay wall 74s, one Nit deferred (SKILL.md:212 'only' placement), no gate/hook/containment surface, ci-route full_required=false.
GATE: GH-1575 head 13f3c1289fc6be4ddafc52ed8a8024546d6b9d0f docs 137s green
BASELINE: attempt GA-1575-2 kind=pre-push-hook-docs-gate sha=13f3c1289fc6be4ddafc52ed8a8024546d6b9d0f start=2026-11-24T19:21:05Z end=2026-11-24T19:23:26Z seconds=141 (hook reported 137s) route=docs outcome=green first push of docs/XYZ-forge-gh1575-express-manual-entry-2026-11-24, PR #1596, attempt context booked via gate_receipt attempt-start after first push refused (gate-attempt: REFUSED no reservation, 1s).
BASELINE: milestone M1 (#1575): PR https://github.com/HiQS-Labs/XYZ-forge/pull/1596 head 13f3c1289fc6be4ddafc52ed8a8024546d6b9d0f; independent review Approved (claude-sonnet-5-5, relay-attested); docs gates green x2; CodeRabbit advisory requested 2026-11-24T19:23:51Z (comment on #1596), waiver eligible at 2026-11-24T19:53:51Z; hosted smoke in progress; not merged. Next lane (#1590 prep) NOT dispatched pending KS-15 checkpoint and KS-20 boundary.
