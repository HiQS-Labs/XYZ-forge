---
title: "Remaining weekly planning boundaries — Recon Map"
status: Reference
created: 2026-10-12
updated: 2026-10-12
owner: Codex
doc_type: reference
roadmap_exempt: true
goal: Ground required W7–W11 against current owners before their implementation plan.
---

# Recon Map — remaining weekly planning boundaries

Commit: bc4bdf42eae2631e66b4656d077a4c84b6131abd · canonical target:
d09b8f9dedd436be3e5f883f68deff985719fe1b · Mode: grep-only/direct reads.
A/B/C/D traces ran serially in the main context during this continuation. The exact
boundaries were already traced before this map; no code landed afterward (d09 is
ledger/reconciliation/docs/evidence). No current graph is callable in this runtime.
This is current-state evidence, not an implementation or acceptance attestation.

## Subject and current-state radius

W7–W11 cross the weekly/daily core, shared intake, canonical ledger reader and
merge resolver, authoritative planner, preflight/packet/YAML owners, manual
Marathon launcher/driver, Jog projection/landing and closeout. Existing callers
include weekly/daily outlines, 10days adapters, direct manual CLI users, driver
hooks, GitHub PR publication and declared execution clones. Durable state includes
Git refs/commits, canonical SQL/DB/receipts/events, private preparation intent,
tick/driver locks and tokens, phase/observer records and reviewer attestations.
No dispatcher, schedule or deployed skill changed during recon.

## Seams and call paths

| Seam | Direct source | Existing contract / failure |
|---|---|---|
| Weekly boundary | `planner_core.py:808,994,1072,1282` | Existing opt-in preparation uses complete shared discovery, local clone lock/intents, canonical writers and held results. No freeze/dispatcher. Current batch inspector omits canonical Markdown raw-text grammar; R6 Medium#1028 remains tracked. |
| Discovery | `issue_intake.py:213` | Full issue/open-PR/files pagination and prior-member refresh; PR metadata includes draft, head, checks, body. Read completeness is distinct from execution authority. |
| Prior-art candidates | `prior_art_recon.py:51,87,120,194` | Merged-PR/all-state issue/sibling probes from #1026; 30-result GraphQL/one-page REST fallback. Candidates supplement actual code review; not complete history or criterion proof. |
| Existing PR sequencing | `planner_core.py:92,158,180,207,220` | Advisory graph accepts CI NONE, ignores draft, drops unknown dependency references, breaks cycles without a hold. Actual in-memory red observations are in phase7-readiness-before.json. Weekly currently refuses to treat this as readiness. |
| Canonical queue | `releases_app.py:4602,4633,4720` | Qualified shared Jog query and optional read-only held inventory; all declared repository/GIDs qualify. No Marathon census yet. Inventory describes one declared root and grants no dispatch. |
| Native work evidence | `releases_app.py:5600,5751` | Pure loader reads ledger/events without migrations/config/network. CLI work status additionally reads connector configuration. Lifecycle evidence does not establish criterion delivery. |
| Canonical Marathon ledger | `releases_app.py:516,2988` | planned/running/done/escalated/abandoned rows; human list lacks qualified machine inventory. Marker alone cannot prove active work or completion. |
| Lock ownership | `rtl.py:966`; `releases_app.py:346,381` | Shared driver-lock resolver uses Git common-dir; canonical writer lock owns audit/journal. Read census must never acquire/reap/recover/signal a live owner. Current weekly lock is clone-local. |
| Observer | `marathon.sh:129,151,166,181,217,254,563` | #1017 attribution repair landed. Existing helpers qualify result/heartbeat to context and exact logical product path. Observe loops; init/phase/driver/finish/terminal write context. No one-shot read API. Progress context is optional and lives beside the run log. |
| Ledger integration | `ledger_merge.py:1,47,170`; `releases-merge-resolve.sh:108,139,226` | Existing B1 keeps higher generation and replays verbs, regenerating added GIDs/events. That cannot preserve weekly identities/history. Current task's conservative documented dump resolution retains incoming owner rows and exact task additions before sanctioned rebuild; this recipe is not yet a reusable weekly owner API. |
| Authoritative proposal | `_marathon_plan.py:786,929,973,1061,1085`; `marathon_plan.py:163,192` | Canonical owner rank/scoring/packing already reused. Missing dependencies only warn; closed/completed markers count toward state. Dry run deletes temporary rendered plan; no bounded strict candidate projection API. Database rank map is keyed by bare number. |
| Preflight | `swarm_preflight.py:1297,1358,1476,1515,1705,1825` | Fetches and creates/removes a temporary ref worktree even during dry run. Acceptance fidelity exists, but fetch failure is advisory in some paths. Canonical packet renderer owns brief shape; dry-run report is not a canonical brief. |
| YAML | `marathon_yaml_emit.py:71,125,226`; `bin/marathon-yaml:14,94,173` | Existing emitter and validator own constrained scalar dependency/order. Emitter writes output, rejects unknown/missing packets and unsupported dependencies. Current fields include reviewer/round/turn bounds, not full weekly receipt/cost policy. |
| Existing independent receipt | `relay_attest.py:231,318` | Validates driver-witnessed reviewer, relay bytes/trailer and isolated reviewed HEAD; candidate changes outside transcripts invalidate attestation. It attests peer review, not human firing approval. |
| Firing/phase boundary | `marathon_drive.py:1890,2668,2713,3310`; `marathon.sh:628` | Closed issue is parked by status alone. Driver checks phase acceptance/gate and peer candidate, then emits approval and may run hook/publication. No shared criterion-level prior-art receipt at fire/resume/each phase. |
| Publication/landing | `marathon_drive.py:2644,2727`; `jog_run.py:356,387,871`; `marathon-closeout.sh:189,198,246,292` | Driver can invoke closeout; Jog checks PR/head/gate receipt before merge. Separate latest-target redundancy/regression approval is not currently enforced. Closeout pushes before PR creation and permits no-checks landing under the existing GH544 private-phase policy. A new required-CI policy must not silently rewrite that standing policy. |

Paths above are repo-relative under existing owners: planner_core/issue_intake in
skills/3-weekly/weekly-planner/scripts; Python owners in utils/py; launcher/closeout
in relay-automation; merge helper in skills/2-daily/merge-cleanup/scripts.

## State and effect ownership

Shared intake owns discovery/normalization/deduplication/evidence mechanics. Core
callers own policy, clones/commits and selection. HQ renders captures; RELEASES
CLI owns rows/events/generations; documented merge resolver owns DB rebuild and
views. Planner/preflight/emitter own execution artifacts. Existing launcher/driver,
Jog and closeout own execution/publication. The new weekly path must add checks at
these owners, not duplicate their queues, SQL readers, scorer, renderer or runner.

Known conservative integration: task old-base rows were unchanged; d09 current
owner rows were retained exactly, plus genuine task additions, settings three-way
and maximum generation. The resolver/check returned0 failures/9 existing warnings;
artifact10/refusal19 passed. Unsupported edits/deletes/identity collisions hold.
Original displaced DB is preserved. This does not establish generic merge recovery.

## Build, failure and rollback today

Core/app changes use existing mapped suites; launcher/driver/schema/test changes
require existing full classification. Mutation-heavy suites run only in the
separate disposable full clone. Current source77e99f17 is Phase6 Approved3/3;
normal bc4 full409/409+Python21 passed830s. Existing hosted smoke passed; normal existing Linux CI38204784286 completed
SUCCESS at exactbc4, Ubuntu407/407 includinggh123. This verifies the observed
fixture correction, not deployed/live-provider acceptance.
Raw evidence logs retain exact bytes even when whitespace checks flag their output;
source/docs checks are clean separately. No test/case/parameter/registration added.
New read seams can be reverted locally; mandatory dispatch policy and persistent
freeze/coordination changes need explicit compatibility/rollback disposition.

## Unknowns and cutoffs

| Unknown | Consequence | Evidence needed before its plan step |
|---|---|---|
| Complete authority roots and unobserved runs | Cannot call missing context/global fleet idle | Caller-declared authoritative roots plus canonical census and driver/context/token reads; absent/ambiguous sources hold. |
| Shared writer location/ownership across clones | Current local lock cannot promise one weekly writer globally | Extend existing fcntl ownership to explicit shared coordination root and record its identity; no guessed primary/deployed path. |
| Reusable GID/history-preserving merge path | B1 replay remints identity; manual task resolution is not weekly automation | Read merge helper/resolver/rebuild callers before a conservative owner extension; refuse unknown/overlapping changes and existing backups. |
| Strict planner projection and cross-repo identities | Existing bare-number rank/dependency maps are insufficient for mixed ownership | Characterize owner reader/callers; optional strict qualified projection must preserve legacy interfaces, scoring and NULL-gh semantics. |
| Required-CI/dependency/budget policies | Defaults could authorize unsupported execution | Required explicit caller inputs; use fresh structured metadata and hold missing/unknown/cyclic dependencies and draft/missing checks. |
| Human approval storage/authority | Reviewer attestation or self-authored JSON cannot grant human consent | Preserve trusted exact operator confirmation in the existing flow; mechanical hash/order/budget binding must not invent an approval authority. |
| All effect sites in closeout/Jog/custom hooks | A front-end-only check could be bypassed by a later phase/hook/push | Read exact closeout/Jog variants and connect the same guard immediately before effects and at resume/phase boundaries. |
| Mandatory guard rollout against existing fixtures | Silently optional guards or weakened old cases would violate policy | Inventory existing caller/fixture assumptions; preserve covering assertions and moratorium, disclose intentional safety-policy changes, propose individual new tests only if necessary. |
| #752/#1020 contradictory/replay state | Unsafe continuation cannot be inferred from terminal markers | Existing durable phase/token/attestation facts; unknown/contradictory state holds with no reset or blind re-fire. |
| Full deployed/provider behavior | Local fixture/observer reads cannot prove live fleet acceptance | Separately authorized future live validation; current task forbids enabling/running/installing. |

A/B covered the listed entry/data paths. C/D are bounded to listed contracts,
existing suites and known failure paths; full fixture impact, the complete downstream Jog/closeout caller graph and runtime
total time/cost enforcement are cutoffs. They are prerequisites
for their implementation plan, not declarations that those edges are absent.
