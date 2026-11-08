# GH-1296 review repair — agent-assisted, acceptance incomplete

Runtime scope: malformed contract input becomes a lane blocker; harmless dot paths match frozen files; parent traversal is conservatively flagged; artifacts_new retains live preflight membership semantics. Packet generation rejects a changed selected capture path or content before staging. Lanes without a frozen request identity are explicitly not launchable.

## Evidence

- Manual helper red/green and controlled freshness-boundary checks: `manual-procedure.md`, `manual-output.jsonl`, and `provenance.jsonl`. These are not a replacement for live packet acceptance.
- Current real snapshot: 10 rules planning ticks completed, no model dispatch. Paired `make_packet` on one unchanged snapshot emitted #1295, #670, #1204, #446 in both versions. Development baseline advertises commands for all four. Candidate flags #1204/#446 for absent contracts; #1295/#670 have no frozen request identity. Generated READMEs and JSON are retained separately.
- Existing `stageb_dryrun.py --cap 4` on that current snapshot: #1204/#446 fail preflight; #1295/#670 have no capture named in emitted briefs. No lane is claimed ready. Disposable full clone clean afterwards.
- Existing `test/gh174-harness-registry.sh`: 8 pass, 0 fail, including its negative controls. This suite does not exercise make_packet. Full gate remains pending.

## Review disposition

- CodeRabbit r4456419993 (malformed artifacts_new): repaired and reproduced red/green.
- CodeRabbit r4456420027 (path normalization): repaired with conservative parent-traversal handling. Preliminary independent QA caught over-normalization; repaired in round 2.
- CodeRabbit r4456420042 (stale capture): selected path and content checked against the frozen request. Preliminary QA caught alternate capture discovery; repaired in round 2.
- CodeRabbit r4456419978 (recorded README drift): the original November 3 artifact is retained as historical evidence, not represented as current output. Fresh current-snapshot READMEs are in this folder. Exact historical regeneration remains blocked by unavailable original run input.
- Independent preliminary Codex/gpt-6-astra review: `relay-system/2026-11-08/gh1296-preliminary.codex.md`. Final independent implementation QA approved `a0f65126` in `relay-system/2026-11-08/gh1296-final.codex.md`; it explicitly does not approve issue closure.

## Acceptance limit and next step

The original #1279 run root points to an absent `Documents/GitHub Repos/XYZ-forge-gh1279-stageb-window-2026-10-31` checkout. Committed tables/config/briefs omit its frozen backlog. Bounded checks of known retained locations and backup manifests found no copy. Parent has no verified alternate; operator confirmed they do not know the root location. No reconstructed input is claimed original. Current-wave evidence does not silently replace issue #1296 historical acceptance; #1296 remains open.

Primary is reserved for the parent. Merged #1368 (`3c4925cb85`) into candidate `a0f65126`; full gate is running in a disposable full clone. Parent reconciliation is still in progress. No merge, factory packet dispatch, #1356 completion, or #1358 rehearsal is claimed. Repair round 2; unrelated prior repair counters preserved.
