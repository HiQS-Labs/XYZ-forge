# GH1092 bounded reviewer-delivery verification

Frozen pre-FINAL evidence checkpoint; later revalidation and approval are recorded append-only
in relay-system/2026-11-12/gh1092-final.codex.md. Earlier failures remain failures.

Implementation source: 3f45258bf4f161d0a8c874c8b70cfa877f98696b, based on Forge
ed0a386fac4caa170bd9d6b297da7154717288df. Shared reviewer prompt and existing relay-xyz
item 5 changed; existing package regenerated. No terminal controller or containment writer changed.

## Evidence and limits

- PLAN: round 1 FAIL/Should S1; revised baseline-rejection criterion, round 2 Approved,
  supervisor exit 0 and actual attestation. See relay-system/2026-11-12/gh1092-plan.codex.md.
- Delivery control: baseline REJECT (eight required clauses missing), candidate render PASS.
  See nonempty baseline-prompt.txt, candidate-prompt.txt and delivery-control.json. This detects
  unchanged delivery text, not future model compliance. Live transcript is separately required.
- Focused suites: gh681 reviewer probes, gh397 reviewer roles, gh505 attestation,
  worktree isolation and package freshness exit 0. Before/after identity equal at 3f45258b.
  Worktree suite 33/0, package 3/0. Preflight codex-turn 43/0 at committed plan-input revision.
  Existing negative controls still reject off-lane residue and demonstrate old forged approval.
- Main live smoke: two setup failures (space-split flags; rejected symlink writable root), then
  actual Codex reviewer reached instruction delivery. It read Forge rules, identified Forge-only
  policy and attempted gh681 in the supplied full clone, not in the relay worktree. The suite
  exited 2 before assertions: macOS mktemp uses its Darwin user-temp path outside that turn's
  writable roots. Reviewer correctly returned PARKED/Unverified, supervisor exit 5; identity
  stayed c6d6f9d2. This is not a runtime pass. All three launch logs are retained; the existing
  smoke thread remains parked and will not be re-fired. FINAL QA must independently resolve
  this acceptance predicate in a correctly supplied execution context before approval.
- Foreign smoke: initial preflight exit 2 refused a relay thread outside the target root.
  Corrected smoke uses a disposable canonical LTVera clone nested only inside the verification
  helper; no new GH981 implementation checkout, no writes to primary/PR992 checkout. PASS, supervisor exit 0 with attestation: reviewer
  identified LTVera test requirements and refused to certify the browser claim (Unverified).
  See relay-system/2026-11-12/gh1092-smoke-foreign.codex.md and smoke-foreign-r2-driver.log.
- Full qualifying gate: pending; run exactly once on the final approved commit in disposable
  full clone, according to route=full/tier=3. No hosted or full-gate pass claimed here.

## Commensurate acceptance and remaining ownership

This PR must not close Forge #1092 or LTVera GH981. Runtime permission is a prompt contract;
it does not grant a missing sandbox/DB/network capability or prove browser safety. Existing
PR1432's named gate and PR1445's acceptance question are reused unchanged. All original eight
GH981 items and unimplemented six-decision predicates remain as the issue/plan records.

Concrete owner recommendations (proposed, not adopted): retain a consequential unmeasured
safety finding as unresolved for readiness; allow a draft only with that finding named and
no merge/readiness claim. Ratify a no-change diagnosis through the pipeline owner using
independent affected-path measurement, without requiring a manufactured code PR. A future
LTVera replay must exercise the actual app, copied-storage/native navigation branch and at
least the observed 126-second reconnection interval, with original log/history evidence.
Those choices/replay remain outside this bounded prompt PR and no waiver is inferred.

## Lessons admission

| Component | Observed verdict |
|---|---|
| Shared prompt delivery | confounded: one live smoke, runtime prerequisite failed |
| Workflow permission mirror | no observed independent effect |
| Package refresh | helped: existing freshness check 3/0 |

NO_ENTRY: no new behavioral lesson established by a completed acceptance run.
Raw CLI transcripts and setup outputs are also preserved under temp/gh1092/unpublished/
for parent inspection; they are not substituted for committed review and decisive evidence.

## Completed normal QA and full local gate

FINAL Round 2 independently reran the explicitly assigned clean-child-environment command:
all eight gh681 cases passed, including Producer classification, scratch-only acceptance and
forbidden-residue rejection; identity stayed unchanged. B1 is closed by this new measurement,
not by removing its original grade or failed run. Driver exit 0 and immutable reviewed head
c460929878066a3f09d20dfff0f9d35a70fc9f4a are retained in FINAL relay and attestation JSON.
The earlier main smoke remains historically PARKED; final revalidation resolves its predicate.

Full local gate ran once on approved source revision
70ebdeb4f4bb4ac9ea3ec8b7ccdbbac8b1417945: **408/408 passed**, including the Python-layer
stage (**21 passed**) and clone-identity invariant. Mode: four-wide, existing sequential lane;
prepared Python 3.14.7 toolchain. External before/after identity bracket is equal. Native receipt
has gate=validate.sh, scope=full, exit_code=0. This is local verification, not promotion evidence;
no promotion or ci-local sequential qualification is claimed. Existing live self-sufficiency
skip was used as in the shipped pre-push route; real Codex QA/smokes above ran separately.

Initial source push succeeded through native exact-SHA full-receipt reuse, without a bypass.
This later commit only publishes evidence/current status. implementation-sha256.json records
all three implementation/package hashes; final publication must verify they remain identical
and use the native documentation gate for this evidence-only update. No post-approval source
change or additional full-gate run is hidden here. The final docs push/hosted checks are reported
separately at handback. Parent supplemental Kimi K3.1 Pro review remains pending.
