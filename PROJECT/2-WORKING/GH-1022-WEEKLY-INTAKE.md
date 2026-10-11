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
phases: 5
goal: Reuse shared discovery for a held weekly proposal without importing unattended execution policy.
---

## Status

| What was just completed | What's next |
|---|---|
| Canonical override reader published6e6db879;plan/finalQA Approved,fullgate409/409,hosted smoke passed. | W7 qualified work reconciliation;remaining W8–W11 readiness,freeze/approval and shared safety. |

## Table of contents

- [Phase 1 — Discovery and compatibility](#phase-1--discovery-and-compatibility)
- [Phase 2 — Shared extraction and held preview](#phase-2--shared-extraction-and-held-preview)
- [Phase 3 — Verification and draft](#phase-3--verification-and-draft)
- [Phase 4 — Canonical branch accumulation](#phase-4--canonical-branch-accumulation-active-design)
- [Phase 5 — Canonical planner override reader](#phase-5--canonical-planner-override-reader-w8-prerequisite)
- [Remaining acceptance](#remaining-acceptance)

## Bet and scope

Outcome: complete issue observations shared by weekly and 10days, without importing
10days' auto-fire policy. Smallest viable staged bet: one harness-owned issue_intake.py,
thin existing shell adapters, and an explicit read-only weekly-intake preview in the
existing planner core. The new weekly skill describes the held preparation entry point.
This PR delivers shared discovery and held local accumulation; umbrella #1022 remains incomplete. The entire workflow is held
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

Issue phased checklist: characterization/extraction are implemented; shared core now
supports observations and local canonical accumulation with separate policy/effects.
Existing/manual controls cover this stage. Authoritative selection and execution
policy differences remain held; no umbrella completion/closure claim.

Architecture checklist status: local auto-* full-clone creation, scoped lock, complete
canonical accounting, owner preservation and commit-bound checkpoint/recovery are
implemented in Phase 4. This does not establish published-branch rollover/concurrent
integration or global one-run coordination. ALL relevance depends on explicit
backfill/prior-member inputs; dependency expansion remains unimplemented. Active
Marathon/Jog/PR decision accounting, authoritative bounded artifacts, draft/required-CI/
unmet-dependency readiness, freeze/drift invalidation, exact operator approval and
shared boundary enforcement remain required W7–W11 work. Unknown canonical journals
and remote existing planning branches hold for explicit sanctioned reconciliation.

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
- [x] Phase 3 foundation final QA/gate/publication — ca4c9b5a review; draft1024 at d7ef2bc9; hosted38156666103 smoke passed.

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
the authoritative Marathon planner after a separately reviewed rank-contract correction.
Current _marathon_plan.py ignores rating_ovr (witnessed 320 override → 210 sum);
selection remains HELD until W8 fixes that canonical-owner gap. This accumulation
phase exposes truthful rank through the existing reader but does not repair or
substitute planner selection. Existing rows are never re-rated,
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
   Existing branch base differing from refreshed target holds: report both SHAs,
   retain branch/checkpoint and require explicit reconciliation; no automatic rebase
   or merge-rebuild. Use PROJECT/4-MISC/weekly/<planning-date>/intake.json for committed
   accounting and the clone Git-dir weekly-<planning-date>.json for local recovery.
   Checkpoint cut is run-start UTC with caller-supplied inclusive overlap; unchanged
   runs retain the old cut and commit.
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

### Phase 4 plan round 1 dispositions

Should implemented in design: authoritative planner currently ignores overrides; expose canonical reader rank and hold selection until separately reviewed W8 owner correction. No weekly scorer. Nit implemented: target advance on resume holds preserving branch/checkpoint, paths and run-start/overlap cut explicit; frontmatter/TOC/status reflect active phase. The observed rank probe is source-grounded; no actual override-free run was recorded in that reviewer turn. Add such a manual control during W8 verification. No source behavior claimed or changed by this disposition.

## Phase 4 implementation and verification (in progress)

Implemented existing-core weekly-prepare policy with explicit inputs, disjoint new/
owned full-clone preparation, clone-local lock, canonical capture/CLI registration,
owned partial intent and generation checks, and commit-before-complete checkpoint.
Shared URL comparison preserves legitimate stored repository casing. Canonical
reader exposes truthful rating axes/override/calc/rank; existing owner rows/captures
are preserved. No source planner rank repair, scoring engine, execution artifacts,
freeze or dispatch authority ships in this phase.

Manual controls in /tmp use sanctioned CLI fixtures only (no direct fixture SQL),
GH responses stubbed and connectors disabled. Initial 22 passed; expanded controls
include unchanged receipt bytes/mtime, malformed receipts/observations, symlink
capture and concurrent owner rating changes. The first concurrent injection failed
because macOS temporary paths had two filesystem aliases: callback count 0. Resolve paths in the
fixture; actual injection count 2 then held and preserved changed owner override.
A mixed-case canonical owner URL reproduced a false foreign hold before the shared
case-normalization fix; owner stored URL stays unchanged. Retain these breadcrumbs.

Known limits remain active: existing remote planning branch and advanced target
hold for explicit reconciliation; clone-local lock is not cross-clone coordination;
unknown canonical journals require sanctioned stopped-owner recovery; dependency
expansion/global active-run accounting, authoritative selection/rank correction,
freeze and shared criterion/fire/phase/resume/landing protocol are unimplemented.
Final phase-source QA, exact tier-2 gate and PR update remain pending. No new CI
case/test/parametrization/registry/gate or operator approval inferred.

### Phase 4 final QA round 1 dispositions

Two source-boundary blockers reproduced manually in disposable full fixtures:
rating-like issue title assigned axes/override; canonical rating change at staging
produced stale accounting with a complete checkpoint. New-title validation now
uses the canonical parser and holds before registration without changing existing
rated rows. The final no-op/check/stage/commit boundary holds canonical WriterLock,
checks target, branch/HEAD and generation, validates staged and committed object
bytes and keeps incomplete receipts on any mismatch. Existing writer lock/audit
sidecars are local effects. No canonical transaction is called inside that lock.
Provenance now binds accumulation artifacts and exact source hashes/attribution.
The first review transcript contains concrete FAIL findings but no attestation:
producer refreshed a manual evidence file during review; containment reverted it.
Its saved bytes and review are preserved. Round 2 will use a fixed input tree.
Whole-module releases CLI direct source sweep is still required before approval.

### Phase4 final QA round2 disposition

A capture edit during observation persistence reproduced a stale complete receipt
on f4dba01f. Bind SHA256 accounting and expected Git blob to one immutable byte
snapshot, also requiring owned creation intent; staged/committed/live checks retain
that original object. Candidate holds before commit with the owner CRLF edit
preserved. Fresh pre/post-commit target checks hold drift and preserve post-drift
commits without completing checkpoint. Existing classified f4 gate passed28/28
selections incl24 release suites; final source gate and QA3 remain pending.

### Phase4 final QA3 escalation and concrete repair

All6903 release-owner source lines swept. Accumulation blockers passed the reviewer
controls, but a preexisting release cmd_update reads before writer lock then uses
stale fallback fields in its full-row update. Actual second-process canonical
update reproduces owner codename loss. Minimal repair compares the validated row
inside existing perform_write's transaction and refuses release-update-stale,
preserving the owner row; quiet updates still succeed. Canonical fixtures check
clean. This repairs the observed existing writer boundary, not a new framework.
Review3/3 remains Escalated; no Approved attestation,cap reset or replacement
review. Operator decision is required for further review after late-fix existing
verification. d0bc final gate passed28/28 before this five-line repair. W7–W11
remain required active work, not implicitly waived by staged publication.

Late repair verification complete on bc934d52: existing classified gate28/28
(incl24 release suites andPython21),gh36914/14,canonicalcheck clean,inventory
unchanged,AST/diff checks pass. Refreshed36 accumulation controls pass. No new
CI cases or proposed test approvals. Parent requested one additional existing
Codex review;operator approval pending,cap3/3 preserved. Review target will be
the evidence-only commit carrying these results;source hashes equalbc934d52.
No held-source push and no whole#1022 acceptance claim.

Operator authorized exactly one additional accumulation review; same artifact
extended to4/4 preserving all3 failures and original escalation. Round4 at84d6e53b
FAIL: release-update fix and final-source evidence passed, but whole-file sweep
found preexisting roadmap-rate restoring stale raw_text after canonical repoint.
Actual second-process writers reproduce old document-link loss. Narrow repair
checks the full selected row inside existing transaction and refuses roadmap-rate-stale
before writing, preserving owner text/path. Quiet and deliberate force controls
pass; six old/candidate controls and canonical checks clean. No new CI cases.
Existing exact-source verification pending; cap4/4 Escalated, no extra review or
approval attestation. W7–W11 remain active; no umbrella completion or held-source
publication. Further independent review requires explicit operator cap decision.

### Consolidated stale-snapshot writer diagnosis (producer, no new review)

Parent requested same-class diagnosis before another cap decision. Directly
checked perform_write, roadmap add/rate/repoint/update/move/reconcile-state/sync,
canonical release update and weekly prepare's accounting boundaries. Real
second-process controls show rate and repoint both derived replacement raw_text
before the lock and could erase each other's owner text. Both now compare the
full selected row inside BEGIN IMMEDIATE before writing; no new protocol/helper.
Release update already has its equivalent guard from Round3.

Real controls: quiet repoint succeeds; intervening rating/override399 is preserved
by named repoint stale refusal; marker-only update and move after repoint preserve
WORKING doc_path/raw_text; concurrent add keeps exactly one GID via existing
UNIQUE(repo_id,gh_number), with transaction rollback for the losing add. Its
IntegrityError is nonzero rather than a named duplicate; changing that UX is not
required to preserve state. Explicit raw_text update intentionally replaces caller-
specified text/rating; marker/section/URL-only writes never fill unrelated columns
from old snapshots. Accepted-start and reconcile-state already re-read full rows
inside the transaction and refuse stale snapshots (source review; no new native
lookup execution). Legacy roadmap sync skips in releases mode; legacy mirror
concurrency is outside this weekly branch policy and was not enabled or repaired.
Settings set writes explicit values only. Release ship/manifest/import/rebuild and
Jog execution are outside this planning write-set and were not claimed race-free.
No general CRUD concurrency guarantee follows from this bounded diagnosis.

Weekly uses add for new rows and preserves existing rows; final canonical WriterLock,
full-row/generation/target/accounting guards hold concurrent owner changes. Cross-clone
coordination and remote rollover remain unimplemented. Smallest justified next
review is these two roadmap stale-row guards plus their mutual-interleaving,
quiet/force/partial-field controls, prior release guard and exact-source existing
gate evidence, within the same held accumulation contract and repo whole-file rule.
Cap remains4/4 Escalated; no independent review is dispatched or inferred.

Consolidated exact source a0b484b5adaca6f959d30ebe6694d3d8d3905cfe:
final existing classified gate exit0,28/28 including24 release suites and
Python21/21,docs/static/clone identity;not promotion. Final gh36914/14,
ledgercheck clean0failures9existingwarnings,unchanged inventory clean,4AST/whitespace
checks pass. 36 accumulation,6 rating/repoint,10 same-class and4 protected-writer
controls have matching final source hashes and retained witnessed old-source
failures;all canonical fixture checks clean. Native reads for protected paths
stubbed,no actual GH reads or connector writes. Temporary drivers not added to CI.
Disposable clone retains canonical origin/HEADa0b484b5 and clean tracked tree;
primary cleana5837828/development. Remote base remainsf1225359,draft#1024 remains
foundationd7ef2bc9. Both narrow roadmap guards are complete for the observed
mutual snapshot overwrite;general all-CRUD concurrency not claimed. See committed
writer-diagnosis-final.json for path coverage,remaining limits and next review scope.
Same artifact remainsEscalated4/4;no further review authorized/no attestation.
Publication held;W7–W11 required active,umbrella incomplete. Next action requires
explicit operator cap decision for this consolidated same-artifact review scope.

### Scoped Round5 approval and publication disposition

The user authorized exactly one further review plus issue filing for concrete
findings below High before normal gated draft publication. All four earlier FAIL
rounds preserved;same artifact5/5. Independent Codex R5 PASS/Approved attested
exact reviewed e016d29a,whole-file sweep and source-bound in-memory witnessed reds;
no unresolved Critical/High and no new actionable lower finding. High owner-loss
impacts were fixed,not downgraded. Therefore no follow-up issue created this turn.
No clean-verdict fabrication or repo-wide policy change. Source hashes still equal
verified a0b484b5;normal push gate will check the final evidence/documentation commit.
This is limited held accumulation approval. Full umbrella W7–W11,global clone/
remote planning lifecycle,canonical planner override/readiness,freeze/exact approval
and shared fire/phase/resume/landing safeguards remain required and unimplemented.
No merge,deployment,installation,schedule,live execution or new CI test authorized.

Reviewed held stage published at4770f091 to existing draft1024 through normal
tier2prepush (GREEN315s,28/28) and hosted38178591497 exactSHA smokeSUCCESS.
Promotion/portabilitySKIPPED,notqualification. No merge/newtest/liveexecution.
This fulfills staged publication only;remaining umbrella checklist stays active.

## Phase 5 — Canonical planner override reader (W8 prerequisite)

Active genuinely new scope after accumulation R5 closed Approved; do not reopen
that review or reuse its cap. Canonical remote development remainsf1225359 and
published branch31ba903e;no intervening target/source change. Current issue1022
body/comments reread;four other open PR write-sets have no planner/reader overlap.
Search found historical DB-planning umbrellas,not equivalent delivered override
support. Existing `_load_ledger_from_db` SELECT omits rating_ovr and sums axes.
The actual-reader in-memory observation gives210 for owner70/65/50/25,ovr320,
including a NULL-gh/doc-only row. This fails the owner-override requirement.
Ordinary210,partial/unrated holds,old sparse schema and duplicate doc identity
already work and must remain unchanged;not eligible for rewriting as new work.

Reuse `releases_app.roadmap_rating_view`,the reviewed canonical reader projection.
No weekly scorer or copied arithmetic. `_marathon_plan.Engine._load_ledger_from_db`
feeds DB rank/axes to existing score_of (rank negation plus existing dependency/
zone/gated adjustments),wave packing and rendered Per-item scoring. CLI wrapper
marathon_plan.py selects that authoritative Python engine;frozen Bash fallback
remains unchanged. Reader does not rate/write the ledger or grant readiness.

Bet: owner overrides should determine canonical rank wherever this existing reader
already consumes fully-rated canonical rows. Easy rollback: revert only the reader
seam;no schema/data/dispatch change. Blast radius is Python ledger-derived rank and
ordering for fully-rated override rows,both numbered and doc-only. Ordinary ranks,
legacy Markdown mode,identity/ambiguity rules,score adjustment and packing remain.
A weekly-side override scorer was rejected because it would compete with the owner.

Ordered implementation and acceptance:
1. Preserve the existing required eight-column query and identity positions. Add
   the optional override via existing canonical schema inspection,with NULL alias
   for historical fixtures missing only rating_ovr. Missing required columns must
   still follow the existing read-error behavior. Use shared projection for rank;
   preserve existing integer axis conversion for fully-rated rows rather than
   silently changing historical numeric-field behavior. No second schema layer.
2. Route fully-rated numbered and uniquely resolved NULL-gh/doc-only rows through
   canonical effective rank. Owner70/65/50/25+ovr320 becomes320;no-override210 stays.
   An override on partial/unrated rows must not invent readiness. True duplicate
   doc/title identities still resolve to ambiguous GIDs with no rank/axes.
3. Verify with existing gh698-planner-db-ratings.sh,marathon-plan.sh and covering
   CLI/frozen-twin checks in disposable full clone. Record source-bound in-memory
   actual-reader before/after controls including missing optional column,identity
   ambiguity and partial/unrated scores. Retain witnessed210vs320 failure. A safe
   isolated full-engine fixture may write local reports/temp plan docs using existing
   fixture seams;disable connectors/stub GH,never invoke driver/live dispatch.
4. Final Codex whole-file QA of changed engine/source/evidence under its OWN normal
   three-round cap. Keep all earlier accumulation rounds unchanged. Run the existing
   classifier's final required route at approved source,then update existingdraft1024
   only after verified review/gates. No new test/case/parametrization/gate/framework.

Not delivered by this slice: weekly selection/promotion,required-CI/draft/dependency
policy,closure/Completed delivery proof,active/global-work/branch lifecycle,immutable
freeze/exact approval,criterion HEAD/plan receipts and pre-fire/phase/resume/landing
checks. Those remain required W7–W11. Weekly stays HELD;no Marathon/Jog generation
or dispatch is authorized by this reader repair. No production ledger writes,
new tests,installation,scheduling,merge/deploy or unrelated issue closures.

Phase5 baseline refreshed with actual AST reader and SQLite in-memory fixtures:
10 controls,exactly two owner-override210vs320 failures;ordinary,partial/unrated,
NULL-gh,duplicate-doc,missing optional column,historical text axes andmissing
required-column exit3 controls retain current behavior. Renderer/parser stubbed;
no filesystem DB or full-engine action. Existing classifier maps this engine as
unmapped tier3/full;final required full gate belongs after final Approved source
at normal push boundary,not repeated during plan/text rounds. No gate-policy edit.

Phase5 plan QA R1 Approved at45d55239;cap3 not extended. Nit disposition:
retain/disclose preexisting _rating_num display1..5 limitation;no renderer change
or newtest. Reader now uses canonical effective rank,required query/optionalNULL
alias and historical int conversion. One existing weekly hold reason and skill
status are updated to avoid falsely claiming the omission remains;HELD shape,
policy/dispatch and other algorithms unchanged. This diagnostic/status correction
will be covered in final QA and refreshed accumulation controls,not capability
promotion. No source code before approved plan;already-active owned admission
confirmed by canonical accepted-start returning original-start preserved.

Phase5 candidate da603c70:10/10 reader controls pass;full actual engine in
isolated canonically-created fixture changes owner ordering778,777→777,778 and
rank210→320,while DB/dump bytes stay identical. GH/native reads/branch inventory
stubbed;full-engine report files and fixture canon ledger/receipts/Git commit were
local writes,not live dispatch. Existing disposable-clone gh69816/16,
marathon-plan70pass0fail2establishedskips,gh3629/9;cloneHEAD/origin/trackedstate
unchanged. Refreshed accumulation36/36 after diagnostic update. FourAST parses
and source hashes retained;no CI tests/cases added. Existing display limitation
above5 still dashes,canonical ledger retains realaxes;no renderer fix claimed.
Final whole-file QA and required full gate remain pending,no newstage publication.

Phase5 final Codex QA R1 PASS/Approved exact4be47217,whole1498engine/1318core
sweep,independent in-memory current-reader probes and source/provenance hashes.
Retained display Nit disclosed,not behavioral expansion. Full classifier-required
gate pending at normal push boundary;focused evidence not qualification. Accumulation
review remainsclosed. No tests added or operational/umbrella approval inferred.

Phase5 source published6e6db879 via unchanged normal full prepush:409/409,
Python21,envelope clean,GREEN821s,no bypass. Hosted38181222495 exactSHA
completedSUCCESS: blocking smokeSUCCESS,macOS/ubuntuSKIPPED,nottested/green.
This is full local self-check,not ci-local/macOS promotion. Owner task ledger
progress updated through canonical CLI with allrating/override/GID/status/doc
fields preserved,connectorsdisabled;canonical checkclean. Proof/progress commit
is code-identical and takes normal docs/ledger gate. Phase5 prerequisite done;
W8 overallnotdone andW7–W11remainactive. Next independent Jog reader identity
scope is grounded in actualbare-GH joinfailure;observerPR1017 remainsowned.
