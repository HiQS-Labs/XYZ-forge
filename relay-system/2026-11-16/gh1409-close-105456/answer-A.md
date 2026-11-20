**DEGRADED PANEL — a requested advisor did not answer; this is the only payload and it is NOT RECONCILED.**

**ANSWER:** **C — keep #1409 open for a specific R4 gap:** the PR-controlled vendor script can overwrite the four restored smoke suites before execution. The `development` protection decision alone would warrant a separate follow-up, rather than holding this implementation issue open indefinitely. (`ci.yml:575–578,611–619`; plan:16–20,53–56)

**FINDINGS**

- **[Pass] Phase 0 disposition is documented.** CODEOWNERS was dropped for the single-author envelope; `main`’s required check is recorded as applied; `development` protection remains an operator decision, explicitly excluded from the revised implementation scope. Its prerequisite is real: reconciliation requires `.protected == false` and calls for a reviewed bot-bypass policy. These are recorded decisions/settings, not changes delivered by #1413. (`relay-system/2026-11-10/gh1409-final-qa.md:14–18`; `PROJECT/2-WORKING/GH-1409-VENDORED-SMOKE-BASE-PIN.md:16–18,51–56`; `.github/workflows/wave-reconcile.yml:41–48`)

- **[Pass] Phase 1 implements R1, R2, R3 and R5 as scoped.** R1 requires a second parent, exports `HEAD^1`, and logs all three SHAs; gh308 consumes that export. R2 rejects added scripts/files, increased distinct bypass cardinality, and increased declared count while allowing shrinks. R3 rejects added marker lines outside `test/`. R5 reads labels live and warns before skipping R2–R4. (`.github/workflows/ci.yml:548–574,592–596`)

- **[Blocker] R4 restores seven files, but does not ensure the four vendored copies remain trusted.** The step restores exactly seven scripts, then executes:
  > `bash "$HARNESS_DIR/relay-automation/xyz-vendor.sh" --no-register "$SCRATCH"`

  It subsequently runs `.xyz/test/…` without restoring or checking those copies. The vendor script is absent from the pinned list and copies `test/` into its writable staging directory. A PR can replace a smoke judge with `exit 0` and change the existing vendor script to write that same no-op into the staged judge **after** copying. Pinning fixes the source copy temporarily; the later vendor operation undoes its effect. No workflow edit, label, baseline growth, or sourced-test-helper edit is necessary. (`.github/workflows/ci.yml:575–578,610–619`; `relay-automation/xyz-vendor.sh:432–445`)

  This is a source-traced bypass, **not an executed reproduction**. It falls outside the specifically documented helper residual, which names `test/lib/*` and `test/_setup.sh`. (`PROJECT/2-WORKING/GH-1409-VENDORED-SMOKE-BASE-PIN.md:104`)

- **[Pass] Phase 2 delivered useful discriminating evidence, with limits.** The receipts include baseline and marker reds, judge-neutering red, legitimate-shrink green, stubbed-label control, and a discriminator showing the neutered suite passes without pinning. The procedure extracts the actual workflow bodies; `provenance.jsonl` records results. None exercises vendor-script replacement. (`TESTS-RESULTS/2026-11-10+GH-1409/SUMMARY.md:9–21`; `controls-procedure.md:25–34,82–96`; `provenance.jsonl:1`) Final QA approved the scoped implementation but explicitly left hosted/full-gate evidence outstanding; the later full-gate receipt records failure with discrimination, not a clean pass. (`relay-system/2026-11-10/gh1409-final-qa.md:126–144`; `provenance.jsonl:5`)

- **[Should] Separate the protection decision when closing implementation work.** The follow-up should identify the operator decision, the exact required check, reconciliation’s protected-branch refusal, and the reviewed bot-bypass policy needed before enabling protection. Keeping that unscheduled decision attached to completed implementation obscures the revised scope; the plan already treats it as a non-goal. (`PROJECT/2-WORKING/GH-1409-VENDORED-SMOKE-BASE-PIN.md:17,53–56`)

**RECOMMENDATION: C — keep #1409 open until the vendor-mediated R4 bypass is closed or explicitly accepted, with a recorded manual red/green control; confidence high, strongest fact: PR-controlled `xyz-vendor.sh` executes between restoration and execution of the four vendored judges (`ci.yml:575–578,611–619`).**
