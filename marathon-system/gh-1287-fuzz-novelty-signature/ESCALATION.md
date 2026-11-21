# ESCALATION — Marathon Phase gh-1287-fuzz-novelty-signature

phase: gh-1287-fuzz-novelty-signature
task: MARATHON-GH-1287-FUZZ-NOVELTY-SIGNATURE-TURN
relay-drive-exit: 0
reason: pre-advance-failed
gate: red
relay-file: marathon-system/gh-1287-fuzz-novelty-signature/RELAY.md

turn-log: /Users/noelsaw/Documents/GitHub/XYZ-forge-gh1356-1287-runner-20261107/relay-system/logs/2026-11-07/codex-turn-MARATHON-GH-1287-FUZZ-NOVELTY-SIGNATURE-TURN-85942.log

<details>
<summary>Last 40 lines of failing turn log</summary>

```text
s=p.read_text()
s=s.replace('STATUS: Open','STATUS: Approved',1)
s+='''
### Round 1 · Reviewer · codex

**Verdict:** Approved

swept file: yes

Ship. Reviewed the whole "'`TESTS-RESULTS/2026-10-30+GH-1280/tools/supervisor.py`, including classification, tracking, launch boundary, canaries, process shutdown and reporting. No concrete pre-existing defect found in this sweep. The change is Easy to reverse and confined to campaign tooling; usage normalization preserves parser/argument/error-kind distinctions while removing echoed values. Non-usage signature handling remains unchanged.

Independent read-only verification (all commands exited 0; `PYTHONDONTWRITEBYTECODE=1`, `TMPDIR="$PWD/.relay-scratch/tmp"`):

- Command: `python3 TESTS-RESULTS/2026-10-30+GH-1280/tools/supervisor.py --contract TESTS-RESULTS/2026-10-30+GH-1280/contracts/contract-long.json --replay-telemetry TESTS-RESULTS/2026-10-30+GH-1280/runs/long/telemetry.jsonl.gz > "$TMPDIR/reviewer-replay.json"`. Parsed the nonempty JSON report: 10,000 events, 8,949 usage events, 23 usage signatures, 34 total signatures, first batch stop at event 500, configured 500-case streak reached at event 1,892, maximum streak 7,387. These independently reproduce the builder'"'s acceptance results.
- Red control command: "'`python3 - <<'"'PY'"'` loaded the supervisor with `runpy.run_path`, replaced only the in-memory `signature` function with its prior last-line/quoted-token/path/digit normalization, then fed every row from the same gzip stream into `Tracker`. Decisive output: `legacy control: events=10000 signatures=2313 usage_signatures=2302 streak_limit_first=None`. No artifact or source was modified. This control demonstrates that the retained input exposes the original pseudo-novelty failure.

All three scoped acceptance criteria are satisfied by source inspection and replay. Full gate/live execution not run here per reviewer containment; the harness must run its disposable-clone gate after this turn. No pytest, shell suites, executable fixtures or git commands were run.

relay closed, no further turn needed
'"'''
p.write_text(s)
PY
TICK_REPO_ROOT=\"/Users/noelsaw/Documents/GitHub/XYZ-forge-gh1356-1287-runner-20261107\" \"/Users/noelsaw/Documents/GitHub/XYZ-forge-gh1356-1287-runner-20261107/bin/tick\" done MARATHON-GH-1287-FUZZ-NOVELTY-SIGNATURE-TURN --agent codex" in /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/rtl-wt.OOZCh1
 succeeded in 0ms:
done: MARATHON-GH-1287-FUZZ-NOVELTY-SIGNATURE-TURN

codex
Approved and closed the token. Updated only `RELAY.md`.

Independent replay confirmed 23 usage signatures and the 500-case novelty streak at event 1,892. The legacy control reproduced 2,302 usage signatures without reaching that streak. Full gate remains for the harness.

relay closed, no further turn needed
tokens used
48,319
Approved and closed the token. Updated only `RELAY.md`.

Independent replay confirmed 23 usage signatures and the 500-case novelty streak at event 1,892. The legacy control reproduced 2,302 usage signatures without reaching that streak. Full gate remains for the harness.

relay closed, no further turn needed
[trace] rtl_enforce: COMMIT f2791b7d6 agent=codex
```
</details>
