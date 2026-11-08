# GH-1296 review repair — agent-assisted, acceptance incomplete

Runtime scope: malformed contract input becomes a lane blocker; harmless dot paths match frozen files; parent traversal is conservatively flagged; artifacts_new retains live preflight membership semantics. Packet generation rejects a changed selected capture path or content before staging. Lanes without a frozen request identity are explicitly not launchable.

## Evidence

- Manual helper red/green and controlled freshness-boundary checks: `manual-procedure.md`, `manual-output.jsonl`, and `provenance.jsonl`. These are not a replacement for live packet acceptance.
- Current real snapshot: 10 rules planning ticks completed, no model dispatch. Paired `make_packet` on one unchanged snapshot emitted #1295, #670, #1204, #446 in both versions. Development baseline advertises commands for all four. Candidate flags #1204/#446 for absent contracts; #1295/#670 have no frozen request identity. Generated READMEs and JSON are retained separately.
- Existing `stageb_dryrun.py --cap 4` on that current snapshot: #1204/#446 fail preflight; #1295/#670 have no capture named in emitted briefs. No lane is claimed ready. Disposable full clone clean afterwards.
- Existing `test/gh174-harness-registry.sh`: 8 pass, 0 fail, including its negative controls. This suite does not exercise make_packet. Full `validate.sh` passed 409/409 on `a0f65126`; receipt and log are retained here.

## Review disposition

- CodeRabbit r4456419993 (malformed artifacts_new): repaired and reproduced red/green.
- CodeRabbit r4456420027 (path normalization): repaired with conservative parent-traversal handling. Preliminary independent QA caught over-normalization; repaired in round 2.
- CodeRabbit r4456420042 (stale capture): selected path and content checked against the frozen request. Preliminary QA caught alternate capture discovery; repaired in round 2.
- CodeRabbit r4456419978 (recorded README drift): the original November 3 artifact is retained as historical evidence, not represented as current output. Fresh current-snapshot READMEs are in this folder. Exact historical regeneration remains blocked by unavailable original run input.
- Independent preliminary Codex/gpt-6-astra review: `relay-system/2026-11-08/gh1296-preliminary.codex.md`. Final independent implementation QA approved `a0f65126` in `relay-system/2026-11-08/gh1296-final.codex.md`; it explicitly does not approve issue closure.

## Acceptance limit and next step

The original #1279 run root points to an absent `Documents/GitHub Repos/XYZ-forge-gh1279-stageb-window-2026-10-31` checkout. Committed tables/config/briefs omit its frozen backlog. Bounded checks of known retained locations and backup manifests found no copy. Parent has no verified alternate; operator confirmed they do not know the root location. No reconstructed input is claimed original. Current-wave evidence does not silently replace issue #1296 historical acceptance; #1296 remains open.

Primary reservation was released. Closed #1287/#1288 views were reconciled using the existing mover and RELEASES CLI, then published at `938a96e60` through the normal documentation gate (85 seconds); primary is clean and synchronized. Merged #1368 (`3c4925cb85`) into candidate `a0f65126`; full gate passed 409/409 in a disposable full clone. Reconciled baselines `8ecb894cc` and `938a96e60` were merged afterward; runtime code is unchanged. No PR merge, factory packet dispatch, #1356 completion, or #1358 rehearsal is claimed. Repair round 2; unrelated prior repair counters preserved.

## Final hosted-review repair

The artifacts-only contract returned no blockers on `24278437` despite preflight requiring target, gate and fix_probes. Required-field and new-artifact probe checks now reject it. `required-fields-controls.json` records that witnessed red control and nine candidate cases, including valid existing/new artifacts. This is focused helper evidence; prior full-gate and current-wave records retain their original revision coverage. Final changed-runtime validation remains required.

### Raw preflight-output format

`current-dryrun/preflight-1204.json` and `preflight-446.json` are retained verbatim tool stdout containing contract errors, not JSON documents. The `.json` suffix was produced by the existing stageb_dryrun collector; read these as text. They are not evidence of successful JSON extraction or ready lanes. Renaming/reformatting them would change the retained raw run, so the naming limitation is documented here; collector naming can be corrected separately under the still-open #1296.
