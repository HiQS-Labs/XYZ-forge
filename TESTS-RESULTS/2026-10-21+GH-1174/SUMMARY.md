# GH-1174 documentation validation

Reviewed/source-validated input: `84ff0d4040eaa371d34672dec978cd6d796dd484`.
Runtime baseline: development `7eeae80488f7f2a8f3be2c2b97419cf3b8032a8a`.

- Existing `test/pdda-repo-contract.sh` in a separate disposable full clone: rc 0,
  zero errors, 455 warnings (cached issue states unavailable; existing governance/marathon debt).
  `PDDA_MODE=full`; LLM readiness self-skipped. This is docs evidence, not runtime qualification.
- Manual static checks: parsed three frontmatters and their relative links; inspected all three
  harness_root templates, AST default target count and calibration JSON; asserted every changed
  path is Markdown or canonical ledger output. No executable/test/workflow bytes changed.
- Existing frontmatter red control: removing title yielded rc 1 / one missing-key error;
  restoration yielded rc 0. The first attempt used a relative PDDA_ONLY_FILE and inspected no
  document (rc 0); retained as unqualified evidence, corrected with the required absolute path.
- Verification clone identity before/after the corrected control is identical and clean.
  The docs-gate clone remained at the input SHA with unchanged local config/remote and clean tree.
- Independent Codex QA: PASS / Approved, mechanically attested by relay-drive against input SHA.
  Receipt: `relay-system/2026-10-21/gh1174-final.codex.md`; attestation copied here.
- Normal-hook publication and exact-head hosted status are recorded after publication.

The operator explicitly approved manual handling because express.py rejects SKILL.md.
No gate bypass, new test, install, fuzzer campaign, model benchmark or manual deployment was invoked. The existing Pages workflow reacts automatically to normal pushes.
The authoritative map qualifies stale source-header/example promises; executable files stay unchanged.
Canonical roadmap add/accepted-start and manifest dial-in writers recorded this task against
`releases next` draft 0.6.0 Front-Door; overdue-release warnings are retained, not silently repaired.

## Publication

`6cc6806642409a50ced138e038dca182f1175e05` fast-forwarded origin/development from
7eeae804. Normal installed pre-push selected docs and passed GREEN in 63 seconds; no bypass.
Remote exact tip verified with git ls-remote. Exact-source-head CI 39542885544: blocking vendored
smoke and advisory Ubuntu succeeded, macOS promotion skipped; run completed SUCCESS.
Pages workflow is waiting; no deployment was approved or manually dispatched by this task.
Final metadata-head status is reported in the issue/handoff after canonical closeout.

Canonical manifest ship and publication records landed at abaa2620 through the normal docs hook
(GREEN63s). Issue #1174 is confirmed CLOSED. The source documentation remains byte-identical
to reviewed 84ff0d40; remaining changes are evidence and lifecycle records.

## Canonical closeout

Gated wave reconciliation succeeded, archived the capture into PROJECT/3-COMPLETED, moved only
GH-1174's ledger row to Completed, and regenerated adopted views/planning through canonical writers.
The generated leaderboard renumbers following the new row; no peer records were hand-edited.
Six pre-existing unrelated held/drift items are reported in reconcile.log and remain outside scope.
The existing deterministic documentation gate also passed within the reconciler.

The first reconciliation was stopped after a read-only resolver check proved inherited XYZ_HARNESS
redirected planner output to the primary checkout. Automatic review initially rejected termination,
then approved that single retry after the resolver/output-path evidence addressed its stated reason.
The canonical journal rolled back (rc6); the redirected output file remained absent. A fresh run
with all three roots explicitly bound to the isolated task clone succeeded (rc0). No continuing
approval blocker or code change follows. Both logs are retained rather than concealing the interruption.

CI for shipped-record head abaa2620 completed SUCCESS (39543175875). The repository's existing
Pages workflow also completed automatically; no manual workflow dispatch/deployment was performed.
The final metadata-head push/check results are recorded in #1174 and the task handoff.
