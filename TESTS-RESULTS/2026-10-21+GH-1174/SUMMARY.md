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
No gate bypass, new test, install, fuzzer campaign, model benchmark or deployment was used.
The authoritative map qualifies stale source-header/example promises; executable files stay unchanged.
Canonical roadmap add/accepted-start and manifest dial-in writers recorded this task against
`releases next` draft 0.6.0 Front-Door; overdue-release warnings are retained, not silently repaired.

## Publication

`6cc6806642409a50ced138e038dca182f1175e05` fast-forwarded origin/development from
7eeae804. Normal installed pre-push selected docs and passed GREEN in 63 seconds; no bypass.
Remote exact tip verified with git ls-remote. Exact-source-head CI 39542885544: blocking vendored
smoke succeeded, macOS promotion skipped, advisory Ubuntu job still running at this snapshot.
Pages workflow is waiting; no deployment was approved or manually dispatched by this task.
Final metadata-head status is reported in the issue/handoff after canonical closeout.
