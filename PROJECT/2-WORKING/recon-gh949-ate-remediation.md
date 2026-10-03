# Recon Map — GH-949 ATE remediation

Base: `3fbed72f781d1ad060e298b798a44c32edef393d`. Mode: graph + exact-source fallback. Lanes: process/callers, ATE records/consumers, discovery/gate environment, supervisor state/oracle synthesis. Read-only recon; no production edits.

## Subject and change class

Targeted cross-module bug repair of the existing process helper, ATE runner, state oracles, locator and runner envelope. No new authority or persisted schema. The campaign repro source files are byte-identical between campaign base4f69865b and current base3fbed72f (bounded git diff).

## Graph coverage

Project XYZ-forge, indexed generation2026-09-01T15:54:30Z. Relevant search returned only unrelated rtl_run_bounded; no remaining search pages. Coverage: proc_group/domain_oracles/locator/runner-envelope not_tracked; ATE scripts excluded subtree; validate/ci-local metadata_changed. Every material edge below is exact-source confirmed; graph is not proof of absence.

## Seams and call paths

| Seam | Source | Caller / consequence |
|---|---|---|
| Bounded subprocess execution | utils/py/proc_group.py:80–110 | run_variations.py:328, fuzz_engine.py:245, claude_cli.py:46, wave_reconcile.py:654. Timeout cleanup only; exceptions bypass group teardown. Keep spawn exceptions and BoundedResult shape. |
| CLI lifecycle | utils/py/proc_group.py:130–200 | test/lib/runaway-guard.sh:59–125 uses timeout/PGID/ack and timeout-free --kill-pgid; missing timeout currently checked after spawn. Preserve125 startup failure and124 timeout. |
| ATE grid/records | utils/ate/scripts/run_variations.py:434–555 | build grid → write control → baseline/reset → run_harness → classification → append JSONL. Empty grid skips loop; spawn/interruption escapes before row. Timestamp at534 uses local strftime+Z. |
| Record readers | utils/ate/scripts/checkin.py:66–113; compile_issue.py:49 onward | top-level fail and nested category/cause already support explicit interrupted/spawn-error results; no schema bump needed. |
| Domain execution | utils/py/domain_oracles.py:126–142 | raw subprocess.run(timeout) kills only leader. zero-state:211–227 and containment:296–319 ignore incomplete run; recovery:406 already rejects nonzero. |
| Idempotence repeats | domain_oracles.py:348–351 → metamorphic_oracle.py:182–208 | later runs bypass domain _run; optional thread pool forbids unconditional signal registration inside run_bounded. Existing tuple/output API can retain shape with explicit timeout failure. |
| Directory links | domain_oracles.py:95–123 | os.walk dirnames excludes traversal but digest hashes filenames only. Hash dir symlink entries without following targets. |
| Git metadata identity | domain_oracles.py:238–252 | hardcoded .git/config misses common config and config.worktree behind linked gitfiles. Resolve Git paths; include absence/presence changes. |
| HOME fallbacks | skills/1-hourly/relay-xyz/find-harness.sh:121–130,348 | optional config/search/AGY expansions precede/ follow explicit override; guard HOME without inventing root-relative fallback. |
| Gate environment | test/lib/runner-envelope.sh:59–85 | validate.sh:1238 and ci-local.sh:399 both call begin before suite dispatch. Scrub proven inherited locator selectors there; preserve explicit fixture assignments and XYZ_HARNESS_DB contract. |

## State and rollback

ATE alone owns append-only variation JSONL and the per-run control; its scratch repo resets are restricted by the existing disposable-repo guard. proc_group owns child group teardown. Existing oracles read trees/config and execute commands against owned fixtures. RELEASES writes remain through releases_app.py only. No new writer, service, schema or dependency. Rollback is revert of grouped repair commits; old raw campaign records are immutable.

## Boundaries and unknowns

Normal-success background descendants are outside the current timeout-only contract and unchanged. SIGKILL and descendants deliberately entering another session cannot be caught by ordinary process-group cleanup. External mini-distribution consumers beyond xyz_mini_sync.py:51 are not enumerated; preserve public helper shapes. rtl_run_bounded in rtl.py/relay-turn-lib.sh is a separate seam and not claimed fixed. Historical #918 shared-root pooled failure is deferred and not diagnosed here. No live authentication/reconciliation or model calls are needed for deterministic acceptance.

## Verification surfaces

Existing suites: gh478-runaway-guard, ate-run-variations, gh142-ate-exit-contract, synthetic/gh102-telemetry-schema, gh-gen4-phase1-domain-oracles, gh155-phase1-metamorphic-invariants, gh365-runner-envelope, find-harness, gh396-find-harness-roots. Do not re-register retired suites; run focused/manual checks only in a disposable full verification clone. Base/repaired controls must check nonempty output, exact child/group disappearance, late writes, Git identity and prior JSONL preservation.
