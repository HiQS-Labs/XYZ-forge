# ESCALATION — Marathon Phase gh-1315-legacy-preview-parity

phase: gh-1315-legacy-preview-parity
task: MARATHON-GH-1315-LEGACY-PREVIEW-PARITY-TURN
relay-drive-exit: 4
reason: cap-stalled
gate: not-run
relay-file: marathon-system/gh-1315-legacy-preview-parity/RELAY.md

turn-log: /Users/noelsaw/flywheel-day2-exec/relay-system/logs/2026-11-26/agy-turn-MARATHON-GH-1315-LEGACY-PREVIEW-PARITY-TURN-MARATHON-GH-1315-LEGACY-PREVIEW-PARITY-TURN-3687-1795713526534-r1-3d6c7377.log

<details>
<summary>Last 8 lines of failing turn log</summary>

```text
**Verdict: Changes requested** on [RELAY.md](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.ixJ5Yn/marathon-system/gh-1315-legacy-preview-parity/RELAY.md#L136-L159).

### Summary
- **Code ([sync.py](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.ixJ5Yn/skills/3-weekly/skills-army-hq/scripts/sync.py#L281-L289)):** Whole-file sweep (`swept file: yes`) found no new or pre-existing defects. A non-mutating CLI probe in `$TMPDIR` confirmed preview/apply parity for unadopted `xyz` (exit `2`, identical refusal naming the ownership reason and `intake.py update xyz --source ...` remedy, zero writes/backups/staging/links) and intact recorded-skill migration (`sample` previews exit `0` with zero writes and applies with managed symlink + retained archive).
- **Blocker ([provenance.jsonl](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.ixJ5Yn/TESTS-RESULTS/2026-11-25+GH-1315/provenance.jsonl#L1-L11) / [readiness_probe.py](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.ixJ5Yn/TESTS-RESULTS/2026-11-25+GH-1315/readiness_probe.py#L104-L111)):** Round 1 claims the retained probe now uses `intake.py catalog` and both before/after receipts are in `TESTS-RESULTS/2026-11-25+GH-1315/provenance.jsonl`, but neither change exists in the seeded tree (`provenance.jsonl` has only the 11 PR #1622 prep rows, and `readiness_probe.py` still uses `git` + `intake.py --apply add`).
- **Token:** `MARATHON-GH-1315-LEGACY-PREVIEW-PARITY-TURN` released to `codex`; `NEXT:` set to `NEXT: codex (Builder)`.

handing off to codex — codex, take your turn
```
</details>
