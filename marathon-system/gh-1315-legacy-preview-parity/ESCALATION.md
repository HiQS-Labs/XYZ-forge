# ESCALATION — Marathon Phase gh-1315-legacy-preview-parity

phase: gh-1315-legacy-preview-parity
task: MARATHON-GH-1315-LEGACY-PREVIEW-PARITY-TURN-3
relay-drive-exit: 4
reason: cap-stalled
gate: not-run
relay-file: marathon-system/gh-1315-legacy-preview-parity/RELAY.md

turn-log: /Users/noelsaw/flywheel-day2-exec/relay-system/logs/2026-11-26/agy-turn-MARATHON-GH-1315-LEGACY-PREVIEW-PARITY-TURN-3-MARATHON-GH-1315-LEGACY-PREVIEW-PARITY-TURN-3-34664-1795715016288-r1-c5c495d7.log

<details>
<summary>Last 10 lines of failing turn log</summary>

```text
**Verdict: Changes requested** on [RELAY.md](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.0lG8J0/marathon-system/gh-1315-legacy-preview-parity/RELAY.md#L145-L176).

### Summary
- **Code ([sync.py](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.0lG8J0/skills/3-weekly/skills-army-hq/scripts/sync.py#L281-L289)):** Whole-file sweep (`swept file: yes`) found no new or pre-existing defects. Non-mutating CLI probes in `$TMPDIR` confirmed `readiness_probe.py` exits `0`, unadopted `xyz` returns exit `2` with identical ownership/remedy guidance and zero writes/backups/staging/links in both preview and apply (with and without `--archive-legacy`), and an unguarded red-control copy (`562b4111...`) fails the probe at exit `1`.
- **Blockers in `TESTS-RESULTS/2026-11-25+GH-1315/`:**
  1. A recursive duplicate nested directory `TESTS-RESULTS/2026-11-25+GH-1315/2026-11-25+GH-1315/` (36 stale files, including conflicting 11-row `provenance.jsonl` and `git`-based `readiness_probe.py`) is committed in the artifact tree.
  2. Round 1 ([RELAY.md](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.0lG8J0/marathon-system/gh-1315-legacy-preview-parity/RELAY.md#L135)) claims two fresh hash-bound receipts were appended to [provenance.jsonl](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.0lG8J0/TESTS-RESULTS/2026-11-25+GH-1315/provenance.jsonl#L1-L13), but only the 11 PR #1622 prep rows and 2 pre-packet rows (`2026-11-26T17:20:36Z`, 23 minutes before packet generation at `17:43:29Z`) exist on disk.
- **Gate / Token:** `gate run: no — harness gate`; `MARATHON-GH-1315-LEGACY-PREVIEW-PARITY-TURN-3` released to `codex` and `NEXT:` updated to `NEXT: codex (Builder)`.

handing off to codex — codex, take your turn
```
</details>
