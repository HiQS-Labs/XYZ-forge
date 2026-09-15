---
title: "GH-522: Continuous issue admission into Jog and Marathon proposals"
gh_issue: 522
source: https://github.com/HiQS-Labs/XYZ-forge/issues/522
status: "Proposed (1-INBOX — not yet active)"
created: 2026-09-08
updated: 2026-09-09
doc_type: feedback
owner: unassigned
effort: 4
complexity: 4
risk: 3
phases: 3
---

# GH-522 — Continuous issue admission

Initial feasibility sketch, not an approved build plan or active marathon.
Full proposal and discussion: [issue #522](https://github.com/HiQS-Labs/XYZ-forge/issues/522).
Grounding: [Recon Map](recon-issue-admission.md).

## Hard eligibility boundary

Bug report → GitHub issue → substantive remediation plan included in that issue →
review/PRS/readiness checks → eligible candidate. A bug-only issue never qualifies,
even with high ratings or a ready label. The monitor reports NEEDS-PLAN; upstream
work authors and reviews the plan. The monitor cannot invent and approve it itself.

## Sketch

A periodic outbound scanner consumes changed issues; deterministic filters verify
identity, plan content, independent review, PRS, local execution contract and freshness.
GPT-5.6 Luna is the initial candidate for hourly orchestration, called only for changed inputs; it proposes logical Jog/Marathon groupings. Deterministic validation gates
any membership write through existing RELEASES writers. Marathon retains execution
ownership and Jog retains queue/lease ownership under MACHINE-CONTRACTS.md.

Jog fits bounded serial fixes; Marathon requires a coherent real arc or repeated
transform with per-item machine checks, dependencies and truthful effective write-sets.
No silent changes to committed waves; exactly one active long-horizon marathon.
Automatic inclusion, start, and merge are separate authorities. Idle is valid.

## Missing pieces

- Versioned issue-plan/review/rating identity, content hashes, trusted reviewer policy,
  and reason codes. Plan must be in the issue body or an explicitly selected issue comment.
- Strict, fail-closed admission boundary; shared effective write-set; PRS integration.
- Durable UTC scan cursor, complete pagination, closure/reopen reconciliation and dedupe.
- Atomic cross-clone reservation using canonical writers, without reviving parked tasks.
- Decision receipts, visible held reasons, bounded retries/model budgets, and kill switch.

## Proposed delivery order

1. Run the hardest-first Phase 0 spike below → expect a measured Luna qualify/narrow/reject
   verdict and an independent verdict on deterministic admission readiness.
2. Harden readiness and operate in shadow mode → expect repeatable proposals across edits,
   restart, unknown preflight outcomes and API failures; measure operator corrections.
3. Enable explicitly scoped auto-inclusion after review → expect idempotent membership,
   no parked-task resurrection and no running-wave edits. Dispatch remains separate.

## Phase 0 — Luna qualification before monitor implementation

Full experiment definitions and stop/go contract are in issue #522. Budget proposal:
two engineering days, US$10 model spend, at most two calibration prompt revisions.
No scheduler/daemon implementation or live queue writes until the spike resolves the
relevant assumptions. Reuse the current readers, preflight and canonical writers.

| Test | Bar |
|---|---|
| Substantive plan discrimination | 60 independently labelled snapshots:20 calibration +40 frozen holdout, each holdout repeated3 times. Zero false eligible proposals; at least18/20 valid controls recognized in every run. Include bug-only, convincing hollow plans, fabricated/revoked reviews, stale PRS and instruction injection. |
| Hard grouping | Ten adjudicated bundles; at least8/10 accepted without material regrouping; zero unsafe parallel admissions. Include shared interfaces, expanded tests, prefix collisions and missing/cyclic dependencies. |
| Real writer races | Edit/close/revoke/change SHA between read and write; race scanners across clones; kill before/after commit. Expect stale refusal, one membership, preserved parked attempts and unchanged running waves. Stub-only evidence does not qualify this boundary. |
| Ingestion/preflight failures | Unknown exits, malformed results, >200 issues, partial pages, reopen/restart and duplicate timestamps. Expect no admission on unknown and no skipped events; unchanged scans make zero model calls. |
| Cost/latency/escalation | Record actual billed tokens and total correction/escalation cost against stronger/manual baseline; target p95 batch under5 minutes and <=20% escalation on ordinary valid holdout cases. Two attempts per revision, then hold. |

Freeze labels/configuration/thresholds before execution. Luna cannot grade itself.
Passing classification qualifies proposal-only shadow mode; automatic inclusion still
requires the real writer/race checks. If Luna misses the bar, narrow its role or evaluate
a stronger candidate on the same frozen suite. Missing provenance or atomicity means
stop/replan, not a weaker gate. A clean finite corpus is not a universal safety guarantee.

Commit raw receipts/configuration/labels and provenance.jsonl together under
TESTS-RESULTS/<run-date>+GH-522/; negative controls under
test/baselines/gh522-issue-admission/. Assert nonempty inputs and witness failures.
Run mutation-heavy probes only in disposable full clones. This update plans the spike;
it does not run it or enable the hourly job.

## Acceptance ideas

- [ ] Bug-only issue with maximum PRS is held NEEDS-PLAN, including a local-only-plan case.
- [ ] Plan edits invalidate prior review/admission; unknown or revoked evidence holds.
- [ ] Missing/cyclic dependencies and declared/expanded write-set collisions hold.
- [ ] Duplicate scans, crashes and concurrent scanners yield one membership; terminal holds persist.
- [ ] Proposal/admission-only modes call neither builders nor merge commands.
- [ ] Nonempty positive fixtures and witnessed red controls have committed evidence plus
  provenance.jsonl; mutation-heavy gates run only in separate disposable full clones.

## Related and limits

#443 remains the closest PRS/readiness work; #492 covers state reconciliation. #418/#423
are open, but source already reads RELEASES DB; do not duplicate that adapter. #505,
#509 and #510 were closed at recon time; preserve their failure cases as regressions.
Planner fail-open concerns in the Recon Map are static findings, not reproduced defects.
No runtime gates or implementation were run for this initial sketch.

## Initial PRS estimate — 2026-09-08

`rated 55/40/50/35` → calc 180; no operator override. Proposed estimates, not reviewed
admission evidence. Priority55: useful readiness automation, downstream of #443 and
upstream plan quality. Severity40: current pain is manual coordination; this is a
feature request, not an observed data-loss incident. Appeal50: neutral. Cheapness35:
multiple admission/state seams and hostile-input proof, more than a scanner wrapper.
Recurrence not measured for this feature; related issues identify concrete seams,
not a claimed incident trend. Reassess against the approved implementation plan.

## Reversibility

Proposal-only is Easy: stop schedule. Automatic membership is Costly: it redirects
real work. Default-disabled writes, immediate disable on invalid admission, and canonical
removal of only unstarted watcher-owned memberships form the rollback; retain receipts.
