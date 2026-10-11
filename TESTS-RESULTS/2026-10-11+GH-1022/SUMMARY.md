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
