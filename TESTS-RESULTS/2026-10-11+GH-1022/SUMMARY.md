# GH-1022 staged discovery verification

Existing Codex prerequisite: 43/43. Existing gh369 baseline: 14/14.
Manual discovery/compatibility probes: 20 passed, including malformed/truncated,
conflicting duplicate, foreign URL/prior, incomplete prior, missing PR files and
offline refusals; closed/reopened observation, retained member refresh, paginated
PR-filtered issue pages, full PR files, held dispatch and no scratch writes.
Five legacy scan command/output/error comparisons matched baseline. Copied skill
from foreign cwd worked with explicit current harness. The first probe with the
inherited old primary harness failed clearly; no implicit fallback/update occurred.

Negative control: deleting a PR file from the collected result made the manual
coverage assertion false. Incomplete file input also made actual discovery raise.
These are recorded manual probes, not new CI tests or permanent test machinery.
The temporary fixtures and script were outside the repo; running the probes wrote
only these evidence files in the task clone. Plan review used local tick/relay state.
No GitHub/connector writes, fetch/plan dry-run, schedule, live Marathon/Jog or deployment.

Candidate gh369 before/after library ownership correction: 14/14 both times, Git identity unchanged. Inventory ratchet passes unchanged. Python compile checks and requests/yaml/pytest imports pass. Final gate and final implementation QA remain pending. Exact source hashes in
manual-results.json bind the manual evidence to its implementation. Repository
identity was unchanged across the prerequisite/base suite runs: HEAD 22806e5f,
origin task clone, core.bare=false and no local user override. The final shell
identity probe exits 1 for absent local user.email; this does not change suite 43/43.

This PR implements only shared discovery/held preview. All umbrella branch ledger,
freeze, readiness and fire/phase/resume/landing protocols remain unimplemented;
no claim of full #1022 acceptance, no test proposals awaiting approval.


Independent plan ownership QA round 2 Approved at 5905ff2d: the import-only library
beside the existing planner matches the explicit skill-subsystem and entry-point policy;
no gate/baseline change or policy exception needed. Earlier location rejection is
retained in the plan. Exact CLI/copy/parity probe source hashes reflect the new library.


Live read-only preview with the final helper location observed two updated issues and
all four open PRs, with changedFiles matching collected file counts. It returned
complete transport, HELD and dispatch false. Narrow state/count evidence is retained
in live-preview.json; raw response was intentionally redirected to task-local scratch.
This did not write a ledger/checkpoint or run a planner dry-run with hidden mutations.


Final QA round 1 returned FAIL for non-string state handling: null/numeric records
raised AttributeError instead of UNKNOWN JSON. The normalizer now rejects those
values with ValueError. In-memory core controls: valid open remains HELD/exit 0;
null/numeric return complete false, UNKNOWN, dispatch false and exit 2. Pre-fix
bytes failed both invalid-state assertions, a witnessed red control. All original
20 manual checks also pass on updated source hashes. No new CI test/case added.

Final QA round 2 found numeric PR reviewDecision escaping advisory sequencing as
AttributeError. The weekly read boundary now validates text fields and CI collection/
item text types consumed by those existing helpers. Legacy policy is unchanged;
valid/null review values remain held. Seven manual variants pass; five invalid
variants fail on pre-fix bytes, then return UNKNOWN/exit 2 on candidate. Original
20 checks pass with refreshed hashes. No tests/cases/gates added.

Final independent QA round 3 Approved, attested implementation ca4c9b5a2d06ac6f247cc6e0594ac9d68b049978. Reviewer reproduced five invalid PR metadata red controls and valid/null/absent review behavior; source hashes match. Subsequent changes here record evidence only.

Final classified docs/skill gate on aeabcdeb026cfd5f70fbded531623e261f4cf521, disposable full clone: exit 0, zero errors and 430 warnings (unavailable issue-state reads and existing governance/Marathon-QA findings). LLM readiness skipped by the existing gate. This is not a full runtime-suite or issue-state verification claim. Final gh369: 14/14; AST parses pass; no tracked clone mutations; primary clean at a58378289863548968ea907cbbddfd2b8d6f4f28. Push hook will recheck the evidence-only final revision.


Phase 4 local accumulation candidate (required continuation, not umbrella completion):
36 manual controls pass on source hashes in accumulation-results.json. Fixtures used
ephemeral independent Git clones, canonical RELEASES init/add/rate commands, HQ
captures, local receipts/locks and commits. Reads were stubbed; connectors disabled;
no pushes, schedules or dispatch. Existing mixed-case owner URLs and all owner rating
axes/override/GID/document bytes remain preserved. New rows stay unrated/held; closed
issues are not asserted delivered. Interrupted canonical registration, refused commit,
and lost successful-commit reply recover without duplicate rows or a second commit.
No-change retains receipt bytes/mtime, checkpoint and HEAD. Target/ledger drift, lock
contention, incomplete discovery, malformed persisted state and symlink captures hold.

Witnessed red input: the mixed-case canonical URL incorrectly held as foreign before
using shared URL equality; accumulation-case-before.log records it. Independent plan
review approved the narrowed accumulation design at 8de581db. Canonical JSON reader now
reports owner axes/override/calculated/effective rank. The authoritative planner's
override omission remains held for separately reviewed W8 correction, evidenced by
planner-rank-before-controls.json. No CI cases or permanent test harness added.
Phase 4 final implementation QA and classified existing suites are still pending.
Remote branch resume/publication, dependency/active-run handling, canonical selection,
freeze/approval and fresh fire/phase/resume/landing receipts remain required active work.

Phase 4 final QA r1 found two blockers; accumulation-blocker-results.json/log
retain actual canonical CLI fixture red failures and candidate passes. Titles
containing parsed rating tokens now hold before registration. Final commit boundary
coordinates with canonical WriterLock, checks branch/HEAD/target/generation and
staged/committed/live objects before completing the checkpoint. All36 controls
still pass on updated hashes. Local canonical lock/audit sidecars are additional
explicit effects. The no-change guard removal red control fails the receipt assertion.
Provenance binds accumulation/manual/red and ledger145 baseline/candidate evidence.
First classified gate was NOT green: plan path wording error plus global connector
disabling defeated existing fixture connectors; neither was masked or skipped.
Corrected gate and final source QA remain pending. First QA driver had a containment
failure from producer evidence refresh during review; findings retained, no approval.

Phase4 final QA r2: FAIL for a capture edit after SHA256 accounting and before
Git-object sampling. Actual old f4dba01f clone control completes a stale checkpoint;
final candidate preserves the injected CRLF edit and holds before commit. Capture
Git objects now derive from the exact immutable bytes used for declared SHA256,
including owned creation intent. Staged/committed checks cannot resample different
capture bytes as proof. SHA1 Git object format is explicit; unknown formats hold.
Fresh target/HEAD checks immediately before and after commit hold drift without
discarding any post-drift commit or completing its checkpoint. Versioned artifacts
bind final source:36 accumulation,20 discovery,2 capture red/pass,4 title/writer
red/pass and2 commit drift controls. No permanent test driver or new CI case added.
Corrected classified f4dba01f gate: exit0,28/28 selections,24 release suites and
existing Python layer21/21,docs/static,clone identity; zero errors/48 docs warnings;
not promotion and before capture fix. Final-source gate and last QA round3 pending.

Final accumulation source d0bc939a classified gate completed exit0,28/28
selections incl24 release suites,Python21/21,docs/static/clone identity;48 docs
warnings,not promotion. Independent QA3 swept all6903 canonical releases lines
and confirmed all accumulation fixes but FAILed a preexisting release updater
lost-update. Review cap3 exhausted, STATUS Escalated, no approval attestation.
Actual second-process canonical owner update reproduced old codename loss; narrow
repair checks the validated row inside the existing writer transaction and refuses
release-update-stale, preserving owner changes. Quiet updates succeed and all4
canonical fixture checks pass. No new test case/runner/gate. Fixtures wrote only
local canonical DB/dump/lock/audit/receipts; connectors disabled, no GH or dispatch.
Late repair existing checks are pending. Further source review requires the
operator's explicit cap decision; no cap reset or replacement review is started.

Late repair bc934d5288e8d859f5be72fbd6a418f157e49ff8: classified existing gate
exit0,28/28 selections incl24 release suites,Python21/21,docs/static/identity;
0 docs errors48 warnings,not full-suite promotion. Final gh36914/14,ledgercheck
clean0 failures9 existing warnings,unchanged inventory ratchet clean,4 AST parses
pass,diff whitespace clean. Refreshed36 accumulation controls pass with updated
app hash in late-fix-accumulation-results.json. No source test/workflow/registry/
gate modifications in final diff. Verification clone origin remains canonical
GitHub,HEADbc934d52,tracked tree clean;primary remains cleana5837828/development.
Parent has requested one extra independent review from the operator;approval is
pending. Keep current artifact STATUS Escalated/ROUND3of3. No additional review,
cap reset or publication of held source has occurred. Exact next target is the
evidence-only commit carrying this record;its4 source hashes equalbc934d52.
Published draft#1024 remainsd7ef2bc9 with hosted smokeSUCCESS;promotion/portability
SKIPPED by policy. Mandatory remaining umbrella work stays ACTIVE.

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

Consolidated producer diagnosis after the single authorized Round4 FAIL:
rate and repoint both derived raw_text before the lock; mutual actual canonical
interleavings reproduce owner loss. Both now snapshot/check the full row inside
existing transaction, refusing named stale writes. Old/candidate controls10 plus
rating/repoint6 and protected-writer4 pass, with all local canonical checks clean.
Accepted-start/reconcile native issue reads were stubbed; canonical second-process
owner writes were real. Marker/move preserve unrelated fields; add uniqueness
retains one GID and rolls back the loser (nonzero IntegrityError,not named duplicate).
Legacy sync skips releases mode; general release/Jog CRUD race-freedom not claimed.
36 accumulation controls pass and all4 source hashes bind a0b484b5. First rate
repair gate3c5264a7 passed28/28 incl24 release suites/Python21;not final evidence
for repoint guard. Final a0b gate pending. No new CI tests/gates/frameworks.
Smallest next review: both guards and mutual/quiet/force/partial-field preservation,
previous release guard and exact final gate evidence within held accumulation
contract and repo whole-file rule. Review remains Escalated4/4;no extra review,
cap reset,publication or umbrella completion. W7–W11 remain required active work.

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

Operator explicitly extended the SAME review to5/5, preserving all4 FAIL histories,
and authorized filing concrete below-High findings before gated draft publication.
R5 PASS/Approved,reviewed e016d29a4f79ec5d8014fafc5476e8224c3b4a4e:
full source sweep,independent in-memory mutual race guard-removal reds and quiet/
force controls;no unresolved Critical/High,no actionable lower-severity finding.
Earlier owner-loss impacts were High and repaired,not downgraded. No follow-up
issue filing is needed from this turn;no arbitrary backlog additions. Attestation
binds exact reviewed head and review bytes;producer source/gate evidence unchanged.
Approval applies to HELD local accumulation only;W7–W11 remain active/unimplemented,
no operational/landing/umbrella completion. Normal gated draft publication next.

Held accumulation published to existing draft1024 at exact remote
4770f0910cfb02d81d5c3c9f80dd33d5cea8fee3. Normal prepush tier2GREEN315s,
28/28 incl24release/Python21;docs0errors48warnings;clean runner envelope,no bypass.
Hosted38178591497 completedSUCCESS exact4770f091: blockingvendoredsmokeSUCCESS;
macOSpromotion andubuntuportabilitySKIPPED bypolicy,nottested/green. No manual
workflow dispatched,no full promotion. R5PASS atreviewede016 sourcehashesunchanged.
No actionable lower finding/no issue filed. W7–W11 remain required/incomplete.
Publication evidence commit follows;only docs/evidence,normal gate again.

Phase5 canonical override prerequisite is locally implemented after planQA
Approved45d55239. Candidate da603c70 reader10/10,fullengine2 before/afterordering
controls,gh69816/16,marathon-plan70/0with2skips,gh3629/9,accumulation36pass.
Ledger bytes unchanged during fullengine;isolated canon ledger creation/reports/
fixture Git commits were actuallocalwrites with stubbedGH/no live dispatch.
Foursourcehash/AST evidence committed. Historical axisdisplaydashes retained and
disclosed. FinalQA/fullclassifiergate pending;weeklyHELD/W7–W11incomplete.

Phase5 final Codex QA R1 PASS/Approved exact4be47217,whole1498engine/1318core
sweep,independent in-memory current-reader probes and source/provenance hashes.
Retained display Nit disclosed,not behavioral expansion. Full classifier-required
gate pending at normal push boundary;focused evidence not qualification. Accumulation
review remainsclosed. No tests added or operational/umbrella approval inferred.

Phase5 published6e6db879:normalfullgate409/409in821s,Python21,cleanenvelope;
hosted38181222495 exactSHA smokeSUCCESS,promotion/portabilitySKIPPED. No full
promotion or liveexecution inferred. Owner progress CLI preservesallscore/status/
GID/doc fields;canon checkclean. Allreviewedsourcehashesunchanged in proofcommit.
W7–W11stillrequiredactive;nextpure Jog ownership seamrecon,observeroverlapheld.


Claude review corrective checkpoint (local, final QA/publication pending):
full31ba review and8 inline findings read against published7d plus local9ead plan.
Six targeted actual-source controls pass: ordinary baseline, competing baseline
clean rc3/preserved1 (pre-fix SQL crash, existing trigger already preserved1),
third-member rated-title batch refusal with no new captures/rows (pre-fix row2
was left written), corrected retry and canonical-case URL registration, malformed
createdAt no partial writes, private adapter no-argument usage/rc2. Existing36
accumulation manual controls pass on the source hashes in
claude-correction-source-hashes.json. Temporary scripts remain outside the repo;
no permanent asserted drivers, CI cases or registry changes. These probes wrote
canonical DB/dumps/receipts/captures/commits only in temporary fixture full clones;
GH/target reads stubbed, connectors disabled, no push or live Marathon/Jog.

N3 interleaving control preserves winning full-clone HEAD/complete receipt and
clean state; the losing bootstrap git clone refuses its now-nonempty directory.
S1 stale explicit harness and N1 invalid-override fallback confirmed; S6 check-URL
churn confirmed as local accounting commit with fresh metadata and dispatchfalse.
Those observations are not fixed by the four deterministic source corrections.
S1/S2/N1 runtime-bundle policy and S7 bounded IO remain pending reviewed repair;
Phase6 Jog scope is paused. S8 individual test proposals tracked in GH1027,
none approved or added. Full16-finding disposition is in the canonical project doc.

Historical provenance audit, N5:98 original rows,19 without revision fields,8
current artifact hash mismatches. Seven historic artifact versions are available
as exact Git blobs; one original log is unavailable. Append-only correction index
links recoverable versions and withdraws the unavailable historical claim. Missing
source bindings remain unqualified; no invented tested SHA or overwritten receipt.
Keep original artifacts to preserve later attestation hashes.

Focused existing suites at exact corrective source41f225bd8726499c999184162037d1fd826140a1:
gh32-releases-app145/145,gh69-roadmap-shadow85/85,gh369-find-doc-root-resolution14/14.
Separate disposable fullclone stayed clean at41f225bd with canonical GitHub origin
before/after;runtime harness/tick/connector overrides unset and device config null.
All four source hashes match the witnessed candidate and committed bytes;AST pass.
Primary checkout remains clean at a58378289863548968ea907cbbddfd2b8d6f4f28.
Changed-path audit has no test/registry/gate additions or modifications.
No new final qualifying gate or review ran;closed R5 is preserved and new review
authority remains pending. Corrective source/evidence retained locally,unpublished.

Additional actual-source concurrent manifest-cut control returns baseline-empty-manifest/rc3 and preservesNULL baseline. OwnGID canonical progress raw_text updated to the held corrective state;all other returned owner fields preserved,check clean0failures9warnings. Task-local DB/dump/receipt writes only,connectorsdisabled. Source bytes remain41f225bd;no review/gate/push.


Continued producer remediation per explicit operator direction, no independent
review or R5 restart: S1/S2/N1 runtime ownership/pins andS7 default bounded IO
implemented locally. Complete bundle uses own shared runtime; standalone copies
use central locator;invalid explicit hints refuse. Actual runtime paths/bytes
are checked before side effects and bound separately from target Git HEAD.
S6 no-op comparison omits only known check URL/time keys, preserves all
result/readiness/unknown fields, and returns fresh full PR metadata even onno-op.
This is held accounting,not frozen approval;future full check evidence and
approval-invalidation enforcement remain required in W9–W11.

Producer verification:19 actual-source controls pass, including copied/old
harness choices, invalidhint refusal,five runtime hashes/private receipt,
default command actual canonical apply,slow Git hook andremote timeouts with
TERM-resistant owned child groups,locks released,uncompleted receipt retained,
exact-input retry/once commit,runtime drift before capture intent andafter
canonical writer transaction,and exact-source restoration/adoption. Default
production deadline60s is shortened to2s only in loaded fixture namespace.
No task/deployed runtime files modified by drift controls:copied temporary
runtime only. A ps read of owned PIDs required sandbox escalation;initial
fixture PATH leak andmacOS /var-/private path comparison were corrected before
retained successful control run. No policy or source bypass made it green.

S6 check-URL no-op retainsHEAD and returns freshURL;9 material mutations
(result,mergeability,review,head,body,files,unknowncheckfield,draft,nullchecks)
all causeheld accounting changes. Existing36 accumulation manual controls and
20 discovery/legacy/copy probes pass,including5 unchanged scan interfaces.
All are temporary manual verification;no permanent drivers,new CI cases,gate
registrations orpaid independent review. Fixtures write canonicalDB/dumps,
captures,intents/receipts andlocal commits,stub transport,connectorsdisabled;
no real Marathon/Jog,recurring scheduling,installation,push ordeployment.
Final source hashes recorded;existing focused checks andconsolidated final
review remain pending before qualification/publication.
