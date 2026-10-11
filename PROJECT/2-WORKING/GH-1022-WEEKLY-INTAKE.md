---
gh_issue: 1022
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1022
title: "Weekly issue intake — staged shared discovery"
status: In progress
created: 2026-10-11
updated: 2026-10-11
owner: Codex
doc_type: feature
effort: 4
complexity: 4
risk: 3
phases: 3
goal: Reuse shared discovery for a held weekly proposal without importing unattended execution policy.
---

## Status

| What was just completed | What's next |
|---|---|
| Independent Codex plan QA Approved; shared extraction and held preview implemented. | Final existing/manual verification, independent QA and draft publication. |

## Table of contents

- [Phase 1 — Discovery and compatibility](#phase-1--discovery-and-compatibility)
- [Phase 2 — Shared extraction and held preview](#phase-2--shared-extraction-and-held-preview)
- [Phase 3 — Verification and draft](#phase-3--verification-and-draft)
- [Remaining acceptance](#remaining-acceptance)

## Bet and scope

Outcome: complete issue observations shared by weekly and 10days, without importing
10days' auto-fire policy. Smallest viable staged bet: one harness-owned issue_intake.py,
thin existing shell adapters, and an explicit read-only weekly-intake preview in the
existing planner core. The new weekly skill describes the held preparation entry point.
This PR is a foundation, not completion of umbrella #1022. The entire workflow is held
until branch reconciliation and execution safeguards ship and receive separate review.

Calling the whole 10days workflow is rejected because it re-rates and auto-fires.
Copying planner/orchestrator code is rejected: planner_core remains outline owner;
marathon_plan/_marathon_plan remain executable-plan owners. No shared scoring engine
is needed for this extraction. No new CI tests, cases, registry entries, guard lanes,
scheduling, deployment, authentication edits or live Marathon/Jog execution.

Reversibility: Costly for the eventual shared execution protocol, Easy for this staged
read adapter; revert adapters and module together. Existing scan/find-doc consumers
notice dependency/lookup changes; weekly/daily default modes must retain their contracts.
Required safety-policy hardening is recorded separately below, never hidden in extraction.

## Phase 1 — Discovery and compatibility

Goal: characterize interfaces and distinguish mechanical extraction from policy.

Base: f1225359e1f677ef029117598625d1e5b4488b50, origin/development.
2026-10-11 issue updated 15:41:28 UTC; all three comments read. Four open PRs:
#1019 cleanup history, #1017 observer path, #954 recipe profiles, #930 held canary.
No intake ownership or equivalent shared module found. prior_art_recon --query intake
reports PASS; pre-registration reconnaissance found no #1022 row; canonical CLI later registered rmi-01M4NVEZG8FAM7BBS950TRBWH9 and rated 70/65/50/25. Source implementation is isolated on
feat/gh1022-weekly-intake, never an auto-* planning branch.

scan-issues.sh: numeric MAX/MIN positional values, 10/0 defaults; MAX > MIN;
UTC date-level updated query; open only; gh issue list limit 200; gh JSON projection
sorts by number; labels become names. gh exit status propagates, no checkpoint.
find-doc.sh: --root > TENDAYS_ROOT > current git toplevel > cwd; malformed arguments
exit 2, help 0; last positional wins; first regular matching file in bucket order
1-INBOX/2-WORKING/3-COMPLETED/4-MISC; miss returns JSON nulls; preflight heading plus
json fence are presence heuristics only. Uses jq and filesystem find traversal order.
Preserve these quirks, prerequisites, messages and failure behavior.

Installed copied skills require the shipped harness locator, not cwd-relative imports
or an independently installed sibling skill. Retain copied and symlinked invocation
via existing locator roots and harness-owned Python; fail clearly for an old harness
missing the module. Python3 is an explicit new adapter prerequisite, already harness
runtime default. Deployment is NOT performed here.

planner_core: ensure_temp_dir and CLI write scratch outline files; native ledger read
can fall back to gh; daily uses closure-number union, PR read lacks draft flag,
CI NONE may enter ready and dependencies are only annotations. These are outstanding
separately reviewed safety-policy changes, not silently repaired during extraction.
New preview calls pure existing sequencing/audit helpers, labels them advisory and
never treats their results as readiness. New preview reads never import main or create
scratch directories. Authoritative planner remains unchanged.

Namespace: repository has weekly-planner/daily-planner but no exact weekly name or
alias. Recheck installed roots before any later installation; this PR installs nothing.

Rating 2026-10-11: propose rated 70/65/50/25 (umbrella scope). Duplicate/stale dispatch
can waste work and regress shipped behavior; current user asks to start, no deadline.
Appeal neutral; broad safety work is costly. Recurrence reconnaissance: weekly-related
issues updated in last 14 days (Sep 28–Oct 11) include #1022, #889, #897, #942;
preceding Sep 14–27 includes #775/#841/#606. These are distinct proposals/skill defects,
not measured recurring duplicate-dispatch incidents. Incident trend unknown; no
severity downgrade inferred. Before registration, no existing rating or owner override for #1022; current CLI row preserves the registered rating.

QA gate: findings written here; baseline manual successful/failed scan and doc/root
collision probes retained; existing gh369 suite is the covering doc resolver check.

## Phase 2 — Shared extraction and held preview

Goal: share read mechanics with a held, effect-free preview.

1. Characterize legacy adapters before edits in disposable fixtures, save source hashes,
   commands/results and nonempty provenance under TESTS-RESULTS/2026-10-11+GH-1022.
2. Add skills/3-weekly/weekly-planner/scripts/issue_intake.py: explicit clock/root/runner; UTC query, discovery/doc lookup,
   qualified normalization/deduplication. Read adapters are effectful I/O, no writes/import
   effects. Legacy subcommands preserve gh command/projection/limit and doc schema.
3. Replace original scripts with thin locator+Python exec adapters; preserve interfaces,
   messages and defaults. Reuse existing locator, no new Bash executable.
4. Add explicit planner_core weekly-intake mode, requiring repository identity and since.
   REST paginated issues includes open/updated/reopened/closed and filters PR records;
   no search-API 1000 ceiling. Read all open PR metadata via paginated GraphQL or explicit
   complete page adapter. Output completeness plus qualified identities; any failure,
   malformed snapshot or conflicting duplicate reports UNKNOWN and exit nonzero with
   no partial output treated as complete. No checkpoint/DB/branch mutation.
5. Weekly relevance boundary: all updated issues since caller date plus explicitly named
   members/carryovers/dependencies from an optional previous snapshot. Re-fetch those exact
   IDs, dedupe qualified issue identities; closed state is observation, never delivered.
   Preserve previous issue membership, but do not accept snapshots from another repo.
6. New weekly skill uses this preview, distinct from weekly-planner/daily-planner;
   documents held boundaries and remaining implementation. No generated YAML claimed
   executable; no fire command exists in this new entry point.

QA gate: parity on legacy success/failure/date windows/root collisions/order; weekly
pagination/PR filtering/reopen/update/membership/malformed/offline/conflicting duplicates;
pure-helper import and preview no-write evidence. No new permanent tests.

## Phase 3 — Verification and draft

Goal: retain falsifiable evidence and publish a truthful staged draft.

Run existing gh369 suite in disposable full clone, bracket Git identity. Record manual
negative controls and source hashes/provenance; inspect forbidden test additions.
Independent final Codex relay QA against staged scope and safety limits. Run classifier's
applicable final gate once on final code revision, in disposable full clone. Publish draft
to development, verify remote SHA and actual hosted checks. No merge/deploy/dispatch.

QA gate: exact-revision evidence, final review verdict, draft PR with remaining scope.

## Remaining acceptance

Issue staged checklist: 1 characterization and 2 extraction addressed here; 3 shared
core connection only read preview; 4 policy differences identified, not implemented;
5 discovery parity/separation only. No umbrella completion/closure claim.

Architecture checklist 1–10 remaining: auto-yyyy-mm-dd one-writer branch lifecycle;
complete restartable checkpoint after durable canonical capture/ledger/receipt writes;
ALL relevant registration through hq_render_capture and releases_app preserving GIDs,
ratings/status/owner edits with XYZ_WORK_CONNECTORS=0; concurrent reconciliation;
active Marathon/Jog/PR decisions/locks; bounded authoritative plan/YAML construction;
structured IDs/draft/required-CI/unmet-dependency readiness corrections; immutable
freeze and drift invalidation; exact operator approval and pre-fire enforcement;
full manual acceptance scenarios and scheduling review.

Mandatory shared protocol remains UNSHIPPED: criterion-by-criterion independent current-code
review, exact target HEAD/plan/branch commit receipts, delta/no-op/overlap holds,
fresh comparisons immediately before fire and at phase/resume, and separate latest-target
redundancy/regression review before landing. #752 and #1020 are unresolved; this PR
changes no driver boundary and authorizes no continuation. Do not substitute doc bucket,
closed status, linked commits, outline PASS, or a generated report for delivery evidence.

Moratorium: no proposed CI tests in executable write-set; existing gh369 and manual
verification suffice for this staged discovery. All future test proposals need individual
operator approval, including cases inside existing suites. No approval inferred from QA.


## Plan review dispositions and current implementation

2026-10-11 independent Codex plan QA Approved, attested to 22806e5f.
Nit 1 implemented: historical absent-row/rating observations now distinguish registration.
Nit 2 partially implemented: phase goals and source inventory are present; the single
ordered implementation list is retained. Use /debug-mantra for any execution-time
failure diagnosis; no speculative acceptance expansion or new CI tests.

- [x] Phase 1 current sources and installed-name inventory characterized.
- [x] Phase 2 shared read module, compatible adapters, explicit held core mode and skill.
- [ ] Phase 3 final independent QA and exact final gate/publication.

Sources: scan-issues.sh and find-doc.sh pre-extraction at base f1225359; planner_core.py
run_cmd/ensure_temp_dir/get_open_prs/detect_merge_sequence/pivot_daily/ingest_weekly_intake;
utils/py/marathon_plan.py delegates to _marathon_plan.py. These names bind the recon
claims after line numbers move. No executable-plan owners or default modes changed.

First manual probe correctly refused the inherited XYZ_HARNESS pointing to the old
primary harness lacking issue_intake.py. This is an explicit update dependency, not a
fallback to duplicated code. Candidate probes select the task harness; installed
adapters must select a current harness before running. No deployment performed.


## Shared module ownership correction — plan round 2

GH-777's existing inventory ratchet rejects every new .py file under utils/scripts/bin,
including import libraries. The original proposed utils/py/issue_intake.py failed that
existing check. No baseline/rule/test was changed. Use the existing intake owner's
`skills/3-weekly/weekly-planner/scripts/issue_intake.py` instead: one import-only bundled
library adjacent to planner_core, no standalone executable CLI. Existing scan/find
entry points call its functions through the selected harness; weekly-intake stays an
existing-core submode. This follows existing skill-subsystem ownership and the
ratchet's documented new-verbs-through-existing-entry-points rule. It does not move
all planner_core, add a writer or orchestrator, or deploy a sibling skill dependency.
Request independent review of this ownership decision; if judged a policy bypass,
hold implementation/publication and seek an explicit operator decision instead of
relaxing the ratchet. All remaining umbrella acceptance remains held.


## Final QA round 1 disposition

Implemented the observed Should finding: state normalization validates string type
before uppercasing, routing malformed null/numeric issue/PR/prior records through
the existing ValueError → UNKNOWN JSON boundary. Valid-state control and pre-fix
red controls retained in state-type-controls.json; manual hashes refreshed.
This is a surgical normalization fix, not a new safety-policy layer or CI test.

## Final QA round 2 and Workhorse continuation

Implemented observed reviewDecision Should at the weekly PR-read boundary. Validate
text/CI shapes consumed by existing advisory helpers with ValueError; preserve
legitimate null/absent review semantics and all legacy sequencing policy. Manual
valid/invalid/pre-fix controls retained; source hashes refreshed. Third final QA is
the remaining round in the configured three-round budget.

The user requested Workhorse monitoring: .workhorse/2026-10-11-gh1022.md retains the
active evidence-backed checklist (local excluded runtime state, no hooks/Goals).
Remaining umbrella acceptance is required and active, not silently removed by the
foundation draft. Continue feasible authorized work after intermediate reports.
No authority to merge, deploy, schedule, fire real work, add tests or extra agents.
CommandCode is not used; #1023 is outside this task's validation and implementation.

## Final approved staged artifact

Final Codex round 3 Approved at ca4c9b5a2d06ac6f247cc6e0594ac9d68b049978; attestation and red controls retained. Existing gh369 14/14 and classified docs/skill gate exit 0, zero errors, 430 warnings on evidence revision aeabcdeb. Issue sync unavailable and existing governance/Marathon warnings explicitly retained; no full runtime-suite claim. Final publication/hosted checks next. Remaining umbrella W6–W11 stays active.

## Phase 4 — Canonical branch accumulation (active design)

Goal: make every relevant observation durable on an explicit local auto-yyyy-mm-dd
planning branch, using the existing canonical writers and preserving owner state.
This phase is required continuation of #1022; the published discovery draft is not
completion. Dispatch remains unavailable throughout this phase.

Ground truth: releases_app roadmap list --json omits the rating columns, while the
canonical planner already reads/ranks DB ratings. Therefore weekly must not invent
another scoring engine or parse display text. Extend that existing JSON reader with
RATING_COLUMNS and a canonical rank field derived exactly as its human reader; reuse
the authoritative Marathon planner for selection. Existing rows are never re-rated,
re-promoted or marked complete based on GitHub state; preserve all GIDs/status/ovr.
New rows stay provisional/unrated until independently assessed. Canonical capture
renderer is utils/hq/hq-lib.sh::hq_render_capture; no new capture template.

Implementation design, pending independent plan QA:

1. Keep writes in an opt-in weekly-prepare policy path in existing planner_core.
   Shared issue_intake retains read/normalization mechanics. Require explicit
   planning date, repository, target ref, since bound and initial backfill choice;
   no timezone, budget, thresholds, dispatch or scheduler defaults. Weekly preparation
   is local only; no automatic push. All output remains HELD.
2. Refuse linked worktrees/bare repos, dirty unrelated state, mismatched origin and
   unresolved canonical writer journal. Use existing Git-dir resolution and a single
   nonblocking planning lock in this full clone. Preserve primary/source checkouts;
   changes occur only in the explicitly supplied isolated preparation clone.
3. Create/resume auto-yyyy-mm-dd from the exact refreshed canonical target SHA.
   Preserve every prior complete member, explicit carryover/dependency and current
   relevant observation. Initial open-backfill must paginate all open issues;
   no partial failure advances a durable checkpoint. Cross-repository/ambiguous
   dependencies hold rather than silently disappear. Unknown acceptance stays held.
4. Inspect canonical ledger through sanctioned reader APIs; reject duplicate or
   foreign identity conflicts. For missing captures call hq_render_capture with
   argument-array subprocess invocation (no interpolated shell code), then roadmap
   add via releases_app CLI with XYZ_WORK_CONNECTORS=0. Preserve existing captures
   byte-for-byte and existing rows untouched. Updated issue bodies remain durable
   observation evidence, not destructive replacements of owner-authored docs.
5. Check ledger generation/target/branch before and after each sanctioned write and
   before committing. Canonical writer lock/journal owns DB crash recovery; weekly
   keeps a scoped partial-progress receipt so retry can reconcile successful additions
   without duplicates. Concurrent/unknown owner edits hold instead of blanket reset,
   DB replacement, forced rating, or unsupported automatic merge-rebuild.
6. Commit only durable canonical captures/DB/dump and the complete weekly observation
   accounting. Stable content excludes a fresh observedAt from no-change comparison;
   unchanged input produces no commit. Advance high-water/checkpoint only after all
   observations have canonical accounting and the commit succeeds. Preserve failure
   evidence and checkpoint; failed inputs never become complete or dispatchable.
7. Read-only dry preview enumerates intended writes; applying in manual verification
   writes local fixture branch/captures/DB/dump/checkpoints and those effects must be
   disclosed. No actual user's planning branch or live connector writes during
   verification. No executable weekly artifact, freeze, approval or fire is inferred.

Verification: existing releases/ledger/capture suites where applicable in disposable
full clone; isolated recorded manual controls for repeated/no-change runs, new+updated+
reopened+closed membership, preserved GID/rating/ovr/owner doc, incomplete discovery,
failed write/commit and recovery, lock contention and concurrent generation changes.
No individual CI test/case is proposed or added. Independent plan and final QA use
only the already authorized Codex relay harness; no extra advisor agents.

Open policy inputs are explicit invocation requirements, not guessed permanent policy.
Remaining W8–W11 executable construction, required-CI/dependency readiness, immutable
freeze/exact approval and shared fire/phase/resume/landing protocol stays required.
