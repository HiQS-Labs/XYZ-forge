---
gh_issue: 1022
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1022
title: "Weekly issue intake and approval-bound planning"
status: In progress
created: 2026-10-11
updated: 2026-10-12
owner: Codex
doc_type: feature
effort: 4
complexity: 4
risk: 3
phases: 7
goal: Implement shared weekly intake, bounded canonical planning and exact approval safeguards without enabling live execution.
---

## Status

| What was just completed | What's next |
|---|---|
| Phase6 publishedbc4/d09, sourceQA Approved3/3, normalfull409/409+Python21/830s, correctedUbuntu407/407 inclgh123 andsmokeSUCCESS. CurrentdraftMERGEABLE/CLEAN onverifiedsnapshot. | W7 declared-work census recon/plan ready; normalnew-scope planQA then implementation. W7–W11 active; R6FAIL6/6/Medium1028 retained, #1027 tests unapproved. |

## Table of contents

- [Phase 1 — Discovery and compatibility](#phase-1--discovery-and-compatibility)
- [Phase 2 — Shared extraction and held preview](#phase-2--shared-extraction-and-held-preview)
- [Phase 3 — Verification and draft](#phase-3--verification-and-draft)
- [Phase 4 — Canonical branch accumulation](#phase-4--canonical-branch-accumulation-active-design)
- [Phase 5 — Canonical planner override reader](#phase-5--canonical-planner-override-reader-w8-prerequisite)
- [Phase 6 — Qualified canonical Jog observations](#phase-6--qualified-canonical-jog-observations-w7-prerequisite)
- [Phase 7 — Canonical declared-work census](#phase-7--canonical-declared-work-census-next-w7-prerequisite)
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

## Phase 6 — Qualified canonical Jog observations (W7 prerequisite)

Observed failure: current cmd_jog_list LEFT JOIN uses only gh_number. A legal
in-memory fixture with one Repo A queued GID and Repo A/Repo B roadmap issue777
returns that queue GID twice, including Repo B title/doc/issue URL. Snapshot
consumers cannot use that as qualified global-work evidence. Fix in the owner;
no weekly-side shadow queue reader/scorer. Source app hash09384ac9,real AST query
probe retained outside CI. Existing connect already refuses a missing DB;
that protection is delivered,not a new implementation claim.

Small coherent change: reuse one canonical row reader from legacy list and a
new explicit `jog list --inventory-json` read-only view. Canonical supported
schemas join roadmap on BOTH repo_id/gh_number. Default human/--json outputs
retain fields/filter/order and missing-table[] behavior;the qualified join fixes
the legal canonical collision. Unsupported legacy schema stays advisory in
legacy viewer and is UNKNOWN in inventory,not silently migrated/guessed.

Inventory is opt-in metadata over the existing queue,not a second backlog:
initialized/read_complete,generation,qualified repository + stable repo/queue
GIDs,all old row fields,held reasons and explicit no-dispatch. `--all` remains
explicit and required by weekly consumers so terminal/carryover rows are read.
Missing DB/table/required identity fields,invalid generation,live canonical
journal or generation change => nonzero UNKNOWN;never success-empty for
unsupported state. Use existing schema/settings/journal helpers. An optional
read-only connection mode extends existing connect without changing writer or
legacy default behavior. No initialize,migrate,recover,lease,signal,write,fetch,
push or connector action;SQLite read-only URI and existing must-exist guard.
Read completeness describes this declared root's snapshot,not integrity review,
criterion delivery,global quiescence or execution/landing approval.

Before/after manual controls: Repo A/B same issue identity,unregistered queue
row,default output/filter/order compatibility,real initialized empty vs missing
schema/missing DB(no creation),canonical generation/journal drift,read-only
mutation refusal and unchanged artifact bytes. Existing jog-queue/gh280 and
covering release checks run in disposable full clone;no new CI test/case/flag
registry/gate. Whole owner-file QA under a new normal cap3 and mapped finalgate.

Easy rollback: revert owner read API/query only;no data/schema migration.
Existing canonical queue/write/lease ownership unchanged. No default policy or
parallel orchestration. This unlocks a subsequent shared-intake adapter using
qualified observations;it does not itself select/register execution work.

Remaining W7 global aggregation/authority roots,branch lifecycle/rollover/PR
routing andlater W8–W11 stay active. Marathon observer path repair landed in
PR1017;consume its owner and avoid duplicate repair. Future reconciliation must
consume canonical observations and hold unavailable/conflicting state,not infer
completion from queue/PR/ledger markers or cancel live work. No live execution,
scheduling,installation,merge/deploy or newtests authorized.

Concrete intended shape: default `jog list`/`--json` retain their field set,filter
andordering,with repository-qualified join on supported canonical schema. One
shared owner query feeds opt-in inventory metadata (including repository slug,
repo/queue/ledger GIDs where available). New inventory must use SQLite readonly
mode;extend existing connect with optional readonly argument,default unchanged.
Existing must-exist guard remains. Snapshot uses existing schema/settings/journal
helpers to distinguish initialized empty from unsupported/missing state and
refuse live journal or generation drift without recovery. It must not borrow
get_generation's invalid-value→0 fallback as proof of a stable generation.
No unsupported legacy schema migration or invented identity. Missing optional
ledger row stays observable as unregistered work rather than dropping the queue.
Metadata explicitly describes one caller-declared root;not global integrity,
quiescence,criterion delivery or execution approval. Shared intake/caller policy
integration is the next step,not falsely claimed by this owner-read seam.

Ordered acceptance: (1) qualify supported join andpreserve legacy output;RepoA/B
same issue777 yields one RepoA queueGID/metadata. (2) opt-in readonly inventory
exposes stable ownership andinitialized/read_complete/generation/held reasons;
invalid schema/generation,journal/drift yields nonzeroUNKNOWN,no create/migrate/
recover/signal/connector operations. (3) safe in-memory andcanonically-created
fixture controls for ownership,unregistered rows,emptyvsunknown,defaultparity,
readonly mutation refusal,missingDB andunchanged bytes;existingjog-queue/gh280
checks in disposable fullclone,no newCItests/cases. (4) own normalplan/finalQA
cap3,mapped finalgate andverified draftupdate,not old accumulation review reset.

No need for a second queue,DBwriter,backgroundwatcher ornew checker/gate. Easy
rollback: owner query/view/optional connection mode only;no data/schema migration.
W7 broader aggregation/authority roots,branch lifecycle/rollover andPRrouting,
W8 construction/readiness,W9–W11 approval/sharedsafety remainrequiredactive.
#1017 observer repair landed;do not duplicate its pathrepair orpretend a
complete Marathon inventory hasbeen obtained. No live Marathon/Jog,merge/deploy,
installation,scheduling ornewtest authorized. Production was unchanged at that original plan draft; the resumption below records the subsequent implementation.


## Claude review remediation — current disposition and review boundary

External COMMENTED review at 31ba903e3e75de4a8fd44b28b20db003f350bbbe:
[full summary](https://github.com/HiQS-Labs/XYZ-forge/pull/1024#issuecomment-6114773074),
[inline review](https://github.com/HiQS-Labs/XYZ-forge/pull/1024#pullrequestreview-5485368258).
Current published source is 7d0bd85e19cccd81cf6cce060b1027a1c8bb49fc;
local pre-correction HEAD 9eadca0aa74ac8e2a9040c308e38709392cd5d38 adds only
Phase6 plan/evidence. Full findings and inline comments were read before fixes.
The completed accumulation R5 (5/5 Approved) remains closed, unchanged. It cannot
attest these changed bytes. Additional corrective final review authority is pending;
no new review dispatched, cap reset, final qualifying gate or corrective push.
The operator explicitly directed continued feasible producer remediation; the
runtime/IO repairs below reuse the documented existing mechanisms. No independent
pre-implementation review or fresh Approved claim is inferred from that direction.
Phase6 is paused; no Jog owner implementation or QA has started.

| ID | Disposition / observed impact |
|---|---|
| S1 | Fixed locally: a complete source/vendor runtime uses its own shared helper and canonical owners; separately copied skills use the central locator. Inherited stale valid hints no longer redirect a complete source bundle away from its tested bytes. Independent final qualification remains pending. |
| S2 | Fixed locally: preparation records actual planner/intake/writer/renderer/process-runner resolved paths and SHA256 bytes, checks drift before effects/reads/commit boundaries, and binds them into local receipts. Runtime observations remain distinct from target HEAD and execution approval. |
| S3 | Valid rollout limit. Explicitly documented consistent helper/Python3/harness update prerequisite and old-vendor failure; no deployment or vendor writes authorized/performed. |
| S4 | Fixed locally: qualified identity stays lowercase while the validated observed GitHub URL retains canonical casing. Actual canonical registration retains Fixture/Repo URL, existing owner rows unchanged. No global URL rewrite. |
| S5 | Fixed locally: reuse dry inspection to validate the whole batch before any capture or registration. Rated third title and malformed createdAt reject without earlier new rows/files; corrected title resumes successfully. Per-member drift checks remain. Already-partial unknown clones remain preserved, not silently reset. |
| S6 | Fixed locally for witnessed metadata noise: omit only check URLs/start/completion times from durable accounting comparison, return fresh full PRs on every call including no-op. Keep result/draft/review/mergeability/head/body/files/unknown changes material. No current approval-invalidation policy decision is needed because accounting is HELD and grants no execution authority; future frozen approvals still require fresh full evidence. Actual delivered-work execution no-op remains unimplemented. |
| S7 | Fixed locally: default weekly commands reuse utils/py/proc_group.py run_bounded with60s IO ceiling/1s termination grace. Actual slow hook/remote controls terminate owned resistant child groups, release locks and retain retry receipts. Normal hooks/signing and fresh target reads remain active. Copied locator startup and legacy modes are outside this scoped command change. |
| S8 | Valid CI coverage gap; permanent drivers/tests not authorized. Three individual cases proposed in [#1027](https://github.com/HiQS-Labs/XYZ-forge/issues/1027), each separately awaiting operator approval. Existing tests unchanged. |
| S9 | Fixed locally as a clean locked refusal. Canonical race reproduced a SQL IntegrityError; existing write-once trigger preserved baseline1 rather than overwriting it with2. Current transaction rechecks live GID baseline and manifest before capture; automatic activation and SQL trigger unchanged. Claimed current data loss disproved. |
| N1 | Fixed locally in the two intake loaders: an unavailable/incomplete explicit harness hint refuses clearly before fallback. Shared locator semantics remain untouched. |
| N2 | Fixed locally: missing/invalid private adapter mode returns usage/rc2 before lookup, without traceback. Existing scan/find wrapper interfaces unchanged. |
| N3 | Lost-root-check race reproduced: another initializer finishes between absent-root check and clone; losing git clone refuses nonempty directory, winner HEAD/complete receipt and clean state remain intact. Existing writer lock/HEAD checks protect resumed clones. Added bootstrap framework rejected absent a failing preservation case; normal loser refusal is acceptable. |
| N4 | Broad generic SQL guard refactor rejected: independently named stale-row predicates preserve existing writer transactions and validated row contracts. The new baseline refusal includes GID. No policy weakened to remove guards. |
| N5 | Valid historical provenance defects: append-only audit identifies19 missing revision fields and8 stale artifact hashes in98 original rows;7 old blobs remain recoverable,1 original log not found. Exact storage links provided; unknown tested revisions remain unqualified, not fabricated. Original history preserved. |
| N6 | Historical log deletion/compression rejected for this corrective scope: hashes/attestations refer to those immutable artifacts. New summary indexes current relevant controls; no duplicate permanent replay driver added. |
| N7 | Historical evidence path redaction rejected because it changes bound bytes. Paths are not secrets; future source-hash keys use repo-relative names. No unrelated content/secrets inspected. |

The four local source corrections are deterministic repairs to existing reviewed
contracts (qualified identity, no partial deterministic input writes, named CLI
refusals, usage errors), rather than new orchestration policy. Easy rollback:
revert the corrective commit; no schema/data migration or deployed state change.
Before/after controls use actual modules and canonical second-process writers in
temporary independent repositories. Their init/add/rate/capture/receipt/commit
writes are local fixture effects; GH/target transport is stubbed, connectors off.
Existing36 accumulation controls and focused gh32(145/145),gh69(85/85),gh369(14/14) pass on exact corrective source41f225bd8726499c999184162037d1fd826140a1 in the disposable fullclone. Corrective source remains unpublished and independently unreviewed.
No tests/cases/parametrizations, CI registry, gate or policy weakening added.

### Corrective producer contract (S1/S2/N1/S6 and S7)

Outcome: entry-point verification identifies the executable bundle actually used,
and a stalled command cannot hold an owned preparation writer indefinitely.
Smallest bet: a complete repository/vendored source bundle uses its own sibling
intake and canonical writer/renderer; a separately copied skill uses the existing
locator. Validate malformed explicit overrides rather than treating them as
absence. Preserve scan/find defaults and fail clearly on an old missing-helper
vendor. Record actual core/intake/writer/renderer/process-runner file hashes in
local preparation receipts, and recheck those bytes before each side-effect and
final commit boundary. Do not claim target HEAD identifies external runtime code,
execution authority or protection against adversarial change/revert sequences.
Use the existing process-group runner with an explicit mechanical IO deadline
for default weekly preparation commands, including remote reads/hooks; preserve
normal hooks/signing and immediate fresh target checks. Injected fixture runner
contract remains unchanged. Timeout returns held/unknown and preserves partial
state, with no surviving owned child group. Legacy planner modes remain unchanged.

Producer work under the operator's continued remediation direction: (1) review loader
ownership/override/copy/old-vendor contract with current sources; (2) implement thin
loaders and actual-runtime pins, verifying inherited stale override, standalone
copy, old vendor and changed code boundary controls; (3) extend only default weekly
IO through proc_group, verifying a slow owned process group times out and releases
locks without bypassing hooks/signing; (4) run affected existing suites in the
disposable clone and independent corrective final QA, then classified final gate
and exact-SHA draft publication. No separate discovery scanner or orchestration
framework. PR1026 c1a0e543fb79a1e405ec962b6dba289f9d00c3e8 owns start-task prior-art
merged/issues/sibling/REST work; its scanner and skills remain untouched and its
landing is not assumed. PR1017 observer ownership also remains separate.


S6 decision clarification: the current file is held canonical accounting, not an
operator-approved freeze. Therefore filtering known check locator/time noise is
an ordinary in-scope no-op correction, with fresh full PR data returned separately.
Alternative1 retains every run URL/time as material (safe but needless commits).
Chosen alternative2 ignores only four known locator/time keys, preserving all
readiness/result/unknown fields as material. Alternative3 ignores actual CI,
review or mergeability transitions too; rejected for this scope because it needs
an approval-invalidation contract and stronger fresh-evidence boundary already
required in unimplemented W9–W11. No operator policy waiver is sought or applied.
The narrow outstanding operator decision is one consolidated corrective final
review authorization after producer verification, preserving the closed R5.
No S8 individual CI test is approved by that review authorization.


Consolidated producer checkpoint1044969dcad23a08e19219e3fb195d58715187d4:
S1/S2/S4/S5/S6/S7/S9/N1/N2 corrected locally;S3 rollout documented,S8
individual test approvalsheld atGH1027. All19runtime,36accumulation,20
discovery/parity controls pass;S6metadata no-op/freshness plus9material-change
controls pass. Existinggh32 145/145,gh69 85/85,gh36914/14 clean+stalehint,
Pythonlayer21/21 pass in clean disposable clone at exactsource1044969d.
Canonical ownGID progress updated;all otherreturned ownerfields preserved,
checkclean0failures9warnings. Sourcehashes unchanged bythis evidence/progress
checkpoint. No otherreview,fullqualifyinggate,push oroperator-policy waiver.
The narrow nextdecision is oneconsolidated corrective finalCodex review,without
resetting orreusing oldR5 approval forchanged bytes. S8tests remainunapproved.


## R6 actual result and permitted publication disposition

Exactlyone additional corrective Codexturn wasexplicitly authorized andcompleted
inexistinghistory:Reviewercommit301b0e4b,FAIL/STATUS Escalated6/6,driverexit4.
Wholeowning-file sweep completed. No unresolvedCritical/High wasestablished;
allpreviousHighowner-integrity repairs remainpresent. This isNOT Approved.
Singleallowance exhausted;no secondreview,capreset orfakecleantag.

S5 retainsoneMediumShould:batchinspection omits exactcanonicalraw_text/Markdown
titlegrammar. Actualtemporaryfullclone replaywithordinary issue2 andtitle
`Fix * retry` issue3 confirmsdryaccepts,beforeapplyregisters2/createscaptures2+3
andcanonicalCLIrefuses3. Existingowner row/GID/ratings/docbytes remainidentical,
complete_commitnull,dispatchfalse. This isavoidablelocalpartial preparation
requiringreconciliation,not observedownerloss ordispatch. Follow-up
[GH1028](https://github.com/HiQS-Labs/XYZ-forge/issues/1028) deduplicated/filed
beforepublication underuser'slower-severity disposition. Preservecanonical
guard andunknownpartialstate;reusecanonicalregistrationpreview infuturefix.
Source1044969d remainsunchanged;do notclaimS5 fullyfixed. S1/S2/S3/S4/S6/S7/S9
andN1/N2 reviewedcorrections/dispositions retainR6 citedPasschecks;S8 remains
GH1027 unapprovedtestgap. N3–N7 dispositions remainasdocumented.

User'sexistingCritical/High-blocks/lower-track policypermitsotherwisegated
draftpublication despiteactualFAIL,aftertrackingGH1028;it doesnotpermitmerge,
promotion,operationalaction,fullissueclaim ornewCItests. Requiredfinalsource
classifieragainstintegrationbase istier3/kernel;pushincrementfrompublished7d
istier2/releases. Fullqualifyingcheck mustrunonce onthis reviewedunchanged
source in disposablefullclone;normalpushhook also remainsrequired.


Publication boundary:fullgate0cd4c353 passed409/409,Python21,cleanrunner envelope
in disposableclone. Currentdraft stillreportsCONFLICTING;no landingqualification
orintegration rebase inferred. PR1026 merged6ebe4ca84ca245d75075061eb8e72d440b60ac4b
andPR1017 merged45afc936d5d29a8c0c37e6ccae63295bacebd4c7;fetch/recon fresh
remote beforefutureW7,do notclaimlive-provideracceptance orW7completion.
Currentreviewed source unchanged;normalincremental pushgate/publication pending.


## Original scope resumed — safe integration and Ubuntu attribution

Localmerge4dd28049 reconciles9ebe4b21 withff895c83 throughdeclaredcanonical
dump resolution/rebuild;originaltask andtargetbothancestors,allparentrows and
eventsretainidentities,original1022ownerfields exact. Canonicalcheck0failures/
9existingwarnings,gh32artifacts10/10,gh54refusals19/19. SixR6sourcebytes
unchanged;mechanical data/docs conflictresolution introducesno behaviorchange
andneedsno replacementcorrectivereview. Normalpushgate remainsrequired.
Primaryuntouched;no GitHubmerge/forcepush. FulloriginalW7–W11 stillactive.

Ubuntu exactSHA9ebe failure remainsunqualifiedportability:gh123movingqueue
3failedassertions inparallel andalone. Failpath writer/testblobs identical
onf122/9ebe/ff895/merge. Strongest hypothesis isfixturea+ O_APPEND:Linux
pwrite appendsignoringoffset andftruncate removesnewtoken;productionO_RDWR
avoidsflag. BaselineexistingCIrun38198894599 boundtoff895 remainsrunning.
Do notclaimbaseexecutionorrootcausereproduceduntilresult;no testcasechangeyet.
R6FAIL/Medium1028 andunapproved1027 remainexplicit;Phase6 mayresumenewscope
afterbranchstabilization,usinglanded1017/1026 withoutclaimingprovideracceptance.

Phase6 resumption at3b5fb32e: developmentff895c83 reconciled by preserving merge4dd28049; #1017/#1026 merged, previous active-ownership blocker superseded. This does not prove complete Marathon/live-provider observations. Own genuinely-new-scope plan review cap3 next, no corrective R6 review/reset. All W7–W11 remain active and weekly HELD.

Phase6 source implemented after planQA Approved atbf6f389a (attested373fc7d7). Actual module/CLI24 isolated-fixture controls pass, including multi-repo collision, unregistered/terminal rows, legacy fields, read-only URI/mutation refusal, empty/UNKNOWN, sidecars/journal, second-connection generation drift and no creation. Fixtures write only owned local git/schema/data/negative-control artifacts; no connectors or builders. Formal GIDs and all declared repository identities required; inventories remain dispatchfalse, not global execution proof. Existing suite runs/final QA next.

Untoucheddevelopmentff895 Ubuntu38198894599 confirms same gh123 failures as9ebe; existing fixture O_APPEND positional-write mismatch narrowed. Correction changes existing PYMOVE openmode a+ to w+, retains cases/assertions/bounds; no newCI test/case/parameter/registration or production lock change. Corrected Linux hosted qualification pending. Reconciled draft3b5 full normalgate409/409+Python21/822s, remoteSHA matches, mergeable; hosted38201048871 blocking smokeSUCCESS/macOS+UbuntuSKIPPED. R6 remains FAIL6/6/Medium1028; no corrective review/reset. W7–W11 active, new reader prerequisite does not complete W7.

Phase6 finalR1 at3378bed1 returnedFAIL withonepre-existing Medium dashboard text-to-HTML S1. Whole7039-line owner/test/writer sweep completed; qualified read seam passed bounded reviewer checks. S1 implemented using stdlib html_escape at all seven stored-text boundaries (plus derived issue text), preserving stored values and legacy non-HTML readers. Actual-render before control emitted active img markup; after three inputs×seven boundaries emit escapedtext and preserve ordinaryUnicode display. No browser/JS execution, productionDB ornewCI case. Current24 Jog controls stillpass with updatedsourcehash. Existing disposable53b4 Jog34/34,adapter223/223,lock6/6; canonical3378 clean0fail9warnings. Exactnewcandidate gate/review and correctedLinuxqualification remainpending. No additionalreviewround invoked aftercheckpoint; R6artifact unchanged.

Independent W8 readiness recon records actualadvisorysequencer missingCI,draft,unknownexternaldependency andcycle enteringready; knownnot-readydependency remainsinreadylistwithblocked_by_unmerged marker. These are existing outline heuristics, not proposal/dispatch proof. Shared strict readiness policy and evidence-bound authoritativeconstruction remain required; no duplicate scorer/engine or enabled execution.

Phase6R2 at3b9fb56b confirmed S1 repaired and new Jog seam/bindings; FAILforoneadditional pre-existing LowS2 dashboard diagnostic: dump parserNone was passed to %d andcrashed. One-line warning-format repair retains canonicalparserNone/recovery/policy andrendersexplicitDump generation(unavailable). Fouractual-render controls preserve matching/differentgeneration behavior andwitnessno-header/empty red→pass; refreshedsource-boundJog24 andescaping controls pass. Source/currentstatus updatedbefore Round3 withinunchangedPhase6cap3; no R6review/reset/newtest orbudget extension. Final normalgate/Linuxqualification pending.

Phase6 completed its pre-authorized normalcap3: R3 Approved at a87ac64a, attested8a2a0159; all R1/R2 history/negativecontrols preserved. Exactowner source77e99f17 matches current bytes; no morePhase6 orR6round authorized/invoked. Targetadvancedfromff895tod09; published3b5MERGEABLEclaim qualified/corrected afterfreshactualCONFLICTING/DIRTY read. Currentd09 resolution uses existing classifier pluscanonicalparse/formatter/validator anddocumented merge-resolve/rebuild. Ownoldbase rows unchanged; retain allcurrenttargetowner rowvalues exactly plusgenuine task additions. PreservetaskGID70/65/50/25/nulloverride/status_label/first_seen/doc/raw/start history; preserveoriginaldisplacedDB backup outsideclone. Canonicalcheck0fail9warnings, existingartifacts10/refusals19. Standardmerges f36f4a5b/fd6d2c5d retain development/review history; no primarywrite/forcepush/GitHubmerge. Sanctioned taskprogress writer changes only ownraw_text/updated_at, preserves allowner fields/history prefix. Normalfullpushgate and correctedLinuxexistingCI next; correction sufficiencyunverifieduntilthat result. This is sourceQA plusknownintegration proof, not freshfull-umbrella prior-art/landingapproval. W7–W11 active.

## Phase 7 — Canonical declared-work census (next W7 prerequisite)

Current recon is [the remaining-boundaries map](GH-1022-WEEKLY-INTAKE/recon-remaining-boundaries.md)
at bc4/d09. This plan is a bounded next seam, not a redefinition of full scope.
W7 global writer/rollover, W8 strict readiness/artifacts, W9 freeze/approval, W10
shared fire/resume/landing and W11 full audit remain required after this census.
No implementation or independent plan approval is claimed here.

Bet: existing ledger/Jog, lifecycle, shared driver-lock resolver and landed observer
are the owners of work facts. A caller-declared read census can expose those facts
without claiming global quiescence or inventing a backlog. Missing roots, schema,
context, identity, stale/conflicting observations or unsupported owners stay held.
A marker/count alone never proves delivery or permission to replace a Marathon.

Blast starts from the recon radius: weekly/daily core, shared intake, canonical
ledger/observer reads and consumers. This next seam introduces two opt-in owner
read views and one thin core observation mode/declared-root input. Writers, legacy
list/observe outputs, scoring/selection and dispatch stay with their current owners.
No new coordinator, scanner, checker/gate, runner, event type, schema migration,
background watcher or deployed registry. Easy rollback: remove new read views and
caller adapter; no persistent data conversion. Source/runtime byte identities remain
separate from observed target heads, with the existing IO runner and bundle ownership.

1. Extend the canonical RELEASES read owner with an opt-in work inventory covering
   qualified Marathon/Jog and existing lifecycle facts under one stable read envelope.
   Reuse the Phase6 connection/schema/journal/generation guards and queries rather
   than writing a weekly SQL reader. Refactor only the shared held-read envelope
   needed by these views; preserve `jog list` defaults/fields/order/filter and its
   standalone inventory. Require current declared schema/identities; retain
   unregistered rows and contradictory/unknown evidence as visible held facts.
   Never migrate/init/recover/acquire leases/signal/read connector secrets/config or
   write a DB, audit, receipt or capture. -> Actual module/CLI fixture reads distinguish
   initialized empty from unsupported, qualified multi-repo facts from ambiguous,
   stable generation from second-connection drift; bytes/sidecars remain unchanged.
2. Add a one-shot read action to the existing observer owner using its bounded JSON,
   matching-receipt and heartbeat helpers. Preserve the #1017 logical product-root
   representation and existing init/observe/phase/finish/terminal behavior. Validate
   required context shape and declared ownership before following metadata paths;
   unavailable/malformed/foreign/drifting records return UNKNOWN/nonzero rather
   than empty/complete. Read completeness does not imply process quiescence,
   criterion completion or attestation authenticity; consumer still validates the
   actual canonical peer receipt. -> Actual one-shot read has no context writes,
   loop/thread/signal/owner cleanup; transposed/missing/partial and logical-path
   fixture controls are recorded, with original observer outputs preserved.
3. Add only shared normalization/deduplication/evidence mechanics beside intake and
   a thin existing-core `weekly-work` caller. Require a caller-declared authority
   file/root list; no implicit fleet/primary/registry/path scan or default authority.
   Use complete selected runtime owner commands with existing bounded IO and actual
   runtime paths/hashes. Preserve every root's observation/provenance; identical
   stable identities can be deduplicated with their sources retained, conflicting
   observations hold rather than choosing a winner. Keep terminal/carryover reads
   explicit/all, include driver-lock/context evidence through their existing owners,
   and reject unsupported/missing outputs without legacy success-empty fallback.
   -> Read-only fixture batch covers empty/missing/foreign/duplicate/conflicting roots,
   older unsupported owners and root/head/code drift; returns held accounting and
   dispatchfalse, never a selected/runnable plan.
4. Expose the read seam in weekly's capability documentation while preserving
   distinct weekly-planner/daily-planner/10days policy and scan/find-doc interfaces.
   No installation, scheduling, clone/ledger/commit/push or builder side effect in
   this observation mode. Carry the unapproved individual test proposals separately;
   no generated write-set grants a CI test/case addition. -> Existing covering
   release/Jog/observer suites run only in the disposable full clone, plus recorded
   witnessed manual controls, source/schema/lint checks and normal classifier gate.
5. Obtain normal new-scope plan/final QA under the existing repository process and a
   named cap, then publish only the implementation branch after exact source/remote/
   hosted checks. R6FAIL6/6, #1028 and #1027 decisions remain unchanged; this census
   cannot re-review/relabel corrective findings or attest full W7–W11 delivery.

Before implementation, the precise work-envelope extraction and one-shot observer
shape need plan QA. Authority-root completeness remains a caller/independent-review
claim, not a filesystem absence heuristic. Live provider/fleet integration is not
established and is forbidden in this task. The ROOT/HEAD/generation/context results
are evidence for later strict readiness, not that readiness itself.

Remaining policy changes must be reviewed explicitly: clone-global one-writer and
known GID-preserving rollover, required-CI/draft/dependency treatment, immutable
budget/order/reviewer approval, criterion receipts at each effect boundary and a
separate latest-target redundancy/regression receipt before publication/landing.
Closeout currently permits missing hosted CI under the GH544 private-phase policy;
weekly must require an explicit per-packet CI policy and hold missing/unknown policy,
without silently weakening/reinterpreting either rule. Contradictory #752/#1020
state, unknown cost/runtime enforcement, unsupported schema/dependencies and missing
human confirmation remain held. No recurring cadence/budget/default is enabled.

Corrected-source Linux qualification verified: existingCI38204784286 exactbc4 completedSUCCESS, Ubuntu407/407 withgh123parallelrc0 andblockingSmokeSUCCESS, macOSpromotionSKIPPED. ActualrunJSON/fulljoblog andnormalpushlog are retainedwithcommittedprovenance. No workflowbypass/restart,newCIcase orrealMarathon/provider acceptance. PublishedHEADbc4 matchesremote andcurrentd09 target; latestPRreadMERGEABLE/CLEAN. Phase6source/gatepublication verified; W7censusmap/plan next, allW7–W11 remainactive. OwnprogressCLI preserves GID/axes/ovr/status/doc/first_seen,changesonlyraw_text/updated_at.


### Phase7 implementation checkpoint — 2026-10-12

Implemented the approved census seam in the canonical work inventory, existing
observer snapshot, shared normalization and thin weekly-work adapter. Actual owner
and CLI manual controls: Jog24, work15, observer8, core12; existing preparation
runtime controls19 passed. UNKNOWN observer exit2 payloads, malformed raw facts and
final runtime drift retain observations rather than erasing evidence. Source-bound
manual outputs/provenance are committed; ephemeral drivers remain outside the repo.
Fixtures create owned local DB/Git/context state, while census reads leave those
bytes and sidecars unchanged. No CI test/case/registration or live dispatch added.
Phase7 final owner QA and covering existing suites remain pending. Census is a W7
prerequisite: reconciliation/rollover, authoritative selection, freeze/exact approval,
shared fire/phase/resume/landing and the full W11 audit still require implementation.


Phase7 final R1 FAIL is retained: B1 malformed/foreign receipt reported complete,
B2 later observer failure removed normalized known inventory, S1 missing capability
in existing planner skill. B1 now holds rejected receipt/heartbeat/relay attribution
and retains bounded raw metadata; B2 keeps valid qualified facts alongside source
errors. S1 documents explicit authority roots and no-idle/no-dispatch limits in the
repository planner skill. Actual remediation controls core13/observer12/work15 PASS.
Earlier candidate existing suites adapter223/lifecycle125/work-state28/lock18/
artifacts10/refusals19 passed in disposable clone. These receipts retain their
exact candidate scope; R2 complete owner sweep and final-clone qualification pending.
R6FAIL/Medium1028 and Phase6Approved3/3 unchanged. Full1022 remains incomplete.
